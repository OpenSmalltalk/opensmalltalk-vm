/* Automatically generated from Squeak on #(19 March 2005 10:09:01 am) */

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

/* memory access macros */
#define byteAt(i) (*((unsigned char *) (i)))
#define byteAtput(i, val) (*((unsigned char *) (i)) = val)
#define longAt(i) (*((int *) (i)))
#define longAtput(i, val) (*((int *) (i)) = val)



/*** Proxy Functions ***/
#define stackValue(i) (interpreterProxy->stackValue(i))
#define stackIntegerValue(i) (interpreterProxy->stackIntegerValue(i))
#define successFlag (!interpreterProxy->failed())
#define success(bool) (interpreterProxy->success(bool))
#define arrayValueOf(oop) (interpreterProxy->arrayValueOf(oop))
#define checkedIntegerValueOf(oop) (interpreterProxy->checkedIntegerValueOf(oop))
#define fetchArrayofObject(idx,oop) (interpreterProxy->fetchArrayofObject(idx,oop))
#define fetchFloatofObject(idx,oop) (interpreterProxy->fetchFloatofObject(idx,oop))
#define fetchIntegerofObject(idx,oop) (interpreterProxy->fetchIntegerofObject(idx,oop))
#define floatValueOf(oop) (interpreterProxy->floatValueOf(oop))
#define pop(n) (interpreterProxy->pop(n))
#define pushInteger(n) (interpreterProxy->pushInteger(n))
#define sizeOfSTArrayFromCPrimitive(cPtr) (interpreterProxy->sizeOfSTArrayFromCPrimitive(cPtr))
#define storeIntegerofObjectwithValue(idx,oop,value) (interpreterProxy->storeIntegerofObjectwithValue(idx,oop,value))
#define primitiveFail() interpreterProxy->primitiveFail()
/* allows accessing Strings in both C and Smalltalk */
#define asciiValue(c) c


/*** Constants ***/

/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"MiscPrimitivePlugin 19 March 2005 (i)"
#else
	"MiscPrimitivePlugin 19 March 2005 (e)"
#endif
;

/*** Function Prototypes ***/
static int encodeBytesOfinat(int anInt, unsigned char *ba, int i);
static int encodeIntinat(int anInt, unsigned char *ba, int i);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static int halt(void);
static int msg(char *s);
#pragma export on
EXPORT(int) primitiveCompareString(void);
EXPORT(int) primitiveCompressToByteArray(void);
EXPORT(int) primitiveConvert8BitSigned(void);
EXPORT(int) primitiveDecompressFromByteArray(void);
EXPORT(int) primitiveFindFirstInString(void);
EXPORT(int) primitiveFindSubstring(void);
EXPORT(int) primitiveIndexOfAsciiInString(void);
EXPORT(int) primitiveStringHash(void);
EXPORT(int) primitiveTranslateStringWithTable(void);
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
#pragma export off


/*	Copy the integer anInt into byteArray ba at index i, and return the next index */

static int encodeBytesOfinat(int anInt, unsigned char *ba, int i) {
    int j;

	for (j = 0; j <= 3; j += 1) {
		ba[i + j] = ((((unsigned) anInt) >> ((3 - j) * 8)) & 255);
	}
	return i + 4;
}


/*	Encode the integer anInt in byteArray ba at index i, and return the next index.
	The encoding is as follows...
		0-223	0-223
		224-254	(0-30)*256 + next byte (0-7935)
		255		next 4 bytes */

static int encodeIntinat(int anInt, unsigned char *ba, int i) {
	if (anInt <= 223) {
		ba[i] = anInt;
		return i + 1;
	}
	if (anInt <= 7935) {
		ba[i] = ((((int) anInt >> 8)) + 224);
		ba[i + 1] = (anInt % 256);
		return i + 2;
	}
	ba[i] = 255;
	return encodeBytesOfinat(anInt, ba, i + 1);
}


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

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}


