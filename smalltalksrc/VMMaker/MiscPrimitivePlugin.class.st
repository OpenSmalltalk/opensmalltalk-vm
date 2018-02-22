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
	| len1 len2 order string1 string2 |

	<var: 'order' type: #'unsigned char *'>
	<var: 'string1' type: #'unsigned char *'>
	<var: 'string2' type: #'unsigned char *'>
	((interpreterProxy isBytes: (interpreterProxy stackValue: 0))
	and: [(interpreterProxy isBytes: (interpreterProxy stackValue: 1))
	and: [interpreterProxy isBytes: (interpreterProxy stackValue: 2)]]) ifFalse:
		[^interpreterProxy primitiveFail].
	string1 := interpreterProxy firstIndexableField: (interpreterProxy stackValue: 2).
	string2 := interpreterProxy firstIndexableField: (interpreterProxy stackValue: 1).
	order := interpreterProxy firstIndexableField: (interpreterProxy stackValue: 0).
	len1 := interpreterProxy sizeOfSTArrayFromCPrimitive: string1.
	len2 := interpreterProxy sizeOfSTArrayFromCPrimitive: string2.
	0 to: (len1 min: len2) - 1 do: 
		[ :i | | c1 c2 |
		c1 := order at: (string1 at: i).
		c2 := order at: (string2 at: i).
		c1 = c2 ifFalse:
			[^interpreterProxy methodReturnValue:
				(interpreterProxy integerObjectOf:
					(c1 < c2 ifTrue: [1] ifFalse: [3]))]].
	interpreterProxy methodReturnValue:
		(interpreterProxy integerObjectOf:
			(len1 = len2 ifTrue: [2] ifFalse: [len1 < len2 ifTrue: [1] ifFalse: [3]]))
]

