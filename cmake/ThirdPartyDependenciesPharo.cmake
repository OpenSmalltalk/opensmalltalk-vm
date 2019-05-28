include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/PkgConfig.cmake")

if(DARWIN)
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/FreeType2.cmake")
endif()
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/OpenSSL.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/LibSSH2.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/LibGit2.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/SDL2.cmake")
