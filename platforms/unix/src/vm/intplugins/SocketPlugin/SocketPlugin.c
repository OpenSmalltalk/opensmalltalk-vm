/* Automatically generated from Squeak on #(18 March 2005 7:42:46 pm) */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Default EXPORT macro that does nothing (see comment in sq.h): */
#define EXPORT(returnType) returnType

/* Do not include the entire sq.h file but just those parts needed. */
/*  The virtual machine proxy definition */
#include "sqVirtualMachine.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */
#include "sqPlatformSpecific.h"

#define true 1
#define false 0
#define null 0  /* using 'null' because nil is predefined in Think C */
#ifdef SQUEAK_BUILTIN_PLUGIN
#undef EXPORT
// was #undef EXPORT(returnType) but screws NorCroft cc
#define EXPORT(returnType) static returnType
#endif
#include "SocketPlugin.h"

/* memory access macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)


/*** Constants ***/

/*** Function Prototypes ***/
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static int halt(void);
#pragma export on
EXPORT(int) initialiseModule(void);
#pragma export off
static int intToNetAddress(int addr);
#pragma export on
EXPORT(int) moduleUnloaded(char * aModuleName);
#pragma export off
static int msg(char *s);
static int netAddressToInt(unsigned char * ptrToByteArray);
#pragma export on
EXPORT(int) primitiveDisableSocketAccess(void);
EXPORT(int) primitiveHasSocketAccess(void);
EXPORT(int) primitiveInitializeNetwork(void);
EXPORT(int) primitiveResolverAbortLookup(void);
EXPORT(int) primitiveResolverAddressLookupResult(void);
EXPORT(int) primitiveResolverError(void);
EXPORT(int) primitiveResolverLocalAddress(void);
EXPORT(int) primitiveResolverNameLookupResult(void);
EXPORT(int) primitiveResolverStartAddressLookup(void);
EXPORT(int) primitiveResolverStartNameLookup(void);
EXPORT(int) primitiveResolverStatus(void);
EXPORT(int) primitiveSocketAbortConnection(void);
EXPORT(int) primitiveSocketAccept(void);
EXPORT(int) primitiveSocketAccept3Semaphores(void);
EXPORT(int) primitiveSocketCloseConnection(void);
EXPORT(int) primitiveSocketConnectToPort(void);
EXPORT(int) primitiveSocketConnectionStatus(void);
EXPORT(int) primitiveSocketCreate(void);
EXPORT(int) primitiveSocketCreate3Semaphores(void);
EXPORT(int) primitiveSocketDestroy(void);
EXPORT(int) primitiveSocketError(void);
EXPORT(int) primitiveSocketGetOptions(void);
EXPORT(int) primitiveSocketListenOnPort(void);
EXPORT(int) primitiveSocketListenOnPortBacklog(void);
EXPORT(int) primitiveSocketListenOnPortBacklogInterface(void);
EXPORT(int) primitiveSocketListenWithOrWithoutBacklog(void);
EXPORT(int) primitiveSocketLocalAddress(void);
EXPORT(int) primitiveSocketLocalPort(void);
EXPORT(int) primitiveSocketReceiveDataAvailable(void);
EXPORT(int) primitiveSocketReceiveDataBufCount(void);
EXPORT(int) primitiveSocketReceiveUDPDataBufCount(void);
EXPORT(int) primitiveSocketRemoteAddress(void);
EXPORT(int) primitiveSocketRemotePort(void);
EXPORT(int) primitiveSocketSendDataBufCount(void);
EXPORT(int) primitiveSocketSendDone(void);
EXPORT(int) primitiveSocketSendUDPDataBufCount(void);
EXPORT(int) primitiveSocketSetOptions(void);
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
EXPORT(int) shutdownModule(void);
#pragma export off
static int socketRecordSize(void);
static SQSocket * socketValueOf(int socketOop);
static int sqAssert(int aBool);
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"SocketPlugin 18 March 2005 (i)"
#else
	"SocketPlugin 18 March 2005 (e)"
#endif
;
static int sCCLOPfn;
static int sCCSOTfn;
static int sCCTPfn;
static int sDSAfn;
static int sHSAfn;



/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*) getModuleName(void) {
	return moduleName;
}

static int halt(void) {
	;
}

