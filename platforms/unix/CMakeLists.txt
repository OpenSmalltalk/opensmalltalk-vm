# Yes, it's true: you can write makefiles in COBOL.
# 
# Last edited: 2010-05-13 12:54:20 by piumarta on emilia-2.local

PROJECT (squeak)

CMAKE_MINIMUM_REQUIRED (VERSION 2.6.2)

IF (NOT DEFINED VM_HOST OR NOT DEFINED VM_VERSION)
  MESSAGE (FATAL_ERROR "
    You MUST NOT run CMake directly the first time you configure a build.
    Run 'platforms/unix/cmake/configure' from within your build directory."
  )
ENDIF (NOT DEFINED VM_HOST OR NOT DEFINED VM_VERSION)

SET (prefix  ${CMAKE_INSTALL_PREFIX})

SET (version ${VM_VERSION})

SET (bindir bin)
SET (imgdir lib/squeak)
SET (plgdir lib/squeak/${version})
SET (mandir man/man1)
SET (docdir share/doc/squeak-${version})

GET_CMAKE_PROPERTY (vars VARIABLES)
FOREACH (opt ${vars})
  IF (opt MATCHES "OPT--.*")
    STRING (REGEX REPLACE "OPT--(.*)" "\\1" var ${opt})
    MESSAGE (STATUS "Setting ${var}=${${opt}}")
    SET (${var} ${${opt}})
  ENDIF ()
ENDFOREACH (opt)

SET (CMAKE_INSTALL_PREFIX ${prefix})

SET (bld    ${CMAKE_BINARY_DIR})
SET (unix   ${CMAKE_SOURCE_DIR})
SET (config ${unix}/cmake)

GET_FILENAME_COMPONENT (cross ${unix}/../Cross ABSOLUTE)

IF (OPT--src)
  GET_FILENAME_COMPONENT (src ${OPT--src} ABSOLUTE)
ELSE (SRC)
  SET (src  ${unix}/src)
ENDIF (OPT--src)

IF (NOT EXISTS ${src})
  MESSAGE (FATAL_ERROR "
    Source directory ${src} does not exist."
  )
ENDIF (NOT EXISTS ${src})

INCLUDE (${config}/Utils.cmake)
INCLUDE (${config}/Plugins.cmake)

STRING (REGEX REPLACE "([^-]*)-([^-]*)-([^-]*).*" "\\1" VM_HOST_CPU    ${VM_HOST})
STRING (REGEX REPLACE "([^-]*)-([^-]*)-([^-]*).*" "\\2" VM_HOST_VENDOR ${VM_HOST})
STRING (REGEX REPLACE "([^-]*)-([^-]*)-([^-]*).*" "\\3" VM_HOST_OS     ${VM_HOST})

SET (vm-host     "${VM_HOST}")
SET (vm-host-os  "${VM_HOST_OS}")
SET (vm-host-cpu "${VM_HOST_CPU}")

IF (OPT--CFLAGS)
  SET (CMAKE_C_FLAGS "${OPT--CFLAGS}")
ENDIF ()

IF (CMAKE_ARCH_FLAGS STREQUAL "-m32")
  IF (VM_HOST_CPU STREQUAL "x86_64")
    SET (VM_HOST_CPU "i386")
  ENDIF ()
ENDIF ()

IF (NOT CMAKE_C_FLAGS)
  IF (CMAKE_COMPILER_IS_GNUCC)
    IF     (VM_HOST_CPU MATCHES "i.86")
      SET (CMAKE_C_FLAGS "-g -O2 -fomit-frame-pointer")
    ELSEIF (VM_HOST_CPU STREQUAL "ppc" OR VM_HOST_CPU STREQUAL "powerpc")
      SET (CMAKE_C_FLAGS "-g -O3 -funroll-loops -mcpu=750 -mno-fused-madd")
    ENDIF ()
  ELSE ()
    SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS_RELEASE}")
  ENDIF (CMAKE_COMPILER_IS_GNUCC)
ENDIF (NOT CMAKE_C_FLAGS)

IF (NOT CMAKE_C_FLAGS)
  SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS_RELEASE}")
ENDIF (NOT CMAKE_C_FLAGS)

IF (CMAKE_ARCH_FLAGS)
  SET (CMAKE_C_FLAGS "${CMAKE_ARCH_FLAGS} ${CMAKE_C_FLAGS}")
ENDIF (CMAKE_ARCH_FLAGS)

IF (EXISTS /usr/pkg/include)
  SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -I/usr/pkg/include")
ENDIF (EXISTS /usr/pkg/include)

IF (EXISTS /usr/local/include)
  SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -I/usr/local/include")
ENDIF (EXISTS /usr/local/include)

IF (EXISTS /usr/local/lib)
  SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -L/usr/local/lib")
ENDIF (EXISTS /usr/local/lib)

MESSAGE (STATUS "Using CFLAGS ${CMAKE_C_FLAGS}")

MACRO (USE_LIBRARY lib)
  LIST (APPEND squeak_libs "${lib}")
ENDMACRO (USE_LIBRARY)

MACRO (USE_FRAMEWORK fwk)
  USE_LIBRARY ("-framework ${fwk}")
ENDMACRO (USE_FRAMEWORK)

MACRO (CONFIG_DEFINE var)
  LIST (APPEND config_vars "${var}")
ENDMACRO (CONFIG_DEFINE var)

SET (UNIX 1)
CONFIG_DEFINE (UNIX)

SET (ioMicroSecondClock ioMicroSeconds)
CONFIG_DEFINE (ioMicroSecondClock)

SET (ioUtcWithOffset sqUnixUtcWithOffset)
CONFIG_DEFINE (ioUtcWithOffset)

SET (CMAKE_SKIP_BUILD_RPATH TRUE)
SET (CMAKE_BUILD_WITH_INSTALL_RPATH TRUE) 
SET (CMAKE_INSTALL_RPATH "")
SET (CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)

INCLUDE (${unix}/vm/config.cmake)

CONFIGURE_PLUGINS ()

LIST (REMOVE_DUPLICATES config_vars)
FILE (WRITE ${bld}/config.h.in "")
FOREACH (var ${config_vars})
  FILE (APPEND ${bld}/config.h.in "#cmakedefine ${var} @${var}@\n")
ENDFOREACH (var)

CONFIGURE_FILE (${bld}/config.h.in ${bld}/config.h)

INCLUDE (${unix}/vm/build.cmake)

BUILD_PLUGINS ()

ADD_SUBDIRECTORY (${unix}/npsqueak)

SET (cmake ${unix}/../../cmake)

IF (EXISTS ${cmake}/Packages.cmake)
  INCLUDE (${cmake}/Packages.cmake)
ENDIF ()

GET_CMAKE_PROPERTY (tmp VARIABLES)
LIST (REMOVE_ITEM tmp tmp)
LIST (SORT tmp)
FILE (WRITE ${bld}/config.status "")
FOREACH (var ${tmp})
  FILE (APPEND ${bld}/config.status "${var}=${${var}}\n")
ENDFOREACH ()
