"
LargeIntegersPlugin provides functions for speeding up LargeInteger arithmetics. Usually it is part of your installation as 'LargeIntegers' plugin (a C-compiled binary).


Correctly installed?
----------------------
Probably you are just working with it.

To be really sure try
	100 factorial. ""to force plugin loading""
	SmalltalkImage current listLoadedModules.
Then you should see 'LargeIntegers' somewhere in the output strings. If this should not be the case, you probably have a problem.


Variables
-----------

Inst vars:
	andOpIndex			C constant
	orOpIndex			C constant
	xorOpIndex 			C constant
Used like an enum, in ST one would use symbols instead.

Class vars:
	none


History
--------

v2.0

Rewrite primitives to use 32-bits digits instead of 8-bits digits. This can fasten many operation up to 2x and multiplication up to 7x.
Since Large Integers are still variable byte object, care is taken to allocate just enough bytes to contain integer value (not necessarily a multiple of 4 bytes).
Primitives will use the extra bytes beyond necessary bytes up to next multiple of 4, so it's mandatory that those extra bytes be correctly set to zero
At image side, digits are still 8-bits so that fallback code involve only SmallInteger.

Primitives assume that byte ordering (endianness) is allways little endian, because LargeIntegers remain regular byte Objects.
On (hypothetic) big endian machines, conversion is performed at fetch/store time thru usage of dedicated macro.

v1.5

- no code change at all compared to v1.4
- made to outsource testing code (LargeIntegersPluginTest) introduced in earlier versions
- updated class comment: reference to LargeIntegersPluginTest removed

v1.4

- no semantic change compared to v1.3
- >>cHighBit: improved (could be faster now)
- fix: class comment
- improved class comment
- >>flag: introduced to allow #flag: messages (does nothing)
- new: class>>buildCodeGeneratorUpTo: as hook for switching debugMode (default is not to change anything)
- removed: class>>new (obsolete)
- minor cleanup of source code layout

v1.3

- fix: >>primDigitDiv:negative: now checks if its Integer args are normalized; without this change the plugin crashes, if a division by zero through a non normalized - filled with zero bytes - arg occurs. This can happen through printing by the inspector windows after changing the bytes of a LargeInteger manually.

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
	#category : #'VMMaker-Plugins'
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

	^ self moduleName, ' ', self version
]

