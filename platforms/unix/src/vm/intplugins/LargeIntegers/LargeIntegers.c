/* Automatically generated from Squeak on #(19 March 2005 10:08:59 am) */

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


/*** Constants ***/

/*** Function Prototypes ***/
#pragma export on
EXPORT(int) _primDigitBitShift(void);
#pragma export off
static int anyBitOfBytesfromto(int aBytesOop, int start, int stopArg);
static int byteSizeOfBytes(int bytesOop);
static int bytesLshift(int aBytesOop, int shiftCount);
static int bytesRshiftbyteslookfirst(int aBytesOop, int anInteger, int b, int a);
static int bytesgrowTo(int aBytesObject, int newLen);
static int bytesOrIntgrowTo(int oop, int len);
static int cByteOpshortlenlongleninto(int opIndex, unsigned char * pByteShort, int shortLen, unsigned char * pByteLong, int longLen, unsigned char * pByteRes);
static int cBytesCopyFromtolen(unsigned char * pFrom, unsigned char * pTo, int len);
static int cBytesHighBitlen(unsigned char *  pByte, int len);
static int cBytesLshiftfromlentolen(int shiftCount, unsigned char * pFrom, int lenFrom, unsigned char * pTo, int lenTo);
static int cBytesReplacefromtowithstartingAt(unsigned char * pTo, int start, int stop, unsigned char * pFrom, int repStart);
static int cCopyIntValtoBytes(int val, int bytes);
static int cCoreBytesRshiftCountnmfbytesfromlentolen(int count, int n, int m, int f, int b, unsigned char * pFrom, int fromLen, unsigned char * pTo, int toLen);
static int cCoreDigitDivDivlenremlenquolen(unsigned char * pDiv, int divLen, unsigned char * pRem, int remLen, unsigned char * pQuo, int quoLen);
static unsigned char cDigitAddlenwithleninto(unsigned char * pByteShort, int shortLen, unsigned char * pByteLong, int longLen, unsigned char * pByteRes);
static int cDigitComparewithlen(unsigned char * pFirst, unsigned char * pSecond, int len);
static int cDigitLengthOfCSI(int csi);
static unsigned char cDigitMultiplylenwithleninto(unsigned char * pByteShort, int shortLen, unsigned char * pByteLong, int longLen, unsigned char * pByteRes);
static int cDigitOfCSIat(int csi, int ix);
static int cDigitSublenwithleninto(unsigned char * pByteSmall, int smallLen, unsigned char * pByteLarge, int largeLen, unsigned char * pByteRes);
static int cHighBit(int uint);
static int createLargeFromSmallInteger(int anOop);
static int digitAddLargewith(int firstInteger, int secondInteger);
static int digitBitLogicwithopIndex(int firstInteger, int secondInteger, int opIx);
static int digitCompareLargewith(int firstInteger, int secondInteger);
static int digitDivLargewithnegative(int firstInteger, int secondInteger, int neg);
static int digitLength(int oop);
static int digitMultiplyLargewithnegative(int firstInteger, int secondInteger, int neg);
static int digitOfat(int oop, int ix);
static int digitOfBytesat(int aBytesOop, int ix);
static int digitSubLargewith(int firstInteger, int secondInteger);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static int halt(void);
static int highBitOfBytes(int aBytesOop);
static void initialize(void);
static int isNormalized(int anInteger);
static int msg(char *s);
static int negative(int aLarge);
static int normalize(int aLargeInteger);
static int normalizeNegative(int aLargeNegativeInteger);
static int normalizePositive(int aLargePositiveInteger);
#pragma export on
EXPORT(int) primAnyBitFromTo(void);
EXPORT(int) primAsLargeInteger(void);
EXPORT(int) primCheckIfCModuleExists(void);
EXPORT(int) primDigitAdd(void);
EXPORT(int) primDigitAddWith(void);
EXPORT(int) primDigitBitAnd(void);
EXPORT(int) primDigitBitLogicWithOp(void);
EXPORT(int) primDigitBitOr(void);
EXPORT(int) primDigitBitShift(void);
EXPORT(int) primDigitBitShiftMagnitude(void);
EXPORT(int) primDigitBitXor(void);
EXPORT(int) primDigitCompare(void);
EXPORT(int) primDigitCompareWith(void);
EXPORT(int) primDigitDivNegative(void);
EXPORT(int) primDigitDivWithNegative(void);
EXPORT(int) primDigitMultiplyNegative(void);
EXPORT(int) primDigitMultiplyWithNegative(void);
EXPORT(int) primDigitSubtract(void);
EXPORT(int) primDigitSubtractWith(void);
EXPORT(int) primGetModuleName(void);
EXPORT(int) primNormalize(void);
EXPORT(int) primNormalizeNegative(void);
EXPORT(int) primNormalizePositive(void);
EXPORT(int) setInterpreter(struct VirtualMachine* anInterpreter);
#pragma export off
static int sqAssert(int aBool);
static int think(void);
static int unsafeByteOfat(int bytesOop, int ix);
/*** Variables ***/
static const int  andOpIndex = 0;

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"LargeIntegers v1.3 19 March 2005 (i)"
#else
	"LargeIntegers v1.3 19 March 2005 (e)"
#endif
;
static const int  orOpIndex = 1;
static const int  xorOpIndex = 2;


EXPORT(int) _primDigitBitShift(void) {
	int rShift;
	int aLarge;
	int anInteger;
	int shiftCount;
	int _return_value;
	int aLargeInteger;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	anInteger = interpreterProxy->stackValue(1);
	shiftCount = interpreterProxy->stackIntegerValue(0);
	/* missing DebugCode */;
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((anInteger & 1)) {
		aLarge = createLargeFromSmallInteger(anInteger);
	} else {
		aLarge = anInteger;
	}
	if (shiftCount >= 0) {
		_return_value = bytesLshift(aLarge, shiftCount);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, _return_value);
		return null;
	} else {
		rShift = 0 - shiftCount;
		/* begin normalize: */
		aLargeInteger = bytesRshiftbyteslookfirst(aLarge, rShift & 7, ((unsigned) rShift >> 3), interpreterProxy->slotSizeOf(aLarge));
		/* missing DebugCode */;
		if ((interpreterProxy->fetchClassOf(aLargeInteger)) == (interpreterProxy->classLargePositiveInteger())) {
			_return_value = normalizePositive(aLargeInteger);
			goto l1;
		} else {
			_return_value = normalizeNegative(aLargeInteger);
			goto l1;
		}
	l1:	/* end normalize: */;
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(3, _return_value);
		return null;
	}
}


/*	Argument has to be aBytesOop! */
/*	Tests for any magnitude bits in the interval from start to stopArg. */

static int anyBitOfBytesfromto(int aBytesOop, int start, int stopArg) {
	int firstByteIx;
	int rightShift;
	int leftShift;
	int lastByteIx;
	int magnitude;
	int stop;
	int mask;
	int digit;
	int ix;

	/* missing DebugCode */;
	if ((start < 1) || (stopArg < 1)) {
		return interpreterProxy->primitiveFail();
	}
	magnitude = aBytesOop;
	stop = ((stopArg < (cBytesHighBitlen(interpreterProxy->firstIndexableField(magnitude), interpreterProxy->slotSizeOf(magnitude)))) ? stopArg : (cBytesHighBitlen(interpreterProxy->firstIndexableField(magnitude), interpreterProxy->slotSizeOf(magnitude))));
	if (start > stop) {
		return 0;
	}
	firstByteIx = (((int) (start - 1) >> 3)) + 1;
	lastByteIx = (((int) (stop - 1) >> 3)) + 1;
	rightShift = 0 - ((start - 1) % 8);
	leftShift = 7 - ((stop - 1) % 8);
	if (firstByteIx == lastByteIx) {
		mask = ((((0 - rightShift) < 0) ? ((unsigned) 255 >> -(0 - rightShift)) : ((unsigned) 255 << (0 - rightShift)))) & ((((0 - leftShift) < 0) ? ((unsigned) 255 >> -(0 - leftShift)) : ((unsigned) 255 << (0 - leftShift))));
		/* begin digitOfBytes:at: */
		if (firstByteIx > (interpreterProxy->slotSizeOf(magnitude))) {
			digit = 0;
			goto l1;
		} else {
			digit = ((interpreterProxy->stObjectat(magnitude, firstByteIx)) >> 1);
			goto l1;
		}
	l1:	/* end digitOfBytes:at: */;
		return (digit & mask) != 0;
	}
	if ((((rightShift < 0) ? ((unsigned) (digitOfBytesat(magnitude, firstByteIx)) >> -rightShift) : ((unsigned) (digitOfBytesat(magnitude, firstByteIx)) << rightShift))) != 0) {
		return 1;
	}
	for (ix = (firstByteIx + 1); ix <= (lastByteIx - 1); ix += 1) {
		if ((digitOfBytesat(magnitude, ix)) != 0) {
			return 1;
		}
	}
	if (((((leftShift < 0) ? ((unsigned) (digitOfBytesat(magnitude, lastByteIx)) >> -leftShift) : ((unsigned) (digitOfBytesat(magnitude, lastByteIx)) << leftShift))) & 255) != 0) {
		return 1;
	}
	return 0;
}


