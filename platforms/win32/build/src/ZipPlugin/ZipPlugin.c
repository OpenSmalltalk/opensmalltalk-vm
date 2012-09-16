/* Automatically generated from Squeak on 15 September 2012 4:47:57 pm 
   by VMMaker 4.10.2
 */

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

#include "sqMemoryAccess.h"


/*** Constants ***/
#define DeflateHashMask 32767
#define DeflateHashShift 5
#define DeflateHashTableSize 32768
#define DeflateMaxDistance 32768
#define DeflateMaxDistanceCodes 30
#define DeflateMaxLiteralCodes 286
#define DeflateMaxMatch 258
#define DeflateMinMatch 3
#define DeflateWindowMask 32767
#define DeflateWindowSize 32768
#define MaxBits 16
#define StateNoMoreData 1

/*** Function Prototypes ***/
static sqInt deflateBlockchainLengthgoodMatch(sqInt lastIndex, sqInt chainLength, sqInt goodMatch);
static sqInt findMatchlastLengthlastMatchchainLengthgoodMatch(sqInt here, sqInt lastLength, sqInt lastMatch, sqInt maxChainLength, sqInt goodMatch);
#pragma export on
EXPORT(const char*) getModuleName(void);
#pragma export off
static sqInt halt(void);
static sqInt loadDeflateStreamFrom(sqInt rcvr);
static sqInt loadZipEncoderFrom(sqInt rcvr);
#pragma export on
EXPORT(sqInt) primitiveDeflateBlock(void);
EXPORT(sqInt) primitiveDeflateUpdateHashTable(void);
EXPORT(sqInt) primitiveInflateDecompressBlock(void);
EXPORT(sqInt) primitiveUpdateAdler32(void);
EXPORT(sqInt) primitiveUpdateGZipCrc32(void);
EXPORT(sqInt) primitiveZipSendBlock(void);
#pragma export off
static sqInt sendBlockwithwithwith(sqInt literalStream, sqInt distanceStream, sqInt litTree, sqInt distTree);
#pragma export on
EXPORT(sqInt) setInterpreter(struct VirtualMachine*anInterpreter);
#pragma export off
static sqInt shouldFlush(void);
static sqInt zipDecodeValueFromsize(unsigned int *table, sqInt tableSize);
static sqInt zipDecompressBlock(void);
static sqInt zipNextBits(sqInt n);
/*** Variables ***/

#ifdef SQUEAK_BUILTIN_PLUGIN
extern
#endif
struct VirtualMachine* interpreterProxy;
static const char *moduleName =
#ifdef SQUEAK_BUILTIN_PLUGIN
	"ZipPlugin 15 September 2012 (i)"
#else
	"ZipPlugin 15 September 2012 (e)"
#endif
;
static unsigned int zipBaseDistance[] = {
0, 1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 
256, 384, 512, 768, 1024, 1536, 2048, 3072, 4096, 6144, 8192, 12288, 16384, 24576};
static unsigned int zipBaseLength[] = {
0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 24, 28, 
32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 0};
static sqInt zipBitBuf;
static sqInt zipBitPos;
static sqInt zipBlockPos;
static sqInt zipBlockStart;
static unsigned char* zipCollection;
static sqInt zipCollectionSize;
static unsigned int zipCrcTable[] = {
0, 1996959894, 3993919788U, 2567524794U, 124634137, 1886057615, 3915621685U, 2657392035U, 249268274, 2044508324, 3772115230U, 2547177864U, 162941995, 2125561021, 3887607047U, 2428444049U, 
498536548, 1789927666, 4089016648U, 2227061214U, 450548861, 1843258603, 4107580753U, 2211677639U, 325883990, 1684777152, 4251122042U, 2321926636U, 335633487, 1661365465, 4195302755U, 2366115317U, 
997073096, 1281953886, 3579855332U, 2724688242U, 1006888145, 1258607687, 3524101629U, 2768942443U, 901097722, 1119000684, 3686517206U, 2898065728U, 853044451, 1172266101, 3705015759U, 2882616665U, 
651767980, 1373503546, 3369554304U, 3218104598U, 565507253, 1454621731, 3485111705U, 3099436303U, 671266974, 1594198024, 3322730930U, 2970347812U, 795835527, 1483230225, 3244367275U, 3060149565U, 
1994146192, 31158534, 2563907772U, 4023717930U, 1907459465, 112637215, 2680153253U, 3904427059U, 2013776290, 251722036, 2517215374U, 3775830040U, 2137656763, 141376813, 2439277719U, 3865271297U, 
1802195444, 476864866, 2238001368U, 4066508878U, 1812370925, 453092731, 2181625025U, 4111451223U, 1706088902, 314042704, 2344532202U, 4240017532U, 1658658271, 366619977, 2362670323U, 4224994405U, 
1303535960, 984961486, 2747007092U, 3569037538U, 1256170817, 1037604311, 2765210733U, 3554079995U, 1131014506, 879679996, 2909243462U, 3663771856U, 1141124467, 855842277, 2852801631U, 3708648649U, 
1342533948, 654459306, 3188396048U, 3373015174U, 1466479909, 544179635, 3110523913U, 3462522015U, 1591671054, 702138776, 2966460450U, 3352799412U, 1504918807, 783551873, 3082640443U, 3233442989U, 
3988292384U, 2596254646U, 62317068, 1957810842, 3939845945U, 2647816111U, 81470997, 1943803523, 3814918930U, 2489596804U, 225274430, 2053790376, 3826175755U, 2466906013U, 167816743, 2097651377, 
4027552580U, 2265490386U, 503444072, 1762050814, 4150417245U, 2154129355U, 426522225, 1852507879, 4275313526U, 2312317920U, 282753626, 1742555852, 4189708143U, 2394877945U, 397917763, 1622183637, 
3604390888U, 2714866558U, 953729732, 1340076626, 3518719985U, 2797360999U, 1068828381, 1219638859, 3624741850U, 2936675148U, 906185462, 1090812512, 3747672003U, 2825379669U, 829329135, 1181335161, 
3412177804U, 3160834842U, 628085408, 1382605366, 3423369109U, 3138078467U, 570562233, 1426400815, 3317316542U, 2998733608U, 733239954, 1555261956, 3268935591U, 3050360625U, 752459403, 1541320221, 
2607071920U, 3965973030U, 1969922972, 40735498, 2617837225U, 3943577151U, 1913087877, 83908371, 2512341634U, 3803740692U, 2075208622, 213261112, 2463272603U, 3855990285U, 2094854071, 198958881, 
2262029012U, 4057260610U, 1759359992, 534414190, 2176718541U, 4139329115U, 1873836001, 414664567, 2282248934U, 4279200368U, 1711684554, 285281116, 2405801727U, 4167216745U, 1634467795, 376229701, 
2685067896U, 3608007406U, 1308918612, 956543938, 2808555105U, 3495958263U, 1231636301, 1047427035, 2932959818U, 3654703836U, 1088359270, 936918000, 2847714899U, 3736837829U, 1202900863, 817233897, 
3183342108U, 3401237130U, 1404277552, 615818150, 3134207493U, 3453421203U, 1423857449, 601450431, 3009837614U, 3294710456U, 1567103746, 711928724, 3020668471U, 3272380065U, 1510334235, 755167117};
static unsigned int* zipDistTable;
static sqInt zipDistTableSize;
static unsigned int zipDistanceCodes[] = {
0, 1, 2, 3, 4, 4, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 
8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 
10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 
11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 
12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 
12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 12, 
13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 
13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 13, 
14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 
15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 
15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 
15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 
15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 
0, 0, 16, 17, 18, 18, 19, 19, 20, 20, 20, 20, 21, 21, 21, 21, 
22, 22, 22, 22, 22, 22, 22, 22, 23, 23, 23, 23, 23, 23, 23, 23, 
24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 
25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 25, 
26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 
26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 
27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 
27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 
28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 
28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 
28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 
28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 
29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 
29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 
29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 
29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29};
static unsigned int* zipDistanceFreq;
static unsigned int* zipDistances;
static unsigned int zipExtraDistanceBits[] = {
0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 
7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13};
static unsigned int zipExtraLengthBits[] = {
0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 
3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0};
static unsigned int* zipHashHead;
static unsigned int* zipHashTail;
static sqInt zipHashValue;
static unsigned int* zipLitTable;
static sqInt zipLitTableSize;
static sqInt zipLiteralCount;
static unsigned int* zipLiteralFreq;
static sqInt zipLiteralSize;
static unsigned char* zipLiterals;
static sqInt zipMatchCount;
static unsigned int zipMatchLengthCodes[] = {
257, 258, 259, 260, 261, 262, 263, 264, 265, 265, 266, 266, 267, 267, 268, 268, 
269, 269, 269, 269, 270, 270, 270, 270, 271, 271, 271, 271, 272, 272, 272, 272, 
273, 273, 273, 273, 273, 273, 273, 273, 274, 274, 274, 274, 274, 274, 274, 274, 
275, 275, 275, 275, 275, 275, 275, 275, 276, 276, 276, 276, 276, 276, 276, 276, 
277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 277, 
278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 278, 
279, 279, 279, 279, 279, 279, 279, 279, 279, 279, 279, 279, 279, 279, 279, 279, 
280, 280, 280, 280, 280, 280, 280, 280, 280, 280, 280, 280, 280, 280, 280, 280, 
281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 
281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 281, 
282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 
282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 282, 
283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 
283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 283, 
284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 
284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284, 284};
static sqInt zipPosition;
static sqInt zipReadLimit;
static unsigned char* zipSource;
static sqInt zipSourceLimit;
static sqInt zipSourcePos;
static sqInt zipState;



