/* Automatically generated from Squeak on #(19 March 2005 10:09:13 am) */

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
#include <X11/Xlib.h>

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
static int msg(char *s);
#pragma export on
EXPORT(int) primitiveCanConnectToDisplay(void);
EXPORT(int) primitiveDisconnectDisplay(void);
EXPORT(int) primitiveFlushDisplay(void);
EXPORT(int) primitiveGetDisplayName(void);
EXPORT(int) primitiveIsConnectedToDisplay(void);
EXPORT(int) primitiveKillDisplay(void);
EXPORT(int) primitiveModuleName(void);
EXPORT(int) primitiveOpenDisplay(void);
EXPORT(int) primitiveSetDisplayName(void);
EXPORT(int) primitiveVersionString(void);
#pragma export off
static int sandboxSecurity(void);
static int securityHeurisitic(void);
#pragma export on
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
EXPORT(int) shutdownModule(void);
#pragma export off
static int stringFromCString(char *aCString);
static char * transientCStringFromString(int aString);
static char * versionString(void);
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"XDisplayControlPlugin 19 March 2005 (i)"
#else
	"XDisplayControlPlugin 19 March 2005 (e)"
#endif
;
static int osprocessSandboxSecurity;



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
	osprocessSandboxSecurity = -1;
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}


/*	Open and close a connection to displayName. It the connection was successfully
	opened, answer true; otherwise false. This is intended to check for the ability
	to open an X display prior to actually making the attempt. */

EXPORT(int) primitiveCanConnectToDisplay(void) {
    int name;
    char * namePtr;
    Display *d;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(2);
		interpreterProxy->push(interpreterProxy->falseObject());
	} else {
		name = interpreterProxy->stackObjectValue(0);
		namePtr = transientCStringFromString(name);
		d = XOpenDisplay(namePtr);
		if (d == 0) {
			interpreterProxy->pop(2);
			interpreterProxy->push(interpreterProxy->falseObject());
		} else {
			XCloseDisplay(d);
			interpreterProxy->pop(2);
			interpreterProxy->push(interpreterProxy->trueObject());
		}
	}
}


/*	Call an internal function which will disconnect the X display session. The actual
	Squeak window on the X server is not effected, but this instance of Squeak will
	not have any further interaction with it. */

EXPORT(int) primitiveDisconnectDisplay(void) {
	if (!((sandboxSecurity()) == 1)) {
		forgetXDisplay();
	}
}


/*	Call an internal function to synchronize output to the X display. */

EXPORT(int) primitiveFlushDisplay(void) {
	synchronizeXDisplay();
}


/*	Answer a string containing the name for the X display, or nil if the display was opened
	using the $DISPLAY environment variable. This answers the name of the X display as of
	the time it was last opened, which may be different from the current setting of $DISPLAY. */

EXPORT(int) primitiveGetDisplayName(void) {
    extern char *displayName;

	if (displayName == 0) {
		interpreterProxy->pop(1);
		interpreterProxy->push(interpreterProxy->nilObject());
	} else {
		interpreterProxy->pop(1);
		interpreterProxy->push(stringFromCString(displayName));
	}
}


/*	Answer true if VM is currently connected to an X server. */

EXPORT(int) primitiveIsConnectedToDisplay(void) {
    extern int isConnectedToXServer;

	if (isConnectedToXServer != 0) {
		interpreterProxy->pop(1);
		interpreterProxy->push(interpreterProxy->trueObject());
	} else {
		interpreterProxy->pop(1);
		interpreterProxy->push(interpreterProxy->falseObject());
	}
}


/*	Call an internal function to disconnect the X display session and destroy
	the Squeak window on the X display. */

EXPORT(int) primitiveKillDisplay(void) {
	if (!((sandboxSecurity()) == 1)) {
		disconnectXDisplay();
	}
}


/*	Answer a string containing the module name string for this plugin. */

EXPORT(int) primitiveModuleName(void) {
    char *s;

	s= (char *)moduleName;
	interpreterProxy->pop(1);
	interpreterProxy->push(stringFromCString(s));
}


/*	Call an internal function which will open the X display session. */

EXPORT(int) primitiveOpenDisplay(void) {
	if (!((sandboxSecurity()) == 1)) {
		openXDisplay();
	}
}


/*	Set the name for the X display for use in the next call to primitiveOpenXDisplay. Expects
	one parameter which must be either a String or nil. */

EXPORT(int) primitiveSetDisplayName(void) {
    extern char *displayName;
    static char nameBuffer[501];
    int name;
    char * namePtr;

	if ((sandboxSecurity()) == 1) {
		interpreterProxy->pop(2);
		interpreterProxy->pushInteger(-1);
	} else {
		name = interpreterProxy->stackObjectValue(0);
		if (name == (interpreterProxy->nilObject())) {
			displayName = 0;
		} else {
			namePtr = transientCStringFromString(name);
			strncpy(nameBuffer, namePtr, 500);
			nameBuffer[500] = 0;
			displayName = nameBuffer;
		}
		interpreterProxy->pop(1);
	}
}


/*	Answer a string containing the version string for this plugin. */

EXPORT(int) primitiveVersionString(void) {
	interpreterProxy->pop(1);
	interpreterProxy->push(stringFromCString(versionString()));
}


