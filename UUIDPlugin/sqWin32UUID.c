/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32UUID.c
*   CONTENT: UUID support
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: 
*   EMAIL:   Andreas.Raab@gmx.de
*   RCSID:   $Id: sqWin32UUID.c,v 1.1 2002/05/04 23:20:28 andreasraab Exp $
*
*   NOTES:
*****************************************************************************/
#include <windows.h>
#include <ole2.h>
#include "sq.h"

int sqUUIDInit(void) {
  return 1;
}

int sqUUIDShutdown(void) {
  return 1;
}

int MakeUUID(char *location) {
  if(CoCreateGuid((GUID*)location) == S_OK) return 1;
  primitiveFail();
  return 0;
}

