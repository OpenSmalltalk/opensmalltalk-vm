
//
//  SqueakNoOGLIPhoneAppDelegate.m
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 5/15/08.
/*
Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
Copyright (c) 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
MIT License
Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

The end-user documentation included with the redistribution, if any, must include the following acknowledgment: 
"This product includes software developed by Corporate Smalltalk Consulting Ltd (http://www.smalltalkconsulting.com) 
and its contributors", in the same place and form as other third-party acknowledgments. 
Alternately, this acknowledgment may appear in the software itself, in the same form and location as other 
such third-party acknowledgments.
*/
//
#include "dummyFFI.h"
#include "sqFFI.h"

int ffiPushSignedByte(int value)
{
return 1;
}

int ffiPushUnsignedByte(int value)
{
return 1;
}

int ffiPushSignedShort(int value)
{

return 1;
}

int ffiPushUnsignedShort(int value)
{

return 1;
}

int ffiPushSignedInt(int value)
{

return 1;
}

int ffiPushUnsignedInt(int value)
{

return 1;
}

# define primitiveFail() 0


int ffiPushSignedLongLong(int low, int high)
{
return primitiveFail();
}

int ffiPushUnsignedLongLong(int low, int high)
{
return primitiveFail();
}

int ffiPushSignedChar(int value)
{
return 1;
}

int ffiPushUnsignedChar(int value)
{
return 1;
}

int ffiPushBool(int value)
{
return 1;
}

int ffiPushSingleFloat(double value)
{
return 1;
}

int ffiPushDoubleFloat(double value)
{
return 1;
}

/*  ffiReturnFloatValue:
Return the value from a previous ffi call with float return type. */
double ffiReturnFloatValue(void)
{
return 0;
}

/*  ffiLongLongResultLow:
Return the low 32bit from the 64bit result of a call to an external function */
int ffiLongLongResultLow(void)
{
return 0;
}


/*  ffiLongLongResultHigh:
Return the high 32bit from the 64bit result of a call to an external function */
int ffiLongLongResultHigh(void)
{
return 0;
}

/*  ffiStoreStructure:
Store the structure result of a previous ffi call into the given address*/
int ffiStoreStructure(int address, int structSize)
{
return 1;
}

int ffiCallAddressOfWithPointerReturn(int fn, int callType) 
{
	return 0;
}
int ffiPushStringOfLength(int srcIndex, int length)
{
	return 0;
}
/*  ffiAlloc:
Allocate space from the external heap */
int ffiAlloc(int byteSize)
{
	return 0;
}

/*  ffiFree:
Free space from the external heap */
int ffiFree(sqIntptr_t pointer)
{
return 1;
}

int ffiInitialize(void) {
	return 1;
}

int ffiCallAddressOfWithStructReturn(int fn, int callType, 
int *structSpec, int specSize)
{
	return 0;
}

int ffiCallAddressOfWithReturnType(int fn, int callType, int typeSpec)
{
return 0;
}

int ffiCanReturn(int *structSpec, int specSize) 
{
return 0;
}

/*  ffiCleanup:
 Cleanup after a foreign function call has completed.
 The generic support code only frees the temporarily
 allocated strings. */
int ffiCleanup(void)
{
	return 0;
}

/*  ffiSupportsCallingConvention:
 Return true if the support code supports the given calling convention */
int ffiSupportsCallingConvention(int callType)
{
	return 0;
}

int ffiPushStructureOfLength(int pointer, int* structSpec, int structSize)
{
	return 0;
}
int ffiPushPointer(int pointer)
{
	return 0;
}
