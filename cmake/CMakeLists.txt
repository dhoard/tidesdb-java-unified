cmake_minimum_required(VERSION 3.25)
project(tidesdb-jni C CXX)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(BUILD_SHARED_LIBS OFF)

# --- Compression libraries (built from cloned source, static, PIC) ---
# These must be built BEFORE tidesdb so its CMake can find the targets.

# zstd
set(ZSTD_BUILD_PROGRAMS OFF CACHE BOOL "")
set(ZSTD_BUILD_CONTRIB OFF CACHE BOOL "")
set(ZSTD_BUILD_TESTS OFF CACHE BOOL "")
set(ZSTD_BUILD_STATIC ON CACHE BOOL "")
set(ZSTD_BUILD_SHARED OFF CACHE BOOL "")
add_subdirectory(${ZSTD_SOURCE_DIR}/build/cmake zstd_build)

# lz4
set(LZ4_BUILD_CLI OFF CACHE BOOL "")
set(LZ4_BUILD_LEGACY_LZ4C OFF CACHE BOOL "")
set(BUILD_STATIC_LIBS ON CACHE BOOL "")
add_subdirectory(${LZ4_SOURCE_DIR}/build/cmake lz4_build)

# snappy
set(SNAPPY_BUILD_TESTS OFF CACHE BOOL "")
set(SNAPPY_BUILD_BENCHMARKS OFF CACHE BOOL "")
set(SNAPPY_INSTALL OFF CACHE BOOL "")
add_subdirectory(${SNAPPY_SOURCE_DIR} snappy_build)

# --- TidesDB (built as static library, with compression from above) ---
set(TIDESDB_WITH_ZSTD ON CACHE BOOL "")
set(TIDESDB_WITH_LZ4 ON CACHE BOOL "")
set(TIDESDB_WITH_SNAPPY ON CACHE BOOL "")
set(TIDESDB_BUILD_TESTS OFF CACHE BOOL "")
set(TIDESDB_WITH_SANITIZER OFF CACHE BOOL "")
set(ENABLE_READ_PROFILING OFF CACHE BOOL "")

# Provide find targets so TidesDB's CMake resolves our static builds
add_library(zstd::libzstd_shared ALIAS libzstd_static)
add_library(lz4::lz4_shared ALIAS lz4_static)
add_library(Snappy::snappy_shared ALIAS snappy)

add_subdirectory(${TIDESDB_SOURCE_DIR} tidesdb_build)

# --- JNI shared library ---
find_package(JNI REQUIRED)

add_library(tidesdb_jni SHARED
    ${TIDESDB_JAVA_SOURCE_DIR}/src/main/c/com_tidesdb_TidesDB.c
)

target_include_directories(tidesdb_jni BEFORE PRIVATE
    ${TIDESDB_SOURCE_DIR}/src
    ${TIDESDB_SOURCE_DIR}/external
    ${JNI_INCLUDE_DIRS}
)

target_link_libraries(tidesdb_jni PRIVATE
    tidesdb
    libzstd_static
    lz4_static
    snappy
    ${JNI_LIBRARIES}
)

# --- Linux-specific ---
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_link_libraries(tidesdb_jni PRIVATE
        -static-libgcc -static-libstdc++
    )
endif()

# --- Strip release builds ---
if(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_custom_command(TARGET tidesdb_jni POST_BUILD
        COMMAND ${CMAKE_STRIP} --strip-unneeded $<TARGET_FILE:tidesdb_jni>
    )
endif()
