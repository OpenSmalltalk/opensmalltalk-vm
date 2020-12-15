find_package(Cairo)

if (Cairo_FOUND)
	add_dependencies(${VM_LIBRARY_NAME} Cairo::Cairo)
elseif (DOWNLOAD_DEPENDENCIES)

  # Cairo does not support building on CMake
  # Download it for now, except for linuxes
  if (NOT UNIX)
    if (WIN)
        If(${CMAKE_SYSTEM_PROCESSOR} MATCHES "ARM64")
            add_third_party_dependency("pixman-0.40.0")
            add_third_party_dependency("cairo-1.16.0")
            add_third_party_dependency("libpng-1.6.37")
        else()
            # X86 and X86_64
            add_third_party_dependency("pixman-0.34.0")
            add_third_party_dependency("cairo-1.15.4")
            add_third_party_dependency("libpng-1.6.34")
        endif()
    else()
        add_third_party_dependency("pixman-0.34.0")
        add_third_party_dependency("cairo-1.15.4")
        add_third_party_dependency("libpng-1.2.49")
    endif()
  endif()
else()
	message(FATAL_ERROR "Could not find Cairo")
endif()
