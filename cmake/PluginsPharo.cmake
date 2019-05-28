# Plugin that are only used by Pharo

if(NOT MINIMAL_PLUGIN_SET)

add_vm_plugin_auto(EventsHandlerPlugin EXTERNAL)
allow_plugin_undefined_symbols(EventsHandlerPlugin _ioProcessEventsHandler _setIoProcessEventsHandler _vmIOProcessEvents)
if(HAVE_SDL2)
    add_vm_plugin_auto(SDL2DisplayPlugin EXTERNAL)
	allow_plugin_undefined_symbols(SDL2DisplayPlugin _setIoProcessEventsHandler)
    vm_plugin_link_libraries(SDL2DisplayPlugin ${SDL2_LIBRARIES})
	if(SDL2_BuildDep)
		add_dependencies(SDL2DisplayPlugin ${SDL2_BuildDep})
	endif()
endif()

# Free type plugin
# Prefer freetype version that we build
if(NOT HAVE_FreeType2)
	find_package(Freetype)
	if(FREETYPE_FOUND)
		include_directories(${FREETYPE_INCLUDE_DIRS})
		set(HAVE_FreeType2 TRUE CACHE INTERNAL "Do we have FreeType?")
		set(FreeType2_LIBRARIES "${FREETYPE_LIBRARIES}" CACHE STRING "Do we have FreeType?")
	endif()
endif()

if(HAVE_FreeType2)
    add_vm_plugin_auto(FT2Plugin EXTERNAL)
	if(FreeType2_BuildDep)
		add_dependencies(FT2Plugin ${FreeType2_BuildDep})
	endif()
    vm_plugin_link_libraries(FT2Plugin ${FreeType2_LIBRARIES})
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
