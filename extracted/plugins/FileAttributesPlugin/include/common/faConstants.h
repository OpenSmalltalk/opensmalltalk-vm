/*
 * faConstants.h
 *
 * File Attributes constants
 *
 * Note that these must be kept in sync with their definition in 
 * FileAttributesPlugin errors / status protocol.
 *
 */
#define FA_SUCCESS			  0

#define FA_STRING_TOO_LONG		 -1
#define FA_STAT_FAILED			 -2
#define FA_CANT_STAT_PATH		 -3
#define FA_GET_ATTRIBUTES_FAILED	 -4
#define FA_TIME_CONVERSION_FAILED	 -5
#define FA_INVALID_ARGUMENTS		 -6
#define FA_CORRUPT_VALUE	 	 -7
#define FA_CANT_READ_LINK		 -8
#define	FA_CANT_OPEN_DIR		 -9
#define FA_CANT_ALLOCATE_MEMORY		-10
#define FA_INVALID_REQUEST		-11
#define FA_UNABLE_TO_CLOSE_DIR		-12
#define FA_UNSUPPORTED_OPERATION	-13
#define FA_UNEXPECTED_ERROR		-14
#define FA_INTERPRETER_ERROR		-15 /* Actual error flagged in interpreterProxy */
#define	FA_CANT_READ_DIR		-16
#define FA_BAD_SESSION_ID		-17


#define FA_NO_MORE_DATA			  1