/*	Precondition: bytesOop is not anInteger and a bytes object. */
/*	Function #byteSizeOf: is used by the interpreter, be careful with name  
	     clashes... */

static int byteSizeOfBytes(int bytesOop) {
	return interpreterProxy->slotSizeOf(bytesOop);
}


/*	Attention: this method invalidates all oop's! Only newBytes is valid at    
	       return. */
/*	Does not normalize. */

static int bytesLshift(int aBytesOop, int shiftCount) {
	int oldLen;
	int highBit;
	int newLen;
	int newBytes;

	oldLen = interpreterProxy->slotSizeOf(aBytesOop);
	if ((highBit = cBytesHighBitlen(interpreterProxy->firstIndexableField(aBytesOop), oldLen)) == 0) {
		return interpreterProxy->integerObjectOf(0);
	}
	newLen = ((int) ((highBit + shiftCount) + 7) >> 3);
	interpreterProxy->pushRemappableOop(aBytesOop);
	newBytes = interpreterProxy->instantiateClassindexableSize(interpreterProxy->fetchClassOf(aBytesOop), newLen);
	aBytesOop = interpreterProxy->popRemappableOop();
	cBytesLshiftfromlentolen(shiftCount, interpreterProxy->firstIndexableField(aBytesOop), oldLen, interpreterProxy->firstIndexableField(newBytes), newLen);
	return newBytes;
}


/*	Attention: this method invalidates all oop's! Only newBytes is valid at    
	  return. */
/*	Shift right 8*b+anInteger bits, 0<=n<8.         
	Discard all digits beyond a, and all zeroes at or below a. */
/*	Does not normalize. */

static int bytesRshiftbyteslookfirst(int aBytesOop, int anInteger, int b, int a) {
	int f;
	int oldLen;
	int n;
	int x;
	int i;
	int newLen;
	int m;
	int digit;
	int newBytes;

	n = 0 - anInteger;
	x = 0;
	f = n + 8;
	i = a;
	m = (((0 - f) < 0) ? ((unsigned) 255 >> -(0 - f)) : ((unsigned) 255 << (0 - f)));
	/* begin digitOfBytes:at: */
	if (i > (interpreterProxy->slotSizeOf(aBytesOop))) {
		digit = 0;
		goto l2;
	} else {
		digit = ((interpreterProxy->stObjectat(aBytesOop, i)) >> 1);
		goto l2;
	}
l2:	/* end digitOfBytes:at: */;
	while ((((((n < 0) ? ((unsigned) digit >> -n) : ((unsigned) digit << n))) | x) == 0) && (i != 1)) {

		/* Can't exceed 8 bits */

		x = ((f < 0) ? ((unsigned) digit >> -f) : ((unsigned) digit << f));
		i -= 1;
		/* begin digitOfBytes:at: */
		if (i > (interpreterProxy->slotSizeOf(aBytesOop))) {
			digit = 0;
			goto l1;
		} else {
			digit = ((interpreterProxy->stObjectat(aBytesOop, i)) >> 1);
			goto l1;
		}
	l1:	/* end digitOfBytes:at: */;
	}
	if (i <= b) {
		return interpreterProxy->instantiateClassindexableSize(interpreterProxy->fetchClassOf(aBytesOop), 0);
	}
	oldLen = interpreterProxy->slotSizeOf(aBytesOop);
	newLen = i - b;
	interpreterProxy->pushRemappableOop(aBytesOop);
	newBytes = interpreterProxy->instantiateClassindexableSize(interpreterProxy->fetchClassOf(aBytesOop), newLen);
	aBytesOop = interpreterProxy->popRemappableOop();
	cCoreBytesRshiftCountnmfbytesfromlentolen(i, n, m, f, b, interpreterProxy->firstIndexableField(aBytesOop), oldLen, interpreterProxy->firstIndexableField(newBytes), newLen);
	return newBytes;
}


/*	Attention: this method invalidates all oop's! Only newBytes is valid at    
	     return. */
/*	Does not normalize. */

static int bytesgrowTo(int aBytesObject, int newLen) {
	int copyLen;
	int oldLen;
	int newBytes;

	interpreterProxy->pushRemappableOop(aBytesObject);
	newBytes = interpreterProxy->instantiateClassindexableSize(interpreterProxy->fetchClassOf(aBytesObject), newLen);
	aBytesObject = interpreterProxy->popRemappableOop();
	oldLen = interpreterProxy->slotSizeOf(aBytesObject);
	if (oldLen < newLen) {
		copyLen = oldLen;
	} else {
		copyLen = newLen;
	}
	cBytesCopyFromtolen(interpreterProxy->firstIndexableField(aBytesObject), interpreterProxy->firstIndexableField(newBytes), copyLen);
	return newBytes;
}


/*	Attention: this method invalidates all oop's! Only newBytes is valid at    
	          return. */

static int bytesOrIntgrowTo(int oop, int len) {
	int val;
	int class;
	int newBytes;

	if ((oop & 1)) {
		val = (oop >> 1);
		if (val < 0) {
			class = interpreterProxy->classLargeNegativeInteger();
		} else {
			class = interpreterProxy->classLargePositiveInteger();
		}
		newBytes = interpreterProxy->instantiateClassindexableSize(class, len);
		cCopyIntValtoBytes(val, newBytes);
	} else {
		newBytes = bytesgrowTo(oop, len);
	}
	return newBytes;
}


/*	pByteRes len = longLen. */

static int cByteOpshortlenlongleninto(int opIndex, unsigned char * pByteShort, int shortLen, unsigned char * pByteLong, int longLen, unsigned char * pByteRes) {
	int limit;
	int i;

	limit = shortLen - 1;
	if (opIndex == andOpIndex) {
		for (i = 0; i <= limit; i += 1) {
			pByteRes[i] = ((pByteShort[i]) & (pByteLong[i]));
		}
		limit = longLen - 1;
		for (i = shortLen; i <= limit; i += 1) {
			pByteRes[i] = 0;
		}
		return 0;
	}
	if (opIndex == orOpIndex) {
		for (i = 0; i <= limit; i += 1) {
			pByteRes[i] = ((pByteShort[i]) | (pByteLong[i]));
		}
		limit = longLen - 1;
		for (i = shortLen; i <= limit; i += 1) {
			pByteRes[i] = (pByteLong[i]);
		}
		return 0;
	}
	if (opIndex == xorOpIndex) {
		for (i = 0; i <= limit; i += 1) {
			pByteRes[i] = ((pByteShort[i]) ^ (pByteLong[i]));
		}
		limit = longLen - 1;
		for (i = shortLen; i <= limit; i += 1) {
			pByteRes[i] = (pByteLong[i]);
		}
		return 0;
	}
	return interpreterProxy->primitiveFail();
}


/*	 */

static int cBytesCopyFromtolen(unsigned char * pFrom, unsigned char * pTo, int len) {
	int limit;
	int i;

	;
	limit = len - 1;
	for (i = 0; i <= limit; i += 1) {
		pTo[i] = (pFrom[i]);
	}
	return 0;
}


/*	Answer the index (in bits) of the high order bit of the receiver, or zero if the    
	 receiver is zero. This method is allowed (and needed) for     
	LargeNegativeIntegers as well, since Squeak's LargeIntegers are     
	sign/magnitude. */

static int cBytesHighBitlen(unsigned char *  pByte, int len) {
	int lastDigit;
	int realLength;

	realLength = len;
	while ((lastDigit = pByte[realLength - 1]) == 0) {
		if ((realLength -= 1) == 0) {
			return 0;
		}
	}
	return (cHighBit(lastDigit)) + (8 * (realLength - 1));
}


/*	C indexed! */

