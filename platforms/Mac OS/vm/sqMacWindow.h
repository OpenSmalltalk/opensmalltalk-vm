/****************************************************************************
*   PROJECT: Squeak Headers
*   FILE:    sqMacWindow.c
*   CONTENT: 
*
*   AUTHOR:  John Maloney, John McIntosh, and others.
*   ADDRESS: 
*   EMAIL:   johnmci@smalltalkconsulting.com
*   RCSID:   $Id: sqMacWindow.h 1344 2006-03-05 21:07:15Z johnmci $
*
*   NOTES: 
*  Feb 22nd, 2002, JMM moved code into 10 other files, see sqMacMain.c for comments
*  May 5th, 2002, JMM build as NS plugin
*  Jun 7th, 2003, JMM fix up full screen threading issue
*  Sept 11th, 2004, JMM add getDominateScreen
*  Jul 20th, 2004, JMM support for multiple windows
****************************************************************************/

#include <Carbon/Carbon.h>
double ioScreenScaleFactor(void);
void SetWindowTitle(int windowIndex,char *title);
WindowPtr getSTWindow(void);
WindowPtr SetUpWindow(int t,int l,int b, int r, UInt32 windowType, UInt32 windowAttributes);
void SetUpPixmap(void);
void FreePixmap(void);
GDHandle	getThatDominateGDevice(WindowPtr window);
void sqShowWindow(int windowIndex);
