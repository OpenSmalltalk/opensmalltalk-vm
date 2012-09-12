# -*- sh -*-

AC_ARG_WITH(vm-sound-OSS,
[  --without-vm-sound-OSS      disable OSS vm sound support [default=enabled]],
  [with_vm_sound_OSS="$withval"],
  [with_vm_sound_OSS="yes"])

if test "$with_vm_sound_OSS" = "no"; then
	AC_PLUGIN_DISABLE_PLUGIN(vm-sound-OSS);
else
	AC_MSG_CHECKING([for Open Sound System])
	AC_TRY_COMPILE([#include <sys/soundcard.h>],[OPEN_SOUND_SYSTEM;],[
	  AC_MSG_RESULT(yes)
	],[
	  AC_MSG_RESULT(no)
	  AC_PLUGIN_DISABLE
	])
fi
