cmake_minimum_required(VERSION 3.27)

project(fcitx5-macos-installer LANGUAGES Swift)

list(PREPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

set(CMAKE_OSX_DEPLOYMENT_TARGET 13)
add_definitions(-target "${CMAKE_OSX_ARCHITECTURES}-apple-macos${CMAKE_OSX_DEPLOYMENT_TARGET}")

set(APP_NAME Fcitx5Installer)
add_subdirectory(deps)
add_subdirectory(src)
add_subdirectory(im)
