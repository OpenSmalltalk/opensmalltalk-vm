
AC_MSG_CHECKING([for SSL support])
ssl_cflags=""
ssl_libs=""

case $host in
    *-openbsd*) 
        AC_PLUGIN_USE_LIB([-lcrypto] -lssl -ltls" 
        AC_MSG_RESULT([libtls (system LibreSSL)])
        ;;
    *)

        AC_ARG_ENABLE([dynamic-openssl],
            AS_HELP_STRING([--disable-dynamic-openssl], [Disable dynamic lookup of OpenSSL, rather link]))

        AS_IF([test "x$enable_dynamic-openssl" != "xno"], [
            AC_CHECK_HEADERS([openssl/ssl.h],[
                AC_
                AC_MS_RESULT([OpenSSL (dynamic)])
                ssl_libs="-ldl"
            ],[
                AC_MSG_ERROR([Headers Missing])
                AC_PLUGIN_DISABLE()
            ]
        ],[
            AC_PLUGIN_CHECK_LIB(
            ssl_libs="lcrypto -lssl"
            ssl_cflags="-DSQSSL_OPENSSL_LINKED"
        ])


AC_ARG_WITH([libtls],
    AS_HELP_STRING([--with-libtls], [Use libtls instead of OpenSSL unconditionally]))

AS_IF([test "x$with_libtls" != "xno"],
      [AC_CHECK_HEADERS([tls.h], [have_foo=yes], [have_foo=no])],
      [have_foo=no])


AC_CHECK_HEADERS([])



dnl AC_PLUGIN_USE_LIB("--")

