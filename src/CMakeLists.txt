set(APP_PATH "${CMAKE_CURRENT_BINARY_DIR}/${APP_NAME}.app/Contents")

add_executable("${APP_NAME}"
    MACOSX_BUNDLE
    entry.swift
    view.swift
    meta.swift
)

add_custom_command(TARGET "${APP_NAME}" POST_BUILD
    COMMAND mkdir -p "${APP_PATH}/Resources"
    COMMAND cp assets/fcitx.icns "${APP_PATH}/Resources"
    COMMAND cp install.sh "${APP_PATH}/Resources"
    COMMAND rm -f "${APP_PATH}/MacOS/${APP_NAME}.d"
    WORKING_DIRECTORY ${PROJECT_SOURCE_DIR}
)
