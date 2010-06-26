/*
 *  sqMacNSPluginUILogic2.h
 *  SqueakVMUNIXPATHS
 *
 */

void setupPipes(void);
int plugInTimeToReturn(void);
int plugInNotifyUser(char *msg);
int primitivePluginBrowserReady(void);
void browserProcessCommand(void);
int MouseModifierStateFromBrowser(EventRecord*);
void signalAnyInterestedParties(void);
int recordKeyboardEvent(EventRecord *, int );
void recordMouseEvent(EventRecord *);
void recordMouseEventCarbon(EventRef ,UInt32 ,Boolean noPointConversion);
Boolean inline browserActiveAndDrawingContextOk(void);
void browserSetCursor(Cursor *macCursor);
int primitivePluginRequestState(void);
int primitivePluginDestroyRequest(void);
int primitivePluginRequestFileHandle(void);
int primitivePluginPostURL(void);
int primitivePluginRequestURLStream(void);
int primitivePluginRequestURL(void);
int browserGetWindowSize(void);
Boolean inline browserActiveAndDrawingContextOkAndNOTInFullScreenMode(void);
Boolean inline browserActiveAndDrawingContextOkAndInFullScreenMode(void);

typedef struct SqueakSharedMemoryBlock {
	int		written;
	int		top;
	int		right;
	int		bottom;
	int		left;
	char	screenBits[];
} SqueakSharedMemoryBlock;