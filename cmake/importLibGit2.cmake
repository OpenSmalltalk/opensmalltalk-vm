function(find_system_git2)
  message(STATUS "Looking for Git2 in the system")
  find_package(LibGit2)
  if(LIBGIT2_FOUND)
    add_dependencies(${VM_LIBRARY_NAME} git2)
  else()
    message(STATUS "Git2 not found.")
  endif()
  set(LIBGIT2_FOUND ${LIBGIT2_FOUND} PARENT_SCOPE)
endfunction()

function(download_git2)
  message(STATUS "Downloading Git2 binary")
  if(WIN)
    add_third_party_dependency("libgit2-win-1.0.0" "build/vm")
    add_third_party_dependency("libgit2-0.25.1-fixLibGit" "build/vm")    
    add_third_party_dependency("zlib-1.2.11-fixLibGit" "build/vm")
    add_third_party_dependency("openssl-1.0.2q-fixLigGit" "build/vm")
    add_third_party_dependency("libssh2-1.9.0" "build/vm")
  elseif(OSX)
    add_third_party_dependency("libgit2-0.25.1" ${LIBRARY_OUTPUT_DIRECTORY})
    add_third_party_dependency("libgit2-mac-1.0.0" ${LIBRARY_OUTPUT_DIRECTORY})
    add_third_party_dependency("libssh2-1.7.0" ${LIBRARY_OUTPUT_DIRECTORY})
    add_third_party_dependency("openssl-1.0.2q" ${LIBRARY_OUTPUT_DIRECTORY})    
  else()
    add_third_party_dependency("libgit2-0.25.1" "build/vm")
    add_third_party_dependency_with_baseurl("libgit2-linux-1.0.0" "build/vm" "https://github.com/guillep/libgit_build/releases/download/v1.0.2/")
    add_third_party_dependency("libssh2-1.7.0" "build/vm")
    add_third_party_dependency("openssl-1.0.2q" "build/vm")
  endif()
endfunction()

function(build_git2)
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

	if(WIN)
		add_dependencies(git2 libgit2_copy)
	endif()
endfunction()

if (DOWNLOAD_DEPENDENCIES)
  #Only get Git2 if required
  if(PHARO_DEPENDENCIES_PREFER_DOWNLOAD_BINARIES)
    #Download LibGit2 binaries directly
    download_git2()
  else()
    #Look for Git2 in the system, then build or download if possible
    find_system_git2()
    if(NOT LIBGIT2_FOUND)
      build_git2()
    endif()
  endif()
endif()

