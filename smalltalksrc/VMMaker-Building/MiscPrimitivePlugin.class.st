"
This plugin pulls together a number of string and array related primitives.  In the olden days these primitives were generated as ""translated primitives"", which generated the primitive versions form methods in the image.  In 2018 they were rewritten to use conventional Slang.
"
Class {
	#name : #MiscPrimitivePlugin,
	#superclass : #InterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #'helper functions' }
MiscPrimitivePlugin >> encodeBytesOf: anInt in: ba at: i [
	"Copy the integer anInt into byteArray ba at index i, and answer the next index"
	<inline: #always>
	<var: #ba type: #'unsigned char *'>
	0 to: 3 do:
		[:j | ba at: i + j put: (anInt >> (3 - j * 8) bitAnd: 16rFF)].
	^i + 4
]

{ #category : #'helper functions' }
MiscPrimitivePlugin >> encodeInt: anInt in: ba at: i [
	"Encode the integer anInt in byteArray ba at index i, and answer the next index.
	 The encoding is as follows...
		0-223		0-223
		224-254	(0-30) * 256 + next byte (0-7935)
		255		next 4 bytes"		

	<inline: #always>
	<var: #ba declareC: 'unsigned char *ba'>
	anInt <= 223 ifTrue: [ba at: i put: anInt. ^i + 1].
	anInt <= 7935 ifTrue: [ba at: i put: anInt // 256 + 224. ba at: i + 1 put: anInt \\ 256. ^i + 2].
	ba at: i put: 255.
	^self encodeBytesOf: anInt in: ba at: i + 1
]

{ #category : #primitives }
MiscPrimitivePlugin >> primitiveCompareString [
	"ByteString (class) compare: string1 with: string2 collated: order"
	<export: true>
	| len1 len2 order string1 string2 orderOop string1Oop string2Oop |

	<var: 'order' type: #'unsigned char *'>
	<var: 'string1' type: #'unsigned char *'>
	<var: 'string2' type: #'unsigned char *'>
	orderOop := interpreterProxy stackValue: 0.
	string2Oop := interpreterProxy stackValue: 1.
	string1Oop := interpreterProxy stackValue: 2.
	((interpreterProxy isBytes: orderOop)
	and: [(interpreterProxy isBytes: string2Oop)
	and: [interpreterProxy isBytes: string1Oop]]) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	order := interpreterProxy firstIndexableField: orderOop.
	(interpreterProxy sizeOfSTArrayFromCPrimitive: order) < 256 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	string1 := interpreterProxy firstIndexableField: string1Oop.
	string2 := interpreterProxy firstIndexableField: string2Oop.
	len1 := interpreterProxy sizeOfSTArrayFromCPrimitive: string1.
	len2 := interpreterProxy sizeOfSTArrayFromCPrimitive: string2.
	0 to: (len1 min: len2) - 1 do: 
		[ :i | | c1 c2 |
		c1 := order at: (string1 at: i).
		c2 := order at: (string2 at: i).
		c1 = c2 ifFalse:
			[^interpreterProxy methodReturnInteger: (c1 < c2 ifTrue: [1] ifFalse: [3])]].
	interpreterProxy methodReturnInteger:
		(len1 = len2 ifTrue: [2] ifFalse: [len1 < len2 ifTrue: [1] ifFalse: [3]])
]

{ #category : #primitives }
MiscPrimitivePlugin >> primitiveCompressToByteArray [
	"Bitmap compress: bm toByteArray: ba"
	<export: true>
	| bm ba eqBytes i j k lowByte size destSize word |
	<var: 'ba' type: #'unsigned char *'>
	<var: 'bm' type: #'int *'>
	bm := self cCode: [interpreterProxy arrayValueOf: (interpreterProxy stackValue: 1)]
				inSmalltalk: [interpreterProxy
								cCoerce: (interpreterProxy arrayValueOf: (interpreterProxy stackValue: 1))
								to: #'int *'].
	interpreterProxy failed ifTrue: [^nil].
	(interpreterProxy isBytes: (interpreterProxy stackValue: 0)) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(interpreterProxy isOopImmutable: (interpreterProxy stackValue: 0)) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	ba := interpreterProxy firstIndexableField: (interpreterProxy stackValue: 0).
	size := interpreterProxy sizeOfSTArrayFromCPrimitive: bm.
	destSize := interpreterProxy sizeOfSTArrayFromCPrimitive: ba.
	destSize < ((size * 4) + 7 + (size // 1984 * 3)) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrUnsupported]. "Size may be OK but we don't know, hence fail with unsupported"
	i := self encodeInt: size in: ba at: 0.
	k := 0.
	[k < size] whileTrue: 
		[word := bm at: k.
		lowByte := word bitAnd: 255.
		eqBytes := (word >> 8 bitAnd: 255) = lowByte and: [(word >> 16 bitAnd: 255) = lowByte and: [(word >> 24 bitAnd: 255) = lowByte]].
		j := k.
		[j + 1 < size and: [word = (bm at: j + 1)]] whileTrue: [j := j + 1].
		j > k
			ifTrue: 
				[eqBytes
					ifTrue: 
						[i := self encodeInt: j - k + 1 * 4 + 1 in: ba at: i.
						ba at: i put: lowByte.
						i := i + 1]
					ifFalse: 
						[i := self encodeInt: j - k + 1 * 4 + 2 in: ba at: i.
						i := self encodeBytesOf: word in: ba at: i].
				k := j + 1]
			ifFalse:
				[eqBytes
					ifTrue: 
						[i := self encodeInt: 1 * 4 + 1 in: ba at: i.
						ba at: i put: lowByte.
						i := i + 1.
						k := k + 1]
					ifFalse: 
						[[j + 1 < size and: [(bm at: j) ~= (bm at: j + 1)]] whileTrue: [j := j + 1].
						j + 1 = size ifTrue: [j := j + 1].
						i := self encodeInt: j - k * 4 + 3 in: ba at: i.
						k to: j - 1 by: 1 do: [ :m | i := self encodeBytesOf: (bm at: m) in: ba at: i].
						k := j]]].
	interpreterProxy methodReturnInteger: i
]

{ #category : #primitives }
MiscPrimitivePlugin >> primitiveConvert8BitSigned [
	"SampledSound (class) convert8bitSignedFrom: aByteArray to16Bit: aSoundBuffer"
	<export: true>
	| aByteArray aSoundBuffer arraySize byteArrayOop soundBufferOop |

	<var: 'aByteArray' type: #'unsigned char *'>
	<var: 'aSoundBuffer' type: #'unsigned short *'>
	byteArrayOop := interpreterProxy stackValue: 1.
	(interpreterProxy isBytes: byteArrayOop) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	aByteArray := interpreterProxy firstIndexableField: byteArrayOop.
	soundBufferOop := interpreterProxy stackValue: 0.
	aSoundBuffer := self
						cCode: [interpreterProxy arrayValueOf: soundBufferOop]
						inSmalltalk: [interpreterProxy
										cCoerce: (interpreterProxy arrayValueOf: soundBufferOop)
										to: #'unsigned short *'].
	interpreterProxy failed ifTrue: [^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(interpreterProxy isOopImmutable: soundBufferOop) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	arraySize := interpreterProxy sizeOfSTArrayFromCPrimitive: aByteArray.
	(interpreterProxy byteSizeOf: soundBufferOop) < (2 * arraySize) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	0 to: arraySize - 1 do: 
		[ :i | | s |
		s := aByteArray at: i.
		aSoundBuffer
			at: i
			put: (s > 127
					ifTrue: [s - 256 bitShift: 8]
					ifFalse: [s bitShift: 8])].
	interpreterProxy methodReturnReceiver
]

{ #category : #primitives }
MiscPrimitivePlugin >> primitiveDecompressFromByteArray [
	"Bitmap decompress: bm fromByteArray: ba at: index"
	<export: true>
	| bm ba index i anInt code data end k n pastEnd |
	<var: 'ba' type: #'unsigned char *'>
	<var: 'bm' type: #'int *'>
	<var: 'anInt' type: #'unsigned int'>
	<var: 'code' type: #'unsigned int'>
	<var: 'data' type: #'unsigned int'>
	<var: 'n' type: #'unsigned int'>
	bm := self cCode: [interpreterProxy arrayValueOf: (interpreterProxy stackValue: 2)]
				inSmalltalk: [interpreterProxy
								cCoerce: (interpreterProxy arrayValueOf: (interpreterProxy stackValue: 2))
								to: #'int *'].
	(interpreterProxy isOopImmutable: (interpreterProxy stackValue: 2)) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	(interpreterProxy isBytes: (interpreterProxy stackValue: 1)) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	ba := interpreterProxy firstIndexableField: (interpreterProxy stackValue: 1).
	index := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue: [^nil].
	i := index - 1.
	k := 0.
	end := interpreterProxy sizeOfSTArrayFromCPrimitive: ba.
	pastEnd := interpreterProxy sizeOfSTArrayFromCPrimitive: bm.
	[i < end] whileTrue: 
		[anInt := ba at: i.
		i := i + 1.
		anInt <= 223 ifFalse:
			[anInt <= 254
				ifTrue: 
					[anInt := anInt - 224 * 256 + (ba at: i).
					i := i + 1]
				ifFalse: 
					[anInt := 0.
					1 to: 4 by: 1 do: 
						[ :j | anInt := (anInt bitShift: 8) + (ba at: i).
						i := i + 1]]].
		n := anInt >> 2.
		k + n > pastEnd ifTrue:
			[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
		code := anInt bitAnd: 3.
		"code = 0 ifTrue: [nil]."
		code = 1 ifTrue: 
			[data := ba at: i.
			i := i + 1.
			data := data bitOr: (data bitShift: 8).
			data := data bitOr: (data bitShift: 16).
			1 to: n do: 
				[ :j |
				bm at: k put: data.
				k := k + 1]].
		code = 2 ifTrue: 
			[data := 0.
			1 to: 4 do: 
				[ :j |
				data := (data bitShift: 8) bitOr: (ba at: i).
				i := i + 1].
			1 to: n do: 
				[ :j |
				bm at: k put: data.
				k := k + 1]].
		code = 3 ifTrue:
			[1 to: n do: 
				[ :m |
				data := 0.
				1 to: 4 do: 
					[ :j |
					data := (data bitShift: 8) bitOr: (ba at: i).
					i := i + 1].
				bm at: k put: data.
				k := k + 1]]].
	interpreterProxy pop: interpreterProxy methodArgumentCount
]

{ #category : #primitives }
MiscPrimitivePlugin >> primitiveFindFirstInString [
	"ByteString (class) findFirstInString: aString inSet: inclusionMap  startingAt: start"
	<export: true>
	
	|  aString i inclusionMap stringSize aStringOop inclusionMapOop |
	<var: 'aString' type: #'unsigned char *'>
	<var: 'inclusionMap' type: #'unsigned char *'>
	aStringOop := interpreterProxy stackValue: 2.
	(interpreterProxy isBytes: aStringOop) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	inclusionMapOop :=  interpreterProxy stackValue: 1.
	(interpreterProxy isBytes: inclusionMapOop) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	i := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue: [^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	i := i - 1. "Convert to 0-based index."
	i < 0 ifTrue: [^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	inclusionMap := interpreterProxy firstIndexableField: inclusionMapOop.
	(interpreterProxy sizeOfSTArrayFromCPrimitive: inclusionMap) ~= 256 ifTrue:
		[^interpreterProxy methodReturnInteger: 0].
	aString := interpreterProxy firstIndexableField: aStringOop.
	stringSize := interpreterProxy sizeOfSTArrayFromCPrimitive: aString.
	[i < stringSize and: [(inclusionMap at: (aString at: i)) = 0]] whileTrue:
		[i := i + 1].
	interpreterProxy methodReturnInteger: (i >= stringSize ifTrue: [0] ifFalse: [i + 1])
]

{ #category : #primitives }
MiscPrimitivePlugin >> primitiveFindSubstring [
	"ByteString findSubstring: key in: body startingAt: start matchTable: matchTable"
	<export: true>

	| body key keySize matchTable start bodyOop keyOop matchTableOop |
	<var: #key type: #'unsigned char *'>
	<var: #body type: #'unsigned char *'>
	<var: #matchTable type: #'unsigned char *'>
	keyOop := interpreterProxy stackValue: 3.
	(interpreterProxy isBytes: keyOop) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	bodyOop := interpreterProxy stackValue: 2.
	(interpreterProxy isBytes: bodyOop) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	start := interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue: 
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	matchTableOop := interpreterProxy stackValue: 0.
	(interpreterProxy isBytes: matchTableOop) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	matchTable := interpreterProxy firstIndexableField: matchTableOop.
	(interpreterProxy sizeOfSTArrayFromCPrimitive: matchTable) < 256 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].		
	key := interpreterProxy firstIndexableField: keyOop.
	(keySize := interpreterProxy sizeOfSTArrayFromCPrimitive: key) > 0 ifTrue:
		[keySize := keySize - 1. "adjust for zero relative indexes"
		start := start - 1 max: 0. "adjust for zero relative indexes"
		body := interpreterProxy firstIndexableField: bodyOop.	
		start to: (interpreterProxy sizeOfSTArrayFromCPrimitive: body) - 1 - keySize do: 
			[ :startIndex | | index |
			index := 0.
			[(matchTable at: (body at: startIndex + index)) = (matchTable at: (key at: index))] whileTrue: 
				[index = keySize ifTrue:
					[^interpreterProxy methodReturnInteger: startIndex + 1].
				index := index + 1]]].
	^interpreterProxy methodReturnInteger: 0
]

{ #category : #primitives }
MiscPrimitivePlugin >> primitiveIndexOfAsciiInString [
	"ByteString indexOfAscii: anInteger inString: aString startingAt: start"
	<export: true>

	| anInteger aString start stringSize aStringOop |
	<var: #aString type: #'unsigned char *'>
	anInteger := interpreterProxy stackIntegerValue: 2.
	interpreterProxy failed ifTrue: 
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	aStringOop := interpreterProxy stackValue: 1.
	(interpreterProxy isBytes: aStringOop) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	start := interpreterProxy stackIntegerValue: 0.	
	interpreterProxy failed ifTrue: 
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	start >= 1 ifFalse: [^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	aString := interpreterProxy firstIndexableField: aStringOop.
	stringSize := interpreterProxy sizeOfSTArrayFromCPrimitive: aString.
	start - 1 to: stringSize - 1 do:
		[ :pos |
		(aString at: pos) = anInteger ifTrue:
			[^interpreterProxy methodReturnInteger: pos + 1]].
	^interpreterProxy methodReturnInteger: 0
]

{ #category : #primitives }
MiscPrimitivePlugin >> primitiveStringHash [
	"ByteArray (class) hashBytes: aByteArray startingWith: speciesHash"
	<export: true>

	| aByteArray hash byteArrayOop |
	<var: 'aByteArray' type: #'unsigned char *'>
	<var: 'hash' type: #'unsigned int'>
	hash := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	byteArrayOop := interpreterProxy stackValue: 1.
	(interpreterProxy isBytes: byteArrayOop) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	aByteArray := interpreterProxy firstIndexableField: byteArrayOop.
	0 to: (interpreterProxy sizeOfSTArrayFromCPrimitive: aByteArray) - 1 do: 
		[ :pos |
		hash := hash + (aByteArray at: pos) * 16r19660D ].
	interpreterProxy methodReturnInteger: (hash bitAnd: 16r0FFFFFFF)
]

{ #category : #primitives }
MiscPrimitivePlugin >> primitiveTranslateStringWithTable [
	"ByteString (class) translate: aString from: start to: stop table: table"
	<export: true>

	| aString start stop table aStringOop tableOop |
	<var: #table type: #'unsigned char *'>
	<var: #aString type: #'unsigned char *'>
	aStringOop := interpreterProxy stackValue: 3.
	(interpreterProxy isBytes: aStringOop) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	(interpreterProxy isOopImmutable: aStringOop) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	start := interpreterProxy stackIntegerValue: 2.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].	
	stop := interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].	
	tableOop := interpreterProxy stackValue: 0.
	(interpreterProxy isBytes: tableOop) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	aString := interpreterProxy firstIndexableField: aStringOop.
	(start >= 1 and: [stop <= (interpreterProxy sizeOfSTArrayFromCPrimitive: aString)]) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadIndex].
	table := interpreterProxy firstIndexableField: tableOop.
	(interpreterProxy sizeOfSTArrayFromCPrimitive: table) < 256 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	start - 1 to: stop - 1 do: [ :i | aString at: i put: (table at: (aString at: i))].
	interpreterProxy methodReturnReceiver
]
