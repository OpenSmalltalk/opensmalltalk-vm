IF (VM_HOST_CPU MATCHES "i[3456789]86")
  PLUGIN_DEFINITIONS (-DUSE_MMX=1)
ENDIF ()

PLUGIN_FIND_LIBRARY (PTHREAD pthread)

IF (NOT HAVE_LIBPTHREAD)
  PLUGIN_DEFINITIONS (-DNOPTHREADS=1)
ENDIF ()

SET (lmp3 "${cross}/plugins/Mpeg3Plugin/libmpeg")

LIST(APPEND ${plugin}_sources
  ${lmp3}/bitstream.c ${lmp3}/libmpeg3.c ${lmp3}/mpeg3atrack.c ${lmp3}/mpeg3demux.c ${lmp3}/mpeg3io.c
  ${lmp3}/mpeg3title.c ${lmp3}/mpeg3vtrack.c ${lmp3}/changesForSqueak.c
  ${lmp3}/audio/dct.c ${lmp3}/audio/header.c ${lmp3}/audio/layer2.c ${lmp3}/audio/layer3.c
  ${lmp3}/audio/mpeg3audio.c ${lmp3}/audio/pcm.c ${lmp3}/audio/synthesizers.c ${lmp3}/audio/tables.c
  ${lmp3}/video/getpicture.c ${lmp3}/video/headers.c ${lmp3}/video/idct.c ${lmp3}/video/macroblocks.c
  ${lmp3}/video/mmxtest.c ${lmp3}/video/motion.c ${lmp3}/video/mpeg3video.c ${lmp3}/video/output.c
  ${lmp3}/video/reconstruct.c ${lmp3}/video/seek.c ${lmp3}/video/slice.c ${lmp3}/video/vlc.c
)

PLUGIN_INCLUDE_DIRECTORIES (${lmp3} ${lmp3}/audio ${lmp3}/video)
