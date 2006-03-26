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
		'zipBaseDistance'
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
	#category : #'VMMaker-Plugins'
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
	DeflateWindowSize _ 16r8000.
	DeflateWindowMask _ DeflateWindowSize - 1.
	DeflateMinMatch _ 3.
	DeflateMaxMatch _ 258.
	DeflateMaxDistance _ DeflateWindowSize.
	DeflateHashBits _ 15.
	DeflateHashTableSize _ 1 << DeflateHashBits.
	DeflateHashMask _ DeflateHashTableSize - 1.
	DeflateHashShift _ (DeflateHashBits + DeflateMinMatch - 1) // DeflateMinMatch.
	DeflateMaxLiteralCodes _ ZipWriteStream maxLiteralCodes.
	DeflateMaxDistanceCodes _ ZipWriteStream maxDistanceCodes.
]

{ #category : #deflating }
DeflatePlugin >> compare: here with: matchPos min: minLength [
	"Compare the two strings and return the length of matching characters.
	minLength is a lower bound for match lengths that will be accepted.
	Note: here and matchPos are zero based."
	| length |
	self inline: true.
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
	length _ 2.
	[length < DeflateMaxMatch and:[
		(zipCollection at: here+length) = (zipCollection at: matchPos+length)]]
			whileTrue:[length _ length + 1].
	^length
]

{ #category : #deflating }
DeflatePlugin >> deflateBlock: lastIndex chainLength: chainLength goodMatch: goodMatch [
	"Continue deflating the receiver's collection from blockPosition to lastIndex.
	Note that lastIndex must be at least MaxMatch away from the end of collection"
	| here matchResult flushNeeded hereMatch hereLength newMatch newLength hasMatch |
	self inline: false.
	zipBlockPos > lastIndex ifTrue:[^false]. "Nothing to deflate"
	zipLiteralCount >= zipLiteralSize ifTrue:[^true].
	hasMatch _ false.
	here _ zipBlockPos.
	[here <= lastIndex] whileTrue:[
		hasMatch ifFalse:[
			"Find the first match"
			matchResult _ self findMatch: here
								lastLength: DeflateMinMatch-1
								lastMatch: here
								chainLength: chainLength
								goodMatch: goodMatch.
			self insertStringAt: here. "update hash table"
			hereMatch _ matchResult bitAnd: 16rFFFF.
			hereLength _ matchResult bitShift: -16].

		"Look ahead if there is a better match at the next position"
		matchResult _ self findMatch: here+1
							lastLength: hereLength
							lastMatch: hereMatch
							chainLength: chainLength
							goodMatch: goodMatch.
		newMatch _ matchResult bitAnd: 16rFFFF.
		newLength _ matchResult bitShift: -16.

		"Now check if the next match is better than the current one.
		If not, output the current match (provided that the current match
		is at least MinMatch long)"
		(hereLength >= newLength and:[hereLength >= DeflateMinMatch]) ifTrue:[
			"Encode the current match"
			flushNeeded _ self
				encodeMatch: hereLength
				distance: here - hereMatch.
			"Insert all strings up to the end of the current match.
			Note: The first string has already been inserted."
			1 to: hereLength-1 do:[:i| self insertStringAt: (here _ here + 1)].
			hasMatch _ false.
			here _ here + 1.
		] ifFalse:[
			"Either the next match is better than the current one or we didn't
			have a good match after all (e.g., current match length < MinMatch).
			Output a single literal."
			flushNeeded _ self encodeLiteral: (zipCollection at: here).
			here _ here + 1.
			(here <= lastIndex and:[flushNeeded not]) ifTrue:[
				"Cache the results for the next round"
				self insertStringAt: here.
				hasMatch _ true.
				hereMatch _ newMatch.
				hereLength _ newLength].
		].
		flushNeeded ifTrue:[zipBlockPos _ here. ^true].
	].
	zipBlockPos _ here.
	^false
]

{ #category : #encoding }
DeflatePlugin >> encodeLiteral: lit [
	"Encode the given literal"
	self inline: true.
	zipLiterals at: zipLiteralCount put: lit.
	zipDistances at: zipLiteralCount put: 0.
	zipLiteralFreq at: lit put: (zipLiteralFreq at: lit) + 1.
	zipLiteralCount _ zipLiteralCount + 1.
	^zipLiteralCount = zipLiteralSize "We *must* flush"
		or:[(zipLiteralCount bitAnd: 16rFFF) = 0 "Only check every N kbytes"
			and:[self shouldFlush]]
]

{ #category : #encoding }
DeflatePlugin >> encodeMatch: length distance: dist [
	"Encode the given match of length length starting at dist bytes ahead"
	| literal distance |
	self inline: true.
	zipLiterals at: zipLiteralCount put: length - DeflateMinMatch.
	zipDistances at: zipLiteralCount put: dist.
	literal _ (zipMatchLengthCodes at: length - DeflateMinMatch).
	zipLiteralFreq at: literal put: (zipLiteralFreq at: literal) + 1.
	dist < 257
		ifTrue:[distance _ zipDistanceCodes at: dist - 1]
		ifFalse:[distance _ zipDistanceCodes at: 256 + (dist - 1 bitShift: -7)].
	zipDistanceFreq at: distance put: (zipDistanceFreq at: distance) + 1.
	zipLiteralCount _ zipLiteralCount + 1.
	zipMatchCount _ zipMatchCount + 1.
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
	self inline: false.
	"Compute the default match result"
	matchResult _ (lastLength bitShift: 16) bitOr: lastMatch.

	"There is no way to find a better match than MaxMatch"
	lastLength >= DeflateMaxMatch ifTrue:[^matchResult].

	"Start position for searches"
	matchPos _ zipHashHead at: (self updateHashAt: here + DeflateMinMatch - 1).

	"Compute the distance to the (possible) match"
	distance _ here - matchPos.

	"Note: It is required that 0 < distance < MaxDistance"
	(distance > 0 and:[distance < DeflateMaxDistance]) ifFalse:[^matchResult].

	chainLength _ maxChainLength.	"Max. nr of match chain to search"
	here > DeflateMaxDistance	"Limit for matches that are too old"
		ifTrue:[limit _ here - DeflateMaxDistance]
		ifFalse:[limit _ 0].

	"Best match length so far (current match must be larger to take effect)"
	bestLength _ lastLength.

	[true] whileTrue:[
		"Compare the current string with the string at match position"
		length _ self compare: here with: matchPos min: bestLength.
		"Truncate accidental matches beyound stream position"
		(here + length > zipPosition) ifTrue:[length _ zipPosition - here].
		"Ignore very small matches if they are too far away"
		(length = DeflateMinMatch and:[(here - matchPos) > (DeflateMaxDistance // 4)])
			ifTrue:[length _ DeflateMinMatch - 1].
		length > bestLength ifTrue:["We have a new (better) match than before"
			"Compute the new match result"
			matchResult _ (length bitShift: 16) bitOr: matchPos.
			bestLength _ length.
			"There is no way to find a better match than MaxMatch"
			bestLength >= DeflateMaxMatch ifTrue:[^matchResult].
			"But we may have a good, fast match"
			bestLength > goodMatch ifTrue:[^matchResult].
		].
		(chainLength _ chainLength - 1) > 0 ifFalse:[^matchResult].
		"Compare with previous entry in hash chain"
		matchPos _ zipHashTail at: (matchPos bitAnd: DeflateWindowMask).
		matchPos <= limit ifTrue:[^matchResult]. "Match position is too old"
	].
]

{ #category : #deflating }
DeflatePlugin >> insertStringAt: here [
	"Insert the string at the given start position into the hash table.
	Note: The hash value is updated starting at MinMatch-1 since
	all strings before have already been inserted into the hash table
	(and the hash value is updated as well)."
	| prevEntry |
	self inline: true.
	zipHashValue _ self updateHashAt: (here + DeflateMinMatch - 1).
	prevEntry _ zipHashHead at: zipHashValue.
	zipHashHead at: zipHashValue put: here.
	zipHashTail at: (here bitAnd: DeflateWindowMask) put: prevEntry.
]

{ #category : #'primitive support' }
DeflatePlugin >> loadDeflateStreamFrom: rcvr [
	| oop |
	self inline: false.
	((interpreterProxy isPointers: rcvr) and:[
		(interpreterProxy slotSizeOf: rcvr) >= 15]) ifFalse:[^false].
	oop _ interpreterProxy fetchPointer: 0 ofObject: rcvr.
	(interpreterProxy isIntegerObject: oop)
		ifTrue:[^interpreterProxy primitiveFail].
	(interpreterProxy isBytes: oop)
		ifFalse:[^interpreterProxy primitiveFail].
	zipCollection _ interpreterProxy firstIndexableField: oop.
	zipCollectionSize _ interpreterProxy byteSizeOf: oop.

	zipPosition _ interpreterProxy fetchInteger: 1 ofObject: rcvr.
	zipReadLimit _ interpreterProxy fetchInteger: 2 ofObject: rcvr.
	"zipWriteLimit _ interpreterProxy fetchInteger: 3 ofObject: rcvr."

	oop _ interpreterProxy fetchPointer: 4 ofObject: rcvr.
	((interpreterProxy isIntegerObject: oop) or:[
		(interpreterProxy isWords: oop) not]) ifTrue:[^false].
	(interpreterProxy slotSizeOf: oop) = DeflateHashTableSize ifFalse:[^false].
	zipHashHead _ interpreterProxy firstIndexableField: oop.
	oop _ interpreterProxy fetchPointer: 5 ofObject: rcvr.
	((interpreterProxy isIntegerObject: oop) or:[
		(interpreterProxy isWords: oop) not]) ifTrue:[^false].
	(interpreterProxy slotSizeOf: oop) = DeflateWindowSize ifFalse:[^false].
	zipHashTail _ interpreterProxy firstIndexableField: oop.
	zipHashValue _ interpreterProxy fetchInteger: 6 ofObject: rcvr.
	zipBlockPos _ interpreterProxy fetchInteger: 7 ofObject: rcvr.
	"zipBlockStart _ interpreterProxy fetchInteger: 8 ofObject: rcvr."
	oop _ interpreterProxy fetchPointer: 9 ofObject: rcvr.
	((interpreterProxy isIntegerObject: oop) or:[
		(interpreterProxy isBytes: oop) not]) ifTrue:[^false].
	zipLiteralSize _ interpreterProxy slotSizeOf: oop.
	zipLiterals _ interpreterProxy firstIndexableField: oop.

	oop _ interpreterProxy fetchPointer: 10 ofObject: rcvr.
	((interpreterProxy isIntegerObject: oop) or:[
		(interpreterProxy isWords: oop) not]) ifTrue:[^false].
	(interpreterProxy slotSizeOf: oop) < zipLiteralSize ifTrue:[^false].
	zipDistances _ interpreterProxy firstIndexableField: oop.

	oop _ interpreterProxy fetchPointer: 11 ofObject: rcvr.
	((interpreterProxy isIntegerObject: oop) or:[
		(interpreterProxy isWords: oop) not]) ifTrue:[^false].
	(interpreterProxy slotSizeOf: oop) = DeflateMaxLiteralCodes ifFalse:[^false].
	zipLiteralFreq _ interpreterProxy firstIndexableField: oop.

	oop _ interpreterProxy fetchPointer: 12 ofObject: rcvr.
	((interpreterProxy isIntegerObject: oop) or:[
		(interpreterProxy isWords: oop) not]) ifTrue:[^false].
	(interpreterProxy slotSizeOf: oop) = DeflateMaxDistanceCodes ifFalse:[^false].
	zipDistanceFreq _ interpreterProxy firstIndexableField: oop.

	zipLiteralCount _ interpreterProxy fetchInteger: 13 ofObject: rcvr.
	zipMatchCount _ interpreterProxy fetchInteger: 14 ofObject: rcvr.

	^interpreterProxy failed not
]

{ #category : #'primitive support' }
DeflatePlugin >> loadZipEncoderFrom: rcvr [
	| oop |
	self inline: false.
	((interpreterProxy isPointers: rcvr) and:[
		(interpreterProxy slotSizeOf: rcvr) >= 6]) ifFalse:[^false].
	oop _ interpreterProxy fetchPointer: 0 ofObject: rcvr.
	(interpreterProxy isIntegerObject: oop)
		ifTrue:[^interpreterProxy primitiveFail].
	(interpreterProxy isBytes: oop)
		ifFalse:[^interpreterProxy primitiveFail].
	zipCollection _ interpreterProxy firstIndexableField: oop.
	zipCollectionSize _ interpreterProxy byteSizeOf: oop.

	zipPosition _ interpreterProxy fetchInteger: 1 ofObject: rcvr.
	zipReadLimit _ interpreterProxy fetchInteger: 2 ofObject: rcvr.
	"zipWriteLimit _ interpreterProxy fetchInteger: 3 ofObject: rcvr."
	zipBitBuf _ interpreterProxy fetchInteger: 4 ofObject: rcvr.
	zipBitPos _ interpreterProxy fetchInteger: 5 ofObject: rcvr.

	^interpreterProxy failed not
]

{ #category : #encoding }
DeflatePlugin >> nextZipBits: nBits put: value [
	"Require:
		zipCollection, zipCollectionSize, zipPosition,
		zipBitBuf, zipBitPos.
	"
	self inline: true.
	(value >= 0 and:[(1 << nBits) > value])
		ifFalse:[^interpreterProxy primitiveFail].
	zipBitBuf _ zipBitBuf bitOr: (value bitShift: zipBitPos).
	zipBitPos _ zipBitPos + nBits.
	[zipBitPos >= 8 and:[zipPosition < zipCollectionSize]] whileTrue:[
		zipCollection at: zipPosition put: (zipBitBuf bitAnd: 255).
		zipPosition _ zipPosition + 1.
		zipBitBuf _ zipBitBuf >> 8.
		zipBitPos _ zipBitPos - 8].

]

{ #category : #primitives }
DeflatePlugin >> primitiveDeflateBlock [
	"Primitive. Deflate the current contents of the receiver."
	| goodMatch chainLength lastIndex rcvr result |
	self export: true.
	self inline: false.
	interpreterProxy methodArgumentCount = 3
		ifFalse:[^interpreterProxy primitiveFail].
	goodMatch _ interpreterProxy stackIntegerValue: 0.
	chainLength _ interpreterProxy stackIntegerValue: 1.
	lastIndex _ interpreterProxy stackIntegerValue: 2.
	rcvr _ interpreterProxy stackObjectValue: 3.
	interpreterProxy failed ifTrue:[^nil].
	self cCode:'' inSmalltalk:[
		zipMatchLengthCodes _ CArrayAccessor on: ZipWriteStream matchLengthCodes.
		zipDistanceCodes _ CArrayAccessor on: ZipWriteStream distanceCodes].
	(self loadDeflateStreamFrom: rcvr)
		ifFalse:[^interpreterProxy primitiveFail].
	result _ self deflateBlock: lastIndex chainLength: chainLength goodMatch: goodMatch.
	interpreterProxy failed ifFalse:[
		"Store back modified values"
		interpreterProxy storeInteger: 6 ofObject: rcvr withValue: zipHashValue.
		interpreterProxy storeInteger: 7 ofObject: rcvr withValue: zipBlockPos.
		interpreterProxy storeInteger: 13 ofObject: rcvr withValue: zipLiteralCount.
		interpreterProxy storeInteger: 14 ofObject: rcvr withValue: zipMatchCount].
	interpreterProxy failed ifFalse:[
		interpreterProxy pop: 4.
		interpreterProxy pushBool: result.
	].
]

{ #category : #primitives }
DeflatePlugin >> primitiveDeflateUpdateHashTable [
	"Primitive. Update the hash tables after data has been moved by delta."
	| delta table tableSize tablePtr entry |
	self export: true.
	self var: #tablePtr type:'int *'.
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	delta _ interpreterProxy stackIntegerValue: 0.
	table _ interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isWords: table)
		ifFalse:[^interpreterProxy primitiveFail].
	tableSize _ interpreterProxy slotSizeOf: table.
	tablePtr _ interpreterProxy firstIndexableField: table.
	0 to: tableSize-1 do:[:i|
		entry _ tablePtr at: i.
		entry >= delta
			ifTrue:[tablePtr at: i put: entry - delta]
			ifFalse:[tablePtr at: i put: 0]].
	interpreterProxy pop: 2. "Leave rcvr on stack"
]

{ #category : #primitives }
DeflatePlugin >> primitiveUpdateAdler32 [
	"Primitive. Update a 32bit CRC value."
	| collection stopIndex startIndex length bytePtr s1 adler32 s2 b |
	self export: true.
	self var: #adler32 type:'unsigned int '.
	self var: #bytePtr type:'unsigned char *'.
	interpreterProxy methodArgumentCount = 4
		ifFalse:[^interpreterProxy primitiveFail].
	collection _ interpreterProxy stackObjectValue: 0.
	stopIndex _ interpreterProxy stackIntegerValue: 1.
	startIndex _ interpreterProxy stackIntegerValue: 2.
	adler32 _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 3).
	interpreterProxy failed ifTrue:[^0].
	((interpreterProxy isBytes: collection) and:[stopIndex >= startIndex and:[startIndex > 0]])
		ifFalse:[^interpreterProxy primitiveFail].
	length _ interpreterProxy byteSizeOf: collection.
	(stopIndex <= length) ifFalse:[^interpreterProxy primitiveFail].
	bytePtr _ interpreterProxy firstIndexableField: collection.
	startIndex _ startIndex - 1.
	stopIndex _ stopIndex - 1.
	s1 := adler32 bitAnd: 16rFFFF.
	s2 := (adler32 >> 16) bitAnd: 16rFFFF.
	startIndex to: stopIndex do:[:i|
		b := bytePtr at: i.
		s1 := (s1 + b) \\ 65521.
		s2 := (s2 + s1) \\ 65521.
	].
	adler32 := (s2 bitShift: 16) + s1.
	interpreterProxy pop: 5. "args + rcvr"
	interpreterProxy push: (interpreterProxy positive32BitIntegerFor: adler32).
]

{ #category : #primitives }
DeflatePlugin >> primitiveUpdateGZipCrc32 [
	"Primitive. Update a 32bit CRC value."
	| collection stopIndex startIndex crc length bytePtr |
	self export: true.
	self var: #crc type:'unsigned int '.
	self var: #bytePtr type:'unsigned char *'.
	self var: #crcTable type:'unsigned int *'.
	interpreterProxy methodArgumentCount = 4
		ifFalse:[^interpreterProxy primitiveFail].
	collection _ interpreterProxy stackObjectValue: 0.
	stopIndex _ interpreterProxy stackIntegerValue: 1.
	startIndex _ interpreterProxy stackIntegerValue: 2.
	crc _ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 3).
	interpreterProxy failed ifTrue:[^0].
	((interpreterProxy isBytes: collection) and:[stopIndex >= startIndex and:[startIndex > 0]])
		ifFalse:[^interpreterProxy primitiveFail].
	length _ interpreterProxy byteSizeOf: collection.
	(stopIndex <= length) ifFalse:[^interpreterProxy primitiveFail].
	bytePtr _ interpreterProxy firstIndexableField: collection.
	self cCode:'' inSmalltalk:[zipCrcTable _ CArrayAccessor on: GZipWriteStream crcTable].
	startIndex _ startIndex - 1.
	stopIndex _ stopIndex - 1.
	startIndex to: stopIndex do:[:i|
		crc _ (zipCrcTable at: ((crc bitXor: (bytePtr at: i)) bitAnd: 255)) bitXor: (crc >> 8).
	].
	interpreterProxy pop: 5. "args + rcvr"
	interpreterProxy push: (interpreterProxy positive32BitIntegerFor: crc).
]

{ #category : #primitives }
DeflatePlugin >> primitiveZipSendBlock [
	| distTree litTree distStream litStream rcvr result |
	self export: true.
	interpreterProxy methodArgumentCount = 4 
		ifFalse:[^interpreterProxy primitiveFail].
	distTree _ interpreterProxy stackObjectValue: 0.
	litTree _ interpreterProxy stackObjectValue: 1.
	distStream _ interpreterProxy stackObjectValue: 2.
	litStream _ interpreterProxy stackObjectValue: 3.
	rcvr _ interpreterProxy stackObjectValue: 4.
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
		zipMatchLengthCodes _ CArrayAccessor on: ZipWriteStream matchLengthCodes.
		zipDistanceCodes _ CArrayAccessor on: ZipWriteStream distanceCodes.
		zipExtraLengthBits _ CArrayAccessor on: ZipWriteStream extraLengthBits.
		zipExtraDistanceBits _ CArrayAccessor on: ZipWriteStream extraDistanceBits.
		zipBaseLength _ CArrayAccessor on: ZipWriteStream baseLength.
		zipBaseDistance _ CArrayAccessor on: ZipWriteStream baseDistance].
	result _ self sendBlock: litStream with: distStream with: litTree with: distTree.
	interpreterProxy failed ifFalse:[
		interpreterProxy storeInteger: 1 ofObject: rcvr withValue: zipPosition.
		interpreterProxy storeInteger: 4 ofObject: rcvr withValue: zipBitBuf.
		interpreterProxy storeInteger: 5 ofObject: rcvr withValue: zipBitPos.
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
	self var: #litArray type:'unsigned char *'.
	self var: #distArray type:'unsigned int *'.
	self var: #llBitLengths type:'unsigned int *'.
	self var: #llCodes type:'unsigned int *'.
	self var: #distBitLengths type:'unsigned int *'.
	self var: #distCodes type:'unsigned int *'.
	oop _ interpreterProxy fetchPointer: 0 ofObject: literalStream.
	litPos _ interpreterProxy fetchInteger: 1 ofObject: literalStream.
	litLimit _ interpreterProxy fetchInteger: 2 ofObject: literalStream.
	((interpreterProxy isIntegerObject: oop) not and:[litPos <= litLimit and:[
		litLimit <= (interpreterProxy byteSizeOf: oop) and:[interpreterProxy isBytes: oop]]])
			ifFalse:[^interpreterProxy primitiveFail].
	litArray _ interpreterProxy firstIndexableField: oop.

	oop _ interpreterProxy fetchPointer: 0 ofObject: distanceStream.
	((interpreterProxy isIntegerObject: oop) not and:[
		(interpreterProxy fetchInteger: 1 ofObject: distanceStream) = litPos and:[
			(interpreterProxy fetchInteger: 2 ofObject: distanceStream) = litLimit]])
				ifFalse:[^interpreterProxy primitiveFail].
	((interpreterProxy isWords: oop) and:[
		litLimit <= (interpreterProxy slotSizeOf: oop)])
			ifFalse:[^interpreterProxy primitiveFail].
	distArray _ interpreterProxy firstIndexableField: oop.

	oop _ interpreterProxy fetchPointer: 0 ofObject: litTree.
	((interpreterProxy isIntegerObject: oop) not and:[interpreterProxy isWords: oop])
		ifFalse:[^interpreterProxy primitiveFail].
	litBlCount _ interpreterProxy slotSizeOf: oop.
	llBitLengths _ interpreterProxy firstIndexableField: oop.

	oop _ interpreterProxy fetchPointer: 1 ofObject: litTree.
	((interpreterProxy isIntegerObject: oop) not and:[interpreterProxy isWords: oop])
		ifFalse:[^interpreterProxy primitiveFail].
	(litBlCount = (interpreterProxy slotSizeOf: oop))
		ifFalse:[^interpreterProxy primitiveFail].
	llCodes _ interpreterProxy firstIndexableField: oop.

	oop _ interpreterProxy fetchPointer: 0 ofObject: distTree.
	((interpreterProxy isIntegerObject: oop) not and:[interpreterProxy isWords: oop])
		ifFalse:[^interpreterProxy primitiveFail].
	distBlCount _ interpreterProxy slotSizeOf: oop.
	distBitLengths _ interpreterProxy firstIndexableField: oop.

	oop _ interpreterProxy fetchPointer: 1 ofObject: distTree.
	((interpreterProxy isIntegerObject: oop) not and:[interpreterProxy isWords: oop])
		ifFalse:[^interpreterProxy primitiveFail].
	(distBlCount = (interpreterProxy slotSizeOf: oop))
		ifFalse:[^interpreterProxy primitiveFail].
	distCodes _ interpreterProxy firstIndexableField: oop.

	interpreterProxy failed ifTrue:[^nil].

	self nextZipBits: 0 put: 0. "Flush pending bits if necessary"
	sum _ 0.
	[litPos < litLimit and:[zipPosition + 4 < zipCollectionSize]] whileTrue:[
		lit _ litArray at: litPos.
		dist _ distArray at: litPos.
		litPos _ litPos + 1.
		dist = 0 ifTrue:["literal"
			sum _ sum + 1.
			lit < litBlCount ifFalse:[^interpreterProxy primitiveFail].
			self nextZipBits: (llBitLengths at: lit) put: (llCodes at: lit).
		] ifFalse:["match"
			sum _ sum + lit + DeflateMinMatch.
			lit < 256 ifFalse:[^interpreterProxy primitiveFail].
			code _ zipMatchLengthCodes at: lit.
			code < litBlCount ifFalse:[^interpreterProxy primitiveFail].
			self nextZipBits: (llBitLengths at: code) put: (llCodes at: code).
			extra _ zipExtraLengthBits at: code - 257.
			extra = 0 ifFalse:[
				lit _ lit - (zipBaseLength at: code - 257).
				self nextZipBits: extra put: lit].
			dist _ dist - 1.
			dist < 16r8000 ifFalse:[^interpreterProxy primitiveFail].
			dist < 256
				ifTrue:[code _ zipDistanceCodes at: dist]
				ifFalse:[code _ zipDistanceCodes at: 256 + (dist >> 7)].
			code < distBlCount ifFalse:[^interpreterProxy primitiveFail].
			self nextZipBits: (distBitLengths at: code) put: (distCodes at: code).
			extra _ zipExtraDistanceBits at: code.
			extra = 0 ifFalse:[
				dist _ dist - (zipBaseDistance at: code).
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
	self inline: false.
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
	nLits _ zipLiteralCount - zipMatchCount.
	nLits <= zipMatchCount ifTrue:[^false]. "whow! so many matches"
	^nLits * 4 <= zipMatchCount
]

{ #category : #deflating }
DeflatePlugin >> updateHash: nextValue [
	"Update the running hash value based on the next input byte.
	Return the new updated hash value."
	^((zipHashValue bitShift: DeflateHashShift) bitXor: nextValue) bitAnd: DeflateHashMask.
]

{ #category : #deflating }
DeflatePlugin >> updateHashAt: here [
	"Update the hash value at position here (one based)"
	^self updateHash: (zipCollection at: here)
]
