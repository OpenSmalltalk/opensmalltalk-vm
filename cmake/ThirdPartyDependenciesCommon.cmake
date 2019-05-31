if(WIN32)
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/WindowsRuntimeLibraries.cmake")
endif()

if(PHARO_VM OR (SUPPORT_TRADITIONAL_DISPLAY AND ALLOW_SDL2))
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/SDL2.cmake")
endif()
