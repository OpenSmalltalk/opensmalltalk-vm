# -*- sh -*-

AC_ARG_WITH(vm-display-fbdev,
[  --without-vm-display-fbdev      disable frame buffer vm display support [default=enabled]],
  [with_vm_display_fbdev="$withval"],
  [with_vm_display_fbdev="yes"])
if test "$with_vm_display_fbdev" = "no"; then
	AC_PLUGIN_DISABLE_PLUGIN(vm-display-fbdev);
else
	AC_CHECK_HEADERS(linux/fb.h,,AC_PLUGIN_DISABLE)
fi
