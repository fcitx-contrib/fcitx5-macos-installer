#!/bin/zsh
set -xeu

date 1>&2
setopt NULL_GLOB

user="$1"
Resources="$2"
ARCH="$(uname -m)"
INSTALL_DIR="/Library/Input Methods"
APP_DIR="$INSTALL_DIR/Fcitx5.app"
DATA_DIR="/Users/$user/Library/fcitx5"
CONFIG_DIR="/Users/$user/.config/fcitx5"

ICON_FILE="fcitx.icns"
ICON_PATH="$APP_DIR/Contents/Resources/$ICON_FILE"
ICON_BAKUP="/tmp/$ICON_FILE"

cd "$Resources"
mkdir -p "$INSTALL_DIR"

# Backup maybe user-defined icon
if [[ -f "$ICON_PATH" ]]; then
  mv "$ICON_PATH" "$ICON_BAKUP"
fi

rm -rf "$APP_DIR/Contents/*"

tar xjvf "Fcitx5-$ARCH.tar.bz2" -C "$INSTALL_DIR"

if [[ -f "$ICON_BAKUP" ]]; then
  mv "$ICON_BAKUP" "$ICON_PATH"
fi

xattr -dr com.apple.quarantine "$APP_DIR"
codesign --force --sign - --deep "$APP_DIR"

mkdir -p "$DATA_DIR"
for plugin_path in plugins/*-$ARCH.tar.bz2; do
  tar xjvf "$plugin_path" -C "$DATA_DIR"
done
chown -R "$user" "$DATA_DIR"

mkdir -p "$CONFIG_DIR"
if [[ -d config ]]; then
  pushd config
  for file_name in *; do
    if [[ ! -f "$CONFIG_DIR/$file_name" ]]; then
      cp "$file_name" "$CONFIG_DIR"
    fi
  done
  popd
fi
chown -R "$user" "$CONFIG_DIR"

if killall Fcitx5; then
  echo killed previously-installed Fctix5
  exit 0
fi

./register_im
su -m "$user" -c ./enable_im
