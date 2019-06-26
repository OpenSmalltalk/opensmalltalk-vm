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