EXPORT(int) initialiseModule(void) {
	sDSAfn = interpreterProxy->ioLoadFunctionFrom("secDisableSocketAccess", "SecurityPlugin");
	sHSAfn = interpreterProxy->ioLoadFunctionFrom("secHasSocketAccess", "SecurityPlugin");
	sCCTPfn = interpreterProxy->ioLoadFunctionFrom("secCanConnectToPort", "SecurityPlugin");
	sCCLOPfn = interpreterProxy->ioLoadFunctionFrom("secCanListenOnPort", "SecurityPlugin");
	sCCSOTfn = interpreterProxy->ioLoadFunctionFrom("secCanCreateSocketOfType", "SecurityPlugin");
	return socketInit();
}


/*	Convert the given 32-bit integer into an internet network address represented as a four-byte ByteArray. */

static int intToNetAddress(int addr) {
	char * naPtr;
	int netAddressOop;

	netAddressOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), 4);
	naPtr = (char *) interpreterProxy->firstIndexableField(netAddressOop);
	naPtr[0] = (((char) ((((unsigned) addr) >> 24) & 255)));
	naPtr[1] = (((char) ((((unsigned) addr) >> 16) & 255)));
	naPtr[2] = (((char) ((((unsigned) addr) >> 8) & 255)));
	naPtr[3] = (((char) (addr & 255)));
	return netAddressOop;
}


/*	The module with the given name was just unloaded.
	Make sure we have no dangling references. */

EXPORT(int) moduleUnloaded(char * aModuleName) {
	if ((strcmp(aModuleName, "SecurityPlugin")) == 0) {
		sDSAfn = sHSAfn = sCCTPfn = sCCLOPfn = sCCSOTfn = 0;
	}
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}


/*	Convert the given internet network address (represented as a four-byte ByteArray) into a 32-bit integer. Fail if the given ptrToByteArray does not appear to point to a four-byte ByteArray. */

static int netAddressToInt(unsigned char * ptrToByteArray) {
	int sz;

	sz = interpreterProxy->byteSizeOf(((int) (ptrToByteArray) -4));
	if (!(sz == 4)) {
		return interpreterProxy->primitiveFail();
	}
	return (((ptrToByteArray[3]) + ((ptrToByteArray[2]) << 8)) + ((ptrToByteArray[1]) << 16)) + ((ptrToByteArray[0]) << 24);
}

EXPORT(int) primitiveDisableSocketAccess(void) {
	if (sDSAfn != 0) {
		 ((int (*) (void)) sDSAfn)();
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(1);
	}
}

EXPORT(int) primitiveHasSocketAccess(void) {
	int hasAccess;

	interpreterProxy->pop(1);
	if (sHSAfn != 0) {
		hasAccess =  ((int (*) (void)) sHSAfn)();
	} else {
		hasAccess = 1;
	}
	interpreterProxy->pop(1);
	interpreterProxy->pushBool(hasAccess);
}

EXPORT(int) primitiveInitializeNetwork(void) {
	int err;
	int resolverSemaIndex;

	resolverSemaIndex = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	err = sqNetworkInit(resolverSemaIndex);
	interpreterProxy->success(err == 0);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(int) primitiveResolverAbortLookup(void) {
	sqResolverAbort();
	if (interpreterProxy->failed()) {
		return null;
	}
	return null;
}

EXPORT(int) primitiveResolverAddressLookupResult(void) {
	int s;
	int sz;

	sz = sqResolverAddrLookupResultSize();
	if (!(interpreterProxy->failed())) {
		s = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), sz);
		sqResolverAddrLookupResult((char *) interpreterProxy->firstIndexableField(s), sz);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, s);
	return null;
}

EXPORT(int) primitiveResolverError(void) {
	int _return_value;

	_return_value = interpreterProxy->integerObjectOf((sqResolverError()));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
}

EXPORT(int) primitiveResolverLocalAddress(void) {
	int addr;
	int _return_value;

	addr = sqResolverLocalAddress();
	_return_value = intToNetAddress(addr);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
}

EXPORT(int) primitiveResolverNameLookupResult(void) {
	int addr;
	int _return_value;

	addr = sqResolverNameLookupResult();
	_return_value = intToNetAddress(addr);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
}

