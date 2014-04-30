#!/bin/bash

# Some functions copied from DevStack itself

# Prints backtrace info
# filename:lineno:function
# backtrace level
backtrace() {
    local level=$1
    local deep=$((${#BASH_SOURCE[@]} - 1))
    echo "[Call Trace]"
    while [ $level -le $deep ]; do
        echo "${BASH_SOURCE[$deep]}:${BASH_LINENO[$deep-1]}:${FUNCNAME[$deep-1]}"
        deep=$((deep - 1))
    done
}

# Prints line number and "message" then exits
# die $LINENO "message"
die() {
    local exitcode=$?
    set +o xtrace
    local line=$1; shift
    if [[ $exitcode == 0 ]]; then
        exitcode=1
    fi
    backtrace 2
    err $line "$*"
    exit $exitcode
}

function_die() {
    local exitcode=$?
    set +o xtrace
    local line=$1; shift
    if [[ $exitcode == 0 ]]; then
        exitcode=1
    fi
    backtrace 2
    err $line "$*"
    return $exitcode
}

quiet_die() {
    local exitcode=$?
    local message="$1"
    echo "$message"
    exit $exitcode
}

function_quiet_die() {
    local exitcode=$?
    local message="$1"
    echo "$message"
    return $exitcode
}

# Prints line number and "message" in error format
# err $LINENO "message"
err() {
    local exitcode=$?
    errXTRACE=$(set +o | grep xtrace)
    set +o xtrace
    local msg="[ERROR] ${BASH_SOURCE[2]}:$1 $2"
    echo -e "********************\n${msg}\n********************" 1>&2;
    if [[ -n ${SCREEN_LOGDIR} ]]; then
        echo $msg >> "${SCREEN_LOGDIR}/error.log"
    fi
    $errXTRACE
    return $exitcode
}

# Test if the named environment variable is set and not zero length
# is_set env-var
is_set() {
    local var=\$"$1"
    eval "[ -n \"$var\" ]" # For ex.: sh -c "[ -n \"$var\" ]" would be better, but several exercises depends on this
}

# Checks an environment variable is not set or has length 0 OR if the
# exit code is non-zero and prints "message"
# NOTE: env-var is the variable name without a '$'
# err_if_not_set $LINENO env-var "message"
err_if_not_set() {
    local exitcode=$?
    errinsXTRACE=$(set +o | grep xtrace)
    set +o xtrace
    local line=$1; shift
    local evar=$1; shift
    if ! is_set $evar || [ $exitcode != 0 ]; then
        err $line "$*"
    fi
    $errinsXTRACE
    return $exitcode
}

#replace_in_file() {
#    local tmp_file=`mktemp`
#    local sed="$1"
#    local file="$2"
#    # undef $/ means file is treated as a whole as opposed to line by line
#    perl -e "undef \$/; \$myfile = <STDIN>; \$myfile =~ $sed; print \$myfile" < "$file" > "$tmp_file"
#    mv "$tmp_file" "$file"
#}

add_or_replace_in_file() {
    local search=$1
    local replace=$2
    local file=$3
    if [[ ! -f $file ]]; then
        touch $file
    fi
    if grep $search $file &> /dev/null; then
        sed -i "s@$search@$replace@" $file
    else
        echo -e "\n$replace" >> $file
    fi
}

# date for use in filenames
safe_date() {
    date +%Y_%m_%d__%H_%M_%S
}

git_cmd() {
    local repo_path=$1
    shift
    # env -i to eliminate GIT_DIR and GIT_WORK_TREE
    # see http://stackoverflow.com/questions/3542854/calling-git-pull-from-a-git-post-update-hook
    (cd $repo_path && env -i git "$@")
}

make_bare_repo_path() {
    local bare_repo_root_dir=$1
    local project=$2
    echo "$bare_repo_root_dir/$project.git"
}

log_info() {
    local msg=$1
    echo "INFO: $msg"
}


project_from_repo_url() {
    local git_repo_url=$1
#    # ## deletes from beginning using regex
#    local last_path_segment=${git_repo_url##*/}
#    # %% deletes from end using regex
#    local project=${last_path_segment%%.*}
    echo $(basename $git_repo_url .git)
}