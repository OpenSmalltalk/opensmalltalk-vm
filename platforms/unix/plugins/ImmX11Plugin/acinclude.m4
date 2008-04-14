# xicfont options.

AC_ARG_ENABLE(xicfont-option,
AC_HELP_STRING([--enable-xicfont-option],
	[enable -xicfont option @<:@default=no@:>@]),
AC_DEFINE(USE_XICFONT_OPTION, 1))

AC_ARG_ENABLE(xicfont-resource,
AC_HELP_STRING([--enable-xicfont-resource],
	[read XResource for xicfont @<:@default=no@:>@]),
AC_DEFINE(USE_XICFONT_RESOURCE, 1))

AC_ARG_ENABLE(xicfont-default,
AC_HELP_STRING([--enable-xicfont-default],
	[read XDefault for xicfont @<:@default=no@:>@]),
AC_DEFINE(USE_XICFONT_DEFAULT, 1))
