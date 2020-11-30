find_package(Cairo)

if (Cairo_FOUND)
	add_dependencies(${VM_LIBRARY_NAME} Cairo::Cairo)
elseif (DOWNLOAD_DEPENDENCIES)

  # Cairo does not support building on CMake
  # Download it for now, except for linuxes
  if (NOT UNIX)
    add_third_party_dependency("pixman-0.34.0" "build/vm")
    add_third_party_dependency("cairo-1.15.4" "build/vm")
    if (WIN)
      add_third_party_dependency("libpng-1.6.34" "build/vm")
    else()
      add_third_party_dependency("libpng-1.2.49" "build/vm")
    endif()
  endif()
else()
	message(FATAL_ERROR "Could not find Cairo")
endif()
