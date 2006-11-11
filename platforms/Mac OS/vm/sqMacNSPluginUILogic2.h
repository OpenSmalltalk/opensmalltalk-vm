/*
 *  sqMacNSPluginUILogic2.h
 *  SqueakVMUNIXPATHS
 *
 */

int setupPipes(void);
int plugInTimeToReturn(void);
int plugInNotifyUser(char *msg);
int primitivePluginBrowserReady(void);
void browserProcessCommand(void);
static void browserReceiveData();
void browserSendInt(int value);
static void browserSend(const void *buf, size_t count);
static void browserReceive(void *buf, size_t count);
static void browserReceiveData(void);
static void npHandler(int fd, void *data, int flags);
static void handle_CMD_SHARED_MEMORY(void);
static void handle_CMD_EVENT(void);
int MouseModifierStateFromBrowser(EventRecord*);
void signalAnyInterestedParties(void);
int recordKeyboardEvent(EventRecord *, int );
int recordMouseEvent(EventRecord *);
void recordMouseEventCarbon(EventRef ,UInt32 );
Boolean browserActiveAndDrawingContextOk(void);
void browserSetCursor(Cursor *macCursor);
int primitivePluginRequestState(void);
int primitivePluginDestroyRequest(void);
int primitivePluginRequestFileHandle(void);
int primitivePluginPostURL(void);
int primitivePluginRequestURLStream(void);
int primitivePluginRequestURL(void);