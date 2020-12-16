#  Pharo Virtual Machine
#
#  Available Targets:
#
#  vmmaker: generates a Pharo development environment with the virtual machine code, Slang transpiler and machine code simulation
#  generate-sources: generates the virtual machine source code in C, using the Slang-to-C transpiler

cmake_minimum_required(VERSION 3.7.2)
# Use new and simpler escape sequences
cmake_policy(SET CMP0053 NEW)

include(macros.cmake)

set(VERSION_MAJOR 9)
set(VERSION_MINOR 0)
set(VERSION_PATCH 0)

set(APPNAME Pharo CACHE STRING "VM Application name")

# Configure CMake to load our modules
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Extract VCS information
get_commit_hash(GIT_COMMIT_HASH)
get_git_describe(GIT_DESCRIBE)
get_git_date(GIT_COMMIT_DATE)

#Variable used to set the VM date
set(BUILT_FROM "${GIT_DESCRIBE} - Commit: ${GIT_COMMIT_HASH} - Date: ${GIT_COMMIT_DATE}")
message(STATUS ${BUILT_FROM})

# Avoid using the d postfix to debug libraries
# Otherwise, debug libraries change name and breaks FFI bindings
set(CMAKE_DEBUG_POSTFIX "")

#Configure toolchain for CYGWIN
if ((CMAKE_HOST_UNIX) AND (${CMAKE_HOST_SYSTEM_NAME} MATCHES "CYGWIN*"))
  message(STATUS "Building on CYGWIN CMAKE: Adapting paths")
  set(CYGWIN 1)
  set(WIN 1)

  # specify the cross compiler
  set(CMAKE_TOOLCHAIN_PREFIX x86_64-w64-mingw32)
  
  SET(CMAKE_C_COMPILER   ${CMAKE_TOOLCHAIN_PREFIX}-clang)
  SET(CMAKE_CXX_COMPILER ${CMAKE_TOOLCHAIN_PREFIX}-clang++)
  SET(CMAKE_RC_COMPILER ${CMAKE_TOOLCHAIN_PREFIX}-windres)
  SET(CMAKE_SYSTEM_PROCESSOR x86_64)
endif()

#Set up the project
#This needs to be at this point, after setting the toolchain configuration
project(PharoVM)

# Correctly set the system processor under MSVC
# This is required because CMake will set the HOST_PROCESSOR in windows
# And not care about our Visual Studio settings
# See https://gitlab.kitware.com/cmake/cmake/-/issues/15170
if (MSVC)
    set(CMAKE_SYSTEM_PROCESSOR ${MSVC_CXX_ARCHITECTURE_ID})
endif()
message(STATUS "Compiling for architecture: ${CMAKE_SYSTEM_PROCESSOR}")


set(FLAVOUR CoInterpreter CACHE STRING "The kind of VM to generate. Possible values: StackVM, CoInterpreter")
set(GENERATE_SOURCES TRUE CACHE BOOL "If it generates the sources")
set(ALWAYS_INTERACTIVE FALSE CACHE BOOL "If this VM will always add interactive or not. If it is set, the headless parameter is not by default true")
set(FEATURE_FFI TRUE CACHE BOOL "Configure and compile support for FFI in the VM")
set(FEATURE_NETWORK TRUE CACHE BOOL "Configure and compile support for network and sockets in the VM")
set(FEATURE_COMPILE_GNUISATION TRUE CACHE BOOL "Use gcc gnu extensions to compile the VM")
set(FEATURE_COMPILE_INLINE_MEMORY_ACCESSORS TRUE CACHE BOOL "Use inline memory accessors instead of macros")

set(PHARO_DEPENDENCIES_PREFER_DOWNLOAD_BINARIES FALSE CACHE BOOL "Prefer downloading dependencies")
set(DOWNLOAD_DEPENDENCIES TRUE CACHE BOOL "Download dependencies at build time")
set(FEATURE_LIB_SDL2 TRUE CACHE BOOL "Build SDL2 support")
set(FEATURE_LIB_CAIRO TRUE CACHE BOOL "Build Cairo support")
set(FEATURE_LIB_FREETYPE2 TRUE CACHE BOOL "Build Cairo support")
set(FEATURE_LIB_GIT2 TRUE CACHE BOOL "Build LibGit2 support")

set(PHARO_LIBRARY_PATH "@executable_path/Plugins" CACHE STRING "The RPATH to use in the build")

# If we are generating sources, set the source dir as the generation source dir.
# Otherwise set it to by default to the current source dir, parametrizable
if(${GENERATE_SOURCES})
    set(GENERATED_SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR})
else()
    set(GENERATED_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR} CACHE STRING "Source directory where to find the generated source. Default value is CMAKE_CURRENT_SOURCE_DIR")
endif()

