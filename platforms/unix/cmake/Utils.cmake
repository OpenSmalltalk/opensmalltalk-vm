# Some random useful things to avoid repetition
# 
# Last edited: 2009-08-26 10:41:32 by piumarta on ubuntu.piumarta.com

MACRO (STRING_APPEND var str)
  IF (DEFINED ${var})
    SET (${var} "${${var}} ${str}")
  ELSE (DEFINED ${var})
    SET (${var} "${str}")
  ENDIF (DEFINED ${var})
ENDMACRO (STRING_APPEND)

MACRO (LIST_APPEND list)
  LIST (APPEND ${list} "${ARGN}")
  LIST (REMOVE_DUPLICATES ${list})
ENDMACRO (LIST_APPEND)

MACRO (FILE_APPEND to from)
  IF (EXISTS ${from})
    FILE (READ ${from} tmp)
    FILE (APPEND ${to} "${tmp}")
  ENDIF (EXISTS ${from})
ENDMACRO (FILE_APPEND)

MACRO (FILE_COPY to from)
  IF (EXISTS ${from})
    FILE (READ ${from} tmp)
    FILE (WRITE ${to} "${tmp}")
  ENDIF (EXISTS ${from})
ENDMACRO (FILE_COPY)
