# OpenSmalltalkVM cmake build script.
cmake_minimum_required(VERSION 3.1)
project(OpenSmalltalkVM)

# Set output dir.
# OpenSmalltalkVM_BUILD_AS_INTERNAL_PROJECT can be used before including this
# project using add_subdirectory()
if(NOT OpenSmalltalkVM_BUILD_AS_INTERNAL_PROJECT)
	set(EXECUTABLE_OUTPUT_PATH "${OpenSmalltalkVM_BINARY_DIR}/dist")
	set(LIBRARY_OUTPUT_PATH "${OpenSmalltalkVM_BINARY_DIR}/dist")
endif()

# Check the build type
if (CMAKE_BUILD_TYPE STREQUAL "")
	# CMake defaults to leaving CMAKE_BUILD_TYPE empty. This screws up
	# differentiation between debug and release builds.
	set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Choose the type of build, options are: None (CMAKE_CXX_FLAGS or CMAKE_C_FLAGS used) Debug Release RelWithDebInfo MinSizeRel." FORCE)
endif ()

# Turn on warnings
if (MSVC)
	# using Visual Studio C++
	set(CMAKE_C_FLAGS "${CMAKE_CXX_FLAGS} /W3")
	set(VM_MSVC TRUE)
else()
	set(CMAKE_C_FLAGS "${CMAKE_CXX_FLAGS} -Wall")
    if(UNIX)
        set(CMAKE_C_FLAGS "${CMAKE_CXX_FLAGS} -pthread")
    endif()

	# Export symbols from applications.
	#set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--export-dynamic")
endif()

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

if(NOT VM_MSVC)
	set(VM_DEPENDENCIES_LIBRARIES m ${VM_DEPENDENCIES_LIBRARIES})
endif()

