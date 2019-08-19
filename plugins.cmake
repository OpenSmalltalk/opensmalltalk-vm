include(plugins.macros.cmake)

#
# SecurityPlugin - Dummy Version
#

message(STATUS "Adding plugin: SecurityPlugin")    

file(GLOB SecurityPlugin_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/plugins/SecurityPlugin/common/*.c   
)

addLibraryWithRPATH(SecurityPlugin ${SecurityPlugin_SOURCES})
target_link_libraries(SecurityPlugin ${VM_LIBRARY_NAME})

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
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/FilePlugin/src/common/FilePlugin.c
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/FilePlugin/src/win/*.c   
        ${CMAKE_CURRENT_SOURCE_DIR}/src/fileUtilsWin.c
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/vm/src/win/sqWin32Directory.c        
    )    
endif()

addLibraryWithRPATH(FilePlugin ${FilePlugin_SOURCES})
target_link_libraries(FilePlugin ${VM_LIBRARY_NAME})

if(OSX)
    target_link_libraries(FilePlugin "-framework CoreFoundation")
endif()

if(WIN)
    target_compile_definitions(FilePlugin PUBLIC "-DWIN32_FILE_SUPPORT")
endif()


#
# FileAttributesPlugin
#

add_vm_plugin(FileAttributesPlugin)
target_link_libraries(FileAttributesPlugin FilePlugin)

#
# UUIDPlugin
#

message(STATUS "Adding plugin: UUIDPlugin")

file(GLOB UUIDPlugin_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/plugins/UUIDPlugin/common/*.c   
)

addLibraryWithRPATH(UUIDPlugin ${UUIDPlugin_SOURCES})
target_link_libraries(UUIDPlugin ${VM_LIBRARY_NAME})
if(WIN)
    target_link_libraries(UUIDPlugin "-lole32")
endif()
#
# Socket Plugin
# 

if(WIN)
    add_vm_plugin(SocketPlugin ${CMAKE_CURRENT_SOURCE_DIR}/plugins/SocketPlugin/win32/src/win32SocketPluginExtras.c)
    target_link_libraries(SocketPlugin "-lWs2_32")
else()
    add_vm_plugin(SocketPlugin)
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

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakFFIPrims/include/common
)

set(SqueakFFIPrims_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakFFIPrims/src/common/SqueakFFIPrims.c 
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakFFIPrims/src/common/sqManualSurface.c
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakFFIPrims/src/common/sqFFIPlugin.c
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/SqueakFFIPrims/src/common/sqFFITestFuncs.c
)

addLibraryWithRPATH(SqueakFFIPrims ${SqueakFFIPrims_SOURCES})
target_link_libraries(SqueakFFIPrims ${VM_LIBRARY_NAME})

#
# IA32ABI Plugin
#

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/IA32ABI/include/common
)

set(IA32ABI_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/IA32ABI/src/common/IA32ABI.c 
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/IA32ABI/src/common/AlienSUnitTestProcedures.c
    ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/IA32ABI/src/common/xabicc.c
)

if(WIN)
    set(IA32ABI_SOURCES
        ${IA32ABI_SOURCES}
        ${CMAKE_CURRENT_SOURCE_DIR}/extracted/plugins/IA32ABI/src/common/x64win64stub.c
    )
endif()

addLibraryWithRPATH(IA32ABI ${IA32ABI_SOURCES})
target_link_libraries(IA32ABI ${VM_LIBRARY_NAME})

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
target_link_libraries(BitBltPlugin ${VM_LIBRARY_NAME})

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
target_link_libraries(LocalePlugin ${VM_LIBRARY_NAME})

if(OSX)
    target_link_libraries(LocalePlugin "-framework CoreFoundation")
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
target_link_libraries(SqueakSSL ${VM_LIBRARY_NAME})

if(OSX)
    target_link_libraries(SqueakSSL "-framework CoreFoundation")
    target_link_libraries(SqueakSSL "-framework Security")
elseif(WIN)
    target_link_libraries(SqueakSSL "-lSecur32")
    target_link_libraries(SqueakSSL "-lCrypt32")
else()
    target_link_libraries(SqueakSSL "-lssl")    
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
    target_link_libraries(UnixOSProcessPlugin FilePlugin)
endif()