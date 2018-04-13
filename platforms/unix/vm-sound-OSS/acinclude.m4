# -*- sh -*-

AC_ARG_WITH([vm-sound-OSS],
  AS_HELP_STRING([--without-vm-sound-OSS], [disable OSS vm sound support (default=enabled)]),
  [with_vm_sound_OSS="$withval"],
  [with_vm_sound_OSS="yes"])

if test "$with_vm_sound_OSS" = "no"; then
  AC_PLUGIN_DISABLE_PLUGIN(vm-sound-OSS);
else
  AC_MSG_CHECKING([for Open Sound System])
  soundcard_h_found="no"
  AC_CHECK_HEADERS([soundcard.h sys/soundcard.h],[soundcard_h_found="yes"; break])
  if test "$soundcard_h_found" = "no"; then
    AC_PLUGIN_DISABLE
  else
    dnl Opportunistically use ossaudio if available.
    AC_CHECK_LIB([ossaudio],[_oss_ioctl],[AC_PLUGIN_USE_LIB([ossaudio])])
  fi
fi
