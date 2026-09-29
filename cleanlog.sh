#!/bin/bash

set -eou pipefail
source adb_settings.sh
adb_phone logcat -c
adb_phone logcat -v time | \
    grep --line-buffered -E \
         'AndroidRuntime|FATAL EXCEPTION|dexdrip|Notification|Icon|number'