EXPORT(int) primitiveResolverStartAddressLookup(void) {
	int addr;
	char *address;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	address = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	addr = netAddressToInt(((unsigned char *) address));
	if (!(interpreterProxy->failed())) {
		sqResolverStartAddrLookup(addr);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(int) primitiveResolverStartNameLookup(void) {
	int sz;
	char *name;

	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	name = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(interpreterProxy->failed())) {
		sz = interpreterProxy->byteSizeOf(((int) (name) -4));
		sqResolverStartNameLookup(name, sz);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(int) primitiveResolverStatus(void) {
	int status;
	int _return_value;

	status = sqResolverStatus();
	_return_value = interpreterProxy->integerObjectOf(status);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
}

EXPORT(int) primitiveSocketAbortConnection(void) {
	SocketPtr s;
	int socket;

	socket = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	s = socketValueOf(socket);
	if (!(interpreterProxy->failed())) {
		sqSocketAbortConnection(s);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(int) primitiveSocketAccept(void) {
	int socketOop;
	SocketPtr serverSocket;
	SocketPtr s;
	int sockHandle;
	int recvBufSize;
	int sendBufSize;
	int semaIndex;

	sockHandle = interpreterProxy->stackValue(3);
	recvBufSize = interpreterProxy->stackIntegerValue(2);
	sendBufSize = interpreterProxy->stackIntegerValue(1);
	semaIndex = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	serverSocket = socketValueOf(sockHandle);
	if (!(interpreterProxy->failed())) {
		socketOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), socketRecordSize());
		s = socketValueOf(socketOop);
		sqSocketAcceptFromRecvBytesSendBytesSemaID(s, serverSocket, recvBufSize, sendBufSize, semaIndex);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(5, socketOop);
	return null;
}

EXPORT(int) primitiveSocketAccept3Semaphores(void) {
	int socketOop;
	SocketPtr serverSocket;
	SocketPtr s;
	int sockHandle;
	int recvBufSize;
	int sendBufSize;
	int semaIndex;
	int aReadSema;
	int aWriteSema;

	sockHandle = interpreterProxy->stackValue(5);
	recvBufSize = interpreterProxy->stackIntegerValue(4);
	sendBufSize = interpreterProxy->stackIntegerValue(3);
	semaIndex = interpreterProxy->stackIntegerValue(2);
	aReadSema = interpreterProxy->stackIntegerValue(1);
	aWriteSema = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	serverSocket = socketValueOf(sockHandle);
	if (!(interpreterProxy->failed())) {
		socketOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), socketRecordSize());
		s = socketValueOf(socketOop);
		sqSocketAcceptFromRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(s, serverSocket, recvBufSize, sendBufSize, semaIndex, aReadSema, aWriteSema);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(7, socketOop);
	return null;
}

EXPORT(int) primitiveSocketCloseConnection(void) {
	SocketPtr s;
	int socket;

	socket = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	s = socketValueOf(socket);
	if (!(interpreterProxy->failed())) {
		sqSocketCloseConnection(s);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(int) primitiveSocketConnectToPort(void) {
	int addr;
	int okToConnect;
	SocketPtr s;
	int socket;
	char *address;
	int port;

	socket = interpreterProxy->stackValue(2);
	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(1)));
	address = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(1))));
	port = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}

	/* If the security plugin can be loaded, use it to check for permission.
	If 
	not, assume it's ok */

	addr = netAddressToInt(((unsigned char *) address));
	if (sCCTPfn != 0) {
		okToConnect =  ((int (*) (int, int)) sCCTPfn)(addr, port);
		if (!(okToConnect)) {
			interpreterProxy->primitiveFail();
			return null;
		}
	}
	s = socketValueOf(socket);
	if (!(interpreterProxy->failed())) {
		sqSocketConnectToPort(s, addr, port);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(3);
	return null;
}

EXPORT(int) primitiveSocketConnectionStatus(void) {
	SocketPtr s;
	int status;
	int socket;
	int _return_value;

	socket = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	s = socketValueOf(socket);
	if (!(interpreterProxy->failed())) {
		status = sqSocketConnectionStatus(s);
	}
	_return_value = interpreterProxy->integerObjectOf(status);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveSocketCreate(void) {
	int socketOop;
	SocketPtr s;
	int okToCreate;
	int netType;
	int socketType;
	int recvBufSize;
	int sendBufSize;
	int semaIndex;

	netType = interpreterProxy->stackIntegerValue(4);
	socketType = interpreterProxy->stackIntegerValue(3);
	recvBufSize = interpreterProxy->stackIntegerValue(2);
	sendBufSize = interpreterProxy->stackIntegerValue(1);
	semaIndex = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (sCCSOTfn != 0) {
		okToCreate =  ((int (*) (int, int)) sCCSOTfn)(netType, socketType);
		if (!(okToCreate)) {
			interpreterProxy->primitiveFail();
			return null;
		}
	}
	socketOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), socketRecordSize());
	s = socketValueOf(socketOop);
	sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaID(s, netType, socketType, recvBufSize, sendBufSize, semaIndex);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(6, socketOop);
	return null;
}

