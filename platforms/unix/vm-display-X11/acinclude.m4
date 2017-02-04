# -*- sh -*-

AC_ARG_WITH(x,
[  --without-x             disable X Window System support [default=enabled]],
  [have_x="$withval"],
  [have_x="yes"])

AC_ARG_WITH(gl,
[  --without-gl            disable OpenGL support [default=enabled]],
  [have_gl="$withval"],
  [have_gl="yes"])

vm_dispx11_objs="sqUnixX11.lo sqUnixMozilla.lo"
vm_dispx11_bitblt_flags=""

case $host_cpu in
arm*)
AC_ARG_ENABLE(fast-bitblt,
 [  --enable-fast-bitblt enable fast BitBlt optimizations (default=no)],
 [ if   test "x$enableval" = "xyes" ; then
      vm_dispx11_objs="sqUnixX11.lo sqUnixMozilla.lo sqUnixX11Arm.lo"
      vm_dispx11_bitblt_flags="-DENABLE_FAST_BLT"
   fi
 ],
 [])
;;
esac


###xxx FIXME (AGAIN): mandrake needs explicit -lpthread

VMLIBS=${LIBS}
VMCFLAGS=${CFLAGS}
VMCPPFLAGS=${CPPFLAGS}
VMINCLUDES=${INCLUDES}

if test "$have_x" = "yes"; then
  AC_PATH_XTRA
  LIBS="${X_PRE_LIBS} ${X_LIBS} ${X_EXTRA_LIBS} ${LIBS}"
#  if test "${x_libraries}" != ""; then
#    CFLAGS="${X_CFLAGS} ${CFLAGS} -L${x_libraries}"
#  fi
  if test "${x_includes}" != ""; then
    CPPFLAGS="${CPPFLAGS} -I${x_includes}"
    INCLUDES="${INCLUDES} -I${x_includes}"
    X_INCLUDES="-I${x_includes}"
  fi
  AC_CHECK_LIB(X11, XOpenDisplay, [
    AC_DEFINE(USE_X11, [1], [Use X11])
    AC_DEFINE_UNQUOTED(VM_X11DIR, "${x_libraries}", [X11 libraries])
    LIBS="${LIBS} -lX11"
    AC_CHECK_LIB(Xext, XShmAttach)
    if test "$have_gl" = ""; then have_gl="no"; fi
	if test "$have_gl" = "yes"; then
		AC_CHECK_HEADERS(GL/gl.h, [
		  have_gl=yes
		  AC_DEFINE(USE_X11_GLX, [1], [Use X11 GLX])
		  AC_CHECK_LIB(GL,glIsEnabled)
		])
	else
		AC_DEFINE(USE_X11_GLX, 0, [Use X11 GLX])
	fi
  ],[
    AC_PLUGIN_DISABLE
  ])
else
  AC_PLUGIN_DISABLE
fi

X_LIBS=${LIBS}
AC_SUBST(X_LIBS)
X_CFLAGS=${CFLAGS}
AC_SUBST(X_CFLAGS)
X_CPPFLAGS=${CPPFLAGS}
AC_SUBST(X_CPPFLAGS)
X_INCLUDES=${INCLUDES}
AC_SUBST(X_INCLUDES)

LIBS=${VMLIBS}
CFLAGS=${VMCFLAGS}
CPPFLAGS=${VMCPPFLAGS}
INCLUDES=${VMINCLUDES}

AC_SUBST(VM_DISPX11_OBJS, $vm_dispx11_objs)
AC_SUBST(VM_DISPX11_BITBLT_FLAGS, $vm_dispx11_bitblt_flags)
