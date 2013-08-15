SET(${plugin}_sources "${${plugin}_source_dir}/${plugin}.c")

SET(xbbp "${cross}/plugins/${plugin}")

IF (DEFINED ENABLE-FAST-BLT)
  LIST(APPEND ${plugin}_extra_sources ${xbbp}/BitBltDispatch.c ${xbbp}/BitBltGeneric.c)
  IF (vm-host-cpu MATCHES "arm")
    ENABLE_LANGUAGE (ASM)
    SET (CMAKE_ASM_COMPILE_OBJECT "asasm -cpu 6 -I ${xbbp} -o <OBJECT> <SOURCE>")
    LIST(APPEND ${plugin}_extra_sources
        ${xbbp}/BitBltArm.c ${xbbp}/BitBltArmSimd.c ${xbbp}/BitBltArmSimdAlphaBlend.s
        ${xbbp}/BitBltArmSimdBitLogical.s ${xbbp}/BitBltArmSimdPixPaint.s
        ${xbbp}/BitBltArmSimdSourceWord.s
    )
    PLUGIN_DEFINITIONS("-DENABLE_FAST_BLT")
    IF (vm-host-os STREQUAL "linux")
      LIST (APPEND ${plugin}_extra_sources ${xbbp}/BitBltArmLinux.c)
    ELSE ()
      LIST (APPEND ${plugin}_extra_sources ${xbbp}/BitBltArmOther.c)
    ENDIF ()
  ELSE ()
    MESSAGE (FATAL_ERROR "
  --enableFastBlt is not supported on this platform
"   )
  ENDIF ()
ENDIF ()
