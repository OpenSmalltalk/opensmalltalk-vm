# -*- sh -*-

AC_ARG_WITH(vm-display-qnxScreen,
[  --without-vm-display-qnxScreen      disable QNX Screen display support [default=disabled]],
  [with_vm_display_qnxScreen="$withval"],
  [with_vm_display_qnxScreen="no"])
if test "$with_vm_display_qnxScreen" = "no"; then
	AC_PLUGIN_DISABLE_PLUGIN(vm-display-qnxScreen);
fi