/*	Continue deflating the receiver's collection from blockPosition to lastIndex.
	Note that lastIndex must be at least MaxMatch away from the end of collection */

static sqInt deflateBlockchainLengthgoodMatch(sqInt lastIndex, sqInt chainLength, sqInt goodMatch) {
    sqInt flushNeeded;
    sqInt hasMatch;
    sqInt here;
    sqInt hereLength;
    sqInt hereMatch;
    sqInt i;
    sqInt matchResult;
    sqInt newLength;
    sqInt newMatch;
    sqInt distance;
    sqInt literal;
    sqInt lit;
    sqInt prevEntry;
    sqInt here1;
    sqInt prevEntry1;
    sqInt prevEntry2;

	if (zipBlockPos > lastIndex) {
		return 0;
	}
	if (zipLiteralCount >= zipLiteralSize) {
		return 1;
	}
	hasMatch = 0;
	here = zipBlockPos;
	while (here <= lastIndex) {
		if (!(hasMatch)) {

			/* Find the first match */

			matchResult = findMatchlastLengthlastMatchchainLengthgoodMatch(here, DeflateMinMatch - 1, here, chainLength, goodMatch);
			/* begin insertStringAt: */
			zipHashValue = ((((usqInt) zipHashValue << 5)) ^ (zipCollection[(here + DeflateMinMatch) - 1])) & DeflateHashMask;
			prevEntry = zipHashHead[zipHashValue];
			zipHashHead[zipHashValue] = here;
			zipHashTail[here & DeflateWindowMask] = prevEntry;
			hereMatch = matchResult & 65535;
			hereLength = ((usqInt) matchResult >> 16);
		}
		matchResult = findMatchlastLengthlastMatchchainLengthgoodMatch(here + 1, hereLength, hereMatch, chainLength, goodMatch);
		newMatch = matchResult & 65535;

		/* Now check if the next match is better than the current one.
		If not, output the current match (provided that the current match
		is at least MinMatch long) */

		newLength = ((usqInt) matchResult >> 16);
		if ((hereLength >= newLength) && (hereLength >= DeflateMinMatch)) {
			/* begin encodeMatch:distance: */
			zipLiterals[zipLiteralCount] = (hereLength - DeflateMinMatch);
			zipDistances[zipLiteralCount] = (here - hereMatch);
			literal = zipMatchLengthCodes[hereLength - DeflateMinMatch];
			zipLiteralFreq[literal] = ((zipLiteralFreq[literal]) + 1);
			if ((here - hereMatch) < 257) {
				distance = zipDistanceCodes[(here - hereMatch) - 1];
			} else {
				distance = zipDistanceCodes[256 + (((usqInt) ((here - hereMatch) - 1) >> 7))];
			}
			zipDistanceFreq[distance] = ((zipDistanceFreq[distance]) + 1);
			zipLiteralCount += 1;
			zipMatchCount += 1;
			flushNeeded = (zipLiteralCount == zipLiteralSize) || (((zipLiteralCount & 4095) == 0) && (shouldFlush()));
			for (i = 1; i <= (hereLength - 1); i += 1) {
				/* begin insertStringAt: */
				here1 = (here += 1);
				zipHashValue = ((((usqInt) zipHashValue << 5)) ^ (zipCollection[(here1 + DeflateMinMatch) - 1])) & DeflateHashMask;
				prevEntry1 = zipHashHead[zipHashValue];
				zipHashHead[zipHashValue] = here1;
				zipHashTail[here1 & DeflateWindowMask] = prevEntry1;
			}
			hasMatch = 0;
			here += 1;
		} else {
			/* begin encodeLiteral: */
			lit = zipCollection[here];
			zipLiterals[zipLiteralCount] = lit;
			zipDistances[zipLiteralCount] = 0;
			zipLiteralFreq[lit] = ((zipLiteralFreq[lit]) + 1);
			zipLiteralCount += 1;
			flushNeeded = (zipLiteralCount == zipLiteralSize) || (((zipLiteralCount & 4095) == 0) && (shouldFlush()));
			here += 1;
			if ((here <= lastIndex) && (!flushNeeded)) {
				/* begin insertStringAt: */
				zipHashValue = ((((usqInt) zipHashValue << 5)) ^ (zipCollection[(here + DeflateMinMatch) - 1])) & DeflateHashMask;
				prevEntry2 = zipHashHead[zipHashValue];
				zipHashHead[zipHashValue] = here;
				zipHashTail[here & DeflateWindowMask] = prevEntry2;
				hasMatch = 1;
				hereMatch = newMatch;
				hereLength = newLength;
			}
		}
		if (flushNeeded) {
			zipBlockPos = here;
			return 1;
		}
	}
	zipBlockPos = here;
	return 0;
}


