"
This adds Zip deflating support.
InflatePlugin should not be translated but this subclass should since it is incorporated within that class's translation process
"
Class {
	#name : #DeflatePlugin,
	#superclass : #InflatePlugin,
	#instVars : [
		'zipHashHead',
		'zipHashTail',
		'zipHashValue',
		'zipBlockPos',
		'zipBlockStart',
		'zipLiterals',
		'zipDistances',
		'zipLiteralFreq',
		'zipDistanceFreq',
		'zipLiteralCount',
		'zipLiteralSize',
		'zipMatchCount',
		'zipMatchLengthCodes',
		'zipDistanceCodes',
		'zipCrcTable',
		'zipExtraLengthBits',
		'zipExtraDistanceBits',
		'zipBaseLength',
		'zipBaseDistance',
		'writeStreamInstSize'
	],
	#classVars : [
		'DeflateHashBits',
		'DeflateHashMask',
		'DeflateHashShift',
		'DeflateHashTableSize',
		'DeflateMaxDistance',
		'DeflateMaxDistanceCodes',
		'DeflateMaxLiteralCodes',
		'DeflateMaxMatch',
		'DeflateMinMatch',
		'DeflateWindowMask',
		'DeflateWindowSize'
	],
	#category : 'VMMaker-Plugins'
}

