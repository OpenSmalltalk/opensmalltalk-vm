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
    set(VM_PLUGIN_${NAME}_TYPE ${TYPE})
    option(BUILD_PLUGIN_${NAME} "Build plugin ${NAME}" ON)
    if(BUILD_PLUGIN_${NAME})
        if("${TYPE}" STREQUAL "INTERNAL")
            set(VM_INTERNAL_PLUGINS_INC_SOURCES "${VM_INTERNAL_PLUGINS_INC_SOURCES}\nINTERNAL_PLUGIN(${NAME})")
            set(VM_INTERNAL_PLUGIN_SOURCES ${VM_PLUGIN_${NAME}_SOURCES} ${VM_INTERNAL_PLUGIN_SOURCES})
            source_group("Internal Plugins\\${NAME}" FILES ${VM_PLUGIN_${NAME}_SOURCES})
        else()
            if(NOT ONLY_CONFIG_H)
                add_library(${NAME} SHARED ${ARGN})
            endif()
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
    add_vm_plugin_sources(${NAME} ${TYPE} ${PLUGIN_SOURCES} ${ARGN})
endmacro()

macro(vm_plugin_link_libraries NAME)
    if(VM_PLUGIN_${NAME}_TYPE STREQUAL "EXTERNAL")
        if(NOT ONLY_CONFIG_H)
            target_link_libraries(${NAME} ${ARGN})
        endif()
    else()
        set(VM_DEPENDENCIES_LIBRARIES ${ARGN} ${VM_DEPENDENCIES_LIBRARIES})
    endif()
endmacro()

# The sources of the FFI plugin are special.
set(SqueakFFIPrims_Sources
    "${CrossPlatformPluginFolder}/SqueakFFIPrims/sqFFI.h"
    "${CrossPlatformPluginFolder}/SqueakFFIPrims/sqFFIPlugin.c"
    "${CrossPlatformPluginFolder}/SqueakFFIPrims/sqFFITestFuncs.c"
    "${CrossPlatformPluginFolder}/SqueakFFIPrims/sqManualSurface.c"
    "${PluginsSourceFolderName}/SqueakFFIPrims/SqueakFFIPrims.c"
)

add_vm_plugin_sources(SqueakFFIPrims INTERNAL ${SqueakFFIPrims_Sources})

# The sources of the IA32ABI plugin are special.
set(IA32ABI_Sources
    "${CrossPlatformPluginFolder}/IA32ABI/AlienSUnitTestProcedures.c"
    "${CrossPlatformPluginFolder}/IA32ABI/xabicc.c"
    "${CrossPlatformPluginFolder}/IA32ABI/x64win64stub.c"
    "${PluginsSourceFolderName}/IA32ABI/IA32ABI.c"
)

add_vm_plugin_sources(IA32ABI INTERNAL ${IA32ABI_Sources})

# Basic internal plugins
add_vm_plugin_auto(FilePlugin INTERNAL)
add_vm_plugin_auto(LargeIntegers INTERNAL)
add_vm_plugin_auto(LocalePlugin INTERNAL)
add_vm_plugin_auto(MiscPrimitivePlugin INTERNAL)
add_vm_plugin_auto(SecurityPlugin INTERNAL)
add_vm_plugin_auto(SocketPlugin INTERNAL)
if(WIN32)
    vm_plugin_link_libraries(SocketPlugin Ws2_32)
endif()

add_vm_plugin_auto(B2DPlugin INTERNAL)
add_vm_plugin_sources(BitBltPlugin INTERNAL
    "${PluginsSourceFolderName}/BitBltPlugin/BitBltPlugin.c"
)

add_vm_plugin_auto(FloatArrayPlugin INTERNAL)
add_vm_plugin_auto(FloatMathPlugin INTERNAL)
add_vm_plugin_auto(Matrix2x3Plugin INTERNAL)

# Basic external plugins
add_vm_plugin_auto(SurfacePlugin EXTERNAL)
add_vm_plugin_auto(FileAttributesPlugin EXTERNAL)

# Drop plugin
add_vm_plugin_sources(DropPlugin INTERNAL
    "${PluginsSourceFolderName}/DropPlugin/DropPlugin.c"
)

# Extra plugins
add_vm_plugin_auto(ZipPlugin INTERNAL) # Used by Monticello

if(PHARO_VM)
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/PluginsPharo.cmake")
elseif(SQUEAK_VM)
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/PluginsSqueak.cmake")
endif()

# Write the list of plugins.
file(WRITE ${CMAKE_BINARY_DIR}/sqInternalPlugins.inc
${VM_INTERNAL_PLUGINS_INC_SOURCES})