/*	Find the longest match for the string starting at here.
	If there is no match longer than lastLength return lastMatch/lastLength.
	Traverse at most maxChainLength entries in the hash table.
	Stop if a match of at least goodMatch size has been found. */

static sqInt findMatchlastLengthlastMatchchainLengthgoodMatch(sqInt here, sqInt lastLength, sqInt lastMatch, sqInt maxChainLength, sqInt goodMatch) {
    sqInt bestLength;
    sqInt chainLength;
    sqInt distance;
    sqInt length;
    sqInt limit;
    sqInt matchPos;
    sqInt matchResult;
    sqInt length1;


	/* Compute the default match result */
	/* There is no way to find a better match than MaxMatch */

	matchResult = (((usqInt) lastLength << 16)) | lastMatch;
	if (lastLength >= DeflateMaxMatch) {
		return matchResult;
	}

	/* Compute the distance to the (possible) match */

	matchPos = zipHashHead[((((usqInt) zipHashValue << 5)) ^ (zipCollection[(here + DeflateMinMatch) - 1])) & DeflateHashMask];

	/* Note: It is required that 0 < distance < MaxDistance */

	distance = here - matchPos;
	if (!((distance > 0) && (distance < DeflateMaxDistance))) {
		return matchResult;
	}

	/* Max. nr of match chain to search */

	chainLength = maxChainLength;
	if (here > DeflateMaxDistance) {

		/* Limit for matches that are too old */

		limit = here - DeflateMaxDistance;
	} else {
		limit = 0;
	}
	bestLength = lastLength;
	while (1) {
		/* begin compare:with:min: */
		if (!((zipCollection[here + bestLength]) == (zipCollection[matchPos + bestLength]))) {
			length = 0;
			goto l1;
		}
		if (!((zipCollection[(here + bestLength) - 1]) == (zipCollection[(matchPos + bestLength) - 1]))) {
			length = 0;
			goto l1;
		}
		if (!((zipCollection[here]) == (zipCollection[matchPos]))) {
			length = 0;
			goto l1;
		}
		if (!((zipCollection[here + 1]) == (zipCollection[matchPos + 1]))) {
			length = 1;
			goto l1;
		}
		length1 = 2;
		while ((length1 < DeflateMaxMatch) && ((zipCollection[here + length1]) == (zipCollection[matchPos + length1]))) {
			length1 += 1;
		}
		length = length1;
	l1:	/* end compare:with:min: */;
		if ((here + length) > zipPosition) {
			length = zipPosition - here;
		}
		if ((length == DeflateMinMatch) && ((here - matchPos) > (((sqInt) DeflateMaxDistance >> 2)))) {
			length = DeflateMinMatch - 1;
		}
		if (length > bestLength) {

			/* We have a new (better) match than before */
			/* Compute the new match result */

			matchResult = (((usqInt) length << 16)) | matchPos;

			/* There is no way to find a better match than MaxMatch */

			bestLength = length;
			if (bestLength >= DeflateMaxMatch) {
				return matchResult;
			}
			if (bestLength > goodMatch) {
				return matchResult;
			}
		}
		if (!(((chainLength -= 1)) > 0)) {
			return matchResult;
		}
		matchPos = zipHashTail[matchPos & DeflateWindowMask];
		if (matchPos <= limit) {
			return matchResult;
		}
	}
}


/*	Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important! */

EXPORT(const char*) getModuleName(void) {
	return moduleName;
}

static sqInt halt(void) {
	;
}

