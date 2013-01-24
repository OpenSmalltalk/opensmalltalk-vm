//  A Squeak VM for RiscOS machines
//  Suited to RISC OS > 4, preferably > 5
// See www.squeak.org for much more information
//
// tim Rowledge tim@rowledge.org
//
// License: MIT License -
// Copyright (C) <2013> <tim rowledge>
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
// This is sqRPCSysCall - currently unused
// I would allow Squeak access to SWI calls
#include "oslib/os.h"
#include "oslib/osbyte.h"
#include "oslib/osfscontrol.h"
#include "oslib/wimp.h"
#include "oslib/wimpspriteop.h"
#include "oslib/colourtran.h"
#include "sq.h"
#include <kernel.h>




/* Assorted defines and imports to make the system call code work */
#define NilObject  0
#define FalseObject  1
#define TrueObject  2
#define ClassString  6
#define ClassArray  7
#define ClassLargePositiveInteger  13
#define ClassByteArray  26
extern int successFlag;
extern int nilObj, trueObj, falseObj;
extern int splObj(int index);
int primitiveFail(void);
int fetchClassOf(int oop);
int fixedFieldsOf(int instPointer);
int positive32BitValueOf(int integerPointer);
int positive32BitIntegerFor(int integerValue);
int fetchByteofObject(int byteIndex, int objectPointer);
int isIntegerValue(int valueWord);
int instantiateClassindexableSize(int classPointer, int size);
extern int stackValue(int);

#define longAt(i) (*((int *) (i)))

#define IgnoredType 3
#define SmallIntegerType 1
#define LargePositiveIntegerType 2
#define StringType 4
#define BooleanType 5
#define LowestTypeCode SmallIntegerType
#define HighestTypeCode BooleanType
#define SystemCallInvalidStringError -1
#define SystemCallInvalidArgumentError -2
#define SystemCallInvalidReturnTypeError -3

_kernel_swi_regs outputRegisters;
_kernel_swi_regs inputRegisters;
_kernel_oserror * errp;

int extractSysCallArg(int arg, int i) {
	int ln;
	int argClass;

	if (((arg & 1) == 1)) {
		inputRegisters.r[i] = (arg >>1);
		return true;
	}
	if ((arg == nilObj) || (arg == falseObj)) {
		inputRegisters.r[i] = 0;
		return true;
	}
	if ((arg == trueObj) ) {
		inputRegisters.r[i] = 1;
		return true;
	}
	argClass = fetchClassOf(arg);
	if (argClass == (splObj(ClassLargePositiveInteger))) {
		inputRegisters.r[i] = positive32BitValueOf(arg);
		return true;
	}
	if (argClass == (splObj(ClassString))) {
		ln = lengthOf(arg);
		if ((ln & 3)== 0 ) {
			return SystemCallInvalidStringError;
		}
		inputRegisters.r[i] = (arg + 4 /*BaseHeaderSize*/);
		return true;
	}
	if (argClass == (splObj(ClassByteArray))) {
		inputRegisters.r[i] = (arg + 4 /*BaseHeaderSize*/);
		return true;
	}
	return SystemCallInvalidArgumentError;
}

int extractSysCallRes(int i,  int typecode) {
	int arg, ln, str;

	if (typecode == IgnoredType) {
		return nilObj;
	}
	arg = outputRegisters.r[i];
	if (typecode == SmallIntegerType) {
		if (isIntegerValue(arg)) {
			return (arg << 1) +1;
		}
	}
	if (typecode <= LargePositiveIntegerType) {
		return positive32BitIntegerFor(arg);
	}
	if (typecode == StringType) {
		/* create a string from this arg */
		ln = strlen((char *)arg);
		str = instantiateClassindexableSize(splObj(ClassString), ln);
		strcpy((char *)(str + 4 /*BaseHeaderSize*/ ), (char *)arg );
		return str;
	}
	if (typecode == BooleanType) {
		return (arg == 0)?falseObj:trueObj;
	}
	// maybe we should return an error if we get here?
	return nilObj;
}


int ioSystemCall(int syscall) {
int alen = -1; // initialise to -1 to prevent attempt to extract return types when there are none...
int arg;
int i;
int typeCode;
int res;
int callNum;
int returnTypes;
int fixedIVs;
int classFormat;
int errNum;

	/* make sure that callNum is an integer, and that returnTypes is either nil or an array of acceptable typeCodes */
	callNum = fetchIntegerofObject(0, syscall);
	returnTypes = fetchPointerofObject(3, syscall);
	if (!(successFlag)) {
		return primitiveFail();
	}
	if (!(returnTypes == nilObj)) {
		if ((fetchClassOf(returnTypes)) == (splObj(ClassArray))) {
			if ((alen = lengthOf(returnTypes) -1) > 0) {
				for (i = 0; i <= alen; i += 1) {
					// check the type of each return entry for safety
					typeCode = fetchIntegerofObject(i, returnTypes);
					if (typeCode > HighestTypeCode || typeCode < LowestTypeCode ) {
						storeIntegerofObjectwithValue(2, syscall, SystemCallInvalidReturnTypeError);
						return primitiveFail();
					}
				}
			} else {
				// just in case of weird arrays
				returnTypes = nilObj;
			}
		} else {
			// if it's not nil and not an ok Array, bail out
		storeIntegerofObjectwithValue(2, syscall, SystemCallInvalidReturnTypeError);
			return primitiveFail();
		}
	}

	classFormat = formatOfClass(fetchClassOf(syscall));
	fixedIVs = (((((unsigned) classFormat) >> 11) & 192) + ((((unsigned) classFormat) >> 2) & 63)) - 1 ;
	for (i = 0; i <= 7; i += 1) {
		/* fetch each argument and convert it to C struct */
		arg = fetchPointerofObject(fixedIVs + i, syscall);
		if ( (errNum = extractSysCallArg(arg, i)) <= 0 ) {
			storeIntegerofObjectwithValue(2, syscall, errNum );
			return primitiveFail();
		}
	}
	/* Do the actual swi call */
	errp = _kernel_swi(callNum, &inputRegisters, &outputRegisters);
	if (errp != NULL) {
		/* whoops it failed; return the error number */
		storeIntegerofObjectwithValue(2, syscall, errp->errnum);
		return true ;
	} else {
		/* swicall was ok, set the error number to nil */
		storePointerofObjectwithValue(2, syscall, nilObj);
	}
	for (i = 0; i <= alen; i += 1) {
		/* fetch the answer, translated as the returnTypes array requires */
		typeCode = quickFetchIntegerofObject(i, returnTypes);
		res = extractSysCallRes(i, typeCode);
		storePointerofObjectwithValue(8 + fixedIVs + i, syscall, res);
	}
	return true;
}

int primitiveSystemCall(void) {
    int rx;

	rx = stackValue(0);
	/* begin success: */
	successFlag = (((((unsigned) (longAt(rx))) >> 8) & 15) <= 4) && successFlag;
	if (successFlag) {
		/* begin success: */
		successFlag = (ioSystemCall(rx)) && successFlag;
	}
}


