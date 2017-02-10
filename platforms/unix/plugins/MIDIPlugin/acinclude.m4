AC_MSG_CHECKING([for MIDI support via ALSA])
AC_TRY_COMPILE([
  #include <alsa/asoundlib.h>
],[;],[
  AC_MSG_RESULT(yes)
  AC_DEFINE(USE_MIDI_ALSA, 1, [Use MIDI ALSA])
],[
  AC_MSG_RESULT(no)
  AC_PLUGIN_DISABLE
])