/*	Answer 1 if running in secure mode, else 0. The osprocessSandboxSecurity
	variable is initialized to -1. On the first call to this method, set its value to
	either 0 (user has full access to the plugin) or 1 (user is not permitted to do
	dangerous things). */

static int sandboxSecurity(void) {
	if (osprocessSandboxSecurity < 0) {
		osprocessSandboxSecurity = securityHeurisitic();
	}
	return osprocessSandboxSecurity;
}


/*	Answer 0 to permit full access to OSProcess functions, or 1 if access should be
	restricted for dangerous functions. The rules are:
		- If the security plugin is not present, grant full access
		- If the security plugin can be loaded, restrict access unless user has all
		  of secCanWriteImage, secHasFileAccess and secHasSocketAccess */
/*	FIXME: This function has not been tested. -dtl */
/*	If the security plugin can be loaded, use it to check. If not, assume it's ok */

static int securityHeurisitic(void) {
    int hasSocketAccess;
    int sHSAfn;
    int canWriteImage;
    int sCWIfn;
    int sHFAfn;
    int hasFileAccess;

	sCWIfn = interpreterProxy->ioLoadFunctionFrom("secCanWriteImage", "SecurityPlugin");
	if (sCWIfn == 0) {
		return 0;
	}
	canWriteImage =  ((int (*) (void)) sCWIfn)();
	sHFAfn = interpreterProxy->ioLoadFunctionFrom("secHasFileAccess", "SecurityPlugin");
	if (sHFAfn == 0) {
		return 0;
	}
	hasFileAccess =  ((int (*) (void)) sHFAfn)();
	sHSAfn = interpreterProxy->ioLoadFunctionFrom("secHasSocketAccess", "SecurityPlugin");
	if (sHSAfn == 0) {
		return 0;
	}
	hasSocketAccess =  ((int (*) (void)) sHSAfn)();
	if ((canWriteImage && (hasFileAccess)) && (hasSocketAccess)) {
		return 0;
	} else {
		return 1;
	}
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
}


/*	Answer a new String copied from a null-terminated C string.
	Caution: This may invoke the garbage collector. */

static int stringFromCString(char *aCString) {
    int len;
    char *stringPtr;
    int newString;

	len = strlen(aCString);
	newString = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), len);
	stringPtr = interpreterProxy->arrayValueOf(newString);
	(char *)strncpy(stringPtr, aCString, len);
	return newString;
}


/*	Answer a new null-terminated C string copied from aString.
	The string is allocated in object memory, and will be moved
	without warning by the garbage collector. Any C pointer
	reference the the result is valid only until the garbage
	collector next runs. Therefore, this method should only be used
	within a single primitive in a section of code in which the
	garbage collector is guaranteed not to run. Note also that
	this method may itself invoke the garbage collector prior
	to allocating the new C string.

	Warning: The result of this method will be invalidated by the
	next garbage collection, including a GC triggered by creation
	of a new object within a primitive. Do not call this method
	twice to obtain two string pointers. */

static char * transientCStringFromString(int aString) {
    int len;
    char *cString;
    char *stringPtr;
    int newString;


	/* Allocate space for a null terminated C string. */

	len = interpreterProxy->sizeOfSTArrayFromCPrimitive(interpreterProxy->arrayValueOf(aString));
	interpreterProxy->pushRemappableOop(aString);
	newString = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), len + 1);
	stringPtr = interpreterProxy->arrayValueOf(interpreterProxy->popRemappableOop());

	/* Point to the actual C string. */

	cString = interpreterProxy->arrayValueOf(newString);
	(char *)strncpy(cString, stringPtr, len);
	cString[len] = 0;
	return cString;
}


/*	Answer a string containing the version string for this plugin. Handle MNU
	errors, which can occur if class InterpreterPlugin has been removed from
	the system.

	Important: When this method is changed, the class side method must also be
	changed to match. */

static char * versionString(void) {
    static char version[]= "1.0";

	return version;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* XDisplayControlPlugin_exports[][3] = {
	{"XDisplayControlPlugin", "primitiveGetDisplayName", (void*)primitiveGetDisplayName},
	{"XDisplayControlPlugin", "primitiveDisconnectDisplay", (void*)primitiveDisconnectDisplay},
	{"XDisplayControlPlugin", "primitiveIsConnectedToDisplay", (void*)primitiveIsConnectedToDisplay},
	{"XDisplayControlPlugin", "primitiveOpenDisplay", (void*)primitiveOpenDisplay},
	{"XDisplayControlPlugin", "primitiveCanConnectToDisplay", (void*)primitiveCanConnectToDisplay},
	{"XDisplayControlPlugin", "initialiseModule", (void*)initialiseModule},
	{"XDisplayControlPlugin", "shutdownModule", (void*)shutdownModule},
	{"XDisplayControlPlugin", "primitiveSetDisplayName", (void*)primitiveSetDisplayName},
	{"XDisplayControlPlugin", "primitiveVersionString", (void*)primitiveVersionString},
	{"XDisplayControlPlugin", "primitiveModuleName", (void*)primitiveModuleName},
	{"XDisplayControlPlugin", "primitiveFlushDisplay", (void*)primitiveFlushDisplay},
	{"XDisplayControlPlugin", "primitiveKillDisplay", (void*)primitiveKillDisplay},
	{"XDisplayControlPlugin", "getModuleName", (void*)getModuleName},
	{"XDisplayControlPlugin", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