static int cBytesLshiftfromlentolen(int shiftCount, unsigned char * pFrom, int lenFrom, unsigned char * pTo, int lenTo) {
	int limit;
	int lastIx;
	int i;
	int carry;
	int byteShift;
	int rShift;
	int mask;
	int digit;
	int bitShift;

	byteShift = ((int) shiftCount >> 3);
	bitShift = shiftCount % 8;
	if (bitShift == 0) {
		return cBytesReplacefromtowithstartingAt(pTo, byteShift, lenTo - 1, pFrom, 0);
	}
	carry = 0;
	rShift = bitShift - 8;
	mask = (((0 - bitShift) < 0) ? ((unsigned) 255 >> -(0 - bitShift)) : ((unsigned) 255 << (0 - bitShift)));
	limit = byteShift - 1;
	for (i = 0; i <= limit; i += 1) {
		pTo[i] = 0;
	}
	limit = (lenTo - byteShift) - 2;
	/* begin sqAssert: */
	/* missing DebugCode */;
l1:	/* end sqAssert: */;
	for (i = 0; i <= limit; i += 1) {
		digit = pFrom[i];
		pTo[i + byteShift] = ((((bitShift < 0) ? ((unsigned) (digit & mask) >> -bitShift) : ((unsigned) (digit & mask) << bitShift))) | carry);
		carry = ((rShift < 0) ? ((unsigned) digit >> -rShift) : ((unsigned) digit << rShift));
	}
	lastIx = limit + 1;
	if (lastIx > (lenFrom - 1)) {
		digit = 0;
	} else {
		digit = pFrom[lastIx];
	}
	pTo[lastIx + byteShift] = ((((bitShift < 0) ? ((unsigned) (digit & mask) >> -bitShift) : ((unsigned) (digit & mask) << bitShift))) | carry);
	carry = ((rShift < 0) ? ((unsigned) digit >> -rShift) : ((unsigned) digit << rShift));
	/* begin sqAssert: */
	/* missing DebugCode */;
l2:	/* end sqAssert: */;
}


/*	C indexed! */

static int cBytesReplacefromtowithstartingAt(unsigned char * pTo, int start, int stop, unsigned char * pFrom, int repStart) {
	return cBytesCopyFromtolen(pFrom + repStart, pTo + start, (stop - start) + 1);
}

static int cCopyIntValtoBytes(int val, int bytes) {
	unsigned char *  pByte;
	int ix;

	pByte = interpreterProxy->firstIndexableField(bytes);
	for (ix = 1; ix <= (cDigitLengthOfCSI(val)); ix += 1) {
		pByte[ix - 1] = (cDigitOfCSIat(val, ix));
	}
}

static int cCoreBytesRshiftCountnmfbytesfromlentolen(int count, int n, int m, int f, int b, unsigned char * pFrom, int fromLen, unsigned char * pTo, int toLen) {
	int j;
	int x;
	int digit;

	/* begin sqAssert: */
	/* missing DebugCode */;
l1:	/* end sqAssert: */;
	x = ((n < 0) ? ((unsigned) (pFrom[b]) >> -n) : ((unsigned) (pFrom[b]) << n));
	/* begin sqAssert: */
	/* missing DebugCode */;
l2:	/* end sqAssert: */;
	for (j = (b + 1); j <= (count - 1); j += 1) {
		digit = pFrom[j];
		pTo[(j - b) - 1] = ((((f < 0) ? ((unsigned) (digit & m) >> -f) : ((unsigned) (digit & m) << f))) | x);
		x = ((n < 0) ? ((unsigned) digit >> -n) : ((unsigned) digit << n));
	}
	if (count == fromLen) {
		digit = 0;
	} else {
		digit = pFrom[count];
	}
	pTo[(count - b) - 1] = ((((f < 0) ? ((unsigned) (digit & m) >> -f) : ((unsigned) (digit & m) << f))) | x);
}

static int cCoreDigitDivDivlenremlenquolen(unsigned char * pDiv, int divLen, unsigned char * pRem, int remLen, unsigned char * pQuo, int quoLen) {
	int cond;
	int a;
	int k;
	int dnh;
	int i;
	int hi;
	int l;
	int dl;
	int q;
	int r1r2;
	int j;
	int mul;
	int t;
	int ql;
	int lo;
	int dh;
	int r3;


	/* Last actual byte of data (ST ix) */

	dl = divLen - 1;
	ql = quoLen;
	dh = pDiv[dl - 1];
	if (dl == 1) {
		dnh = 0;
	} else {
		dnh = pDiv[dl - 2];
	}
	for (k = 1; k <= ql; k += 1) {

		/* r1 _ rem digitAt: j. */

		j = (remLen + 1) - k;
		if ((pRem[j - 1]) == dh) {
			q = 255;
		} else {
			r1r2 = (((unsigned) (pRem[j - 1]) << 8)) + (pRem[j - 2]);
			t = r1r2 % dh;

			/* Next compute (hi,lo) _ q*dnh */

			q = r1r2 / dh;
			mul = q * dnh;
			hi = ((unsigned) mul >> 8);

			/* Correct overestimate of q.                
				Max of 2 iterations through loop -- see Knuth vol. 2 */

			lo = mul & 255;
			if (j < 3) {
				r3 = 0;
			} else {
				r3 = pRem[j - 3];
			}
					while (1) {
				if ((t < hi) || ((t == hi) && (r3 < lo))) {
					q -= 1;
					lo -= dnh;
					if (lo < 0) {
						hi -= 1;
						lo += 256;
					}
					cond = hi >= dh;
				} else {
					cond = 0;
				}
				if (!(cond)) break;
				hi -= dh;
			}
		}
		l = j - dl;
		a = 0;
		for (i = 1; i <= divLen; i += 1) {
			hi = (pDiv[i - 1]) * (((unsigned) q >> 8));

			/* pRem at: l - 1 put: lo - (lo // 256 * 256). */
			/* sign-tolerant form of (lo bitAnd: 255) -> obsolete... */

			lo = (a + (pRem[l - 1])) - ((pDiv[i - 1]) * (q & 255));
			pRem[l - 1] = (lo & 255);
			a = (((int) lo >> 8)) - hi;
			l += 1;
		}
		if (a < 0) {
			q -= 1;
			l = j - dl;
			a = 0;
			for (i = 1; i <= divLen; i += 1) {
				a = ((((unsigned) a >> 8)) + (pRem[l - 1])) + (pDiv[i - 1]);
				pRem[l - 1] = (a & 255);
				l += 1;
			}
		}
		pQuo[quoLen - k] = q;
	}
}


/*	pByteRes len = longLen; returns over.. */

static unsigned char cDigitAddlenwithleninto(unsigned char * pByteShort, int shortLen, unsigned char * pByteLong, int longLen, unsigned char * pByteRes) {
	int limit;
	int i;
	int accum;

	accum = 0;
	limit = shortLen - 1;
	for (i = 0; i <= limit; i += 1) {
		accum = ((((unsigned) accum >> 8)) + (pByteShort[i])) + (pByteLong[i]);
		pByteRes[i] = (accum & 255);
	}
	limit = longLen - 1;
	for (i = shortLen; i <= limit; i += 1) {
		accum = (((unsigned) accum >> 8)) + (pByteLong[i]);
		pByteRes[i] = (accum & 255);
	}
	return ((unsigned) accum >> 8);
}


/*	Precondition: pFirst len = pSecond len. */

static int cDigitComparewithlen(unsigned char * pFirst, unsigned char * pSecond, int len) {
	int firstDigit;
	int secondDigit;
	int ix;

	ix = len - 1;
	while (ix >= 0) {
		if ((secondDigit = pSecond[ix]) != (firstDigit = pFirst[ix])) {
			if (secondDigit < firstDigit) {
				return 1;
			} else {
				return -1;
			}
		}
		ix -= 1;
	}
	return 0;
}


/*	Answer the number of indexable fields of a CSmallInteger. This value is 
	   the same as the largest legal subscript. */

static int cDigitLengthOfCSI(int csi) {
	if ((csi < 256) && (csi > -256)) {
		return 1;
	}
	if ((csi < 65536) && (csi > -65536)) {
		return 2;
	}
	if ((csi < 16777216) && (csi > -16777216)) {
		return 3;
	}
	return 4;
}


/*	pByteRes len = longLen * shortLen */

static unsigned char cDigitMultiplylenwithleninto(unsigned char * pByteShort, int shortLen, unsigned char * pByteLong, int longLen, unsigned char * pByteRes) {
	int k;
	int limitLong;
	int limitShort;
	int ab;
	int carry;
	int i;
	int j;
	int digit;

	if ((shortLen == 1) && ((pByteShort[0]) == 0)) {
		return 0;
	}
	if ((longLen == 1) && ((pByteLong[0]) == 0)) {
		return 0;
	}
	limitShort = shortLen - 1;
	for (i = 0; i <= limitShort; i += 1) {
		if ((digit = pByteShort[i]) != 0) {
			k = i;

			/* Loop invariant: 0<=carry<=0377, k=i+j-1 (ST) */
			/* -> Loop invariant: 0<=carry<=0377, k=i+j (C) (?) */

			carry = 0;
			limitLong = longLen - 1;
			for (j = 0; j <= limitLong; j += 1) {
				ab = (((pByteLong[j]) * digit) + carry) + (pByteRes[k]);
				carry = ((unsigned) ab >> 8);
				pByteRes[k] = (ab & 255);
				k += 1;
			}
			pByteRes[k] = carry;
		}
	}
	return 0;
}


/*	Answer the value of an indexable field in the receiver.              
	LargePositiveInteger uses bytes of base two number, and each is a       
	      'digit' base 256. */
/*	ST indexed! */

