#!/bin/bash
TOP="$(realpath .)"
export DEBFULLNAME="Maarten Fonville"
export DEBEMAIL="maarten.fonville@gmail.com"

d="$1"
case "$d" in
  trusty) trustydep=", lib32bz2-1.0 [amd64]";;
  wily|xenial);;
  clean) rm -f "$TOP/android-studio/debian/control" "$TOP/android-studio/debian/changelog" "$TOP/android-studio/debian/changelog.dch" "$TOP/android-studio/debian/preinst"; echo "Android Studio sources cleaned!"; exit 0;;
  *) echo "Unrecognized Ubuntu version, use a valid distribution as 1st argument"; exit 1;;
esac

c="$2"
case "$c" in
  stable)          suf="";;
  beta|canary|dev) suf="-$2";;
  *) echo "Unrecognized release channel, use a valid Android Studio release channel as 2nd argument"; exit 1;;
esac

con="$(echo "android-studio, android-studio-beta, android-studio-dev, " | sed -e "s/android-studio$suf, //")"
con=${con::-2}

page="$(wget -O - -q "http://tools.android.com/download/studio/$c" | grep -oE "(The current build in the $c channel is[^(]*\()|(For more information, see[^(]*\()" | sed -n 's/.*a href="\([^"]*\)".*/\1/p')"
dl="$(wget -O - -q "$page" | grep -oE 'href="https://dl.google.com/dl/android/studio/ide-zips/[^"]+-linux.zip"')"
dl=${dl:6:-1}
ver="$(printf "$dl" | sed -n 's/.*android-studio-ide-\([0-9\.]*\)-linux\.zip/\1/p')"

if [ -z "$ver" ]; then
  echo "Could not parse android-studio webpage"
  exit 1
fi

echo "#!/bin/bash

## Download Android Studio from Google
wget -O /opt/android-studio-ide.zip '$dl'

## We should add SHA1 checksum scan here in the future" > "$TOP/android-studio/debian/preinst"

echo "Source: android-studio$suf
Section: devel
Priority: optional
Maintainer: Maarten Fonville <maarten.fonville@gmail.com>
Build-Depends: debhelper (>= 7.0.50~), wget
Standards-Version: 3.9.5
Homepage: http://developer.android.com/tools/studio/index.html


Package: android-studio$suf
Architecture: any
Suggests: default-jdk
Pre-Depends: wget
Depends: \${misc:Depends}, java-sdk | oracle-java7-installer | oracle-java8-installer, unzip
Recommends: libc6-i386 [amd64], lib32stdc++6 [amd64], lib32gcc1 [amd64], lib32ncurses5 [amd64], lib32z1 [amd64], lib32z1-dev [amd64]$trustydep
Conflicts: $con
Description: Android Studio.
 Android Studio is the official IDE for Android application development, based on IntelliJ IDEA." > "$TOP/android-studio/debian/control"


rm -f "$TOP/android-studio/debian/changelog"
pushd "$TOP/android-studio" > /dev/null
dch --create -v "$ver~$d" --package "android-studio$suf" -D "$d" -u low "Updated to Android Studio Linux $ver ($c)" #also possible to pass -M if you are the maintainer in the control file
popd > /dev/null
echo "android-studio${suf}_$ver~$d"