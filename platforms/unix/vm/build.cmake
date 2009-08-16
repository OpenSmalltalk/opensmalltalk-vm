ADD_EXECUTABLE (squeak
  ${src}/vm/interp.c
  ${unix}/vm/aio.c
  ${unix}/vm/debug.c
  ${unix}/vm/osExports.c
  ${unix}/vm/sqUnixCharConv.c
  ${unix}/vm/sqUnixExternalPrims.c
  ${unix}/vm/sqUnixMain.c
  ${unix}/vm/sqUnixMemory.c
  ${cross}/vm/sqNamedPrims.c
  ${cross}/vm/sqVirtualMachine.c
  ${bld}/version.c
  ${bld}/disabledPlugins.c
)

# IF (CMAKE_COMPILER_IS_GNUCC)
#   SET (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -export-dynamic")
# ENDIF (CMAKE_COMPILER_IS_GNUCC)

ADD_CUSTOM_COMMAND (
  OUTPUT  version.c
  COMMAND ${config}/verstamp ${bld}/version.c ${CMAKE_C_COMPILER}
)

INCLUDE_DIRECTORIES (
  ${bld}
  ${src}/vm
  ${unix}/vm
  ${cross}/vm
  ${unix}/plugins/B3DAcceleratorPlugin	# for sqUnixOpenGL.h
)

TARGET_LINK_LIBRARIES (squeak m ${squeak_libs})
