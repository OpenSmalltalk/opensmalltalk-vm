find_package(FFI)

if (FFI_FOUND)
	target_link_libraries(${VM_LIBRARY_NAME} FFI::lib)
elseif (NOT WITHOUT_DEPENDENCIES)
	include(cmake/DownloadProject.cmake)

	download_project(PROJ                libffi
                 GIT_REPOSITORY      https://github.com/guillep/libffi.git
                 GIT_TAG             "v3.3-cmake"
                 ${UPDATE_DISCONNECTED_IF_AVAILABLE}
	)

	add_subdirectory(${libffi_SOURCE_DIR} ${libffi_BINARY_DIR} EXCLUDE_FROM_ALL)

	#set_target_properties(${NAME} PROPERTIES MACOSX_RPATH ON)
	set_target_properties(ffi_shared PROPERTIES LIBRARY_OUTPUT_DIRECTORY ${EXECUTABLE_OUTPUT_PATH})
	#set_target_properties(${NAME} PROPERTIES INSTALL_NAME_DIR "@executable_path/Plugins")

	include_directories("${libffi_BINARY_DIR}/include")
	add_library(libFFI ALIAS ffi_shared)
else()
 	message(FATAL_ERROR "FFI not found")
endif()
