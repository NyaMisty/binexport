# Copyright 2011-2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function(binexport_check_target target)
  if(NOT TARGET ${target})
    message(FATAL_ERROR
      "Compiling ${PROJECT_NAME} requires a ${target} CMake "
      "target in your project")
  endif()
endfunction()

include(FetchContent)

# Googletest
FetchContent_Declare(googletest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG        b1fbd33c06cdb0024c67733c6fdec2009d17b384 # 2020-11-24
)
FetchContent_MakeAvailable(googletest)
binexport_check_target(gtest)
binexport_check_target(gtest_main)
binexport_check_target(gmock)

# Abseil
FetchContent_Declare(absl
  GIT_REPOSITORY https://github.com/abseil/abseil-cpp
  GIT_TAG        592924480acf034aec0454160492a20bccdbdf3e # 2020-12-01
)
set(ABSL_CXX_STANDARD ${CMAKE_CXX_STANDARD} CACHE STRING "" FORCE)
set(ABSL_USE_EXTERNAL_GOOGLETEST ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(absl)
binexport_check_target(absl::core_headers)

# Protocol Buffers
FetchContent_Declare(protobuf
  GIT_REPOSITORY https://github.com/protocolbuffers/protobuf.git
  GIT_TAG        e8906e4ecd9e75f7c438afc317c99f82441c138a # 2020-12-02
  GIT_SUBMODULES "cmake" # Workaround for CMake #20579
  SOURCE_SUBDIR  cmake
)
set(protobuf_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(protobuf_BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(protobuf_WITH_ZLIB OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(protobuf)
binexport_check_target(protobuf::libprotobuf)
binexport_check_target(protobuf::protoc)
set(Protobuf_INCLUDE_DIR "${protobuf_SOURCE_DIR}/src" CACHE INTERNAL "")
set(Protobuf_LIBRARIES protobuf::libprotobuf CACHE INTERNAL "")
find_package(Protobuf 3.14 REQUIRED) # Make protobuf_generate_cpp available

# Binary Ninja API
if(BINEXPORT_ENABLE_BINARYNINJA)
  if(BINEXPORT_BINARYNINJA_CHANNEL STREQUAL "stable")
    set(_binexport_binaryninjacore_suffix "_stable")
    set(_binexport_binaryninja_git_tag
        "d5e3e8b3141fc742b0004a7c9549b28a33db18d0") # 2021-02-24
  else()
    set(_binexport_binaryninjacore_suffix "")
    set(_binexport_binaryninja_git_tag
        "a39ee992ab54eddb4ce06c41e8d552e55bf4e0b2") # 2021-04-08
  endif()
  FetchContent_Declare(binaryninjaapi
    GIT_REPOSITORY https://github.com/Vector35/binaryninja-api.git
    GIT_TAG        ${_binexport_binaryninja_git_tag}
    GIT_SUBMODULES "docs" # Workaround for CMake #20579
  )
  FetchContent_GetProperties(binaryninjaapi)
  if(NOT binaryninjaapi_POPULATED)
    FetchContent_Populate(binaryninjaapi)  # For binaryninjaapi_SOURCE_DIR
  endif()
  add_library(binaryninjacore SHARED
    third_party/binaryninja_api/binaryninjacore${_binexport_binaryninjacore_suffix}.cc
  )
  set_target_properties(binaryninjacore PROPERTIES
    SOVERSION 1
  )
  target_include_directories(binaryninjacore PRIVATE
    "${binaryninjaapi_SOURCE_DIR}"
  )
  set(BN_CORE_LIBRARY binaryninjacore)
  set(HEADLESS TRUE)
  if(binaryninjaapi_POPULATED)
    add_subdirectory("${binaryninjaapi_SOURCE_DIR}" "${binaryninjaapi_BINARY_DIR}")
  endif()
  binexport_check_target(binaryninjaapi)
  add_library(BinaryNinja::API ALIAS binaryninjaapi)
endif()

# Boost (a subset that we ship)
set(Boost_NO_SYSTEM_PATHS TRUE)
set(BOOST_ROOT "${BINEXPORT_SOURCE_DIR}/third_party/boost_parts")
find_package(Boost 1.71 REQUIRED)

find_package(Git)
if(BINEXPORT_ENABLE_IDAPRO)
  find_package(IdaSdk REQUIRED)
endif()
