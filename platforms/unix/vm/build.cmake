ADD_EXECUTABLE (squeakvm
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
  ${X11_INCLUDE_DIR}
  ${OPENGL_INCLUDE_DIR}
)

SET_TARGET_PROPERTIES (squeakvm PROPERTIES LINK_FLAGS "${CMAKE_EXE_EXPORTS_C_FLAG}")

TARGET_LINK_LIBRARIES (squeakvm m ${squeak_libs})

INSTALL (PROGRAMS ${bld}/squeakvm DESTINATION ${plgdir})

CONFIGURE_FILE (${config}/config.in ${bld}/config @ONLY)

# launcher script

ADD_CUSTOM_TARGET (squeak
  DEPENDS ${config}/squeak.in
  COMMAND sh ${bld}/config ${config}/squeak.in ${bld}/squeak
)
ADD_DEPENDENCIES (squeakvm squeak)
INSTALL (PROGRAMS ${bld}/squeak DESTINATION bin)

# manual page

ADD_CUSTOM_TARGET (squeak.1
  DEPENDS ${unix}/doc/squeak.1
  COMMAND sh ${bld}/config ${unix}/doc/squeak.1 ${bld}/squeak.1
)
ADD_DEPENDENCIES (squeakvm squeak.1)
INSTALL (FILES ${bld}/squeak.1 DESTINATION share/man/man1)
