# -*- sh -*-

AC_ARG_WITH(vm-sound-OSS,
[  --without-vm-sound-OSS      disable OSS vm sound support [default=enabled]],
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
  fi
fi
