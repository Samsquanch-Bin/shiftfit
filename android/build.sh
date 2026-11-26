#!/usr/bin/env bash
# Builds ShiftFit.apk with Capacitor. Run from the repo root on a GitHub Ubuntu runner.
set -euxo pipefail
RUN=${GITHUB_RUN_NUMBER:-1}
java -version; node -v; echo "ANDROID_HOME=${ANDROID_HOME:-unset} ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT:-unset}"
rm -rf app && mkdir app && cd app
npm init -y >/dev/null
npm i --no-audit --no-fund @capacitor/core@6 @capacitor/cli@6 @capacitor/android@6 @capacitor/app@6 @capacitor/filesystem@6 @capacitor/share@6
mkdir www && cp ../index.html ../manifest.json ../sw.js ../icon-*.png www/
cp ../android/capacitor.config.json .
npx cap add android
npx cap sync android
cd android
M=app/src/main/AndroidManifest.xml
sed -i 's#<uses-permission android:name="android.permission.INTERNET" />#<uses-permission android:name="android.permission.INTERNET" />\n    <uses-permission android:name="android.permission.CAMERA" />\n    <uses-feature android:name="android.hardware.camera" android:required="false" />#' $M
grep -q CAMERA $M
rm -rf app/src/main/res/mipmap-anydpi-v26
for n in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  cp ../../android/res/ic_$n.png app/src/main/res/mipmap-$n/ic_launcher.png
  cp ../../android/res/ic_$n.png app/src/main/res/mipmap-$n/ic_launcher_round.png
  rm -f app/src/main/res/mipmap-$n/ic_launcher_foreground.png
done
sed -i "s/versionCode 1/versionCode $RUN/; s/versionName \"1.0\"/versionName \"1.$RUN\"/" app/build.gradle
grep -n "versionCode\|versionName" app/build.gradle
mkdir -p ~/.android && cp ../../android/debug.keystore ~/.android/debug.keystore
echo "sdk.dir=${ANDROID_HOME:-$ANDROID_SDK_ROOT}" > local.properties
chmod +x gradlew
./gradlew assembleDebug --no-daemon --stacktrace
cp app/build/outputs/apk/debug/app-debug.apk ../../ShiftFit.apk
ls -la ../../ShiftFit.apk
