# OpenSmalltalkVM cmake build script.
cmake_minimum_required(VERSION 3.11)
cmake_policy(SET CMP0054 NEW)
project(OpenSmalltalkVM)
#for setjmp.asm
enable_language(ASM-ATT)

option(ONLY_CONFIG_H "Only generate config.h" OFF)

option(COG_JIT "Cog JIT" ON)
option(SPUR_OBJECT_MODEL "Spur Object Model (i.e, no V3 image format)" ON)
option(SISTA_OPTIMIZER "Sista-optimized Cog JIT" OFF)
option(LOWCODE_EXTENSIONS "Lowcode Extensions" OFF)

option(PHARO_BRANDING "Pharo Branding" OFF)
option(NEWSPEAK_BRANDING "Newspeak Branding" OFF)
option(SQUEAK_BRANDING "Squeak Branding" ON)

option(SUPPORT_TRADITIONAL_DISPLAY "Enables building a VM with support for a window." OFF)
option(ALLOW_SDL2 "Enables support for the SDL2 display plugin" OFF)
option(GENERATE_TOP_LEVEL_RUN_SCRIPT "Generate a top level run script on installation" ON)
option(MINIMAL_PLUGIN_SET "Build the VM with the minimal number of plugins" OFF)
option(BUILD_PLUGINS_AS_BUNDLES "Build VM plugins as bundles" OFF)

# Check the build type
if (CMAKE_BUILD_TYPE STREQUAL "")
	# CMake defaults to leaving CMAKE_BUILD_TYPE empty. This screws up
	# differentiation between debug and release builds.
	set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Choose the type of build, options are: None (CMAKE_CXX_FLAGS or CMAKE_C_FLAGS used) Debug Release RelWithDebInfo MinSizeRel." FORCE)
endif ()

# Turn on warnings
if (MSVC)
	# using Visual Studio C++
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /W3")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W3")
	set(VM_MSVC TRUE)
else()
	set(WARNING_FLAG_LIST -Wall
		-Wno-missing-field-initializers -Wno-missing-prototypes
		-Wno-missing-braces -Wparentheses -Wswitch -Wno-unused-function
		-Wno-unused-label -Wno-unused-parameter
		-Wno-empty-body -Wno-uninitialized -Wno-unknown-pragmas -Wno-shadow
		-Wno-conversion -Wno-int-conversion -Wno-sign-conversion -Wpointer-sign
		-Wno-trigraphs -Wdeprecated-declarations

        # -Wunused-variable -Wunused-value -Wunused-but-set-variable
        # Supress these warning to reduce the side of the Travius log and avoid
        # "The job exceeded the maximum log length, and has been terminated."
        -Wno-unused-variable -Wno-unused-value
	)

	if("${CMAKE_C_COMPILER_ID}" MATCHES "Clang")
		set(WARNING_FLAG_LIST ${WARNING_FLAG_LIST}
			-Wno-newline-eof -Wno-shorten-64-to-32 -Wno-enum-conversion
			-Wno-bool-conversion -Wno-constant-conversion -Wno-four-char-constants
		)
	else()
		set(WARNING_FLAG_LIST ${WARNING_FLAG_LIST}
			-Wno-unused-but-set-variable
		)
	endif()

	set(WARNING_FLAGS)
	foreach(flag ${WARNING_FLAG_LIST})
		set(WARNING_FLAGS "${WARNING_FLAGS} ${flag}")
	endforeach()

	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -std=gnu99 ${WARNING_FLAGS}")
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${WARNING_FLAGS}")
    if(UNIX)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pthread")
    endif()

	# Export symbols from applications.
	#set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--export-dynamic")
endif()

# Set optimization flags
set(CMAKE_CONFIGURATION_TYPES Debug Release RelWithDebInfo Assert)
if (MSVC)
else()
	set(COMMON_FLAGS "-fno-strict-aliasing")
	#if(WIN32)
	#	set(COMMON_FLAGS "${COMMON_FLAGS} -falign-loops=16 -falign-jumps=16 -falign-functions=16 -falign-labels=16 -Dsetjmp=_setjmp")
	#endif()
	set(OPTIMIZATION_FLAGS "-O2 -fno-omit-frame-pointer -finline-functions ${COMMON_FLAGS}")

	set(CMAKE_C_FLAGS_DEBUG "-g ${COMMON_FLAGS} -DDEBUGVM=1")
	set(CMAKE_CXX_FLAGS_DEBUG "-g ${COMMON_FLAGS} -DDEBUGVM=1")

	set(CMAKE_C_FLAGS_RELEASE "${OPTIMIZATION_FLAGS} -DNDEBUG -DDEBUGVM=0")
	set(CMAKE_CXX_FLAGS_RELEASE "${OPTIMIZATION_FLAGS} -DNDEBUG -DDEBUGVM=0")

	set(CMAKE_C_FLAGS_RELWITHDEBINFO "-g ${OPTIMIZATION_FLAGS} -DNDEBUG -DDEBUGVM=0")
	set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "-g ${OPTIMIZATION_FLAGS} -DNDEBUG -DDEBUGVM=0")

	set(CMAKE_C_FLAGS_ASSERT "${OPTIMIZATION_FLAGS} -DDEBUGVM=1")
	set(CMAKE_CXX_FLAGS_ASSERT "${OPTIMIZATION_FLAGS} -DDEBUGVM=1")
