/* Automatically generated by
	SmartSyntaxPluginCodeGenerator VMMaker.oscog-eem.2847 uuid: 7737c3b2-b284-4437-8070-d692253551e5
   from
	ClipboardExtendedPlugin VMMaker.oscog-eem.2847 uuid: 7737c3b2-b284-4437-8070-d692253551e5
 */
static char __buildInfo[] = "ClipboardExtendedPlugin VMMaker.oscog-eem.2847 uuid: 7737c3b2-b284-4437-8070-d692253551e5 " __DATE__ ;



#include "config.h"
#include <math.h>
#include "sqMathShim.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Default EXPORT macro that does nothing (see comment in sq.h): */
#define EXPORT(returnType) returnType

/* Do not include the entire sq.h file but just those parts needed. */
#include "sqConfig.h"			/* Configuration options */
#include "sqVirtualMachine.h"	/*  The virtual machine proxy definition */
#include "sqPlatformSpecific.h"	/* Platform specific definitions */

#define true 1
#define false 0
#define null 0  /* using 'null' because nil is predefined in Think C */
#ifdef SQUEAK_BUILTIN_PLUGIN
# undef EXPORT
# define EXPORT(returnType) static returnType
# define INT_EXT "(i)"
#else
# define INT_EXT "(e)"
#endif

#include "sqMemoryAccess.h"


/*** Constants ***/
#define PrimErrBadArgument 3


/*** Function Prototypes ***/
EXPORT(const char*) getModuleName(void);
EXPORT(sqInt) ioAddClipboardData(void);
EXPORT(sqInt) ioClearClipboard(void);
EXPORT(sqInt) ioCreateClipboard(void);
EXPORT(sqInt) ioGetClipboardFormat(void);
EXPORT(sqInt) ioReadClipboardData(void);
EXPORT(sqInt) setInterpreter(struct VirtualMachine *anInterpreter);


/*** Variables ***/

#if !defined(SQUEAK_BUILTIN_PLUGIN)
static sqInt (*failed)(void);
static void * (*firstIndexableField)(sqInt oop);
#if !defined(integerValueOf)
static sqInt (*integerValueOf)(sqInt oop);
#endif
static sqInt (*isBytes)(sqInt oop);
#if !defined(isIntegerObject)
static sqInt (*isIntegerObject)(sqInt objectPointer);
#endif
static sqInt (*methodReturnValue)(sqInt oop);
static sqInt (*nilObject)(void);
static sqInt (*pop)(sqInt nItems);
static sqInt (*positive32BitIntegerFor)(unsigned int integerValue);
static sqInt (*positive64BitIntegerFor)(usqLong integerValue);
static usqIntptr_t (*positiveMachineIntegerValueOf)(sqInt oop);
static sqInt (*primitiveFailFor)(sqInt reasonCode);
static sqInt (*slotSizeOf)(sqInt oop);
static sqInt (*stackValue)(sqInt offset);
#else /* !defined(SQUEAK_BUILTIN_PLUGIN) */
extern sqInt failed(void);
extern void * firstIndexableField(sqInt oop);
#if !defined(integerValueOf)
extern sqInt integerValueOf(sqInt oop);
#endif
extern sqInt isBytes(sqInt oop);
#if !defined(isIntegerObject)
extern sqInt isIntegerObject(sqInt objectPointer);
#endif
extern sqInt methodReturnValue(sqInt oop);
extern sqInt nilObject(void);
extern sqInt pop(sqInt nItems);
extern sqInt positive32BitIntegerFor(unsigned int integerValue);
extern sqInt positive64BitIntegerFor(usqLong integerValue);
extern usqIntptr_t positiveMachineIntegerValueOf(sqInt oop);
extern sqInt primitiveFailFor(sqInt reasonCode);
extern sqInt slotSizeOf(sqInt oop);
extern sqInt stackValue(sqInt offset);
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName = "ClipboardExtendedPlugin VMMaker.oscog-eem.2847 " INT_EXT;



/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

	/* InterpreterPlugin>>#getModuleName */
EXPORT(const char*)
getModuleName(void)
{
	return moduleName;
}

	/* ClipboardExtendedPlugin>>#ioAddClipboardData:data:dataFormat: */
EXPORT(sqInt)
ioAddClipboardData(void)
{
	char *aFormat;
	sqInt clipboard;
	usqIntptr_t clipboardAddress;
	char *data;
	sqInt dataLength;
	sqInt formatLength;

	if (!((isBytes(stackValue(1)))
		 && (isBytes(stackValue(0))))) {
		primitiveFailFor(PrimErrBadArgument);
		return null;
	}
	clipboard = stackValue(2);
	data = ((char *) (firstIndexableField(stackValue(1))));
	aFormat = ((char *) (firstIndexableField(stackValue(0))));
	if (failed()) {
		return null;
	}
	clipboardAddress = positiveMachineIntegerValueOf(clipboard);
	dataLength = slotSizeOf(((sqInt)(sqIntptr_t)(data) - BaseHeaderSize));
	formatLength = slotSizeOf(((sqInt)(sqIntptr_t)(aFormat) - BaseHeaderSize));
	sqPasteboardPutItemFlavordatalengthformatTypeformatLength(clipboardAddress, data, dataLength, aFormat, formatLength);
	if (!(failed())) {
		pop(3);
	}
	return null;
}

	/* ClipboardExtendedPlugin>>#ioClearClipboard: */
EXPORT(sqInt)
ioClearClipboard(void)
{
	sqInt clipboard;
	usqIntptr_t clipboardAddress;

	clipboard = stackValue(0);
	if (failed()) {
		return null;
	}
	clipboardAddress = positiveMachineIntegerValueOf(clipboard);
	sqPasteboardClear(clipboardAddress);
	if (!(failed())) {
		pop(1);
	}
	return null;
}

	/* ClipboardExtendedPlugin>>#ioCreateClipboard */
