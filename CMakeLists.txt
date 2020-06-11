cmake_minimum_required(VERSION 2.8.4)

# Use new and simpler escape sequences
cmake_policy(SET CMP0053 NEW)

include(macros.cmake)

set(VERSION_MAJOR 8)
set(VERSION_MINOR 5)
set(VERSION_PATCH 0)

set(APPNAME Pharo CACHE STRING "VM Application name")

get_commit_hash(GIT_COMMIT_HASH)
get_git_describe(GIT_DESCRIBE)
get_git_date(GIT_COMMIT_DATE)

set(BUILT_FROM "${GIT_DESCRIBE} - Commit: ${GIT_COMMIT_HASH} - Date: ${GIT_COMMIT_DATE}")
message(STATUS ${BUILT_FROM})

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

project(PharoVM)

set(FLAVOUR CoInterpreterWithQueueFFI CACHE STRING "The kind of VM to generate. Possible values: StackVM, CogVM, CoInterpreterWithQueueFFI")

if(FLAVOUR MATCHES "StackVM")
  set(VMSOURCEFILES ${CMAKE_CURRENT_BINARY_DIR}/generated/vm/src/gcc3x-interp.c)
else()
  set(VMSOURCEFILES ${CMAKE_CURRENT_BINARY_DIR}/generated/vm/src/cogit.c ${CMAKE_CURRENT_BINARY_DIR}/generated/vm/src/gcc3x-cointerp.c)
endif()

if(FLAVOUR MATCHES "CoInterpreterWithQueueFFI")
  add_definitions(-DASYNC_FFI_QUEUE=1)
endif()

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

    add_definitions(-DNO_ISNAN -DNO_SERVICE -D'TZ="CEST"' "-D'VM_LABEL(foo)=0'" -DLSB_FIRST=1 -DAllocationCheckFiller=0xADD4E55)

    #Setting minimal Windows Version to VISTA
    add_definitions(-D_WIN32_WINNT=0x0600 -DWINVER=0x0600 -DNTDDI_VERSION=0x06000000 -DWIN64=1)

elseif(UNIX)

    # Use the default path to send as argument of extrernal apps (like pharo itself)
    set(CMAKE_CURRENT_SOURCE_DIR_TO_OUT ${CMAKE_CURRENT_SOURCE_DIR})
    set(CMAKE_CURRENT_BINARY_DIR_TO_OUT ${CMAKE_CURRENT_BINARY_DIR})

    set(COMMON_FLAGS "-Wall")

    add_definitions(-DLSB_FIRST=1)

    set(COMMON_FLAGS "-O2")

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

add_definitions(-DIMMUTABILITY=1)
add_definitions(-DCOGMTVM=0)
add_definitions(-DPharoVM=1)

#We require that VM_LABEL does nothing.
#We should actually cleanup all the places where this is set/used in the VM
add_definitions(-D"VM_LABEL\(foo\)=0")

#
# This definition is used to improve the logging of the messages, to cut-down the path
# of the source files in the compilation of debug messages.
#
# The additional / is important to remove the last character from the path.
# Note that it does not matter if the OS uses / or \, because we are only
# saving the path size.
string(LENGTH "${CMAKE_SOURCE_DIR}/" SOURCE_PATH_SIZE)
add_definitions("-DSOURCE_PATH_SIZE=${SOURCE_PATH_SIZE}")

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

#Setting output directories
set(VMMAKER_OUTPUT_PATH "build/vmmaker")
make_directory(${VMMAKER_OUTPUT_PATH})
set(EXECUTABLE_OUTPUT_PATH "build/vm")

#If in OSX, configure creation of Bundle
if (OSX)
  set(LIBRARY_OUTPUT_DIRECTORY "build/vm/$<CONFIG>/${VM_EXECUTABLE_NAME}.app/Contents/MacOS/Plugins")
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

#Custom command that downloads a Pharo image and VM in ${VMMAKER_OUTPUT_PATH}
add_custom_command(
  OUTPUT ${VMMAKER_OUTPUT_PATH}/Pharo.image ${VMMAKER_OUTPUT_PATH}/pharo
  COMMAND wget -O - https://get.pharo.org/64/80 | bash
  COMMAND wget -O - https://get.pharo.org/64/vm80 | bash
  WORKING_DIRECTORY ${VMMAKER_OUTPUT_PATH}
  COMMENT "Downloading Pharo 80")

