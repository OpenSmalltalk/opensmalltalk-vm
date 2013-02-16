// sqRPCScratchOps.c -- Scratch operations for RISC OS
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

#include "ScratchPlugin.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "oslib/uri.h"

void OpenURL(char *url) {
	// Open a browser on the given URL
	uri_dispatch_result_flags junk;
	wimp_t * junk2;
	uri_dispatch((bits)0, url, wimp_BROADCAST, &junk , junk2 );
}

void SetScratchWindowTitle(char *title) {
	// Set the text in the window title bar.
extern int ioSetTitleOfWindow(int windowIndex, char * newTitle, int sizeOfTitle);
	ioSetTitleOfWindow(1, title,  strlen(title));
}

void GetFolderPathForID(int folderID, char *path, int maxPath) {
  // Get the full path for a special folder:
	//  1 - user's home folder
	//  2 - user's desktop folder
	//  3 - user's document folder
	//  4 - user's photos or pictures folder
	//  5 - user's music folder
	// path is filled in with a zero-terminated string of max length maxPath
	// RISC OS really doesn't do things this way but let's see if it works out
extern char * getImageName();
char * imageName = getImageName();
extern void sqStringFromFilename( char * sqString, char*fileName, int sqSize);
	int imagePathLen = strrchr(imageName, '.') - imageName;

	char *s = NULL;

	path[0] = 0;  // a zero-length path indicates failure

	// get the scratch image's directory
	s = getImageName();
	if ((s == NULL) || (strlen(s) == 0)) return;

	strncat(path, s, imagePathLen -1); // home folder

	if (folderID == 1) return;
	if (folderID == 2) strncat(path, "/Desktop", maxPath);
	if (folderID == 3) strncat(path, "/Documents", maxPath);
	if (folderID == 4) strncat(path, "/Pictures", maxPath);
	if (folderID == 5) strncat(path, "/Music", maxPath);

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


// Serial port stuff not handled at all
int SerialPortCount(void) { return 0;}
void SerialPortName(int portIndex, char *bsdPath, int maxPathSize) {
// Find the name of the given port number. Fill in bsdPath if successful.
// Otherwise, make bsdPath be the empty string.
	*bsdPath = '\0';	// result is the empty string if port not found

}

/* serial port open/close */
int SerialPortOpenPortNamed(char *portName, int baudRate) { return -1;}
void SerialPortClose(int portNum) {}
int SerialPortIsOpen(int portNum) {return 0;}

/* serial port read/write */
int SerialPortRead(int portNum, char *bufPtr, int bufSize) {return 0;}
int SerialPortWrite(int portNum, char *bufPtr, int bufSize) {return 0;}

/* serial port port options */
int SerialPortSetOption(int portNum, int optionNum, int newValue) {return 0;}
int SerialPortGetOption(int portNum, int optionNum){return 0;}