{ #category : #translation }
DeflatePlugin class >> declareCVarsIn: cg [
	super declareCVarsIn: cg. "Required since we share some instVars"
	cg var: #zipHashHead type: #'unsigned int*'.
	cg var: #zipHashTail type: #'unsigned int*'.
	cg var: #zipLiterals type: #'unsigned char*'.
	cg var: #zipDistances type: #'unsigned int*'.
	cg var: #zipLiteralFreq type: #'unsigned int*'.
	cg var: #zipDistanceFreq type: #'unsigned int*'.
	cg var: #zipMatchLengthCodes type: #'unsigned int' array: ZipWriteStream matchLengthCodes.
	cg var: #zipDistanceCodes type: #'unsigned int' array: ZipWriteStream distanceCodes.
	cg var: #zipCrcTable type: #'unsigned int' array: GZipWriteStream crcTable.
	cg var: #zipExtraLengthBits type: #'unsigned int' array: ZipWriteStream extraLengthBits.
	cg var: #zipExtraDistanceBits type: #'unsigned int' array: ZipWriteStream extraDistanceBits.
	cg var: #zipBaseLength type: #'unsigned int' array: ZipWriteStream baseLength.
	cg var: #zipBaseDistance type: #'unsigned int' array: ZipWriteStream baseDistance
]

{ #category : #'class initialization' }
DeflatePlugin class >> initialize [
	"DeflatePlugin initialize"
	DeflateWindowSize := 16r8000.
	DeflateWindowMask := DeflateWindowSize - 1.
	DeflateMinMatch := 3.
	DeflateMaxMatch := 258.
	DeflateMaxDistance := DeflateWindowSize.
	DeflateHashBits := 15.
	DeflateHashTableSize := 1 << DeflateHashBits.
	DeflateHashMask := DeflateHashTableSize - 1.
	DeflateHashShift := (DeflateHashBits + DeflateMinMatch - 1) // DeflateMinMatch.
	DeflateMaxLiteralCodes := ZipWriteStream maxLiteralCodes.
	DeflateMaxDistanceCodes := ZipWriteStream maxDistanceCodes.
]

{ #category : #deflating }
DeflatePlugin >> compare: here with: matchPos min: minLength [
	"Compare the two strings and return the length of matching characters.
	minLength is a lower bound for match lengths that will be accepted.
	Note: here and matchPos are zero based."
	| length |
	<inline: true>
	"First test if we can actually get longer than minLength"
	(zipCollection at: here+minLength) = (zipCollection at: matchPos+minLength)
		ifFalse:[^0].
	(zipCollection at: here+minLength-1) = (zipCollection at: matchPos+minLength-1)
		ifFalse:[^0].
	"Then test if we have an initial match at all"
	(zipCollection at: here) = (zipCollection at: matchPos)
		ifFalse:[^0].
	(zipCollection at: here+1) = (zipCollection at: matchPos+1)
		ifFalse:[^1].
	"Finally do the real comparison"
	length := 2.
	[length < DeflateMaxMatch and:[
		(zipCollection at: here+length) = (zipCollection at: matchPos+length)]]
			whileTrue:[length := length + 1].
	^length
]

{ #category : #deflating }
DeflatePlugin >> deflateBlock: lastIndex chainLength: chainLength goodMatch: goodMatch [
	"Continue deflating the receiver's collection from blockPosition to lastIndex.
	Note that lastIndex must be at least MaxMatch away from the end of collection"
	| here matchResult flushNeeded hereMatch hereLength newMatch newLength hasMatch |
	<inline: false>
	zipBlockPos > lastIndex ifTrue:[^false]. "Nothing to deflate"
	zipLiteralCount >= zipLiteralSize ifTrue:[^true].
	hasMatch := false.
	here := zipBlockPos.
	[here <= lastIndex] whileTrue:[
		hasMatch ifFalse:[
			"Find the first match"
			matchResult := self findMatch: here
								lastLength: DeflateMinMatch-1
								lastMatch: here
								chainLength: chainLength
								goodMatch: goodMatch.
			self insertStringAt: here. "update hash table"
			hereMatch := matchResult bitAnd: 16rFFFF.
			hereLength := matchResult bitShift: -16].

		"Look ahead if there is a better match at the next position"
		matchResult := self findMatch: here+1
							lastLength: hereLength
							lastMatch: hereMatch
							chainLength: chainLength
							goodMatch: goodMatch.
		newMatch := matchResult bitAnd: 16rFFFF.
		newLength := matchResult bitShift: -16.

		"Now check if the next match is better than the current one.
		If not, output the current match (provided that the current match
		is at least MinMatch long)"
		(hereLength >= newLength and:[hereLength >= DeflateMinMatch]) ifTrue:[
			"Encode the current match"
			flushNeeded := self
				encodeMatch: hereLength
				distance: here - hereMatch.
			"Insert all strings up to the end of the current match.
			Note: The first string has already been inserted."
			1 to: hereLength-1 do:[:i| self insertStringAt: (here := here + 1)].
			hasMatch := false.
			here := here + 1.
		] ifFalse:[
			"Either the next match is better than the current one or we didn't
			have a good match after all (e.g., current match length < MinMatch).
			Output a single literal."
			flushNeeded := self encodeLiteral: (zipCollection at: here).
			here := here + 1.
			(here <= lastIndex and:[flushNeeded not]) ifTrue:[
				"Cache the results for the next round"
				self insertStringAt: here.
				hasMatch := true.
				hereMatch := newMatch.
				hereLength := newLength].
		].
		flushNeeded ifTrue:[zipBlockPos := here. ^true].
	].
	zipBlockPos := here.
	^false
]

{ #category : #'primitive support' }
DeflatePlugin >> determineSizeOfWriteStream: rcvr [
	"Determine the inst size of the class above DeflateStream or
	 ZipEncoder by looking for the first class whose inst size is less than 7."
	| class |
	class := interpreterProxy fetchClassOf: rcvr.
	[class ~= interpreterProxy nilObject
	 and: [(interpreterProxy instanceSizeOf: class) >= 7]] whileTrue:
		[class := interpreterProxy superclassOf: class].
	class = interpreterProxy nilObject ifTrue:
		[^false].
	writeStreamInstSize := interpreterProxy instanceSizeOf: class.
	^true

]

{ #category : #encoding }
DeflatePlugin >> encodeLiteral: lit [
	"Encode the given literal"
	<inline: true>
	zipLiterals at: zipLiteralCount put: lit.
	zipDistances at: zipLiteralCount put: 0.
	zipLiteralFreq at: lit put: (zipLiteralFreq at: lit) + 1.
	zipLiteralCount := zipLiteralCount + 1.
	^zipLiteralCount = zipLiteralSize "We *must* flush"
		or:[(zipLiteralCount bitAnd: 16rFFF) = 0 "Only check every N kbytes"
			and:[self shouldFlush]]
]

{ #category : #encoding }
DeflatePlugin >> encodeMatch: length distance: dist [
	"Encode the given match of length length starting at dist bytes ahead"
	| literal distance |
	<inline: true>
	zipLiterals at: zipLiteralCount put: length - DeflateMinMatch.
	zipDistances at: zipLiteralCount put: dist.
	literal := (zipMatchLengthCodes at: length - DeflateMinMatch).
	zipLiteralFreq at: literal put: (zipLiteralFreq at: literal) + 1.
	dist < 257
		ifTrue:[distance := zipDistanceCodes at: dist - 1]
		ifFalse:[distance := zipDistanceCodes at: 256 + (dist - 1 bitShift: -7)].
	zipDistanceFreq at: distance put: (zipDistanceFreq at: distance) + 1.
	zipLiteralCount := zipLiteralCount + 1.
	zipMatchCount := zipMatchCount + 1.
	^zipLiteralCount = zipLiteralSize "We *must* flush"
		or:[(zipLiteralCount bitAnd: 16rFFF) = 0 "Only check every N kbytes"
			and:[self shouldFlush]]
]

{ #category : #deflating }
DeflatePlugin >> findMatch: here lastLength: lastLength lastMatch: lastMatch chainLength: maxChainLength goodMatch: goodMatch [
	"Find the longest match for the string starting at here.
	If there is no match longer than lastLength return lastMatch/lastLength.
	Traverse at most maxChainLength entries in the hash table.
	Stop if a match of at least goodMatch size has been found."
	| matchResult matchPos distance chainLength limit bestLength length |
	<inline: false>
	"Compute the default match result"
	matchResult := (lastLength bitShift: 16) bitOr: lastMatch.

	"There is no way to find a better match than MaxMatch"
	lastLength >= DeflateMaxMatch ifTrue:[^matchResult].

	"Start position for searches"
	matchPos := zipHashHead at: (self updateHashAt: here + DeflateMinMatch - 1).

	"Compute the distance to the (possible) match"
	distance := here - matchPos.

	"Note: It is required that 0 < distance < MaxDistance"
	(distance > 0 and:[distance < DeflateMaxDistance]) ifFalse:[^matchResult].

	chainLength := maxChainLength.	"Max. nr of match chain to search"
	here > DeflateMaxDistance	"Limit for matches that are too old"
		ifTrue:[limit := here - DeflateMaxDistance]
		ifFalse:[limit := 0].

	"Best match length so far (current match must be larger to take effect)"
	bestLength := lastLength.

	[true] whileTrue:[
		"Compare the current string with the string at match position"
		length := self compare: here with: matchPos min: bestLength.
		"Truncate accidental matches beyound stream position"
		(here + length > zipPosition) ifTrue:[length := zipPosition - here].
		"Ignore very small matches if they are too far away"
		(length = DeflateMinMatch and:[(here - matchPos) > (DeflateMaxDistance // 4)])
			ifTrue:[length := DeflateMinMatch - 1].
		length > bestLength ifTrue:["We have a new (better) match than before"
			"Compute the new match result"
			matchResult := (length bitShift: 16) bitOr: matchPos.
			bestLength := length.
			"There is no way to find a better match than MaxMatch"
			bestLength >= DeflateMaxMatch ifTrue:[^matchResult].
			"But we may have a good, fast match"
			bestLength > goodMatch ifTrue:[^matchResult].
		].
		(chainLength := chainLength - 1) > 0 ifFalse:[^matchResult].
		"Compare with previous entry in hash chain"
		matchPos := zipHashTail at: (matchPos bitAnd: DeflateWindowMask).
		matchPos <= limit ifTrue:[^matchResult]. "Match position is too old"
	].
]

{ #category : #'initialize-release' }
DeflatePlugin >> initialize [
	writeStreamInstSize := 0.
	super initialize
]

{ #category : #deflating }
DeflatePlugin >> insertStringAt: here [
	"Insert the string at the given start position into the hash table.
	Note: The hash value is updated starting at MinMatch-1 since
	all strings before have already been inserted into the hash table
	(and the hash value is updated as well)."
	| prevEntry |
	<inline: true>
	zipHashValue := self updateHashAt: (here + DeflateMinMatch - 1).
	prevEntry := zipHashHead at: zipHashValue.
	zipHashHead at: zipHashValue put: here.
	zipHashTail at: (here bitAnd: DeflateWindowMask) put: prevEntry.
]

{ #category : #'primitive support' }
DeflatePlugin >> loadDeflateStreamFrom: rcvr [
	| oop |
	<inline: false>
	((interpreterProxy isPointers: rcvr)
	 and: [(interpreterProxy slotSizeOf: rcvr) >= 15]) ifFalse:
		[^false].
	oop := interpreterProxy fetchPointer: 0 ofObject: rcvr.
	(interpreterProxy isBytes: oop) ifFalse:
		[^false].
	writeStreamInstSize = 0 ifTrue:
		[(self determineSizeOfWriteStream: rcvr) ifFalse:
			[^false].
		 "If the receiver wasn't valid then we derived writeStreamInstSize from an invalid source.  discard it."
		 (interpreterProxy slotSizeOf: rcvr) < (writeStreamInstSize + 5) ifTrue:
			[writeStreamInstSize := 0.
			 ^false]].
	zipCollection := interpreterProxy firstIndexableField: oop.
	zipCollectionSize := interpreterProxy byteSizeOf: oop.

	zipPosition := interpreterProxy fetchInteger: 1 ofObject: rcvr.
	zipReadLimit := interpreterProxy fetchInteger: 2 ofObject: rcvr.
	"zipWriteLimit := interpreterProxy fetchInteger: 3 ofObject: rcvr."

	oop := interpreterProxy fetchPointer: writeStreamInstSize + 0 ofObject: rcvr.
	((interpreterProxy isWords: oop)
	 and: [(interpreterProxy slotSizeOf: oop) = DeflateHashTableSize]) ifFalse:
		[^false].
	zipHashHead := interpreterProxy firstIndexableField: oop.
	oop := interpreterProxy fetchPointer: writeStreamInstSize + 1 ofObject: rcvr.
	((interpreterProxy isWords: oop)
	 and: [(interpreterProxy slotSizeOf: oop) = DeflateWindowSize]) ifFalse:
		[^false].
	zipHashTail := interpreterProxy firstIndexableField: oop.
	zipHashValue := interpreterProxy fetchInteger: writeStreamInstSize + 2 ofObject: rcvr.
	zipBlockPos := interpreterProxy fetchInteger: writeStreamInstSize + 3 ofObject: rcvr.
	"zipBlockStart := interpreterProxy fetchInteger: writeStreamInstSize + 4 ofObject: rcvr."
	oop := interpreterProxy fetchPointer: writeStreamInstSize + 5 ofObject: rcvr.
	(interpreterProxy isBytes: oop) ifFalse:
		[^false].
	zipLiteralSize := interpreterProxy slotSizeOf: oop.
	zipLiterals := interpreterProxy firstIndexableField: oop.

	oop := interpreterProxy fetchPointer: writeStreamInstSize + 6 ofObject: rcvr.
	((interpreterProxy isWords: oop)
	 and: [(interpreterProxy slotSizeOf: oop) >= zipLiteralSize]) ifFalse:
		[^false].
	zipDistances := interpreterProxy firstIndexableField: oop.

	oop := interpreterProxy fetchPointer: writeStreamInstSize + 7 ofObject: rcvr.
	((interpreterProxy isWords: oop)
	 and: [(interpreterProxy slotSizeOf: oop) = DeflateMaxLiteralCodes]) ifFalse:
		[^false].
	zipLiteralFreq := interpreterProxy firstIndexableField: oop.

	oop := interpreterProxy fetchPointer: writeStreamInstSize + 8 ofObject: rcvr.
	((interpreterProxy isWords: oop)
	 and: [(interpreterProxy slotSizeOf: oop) = DeflateMaxDistanceCodes]) ifFalse:
		[^false].
	zipDistanceFreq := interpreterProxy firstIndexableField: oop.

	zipLiteralCount := interpreterProxy fetchInteger: writeStreamInstSize + 9 ofObject: rcvr.
	zipMatchCount := interpreterProxy fetchInteger: writeStreamInstSize + 10 ofObject: rcvr.

	^interpreterProxy failed not
]

{ #category : #'primitive support' }
DeflatePlugin >> loadZipEncoderFrom: rcvr [
	| oop |
	<inline: false>
	writeStreamInstSize = 0 ifTrue:
		[(self determineSizeOfWriteStream: rcvr) ifFalse:
			[^false].
		 "If the receiver wasn't valid then we derived writeStreamInstSize from an invalid source.  discard it."
		 (interpreterProxy slotSizeOf: rcvr) < (writeStreamInstSize + 3) ifTrue:
			[writeStreamInstSize := 0.
			 ^false]].
	((interpreterProxy isPointers: rcvr)
	 and: [(interpreterProxy slotSizeOf: rcvr) >= (writeStreamInstSize + 3)]) ifFalse:
		[^false].
	oop := interpreterProxy fetchPointer: 0 ofObject: rcvr.
	(interpreterProxy isBytes: oop) ifFalse:
		[^interpreterProxy primitiveFail].
	zipCollection := interpreterProxy firstIndexableField: oop.
	zipCollectionSize := interpreterProxy byteSizeOf: oop.

	zipPosition := interpreterProxy fetchInteger: 1 ofObject: rcvr.
	zipReadLimit := interpreterProxy fetchInteger: 2 ofObject: rcvr.
	"zipWriteLimit := interpreterProxy fetchInteger: 3 ofObject: rcvr."
	zipBitBuf := interpreterProxy fetchInteger: writeStreamInstSize + 1 ofObject: rcvr.
	zipBitPos := interpreterProxy fetchInteger: writeStreamInstSize + 2 ofObject: rcvr.

	^interpreterProxy failed not
]

{ #category : #encoding }
DeflatePlugin >> nextZipBits: nBits put: value [
	"Require:
		zipCollection, zipCollectionSize, zipPosition,
		zipBitBuf, zipBitPos.
	"
	<inline: true>
	(value >= 0 and:[(1 << nBits) > value])
		ifFalse:[^interpreterProxy primitiveFail].
	zipBitBuf := zipBitBuf bitOr: value << zipBitPos.
	zipBitPos := zipBitPos + nBits.
	[zipBitPos >= 8 and:[zipPosition < zipCollectionSize]] whileTrue:[
		zipCollection at: zipPosition put: (zipBitBuf bitAnd: 255).
		zipPosition := zipPosition + 1.
		zipBitBuf := zipBitBuf >> 8.
		zipBitPos := zipBitPos - 8].

]

{ #category : #primitives }
DeflatePlugin >> primitiveDeflateBlock [
	"Primitive. Deflate the current contents of the receiver."
	| goodMatch chainLength lastIndex rcvr result |
	<export: true>
	<inline: false>
	interpreterProxy methodArgumentCount = 3
		ifFalse:[^interpreterProxy primitiveFail].
	goodMatch := interpreterProxy stackIntegerValue: 0.
	chainLength := interpreterProxy stackIntegerValue: 1.
	lastIndex := interpreterProxy stackIntegerValue: 2.
	rcvr := interpreterProxy stackObjectValue: 3.
	interpreterProxy failed ifTrue:[^nil].
	self cCode:'' inSmalltalk:[
		zipMatchLengthCodes := CArrayAccessor on: ZipWriteStream matchLengthCodes.
		zipDistanceCodes := CArrayAccessor on: ZipWriteStream distanceCodes].
	(self loadDeflateStreamFrom: rcvr)
		ifFalse:[^interpreterProxy primitiveFail].
	result := self deflateBlock: lastIndex chainLength: chainLength goodMatch: goodMatch.
	interpreterProxy failed ifFalse:[
		"Store back modified values"
		interpreterProxy storeInteger: writeStreamInstSize + 2 ofObject: rcvr withValue: zipHashValue.
		interpreterProxy storeInteger: writeStreamInstSize + 3 ofObject: rcvr withValue: zipBlockPos.
		interpreterProxy storeInteger: writeStreamInstSize + 9 ofObject: rcvr withValue: zipLiteralCount.
		interpreterProxy storeInteger: writeStreamInstSize + 10 ofObject: rcvr withValue: zipMatchCount].
	interpreterProxy failed ifFalse:[
		interpreterProxy pop: 4.
		interpreterProxy pushBool: result.
	].
]

{ #category : #primitives }
DeflatePlugin >> primitiveDeflateUpdateHashTable [
	"Primitive. Update the hash tables after data has been moved by delta."
	| delta table tableSize tablePtr entry |
	<export: true>
	<var: #tablePtr type:'int *'>
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	delta := interpreterProxy stackIntegerValue: 0.
	table := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: table)
		ifFalse:[^interpreterProxy primitiveFail].
	tableSize := interpreterProxy slotSizeOf: table.
	tablePtr := interpreterProxy firstIndexableField: table.
	0 to: tableSize-1 do:[:i|
		entry := tablePtr at: i.
		entry >= delta
			ifTrue:[tablePtr at: i put: entry - delta]
			ifFalse:[tablePtr at: i put: 0]].
	interpreterProxy pop: 2. "Leave rcvr on stack"
]

{ #category : #primitives }
DeflatePlugin >> primitiveUpdateAdler32 [
	"Primitive. Update a 32bit CRC value."
	| collection stopIndex startIndex length bytePtr s1 adler32 s2 b |
	<export: true>
	<var: #adler32 type:'unsigned int '>
	<var: #bytePtr type:'unsigned char *'>
	interpreterProxy methodArgumentCount = 4
		ifFalse:[^interpreterProxy primitiveFail].
	collection := interpreterProxy stackObjectValue: 0.
	stopIndex := interpreterProxy stackIntegerValue: 1.
	startIndex := interpreterProxy stackIntegerValue: 2.
	adler32 := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 3).
	interpreterProxy failed ifTrue:[^0].
	((interpreterProxy isBytes: collection) and:[stopIndex >= startIndex and:[startIndex > 0]])
		ifFalse:[^interpreterProxy primitiveFail].
	length := interpreterProxy byteSizeOf: collection.
	(stopIndex <= length) ifFalse:[^interpreterProxy primitiveFail].
	bytePtr := interpreterProxy firstIndexableField: collection.
	startIndex := startIndex - 1.
	stopIndex := stopIndex - 1.
	s1 := adler32 bitAnd: 16rFFFF.
	s2 := (adler32 >> 16) bitAnd: 16rFFFF.
	startIndex to: stopIndex do:[:i|
		b := bytePtr at: i.
		s1 := (s1 + b) \\ 65521.
		s2 := (s2 + s1) \\ 65521.
	].
	adler32 := (s2 bitShift: 16) + s1.
	interpreterProxy
		pop: 5 "args + rcvr"
		thenPush: (interpreterProxy positive32BitIntegerFor: adler32)
]

{ #category : #primitives }
DeflatePlugin >> primitiveUpdateGZipCrc32 [
	"Primitive. Update a 32bit CRC value."
	| collection stopIndex startIndex crc length bytePtr |
	<export: true>
	<var: #bytePtr type: #'unsigned char *'>
	interpreterProxy methodArgumentCount = 4
		ifFalse:[^interpreterProxy primitiveFail].
	collection := interpreterProxy stackObjectValue: 0.
	stopIndex := interpreterProxy stackIntegerValue: 1.
	startIndex := interpreterProxy stackIntegerValue: 2.
	crc := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 3).
	interpreterProxy failed ifTrue: [^self].
	((interpreterProxy isBytes: collection) and:[stopIndex >= startIndex and:[startIndex > 0]])
		ifFalse:[^interpreterProxy primitiveFail].
	length := interpreterProxy byteSizeOf: collection.
	(stopIndex <= length) ifFalse:[^interpreterProxy primitiveFail].
	bytePtr := interpreterProxy firstIndexableField: collection.
	self cCode:'' inSmalltalk:[zipCrcTable := CArrayAccessor on: GZipWriteStream crcTable].
	startIndex := startIndex - 1.
	stopIndex := stopIndex - 1.
	startIndex to: stopIndex do:
		[:i|
		crc := (zipCrcTable at: ((crc bitXor: (bytePtr at: i)) bitAnd: 255)) bitXor: (crc >> 8)].
	interpreterProxy
		pop: 5 "args + rcvr"
		thenPush: (interpreterProxy positive32BitIntegerFor: crc)
]

{ #category : #primitives }
DeflatePlugin >> primitiveZipSendBlock [
	| distTree litTree distStream litStream rcvr result |
	<export: true>
	interpreterProxy methodArgumentCount = 4 
		ifFalse:[^interpreterProxy primitiveFail].
	distTree := interpreterProxy stackObjectValue: 0.
	litTree := interpreterProxy stackObjectValue: 1.
	distStream := interpreterProxy stackObjectValue: 2.
	litStream := interpreterProxy stackObjectValue: 3.
	rcvr := interpreterProxy stackObjectValue: 4.
	interpreterProxy failed ifTrue:[^nil].
	(self loadZipEncoderFrom: rcvr)
		ifFalse:[^interpreterProxy primitiveFail].
	((interpreterProxy isPointers: distTree) and:[
		(interpreterProxy slotSizeOf: distTree) >= 2])
			ifFalse:[^interpreterProxy primitiveFail].
	((interpreterProxy isPointers: litTree) and:[
		(interpreterProxy slotSizeOf: litTree) >= 2])
			ifFalse:[^interpreterProxy primitiveFail].
	((interpreterProxy isPointers: litStream) and:[
		(interpreterProxy slotSizeOf: litStream) >= 3])
			ifFalse:[^interpreterProxy primitiveFail].
	((interpreterProxy isPointers: distStream) and:[
		(interpreterProxy slotSizeOf: distStream) >= 3])
			ifFalse:[^interpreterProxy primitiveFail].
	self cCode:'' inSmalltalk:[
		zipMatchLengthCodes := CArrayAccessor on: ZipWriteStream matchLengthCodes.
		zipDistanceCodes := CArrayAccessor on: ZipWriteStream distanceCodes.
		zipExtraLengthBits := CArrayAccessor on: ZipWriteStream extraLengthBits.
		zipExtraDistanceBits := CArrayAccessor on: ZipWriteStream extraDistanceBits.
		zipBaseLength := CArrayAccessor on: ZipWriteStream baseLength.
		zipBaseDistance := CArrayAccessor on: ZipWriteStream baseDistance].
	result := self sendBlock: litStream with: distStream with: litTree with: distTree.
	interpreterProxy failed ifFalse:[
		interpreterProxy storeInteger: 1 ofObject: rcvr withValue: zipPosition.
		interpreterProxy storeInteger: readStreamInstSize + 1 ofObject: rcvr withValue: zipBitBuf.
		interpreterProxy storeInteger: readStreamInstSize + 2 ofObject: rcvr withValue: zipBitPos.
	].
	interpreterProxy failed ifFalse:[
		interpreterProxy pop: 5. "rcvr + args"
		interpreterProxy pushInteger: result.
	].
]

{ #category : #encoding }
DeflatePlugin >> sendBlock: literalStream with: distanceStream with: litTree with: distTree [
	"Require: 
		zipCollection, zipCollectionSize, zipPosition,
		zipBitBuf, zipBitPos.
	"
	| oop litPos litLimit litArray distArray lit dist sum llBitLengths llCodes distBitLengths distCodes code extra litBlCount distBlCount |
	<var: #litArray type: #'unsigned char *'>
	<var: #distArray type: #'unsigned int *'>
	<var: #llBitLengths type: #'unsigned int *'>
	<var: #llCodes type: #'unsigned int *'>
	<var: #distBitLengths type: #'unsigned int *'>
	<var: #distCodes type: #'unsigned int *'>
	oop := interpreterProxy fetchPointer: 0 ofObject: literalStream.
	litPos := interpreterProxy fetchInteger: 1 ofObject: literalStream.
	litLimit := interpreterProxy fetchInteger: 2 ofObject: literalStream.
	(litPos <= litLimit
	 and: [(interpreterProxy isBytes: oop)
	 and: [litLimit <= (interpreterProxy byteSizeOf: oop)]]) ifFalse:
		[^interpreterProxy primitiveFail].
	litArray := interpreterProxy firstIndexableField: oop.

	oop := interpreterProxy fetchPointer: 0 ofObject: distanceStream.
	((interpreterProxy isWords: oop)
	 and: [litLimit <= (interpreterProxy slotSizeOf: oop)
	 and: [(interpreterProxy fetchInteger: 1 ofObject: distanceStream) = litPos
	 and: [(interpreterProxy fetchInteger: 2 ofObject: distanceStream) = litLimit]]]) ifFalse:
		[^interpreterProxy primitiveFail].
	distArray := interpreterProxy firstIndexableField: oop.

	oop := interpreterProxy fetchPointer: 0 ofObject: litTree.
	(interpreterProxy isWords: oop) ifFalse:
		[^interpreterProxy primitiveFail].
	litBlCount := interpreterProxy slotSizeOf: oop.
	llBitLengths := interpreterProxy firstIndexableField: oop.

	oop := interpreterProxy fetchPointer: 1 ofObject: litTree.
	((interpreterProxy isWords: oop)
	 and: [litBlCount = (interpreterProxy slotSizeOf: oop)]) ifFalse:
		[^interpreterProxy primitiveFail].
	llCodes := interpreterProxy firstIndexableField: oop.

	oop := interpreterProxy fetchPointer: 0 ofObject: distTree.
	(interpreterProxy isWords: oop) ifFalse:
		[^interpreterProxy primitiveFail].
	distBlCount := interpreterProxy slotSizeOf: oop.
	distBitLengths := interpreterProxy firstIndexableField: oop.

	oop := interpreterProxy fetchPointer: 1 ofObject: distTree.
	((interpreterProxy isWords: oop)
	 and: [distBlCount = (interpreterProxy slotSizeOf: oop)]) ifFalse:
		[^interpreterProxy primitiveFail].
	distCodes := interpreterProxy firstIndexableField: oop.

	self nextZipBits: 0 put: 0. "Flush pending bits if necessary"
	sum := 0.
	[litPos < litLimit and:[zipPosition + 4 < zipCollectionSize]] whileTrue:[
		lit := litArray at: litPos.
		dist := distArray at: litPos.
		litPos := litPos + 1.
		dist = 0 ifTrue:["literal"
			sum := sum + 1.
			lit < litBlCount ifFalse:[^interpreterProxy primitiveFail].
			self nextZipBits: (llBitLengths at: lit) put: (llCodes at: lit).
		] ifFalse:["match"
			sum := sum + lit + DeflateMinMatch.
			lit < 256 ifFalse:[^interpreterProxy primitiveFail].
			code := zipMatchLengthCodes at: lit.
			code < litBlCount ifFalse:[^interpreterProxy primitiveFail].
			self nextZipBits: (llBitLengths at: code) put: (llCodes at: code).
			extra := zipExtraLengthBits at: code - 257.
			extra = 0 ifFalse:[
				lit := lit - (zipBaseLength at: code - 257).
				self nextZipBits: extra put: lit].
			dist := dist - 1.
			dist < 16r8000 ifFalse:[^interpreterProxy primitiveFail].
			dist < 256
				ifTrue:[code := zipDistanceCodes at: dist]
				ifFalse:[code := zipDistanceCodes at: 256 + (dist >> 7)].
			code < distBlCount ifFalse:[^interpreterProxy primitiveFail].
			self nextZipBits: (distBitLengths at: code) put: (distCodes at: code).
			extra := zipExtraDistanceBits at: code.
			extra = 0 ifFalse:[
				dist := dist - (zipBaseDistance at: code).
				self nextZipBits: extra put: dist].
		].
	].
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy storeInteger: 1 ofObject: literalStream withValue: litPos.
	interpreterProxy storeInteger: 1 ofObject: distanceStream withValue: litPos.
	^sum
]

{ #category : #encoding }
DeflatePlugin >> shouldFlush [
	"Check if we should flush the current block.
	Flushing can be useful if the input characteristics change."
	| nLits |
	<inline: false>
	zipLiteralCount = zipLiteralSize ifTrue:[^true]. "We *must* flush"
	(zipLiteralCount bitAnd: 16rFFF) = 0 ifFalse:[^false]. "Only check every N kbytes"
	zipMatchCount * 10 <= zipLiteralCount ifTrue:[
		"This is basically random data. 
		There is no need to flush early since the overhead
		for encoding the trees will add to the overall size"
		^false].
	"Try to adapt to the input data.
	We flush if the ratio between matches and literals
	changes beyound a certain threshold"
	nLits := zipLiteralCount - zipMatchCount.
	nLits <= zipMatchCount ifTrue:[^false]. "whow! so many matches"
	^nLits * 4 <= zipMatchCount
]

{ #category : #deflating }
DeflatePlugin >> updateHash: nextValue [
	"Update the running hash value based on the next input byte.
	Return the new updated hash value."
	^((zipHashValue << DeflateHashShift) bitXor: nextValue) bitAnd: DeflateHashMask.
]

{ #category : #deflating }
DeflatePlugin >> updateHashAt: here [
	"Update the hash value at position here (one based)"
	^self updateHash: (zipCollection at: here)
]
