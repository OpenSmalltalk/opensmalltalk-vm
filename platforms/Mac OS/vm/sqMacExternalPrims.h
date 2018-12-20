/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacExternalPrims.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacExternalPrims.h 1334 2006-02-25 05:09:15Z johnmci $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  Nov 25th 2003 JMM add gCurrentVMEncoding
****************************************************************************/

#if TARGET_API_MAC_CARBON
    #include <Carbon/Carbon.h>
    extern CFStringEncoding gCurrentVMEncoding;
#else
#endif

