# this one is important
SET(CMAKE_SYSTEM_NAME Windows)
#this one not so much
SET(CMAKE_SYSTEM_VERSION 1)

# specify the cross compiler
set(CMAKE_TOOLCHAIN_PREFIX i686-w64-mingw32)

SET(CMAKE_C_COMPILER   ${CMAKE_TOOLCHAIN_PREFIX}-gcc)
SET(CMAKE_CXX_COMPILER ${CMAKE_TOOLCHAIN_PREFIX}-g++)
SET(CMAKE_RC_COMPILER ${CMAKE_TOOLCHAIN_PREFIX}-windres)
SET(CMAKE_SYSTEM_PROCESSOR i686)

# where is the target environment
SET(CMAKE_FIND_ROOT_PATH  /usr/i686-w64-mingw32/sys-root/mingw/)

# search for programs in the build host directories
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# for libraries and headers in the target directories
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

SET(MINGW_ON_CYGWIN TRUE CACHE INTERNAL "Are we running on cygwin?")
