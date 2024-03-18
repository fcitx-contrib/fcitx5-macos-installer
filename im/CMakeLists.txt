add_executable(register_im register_im.swift)
add_dependencies(register_im "${APP_NAME}")

add_executable(enable_im enable_im.swift)
add_dependencies(enable_im "${APP_NAME}")
