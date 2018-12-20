# -*- sh -*-

AC_CHECK_HEADER([uuid/uuid.h],[
    AC_DEFINE([HAVE_UUID_UUID_H],[1], [uuid/uuid.h])
],[
    AC_CHECK_HEADER([uuid.h],[
        AC_DEFINE([HAVE_UUID_H],[1], [uuid.h])
    ],[
        AC_CHECK_HEADER([sys/uuid.h],[
            AC_DEFINE([HAVE_SYS_UUID_H],[1], [sys/uuid.h])
        ])
    ])
])

AC_SEARCH_LIBS([uuid_generate],[uuid],[
    AC_PLUGIN_USE_LIB([uuid])
    AC_DEFINE([HAVE_UUID_GENERATE],[1], [uuid_generate])
],[
    AC_SEARCH_LIBS([uuidgen],[uuid],[
        AC_PLUGIN_USE_LIB([uuid])
        AC_DEFINE([HAVE_UUIDGEN],[1], [uuidgen])
    ],[
        AC_PLUGIN_DISABLE
    ])
])