# Add a build x86_32 version on x86_64 systems.
if("${CMAKE_SYSTEM_PROCESSOR}" MATCHES "x86_64" OR "${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "AMD64")
	option(BUILD_I386_VERSION "Build x86 32 bits version" OFF)
    set(SQUEAK_PLATFORM_X86_64 True)
elseif("${CMAKE_SYSTEM_PROCESSOR}" MATCHES "i.86")
    set(SQUEAK_PLATFORM_X86_32 True)
endif()

if(SQUEAK_PLATFORM_X86_64)
	if(BUILD_I386_VERSION)
        set(SQUEAK_PLATFORM_X86_32 True)
	    set(SQUEAK_PLATFORM_X86_64 False)
	else()
		set(VM_64BITS TRUE)
		set(SourceFolderName "${SourceFolderName}64")
		if(WIN32)
			set(FFI_VARIANT_X64_WIN64 True)
		else()
			set(FFI_VARIANT_X64_SYSV True)
		endif()
        set(COGIT_PLATFORM_SUFFIX "X64")
        set(VM_TARGET_CPU "x86_64")
	endif()
else()
	set(VM_64BITS False)
endif()

if(SQUEAK_PLATFORM_X86_32)
    if (MSVC)
        set(CMAKE_CXX_FLAGS "/arch:SSE2")
        set(CMAKE_C_FLAGS "/arch:SSE2")
    else()
        set(CMAKE_ASM-ATT_FLAGS "--32")
        set(CMAKE_CXX_FLAGS "-m32 -msse2")
        set(CMAKE_C_FLAGS "-m32 -msse2")
    endif()
    set(COGIT_PLATFORM_SUFFIX "IA32")
    set(FFI_VARIANT_IA32 True)
    set(VM_TARGET_CPU "i686")
endif()

set(VM_TARGET "${CMAKE_SYSTEM}")

if(WIN32)
    set(OS_TYPE "Win32")
    set(VM_TARGET_OS "Win32")
elseif(UNIX)
    set(OS_TYPE "unix")
    if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
	    set(OS_TYPE "Mac OS")
        set(VM_TARGET_OS "1000") # Used to recognise OS X
        set(DARWIN True)
    elseif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
        set(VM_TARGET_OS "linux-gnu")
    else()
        set(VM_TARGET_OS "${CMAKE_SYSTEM_NAME}")
    endif()
endif()

# Output paths.
set(CMAKE_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/dist")
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/;${CMAKE_MODULE_PATH}")

set(SourceFolderName "")

# Spur object model
option(SPUR_OBJECT_MODEL "Spur Object Model" ON)
if(SPUR_OBJECT_MODEL)
	#add_definitions(SpurVM=1)
	set(SourceFolderName "spur")
endif()

# Sista optimizer
option(SISTA_OPTIMIZER "Sista Optimizer" OFF)
if(SISTA_OPTIMIZER)
	#add_definitions(SistaVM=1)
	set(SourceFolderName "${SourceFolderName}sista")
endif()

# Lowcode extended instructions
option(LOWCODE_EXTENSIONS "Lowcode Extensions" OFF)
if(LOWCODE_EXTENSIONS)
	add_definitions(-DLowcodeVM=1)
endif()

# Pharo branding
option(PHARO_BRANDING "Pharo Branding" ON)
set(VM_EXECUTABLE_NAME squeak)
set(VM_LIBRARY_NAME SqueakVMCore)
set(VM_NAME Squeak)

if(PHARO_BRANDING)
	add_definitions(-DPharoVM=1)
	set(VM_EXECUTABLE_NAME pharo)
	set(VM_LIBRARY_NAME PharoVMCore)
    set(VM_NAME Pharo)
endif()
add_definitions(-DVM_NAME="${VM_NAME}")

# Cog JIT
option(COG_JIT "Cog JIT" ON)
if(COG_JIT)
	#add_definitions(CogVM=1)
endif()

# Get the version string
include(GetGitVersion.cmake)

set(SourceFolderName "${SourceFolderName}src")
set(PluginsSourceFolderName "src/plugins")

message("Source folder name: ${SourceFolderName}")

# Debug defines
if (CMAKE_BUILD_TYPE STREQUAL "Debug")
	add_definitions(-DDEBUGVM=1)
else()
endif()

# Common defines
add_definitions(-DUSE_GLOBAL_STRUCT=0
	-DNO_ISNAN=1
	-DUSE_INLINE_MEMORY_ACCESSORS
)

# Configuration
include(CheckIncludeFiles)
include(CheckFunctionExists)
include(CheckSymbolExists)
include(CheckLibraryExists)
include(CheckTypeSize)
include(CheckCSourceCompiles)

if(NOT WIN32)
	include (TestBigEndian)
	test_big_endian(WORDS_BIGENDIAN)
else()
    set(WORDS_BIGENDIAN False)
endif()

if(WORDS_BIGENDIAN)
    add_definitions(-DLSB_FIRST)
endif()

set(HAVE_INTERP_H 1)
check_include_files (alloca.h HAVE_ALLOCA_H)
if(HAVE_ALLOCA_H)
	check_c_source_compiles("
		#include <alloca.h>

		int main()
		{
			return (int*)alloca(5);
		}
		" HAVE_ALLOCA)
else()
	check_c_source_compiles("
		int main()
		{
			return (int*)alloca(5);
		}
		" HAVE_ALLOCA)
endif()

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

# check_include_files(iconv.h HAVE_ICONV_H)
# check_library_exists(iconv iconv "" HAVE_ICONV)
# check_library_exists(ffi ffi_call "" HAVE_LIBFFI)

# System calls
check_function_exists(atexit AT_EXIT)

check_function_exists(snprintf HAVE_SNPRINTF)
check_function_exists(__snprintf HAVE___SNPRINTF)
check_function_exists(nanosleep HAVE_NANOSLEEP)

check_function_exists(mmap HAVE_MMAP)
check_function_exists(kqueue HAVE_KQUEUE)
check_function_exists(select HAVE_SELECT)
check_function_exists(epoll_create1 HAVE_EPOLL)
check_function_exists(epoll_pwait HAVE_EPOLL_PWAIT)

# Time structures
set(CMAKE_EXTRA_INCLUDE_FILES time.h)
if(HAVE_SYS_TIME_H)
    set(CMAKE_EXTRA_INCLUDE_FILES sys/time.h ${CMAKE_EXTRA_INCLUDE_FILES})
endif()
check_c_source_compiles(
"#include <time.h>

int main()
{
	struct tm *tm = 0;
	return (int)tm->tm_gmtoff;
}
"
	HAVE_TM_GMTOFF
)
check_type_size("struct timezone" HAVE_TIMEZONE)
set(CMAKE_EXTRA_INCLUDE_FILES)

# Type sizes
if(BUILD_I386_VERSION OR SQUEAK_PLATFORM_X86_32)
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

if("${SIZEOF_LONG}" STREQUAL "8")
	set(SQUEAK_INT64_TYPEDEF "long")
elseif("${SIZEOF_LONG_LONG}" STREQUAL "8")
	set(SQUEAK_INT64_TYPEDEF "long long")
else()
	message(FATAL_ERROR "Failed to find a 64 bits integer type.")
endif()

if(HAVE_LIBDL)
	set(VM_DEPENDENCIES_LIBRARIES dl ${VM_DEPENDENCIES_LIBRARIES})
endif()
if(HAVE_DYLD)
	set(VM_DEPENDENCIES_LIBRARIES dyld ${VM_DEPENDENCIES_LIBRARIES})
endif()
if(HAVE_ICONV)
    set(VM_DEPENDENCIES_LIBRARIES iconv ${VM_DEPENDENCIES_LIBRARIES})
endif()

# Add the current directory.
include_directories(
	.
	"${PROJECT_SOURCE_DIR}/platforms/Cross/vm"
	"${SourceFolderName}/vm"
)

# VM Flavor sources
if(COG_JIT)
	set(VM_FAVLOR_SOURCES
		${SourceFolderName}/vm/cogit${COGIT_PLATFORM_SUFFIX}.c
		${SourceFolderName}/vm/cointerp.c
	)
else()
	set(VM_FAVLOR_SOURCES
		${SourceFolderName}/vm/interp.c
	)
endif()

# Find required Apple frameworks
if(APPLE)
	find_library(CoreFoundation_LIBRARY CoreFoundation)
	find_library(CoreServices_LIBRARY CoreServices)
	set(VM_DEPENDENCIES_LIBRARIES
		${CoreServices_LIBRARY}
		${CoreFoundation_LIBRARY}
		${VM_DEPENDENCIES_LIBRARIES})
endif()

# Find SDL2
find_path(SDL2_INCLUDE_DIR
  NAMES SDL.h
  PATH_SUFFIXES SDL2
)

find_path(SDL2_LIBRARY_PATH
  NAMES SDL2-2.0.lib SDL2-2.0.a libSDL2-2.0.a libSDL2-2.0.so SDL2.lib SDL2.a libSDL2.a
)

find_library(SDL2_LIBRARY NAMES SDL2-2.0 SDL2 PATHS ${SDL2_LIBRARY_PATH})

set(HAVE_SDL2 False)
if(SDL2_INCLUDE_DIR AND SDL2_LIBRARY)
	set(HAVE_SDL2 True)
	include_directories("${SDL2_INCLUDE_DIR}")
endif()
message("SDL2 Found: ${HAVE_SDL2}")

# Choose the window system
option(SUPPORT_TRADITIONAL_DISPLAY "Enables building a VM with support for a window." ON)

if(SUPPORT_TRADITIONAL_DISPLAY)
	if(HAVE_SDL2)
		set(VM_WINDOW_SYSTEM
			minheadless/source/sqWindow-SDL2.c
		)
		set(VM_DEPENDENCIES_LIBRARIES ${SDL2_LIBRARY} ${VM_DEPENDENCIES_LIBRARIES})
	else()
		set(VM_WINDOW_SYSTEM
			minheadless/source/sqWindow-Null.c
		)
	endif()
else()
	set(VM_WINDOW_SYSTEM
		minheadless/source/sqWindow-Null.c
	)
endif()

# Different source categories
set(VM_COMMON_SOURCES
	platforms/Cross/vm/sq.h
	platforms/Cross/vm/sqAssert.h
	platforms/Cross/vm/sqAtomicOps.h
	platforms/Cross/vm/sqCogStackAlignment.h
	platforms/Cross/vm/sqExternalSemaphores.c
	platforms/Cross/vm/sqHeapMap.c
	platforms/Cross/vm/sqMemoryAccess.h
	platforms/Cross/vm/sqMemoryFence.h
	platforms/Cross/vm/sqNamedPrims.c
	platforms/Cross/vm/sqSCCSVersion.h
	platforms/Cross/vm/sqTicker.c
	platforms/Cross/vm/sqVirtualMachine.h
	platforms/Cross/vm/sqVirtualMachine.c
)

include_directories(
	minheadless/include
	minheadless/source
)

set(VM_PLATFORM_SOURCES
    minheadless/include/sqConfig.h
    minheadless/include/sqEventCommon.h
    minheadless/include/sqNamedPrims.h
    minheadless/include/sqPath.h
    minheadless/include/sqPlatformSpecific.h
    minheadless/include/sqPlatformSpecific-Common.h
    minheadless/include/sqPlatformSpecific-Generic.h
    minheadless/include/sqPlatformSpecific-Unix.h
    minheadless/include/sqPlatformSpecific-Win32.h
    minheadless/include/sqQueue.h
    minheadless/include/sqTextEncoding.h
    minheadless/include/sqWin32Alloc.h
	minheadless/source/sqaio.h
	minheadless/source/sqExternalPrimitives.c
	minheadless/source/sqEventCommon.c
    minheadless/source/sqPath.c
    minheadless/source/sqPrinting.c
    minheadless/source/sqTextEncoding.c
)

if(UNIX)
	set(VM_PLATFORM_SOURCES
		minheadless/source/aioUnix.c
		minheadless/source/sqPlatformSpecific-Unix.c
		minheadless/source/sqUnixCharConv.c
		minheadless/source/sqUnixThreads.c
		minheadless/source/sqUnixHeartbeat.c
		${VM_PLATFORM_SOURCES}
	)

	if(SPUR_OBJECT_MODEL)
		set(VM_PLATFORM_SOURCES
			minheadless/source/sqUnixSpurMemory.c
			${VM_PLATFORM_SOURCES}
		)
	else()
		set(VM_PLATFORM_SOURCES
			minheadless/source/sqUnixMemory.c
			${VM_PLATFORM_SOURCES}
		)
	endif()

	set(VM_DEPENDENCIES_LIBRARIES pthread ${VM_DEPENDENCIES_LIBRARIES})
	if(APPLE)
		add_definitions(-DBUILD_FOR_OSX=1)
	else()
		add_definitions(-D_GNU_SOURCE)
	endif()
elseif(WIN32)
	set(VM_PLATFORM_SOURCES
        minheadless/include/sqWin32Alloc.h
        minheadless/include/sqWin32HandleTable.h
		minheadless/source/sqPlatformSpecific-Win32.c
        minheadless/source/sqWin32.h
        minheadless/source/sqWin32Alloc.c
    	minheadless/source/sqWin32SpurAlloc.c
    	minheadless/source/sqWin32Common.c
    	minheadless/source/sqWin32Directory.c
    	minheadless/source/sqWin32Heartbeat.c
    	minheadless/source/sqWin32Threads.c
    	minheadless/source/sqWin32Time.c
		${VM_PLATFORM_SOURCES}
	)
    add_definitions(
        -D_CRT_SECURE_NO_WARNINGS
        -DUNICODE
        -D_UNICODE
        -DWIN32_FILE_SUPPORT
        -DNO_SERVICE
        -DNO_STD_FILE_SUPPORT
        -Dsetjmp=_setjmp
        -D_WIN32_WINNT=0x501
        -DWINVER=0x501
        -DWIN32=1
    )
    set(VM_DEPENDENCIES_LIBRARIES Winmm ${VM_DEPENDENCIES_LIBRARIES})
    if(SQUEAK_PLATFORM_X86_32)
        if(MSVC)
            add_definitions(-DALLOCA_LIES_SO_USE_GETSP=0)
        else()
            add_definitions(
                -DSTACK_ALIGN_BYTES=16
                -DALLOCA_LIES_SO_USE_GETSP=0
            )
        endif()
        add_definitions(
            -DX86
        )
    endif()
else()
	set(VM_PLATFORM_SOURCES
		minheadless/source/sqPlatformSpecific-Generic.c
		${VM_PLATFORM_SOURCES}
	)

endif()

set(VM_SOURCES
	${VM_COMMON_SOURCES}
	${VM_FAVLOR_SOURCES}
	${VM_PLATFORM_SOURCES}
	${VM_WINDOW_SYSTEM}
)
source_group("VM Common Sources" FILES ${VM_COMMON_SOURCES})
source_group("VM Flavor Sources" FILES ${VM_FAVLOR_SOURCES})
source_group("VM Platform Sources" FILES ${VM_PLATFORM_SOURCES})
source_group("VM Window System" FILES ${VM_WINDOW_SYSTEM})
include("Plugins.cmake")

# Generate the config dot h.
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/minheadless/config.h.in ${CMAKE_CURRENT_BINARY_DIR}/config.h)

# Build the VM core library
set(VM_CORE_LIBRARY_TYPE STATIC)
#if(WIN32)
#    set(VM_CORE_LIBRARY_TYPE SHARED)
#endif()

add_library(${VM_LIBRARY_NAME} ${VM_CORE_LIBRARY_TYPE} ${VM_SOURCES} ${VM_INTERNAL_PLUGIN_SOURCES})
add_dependencies(${VM_LIBRARY_NAME} sqGitVersionString)

target_compile_definitions(${VM_LIBRARY_NAME} PRIVATE
	-DSQUEAK_BUILTIN_PLUGIN
    -DBUILD_VM_CORE
)

# Build the VM executable(s)
add_executable(${VM_EXECUTABLE_NAME} minheadless/source/sqMain.c)
target_link_libraries(${VM_EXECUTABLE_NAME} ${VM_LIBRARY_NAME} ${VM_DEPENDENCIES_LIBRARIES})

if(WIN32)
    add_executable(${VM_EXECUTABLE_NAME}w WIN32 minheadless/source/sqMain.c minheadless/source/sqWin32Main.c)
    target_link_libraries(${VM_EXECUTABLE_NAME}w ${VM_LIBRARY_NAME} ${VM_DEPENDENCIES_LIBRARIES})
endif()
