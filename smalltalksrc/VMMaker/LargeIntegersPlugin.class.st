"
LargeIntegersPlugin provides functions for speeding up LargeInteger arithmetics.

Inst vars:
	andOpIndex			C constant
	orOpIndex			C constant
	xorOpIndex 			C constant
Used like an enum, in ST one would use symbols instead.

Class vars:
	none


Evaluations
-------------

Try

	LargeIntegersTest getModuleName.

If it is nil, you probably have an older LargeInteger module or none at all; it works for version number 'v1.1' or higher.


History
--------

v1.2

- fix: >>anyBitOfBytes: aBytesOop from: start to: stopArg

v1.1

- >>primGetModuleName for checking the version of the plugin;

- >>primDigitBitShiftMagnitude and >>primAnyBitFrom:to: for supporting - not installing! - unification of shift semantics of negative Integers;

v1.0

- speeds up digitDiv:neg: at about 20%.
	In >>cCoreDigitDivDiv:len:rem:len:quo:len: the 'nibble' arithmetic is removed.


"
Class {
	#name : #LargeIntegersPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#instVars : [
		'andOpIndex',
		'orOpIndex',
		'xorOpIndex'
	],
	#category : 'VMMaker-Plugins'
}

{ #category : #translation }
LargeIntegersPlugin class >> declareCVarsIn: cg [ 
	cg var: 'andOpIndex' declareC: 'const int  andOpIndex = 0'.
	cg var: 'orOpIndex' declareC: 'const int  orOpIndex = 1'.
	cg var: 'xorOpIndex' declareC: 'const int  xorOpIndex = 2'
]

{ #category : #translation }
LargeIntegersPlugin class >> moduleName [
	^'LargeIntegers'
]

{ #category : #translation }
LargeIntegersPlugin class >> moduleNameAndVersion [
	"Answer the receiver's module name and version info that is used for the plugin's C code. The default is to append the code generation date, but any useful text is ok (keep it short)"

	^ self moduleName, Character space asString, self version, Character space asString, Date today asString
]

{ #category : #'instance creation' }
LargeIntegersPlugin class >> new [
	^super new initialize
]

{ #category : #translation }
LargeIntegersPlugin class >> version [
	"Answer the receiver's version info as String."

	^ 'v1.3'
]

{ #category : #util }
LargeIntegersPlugin >> anyBitOfBytes: aBytesOop from: start to: stopArg [ 
	"Argument has to be aBytesOop!"
	"Tests for any magnitude bits in the interval from start to stopArg."
	| magnitude rightShift leftShift stop firstByteIx lastByteIx |
	self
		debugCode: [self msg: 'anyBitOfBytes: aBytesOop from: start to: stopArg'].
	start < 1 | (stopArg < 1)
		ifTrue: [^ interpreterProxy primitiveFail].
	magnitude _ aBytesOop.
	stop _ stopArg
				min: (self highBitOfBytes: magnitude).
	start > stop
		ifTrue: [^ false].
	firstByteIx _ start - 1 // 8 + 1.
	lastByteIx _ stop - 1 // 8 + 1.
	rightShift _ 0 - (start - 1 \\ 8).
	leftShift _ 7 - (stop - 1 \\ 8).
	firstByteIx = lastByteIx
		ifTrue: [| digit mask | 
			mask _ (255 bitShift: 0 - rightShift)
						bitAnd: (255 bitShift: 0 - leftShift).
			digit _ self digitOfBytes: magnitude at: firstByteIx.
			^ (digit bitAnd: mask)
				~= 0].
	((self digitOfBytes: magnitude at: firstByteIx)
			bitShift: rightShift)
			~= 0
		ifTrue: [^ true].
	firstByteIx + 1
		to: lastByteIx - 1
		do: [:ix | (self digitOfBytes: magnitude at: ix)
					~= 0
				ifTrue: [^ true]].
	(((self digitOfBytes: magnitude at: lastByteIx)
			bitShift: leftShift)
			bitAnd: 255)
			~= 0
		ifTrue: [^ true].
	^ false
]

{ #category : #util }
LargeIntegersPlugin >> byteSizeOfBytes: bytesOop [ 
	"Precondition: bytesOop is not anInteger and a bytes object."
	"Function #byteSizeOf: is used by the interpreter, be careful with name  
	     clashes..."
	^ interpreterProxy slotSizeOf: bytesOop
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> bytes: aBytesOop Lshift: shiftCount [ 
	"Attention: this method invalidates all oop's! Only newBytes is valid at    
	       return."
	"Does not normalize."
	| newBytes highBit newLen oldLen |
	oldLen _ self byteSizeOfBytes: aBytesOop.
	(highBit _ self cBytesHighBit: (interpreterProxy firstIndexableField: aBytesOop)
				len: oldLen) = 0 ifTrue: [^ 0 asOop: SmallInteger].
	newLen _ highBit + shiftCount + 7 // 8.
	self remapOop: aBytesOop in: [newBytes _ interpreterProxy instantiateClass: (interpreterProxy fetchClassOf: aBytesOop)
					indexableSize: newLen].
	self
		cBytesLshift: shiftCount
		from: (interpreterProxy firstIndexableField: aBytesOop)
		len: oldLen
		to: (interpreterProxy firstIndexableField: newBytes)
		len: newLen.
	^ newBytes
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> bytes: aBytesOop Rshift: anInteger bytes: b lookfirst: a [ 
	"Attention: this method invalidates all oop's! Only newBytes is valid at    
	  return."
	"Shift right 8*b+anInteger bits, 0<=n<8.         
	Discard all digits beyond a, and all zeroes at or below a."
	"Does not normalize."
	| n x f m digit i oldLen newLen newBytes |
	n _ 0 - anInteger.
	x _ 0.
	f _ n + 8.
	i _ a.
	m _ 255 bitShift: 0 - f.
	digit _ self digitOfBytes: aBytesOop at: i.
	[((digit bitShift: n)
		bitOr: x)
		= 0 and: [i ~= 1]]
		whileTrue: 
			[x _ digit bitShift: f.
			"Can't exceed 8 bits"
			i _ i - 1.
			digit _ self digitOfBytes: aBytesOop at: i].
	i <= b ifTrue: [^ interpreterProxy instantiateClass: (interpreterProxy fetchClassOf: aBytesOop)
			indexableSize: 0"Integer new: 0 neg: self negative"].
	"All bits lost"
	oldLen _ self byteSizeOfBytes: aBytesOop.
	newLen _ i - b.
	self remapOop: aBytesOop in: [newBytes _ interpreterProxy instantiateClass: (interpreterProxy fetchClassOf: aBytesOop)
					indexableSize: newLen].
	"r _ Integer new: i - b neg: self negative."
	"	count _ i.       
	"
	self
		cCoreBytesRshiftCount: i
		n: n
		m: m
		f: f
		bytes: b
		from: (interpreterProxy firstIndexableField: aBytesOop)
		len: oldLen
		to: (interpreterProxy firstIndexableField: newBytes)
		len: newLen.
	^ newBytes
]

{ #category : #'oop util' }
LargeIntegersPlugin >> bytes: aBytesObject growTo: newLen [ 
	"Attention: this method invalidates all oop's! Only newBytes is valid at    
	     return."
	"Does not normalize."
	| newBytes oldLen copyLen |
	self remapOop: aBytesObject in: [newBytes _ interpreterProxy instantiateClass: (interpreterProxy fetchClassOf: aBytesObject)
					indexableSize: newLen].
	oldLen _ self byteSizeOfBytes: aBytesObject.
	oldLen < newLen
		ifTrue: [copyLen _ oldLen]
		ifFalse: [copyLen _ newLen].
	self
		cBytesCopyFrom: (interpreterProxy firstIndexableField: aBytesObject)
		to: (interpreterProxy firstIndexableField: newBytes)
		len: copyLen.
	^ newBytes
]

{ #category : #'oop util' }
LargeIntegersPlugin >> bytesOrInt: oop growTo: len [ 
	"Attention: this method invalidates all oop's! Only newBytes is valid at    
	          return."
	| newBytes val class |
	(interpreterProxy isIntegerObject: oop)
		ifTrue: 
			[val _ interpreterProxy integerValueOf: oop.
			val < 0
				ifTrue: [class _ interpreterProxy classLargeNegativeInteger]
				ifFalse: [class _ interpreterProxy classLargePositiveInteger].
			newBytes _ interpreterProxy instantiateClass: class indexableSize: len.
			self cCopyIntVal: val toBytes: newBytes]
		ifFalse: [newBytes _ self bytes: oop growTo: len].
	^ newBytes
]

{ #category : #'C core' }
LargeIntegersPlugin >> cByteOp: opIndex short: pByteShort len: shortLen long: pByteLong len: longLen into: pByteRes [ 
	"pByteRes len = longLen."
	| limit |
	self var: #pByteShort declareC: 'unsigned char * pByteShort'.
	self var: #pByteLong declareC: 'unsigned char * pByteLong'.
	self var: #pByteRes declareC: 'unsigned char * pByteRes'.
	self var: #shortLen declareC: 'int shortLen'.
	self var: #longLen declareC: 'int longLen'.
	self var: #limit declareC: 'int limit'.
	limit _ shortLen - 1.
	opIndex = andOpIndex
		ifTrue: 
			[0 to: limit do: [:i | pByteRes at: i put: ((pByteShort at: i)
						bitAnd: (pByteLong at: i))].
			limit _ longLen - 1.
			shortLen to: limit do: [:i | pByteRes at: i put: 0].
			^ 0].
	opIndex = orOpIndex
		ifTrue: 
			[0 to: limit do: [:i | pByteRes at: i put: ((pByteShort at: i)
						bitOr: (pByteLong at: i))].
			limit _ longLen - 1.
			shortLen to: limit do: [:i | pByteRes at: i put: (pByteLong at: i)].
			^ 0].
	opIndex = xorOpIndex
		ifTrue: 
			[0 to: limit do: [:i | pByteRes at: i put: ((pByteShort at: i)
						bitXor: (pByteLong at: i))].
			limit _ longLen - 1.
			shortLen to: limit do: [:i | pByteRes at: i put: (pByteLong at: i)].
			^ 0].
	^ interpreterProxy primitiveFail
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cBytesCopyFrom: pFrom to: pTo len: len [ 
	""
	| limit |
	self returnTypeC: 'int'.
	self var: #pFrom declareC: 'unsigned char * pFrom'.
	self var: #pTo declareC: 'unsigned char * pTo'.
	self var: #len declareC: 'int len'.
	self var: #limit declareC: 'int limit'.

	self cCode: '' inSmalltalk: [
		(interpreterProxy isKindOf: InterpreterSimulator) ifTrue: [
			"called from InterpreterSimulator"
				limit _ len - 1.
				0 to: limit do: [:i |
					interpreterProxy byteAt: pTo + i
						put: (interpreterProxy byteAt: pFrom + i)
				].
			^ 0
		].
	].	
	limit _ len - 1.
	0 to: limit do: [:i | pTo at: i put: (pFrom at: i)].
	^ 0
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cBytesHighBit: pByte len: len [ 
	"Answer the index (in bits) of the high order bit of the receiver, or zero if the    
	 receiver is zero. This method is allowed (and needed) for     
	LargeNegativeIntegers as well, since Squeak's LargeIntegers are     
	sign/magnitude."
	| realLength lastDigit |
	self var: #pByte declareC: 'unsigned char *  pByte'.
	realLength _ len.
	[(lastDigit _ pByte at: realLength - 1) = 0]
		whileTrue: [(realLength _ realLength - 1) = 0 ifTrue: [^ 0]].
	^  (self cHighBit: lastDigit) + (8 * (realLength - 1))
]

{ #category : #'C core' }
LargeIntegersPlugin >> cBytesLshift: shiftCount from: pFrom len: lenFrom to: pTo len: lenTo [ 
	"C indexed!"
	| byteShift bitShift carry rShift mask limit digit lastIx |
	self returnTypeC: 'int'.
	self var: #pTo declareC: 'unsigned char * pTo'.
	self var: #pFrom declareC: 'unsigned char * pFrom'.
	self var: #lenFrom declareC: 'int lenFrom'.
	self var: #lenTo declareC: 'int lenTo'.
	byteShift _ shiftCount // 8.
	bitShift _ shiftCount \\ 8.
	bitShift = 0 ifTrue: ["Fast version for byte-aligned shifts"
		"C indexed!"
		^ self
			cBytesReplace: pTo
			from: byteShift
			to: lenTo - 1
			with: pFrom
			startingAt: 0].
	carry _ 0.
	rShift _ bitShift - 8.
	mask _ 255 bitShift: 0 - bitShift.
	limit _ byteShift - 1.
	0 to: limit do: [:i | pTo at: i put: 0].
	limit _ lenTo - byteShift - 2.
	self sqAssert: limit < lenFrom.
	0 to: limit do: 
		[:i | 
		digit _ pFrom at: i.
		pTo at: i + byteShift put: (((digit bitAnd: mask)
				bitShift: bitShift)
				bitOr: carry).
		carry _ digit bitShift: rShift].
	lastIx _ limit + 1.
	lastIx > (lenFrom - 1)
		ifTrue: [digit _ 0]
		ifFalse: [digit _ pFrom at: lastIx].
	pTo at: lastIx + byteShift put: (((digit bitAnd: mask)
			bitShift: bitShift)
			bitOr: carry).
	carry _ digit bitShift: rShift.
	self sqAssert: carry = 0
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cBytesReplace: pTo from: start to: stop with: pFrom startingAt: repStart [ 
	"C indexed!"
	self returnTypeC: 'int'.
	self var: #pTo declareC: 'unsigned char * pTo'.
	self var: #pFrom declareC: 'unsigned char * pFrom'.
	self var: #start declareC: 'int start'.
	self var: #stop declareC: 'int stop'.
	self var: #repStart declareC: 'int repStart'.
	^ self
		cBytesCopyFrom: pFrom + repStart
		to: pTo + start
		len: stop - start + 1
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cCopyIntVal: val toBytes: bytes [ 
	| pByte |
	self var: #pByte declareC: 'unsigned char *  pByte'.
	pByte _ interpreterProxy firstIndexableField: bytes.
	1 to: (self cDigitLengthOfCSI: val)
		do: [:ix | pByte at: ix - 1 put: (self cDigitOfCSI: val at: ix)]
]

{ #category : #'C core' }
LargeIntegersPlugin >> cCoreBytesRshiftCount: count n: n m: m f: f bytes: b from: pFrom len: fromLen to: pTo len: toLen [ 
	| x digit |
	self var: #pTo declareC: 'unsigned char * pTo'.
	self var: #pFrom declareC: 'unsigned char * pFrom'.
	self sqAssert: b < fromLen.
	x _ (pFrom at: b)
				bitShift: n.
	self sqAssert: count - 1 < fromLen.
	b + 1 to: count - 1 do: 
		[:j | 
		digit _ pFrom at: j.
		pTo at: j - b - 1 put: (((digit bitAnd: m)
				bitShift: f)
				bitOr: x).
		"Avoid values > 8 bits"
		x _ digit bitShift: n].
	count = fromLen
				ifTrue: [digit _ 0]
				ifFalse: [digit _ pFrom at: count].
	pTo at: count - b - 1 put: (((digit bitAnd: m)
			bitShift: f)
			bitOr: x)
]

{ #category : #'C core' }
LargeIntegersPlugin >> cCoreDigitDivDiv: pDiv len: divLen rem: pRem len: remLen quo: pQuo len: quoLen [ 
	| dl ql dh dnh j t hi lo r3 l a cond q r1r2 mul |
	self var: #pDiv declareC: 'unsigned char * pDiv'.
	self var: #pRem declareC: 'unsigned char * pRem'.
	self var: #pQuo declareC: 'unsigned char * pQuo'.
	dl _ divLen - 1.
	"Last actual byte of data (ST ix)"
	ql _ quoLen.
	dh _ pDiv at: dl - 1.
	dl = 1
		ifTrue: [dnh _ 0]
		ifFalse: [dnh _ pDiv at: dl - 2].
	1 to: ql do: 
		[:k | 
		"maintain quo*arg+rem=self"
		"Estimate rem/div by dividing the leading two bytes of rem by dh."
		"The estimate is q = qhi*16+qlo, where qhi and qlo are nibbles."
		"Nibbles are kicked off! We use full 16 bits now, because we are in  
		the year 2000 ;-) [sr]"
		j _ remLen + 1 - k.
		"r1 _ rem digitAt: j."
		(pRem at: j - 1)
			= dh
			ifTrue: [q _ 255]
			ifFalse: 
				["Compute q = (r1,r2)//dh, t = (r1,r2)\\dh.                
				Note that r1,r2 are bytes, not nibbles.                
				Be careful not to generate intermediate results exceeding 13  
				            bits."
				"r2 _ (rem digitAt: j - 2)."
				r1r2 _ ((pRem at: j - 1)
							bitShift: 8)
							+ (pRem at: j - 2).
				t _ r1r2 \\ dh.
				q _ r1r2 // dh.
				"Next compute (hi,lo) _ q*dnh"
				mul _ q * dnh.
				hi _ mul bitShift: -8.
				lo _ mul bitAnd: 255.
				"Correct overestimate of q.                
				Max of 2 iterations through loop -- see Knuth vol. 2"
				j < 3
					ifTrue: [r3 _ 0]
					ifFalse: [r3 _ pRem at: j - 3].
				
				[(t < hi
					or: [t = hi and: [r3 < lo]])
					ifTrue: 
						["i.e. (t,r3) < (hi,lo)"
						q _ q - 1.
						lo _ lo - dnh.
						lo < 0
							ifTrue: 
								[hi _ hi - 1.
								lo _ lo + 256].
						cond _ hi >= dh]
					ifFalse: [cond _ false].
				cond]
					whileTrue: [hi _ hi - dh]].
		"Subtract q*div from rem"
		l _ j - dl.
		a _ 0.
		1 to: divLen do: 
			[:i | 
			hi _ (pDiv at: i - 1)
						* (q bitShift: -8).
			lo _ a + (pRem at: l - 1) - ((pDiv at: i - 1)
							* (q bitAnd: 255)).
			"pRem at: l - 1 put: lo - (lo // 256 * 256)."
			"sign-tolerant form of (lo bitAnd: 255) -> obsolete..."
			pRem at: l - 1 put: (lo bitAnd: 255).
			"... is sign-tolerant! [sr]"
			a _ lo // 256 - hi.
			l _ l + 1].
		a < 0
			ifTrue: 
				["Add div back into rem, decrease q by 1"
				q _ q - 1.
				l _ j - dl.
				a _ 0.
				1 to: divLen do: 
					[:i | 
					a _ (a bitShift: -8)
								+ (pRem at: l - 1) + (pDiv at: i - 1).
					pRem at: l - 1 put: (a bitAnd: 255).
					l _ l + 1]].
		pQuo at: quoLen - k put: q]
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitAdd: pByteShort len: shortLen with: pByteLong len: longLen into: pByteRes [ 
	"pByteRes len = longLen; returns over.."
	| accum limit |
	self returnTypeC: 'unsigned char'.
	self var: #pByteShort declareC: 'unsigned char * pByteShort'.
	self var: #pByteLong declareC: 'unsigned char * pByteLong'.
	self var: #pByteRes declareC: 'unsigned char * pByteRes'.
	self var: #shortLen declareC: 'int shortLen'.
	self var: #longLen declareC: 'int longLen'.
	self var: #accum declareC: 'int accum'.
	self var: #limit declareC: 'int limit'.
	accum _ 0.
	limit _ shortLen - 1.
	0 to: limit do: 
		[:i | 
		accum _ (accum bitShift: -8)
					+ (pByteShort at: i) + (pByteLong at: i).
		pByteRes at: i put: (accum bitAnd: 255)].
	limit _ longLen - 1.
	shortLen to: limit do: 
		[:i | 
		accum _ (accum bitShift: -8)
					+ (pByteLong at: i).
		pByteRes at: i put: (accum bitAnd: 255)].
	^ accum bitShift: -8
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitCompare: pFirst with: pSecond len: len [ 
	"Precondition: pFirst len = pSecond len."
	| secondDigit ix firstDigit |
	self var: #pFirst declareC: 'unsigned char * pFirst'.
	self var: #pSecond declareC: 'unsigned char * pSecond'.
	ix _ len - 1.
	[ix >= 0]
		whileTrue: 
			[(secondDigit _ pSecond at: ix) ~= (firstDigit _ pFirst at: ix)
				ifTrue: [secondDigit < firstDigit
						ifTrue: [^ 1]
						ifFalse: [^ -1]].
			ix _ ix - 1].
	^ 0
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cDigitLengthOfCSI: csi [ 
	"Answer the number of indexable fields of a CSmallInteger. This value is 
	   the same as the largest legal subscript."
	self returnTypeC: 'int'.
	self var: #csi declareC: 'int csi'.
	(csi < 256 and: [csi > -256])
		ifTrue: [^ 1].
	(csi < 65536 and: [csi > -65536])
		ifTrue: [^ 2].
	(csi < 16777216 and: [csi > -16777216])
		ifTrue: [^ 3].
	^ 4
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitMultiply: pByteShort len: shortLen with: pByteLong len: longLen into: pByteRes [ 
	"pByteRes len = longLen * shortLen"
	| limitLong digit k carry limitShort ab |
	self returnTypeC: 'unsigned char'.
	self var: #pByteShort declareC: 'unsigned char * pByteShort'.
	self var: #pByteLong declareC: 'unsigned char * pByteLong'.
	self var: #pByteRes declareC: 'unsigned char * pByteRes'.
	self var: #shortLen declareC: 'int shortLen'.
	self var: #longLen declareC: 'int longLen'.
	self var: #carry declareC: 'int carry'.
	self var: #limitLong declareC: 'int limitLong'.
	self var: #limitShort declareC: 'int limitShort'.
	self var: #digit declareC: 'int digit'.
	self var: #ab declareC: 'int ab'.
	self var: #k declareC: 'int k'.
	(shortLen = 1 and: [(pByteShort at: 0)
			= 0])
		ifTrue: [^ 0].
	(longLen = 1 and: [(pByteLong at: 0)
			= 0])
		ifTrue: [^ 0].
	"prod starts out all zero"
	limitShort _ shortLen - 1.
	0 to: limitShort do: [:i | (digit _ pByteShort at: i) ~= 0
			ifTrue: 
				[k _ i.
				carry _ 0.
				"Loop invariant: 0<=carry<=0377, k=i+j-1 (ST)"
				"-> Loop invariant: 0<=carry<=0377, k=i+j (C) (?)"
				limitLong _ longLen - 1.
				0 to: limitLong do: 
					[:j | 
					ab _ (pByteLong at: j)
								* digit + carry + (pByteRes at: k).
					carry _ ab bitShift: -8.
					pByteRes at: k put: (ab bitAnd: 255).
					k _ k + 1].
				pByteRes at: k put: carry]].
	^ 0
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cDigitOfCSI: csi at: ix [ 
	"Answer the value of an indexable field in the receiver.              
	LargePositiveInteger uses bytes of base two number, and each is a       
	      'digit' base 256."
	"ST indexed!"
	ix < 0 ifTrue: [interpreterProxy primitiveFail].
	ix > 4 ifTrue: [^ 0].
	csi < 0
		ifTrue: 
			[self cCode: ''
				inSmalltalk: [csi = -1073741824 ifTrue: ["SmallInteger minVal"
						"Can't negate minVal -- treat specially"
						^ #(0 0 0 64 ) at: ix]].
			^ (0 - csi bitShift: 1 - ix * 8)
				bitAnd: 255]
		ifFalse: [^ (csi bitShift: 1 - ix * 8)
				bitAnd: 255]
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitSub: pByteSmall
		len: smallLen
		with: pByteLarge
		len: largeLen
		into: pByteRes [
	| z limit |
	self var: #pByteSmall declareC: 'unsigned char * pByteSmall'.
	self var: #pByteLarge declareC: 'unsigned char * pByteLarge'.
	self var: #pByteRes declareC: 'unsigned char * pByteRes'.
	self var: #smallLen declareC: 'int smallLen'.
	self var: #largeLen declareC: 'int largeLen'.

	z _ 0.
	"Loop invariant is -1<=z<=1"
	limit _ smallLen - 1.
	0 to: limit do: 
		[:i | 
		z _ z + (pByteLarge at: i) - (pByteSmall at: i).
		pByteRes at: i put: z - (z // 256 * 256).
		"sign-tolerant form of (z bitAnd: 255)"
		z _ z // 256].
	limit _ largeLen - 1.
	smallLen to: limit do: 
		[:i | 
		z _ z + (pByteLarge at: i) .
		pByteRes at: i put: z - (z // 256 * 256).
		"sign-tolerant form of (z bitAnd: 255)"
		z _ z // 256].

]

{ #category : #'C core util' }
LargeIntegersPlugin >> cHighBit: uint [ 
	"Answer the index of the high order bit of the argument, or zero if the  
	argument is zero."
	| shifted bitNo |
	self var: #shifted declareC: 'unsigned int  shifted'.
	shifted _ uint.
	bitNo _ 0.
	[shifted < 16]
		whileFalse: 
			[shifted _ shifted bitShift: -4.
			bitNo _ bitNo + 4].
	[shifted = 0]
		whileFalse: 
			[shifted _ shifted bitShift: -1.
			bitNo _ bitNo + 1].
	^ bitNo
]

{ #category : #'oop util' }
LargeIntegersPlugin >> createLargeFromSmallInteger: anOop [ 
	"anOop has to be a SmallInteger!"
	| val class size res pByte |
	self var: #pByte declareC: 'unsigned char *  pByte'.
	val _ interpreterProxy integerValueOf: anOop.
	val < 0
		ifTrue: [class _ interpreterProxy classLargeNegativeInteger]
		ifFalse: [class _ interpreterProxy classLargePositiveInteger].
	size _ self cDigitLengthOfCSI: val.
	res _ interpreterProxy instantiateClass: class indexableSize: size.
	pByte _ interpreterProxy firstIndexableField: res.
	1 to: size do: [:ix | pByte at: ix - 1 put: (self cDigitOfCSI: val at: ix)].
	^ res
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitAddLarge: firstInteger with: secondInteger [ 
	"Does not need to normalize!"
	| over firstLen secondLen shortInt shortLen longInt longLen sum newSum resClass |
	self var: #over declareC: 'unsigned char  over'.
	firstLen _ self byteSizeOfBytes: firstInteger.
	secondLen _ self byteSizeOfBytes: secondInteger.
	resClass _ interpreterProxy fetchClassOf: firstInteger.
	firstLen <= secondLen
		ifTrue: 
			[shortInt _ firstInteger.
			shortLen _ firstLen.
			longInt _ secondInteger.
			longLen _ secondLen]
		ifFalse: 
			[shortInt _ secondInteger.
			shortLen _ secondLen.
			longInt _ firstInteger.
			longLen _ firstLen].
	"	sum _ Integer new: len neg: firstInteger negative."
	self remapOop: #(shortInt longInt ) in: [sum _ interpreterProxy instantiateClass: resClass indexableSize: longLen].
	over _ self
				cDigitAdd: (interpreterProxy firstIndexableField: shortInt)
				len: shortLen
				with: (interpreterProxy firstIndexableField: longInt)
				len: longLen
				into: (interpreterProxy firstIndexableField: sum).
	over > 0
		ifTrue: 
			["sum _ sum growby: 1."
			interpreterProxy remapOop: sum in: [newSum _ interpreterProxy instantiateClass: resClass indexableSize: longLen + 1].
			self
				cBytesCopyFrom: (interpreterProxy firstIndexableField: sum)
				to: (interpreterProxy firstIndexableField: newSum)
				len: longLen.
			sum _ newSum.
			"C index!"
			(self cCoerce: (interpreterProxy firstIndexableField: sum)
				to: 'unsigned char *')
				at: longLen put: over].
	^ sum
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitBitLogic: firstInteger with: secondInteger opIndex: opIx [ 
	"Bit logic here is only implemented for positive integers or Zero; if rec 
	or arg is negative, it fails."
	| firstLarge secondLarge firstLen secondLen shortLen shortLarge longLen longLarge result |
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: 
			[(interpreterProxy integerValueOf: firstInteger)
				< 0 ifTrue: [^ interpreterProxy primitiveFail].
			"convert it to a not normalized LargeInteger"
			self remapOop: secondInteger in: [firstLarge _ self createLargeFromSmallInteger: firstInteger]]
		ifFalse: 
			[(interpreterProxy fetchClassOf: firstInteger)
				= interpreterProxy classLargeNegativeInteger ifTrue: [^ interpreterProxy primitiveFail].
			firstLarge _ firstInteger].
	(interpreterProxy isIntegerObject: secondInteger)
		ifTrue: 
			[(interpreterProxy integerValueOf: secondInteger)
				< 0 ifTrue: [^ interpreterProxy primitiveFail].
			"convert it to a not normalized LargeInteger"
			self remapOop: firstLarge in: [secondLarge _ self createLargeFromSmallInteger: secondInteger]]
		ifFalse: 
			[(interpreterProxy fetchClassOf: secondInteger)
				= interpreterProxy classLargeNegativeInteger ifTrue: [^ interpreterProxy primitiveFail].
			secondLarge _ secondInteger].
	firstLen _ self byteSizeOfBytes: firstLarge.
	secondLen _ self byteSizeOfBytes: secondLarge.
	firstLen < secondLen
		ifTrue: 
			[shortLen _ firstLen.
			shortLarge _ firstLarge.
			longLen _ secondLen.
			longLarge _ secondLarge]
		ifFalse: 
			[shortLen _ secondLen.
			shortLarge _ secondLarge.
			longLen _ firstLen.
			longLarge _ firstLarge].
	self remapOop: #(shortLarge longLarge ) in: [result _ interpreterProxy instantiateClass: interpreterProxy classLargePositiveInteger indexableSize: longLen].
	self
		cByteOp: opIx
		short: (interpreterProxy firstIndexableField: shortLarge)
		len: shortLen
		long: (interpreterProxy firstIndexableField: longLarge)
		len: longLen
		into: (interpreterProxy firstIndexableField: result).
	interpreterProxy failed ifTrue: [^ 0].
	^ self normalizePositive: result
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitCompareLarge: firstInteger with: secondInteger [ 
	"Compare the magnitude of firstInteger with that of secondInteger.      
	Return a code of 1, 0, -1 for firstInteger >, = , < secondInteger"
	| firstLen secondLen |
	firstLen _ self byteSizeOfBytes: firstInteger.
	secondLen _ self byteSizeOfBytes: secondInteger.
	secondLen ~= firstLen
		ifTrue: [secondLen > firstLen
				ifTrue: [^ -1 asOop: SmallInteger]
				ifFalse: [^ 1 asOop: SmallInteger]].
	^ (self
		cDigitCompare: (interpreterProxy firstIndexableField: firstInteger)
		with: (interpreterProxy firstIndexableField: secondInteger)
		len: firstLen)
		asOop: SmallInteger
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitDivLarge: firstInteger with: secondInteger negative: neg [ 
	"Does not normalize."
	"Division by zero has to be checked in caller."
	| firstLen secondLen resultClass l d div rem quo result |
	firstLen _ self byteSizeOfBytes: firstInteger.
	secondLen _ self byteSizeOfBytes: secondInteger.
	neg
		ifTrue: [resultClass _ interpreterProxy classLargeNegativeInteger]
		ifFalse: [resultClass _ interpreterProxy classLargePositiveInteger].
	l _ firstLen - secondLen + 1.
	l <= 0
		ifTrue: 
			[self remapOop: firstInteger in: [result _ interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: 2].
			result stAt: 1 put: (0 asOop: SmallInteger).
			result stAt: 2 put: firstInteger.
			^ result].
	"set rem and div to copies of firstInteger and secondInteger, respectively. 
	  However,  
	 to facilitate use of Knuth's algorithm, multiply rem and div by 2 (that 
	 is, shift)   
	 until the high byte of div is >=128"
	d _ 8 - (self cHighBit: (self unsafeByteOf: secondInteger at: secondLen)).
	self remapOop: firstInteger
		in: 
			[div _ self bytes: secondInteger Lshift: d.
			div _ self bytesOrInt: div growTo: (self digitLength: div)
							+ 1].
	self remapOop: div
		in: 
			[rem _ self bytes: firstInteger Lshift: d.
			(self digitLength: rem)
				= firstLen ifTrue: [rem _ self bytesOrInt: rem growTo: firstLen + 1]].
	self remapOop: #(div rem ) in: [quo _ interpreterProxy instantiateClass: resultClass indexableSize: l].
	self
		cCoreDigitDivDiv: (interpreterProxy firstIndexableField: div)
		len: (self digitLength: div)
		rem: (interpreterProxy firstIndexableField: rem)
		len: (self digitLength: rem)
		quo: (interpreterProxy firstIndexableField: quo)
		len: (self digitLength: quo).
	self remapOop: #(quo ) in: [rem _ self
					bytes: rem
					Rshift: d
					bytes: 0
					lookfirst: (self digitLength: div)
							- 1].
	"^ Array with: quo with: rem"
	self remapOop: #(quo rem ) in: [result _ interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: 2].
	result stAt: 1 put: quo.
	result stAt: 2 put: rem.
	^ result
]

{ #category : #util }
LargeIntegersPlugin >> digitLength: oop [ 
	(interpreterProxy isIntegerObject: oop)
		ifTrue: [^ self cDigitLengthOfCSI: (interpreterProxy integerValueOf: oop)]
		ifFalse: [^ self byteSizeOfBytes: oop]
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitMultiplyLarge: firstInteger with: secondInteger negative: neg [ 
	"Normalizes."
	| firstLen secondLen shortInt shortLen longInt longLen prod resultClass |
	firstLen _ self byteSizeOfBytes: firstInteger.
	secondLen _ self byteSizeOfBytes: secondInteger.
	firstLen <= secondLen
		ifTrue: 
			[shortInt _ firstInteger.
			shortLen _ firstLen.
			longInt _ secondInteger.
			longLen _ secondLen]
		ifFalse: 
			[shortInt _ secondInteger.
			shortLen _ secondLen.
			longInt _ firstInteger.
			longLen _ firstLen].
	neg
		ifTrue: [resultClass _ interpreterProxy classLargeNegativeInteger]
		ifFalse: [resultClass _ interpreterProxy classLargePositiveInteger].
	self remapOop: #(shortInt longInt ) in: [prod _ interpreterProxy instantiateClass: resultClass indexableSize: longLen + shortLen].
	self
		cDigitMultiply: (interpreterProxy firstIndexableField: shortInt)
		len: shortLen
		with: (interpreterProxy firstIndexableField: longInt)
		len: longLen
		into: (interpreterProxy firstIndexableField: prod).
	^ self normalize: prod
]

{ #category : #util }
LargeIntegersPlugin >> digitOf: oop at: ix [ 
	(interpreterProxy isIntegerObject: oop)
		ifTrue: [^ self cDigitOfCSI: (interpreterProxy integerValueOf: oop)
				at: ix]
		ifFalse: [^ self digitOfBytes: oop at: ix]
]

{ #category : #util }
LargeIntegersPlugin >> digitOfBytes: aBytesOop at: ix [ 
	"Argument has to be aLargeInteger!"
	ix > (self byteSizeOfBytes: aBytesOop)
		ifTrue: [^ 0]
		ifFalse: [^ self unsafeByteOf: aBytesOop at: ix]
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitSubLarge: firstInteger with: secondInteger [ 
	"Normalizes."
	| firstLen secondLen class larger largerLen smaller smallerLen neg resLen res firstNeg |
	firstNeg _ (interpreterProxy fetchClassOf: firstInteger)
				= interpreterProxy classLargeNegativeInteger.
	firstLen _ self byteSizeOfBytes: firstInteger.
	secondLen _ self byteSizeOfBytes: secondInteger.
	firstLen = secondLen
		ifTrue: 
			[[(self digitOfBytes: firstInteger at: firstLen)
				= (self digitOfBytes: secondInteger at: firstLen) and: [firstLen > 1]]
				whileTrue: [firstLen _ firstLen - 1].
			secondLen _ firstLen].
	(firstLen < secondLen
		or: [firstLen = secondLen and: [(self digitOfBytes: firstInteger at: firstLen)
					< (self digitOfBytes: secondInteger at: firstLen)]])
		ifTrue: 
			[larger _ secondInteger.
			largerLen _ secondLen.
			smaller _ firstInteger.
			smallerLen _ firstLen.
			neg _ firstNeg == false]
		ifFalse: 
			[larger _ firstInteger.
			largerLen _ firstLen.
			smaller _ secondInteger.
			smallerLen _ secondLen.
			neg _ firstNeg].
	resLen _ largerLen.
	neg
		ifTrue: [class _ interpreterProxy classLargeNegativeInteger]
		ifFalse: [class _ interpreterProxy classLargePositiveInteger].
	self remapOop: #(smaller larger ) in: [res _ interpreterProxy instantiateClass: class indexableSize: resLen].
	self
		cDigitSub: (interpreterProxy firstIndexableField: smaller)
		len: smallerLen
		with: (interpreterProxy firstIndexableField: larger)
		len: largerLen
		into: (interpreterProxy firstIndexableField: res).
	^ self normalize: res
]

{ #category : #util }
LargeIntegersPlugin >> highBitOfBytes: aBytesOop [ 
	^ self cBytesHighBit: (interpreterProxy firstIndexableField: aBytesOop)
		len: (self byteSizeOfBytes: aBytesOop)
]

{ #category : #'ST initialize' }
LargeIntegersPlugin >> initialize [
	"Initializes ST constants; C's are set by class>>declareCVarsIn:."
	self returnTypeC: 'void'.
	self cCode: '"nothing to do here"'
		inSmalltalk: 
			[andOpIndex _ 0.
			orOpIndex _ 1.
			xorOpIndex _ 2]
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> isNormalized: anInteger [ 
	| len maxVal minVal sLen |
	(interpreterProxy isIntegerObject: anInteger)
		ifTrue: [^ true].
	"Check for leading zero of LargeInteger"
	len := self digitLength: anInteger.
	len = 0
		ifTrue: [^ false].
	(self unsafeByteOf: anInteger at: len)
			= 0
		ifTrue: [^ false].
	"no leading zero, now check if anInteger is in SmallInteger range or not"
	sLen := 4.
	"maximal digitLength of aSmallInteger"
	len > sLen
		ifTrue: [^ true].
	len < sLen
		ifTrue: [^ false].
	"len = sLen"
	(interpreterProxy fetchClassOf: anInteger)
			= interpreterProxy classLargePositiveInteger
		ifTrue: [maxVal := 1073741823. "SmallInteger maxVal"
				"all bytes of maxVal but the highest one are just FF's"
				^ (self unsafeByteOf: anInteger at: sLen)
					> (self cDigitOfCSI: maxVal at: sLen)]
		ifFalse: [minVal := -1073741824. "SmallInteger minVal"
				"all bytes of minVal but the highest one are just 00's"
			(self unsafeByteOf: anInteger at: sLen)
					< (self cDigitOfCSI: minVal at: sLen)
				ifTrue: [^ false]
				ifFalse: ["if just one digit differs, then anInteger < minval (the corresponding digit byte is greater!)
						and therefore a LargeNegativeInteger"
					1
						to: sLen
						do: [:ix | (self unsafeByteOf: anInteger at: ix)
									= (self cDigitOfCSI: minVal at: ix)
								ifFalse: [^ true]]]].
	^ false
]

{ #category : #util }
LargeIntegersPlugin >> negative: aLarge [ 
	^ (interpreterProxy fetchClassOf: aLarge)
		= interpreterProxy classLargeNegativeInteger
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> normalize: aLargeInteger [ 
	"Check for leading zeroes and return shortened copy if so."
	self debugCode: [self msg: 'normalize: aLargeInteger'].
	(interpreterProxy fetchClassOf: aLargeInteger)
		= interpreterProxy classLargePositiveInteger
		ifTrue: [^ self normalizePositive: aLargeInteger]
		ifFalse: [^ self normalizeNegative: aLargeInteger]
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> normalizeNegative: aLargeNegativeInteger [ 
	"Check for leading zeroes and return shortened copy if so"
	"First establish len = significant length"
	| sLen val len oldLen minVal |
	len _ oldLen _ self digitLength: aLargeNegativeInteger.
	[len ~= 0 and: [(self unsafeByteOf: aLargeNegativeInteger at: len)
			= 0]]
		whileTrue: [len _ len - 1].
	len = 0 ifTrue: [^ 0 asOop: SmallInteger].
	"Now check if in SmallInteger range"
	sLen _ 4.
	"SmallInteger minVal digitLength"
	len <= sLen
		ifTrue: 
			["SmallInteger minVal"
			minVal _ -1073741824.
			(len < sLen or: [(self digitOfBytes: aLargeNegativeInteger at: sLen)
					< (self cDigitOfCSI: minVal at: sLen)
				"minVal lastDigit"])
				ifTrue: 
					["If high digit less, then can be small"
					val _ 0.
					len
						to: 1
						by: -1
						do: [:i | val _ val * 256 - (self unsafeByteOf: aLargeNegativeInteger at: i)].
					^ val asOop: SmallInteger].
			1 to: sLen do: [:i | "If all digits same, then = minVal (sr: minVal digits 1 to 3 are 
				          0)"
				(self digitOfBytes: aLargeNegativeInteger at: i)
					= (self cDigitOfCSI: minVal at: i)
					ifFalse: ["Not so; return self shortened"
						len < oldLen
							ifTrue: ["^ self growto: len"
								^ self bytes: aLargeNegativeInteger growTo: len]
							ifFalse: [^ aLargeNegativeInteger]]].
			^ minVal asOop: SmallInteger].
	"Return self, or a shortened copy"
	len < oldLen
		ifTrue: ["^ self growto: len"
			^ self bytes: aLargeNegativeInteger growTo: len]
		ifFalse: [^ aLargeNegativeInteger]
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> normalizePositive: aLargePositiveInteger [ 
	"Check for leading zeroes and return shortened copy if so"
	"First establish len = significant length"
	| sLen val len oldLen |
	len _ oldLen _ self digitLength: aLargePositiveInteger.
	[len ~= 0 and: [(self unsafeByteOf: aLargePositiveInteger at: len)
			= 0]]
		whileTrue: [len _ len - 1].
	len = 0 ifTrue: [^ 0 asOop: SmallInteger].
	"Now check if in SmallInteger range"
	sLen _ 4.
	"SmallInteger maxVal digitLength."
	(len <= sLen and: [(self digitOfBytes: aLargePositiveInteger at: sLen)
			<= (self cDigitOfCSI: 1073741823 at: sLen)
		"SmallInteger maxVal"])
		ifTrue: 
			["If so, return its SmallInt value"
			val _ 0.
			len
				to: 1
				by: -1
				do: [:i | val _ val * 256 + (self unsafeByteOf: aLargePositiveInteger at: i)].
			^ val asOop: SmallInteger].
	"Return self, or a shortened copy"
	len < oldLen
		ifTrue: ["^ self growto: len"
			^ self bytes: aLargePositiveInteger growTo: len]
		ifFalse: [^ aLargePositiveInteger]
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primAnyBitFrom: from to: to [ 
	| integer large |
	self debugCode: [self msg: 'primAnyBitFrom: from to: to'].
	integer _ self
				primitive: 'primAnyBitFromTo'
				parameters: #(#SmallInteger #SmallInteger )
				receiver: #Integer.
	(interpreterProxy isIntegerObject: integer)
		ifTrue: ["convert it to a not normalized LargeInteger"
			large _ self createLargeFromSmallInteger: integer]
		ifFalse: [large _ integer].
	^ (self
		anyBitOfBytes: large
		from: from
		to: to)
		asOop: Boolean
]

{ #category : #'control & support primitives' }
LargeIntegersPlugin >> primAsLargeInteger: anInteger [
	"Converts a SmallInteger into a - non normalized! - LargeInteger;          
	 aLargeInteger will be returned unchanged."
	"Do not check for forced fail, because we need this conversion to test the 
	plugin in ST during forced fail, too."
	self debugCode: [self msg: 'primAsLargeInteger: anInteger'].
	self
		primitive: 'primAsLargeInteger'
		parameters: #(Integer )
		receiver: #Oop.
	(interpreterProxy isIntegerObject: anInteger)
		ifTrue: [^ self createLargeFromSmallInteger: anInteger]
		ifFalse: [^ anInteger]
]

{ #category : #'control & support primitives' }
LargeIntegersPlugin >> primCheckIfCModuleExists [
	"If calling this primitive fails, then C module does not exist. Do not check for forced fail, because we want to know if module exists during forced fail, too."
	self
		primitive: 'primCheckIfCModuleExists'
		parameters: #()
		receiver: #Oop.
	^ true asOop: Boolean
]

{ #category : #'development primitives' }
LargeIntegersPlugin >> primDigit: anInteger bitShift: shiftCount [ 
	| rShift aLarge |
	self debugCode: [self msg: 'primDigit: anInteger bitShift: shiftCount'].
	self
		primitive: '_primDigitBitShift'
		parameters: #(Integer SmallInteger )
		receiver: #Oop.
	(interpreterProxy isIntegerObject: anInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			aLarge _ self createLargeFromSmallInteger: anInteger]
		ifFalse: [aLarge _ anInteger].
	shiftCount >= 0
		ifTrue: [^ self bytes: aLarge Lshift: shiftCount]
		ifFalse: 
			[rShift _ 0 - shiftCount.
			^ self normalize: (self
					bytes: aLarge
					Rshift: (rShift bitAnd: 7)
					bytes: (rShift bitShift: -3)
					lookfirst: (self byteSizeOfBytes: aLarge))]
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitAdd: secondInteger [ 
	""
	| firstLarge secondLarge firstInteger |
	self debugCode: [self msg: 'primDigitAdd: secondInteger'].
	firstInteger _ self
				primitive: 'primDigitAdd'
				parameters: #(Integer )
				receiver: #Integer.
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: secondInteger in: [firstLarge _ self createLargeFromSmallInteger: firstInteger]]
		ifFalse: [firstLarge _ firstInteger].
	(interpreterProxy isIntegerObject: secondInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: firstLarge in: [secondLarge _ self createLargeFromSmallInteger: secondInteger]]
		ifFalse: [secondLarge _ secondInteger].
	^ self digitAddLarge: firstLarge with: secondLarge
]

{ #category : #'development primitives' }
LargeIntegersPlugin >> primDigitAdd: firstInteger with: secondInteger [ 
	""
	| firstLarge secondLarge |
	self debugCode: [self msg: 'primDigitAdd: firstInteger with: secondInteger'].
	self
		primitive: 'primDigitAddWith'
		parameters: #(Integer Integer )
		receiver: #Oop.
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: secondInteger in: [firstLarge _ self createLargeFromSmallInteger: firstInteger]]
		ifFalse: [firstLarge _ firstInteger].
	(interpreterProxy isIntegerObject: secondInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: firstLarge in: [secondLarge _ self createLargeFromSmallInteger: secondInteger]]
		ifFalse: [secondLarge _ secondInteger].
	^ self digitAddLarge: firstLarge with: secondLarge
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitBitAnd: secondInteger [ 
	"Bit logic here is only implemented for positive integers or Zero; if rec 
	or arg is negative, it fails."
	| firstInteger |
	self debugCode: [self msg: 'primDigitBitAnd: secondInteger'].
	firstInteger _ self
				primitive: 'primDigitBitAnd'
				parameters: #(Integer )
				receiver: #Integer.
	^ self
		digitBitLogic: firstInteger
		with: secondInteger
		opIndex: andOpIndex
]

{ #category : #'development primitives' }
LargeIntegersPlugin >> primDigitBitLogic: firstInteger with: secondInteger op: opIndex [ 
	"Bit logic here is only implemented for positive integers or Zero; if any arg is negative, it fails."
	self debugCode: [self msg: 'primDigitBitLogic: firstInteger with: secondInteger op: opIndex'].
	self
		primitive: 'primDigitBitLogicWithOp'
		parameters: #(Integer Integer SmallInteger )
		receiver: #Oop.
	^ self
		digitBitLogic: firstInteger
		with: secondInteger
		opIndex: opIndex
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitBitOr: secondInteger [ 
	"Bit logic here is only implemented for positive integers or Zero; if rec 
	or arg is negative, it fails."
	| firstInteger |
	self debugCode: [self msg: 'primDigitBitOr: secondInteger'].
	firstInteger _ self
				primitive: 'primDigitBitOr'
				parameters: #(Integer )
				receiver: #Integer.
	^ self
		digitBitLogic: firstInteger
		with: secondInteger
		opIndex: orOpIndex
]

{ #category : #obsolete }
LargeIntegersPlugin >> primDigitBitShift: shiftCount [ 
	| rShift aLarge anInteger |
	self debugCode: [self msg: 'primDigitBitShift: shiftCount'].
	anInteger _ self
				primitive: 'primDigitBitShift'
				parameters: #(SmallInteger )
				receiver: #Integer.
	(interpreterProxy isIntegerObject: anInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			aLarge _ self createLargeFromSmallInteger: anInteger]
		ifFalse: [aLarge _ anInteger].
	shiftCount >= 0
		ifTrue: [^ self bytes: aLarge Lshift: shiftCount]
		ifFalse: 
			[rShift _ 0 - shiftCount.
			^ self normalize: (self
					bytes: aLarge
					Rshift: (rShift bitAnd: 7)
					bytes: (rShift bitShift: -3)
					lookfirst: (self byteSizeOfBytes: aLarge))]
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitBitShiftMagnitude: shiftCount [ 
	| rShift aLarge anInteger |
	self debugCode: [self msg: 'primDigitBitShiftMagnitude: shiftCount'].
	anInteger _ self
				primitive: 'primDigitBitShiftMagnitude'
				parameters: #(#SmallInteger )
				receiver: #Integer.
	(interpreterProxy isIntegerObject: anInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			aLarge _ self createLargeFromSmallInteger: anInteger]
		ifFalse: [aLarge _ anInteger].
	shiftCount >= 0
		ifTrue: [^ self bytes: aLarge Lshift: shiftCount]
		ifFalse: 
			[rShift _ 0 - shiftCount.
			^ self normalize: (self
					bytes: aLarge
					Rshift: (rShift bitAnd: 7)
					bytes: (rShift bitShift: -3)
					lookfirst: (self byteSizeOfBytes: aLarge))]
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitBitXor: secondInteger [ 
	"Bit logic here is only implemented for positive integers or Zero; if rec 
	or arg is negative, it fails."
	| firstInteger |
	self debugCode: [self msg: 'primDigitBitXor: secondInteger'].
	firstInteger _ self
				primitive: 'primDigitBitXor'
				parameters: #(Integer )
				receiver: #Integer.
	^ self
		digitBitLogic: firstInteger
		with: secondInteger
		opIndex: xorOpIndex
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitCompare: secondInteger [ 
	| firstVal secondVal firstInteger |
	self debugCode: [self msg: 'primDigitCompare: secondInteger'].
	firstInteger _ self
		primitive: 'primDigitCompare'
		parameters: #(Integer  )
		receiver: #Integer.
	"shortcut: aSmallInteger has to be smaller in Magnitude as aLargeInteger"
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: ["first"
			(interpreterProxy isIntegerObject: secondInteger)
				ifTrue: ["second"
					(firstVal _ interpreterProxy integerValueOf: firstInteger) > (secondVal _ interpreterProxy integerValueOf: secondInteger)
						ifTrue: [^ 1 asOop: SmallInteger"first > second"]
						ifFalse: [firstVal < secondVal
								ifTrue: [^ -1 asOop: SmallInteger"first < second"]
								ifFalse: [^ 0 asOop: SmallInteger"first = second"]]]
				ifFalse: ["SECOND"
					^ -1 asOop: SmallInteger"first < SECOND"]]
		ifFalse: ["FIRST"
			(interpreterProxy isIntegerObject: secondInteger)
				ifTrue: ["second"
					^ 1 asOop: SmallInteger"FIRST > second"]
				ifFalse: ["SECOND"
					^ self digitCompareLarge: firstInteger with: secondInteger]]
]

{ #category : #'development primitives' }
LargeIntegersPlugin >> primDigitCompare: firstInteger with: secondInteger [ 
	| firstVal secondVal |
	self debugCode: [self msg: 'primDigitCompare: firstInteger with: secondInteger'].
	self
		primitive: 'primDigitCompareWith'
		parameters: #(Integer Integer )
		receiver: #Oop.
	"shortcut: aSmallInteger has to be smaller in Magnitude as aLargeInteger"
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: ["first"
			(interpreterProxy isIntegerObject: secondInteger)
				ifTrue: ["second"
					(firstVal _ interpreterProxy integerValueOf: firstInteger) > (secondVal _ interpreterProxy integerValueOf: secondInteger)
						ifTrue: [^ 1 asOop: SmallInteger"first > second"]
						ifFalse: [firstVal < secondVal
								ifTrue: [^ -1 asOop: SmallInteger"first < second"]
								ifFalse: [^ 0 asOop: SmallInteger"first = second"]]]
				ifFalse: ["SECOND" ^ -1 asOop: SmallInteger"first < SECOND"]]
		ifFalse: ["FIRST"
			(interpreterProxy isIntegerObject: secondInteger)
				ifTrue: ["second" ^ 1 asOop: SmallInteger"FIRST > second"]
				ifFalse: ["SECOND"
					^ self digitCompareLarge: firstInteger with: secondInteger]]
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitDiv: secondInteger negative: neg [ 
	"Answer the result of dividing firstInteger by secondInteger.
	Fail if parameters are not integers, not normalized or secondInteger is zero."
	| firstAsLargeInteger secondAsLargeInteger firstInteger |
	self
		debugCode: [self msg: 'primDigitDiv: secondInteger negative: neg'].
	firstInteger := self
				primitive: 'primDigitDivNegative'
				parameters: #(#Integer #Boolean )
				receiver: #Integer.

	"Avoid crashes in case of getting unnormalized args."
	(self isNormalized: firstInteger)
		ifFalse: [self msg: 'ERROR in primDigitDiv: secondInteger negative: neg'.
			self msg: '------> receiver *not* normalized!'.
			^ interpreterProxy primitiveFail].
	(self isNormalized: secondInteger)
		ifFalse: [self msg: 'ERROR in primDigitDiv: secondInteger negative: neg'.
			self msg: '------> argument *not* normalized!'.
			^ interpreterProxy primitiveFail].
		
	"Coerce SmallIntegers to corresponding (not normalized) large integers  
	and check for zerodivide."
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: ["convert to LargeInteger"
			self
				remapOop: secondInteger
				in: [firstAsLargeInteger := self createLargeFromSmallInteger: firstInteger]]
		ifFalse: [firstAsLargeInteger := firstInteger].
		
	(interpreterProxy isIntegerObject: secondInteger)
		ifTrue: ["check for zerodivide and convert to LargeInteger"
			(interpreterProxy integerValueOf: secondInteger)
					= 0
				ifTrue: [^ interpreterProxy primitiveFail].
			self
				remapOop: firstAsLargeInteger
				in: [secondAsLargeInteger := self createLargeFromSmallInteger: secondInteger]]
		ifFalse: [secondAsLargeInteger := secondInteger].
	^ self
		digitDivLarge: firstAsLargeInteger
		with: secondAsLargeInteger
		negative: neg
]

{ #category : #'development primitives' }
LargeIntegersPlugin >> primDigitDiv: firstInteger with: secondInteger negative: neg [ 
	"Answer the result of dividing firstInteger by secondInteger.  Fail if     
	parameters are not integers or secondInteger is zero."
	| firstAsLargeInteger secondAsLargeInteger |
	self debugCode: [self msg: 'primDigitDiv: firstInteger with: secondInteger negative: neg'].
	self
		primitive: 'primDigitDivWithNegative'
		parameters: #(Integer Integer Boolean )
		receiver: #Oop.
	"Coerce SmallIntegers to corresponding (not normalized) large integers    
	 and check for zerodivide."
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: ["convert to LargeInteger"
			self remapOop: secondInteger in: [firstAsLargeInteger _ self createLargeFromSmallInteger: firstInteger]]
		ifFalse: [firstAsLargeInteger _ firstInteger].
	(interpreterProxy isIntegerObject: secondInteger)
		ifTrue: 
			["check for zerodivide and convert to LargeInteger"
			(interpreterProxy integerValueOf: secondInteger)
				= 0 ifTrue: [^ interpreterProxy primitiveFail].
			self remapOop: firstAsLargeInteger in: [secondAsLargeInteger _ self createLargeFromSmallInteger: secondInteger]]
		ifFalse: [secondAsLargeInteger _ secondInteger].
	^ self
		digitDivLarge: firstAsLargeInteger
		with: secondAsLargeInteger
		negative: neg
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitMultiply: secondInteger negative: neg [ 
	""
	| firstLarge secondLarge firstInteger |
	self debugCode: [self msg: 'primDigitMultiply: secondInteger negative: neg'].
	firstInteger _ self
		primitive: 'primDigitMultiplyNegative'
		parameters: #( Integer Boolean )
		receiver: #Integer.
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: secondInteger in: [firstLarge _ self createLargeFromSmallInteger: firstInteger]]
		ifFalse: [firstLarge _ firstInteger].
	(interpreterProxy isIntegerObject: secondInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: firstLarge in: [secondLarge _ self createLargeFromSmallInteger: secondInteger]]
		ifFalse: [secondLarge _ secondInteger].
	^ self
		digitMultiplyLarge: firstLarge
		with: secondLarge
		negative: neg
]

{ #category : #'development primitives' }
LargeIntegersPlugin >> primDigitMultiply: firstInteger with: secondInteger negative: neg [
	""
	| firstLarge secondLarge |
	self debugCode: [self msg: 'primDigitMultiply: firstInteger with: secondInteger negative: neg'].
	self
		primitive: 'primDigitMultiplyWithNegative'
		parameters: #(Integer Integer Boolean )
		receiver: #Oop.
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: secondInteger in: [firstLarge _ self createLargeFromSmallInteger: firstInteger]]
		ifFalse: [firstLarge _ firstInteger].
	(interpreterProxy isIntegerObject: secondInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: firstLarge in: [secondLarge _ self createLargeFromSmallInteger: secondInteger]]
		ifFalse: [secondLarge _ secondInteger].
	^ self
		digitMultiplyLarge: firstLarge
		with: secondLarge
		negative: neg
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitSubtract: secondInteger [ 
	""
	| firstLarge secondLarge firstInteger |
	self debugCode: [self msg: 'primDigitSubtract: secondInteger'].
	firstInteger _ self
		primitive: 'primDigitSubtract'
		parameters: #( Integer )
		receiver: #Integer.
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: secondInteger in: [firstLarge _ self createLargeFromSmallInteger: firstInteger]]
		ifFalse: [firstLarge _ firstInteger].
	(interpreterProxy isIntegerObject: secondInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: firstLarge in: [secondLarge _ self createLargeFromSmallInteger: secondInteger]]
		ifFalse: [secondLarge _ secondInteger].
	^ self digitSubLarge: firstLarge with: secondLarge
]

{ #category : #'development primitives' }
LargeIntegersPlugin >> primDigitSubtract: firstInteger with: secondInteger [
	""
	| firstLarge secondLarge |
	self debugCode: [self msg: 'primDigitSubtract: firstInteger with: secondInteger'].
	self
		primitive: 'primDigitSubtractWith'
		parameters: #(Integer Integer )
		receiver: #Oop.
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: secondInteger in: [firstLarge _ self createLargeFromSmallInteger: firstInteger]]
		ifFalse: [firstLarge _ firstInteger].
	(interpreterProxy isIntegerObject: secondInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: firstLarge in: [secondLarge _ self createLargeFromSmallInteger: secondInteger]]
		ifFalse: [secondLarge _ secondInteger].
	^ self digitSubLarge: firstLarge with: secondLarge
]

{ #category : #'control & support primitives' }
LargeIntegersPlugin >> primGetModuleName [
	"If calling this primitive fails, then C module does not exist."
	| strLen strOop strPtr |
	self var: #cString declareC: 'char *cString'.
	self var: #strPtr declareC: 'char *strPtr'.
	self debugCode: [self msg: 'primGetModuleName'].
	self
		primitive: 'primGetModuleName'
		parameters: #()
		receiver: #Oop.
	strLen _ self strlen: self getModuleName.
	strOop _ interpreterProxy instantiateClass: interpreterProxy classString indexableSize: strLen.
	strPtr _ interpreterProxy firstIndexableField: strOop.
	0 to: strLen - 1 do: [:i | strPtr at: i put: (self getModuleName at: i)].
	^ strOop
]

{ #category : #'development primitives' }
LargeIntegersPlugin >> primNormalize: anInteger [ 
"Parameter specification #(Integer) doesn't convert!"
	self debugCode: [self msg: 'primNormalize: anInteger'].
	self
		primitive: 'primNormalize'
		parameters: #(Integer )
		receiver: #Oop.
	(interpreterProxy isIntegerObject: anInteger)
		ifTrue: [^ anInteger].
	^ self normalize: anInteger
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primNormalizeNegative [
	""
	| rcvr |
	self debugCode: [self msg: 'primNormalizeNegative'].
	rcvr _ self
				primitive: 'primNormalizeNegative'
				parameters: #()
				receiver: #LargeNegativeInteger.
	^ self normalizeNegative: rcvr
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primNormalizePositive [
	| rcvr |
	""
	self debugCode: [self msg: 'primNormalizePositive'].
	rcvr _ self
		primitive: 'primNormalizePositive'
		parameters: #()
		receiver: #LargePositiveInteger.
	^ self normalizePositive: rcvr
]

{ #category : #debugging }
LargeIntegersPlugin >> think [
	"Flag for marking methods for later thinking."
	^ self msg: '#think should not be called'
]

{ #category : #util }
LargeIntegersPlugin >> unsafeByteOf: bytesOop at: ix [ 
"Argument bytesOop must not be aSmallInteger!"
	^ interpreterProxy integerValueOf: (interpreterProxy stObject: bytesOop at: ix)
]
