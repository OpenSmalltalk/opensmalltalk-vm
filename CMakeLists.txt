# SLVM native runtime cmake build script.
cmake_minimum_required(VERSION 2.8)
project(OpenSmalltalkVM)

# Check the build type
if (CMAKE_BUILD_TYPE STREQUAL "")
	# CMake defaults to leaving CMAKE_BUILD_TYPE empty. This screws up
	# differentiation between debug and release builds.
	set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Choose the type of build, options are: None (CMAKE_CXX_FLAGS or CMAKE_C_FLAGS used) Debug Release RelWithDebInfo MinSizeRel." FORCE)
endif ()

# Turn on warnings
if ("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
	# using Visual Studio C++
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W4")
	set(VM_MSVC TRUE)
else()
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -pthread")

	# Export symbols from applications.
	#set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--export-dynamic")
endif()

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

if(NOT VM_MSVC)
	set(VM_DEPENDENCIES_LIBRARIES m ${VM_DEPENDENCIES_LIBRARIES})
endif()

find_library(LIB_DL NAMES dl dyld)
if(LIB_DL)
	set(VM_DEPENDENCIES_LIBRARIES ${LIB_DL} ${VM_DEPENDENCIES_LIBRARIES})
endif()

# Add a build x86_32 version on x86_64 systems.
if("${CMAKE_SYSTEM_PROCESSOR}" MATCHES "x86_64")
	option(BUILD_I386_VERSION "Build x86 32 bits version" OFF)
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

if(PHARO_BRANDING)
	add_definitions(-DPharoVM=1)
	set(VM_EXECUTABLE_NAME pharo)
	set(VM_LIBRARY_NAME PharoVMCore)
endif()

# Cog JIT
option(COG_JIT "Cog JIT" ON)
if(COG_JIT)
	#add_definitions(CogVM=1)
endif()

# Get the version string
include(GetGitVersion.cmake)

# Check for 64 bits
if("${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "x86_64")
	if(BUILD_I386_VERSION)
		set(CMAKE_ASM-ATT_FLAGS "--32")
		set(CMAKE_CXX_FLAGS "-m32 -msse2")
		set(CMAKE_C_FLAGS "-m32 -msse2")
		set(FFI_VARIANT_IA32 True)
	else()
		set(VM_64BITS TRUE)
		set(SourceFolderName "${SourceFolderName}64")
		if(WIN32)
			set(FFI_VARIANT_X64_WIN64 True)
		else()
			set(FFI_VARIANT_X64_SYSV True)
		endif()
	endif()
else()
	if("${CMAKE_SYSTEM_PROCESSOR}" MATCHES "i.86")
		set(CMAKE_CXX_FLAGS "msse2")
		set(CMAKE_C_FLAGS "-msse2")
		set(FFI_VARIANT_IA32 True)
	endif()
	set(VM_64BITS False)
endif()

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

# Perform platform checks
include(${CMAKE_ROOT}/Modules/CheckIncludeFile.cmake)
include(${CMAKE_ROOT}/Modules/CheckIncludeFileCXX.cmake)
include(${CMAKE_ROOT}/Modules/CheckFunctionExists.cmake)
include(${CMAKE_ROOT}/Modules/CheckLibraryExists.cmake)

# Enable the assembler.
enable_language(ASM-ATT)

# Set output dir.
set(EXECUTABLE_OUTPUT_PATH "${OpenSmalltalkVM_BINARY_DIR}/dist")
set(LIBRARY_OUTPUT_PATH "${OpenSmalltalkVM_BINARY_DIR}/dist")

# Add the current directory.
include_directories(
.
"${PROJECT_SOURCE_DIR}/platforms/Cross/vm"
"${SourceFolderName}/vm"
)

# VM Flavor sources
if(COG_JIT)
	set(VM_FAVLOR_SOURCES
		${SourceFolderName}/vm/cogit.c
		${SourceFolderName}/vm/cointerp.c
	)
else()
	set(VM_FAVLOR_SOURCES
		${SourceFolderName}/vm/interp.c
	)
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

message("${SDL2_LIBRARY_PATH} ${SDL2_INCLUDE_DIR} ${SDL2_LIBRARY}")

set(SDL2_FOUND False)
if(SDL2_INCLUDE_DIR AND SDL2_LIBRARY)
	set(SDL2_FOUND True)
	include_directories("${SDL2_INCLUDE_DIR}")
endif()

# Choose the window system
option(SUPPORT_TRADITIONAL_DISPLAY "Enables building a VM with support for a window." ON)

if(SUPPORT_TRADITIONAL_DISPLAY)
	if(SDL2_FOUND)
		set(VM_WINDOW_SYSTEM
			minheadless/source/sqPlatformSpecific-SDL2Window.c
		)
		set(VM_DEPENDENCIES_LIBRARIES ${SDL2_LIBRARY} ${VM_DEPENDENCIES_LIBRARIES})
	else()
		set(VM_WINDOW_SYSTEM
			minheadless/source/sqPlatformSpecific-NullWindow.c
		)
	endif()
else()
	set(VM_WINDOW_SYSTEM
		minheadless/source/sqPlatformSpecific-NullWindow.c
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
	minheadless/source/sqExternalPrimitives.c
	minheadless/source/sqEventCommon.c
)

if(UNIX)
	set(VM_PLATFORM_SOURCES
		minheadless/source/aioUnix.c
		minheadless/source/sqPlatformSpecific-Unix.c
		minheadless/source/sqUnixCharConv.c
		minheadless/source/sqUnixSpurMemory.c
		minheadless/source/sqUnixMemory.c
		minheadless/source/sqUnixThreads.c
		minheadless/source/sqUnixHeartbeat.c
		${VM_PLATFORM_SOURCES}
	)

	set(VM_DEPENDENCIES_LIBRARIES pthread ${VM_DEPENDENCIES_LIBRARIES})
elseif(WIN32)
	set(VM_PLATFORM_SOURCES
		minheadless/source/sqPlatformSpecific-Win32.c
		${VM_PLATFORM_SOURCES}
	)
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

include("Plugins.cmake")

# Build the VM core library
add_library(${VM_LIBRARY_NAME} STATIC ${VM_SOURCES} ${VM_INTERNAL_PLUGIN_SOURCES})
add_dependencies(${VM_LIBRARY_NAME} sqGitVersionString)

target_compile_definitions(${VM_LIBRARY_NAME} PRIVATE
	-DSQUEAK_BUILTIN_PLUGIN
)

# Build the VM executable(s)
add_executable(${VM_EXECUTABLE_NAME} minheadless/source/sqMain.c)
target_link_libraries(${VM_EXECUTABLE_NAME} ${VM_LIBRARY_NAME} ${VM_DEPENDENCIES_LIBRARIES})
