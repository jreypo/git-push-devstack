#!/bin/bash

stop_tr_api() {
    stop_screen_window tr-api bin/trove-api
}

stop_tr_tmgr() {
    stop_screen_window tr-tmgr bin/trove-taskmanager
}

stop_tr_cond() {
    stop_screen_window tr-cond bin/trove-conductor
}

start_tr_api() {
    start_screen_window tr-api bin/trove-api
}

start_tr_tmgr() {
    start_screen_window tr-tmgr bin/trove-taskmanager
}

start_tr_cond() {
    start_screen_window tr-cond bin/trove-conductor
}

restart_tr_api() {
    stop_tr_api
    start_tr_api
}

restart_tr_tmgr() {
    stop_tr_tmgr
    start_tr_tmgr
}

restart_tr_cond() {
    stop_tr_cond
    start_tr_cond
}

do_in_guest() {
    local cmd=$1
    ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $GUEST_USERNAME@$GUEST_IP "$cmd"
}

start_tr_guest() {
    do_in_guest "sudo service trove-guest start"
}

stop_tr_guest() {
    do_in_guest "sudo service trove-guest stop"
}

restart_tr_guest() {
    do_in_guest "sudo service trove-guest restart"
}

update_guest_code() {
    do_in_guest "sudo -u $GUEST_USERNAME rsync -e 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' -avz --exclude='.*' ${GUEST_USERNAME}@10.0.0.1:$dest_repo_dir/ /home/$GUEST_USERNAME/trove && sudo service trove-guest restart"
}

fix_guestagent_conf() {
    # trove-guestagent.conf is an odd-ball; it doesn't live in /etc/trove like
    # the other conf files since it is rsync'ed to the guest (and the rsync
    # only pulls /opt/stack/trove); furthermore, it's edited by DevStack (see
    # lib/trove) with NETWORK_GATEWAY, RABBIT_PASSWORD, and log settings; so
    # during a post-receive on trove, this needs to be run since the user's copy
    # will overwrite any edits by DevStack

    # execute in subshell
    (
    # copied from redstack.rc
    RABBIT_PASSWORD=f7999d1955c5014aa32c
    # copied from stack.sh
    ENABLE_DEBUG_LOG_LEVEL=True
    SYSLOG=False
    LOG_COLOR=True

    source $devstack_home_dir/functions
    source $devstack_home_dir/stackrc
    source $devstack_home_dir/lib/trove

    iniset $TROVE_LOCAL_CONF_DIR/trove-guestagent.conf.sample DEFAULT rabbit_password $RABBIT_PASSWORD
    sed -i "s/localhost/$NETWORK_GATEWAY/g" $TROVE_LOCAL_CONF_DIR/trove-guestagent.conf.sample
    setup_trove_logging $TROVE_LOCAL_CONF_DIR/trove-guestagent.conf.sample
    )
}


main() {
    local dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    source $dir/vm.bash
    post_receive_begin
    post_receive $dest_repo_dir


    GUEST_IP=${GUEST_IP:-10.0.0.2}
    GUEST_USERNAME=${GUEST_USERNAME:-`whoami`}

    fix_guestagent_conf
    restart_tr_api
    restart_tr_tmgr
    restart_tr_cond
    echo "Pulling code onto guest ($GUEST_IP)..."
    update_guest_code
    post_receive_end
}

main