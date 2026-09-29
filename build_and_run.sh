#!/bin/bash

# stop on error
set -eou pipefail

source adb_settings.sh

# I call the app "xDripX" rather than "xDrip+"
# so I can run both on the phone and so it's
# obvious to an idiot like me which is which.
APP_NAME="xDripX"

# build options
gradlew()
{
    nice ./gradlew --warning-mode all -PappName="$APP_NAME" "$@"
    #nice ./gradlew --no-daemon --warning-mode all -PappName="$APP_NAME" "$@"
}

# build the app
gradlew assembleProdDebug

# build wear apk
gradlew :wear:assembleProdDebug

# install on the phone
adb_phone install -r app/build/outputs/apk/prod/debug/app-prod-debug.apk

# install on watch if it is reachable by adb
if timeout 3 adb connect "$WATCH_ADDRESS" >/dev/null 2>&1 &&
   [[ $(adb_watch get-state 2>/dev/null) == "device" ]]
then
    echo "Watch detected at $WATCH_ADDRESS: installing Wear APK"
    adb_watch install -r wear/build/outputs/apk/prod/debug/wear-prod-debug.apk
else
    echo "Watch not available at $WATCH_ADDRESS: skipping Wear APK installation"
fi

# enable
adb_phone shell pm enable com.eveningoutpost.dexdrip.debug

# stop original xdrip and juggluco on the phone
adb_phone shell am force-stop com.eveningoutpost.dexdrip
adb_phone shell am force-stop tk.glucodata

# stop our new xdripx as well
adb_phone shell am force-stop com.eveningoutpost.dexdrip.debug


# start debug xdrip
# monkey works, but causes autorotate to switch on (annoying!)
#adb_phone shell monkey -p com.eveningoutpost.dexdrip.debug 1
#
# try this instead
adb_phone shell am start \
    -a android.intent.action.MAIN \
    -c android.intent.category.LAUNCHER \
    -n com.eveningoutpost.dexdrip.debug/com.eveningoutpost.dexdrip.Home

# logging
LOGFILE=oneplus-bluetooth-full.log \
    ./logging.sh \
    'Ob1G5CollectionService|Ob1G5StateMachine|KEKS-Plugin|BluetoothGatt|onConnectionUpdated|Connecting with auto|Got scan result|Full success|Could not authenticate|Got glucose|Bond|Pair' \
    '!Fastpair' \
    '!getBondedDevices' \
    '!Checking'
