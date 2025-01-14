# This file is part of the ios-cmake project. It was retrieved from
# https://github.com/cristeab/ios-cmake.git, which is a fork of
# https://code.google.com/p/ios-cmake/. Which in turn is based off of
# the Platform/Darwin.cmake and Platform/UnixPaths.cmake files which
# are included with CMake 2.8.4
#
# The ios-cmake project is licensed under the new BSD license.
#
# Copyright (c) 2014, Bogdan Cristea and LTE Engineering Software,
# Kitware, Inc., Insight Software Consortium.  All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# This file is based off of the Platform/Darwin.cmake and
# Platform/UnixPaths.cmake files which are included with CMake 2.8.4
# It has been altered for iOS development.
#
# Updated by Alex Stewart (alexs.mac@gmail.com).
# The following variables control the behaviour of this toolchain:
#
# IOS_PLATFORM: OS (default) or SIMULATOR or SIMULATOR64
#    OS = Build for iPhoneOS.
#    SIMULATOR = Build for x86 i386 iPhone Simulator.
#    SIMULATOR64 = Build for x86 x86_64 iPhone Simulator.
# CMAKE_OSX_SYSROOT: Path to the iOS SDK to use.  By default this is
#    automatically determined from IOS_PLATFORM and xcodebuild, but
#    can also be manually specified (although this should not be required).
# CMAKE_IOS_DEVELOPER_ROOT: Path to the Developer directory for the iOS platform
#    being compiled for.  By default this is automatically determined from
#    CMAKE_OSX_SYSROOT, but can also be manually specified (although this should
#    not be required).
#
# This toolchain defines the following variables for use externally:
#
# XCODE_VERSION: Version number (not including Build version) of Xcode detected.
# IOS_SDK_VERSION: Version of iOS SDK being used.
# CMAKE_OSX_ARCHITECTURES: Architectures being compiled for (generated from
#    IOS_PLATFORM).
#
# This toolchain defines the following macros for use externally:
#
# set_xcode_property (TARGET XCODE_PROPERTY XCODE_VALUE)
#   A convenience macro for setting xcode specific properties on targets
#   example: set_xcode_property (myioslib IPHONEOS_DEPLOYMENT_TARGET "3.1").
#
# find_host_package (PROGRAM ARGS)
#   A macro used to find executable programs on the host system, not within the
#   iOS environment.  Thanks to the android-cmake project for providing the
#   command.
# Get the Xcode version being used.
execute_process(COMMAND xcodebuild -version
  OUTPUT_VARIABLE XCODE_VERSION
  ERROR_QUIET
  OUTPUT_STRIP_TRAILING_WHITESPACE)
string(REGEX MATCH "Xcode [0-9\\.]+" XCODE_VERSION "${XCODE_VERSION}")
string(REGEX REPLACE "Xcode ([0-9\\.]+)" "\\1" XCODE_VERSION "${XCODE_VERSION}")
message(STATUS "Building with Xcode version: ${XCODE_VERSION}")
# Default to building for iPhoneOS if not specified otherwise, and we cannot
# determine the platform from the CMAKE_OSX_ARCHITECTURES variable.  The use
# of CMAKE_OSX_ARCHITECTURES is such that try_compile() projects can correctly
# determine the value of IOS_PLATFORM from the root project, as
# CMAKE_OSX_ARCHITECTURES is propagated to them by CMake.
if (NOT DEFINED IOS_PLATFORM)
  if (CMAKE_OSX_ARCHITECTURES)
    if (CMAKE_OSX_ARCHITECTURES MATCHES ".*arm.*")
      set(IOS_PLATFORM "OS")
    elseif (CMAKE_OSX_ARCHITECTURES MATCHES "i386")
      set(IOS_PLATFORM "SIMULATOR")
    elseif (CMAKE_OSX_ARCHITECTURES MATCHES "x86_64")
      set(IOS_PLATFORM "SIMULATOR64")
    endif()
  endif()
  if (NOT IOS_PLATFORM)
    set(IOS_PLATFORM "OS")
  endif()
endif()
set(IOS_PLATFORM ${IOS_PLATFORM} CACHE STRING
  "Type of iOS platform for which to build.")
# Determine the platform name and architectures for use in xcodebuild commands
# from the specified IOS_PLATFORM name.
if (IOS_PLATFORM STREQUAL "OS")
  set(XCODE_IOS_PLATFORM iphoneos)
  set(IOS_ARCH armv7 armv7s arm64)
elseif (IOS_PLATFORM STREQUAL "SIMULATOR")
  set(XCODE_IOS_PLATFORM iphonesimulator)
  set(IOS_ARCH i386)
elseif(IOS_PLATFORM STREQUAL "SIMULATOR64")
  set(XCODE_IOS_PLATFORM iphonesimulator)
  set(IOS_ARCH x86_64)
else()
  message(FATAL_ERROR "Invalid IOS_PLATFORM: ${IOS_PLATFORM}")
endif()
# better value - let xcode decide
set (IOS_ARCH "$(ARCHS_STANDARD)")
message(STATUS "Configuring iOS build for platform: ${IOS_PLATFORM}, "
  "architecture(s): ${IOS_ARCH}")