add_custom_command(
  OUTPUT ${VMMAKER_OUTPUT_PATH}/VMMaker.image
  COMMAND ./pharo Pharo.image --save --quit ${CMAKE_CURRENT_SOURCE_DIR_TO_OUT}/scripts/installVMMaker.st ${CMAKE_CURRENT_SOURCE_DIR_TO_OUT}
  COMMAND ./pharo Pharo.image save VMMaker --delete-old
  DEPENDS ${VMMAKER_OUTPUT_PATH}/Pharo.image
  WORKING_DIRECTORY ${VMMAKER_OUTPUT_PATH}
COMMENT "Generating VMMaker image")

#Custom command that generates the vm source code from VMMaker into ${VMMAKER_OUTPUT_PATH} and copies it to ${CMAKE_CURRENT_SOURCE_DIR}
add_custom_command(
  OUTPUT ${VMSOURCEFILES}
  COMMAND ${VMMAKER_OUTPUT_PATH}/pharo ${VMMAKER_OUTPUT_PATH}/VMMaker.image eval \"PharoVMMaker generate: \#\'${FLAVOUR}\' outputDirectory: \'${CMAKE_CURRENT_BINARY_DIR_TO_OUT}\'\"
  DEPENDS ${VMMAKER_OUTPUT_PATH}/VMMaker.image
  COMMENT "Generating VM files for flavour: ${FLAVOUR}")

#Generating config file
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/include/pharovm/config.h.in build/include/pharovm/config.h)

message(STATUS "C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "C++ Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "Resource Compiler: ${CMAKE_RC_COMPILER}")


include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include/semaphores
    ${CMAKE_CURRENT_BINARY_DIR}/build/include/
    ${CMAKE_CURRENT_BINARY_DIR}/build/include/pharovm/
    ${CMAKE_CURRENT_BINARY_DIR}/generated/vm/include
)

set(VM_FRONTEND_APPLICATION_TYPE)
if(WIN)
    include(win32.cmake)
elseif(OSX)
    include(osx.cmake)
elseif(UNIX)
    include(unix.cmake)
endif()

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

set(VM_SOURCES
    ${SUPPORT_SOURCES}
    ${GENERATED_SOURCES}
    ${EXTRACTED_SOURCES}
)

add_executable(${VM_EXECUTABLE_NAME} ${VM_FRONTEND_APPLICATION_TYPE} ${VM_FRONTEND_SOURCES})
addLibraryWithRPATH(${VM_LIBRARY_NAME} ${VM_SOURCES})

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

# Handling Third party dependencies

add_third_party_dependencies_per_platform()

# Selecting files to include in the package

configure_installables(bin)

install(FILES
  ${CMAKE_CURRENT_BINARY_DIR}/build/include/pharovm/config.h
  DESTINATION include/pharovm
  COMPONENT include)

install(
    DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/include/pharovm"
    DESTINATION include
    COMPONENT include
    FILES_MATCHING PATTERN *.h)

install(
    DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/include/common/"
    DESTINATION include/pharovm
    COMPONENT include
    FILES_MATCHING PATTERN *.h)

install(
    DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/generated/vm/include/"
    DESTINATION include/pharovm
    COMPONENT include
    FILES_MATCHING PATTERN *.h)

# Packaging Setup

make_directory("build/packages")

get_full_platform_name(FULL_PLATFORM_NAME)

set(CPACK_PACKAGE_DESCRIPTION "${APPNAME} Headless VM for ${FULL_PLATFORM_NAME}")
set(CPACK_PACKAGE_VERSION_MAJOR "${VERSION_MAJOR}")
set(CPACK_PACKAGE_VERSION_MINOR "${VERSION_MINOR}")
set(CPACK_PACKAGE_VERSION_PATCH "${VERSION_PATCH}")
set(CPACK_PACKAGE_VENDOR "${APPNAME}")
set(CPACK_PACKAGE_HOMEPAGE_URL "https://pharo.org")
set(CPACK_PACKAGE_FILE_NAME "${APPNAME}VM-${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_PATCH}-${GIT_COMMIT_HASH}-${FULL_PLATFORM_NAME}")
set(CPACK_PACKAGE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/build/packages")
set(CPACK_PACKAGE_CHECKSUM "SHA1")
set(CPACK_GENERATOR "ZIP")
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY FALSE)

#Tell CPACK to archive each sub component separately
set(CPACK_ARCHIVE_COMPONENT_INSTALL ON)

include (CPack)
