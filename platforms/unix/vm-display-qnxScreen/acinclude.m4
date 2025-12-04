# -*- sh -*-

AC_ARG_WITH(vm-display-qnxScreen,
[  --without-vm-display-qnxScreen      disable QNX Screen display support [default=disabled]],
  [with_vm_display_qnxScreen="$withval"],
  [with_vm_display_qnxScreen="yes"])
if test "$with_vm_display_qnxScreen" = "no"; then
	AC_PLUGIN_DISABLE_PLUGIN(vm-display-qnxScreen);
else
	AC_CHECK_HEADERS(linux/fb.h,,AC_PLUGIN_DISABLE)
	AC_CHECK_HEADERS(libevdev-1.0/libevdev/libevdev.h,,AC_PLUGIN_DISABLE)
fi
