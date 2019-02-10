#! /bin/bash
#
# Name:
#   package.sh - creates a new LOVE release for a given OS target
#
# Synopsis:
#   package.sh SRC TARGET
#
# Description:
#   package.sh creates a new LOVE package from a given SRC for a given OS
#   TARGET. Valid targets: macos, windows, and linux.
#

# exit if attempting to use unset variable
set -o nounset

# exit if any statement returns a false value
set -o errexit

PKG="./pkg"
LOVE_MACOS_URL="https://bitbucket.org/rude/love/downloads/love-11.2-macos.zip"
LOVE_WIN_URL="https://bitbucket.org/rude/love/downloads/love-11.2-win32.zip"
USAGE="Usage: deploy.sh SRC TARGET\n"

if [ "$#" -lt 1 -o "$#" -gt 2 ]
  then
    printf "$USAGE"
    exit 1
fi

if [ -z "$1" ]
  then
    printf "Invalid SRC: %s\n" $1
    printf "$USAGE"
    exit 1
fi

SRC="$1"
TARGET="$2"


case "$TARGET" in
  "love")
    printf "Creating LÖVE package ... %s.\n"
    pushd "$SRC" && zip -r FollowMe.love . && popd
    mkdir -p "$PKG" && mv -v "$SRC/FollowMe.love" $PKG
    ;;
  "macos")
    printf "Creating macOS app bundle ...\n"
    cp -v Info.plist "$PKG"
    pushd "$PKG"
    curl -L -o love-macos.zip "$LOVE_MACOS_URL"
    unzip love-macos.zip
    mv -v love.app FollowMe.app
    cp -v FollowMe.love "FollowMe.app/Contents/Resources/"
    cp -v Info.plist "FollowMe.app/Contents/"
    zip -r FollowMe-macOS.zip FollowMe.app
    rm -rf Info.plist love-macos.zip FollowMe.app
    popd
    ;;
  "windows")
    printf "Creating Windows executable ...\n"
    pushd "$PKG"
    curl -L -o love-win.zip "$LOVE_WIN_URL"
    unzip -j love-win.zip -d FollowMe
    pushd FollowMe
    cat love.exe ../FollowMe.love > FollowMe.exe
    rm -f love.exe
    popd
    zip -r FollowMe-Win32.zip FollowMe
    rm -rf love-win.zip FollowMe
    popd
    ;;
  "linux")
    pushd "$PKG"
    # currently the easiest way to distribute to linux is to ship the love
    # package and ask users to install LÖVE, so this is a NOP for now
    printf "Creating Linux package ...\n"
    popd
    ;;
  *) printf "Invalid target: %s.\n" "$TARGET" && exit 1;;
esac