static int cDigitOfCSIat(int csi, int ix) {
	if (ix < 0) {
		interpreterProxy->primitiveFail();
	}
	if (ix > 4) {
		return 0;
	}
	if (csi < 0) {
		;
		return (((((1 - ix) * 8) < 0) ? ((unsigned) (0 - csi) >> -((1 - ix) * 8)) : ((unsigned) (0 - csi) << ((1 - ix) * 8)))) & 255;
	} else {
		return (((((1 - ix) * 8) < 0) ? ((unsigned) csi >> -((1 - ix) * 8)) : ((unsigned) csi << ((1 - ix) * 8)))) & 255;
	}
}

static int cDigitSublenwithleninto(unsigned char * pByteSmall, int smallLen, unsigned char * pByteLarge, int largeLen, unsigned char * pByteRes) {
	int limit;
	int z;
	int i;


	/* Loop invariant is -1<=z<=1 */

	z = 0;
	limit = smallLen - 1;
	for (i = 0; i <= limit; i += 1) {
		z = (z + (pByteLarge[i])) - (pByteSmall[i]);
		pByteRes[i] = (z - ((((int) z >> 8)) * 256));
		z = ((int) z >> 8);
	}
	limit = largeLen - 1;
	for (i = smallLen; i <= limit; i += 1) {
		z += pByteLarge[i];
		pByteRes[i] = (z - ((((int) z >> 8)) * 256));
		z = ((int) z >> 8);
	}
}


/*	Answer the index of the high order bit of the argument, or zero if the  
	argument is zero. */

static int cHighBit(int uint) {
	unsigned int  shifted;
	int bitNo;

	shifted = uint;
	bitNo = 0;
	while (!(shifted < 16)) {
		shifted = ((unsigned) shifted >> 4);
		bitNo += 4;
	}
	while (!(shifted == 0)) {
		shifted = ((unsigned) shifted >> 1);
		bitNo += 1;
	}
	return bitNo;
}


/*	anOop has to be a SmallInteger! */

static int createLargeFromSmallInteger(int anOop) {
	int val;
	int res;
	int size;
	int class;
	unsigned char *  pByte;
	int ix;

	val = (anOop >> 1);
	if (val < 0) {
		class = interpreterProxy->classLargeNegativeInteger();
	} else {
		class = interpreterProxy->classLargePositiveInteger();
	}
	size = cDigitLengthOfCSI(val);
	res = interpreterProxy->instantiateClassindexableSize(class, size);
	pByte = interpreterProxy->firstIndexableField(res);
	for (ix = 1; ix <= size; ix += 1) {
		pByte[ix - 1] = (cDigitOfCSIat(val, ix));
	}
	return res;
}


/*	Does not need to normalize! */

static int digitAddLargewith(int firstInteger, int secondInteger) {
	int newSum;
	int sum;
	int secondLen;
	int longLen;
	int resClass;
	int shortLen;
	int shortInt;
	int longInt;
	unsigned char  over;
	int firstLen;

	firstLen = interpreterProxy->slotSizeOf(firstInteger);
	secondLen = interpreterProxy->slotSizeOf(secondInteger);
	resClass = interpreterProxy->fetchClassOf(firstInteger);
	if (firstLen <= secondLen) {
		shortInt = firstInteger;
		shortLen = firstLen;
		longInt = secondInteger;
		longLen = secondLen;
	} else {
		shortInt = secondInteger;
		shortLen = secondLen;
		longInt = firstInteger;
		longLen = firstLen;
	}
	interpreterProxy->pushRemappableOop(shortInt);
	interpreterProxy->pushRemappableOop(longInt);
	sum = interpreterProxy->instantiateClassindexableSize(resClass, longLen);
	longInt = interpreterProxy->popRemappableOop();
	shortInt = interpreterProxy->popRemappableOop();
	over = cDigitAddlenwithleninto(interpreterProxy->firstIndexableField(shortInt), shortLen, interpreterProxy->firstIndexableField(longInt), longLen, interpreterProxy->firstIndexableField(sum));
	if (over > 0) {
		interpreterProxy->pushRemappableOop(sum);
		newSum = interpreterProxy->instantiateClassindexableSize(resClass, longLen + 1);
		sum = interpreterProxy->popRemappableOop();
		cBytesCopyFromtolen(interpreterProxy->firstIndexableField(sum), interpreterProxy->firstIndexableField(newSum), longLen);

		/* C index! */

		sum = newSum;
		(((unsigned char *) (interpreterProxy->firstIndexableField(sum))))[longLen] = over;
	}
	return sum;
}


/*	Bit logic here is only implemented for positive integers or Zero; if rec 
	or arg is negative, it fails. */

static int digitBitLogicwithopIndex(int firstInteger, int secondInteger, int opIx) {
	int secondLarge;
	int secondLen;
	int longLen;
	int longLarge;
	int firstLarge;
	int shortLen;
	int shortLarge;
	int result;
	int firstLen;

	if ((firstInteger & 1)) {
		if (((firstInteger >> 1)) < 0) {
			return interpreterProxy->primitiveFail();
		}
		interpreterProxy->pushRemappableOop(secondInteger);
		firstLarge = createLargeFromSmallInteger(firstInteger);
		secondInteger = interpreterProxy->popRemappableOop();
	} else {
		if ((interpreterProxy->fetchClassOf(firstInteger)) == (interpreterProxy->classLargeNegativeInteger())) {
			return interpreterProxy->primitiveFail();
		}
		firstLarge = firstInteger;
	}
	if ((secondInteger & 1)) {
		if (((secondInteger >> 1)) < 0) {
			return interpreterProxy->primitiveFail();
		}
		interpreterProxy->pushRemappableOop(firstLarge);
		secondLarge = createLargeFromSmallInteger(secondInteger);
		firstLarge = interpreterProxy->popRemappableOop();
	} else {
		if ((interpreterProxy->fetchClassOf(secondInteger)) == (interpreterProxy->classLargeNegativeInteger())) {
			return interpreterProxy->primitiveFail();
		}
		secondLarge = secondInteger;
	}
	firstLen = interpreterProxy->slotSizeOf(firstLarge);
	secondLen = interpreterProxy->slotSizeOf(secondLarge);
	if (firstLen < secondLen) {
		shortLen = firstLen;
		shortLarge = firstLarge;
		longLen = secondLen;
		longLarge = secondLarge;
	} else {
		shortLen = secondLen;
		shortLarge = secondLarge;
		longLen = firstLen;
		longLarge = firstLarge;
	}
	interpreterProxy->pushRemappableOop(shortLarge);
	interpreterProxy->pushRemappableOop(longLarge);
	result = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classLargePositiveInteger(), longLen);
	longLarge = interpreterProxy->popRemappableOop();
	shortLarge = interpreterProxy->popRemappableOop();
	cByteOpshortlenlongleninto(opIx, interpreterProxy->firstIndexableField(shortLarge), shortLen, interpreterProxy->firstIndexableField(longLarge), longLen, interpreterProxy->firstIndexableField(result));
	if (interpreterProxy->failed()) {
		return 0;
	}
	return normalizePositive(result);
}


/*	Compare the magnitude of firstInteger with that of secondInteger.      
	Return a code of 1, 0, -1 for firstInteger >, = , < secondInteger */

static int digitCompareLargewith(int firstInteger, int secondInteger) {
	int secondLen;
	int firstLen;

	firstLen = interpreterProxy->slotSizeOf(firstInteger);
	secondLen = interpreterProxy->slotSizeOf(secondInteger);
	if (secondLen != firstLen) {
		if (secondLen > firstLen) {
			return interpreterProxy->integerObjectOf(-1);
		} else {
			return interpreterProxy->integerObjectOf(1);
		}
	}
	return interpreterProxy->integerObjectOf((cDigitComparewithlen(interpreterProxy->firstIndexableField(firstInteger), interpreterProxy->firstIndexableField(secondInteger), firstLen)));
}


/*	Does not normalize. */
/*	Division by zero has to be checked in caller. */

