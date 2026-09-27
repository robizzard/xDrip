#!/bin/bash

# stop on error
set -eou pipefail

# find my_private_details.sh relative to this script
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PRIVATE_DETAILS="$SCRIPT_DIR/my_private_details.sh"
cd "$SCRIPT_DIR"

if [[ ! -r "$PRIVATE_DETAILS" ]]
then
    echo "Missing $PRIVATE_DETAILS"
    echo "Copy my_private_details.sh.example to my_private_details.sh and edit it."
    exit 1
fi

source "$PRIVATE_DETAILS"

ADB_PHONE=(adb -s "$PHONE_SERIAL")
ADB_WATCH=(adb -s "$WATCH_ADDRESS")

# I call the app "xDripX" rather than "xDrip+"
# so I can run both on the phone and so it's
# obvious to an idiot like me which is which.
APP_NAME="xDripX"

# build the app
nice ./gradlew --no-daemon assembleProdDebug --warning-mode all -PappName="$APP_NAME"

# build wear apk
nice ./gradlew --no-daemon :wear:assembleProdDebug --warning-mode all -PappName="$APP_NAME"

# install on the phone
"${ADB_PHONE[@]}" install -r app/build/outputs/apk/prod/debug/app-prod-debug.apk

# install on watch if it is reachable by adb
if timeout 3 adb connect "$WATCH_ADDRESS" >/dev/null 2>&1 &&
   [[ $("${ADB_WATCH[@]}" get-state 2>/dev/null) == "device" ]]
then
    echo "Watch detected at $WATCH_ADDRESS: installing Wear APK"
    "${ADB_WATCH[@]}" install -r wear/build/outputs/apk/prod/debug/wear-prod-debug.apk
else
    echo "Watch not available at $WATCH_ADDRESS: skipping Wear APK installation"
fi

# enable
"${ADB_PHONE[@]}" shell pm enable com.eveningoutpost.dexdrip.debug

# stop original xdrip and juggluco on the phone
"${ADB_PHONE[@]}" shell am force-stop com.eveningoutpost.dexdrip
"${ADB_PHONE[@]}" shell am force-stop tk.glucodata

# stop our new xdripx as well
"${ADB_PHONE[@]}" shell am force-stop com.eveningoutpost.dexdrip.debug

# clean logs
"${ADB_PHONE[@]}" logcat -c

# start debug xdrip
"${ADB_PHONE[@]}" shell monkey -p com.eveningoutpost.dexdrip.debug 1

# obtain a useful debug, continuously
#"${ADB_PHONE[@]}" logcat -v time | tee xdrip-direct-connect-test.log # too much to read...

# obtain a debug which is filtered to useful data for our purposes
"${ADB_PHONE[@]}" logcat -v time | grep --line-buffered -E 'Ob1G5CollectionService|Ob1G5StateMachine|KEKS-Plugin|Connecting with auto|Got scan result|Full success|Could not authenticate|Got glucose|Bond|Pair'|grep -v FastPair