# If user did not specify the SDK root to use, then query xcodebuild for it.
if (NOT CMAKE_OSX_SYSROOT)
  execute_process(COMMAND xcodebuild -version -sdk ${XCODE_IOS_PLATFORM} Path
    OUTPUT_VARIABLE CMAKE_OSX_SYSROOT
    ERROR_QUIET
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  message(STATUS "Using SDK: ${CMAKE_OSX_SYSROOT} for platform: ${IOS_PLATFORM}")
endif()
if (NOT EXISTS ${CMAKE_OSX_SYSROOT})
  message(FATAL_ERROR "Invalid CMAKE_OSX_SYSROOT: ${CMAKE_OSX_SYSROOT} "
    "does not exist.")
endif()
# Get the SDK version information.
execute_process(COMMAND xcodebuild -sdk ${CMAKE_OSX_SYSROOT} -version SDKVersion
  OUTPUT_VARIABLE IOS_SDK_VERSION
  ERROR_QUIET
  OUTPUT_STRIP_TRAILING_WHITESPACE)

# Find the Developer root for the specific iOS platform being compiled for
# from CMAKE_OSX_SYSROOT.  Should be ../../ from SDK specified in
# CMAKE_OSX_SYSROOT.  There does not appear to be a direct way to obtain
# this information from xcrun or xcodebuild.
if (NOT CMAKE_IOS_DEVELOPER_ROOT)
  get_filename_component(IOS_PLATFORM_SDK_DIR ${CMAKE_OSX_SYSROOT} PATH)
  get_filename_component(CMAKE_IOS_DEVELOPER_ROOT ${IOS_PLATFORM_SDK_DIR} PATH)
endif()
if (NOT EXISTS ${CMAKE_IOS_DEVELOPER_ROOT})
  message(FATAL_ERROR "Invalid CMAKE_IOS_DEVELOPER_ROOT: "
    "${CMAKE_IOS_DEVELOPER_ROOT} does not exist.")
endif()
# Find the C & C++ compilers for the specified SDK.
if (NOT CMAKE_C_COMPILER)
  execute_process(COMMAND xcrun -sdk ${CMAKE_OSX_SYSROOT} -find clang
    OUTPUT_VARIABLE CMAKE_C_COMPILER
    ERROR_QUIET
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  message(STATUS "Using C compiler: ${CMAKE_C_COMPILER}")
endif()
if (NOT CMAKE_CXX_COMPILER)
  execute_process(COMMAND xcrun -sdk ${CMAKE_OSX_SYSROOT} -find clang++
    OUTPUT_VARIABLE CMAKE_CXX_COMPILER
    ERROR_QUIET
    OUTPUT_STRIP_TRAILING_WHITESPACE)
  message(STATUS "Using CXX compiler: ${CMAKE_CXX_COMPILER}")
endif()
# Find (Apple's) libtool.
execute_process(COMMAND xcrun -sdk ${CMAKE_OSX_SYSROOT} -find libtool
  OUTPUT_VARIABLE IOS_LIBTOOL
  ERROR_QUIET
  OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS "Using libtool: ${IOS_LIBTOOL}")
# Configure libtool to be used instead of ar + ranlib to build static libraries.
# This is required on Xcode 7+, but should also work on previous versions of
# Xcode.
set(CMAKE_C_CREATE_STATIC_LIBRARY
  "${IOS_LIBTOOL} -static -o <TARGET> <LINK_FLAGS> <OBJECTS> ")
set(CMAKE_CXX_CREATE_STATIC_LIBRARY
  "${IOS_LIBTOOL} -static -o <TARGET> <LINK_FLAGS> <OBJECTS> ")
# Get the version of Darwin (OS X) of the host.
execute_process(COMMAND uname -r
  OUTPUT_VARIABLE CMAKE_HOST_SYSTEM_VERSION
  ERROR_QUIET
  OUTPUT_STRIP_TRAILING_WHITESPACE)
# Standard settings.
set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_VERSION ${IOS_SDK_VERSION})
set(UNIX TRUE)
set(APPLE TRUE)
set(IOS TRUE)
# Force unset of OS X-specific deployment target (otherwise autopopulated),
# required as of cmake 2.8.10.
set(CMAKE_OSX_DEPLOYMENT_TARGET "" CACHE STRING
  "Must be empty for iOS builds." FORCE)
# Set the architectures for which to build.
set (CMAKE_OSX_ARCHITECTURES ${IOS_ARCH} CACHE STRING "Build architecture for iOS")
# Skip the platform compiler checks for cross compiling.
set(CMAKE_CXX_COMPILER_FORCED TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_C_COMPILER_WORKS TRUE)
# All iOS/Darwin specific settings - some may be redundant.
set(CMAKE_SHARED_LIBRARY_PREFIX "lib")
set(CMAKE_SHARED_LIBRARY_SUFFIX ".dylib")
set(CMAKE_SHARED_MODULE_PREFIX "lib")
set(CMAKE_SHARED_MODULE_SUFFIX ".so")
set(CMAKE_MODULE_EXISTS 1)
set(CMAKE_DL_LIBS "")
set(CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG "-compatibility_version ")
set(CMAKE_C_OSX_CURRENT_VERSION_FLAG "-current_version ")
set(CMAKE_CXX_OSX_COMPATIBILITY_VERSION_FLAG "${CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG}")
set(CMAKE_CXX_OSX_CURRENT_VERSION_FLAG "${CMAKE_C_OSX_CURRENT_VERSION_FLAG}")
# Specify minimum version of deployment target.
# Unless specified, the latest SDK version is used by default.
set(CMAKE_C_FLAGS
  "${XCODE_IOS_PLATFORM_VERSION_FLAGS} -fobjc-abi-version=2 -fobjc-arc ${CMAKE_C_FLAGS}")
# Hidden visibilty is required for C++ on iOS.
set(CMAKE_CXX_FLAGS
  "${XCODE_IOS_PLATFORM_VERSION_FLAGS} -fvisibility=hidden -fvisibility-inlines-hidden -fobjc-abi-version=2 -fobjc-arc ${CMAKE_CXX_FLAGS}")
set(CMAKE_CXX_FLAGS_RELEASE "-DNDEBUG -O3 -fomit-frame-pointer -ffast-math ${CMAKE_CXX_FLAGS_RELEASE}")
set(CMAKE_C_LINK_FLAGS "${XCODE_IOS_PLATFORM_VERSION_FLAGS} -Wl,-search_paths_first ${CMAKE_C_LINK_FLAGS}")
set(CMAKE_CXX_LINK_FLAGS "${XCODE_IOS_PLATFORM_VERSION_FLAGS}  -Wl,-search_paths_first ${CMAKE_CXX_LINK_FLAGS}")
# In order to ensure that the updated compiler flags are used in try_compile()
# tests, we have to forcibly set them in the CMake cache, not merely set them
# in the local scope.
list(APPEND VARS_TO_FORCE_IN_CACHE
  CMAKE_C_FLAGS
  CMAKE_CXX_FLAGS
  CMAKE_CXX_RELEASE
  CMAKE_C_LINK_FLAGS
  CMAKE_CXX_LINK_FLAGS)
foreach(VAR_TO_FORCE ${VARS_TO_FORCE_IN_CACHE})
  set(${VAR_TO_FORCE} "${${VAR_TO_FORCE}}" CACHE STRING "" FORCE)
endforeach()
set(CMAKE_PLATFORM_HAS_INSTALLNAME 1)
set(CMAKE_SHARED_LIBRARY_CREATE_C_FLAGS "-dynamiclib -headerpad_max_install_names")
set(CMAKE_SHARED_MODULE_CREATE_C_FLAGS "-bundle -headerpad_max_install_names")
set(CMAKE_SHARED_MODULE_LOADER_C_FLAG "-Wl,-bundle_loader,")
set(CMAKE_SHARED_MODULE_LOADER_CXX_FLAG "-Wl,-bundle_loader,")
set(CMAKE_FIND_LIBRARY_SUFFIXES ".dylib" ".so" ".a")
# Hack: if a new cmake (which uses CMAKE_INSTALL_NAME_TOOL) runs on an old
# build tree (where install_name_tool was hardcoded) and where
# CMAKE_INSTALL_NAME_TOOL isn't in the cache and still cmake didn't fail in
# CMakeFindBinUtils.cmake (because it isn't rerun) hardcode
# CMAKE_INSTALL_NAME_TOOL here to install_name_tool, so it behaves as it did
# before, Alex.
if (NOT DEFINED CMAKE_INSTALL_NAME_TOOL)
  find_program(CMAKE_INSTALL_NAME_TOOL install_name_tool)
endif (NOT DEFINED CMAKE_INSTALL_NAME_TOOL)
# Set the find root to the iOS developer roots and to user defined paths.
set(CMAKE_FIND_ROOT_PATH ${CMAKE_IOS_DEVELOPER_ROOT} ${CMAKE_OSX_SYSROOT}
  ${CMAKE_PREFIX_PATH} CACHE STRING  "iOS find search path root" FORCE)
# Default to searching for frameworks first.
set(CMAKE_FIND_FRAMEWORK FIRST)
# Set up the default search directories for frameworks.
set(CMAKE_SYSTEM_FRAMEWORK_PATH
  ${CMAKE_OSX_SYSROOT}/System/Library/Frameworks
  ${CMAKE_OSX_SYSROOT}/System/Library/PrivateFrameworks
  ${CMAKE_OSX_SYSROOT}/Developer/Library/Frameworks)
# Only search the specified iOS SDK, not the remainder of the host filesystem.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
# This little macro lets you set any XCode specific property.
macro(set_xcode_property TARGET XCODE_PROPERTY XCODE_VALUE)
  set_property(TARGET ${TARGET} PROPERTY
    XCODE_ATTRIBUTE_${XCODE_PROPERTY} ${XCODE_VALUE})
endmacro(set_xcode_property)
# This macro lets you find executable programs on the host system.
macro(find_host_package)
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER)
  set(IOS FALSE)
  find_package(${ARGN})
  set(IOS TRUE)
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endmacro(find_host_package)
