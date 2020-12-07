if (DOWNLOAD_DEPENDENCIES)

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
endif()
