#!/bin/zsh
set -xeu

date 1>&2
setopt NULL_GLOB

user="$1"
Resources="$2"
ARCH="$(uname -m)"
INSTALL_DIR="/Library/Input Methods"
APP_DIR="$INSTALL_DIR/Fcitx5.app"
RESOURCES_DIR="$APP_DIR/Contents/Resources"
DATA_DIR="/Users/$user/Library/fcitx5"
CONFIG_DIR="/Users/$user/.config/fcitx5"

cd "$Resources"
mkdir -p "$INSTALL_DIR"
rm -rf "$APP_DIR/Contents/*"
tar xjvf "Fcitx5-$ARCH.tar.bz2" -C "$INSTALL_DIR"

major_version=$(sw_vers -productVersion | cut -d. -f1)
if (( major_version >= 26 )); then
  cp "$RESOURCES_DIR/menu_icon_26.pdf" "$RESOURCES_DIR/menu_icon.pdf"
else
  cp "$RESOURCES_DIR/menu_icon_15.pdf" "$RESOURCES_DIR/menu_icon.pdf"
fi

xattr -dr com.apple.quarantine "$APP_DIR"
codesign --force --sign - --deep "$APP_DIR"

mkdir -p "$DATA_DIR"
for plugin_path in plugins/*-{$ARCH,any}.tar.bz2; do
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