static int digitDivLargewithnegative(int firstInteger, int secondInteger, int neg) {
	int l;
	int secondLen;
	int rem;
	int div;
	int d;
	int result;
	int quo;
	int firstLen;
	int resultClass;

	firstLen = interpreterProxy->slotSizeOf(firstInteger);
	secondLen = interpreterProxy->slotSizeOf(secondInteger);
	if (neg) {
		resultClass = interpreterProxy->classLargeNegativeInteger();
	} else {
		resultClass = interpreterProxy->classLargePositiveInteger();
	}
	l = (firstLen - secondLen) + 1;
	if (l <= 0) {
		interpreterProxy->pushRemappableOop(firstInteger);
		result = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 2);
		firstInteger = interpreterProxy->popRemappableOop();
		interpreterProxy->stObjectatput(result,1,(interpreterProxy->integerObjectOf(0)));
		interpreterProxy->stObjectatput(result,2,firstInteger);
		return result;
	}
	d = 8 - (cHighBit(((interpreterProxy->stObjectat(secondInteger, secondLen)) >> 1)));
	interpreterProxy->pushRemappableOop(firstInteger);
	div = bytesLshift(secondInteger, d);
	div = bytesOrIntgrowTo(div, (digitLength(div)) + 1);
	firstInteger = interpreterProxy->popRemappableOop();
	interpreterProxy->pushRemappableOop(div);
	rem = bytesLshift(firstInteger, d);
	if ((digitLength(rem)) == firstLen) {
		rem = bytesOrIntgrowTo(rem, firstLen + 1);
	}
	div = interpreterProxy->popRemappableOop();
	interpreterProxy->pushRemappableOop(div);
	interpreterProxy->pushRemappableOop(rem);
	quo = interpreterProxy->instantiateClassindexableSize(resultClass, l);
	rem = interpreterProxy->popRemappableOop();
	div = interpreterProxy->popRemappableOop();
	cCoreDigitDivDivlenremlenquolen(interpreterProxy->firstIndexableField(div), digitLength(div), interpreterProxy->firstIndexableField(rem), digitLength(rem), interpreterProxy->firstIndexableField(quo), digitLength(quo));
	interpreterProxy->pushRemappableOop(quo);
	rem = bytesRshiftbyteslookfirst(rem, d, 0, (digitLength(div)) - 1);
	quo = interpreterProxy->popRemappableOop();
	interpreterProxy->pushRemappableOop(quo);
	interpreterProxy->pushRemappableOop(rem);
	result = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classArray(), 2);
	rem = interpreterProxy->popRemappableOop();
	quo = interpreterProxy->popRemappableOop();
	interpreterProxy->stObjectatput(result,1,quo);
	interpreterProxy->stObjectatput(result,2,rem);
	return result;
}

static int digitLength(int oop) {
	if ((oop & 1)) {
		return cDigitLengthOfCSI((oop >> 1));
	} else {
		return interpreterProxy->slotSizeOf(oop);
	}
}


/*	Normalizes. */

static int digitMultiplyLargewithnegative(int firstInteger, int secondInteger, int neg) {
	int secondLen;
	int longLen;
	int shortLen;
	int shortInt;
	int prod;
	int longInt;
	int firstLen;
	int resultClass;

	firstLen = interpreterProxy->slotSizeOf(firstInteger);
	secondLen = interpreterProxy->slotSizeOf(secondInteger);
	if (firstLen <= secondLen) {
		shortInt = firstInteger;
		shortLen = firstLen;
		longInt = secondInteger;
		longLen = secondLen;
	} else {
		shortInt = secondInteger;
		shortLen = secondLen;
		longInt = firstInteger;
		longLen = firstLen;
	}
	if (neg) {
		resultClass = interpreterProxy->classLargeNegativeInteger();
	} else {
		resultClass = interpreterProxy->classLargePositiveInteger();
	}
	interpreterProxy->pushRemappableOop(shortInt);
	interpreterProxy->pushRemappableOop(longInt);
	prod = interpreterProxy->instantiateClassindexableSize(resultClass, longLen + shortLen);
	longInt = interpreterProxy->popRemappableOop();
	shortInt = interpreterProxy->popRemappableOop();
	cDigitMultiplylenwithleninto(interpreterProxy->firstIndexableField(shortInt), shortLen, interpreterProxy->firstIndexableField(longInt), longLen, interpreterProxy->firstIndexableField(prod));
	/* begin normalize: */
	/* missing DebugCode */;
	if ((interpreterProxy->fetchClassOf(prod)) == (interpreterProxy->classLargePositiveInteger())) {
		return normalizePositive(prod);
	} else {
		return normalizeNegative(prod);
	}
	return null;
}

static int digitOfat(int oop, int ix) {
	if ((oop & 1)) {
		return cDigitOfCSIat((oop >> 1), ix);
	} else {
		/* begin digitOfBytes:at: */
		if (ix > (interpreterProxy->slotSizeOf(oop))) {
			return 0;
		} else {
			return ((interpreterProxy->stObjectat(oop, ix)) >> 1);
		}
		return null;
	}
}


/*	Argument has to be aLargeInteger! */

static int digitOfBytesat(int aBytesOop, int ix) {
	if (ix > (interpreterProxy->slotSizeOf(aBytesOop))) {
		return 0;
	} else {
		return ((interpreterProxy->stObjectat(aBytesOop, ix)) >> 1);
	}
}


/*	Normalizes. */

static int digitSubLargewith(int firstInteger, int secondInteger) {
	int res;
	int secondLen;
	int smaller;
	int resLen;
	int firstNeg;
	int smallerLen;
	int largerLen;
	int class;
	int larger;
	int neg;
	int firstLen;

	firstNeg = (interpreterProxy->fetchClassOf(firstInteger)) == (interpreterProxy->classLargeNegativeInteger());
	firstLen = interpreterProxy->slotSizeOf(firstInteger);
	secondLen = interpreterProxy->slotSizeOf(secondInteger);
	if (firstLen == secondLen) {
		while (((digitOfBytesat(firstInteger, firstLen)) == (digitOfBytesat(secondInteger, firstLen))) && (firstLen > 1)) {
			firstLen -= 1;
		}
		secondLen = firstLen;
	}
	if ((firstLen < secondLen) || ((firstLen == secondLen) && ((digitOfBytesat(firstInteger, firstLen)) < (digitOfBytesat(secondInteger, firstLen))))) {
		larger = secondInteger;
		largerLen = secondLen;
		smaller = firstInteger;
		smallerLen = firstLen;
		neg = firstNeg == 0;
	} else {
		larger = firstInteger;
		largerLen = firstLen;
		smaller = secondInteger;
		smallerLen = secondLen;
		neg = firstNeg;
	}
	resLen = largerLen;
	if (neg) {
		class = interpreterProxy->classLargeNegativeInteger();
	} else {
		class = interpreterProxy->classLargePositiveInteger();
	}
	interpreterProxy->pushRemappableOop(smaller);
	interpreterProxy->pushRemappableOop(larger);
	res = interpreterProxy->instantiateClassindexableSize(class, resLen);
	larger = interpreterProxy->popRemappableOop();
	smaller = interpreterProxy->popRemappableOop();
	cDigitSublenwithleninto(interpreterProxy->firstIndexableField(smaller), smallerLen, interpreterProxy->firstIndexableField(larger), largerLen, interpreterProxy->firstIndexableField(res));
	/* begin normalize: */
	/* missing DebugCode */;
	if ((interpreterProxy->fetchClassOf(res)) == (interpreterProxy->classLargePositiveInteger())) {
		return normalizePositive(res);
	} else {
		return normalizeNegative(res);
	}
	return null;
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

static int highBitOfBytes(int aBytesOop) {
	return cBytesHighBitlen(interpreterProxy->firstIndexableField(aBytesOop), interpreterProxy->slotSizeOf(aBytesOop));
}


/*	Initializes ST constants; C's are set by class>>declareCVarsIn:. */

static void initialize(void) {
	"nothing to do here";
}

static int isNormalized(int anInteger) {
	int sLen;
	int minVal;
	int maxVal;
	int len;
	int ix;

	if ((anInteger & 1)) {
		return 1;
	}
	/* begin digitLength: */
	if ((anInteger & 1)) {
		len = cDigitLengthOfCSI((anInteger >> 1));
		goto l1;
	} else {
		len = interpreterProxy->slotSizeOf(anInteger);
		goto l1;
	}
l1:	/* end digitLength: */;
	if (len == 0) {
		return 0;
	}
	if ((((interpreterProxy->stObjectat(anInteger, len)) >> 1)) == 0) {
		return 0;
	}

	/* maximal digitLength of aSmallInteger */

	sLen = 4;
	if (len > sLen) {
		return 1;
	}
	if (len < sLen) {
		return 0;
	}
	if ((interpreterProxy->fetchClassOf(anInteger)) == (interpreterProxy->classLargePositiveInteger())) {

		/* SmallInteger maxVal */
		/* all bytes of maxVal but the highest one are just FF's */

		maxVal = 1073741823;
		return (((interpreterProxy->stObjectat(anInteger, sLen)) >> 1)) > (cDigitOfCSIat(maxVal, sLen));
	} else {

		/* SmallInteger minVal */
		/* all bytes of minVal but the highest one are just 00's */

		minVal = -1073741824;
		if ((((interpreterProxy->stObjectat(anInteger, sLen)) >> 1)) < (cDigitOfCSIat(minVal, sLen))) {
			return 0;
		} else {
			for (ix = 1; ix <= sLen; ix += 1) {
				if (!((((interpreterProxy->stObjectat(anInteger, ix)) >> 1)) == (cDigitOfCSIat(minVal, ix)))) {
					return 1;
				}
			}
		}
	}
	return 0;
}

static int msg(char *s) {
	fprintf(stderr, "\n%s: %s", moduleName, s);
}

static int negative(int aLarge) {
	return (interpreterProxy->fetchClassOf(aLarge)) == (interpreterProxy->classLargeNegativeInteger());
}


/*	Check for leading zeroes and return shortened copy if so. */

static int normalize(int aLargeInteger) {
	/* missing DebugCode */;
	if ((interpreterProxy->fetchClassOf(aLargeInteger)) == (interpreterProxy->classLargePositiveInteger())) {
		return normalizePositive(aLargeInteger);
	} else {
		return normalizeNegative(aLargeInteger);
	}
}


/*	Check for leading zeroes and return shortened copy if so */
/*	First establish len = significant length */

static int normalizeNegative(int aLargeNegativeInteger) {
	int val;
	int sLen;
	int oldLen;
	int minVal;
	int len;
	int i;

	len = oldLen = digitLength(aLargeNegativeInteger);
	while ((len != 0) && ((((interpreterProxy->stObjectat(aLargeNegativeInteger, len)) >> 1)) == 0)) {
		len -= 1;
	}
	if (len == 0) {
		return interpreterProxy->integerObjectOf(0);
	}

	/* SmallInteger minVal digitLength */

	sLen = 4;
	if (len <= sLen) {
		minVal = -1073741824;
		if ((len < sLen) || ((digitOfBytesat(aLargeNegativeInteger, sLen)) < (cDigitOfCSIat(minVal, sLen)))) {
			val = 0;
			for (i = len; i >= 1; i += -1) {
				val = (val * 256) - (((interpreterProxy->stObjectat(aLargeNegativeInteger, i)) >> 1));
			}
			return interpreterProxy->integerObjectOf(val);
		}
		for (i = 1; i <= sLen; i += 1) {
			if (!((digitOfBytesat(aLargeNegativeInteger, i)) == (cDigitOfCSIat(minVal, i)))) {
				if (len < oldLen) {
					return bytesgrowTo(aLargeNegativeInteger, len);
				} else {
					return aLargeNegativeInteger;
				}
			}
		}
		return interpreterProxy->integerObjectOf(minVal);
	}
	if (len < oldLen) {
		return bytesgrowTo(aLargeNegativeInteger, len);
	} else {
		return aLargeNegativeInteger;
	}
}


/*	Check for leading zeroes and return shortened copy if so */
/*	First establish len = significant length */

static int normalizePositive(int aLargePositiveInteger) {
	int val;
	int sLen;
	int oldLen;
	int len;
	int i;

	len = oldLen = digitLength(aLargePositiveInteger);
	while ((len != 0) && ((((interpreterProxy->stObjectat(aLargePositiveInteger, len)) >> 1)) == 0)) {
		len -= 1;
	}
	if (len == 0) {
		return interpreterProxy->integerObjectOf(0);
	}

	/* SmallInteger maxVal digitLength. */

	sLen = 4;
	if ((len <= sLen) && ((digitOfBytesat(aLargePositiveInteger, sLen)) <= (cDigitOfCSIat(1073741823, sLen)))) {
		val = 0;
		for (i = len; i >= 1; i += -1) {
			val = (val * 256) + (((interpreterProxy->stObjectat(aLargePositiveInteger, i)) >> 1));
		}
		return interpreterProxy->integerObjectOf(val);
	}
	if (len < oldLen) {
		return bytesgrowTo(aLargePositiveInteger, len);
	} else {
		return aLargePositiveInteger;
	}
}

EXPORT(int) primAnyBitFromTo(void) {
	int integer;
	int large;
	int from;
	int to;
	int _return_value;

	from = interpreterProxy->stackIntegerValue(1);
	to = interpreterProxy->stackIntegerValue(0);
	/* missing DebugCode */;
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(2), "Integer"));
	integer = interpreterProxy->stackValue(2);
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((integer & 1)) {
		large = createLargeFromSmallInteger(integer);
	} else {
		large = integer;
	}
	_return_value = ((anyBitOfBytesfromto(large, from, to))? interpreterProxy->trueObject(): interpreterProxy->falseObject());
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}


