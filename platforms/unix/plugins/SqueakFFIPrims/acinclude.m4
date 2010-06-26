AC_MSG_CHECKING([for FFI support])

FFI_DIR=${topdir}/platforms/unix/plugins/SqueakFFIPrims

AC_ARG_WITH(ffi,
[  --with-ffi=ffi          use FFI support [default=auto]],
  [with_ffi="$withval"],
  [with_ffi="auto"])

if test "${with_ffi}" != "auto"; then
  ffi_cpu_abi="${with_ffi}"
else
  ffi_cpu_abi=`${FFI_DIR}/ffi-config ${cfgdir} ${FFI_DIR} -cpu-abi`
fi

if test "${ffi_cpu_abi}" != "any-libffi"; then
    AC_MSG_RESULT([${ffi_cpu_abi}])
else
    AC_MSG_RESULT([requires libffi])
    ffi_cpu_abi=any-libffi
    AC_CHECK_HEADER(ffi.h,
	AC_CHECK_LIB(ffi, ffi_call,
	    AC_PLUGIN_USE_LIB(ffi),
	    AC_PLUGIN_DISABLE),
	AC_PLUGIN_DISABLE)
fi

FFI_C=${ffi_cpu_abi}
FFI_S=${ffi_cpu_abi}-asm
FFI_O="${FFI_C}\$o ${FFI_S}\$o"

AC_SUBST(FFI_DIR)
AC_SUBST(FFI_C)
AC_SUBST(FFI_S)
AC_SUBST(FFI_O)