{ #category : #primitives }
MiscPrimitivePlugin >> primitiveCompressToByteArray [
	"Bitmap compress: bm toByteArray: ba"
	<export: true>
	| bm ba eqBytes i j k lowByte size word |
	<var: 'ba' type: #'unsigned char *'>
	<var: 'bm' type: #'int *'>
	bm := self cCode: [interpreterProxy arrayValueOf: (interpreterProxy stackValue: 1)]
				inSmalltalk: [interpreterProxy
								cCoerce: (interpreterProxy arrayValueOf: (interpreterProxy stackValue: 1))
								to: #'int *'].
	interpreterProxy failed ifTrue: [^nil].
	(interpreterProxy isBytes: (interpreterProxy stackValue: 0)) ifFalse: [^interpreterProxy primitiveFail].
	(interpreterProxy isOopImmutable: (interpreterProxy stackValue: 0)) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	ba := interpreterProxy firstIndexableField: (interpreterProxy stackValue: 0).
	size := interpreterProxy sizeOfSTArrayFromCPrimitive: bm.
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
	interpreterProxy methodReturnValue: (interpreterProxy integerObjectOf: i)
]

{ #category : #primitives }
MiscPrimitivePlugin >> primitiveConvert8BitSigned [
	"SampledSound (class) convert8bitSignedFrom: aByteArray to16Bit: aSoundBuffer"
	<export: true>
	| aByteArray aSoundBuffer arraySize |
	<var: 'aByteArray' type: #'unsigned char *'>
	<var: 'aSoundBuffer' type: #'unsigned short *'>
	(interpreterProxy isBytes: (interpreterProxy stackValue: 1)) ifFalse:
		[^interpreterProxy primitiveFail].
	aByteArray := interpreterProxy firstIndexableField: (interpreterProxy stackValue: 1).
	aSoundBuffer := self
						cCode: [interpreterProxy arrayValueOf: (interpreterProxy stackValue: 0)]
						inSmalltalk: [interpreterProxy
										cCoerce: (interpreterProxy arrayValueOf: (interpreterProxy stackValue: 0))
										to: #'unsigned short *'].
	interpreterProxy failed ifTrue: [^nil].
	(interpreterProxy isOopImmutable: (interpreterProxy stackValue: 0)) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	arraySize := interpreterProxy sizeOfSTArrayFromCPrimitive: aByteArray.
	(interpreterProxy byteSizeOf: (interpreterProxy stackValue: 0)) < (2 * arraySize) ifTrue:
		[^interpreterProxy primitiveFail].
	0 to: arraySize - 1 do: 
		[ :i | | s |
		s := aByteArray at: i.
		aSoundBuffer
			at: i
			put: (s > 127
					ifTrue: [s - 256 bitShift: 8]
					ifFalse: [s bitShift: 8])].
	interpreterProxy pop: interpreterProxy methodArgumentCount
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
	(interpreterProxy isBytes: (interpreterProxy stackValue: 1)) ifFalse: [^interpreterProxy primitiveFail].
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
		k + n >= pastEnd ifTrue: [^interpreterProxy primitiveFail].
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
	|  aString i inclusionMap start stringSize |
	<var: 'aString' type: #'unsigned char *'>
	<var: 'inclusionMap' type: #'char *'>
	((interpreterProxy isIntegerObject: (interpreterProxy stackValue: 0))
	and: [(interpreterProxy isBytes: (interpreterProxy stackValue: 1))
	and: [interpreterProxy isBytes: (interpreterProxy stackValue: 2)]]) ifFalse:
		[^interpreterProxy primitiveFail].
	aString := interpreterProxy firstIndexableField: (interpreterProxy stackValue: 2).
	inclusionMap := interpreterProxy firstIndexableField: (interpreterProxy stackValue: 1).
	start := interpreterProxy integerValueOf: (interpreterProxy stackValue: 0).
	(interpreterProxy sizeOfSTArrayFromCPrimitive: inclusionMap) ~= 256 ifTrue:
		[^interpreterProxy methodReturnValue: (interpreterProxy integerObjectOf: 0)].
	i := start - 1.
	stringSize := interpreterProxy sizeOfSTArrayFromCPrimitive: aString.
	[i < stringSize and: [(inclusionMap at: (aString at: i)) = 0]] whileTrue:
		[i := i + 1].
	interpreterProxy methodReturnValue: (interpreterProxy integerObjectOf: (i >= stringSize ifTrue: [0] ifFalse: [i + 1]))
]

{ #category : #primitives }
MiscPrimitivePlugin >> primitiveFindSubstring [
	"ByteString findSubstring: key in: body startingAt: start matchTable: matchTable"
	<export: true>
	| body key keySize matchTable start |
	<var: #key type: #'unsigned char *'>
	<var: #body type: #'unsigned char *'>
	<var: #matchTable type: #'unsigned char *'>
	((interpreterProxy isBytes: (interpreterProxy stackValue: 0))
	and: [(interpreterProxy isIntegerObject: (interpreterProxy stackValue: 1))
	and: [(interpreterProxy isBytes: (interpreterProxy stackValue: 2))
	and: [interpreterProxy isBytes: (interpreterProxy stackValue: 3)]]]) ifFalse:
		[^interpreterProxy primitiveFail].
	key := interpreterProxy firstIndexableField: (interpreterProxy stackValue: 3).
	body := interpreterProxy firstIndexableField: (interpreterProxy stackValue: 2).
	start := interpreterProxy integerValueOf: (interpreterProxy stackValue: 1).
	matchTable := interpreterProxy firstIndexableField: (interpreterProxy stackValue: 0).
	(keySize := interpreterProxy sizeOfSTArrayFromCPrimitive: key) > 0 ifTrue:
		[keySize := keySize - 1. "adjust for zero relative indxes"
		 (start max: 1) to: (interpreterProxy sizeOfSTArrayFromCPrimitive: body) - keySize do: 
			[ :startIndex | | index |
			index := 0.
			[(matchTable at: (body at: startIndex + index - 1)) = (matchTable at: (key at: index))] whileTrue: 
				[index = keySize ifTrue:
					[^interpreterProxy methodReturnValue: (interpreterProxy integerObjectOf: startIndex)].
				index := index + 1]]].
	^interpreterProxy methodReturnValue: (interpreterProxy integerObjectOf: 0)
]

{ #category : #primitives }
MiscPrimitivePlugin >> primitiveIndexOfAsciiInString [
	"ByteString indexOfAscii: anInteger inString: aString startingAt: start"
	<export: true>
	| anInteger aString start stringSize |
	<var: #aString type: #'unsigned char *'>
	((interpreterProxy isIntegerObject: (interpreterProxy stackValue: 0))
	and: [(interpreterProxy isBytes: (interpreterProxy stackValue: 1))
	and: [(interpreterProxy isIntegerObject: (interpreterProxy stackValue: 2))]]) ifFalse:
		[^interpreterProxy primitiveFail].
	anInteger := interpreterProxy integerValueOf: (interpreterProxy stackValue: 2).
	aString := interpreterProxy firstIndexableField: (interpreterProxy stackValue: 1).
	start := interpreterProxy integerValueOf: (interpreterProxy stackValue: 0).
	stringSize := interpreterProxy sizeOfSTArrayFromCPrimitive: aString.
	start - 1 to: stringSize - 1 do:
		[ :pos |
		(aString at: pos) = anInteger ifTrue:
			[^interpreterProxy methodReturnValue: (interpreterProxy integerObjectOf: pos + 1)]].
	^interpreterProxy methodReturnValue: (interpreterProxy integerObjectOf: 0)
]

{ #category : #primitives }
MiscPrimitivePlugin >> primitiveStringHash [
	"ByteArray (class) hashBytes: aByteArray startingWith: speciesHash"
	<export: true>
	| aByteArray speciesHash byteArraySize hash |
	<var: 'aByteArray' type: #'unsigned char *'>
	<var: 'speciesHash' type: #int>
	((interpreterProxy isIntegerObject: (interpreterProxy stackValue: 0))
	and: [interpreterProxy isBytes: (interpreterProxy stackValue: 1)]) ifFalse:
		[^interpreterProxy primitiveFail].
	aByteArray := interpreterProxy firstIndexableField: (interpreterProxy stackValue: 1).
	speciesHash := interpreterProxy integerValueOf: (interpreterProxy stackValue: 0).
	byteArraySize := interpreterProxy sizeOfSTArrayFromCPrimitive: aByteArray.
	hash := speciesHash bitAnd: 16r0FFFFFFF.
	0 to: byteArraySize - 1 do: 
		[ :pos |
		hash := hash + (aByteArray at: pos).
		hash := hash * 16r19660D bitAnd: 16r0FFFFFFF].
	interpreterProxy methodReturnValue:
		(interpreterProxy integerObjectOf: hash)
]

{ #category : #primitives }
MiscPrimitivePlugin >> primitiveTranslateStringWithTable [
	"ByteString (class) translate: aString from: start to: stop table: table"
	<export: true>
	| aString start stop table |
	<var: #table type: #'unsigned char *'>
	<var: #aString type: #'unsigned char *'>
	((interpreterProxy isBytes: (interpreterProxy stackValue: 0))
	and: [(interpreterProxy isIntegerObject: (interpreterProxy stackValue: 1))
	and: [(interpreterProxy isIntegerObject: (interpreterProxy stackValue: 2))
	and: [interpreterProxy isBytes: (interpreterProxy stackValue: 3)]]]) ifFalse:
		[^interpreterProxy primitiveFail].
	(interpreterProxy isOopImmutable: (interpreterProxy stackValue: 3)) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoModification].
	aString := interpreterProxy firstIndexableField: (interpreterProxy stackValue: 3).
	start := interpreterProxy integerValueOf: (interpreterProxy stackValue: 2).
	stop := interpreterProxy integerValueOf: (interpreterProxy stackValue: 1).
	table := interpreterProxy firstIndexableField: (interpreterProxy stackValue: 0).
	start - 1 to: stop - 1 do: [ :i | aString at: i put: (table at: (aString at: i))].
	interpreterProxy pop: interpreterProxy methodArgumentCount
]