/*	Converts a SmallInteger into a - non normalized! - LargeInteger;          
	 aLargeInteger will be returned unchanged. */
/*	Do not check for forced fail, because we need this conversion to test the 
	plugin in ST during forced fail, too. */

EXPORT(int) primAsLargeInteger(void) {
	int anInteger;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Integer"));
	anInteger = interpreterProxy->stackValue(0);
	/* missing DebugCode */;
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((anInteger & 1)) {
		_return_value = createLargeFromSmallInteger(anInteger);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(2, _return_value);
		return null;
	} else {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(2, anInteger);
		return null;
	}
}


/*	If calling this primitive fails, then C module does not exist. Do not check for forced fail, because we want to know if module exists during forced fail, too. */

EXPORT(int) primCheckIfCModuleExists(void) {
	int _return_value;

	_return_value = (1? interpreterProxy->trueObject(): interpreterProxy->falseObject());
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
}


/*	 */

EXPORT(int) primDigitAdd(void) {
	int secondLarge;
	int firstLarge;
	int firstInteger;
	int secondInteger;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Integer"));
	secondInteger = interpreterProxy->stackValue(0);
	/* missing DebugCode */;
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	firstInteger = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((firstInteger & 1)) {
		interpreterProxy->pushRemappableOop(secondInteger);
		firstLarge = createLargeFromSmallInteger(firstInteger);
		secondInteger = interpreterProxy->popRemappableOop();
	} else {
		firstLarge = firstInteger;
	}
	if ((secondInteger & 1)) {
		interpreterProxy->pushRemappableOop(firstLarge);
		secondLarge = createLargeFromSmallInteger(secondInteger);
		firstLarge = interpreterProxy->popRemappableOop();
	} else {
		secondLarge = secondInteger;
	}
	_return_value = digitAddLargewith(firstLarge, secondLarge);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}


/*	 */

EXPORT(int) primDigitAddWith(void) {
	int secondLarge;
	int firstLarge;
	int firstInteger;
	int secondInteger;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	firstInteger = interpreterProxy->stackValue(1);
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Integer"));
	secondInteger = interpreterProxy->stackValue(0);
	/* missing DebugCode */;
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((firstInteger & 1)) {
		interpreterProxy->pushRemappableOop(secondInteger);
		firstLarge = createLargeFromSmallInteger(firstInteger);
		secondInteger = interpreterProxy->popRemappableOop();
	} else {
		firstLarge = firstInteger;
	}
	if ((secondInteger & 1)) {
		interpreterProxy->pushRemappableOop(firstLarge);
		secondLarge = createLargeFromSmallInteger(secondInteger);
		firstLarge = interpreterProxy->popRemappableOop();
	} else {
		secondLarge = secondInteger;
	}
	_return_value = digitAddLargewith(firstLarge, secondLarge);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}


/*	Bit logic here is only implemented for positive integers or Zero; if rec 
	or arg is negative, it fails. */

EXPORT(int) primDigitBitAnd(void) {
	int firstInteger;
	int secondInteger;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Integer"));
	secondInteger = interpreterProxy->stackValue(0);
	/* missing DebugCode */;
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	firstInteger = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	_return_value = digitBitLogicwithopIndex(firstInteger, secondInteger, andOpIndex);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}


/*	Bit logic here is only implemented for positive integers or Zero; if any arg is negative, it fails. */

EXPORT(int) primDigitBitLogicWithOp(void) {
	int firstInteger;
	int secondInteger;
	int opIndex;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(2), "Integer"));
	firstInteger = interpreterProxy->stackValue(2);
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	secondInteger = interpreterProxy->stackValue(1);
	opIndex = interpreterProxy->stackIntegerValue(0);
	/* missing DebugCode */;
	if (interpreterProxy->failed()) {
		return null;
	}
	_return_value = digitBitLogicwithopIndex(firstInteger, secondInteger, opIndex);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}


/*	Bit logic here is only implemented for positive integers or Zero; if rec 
	or arg is negative, it fails. */

