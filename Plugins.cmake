set(CrossPlatformPluginFolder platforms/Cross/plugins)
if (WIN32)
    set(PlatformPluginFolder platforms/win32/plugins)
elseif(UNIX)
    set(PlatformPluginFolder platforms/unix/plugins)
else()
    set(PlatformPluginFolder)
endif()

set(VM_INTERNAL_PLUGINS_INC_SOURCES "")

macro(add_vm_plugin NAME TYPE)
    set(VM_PLUGIN_${NAME}_SOURCES ${ARGN})
    option(BUILD_PLUGIN_${NAME} "Build plugin ${NAME}" ON)
    if(BUILD_PLUGIN_${NAME})
        if("${TYPE}" STREQUAL "INTERNAL")
            set(VM_INTERNAL_PLUGINS_INC_SOURCES "${VM_INTERNAL_PLUGINS_INC_SOURCES}\nINTERNAL_PLUGIN(${NAME})")
            set(VM_INTERNAL_PLUGIN_SOURCES ${VM_PLUGIN_${NAME}_SOURCES} ${VM_INTERNAL_PLUGIN_SOURCES})
        else()
            add_library(${NAME} SHARED ${ARGN})
        endif()
    endif()
endmacro()

macro(add_vm_plugin_sources NAME TYPE)
    include_directories(
        "${PluginsSourceFolderName}/${NAME}"
        "${PlatformPluginFolder}/${NAME}"
        "${CrossPlatformPluginFolder}/${NAME}"
    )
    add_vm_plugin(${NAME} ${TYPE} ${ARGN})
endmacro()

macro(add_vm_plugin_auto NAME TYPE)
    file(GLOB PLUGIN_SOURCES
        "${PluginsSourceFolderName}/${NAME}/*.c"
        "${PlatformPluginFolder}/${NAME}/*.c"
        "${PlatformPluginFolder}/${NAME}/*.h"
        "${CrossPlatformPluginFolder}/${NAME}/*.c"
        "${CrossPlatformPluginFolder}/${NAME}/*.h"
    )
    add_vm_plugin_sources(${NAME} ${TYPE} ${PLUGIN_SOURCES})
endmacro()

# The sources of the FFI plugin are special.
set(SqueakFFIPrims_Sources
    "${CrossPlatformPluginFolder}/SqueakFFIPrims/sqFFI.h"
    "${CrossPlatformPluginFolder}/SqueakFFIPrims/sqFFIPlugin.c"
    "${CrossPlatformPluginFolder}/SqueakFFIPrims/sqManualSurface.c"
)

if(FFI_VARIANT_IA32)
    set(SqueakFFIPrims_Sources
        "${PluginsSourceFolderName}/SqueakFFIPrims/IA32FFIPlugin.c"
        ${SqueakFFIPrims_Sources}
    )
elseif(FFI_VARIANT_X64_WIN64)
    set(SqueakFFIPrims_Sources
        "${PluginsSourceFolderName}/SqueakFFIPrims/X64Win64FFIPlugin.c"
        ${SqueakFFIPrims_Sources}
    )
elseif(FFI_VARIANT_X64_SYSV)
    set(SqueakFFIPrims_Sources
        "${PluginsSourceFolderName}/SqueakFFIPrims/X64SysVFFIPlugin.c"
        ${SqueakFFIPrims_Sources}
    )
else()
    message("TODO: Add the source of the current architecture FFI e.g. ARM, PPC, MIPS, etc...")
endif()

add_vm_plugin_sources(SqueakFFIPrims EXTERNAL ${SqueakFFIPrims_Sources})

# Basic internal plugins
add_vm_plugin_auto(FilePlugin INTERNAL)
add_vm_plugin_auto(LargeIntegers INTERNAL)
add_vm_plugin_auto(LocalePlugin INTERNAL)
add_vm_plugin_auto(MiscPrimitivePlugin INTERNAL)
add_vm_plugin_auto(SecurityPlugin INTERNAL)
add_vm_plugin_auto(SocketPlugin INTERNAL)

add_vm_plugin_auto(B2DPlugin INTERNAL)
add_vm_plugin_auto(BitBltPlugin INTERNAL)

# Basic external plugins
add_vm_plugin_auto(SurfacePlugin EXTERNAL)

# Free type plugin
find_package(Freetype)
if(FREETYPE_FOUND)
    include_directories(${FREETYPE_INCLUDE_DIRS})
    add_vm_plugin_auto(FT2Plugin EXTERNAL)
    target_link_libraries(FT2Plugin ${FREETYPE_LIBRARIES})
endif()

# OSProcess
if(UNIX)
    add_definitions(
        -D_XOPEN_SOURCE=700
        -D_XOPEN_SOURCE_EXTENDED=1
        -D_DEFAULT_SOURCE=1
    )
    add_vm_plugin_auto(UnixOSProcessPlugin INTERNAL)
endif()

# Write the list of plugins.
file(WRITE ${CMAKE_BINARY_DIR}/sqInternalPlugins.inc
${VM_INTERNAL_PLUGINS_INC_SOURCES})