if (${FEATURE_COMPILE_INLINE_MEMORY_ACCESSORS})
    add_compile_definitions(USE_INLINE_MEMORY_ACCESSORS=1)
endif()


set(PLUGIN_GENERATED_FILES 
  	${GENERATED_SOURCE_DIR}/generated/plugins/src/FilePlugin/FilePlugin.c)


if(FLAVOUR MATCHES "CoInterpreter")
  add_compile_definitions(ASYNC_FFI_QUEUE=1)
endif()

# Configuration
include(CheckIncludeFiles)
include(CheckFunctionExists)
include(CheckSymbolExists)
include(CheckLibraryExists)
include(CheckTypeSize)
include(CheckCSourceCompiles)
include(CheckStructHasMember)
include(ExternalProject)

set(COMMON_FLAGS "")
set(BUILD_I386_VERSION NO)

if(MSVC)
    set(OS_TYPE "Win32")
    get_platform_name(VM_TARGET_OS)
    message(STATUS "Building for ${VM_TARGET_OS}")
elseif(WIN)
    message(STATUS "Building for WINDOWS")

    #Tell the system we are not in UNIX. This is required for Cygwin builds
    unset(UNIX)
    unset(UNIX CACHE)

  	# transform the path into a windows path with unix backslashes C:/bla/blu
  	# this is the path required to send as argument to libraries outside of the control of cygwin (like pharo itself)
  	execute_process(
          COMMAND cygpath ${CMAKE_CURRENT_SOURCE_DIR} --mixed
          OUTPUT_VARIABLE CMAKE_CURRENT_SOURCE_DIR_TO_OUT
          OUTPUT_STRIP_TRAILING_WHITESPACE)
    execute_process(
          COMMAND cygpath ${CMAKE_CURRENT_BINARY_DIR} --mixed
          OUTPUT_VARIABLE CMAKE_CURRENT_BINARY_DIR_TO_OUT
          OUTPUT_STRIP_TRAILING_WHITESPACE)

    set(CMAKE_SHARED_LIBRARY_PREFIX "")
    set(CMAKE_SHARED_LIBRARY_SUFFIX ".dll")
    set(CMAKE_SHARED_MODULE_PREFIX "")
    set(CMAKE_SHARED_MODULE_SUFFIX ".dll")


#    if(NOT MSVC)
        set(COMMON_FLAGS "-fwrapv -fdeclspec -msse2 -ggdb2 -m64 -mno-rtd -mms-bitfields -O2 -momit-leaf-frame-pointer -funroll-loops -D_MT -fno-builtin-printf -fno-builtin-putchar -fno-builtin-fprintf -Wall -Wno-unused-variable -fno-optimize-sibling-calls")
#    endif()

    set(OS_TYPE "Win32")
    set(VM_TARGET_OS "Win64")

    # this one is important
    SET(CMAKE_SYSTEM_NAME Windows)

    add_compile_definitions(NO_ISNAN NO_SERVICE "'VM_LABEL(foo)=0'" LSB_FIRST=1 AllocationCheckFiller=0xADD4E55)

    #Setting minimal Windows Version to VISTA
    add_compile_definitions(_WIN32_WINNT=0x0600 WINVER=0x0600 NTDDI_VERSION=0x06000000 WIN64=1)

elseif(UNIX)

    # Use the default path to send as argument of extrernal apps (like pharo itself)
    set(CMAKE_CURRENT_SOURCE_DIR_TO_OUT ${CMAKE_CURRENT_SOURCE_DIR})
    set(CMAKE_CURRENT_BINARY_DIR_TO_OUT ${CMAKE_CURRENT_BINARY_DIR})

    set(COMMON_FLAGS "-O2 -Wall -Werror=implicit-function-declaration")

    add_compile_definitions(LSB_FIRST=1)

    set(OS_TYPE "unix")
    if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
        set(OSX 1)
        set(OS_TYPE "Mac OS")
        set(VM_TARGET_OS "1000") # Used to recognise OS X

        set(COMMON_FLAGS "-stdlib=libc++ -mmacosx-version-min=10.7 ${COMMON_FLAGS}")

    elseif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
        set(VM_TARGET_OS "linux-gnu")
    else()
        set(VM_TARGET_OS "${CMAKE_SYSTEM_NAME}")
    endif()
endif()

set(OPTIMIZATION_FLAGS "")

set(CMAKE_C_FLAGS "-g ${COMMON_FLAGS} ${OPTIMIZATION_FLAGS} -DNDEBUG -DDEBUGVM=0")
set(CMAKE_CXX_FLAGS "-g ${COMMON_FLAGS} ${OPTIMIZATION_FLAGS} -DNDEBUG -DDEBUGVM=0")

add_compile_definitions(IMMUTABILITY=1)
add_compile_definitions(COGMTVM=0)
add_compile_definitions(PharoVM=1)