static sqInt loadDeflateStreamFrom(sqInt rcvr) {
    sqInt oop;

	if (!((interpreterProxy->isPointers(rcvr)) && ((interpreterProxy->slotSizeOf(rcvr)) >= 15))) {
		return 0;
	}
	oop = interpreterProxy->fetchPointerofObject(0, rcvr);
	if ((oop & 1)) {
		return interpreterProxy->primitiveFail();
	}
	if (!(interpreterProxy->isBytes(oop))) {
		return interpreterProxy->primitiveFail();
	}
	zipCollection = interpreterProxy->firstIndexableField(oop);
	zipCollectionSize = interpreterProxy->byteSizeOf(oop);
	zipPosition = interpreterProxy->fetchIntegerofObject(1, rcvr);

	/* zipWriteLimit := interpreterProxy fetchInteger: 3 ofObject: rcvr. */

	zipReadLimit = interpreterProxy->fetchIntegerofObject(2, rcvr);
	oop = interpreterProxy->fetchPointerofObject(4, rcvr);
	if (((oop & 1)) || (!(interpreterProxy->isWords(oop)))) {
		return 0;
	}
	if (!((interpreterProxy->slotSizeOf(oop)) == DeflateHashTableSize)) {
		return 0;
	}
	zipHashHead = interpreterProxy->firstIndexableField(oop);
	oop = interpreterProxy->fetchPointerofObject(5, rcvr);
	if (((oop & 1)) || (!(interpreterProxy->isWords(oop)))) {
		return 0;
	}
	if (!((interpreterProxy->slotSizeOf(oop)) == DeflateWindowSize)) {
		return 0;
	}
	zipHashTail = interpreterProxy->firstIndexableField(oop);
	zipHashValue = interpreterProxy->fetchIntegerofObject(6, rcvr);

	/* zipBlockStart := interpreterProxy fetchInteger: 8 ofObject: rcvr. */

	zipBlockPos = interpreterProxy->fetchIntegerofObject(7, rcvr);
	oop = interpreterProxy->fetchPointerofObject(9, rcvr);
	if (((oop & 1)) || (!(interpreterProxy->isBytes(oop)))) {
		return 0;
	}
	zipLiteralSize = interpreterProxy->slotSizeOf(oop);
	zipLiterals = interpreterProxy->firstIndexableField(oop);
	oop = interpreterProxy->fetchPointerofObject(10, rcvr);
	if (((oop & 1)) || (!(interpreterProxy->isWords(oop)))) {
		return 0;
	}
	if ((interpreterProxy->slotSizeOf(oop)) < zipLiteralSize) {
		return 0;
	}
	zipDistances = interpreterProxy->firstIndexableField(oop);
	oop = interpreterProxy->fetchPointerofObject(11, rcvr);
	if (((oop & 1)) || (!(interpreterProxy->isWords(oop)))) {
		return 0;
	}
	if (!((interpreterProxy->slotSizeOf(oop)) == DeflateMaxLiteralCodes)) {
		return 0;
	}
	zipLiteralFreq = interpreterProxy->firstIndexableField(oop);
	oop = interpreterProxy->fetchPointerofObject(12, rcvr);
	if (((oop & 1)) || (!(interpreterProxy->isWords(oop)))) {
		return 0;
	}
	if (!((interpreterProxy->slotSizeOf(oop)) == DeflateMaxDistanceCodes)) {
		return 0;
	}
	zipDistanceFreq = interpreterProxy->firstIndexableField(oop);
	zipLiteralCount = interpreterProxy->fetchIntegerofObject(13, rcvr);
	zipMatchCount = interpreterProxy->fetchIntegerofObject(14, rcvr);
	return !(interpreterProxy->failed());
}

static sqInt loadZipEncoderFrom(sqInt rcvr) {
    sqInt oop;

	if (!((interpreterProxy->isPointers(rcvr)) && ((interpreterProxy->slotSizeOf(rcvr)) >= 6))) {
		return 0;
	}
	oop = interpreterProxy->fetchPointerofObject(0, rcvr);
	if ((oop & 1)) {
		return interpreterProxy->primitiveFail();
	}
	if (!(interpreterProxy->isBytes(oop))) {
		return interpreterProxy->primitiveFail();
	}
	zipCollection = interpreterProxy->firstIndexableField(oop);
	zipCollectionSize = interpreterProxy->byteSizeOf(oop);
	zipPosition = interpreterProxy->fetchIntegerofObject(1, rcvr);

	/* zipWriteLimit := interpreterProxy fetchInteger: 3 ofObject: rcvr. */

	zipReadLimit = interpreterProxy->fetchIntegerofObject(2, rcvr);
	zipBitBuf = interpreterProxy->fetchIntegerofObject(4, rcvr);
	zipBitPos = interpreterProxy->fetchIntegerofObject(5, rcvr);
	return !(interpreterProxy->failed());
}


/*	Primitive. Deflate the current contents of the receiver. */

EXPORT(sqInt) primitiveDeflateBlock(void) {
    sqInt chainLength;
    sqInt goodMatch;
    sqInt lastIndex;
    sqInt rcvr;
    sqInt result;

	if (!((interpreterProxy->methodArgumentCount()) == 3)) {
		return interpreterProxy->primitiveFail();
	}
	goodMatch = interpreterProxy->stackIntegerValue(0);
	chainLength = interpreterProxy->stackIntegerValue(1);
	lastIndex = interpreterProxy->stackIntegerValue(2);
	rcvr = interpreterProxy->stackObjectValue(3);
	if (interpreterProxy->failed()) {
		return null;
	}
	;
	if (!(loadDeflateStreamFrom(rcvr))) {
		return interpreterProxy->primitiveFail();
	}
	result = deflateBlockchainLengthgoodMatch(lastIndex, chainLength, goodMatch);
	if (!(interpreterProxy->failed())) {
		interpreterProxy->storeIntegerofObjectwithValue(6, rcvr, zipHashValue);
		interpreterProxy->storeIntegerofObjectwithValue(7, rcvr, zipBlockPos);
		interpreterProxy->storeIntegerofObjectwithValue(13, rcvr, zipLiteralCount);
		interpreterProxy->storeIntegerofObjectwithValue(14, rcvr, zipMatchCount);
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(4);
		interpreterProxy->pushBool(result);
	}
}


/*	Primitive. Update the hash tables after data has been moved by delta. */

EXPORT(sqInt) primitiveDeflateUpdateHashTable(void) {
    sqInt delta;
    sqInt entry;
    sqInt i;
    sqInt table;
    int *tablePtr;
    sqInt tableSize;

	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}
	delta = interpreterProxy->stackIntegerValue(0);
	table = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(interpreterProxy->isWords(table))) {
		return interpreterProxy->primitiveFail();
	}
	tableSize = interpreterProxy->slotSizeOf(table);
	tablePtr = interpreterProxy->firstIndexableField(table);
	for (i = 0; i <= (tableSize - 1); i += 1) {
		entry = tablePtr[i];
		if (entry >= delta) {
			tablePtr[i] = (entry - delta);
		} else {
			tablePtr[i] = 0;
		}
	}
	interpreterProxy->pop(2);
}


