# Plugin that are only used by Pharo

if(NOT MINIMAL_PLUGIN_SET)

add_vm_plugin_auto(EventsHandlerPlugin EXTERNAL)
allow_plugin_undefined_symbols(EventsHandlerPlugin _ioProcessEventsHandler _setIoProcessEventsHandler _vmIOProcessEvents)

if(HAVE_SDL2)
    add_vm_plugin_auto(SDL2DisplayPlugin EXTERNAL)
	allow_plugin_undefined_symbols(SDL2DisplayPlugin _setIoProcessEventsHandler)
    vm_plugin_link_libraries(SDL2DisplayPlugin ${SDL2_LIBRARIES})
	if(SDL2_BuildDep AND (NOT WIN32))
		add_dependencies(SDL2DisplayPlugin ${SDL2_BuildDep})
	endif()
endif()

# Pharo is not using the FreeType plugin anymore.
#include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/FT2Plugin.cmake")

# OSProcess
if(UNIX)
    if(NOT APPLE)
        add_vm_plugin_auto(VMProfileLinuxSupportPlugin INTERNAL)
    endif()
    add_vm_plugin_auto(UnixOSProcessPlugin INTERNAL)
endif()
if(WIN32)
    add_vm_plugin_auto(Win32OSProcessPlugin INTERNAL)
endif()

endif(NOT MINIMAL_PLUGIN_SET)
