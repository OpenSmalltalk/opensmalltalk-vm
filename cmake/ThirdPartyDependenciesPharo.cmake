include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/PkgConfig.cmake")

if(DARWIN OR WIN32)
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/Zlib.cmake")
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/LibPNG.cmake")
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/FreeType2.cmake")
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/Pixman.cmake")
    include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/Cairo.cmake")
endif()

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/OpenSSL.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/LibSSH2.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/LibGit2.cmake")
