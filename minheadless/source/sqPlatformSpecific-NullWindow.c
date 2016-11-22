sqInt ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY)
{
    return false;
}

sqInt ioForceDisplayUpdate(void)
{
    return 0;
}

sqInt ioFormPrint(sqInt bitsAddr, sqInt width, sqInt height, sqInt depth,
		  double hScale, double vScale, sqInt landscapeFlag)
{
    return 0;
}

sqInt ioSetFullScreen(sqInt fullScreen)
{
    return 0;
}

sqInt ioSetCursor(sqInt cursorBitsIndex, sqInt offsetX, sqInt offsetY)
{
    return 0;
}

sqInt ioSetCursorWithMask(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY)
{
    return 0;
}

sqInt ioShowDisplay(sqInt dispBitsIndex, sqInt width, sqInt height, sqInt depth,
		    sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB)
{
    return 0;
}

sqInt ioHasDisplayDepth(sqInt depth)
{
    return 0;
}

sqInt ioSetDisplayMode(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag)
{
    return 0;
}

char* ioGetWindowLabel(void)
{
    return "";
}

sqInt ioSetWindowLabelOfSize(void *lblIndex, sqInt sz)
{
    return 0;
}

sqInt ioGetWindowWidth(void)
{
    return 0;
}

sqInt ioGetWindowHeight(void)
{
    return 0;
}

sqInt ioSetWindowWidthHeight(sqInt w, sqInt h)
{
    return 0;
}

sqInt ioIsWindowObscured(void)
{
    return 0;
}

/* Events */
sqInt ioGetNextEvent(sqInputEvent *evt)
{
    evt->type = EventTypeNone;
    return 0;
}

sqInt ioSetInputSemaphore(sqInt semaIndex)
{
    return 0;
}

sqInt ioGetButtonState(void)
{
    return 0;
}

sqInt ioGetKeystroke(void)
{
    return 0;
}

sqInt ioMousePoint(void)
{
    return 0;
}

sqInt ioPeekKeystroke(void)
{
    return 0;
}

sqInt ioProcessEvents(void)
{
    return 0;
}

double ioScreenScaleFactor(void)
{
    return 4.0/3.0;
}

sqInt ioScreenSize(void)
{
    return 0;
}

sqInt ioScreenDepth(void)
{
    return 0;
}
