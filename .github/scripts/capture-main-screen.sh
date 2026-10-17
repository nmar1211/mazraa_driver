#!/usr/bin/env bash
set -euo pipefail

: "${APP_ID:?APP_ID is required}"
: "${DEBUG_APK:?DEBUG_APK is required}"

mkdir -p artifacts
rm -f artifacts/window.xml artifacts/main-screen.png artifacts/not-ready-screen.png

# Keep the canonical 9:16 ratio while using a lighter emulator framebuffer.
# 1080x1920 scales losslessly by 4/3 to the 1440x2560 design reference.
adb shell wm size 1080x1920 >/dev/null
adb shell wm dismiss-keyguard >/dev/null 2>&1 || true

adb uninstall "$APP_ID" >/dev/null 2>&1 || true
adb install "$DEBUG_APK"
adb shell am force-stop "$APP_ID" || true
adb shell pm clear "$APP_ID" >/dev/null 2>&1 || true
adb shell monkey -p "$APP_ID" -c android.intent.category.LAUNCHER 1

launched=false
for attempt in $(seq 1 45); do
  resumed="$(adb shell dumpsys activity activities 2>/dev/null | grep -m1 -E 'topResumedActivity=|ResumedActivity:' || true)"
  if [[ "$resumed" == *"$APP_ID"* ]]; then
    launched=true
    break
  fi
  sleep 1
done
[[ "$launched" == true ]] || exit 1

ready=false
for attempt in $(seq 1 45); do
  adb shell rm -f /sdcard/mazraa-window.xml >/dev/null 2>&1 || true
  if adb shell uiautomator dump --compressed /sdcard/mazraa-window.xml >/dev/null 2>&1 \
      && adb exec-out cat /sdcard/mazraa-window.xml > artifacts/window.xml 2>/dev/null; then
    if grep -Fq 'خلك شريك التوصيل الأفضل' artifacts/window.xml \
        && grep -Fq 'ابدأ الآن' artifacts/window.xml \
        && grep -Fq 'لدي حساب بالفعل' artifacts/window.xml; then
      ready=true
      break
    fi
  fi
  sleep 1
done

if [[ "$ready" != true ]]; then
  echo 'Fixed screen 01 did not expose all canonical semantic markers.'
  adb exec-out screencap -p > artifacts/not-ready-screen.png || true
  adb logcat -d > artifacts/logcat.txt || true
  exit 1
fi

sleep 1
adb exec-out screencap -p > artifacts/main-screen.png
test -s artifacts/main-screen.png
file artifacts/main-screen.png
