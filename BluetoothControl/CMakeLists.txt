# BluetoothControl/CMakeLists.txt

cmake_minimum_required(VERSION 3.16)

project(BluetoothControlLib LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find necessary Qt modules.
find_package(Qt6 REQUIRED COMPONENTS Bluetooth Core Gui)

# Define this as a library. Use SHARED for a dynamic library, STATIC for a static one.
# SHARED is generally more flexible for subdirectories.
add_library(BluetoothControl SHARED # Changed from add_executable
  chatserver.h chatserver.cpp
)

# Link the library against Qt modules.
target_link_libraries(BluetoothControl PRIVATE
  Qt6::Bluetooth
  Qt6::Gui
  Qt6::Core
)
