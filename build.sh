#!/usr/bin/env bash

source ./settings.env

if [[  "$1" == "--adb" ]]; then
  ADB=true
  shift
fi

find_version() {
  if grep "^$1" ../versions.txt; then
    echo $line;
  fi
}

if [ ! -d work ]; then
  echo "Downloading required tools"
  mkdir work

  curl https://github.com/iBotPeaches/Apktool/releases/download/v2.9.3/apktool_2.9.3.jar -Lo work/apktool.jar
  curl https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar -Lo work/uber-apk-signer.jar
fi

if [ -d work/patches ]; then
  rm -rf work/patches
fi

mkdir work/patches

find patches -type f | while IFS= read -r file; do
  mkdir -p work/$(dirname $file)

  sed \
    -e "s#\$APPLICATION_ID#$APPLICATION_ID#g" \
    -e "s#\$APP_NAME#$APP_NAME#g" \
    -e "s#\$HOST_ALTERNATE#$HOST_ALTERNATE#g" \
    -e "s#\$HOST_API#$HOST_API#g" \
    -e "s#\$HOST_CDN#$HOST_CDN#g" \
    -e "s#\$HOST_DEVELOPER_PORTAL#$HOST_DEVELOPER_PORTAL#g" \
    -e "s#\$HOST_GIFT#$HOST_GIFT#g" \
    -e "s#\$HOST_GUILD_TEMPLATE#$HOST_GUILD_TEMPLATE#g" \
    -e "s#\$HOST_INVITE#$HOST_INVITE#g" \
    -e "s#\$HOST_MEDIA_PROXY#$HOST_MEDIA_PROXY#g" \
    -e "s#\$USER_AGENT#$USER_AGENT#g" \
    -e "s#\$VERSION_NAME#$VERSION_NAME#g" \
    -e "s#\$HOST#$HOST#g" \
    $file > work/$file
done

cd work

discordver=$(find_version ${1:-126021})

if [[ -z $discordver ]]; then
  echo "Invalid discord version, exiting"
  exit 1
fi

build=$(echo $discordver | cut -d ' ' -f 1)
version=$(echo $discordver | cut -d ' ' -f 2)
versionstring=$(echo $discordver | cut -d ' ' -f 2-)

if [ ! -f discord-$build.apk ]; then
  echo "Downloading discord-$build.apk"
  curl https://aliucord.com/download/discord?v=$build -Lo discord-$build.apk
fi

if [ -d discord-$build ]; then
  echo "Removing previous discord decompilation"
  rm -rf discord-$build
fi

echo "Decompiling discord-$build.apk"
java -jar apktool.jar d discord-$build.apk

cd discord-$build
echo "Patching discord source"

find ../patches -type f | while IFS= read -r file; do
  patch -p0 --verbose --forward --unified -i $file
done

cd ..

java -jar apktool.jar b discord-$build -v
java -jar uber-apk-signer.jar --apks discord-$build/dist/discord-$build.apk -o .

if test $ADB; then
  echo "Installing APK on the emulator"
  adb install discord-$build-aligned-debugSigned.apk

  echo "Opening application"
  adb shell monkey -p $APPLICATION_ID -c android.intent.category.LAUNCHER 1

  echo "Showing app logs"
  adb logcat -v color -e $APPLICATION_ID
fi
