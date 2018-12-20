//  A Squeak VM for RiscOS machines
//  Suited to RISC OS > 4, preferably > 5
// See www.squeak.org for much more information
//
// tim Rowledge tim@rowledge.org
//
// License: MIT License -
// Copyright (C) <2013> <tim rowledge>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// This is sqRPCFileCopy.c
// It implements a nasty little primitive that copies a file using the OS call
// that will keep the filetypes etc as-is.
// It wouldn't be needed if Squeak had a decent filesystem interface

//#define DEBUG
#include "oslib/os.h"
#include "oslib/osfile.h"
#include "oslib/osfscontrol.h"
#include "sq.h"

char fromname[MAXDIRNAMELENGTH];
char toname[MAXDIRNAMELENGTH];

/*** Functions ***/
sqInt sqCopyFilesizetosize(char *srcName, sqInt srcNameSize, char *dstName, sqInt dstNameSize) {
	os_error *e;


	osfscontrol_copy_flags flag = osfscontrol_COPY_FORCE;
		PRINTF(("\\t sqCopyFilesizetosize called\n"));

	if (!canonicalizeFilenameToString(srcName, srcNameSize, fromname))
		return false;

	if (!canonicalizeFilenameToString(dstName, dstNameSize, toname))
		return false;

		PRINTF(("\\t sqCopyFilesizetosize file names ok\n"));

	e = xosfscontrol_copy(
		(char const *)fromname,
		(char const *)toname,
		flag,
		(bits)0,(bits)0,(bits)0,(bits)0,(osfscontrol_descriptor *)0 );

	if (e != NULL) return false;
	PRINTF(("\\t sqCopyFilesizetosize ok\n"));

	return true;
}



