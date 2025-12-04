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

. ../../settings.env

echo "Patching manifest"

sed --debug -i \
 -e "s#package=\"com.discord\"#package=\"$APPLICATION_ID\"#" \
 -e "s#@string/discord#$APP_NAME#" AndroidManifest.xml \
 -e "s#android:authorities=\"com.discord#android:authorities=\"$APPLICATION_ID#" \
  AndroidManifest.xml

for path in $(find smali* -type f); do
  echo "Patching: $path"

  sed -i \
   -e "s#https://discord.com#$HOST#" \
   -e"s#https://discordapp.com#$HOST_ALTERNAME#" \
   -e "s#https://discord.com/api/#$HOST_API#" \
   -e "s#https://cdn.discordapp.com#$HOST_CDN#" \
   -e "s#https://discord.com/developers#$HOST_DEVELOPER_PORTAL#" \
   -e "s#https://discord.gift#$HOST_GIFT#" \
   -e "s#https://discord.new#$HOST_GUILD_TEMPLATE#" \
   -e "s#https://discord.gg#$HOST_INVITE#" \
   -e "s#https://media.discordapp.net#$HOST_MEDIA_PROXY#" \
   -e "s#Discord-Android/$version#$USER_AGENT#" \
   -e "s#$versionstring#$VERSION_NAME#" \
   $path
done

cd ..

java -jar apktool.jar b discord-$build -v
java -jar uber-apk-signer.jar --apks discord-$build/dist/discord-$build.apk -o .
