# CMake target for compiling Pocket Swasth Native Inference C++ Engine
cmake_minimum_required(VERSION 3.18.1)

if(${ANDROID_ABI} STREQUAL "armeabi-v7a")
    message(WARNING "Skipping llama.cpp compilation for armeabi-v7a (32-bit) due to NEON incompatibilities.")
    add_library(native-lib SHARED native-lib.cpp)
    find_library(log-lib log)
    target_link_libraries(native-lib ${log-lib})
    return()
endif()

# Include llama.cpp subdirectory to compile the neural network engine
add_subdirectory(llama_cpp)

# Declare target library name and source files
add_library(
        native-lib
        SHARED
        native-lib.cpp
)

# Find Android NDK logging libraries
find_library(
        log-lib
        log
)

# Link native-lib with target log libraries and the new llama engine
target_link_libraries(
        native-lib
        ${log-lib}
        llama
)
