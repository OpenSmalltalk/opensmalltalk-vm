LINK_DIRECTORIES (${vm_link_directories})

ADD_EXECUTABLE (squeakvm${scriptsuffix}
  ${bld}/${interp}.c
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
)

ADD_CUSTOM_COMMAND (
  OUTPUT  version.c
  COMMAND ${config}/verstamp ${bld}/version.c ${CMAKE_C_COMPILER}
)

ADD_CUSTOM_COMMAND (
  DEPENDS ${src}/vm/interp.c
  OUTPUT  ${bld}/interp.c
  COMMAND tr '\\015' '\\012' < ${src}/vm/interp.c > ${bld}/interp.c
)

ADD_CUSTOM_COMMAND (
  DEPENDS ${bld}/interp.c
  OUTPUT  ${bld}/gnu-interp.c
  COMMAND ${config}/gnuify ${config}/gnuify.awk ${bld}/interp.c ${bld}/gnu-interp.c
)

INCLUDE_DIRECTORIES (
  ${bld}
# ${src}/vm # files are now copied/generated in ${bld}
  ${unix}/vm
  ${cross}/vm
  ${unix}/plugins/B3DAcceleratorPlugin	# for sqUnixOpenGL.h
  ${X11_INCLUDE_DIR}
  ${OPENGL_INCLUDE_DIR}
  ${vm_include_directories}
)

SET_TARGET_PROPERTIES (squeakvm${scriptsuffix} PROPERTIES LINK_FLAGS "${CMAKE_EXE_EXPORTS_C_FLAG}")

TARGET_LINK_LIBRARIES (squeakvm${scriptsuffix} m ${squeak_libs} ${vm_link_libraries})

INSTALL (PROGRAMS ${bld}/squeakvm${scriptsuffix} DESTINATION ${plgdir})

IF (vm-sound-OSS_disabled)
  SET (useoss "false")
ELSE ()
  SET (useoss "true")
ENDIF ()

CONFIGURE_FILE (${config}/config.in ${bld}/config @ONLY)

# launcher scripts

ADD_CUSTOM_TARGET (squeak
  DEPENDS ${config}/squeak.in
  COMMAND sh ${bld}/config ${config}/squeak.in ${bld}/squeak
  COMMAND chmod +x ${bld}/squeak
)

INSTALL (PROGRAMS ${bld}/squeak DESTINATION bin)

ADD_CUSTOM_TARGET (squeak.sh
  DEPENDS ${config}/squeak.sh.in
  COMMAND sh ${bld}/config ${config}/squeak.sh.in ${bld}/squeak.sh
  COMMAND chmod +x ${bld}/squeak.sh
)

INSTALL (PROGRAMS ${bld}/squeak.sh DESTINATION bin)

ADD_EXECUTABLE (ckformat
  ${src}/ckformat.c
)

INSTALL (PROGRAMS ${bld}/ckformat DESTINATION ${plgdir})

ADD_DEPENDENCIES (squeakvm${scriptsuffix} squeak squeak.sh ckformat)

# manual page

ADD_CUSTOM_TARGET (squeak.1
  DEPENDS ${unix}/doc/squeak.1
  COMMAND sh ${bld}/config ${unix}/doc/squeak.1 ${bld}/squeak.1
)
ADD_DEPENDENCIES (squeakvm${scriptsuffix} squeak.1)
INSTALL (FILES ${bld}/squeak.1 DESTINATION share/man/man1)