EXPORT(int) primitiveSocketCreate3Semaphores(void) {
	int socketOop;
	SocketPtr s;
	int okToCreate;
	int netType;
	int socketType;
	int recvBufSize;
	int sendBufSize;
	int semaIndex;
	int aReadSema;
	int aWriteSema;

	netType = interpreterProxy->stackIntegerValue(6);
	socketType = interpreterProxy->stackIntegerValue(5);
	recvBufSize = interpreterProxy->stackIntegerValue(4);
	sendBufSize = interpreterProxy->stackIntegerValue(3);
	semaIndex = interpreterProxy->stackIntegerValue(2);
	aReadSema = interpreterProxy->stackIntegerValue(1);
	aWriteSema = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (sCCSOTfn != 0) {
		okToCreate =  ((int (*) (int, int)) sCCSOTfn)(netType, socketType);
		if (!(okToCreate)) {
			interpreterProxy->primitiveFail();
			return null;
		}
	}
	socketOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classByteArray(), socketRecordSize());
	s = socketValueOf(socketOop);
	sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID(s, netType, socketType, recvBufSize, sendBufSize, semaIndex, aReadSema, aWriteSema);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(8, socketOop);
	return null;
}

EXPORT(int) primitiveSocketDestroy(void) {
	SocketPtr s;
	int socket;

	socket = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	s = socketValueOf(socket);
	if (!(interpreterProxy->failed())) {
		sqSocketDestroy(s);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(1);
	return null;
}

EXPORT(int) primitiveSocketError(void) {
	int err;
	SocketPtr s;
	int socket;
	int _return_value;

	socket = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	s = socketValueOf(socket);
	if (!(interpreterProxy->failed())) {
		err = sqSocketError(s);
	}
	_return_value = interpreterProxy->integerObjectOf(err);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveSocketGetOptions(void) {
	int returnedValue;
	int optionNameStart;
	SocketPtr s;
	int optionNameSize;
	int errorCode;
	int results;
	int socket;
	int optionName;

	socket = interpreterProxy->stackValue(1);
	optionName = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	s = socketValueOf(socket);
	interpreterProxy->success(interpreterProxy->isBytes(optionName));
	optionNameStart = ((int) (interpreterProxy->firstIndexableField(optionName)));
	optionNameSize = interpreterProxy->slotSizeOf(optionName);
	if (interpreterProxy->failed()) {
		return null;
	}
	returnedValue = 0;
	errorCode = sqSocketGetOptionsoptionNameStartoptionNameSizereturnedValue(s, optionNameStart, optionNameSize, &returnedValue);
	interpreterProxy->pushRemappableOop(interpreterProxy->integerObjectOf(returnedValue));
	interpreterProxy->pushRemappableOop(interpreterProxy->integerObjectOf(errorCode));
	interpreterProxy->pushRemappableOop(interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 2));
	results = interpreterProxy->popRemappableOop();
	interpreterProxy->storePointerofObjectwithValue(0, results, interpreterProxy->popRemappableOop());
	interpreterProxy->storePointerofObjectwithValue(1, results, interpreterProxy->popRemappableOop());
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, results);
	return null;
}


/*	one part of the wierdass dual prim primitiveSocketListenOnPort which 
	was warped by some demented evil person determined to twist the very 
	nature of reality */

EXPORT(int) primitiveSocketListenOnPort(void) {
	int okToListen;
	SocketPtr s;
	int socket;
	int port;

	socket = interpreterProxy->stackValue(1);
	port = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}

	/* If the security plugin can be loaded, use it to check for permission.
	If 
	not, assume it's ok */

	s = socketValueOf(socket);
	if (sCCLOPfn != 0) {
		okToListen =  ((int (*) (SocketPtr, int)) sCCLOPfn)(s, port);
		if (!(okToListen)) {
			interpreterProxy->primitiveFail();
			return null;
		}
	}
	sqSocketListenOnPort(s, port);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(2);
	return null;
}


/*	second part of the wierdass dual prim primitiveSocketListenOnPort 
	which was warped by some demented evil person determined to twist the 
	very nature of reality */

EXPORT(int) primitiveSocketListenOnPortBacklog(void) {
	int okToListen;
	SocketPtr s;
	int socket;
	int port;
	int backlog;

	socket = interpreterProxy->stackValue(2);
	port = interpreterProxy->stackIntegerValue(1);
	backlog = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}

	/* If the security plugin can be loaded, use it to check for permission.
	If 
	not, assume it's ok */

	s = socketValueOf(socket);
	if (sCCLOPfn != 0) {
		okToListen =  ((int (*) (SocketPtr, int)) sCCLOPfn)(s, port);
		if (!(okToListen)) {
			interpreterProxy->primitiveFail();
			return null;
		}
	}
	sqSocketListenOnPortBacklogSize(s, port, backlog);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(3);
	return null;
}


