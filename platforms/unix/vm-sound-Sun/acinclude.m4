# -*- sh -*-
# test header file <sys/audioio.h> and enable vm-sound-Sun, unless --without-vm-sound-Sun 
# support for HAVE_SUN_AUDIOIO_H dropped (originally the plugin supported <sun/audioio.h> and <sys/audioio.h>

AC_ARG_WITH(vm-sound-Sun,
  AS_HELP_STRING([--without-vm-sound-Sun],[disable Sun vm sound support (default=enabled)]),
  [with_vm_sound_Sun="$withval"],
  [with_vm_sound_Sun="yes"])

if test "$with_vm_sound_Sun" = "yes"; then
  AC_MSG_CHECKING([for SunOS/Solaris audio])
  AC_CHECK_HEADERS([sys/audioio.h],[],[AC_PLUGIN_DISABLE])
else
  AC_PLUGIN_DISABLE_PLUGIN(vm-sound-Sun);
fi