/*	Return 1, 2 or 3, if string1 is <, =, or > string2, with the collating order of characters given by the order array. */

EXPORT(int) primitiveCompareString(void) {
    int rcvr;
    unsigned char *string1;
    unsigned char *string2;
    unsigned char *order;
    int len2;
    int len1;
    int c2;
    int i;
    int c1;

	rcvr = stackValue(3);
	string1 = arrayValueOf(stackValue(2));
	string1 -= 1;
	string2 = arrayValueOf(stackValue(1));
	string2 -= 1;
	order = arrayValueOf(stackValue(0));
	order -= 1;
	if (!(successFlag)) {
		return null;
	}
	len1 = sizeOfSTArrayFromCPrimitive(string1 + 1);
	len2 = sizeOfSTArrayFromCPrimitive(string2 + 1);
	for (i = 1; i <= (((len1 < len2) ? len1 : len2)); i += 1) {
		c1 = order[(string1[i]) + 1];
		c2 = order[(string2[i]) + 1];
		if (!(c1 == c2)) {
			if (c1 < c2) {
				if (!(successFlag)) {
					return null;
				}
				pop(4);
				pushInteger(1);
				return null;
			} else {
				if (!(successFlag)) {
					return null;
				}
				pop(4);
				pushInteger(3);
				return null;
			}
		}
	}
	if (len1 == len2) {
		if (!(successFlag)) {
			return null;
		}
		pop(4);
		pushInteger(2);
		return null;
	}
	if (len1 < len2) {
		if (!(successFlag)) {
			return null;
		}
		pop(4);
		pushInteger(1);
		return null;
	} else {
		if (!(successFlag)) {
			return null;
		}
		pop(4);
		pushInteger(3);
		return null;
	}
	if (!(successFlag)) {
		return null;
	}
	pop(3);
}


/*	Store a run-coded compression of the receiver into the byteArray ba,
	and return the last index stored into. ba is assumed to be large enough.
	The encoding is as follows...
		S {N D}*.
		S is the size of the original bitmap, followed by run-coded pairs.
		N is a run-length * 4 + data code.
		D, the data, depends on the data code...
			0	skip N words, D is absent
			1	N words with all 4 bytes = D (1 byte)
			2	N words all = D (4 bytes)
			3	N words follow in D (4N bytes)
		S and N are encoded as follows...
			0-223	0-223
			224-254	(0-30)*256 + next byte (0-7935)
			255		next 4 bytes */

EXPORT(int) primitiveCompressToByteArray(void) {
    int rcvr;
    int *bm;
    unsigned char *ba;
    int k;
    int size;
    int word;
    int j;
    int eqBytes;
    int i;
    int lowByte;
    int m;

	rcvr = stackValue(2);
	bm = arrayValueOf(stackValue(1));
	bm -= 1;
	ba = arrayValueOf(stackValue(0));
	ba -= 1;
	if (!(successFlag)) {
		return null;
	}
	size = sizeOfSTArrayFromCPrimitive(bm + 1);
	i = encodeIntinat(size, ba, 1);
	k = 1;
	while (k <= size) {
		word = bm[k];
		lowByte = word & 255;
		eqBytes = (((((unsigned) word) >> 8) & 255) == lowByte) && ((((((unsigned) word) >> 16) & 255) == lowByte) && (((((unsigned) word) >> 24) & 255) == lowByte));
		j = k;
		while ((j < size) && (word == (bm[j + 1]))) {
			j += 1;
		}
		if (j > k) {
			if (eqBytes) {
				i = encodeIntinat((((j - k) + 1) * 4) + 1, ba, i);
				ba[i] = lowByte;
				i += 1;
			} else {
				i = encodeIntinat((((j - k) + 1) * 4) + 2, ba, i);
				i = encodeBytesOfinat(word, ba, i);
			}
			k = j + 1;
		} else {
			if (eqBytes) {
				i = encodeIntinat((1 * 4) + 1, ba, i);
				ba[i] = lowByte;
				i += 1;
				k += 1;
			} else {
				while ((j < size) && ((bm[j]) != (bm[j + 1]))) {
					j += 1;
				}
				if (j == size) {
					j += 1;
				}
				i = encodeIntinat(((j - k) * 4) + 3, ba, i);
				for (m = k; m <= (j - 1); m += 1) {
					i = encodeBytesOfinat(bm[m], ba, i);
				}
				k = j;
			}
		}
	}
	if (!(successFlag)) {
		return null;
	}
	pop(3);
	pushInteger(i - 1);
	return null;
}