EXPORT(sqInt)
ioCreateClipboard(void)
{
	sqInt clipboardAddress;

	clipboardAddress = (BytesPerWord == 8
		? positive64BitIntegerFor(sqCreateClipboard())
		: positive32BitIntegerFor(sqCreateClipboard()));
	if (!(failed())) {
		methodReturnValue(clipboardAddress);
	}
	return null;
}

	/* ClipboardExtendedPlugin>>#ioGetClipboardFormat:formatNumber: */
EXPORT(sqInt)
ioGetClipboardFormat(void)
{
	sqInt clipboard;
	usqIntptr_t clipboardAddress;
	sqInt formatNumber;
	sqInt itemCount;
	sqInt _return_value;

	if (!(isIntegerObject((formatNumber = stackValue(0))))) {
		primitiveFailFor(PrimErrBadArgument);
		return null;
	}
	clipboard = stackValue(1);
	formatNumber = integerValueOf(formatNumber);
	if (failed()) {
		return null;
	}
	clipboardAddress = positiveMachineIntegerValueOf(clipboard);
	itemCount = sqPasteboardGetItemCount(clipboardAddress);
	if (itemCount > 0) {
		_return_value = sqPasteboardCopyItemFlavorsitemNumber(clipboardAddress, formatNumber);
		if (!(failed())) {
			methodReturnValue(_return_value);
		}
		return null;
	}
	if (!(failed())) {
		methodReturnValue(nilObject());
	}
	return null;
}

	/* ClipboardExtendedPlugin>>#ioReadClipboardData:format: */
EXPORT(sqInt)
ioReadClipboardData(void)
{
	sqInt clipboard;
	usqIntptr_t clipboardAddress;
	char *format;
	sqInt formatLength;
	sqInt _return_value;

	if (!(isBytes(stackValue(0)))) {
		primitiveFailFor(PrimErrBadArgument);
		return null;
	}
	clipboard = stackValue(1);
	format = ((char *) (firstIndexableField(stackValue(0))));
	if (failed()) {
		return null;
	}
	clipboardAddress = positiveMachineIntegerValueOf(clipboard);
	formatLength = slotSizeOf(((sqInt)(sqIntptr_t)(format) - BaseHeaderSize));
	if (!(failed())) {
		_return_value = sqPasteboardCopyItemFlavorDataformatformatLength(clipboardAddress, format, formatLength);
		if (!(failed())) {
			methodReturnValue(_return_value);
		}
	}
	return null;
}


/*	Note: This is coded so that it can be run in Squeak. */

	/* InterpreterPlugin>>#setInterpreter: */
EXPORT(sqInt)
setInterpreter(struct VirtualMachine *anInterpreter)
{
	sqInt ok;


	/* This may seem tautological, but in a real plugin it checks that the VM provides
	   the version the plugin was compiled against which is the version the plugin expects. */
	interpreterProxy = anInterpreter;
	ok = ((interpreterProxy->majorVersion()) == (VM_PROXY_MAJOR))
	 && ((interpreterProxy->minorVersion()) >= (VM_PROXY_MINOR));
	if (ok) {
		
#if !defined(SQUEAK_BUILTIN_PLUGIN)
		failed = interpreterProxy->failed;
		firstIndexableField = interpreterProxy->firstIndexableField;
#if !defined(integerValueOf)
		integerValueOf = interpreterProxy->integerValueOf;
#endif
		isBytes = interpreterProxy->isBytes;
#if !defined(isIntegerObject)
		isIntegerObject = interpreterProxy->isIntegerObject;
#endif
		methodReturnValue = interpreterProxy->methodReturnValue;
		nilObject = interpreterProxy->nilObject;
		pop = interpreterProxy->pop;
		positive32BitIntegerFor = interpreterProxy->positive32BitIntegerFor;
		positive64BitIntegerFor = interpreterProxy->positive64BitIntegerFor;
		positiveMachineIntegerValueOf = interpreterProxy->positiveMachineIntegerValueOf;
		primitiveFailFor = interpreterProxy->primitiveFailFor;
		slotSizeOf = interpreterProxy->slotSizeOf;
		stackValue = interpreterProxy->stackValue;
#endif /* !defined(SQUEAK_BUILTIN_PLUGIN) */
	}
	return ok;
}


#ifdef SQUEAK_BUILTIN_PLUGIN

static char _m[] = "ClipboardExtendedPlugin";
void* ClipboardExtendedPlugin_exports[][3] = {
	{(void*)_m, "getModuleName", (void*)getModuleName},
	{(void*)_m, "ioAddClipboardData\000\000", (void*)ioAddClipboardData},
	{(void*)_m, "ioClearClipboard\000\000", (void*)ioClearClipboard},
	{(void*)_m, "ioCreateClipboard\000\377", (void*)ioCreateClipboard},
	{(void*)_m, "ioGetClipboardFormat\000\000", (void*)ioGetClipboardFormat},
	{(void*)_m, "ioReadClipboardData\000\000", (void*)ioReadClipboardData},
	{(void*)_m, "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};

#else /* ifdef SQ_BUILTIN_PLUGIN */

signed char ioAddClipboardDataAccessorDepth = 0;
signed char ioClearClipboardAccessorDepth = 0;
signed char ioGetClipboardFormatAccessorDepth = 0;
signed char ioReadClipboardDataAccessorDepth = 0;

#endif /* ifdef SQ_BUILTIN_PLUGIN */