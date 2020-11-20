find_package(SDL2)

if (SDL2_FOUND)
	# Do nothing! We have it!
elseif (NOT WITHOUT_DEPENDENCIES)

	include(cmake/DownloadProject.cmake)

	if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  	set(SHOULD_BUILD_SDL FALSE)
	else()
  	set(SHOULD_BUILD_SDL TRUE)
	endif()

	if (SHOULD_BUILD_SDL)
    message(STATUS "SDL2 not found.")
    message(STATUS "Building SDL2")
    download_project(PROJ SDL2
        URL         https://libsdl.org/release/SDL2-2.0.12.tar.gz
        URL_HASH    MD5=783b6f2df8ff02b19bb5ce492b99c8ff
        ${UPDATE_DISCONNECTED_IF_AVAILABLE}
    )
    add_subdirectory(${SDL2_SOURCE_DIR} ${SDL2_BINARY_DIR} EXCLUDE_FROM_ALL)

    set_target_properties(SDL2 PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${EXECUTABLE_OUTPUT_PATH})
	endif()

	add_dependencies(${VM_LIBRARY_NAME} SDL2)
endif()

#add_third_party_dependency("SDL2-2.0.5" "build/vm")
