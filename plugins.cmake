include(plugins.macros.cmake)

#
# FilePlugin
#
message(STATUS "Adding plugin: FilePlugin")

if(OSX)
    include_directories(
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/FilePlugin/include/common
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/FilePlugin/include/osx
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/FilePlugin/include/unix
    )
    
    file(GLOB FilePlugin_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/FilePlugin/src/common/*.c
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/FilePlugin/src/unix/*.c
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/unix/sqUnixCharConv.c        
        ${CMAKE_CURRENT_SOURCE_DIR}/src/fileUtils.c
    )
elseif(UNIX)
    include_directories(
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/FilePlugin/include/common
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/FilePlugin/include/unix
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/include/unix
    )
    
    file(GLOB FilePlugin_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/FilePlugin/src/common/*.c
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/FilePlugin/src/unix/*.c
        ${CMAKE_CURRENT_SOURCE_DIR}/src/fileUtils.c
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/unix/sqUnixCharConv.c
    )    
else()
    include_directories(
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/FilePlugin/include/common
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/FilePlugin/include/win
    )
    
    file(GLOB FilePlugin_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/FilePlugin/src/win/*.c
        ${CMAKE_CURRENT_SOURCE_DIR}/src/fileUtilsWin.c
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/win/sqWin32Directory.c        
    )    
endif()

addLibraryWithRPATH(FilePlugin
    ${FilePlugin_SOURCES}
    ${PHARO_CURRENT_GENERATED}/plugins/src/FilePlugin/FilePlugin.c)

if(OSX)
    target_link_libraries(FilePlugin PRIVATE "-framework CoreFoundation")
endif()

if(WIN)
    target_compile_definitions(FilePlugin PRIVATE "-DWIN32_FILE_SUPPORT")
endif()


#
# FileAttributesPlugin
#
add_vm_plugin(FileAttributesPlugin)
target_link_libraries(FileAttributesPlugin PRIVATE FilePlugin)

#
# UUIDPlugin
#

message(STATUS "Adding plugin: UUIDPlugin")

file(GLOB UUIDPlugin_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/plugins/UUIDPlugin/common/*.c   
)

addLibraryWithRPATH(UUIDPlugin ${UUIDPlugin_SOURCES})
if(WIN)
    target_link_libraries(UUIDPlugin PRIVATE "-lole32")
elseif(UNIX AND NOT OSX)
   #find_path(LIB_UUID_INCLUDE_DIR uuid.h PATH_SUFFIXES uuid)
    find_library(LIB_UUID_LIBRARY uuid)
    message(STATUS "Using uuid library:" ${LIB_UUID_LIBRARY}) 
    target_link_libraries(UUIDPlugin PRIVATE ${LIB_UUID_LIBRARY})
endif()

#
# Socket Plugin
#
if (${FEATURE_NETWORK})
    add_vm_plugin(SocketPlugin)
  if(WIN)
    target_link_libraries(SocketPlugin PRIVATE "-lWs2_32")
  endif()
endif()

#
# Surface Plugin
#

add_vm_plugin(SurfacePlugin)

#
# SqueakFFIPrims Plugin
#

#
# This solution is not portable to different architectures!
#

if(${FEATURE_FFI})

message(STATUS "Adding plugin: SqueakFFIPrims")

set(SqueakFFIPrims_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakFFIPrims/src/common/SqueakFFIPrims.c 
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakFFIPrims/src/common/sqManualSurface.c
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakFFIPrims/src/common/sqFFIPlugin.c
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakFFIPrims/src/common/sqFFITestFuncs.c
)
addLibraryWithRPATH(SqueakFFIPrims ${SqueakFFIPrims_SOURCES})
target_include_directories(SqueakFFIPrims 
PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakFFIPrims/include/common
)


#
# IA32ABI Plugin
#

set(IA32ABI_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/IA32ABI/src/common/IA32ABI.c 
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/IA32ABI/src/common/AlienSUnitTestProcedures.c
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/IA32ABI/src/common/xabicc.c
)
# Only add this file for Win x86_64
if(WIN AND CMAKE_SYSTEM_PROCESSOR MATCHES x86_64)
    set(IA32ABI_SOURCES
        ${IA32ABI_SOURCES}
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/IA32ABI/src/common/x64win64stub.c
    )
endif()

addLibraryWithRPATH(IA32ABI ${IA32ABI_SOURCES})

target_include_directories(IA32ABI
    PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/IA32ABI/include/common
)

target_link_libraries(IA32ABI PRIVATE ${VM_LIBRARY_NAME})

endif()


#
# LargeIntegers Plugin
#

add_vm_plugin(LargeIntegers)

#
# JPEGReaderPlugin
#

add_vm_plugin(JPEGReaderPlugin)

#
# JPEGReadWriter2Plugin
#

add_vm_plugin(JPEGReadWriter2Plugin)


#
# MiscPrimitivePlugin
#

add_vm_plugin(MiscPrimitivePlugin)

#
# BitBltPlugin
#

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/BitBltPlugin/include/common
)

set(BitBltPlugin_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/BitBltPlugin/src/common/BitBltPlugin.c   
)

addLibraryWithRPATH(BitBltPlugin ${BitBltPlugin_SOURCES})

#
# B2DPlugin
#

add_vm_plugin(B2DPlugin)

#
# LocalePlugin
#

message(STATUS "Adding plugin: LocalePlugin")

if(OSX)
    include_directories(
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/LocalePlugin/include/common
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/LocalePlugin/include/osx
    )
    
    file(GLOB LocalePlugin_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/LocalePlugin/src/common/*.c
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/LocalePlugin/src/osx/*.c   
    )
elseif(UNIX)
    include_directories(
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/LocalePlugin/include/common
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/LocalePlugin/include/unix
    )
    
    file(GLOB LocalePlugin_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/LocalePlugin/src/common/*.c
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/LocalePlugin/src/unix/*.c   
    )    
else()
    include_directories(
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/LocalePlugin/include/common
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/LocalePlugin/include/win
    )
    
    file(GLOB LocalePlugin_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/LocalePlugin/src/common/*.c
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/LocalePlugin/src/win/*.c   
    )    
endif()

addLibraryWithRPATH(LocalePlugin ${LocalePlugin_SOURCES})

if(OSX)
	target_link_libraries(LocalePlugin PRIVATE "-framework CoreFoundation")
endif()

#
# SqueakSSL
#

message(STATUS "Adding plugin: SqueakSSL")

if(OSX)
    include_directories(
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakSSL/include/common
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakSSL/include/osx
    )
    
    file(GLOB SqueakSSL_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakSSL/src/common/*.c
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakSSL/src/osx/*.c   
    )
else()
    if(WIN)
        include_directories(
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakSSL/include/common
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakSSL/include/win
        )
        
        file(GLOB SqueakSSL_SOURCES
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakSSL/src/common/*.c
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakSSL/src/win/*.c   
        )    
    else()
        include_directories(
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakSSL/include/common
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakSSL/include/unix
        )
        
        file(GLOB SqueakSSL_SOURCES
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakSSL/src/common/*.c
            ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakSSL/src/unix/*.c   
        )
    endif()
endif()

addLibraryWithRPATH(SqueakSSL ${SqueakSSL_SOURCES})

if(OSX)
    target_link_libraries(SqueakSSL PRIVATE "-framework CoreFoundation")
    target_link_libraries(SqueakSSL PRIVATE "-framework Security")
elseif(WIN)
    target_link_libraries(SqueakSSL PRIVATE Crypt32 Secur32)
else()
    find_package(OpenSSL REQUIRED)
    target_link_libraries(SqueakSSL PRIVATE OpenSSL::SSL OpenSSL::Crypto)    
endif()


#
# DSAPrims
#
add_vm_plugin(DSAPrims)

#
# UnixOSProcessPlugin
#

if(NOT WIN)
    add_vm_plugin(UnixOSProcessPlugin)
    target_link_libraries(UnixOSProcessPlugin PRIVATE FilePlugin)
endif()
