find_package(Freetype)

if (Freetype_FOUND)
	add_dependencies(${VM_LIBRARY_NAME} Freetype::Freetype)
elseif (NOT WITHOUT_DEPENDENCIES)
	message(STATUS "Freetype not found in the system")

    message(STATUS "Building Freetype")

    include(cmake/DownloadProject.cmake)

    download_project(PROJ                freetype
                 URL      https://download.savannah.gnu.org/releases/freetype/freetype-2.10.0.tar.gz
                 ${UPDATE_DISCONNECTED_IF_AVAILABLE}
    )

    set(DISABLE_FORCE_DEBUG_POSTFIX ON)

    # Store the old value of the 'BUILD_SHARED_LIBS'
    set(BUILD_SHARED_LIBS_OLD ${BUILD_SHARED_LIBS})
    # Make subproject to use 'BUILD_SHARED_LIBS=ON' setting.
    set(BUILD_SHARED_LIBS ON CACHE INTERNAL "Build SHARED libraries")

    add_subdirectory(${freetype_SOURCE_DIR} ${freetype_BINARY_DIR} EXCLUDE_FROM_ALL)

    # Restore the old value of the parameter
    set(BUILD_SHARED_LIBS ${BUILD_SHARED_LIBS_OLD} CACHE BOOL "Type of libraries to build" FORCE)
    
    #set_target_properties(${NAME} PROPERTIES MACOSX_RPATH ON)
    set_target_properties(freetype PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${EXECUTABLE_OUTPUT_PATH})
    #set_target_properties(${NAME} PROPERTIES INSTALL_NAME_DIR "@executable_path/Plugins")

	add_dependencies(${VM_LIBRARY_NAME} freetype)
else()
 	message(FATAL_ERROR "Freetype not found")
endif()


# add_third_party_dependency("freetype-2.9.1" "build/vm")