EXPORT(int) primDigitBitOr(void) {
	int firstInteger;
	int secondInteger;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Integer"));
	secondInteger = interpreterProxy->stackValue(0);
	/* missing DebugCode */;
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	firstInteger = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	_return_value = digitBitLogicwithopIndex(firstInteger, secondInteger, orOpIndex);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primDigitBitShift(void) {
	int anInteger;
	int rShift;
	int aLarge;
	int shiftCount;
	int _return_value;
	int aLargeInteger;

	shiftCount = interpreterProxy->stackIntegerValue(0);
	/* missing DebugCode */;
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	anInteger = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((anInteger & 1)) {
		aLarge = createLargeFromSmallInteger(anInteger);
	} else {
		aLarge = anInteger;
	}
	if (shiftCount >= 0) {
		_return_value = bytesLshift(aLarge, shiftCount);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(2, _return_value);
		return null;
	} else {
		rShift = 0 - shiftCount;
		/* begin normalize: */
		aLargeInteger = bytesRshiftbyteslookfirst(aLarge, rShift & 7, ((unsigned) rShift >> 3), interpreterProxy->slotSizeOf(aLarge));
		/* missing DebugCode */;
		if ((interpreterProxy->fetchClassOf(aLargeInteger)) == (interpreterProxy->classLargePositiveInteger())) {
			_return_value = normalizePositive(aLargeInteger);
			goto l1;
		} else {
			_return_value = normalizeNegative(aLargeInteger);
			goto l1;
		}
	l1:	/* end normalize: */;
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(2, _return_value);
		return null;
	}
}

EXPORT(int) primDigitBitShiftMagnitude(void) {
	int anInteger;
	int rShift;
	int aLarge;
	int shiftCount;
	int _return_value;
	int aLargeInteger;

	shiftCount = interpreterProxy->stackIntegerValue(0);
	/* missing DebugCode */;
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	anInteger = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((anInteger & 1)) {
		aLarge = createLargeFromSmallInteger(anInteger);
	} else {
		aLarge = anInteger;
	}
	if (shiftCount >= 0) {
		_return_value = bytesLshift(aLarge, shiftCount);
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(2, _return_value);
		return null;
	} else {
		rShift = 0 - shiftCount;
		/* begin normalize: */
		aLargeInteger = bytesRshiftbyteslookfirst(aLarge, rShift & 7, ((unsigned) rShift >> 3), interpreterProxy->slotSizeOf(aLarge));
		/* missing DebugCode */;
		if ((interpreterProxy->fetchClassOf(aLargeInteger)) == (interpreterProxy->classLargePositiveInteger())) {
			_return_value = normalizePositive(aLargeInteger);
			goto l1;
		} else {
			_return_value = normalizeNegative(aLargeInteger);
			goto l1;
		}
	l1:	/* end normalize: */;
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(2, _return_value);
		return null;
	}
}


/*	Bit logic here is only implemented for positive integers or Zero; if rec 
	or arg is negative, it fails. */

EXPORT(int) primDigitBitXor(void) {
	int firstInteger;
	int secondInteger;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Integer"));
	secondInteger = interpreterProxy->stackValue(0);
	/* missing DebugCode */;
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	firstInteger = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	_return_value = digitBitLogicwithopIndex(firstInteger, secondInteger, xorOpIndex);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}

EXPORT(int) primDigitCompare(void) {
	int firstVal;
	int firstInteger;
	int secondVal;
	int secondInteger;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Integer"));
	secondInteger = interpreterProxy->stackValue(0);
	/* missing DebugCode */;
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	firstInteger = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((firstInteger & 1)) {
		if ((secondInteger & 1)) {
			if ((firstVal = (firstInteger >> 1)) > (secondVal = (secondInteger >> 1))) {
				_return_value = interpreterProxy->integerObjectOf(1);
				if (interpreterProxy->failed()) {
					return null;
				}
				interpreterProxy->popthenPush(2, _return_value);
				return null;
			} else {
				if (firstVal < secondVal) {
					_return_value = interpreterProxy->integerObjectOf(-1);
					if (interpreterProxy->failed()) {
						return null;
					}
					interpreterProxy->popthenPush(2, _return_value);
					return null;
				} else {
					_return_value = interpreterProxy->integerObjectOf(0);
					if (interpreterProxy->failed()) {
						return null;
					}
					interpreterProxy->popthenPush(2, _return_value);
					return null;
				}
			}
		} else {
			_return_value = interpreterProxy->integerObjectOf(-1);
			if (interpreterProxy->failed()) {
				return null;
			}
			interpreterProxy->popthenPush(2, _return_value);
			return null;
		}
	} else {
		if ((secondInteger & 1)) {
			_return_value = interpreterProxy->integerObjectOf(1);
			if (interpreterProxy->failed()) {
				return null;
			}
			interpreterProxy->popthenPush(2, _return_value);
			return null;
		} else {
			_return_value = digitCompareLargewith(firstInteger, secondInteger);
			if (interpreterProxy->failed()) {
				return null;
			}
			interpreterProxy->popthenPush(2, _return_value);
			return null;
		}
	}
}

EXPORT(int) primDigitCompareWith(void) {
	int firstVal;
	int secondVal;
	int firstInteger;
	int secondInteger;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	firstInteger = interpreterProxy->stackValue(1);
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Integer"));
	secondInteger = interpreterProxy->stackValue(0);
	/* missing DebugCode */;
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((firstInteger & 1)) {
		if ((secondInteger & 1)) {
			if ((firstVal = (firstInteger >> 1)) > (secondVal = (secondInteger >> 1))) {
				_return_value = interpreterProxy->integerObjectOf(1);
				if (interpreterProxy->failed()) {
					return null;
				}
				interpreterProxy->popthenPush(3, _return_value);
				return null;
			} else {
				if (firstVal < secondVal) {
					_return_value = interpreterProxy->integerObjectOf(-1);
					if (interpreterProxy->failed()) {
						return null;
					}
					interpreterProxy->popthenPush(3, _return_value);
					return null;
				} else {
					_return_value = interpreterProxy->integerObjectOf(0);
					if (interpreterProxy->failed()) {
						return null;
					}
					interpreterProxy->popthenPush(3, _return_value);
					return null;
				}
			}
		} else {
			_return_value = interpreterProxy->integerObjectOf(-1);
			if (interpreterProxy->failed()) {
				return null;
			}
			interpreterProxy->popthenPush(3, _return_value);
			return null;
		}
	} else {
		if ((secondInteger & 1)) {
			_return_value = interpreterProxy->integerObjectOf(1);
			if (interpreterProxy->failed()) {
				return null;
			}
			interpreterProxy->popthenPush(3, _return_value);
			return null;
		} else {
			_return_value = digitCompareLargewith(firstInteger, secondInteger);
			if (interpreterProxy->failed()) {
				return null;
			}
			interpreterProxy->popthenPush(3, _return_value);
			return null;
		}
	}
}


/*	Answer the result of dividing firstInteger by secondInteger.
	Fail if parameters are not integers, not normalized or secondInteger is zero. */

EXPORT(int) primDigitDivNegative(void) {
	int firstInteger;
	int secondAsLargeInteger;
	int firstAsLargeInteger;
	int secondInteger;
	int neg;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	secondInteger = interpreterProxy->stackValue(1);
	neg = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	/* missing DebugCode */;
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(2), "Integer"));
	firstInteger = interpreterProxy->stackValue(2);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(isNormalized(firstInteger))) {
		/* missing DebugCode */;
		interpreterProxy->primitiveFail();
		return null;
	}
	if (!(isNormalized(secondInteger))) {
		/* missing DebugCode */;
		interpreterProxy->primitiveFail();
		return null;
	}
	if ((firstInteger & 1)) {
		interpreterProxy->pushRemappableOop(secondInteger);
		firstAsLargeInteger = createLargeFromSmallInteger(firstInteger);
		secondInteger = interpreterProxy->popRemappableOop();
	} else {
		firstAsLargeInteger = firstInteger;
	}
	if ((secondInteger & 1)) {
		if (((secondInteger >> 1)) == 0) {
			interpreterProxy->primitiveFail();
			return null;
		}
		interpreterProxy->pushRemappableOop(firstAsLargeInteger);
		secondAsLargeInteger = createLargeFromSmallInteger(secondInteger);
		firstAsLargeInteger = interpreterProxy->popRemappableOop();
	} else {
		secondAsLargeInteger = secondInteger;
	}
	_return_value = digitDivLargewithnegative(firstAsLargeInteger, secondAsLargeInteger, neg);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}


/*	Answer the result of dividing firstInteger by secondInteger.  Fail if     
	parameters are not integers or secondInteger is zero. */

EXPORT(int) primDigitDivWithNegative(void) {
	int secondAsLargeInteger;
	int firstAsLargeInteger;
	int firstInteger;
	int secondInteger;
	int neg;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(2), "Integer"));
	firstInteger = interpreterProxy->stackValue(2);
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	secondInteger = interpreterProxy->stackValue(1);
	neg = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	/* missing DebugCode */;
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((firstInteger & 1)) {
		interpreterProxy->pushRemappableOop(secondInteger);
		firstAsLargeInteger = createLargeFromSmallInteger(firstInteger);
		secondInteger = interpreterProxy->popRemappableOop();
	} else {
		firstAsLargeInteger = firstInteger;
	}
	if ((secondInteger & 1)) {
		if (((secondInteger >> 1)) == 0) {
			interpreterProxy->primitiveFail();
			return null;
		}
		interpreterProxy->pushRemappableOop(firstAsLargeInteger);
		secondAsLargeInteger = createLargeFromSmallInteger(secondInteger);
		firstAsLargeInteger = interpreterProxy->popRemappableOop();
	} else {
		secondAsLargeInteger = secondInteger;
	}
	_return_value = digitDivLargewithnegative(firstAsLargeInteger, secondAsLargeInteger, neg);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}


/*	 */

