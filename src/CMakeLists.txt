set(APP_PATH "${CMAKE_CURRENT_BINARY_DIR}/${APP_NAME}.app/Contents")

add_executable("${APP_NAME}"
    MACOSX_BUNDLE
    entry.swift
    view.swift
    meta.swift
)

target_link_libraries("${APP_NAME}"
    PRIVATE
    AlertToast
)
