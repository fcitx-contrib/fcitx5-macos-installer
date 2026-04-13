cmake_minimum_required(VERSION 4.3)

set(CMAKE_OSX_DEPLOYMENT_TARGET 13.3)
set(CMAKE_Swift_COMPILER_TARGET "${CMAKE_OSX_ARCHITECTURES}-apple-macos${CMAKE_OSX_DEPLOYMENT_TARGET}")

project(fcitx5-macos-installer LANGUAGES Swift)

list(PREPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")

add_compile_options(-target "${CMAKE_Swift_COMPILER_TARGET}")
add_link_options(-target "${CMAKE_Swift_COMPILER_TARGET}")
set(CMAKE_Swift_LANGUAGE_VERSION 6)

set(APP_NAME Fcitx5Installer)
add_subdirectory(deps)
add_subdirectory(src)
add_subdirectory(im)
