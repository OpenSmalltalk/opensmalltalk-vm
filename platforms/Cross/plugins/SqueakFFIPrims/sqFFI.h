/****************************************************************************
*   PROJECT: Squeak foreign function interface
*   FILE:    sqFFI.h
*   CONTENT: Declarations for the foreign function interface
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   andreasr@wdi.disney.com
*   RCSID:   $Id$
*
*   NOTES:
*
*****************************************************************************/
#ifndef SQ_FFI_H
#define SQ_FFI_H

#include "sqMemoryAccess.h"

/* What follows is the old FFI API when spread across several marshalling files.
 * With the ThreadedFFIPlugin all marshalling is in a single generated plugin
 * and so the following API is not wanted.
 */
#if !ThreadedFFIPlugin
/* Calling conventions */
#define FFICallTypeCDecl 0
#define FFICallTypeApi 1

/* Atomic types */
#define FFITypeVoid 0
#define FFITypeBool 1
#define FFITypeUnsignedByte 2
#define FFITypeSignedByte 3
#define FFITypeUnsignedShort 4
#define FFITypeSignedShort 5
#define FFITypeUnsignedInt 6
#define FFITypeSignedInt 7
#define FFITypeUnsignedLongLong 8
#define FFITypeSignedLongLong 9
#define FFITypeUnsignedChar 10
#define FFITypeSignedChar 11
#define FFITypeSingleFloat 12
#define FFITypeDoubleFloat 13

/* Shift and mask for atomic types */
#define FFIAtomicTypeShift 24
#define FFIAtomicTypeMask 251658240

/* Type flags */
#define FFIFlagPointer 131072
#define FFIFlagStructure 65536
#define FFIFlagAtomic 262144

/* Size mask */
#define FFIStructSizeMask 65535

/* error constants */
#define FFINoCalloutAvailable -1
#define FFIErrorGenericError 0
#define FFIErrorNotFunction 1
#define FFIErrorBadArgs 2
#define FFIErrorBadArg 3
#define FFIErrorIntAsPointer 4
#define FFIErrorBadAtomicType 5
#define FFIErrorCoercionFailed 6
#define FFIErrorWrongType 7
#define FFIErrorStructSize 8
#define FFIErrorCallType 9
#define FFIErrorBadReturn 10
#define FFIErrorBadAddress 11
#define FFIErrorNoModule 12
#define FFIErrorAddressNotFound 13
#define FFIErrorAttemptToPassVoid 14
#define FFIErrorModuleNotFound 15
#define FFIErrorBadExternalLibrary 16
#define FFIErrorBadExternalFunction 17
#define FFIErrorInvalidPointer 18

/* Announce a coming FFI call */
int ffiInitialize(void);

/* cleanup */
int ffiCleanup(void);

/* Allocate/free external memory */
int ffiAlloc(int byteSize);
int ffiFree(sqIntptr_t ptr);

/* general <=32bit integer loads */
int ffiPushSignedByte(int value);
int ffiPushUnsignedByte(int value);
int ffiPushSignedShort(int value);
int ffiPushUnsignedShort(int value);
int ffiPushSignedInt(int value);
int ffiPushUnsignedInt(int value);
int ffiPushBool(int value);

/* 64bit integer loads */
int ffiPushSignedLongLong(int lowWord, int highWord);
int ffiPushUnsignedLongLong(int lowWord, int highWord);
/* 64bit integer returns */
int ffiLongLongResultLow(void);
int ffiLongLongResultHigh(void);

/* special <=32bit loads */
int ffiPushSignedChar(int value);
int ffiPushUnsignedChar(int value);

/* float loads */
int ffiPushSingleFloat(double value);
int ffiPushDoubleFloat(double value);

/* structure loads */
int ffiPushStructureOfLength(int pointer, int* structSpec, int specSize);

/* pointer loads */
int ffiPushPointer(int pointer);

/* string loads */
int ffiPushStringOfLength(int srcIndex, int length);

/* return true if calling convention is supported */
int ffiSupportsCallingConvention(int callType);

/* return true if these types can be returned */
int ffiCanReturn(int* structSpec, int specSize);

/* call the appropriate function w/ the given return type */
int ffiCallAddressOfWithPointerReturn(int fn, int callType);
int ffiCallAddressOfWithStructReturn(int fn, int callType, 
				     int* structSpec, int specSize);
int ffiCallAddressOfWithReturnType(int fn, int callType, int typeSpec);

/* store the structure result of a previous call */
int ffiStoreStructure(int address, int structSize);

/* return the float value from a previous call */
double ffiReturnFloatValue(void);
#endif /* !ThreadedFFIPlugin */

/* Set the log file name for logging call-outs */
int ffiLogFileNameOfLength(void *nameIndex, int nameLength);
int ffiLogCallOfLength(void *nameIndex, int nameLength);

/* The following are for creating, manipulating, and destroying
 * "manual surfaces".  These are surfaces that are managed by Squeak code,
 * which has manual control over the memory location where the image data is
 * stored (the pointer used may be obtained via FFI calls, or other means).
 *
 * Upon creation, no memory is allocated for the surface.  Squeak code is 
 * responsible for passing in a pointer to the memory to use.  It is OK to set 
 * the pointer to different values, or to NULL.  If the pointer is NULL, then
 * BitBlt calls to ioLockSurface() will fail.
 *
 * createManualFunction() returns a non-negative surface ID if successful, and
 * -1 otherwise.  The other return true for success, and false for failure.
 */   
#include "../SurfacePlugin/SurfacePlugin.h"

void initSurfacePluginFunctionPointers();
void initManualSurfaceFunctionPointers
	(fn_ioRegisterSurface, fn_ioUnregisterSurface, fn_ioFindSurface);
int createManualSurface
	(int width, int height, int rowPitch, int depth, int isMSB);
int destroyManualSurface(int surfaceID);
int setManualSurfacePointer(int surfaceID, void* ptr);

#endif /* SQ_FFI_H */
