import Carbon

let url = URL(fileURLWithPath: "/Library/Input Methods/Fcitx5.app")
TISRegisterInputSource(url as CFURL)
