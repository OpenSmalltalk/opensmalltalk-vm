# Require OpenGL
# (Note: some broken distribs [mandrake] require explicit -lpthread)

AC_CHECK_LIB(GL,glIsEnabled,
  [AC_PLUGIN_USE_LIB(GL)],
  [unset ac_cv_lib_GL_glIsEnabled	# stupid moronic pathetic autoconf
   AC_CHECK_LIB(GL,glIsEnabled,
     [AC_PLUGIN_USE_LIB(GL)],
     [unset ac_cv_lib_GL_glIsEnabled	# stupid moronic pathetic autoconf
      AC_CHECK_LIB(GL,glIsEnabled,
        [AC_PLUGIN_USE_LIB(GL)
	 AC_PLUGIN_USE_LIB(pthread)],
        [AC_PLUGIN_DISABLE],
        [-lpthread])])])
