find_package(Cairo)

if (Cairo_FOUND)

elseif (NOT WITHOUT_DEPENDENCIES)

	include(cmake/DownloadProject.cmake)

	# Cairo does not support building on CMake
	# In Win32

	if(WIN)
		#	add_third_party_dependency("cairo-1.15.4" "build/vm")
		#	add_third_party_dependency("libpixman-0.38.4" "build/vm")
		#	add_third_party_dependency("libpng-1.6.34" "build/vm")
	else()
		message(FATAL_ERROR "No Cairo support specified for host ${CMAKE_HOST_SYSTEM_NAME}")
	endif()
else()
	message(FATAL_ERROR "Could not find Cairo")
endif()

add_dependencies(${VM_LIBRARY_NAME} Cairo::Cairo)
