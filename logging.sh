#!/bin/bash

usage()
{
    cat <<EOF
Usage: ${0##*/} MAIN_PATTERN [PATTERN ...] [!PATTERN ...]

Filter adb_phone logcat output.

Arguments:
  MAIN_PATTERN   Extended-regexp used for the initial grep -E.
  PATTERN        Show lines matching any of these additional patterns.
  !PATTERN       Exclude lines matching any of these patterns.

Environment:
  LOGFILE        If non-empty, tee the complete unfiltered logcat output
                 to this file. If unset or empty, no log file is written.

Example:
  ${0##*/} 'Ob1G5CollectionService|Ob1G5StateMachine|BluetoothGatt|Got glucose' \
      glucose '!onConnectionUpdated'

  LOGFILE=oneplus-bluetooth-full.log ${0##*/} \
      'Ob1G5CollectionService|Ob1G5StateMachine|KEKS-Plugin' \
      '!BluetoothGatt'
EOF
}


if [[ $# -lt 1 || ${1:-} == "-h" || ${1:-} == "--help" ]]; then
    usage
    exit $(( $# < 1 ))
fi

source adb_settings.sh

main_pattern=$1
shift

include_args=()
exclude_args=()

for pattern in "$@"; do
    if [[ $pattern == '!'* ]]; then
        exclude_args+=( -e "${pattern:1}" )
    else
        include_args+=( -e "$pattern" )
    fi
done

# clean logs
adb_phone logcat -c

# run our wanted logs
adb_phone logcat -b all -v time | \
{
    if [[ -n ${LOGFILE:-} ]]; then
        tee "$LOGFILE"
    else
        cat
    fi
} | \
grep --line-buffered -E "$main_pattern" | \
{
    if((${#include_args[@]})); then
        grep --line-buffered "${include_args[@]}"
    else
        cat
    fi
} | \
{
    if((${#exclude_args[@]})); then
        grep --line-buffered -v "${exclude_args[@]}"
    else
        cat
    fi
}



# obtain a useful debug, continuously, but this is a
# lot of output...
#adb_phone logcat -v time | tee xdrip-direct-connect-test.log