/*	Copy the contents of the given array of signed 8-bit samples into the given array of 16-bit signed samples. */

EXPORT(int) primitiveConvert8BitSigned(void) {
    int rcvr;
    unsigned char *aByteArray;
    unsigned short *aSoundBuffer;
    int i;
    int n;
    int s;

	rcvr = stackValue(2);
	aByteArray = arrayValueOf(stackValue(1));
	aByteArray -= 1;
	aSoundBuffer = arrayValueOf(stackValue(0));
	aSoundBuffer -= 1;
	if (!(successFlag)) {
		return null;
	}
	n = sizeOfSTArrayFromCPrimitive(aByteArray + 1);
	for (i = 1; i <= n; i += 1) {
		s = aByteArray[i];
		if (s > 127) {
			aSoundBuffer[i] = (((unsigned) (s - 256) << 8));
		} else {
			aSoundBuffer[i] = (((unsigned) s << 8));
		}
	}
	if (!(successFlag)) {
		return null;
	}
	pop(2);
}


/*	Decompress the body of a byteArray encoded by compressToByteArray (qv)...
	The format is simply a sequence of run-coded pairs, {N D}*.
		N is a run-length * 4 + data code.
		D, the data, depends on the data code...
			0	skip N words, D is absent
				(could be used to skip from one raster line to the next)
			1	N words with all 4 bytes = D (1 byte)
			2	N words all = D (4 bytes)
			3	N words follow in D (4N bytes)
		S and N are encoded as follows (see decodeIntFrom:)...
			0-223	0-223
			224-254	(0-30)*256 + next byte (0-7935)
			255		next 4 bytes */
/*	NOTE:  If fed with garbage, this routine could read past the end of ba, but it should fail before writing past the ned of bm. */

EXPORT(int) primitiveDecompressFromByteArray(void) {
    int rcvr;
    int *bm;
    unsigned char *ba;
    int index;
    int anInt;
    int pastEnd;
    int code;
    int end;
    int k;
    int j;
    int i;
    int n;
    int m;
    int data;

	rcvr = stackValue(3);
	bm = arrayValueOf(stackValue(2));
	bm -= 1;
	ba = arrayValueOf(stackValue(1));
	ba -= 1;
	index = stackIntegerValue(0);
	if (!(successFlag)) {
		return null;
	}

	/* byteArray read index */

	i = index;
	end = sizeOfSTArrayFromCPrimitive(ba + 1);

	/* bitmap write index */

	k = 1;
	pastEnd = (sizeOfSTArrayFromCPrimitive(bm + 1)) + 1;
	while (i <= end) {
		anInt = ba[i];
		i += 1;
		if (!(anInt <= 223)) {
			if (anInt <= 254) {
				anInt = ((anInt - 224) * 256) + (ba[i]);
				i += 1;
			} else {
				anInt = 0;
				for (j = 1; j <= 4; j += 1) {
					anInt = (((unsigned) anInt << 8)) + (ba[i]);
					i += 1;
				}
			}
		}
		n = ((unsigned) anInt) >> 2;
		if ((k + n) > pastEnd) {
			primitiveFail();
			return null;
		}
		code = anInt & 3;
		if (code == 0) {
			null;
		}
		if (code == 1) {
			data = ba[i];
			i += 1;
			data = data | (((unsigned) data << 8));
			data = data | (((unsigned) data << 16));
			for (j = 1; j <= n; j += 1) {
				bm[k] = data;
				k += 1;
			}
		}
		if (code == 2) {
			data = 0;
			for (j = 1; j <= 4; j += 1) {
				data = (((unsigned) data << 8)) | (ba[i]);
				i += 1;
			}
			for (j = 1; j <= n; j += 1) {
				bm[k] = data;
				k += 1;
			}
		}
		if (code == 3) {
			for (m = 1; m <= n; m += 1) {
				data = 0;
				for (j = 1; j <= 4; j += 1) {
					data = (((unsigned) data << 8)) | (ba[i]);
					i += 1;
				}
				bm[k] = data;
				k += 1;
			}
		}
	}
	if (!(successFlag)) {
		return null;
	}
	pop(3);
}

