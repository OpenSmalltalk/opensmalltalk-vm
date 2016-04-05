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

{ #category : #simulation }
LargeIntegersPlugin class >> simulatorClass [
	^SmartSyntaxPluginSimulator
]

{ #category : #translation }
LargeIntegersPlugin class >> version [
	"Answer the receiver's version info as String."

	^ 'v1.5'
]

{ #category : #util }
LargeIntegersPlugin >> anyBitOfLargeInt: aBytesOop from: start to: stopArg [ 
	"Argument has to be aBytesOop!"
	"Tests for any magnitude bits in the interval from start to stopArg."
	| magnitude rightShift leftShift stop firstByteIx lastByteIx |
	self
		debugCode: [self msg: 'anyBitOfLargeInt: aBytesOop from: start to: stopArg'].
	start < 1 | (stopArg < 1)
		ifTrue: [^ interpreterProxy primitiveFail].
	magnitude := aBytesOop.
	stop := stopArg
				min: (self highBitOfLargeInt: magnitude).
	start > stop
		ifTrue: [^ false].
	firstByteIx := start - 1 // 8 + 1.
	lastByteIx := stop - 1 // 8 + 1.
	rightShift := (start - 1 \\ 8).
	leftShift := 7 - (stop - 1 \\ 8).
	firstByteIx = lastByteIx
		ifTrue: [| digit mask | 
			mask := (255 << rightShift) bitAnd: (255 >> leftShift).
			digit := self digitOfLargeInt: magnitude at: firstByteIx.
			^ (digit bitAnd: mask)
				~= 0].
	((self digitOfLargeInt: magnitude at: firstByteIx)
			>> rightShift)
			~= 0
		ifTrue: [^ true].
	firstByteIx + 1
		to: lastByteIx - 1
		do: [:ix | (self digitOfLargeInt: magnitude at: ix)
					~= 0
				ifTrue: [^ true]].
	(((self digitOfLargeInt: magnitude at: lastByteIx)
			<< leftShift)
			bitAnd: 255)
			~= 0
		ifTrue: [^ true].
	^ false
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cCopyIntVal: val toBytes: bytes [ 
	| pByte |
	<var: #pByte type: #'unsigned char *'>
	pByte := interpreterProxy firstIndexableField: bytes.
	1 to: (self cDigitLengthOfCSI: val)
		do: [:ix | pByte at: ix - 1 put: (self cDigitOfCSI: val at: ix)]
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitAdd: pByteShort len: shortLen with: pByteLong len: longLen into: pByteRes [ 
	"pByteRes len = longLen; returns over.."
	| accum limit |
	<returnTypeC: #'unsigned char'>
	<var: #pByteShort type: #'unsigned char *'>
	<var: #pByteLong type: #'unsigned char *'>
	<var: #pByteRes type: #'unsigned char *'>
	<var: #accum type: #'unsigned int'>
	accum := 0.
	limit := shortLen - 1.
	0 to: limit do: 
		[:i | 
		accum := (accum >> 8)
					+ (pByteShort at: i) + (pByteLong at: i).
		pByteRes at: i put: (accum bitAnd: 255)].
	limit := longLen - 1.
	shortLen to: limit do: 
		[:i | 
		accum := (accum >> 8)
					+ (pByteLong at: i).
		pByteRes at: i put: (accum bitAnd: 255)].
	^ accum >> 8
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitCompare: pFirst with: pSecond len: len [ 
	"Precondition: pFirst len = pSecond len."
	| secondDigit ix firstDigit |
	<var: #pFirst type: #'unsigned char *'>
	<var: #pSecond type: #'unsigned char *'>
	<var: #firstDigit type: #'unsigned int'>
	<var: #secondDigit type: #'unsigned int'>
	ix := len - 1.
	[ix >= 0]
		whileTrue: 
			[(secondDigit := pSecond at: ix) ~= (firstDigit := pFirst at: ix)
				ifTrue: [secondDigit < firstDigit
						ifTrue: [^ 1]
						ifFalse: [^ -1]].
			ix := ix - 1].
	^ 0
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cDigitCopyFrom: pFrom to: pTo len: len [ 
	| limit |
	<returnTypeC: #'int'>
	<var: #pFrom type: #'unsigned char *'>
	<var: #pTo type: #'unsigned char *'>

	self cCode: '' inSmalltalk: [
		(interpreterProxy isKindOf: InterpreterSimulator) ifTrue: [
			"called from InterpreterSimulator"
				limit := len - 1.
				0 to: limit do: [:i |
					interpreterProxy byteAt: pTo + i
						put: (interpreterProxy byteAt: pFrom + i)
				].
			^ 0
		].
	].	
	limit := len - 1.
	0 to: limit do: [:i | pTo at: i put: (pFrom at: i)].
	^ 0

]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitDiv: pDiv len: divLen rem: pRem len: remLen quo: pQuo len: quoLen [ 
	| dl ql dh dnh j t hi lo r3 l a cond q r1r2 mul b |
	<var: #pDiv type: #'unsigned char *'>
	<var: #pRem type: #'unsigned char *'>
	<var: #pQuo type: #'unsigned char *'>
	<var: #dh type: #'unsigned int'>
	<var: #dnh type: #'unsigned int'>
	<var: #r3 type: #'unsigned int'>
	<var: #q type: #'unsigned int'>
	<var: #a type: #'unsigned int'>
	<var: #b type: #'unsigned int'>
	<var: #t type: #'unsigned int'>
	<var: #mul type: #'unsigned int'>
	<var: #hi type: #'unsigned int'>
	<var: #lo type: #'unsigned int'>
	<var: #r1r2 type: #'unsigned int'>
	dl := divLen - 1.
	"Last actual byte of data (ST ix)"
	ql := quoLen.
	dh := pDiv at: dl - 1.
	dl = 1
		ifTrue: [dnh := 0]
		ifFalse: [dnh := pDiv at: dl - 2].
	1 to: ql do: 
		[:k | 
		"maintain quo*arg+rem=self"
		"Estimate rem/div by dividing the leading two digits of rem by dh."
		"The estimate is q = qhi*16r100+qlo, where qhi and qlo are unsigned char."
		j := remLen + 1 - k.
		"r1 := rem digitAt: j."
		(pRem at: j - 1)
			= dh
			ifTrue: [q := 16rFF]
			ifFalse: 
				["Compute q = (r1,r2)//dh, t = (r1,r2)\\dh."
				"r2 := (rem digitAt: j - 2)."
				r1r2 := pRem at: j - 1.
				r1r2 := (r1r2 << 8) + (pRem at: j - 2).
				t := r1r2 \\ dh.
				q := r1r2 // dh.
				"Next compute (hi,lo) := q*dnh"
				mul := q * dnh.
				hi := mul >> 8.
				lo := mul bitAnd: 16rFF.
				"Correct overestimate of q.                
				Max of 2 iterations through loop -- see Knuth vol. 2"
				j < 3
					ifTrue: [r3 := 0]
					ifFalse: [r3 := pRem at: j - 3].
				
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
										lo := lo + 16r100 - dnh]
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
			hi := (pDiv at: i - 1) * (q >> 8).
			lo := (pDiv at: i - 1) * (q bitAnd: 16rFF).
			b := (pRem at: l - 1) - a - (lo bitAnd: 16rFF).
			pRem at: l - 1 put: (b bitAnd: 16rFF).
			"BEWARE: signed shift is implementation defined in C..."
			b := b signedBitShift: -8.
				"This is a possible replacement to simulate arithmetic shift (preserving sign of b)"
				"b := b >> 8 bitOr: (0 - (b >> ((interpreterProxy sizeof: b)*8""CHAR_BIT""-1)) << 8)."
			a := hi + (lo >> 8) - b.
			l := l + 1].
		a > 0
			ifTrue: 
				["Add div back into rem, decrease q by 1"
				q := q - 1.
				l := j - dl.
				a := 0.
				1 to: divLen do: 
					[:i | 
					a := (a >> 8)
								+ (pRem at: l - 1) + (pDiv at: i - 1).
					pRem at: l - 1 put: (a bitAnd: 16rFF).
					l := l + 1]].
		pQuo at: quoLen - k put: q].
	^0
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cDigitHighBit: pByte len: len [ 
	"Answer the index (in bits) of the high order bit of the receiver, or zero if the    
	 receiver is zero. This method is allowed (and needed) for     
	LargeNegativeIntegers as well, since Squeak's LargeIntegers are     
	sign/magnitude."
	| realLength lastDigit |
	<var: #pByte type: #'unsigned char *'>
	<var: #lastDigit type: #'unsigned int'>
	realLength := len.
	[(lastDigit := pByte at: realLength - 1) = 0]
		whileTrue: [(realLength := realLength - 1) = 0 ifTrue: [^ 0]].
	^  (self cHighBit: lastDigit) + (8 * (realLength - 1))
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cDigitLengthOfCSI: csi [ 
	"Answer the number of bytes required to represent the value of a CSmallInteger."
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

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitLshift: shiftCount from: pFrom len: lenFrom to: pTo len: lenTo [ 
	"C indexed!"
	| digitShift bitShift carry limit digit rshift |
	<var: #pTo type: #'unsigned char *'>
	<var: #pFrom type: #'unsigned char *'>
	<var: #carry type: #'unsigned int'>
	<var: #digit type: #'unsigned int'>
	digitShift := shiftCount // 8.
	bitShift := shiftCount \\ 8.
	
	limit := digitShift - 1.
	0 to: limit do: [:i | pTo at: i put: 0].
	
	bitShift = 0 ifTrue: ["Fast version for digit-aligned shifts"
		"C indexed!"
		^ self
			cDigitReplace: pTo
			from: digitShift
			to: lenTo - 1
			with: pFrom
			startingAt: 0].
		
	"This implementation use at most 15 bits of carry.
	bitAnd: 16rFF is only for simulator, useless in C"
	rshift := 8 - bitShift.
	carry := 0.
	limit := lenFrom - 1.
	0 to: limit do: 
		[:i | 
		digit := pFrom at: i.
		pTo at: i + digitShift put: ((carry bitOr: digit << bitShift) bitAnd: 16rFF).
		carry := digit >> rshift].
	carry = 0 ifFalse: [pTo at: lenTo - 1 put: carry].
	^0

]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitMontgomery: pBytesFirst
				len: firstLen
				times: pBytesSecond
				len: secondLen
				modulo: pBytesThird
				len: thirdLen
				mInvModB: mInv
				into: pBytesRes [
				
	| u limit1 limit2 limit3 accum lastByte |
	<var: #pBytesFirst type: #'unsigned char *'>
	<var: #pBytesSecond type: #'unsigned char *'>
	<var: #pBytesThird type: #'unsigned char *'>
	<var: #pBytesRes type: #'unsigned char *'>
	<var: #accum type: #'unsigned int'>
	<var: #u type: #'unsigned char'>
	<var: #lastByte type: #'unsigned char'>
	limit1 := firstLen - 1.
	limit2 := secondLen - 1.
	limit3 := thirdLen - 1.
	lastByte := 0.
	0 to: limit1 do: 
		[:i | 
		accum := (pBytesRes at: 0) + ((pBytesFirst at: i)*(pBytesSecond at: 0)).
		u := accum * mInv bitAnd: 255.
		accum :=  accum + (u * (pBytesThird at: 0)).
		1 to: limit2 do: [:k |
			accum := (accum >> 8) + (pBytesRes at: k) + ((pBytesFirst at: i)*(pBytesSecond at: k)) + (u * (pBytesThird at: k)).
			pBytesRes at: k-1 put: (accum bitAnd: 255)].
		secondLen to: limit3 do: [:k |
			accum := (accum >> 8) + (pBytesRes at: k) + (u * (pBytesThird at: k)).
			pBytesRes at: k-1 put: (accum bitAnd: 255)].
		accum := (accum >> 8) + lastByte.
		pBytesRes at: limit3 put: (accum bitAnd: 255).
		lastByte := accum >> 8].
	firstLen to: limit3 do: 
		[:i | 
		accum := (pBytesRes at: 0).
		u := accum * mInv bitAnd: 255.
		accum := accum + (u * (pBytesThird at: 0)).
		1 to: limit3 do: [:k |
			accum := (accum >> 8) + (pBytesRes at: k) + (u * (pBytesThird at: k)).
			pBytesRes at: k-1 put: (accum bitAnd: 255)].
		accum := (accum >> 8) + lastByte.
		pBytesRes at: limit3 put: (accum bitAnd: 255).
		lastByte := accum >> 8].
	(lastByte = 0 and: [(self cDigitCompare: pBytesThird with: pBytesRes len: thirdLen) = 1]) ifFalse: [
		"self cDigitSub: pBytesThird len: thirdLen with: pBytesRes len: thirdLen into: pBytesRes"
		accum := 0.
		0 to: limit3 do: 
			[:i | 
			accum := accum + (pBytesRes at: i) - (pBytesThird at: i).
			pBytesRes at: i put: (self cCode: [accum] inSmalltalk: [accum bitAnd: 255]).
			accum := accum signedBitShift: -8]].
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitMultiply: pByteShort len: shortLen with: pByteLong len: longLen into: pByteRes [ 
	| limitLong digit k carry limitShort ab |
	<returnTypeC: #'unsigned char'>
	<var: #pByteShort type: #'unsigned char *'>
	<var: #pByteLong type: #'unsigned char *'>
	<var: #pByteRes type: #'unsigned char *'>
	<var: #digit type: #'unsigned int'>
	<var: #carry type: #'unsigned int'>
	<var: #ab type: #'unsigned int'>
	(shortLen = 1 and: [(pByteShort at: 0)
			= 0])
		ifTrue: [^ 0].
	(longLen = 1 and: [(pByteLong at: 0)
			= 0])
		ifTrue: [^ 0].
	"prod starts out all zero"
	limitShort := shortLen - 1.
	limitLong := longLen - 1.
	0 to: limitShort do: [:i | (digit := pByteShort at: i) ~= 0
			ifTrue: 
				[k := i.
				carry := 0.
				"Loop invariant: 0<=carry<=0377, k=i+j-1 (ST)"
				"-> Loop invariant: 0<=carry<=0377, k=i+j (C) (?)"
				0 to: limitLong do: 
					[:j | 
					ab := (pByteLong at: j).
					ab := ab * digit + carry + (pByteRes at: k).
					carry := ab >> 8.
					pByteRes at: k put: (ab bitAnd: 16rFF).
					k := k + 1].
				pByteRes at: k put: carry]].
	^ 0
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cDigitOfCSI: csi at: ix [ 
	"Answer the value of an indexable field in the receiver.              
	LargePositiveInteger uses bytes of base two number, and each is a       
	      'digit' base 256."
	"ST indexed!"
	^self
		cCode: [(csi < 0
					ifTrue: [0 - csi]
					ifFalse: [csi]) >> (ix - 1 * 8) bitAnd: 255]
		inSmalltalk: [csi digitAt: ix]
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitOp: opIndex short: pByteShort len: shortLen long: pByteLong len: longLen into: pByteRes [ 
	"pByteRes len = longLen."
	| limit |
	<var: #pByteShort type: #'unsigned char *'>
	<var: #pByteLong type: #'unsigned char *'>
	<var: #pByteRes type: #'unsigned char *'>
	limit := shortLen - 1.
	opIndex = andOpIndex
		ifTrue: 
			[0 to: limit do: [:i | pByteRes at: i put: ((pByteShort at: i)
						bitAnd: (pByteLong at: i))].
			limit := longLen - 1.
			shortLen to: limit do: [:i | pByteRes at: i put: 0].
			^ 0].
	opIndex = orOpIndex
		ifTrue: 
			[0 to: limit do: [:i | pByteRes at: i put: ((pByteShort at: i)
						bitOr: (pByteLong at: i))].
			limit := longLen - 1.
			shortLen to: limit do: [:i | pByteRes at: i put: (pByteLong at: i)].
			^ 0].
	opIndex = xorOpIndex
		ifTrue: 
			[0 to: limit do: [:i | pByteRes at: i put: ((pByteShort at: i)
						bitXor: (pByteLong at: i))].
			limit := longLen - 1.
			shortLen to: limit do: [:i | pByteRes at: i put: (pByteLong at: i)].
			^ 0].
	^ interpreterProxy primitiveFail
]

{ #category : #'C core util' }
LargeIntegersPlugin >> cDigitReplace: pTo from: start to: stop with: pFrom startingAt: repStart [ 
	"C indexed!"
	<returnTypeC: #'int'>
	<var: #pTo type: #'unsigned char *'>
	<var: #pFrom type: #'unsigned char *'>
	^ self
		cDigitCopyFrom: pFrom + repStart
		to: pTo + start
		len: stop - start + 1
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitRshift: shiftCount from: pFrom len: fromLen to: pTo len: toLen [ 
	| digit bitShift carry digitShift leftShift limit start |
	<var: #pTo type: #'unsigned char *'>
	<var: #pFrom type: #'unsigned char *'>
	<var: #carry type: #'unsigned int'>
	<var: #digit type: #'unsigned int'>
	digitShift := shiftCount // 8.
	bitShift := shiftCount \\ 8.
	bitShift = 0 ifTrue: ["Fast version for byte-aligned shifts"
		"C indexed!"
		^self
			cDigitReplace: pTo
			from: 0
			to: toLen - 1
			with: pFrom
			startingAt: digitShift].
		
	"This implementation use at most 16 bits of x"
	leftShift := 8 - bitShift.
	carry := (pFrom at: digitShift) >> bitShift.
	start := digitShift + 1.
	limit := fromLen - 1.
	start to: limit do: 
		[:j | 
		digit := pFrom at: j.
		pTo at: j - start put: ((carry bitOr: digit << leftShift) bitAnd: 16rFF).
		carry := digit >> bitShift].
	carry = 0 ifFalse: [pTo at: toLen - 1 put: carry].
	^0
]

{ #category : #'C core' }
LargeIntegersPlugin >> cDigitSub: pByteSmall len: smallLen with: pByteLarge len: largeLen into: pByteRes [
	| z |
	<var: #pByteSmall type: #'unsigned char *'>
	<var: #pByteLarge type: #'unsigned char *'>
	<var: #pByteRes type: #'unsigned char *'>
	<var: #z type: #'unsigned int'>

	z := 0. "Loop invariant is -1<=z<=1"
	0 to: smallLen - 1 do: 
		[:i | 
		z := z + (pByteLarge at: i) - (pByteSmall at: i).
		pByteRes at: i put: (self cCode: [z] inSmalltalk: [z bitAnd: 255]).
		z := z signedBitShift: -8].
	smallLen to: largeLen - 1 do: 
		[:i | 
		z := z + (pByteLarge at: i) .
		pByteRes at: i put: (self cCode: [z] inSmalltalk: [z bitAnd: 255]).
		z := z signedBitShift: -8].

]

{ #category : #'C core util' }
LargeIntegersPlugin >> cHighBit: uint [ 
	"Answer the index of the high order bit of the argument, or zero if the  
	argument is zero."
	"For 64 bit uints there could be added a 32-shift."
	| shifted bitNo |
	<var: #uint type: #'unsigned int'>
	<var: #shifted type: #'unsigned int'>
	shifted := uint.
	bitNo := 0.
	shifted < (1 << 16)
		ifFalse: [shifted := shifted bitShift: -16.
			bitNo := bitNo + 16].
	shifted < (1 << 8)
		ifFalse: [shifted := shifted bitShift: -8.
			bitNo := bitNo + 8].
	shifted < (1 << 4)
		ifFalse: [shifted := shifted bitShift: -4.
			bitNo := bitNo + 4].
	shifted < (1 << 2)
		ifFalse: [shifted := shifted bitShift: -2.
			bitNo := bitNo + 2].
	shifted < (1 << 1)
		ifFalse: [shifted := shifted bitShift: -1.
			bitNo := bitNo + 1].
	"shifted 0 or 1 now"
	^ bitNo + shifted
]

{ #category : #'oop util' }
LargeIntegersPlugin >> createLargeFromSmallInteger: anOop [ 
	"anOop has to be a SmallInteger!"
	| val class size res pByte byte |
	<var: #pByte type: #'unsigned char *'>
	val := interpreterProxy integerValueOf: anOop.
	val < 0
		ifTrue: [class := interpreterProxy classLargeNegativeInteger]
		ifFalse: [class := interpreterProxy classLargePositiveInteger].
	size := self cDigitLengthOfCSI: val.
	res := interpreterProxy instantiateClass: class indexableSize: size.
	pByte := interpreterProxy firstIndexableField: res.
	1 to: size do: [:ix |
		byte := self cDigitOfCSI: val at: ix.
		pByte at: ix - 1 put: byte].
	^res
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digit: aBytesOop Lshift: shiftCount [ 
	"Attention: this method invalidates all oop's! Only newBytes is valid at return."
	"Does not normalize."
	| newBytes highBit newLen oldLen |
	oldLen := self digitSizeOfLargeInt: aBytesOop.
	(highBit := self cDigitHighBit: (interpreterProxy firstIndexableField: aBytesOop)
				len: oldLen) = 0 ifTrue: [^ 0 asOop: SmallInteger].
	newLen := highBit + shiftCount + 7 // 8.
	self remapOop: aBytesOop in: [newBytes := interpreterProxy instantiateClass: (interpreterProxy fetchClassOf: aBytesOop)
					indexableSize: newLen].
	self
		cDigitLshift: shiftCount
		from: (interpreterProxy firstIndexableField: aBytesOop)
		len: oldLen
		to: (interpreterProxy firstIndexableField: newBytes)
		len: newLen.
	^ newBytes
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digit: aBytesOop Rshift: shiftCount lookfirst: a [ 
	"Attention: this method invalidates all oop's! Only newBytes is valid at return."
	"Shift right shiftCount bits, 0<=shiftCount.         
	Discard all digits beyond a, and all zeroes at or below a."
	"Does not normalize."
	| newByteLen newOop oldBitLen newBitLen oldDigitLen |
	oldBitLen := self cDigitHighBit: (interpreterProxy firstIndexableField: aBytesOop) len: a.
	oldDigitLen := oldBitLen + 7 // 8.
	newBitLen := oldBitLen - shiftCount.
	newBitLen <= 0 ifTrue: ["All bits lost"
		^ interpreterProxy
			instantiateClass: (interpreterProxy fetchClassOf: aBytesOop)
			indexableSize: 0].
	newByteLen := newBitLen + 7 // 8.
	self remapOop: aBytesOop in: [newOop := interpreterProxy instantiateClass: (interpreterProxy fetchClassOf: aBytesOop)
					indexableSize: newByteLen].
	self
		cDigitRshift: shiftCount
		from: (interpreterProxy firstIndexableField: aBytesOop)
		len: oldDigitLen
		to: (interpreterProxy firstIndexableField: newOop)
		len: newByteLen.
	^ newOop
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitAddLarge: firstInteger with: secondInteger [ 
	"Does not need to normalize!"
	| over firstLen secondLen shortInt shortLen longInt longLen sum newSum resClass |
	<var: #over type: #'unsigned char'>
	firstLen := self digitSizeOfLargeInt: firstInteger.
	secondLen := self digitSizeOfLargeInt: secondInteger.
	resClass := interpreterProxy fetchClassOf: firstInteger.
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
	"	sum := Integer new: len neg: firstInteger negative."
	self remapOop: #(shortInt longInt ) in: [sum := interpreterProxy instantiateClass: resClass indexableSize: longLen].
	over := self
				cDigitAdd: (interpreterProxy firstIndexableField: shortInt)
				len: shortLen
				with: (interpreterProxy firstIndexableField: longInt)
				len: longLen
				into: (interpreterProxy firstIndexableField: sum).
	over > 0
		ifTrue: 
			["sum := sum growby: 1."
			self remapOop: sum in: [newSum := interpreterProxy instantiateClass: resClass indexableSize: longLen + 1].
			self
				cDigitCopyFrom: (interpreterProxy firstIndexableField: sum)
				to: (interpreterProxy firstIndexableField: newSum)
				len: longLen.
			sum := newSum.
			"C index!"
			(self cCoerce: (interpreterProxy firstIndexableField: sum)
				to: 'unsigned char *')
				at: longLen put: over].
	^ sum
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitBitLogic: firstInteger with: secondInteger opIndex: opIx [ 
	"Bit logic here is only implemented for positive integers or Zero;
	if rec or arg is negative, it fails."
	| firstLarge secondLarge firstLen secondLen shortLen shortLarge longLen longLarge result |
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: 
			[(interpreterProxy integerValueOf: firstInteger)
				< 0 ifTrue: [^ interpreterProxy primitiveFail].
			"convert it to a not normalized LargeInteger"
			self remapOop: secondInteger in: [firstLarge := self createLargeFromSmallInteger: firstInteger]]
		ifFalse: 
			[(interpreterProxy fetchClassOf: firstInteger)
				= interpreterProxy classLargeNegativeInteger ifTrue: [^ interpreterProxy primitiveFail].
			firstLarge := firstInteger].
	(interpreterProxy isIntegerObject: secondInteger)
		ifTrue: 
			[(interpreterProxy integerValueOf: secondInteger)
				< 0 ifTrue: [^ interpreterProxy primitiveFail].
			"convert it to a not normalized LargeInteger"
			self remapOop: firstLarge in: [secondLarge := self createLargeFromSmallInteger: secondInteger]]
		ifFalse: 
			[(interpreterProxy fetchClassOf: secondInteger)
				= interpreterProxy classLargeNegativeInteger ifTrue: [^ interpreterProxy primitiveFail].
			secondLarge := secondInteger].
	firstLen := self digitSizeOfLargeInt: firstLarge.
	secondLen := self digitSizeOfLargeInt: secondLarge.
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
	self remapOop: #(shortLarge longLarge ) in: [result := interpreterProxy instantiateClass: interpreterProxy classLargePositiveInteger indexableSize: longLen].
	self
		cDigitOp: opIx
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
	firstLen := self digitSizeOfLargeInt: firstInteger.
	secondLen := self digitSizeOfLargeInt: secondInteger.
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
	firstLen := self digitSizeOfLargeInt: firstInteger.
	secondLen := self digitSizeOfLargeInt: secondInteger.
	neg
		ifTrue: [resultClass := interpreterProxy classLargeNegativeInteger]
		ifFalse: [resultClass := interpreterProxy classLargePositiveInteger].
	l := firstLen - secondLen + 1.
	l <= 0
		ifTrue: 
			[self remapOop: firstInteger in: [result := interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: 2].
			result stAt: 1 put: (0 asOop: SmallInteger).
			result stAt: 2 put: firstInteger.
			^ result].
	"set rem and div to copies of firstInteger and secondInteger, respectively. 
	  However,  
	 to facilitate use of Knuth's algorithm, multiply rem and div by 2 (that 
	 is, shift)   
	 until the high byte of div is >=128"
	d := 8 - (self cHighBit: (self unsafeDigitOf: secondInteger at: secondLen)).
	self remapOop: firstInteger
		in: 
			[div := self digit: secondInteger Lshift: d.
			div := self largeIntOrInt: div growTo: (self digitLength: div)
							+ 1].
	self remapOop: div
		in: 
			[rem := self digit: firstInteger Lshift: d.
			(self digitLength: rem)
				= firstLen ifTrue: [rem := self largeIntOrInt: rem growTo: firstLen + 1]].
	self remapOop: #(div rem ) in: [quo := interpreterProxy instantiateClass: resultClass indexableSize: l].
	self
		cDigitDiv: (interpreterProxy firstIndexableField: div)
		len: (self digitLength: div)
		rem: (interpreterProxy firstIndexableField: rem)
		len: (self digitLength: rem)
		quo: (interpreterProxy firstIndexableField: quo)
		len: (self digitLength: quo).
	self remapOop: #(quo ) in: [rem := self
					digit: rem
					Rshift: d
					lookfirst: (self digitLength: div)
							- 1].
	"^ Array with: quo with: rem"
	self remapOop: #(quo rem ) in: [result := interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: 2].
	result stAt: 1 put: quo.
	result stAt: 2 put: rem.
	^ result
]

{ #category : #util }
LargeIntegersPlugin >> digitLength: oop [ 
	(interpreterProxy isIntegerObject: oop)
		ifTrue: [^ self cDigitLengthOfCSI: (interpreterProxy integerValueOf: oop)]
		ifFalse: [^ self digitSizeOfLargeInt: oop]
]

{ #category : #util }
LargeIntegersPlugin >> digitLengthOfNonImmediate: oop [
	<inline: true>
	^self digitSizeOfLargeInt: oop
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitMontgomery: firstLarge times: secondLarge modulo: thirdLarge mInvModB: mInv [

	| firstLen secondLen thirdLen prod |
	firstLen := self digitSizeOfLargeInt: firstLarge.
	secondLen := self digitSizeOfLargeInt: secondLarge.
	thirdLen := self digitSizeOfLargeInt: thirdLarge.

	firstLen <= thirdLen ifFalse: [^interpreterProxy primitiveFail].
	secondLen <= thirdLen ifFalse: [^interpreterProxy primitiveFail].
	(mInv >= 0 and: [mInv <= 255]) ifFalse: [^interpreterProxy primitiveFail].
	self remapOop: #(firstLarge secondLarge thirdLarge) in: [prod := interpreterProxy instantiateClass: interpreterProxy classLargePositiveInteger indexableSize: thirdLen].
	self
				cDigitMontgomery: (interpreterProxy firstIndexableField: firstLarge)
				len: firstLen
				times: (interpreterProxy firstIndexableField: secondLarge)
				len: secondLen
				modulo: (interpreterProxy firstIndexableField: thirdLarge)
				len: thirdLen
				mInvModB: mInv
				into: (interpreterProxy firstIndexableField: prod).
	^self normalizePositive: prod
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitMultiplyLarge: firstInteger with: secondInteger negative: neg [ 
	"Normalizes."
	| firstLen secondLen shortInt shortLen longInt longLen prod resultClass |
	firstLen := self digitSizeOfLargeInt: firstInteger.
	secondLen := self digitSizeOfLargeInt: secondInteger.
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
	neg
		ifTrue: [resultClass := interpreterProxy classLargeNegativeInteger]
		ifFalse: [resultClass := interpreterProxy classLargePositiveInteger].
	self remapOop: #(shortInt longInt ) in: [prod := interpreterProxy instantiateClass: resultClass indexableSize: longLen + shortLen].
	self
		cDigitMultiply: (interpreterProxy firstIndexableField: shortInt)
		len: shortLen
		with: (interpreterProxy firstIndexableField: longInt)
		len: longLen
		into: (interpreterProxy firstIndexableField: prod).
	^ self normalize: prod
]

{ #category : #util }
LargeIntegersPlugin >> digitOfLargeInt: aBytesOop at: ix [ 
	"Argument has to be aLargeInteger!"
	ix > (self digitSizeOfLargeInt: aBytesOop)
		ifTrue: [^ 0]
		ifFalse: [^ self unsafeDigitOf: aBytesOop at: ix]
]

{ #category : #util }
LargeIntegersPlugin >> digitSizeOfLargeInt: bytesOop [ 
	"Precondition: bytesOop is not anInteger and a bytes object."
	^ interpreterProxy slotSizeOf: bytesOop
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> digitSubLarge: firstInteger with: secondInteger [ 
	"Normalizes."
	| firstLen secondLen larger largerLen smaller smallerLen neg resLen res firstNeg |
	firstNeg := (interpreterProxy fetchClassOf: firstInteger)
				= interpreterProxy classLargeNegativeInteger.
	firstLen := self digitSizeOfLargeInt: firstInteger.
	secondLen := self digitSizeOfLargeInt: secondInteger.
	firstLen = secondLen ifTrue: 
		[[firstLen > 1
		  and: [(self digitOfLargeInt: firstInteger at: firstLen) = (self digitOfLargeInt: secondInteger at: firstLen)]]
			whileTrue: [firstLen := firstLen - 1].
		secondLen := firstLen].
	(firstLen < secondLen
	 or: [firstLen = secondLen
		 and: [(self digitOfLargeInt: firstInteger at: firstLen) < (self digitOfLargeInt: secondInteger at: firstLen)]])
		ifTrue: 
			[larger := secondInteger.
			largerLen := secondLen.
			smaller := firstInteger.
			smallerLen := firstLen.
			neg := firstNeg == false]
		ifFalse: 
			[larger := firstInteger.
			largerLen := firstLen.
			smaller := secondInteger.
			smallerLen := secondLen.
			neg := firstNeg].
	resLen := largerLen.
	self remapOop: #(smaller larger)
		in: [res := interpreterProxy
					instantiateClass: (neg
										ifTrue: [interpreterProxy classLargeNegativeInteger]
										ifFalse: [interpreterProxy classLargePositiveInteger])
					indexableSize: resLen].
	self
		cDigitSub: (interpreterProxy firstIndexableField: smaller)
		len: smallerLen
		with: (interpreterProxy firstIndexableField: larger)
		len: largerLen
		into: (interpreterProxy firstIndexableField: res).
	^neg 
		ifTrue: [self normalizeNegative: res]
		ifFalse: [self normalizePositive: res]
]

{ #category : #util }
LargeIntegersPlugin >> highBitOfLargeInt: aBytesOop [ 
	^ self cDigitHighBit: (interpreterProxy firstIndexableField: aBytesOop)
		len: (self digitSizeOfLargeInt: aBytesOop)
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
LargeIntegersPlugin >> isNormalized: anInteger [ 
	| len class positive pointer |
	<var: #pointer type: #'unsigned char *'>
	(interpreterProxy isIntegerObject: anInteger) ifTrue:
		[^true].
	class := interpreterProxy fetchClassOf: anInteger.
	(positive := class = interpreterProxy classLargePositiveInteger) ifFalse:
		[class = interpreterProxy classLargeNegativeInteger ifFalse:
			[interpreterProxy primitiveFailFor: PrimErrBadArgument.
			 ^false]].
	pointer := interpreterProxy cCoerce: (interpreterProxy firstIndexableField: anInteger) to: #'unsigned char *'.
	"Check for leading zero of LargeInteger"
	len := self digitLengthOfNonImmediate: anInteger.
	(len = 0 or: [(pointer at: len - 1) = 0]) ifTrue:
		[^false].
	"no leading zero, now check if anInteger is in SmallInteger range or not"
	"maximal digitLength of aSmallInteger"
	len ~= interpreterProxy bytesPerOop ifTrue:
		[^len > interpreterProxy bytesPerOop].
	positive ifTrue: "all bytes of but the highest one are just FF's"
		[^(pointer at: interpreterProxy bytesPerOop - 1)
			> (self cDigitOfCSI: interpreterProxy maxSmallInteger at: interpreterProxy bytesPerOop)].
	"all bytes of but the highest one are just 00's"
	(pointer at: interpreterProxy bytesPerOop - 1)
	 < (self cDigitOfCSI: interpreterProxy minSmallInteger at: interpreterProxy bytesPerOop) ifTrue:
		[^false].
	"if just one digit differs, then anInteger < minval (the corresponding digit byte is greater!)
	 and therefore a LargeNegativeInteger"
	0 to: interpreterProxy bytesPerOop - 1 do:
		[:ix |
		(pointer at: ix) = (self cDigitOfCSI: interpreterProxy minSmallInteger at: ix + 1) ifFalse:
			[^true]].
	^false
]

{ #category : #'oop util' }
LargeIntegersPlugin >> largeInt: aBytesObject growTo: newLen [ 
	"Attention: this method invalidates all oop's! Only newBytes is valid at return."
	"Does not normalize."
	| newBytes oldLen copyLen |
	self remapOop: aBytesObject in: [newBytes := interpreterProxy instantiateClass: (interpreterProxy fetchClassOf: aBytesObject)
					indexableSize: newLen].
	oldLen := self digitSizeOfLargeInt: aBytesObject.
	oldLen < newLen
		ifTrue: [copyLen := oldLen]
		ifFalse: [copyLen := newLen].
	self
		cDigitCopyFrom: (interpreterProxy firstIndexableField: aBytesObject)
		to: (interpreterProxy firstIndexableField: newBytes)
		len: copyLen.
	^ newBytes
]

{ #category : #'oop util' }
LargeIntegersPlugin >> largeIntOrInt: oop growTo: len [ 
	"Attention: this method invalidates all oop's! Only newBytes is valid at return."
	| newBytes val class |
	(interpreterProxy isIntegerObject: oop)
		ifTrue: 
			[val := interpreterProxy integerValueOf: oop.
			val < 0
				ifTrue: [class := interpreterProxy classLargeNegativeInteger]
				ifFalse: [class := interpreterProxy classLargePositiveInteger].
			newBytes := interpreterProxy instantiateClass: class indexableSize: len.
			self cCopyIntVal: val toBytes: newBytes]
		ifFalse: [newBytes := self largeInt: oop growTo: len].
	^ newBytes
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
	"Check for leading zeroes and return shortened copy if so."
	"First establish len = significant length."
	| sLen val len oldLen pointer |
	len := oldLen := self digitLengthOfNonImmediate: aLargeNegativeInteger.
	pointer := interpreterProxy
				cCoerce: (interpreterProxy firstIndexableField: aLargeNegativeInteger)
				to: #'unsigned char *'.
	[len > 0 and: [(pointer at: len - 1) = 0]] whileTrue:
		[len := len - 1].
	len = 0 ifTrue: [^ 0 asOop: SmallInteger].

	"Now check if in SmallInteger range"
	sLen := interpreterProxy minSmallInteger < -16r40000000
				ifTrue: [8]
				ifFalse: [4]. "SmallInteger digitLength"
	len <= sLen ifTrue: 
		[(len < sLen
		  or: [(pointer at: sLen - 1)
				< (self cDigitOfCSI: interpreterProxy minSmallInteger at: sLen)]) ifTrue: "interpreterProxy minSmallInteger lastDigit"
			["If high digit less, then can be small"
			val := 0 - (pointer at: (len := len - 1)).
			len - 1 to: 0 by: -1 do:
				[:i | val := val * 256 - (pointer at: i)].
			^val asOop: SmallInteger].
		 1 to: sLen do:
			[:i | | byte | "If all digits same, then = minSmallInteger (sr: minSmallInteger digits 1 to sLen - 1 are 0)"
			byte := i > len ifTrue: [0] ifFalse: [pointer at: i - 1].
			byte ~= (self cDigitOfCSI: interpreterProxy minSmallInteger at: i) ifTrue: "Not so; return self shortened"
				[len < oldLen ifTrue: "^ self growto: len"
					[^self largeInt: aLargeNegativeInteger growTo: len].
				 ^aLargeNegativeInteger]].
		 ^interpreterProxy minSmallInteger asOop: SmallInteger].
	"Return self, or a shortened copy"
	len < oldLen ifTrue: "^ self growto: len"
		[^self largeInt: aLargeNegativeInteger growTo: len].
	^aLargeNegativeInteger
]

{ #category : #'oop functions' }
LargeIntegersPlugin >> normalizePositive: aLargePositiveInteger [ 
	"Check for leading zeroes and return shortened copy if so."
	"First establish len = significant length."
	| sLen val len oldLen pointer |
	<var: #pointer type: #'unsigned char *'>
	len := oldLen := self digitLengthOfNonImmediate: aLargePositiveInteger.
	pointer := interpreterProxy
				cCoerce: (interpreterProxy firstIndexableField: aLargePositiveInteger)
				to: #'unsigned char *'.
	[len > 0 and: [(pointer at: len - 1) = 0]] whileTrue:
		[len := len - 1].
	len = 0 ifTrue: [^ 0 asOop: SmallInteger].

	"Now check if in SmallInteger range"
	sLen := interpreterProxy maxSmallInteger > 16r3FFFFFFF "SmallInteger maxVal digitLength."
				ifTrue: [8]
				ifFalse: [4].
	len <= sLen ifTrue: 
		[(len < sLen
		  or: [(pointer at: sLen - 1) <= (self cDigitOfCSI: interpreterProxy maxSmallInteger at: sLen)]) ifTrue: 
			["If so, return its SmallInt value"
			 val := pointer at: (len := len - 1).
			 len - 1 to: 0 by: -1 do:
				[:i | val := val * 256 + (pointer at: i)].
			^val asOop: SmallInteger]].
	"Return self, or a shortened copy"
	len < oldLen ifTrue: "^ self growto: len"
		[^self largeInt: aLargePositiveInteger growTo: len].
	^aLargePositiveInteger
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
	| firstVal secondVal firstInteger |
	self debugCode: [self msg: 'primDigitCompare: secondInteger'].
	firstInteger := self
				primitive: 'primDigitCompare'
				parameters: #(#Integer )
				receiver: #Integer.
	"shortcut: aSmallInteger has to be smaller in Magnitude as aLargeInteger"
	(interpreterProxy isIntegerObject: firstInteger)
		ifTrue: ["first"
			(interpreterProxy isIntegerObject: secondInteger)
				ifTrue: ["second"
					(firstVal := interpreterProxy integerValueOf: firstInteger) > (secondVal := interpreterProxy integerValueOf: secondInteger)
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
	"Avoid crashes in case of getting unnormalized args."
	(self isNormalized: firstInteger)
		ifFalse: [self
				debugCode: [self msg: 'ERROR in primDigitDiv: secondInteger negative: neg'.
					self msg: '------> receiver *not* normalized!'].
			^ interpreterProxy primitiveFail].
	(self isNormalized: secondInteger)
		ifFalse: [self
				debugCode: [self msg: 'ERROR in primDigitDiv: secondInteger negative: neg'.
					self msg: '------> argument *not* normalized!'].
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
	self st: (interpreterProxy firstIndexableField: strOop)
		rn: self getModuleName
		cpy: strLen.
	^strOop
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primMontgomeryDigitLength [
	self debugCode: [self msg: 'primMontgomeryDigitLength'].
	self
				primitive: 'primMontgomeryDigitLength'
				parameters: #()
				receiver: #Integer.
	^interpreterProxy integerObjectOf: 8
]

{ #category : #'Integer primitives' }
LargeIntegersPlugin >> primMontgomeryTimes: secondOperandInteger modulo: thirdModuloInteger mInvModB: smallInverseInteger [
	| firstLarge secondLarge firstInteger thirdLarge |
	self debugCode: [self msg: 'montgomeryTimes: secondOperandInteger modulo: thirdModuloInteger mInvModB: smallInverseInteger'].
	firstInteger := self
				primitive: 'primMontgomeryTimesModulo'
				parameters: #(Integer Integer SmallInteger )
				receiver: #Integer.
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
	^ self digitMontgomery: firstLarge times: secondLarge modulo: thirdLarge mInvModB: smallInverseInteger
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
LargeIntegersPlugin >> unsafeDigitOf: bytesObj at: ix [
	"Argument bytesObj must not be aSmallInteger!"
	<inline: true>
	^(interpreterProxy cCoerce: (interpreterProxy firstIndexableField: bytesObj) to: #'unsigned char *') at: ix - 1
]