EXPORT(int) primDigitMultiplyNegative(void) {
	int secondLarge;
	int firstLarge;
	int firstInteger;
	int secondInteger;
	int neg;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	secondInteger = interpreterProxy->stackValue(1);
	neg = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	/* missing DebugCode */;
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(2), "Integer"));
	firstInteger = interpreterProxy->stackValue(2);
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((firstInteger & 1)) {
		interpreterProxy->pushRemappableOop(secondInteger);
		firstLarge = createLargeFromSmallInteger(firstInteger);
		secondInteger = interpreterProxy->popRemappableOop();
	} else {
		firstLarge = firstInteger;
	}
	if ((secondInteger & 1)) {
		interpreterProxy->pushRemappableOop(firstLarge);
		secondLarge = createLargeFromSmallInteger(secondInteger);
		firstLarge = interpreterProxy->popRemappableOop();
	} else {
		secondLarge = secondInteger;
	}
	_return_value = digitMultiplyLargewithnegative(firstLarge, secondLarge, neg);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}


/*	 */

EXPORT(int) primDigitMultiplyWithNegative(void) {
	int secondLarge;
	int firstLarge;
	int firstInteger;
	int secondInteger;
	int neg;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(2), "Integer"));
	firstInteger = interpreterProxy->stackValue(2);
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	secondInteger = interpreterProxy->stackValue(1);
	neg = interpreterProxy->booleanValueOf(interpreterProxy->stackValue(0));
	/* missing DebugCode */;
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((firstInteger & 1)) {
		interpreterProxy->pushRemappableOop(secondInteger);
		firstLarge = createLargeFromSmallInteger(firstInteger);
		secondInteger = interpreterProxy->popRemappableOop();
	} else {
		firstLarge = firstInteger;
	}
	if ((secondInteger & 1)) {
		interpreterProxy->pushRemappableOop(firstLarge);
		secondLarge = createLargeFromSmallInteger(secondInteger);
		firstLarge = interpreterProxy->popRemappableOop();
	} else {
		secondLarge = secondInteger;
	}
	_return_value = digitMultiplyLargewithnegative(firstLarge, secondLarge, neg);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(4, _return_value);
	return null;
}


/*	 */

EXPORT(int) primDigitSubtract(void) {
	int secondLarge;
	int firstLarge;
	int firstInteger;
	int secondInteger;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Integer"));
	secondInteger = interpreterProxy->stackValue(0);
	/* missing DebugCode */;
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	firstInteger = interpreterProxy->stackValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((firstInteger & 1)) {
		interpreterProxy->pushRemappableOop(secondInteger);
		firstLarge = createLargeFromSmallInteger(firstInteger);
		secondInteger = interpreterProxy->popRemappableOop();
	} else {
		firstLarge = firstInteger;
	}
	if ((secondInteger & 1)) {
		interpreterProxy->pushRemappableOop(firstLarge);
		secondLarge = createLargeFromSmallInteger(secondInteger);
		firstLarge = interpreterProxy->popRemappableOop();
	} else {
		secondLarge = secondInteger;
	}
	_return_value = digitSubLargewith(firstLarge, secondLarge);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}


/*	 */

EXPORT(int) primDigitSubtractWith(void) {
	int secondLarge;
	int firstLarge;
	int firstInteger;
	int secondInteger;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(1), "Integer"));
	firstInteger = interpreterProxy->stackValue(1);
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Integer"));
	secondInteger = interpreterProxy->stackValue(0);
	/* missing DebugCode */;
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((firstInteger & 1)) {
		interpreterProxy->pushRemappableOop(secondInteger);
		firstLarge = createLargeFromSmallInteger(firstInteger);
		secondInteger = interpreterProxy->popRemappableOop();
	} else {
		firstLarge = firstInteger;
	}
	if ((secondInteger & 1)) {
		interpreterProxy->pushRemappableOop(firstLarge);
		secondLarge = createLargeFromSmallInteger(secondInteger);
		firstLarge = interpreterProxy->popRemappableOop();
	} else {
		secondLarge = secondInteger;
	}
	_return_value = digitSubLargewith(firstLarge, secondLarge);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(3, _return_value);
	return null;
}


/*	If calling this primitive fails, then C module does not exist. */

EXPORT(int) primGetModuleName(void) {
	int i;
	char *strPtr;
	int strLen;
	int strOop;

	/* missing DebugCode */;
	strLen = strlen(moduleName);
	strOop = interpreterProxy->instantiateClassindexableSize(interpreterProxy->classString(), strLen);
	strPtr = interpreterProxy->firstIndexableField(strOop);
	for (i = 0; i <= (strLen - 1); i += 1) {
		strPtr[i] = (moduleName[i]);
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, strOop);
	return null;
}


/*	Parameter specification #(Integer) doesn't convert! */

EXPORT(int) primNormalize(void) {
	int anInteger;
	int _return_value;

	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "Integer"));
	anInteger = interpreterProxy->stackValue(0);
	/* missing DebugCode */;
	if (interpreterProxy->failed()) {
		return null;
	}
	if ((anInteger & 1)) {
		if (interpreterProxy->failed()) {
			return null;
		}
		interpreterProxy->popthenPush(2, anInteger);
		return null;
	}
	/* begin normalize: */
	/* missing DebugCode */;
	if ((interpreterProxy->fetchClassOf(anInteger)) == (interpreterProxy->classLargePositiveInteger())) {
		_return_value = normalizePositive(anInteger);
		goto l1;
	} else {
		_return_value = normalizeNegative(anInteger);
		goto l1;
	}
l1:	/* end normalize: */;
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(2, _return_value);
	return null;
}


/*	 */

EXPORT(int) primNormalizeNegative(void) {
	int rcvr;
	int _return_value;

	/* missing DebugCode */;
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "LargeNegativeInteger"));
	rcvr = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	_return_value = normalizeNegative(rcvr);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
	return null;
}


/*	 */

EXPORT(int) primNormalizePositive(void) {
	int rcvr;
	int _return_value;

	/* missing DebugCode */;
	interpreterProxy->success(interpreterProxy->isKindOf(interpreterProxy->stackValue(0), "LargePositiveInteger"));
	rcvr = interpreterProxy->stackValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	_return_value = normalizePositive(rcvr);
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->popthenPush(1, _return_value);
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

static int sqAssert(int aBool) {
	/* missing DebugCode */;
}


/*	Flag for marking methods for later thinking. */

static int think(void) {
	return msg("#think should not be called");
}


/*	Argument bytesOop must not be aSmallInteger! */

static int unsafeByteOfat(int bytesOop, int ix) {
	return ((interpreterProxy->stObjectat(bytesOop, ix)) >> 1);
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* LargeIntegers_exports[][3] = {
	{"LargeIntegers", "primAnyBitFromTo", (void*)primAnyBitFromTo},
	{"LargeIntegers", "primDigitSubtractWith", (void*)primDigitSubtractWith},
	{"LargeIntegers", "primDigitBitShift", (void*)primDigitBitShift},
	{"LargeIntegers", "primDigitBitLogicWithOp", (void*)primDigitBitLogicWithOp},
	{"LargeIntegers", "primDigitMultiplyNegative", (void*)primDigitMultiplyNegative},
	{"LargeIntegers", "primDigitMultiplyWithNegative", (void*)primDigitMultiplyWithNegative},
	{"LargeIntegers", "primCheckIfCModuleExists", (void*)primCheckIfCModuleExists},
	{"LargeIntegers", "primDigitCompare", (void*)primDigitCompare},
	{"LargeIntegers", "primDigitCompareWith", (void*)primDigitCompareWith},
	{"LargeIntegers", "primDigitBitOr", (void*)primDigitBitOr},
	{"LargeIntegers", "primNormalizePositive", (void*)primNormalizePositive},
	{"LargeIntegers", "primDigitAdd", (void*)primDigitAdd},
	{"LargeIntegers", "primDigitDivWithNegative", (void*)primDigitDivWithNegative},
	{"LargeIntegers", "getModuleName", (void*)getModuleName},
	{"LargeIntegers", "setInterpreter", (void*)setInterpreter},
	{"LargeIntegers", "primNormalizeNegative", (void*)primNormalizeNegative},
	{"LargeIntegers", "_primDigitBitShift", (void*)_primDigitBitShift},
	{"LargeIntegers", "primDigitBitAnd", (void*)primDigitBitAnd},
	{"LargeIntegers", "primDigitBitXor", (void*)primDigitBitXor},
	{"LargeIntegers", "primDigitAddWith", (void*)primDigitAddWith},
	{"LargeIntegers", "primDigitDivNegative", (void*)primDigitDivNegative},
	{"LargeIntegers", "primAsLargeInteger", (void*)primAsLargeInteger},
	{"LargeIntegers", "primDigitSubtract", (void*)primDigitSubtract},
	{"LargeIntegers", "primGetModuleName", (void*)primGetModuleName},
	{"LargeIntegers", "primDigitBitShiftMagnitude", (void*)primDigitBitShiftMagnitude},
	{"LargeIntegers", "primNormalize", (void*)primNormalize},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

