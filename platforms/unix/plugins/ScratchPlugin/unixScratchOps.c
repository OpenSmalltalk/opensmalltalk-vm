/* unixScratchOps.c -- Scratch operations for unix based OSes.
 *
 * 
 *   Copyright (C) 2011 Massachusetts Institute of Technology
 *   All rights reserved.
 *   
 *   Permission is hereby granted, free of charge, to any person obtaining a
 *   copy of this software and associated documentation files (the "Software"),
 *   to deal in the Software without restriction, including without limitation
 *   the rights to use, copy, modify, merge, publish, distribute, sublicense,
 *   and/or sell copies of the Software, and to permit persons to whom the
 *   Software is furnished to do so, subject to the following conditions:
 * 
 *   The above copyright notice and this permission notice shall be included in
 *   all copies or substantial portions of the Software.
 * 
 *   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 *   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 *   DEALINGS IN THE SOFTWARE.
 *
 */

#include "ScratchPlugin.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

void OpenURL(char *url) {
	// Open a browser on the given URL.
#ifdef I_REALLY_DONT_CARE_HOW_UNSAFE_THIS_IS
	char cmd[1000] = "xdg-open ";
 	strcat( cmd, url); 
 	system(cmd);
#else
	// Implement a secure way here.
	// IMHO it would be best to call a script that the user or
	// package maintainer can customize. But in any case,
	// DO NOT call system() with an unchecked URL. --bf
#endif
}

void SetScratchWindowTitle(char *title) {
	// Set the text in the window title bar. Not yet implemented.
}

void GetFolderPathForID(int folderID, char *path, int maxPath) {
  // Get the full path for a special folder:
	//  1 - user's home folder
	//  2 - user's desktop folder
	//  3 - user's document folder
	//  4 - user's photos or pictures folder (does Linux have a convention for this?)
	//  5 - user's music folder (does Linux have a convention for this?)
	// path is filled in with a zero-terminated string of max length maxPath

	char *s = NULL;

	path[0] = 0;  // a zero-length path indicates failure
	
	// get the user's HOME directory
	s = getenv("HOME");
	if ((s == NULL) || (strlen(s) == 0)) return;

	strncat(path, s, maxPath); // home folder

	if (folderID == 1) return;
	if (folderID == 2) strncat(path, "/Desktop", maxPath);
	if (folderID == 4) strncat(path, "/Pictures", maxPath);
	if (folderID == 5) strncat(path, "/Music", maxPath);
	
	if (folderID == 3) {
		s = getenv("SUGAR_ACTIVITY_ROOT");
		if (s != NULL) {
			// On XO, return the writeable activity "data" directory
			strncat(path, s, maxPath);
			strncat(path, "/data", maxPath);
		} else  {
			strncat(path, "/Documents", maxPath);
		}
	}
}

int WinShortToLongPath(char *shortPath, char* longPath, int maxPath) {
	return -1; // fail on non-Windows platforms
}

int IsFileOrFolderHidden(char *fullPath) {
	// Always return false on Linux
	return 0;
}

void SetUnicodePasteBuffer(short int *utf16, int count) {
	// Store the given Unicode UTF16 string in the paste buffer.
	// No longer needed; use clipboard methods in UnicodePlugin.
}
