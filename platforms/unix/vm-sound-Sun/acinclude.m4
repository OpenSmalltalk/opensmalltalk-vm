# -*- sh -*-

AC_ARG_WITH(vm-sound-Sun,
  AS_HELP_STRING([--without-vm-sound-Sun],[disable Sun vm sound support (default=enabled)]),
  [with_vm_sound_Sun="$withval"],
  [with_vm_sound_Sun="yes"])

if test "$with_vm_sound_Sun" = "yes"; then
AC_MSG_CHECKING([for SunOS/Solaris audio])
AC_TRY_COMPILE([#include <sys/audioio.h>],[AUDIO_SUNVTS;],[
  AC_MSG_RESULT(yes)
  AC_DEFINE_UNQUOTED(HAVE_SYS_AUDIOIO_H,1, [SunOS/Solaris audio])
],[
  AC_TRY_COMPILE([#include <sun/audioio.h>],[AUDIO_SUNVTS;],[
    AC_MSG_RESULT(yes)
    AC_DEFINE_UNQUOTED(HAVE_SUN_AUDIOIO_H,1, [Sun audioio])
  ],[
    AC_MSG_RESULT(no)
    AC_PLUGIN_DISABLE
  ])
])
else
	AC_PLUGIN_DISABLE_PLUGIN(vm-sound-Sun);
fi

