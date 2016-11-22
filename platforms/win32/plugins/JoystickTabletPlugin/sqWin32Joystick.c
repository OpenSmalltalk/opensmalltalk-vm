/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Joystick.c
*   CONTENT: Joystick management
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*
*   NOTES:
*     1) Only buttons 1-4 are supported
*     2) No z,r,u,v-Values are supported
*****************************************************************************/
#include <windows.h>
#include "sq.h"
#include <mmsystem.h>

#ifndef NO_JOYSTICK

int numJoySticks=0;
JOYCAPS *joySticks = NULL;

/* direct use of interpreter API */
int methodArgumentCount(void);
int stackIntegerValue(int);
int failed(void);
	
int joystickRead(int index)
{
	JOYINFO joyInfo;
	int xBits,yBits,xMax,yMax;
	int buttons;

	index = index - 1;
	if(index < 0 || index > numJoySticks) return 0;

	if(joyGetPos(index,&joyInfo) != JOYERR_NOERROR)
		return 0;

	buttons = joyInfo.wButtons & 0x0F; /* JOYBUTTON1 ... JOYBUTTON4 */
	xMax = joySticks[index].wXmax - joySticks[index].wXmin;
	yMax = joySticks[index].wYmax - joySticks[index].wYmin;
	if(xMax) {
		xBits = ((joyInfo.wXpos - joySticks[index].wXmin) * 0x7FF) / xMax;
	} else {
		xBits = (joyInfo.wXpos - joySticks[index].wXmin) & 0x7FF;
	}
	if(yMax) {
		yBits = ((joyInfo.wYpos - joySticks[index].wYmin) * 0x7FF) / yMax;
	} else {
		yBits = (joyInfo.wYpos - joySticks[index].wYmin) & 0x7FF;
	}
	return (1 << 27) | (buttons << 22) | (yBits << 11) | xBits;
}

int joystickInit(void)		
{
	int i;

	numJoySticks = joyGetNumDevs();
	if(numJoySticks)
		joySticks = calloc(numJoySticks,sizeof(JOYCAPS));
	for(i=0;i<numJoySticks; i++)
		joyGetDevCaps(i,&(joySticks[i]),sizeof(JOYCAPS));
	return 1;
}

int joystickShutdown(void)		
{
	free(joySticks);
	joySticks = NULL;
	return 1;
}

/* win32JoystickDebugInfo:
	Print debugging information for all joysticks.
*/
EXPORT(int) win32JoystickDebugInfo(void)
{
	int i;
	JOYCAPS *caps;

	if(methodArgumentCount() != 0) return primitiveFail();
	warnPrintf(TEXT("<--- Joystick debug information --->\n"));
	for(i=0; i<numJoySticks; i++) {
		caps = joySticks + i;
		warnPrintf(TEXT("Joystick %d:\n"), i);
		warnPrintf(TEXT("\tName: %s\n"), caps->szPname);
		warnPrintf(TEXT("\tMin X: %d\n\tMax X: %d\n"), caps->wXmin, caps->wXmax);
		warnPrintf(TEXT("\tMin Y: %d\n\tMax Y: %d\n"), caps->wYmin, caps->wYmax);
		warnPrintf(TEXT("\tMin Z: %d\n\tMax Z: %d\n"), caps->wZmin, caps->wZmax);
		warnPrintf(TEXT("\tMin R: %d\n\tMax R: %d\n"), caps->wRmin, caps->wRmax);
		warnPrintf(TEXT("\tMin U: %d\n\tMax U: %d\n"), caps->wUmin, caps->wUmax);
		warnPrintf(TEXT("\tMin V: %d\n\tMax V: %d\n"), caps->wVmin, caps->wVmax);
		warnPrintf(TEXT("\tMaxButtons: %d\n"), caps->wMaxButtons);
		warnPrintf(TEXT("\tNumButtons: %d\n"), caps->wNumButtons);
		warnPrintf(TEXT("\tMaxAxes: %d\n"), caps->wMaxAxes);
		warnPrintf(TEXT("\tNumAxes: %d\n"), caps->wNumAxes);

		warnPrintf(TEXT("\tCaps: "));
		if(caps->wCaps & JOYCAPS_HASZ)
			warnPrintf(TEXT("JOYCAPS_HASZ "));
		if(caps->wCaps & JOYCAPS_HASR)
			warnPrintf(TEXT("JOYCAPS_HASR "));
		if(caps->wCaps & JOYCAPS_HASU)
			warnPrintf(TEXT("JOYCAPS_HASU "));
		if(caps->wCaps & JOYCAPS_HASV)
			warnPrintf(TEXT("JOYCAPS_HASV "));
		if(caps->wCaps & JOYCAPS_HASPOV)
			warnPrintf(TEXT("JOYCAPS_HASPOV "));
		warnPrintf(TEXT("\n"));
	}
	return 1;
}

