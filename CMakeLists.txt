cmake_minimum_required(VERSION 4.0)

project(fcitx5-macos-installer LANGUAGES Swift)

list(PREPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

set(CMAKE_OSX_DEPLOYMENT_TARGET 13)
set(F5M_TARGET "${CMAKE_OSX_ARCHITECTURES}-apple-macos${CMAKE_OSX_DEPLOYMENT_TARGET}")
add_compile_options(-target "${F5M_TARGET}")
add_link_options(-target "${F5M_TARGET}")

set(APP_NAME Fcitx5Installer)
add_subdirectory(deps)
add_subdirectory(src)
add_subdirectory(im)
