/****************************************************************************
*   PROJECT: Squeak port for Win32 (NT / Win95)
*   FILE:    sqWin32Stubs.c
*   CONTENT: Stubs for most optional primitives
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: University of Magdeburg, Germany
*   EMAIL:   raab@isg.cs.uni-magdeburg.de
*
*****************************************************************************/
#include "sq.h"

sqInt ioDisablePowerManager(sqInt disableIfNonZero) { return success(false); }

#ifdef NO_SOUND
int snd_AvailableSpace(void) { return success(false); }
int snd_InsertSamplesFromLeadTime(int frameCount, int srcBufPtr, int samplesOfLeadTime) { return success(false); }
int snd_PlaySamplesFromAtLength(int frameCount, int arrayIndex, int startIndex) { return success(false); }
int snd_PlaySilence(void) { return success(false); }
int snd_Start(int frameCount, int samplesPerSec, int stereo, int semaIndex) { return success(false); }
int snd_Stop(void) { return 1; }
int snd_SetRecordLevel(int level) { return success(false); }
int snd_StartRecording(int desiredSamplesPerSec, int stereo, int semaIndex) { return success(false); }
int snd_StopRecording(void) { return success(false); }
double snd_GetRecordingSampleRate(void) { return success(false); }
int snd_RecordSamplesIntoAtLength(int buf, int startSliceIndex, int bufferSizeInBytes) { return success(false); }
#endif

#ifdef NO_JOYSTICK
int joystickInit(void) { return 1; }
int joystickRead(int stickIndex) { return success(false); }
#endif

#ifdef NO_NETWORK
int		sqNetworkInit(int resolverSemaIndex) { return success(false); }
void	sqNetworkShutdown(void) { }
void	sqResolverAbort(void) { success(false); }
void	sqResolverAddrLookupResult(char *nameForAddress, int nameSize) { success(false); }
int		sqResolverAddrLookupResultSize(void) { return success(false); }
int		sqResolverError(void) { return success(false); }
int		sqResolverLocalAddress(void) { return success(false); }
int		sqResolverNameLookupResult(void) { return success(false); }
void	sqResolverStartAddrLookup(int address) { success(false); }
void	sqResolverStartNameLookup(char *hostName, int nameSize) { success(false); }
int		sqResolverStatus(void) { return success(false); }
void	sqSocketAbortConnection(SocketPtr s) { success(false); }
void	sqSocketCloseConnection(SocketPtr s) { success(false); }
int		sqSocketConnectionStatus(SocketPtr s) { return success(false); }
void	sqSocketConnectToPort(SocketPtr s, int addr, int port) { success(false); }
void	sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaID(
			SocketPtr s, int netType, int socketType,
			int recvBufSize, int sendBufSize, int semaIndex) { success(false); }
void	sqSocketDestroy(SocketPtr s) { success(false); }
int		sqSocketError(SocketPtr s) { return success(false); }
void	sqSocketListenOnPort(SocketPtr s, int port) { success(false); }
int		sqSocketLocalAddress(SocketPtr s) { return success(false); }
int		sqSocketLocalPort(SocketPtr s) { return success(false); }
int		sqSocketReceiveDataAvailable(SocketPtr s) { return success(false); }
int		sqSocketReceiveDataBufCount(SocketPtr s, int buf, int bufSize) { return success(false); }
int		sqSocketRemoteAddress(SocketPtr s) { return success(false); }
int		sqSocketRemotePort(SocketPtr s) { return success(false); }
int		sqSocketSendDataBufCount(SocketPtr s, int buf, int bufSize) { return success(false); }
int		sqSocketSendDone(SocketPtr s) { return success(false); }
void	sqSocketListenOnPortBacklogSize(SocketPtr s, int port, int backlogSize) { success(false); }
void	sqSocketAcceptFromRecvBytesSendBytesSemaID(
            SocketPtr s, SocketPtr serverSocket,
            int recvBufSize, int sendBufSize, int semaIndex) { success(false); }
#endif

#ifdef NO_SERIAL_PORT
int serialPortClose(int portNum) { return 1; }
int serialPortOpen(
  int portNum, int baudRate, int stopBitsType, int parityType, int dataBits,
  int inFlowCtrl, int outFlowCtrl, int xOnChar, int xOffChar) { return success(false); }
int serialPortReadInto(int portNum, int count, void *bufferPtr) { return success(false); }
int serialPortWriteFrom(int portNum, int count, void *bufferPtr) { return success(false); }
#endif

#ifdef NO_MIDI
void SetupMIDI(void) {}
int sqMIDIGetClock(void) { return success(false); }
int sqMIDIGetPortCount(void) { return success(false); }
int sqMIDIGetPortDirectionality(int portNum) { return success(false); }
int sqMIDIGetPortName(int portNum, char *namePtr, int length) { return success(false); }
int sqMIDIClosePort(int portNum) { return 1; }
int sqMIDIOpenPort(int portNum, int readSemaIndex, int interfaceClockRate) { return success(false); }
int sqMIDIParameter(int whichParameter, int modify, int newValue) { return success(false); }
int sqMIDIPortReadInto(int portNum, int count, char *bufferPtr) { return success(false); }
int sqMIDIPortWriteFromAt(int portNum, int count, char *bufferPtr, int time) { return success(false); }
#endif


#ifdef NO_ASYNC_FILES
int asyncFileClose(AsyncFile *f) { return success(false); }
int asyncFileOpen(AsyncFile *f, char *fileNamePtr, int fileNameSize, int writeFlag, int semaIndex) { return success(false); }
int asyncFileRecordSize() { return success(false); }
int asyncFileReadResult(AsyncFile *f, void *bufferPtr, int bufferSize) { return success(false); }
int asyncFileReadStart(AsyncFile *f, int fPosition, int count) { return success(false); }
int asyncFileWriteResult(AsyncFile *f) { return success(false); }
int asyncFileWriteStart(AsyncFile *f, int fPosition, void *bufferPtr, int bufferSize) { return success(false); }
#endif

#ifdef NO_TABLET
int tabletGetParameters(int cursorIndex, int result[]) { return success(false); }
int tabletRead(int cursorIndex, int result[]) { return success(false); }
int tabletResultSize(void) { return success(false); }
#endif
