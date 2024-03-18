#!/bin/zsh
set -xeu

date
setopt NULL_GLOB

user="$1"
Resources="$2"
ARCH="$(uname -m)"
INSTALL_DIR="/Library/Input Methods"
APP_DIR="$INSTALL_DIR/Fcitx5.app"
DATA_DIR="/Users/$user/Library/fcitx5"
CONFIG_DIR="/Users/$user/.config/fcitx5"

cd "$Resources"
mkdir -p "$INSTALL_DIR"
rm -rf "$APP_DIR"
tar xjvf "Fcitx5-$ARCH.tar.bz2" -C "$INSTALL_DIR"
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
fi

./register_im
su -m "$user" -c ./enable_im
