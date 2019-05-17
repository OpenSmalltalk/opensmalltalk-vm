set(CrossPlatformPluginFolder platforms/Cross/plugins)
if (WIN32)
    set(PlatformPluginFolder platforms/win32/plugins)
elseif(UNIX)
    set(PlatformPluginFolder platforms/unix/plugins)
else()
    set(PlatformPluginFolder)
endif()

set(VM_INTERNAL_PLUGINS_INC_SOURCES "")
set(VM_EXTERNAL_PLUGINS_TARGETS)

macro(add_vm_plugin NAME TYPE)
    set(VM_PLUGIN_${NAME}_SOURCES ${ARGN})
    set(VM_PLUGIN_${NAME}_TYPE ${TYPE})
    option(BUILD_PLUGIN_${NAME} "Build plugin ${NAME}" ON)

    # HACK: External plugins are not yet properly implemented on Windows.
    if(WIN32)
        set(VM_PLUGIN_${NAME}_TYPE INTERNAL)
    endif()
    
    if(BUILD_PLUGIN_${NAME})
        if("${VM_PLUGIN_${NAME}_TYPE}" STREQUAL "INTERNAL")
            set(VM_INTERNAL_PLUGINS_INC_SOURCES "${VM_INTERNAL_PLUGINS_INC_SOURCES}\nINTERNAL_PLUGIN(${NAME})")
            set(VM_INTERNAL_PLUGIN_SOURCES ${VM_PLUGIN_${NAME}_SOURCES} ${VM_INTERNAL_PLUGIN_SOURCES})
            source_group("Internal Plugins\\${NAME}" FILES ${VM_PLUGIN_${NAME}_SOURCES})
        else()
            if(NOT ONLY_CONFIG_H)
                add_library(${NAME} MODULE ${ARGN})
                set(VM_EXTERNAL_PLUGINS_TARGETS ${VM_EXTERNAL_PLUGINS_TARGETS} ${NAME})
                if(DARWIN)
                    if(BUILD_PLUGINS_AS_BUNDLES)
                        set_target_properties(${NAME} PROPERTIES BUNDLE TRUE)
                    else()
                        set_target_properties(${NAME} PROPERTIES SUFFIX ".dylib")
                    endif()
                endif()
            endif()
        endif()
    endif()
endmacro()

macro(allow_plugin_undefined_symbols NAME)
    if("${VM_PLUGIN_${NAME}_TYPE}" STREQUAL "EXTERNAL")
        if(DARWIN)
            foreach(symbol ${ARGN})
                target_link_libraries(${NAME} "-Wl,-U,${symbol}")
            endforeach()
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