/*	Primitive. Inflate a single block. */

EXPORT(sqInt) primitiveInflateDecompressBlock(void) {
    sqInt oop;
    sqInt rcvr;

	if (!((interpreterProxy->methodArgumentCount()) == 2)) {
		return interpreterProxy->primitiveFail();
	}
	oop = interpreterProxy->stackObjectValue(0);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(interpreterProxy->isWords(oop))) {
		return interpreterProxy->primitiveFail();
	}
	zipDistTable = interpreterProxy->firstIndexableField(oop);

	/* literal table */

	zipDistTableSize = interpreterProxy->slotSizeOf(oop);
	oop = interpreterProxy->stackObjectValue(1);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(interpreterProxy->isWords(oop))) {
		return interpreterProxy->primitiveFail();
	}
	zipLitTable = interpreterProxy->firstIndexableField(oop);

	/* Receiver (InflateStream) */

	zipLitTableSize = interpreterProxy->slotSizeOf(oop);
	rcvr = interpreterProxy->stackObjectValue(2);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(interpreterProxy->isPointers(rcvr))) {
		return interpreterProxy->primitiveFail();
	}
	if ((interpreterProxy->slotSizeOf(rcvr)) < 9) {
		return interpreterProxy->primitiveFail();
	}
	zipReadLimit = interpreterProxy->fetchIntegerofObject(2, rcvr);
	zipState = interpreterProxy->fetchIntegerofObject(3, rcvr);
	zipBitBuf = interpreterProxy->fetchIntegerofObject(4, rcvr);
	zipBitPos = interpreterProxy->fetchIntegerofObject(5, rcvr);
	zipSourcePos = interpreterProxy->fetchIntegerofObject(7, rcvr);
	zipSourceLimit = interpreterProxy->fetchIntegerofObject(8, rcvr);
	if (interpreterProxy->failed()) {
		return null;
	}
	zipReadLimit -= 1;
	zipSourcePos -= 1;

	/* collection */

	zipSourceLimit -= 1;
	oop = interpreterProxy->fetchPointerofObject(0, rcvr);
	if ((oop & 1)) {
		return interpreterProxy->primitiveFail();
	}
	if (!(interpreterProxy->isBytes(oop))) {
		return interpreterProxy->primitiveFail();
	}
	zipCollection = interpreterProxy->firstIndexableField(oop);

	/* source */

	zipCollectionSize = interpreterProxy->byteSizeOf(oop);
	oop = interpreterProxy->fetchPointerofObject(6, rcvr);
	if ((oop & 1)) {
		return interpreterProxy->primitiveFail();
	}
	if (!(interpreterProxy->isBytes(oop))) {
		return interpreterProxy->primitiveFail();
	}

	/* do the primitive */

	zipSource = interpreterProxy->firstIndexableField(oop);
	zipDecompressBlock();
	if (!(interpreterProxy->failed())) {
		interpreterProxy->storeIntegerofObjectwithValue(2, rcvr, zipReadLimit + 1);
		interpreterProxy->storeIntegerofObjectwithValue(3, rcvr, zipState);
		interpreterProxy->storeIntegerofObjectwithValue(4, rcvr, zipBitBuf);
		interpreterProxy->storeIntegerofObjectwithValue(5, rcvr, zipBitPos);
		interpreterProxy->storeIntegerofObjectwithValue(7, rcvr, zipSourcePos + 1);
		interpreterProxy->pop(2);
	}
}


/*	Primitive. Update a 32bit CRC value. */

EXPORT(sqInt) primitiveUpdateAdler32(void) {
    unsigned int  adler32;
    sqInt b;
    unsigned char *bytePtr;
    sqInt collection;
    sqInt i;
    sqInt length;
    sqInt s1;
    sqInt s2;
    sqInt startIndex;
    sqInt stopIndex;

	if (!((interpreterProxy->methodArgumentCount()) == 4)) {
		return interpreterProxy->primitiveFail();
	}
	collection = interpreterProxy->stackObjectValue(0);
	stopIndex = interpreterProxy->stackIntegerValue(1);
	startIndex = interpreterProxy->stackIntegerValue(2);
	adler32 = interpreterProxy->positive32BitValueOf(interpreterProxy->stackValue(3));
	if (interpreterProxy->failed()) {
		return 0;
	}
	if (!((interpreterProxy->isBytes(collection)) && ((stopIndex >= startIndex) && (startIndex > 0)))) {
		return interpreterProxy->primitiveFail();
	}
	length = interpreterProxy->byteSizeOf(collection);
	if (!(stopIndex <= length)) {
		return interpreterProxy->primitiveFail();
	}
	bytePtr = interpreterProxy->firstIndexableField(collection);
	startIndex -= 1;
	stopIndex -= 1;
	s1 = adler32 & 65535;
	s2 = (((usqInt) adler32) >> 16) & 65535;
	for (i = startIndex; i <= stopIndex; i += 1) {
		b = bytePtr[i];
		s1 = (s1 + b) % 65521;
		s2 = (s2 + s1) % 65521;
	}
	adler32 = (((usqInt) s2 << 16)) + s1;
	interpreterProxy->pop(5);
	interpreterProxy->push(interpreterProxy->positive32BitIntegerFor(adler32));
}


/*	Primitive. Update a 32bit CRC value. */

EXPORT(sqInt) primitiveUpdateGZipCrc32(void) {
    unsigned char *bytePtr;
    sqInt collection;
    unsigned int  crc;
    sqInt i;
    sqInt length;
    sqInt startIndex;
    sqInt stopIndex;

	if (!((interpreterProxy->methodArgumentCount()) == 4)) {
		return interpreterProxy->primitiveFail();
	}
	collection = interpreterProxy->stackObjectValue(0);
	stopIndex = interpreterProxy->stackIntegerValue(1);
	startIndex = interpreterProxy->stackIntegerValue(2);
	crc = interpreterProxy->positive32BitValueOf(interpreterProxy->stackValue(3));
	if (interpreterProxy->failed()) {
		return 0;
	}
	if (!((interpreterProxy->isBytes(collection)) && ((stopIndex >= startIndex) && (startIndex > 0)))) {
		return interpreterProxy->primitiveFail();
	}
	length = interpreterProxy->byteSizeOf(collection);
	if (!(stopIndex <= length)) {
		return interpreterProxy->primitiveFail();
	}
	bytePtr = interpreterProxy->firstIndexableField(collection);
	;
	startIndex -= 1;
	stopIndex -= 1;
	for (i = startIndex; i <= stopIndex; i += 1) {
		crc = (zipCrcTable[(crc ^ (bytePtr[i])) & 255]) ^ (((usqInt) crc) >> 8);
	}
	interpreterProxy->pop(5);
	interpreterProxy->push(interpreterProxy->positive32BitIntegerFor(crc));
}

