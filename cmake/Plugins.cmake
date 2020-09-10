include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/PluginsMacros.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/PluginsCommon.cmake")

if(PHARO_VM)
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/PluginsPharo.cmake")
elseif(SQUEAK_VM)
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/PluginsSqueak.cmake")
endif()

# Write the list of plugins.
file(WRITE ${CMAKE_BINARY_DIR}/sqInternalPlugins.inc
${VM_INTERNAL_PLUGINS_INC_SOURCES})
