AC_MSG_CHECKING([for MIDI support via ALSA])

AC_CHECK_HEADERS([alsa/asoundlib.h],[
    AC_DEFINE(USE_MIDI_ALSA, 1, [Use MIDI ALSA])],
    AC_PLUGIN_DISABLE)
AC_PLUGIN_SEARCH_LIBS([snd_seq_open],[asound])