EXPORT(int) primitiveFindFirstInString(void) {
    int rcvr;
    unsigned char *aString;
    char *inclusionMap;
    int start;
    int i;
    int stringSize;

	rcvr = stackValue(3);
	aString = arrayValueOf(stackValue(2));
	aString -= 1;
	inclusionMap = arrayValueOf(stackValue(1));
	inclusionMap -= 1;
	start = stackIntegerValue(0);
	if (!(successFlag)) {
		return null;
	}
	if ((sizeOfSTArrayFromCPrimitive(inclusionMap + 1)) != 256) {
		if (!(successFlag)) {
			return null;
		}
		pop(4);
		pushInteger(0);
		return null;
	}
	i = start;
	stringSize = sizeOfSTArrayFromCPrimitive(aString + 1);
	while ((i <= stringSize) && ((inclusionMap[(asciiValue(aString[i])) + 1]) == 0)) {
		i += 1;
	}
	if (i > stringSize) {
		if (!(successFlag)) {
			return null;
		}
		pop(4);
		pushInteger(0);
		return null;
	}
	if (!(successFlag)) {
		return null;
	}
	pop(4);
	pushInteger(i);
	return null;
}


/*	Answer the index in the string body at which the substring key first occurs, at or beyond start.  The match is determined using matchTable, which can be used to effect, eg, case-insensitive matches.  If no match is found, zero will be returned.

	The algorithm below is not optimum -- it is intended to be translated to C which will go so fast that it wont matter. */

EXPORT(int) primitiveFindSubstring(void) {
    int rcvr;
    unsigned char *key;
    unsigned char *body;
    int start;
    unsigned char *matchTable;
    int startIndex;
    int index;

	rcvr = stackValue(4);
	key = arrayValueOf(stackValue(3));
	key -= 1;
	body = arrayValueOf(stackValue(2));
	body -= 1;
	start = stackIntegerValue(1);
	matchTable = arrayValueOf(stackValue(0));
	matchTable -= 1;
	if (!(successFlag)) {
		return null;
	}
	if ((sizeOfSTArrayFromCPrimitive(key + 1)) == 0) {
		if (!(successFlag)) {
			return null;
		}
		pop(5);
		pushInteger(0);
		return null;
	}
	for (startIndex = start; startIndex <= (((sizeOfSTArrayFromCPrimitive(body + 1)) - (sizeOfSTArrayFromCPrimitive(key + 1))) + 1); startIndex += 1) {
		index = 1;
		while ((matchTable[(asciiValue(body[(startIndex + index) - 1])) + 1]) == (matchTable[(asciiValue(key[index])) + 1])) {
			if (index == (sizeOfSTArrayFromCPrimitive(key + 1))) {
				if (!(successFlag)) {
					return null;
				}
				pop(5);
				pushInteger(startIndex);
				return null;
			}
			index += 1;
		}
	}
	if (!(successFlag)) {
		return null;
	}
	pop(5);
	pushInteger(0);
	return null;
}

