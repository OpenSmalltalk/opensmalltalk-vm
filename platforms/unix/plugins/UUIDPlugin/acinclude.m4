# -*- sh -*-

AC_MSG_CHECKING([for UUID support uuid/uuid.h & uuid_generate])

AC_TRY_COMPILE([#include <uuid/uuid.h>],[uuid_generate;],
	[AC_MSG_RESULT(yes)
		AC_CHECK_LIB(uuid, uuid_generate, LIB_UUID="-luuid")],
	[AC_MSG_RESULT(no)
		 AC_MSG_CHECKING([for UUID uuid.h & uuidgen])
		 AC_TRY_COMPILE([#include <uuid.h>],[uuidgen;],
		 [AC_MSG_RESULT(yes)
			 AC_CHECK_LIB(uuid, uuidgen, LIB_UUID="-luuid" )],
		 [AC_MSG_RESULT(no)
		   AC_PLUGIN_DISABLE])])

AC_SUBST(LIB_UUID)