/* win32JoystickDebugPrintRawValues:
	Print the raw values of a readout of the specified joystick.
*/
EXPORT(int) win32JoystickDebugPrintRawValues(void)
{
	int index, err;
	JOYINFO info;

	if(methodArgumentCount() != 1) return primitiveFail();
	index = stackIntegerValue(0);
	if(failed()) return 0;
	if(index < 1 || index > 2) return primitiveFail();

	warnPrintf(TEXT("Raw joystick values (%d):\n"), index);
	err = joyGetPos(index-1, &info);
	if(err != JOYERR_NOERROR) {
		if(err == MMSYSERR_NODRIVER)
			warnPrintf(TEXT("\t<no driver present>\n\n"));
		else if(err == MMSYSERR_INVALPARAM)
			warnPrintf(TEXT("\t<invalid param in joyGetPos()>\n\n"));
		else if(err == MMSYSERR_BADDEVICEID)
			warnPrintf(TEXT("\t<bad device id>\n\n"));
		else if(err == JOYERR_UNPLUGGED)
			warnPrintf(TEXT("\t<joystick unplugged>\n\n"));
		else
			warnPrintf(TEXT("\t<unknown error: %d>\n\n"), err);
	} else {
		warnPrintf(TEXT("\tX: %d\n"), info.wXpos);
		warnPrintf(TEXT("\tY: %d\n"), info.wYpos);
		warnPrintf(TEXT("\tZ: %d\n"), info.wZpos);
		warnPrintf(TEXT("\tButtons: %x\n"), info.wButtons);
	}
	pop(1); /* Leave rcvr on stack */
	return 1;
}

/* win32JoystickDebugPrintAlternativeValues:
	Print the raw values of an alternative readout of the specified joystick.
*/
EXPORT(int) win32JoystickDebugPrintAlternativeValues(void)
{
	int index, err;
	JOYINFOEX info;

	if(methodArgumentCount() != 1) return primitiveFail();
	index = stackIntegerValue(0);
	if(failed()) return 0;
	if(index < 1 || index > 2) return primitiveFail();

	warnPrintf(TEXT("Alternative joystick values (%d):\n"), index);
	info.dwSize = sizeof(info);
	info.dwFlags = JOY_RETURNALL;
	err = joyGetPosEx(index-1, &info);
	if(err != JOYERR_NOERROR) {
		if(err == MMSYSERR_NODRIVER)
			warnPrintf(TEXT("\t<no driver present>\n\n"));
		else if(err == MMSYSERR_INVALPARAM)
			warnPrintf(TEXT("\t<invalid param in joyGetPos()>\n\n"));
		else if(err == MMSYSERR_BADDEVICEID)
			warnPrintf(TEXT("\t<bad device id>\n\n"));
		else if(err == JOYERR_UNPLUGGED)
			warnPrintf(TEXT("\t<joystick unplugged>\n\n"));
		else
			warnPrintf(TEXT("\t<unknown error: %d>\n\n"), err);
	} else {
		warnPrintf(TEXT("\tX: %lu\n"), info.dwXpos);
		warnPrintf(TEXT("\tY: %lu\n"), info.dwYpos);
		warnPrintf(TEXT("\tZ: %lu\n"), info.dwZpos);
		warnPrintf(TEXT("\tR: %lu\n"), info.dwRpos);
		warnPrintf(TEXT("\tU: %lu\n"), info.dwUpos);
		warnPrintf(TEXT("\tV: %lu\n"), info.dwVpos);
		warnPrintf(TEXT("\tButtons: %lx\n"), info.dwButtons);
		warnPrintf(TEXT("\tPOV: %lu\n"), info.dwPOV);
	}
	pop(1); /* Leave rcvr on stack */
	return 1;
}

#endif /* NO_JOYSTICK */