EXPORT(int) primitiveIndexOfAsciiInString(void) {
    int rcvr;
    int anInteger;
    unsigned char *aString;
    int start;
    int pos;
    int stringSize;

	rcvr = stackValue(3);
	anInteger = stackIntegerValue(2);
	aString = arrayValueOf(stackValue(1));
	aString -= 1;
	start = stackIntegerValue(0);
	if (!(successFlag)) {
		return null;
	}
	stringSize = sizeOfSTArrayFromCPrimitive(aString + 1);
	for (pos = start; pos <= stringSize; pos += 1) {
		if ((asciiValue(aString[pos])) == anInteger) {
			if (!(successFlag)) {
				return null;
			}
			pop(4);
			pushInteger(pos);
			return null;
		}
	}
	if (!(successFlag)) {
		return null;
	}
	pop(4);
	pushInteger(0);
	return null;
}


/*	Answer the hash of a byte-indexed collection,
	using speciesHash as the initial value.
	See SmallInteger>>hashMultiply.

	The primitive should be renamed at a
	suitable point in the future */

EXPORT(int) primitiveStringHash(void) {
    int rcvr;
    unsigned char *aByteArray;
    int speciesHash;
    int pos;
    int low;
    int byteArraySize;
    int hash;

	rcvr = stackValue(2);
	aByteArray = arrayValueOf(stackValue(1));
	aByteArray -= 1;
	speciesHash = stackIntegerValue(0);
	if (!(successFlag)) {
		return null;
	}
	byteArraySize = sizeOfSTArrayFromCPrimitive(aByteArray + 1);
	hash = speciesHash & 268435455;
	for (pos = 1; pos <= byteArraySize; pos += 1) {

		/* Begin hashMultiply */

		hash += aByteArray[pos];
		low = hash & 16383;
		hash = ((9741 * low) + ((((9741 * (((unsigned) hash >> 14))) + (101 * low)) & 16383) * 16384)) & 268435455;
	}
	if (!(successFlag)) {
		return null;
	}
	pop(3);
	pushInteger(hash);
	return null;
}


/*	translate the characters in the string by the given table, in place */

EXPORT(int) primitiveTranslateStringWithTable(void) {
    int rcvr;
    unsigned char *aString;
    int start;
    int stop;
    unsigned char *table;
    int i;

	rcvr = stackValue(4);
	aString = arrayValueOf(stackValue(3));
	aString -= 1;
	start = stackIntegerValue(2);
	stop = stackIntegerValue(1);
	table = arrayValueOf(stackValue(0));
	table -= 1;
	if (!(successFlag)) {
		return null;
	}
	for (i = start; i <= stop; i += 1) {
		aString[i] = (table[(asciiValue(aString[i])) + 1]);
	}
	if (!(successFlag)) {
		return null;
	}
	pop(4);
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


#ifdef SQUEAK_BUILTIN_PLUGIN


void* MiscPrimitivePlugin_exports[][3] = {
	{"MiscPrimitivePlugin", "primitiveIndexOfAsciiInString", (void*)primitiveIndexOfAsciiInString},
	{"MiscPrimitivePlugin", "primitiveCompareString", (void*)primitiveCompareString},
	{"MiscPrimitivePlugin", "primitiveStringHash", (void*)primitiveStringHash},
	{"MiscPrimitivePlugin", "primitiveConvert8BitSigned", (void*)primitiveConvert8BitSigned},
	{"MiscPrimitivePlugin", "primitiveFindFirstInString", (void*)primitiveFindFirstInString},
	{"MiscPrimitivePlugin", "primitiveDecompressFromByteArray", (void*)primitiveDecompressFromByteArray},
	{"MiscPrimitivePlugin", "primitiveTranslateStringWithTable", (void*)primitiveTranslateStringWithTable},
	{"MiscPrimitivePlugin", "getModuleName", (void*)getModuleName},
	{"MiscPrimitivePlugin", "primitiveFindSubstring", (void*)primitiveFindSubstring},
	{"MiscPrimitivePlugin", "primitiveCompressToByteArray", (void*)primitiveCompressToByteArray},
	{"MiscPrimitivePlugin", "setInterpreter", (void*)setInterpreter},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

