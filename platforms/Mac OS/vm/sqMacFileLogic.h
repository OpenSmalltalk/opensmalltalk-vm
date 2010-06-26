/****************************************************************************
*   PROJECT: Mac directory logic
*   FILE:    sqMacFileLogic.c
*   CONTENT: 
*
*   AUTHOR:  John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacFileLogic.h 1344 2006-03-05 21:07:15Z johnmci $
*
*   NOTES: See change log below.
*	Jan 2nd 2002 JMM added logic to make lookups faster
*	Jan 22nd 2002 JMM squeak file type offset change
*       Nov 25th 2003 JMM add gCurrentVMEncoding
        3.7.0bx Nov 24th, 2003 JMM gCurrentVMEncoding
	Mar 24th, 2005 JMM add routine for posix to HFS+
	Jan 7th, 2006 JMM rework macosxpath & ioFilenamefromStringofLengthresolveAliases
*/
#include "sqMacUnixFileInterface.h"
