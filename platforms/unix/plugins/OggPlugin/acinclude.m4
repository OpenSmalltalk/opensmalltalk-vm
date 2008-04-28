# -*- sh -*-

AC_MSG_CHECKING([for Ogg Vorbis and Speex support])

AC_TRY_COMPILE([
  #include <vorbis/codec.h>
  #include <vorbis/vorbisenc.h>
  #include <speex/speex.h>
],[;],[
  AC_CHECK_LIB(ogg, ogg_sync_buffer,
    AC_CHECK_LIB(vorbis, vorbis_synthesis_headerin,
      AC_CHECK_LIB(speex, speex_packet_to_header,
	AC_MSG_RESULT(yes),
	AC_MSG_RESULT(no)
	AC_PLUGIN_DISABLE),
      AC_MSG_RESULT(no)
      AC_PLUGIN_DISABLE),
    AC_MSG_RESULT(no)
    AC_PLUGIN_DISABLE)
],[
  AC_MSG_RESULT(no)
  AC_PLUGIN_DISABLE
])
