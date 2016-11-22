set(CrossPlatformPluginFolder platforms/Cross/plugins)
if (WIN32)
    set(PlatformPluginFolder platforms/win32/plugins)
elseif(UNIX)
    set(PlatformPluginFolder platforms/unix/plugins)
else()
    set(PlatformPluginFolder)
endif()

macro(add_vm_plugin NAME TYPE)
    set(VM_PLUGIN_${NAME}_SOURCES ${ARGN})
    if("${TYPE}" STREQUAL "INTERNAL")
        set(VM_INTERNAL_PLUGIN_SOURCES ${VM_PLUGIN_${NAME}_SOURCES} ${VM_INTERNAL_PLUGIN_SOURCES})
    else()
    endif()
endmacro()

macro(add_vm_plugin_auto NAME TYPE)
    include_directories(
        "${PluginsSourceFolderName}/${NAME}"
        "${PlatformPluginFolder}/${NAME}"
        "${CrossPlatformPluginFolder}/${NAME}"
    )
    file(GLOB PLUGIN_SOURCES
        "${PluginsSourceFolderName}/${NAME}/*.c"
        "${PlatformPluginFolder}/${NAME}/*.c"
        "${PlatformPluginFolder}/${NAME}/*.h"
        "${CrossPlatformPluginFolder}/${NAME}/*.c"
        "${CrossPlatformPluginFolder}/${NAME}/*.h"
    )
    add_vm_plugin(${NAME} ${TYPE} ${PLUGIN_SOURCES})
endmacro()

# Basic plugins
add_vm_plugin_auto(FilePlugin INTERNAL)
add_vm_plugin_auto(LargeIntegers INTERNAL)
add_vm_plugin_auto(LocalePlugin INTERNAL)
add_vm_plugin_auto(MiscPrimitivePlugin INTERNAL)
add_vm_plugin_auto(SecurityPlugin INTERNAL)
