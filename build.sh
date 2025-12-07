#!/bin/bash

find_version() {
  if grep "^$1" ../versions.txt; then
    echo $line;
  fi
}

if [ ! -d work ]; then
  echo "Downloading required tools"
  mkdir work

  wget https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.9.3.jar -O work/apktool.jar
  wget https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar -O work/uber-apk-signer.jar
fi

if [ -d work/patches ]; then
  rm -rf work/patches
fi

mkdir work/patches
. ./settings.env

find patches -type f | while IFS= read -r file; do
  mkdir -p work/$(dirname $file)

  sed \
    -e "s#android:authorities=\"\$APPLICATION_ID#android:authorities=\"$APPLICATION_ID#" \
    -e "s#package=\"\$APPLICATION_ID\"#package=\"$APPLICATION_ID\"#" \
    -e "s#\$APP_NAME#$APP_NAME#" \
    -e "s#\$HOST_ALTERNATE#$HOST_ALTERNATE#" \
    -e "s#\$HOST_API#$HOST_API#" \
    -e "s#\$HOST_CDN#$HOST_CDN#" \
    -e "s#\$HOST_DEVELOPER_PORTAL#$HOST_DEVELOPER_PORTAL#" \
    -e "s#\$HOST_GIFT#$HOST_GIFT#" \
    -e "s#\$HOST_GUILD_TEMPLATE#$HOST_GUILD_TEMPLATE#" \
    -e "s#\$HOST_INVITE#$HOST_INVITE#" \
    -e "s#\$HOST_MEDIA_PROXY#$HOST_MEDIA_PROXY#" \
    -e "s#\$USER_AGENT#$USER_AGENT#" \
    -e "s#\$VERSION_NAME#$VERSION_NAME#" \
    -e "s#\$HOST#$HOST#" \
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
  wget https://aliucord.com/download/discord?v=$build -O discord-$build.apk
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
  patch -p0 -i $file
done

cd ..

java -jar apktool.jar b discord-$build -v
java -jar uber-apk-signer.jar --apks discord-$build/dist/discord-$build.apk -o .
