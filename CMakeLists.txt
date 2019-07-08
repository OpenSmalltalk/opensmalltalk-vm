cmake_minimum_required(VERSION 2.8.4)

include(macros.cmake)

set(VERSION_MAJOR 8)
set(VERSION_MINOR 1)
set(VERSION_PATCH 0)

get_commit_hash(GIT_COMMIT_HASH)
get_git_describe(GIT_DESCRIBE)

set(BUILT_FROM "${GIT_DESCRIBE} - Commit: ${GIT_COMMIT_HASH}")

if(WIN32 OR WIN OR CYGWIN)
    set(WIN 1)

    # specify the cross compiler
    set(CMAKE_TOOLCHAIN_PREFIX x86_64-w64-mingw32)

    SET(CMAKE_C_COMPILER   ${CMAKE_TOOLCHAIN_PREFIX}-clang)
    SET(CMAKE_CXX_COMPILER ${CMAKE_TOOLCHAIN_PREFIX}-clang++)
    SET(CMAKE_RC_COMPILER ${CMAKE_TOOLCHAIN_PREFIX}-windres)
    SET(CMAKE_SYSTEM_PROCESSOR x86_64)
endif()

if(CYGWIN)

    # where is the target environment 
    SET(CMAKE_FIND_ROOT_PATH  /usr/x86_64-w64-mingw32/sys-root/mingw/)

    # search for programs in the build host directories
    SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
    # for libraries and headers in the target directories
    SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
    SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
    
endif()

if(MSVC)
   set(WIN 1)
endif()

project(PharoVM)

# Configuration
include(CheckIncludeFiles)
include(CheckFunctionExists)
include(CheckSymbolExists)
include(CheckLibraryExists)
include(CheckTypeSize)
include(CheckCSourceCompiles)
include(CheckStructHasMember)

set(COMMON_FLAGS "")
set(BUILD_I386_VERSION NO)

if(WIN)
    unset(UNIX)

    message(STATUS "Building for WINDOWS")

    set(CMAKE_SHARED_LIBRARY_PREFIX "")
    set(CMAKE_SHARED_LIBRARY_SUFFIX ".dll")
    set(CMAKE_SHARED_MODULE_PREFIX "")
    set(CMAKE_SHARED_MODULE_SUFFIX ".dll")    


    if(NOT MSVC)
        set(COMMON_FLAGS "-fdeclspec -msse2 -ggdb2 -m64 -mno-rtd -mms-bitfields -O1 -momit-leaf-frame-pointer -funroll-loops -D_MT -fno-builtin-printf -fno-builtin-putchar -fno-builtin-fprintf -Wall -Wno-unused-variable")
    endif()
    
    set(OS_TYPE "Win32")
    set(VM_TARGET_OS "Win64")

    # this one is important
    SET(CMAKE_SYSTEM_NAME Windows)

    add_definitions(-DLSB_FIRST=1)
    
    #Setting minimal Windows Version to VISTA
    add_definitions(-DWIN32 -D_WIN32_WINNT=0x0600 -DWINVER=0x0600 -DNTDDI_VERSION=0x06000000 -DWIN64=1)
    
elseif(UNIX)

    set(COMMON_FLAGS "")

    add_definitions(-DLSB_FIRST=1)

    set(OS_TYPE "unix")
    if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
        set(OSX 1)
        set(OS_TYPE "Mac OS")
        set(VM_TARGET_OS "1000") # Used to recognise OS X      
        
    elseif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
        set(VM_TARGET_OS "linux-gnu")
    else()
        set(VM_TARGET_OS "${CMAKE_SYSTEM_NAME}")
    endif()
endif()

set(OPTIMIZATION_FLAGS "")

set(CMAKE_C_FLAGS "-g ${COMMON_FLAGS} ${OPTIMIZATION_FLAGS} -DNDEBUG -DDEBUGVM=0")
set(CMAKE_CXX_FLAGS "-g ${COMMON_FLAGS} ${OPTIMIZATION_FLAGS} -DNDEBUG -DDEBUGVM=0")

add_definitions(-DPharoVM=1 -DIMMUTABILITY=1)

#
# This definition is used to improve the logging of the messages, to cut-down the path
# of the source files in the compilation of debug messages.
#
# The additional / is important to remove the last character from the path.
# Note that it does not matter if the OS uses / or \, because we are only
# saving the path size.
string(LENGTH "${CMAKE_SOURCE_DIR}/" SOURCE_PATH_SIZE)
add_definitions("-DSOURCE_PATH_SIZE=${SOURCE_PATH_SIZE}")

