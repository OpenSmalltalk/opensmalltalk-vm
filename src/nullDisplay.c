#include "pharovm/pharo.h"

#define UNIMPLEMENTED unimplementedPrimitive(__FUNCTION__);

void unimplementedPrimitive(const char* name){
	logWarn("Unimplemented primitive: %s\n", name);
}

#ifdef _WIN32
int ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY)
#else
sqInt ioSetCursorARGB(sqInt cursorBitsIndex, sqInt extentX, sqInt extentY, sqInt offsetX, sqInt offsetY)
#endif
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioForceDisplayUpdate(void)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioFormPrint(sqInt bitsAddr, sqInt width, sqInt height, sqInt depth,
		  double hScale, double vScale, sqInt landscapeFlag)
{
	UNIMPLEMENTED
	return 0;
}

void
ioNoteDisplayChangedwidthheightdepth(void *b, int w, int h, int d)
{
	UNIMPLEMENTED
}

sqInt
ioSetFullScreen(sqInt fullScreen)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioSetCursor(sqInt cursorBitsIndex, sqInt offsetX, sqInt offsetY)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioSetCursorWithMask(sqInt cursorBitsIndex, sqInt cursorMaskIndex, sqInt offsetX, sqInt offsetY)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioShowDisplay(sqInt dispBitsIndex, sqInt width, sqInt height, sqInt depth,
		    sqInt affectedL, sqInt affectedR, sqInt affectedT, sqInt affectedB)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioHasDisplayDepth(sqInt depth)
{
	return true;
}

sqInt
ioSetDisplayMode(sqInt width, sqInt height, sqInt depth, sqInt fullscreenFlag)
{
	UNIMPLEMENTED
	return 0;
}

char*
ioGetWindowLabel(void)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioSetWindowLabelOfSize(void *lblIndex, sqInt sz)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioGetWindowWidth(void)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioGetWindowHeight(void)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioSetWindowWidthHeight(sqInt w, sqInt h)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioIsWindowObscured(void)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioGetNextEvent(sqInputEvent *evt)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioGetButtonState(void)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioGetKeystroke(void)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioMousePoint(void)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioPeekKeystroke(void)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioProcessEvents(void)
{
    aioPoll(0);
    return 0;
}

double
ioScreenScaleFactor(void)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioScreenSize(void)
{
	UNIMPLEMENTED
	return 0;
}

sqInt
ioScreenDepth(void)
{
	UNIMPLEMENTED
	return 0;
}

sqInt clipboardSize(void)
{
	UNIMPLEMENTED
    return 0;
}

sqInt
clipboardReadIntoAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
	UNIMPLEMENTED
    return 0;
}

sqInt
clipboardWriteFromAt(sqInt count, sqInt byteArrayIndex, sqInt startIndex)
{
	UNIMPLEMENTED
    return 0;
}

static sqInt
dropInit (void)
{
	UNIMPLEMENTED
    return 0;
}

static sqInt
dropShutdown (void)
{
	UNIMPLEMENTED
    return 0;
}

char*
dropRequestFileName(sqInt dropIndex)
{
	UNIMPLEMENTED
    return 0;
}

sqInt
dropRequestFileHandle(sqInt dropIndex)
{
	UNIMPLEMENTED
    return nilObject();
}

sqInt
ioBeep(void)
{
	UNIMPLEMENTED
    return 0;
}

sqInt
ioDisablePowerManager(sqInt disableIfNonZero){
	UNIMPLEMENTED
    return true;
}

void
ioClearProfile(void){
	UNIMPLEMENTED
}

long
ioControlNewProfile(int on, unsigned long buffer_size){
	UNIMPLEMENTED
	return 0;
}


int plugInNotifyUser(char *msg) {
	UNIMPLEMENTED
	return 0;
}

int plugInTimeToReturn(void) {
    return false;
}

void
ioNewProfileStatus(sqInt *running, long *buffersize)
{
	UNIMPLEMENTED
}

long
ioNewProfileSamplesInto(void *sampleBuffer)
{
	UNIMPLEMENTED
    return 0;
}


sqInt crashInThisOrAnotherThread(sqInt flags)
{
	UNIMPLEMENTED
	return 0;
}

sqInt ioSetInputSemaphore(sqInt semaIndex){
	UNIMPLEMENTED;
	return 1;
}

void ioSignalInputEvent(void){
	UNIMPLEMENTED;
}

char* ioGetLogDirectory(void){
    return (char*)"";
}

sqInt ioSetLogDirectoryOfSize(void* lblIndex, sqInt sz){
    return 1;
}
