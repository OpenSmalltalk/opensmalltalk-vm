/*  sqUnixExtendedClipboard.c  -- support for clipboard with multiple types
 *
 * Copyright (C) 2007 by Viewpoints Research Institute and other
 *                             authors/contributors as listed.
 *   All rights reserved.
 *   
 *   This file is part of Unix Squeak.
 * 
 *   Permission is hereby granted, free of charge, to any person obtaining a copy
 *   of this software and associated documentation files (the "Software"), to deal
 *   in the Software without restriction, including without limitation the rights
 *   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *   copies of the Software, and to permit persons to whom the Software is
 *   furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *   SOFTWARE.
 */

#include<string.h>
#include<stdio.h>
#include<stdlib.h>
#include<X11/Xlib.h>
#include<X11/Xatom.h>

#ifdef CLIPBOARD_TEST
  #include<stdio.h>
  typedef int sqInt;
#else
  #include "sqVirtualMachine.h"
  extern struct VirtualMachine* interpreterProxy;
#endif /* ifdef CLIPBOARD_TEST */

extern Display * stDisplay;

char ** clipboardGetTypeNames();
sqInt clipboardSizeWithType(char * typeName, int ntypeName);
sqInt clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex);
void * firstIndexableField(sqInt oop);
void clipboardWriteWithType(char * data, size_t ndata, char * typeName, size_t ntypeName, int isDnd, int isClaiming);

#ifndef CLIPBOARD_TEST

void sqPasteboardClear( sqInt inPasteboard )
{
  /* NOT IMPLEMENTED YET */
}

/* Return a number of types.
 * Update it only if the selection is CLIPBOARD
 */
int sqPasteboardGetItemCount(sqInt inPasteboard)
{
  int i= 0;
  char ** types;
  types= clipboardGetTypeNames();
  if (NULL == types) return 0;
  for (i= 0; NULL != types[i]; i++) free(types[i]); /* XFree() is better */
  free(types);
  return i;
}

/* Answer a type name at index. */
int sqPasteboardCopyItemFlavorsitemNumber (sqInt inPasteboard, int formatNumber)
{
  size_t length;
  int outData;
  char * dest;
  char ** types;
  char * type;

  if (formatNumber < 1)
    return interpreterProxy->nilObject();
  
  /* TODO: clipboardGetTypeNames() is should be cached. */
  /* TODO: types should be free(). */
  types= clipboardGetTypeNames();
  if (types == NULL)
    return interpreterProxy->nilObject();

  type= types[formatNumber - 1];
  if (type == NULL)
    return interpreterProxy->nilObject();

  length= strlen(type);
  outData = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), length);

  dest = ((char *) (interpreterProxy->firstIndexableField(outData)));
  memcpy(dest, type, length);

  return outData;
}

/* In X11 clipboard is global in a display, so it just return 1 */
sqInt sqCreateClipboard( void )
{
  return 1;
}


void sqPasteboardPutItemFlavordatalengthformatTypeformatLength ( sqInt inPasteboard, char * data, int ndata, char * typeName, int ntypeName)
{
  clipboardWriteWithType(data, ndata, typeName, ntypeName, 0, 1);
}


/* Read the clipboard */
int sqPasteboardCopyItemFlavorDataformatformatLength (sqInt inPasteboard, char* format, int formatLength)
{
  int bytes= 0;
  sqInt outData;

  bytes= clipboardSizeWithType(format, formatLength);
  outData = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), bytes);
  clipboardReadIntoAt(bytes, (sqInt) firstIndexableField(outData), 0);
  return outData;
}

#endif /* #ifndef CLIPBOARD_TEST */

#ifdef CLIPBOARD_TEST

static Display * display;

Display * ioGetDisplay()
{
  return display;
}

char * getSelectionData(Atom selection, Atom target, size_t * bytes, XEvent * event)
{
  char * answer= "Hello world!";
  *bytes= strlen(answer) + 1;
  char * result= calloc(*bytes, 1);
  memcpy(result, answer, *bytes);
  return result;
}

void updateInputTargets(Atom * newTargets, int targetSize)
{
}

int main () {
  Window window;
  int i;
  size_t nitems;
  
  display= XOpenDisplay(NULL);
  if(display == NULL) {
    printf("Cannot open display\n");
    return 1;
  }
  window= XCreateSimpleWindow(display, DefaultRootWindow(display),
				 10, 10, 100, 100, 1, 0, 0);
  getItemFravors();
  getItemFravors();

  printf("\n");
  char * text= (char *) getSelectionData(
					 atom("CLIPBOARD"),
					 atom("STRING"), &nitems);
  printf("String contents: %s\n", text);
  return 0;
}

#endif /* CLIPBOARD_TEST */

