dnl SqueakSSL

case $host in
    *-openbsd*)
        AC_MSG_CHECKING([for SSL support])
        AC_PLUGIN_USE_LIB([crypto])
        AC_PLUGIN_USE_LIB([ssl])
        AC_PLUGIN_USE_LIB([tls])
        AC_MSG_RESULT([libtls (system LibreSSL)])
        ;;
    *)
        AC_ARG_ENABLE([dynamicopenssl],
            AS_HELP_STRING([--disable-dynamicopenssl], [Disable dynamic lookup of OpenSSL, rather link]))
        AC_ARG_WITH([libtls],
            AS_HELP_STRING([--with-libtls], [Use libtls instead of OpenSSL unconditionally]))

        AS_IF([test "x$with_libtls" != "xno"],
              [AC_CHECK_HEADERS([tls.h], [have_tls=yes], [have_tls=no])],
              [have_tls=no])

        AS_IF([test "x$have_tls" = "xyes"],[
              AC_MSG_CHECKING([for SSL support])
              AC_PLUGIN_USE_LIB([crypto])
              AC_PLUGIN_USE_LIB([ssl])
              AC_PLUGIN_USE_LIB([tls])
              AC_MSG_RESULT([libtls])
        ],[
            AS_IF([test "x$with_libtls" = "xyes"], [AC_MSG_ERROR([libtls requested but not found])])
            AS_IF([test "x$enable_dynamicopenssl" != "xno"], [
                AC_CHECK_HEADERS([openssl/ssl.h],[
                    AC_MSG_CHECKING([for SSL support])
                    AC_MSG_RESULT([OpenSSL (dynamic)])
                ],[
                    AC_MSG_CHECKING([for SSL support])
                    AC_MSG_RESULT([Headers Missing])
                    AC_PLUGIN_DISABLE()
                ])
            ],[
                AC_PLUGIN_SEARCH_LIBS([BIO_new], [crypto])
                AC_PLUGIN_SEARCH_LIBS([SSL_new], [ssl])
                AC_DEFINE([SQSSL_OPENSSL_LINKED], [1], [Linked OpenSSL])
                AC_MSG_CHECKING([for SSL support])
                AC_MSG_RESULT([OpenSSL (linked)])
            ])
        ])
        ;;
esac


dnl EOF