/*	Bind a socket to the given port and interface address with no more than backlog pending connections.  The socket can be UDP, in which case the backlog should be specified as zero. */

EXPORT(int) primitiveSocketListenOnPortBacklogInterface(void) {
	int addr;
	int okToListen;
	SocketPtr s;
	int socket;
	int port;
	int backlog;
	char *ifAddr;

	socket = interpreterProxy->stackValue(3);
	port = interpreterProxy->stackIntegerValue(2);
	backlog = interpreterProxy->stackIntegerValue(1);
	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(0)));
	ifAddr = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(0))));
	if (interpreterProxy->failed()) {
		return null;
	}

	/* If the security plugin can be loaded, use it to check for permission.
	If 
	not, assume it's ok */

	s = socketValueOf(socket);
	if (sCCLOPfn != 0) {
		okToListen =  ((int (*) (SocketPtr, int)) sCCLOPfn)(s, port);
		if (!(okToListen)) {
			interpreterProxy->primitiveFail();
			return null;
		}
	}
	addr = netAddressToInt(((unsigned char *) ifAddr));
	sqSocketListenOnPortBacklogSizeInterface(s, port, backlog, addr);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->pop(4);
	return null;
}


/*	Backward compatibility */

EXPORT(int) primitiveSocketListenWithOrWithoutBacklog(void) {
	if ((interpreterProxy->methodArgumentCount()) == 2) {
		return primitiveSocketListenOnPort();
	} else {
		return primitiveSocketListenOnPortBacklog();
	}
}

