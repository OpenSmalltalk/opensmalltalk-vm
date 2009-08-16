# Some random useful things to avoid repetition
# 
# Last edited: 2009-08-13 20:28:39 by piumarta on emilia-2.local

MACRO (STRING_APPEND var str)
    IF (DEFINED ${var})
        SET (${var} "${${var}} ${str}")
    ELSE (DEFINED ${var})
        SET (${var} "${str}")
    ENDIF (DEFINED ${var})
ENDMACRO (STRING_APPEND)

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
