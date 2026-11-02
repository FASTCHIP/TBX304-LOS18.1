#!/usr/bin/env bash
# Flash LOS via TWRP OpenRecoveryScript — no touchscreen interaction needed.
# Prereq: device in system with USB debugging, or already in TWRP (skip step 1).
set -euo pipefail
ZIP="${1:?usage: flash-ors.sh path/to/lineage-18.1-*-TBX304.zip}"
ADB="${ADB:-adb}"

"$ADB" reboot recovery; sleep 25
"$ADB" shell twrp --version   # must show TWRP 3.x
# sanity: wipe only when you intend a clean install (major upgrade)
read -p "WIPE data+cache+dalvik? [y/N] " W
if [ "${W,,}" = y ]; then
  "$ADB" shell "twrp wipe data"; sleep 8
  "$ADB" shell "twrp wipe cache"; sleep 4
  "$ADB" shell "twrp wipe dalvik"; sleep 4
fi
"$ADB" push "$ZIP" /data/los.zip
LOCAL_SHA=$(sha256sum "$ZIP" | cut -d' ' -f1)
DEV_SHA=$("$ADB" shell sha256sum /data/los.zip | tr -d '\r' | cut -d' ' -f1)
[ "$LOCAL_SHA" = "$DEV_SHA" ] || { echo "SHA MISMATCH: $LOCAL_SHA vs $DEV_SHA"; exit 1; }
echo "sha verified on device: $DEV_SHA"
"$ADB" shell "echo 'install /data/los.zip' > /cache/recovery/openrecoveryscript"
"$ADB" reboot recovery
echo "TWRP installs and reboots automatically; first boot ~5-10 min."
