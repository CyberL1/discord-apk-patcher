#!/bin/bash

if [ ! -d work ]; then
  echo "Downloading required tools"
  mkdir work
  cd work

  wget https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.9.3.jar -O apktool.jar
  wget https://github.com/patrickfav/uber-apk-signer/releases/download/v1.3.0/uber-apk-signer-1.3.0.jar -O uber-apk-signer.jar
fi

cd work

if [ ! -f discord.apk ]; then
  echo "Downloading discord.apk"
  wget https://aliucord.com/download/discord?v=126021 -O discord.apk
fi

if [ -d discord ]; then
  echo "Removing previous discord decompilation"
  rm -rf discord
fi

echo "Decompiling discord.apk"
java -jar apktool.jar d discord.apk

cd discord
echo "Patching discord source"

. ../../settings.env

echo "Pathing manifest"

sed --debug -i "s#package=\"com.discord\"#package=\"$APPLICATION_ID\"#" AndroidManifest.xml
sed --debug -i "s#@string/discord#$APP_NAME#" AndroidManifest.xml
sed --debug -i "s#android:authorities=\"com.discord#android:authorities=\"$APPLICATION_ID#" AndroidManifest.xml

for path in $(find smali* -type f); do
  echo "Pathing: $path"

  sed -i "s#https://discord.com#$HOST#" $path
  sed -i "s#https://discordapp.com#$HOST_ALTERNAME#" $path
  sed -i "s#https://discord.com/api/#$HOST_API#" $path
  sed -i "s#https://cdn.discordapp.com#$HOST_CDN#" $path
  sed -i "s#https://discord.com/developers#$HOST_DEVELOPER_PORTAL#" $path
  sed -i "s#https://discord.gift#$HOST_GIFT#" $path
  sed -i "s#https://discord.new#$HOST_GUILD_TEMPLATE#" $path
  sed -i "s#https://discord.gg#$HOST_INVITE#" $path
  sed -i "s#https://media.discordapp.net#$HOST_MEDIA_PROXY#" $path
  sed -i "s#Discord-Android/126021#$USER_AGENT#" $path
  sed -i "s#126.21 - Stable#$VERSION_NAME#" $path
done

cd ..

java -jar apktool.jar b discord -v
java -jar uber-apk-signer.jar --apks discord/dist/discord.apk -o .
