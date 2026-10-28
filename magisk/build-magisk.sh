#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
OUT_ZIP="$PWD/NotGameTurbo-magisk.zip"

APK="$(ls ./*.apk 2>/dev/null | head -1 || true)"
if [ -z "$APK" ]; then
    echo "error: no .apk found in $PWD" >&2
    exit 1
fi
echo "APK: $APK"

BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT

mkdir -p "$BUILD/system/priv-app/NotGameTurbo" "$BUILD/system/etc/permissions"
cp "$APK" "$BUILD/system/priv-app/NotGameTurbo/NotGameTurbo.apk"
cp "$REPO_DIR/privapp-permissions-notgameturbo.xml" "$BUILD/system/etc/permissions/"

cat > "$BUILD/module.prop" <<EOF
id=notgameturbo
name=NotGameTurbo
version=v1.4
versionCode=104
author=grewal
description=Per-app touch game mode, super report rate, tuning and panel orientation for Xiaomi devices with the touchfeature HAL.
EOF

cat > "$BUILD/sepolicy.rule" <<'EOF'
allow platform_app_36 hal_touchfeature_xiaomi_service service_manager find
allow platform_app_36 hal_touchfeature_xiaomi_default binder { call transfer }
allow hal_touchfeature_xiaomi_default platform_app_36 binder { call transfer }
allow hal_touchfeature_xiaomi_default platform_app_36 fd use
allow priv_app hal_touchfeature_xiaomi_service service_manager find
allow priv_app hal_touchfeature_xiaomi_default binder { call transfer }
allow hal_touchfeature_xiaomi_default priv_app binder { call transfer }
allow hal_touchfeature_xiaomi_default priv_app fd use
allow platform_app_36 vendor_sysfs_touch file { ioctl read write getattr lock append map open watch watch_reads }
allow priv_app vendor_sysfs_touch file { ioctl read write getattr lock append map open watch watch_reads }
typeattribute vendor_sysfs_touch mlstrustedobject
EOF

rm -f "$OUT_ZIP"
( cd "$BUILD" && zip -r9 -q "$OUT_ZIP" module.prop sepolicy.rule system )
echo "Created: $OUT_ZIP"