EXPORT(sqInt) primitiveZipSendBlock(void) {
    sqInt distStream;
    sqInt distTree;
    sqInt litStream;
    sqInt litTree;
    sqInt rcvr;
    sqInt result;

	if (!((interpreterProxy->methodArgumentCount()) == 4)) {
		return interpreterProxy->primitiveFail();
	}
	distTree = interpreterProxy->stackObjectValue(0);
	litTree = interpreterProxy->stackObjectValue(1);
	distStream = interpreterProxy->stackObjectValue(2);
	litStream = interpreterProxy->stackObjectValue(3);
	rcvr = interpreterProxy->stackObjectValue(4);
	if (interpreterProxy->failed()) {
		return null;
	}
	if (!(loadZipEncoderFrom(rcvr))) {
		return interpreterProxy->primitiveFail();
	}
	if (!((interpreterProxy->isPointers(distTree)) && ((interpreterProxy->slotSizeOf(distTree)) >= 2))) {
		return interpreterProxy->primitiveFail();
	}
	if (!((interpreterProxy->isPointers(litTree)) && ((interpreterProxy->slotSizeOf(litTree)) >= 2))) {
		return interpreterProxy->primitiveFail();
	}
	if (!((interpreterProxy->isPointers(litStream)) && ((interpreterProxy->slotSizeOf(litStream)) >= 3))) {
		return interpreterProxy->primitiveFail();
	}
	if (!((interpreterProxy->isPointers(distStream)) && ((interpreterProxy->slotSizeOf(distStream)) >= 3))) {
		return interpreterProxy->primitiveFail();
	}
	;
	result = sendBlockwithwithwith(litStream, distStream, litTree, distTree);
	if (!(interpreterProxy->failed())) {
		interpreterProxy->storeIntegerofObjectwithValue(1, rcvr, zipPosition);
		interpreterProxy->storeIntegerofObjectwithValue(4, rcvr, zipBitBuf);
		interpreterProxy->storeIntegerofObjectwithValue(5, rcvr, zipBitPos);
	}
	if (!(interpreterProxy->failed())) {
		interpreterProxy->pop(5);
		interpreterProxy->pushInteger(result);
	}
}


/*	Require: 
		zipCollection, zipCollectionSize, zipPosition,
		zipBitBuf, zipBitPos.
	 */