EXPORT(int) primitiveSocketLocalAddress(void) {
	int addr;
	SocketPtr s;
	int socket;
	int _return_value;

	socket = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	s = socketValueOf(socket);
	addr = sqSocketLocalAddress(s);
	_return_value = intToNetAddress(addr);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveSocketLocalPort(void) {
	SocketPtr s;
	int port;
	int socket;
	int _return_value;

	socket = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	s = socketValueOf(socket);
	port = sqSocketLocalPort(s);
	_return_value = interpreterProxy->integerObjectOf(port);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveSocketReceiveDataAvailable(void) {
	int dataIsAvailable;
	SocketPtr s;
	int socket;
	int _return_value;

	socket = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	s = socketValueOf(socket);
	dataIsAvailable = sqSocketReceiveDataAvailable(s);
	_return_value = (dataIsAvailable) ? interpreterProxy->trueObject(): interpreterProxy->falseObject();
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveSocketReceiveDataBufCount(void) {
	int bytesReceived;
	int arrayBase;
	int byteSize;
	SocketPtr s;
	int bufStart;
	int socket;
	int array;
	int startIndex;
	int count;
	int _return_value;

	socket = interpreterProxy->stackValue(3);
	array = interpreterProxy->stackValue(2);
	startIndex = interpreterProxy->stackIntegerValue(1);
	count = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}

	/* buffer can be any indexable words or bytes object */

	s = socketValueOf(socket);
	interpreterProxy->success(interpreterProxy->isWordsOrBytes(array));
	if (interpreterProxy->isWords(array)) {
		byteSize = 4;
	} else {
		byteSize = 1;
	}
	interpreterProxy->success((startIndex >= 1) && ((count >= 0) && (((startIndex + count) - 1) <= (interpreterProxy->slotSizeOf(array)))));
	if (!(interpreterProxy->failed())) {
		arrayBase = ((int) (interpreterProxy->firstIndexableField(array)));
		bufStart = arrayBase + ((startIndex - 1) * byteSize);
		bytesReceived = sqSocketReceiveDataBufCount(s, bufStart, count * byteSize);
	}
	_return_value = interpreterProxy->integerObjectOf((bytesReceived / byteSize));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(5, _return_value);
	return null;
}

EXPORT(int) primitiveSocketReceiveUDPDataBufCount(void) {
	int bytesReceived;
	int arrayBase;
	int address;
	int byteSize;
	int moreFlag;
	SocketPtr s;
	int bufStart;
	int port;
	int results;
	int socket;
	int array;
	int startIndex;
	int count;

	socket = interpreterProxy->stackValue(3);
	array = interpreterProxy->stackValue(2);
	startIndex = interpreterProxy->stackIntegerValue(1);
	count = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}

	/* buffer can be any indexable words or bytes object */

	s = socketValueOf(socket);
	interpreterProxy->success(interpreterProxy->isWordsOrBytes(array));
	if (interpreterProxy->isWords(array)) {
		byteSize = 4;
	} else {
		byteSize = 1;
	}
	interpreterProxy->success((startIndex >= 1) && ((count >= 0) && (((startIndex + count) - 1) <= (interpreterProxy->slotSizeOf(array)))));
	if (!(interpreterProxy->failed())) {
		arrayBase = ((int) (interpreterProxy->firstIndexableField(array)));

		/* allocate storage for results, remapping newly allocated
			 oops in case GC happens during allocation */

		bufStart = arrayBase + ((startIndex - 1) * byteSize);
		address = 0;
		port = 0;
		moreFlag = 0;
		bytesReceived = sqSocketReceiveUDPDataBufCountaddressportmoreFlag(s, bufStart, count * byteSize, &address, &port, &moreFlag);
		interpreterProxy->pushRemappableOop(interpreterProxy->integerObjectOf(port));
		interpreterProxy->pushRemappableOop(intToNetAddress(address));
		interpreterProxy->pushRemappableOop(interpreterProxy->integerObjectOf((bytesReceived / byteSize)));
		interpreterProxy->pushRemappableOop(interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 4));
		results = interpreterProxy->popRemappableOop();
		interpreterProxy->storePointerofObjectwithValue(0, results, interpreterProxy->popRemappableOop());
		interpreterProxy->storePointerofObjectwithValue(1, results, interpreterProxy->popRemappableOop());
		interpreterProxy->storePointerofObjectwithValue(2, results, interpreterProxy->popRemappableOop());
		if (moreFlag) {
			interpreterProxy->storePointerofObjectwithValue(3, results, interpreterProxy->trueObject());
		} else {
			interpreterProxy->storePointerofObjectwithValue(3, results, interpreterProxy->falseObject());
		}
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(5, results);
	return null;
}

EXPORT(int) primitiveSocketRemoteAddress(void) {
	int addr;
	SocketPtr s;
	int socket;
	int _return_value;

	socket = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	s = socketValueOf(socket);
	addr = sqSocketRemoteAddress(s);
	_return_value = intToNetAddress(addr);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveSocketRemotePort(void) {
	SocketPtr s;
	int port;
	int socket;
	int _return_value;

	socket = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	s = socketValueOf(socket);
	port = sqSocketRemotePort(s);
	_return_value = interpreterProxy->integerObjectOf(port);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveSocketSendDataBufCount(void) {
	int arrayBase;
	int bytesSent;
	int byteSize;
	SocketPtr s;
	int bufStart;
	int socket;
	int array;
	int startIndex;
	int count;
	int _return_value;

	socket = interpreterProxy->stackValue(3);
	array = interpreterProxy->stackValue(2);
	startIndex = interpreterProxy->stackIntegerValue(1);
	count = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}

	/* buffer can be any indexable words or bytes object except CompiledMethod  */

	s = socketValueOf(socket);
	interpreterProxy->success(interpreterProxy->isWordsOrBytes(array));
	if (interpreterProxy->isWords(array)) {
		byteSize = 4;
	} else {
		byteSize = 1;
	}
	interpreterProxy->success((startIndex >= 1) && ((count >= 0) && (((startIndex + count) - 1) <= (interpreterProxy->slotSizeOf(array)))));
	if (!(interpreterProxy->failed())) {
		arrayBase = ((int) (interpreterProxy->firstIndexableField(array)));
		bufStart = arrayBase + ((startIndex - 1) * byteSize);
		bytesSent = sqSocketSendDataBufCount(s, bufStart, count * byteSize);
	}
	_return_value = interpreterProxy->integerObjectOf((bytesSent / byteSize));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(5, _return_value);
	return null;
}

EXPORT(int) primitiveSocketSendDone(void) {
	SocketPtr s;
	int done;
	int socket;
	int _return_value;

	socket = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	s = socketValueOf(socket);
	done = sqSocketSendDone(s);
	_return_value = (done) ? interpreterProxy->trueObject(): interpreterProxy->falseObject();
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primitiveSocketSendUDPDataBufCount(void) {
	int arrayBase;
	int bytesSent;
	int address;
	int byteSize;
	SocketPtr s;
	int bufStart;
	int socket;
	int array;
	char *hostAddress;
	int portNumber;
	int startIndex;
	int count;
	int _return_value;

	socket = interpreterProxy->stackValue(5);
	array = interpreterProxy->stackValue(4);
	interpreterProxy->success(interpreterProxy->isBytes(interpreterProxy->stackValue(3)));
	hostAddress = ((char *) (interpreterProxy->firstIndexableField(interpreterProxy->stackValue(3))));
	portNumber = interpreterProxy->stackIntegerValue(2);
	startIndex = interpreterProxy->stackIntegerValue(1);
	count = interpreterProxy->stackIntegerValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}

	/* buffer can be any indexable words or bytes object except CompiledMethod  */

	s = socketValueOf(socket);
	interpreterProxy->success(interpreterProxy->isWordsOrBytes(array));
	if (interpreterProxy->isWords(array)) {
		byteSize = 4;
	} else {
		byteSize = 1;
	}
	interpreterProxy->success((startIndex >= 1) && ((count >= 0) && (((startIndex + count) - 1) <= (interpreterProxy->slotSizeOf(array)))));
	if (!(interpreterProxy->failed())) {
		arrayBase = ((int) (interpreterProxy->firstIndexableField(array)));
		bufStart = arrayBase + ((startIndex - 1) * byteSize);
		address = netAddressToInt(((unsigned char *) hostAddress));
		bytesSent = sqSockettoHostportSendDataBufCount(s, address, portNumber, bufStart, count * byteSize);
	}
	_return_value = interpreterProxy->integerObjectOf((bytesSent / byteSize));
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(7, _return_value);
	return null;
}

EXPORT(int) primitiveSocketSetOptions(void) {
	int returnedValue;
	int optionNameStart;
	int optionValueSize;
	SocketPtr s;
	int optionValueStart;
	int optionNameSize;
	int errorCode;
	int results;
	int socket;
	int optionName;
	int optionValue;

	socket = interpreterProxy->stackValue(2);
	optionName = interpreterProxy->stackValue(1);
	optionValue = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	s = socketValueOf(socket);
	interpreterProxy->success(interpreterProxy->isBytes(optionName));
	optionNameStart = ((int) (interpreterProxy->firstIndexableField(optionName)));
	optionNameSize = interpreterProxy->slotSizeOf(optionName);
	interpreterProxy->success(interpreterProxy->isBytes(optionValue));
	optionValueStart = ((int) (interpreterProxy->firstIndexableField(optionValue)));
	optionValueSize = interpreterProxy->slotSizeOf(optionValue);
	if (interpreterProxy->failed()) {
		return null;
	}
	returnedValue = 0;
	errorCode = sqSocketSetOptionsoptionNameStartoptionNameSizeoptionValueStartoptionValueSizereturnedValue(s, optionNameStart, optionNameSize, optionValueStart, optionValueSize, &returnedValue);
	interpreterProxy->pushRemappableOop(interpreterProxy->integerObjectOf(returnedValue));
	interpreterProxy->pushRemappableOop(interpreterProxy->integerObjectOf(errorCode));
	interpreterProxy->pushRemappableOop(interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 2));
	results = interpreterProxy->popRemappableOop();
	interpreterProxy->storePointerofObjectwithValue(0, results, interpreterProxy->popRemappableOop());
	interpreterProxy->storePointerofObjectwithValue(1, results, interpreterProxy->popRemappableOop());
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, results);
	return null;
}


