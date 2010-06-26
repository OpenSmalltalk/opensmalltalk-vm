# -*- sh -*-

if test "$with_vm_sound_OSS"="yes"; then
	AC_MSG_CHECKING([for Open Sound System])
	AC_TRY_COMPILE([#include <sys/soundcard.h>],[OPEN_SOUND_SYSTEM;],[
	  AC_MSG_RESULT(yes)
	],[
	  AC_MSG_RESULT(no)
	  AC_PLUGIN_DISABLE
	])
fi