{ #category : #translation }
LargeIntegersPlugin class >> version [
	"Answer the receiver's version info as String."

	^ 'v2.0'
]

{ #category : #util }
LargeIntegersPlugin >> anyBitOfLargeInt: anOop from: start to: stopArg [ 
	"Argument has to be a Large Integer!"
	"Tests for any magnitude bits in the interval from start to stopArg."
	| magnitude stop firstDigitIx lastDigitIx firstMask lastMask |
	<var: #digit type: #'unsigned int'>
	<var: #firstMask type: #'unsigned int'>
	<var: #lastMask type: #'unsigned int'>
	<var: #firstDigitIx type: #usqInt>
	<var: #lastDigitIx type: #usqInt>
	<var: #ix type: #usqInt>
	self
		debugCode: [self msg: 'anyBitOfLargeInt: anOop from: start to: stopArg'].
	start < 1 | (stopArg < 1)
		ifTrue: [^ interpreterProxy primitiveFail].
	magnitude := anOop.
	stop := stopArg min: (self highBitOfLargeInt: magnitude).
	start > stop
		ifTrue: [^ false].
	firstDigitIx := start - 1 // 32 + 1.
	lastDigitIx := stop - 1 // 32 + 1.
	firstMask := 16rFFFFFFFF asUnsignedLong << (start - 1 bitAnd: 31). "Note asUnsignedLong required to avoid ULLL suffix bug"
	lastMask := 16rFFFFFFFF >> (31 - (stop - 1 bitAnd: 31)).
	firstDigitIx = lastDigitIx
		ifTrue: [| digit | 
			digit := self unsafeDigitOfLargeInt: magnitude at: firstDigitIx.
			^ (digit bitAnd: (firstMask bitAnd: lastMask))
				~= 0].
	((self unsafeDigitOfLargeInt: magnitude at: firstDigitIx) bitAnd: firstMask)
			~= 0
		ifTrue: [^ true].
	firstDigitIx + 1
		to: lastDigitIx - 1
		do: [:ix | (self unsafeDigitOfLargeInt: magnitude at: ix)
					~= 0
				ifTrue: [^ true]].
	((self unsafeDigitOfLargeInt: magnitude at: lastDigitIx)  bitAnd: lastMask)
			~= 0
		ifTrue: [^ true].
	^ false
]

{ #category : #util }
LargeIntegersPlugin >> byteSizeOfCSI: csi [ 
	"Answer the number of bytes required to represent the value of a C-SmallInteger."
	csi >= 0 ifTrue:
		[csi < 256 ifTrue:
			[^1].
		 csi < 65536 ifTrue:
			[^2].
		 csi < 16777216 ifTrue:
			[^3].
		 self cppIf: interpreterProxy bytesPerOop = 4
			ifTrue:
				[^4]
			ifFalse:
				[csi < 4294967296 ifTrue:
					[^4].
				 csi < 1099511627776 ifTrue:
					[^5].
				 csi < 281474976710656 ifTrue:
					[^6].
				 csi < 72057594037927936 ifTrue:
					[^7].
				 ^8]].
	csi > -256 ifTrue:
		[^1].
	csi > -65536 ifTrue:
		[^2].
	csi > -16777216 ifTrue:
		[^3].
	self cppIf: interpreterProxy bytesPerOop = 4
		ifTrue:
			[^4]
		ifFalse:
			[csi > -4294967296 ifTrue:
				[^4].
			 csi > -1099511627776 ifTrue:
				[^5].
			 csi > -281474976710656 ifTrue:
				[^6].
			 csi > -72057594037927936 ifTrue:
				[^7].
			^8]
]

{ #category : #util }
LargeIntegersPlugin >> byteSizeOfLargeInt: bytesOop [ 
	"Answer the number of bytes required to represent a LargeInteger.
	Precondition: bytesOop is not a small integer."
	<inline: #always>
	^ interpreterProxy slotSizeOf: bytesOop
]

{ #category : #'C core util' }
LargeIntegersPlugin >> byteSwapped32IfBigEndian: anInteger [
	"This is only for simulation purposes"
	<doNotGenerate>
	^interpreterProxy byteSwapped32IfBigEndian: anInteger
]

{ #category : #'C core util' }
LargeIntegersPlugin >> byteSwapped64IfBigEndian: anInteger [
	"This is only for simulation purposes"
	<doNotGenerate>
	^interpreterProxy byteSwapped64IfBigEndian: anInteger
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitAdd: pWordShort len: shortLen with: pWordLong len: longLen into: pWordRes [ 
	"pWordRes len = longLen; returns over.."
	| accum |
	<returnTypeC: #'unsigned int'>
	<var: #pWordShort type: #'unsigned int *'>
	<var: #pWordLong type: #'unsigned int *'>
	<var: #pWordRes type: #'unsigned int *'>
	<var: #accum type: #'unsigned long long'>
	accum := 0.
	0 to: shortLen - 1 do: 
		[:i | 
		accum := (accum >> 32)
					+ (self cDigitOf: pWordShort at: i)
					+ (self cDigitOf: pWordLong at: i).
		self cDigitOf: pWordRes at: i put: (accum bitAnd: 16rFFFFFFFF)].
	shortLen to: longLen - 1 do: 
		[:i | 
		accum := (accum >> 32)
					+ (self cDigitOf: pWordLong at: i).
		self cDigitOf: pWordRes at: i put: (accum bitAnd: 16rFFFFFFFF)].
	^ accum >> 32
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitCompare: pFirst with: pSecond len: len [ 
	"Precondition: pFirst len = pSecond len."
	| secondDigit ix firstDigit |
	<var: #pFirst type: #'unsigned int *'>
	<var: #pSecond type: #'unsigned int *'>
	<var: #firstDigit type: #'unsigned int'>
	<var: #secondDigit type: #'unsigned int'>
	ix := len - 1.
	[ix >= 0]
		whileTrue: 
			[(secondDigit := pSecond at: ix) ~= (firstDigit := pFirst at: ix)
				ifTrue: [(self byteSwapped32IfBigEndian: secondDigit) < (self byteSwapped32IfBigEndian: firstDigit)
						ifTrue: [^ 1]
						ifFalse: [^ -1]].
			ix := ix - 1].
	^ 0
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cDigitCopyFrom: pFrom to: pTo len: len [ 
	<var: #pFrom type: #'unsigned int *'>
	<var: #pTo type: #'unsigned int *'>

	"Note: don't care about endianness here, copy operation is endian neutral"
	0 to: len - 1 do: [:i | pTo at: i put: (pFrom at: i)].
	^ 0
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitDiv: pDiv len: divLen rem: pRem len: remLen quo: pQuo len: quoLen [ 
	| dl ql dh dnh j t hi lo r3 l a b cond q r1r2 mul |
	<var: #pDiv type: #'unsigned int *'>
	<var: #pRem type: #'unsigned int *'>
	<var: #pQuo type: #'unsigned int *'>
	<var: #dh type: #'unsigned int'>
	<var: #dnh type: #'unsigned int'>
	<var: #r3 type: #'unsigned int'>
	<var: #q type: #'unsigned long long'>
	<var: #a type: #'unsigned long long'>
	<var: #b type: #'unsigned long long'>
	<var: #t type: #'unsigned long long'>
	<var: #mul type: #'unsigned long long'>
	<var: #hi type: #'unsigned long long'>
	<var: #lo type: #'unsigned long long'>
	<var: #r1r2 type: #'unsigned long long'>
	dl := divLen - 1.
	"Last actual byte of data (ST ix)"
	ql := quoLen.
	dh := self cDigitOf: pDiv at: dl - 1.
	dl = 1
		ifTrue: [dnh := 0]
		ifFalse: [dnh := self cDigitOf: pDiv at: dl - 2].
	1 to: ql do: 
		[:k | 
		"maintain quo*arg+rem=self"
		"Estimate rem/div by dividing the leading two unint32 of rem by dh."
		"The estimate is q = qhi*16r100000000+qlo, where qhi and qlo are uint32."
		j := remLen + 1 - k.
		"r1 := rem digitAt: j."
		(self cDigitOf: pRem at: j - 1)
			= dh
			ifTrue: [q := 16rFFFFFFFF]
			ifFalse: 
				["Compute q = (r1,r2)//dh, t = (r1,r2)\\dh.
				Note that r1,r2 are uint64, not uint32."
				"r2 := (rem digitAt: j - 2)."
				r1r2 := self cDigitOf: pRem at: j - 1.
				r1r2 := (r1r2 << 32) + (self cDigitOf: pRem at: j - 2).
				t := r1r2 \\ dh.
				q := r1r2 // dh.
				"Next compute (hi,lo) := q*dnh"
				mul := q * dnh.
				hi := mul >> 32.
				lo := mul bitAnd: 16rFFFFFFFF.
				"Correct overestimate of q.                
				Max of 2 iterations through loop -- see Knuth vol. 2"
				j < 3
					ifTrue: [r3 := 0]
					ifFalse: [r3 := self cDigitOf: pRem at: j - 3].
				
				[(t < hi
					or: [t = hi and: [r3 < lo]])
					ifTrue: 
						["i.e. (t,r3) < (hi,lo)"
						q := q - 1.
						hi = 0 "since hi is unsigned we must have this guard"
							ifTrue: [cond := false]
							ifFalse:
								[lo < dnh
									ifTrue: 
										[hi := hi - 1.
										lo := lo + 16r100000000 - dnh]
									ifFalse:
										[lo := lo - dnh].
								cond := hi >= dh]]
					ifFalse: [cond := false].
				cond]
					whileTrue: [hi := hi - dh]].
		"Subtract q*div from rem"
		l := j - dl.
		a := 0.
		1 to: divLen do: 
			[:i | 
			hi := (self cDigitOf: pDiv at: i - 1) * (q >> 32).
			lo := (self cDigitOf: pDiv at: i - 1) * (q bitAnd: 16rFFFFFFFF).
			b := (self cDigitOf: pRem at: l - 1) - a - (lo bitAnd: 16rFFFFFFFF).
			self cDigitOf: pRem at: l - 1 put: (b bitAnd: 16rFFFFFFFF).
			"simulate arithmetic shift (preserving sign of b)"
			b := b >> 32 bitOr: (0 - (b >> 63) bitAnd: 16rFFFFFFFF00000000).
			a := hi + (lo >> 32) - b.
			l := l + 1].
		a > 0
			ifTrue: 
				["Add div back into rem, decrease q by 1"
				q := q - 1.
				l := j - dl.
				a := 0.
				1 to: divLen do: 
					[:i | 
					a := (a >> 32)
								+ (self cDigitOf: pRem at: l - 1) + (self cDigitOf: pDiv at: i - 1).
					self cDigitOf: pRem at: l - 1 put: (a bitAnd: 16rFFFFFFFF).
					l := l + 1]].
		self cDigitOf: pQuo at: quoLen - k put: (self cCoerceSimple: q to: #'unsigned int')].
	^0
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cDigitHighBit: pUint32 len: len [ 
	"Answer the index (in bits) of the high order bit of the receiver, or zero if the    
	 receiver is zero. This method is allowed (and needed) for     
	LargeNegativeIntegers as well, since Squeak's LargeIntegers are sign/magnitude.
	Work with 32 bits digits."
	| realLength lastDigit |
	<var: #pUint32 type: #'unsigned int *'>
	<var: #lastDigit type: #'unsigned int'>
	realLength := len.
	[realLength = 0 ifTrue: [^0].
	(lastDigit := self cDigitOf: pUint32 at: (realLength := realLength - 1)) = 0]
		whileTrue.
	^  (self cHighBit32: lastDigit) + (32 * realLength)
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitLshift: shiftCount from: pFrom len: lenFrom to: pTo len: lenTo [ 
	"C indexed!"
	| digitShift bitShift carry limit digit rshift |
	<var: #pTo type: #'unsigned int *'>
	<var: #pFrom type: #'unsigned int *'>
	<var: #carry type: #'unsigned int'>
	<var: #digit type: #'unsigned int'>
	digitShift := shiftCount // 32.
	bitShift := shiftCount \\ 32.
	
	limit := digitShift - 1.
	"Note: 0 is endian neutral, use direct access"
	0 to: limit do: [:i | pTo at: i put: 0].
	
	bitShift = 0 ifTrue: ["Fast version for digit-aligned shifts"
		"C indexed!"
		^ self
			cDigitReplace: pTo
			from: digitShift
			to: lenTo - 1
			with: pFrom
			startingAt: 0].
		
	"This implementation use at most 31 bits of carry.
	bitAnd: 16rFFFFFFFF is only for simulator, useless in C"
	rshift := 32 - bitShift.
	carry := 0.
	limit := lenFrom - 1.
	0 to: limit do: 
		[:i | 
		digit := self cDigitOf: pFrom at: i.
		self cDigitOf: pTo at: i + digitShift put: ((carry bitOr: digit << bitShift) bitAnd: 16rFFFFFFFF).
		carry := digit >> rshift].
	carry = 0 ifFalse: [self cDigitOf: pTo at: lenTo - 1 put: carry].
	^0
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitMontgomery: pFirst
				len: firstLen
				times: pSecond
				len: secondLen
				modulo: pThird
				len: thirdLen
				mInvModB: mInv
				into: pRes [
				
	| u limit1 limit2 limit3 accum accum2 accum3 lastDigit |
	<var: #pFirst type: #'unsigned int *'>
	<var: #pSecond type: #'unsigned int *'>
	<var: #pThird type: #'unsigned int *'>
	<var: #mInv type: #'unsigned int'>
	<var: #pRes type: #'unsigned int *'>
	<var: #accum type: #'unsigned long long'>
	<var: #accum2 type: #'unsigned long long'>
	<var: #accum3 type: #'unsigned long long'>
	<var: #u type: #'unsigned long long '>
	<var: #lastDigit type: #'unsigned int '>
	limit1 := firstLen - 1.
	limit2 := secondLen - 1.
	limit3 := thirdLen - 1.
	lastDigit := 0.
	0 to: limit1 do: 
		[:i | 
		accum3 := self cDigitOf: pFirst at: i.
		accum3 := accum3*(self cDigitOf: pSecond at: 0) + (self cDigitOf: pRes at: 0).
		u := accum3 * mInv bitAnd: 16rFFFFFFFF.
		accum2 :=  u * (self cDigitOf: pThird at: 0).
		accum := (accum2 bitAnd: 16rFFFFFFFF) + (accum3 bitAnd: 16rFFFFFFFF).
		accum := (accum >> 32) + (accum2 >> 32) + (accum3 >> 32).
		1 to: limit2 do: [:k |
			accum3 := self cDigitOf: pFirst at: i.
			accum3 := accum3*(self cDigitOf: pSecond at: k) + (self cDigitOf: pRes at: k).
			accum2 :=  u * (self cDigitOf: pThird at: k).
			accum := accum + (accum2 bitAnd: 16rFFFFFFFF) + (accum3 bitAnd: 16rFFFFFFFF).
			self cDigitOf: pRes at: k-1 put: (accum bitAnd: 16rFFFFFFFF).
			accum := (accum >> 32) + (accum2 >> 32) + (accum3 >> 32)].
		secondLen to: limit3 do: [:k |
			accum2 :=  u * (self cDigitOf: pThird at: k).
			accum := accum + (self cDigitOf: pRes at: k) + (accum2 bitAnd: 16rFFFFFFFF).
			self cDigitOf: pRes at: k-1 put: (accum bitAnd: 16rFFFFFFFF).
			accum := (accum >> 32) + (accum2 >> 32)].
		accum := accum + lastDigit.
		self cDigitOf: pRes at: limit3 put: (accum bitAnd: 16rFFFFFFFF).
		lastDigit := accum >> 32].
	firstLen to: limit3 do: 
		[:i | 
		accum := (self cDigitOf: pRes at: 0).
		u := accum * mInv bitAnd: 16rFFFFFFFF.
		accum := accum + (u * (self cDigitOf: pThird at: 0)).
		accum := accum >> 32.
		1 to: limit3 do: [:k |
			accum2 :=  u * (self cDigitOf: pThird at: k).
			accum := accum + (self cDigitOf: pRes at: k) + (accum2 bitAnd: 16rFFFFFFFF).
			self cDigitOf: pRes at: k-1 put: (accum bitAnd: 16rFFFFFFFF).
			accum := (accum >> 32) + (accum2 >> 32)].
		accum := accum + lastDigit.
		self cDigitOf: pRes at: limit3 put: (accum bitAnd: 16rFFFFFFFF).
		lastDigit := accum >> 32].
	(lastDigit = 0 and: [(self cDigitCompare: pThird with: pRes len: thirdLen) = 1]) ifFalse: [
		"self cDigitSub: pThird len: thirdLen with: pRes len: thirdLen into: pRes"
		accum := 0.
		0 to: limit3 do: 
			[:i | 
			accum := accum + (self cDigitOf: pRes at: i) - (self cDigitOf: pThird at: i).
			self cDigitOf: pRes at: i put: (accum bitAnd: 16rFFFFFFFF).
			accum := 0 - (accum >> 63)]].
	^0
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitMultiply: pWordShort len: shortLen with: pWordLong len: longLen into: pWordRes len: resLen [
	| limitLong digit k carry limitShort ab |
	<returnTypeC: #'unsigned int'>
	<var: #pWordShort type: #'unsigned int *'>
	<var: #pWordLong type: #'unsigned int *'>
	<var: #pWordRes type: #'unsigned int *'>
	<var: #digit type: #'unsigned int'>
	<var: #carry type: #'unsigned int'>
	<var: #ab type: #'unsigned long long'>
	(shortLen = 1 and: [(pWordShort at: 0) = 0])
		ifTrue: [^ 0].
	(longLen = 1 and: [(pWordLong at: 0) = 0])
		ifTrue: [^ 0].
	"prod starts out all zero"
	limitShort := shortLen - 1.
	limitLong := longLen - 1.
	0 to: limitShort do: [:i | (digit := self cDigitOf: pWordShort at: i) ~= 0
			ifTrue: 
				[k := i.
				carry := 0.
				"Loop invariant: 0<=carry<=16rFFFFFFFF, k=i+j-1 (ST)"
				"-> Loop invariant: 0<=carry<=16rFFFFFFFF, k=i+j (C) (?)"
				0 to: limitLong do: 
					[:j | 
					ab := (self cDigitOf: pWordLong at: j).
					ab := ab * digit + carry + (self cDigitOf: pWordRes at: k).
					carry := ab >> 32.
					self cDigitOf: pWordRes at: k put: (ab bitAnd: 16rFFFFFFFF).
					k := k + 1].
				k < resLen ifTrue: [self cDigitOf: pWordRes at: k put: carry]]].
	^ 0
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cDigitOf: cPointer at: zeroBasedDigitIndex [
	<inline: true>
	<returnTypeC: #'unsigned int'>
	<var: 'cPointer' type: #'unsigned int *'>
	^self byteSwapped32IfBigEndian: ((self cCode: [cPointer] inSmalltalk: [interpreterProxy cCoerce: cPointer to: #'unsigned int *']) at: zeroBasedDigitIndex)
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cDigitOf: cPointer at: zeroBasedDigitIndex put: aValue [
	<inline: true>
	<returnTypeC: #'unsigned int'>
	<var: 'cPointer' type: #'unsigned int *'>
	<var: 'aValue' type: #'unsigned int'>
	^(self cCode: [cPointer] inSmalltalk: [interpreterProxy cCoerce: cPointer to: #'unsigned int *'])
		at: zeroBasedDigitIndex
		put: (self byteSwapped32IfBigEndian: aValue)
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitOp: opIndex short: pWordShort len: shortLen long: pWordLong len: longLen into: pWordRes [ 
	"pWordRes len = longLen.
	NOTE: we don't bother with endianness here, those bit opes are endian-neutral"
	| limit |
	<var: #pWordShort type: #'unsigned int *'>
	<var: #pWordLong type: #'unsigned int *'>
	<var: #pWordRes type: #'unsigned int *'>
	limit := shortLen - 1.
	opIndex = andOpIndex
		ifTrue: 
			[0 to: limit do: [:i | pWordRes at: i put: ((pWordShort at: i)
						bitAnd: (pWordLong at: i))].
			limit := longLen - 1.
			shortLen to: limit do: [:i | pWordRes at: i put: 0].
			^ 0].
	opIndex = orOpIndex
		ifTrue: 
			[0 to: limit do: [:i | pWordRes at: i put: ((pWordShort at: i)
						bitOr: (pWordLong at: i))].
			limit := longLen - 1.
			shortLen to: limit do: [:i | pWordRes at: i put: (pWordLong at: i)].
			^ 0].
	opIndex = xorOpIndex
		ifTrue: 
			[0 to: limit do: [:i | pWordRes at: i put: ((pWordShort at: i)
						bitXor: (pWordLong at: i))].
			limit := longLen - 1.
			shortLen to: limit do: [:i | pWordRes at: i put: (pWordLong at: i)].
			^ 0].
	^ interpreterProxy primitiveFail
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cDigitReplace: pTo from: start to: stop with: pFrom startingAt: repStart [ 
	"C indexed!"
	<var: #pTo type: #'unsigned int *'>
	<var: #pFrom type: #'unsigned int *'>
	^ self
		cDigitCopyFrom: pFrom + repStart
		to: pTo + start
		len: stop - start + 1
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitRshift: shiftCount from: pFrom len: lenFrom to: pTo len: lenTo [ 
	| carry digit digitShift bitShift leftShift limit start |
	<var: #pTo type: #'unsigned int *'>
	<var: #pFrom type: #'unsigned int *'>
	<var: #carry type: #'unsigned int'>
	<var: #digit type: #'unsigned int'>
	digitShift := shiftCount // 32.
	bitShift := shiftCount \\ 32.
	bitShift = 0 ifTrue: ["Fast version for digit-aligned shifts"
		"C indexed!"
		^self
			cDigitReplace: pTo
			from: 0
			to: lenTo - 1
			with: pFrom
			startingAt: digitShift].
		
	"This implementation use at most 31 bits of carry.
	bitAnd: 16rFFFFFFFF is only for simulator, useless in C"
	leftShift := 32 - bitShift.
	carry := (self cDigitOf: pFrom at: digitShift) >> bitShift.
	start := digitShift + 1.
	limit := lenFrom - 1.
	start to: limit do: 
		[:j | 
		digit := self cDigitOf: pFrom at: j.
		self cDigitOf: pTo at: j - start put: ((carry bitOr: digit << leftShift) bitAnd: 16rFFFFFFFF).
		carry := digit >> bitShift].
	carry = 0 ifFalse: [self cDigitOf: pTo at: lenTo - 1 put: carry].
	^0
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitSub: pWordSmall
		len: smallLen
		with: pWordLarge
		len: largeLen
		into: pWordRes [
	| z |
	<var: #pWordSmall type: #'unsigned int *'>
	<var: #pWordLarge type: #'unsigned int *'>
	<var: #pWordRes type: #'unsigned int *'>
	<var: #z type: #'unsigned long long'>

	z := 0.
	0 to: smallLen - 1 do: 
		[:i | 
		z := z + (self cDigitOf: pWordLarge at: i) - (self cDigitOf: pWordSmall at: i).
		self cDigitOf: pWordRes at: i put: (z bitAnd: 16rFFFFFFFF).
		z := 0 - (self cCode: [z >> 63] inSmalltalk: [z >> 63 bitAnd: 1])].
	smallLen to: largeLen - 1 do: 
		[:i | 
		z := z + (self cDigitOf: pWordLarge at: i) .
		self cDigitOf: pWordRes at: i put: (z bitAnd: 16rFFFFFFFF).
		z := 0 - (self cCode: [z >> 63] inSmalltalk: [z >> 63 bitAnd: 1])].
	^0
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cHighBit32: anUnsignedInt32 [ 
	"Answer the index of the high order bit of the argument, or zero if the  
	argument is zero."
	| shifted bitNo |

	<var: #anUnsignedInt32 type: #'unsigned int'>
	<var: #shifted type: #'unsigned int'>
	shifted := anUnsignedInt32.
	bitNo := 0.
	shifted < (1 << 16)
		ifFalse: [shifted := shifted >> 16.
			bitNo := bitNo + 16].
	shifted < (1 << 8)
		ifFalse: [shifted := shifted >> 8.
			bitNo := bitNo + 8].
	shifted < (1 << 4)
		ifFalse: [shifted := shifted >> 4.
			bitNo := bitNo + 4].
	shifted < (1 << 2)
		ifFalse: [shifted := shifted >> 2.
			bitNo := bitNo + 2].
	shifted < (1 << 1)
		ifFalse: [shifted := shifted >> 1.
			bitNo := bitNo + 1].
	"shifted 0 or 1 now"
	^ bitNo + shifted
]

{ #category : #'oop util' }
LargeIntegersPlugin >> createLargeFromSmallInteger: anOop [ 
	"anOop has to be a SmallInteger!"
	| val res pDigit byteSize digitSize |
	<var: #pDigit type: #'unsigned int *'>
	val := interpreterProxy integerValueOf: anOop.
	byteSize := self byteSizeOfCSI: val.
	res := self createLargeIntegerNeg: val < 0 byteLength: byteSize.
	pDigit := self pointerToFirstDigitOfLargeInt: res.
	digitSize := byteSize + 3 // 4.
	1 to: digitSize do: [:ix | self cDigitOf: pDigit at: ix - 1 put: (self digitOfCSI: val at: ix)].
	^ res
]

{ #category : #util }
LargeIntegersPlugin >> createLargeIntegerNeg: neg byteLength: byteLength [
	<inline: #always>
	^interpreterProxy
		instantiateClass: (neg
				ifTrue: [interpreterProxy classLargeNegativeInteger]
				ifFalse: [interpreterProxy classLargePositiveInteger])
		indexableSize: byteLength
]

{ #category : #util }
LargeIntegersPlugin >> createLargeIntegerNeg: neg digitLength: digitLength [
	<inline: #always>
	^self createLargeIntegerNeg: neg byteLength: digitLength * 4
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digit: anOop Lshift: shiftCount [ 
	"Attention: this method invalidates all oop's! Only newOop is valid at return."
	"Does not normalize."
	| newOop highBit newDigitLen newByteLen oldDigitLen |
	oldDigitLen := self digitSizeOfLargeInt: anOop.
	(highBit := self cDigitHighBit: (self pointerToFirstDigitOfLargeInt: anOop)
				len: oldDigitLen) = 0 ifTrue: [^  interpreterProxy instantiateClass: (interpreterProxy fetchClassOf: anOop) indexableSize: 1].
	newByteLen := highBit + shiftCount + 7 // 8.
	self remapOop: anOop in:
		[newOop := interpreterProxy
						instantiateClass: (interpreterProxy fetchClassOf: anOop)
						indexableSize: newByteLen].
	newOop ifNil:
		[interpreterProxy primitiveFailFor: PrimErrNoMemory.
		 ^nil].
	newDigitLen := newByteLen + 3 // 4.
	self
		cDigitLshift: shiftCount
		from: (self pointerToFirstDigitOfLargeInt: anOop)
		len: oldDigitLen
		to: (self pointerToFirstDigitOfLargeInt: newOop)
		len: newDigitLen.
	^ newOop
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digit: anOop Rshift: shiftCount lookfirst: a [ 
	"Attention: this method invalidates all oop's! Only newBytes is valid at return."
	"Shift right 32*digitShift+bitShift bits, 0<=bitShift<32.         
	Discard all digits beyond a, and all zeroes at or below a."
	"Does not normalize."
	| newByteLen newOop oldBitLen newBitLen oldDigitLen newDigitLen |
	oldBitLen := self cDigitHighBit: (self pointerToFirstDigitOfLargeInt: anOop) len: a.
	oldDigitLen := oldBitLen + 31 // 32.
	newBitLen := oldBitLen - shiftCount.
	newBitLen <= 0 ifTrue: ["All bits lost"
		^ interpreterProxy
			instantiateClass: (interpreterProxy fetchClassOf: anOop)
			indexableSize: 0].
	newByteLen := newBitLen + 7 // 8.
	newDigitLen := newByteLen + 3 // 4.
	self remapOop: anOop in:
		[newOop := interpreterProxy
						instantiateClass: (interpreterProxy fetchClassOf: anOop)
						indexableSize: newByteLen].
	newOop ifNil: [^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	self
		cDigitRshift: shiftCount
		from: (self pointerToFirstDigitOfLargeInt: anOop)
		len: oldDigitLen
		to: (self pointerToFirstDigitOfLargeInt: newOop)
		len: newDigitLen.
	^ newOop
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitAddLarge: firstInteger with: secondInteger [ 
	"Does not need to normalize!"
	| over firstDigitLen secondDigitLen shortInt shortDigitLen longInt longDigitLen sum newSum neg |
	<var: #over type: #'unsigned int'>
	firstDigitLen := self digitSizeOfLargeInt: firstInteger.
	secondDigitLen := self digitSizeOfLargeInt: secondInteger.
	neg := interpreterProxy isLargeNegativeIntegerObject: firstInteger.
	firstDigitLen <= secondDigitLen
		ifTrue: 
			[shortInt := firstInteger.
			shortDigitLen := firstDigitLen.
			longInt := secondInteger.
			longDigitLen := secondDigitLen]
		ifFalse: 
			[shortInt := secondInteger.
			shortDigitLen := secondDigitLen.
			longInt := firstInteger.
			longDigitLen := firstDigitLen].
	"	sum := Integer new: len neg: firstInteger negative."
	self remapOop: #(shortInt longInt ) in: [sum := self createLargeIntegerNeg: neg digitLength: longDigitLen].
	sum ifNil: [^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	over := self
				cDigitAdd: (self pointerToFirstDigitOfLargeInt: shortInt)
				len: shortDigitLen
				with: (self pointerToFirstDigitOfLargeInt: longInt)
				len: longDigitLen
				into: (self pointerToFirstDigitOfLargeInt: sum).
	over > 0
		ifTrue: 
			["sum := sum growby: 1."
			self remapOop: sum in: [newSum := self createLargeIntegerNeg: neg byteLength: longDigitLen * 4 + 1].
			newSum ifNil: [^interpreterProxy primitiveFailFor: PrimErrNoMemory].
			self
				cDigitCopyFrom: (self pointerToFirstDigitOfLargeInt: sum)
				to: (self pointerToFirstDigitOfLargeInt: newSum)
				len: longDigitLen.
			sum := newSum.
			"C index!"
			self cDigitOf: (self pointerToFirstDigitOfLargeInt: sum)
				at: longDigitLen put: over]
		ifFalse:
			[sum := neg 
				ifTrue: [self normalizeNegative: sum]
				ifFalse: [self normalizePositive: sum]].
	^ sum
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitBitLogic: firstInteger with: secondInteger opIndex: opIx [ 
	"Bit logic here is only implemented for positive integers or Zero;
	if rec or arg is negative, it fails."
	| firstLarge secondLarge firstLen secondLen shortLen shortLarge longLen longLarge result |
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: 
			[(interpreterProxy integerValueOf: firstInteger) < 0 ifTrue:
				[^ interpreterProxy primitiveFail].
			"convert it to a not normalized LargeInteger"
			self remapOop: secondInteger in: [firstLarge := self createLargeFromSmallInteger: firstInteger]]
		ifFalse: 
			[(interpreterProxy isLargePositiveIntegerObject: firstInteger) ifFalse: [^ interpreterProxy primitiveFail].
			firstLarge := firstInteger].
	(interpreterProxy isIntegerObject: secondInteger)
		ifTrue: 
			[(interpreterProxy integerValueOf: secondInteger) < 0 ifTrue:
				[^ interpreterProxy primitiveFail].
			"convert it to a not normalized LargeInteger"
			self remapOop: firstLarge in: [secondLarge := self createLargeFromSmallInteger: secondInteger]]
		ifFalse: 
			[(interpreterProxy isLargePositiveIntegerObject: secondInteger) ifFalse: [^ interpreterProxy primitiveFail].
			secondLarge := secondInteger].
	firstLen := self byteSizeOfLargeInt: firstLarge.
	secondLen := self byteSizeOfLargeInt: secondLarge.
	firstLen < secondLen
		ifTrue: 
			[shortLen := firstLen.
			shortLarge := firstLarge.
			longLen := secondLen.
			longLarge := secondLarge]
		ifFalse: 
			[shortLen := secondLen.
			shortLarge := secondLarge.
			longLen := firstLen.
			longLarge := firstLarge].
	self remapOop: #(shortLarge longLarge) in:
		[result := interpreterProxy instantiateClass: interpreterProxy classLargePositiveInteger indexableSize: longLen].
	result ifNil: [^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	self
		cDigitOp: opIx
		short: (self pointerToFirstDigitOfLargeInt: shortLarge)
		len: shortLen + 3 // 4
		long: (self pointerToFirstDigitOfLargeInt: longLarge)
		len: longLen + 3 // 4
		into: (self pointerToFirstDigitOfLargeInt: result).
	interpreterProxy failed ifTrue: [^ 0].
	^self normalizePositive: result
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitCompareLarge: firstInteger with: secondInteger [ 
	"Compare the magnitude of firstInteger with that of secondInteger.      
	Return a code of 1, 0, -1 for firstInteger >, = , < secondInteger"
	| firstDigitLen secondDigitLen |
	firstDigitLen := self digitSizeOfLargeInt: firstInteger.
	secondDigitLen := self digitSizeOfLargeInt: secondInteger.
	secondDigitLen ~= firstDigitLen
		ifTrue: [secondDigitLen > firstDigitLen
				ifTrue: [^ -1 asOop: SmallInteger]
				ifFalse: [^ 1 asOop: SmallInteger]].
	^ (self
		cDigitCompare: (self pointerToFirstDigitOfLargeInt: firstInteger)
		with: (self pointerToFirstDigitOfLargeInt: secondInteger)
		len: firstDigitLen)
		asOop: SmallInteger
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitDivLarge: firstInteger with: secondInteger negative: neg [ 
	"Does not normalize."
	"Division by zero has to be checked in caller."
	| firstDigitLen secondDigitLen quoDigitLen d div rem quo result |
	firstDigitLen := self digitSizeOfLargeInt: firstInteger.
	secondDigitLen := self digitSizeOfLargeInt: secondInteger.
	quoDigitLen := firstDigitLen - secondDigitLen + 1.
	quoDigitLen <= 0
		ifTrue: 
			[self remapOop: firstInteger in: [result := interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: 2].
			 result ifNotNil:
				[interpreterProxy stObject: result at: 1 put: (0 asOop: SmallInteger).
				 interpreterProxy stObject: result at: 2 put: firstInteger].
			^ result].
	"set rem and div to copies of firstInteger and secondInteger, respectively. 
	 However,  to facilitate use of Knuth's algorithm, multiply rem and div by 2
	 (that is, shift) until the high word of div is >=16r80000000"
	d := 32 - (self cHighBit32: (self unsafeDigitOfLargeInt: secondInteger at: secondDigitLen)).
	self remapOop: firstInteger
		in:	[div := self digit: secondInteger Lshift: d.
			 div ifNotNil:
				[div := self largeInt: div growTo: (self digitSizeOfLargeInt: div) + 1 * 4].
			 div ifNil: [^div]].
	self remapOop: div
		in:	[rem := self digit: firstInteger Lshift: d.
			 rem ifNotNil:
				[(self digitSizeOfLargeInt: rem) = firstDigitLen ifTrue:
					[rem := self largeInt: rem growTo: firstDigitLen + 1 * 4]].
			 rem ifNil: [^rem]].
	self remapOop: #(div rem)
		in: [quo := self createLargeIntegerNeg: neg digitLength: quoDigitLen].
	self
		cDigitDiv: (self pointerToFirstDigitOfLargeInt: div)
		len: (self digitSizeOfLargeInt: div)
		rem: (self pointerToFirstDigitOfLargeInt: rem)
		len: (self digitSizeOfLargeInt: rem)
		quo: (self pointerToFirstDigitOfLargeInt: quo)
		len: (self digitSizeOfLargeInt: quo).
	self remapOop: quo
		in: [rem := self digit: rem Rshift: d lookfirst: (self digitSizeOfLargeInt: div) - 1].
	"^ Array with: quo with: rem"
	self remapOop: #(quo rem)
		in: [result := interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: 2].
	result ifNotNil:
		[interpreterProxy stObject: result at: 1 put: quo.
		 interpreterProxy stObject: result at: 2 put: rem].
	^result
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitMontgomery: firstLarge times: secondLarge modulo: thirdLarge mInvModB: mInv [
	<var: #mInv type: #'unsigned int'>
	| firstLen secondLen thirdLen prod |
	firstLen := self digitSizeOfLargeInt: firstLarge.
	secondLen := self digitSizeOfLargeInt: secondLarge.
	thirdLen := self digitSizeOfLargeInt: thirdLarge.
	(firstLen <= thirdLen and: [secondLen <= thirdLen]) ifFalse: [^interpreterProxy primitiveFail].

	self remapOop: #(firstLarge secondLarge thirdLarge)
		in: [prod := interpreterProxy instantiateClass: interpreterProxy classLargePositiveInteger indexableSize: thirdLen * 4].
	prod ifNil: [^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	self
		cDigitMontgomery: (self pointerToFirstDigitOfLargeInt: firstLarge)
		len: firstLen
		times: (self pointerToFirstDigitOfLargeInt: secondLarge)
		len: secondLen
		modulo: (self pointerToFirstDigitOfLargeInt: thirdLarge)
		len: thirdLen
		mInvModB: mInv
		into: (self pointerToFirstDigitOfLargeInt: prod).
	^self normalizePositive: prod
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitMultiplyLarge: firstInteger with: secondInteger negative: neg [ 
	"Normalizes."
	| firstLen secondLen shortInt shortLen longInt longLen prod |
	firstLen := self byteSizeOfLargeInt: firstInteger.
	secondLen := self byteSizeOfLargeInt: secondInteger.
	firstLen <= secondLen
		ifTrue: 
			[shortInt := firstInteger.
			shortLen := firstLen.
			longInt := secondInteger.
			longLen := secondLen]
		ifFalse: 
			[shortInt := secondInteger.
			shortLen := secondLen.
			longInt := firstInteger.
			longLen := firstLen].
	self remapOop: #(shortInt longInt) in: [prod := self createLargeIntegerNeg: neg byteLength: longLen + shortLen].
	prod ifNil: [^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	self
		cDigitMultiply: (self pointerToFirstDigitOfLargeInt: shortInt)
		len: shortLen + 3 // 4
		with: (self pointerToFirstDigitOfLargeInt: longInt)
		len: longLen + 3 // 4
		into: (self pointerToFirstDigitOfLargeInt: prod)
		len: longLen + shortLen + 3 // 4.
	^neg 
		ifTrue: [self normalizeNegative: prod]
		ifFalse: [self normalizePositive: prod]
]

{ #category : #util }
LargeIntegersPlugin >> digitOfCSI: csi at: ix [ 
	"Answer the value of a 32 bits digit in a C-SmallInteger."
	"ST indexed!"
	^(csi < 0
		ifTrue:  [0 - csi]
		ifFalse: [csi]) >> (ix - 1 * 32)
]

{ #category : #util }
LargeIntegersPlugin >> digitOfLargeInt: aBytesOop at: ix [ 
	"Argument has to be aLargeInteger!"
	ix > (self digitSizeOfLargeInt: aBytesOop)
		ifTrue: [^ 0]
		ifFalse: [^ self unsafeDigitOfLargeInt: aBytesOop at: ix]
]

{ #category : #util }
LargeIntegersPlugin >> digitSizeOfCSI: csi [ 
	"Answer the number of 32-bits fields of a C-SmallInteger. This value is 
	   the same as the largest legal subscript."
	^(interpreterProxy maxSmallInteger <= 16r3FFFFFFF)
		ifTrue: [1]
		ifFalse: [csi > 16rFFFFFFFF asIntegerPtr "conversion is not really needed here, but avoid generating a warning in 32bits, and harmless in 64bits"
			ifTrue: [2]
			ifFalse: [csi < -16rFFFFFFFF
				ifTrue: [2]
				ifFalse: [1]]]
]

{ #category : #util }
LargeIntegersPlugin >> digitSizeOfLargeInt: anOop [
	"answer number of 32 bits digits of a Large Integer"
	<inline: true>
	^(self byteSizeOfLargeInt: anOop) + 3 // 4
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitSubLarge: firstInteger with: secondInteger [ 
	"Normalizes."
	| firstDigitLen secondDigitLen larger largeDigitLen smaller smallerDigitLen neg resDigitLen res firstNeg |
	firstNeg := interpreterProxy isLargeNegativeIntegerObject: firstInteger.
	firstDigitLen := self digitSizeOfLargeInt: firstInteger.
	secondDigitLen := self digitSizeOfLargeInt: secondInteger.
	firstDigitLen = secondDigitLen ifTrue: 
		[[firstDigitLen > 1
		  and: [(self unsafeDigitOfLargeInt: firstInteger at: firstDigitLen) = (self unsafeDigitOfLargeInt: secondInteger at: firstDigitLen)]]
			whileTrue: [firstDigitLen := firstDigitLen - 1].
		secondDigitLen := firstDigitLen].
	(firstDigitLen < secondDigitLen
	 or: [firstDigitLen = secondDigitLen
		 and: [(self unsafeDigitOfLargeInt: firstInteger at: firstDigitLen) < (self unsafeDigitOfLargeInt: secondInteger at: firstDigitLen)]])
		ifTrue: 
			[larger := secondInteger.
			largeDigitLen := secondDigitLen.
			smaller := firstInteger.
			smallerDigitLen := firstDigitLen.
			neg := firstNeg == false]
		ifFalse: 
			[larger := firstInteger.
			largeDigitLen := firstDigitLen.
			smaller := secondInteger.
			smallerDigitLen := secondDigitLen.
			neg := firstNeg].
	resDigitLen := largeDigitLen.
	self remapOop: #(smaller larger)
		in: [res := self createLargeIntegerNeg: neg digitLength: resDigitLen].
	res ifNil: [^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	self
		cDigitSub: (self pointerToFirstDigitOfLargeInt: smaller)
		len: smallerDigitLen
		with: (self pointerToFirstDigitOfLargeInt: larger)
		len: largeDigitLen
		into: (self pointerToFirstDigitOfLargeInt: res).
	^neg 
		ifTrue: [self normalizeNegative: res]
		ifFalse: [self normalizePositive: res]
]

{ #category : #util }
LargeIntegersPlugin >> highBitOfLargeInt: anOop [ 
	<inline: true>
	^ self
		cDigitHighBit: (self pointerToFirstDigitOfLargeInt: anOop)
		len: (self digitSizeOfLargeInt: anOop)
]

{ #category : #'ST initialize' }
LargeIntegersPlugin >> initialize [
	"Initializes ST constants; C's are set by class>>declareCVarsIn:."
	<returnTypeC: 'void'>
	self cCode: '"nothing to do here"'
		inSmalltalk: 
			[andOpIndex := 0.
			orOpIndex := 1.
			xorOpIndex := 2]
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> isNormalized: aLargeInteger [ 
	| len |
	"Check for leading zero of LargeInteger"
	len := self byteSizeOfLargeInt: aLargeInteger.
	len = 0 ifTrue:
		[^ false].
	(self unsafeByteOfLargeInt: aLargeInteger at: len) = 0 ifTrue:
		[^ false].
	^true
]

{ #category : #'oop util' }
LargeIntegersPlugin >> largeInt: aBytesObject growTo: newByteLen [ 
	"Attention: this method invalidates all oop's! Only newBytes is valid at return."
	"Does not normalize."
	| newBytes oldDigitLen newDigitLen copyLen |
	self remapOop: aBytesObject in:
		[newBytes := interpreterProxy
						instantiateClass: (interpreterProxy fetchClassOf: aBytesObject)
						indexableSize: newByteLen.
		 newBytes ifNil:
			[interpreterProxy primitiveFailFor: PrimErrNoMemory. ^nil]].
	newDigitLen := newByteLen + 3 // 4.
	oldDigitLen := self digitSizeOfLargeInt: aBytesObject.
	copyLen := oldDigitLen < newDigitLen
					ifTrue: [oldDigitLen]
					ifFalse: [newDigitLen].
	self
		cDigitCopyFrom: (self pointerToFirstDigitOfLargeInt: aBytesObject)
		to: (self pointerToFirstDigitOfLargeInt: newBytes)
		len: copyLen.
	^newBytes
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> normalize: aLargeInteger [ 
	"Check for leading zeroes and return shortened copy if so."
	self debugCode: [self msg: 'normalize: aLargeInteger'].
	(interpreterProxy isLargePositiveIntegerObject: aLargeInteger)
		ifTrue: [^ self normalizePositive: aLargeInteger]
		ifFalse: [^ self normalizeNegative: aLargeInteger]
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> normalizeNegative: aLargeNegativeInteger [ 
	"Check for leading zeroes and return shortened copy if so."
	"First establish len = significant length."
	| val val2 sLen digitLen byteLen oldByteLen minVal |
	<var: #val type: #usqInt>
	<var: #val2 type: #usqInt>
	<var: #minVal type: #usqInt>
	digitLen := self digitSizeOfLargeInt: aLargeNegativeInteger.
	[digitLen ~= 0 and: [(self unsafeDigitOfLargeInt: aLargeNegativeInteger at: digitLen) = 0]]
		whileTrue: [digitLen := digitLen - 1].
	digitLen = 0 ifTrue: [^ 0 asOop: SmallInteger].
	"Now check if in SmallInteger range"
	val := self unsafeDigitOfLargeInt: aLargeNegativeInteger at: digitLen.
	sLen := interpreterProxy minSmallInteger < -16r40000000
				ifTrue: [2]
				ifFalse: [1]. "SmallInteger minVal digitLength"
	digitLen <= sLen
		ifTrue: 
			[minVal := 0 - interpreterProxy minSmallInteger.
			val2 := val.
			digitLen > 1 ifTrue: [val2 := val2 << 32 + (self unsafeDigitOfLargeInt: aLargeNegativeInteger at: 1)].
			val2 <= minVal
				ifTrue: [^0 -  val2 asOop: SmallInteger]].
	"Return self, or a shortened copy"
	byteLen := digitLen * 4.
	val <= 16rFFFF
		ifTrue: [byteLen := byteLen - 2]
		ifFalse: [val := val >> 16].
	val <= 16rFF
		ifTrue: [byteLen := byteLen - 1].
	oldByteLen := self byteSizeOfLargeInt: aLargeNegativeInteger.
	byteLen < oldByteLen
		ifTrue: [^ self largeInt: aLargeNegativeInteger growTo: byteLen]
		ifFalse: [^ aLargeNegativeInteger]
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> normalizePositive: aLargePositiveInteger [ 
	"Check for leading zeroes and return shortened copy if so."
	"First establish len = significant length."
	| val val2 sLen digitLen byteLen oldByteLen maxVal |
	<var: #val type: #usqInt>
	<var: #val2 type: #usqInt>
	<var: #maxVal type: #usqInt>
	digitLen := self digitSizeOfLargeInt: aLargePositiveInteger.
	[digitLen ~= 0 and: [(self unsafeDigitOfLargeInt: aLargePositiveInteger at: digitLen) = 0]]
		whileTrue: [digitLen := digitLen - 1].
	digitLen = 0 ifTrue: [^ 0 asOop: SmallInteger].
	"Now check if in SmallInteger range"
	val := self unsafeDigitOfLargeInt: aLargePositiveInteger at: digitLen.
	sLen := interpreterProxy maxSmallInteger > 16r3FFFFFFF
				ifTrue: [2]
				ifFalse: [1]. "SmallInteger maxVal digitLength"
	digitLen <= sLen
		ifTrue: 
			[maxVal := interpreterProxy maxSmallInteger.
			val2 := val.
			digitLen > 1 ifTrue:
				["Note: asUnsignedLongLong is not necessary because this branch is for 64 bits only.
				but we want to avoid a C Compiler warning on 32 bits"
				val2 := val2 asUnsignedLongLong << 32 + (self unsafeDigitOfLargeInt: aLargePositiveInteger at: 1)].
			val2 <= maxVal
				ifTrue: [^val2 asOop: SmallInteger]].
	"Return self, or a shortened copy"
	byteLen := digitLen * 4.
	val <= 16rFFFF
		ifTrue: [byteLen := byteLen - 2]
		ifFalse: [val := val >> 16].
	val <= 16rFF
		ifTrue: [byteLen := byteLen - 1].
	oldByteLen := self byteSizeOfLargeInt: aLargePositiveInteger.
	byteLen < oldByteLen
		ifTrue: [^ self largeInt: aLargePositiveInteger growTo: byteLen]
		ifFalse: [^ aLargePositiveInteger]
]

{ #category : #util }
LargeIntegersPlugin >> pointerToFirstDigitOfLargeInt: bytesObject [
	<inline: #always>
	<returnTypeC: #'unsigned int *'>
	^interpreterProxy cCoerce: (interpreterProxy firstIndexableField: bytesObject) to: #'unsigned int *'
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primAnyBitFrom: from to: to [ 
	| integer large |
	self debugCode: [self msg: 'primAnyBitFrom: from to: to'].
	integer := self
				primitive: 'primAnyBitFromTo'
				parameters: #(#SmallInteger #SmallInteger )
				receiver: #Integer.
	(interpreterProxy isIntegerObject: integer)
		ifTrue: ["convert it to a not normalized LargeInteger"
			large := self createLargeFromSmallInteger: integer]
		ifFalse: [large := integer].
	^ (self
		anyBitOfLargeInt: large
		from: from
		to: to)
		asOop: Boolean
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitAdd: secondInteger [
	| firstLarge secondLarge firstInteger |
	self debugCode: [self msg: 'primDigitAdd: secondInteger'].
	firstInteger := self
				primitive: 'primDigitAdd'
				parameters: #(Integer )
				receiver: #Integer.
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: secondInteger in: [firstLarge := self createLargeFromSmallInteger: firstInteger]]
		ifFalse: [firstLarge := firstInteger].
	(interpreterProxy isIntegerObject: secondInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: firstLarge in: [secondLarge := self createLargeFromSmallInteger: secondInteger]]
		ifFalse: [secondLarge := secondInteger].
	^ self digitAddLarge: firstLarge with: secondLarge
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitBitAnd: secondInteger [ 
	"Bit logic here is only implemented for positive integers or Zero; if rec 
	or arg is negative, it fails."
	| firstInteger |
	self debugCode: [self msg: 'primDigitBitAnd: secondInteger'].
	firstInteger := self
				primitive: 'primDigitBitAnd'
				parameters: #(Integer )
				receiver: #Integer.
	^ self
		digitBitLogic: firstInteger
		with: secondInteger
		opIndex: andOpIndex
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitBitOr: secondInteger [ 
	"Bit logic here is only implemented for positive integers or Zero; if rec 
	or arg is negative, it fails."
	| firstInteger |
	self debugCode: [self msg: 'primDigitBitOr: secondInteger'].
	firstInteger := self
				primitive: 'primDigitBitOr'
				parameters: #(Integer )
				receiver: #Integer.
	^ self
		digitBitLogic: firstInteger
		with: secondInteger
		opIndex: orOpIndex
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitBitShiftMagnitude: shiftCount [ 
	| rShift aLarge anInteger |
	self debugCode: [self msg: 'primDigitBitShiftMagnitude: shiftCount'].
	anInteger := self
				primitive: 'primDigitBitShiftMagnitude'
				parameters: #(#SmallInteger )
				receiver: #Integer.
	(interpreterProxy isIntegerObject: anInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			aLarge := self createLargeFromSmallInteger: anInteger]
		ifFalse: [aLarge := anInteger].
	shiftCount >= 0
		ifTrue: [^ self digit: aLarge Lshift: shiftCount]
		ifFalse: 
			[rShift := 0 - shiftCount.
			^ self normalize: (self
					digit: aLarge
					Rshift: rShift
					lookfirst: (self digitSizeOfLargeInt: aLarge))]
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitBitXor: secondInteger [ 
	"Bit logic here is only implemented for positive integers or Zero; if rec 
	or arg is negative, it fails."
	| firstInteger |
	self debugCode: [self msg: 'primDigitBitXor: secondInteger'].
	firstInteger := self
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
	"Compare the magnitude of self with that of arg.   
	 Answer a code of 1, 0, -1 for self >, = , < arg"	| firstVal secondVal firstInteger |
	self debugCode: [self msg: 'primDigitCompare: secondInteger'].
	firstInteger := self
					primitive: 'primDigitCompare'
					parameters: #(#Integer )
					receiver: #Integer.
	"shortcut: aSmallInteger has to be smaller in Magnitude than aLargeInteger"
	(interpreterProxy isIntegerObject: firstInteger) ifTrue:
		[(interpreterProxy isIntegerObject: secondInteger) ifTrue:
			[firstVal := interpreterProxy integerValueOf: firstInteger.
			 secondVal := interpreterProxy integerValueOf: secondInteger.
			 "Compute their magnitudes.  Since SmallIntegers are tagged they have
			  fewer bits than an integer on the platform; therefore in computing their
			  magnitude they cannot overflow."
			 firstVal < 0 ifTrue: [firstVal := 0 - firstVal].
			 secondVal < 0 ifTrue: [secondVal := 0 - secondVal].
			 ^firstVal = secondVal
				ifTrue: [0 asOop: SmallInteger]
				ifFalse:
					[firstVal < secondVal
						ifTrue: [-1 asOop: SmallInteger]
						ifFalse: [1 asOop: SmallInteger]]].
			^-1 asOop: SmallInteger]. "first < second"
	(interpreterProxy isIntegerObject: secondInteger) ifTrue:
		[^1 asOop: SmallInteger]. "first > second"
	^ self digitCompareLarge: firstInteger with: secondInteger
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitDiv: secondInteger negative: neg [ 
	"Answer the result of dividing firstInteger by secondInteger. 
	Fail if parameters are not integers, not normalized or secondInteger is 
	zero. "
	| firstAsLargeInteger secondAsLargeInteger firstInteger |
	self debugCode: [self msg: 'primDigitDiv: secondInteger negative: neg'].
	firstInteger := self
				primitive: 'primDigitDivNegative'
				parameters: #(#Integer #Boolean )
				receiver: #Integer.
	"Coerce SmallIntegers to corresponding (not normalized) large integers  
	and check for zerodivide."
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: ["convert to LargeInteger"
			self
				remapOop: secondInteger
				in: [firstAsLargeInteger := self createLargeFromSmallInteger: firstInteger]]
		ifFalse:
			["Avoid crashes in case of getting unnormalized args."
			(self isNormalized: firstInteger)
				ifFalse:
					[self debugCode:
						[self msg: 'ERROR in primDigitDiv: secondInteger negative: neg'.
						self msg: '------> receiver *not* normalized!'].
					^ interpreterProxy primitiveFail].
			firstAsLargeInteger := firstInteger].
	(interpreterProxy isIntegerObject: secondInteger)
		ifTrue: ["check for zerodivide and convert to LargeInteger"
			(interpreterProxy integerValueOf: secondInteger)
					= 0
				ifTrue: [^ interpreterProxy primitiveFail].
			self
				remapOop: firstAsLargeInteger
				in: [secondAsLargeInteger := self createLargeFromSmallInteger: secondInteger]]
		ifFalse:
			["Avoid crashes in case of getting unnormalized args."
			(self isNormalized: secondInteger)
				ifFalse:
					[self debugCode:
						[self msg: 'ERROR in primDigitDiv: secondInteger negative: neg'.
						self msg: '------> argument *not* normalized!'].
					^ interpreterProxy primitiveFail].
			secondAsLargeInteger := secondInteger].
	^ self
		digitDivLarge: firstAsLargeInteger
		with: secondAsLargeInteger
		negative: neg
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitMultiply: secondInteger negative: neg [ 
	| firstLarge secondLarge firstInteger |
	self debugCode: [self msg: 'primDigitMultiply: secondInteger negative: neg'].
	firstInteger := self
				primitive: 'primDigitMultiplyNegative'
				parameters: #(#Integer #Boolean )
				receiver: #Integer.
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self
				remapOop: secondInteger
				in: [firstLarge := self createLargeFromSmallInteger: firstInteger]]
		ifFalse: [firstLarge := firstInteger].
	(interpreterProxy isIntegerObject: secondInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self
				remapOop: firstLarge
				in: [secondLarge := self createLargeFromSmallInteger: secondInteger]]
		ifFalse: [secondLarge := secondInteger].
	^ self
		digitMultiplyLarge: firstLarge
		with: secondLarge
		negative: neg
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primDigitSubtract: secondInteger [ 
	| firstLarge secondLarge firstInteger |
	self debugCode: [self msg: 'primDigitSubtract: secondInteger'].
	firstInteger := self
				primitive: 'primDigitSubtract'
				parameters: #(#Integer )
				receiver: #Integer.
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self
				remapOop: secondInteger
				in: [firstLarge := self createLargeFromSmallInteger: firstInteger]]
		ifFalse: [firstLarge := firstInteger].
	(interpreterProxy isIntegerObject: secondInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self
				remapOop: firstLarge
				in: [secondLarge := self createLargeFromSmallInteger: secondInteger]]
		ifFalse: [secondLarge := secondInteger].
	^ self digitSubLarge: firstLarge with: secondLarge
]

{ #category : #'control & support primitives' }
LargeIntegersPlugin >> primGetModuleName [
	"If calling this primitive fails, then C module does not exist."
	| strLen strOop |
	self debugCode: [self msg: 'primGetModuleName'].
	self
		primitive: 'primGetModuleName'
		parameters: #()
		receiver: #Oop.
	strLen := self strlen: self getModuleName.
	strOop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: strLen.
	self strncpy: (interpreterProxy firstIndexableField: strOop)
		_: self getModuleName
		_: strLen.
	^strOop
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primMontgomeryDigitLength [
	self debugCode: [self msg: 'primMontgomeryDigitLength'].
	self
				primitive: 'primMontgomeryDigitLength'
				parameters: #()
				receiver: #Integer.
	^interpreterProxy integerObjectOf: 32
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primMontgomeryTimes: secondOperandInteger modulo: thirdModuloInteger mInvModB: mInverseInteger [
	| firstLarge secondLarge firstInteger thirdLarge mInv |
	<var: #mInv type: #'unsigned int'>
	self debugCode: [self msg: 'montgomeryTimes: secondOperandInteger modulo: thirdModuloInteger mInvModB: smallInverseInteger'].
	firstInteger := self
				primitive: 'primMontgomeryTimesModulo'
				parameters: #(Integer Integer Integer )
				receiver: #Integer.
	 mInv := interpreterProxy positive32BitValueOf: mInverseInteger.
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: #(secondOperandInteger thirdModuloInteger) in: [firstLarge := self createLargeFromSmallInteger: firstInteger]]
		ifFalse: [firstLarge := firstInteger].
	(interpreterProxy isIntegerObject: secondOperandInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: #(firstLarge thirdModuloInteger) in: [secondLarge := self createLargeFromSmallInteger: secondOperandInteger]]
		ifFalse: [secondLarge := secondOperandInteger].
	(interpreterProxy isIntegerObject: thirdModuloInteger)
		ifTrue: ["convert it to a not normalized LargeInteger"
			self remapOop: #(firstLarge secondLarge) in: [thirdLarge := self createLargeFromSmallInteger: thirdModuloInteger]]
		ifFalse: [thirdLarge := thirdModuloInteger].
	^ self digitMontgomery: firstLarge times: secondLarge modulo: thirdLarge mInvModB: mInv
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primNormalizeNegative [
	| rcvr |
	self debugCode: [self msg: 'primNormalizeNegative'].
	rcvr := self
				primitive: 'primNormalizeNegative'
				parameters: #()
				receiver: #LargeNegativeInteger.
	^ self normalizeNegative: rcvr
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primNormalizePositive [
	| rcvr |
	self debugCode: [self msg: 'primNormalizePositive'].
	rcvr := self
				primitive: 'primNormalizePositive'
				parameters: #()
				receiver: #LargePositiveInteger.
	^ self normalizePositive: rcvr
]

{ #category : #util }
LargeIntegersPlugin >> unsafeByteOfLargeInt: bytesObj at: ix [
	"Argument bytesObj must not be aSmallInteger!"
	<inline: true>
	<returnTypeC: #'unsigned char'>
	^(interpreterProxy cCoerce: (interpreterProxy firstIndexableField: bytesObj) to: #'unsigned char *') at: ix - 1
]

{ #category : #util }
LargeIntegersPlugin >> unsafeDigitOfLargeInt: anOop at: ix [
	"Argument must not be aSmallInteger!"
	<inline: #always>
	<returnTypeC: #'unsigned int'>
	^self cDigitOf: (self pointerToFirstDigitOfLargeInt: anOop) at: ix - 1
]