if(UNIX AND NOT OSX)
    set(VM_EXECUTABLE_NAME pharo)
else()
    set(VM_EXECUTABLE_NAME Pharo)
endif()

set(VM_LIBRARY_NAME PharoVMCore)
set(VM_NAME Pharo)
set(PHARO_VM TRUE)
set(DEFAULT_IMAGE_NAME Pharo.image)

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

#Setting output directories
set(EXECUTABLE_OUTPUT_PATH "build/vm")
set(LIBRARY_OUTPUT_PATH "build/vm")

check_include_files(dirent.h HAVE_DIRENT_H)
check_include_files(features.h HAVE_FEATURES_H)
check_include_files(unistd.h HAVE_UNISTD_H)
check_include_files(ndir.h HAVE_NDIR_H)
check_include_files(sys/ndir.h HAVE_SYS_NDIR_H)
check_include_files(sys/dir.h HAVE_SYS_DIR_H)
check_include_files(sys/filio.h HAVE_SYS_FILIO_H)
check_include_files(sys/time.h HAVE_SYS_TIME_H)

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

#Generating config file
configure_file(includes/config.h.in build/includes/config.h)
include_directories(build/includes)

message(STATUS "C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "C++ Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "Resource Compiler: ${CMAKE_RC_COMPILER}")


include_directories(
	includes
)

if(WIN)
    include(win.cmake)
elseif(OSX)
    include(osx.cmake)
elseif(UNIX)
    include(unix.cmake)
endif()

set(SUPPORT_SOURCES
	src/debug.c
	src/utils.c
	src/nullDisplay.c
	src/externalPrimitives.c
	src/client.c
)

set(VM_SOURCES
	${SUPPORT_SOURCES}
	${EXTRACTED_SOURCES}
)

addLibraryWithRPATH(${VM_LIBRARY_NAME} SHARED ${VM_SOURCES})
add_executable(${VM_EXECUTABLE_NAME} ${VM_FRONTEND_SOURCES})

target_link_libraries(${VM_EXECUTABLE_NAME} ${VM_LIBRARY_NAME})

if(NOT WIN AND UNIX AND OSX)
   target_link_libraries(${VM_EXECUTABLE_NAME} "-framework AppKit")
   target_link_libraries(${VM_EXECUTABLE_NAME} "-framework CoreGraphics")
endif()

if(NOT WIN AND UNIX AND NOT OSX)
   target_link_libraries(${VM_EXECUTABLE_NAME} dl)
   target_link_libraries(${VM_EXECUTABLE_NAME} m)
   target_link_libraries(${VM_EXECUTABLE_NAME} pthread)
endif()

if(WIN)
   target_link_libraries(${VM_LIBRARY_NAME} winmm)
   target_link_libraries(${VM_EXECUTABLE_NAME} Ole32)
   target_link_libraries(${VM_EXECUTABLE_NAME} comctl32)
   target_link_libraries(${VM_EXECUTABLE_NAME} uuid)
endif()

include(plugins.cmake)

# Handling Third party dependencies

add_third_party_dependencies_per_platform()

# Selecting files to include in the package

configure_installables()

# Packaging Setup 

make_directory("build/packages")

get_full_platform_name(FULL_PLATFORM_NAME)

set(CPACK_PACKAGE_DESCRIPTION "Pharo Headless VM for ${FULL_PLATFORM_NAME}")
set(CPACK_PACKAGE_VERSION_MAJOR "${VERSION_MAJOR}")
set(CPACK_PACKAGE_VERSION_MINOR "${VERSION_MINOR}")
set(CPACK_PACKAGE_VERSION_PATCH "${VERSION_PATCH}")
set(CPACK_PACKAGE_VENDOR "Pharo")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://pharo.org")
set(CPACK_PACKAGE_FILE_NAME "PharoVM-${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}-${GIT_COMMIT_HASH}-${FULL_PLATFORM_NAME}")
set(CPACK_PACKAGE_DIRECTORY "${CMAKE_SOURCE_DIR}/build/packages")
set(CPACK_PACKAGE_CHECKSUM "SHA1")
set(CPACK_GENERATOR "ZIP")
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY FALSE)

include (CPack)