endif()

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

if(NOT VM_MSVC)
	set(VM_DEPENDENCIES_LIBRARIES m ${VM_DEPENDENCIES_LIBRARIES})
endif()

# Add a build x86_32 version on x86_64 systems.
set(IS_64_BITS_BUILD_MACHINE False)
set(IS_X86_ARCH_MACHINE False)
if("${CMAKE_SYSTEM_PROCESSOR}" MATCHES "x86_64" OR "${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "AMD64")
	set(IS_64_BITS_BUILD_MACHINE True)
	# Do not build a 64 bit VM when invoking cmake with a 32 bits visual studio generator.
	if("${CMAKE_GENERATOR}" MATCHES "Visual Studio")
		if(NOT CMAKE_CL_64)
			set(IS_64_BITS_BUILD_MACHINE False)
		endif()
	endif()
elseif("${CMAKE_SYSTEM_PROCESSOR}" MATCHES "i.86")
	set(IS_X86_BUILD_MACHINE True)
endif()

if(IS_64_BITS_BUILD_MACHINE)
	option(BUILD_I386_VERSION "Build x86 32 bits version" OFF)
    set(OSVM_PLATFORM_X86_64 True)
else(IS_X86_BUILD_MACHINE)
	set(OSVM_PLATFORM_X86_32 True)
endif()

if(OSVM_PLATFORM_X86_64)
	if(BUILD_I386_VERSION)
        set(OSVM_PLATFORM_X86_32 True)
	    set(OSVM_PLATFORM_X86_64 False)
	else()
		set(VM_64BITS TRUE)
		set(VM_TARGET_CPU "x86_64")
		if(WIN32)
			set(VM_TARGET_CPU "X64")
			set(FFI_VARIANT_X64_WIN64 True)
		else()
			set(FFI_VARIANT_X64_SYSV True)
		endif()
	endif()
else()
	set(VM_64BITS False)
endif()

if(OSVM_PLATFORM_X86_32)
    if (MSVC)
        set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /arch:SSE2")
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /arch:SSE2")
    else()
        set(CMAKE_ASM-ATT_FLAGS "--32")
        set(CMAKE_CXX_FLAGS "-m32 -msse2 ${CMAKE_CXX_FLAGS} ")
        set(CMAKE_C_FLAGS "-m32 -msse2 ${CMAKE_C_FLAGS}")
    endif()
    set(FFI_VARIANT_IA32 True)
    set(VM_TARGET_CPU "i686")
	if(WIN32)
		set(VM_TARGET_CPU "IX86")
	endif()
endif()

set(VM_TARGET "${CMAKE_SYSTEM}")
set(SourceFolderName "src/")
set(ProductFolderName "")

# Lowcode extended instructions
if(LOWCODE_EXTENSIONS)
	add_definitions(-DLowcodeVM=1)
	set(SourceFolderName "${SourceFolderName}lowcode.vm")
	set(ProductFolderName "${ProductFolderName}lowcodevm")
else()
	set(SourceFolderName "${SourceFolderName}vm")
endif()


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
		set(ProductFolderName "linux")
    else()
        set(VM_TARGET_OS "${CMAKE_SYSTEM_NAME}")
		set(ProductFolderName "${CMAKE_SYSTEM_NAME}")
    endif()
endif()


# 64 bits VM
if(VM_64BITS)
	set(SourceFolderName "${SourceFolderName}.64bit")
	set(ProductFolderName "${ProductFolderName}64")
else()
	set(SourceFolderName "${SourceFolderName}.32bit")
	set(ProductFolderName "${ProductFolderName}32")
endif()


# What Cogit is active?
if(SISTA_OPTIMIZER)
	#add_definitions(SistaVM=1) # not needed because already set in sources
	set(SourceFolderName "${SourceFolderName}.sista")
	set(ProductFolderName "sista${ProductFolderName}")
elseif(COG_JIT)
	set(SourceFolderName "${SourceFolderName}.cog")
	set(ProductFolderName "cog${ProductFolderName}")
else()
	set(SourceFolderName "${SourceFolderName}.stack")
	set(ProductFolderName "stack${ProductFolderName}")
endif()


# Spur object model
if(SPUR_OBJECT_MODEL)
	#add_definitions(SpurVM=1) # not needed because already set in sources
	set(SourceFolderName "${SourceFolderName}.spur")
	set(ProductFolderName "spur${ProductFolderName}")
else()
	set(SourceFolderName "${SourceFolderName}.v3")
	set(ProductFolderName "v3${ProductFolderName}")	
endif()


# Add the minheadless suffix
set(ProductFolderName "${ProductFolderName}mhdls")
if(HAVE_SDL2 AND SUPPORT_TRADITIONAL_DISPLAY)
	set(ProductFolderName "${ProductFolderName}sdl2")
endif()


# VM branding
if(PHARO_BRANDING)
	set(PHARO_VM TRUE)
	set(VM_EXECUTABLE_NAME pharo)
	set(VM_LIBRARY_NAME PharoVMCore)
	set(VM_NAME Pharo)
	set(VM_PLUGINS_ENV_VAR_NAME "PHARO_PLUGINS")
	set(ProductFolderName "ph${ProductFolderName}")
	if(DARWIN OR WIN32)
		set(VM_EXECUTABLE_NAME Pharo)
	endif()
elseif(NEWSPEAK_BRANDING)
	set(NEWSPEAK_VM TRUE)
	set(VM_EXECUTABLE_NAME newspeak)
	set(VM_LIBRARY_NAME NewspeakVMCore)
	set(VM_NAME Newspeak)
	set(VM_PLUGINS_ENV_VAR_NAME "NEWSPEAK_PLUGINS")
	set(ProductFolderName "ns${ProductFolderName}")
	if(DARWIN OR WIN32)
		set(VM_EXECUTABLE_NAME Newspeak)
	endif()	
elseif(SQUEAK_BRANDING)
	set(SQUEAK_VM TRUE)
	set(VM_EXECUTABLE_NAME squeak)
	set(VM_LIBRARY_NAME SqueakVMCore)
	set(VM_NAME Squeak)
	set(VM_PLUGINS_ENV_VAR_NAME "SQUEAK_PLUGINS")
	set(ProductFolderName "sq${ProductFolderName}")
	if(DARWIN OR WIN32)
		set(VM_EXECUTABLE_NAME Squeak)
	endif()
else()
	set(PHARO_VM FALSE)
	set(NEWSPEAK_VM FALSE)
	set(SQUEAK_VM FALSE)
	set(VM_EXECUTABLE_NAME osvm)
	set(VM_LIBRARY_NAME OpenSmalltalkVMCore)
	set(VM_NAME OpenSmalltalkVM)
	set(VM_PLUGINS_ENV_VAR_NAME "OPENSMALLTALK_PLUGINS")
	if(DARWIN OR WIN32)
		set(VM_EXECUTABLE_NAME OpenSmalltalkVM)
	endif()
endif()
add_definitions(-DVM_NAME="${VM_NAME}")

if(PHARO_VM)
	add_definitions(-DPharoVM=1 -DIMMUTABILITY=1)
elseif(NEWSPEAK_VM)
	add_definitions(-DNewspeakVM=1)
elseif(SQUEAK_VM)
	# Nothing extra to define
endif()


# Cog JIT
if(COG_JIT)
	#add_definitions(CogVM=1)
endif()

add_definitions(-DCOGMTVM=0)

set(SourceFolderName "${SourceFolderName}src")
set(PluginsSourceFolderName "src/plugins")

message(STATUS "Source folder name: ${SourceFolderName}")

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
include(CheckCSourceRuns)

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

check_include_files(execinfo.h HAVE_EXECINFO_H)
check_include_files(fcntl.h HAVE_FCNTL_H)
check_include_files(inttypes.h HAVE_INTTYPES_H)
check_include_files(memory.h HAVE_MEMORY_H)
check_include_files(stdint.h HAVE_STDINT_H)
check_include_files(stdlib.h HAVE_STDLIB_H)
check_include_files(strings.h HAVE_STRINGS_H)
check_include_files(string.h HAVE_STRING_H)
check_include_files(sys/file.h HAVE_SYS_FILE_H)
check_include_files(sys/param.h HAVE_SYS_PARAM_H)
check_include_files(sys/select.h HAVE_SYS_SELECT_H)
check_include_files(sys/stat.h HAVE_SYS_STAT_H)
check_include_files(sys/types.h HAVE_SYS_TYPES_H)
check_include_files("stdlib.h;stdarg.h;string.h;float.h" STDC_HEADERS)

check_include_files(dlfcn.h HAVE_DLFCN_H)
check_library_exists(dl dlopen "" HAVE_LIBDL)
check_library_exists(dyld dlopen "" HAVE_DYLD)
# is for the symbol
check_library_exists(dl dlerror "" HAVE_DLERROR)
check_library_exists(dyld dlerror  "" HAVE_DLERROR)

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



check_c_source_compiles("
#include <pthread.h>
int main() { 
int i = PTHREAD_PRIO_INHERIT;
return i;}" HAVE_PTHREAD_PRIO_INHERIT)

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
check_c_source_compiles(
"#include <time.h>
int main() {
  static struct tm a;
  if (a.tm_zone) return 0;
  return 0; }" HAVE_STRUCT_TM_TM_ZONE)
if(HAVE_STRUCT_TM_TM_ZONE)
  set(HAVE_TM_ZONE TRUE)
endif()
set(CMAKE_EXTRA_INCLUDE_FILES)

# stat structure
if(HAVE_SYS_STAT_H)
  check_c_source_compiles("
#include <sys/stat.h>
int main() {
  static struct stat a;
  if (a.st_blksize) return 0;
  return 0;}" HAVE_STRUCT_STAT_ST_BLKSIZE)
  if(HAVE_STRUCT_STAT_ST_BLKSIZE)
    set(HAVE_ST_BLKSIZE TRUE)
  endif()
else()
  set(HAVE_STRUCT_STAT_ST_BLKSIZE FALSE)
  set(HAVE_ST_BLKSIZE FALSE)
endif()

# Type sizes
if(BUILD_I386_VERSION OR OSVM_PLATFORM_X86_32)
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

if(HAVE_LIBDL)
	set(VM_DEPENDENCIES_LIBRARIES dl ${VM_DEPENDENCIES_LIBRARIES})
endif()
if(HAVE_DYLD)
	set(VM_DEPENDENCIES_LIBRARIES dyld ${VM_DEPENDENCIES_LIBRARIES})
endif()
if(HAVE_ICONV)
    set(VM_DEPENDENCIES_LIBRARIES iconv ${VM_DEPENDENCIES_LIBRARIES})
endif()

# UUID
find_library(UUID_LIBRARY NAMES uuid)

check_include_files(sys/uuid.h HAVE_SYS_UUID_H)
check_include_files(uuid/uuid.h HAVE_UUID_UUID_H)
check_include_files(uuid.h HAVE_UUID_H)

if(UUID_LIBRARY)
	set(CMAKE_REQUIRED_LIBRARIES ${UUID_LIBRARY})
	if(HAVE_SYS_UUID_H)
		check_symbol_exists(uuidgen sys/uuid.h HAVE_UUIDGEN)
		check_symbol_exists(uuid_generate sys/uuid.h HAVE_UUID_GENERATE)
	elseif(HAVE_UUID_UUID_H)
		check_symbol_exists(uuidgen uuid/uuid.h HAVE_UUIDGEN)
		check_symbol_exists(uuid_generate uuid/uuid.h HAVE_UUID_GENERATE)
	elseif(HAVE_UUID_H)
		check_symbol_exists(uuidgen uuid.h HAVE_UUIDGEN)
		check_symbol_exists(uuid_generate uuid.h HAVE_UUID_GENERATE)
	endif()
endif()

set(HAVE_VALID_UUID_LIBRARY False)
if(UUID_LIBRARY AND (HAVE_SYS_UUID_H OR HAVE_UUID_UUID_H OR HAVE_UUID_H) AND (HAVE_UUIDGEN OR HAVE_UUID_GENERATE))
	set(HAVE_VALID_UUID_LIBRARY True)
endif()

# Add the current directory.
include_directories(
	.
	"${PROJECT_SOURCE_DIR}/include"
	"${PROJECT_SOURCE_DIR}/platforms/Cross/vm"
	"${PROJECT_SOURCE_DIR}/platforms/Cross/plugins"
	"${SourceFolderName}"
)

# VM Flavor sources
if(COG_JIT)
	if(VM_MSVC)
		set(InterpreterSource ${SourceFolderName}/cointerp.c)
	else()
		set(InterpreterSource ${SourceFolderName}/gcc3x-cointerp.c)
	endif()
	set(VM_FAVLOR_SOURCES
		${SourceFolderName}/cogit.c
		${InterpreterSource}
	)
else()
	set(InterpreterSource ${SourceFolderName}/interp.c)
	set(VM_FAVLOR_SOURCES
		${InterpreterSource}
	)
endif()

# Compile the interpreter with less aggresive optimization options.
if(NOT ("${CMAKE_BUILD_TYPE}" STREQUAL "Debug") AND NOT MSVC)
	set_source_files_properties(${InterpreterSource} PROPERTIES COMPILE_FLAGS -O1)
endif()

# Find required Apple frameworks
if(APPLE)
	find_library(CoreFoundation_LIBRARY CoreFoundation)
	find_library(CoreServices_LIBRARY CoreServices)
	find_library(Foundation_LIBRARY Foundation)
	find_library(AppKit_LIBRARY AppKit)
	find_library(Security_LIBRARY Security)
	set(VM_DEPENDENCIES_LIBRARIES
		${CoreServices_LIBRARY}
		${CoreFoundation_LIBRARY}
		${Foundation_LIBRARY}
		${VM_DEPENDENCIES_LIBRARIES})
endif()

if(SUPPORT_TRADITIONAL_DISPLAY AND ALLOW_SDL2)
	set(ProductFolderName "${ProductFolderName}+sdl2")
endif()

# Set output dir.
# OpenSmalltalkVM_BUILD_AS_INTERNAL_PROJECT can be used before including this
# project using add_subdirectory()
if(NOT OpenSmalltalkVM_BUILD_AS_INTERNAL_PROJECT)
	set(ProductDistFolder "${OpenSmalltalkVM_BINARY_DIR}/dist/")
	set(ProductInstallBaseFolder "${ProductFolderName}")
	set(ProductInstallProgramFolder "${ProductFolderName}/lib/${VM_EXECUTABLE_NAME}")

	if(DARWIN)
		set(ProductInstallBaseFolder ".")
		set(ProductInstallProgramFolder ".")
	elseif(WIN32)
		# We use the vm folder for compatibility with the VM packing scripts
		# for CI deployment.
		set(ProductInstallBaseFolder "vm")
		set(ProductInstallProgramFolder "vm")
	endif()

	set(EXECUTABLE_OUTPUT_PATH "${ProductDistFolder}")
	set(LIBRARY_OUTPUT_PATH "${ProductDistFolder}")
endif()

set(HAVE_SDL2 False CACHE INTERNAL "Is SDL2 available?")
set(HAVE_FreeType2 False CACHE INTERNAL "Is FreeType available?")
if(NOT ONLY_CONFIG_H)
	include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/ThirdPartyDependencies.cmake")
endif()

# Choose the window system
set(VM_WINDOW_SYSTEM)
if(SUPPORT_TRADITIONAL_DISPLAY AND ALLOW_SDL2)
	set(VM_WINDOW_SYSTEM
		platforms/minheadless/sdl2-window/sqWindow-SDL2.c
	)
	set(VM_DEPENDENCIES_LIBRARIES ${VM_DEPENDENCIES_LIBRARIES} ${SDL2_LIBRARIES})
endif()

# Different source categories
set(VM_COMMON_SOURCES
	platforms/Cross/vm/sq.h
	platforms/Cross/vm/sqAssert.h
	platforms/Cross/vm/sqAtomicOps.h
    platforms/Cross/vm/sqCircularQueue.h
	platforms/Cross/vm/sqCogStackAlignment.h
	platforms/Cross/vm/sqExternalSemaphores.c
	platforms/Cross/vm/sqHeapMap.c
	platforms/Cross/vm/sqMemoryAccess.h
	platforms/Cross/vm/sqMemoryFence.h
	platforms/Cross/vm/sqNamedPrims.c
    platforms/Cross/vm/sqPath.h
    platforms/Cross/vm/sqPath.c
	platforms/Cross/vm/sqSCCSVersion.h
    platforms/Cross/vm/sqTextEncoding.h
    platforms/Cross/vm/sqTextEncoding.c
	platforms/Cross/vm/sqTicker.c
	platforms/Cross/vm/sqVirtualMachine.h
	platforms/Cross/vm/sqVirtualMachine.c
)

include_directories(
	platforms/minheadless/common
)

set(VM_PLATFORM_COMMON_SOURCES
	platforms/minheadless/common/sqaio.h
    platforms/minheadless/common/sqConfig.h
    platforms/minheadless/common/sqEventCommon.h
    platforms/minheadless/common/sqNamedPrims.h
    platforms/minheadless/common/sqPlatformSpecific.h
    platforms/minheadless/common/sqPlatformSpecificCommon.h
	platforms/minheadless/common/sqInternalPrimitives.c
	platforms/minheadless/common/sqExternalPrimitives.c
	platforms/minheadless/common/sqEventCommon.c
    platforms/minheadless/common/sqPrinting.c
	platforms/minheadless/common/sqWindow-Null.c
	platforms/minheadless/common/sqWindow-Dispatch.c
	platforms/minheadless/common/sqVirtualMachineInterface.c
)

if(UNIX)
	include_directories(
		platforms/minheadless/unix
	)

	set(VM_PLATFORM_SOURCES
		platforms/minheadless/unix/aioUnix.c
	    platforms/minheadless/unix/sqPlatformSpecific-Unix.h
		platforms/minheadless/unix/sqPlatformSpecific-Unix.c
		platforms/minheadless/unix/sqUnixCharConv.c
		platforms/minheadless/unix/sqUnixThreads.c
		platforms/minheadless/unix/sqUnixHeartbeat.c
		${VM_PLATFORM_SOURCES}
	)

	if(SPUR_OBJECT_MODEL)
		set(VM_PLATFORM_SOURCES
			platforms/minheadless/unix/sqUnixSpurMemory.c
			${VM_PLATFORM_SOURCES}
		)
	else()
		set(VM_PLATFORM_SOURCES
			platforms/minheadless/unix/sqUnixMemory.c
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
	include_directories(
		platforms/minheadless/windows
	)

	if(OSVM_PLATFORM_X86_32)
		set(SETJMP_IMPL platforms/win32/misc/_setjmp-x86.asm)
	else()
		set(SETJMP_IMPL platforms/win32/misc/_setjmp-x64.asm)
	endif()

	set(VM_PLATFORM_SOURCES
    	platforms/minheadless/windows/sqWin32Alloc.h
        platforms/minheadless/windows/sqWin32HandleTable.h
	    platforms/minheadless/windows/sqPlatformSpecific-Win32.h
		platforms/minheadless/windows/sqPlatformSpecific-Win32.c
        platforms/minheadless/windows/sqWin32.h
        platforms/minheadless/windows/sqWin32Alloc.c
    	platforms/minheadless/windows/sqWin32SpurAlloc.c
        platforms/minheadless/windows/sqWin32Backtrace.c
    	platforms/minheadless/windows/sqWin32Common.c
    	platforms/minheadless/windows/sqWin32Directory.c
    	platforms/minheadless/windows/sqWin32Heartbeat.c
    	platforms/minheadless/windows/sqWin32Stubs.c
    	platforms/minheadless/windows/sqWin32Threads.c
    	platforms/minheadless/windows/sqWin32Time.c
		${SETJMP_IMPL}
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
		-D_MT
    )

	if(NOT MSVC)
		set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fno-builtin-printf -fno-builtin-putchar -fno-builtin-fprintf -mno-rtd -mms-bitfields")
		set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fno-builtin-printf -fno-builtin-putchar -fno-builtin-fprintf -mno-rtd -mms-bitfields")
	endif()

    set(VM_DEPENDENCIES_LIBRARIES Winmm ${VM_DEPENDENCIES_LIBRARIES})
    if(OSVM_PLATFORM_X86_32)
        add_definitions(
            -DX86
			-DWIN32=1
        )
	elseif(OSVM_PLATFORM_X86_64)
		add_definitions(
			-DWIN64=1
        )
    endif()
else()
	set(VM_PLATFORM_SOURCES
    	platforms/minheadless/generic/sqPlatformSpecific-Generic.h
		platforms/minheadless/generic/sqPlatformSpecific-Generic.c
		${VM_PLATFORM_SOURCES}
	)
endif()

set(VM_SOURCES
	${VM_COMMON_SOURCES}
	${VM_FAVLOR_SOURCES}
	${VM_PLATFORM_COMMON_SOURCES}
	${VM_PLATFORM_SOURCES}
	${VM_WINDOW_SYSTEM}
)

source_group("VM Common Sources" FILES ${VM_COMMON_SOURCES})
source_group("VM Flavor Sources" FILES ${VM_FAVLOR_SOURCES})
source_group("VM Platform Common Sources" FILES ${VM_PLATFORM_COMMON_SOURCES})
source_group("VM Platform Sources" FILES ${VM_PLATFORM_SOURCES})
source_group("VM Window System" FILES ${VM_WINDOW_SYSTEM})
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/Plugins.cmake")

# Generate the config dot h.
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/platforms/minheadless/config.h.in ${CMAKE_CURRENT_BINARY_DIR}/config.h)
if(NOT ONLY_CONFIG_H)
    include_directories(${CMAKE_BINARY_DIR})

    # Build the VM core library
    set(VM_CORE_LIBRARY_TYPE STATIC)
    if(WIN32)
        set(VM_CORE_LIBRARY_TYPE SHARED)
	endif()

    if("${VM_CORE_LIBRARY_TYPE}" STREQUAL "STATIC")
    	add_definitions(-DBUILD_OSVM_STATIC)
    endif()

	# Extract the public header
	file(GLOB PublicHeaderFiles RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
	    "include/*.h"
	    "include/*.hpp"
	)

    add_library(${VM_LIBRARY_NAME} ${VM_CORE_LIBRARY_TYPE} ${VM_SOURCES} ${VM_INTERNAL_PLUGIN_SOURCES})
	target_link_libraries(${VM_LIBRARY_NAME} ${VM_DEPENDENCIES_LIBRARIES})
    target_compile_definitions(${VM_LIBRARY_NAME} PRIVATE
    	-DSQUEAK_BUILTIN_PLUGIN
        -DBUILD_VM_CORE
    )
	set_target_properties(${VM_LIBRARY_NAME} PROPERTIES
		PUBLIC_HEADER ${PublicHeaderFiles}
		FRAMEWORK TRUE)

	# Build the VM after SDL2 always. If the SDL2DisplayPlugin is an internal plugin,
	# or the SDL2 based display is used, then we need this dependency.
	if(SDL2_BuildDep)
		add_dependencies(${VM_LIBRARY_NAME} ${SDL2_BuildDep})
	endif()

    # Build the VM executable(s)
	set(VM_EXECUTABLE_TARGETS ${VM_EXECUTABLE_NAME})
    if(WIN32)
		set(VM_VERSION_FILEVERSION "minheadless CMake")
		set(Win32ResourcesFolder "${CMAKE_CURRENT_SOURCE_DIR}/platforms/minheadless/windows/resources/${VM_EXECUTABLE_NAME}")
		configure_file("${Win32ResourcesFolder}/${VM_EXECUTABLE_NAME}.rc.in"
			"${CMAKE_CURRENT_BINARY_DIR}/${VM_EXECUTABLE_NAME}.rc" @ONLY IMMEDIATE)
		configure_file("${Win32ResourcesFolder}/${VM_EXECUTABLE_NAME}.exe.manifest.in"
			"${CMAKE_CURRENT_BINARY_DIR}/${VM_EXECUTABLE_NAME}.exe.manifest" @ONLY IMMEDIATE)
		configure_file("${Win32ResourcesFolder}/${VM_EXECUTABLE_NAME}.exe.manifest.in"
			"${CMAKE_CURRENT_BINARY_DIR}/${VM_EXECUTABLE_NAME}Console.exe.manifest" @ONLY IMMEDIATE)
		set(Win32Resource "${CMAKE_CURRENT_BINARY_DIR}/${VM_EXECUTABLE_NAME}.rc")
		set(Win32Manifest "${CMAKE_CURRENT_BINARY_DIR}/${VM_EXECUTABLE_NAME}.exe.manifest")
		set(Win32ConsoleManifest "${CMAKE_CURRENT_BINARY_DIR}/${VM_EXECUTABLE_NAME}Console.exe.manifest")

		set(VM_EXECUTABLE_TARGETS ${VM_EXECUTABLE_NAME} ${VM_EXECUTABLE_NAME}Console)
		add_executable(${VM_EXECUTABLE_NAME}Console platforms/minheadless/common/sqMain.c ${Win32Resource} ${Win32ConsoleManifest})
	    target_link_libraries(${VM_EXECUTABLE_NAME}Console ${VM_LIBRARY_NAME})

        add_executable(${VM_EXECUTABLE_NAME} WIN32 platforms/minheadless/windows/sqWin32Main.c ${Win32Resource} ${Win32Manifest})
        target_link_libraries(${VM_EXECUTABLE_NAME} ${VM_LIBRARY_NAME})
	elseif(DARWIN)
		if(PHARO_VM)
			file(GLOB VM_ICONS RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
				"platforms/iOS/vm/OSX/Pharo*.icns"
			)
			set(VM_EXECUTABLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/platforms/iOS/vm/OSX/Pharo-Info.plist")
		else()
			file(GLOB VM_ICONS RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
				"platforms/iOS/vm/OSX/Squeak*.icns"
			)
			set(VM_EXECUTABLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/platforms/iOS/vm/OSX/Squeak-Info.plist")
		endif()
		set(VM_RESOURCE_FILES ${VM_ICONS})
		add_executable(${VM_EXECUTABLE_NAME} MACOSX_BUNDLE
			platforms/minheadless/mac/sqMain.m
			${VM_RESOURCE_FILES}
		)

		set_target_properties(${VM_EXECUTABLE_NAME} PROPERTIES
			RESOURCE "${VM_RESOURCE_FILES}"
			MACOSX_BUNDLE_INFO_PLIST ${VM_EXECUTABLE_INFO_PLIST})
		target_link_libraries(${VM_EXECUTABLE_NAME} ${VM_LIBRARY_NAME} ${Foundation_LIBRARY} ${AppKit_LIBRARY})
	else()
		add_executable(${VM_EXECUTABLE_NAME} platforms/minheadless/common/sqMain.c)
	    target_link_libraries(${VM_EXECUTABLE_NAME} ${VM_LIBRARY_NAME})

        if(GENERATE_TOP_LEVEL_RUN_SCRIPT)
    	 	set(expanded_relative_imgdir "lib/${VM_EXECUTABLE_NAME}")
    		configure_file(${CMAKE_CURRENT_SOURCE_DIR}/platforms/minheadless/startup.sh.in "${CMAKE_BINARY_DIR}/scripts/${VM_EXECUTABLE_NAME}" @ONLY)
            install(PROGRAMS "${CMAKE_BINARY_DIR}/scripts/${VM_EXECUTABLE_NAME}" DESTINATION "${ProductInstallBaseFolder}")
        endif()

		set(expanded_relative_imgdir "../lib/${VM_EXECUTABLE_NAME}")
		configure_file(${CMAKE_CURRENT_SOURCE_DIR}/platforms/minheadless/startup.sh.in "${CMAKE_BINARY_DIR}/scripts/bin/${VM_EXECUTABLE_NAME}" @ONLY)
        install(PROGRAMS "${CMAKE_BINARY_DIR}/scripts/bin/${VM_EXECUTABLE_NAME}" DESTINATION "${ProductInstallBaseFolder}/bin")
    endif()

	if(DARWIN)
		function(MakeOSXBundleApp
			target binary_dir embedded_bundles embedded_plugins embedded_frameworks
			thirdparty_libraries_names thirdparty_libraries_patterns)

		  # Function from sample http://www.cmake.org/Wiki/images/e/e3/QTTest.zip
		  # https://gitlab.kitware.com/cmake/community/wikis/doc/tutorials/BuildingOSXApplications
	      SET (OSX_MAKE_STANDALONE_BUNDLE_CMAKE_SCRIPT "${binary_dir}/${target}_OSX_MakeStandAloneBundle.cmake")
	      SET (OSX_MAKE_STANDALONE_BUNDLE_BASH_SCRIPT "${binary_dir}/${target}_OSX_MakeStandAloneBundle.sh")

	      CONFIGURE_FILE("${CMAKE_CURRENT_SOURCE_DIR}/cmake/CompleteBundle.cmake.in"
	        "${OSX_MAKE_STANDALONE_BUNDLE_CMAKE_SCRIPT}" @ONLY IMMEDIATE)
	      CONFIGURE_FILE("${CMAKE_CURRENT_SOURCE_DIR}/cmake/CreateBundle.sh.in"
	        "${OSX_MAKE_STANDALONE_BUNDLE_BASH_SCRIPT}" @ONLY IMMEDIATE)

	     install(SCRIPT "${OSX_MAKE_STANDALONE_BUNDLE_CMAKE_SCRIPT}")
	    endfunction(MakeOSXBundleApp)

		if(BUILD_PLUGINS_AS_BUNDLES)
			MakeOSXBundleApp(${VM_EXECUTABLE_NAME} ${CMAKE_CURRENT_BINARY_DIR}
				"${VM_EXTERNAL_PLUGINS_TARGETS}" "" ""
				"${ThirdPartyLibrariesFileNames}" "${ThirdPartyLibrariesPatterns}")
		else()
			MakeOSXBundleApp(${VM_EXECUTABLE_NAME} ${CMAKE_CURRENT_BINARY_DIR}
				"" "${VM_EXTERNAL_PLUGINS_TARGETS}" ""
				"${ThirdPartyLibrariesFileNames}" "${ThirdPartyLibrariesPatterns}"
			)
		endif()
	else()
		install(TARGETS ${VM_LIBRARY_NAME} ${VM_EXECUTABLE_TARGETS} ${VM_EXTERNAL_PLUGINS_TARGETS}
			ARCHIVE DESTINATION ${ProductInstallProgramFolder}
			LIBRARY DESTINATION ${ProductInstallProgramFolder}
			RUNTIME DESTINATION ${ProductInstallProgramFolder}
			PUBLIC_HEADER DESTINATION ${ProductInstallBaseFolder}/include
			PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_WRITE GROUP_EXECUTE WORLD_READ WORLD_WRITE WORLD_EXECUTE
		)

		# HACK: On cygwin the resulting dlls and exe file are having wrong
		# permissions.
		if(MINGW_ON_CYGWIN)
			set(FIX_CYGWIN_INSTALL_PERMISSIONS_BASH_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/FixCygwinInstallPermissions.sh")
			configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake/FixCygwinInstallPermissions.sh.in" "${FIX_CYGWIN_INSTALL_PERMISSIONS_BASH_SCRIPT}" @ONLY)
			set(FIX_CYGWIN_INSTALL_PERMISSIONS_SCRIPT "${CMAKE_CURRENT_BINARY_DIR}/FixCygwinInstallPermissions.cmake")
			configure_file("${CMAKE_CURRENT_SOURCE_DIR}/cmake/FixCygwinInstallPermissions.cmake.in" "${FIX_CYGWIN_INSTALL_PERMISSIONS_SCRIPT}" @ONLY)
			install(SCRIPT "${FIX_CYGWIN_INSTALL_PERMISSIONS_SCRIPT}")
		endif()
	endif()
endif()

message(STATUS "Build results can be installed to ${CMAKE_INSTALL_PREFIX}")
