CHECK_INCLUDE_FILE (linux/fb.h HAVE_LINUX_FB_H)

IF (NOT HAVE_LINUX_FB_H)
  DISABLE_PLUGIN ()
ELSE ()
  SET (${plugin}_sources ${unix}/${plugin}/sqUnixFBDev.c)
ENDIF ()
