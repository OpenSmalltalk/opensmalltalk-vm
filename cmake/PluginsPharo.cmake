# Plugin that are only used by Pharo

if(NOT MINIMAL_PLUGIN_SET)
	
add_vm_plugin_auto(EventsHandlerPlugin EXTERNAL)
allow_plugin_undefined_symbols(EventsHandlerPlugin _ioProcessEventsHandler _setIoProcessEventsHandler _vmIOProcessEvents)
if(HAVE_SDL2)
    add_vm_plugin_auto(SDL2DisplayPlugin EXTERNAL)
    vm_plugin_link_libraries(SDL2DisplayPlugin ${SDL2_LIBRARY})
endif()

# Free type plugin
find_package(Freetype)
if(FREETYPE_FOUND)
    include_directories(${FREETYPE_INCLUDE_DIRS})
    add_vm_plugin_auto(FT2Plugin EXTERNAL)
    vm_plugin_link_libraries(FT2Plugin ${FREETYPE_LIBRARIES})
endif()

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
