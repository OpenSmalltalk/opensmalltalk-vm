/*
 *  dabusinessppcPostLogicInteger.c
 *  IA32ABI
 *
 *  Created by John M McIntosh on 17/12/08.
 *  Copyright 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
 *  MIT License
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
 
 *
 */

/* post call need to refresh stack pointer in case of call-back and GC. */
resultMaybeAlien = interpreterProxy->stackValue(resultOffset);
if (objIsAlien(resultMaybeAlien)) {
	if (!(size = sizeField(resultMaybeAlien)))
		size = sizeof(void *);
	long argByteSize = min(abs(size),8);
	switch (argByteSize) {
		case (1):
			memcpy(startOfDataWithSize(resultMaybeAlien,size), longReturnValueLocation+3, argByteSize);
			break;
		case (2):
			memcpy(startOfDataWithSize(resultMaybeAlien,size), longReturnValueLocation+2, argByteSize);
			break;
		case (3):
			memcpy(startOfDataWithSize(resultMaybeAlien,size), longReturnValueLocation+1, argByteSize);
			break;
		default: 
			memcpy(startOfDataWithSize(resultMaybeAlien,size),longReturnValueLocation,argByteSize);
	}
}

return PrimErrNoErr;

