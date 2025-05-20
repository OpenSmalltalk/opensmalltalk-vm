# -*- sh -*-
# test whether the macro AUDIO_SUNVTS is defined in <sys/audioio.h> or <sun/audioio.h>

AC_ARG_WITH(vm-sound-Sun,
  AS_HELP_STRING([--without-vm-sound-Sun],[disable Sun vm sound support (default=enabled)]),
  [with_vm_sound_Sun="$withval"],
  [with_vm_sound_Sun="yes"])

if test "$with_vm_sound_Sun" = "yes"; then
AC_MSG_CHECKING([for SunOS/Solaris audio])
AC_COMPILE_IFELSE([AC_LANG_SOURCE([[#include <sys/audioio.h> int test = AUDIO_SUNVTS;]])],[
  AC_MSG_RESULT(yes)
  AC_DEFINE_UNQUOTED(HAVE_SYS_AUDIOIO_H,1, [SunOS/Solaris audio])
],[
  AC_COMPILE_IFELSE([AC_LANG_SOURCE([[#include <sun/audioio.h> int test = AUDIO_SUNVTS;]])],[
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