static sqInt sendBlockwithwithwith(sqInt literalStream, sqInt distanceStream, sqInt litTree, sqInt distTree) {
    sqInt code;
    sqInt dist;
    unsigned int *distArray;
    unsigned int *distBitLengths;
    sqInt distBlCount;
    unsigned int *distCodes;
    sqInt extra;
    sqInt lit;
    unsigned char *litArray;
    sqInt litBlCount;
    sqInt litLimit;
    sqInt litPos;
    unsigned int *llBitLengths;
    unsigned int *llCodes;
    sqInt oop;
    sqInt sum;

	oop = interpreterProxy->fetchPointerofObject(0, literalStream);
	litPos = interpreterProxy->fetchIntegerofObject(1, literalStream);
	litLimit = interpreterProxy->fetchIntegerofObject(2, literalStream);
	if (!((!((oop & 1))) && ((litPos <= litLimit) && ((litLimit <= (interpreterProxy->byteSizeOf(oop))) && (interpreterProxy->isBytes(oop)))))) {
		return interpreterProxy->primitiveFail();
	}
	litArray = interpreterProxy->firstIndexableField(oop);
	oop = interpreterProxy->fetchPointerofObject(0, distanceStream);
	if (!((!((oop & 1))) && (((interpreterProxy->fetchIntegerofObject(1, distanceStream)) == litPos) && ((interpreterProxy->fetchIntegerofObject(2, distanceStream)) == litLimit)))) {
		return interpreterProxy->primitiveFail();
	}
	if (!((interpreterProxy->isWords(oop)) && (litLimit <= (interpreterProxy->slotSizeOf(oop))))) {
		return interpreterProxy->primitiveFail();
	}
	distArray = interpreterProxy->firstIndexableField(oop);
	oop = interpreterProxy->fetchPointerofObject(0, litTree);
	if (!((!((oop & 1))) && (interpreterProxy->isWords(oop)))) {
		return interpreterProxy->primitiveFail();
	}
	litBlCount = interpreterProxy->slotSizeOf(oop);
	llBitLengths = interpreterProxy->firstIndexableField(oop);
	oop = interpreterProxy->fetchPointerofObject(1, litTree);
	if (!((!((oop & 1))) && (interpreterProxy->isWords(oop)))) {
		return interpreterProxy->primitiveFail();
	}
	if (!(litBlCount == (interpreterProxy->slotSizeOf(oop)))) {
		return interpreterProxy->primitiveFail();
	}
	llCodes = interpreterProxy->firstIndexableField(oop);
	oop = interpreterProxy->fetchPointerofObject(0, distTree);
	if (!((!((oop & 1))) && (interpreterProxy->isWords(oop)))) {
		return interpreterProxy->primitiveFail();
	}
	distBlCount = interpreterProxy->slotSizeOf(oop);
	distBitLengths = interpreterProxy->firstIndexableField(oop);
	oop = interpreterProxy->fetchPointerofObject(1, distTree);
	if (!((!((oop & 1))) && (interpreterProxy->isWords(oop)))) {
		return interpreterProxy->primitiveFail();
	}
	if (!(distBlCount == (interpreterProxy->slotSizeOf(oop)))) {
		return interpreterProxy->primitiveFail();
	}
	distCodes = interpreterProxy->firstIndexableField(oop);
	if (interpreterProxy->failed()) {
		return null;
	}
	/* begin nextZipBits:put: */
	if (!((0 >= 0) && ((1 << 0) > 0))) {
		interpreterProxy->primitiveFail();
		goto l6;
	}
	zipBitBuf = zipBitBuf | (((zipBitPos < 0) ? ((usqInt) 0 >> -zipBitPos) : ((usqInt) 0 << zipBitPos)));
	zipBitPos += 0;
	while ((zipBitPos >= 8) && (zipPosition < zipCollectionSize)) {
		zipCollection[zipPosition] = (zipBitBuf & 255);
		zipPosition += 1;
		zipBitBuf = ((usqInt) zipBitBuf) >> 8;
		zipBitPos -= 8;
	}
l6:	/* end nextZipBits:put: */;
	sum = 0;
	while ((litPos < litLimit) && ((zipPosition + 4) < zipCollectionSize)) {
		lit = litArray[litPos];
		dist = distArray[litPos];
		litPos += 1;
		if (dist == 0) {

			/* literal */

			sum += 1;
			if (!(lit < litBlCount)) {
				return interpreterProxy->primitiveFail();
			}
			/* begin nextZipBits:put: */
			if (!(((llCodes[lit]) >= 0) && ((1 << (llBitLengths[lit])) > (llCodes[lit])))) {
				interpreterProxy->primitiveFail();
				goto l1;
			}
			zipBitBuf = zipBitBuf | (((zipBitPos < 0) ? ((usqInt) (llCodes[lit]) >> -zipBitPos) : ((usqInt) (llCodes[lit]) << zipBitPos)));
			zipBitPos += llBitLengths[lit];
			while ((zipBitPos >= 8) && (zipPosition < zipCollectionSize)) {
				zipCollection[zipPosition] = (zipBitBuf & 255);
				zipPosition += 1;
				zipBitBuf = ((usqInt) zipBitBuf) >> 8;
				zipBitPos -= 8;
			}
		l1:	/* end nextZipBits:put: */;
		} else {

			/* match */

			sum = (sum + lit) + DeflateMinMatch;
			if (!(lit < 256)) {
				return interpreterProxy->primitiveFail();
			}
			code = zipMatchLengthCodes[lit];
			if (!(code < litBlCount)) {
				return interpreterProxy->primitiveFail();
			}
			/* begin nextZipBits:put: */
			if (!(((llCodes[code]) >= 0) && ((1 << (llBitLengths[code])) > (llCodes[code])))) {
				interpreterProxy->primitiveFail();
				goto l4;
			}
			zipBitBuf = zipBitBuf | (((zipBitPos < 0) ? ((usqInt) (llCodes[code]) >> -zipBitPos) : ((usqInt) (llCodes[code]) << zipBitPos)));
			zipBitPos += llBitLengths[code];
			while ((zipBitPos >= 8) && (zipPosition < zipCollectionSize)) {
				zipCollection[zipPosition] = (zipBitBuf & 255);
				zipPosition += 1;
				zipBitBuf = ((usqInt) zipBitBuf) >> 8;
				zipBitPos -= 8;
			}
		l4:	/* end nextZipBits:put: */;
			extra = zipExtraLengthBits[code - 257];
			if (!(extra == 0)) {
				lit -= zipBaseLength[code - 257];
				/* begin nextZipBits:put: */
				if (!((lit >= 0) && ((1 << extra) > lit))) {
					interpreterProxy->primitiveFail();
					goto l2;
				}
				zipBitBuf = zipBitBuf | (((zipBitPos < 0) ? ((usqInt) lit >> -zipBitPos) : ((usqInt) lit << zipBitPos)));
				zipBitPos += extra;
				while ((zipBitPos >= 8) && (zipPosition < zipCollectionSize)) {
					zipCollection[zipPosition] = (zipBitBuf & 255);
					zipPosition += 1;
					zipBitBuf = ((usqInt) zipBitBuf) >> 8;
					zipBitPos -= 8;
				}
			l2:	/* end nextZipBits:put: */;
			}
			dist -= 1;
			if (!(dist < 32768)) {
				return interpreterProxy->primitiveFail();
			}
			if (dist < 256) {
				code = zipDistanceCodes[dist];
			} else {
				code = zipDistanceCodes[256 + (((usqInt) dist) >> 7)];
			}
			if (!(code < distBlCount)) {
				return interpreterProxy->primitiveFail();
			}
			/* begin nextZipBits:put: */
			if (!(((distCodes[code]) >= 0) && ((1 << (distBitLengths[code])) > (distCodes[code])))) {
				interpreterProxy->primitiveFail();
				goto l5;
			}
			zipBitBuf = zipBitBuf | (((zipBitPos < 0) ? ((usqInt) (distCodes[code]) >> -zipBitPos) : ((usqInt) (distCodes[code]) << zipBitPos)));
			zipBitPos += distBitLengths[code];
			while ((zipBitPos >= 8) && (zipPosition < zipCollectionSize)) {
				zipCollection[zipPosition] = (zipBitBuf & 255);
				zipPosition += 1;
				zipBitBuf = ((usqInt) zipBitBuf) >> 8;
				zipBitPos -= 8;
			}
		l5:	/* end nextZipBits:put: */;
			extra = zipExtraDistanceBits[code];
			if (!(extra == 0)) {
				dist -= zipBaseDistance[code];
				/* begin nextZipBits:put: */
				if (!((dist >= 0) && ((1 << extra) > dist))) {
					interpreterProxy->primitiveFail();
					goto l3;
				}
				zipBitBuf = zipBitBuf | (((zipBitPos < 0) ? ((usqInt) dist >> -zipBitPos) : ((usqInt) dist << zipBitPos)));
				zipBitPos += extra;
				while ((zipBitPos >= 8) && (zipPosition < zipCollectionSize)) {
					zipCollection[zipPosition] = (zipBitBuf & 255);
					zipPosition += 1;
					zipBitBuf = ((usqInt) zipBitBuf) >> 8;
					zipBitPos -= 8;
				}
			l3:	/* end nextZipBits:put: */;
			}
		}
	}
	if (interpreterProxy->failed()) {
		return null;
	}
	interpreterProxy->storeIntegerofObjectwithValue(1, literalStream, litPos);
	interpreterProxy->storeIntegerofObjectwithValue(1, distanceStream, litPos);
	return sum;
}