#We require that VM_LABEL does nothing.
#We should actually cleanup all the places where this is set/used in the VM
add_compile_definitions("VM_LABEL\(foo\)=0")

#
# This definition is used to improve the logging of the messages, to cut-down the path
# of the source files in the compilation of debug messages.
#
# The additional / is important to remove the last character from the path.
# Note that it does not matter if the OS uses / or \, because we are only
# saving the path size.
string(LENGTH "${CMAKE_SOURCE_DIR}/" SOURCE_PATH_SIZE)
add_compile_definitions("SOURCE_PATH_SIZE=${SOURCE_PATH_SIZE}")

if(UNIX AND NOT OSX AND NOT WIN)
    set(VM_EXECUTABLE_NAME pharo CACHE STRING "VM Executable name")
else()
    set(VM_EXECUTABLE_NAME Pharo CACHE STRING "VM Executable name")
endif()

message(STATUS "Building ${APPNAME} with executable named ${VM_EXECUTABLE_NAME}")

set(VM_LIBRARY_NAME ${APPNAME}VMCore)
set(VM_NAME ${APPNAME})
set(PHARO_VM TRUE)
set(DEFAULT_IMAGE_NAME ${APPNAME}.image)

set(VM_TARGET "${CMAKE_SYSTEM}")

#Change to the correct CPU
set(VM_TARGET_CPU "x86_64")

# Type sizes
if(BUILD_I386_VERSION)
	set(SIZEOF_INT 4)
	set(SIZEOF_LONG 4)
	set(SIZEOF_LONG_LONG 8)
	set(SIZEOF_VOID_P 4)
else()
   	check_type_size("int" SIZEOF_INT)
    check_type_size("long" SIZEOF_LONG)
    check_type_size("long long" SIZEOF_LONG_LONG)
    check_type_size("void*" SIZEOF_VOID_P)
endif()

message(STATUS "int ${SIZEOF_INT}")
message(STATUS "long ${SIZEOF_LONG}")
message(STATUS "long long ${SIZEOF_LONG_LONG}")
message(STATUS "void* ${SIZEOF_VOID_P}")

if("${SIZEOF_LONG}" STREQUAL "8")
	set(SQUEAK_INT64_TYPEDEF "long")
elseif("${SIZEOF_LONG_LONG}" STREQUAL "8")
	set(SQUEAK_INT64_TYPEDEF "long long")
else()
	message(FATAL_ERROR "Failed to find a 64 bits integer type.")
endif()

set(EXECUTABLE_OUTPUT_PATH "${CMAKE_CURRENT_BINARY_DIR}/build/vm")

#If in OSX, configure creation of Bundle
if (OSX)
  set(EXECUTABLE_OUTPUT_PATH "build/vm/Debug")
  set(RUNTIME_OUTPUT_PATH "build/vm/")
  set(LIBRARY_OUTPUT_DIRECTORY "build/vm/Debug/${VM_EXECUTABLE_NAME}.app/Contents/MacOS/Plugins")
else()
  set(LIBRARY_OUTPUT_DIRECTORY ${EXECUTABLE_OUTPUT_PATH})
endif()
set(LIBRARY_OUTPUT_PATH ${LIBRARY_OUTPUT_DIRECTORY})
message(STATUS "Writing libraries to: ${LIBRARY_OUTPUT_DIRECTORY}")

#make_directory(${LIBRARY_OUTPUT_PATH})

check_include_files(dirent.h HAVE_DIRENT_H)
check_include_files(features.h HAVE_FEATURES_H)
check_include_files(unistd.h HAVE_UNISTD_H)
check_include_files(ndir.h HAVE_NDIR_H)
check_include_files(sys/ndir.h HAVE_SYS_NDIR_H)
check_include_files(sys/dir.h HAVE_SYS_DIR_H)
check_include_files(sys/filio.h HAVE_SYS_FILIO_H)
check_include_files(sys/time.h HAVE_SYS_TIME_H)
check_include_files(execinfo.h HAVE_EXECINFO_H)

check_include_files(dlfcn.h HAVE_DLFCN_H)
check_library_exists(dl dlopen "" HAVE_LIBDL)
check_library_exists(dyld dlopen "" HAVE_DYLD)
check_struct_has_member("struct tm" tm_gmtoff time.h HAVE_TM_GMTOFF)

#Required by the UUID Plugin

check_include_files(sys/uuid.h HAVE_SYS_UUID_H)
check_include_files(uuid/uuid.h HAVE_UUID_UUID_H)
check_include_files(uuid.h HAVE_UUID_H)
check_library_exists(uuid uuidgen "" HAVE_UUIDGEN)
check_library_exists(uuid uuid_generate "" HAVE_UUID_GENERATE)


