PLUGIN_DEFINITIONS (-DNO_ISNAN=1)

# fdlibm.h does not recognize x86_64, so set endianness here for all platforms.

TEST_BIG_ENDIAN (IS_BIG_ENDIAN)
IF (NOT IS_BIG_ENDIAN)
  PLUGIN_DEFINITIONS (-D__LITTLE_ENDIAN=1)
ENDIF ()

# GCC optimizations break fdlibm so disable them for now.

IF (CMAKE_COMPILER_IS_GNUCC)
  SET (LIBM_CFLAGS "${CMAKE_C_FLAGS} -O0 -mno-fused-madd")
ELSE ()
  SET (LIBM_CFLAGS "${CMAKE_C_FLAGS}")
ENDIF ()
