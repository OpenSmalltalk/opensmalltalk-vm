function(find_system_ffi)
  message(STATUS "Looking for FFI in the system")
  find_package(FFI)
  if(FFI_FOUND)
	target_link_libraries(${VM_LIBRARY_NAME} FFI::lib)
  else()
    message(STATUS "FFI not found.")
  endif()
  set(FFI_FOUND ${FFI_FOUND} PARENT_SCOPE)
endfunction()

function(build_ffi)
	message(STATUS "Building FFI")
	include(cmake/DownloadProject.cmake)

	download_project(PROJ                libffi
                 GIT_REPOSITORY      https://github.com/guillep/libffi.git
                 GIT_TAG             "v3.3-cmake"
                 ${UPDATE_DISCONNECTED_IF_AVAILABLE}
	)

	add_subdirectory(${libffi_SOURCE_DIR} ${libffi_BINARY_DIR} EXCLUDE_FROM_ALL)

	if(CYGWIN)
		set_target_properties(objlib PROPERTIES POSITION_INDEPENDENT_CODE OFF)
	endif()

	set_target_properties(ffi_shared PROPERTIES MACOSX_RPATH ON)
	set_target_properties(ffi_shared PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${EXECUTABLE_OUTPUT_PATH})
	set_target_properties(ffi_shared PROPERTIES INSTALL_NAME_DIR "@executable_path/Plugins")

	# libffi cmakelists does not correctly export the library includes
	# so we have to make it ourselves...
	include_directories("${libffi_BINARY_DIR}/include")

	add_library(libFFI ALIAS ffi_shared)
	target_link_libraries(${VM_LIBRARY_NAME} ffi_shared)
endfunction()

if(PHARO_DEPENDENCIES_PREFER_DOWNLOAD_BINARIES)
  #Download FFI binaries directly
  build_FFI()
else()
  #Look for FFI in the system, then build or download if possible
  find_system_FFI()
  if(NOT FFI_FOUND)
    build_FFI()
  endif()
endif()