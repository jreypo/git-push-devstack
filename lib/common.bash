#!/bin/bash

# Some functions copied from DevStack itself

debug_value() {
    local name="$1"
    local value="$2"
    printf "DEBUG: %s=\"%q\"\n" "$name" "$value"
}

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


# Checks an environment variable is not set or has length 0 OR if the
# exit code is non-zero and prints "message" and exits
# NOTE: env-var is the variable name without a '$'
# die_if_not_set $LINENO env-var "message"
die_if_not_set() {
    local exitcode=$?
    FXTRACE=$(set +o | grep xtrace)
    set +o xtrace
    local line=$1; shift
    local evar=$1; shift
    if ! is_set $evar || [ $exitcode != 0 ]; then
        die $line "$*"
    fi
    $FXTRACE
}

# Prints line number and "message" in error format
# err $LINENO "message"
err() {
    local exitcode=$?
    errXTRACE=$(set +o | grep xtrace)
    set +o xtrace
    local msg="[ERROR] ${BASH_SOURCE[2]}:$1 $2"
    echo -e '\E[40;31m'"${msg}\033[m" 1>&2;
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

replace_in_file() {
    local tmp_file=`mktemp`
    local sed="$1"
    local file="$2"
    # undef $/ means file is treated as a whole as opposed to line by line
    perl -e "undef \$/; \$myfile = <STDIN>; \$myfile =~ $sed; print \$myfile" < "$file" > "$tmp_file"
    mv "$tmp_file" "$file"
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