#Include targets to build the dev environment and the sources
include(cmake/vmmaker.cmake)

#Generating config file
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/include/pharovm/config.h.in ${CMAKE_CURRENT_BINARY_DIR}/build/include/pharovm/config.h)

message(STATUS "C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "C++ Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "Resource Compiler: ${CMAKE_RC_COMPILER}")

set(VM_FRONTEND_APPLICATION_TYPE)
include(cmake/${CMAKE_SYSTEM_NAME}.cmake)

set(GENERATED_SOURCES ${VMSOURCEFILES})

set(SUPPORT_SOURCES	
	${CMAKE_CURRENT_SOURCE_DIR}/src/debug.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/utils.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/errorCode.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/nullDisplay.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/externalPrimitives.c
	${CMAKE_CURRENT_SOURCE_DIR}/src/client.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/pathUtilities.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/parameterVector.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/parameters.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/fileDialogCommon.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/stringUtilities.c
    ${CMAKE_CURRENT_SOURCE_DIR}/src/imageAccess.c
    
    ${CMAKE_CURRENT_SOURCE_DIR}/src/semaphores/platformSemaphore.c

    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/common/heartbeat.c
)

if(${FEATURE_FFI})
    list (APPEND SUPPORT_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/ffi/src/functionDefinitionPrimitives.c
        ${CMAKE_CURRENT_SOURCE_DIR}/ffi/src/primitiveCalls.c
        ${CMAKE_CURRENT_SOURCE_DIR}/ffi/src/primitiveUtils.c
        ${CMAKE_CURRENT_SOURCE_DIR}/ffi/src/types.c
        ${CMAKE_CURRENT_SOURCE_DIR}/ffi/src/typesPrimitives.c
        ${CMAKE_CURRENT_SOURCE_DIR}/ffi/src/utils.c

        # Single-threaded callout support
        ${CMAKE_CURRENT_SOURCE_DIR}/ffi/src/sameThread/sameThread.c
    
        # Callback support
        ${CMAKE_CURRENT_SOURCE_DIR}/ffi/src/callbacks/callbackPrimitives.c
        ${CMAKE_CURRENT_SOURCE_DIR}/ffi/src/callbacks/callbacks.c

        # Required by callbacks
        ${CMAKE_CURRENT_SOURCE_DIR}/src/semaphores/pharoSemaphore.c
        ${CMAKE_CURRENT_SOURCE_DIR}/src/threadSafeQueue/threadSafeQueue.c
    )
    if (${FEATURE_THREADED_FFI})
        list(APPEND SUPPORT_SOURCES
            ${CMAKE_CURRENT_SOURCE_DIR}/ffi/src/pThreadedFFI.c
            ${CMAKE_CURRENT_SOURCE_DIR}/ffi/src/worker/worker.c
            ${CMAKE_CURRENT_SOURCE_DIR}/ffi/src/worker/workerPrimitives.c
            ${CMAKE_CURRENT_SOURCE_DIR}/ffi/src/worker/workerTask.c
        )
    endif()
endif()


set(VM_SOURCES
    ${SUPPORT_SOURCES}
    ${GENERATED_SOURCES}
    ${EXTRACTED_SOURCES}
)

add_executable(${VM_EXECUTABLE_NAME} ${VM_FRONTEND_APPLICATION_TYPE} ${VM_FRONTEND_SOURCES})
addLibraryWithRPATH(${VM_LIBRARY_NAME} ${VM_SOURCES})

#
# LibFFI
#
if (${FEATURE_FFI})
    include(cmake/importLibFFI.cmake)
endif()

target_include_directories(${VM_LIBRARY_NAME}
PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/include
    ${CMAKE_CURRENT_BINARY_DIR}/build/include/pharovm/
    ${PHARO_CURRENT_GENERATED}/vm/include
PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include/semaphores
)
add_platform_headers()

if (${FEATURE_FFI})
    target_include_directories(${VM_LIBRARY_NAME}
        PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/ffi/include)
    target_compile_definitions(${VM_LIBRARY_NAME} 
        PRIVATE FEATURE_FFI=1)
endif()


#If in OSX, configure creation of Bundle
if(OSX)
  set_target_properties(
    ${VM_EXECUTABLE_NAME}
    PROPERTIES
    MACOSX_BUNDLE YES
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/resources/mac/Info.plist.in"
  )
endif()

target_link_libraries(${VM_EXECUTABLE_NAME} ${VM_LIBRARY_NAME})

add_required_libs_per_platform()

include(plugins.cmake)

add_subdirectory(ffiTestLibrary ${CMAKE_CURRENT_BINARY_DIR}/build/ffiTestLibrary)

# Handling Third party dependencies
add_third_party_dependencies_per_platform()

# Packaging Setup

include(cmake/packaging.cmake)