/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter) {
	int ok;

	interpreterProxy = anInterpreter;
	ok = interpreterProxy->majorVersion() == VM_PROXY_MAJOR;
	if (ok == 0) {
		return 0;
	}
	ok = interpreterProxy->minorVersion() >= VM_PROXY_MINOR;
	return ok;
}

EXPORT(int) shutdownModule(void) {
	return socketShutdown();
}


/*	Return the size of a Smalltalk socket record in bytes. */

static int socketRecordSize(void) {
	return sizeof(SQSocket);
}


/*	Return a pointer to the first byte of of the socket record within the  
	given Smalltalk object, or nil if socketOop is not a socket record. */

static SQSocket * socketValueOf(int socketOop) {
	int socketIndex;

	interpreterProxy->success((interpreterProxy->isBytes(socketOop)) && ((interpreterProxy->byteSizeOf(socketOop)) == (socketRecordSize())));
	if (interpreterProxy->failed()) {
		return null;
	} else {
		socketIndex = ((int) (interpreterProxy->firstIndexableField(socketOop)));
		return (SQSocket *) socketIndex;
	}
}

static int sqAssert(int aBool) {
	/* missing DebugCode */;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* SocketPlugin_exports[][3] = {
	{"SocketPlugin", "primitiveDisableSocketAccess", (void*)primitiveDisableSocketAccess},
	{"SocketPlugin", "primitiveResolverAbortLookup", (void*)primitiveResolverAbortLookup},
	{"SocketPlugin", "primitiveSocketAccept3Semaphores", (void*)primitiveSocketAccept3Semaphores},
	{"SocketPlugin", "primitiveInitializeNetwork", (void*)primitiveInitializeNetwork},
	{"SocketPlugin", "primitiveResolverAddressLookupResult", (void*)primitiveResolverAddressLookupResult},
	{"SocketPlugin", "primitiveSocketConnectionStatus", (void*)primitiveSocketConnectionStatus},
	{"SocketPlugin", "primitiveSocketRemotePort", (void*)primitiveSocketRemotePort},
	{"SocketPlugin", "primitiveSocketSendDataBufCount", (void*)primitiveSocketSendDataBufCount},
	{"SocketPlugin", "primitiveResolverNameLookupResult", (void*)primitiveResolverNameLookupResult},
	{"SocketPlugin", "primitiveSocketListenWithOrWithoutBacklog", (void*)primitiveSocketListenWithOrWithoutBacklog},
	{"SocketPlugin", "primitiveSocketListenOnPortBacklogInterface", (void*)primitiveSocketListenOnPortBacklogInterface},
	{"SocketPlugin", "primitiveSocketDestroy", (void*)primitiveSocketDestroy},
	{"SocketPlugin", "primitiveSocketReceiveDataBufCount", (void*)primitiveSocketReceiveDataBufCount},
	{"SocketPlugin", "primitiveSocketAbortConnection", (void*)primitiveSocketAbortConnection},
	{"SocketPlugin", "primitiveSocketListenOnPort", (void*)primitiveSocketListenOnPort},
	{"SocketPlugin", "primitiveSocketError", (void*)primitiveSocketError},
	{"SocketPlugin", "primitiveSocketLocalPort", (void*)primitiveSocketLocalPort},
	{"SocketPlugin", "primitiveSocketReceiveUDPDataBufCount", (void*)primitiveSocketReceiveUDPDataBufCount},
	{"SocketPlugin", "primitiveHasSocketAccess", (void*)primitiveHasSocketAccess},
	{"SocketPlugin", "primitiveSocketCreate3Semaphores", (void*)primitiveSocketCreate3Semaphores},
	{"SocketPlugin", "primitiveSocketCreate", (void*)primitiveSocketCreate},
	{"SocketPlugin", "primitiveSocketRemoteAddress", (void*)primitiveSocketRemoteAddress},
	{"SocketPlugin", "primitiveSocketSetOptions", (void*)primitiveSocketSetOptions},
	{"SocketPlugin", "primitiveResolverStatus", (void*)primitiveResolverStatus},
	{"SocketPlugin", "primitiveResolverStartNameLookup", (void*)primitiveResolverStartNameLookup},
	{"SocketPlugin", "primitiveSocketSendUDPDataBufCount", (void*)primitiveSocketSendUDPDataBufCount},
	{"SocketPlugin", "initialiseModule", (void*)initialiseModule},
	{"SocketPlugin", "primitiveResolverError", (void*)primitiveResolverError},
	{"SocketPlugin", "primitiveSocketGetOptions", (void*)primitiveSocketGetOptions},
	{"SocketPlugin", "getModuleName", (void*)getModuleName},
	{"SocketPlugin", "primitiveResolverLocalAddress", (void*)primitiveResolverLocalAddress},
	{"SocketPlugin", "setInterpreter", (void*)setInterpreter},
	{"SocketPlugin", "primitiveSocketReceiveDataAvailable", (void*)primitiveSocketReceiveDataAvailable},
	{"SocketPlugin", "primitiveResolverStartAddressLookup", (void*)primitiveResolverStartAddressLookup},
	{"SocketPlugin", "primitiveSocketSendDone", (void*)primitiveSocketSendDone},
	{"SocketPlugin", "primitiveSocketConnectToPort", (void*)primitiveSocketConnectToPort},
	{"SocketPlugin", "shutdownModule", (void*)shutdownModule},
	{"SocketPlugin", "primitiveSocketLocalAddress", (void*)primitiveSocketLocalAddress},
	{"SocketPlugin", "primitiveSocketListenOnPortBacklog", (void*)primitiveSocketListenOnPortBacklog},
	{"SocketPlugin", "primitiveSocketAccept", (void*)primitiveSocketAccept},
	{"SocketPlugin", "moduleUnloaded", (void*)moduleUnloaded},
	{"SocketPlugin", "primitiveSocketCloseConnection", (void*)primitiveSocketCloseConnection},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