/*	Note: This is coded so that is can be run from Squeak. */

EXPORT(sqInt) setInterpreter(struct VirtualMachine*anInterpreter) {
    sqInt ok;

	interpreterProxy = anInterpreter;
	ok = interpreterProxy->majorVersion() == VM_PROXY_MAJOR;
	if (ok == 0) {
		return 0;
	}
	ok = interpreterProxy->minorVersion() >= VM_PROXY_MINOR;
	return ok;
}


/*	Check if we should flush the current block.
	Flushing can be useful if the input characteristics change. */

static sqInt shouldFlush(void) {
    sqInt nLits;

	if (zipLiteralCount == zipLiteralSize) {
		return 1;
	}
	if (!((zipLiteralCount & 4095) == 0)) {
		return 0;
	}
	if ((zipMatchCount * 10) <= zipLiteralCount) {
		return 0;
	}
	nLits = zipLiteralCount - zipMatchCount;
	if (nLits <= zipMatchCount) {
		return 0;
	}
	return (nLits * 4) <= zipMatchCount;
}


/*	Decode the next value in the receiver using the given huffman table. */

static sqInt zipDecodeValueFromsize(unsigned int *table, sqInt tableSize) {
    sqInt bits;
    sqInt bitsNeeded;
    sqInt index;
    sqInt tableIndex;
    sqInt value;
    sqInt bits1;
    sqInt byte;


	/* Initial bits needed */

	bitsNeeded = ((usqInt) (table[0]) >> 24);
	if (bitsNeeded > MaxBits) {
		interpreterProxy->primitiveFail();
		return 0;
	}

	/* First real table */

	tableIndex = 2;
	while (1) {
		/* begin zipNextBits: */
		while (zipBitPos < bitsNeeded) {
			byte = zipSource[(zipSourcePos += 1)];
			zipBitBuf += byte << zipBitPos;
			zipBitPos += 8;
		}
		bits1 = zipBitBuf & ((1 << bitsNeeded) - 1);
		zipBitBuf = ((usqInt) zipBitBuf) >> bitsNeeded;
		zipBitPos -= bitsNeeded;
		bits = bits1;
		index = (tableIndex + bits) - 1;
		if (index >= tableSize) {
			interpreterProxy->primitiveFail();
			return 0;
		}

		/* Lookup entry in table */

		value = table[index];
		if ((value & 1056964608) == 0) {
			return value;
		}

		/* Table offset in low 16 bit */

		tableIndex = value & 65535;

		/* Additional bits in high 8 bit */

		bitsNeeded = (((usqInt) value >> 24)) & 255;
		if (bitsNeeded > MaxBits) {
			interpreterProxy->primitiveFail();
			return 0;
		}
	}
	return 0;
}

static sqInt zipDecompressBlock(void) {
    sqInt distance;
    sqInt dstPos;
    sqInt extra;
    sqInt i;
    sqInt length;
    sqInt max;
    sqInt oldBitPos;
    sqInt oldBits;
    sqInt oldPos;
    sqInt srcPos;
    sqInt value;

	max = zipCollectionSize - 1;
	while ((zipReadLimit < max) && (zipSourcePos <= zipSourceLimit)) {

		/* Back up stuff if we're running out of space */

		oldBits = zipBitBuf;
		oldBitPos = zipBitPos;
		oldPos = zipSourcePos;
		value = zipDecodeValueFromsize(zipLitTable, zipLitTableSize);
		if (value < 256) {
			zipCollection[(zipReadLimit += 1)] = value;
		} else {
			if (value == 256) {

				/* length/distance or end of block */
				/* End of block */

				zipState = zipState & StateNoMoreData;
				return 0;
			}
			extra = (((usqInt) value >> 16)) - 1;
			length = value & 65535;
			if (extra > 0) {
				length += zipNextBits(extra);
			}
			value = zipDecodeValueFromsize(zipDistTable, zipDistTableSize);
			extra = ((usqInt) value >> 16);
			distance = value & 65535;
			if (extra > 0) {
				distance += zipNextBits(extra);
			}
			if ((zipReadLimit + length) >= max) {
				zipBitBuf = oldBits;
				zipBitPos = oldBitPos;
				zipSourcePos = oldPos;
				return 0;
			}
			dstPos = zipReadLimit;
			srcPos = zipReadLimit - distance;
			for (i = 1; i <= length; i += 1) {
				zipCollection[dstPos + i] = (zipCollection[srcPos + i]);
			}
			zipReadLimit += length;
		}
	}
}

static sqInt zipNextBits(sqInt n) {
    sqInt bits;
    sqInt byte;

	while (zipBitPos < n) {
		byte = zipSource[(zipSourcePos += 1)];
		zipBitBuf += byte << zipBitPos;
		zipBitPos += 8;
	}
	bits = zipBitBuf & ((1 << n) - 1);
	zipBitBuf = ((usqInt) zipBitBuf) >> n;
	zipBitPos -= n;
	return bits;
}


#ifdef SQUEAK_BUILTIN_PLUGIN


void* ZipPlugin_exports[][3] = {
	{"ZipPlugin", "primitiveZipSendBlock", (void*)primitiveZipSendBlock},
	{"ZipPlugin", "primitiveUpdateAdler32", (void*)primitiveUpdateAdler32},
	{"ZipPlugin", "primitiveUpdateGZipCrc32", (void*)primitiveUpdateGZipCrc32},
	{"ZipPlugin", "primitiveDeflateUpdateHashTable", (void*)primitiveDeflateUpdateHashTable},
	{"ZipPlugin", "setInterpreter", (void*)setInterpreter},
	{"ZipPlugin", "getModuleName", (void*)getModuleName},
	{"ZipPlugin", "primitiveDeflateBlock", (void*)primitiveDeflateBlock},
	{"ZipPlugin", "primitiveInflateDecompressBlock", (void*)primitiveInflateDecompressBlock},
	{NULL, NULL, NULL}
};


#endif /* ifdef SQ_BUILTIN_PLUGIN */

