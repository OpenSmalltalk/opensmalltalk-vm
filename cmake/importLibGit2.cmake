find_package(LibGit2)

if (NOT LibGit2_FOUND)
	message(STATUS "LibGit2 not found in the system")

    message(STATUS "Building LibGit2 with LibSSH 1.9.0")

    include(cmake/DownloadProject.cmake)

    download_project(PROJ LibSSH2
        GIT_REPOSITORY      https://github.com/libssh2/libssh2.git
        GIT_TAG             "libssh2-1.9.0"
        ${UPDATE_DISCONNECTED_IF_AVAILABLE}
    )

    download_project(PROJ LibGit2
        GIT_REPOSITORY      https://github.com/libgit2/libgit2.git
        GIT_TAG             "v1.0.1"
        ${UPDATE_DISCONNECTED_IF_AVAILABLE}
    )

     # Make subproject to use 'BUILD_SHARED_LIBS=ON' setting.
    set(BUILD_CLAR OFF CACHE INTERNAL "Build SHARED libraries")
    set(EMBED_SSH_PATH "${LibSSH2_SOURCE_DIR}" CACHE INTERNAL "Libssh2 sources path")
    add_subdirectory(${LibGit2_SOURCE_DIR} ${LibGit2_BINARY_DIR} EXCLUDE_FROM_ALL)
    unset(BUILD_CLAR)

    #set_target_properties(${NAME} PROPERTIES MACOSX_RPATH ON)
    add_custom_target(libgit2_copy
      COMMAND ${CMAKE_COMMAND} -E copy_if_different ${LibGit2_BINARY_DIR}/Debug/git2.dll ${EXECUTABLE_OUTPUT_PATH}/Debug/build/vm
      
      COMMENT "Copying Libgit binaries from '${LibGit2_BINARY_DIR}' to '${EXECUTABLE_OUTPUT_PATH}'" VERBATIM
    )
    #set_target_properties(${NAME} PROPERTIES INSTALL_NAME_DIR "@executable_path/Plugins")
endif()
add_dependencies(git2 libgit2_copy)
add_dependencies(${VM_LIBRARY_NAME} git2)

# Libgit2 dependencies
# add_third_party_dependency("libgit2-win-1.0.0" "build/vm")
# add_third_party_dependency("libgit2-0.25.1-fixLibGit" "build/vm")