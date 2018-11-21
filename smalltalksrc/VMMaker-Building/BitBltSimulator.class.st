"
Provide bitblt support for the vm simulator.

Instance Variables
	copyBitsBreakCount:	<Integer|nil>
	copyBitsCount:			<Integer|nil>
	destinationHashes:		<OrderedCollection|nil>

copyBitsBreakCount
	- if set, and destinationHashes is non-nil, copyBits will halt at this count

copyBitsCount
	- if destinationHashes is non-nil this counts copyBits invocations

destinationHashes
	- if an empty OrderedCollection then this will collect the hash of the destination bitmap after each copyBits operation.
	  if a non-empty OrderedCollection, then the hash of the destination bitmap will be compared to the corresponding hash
	  in destinationHashes after each copyBits operation, halting if there is a mismatch.
	  if nil, then nothing is done.  In this way one can track down regressions by collecting hashes in the unregressed version
	  and comparing against results in the regressed version.
"
Class {
	#name : #BitBltSimulator,
	#superclass : #BitBltSimulation,
	#instVars : [
		'destinationHashes',
		'copyBitsCount',
		'copyBitsBreakCount'
	],
	#classInstVars : [
		'opTable',
		'maskTable',
		'warpBitShiftTable',
		'ditherMatrix4x4',
		'ditherThresholds16',
		'ditherValues16',
		'dither8Lookup',
		'isInitialised'
	],
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #accessing }
BitBltSimulator class >> dither8Lookup [

	^ dither8Lookup
]

{ #category : #accessing }
BitBltSimulator class >> ditherMatrix4x4 [

	^ ditherMatrix4x4
]

{ #category : #accessing }
BitBltSimulator class >> ditherThresholds16 [

	^ ditherThresholds16
]

{ #category : #accessing }
BitBltSimulator class >> ditherValues16 [

	^ ditherValues16
]

{ #category : #'class initialization' }
BitBltSimulator class >> initialize [
	"self initialize"
	super initialize.
	isInitialised := false.

]

{ #category : #accessing }
BitBltSimulator class >> isInitialised [

	^ isInitialised
]

{ #category : #accessing }
BitBltSimulator class >> maskTable [

	^ maskTable
]

{ #category : #'instance creation' }
BitBltSimulator class >> new [
	^super new
]

{ #category : #accessing }
BitBltSimulator class >> setInitialised [

	isInitialised := true.
]

{ #category : #translation }
BitBltSimulator class >> shouldBeTranslated [
"This class should not be translated "
	^false
]

{ #category : #accessing }
BitBltSimulator class >> warpBitShiftTable [

	^ warpBitShiftTable
]

{ #category : #'debug support' }
BitBltSimulator >> copyBits [
	(destinationHashes notNil and: [copyBitsCount + 1 = copyBitsBreakCount]) ifTrue:
		[self halt: 'reached copyBitsBreakCount ', copyBitsBreakCount printString].
	super copyBits.
	(interpreterProxy failed
	 or: [destinationHashes isNil]) ifFalse:
		[copyBitsCount ifNil: [copyBitsCount := 0].
		 (copyBitsCount := copyBitsCount + 1) <= destinationHashes size
			ifTrue:
				[(destinationHashes at: copyBitsCount) ~= self destinationHash ifTrue:
					[self halt: 'destination different']]
			ifFalse:
				[destinationHashes addLast: self destinationHash]]
]

{ #category : #'debug support' }
BitBltSimulator >> copyBitsBreakCount [

	^ copyBitsBreakCount
]

{ #category : #'debug support' }
BitBltSimulator >> copyBitsBreakCount: anObject [

	copyBitsBreakCount := anObject
]

{ #category : #'debug support' }
BitBltSimulator >> copyBitsCount [

	^ copyBitsCount
]

{ #category : #'debug support' }
BitBltSimulator >> copyBitsCount: anObject [

	copyBitsCount := anObject
]

{ #category : #'translation support' }
BitBltSimulator >> cppIf: conditionBlockOrSymbolValue ifTrue: trueExpressionOrBlock ifFalse: falseExpressionOrBlockOrNil [
	"The simulator does not have fast blt defines"
	^ conditionBlockOrSymbolValue == #'ENABLE_FAST_BLT'
		ifTrue: falseExpressionOrBlockOrNil
		ifFalse: [super
					cppIf: conditionBlockOrSymbolValue
					ifTrue: trueExpressionOrBlock
					ifFalse: falseExpressionOrBlockOrNil]
]

{ #category : #'debug support' }
BitBltSimulator >> destinationHash [
	| mem bits |
	mem := interpreterProxy memory.
	bits := mem copyFrom: destBits // mem bytesPerElement + 1 to: endOfDestination // mem bytesPerElement.
	ByteArray adoptInstance: bits.
	"This must be (and is) true; but the copyFrom:to: short cut is 100x faster than the byteAt: version"
	"self assert: (((destBits to: endOfDestination - 1) collect: [:i| interpreterProxy byteAt: i]) as: ByteArray) = bits"
	^bits hash
]

{ #category : #'debug support' }
BitBltSimulator >> destinationHashes [

	^ destinationHashes
]

{ #category : #'debug support' }
BitBltSimulator >> destinationHashes: anObject [

	destinationHashes := anObject.
	copyBitsCount ifNil: [copyBitsCount := 0].
	copyBitsBreakCount ifNil: [copyBitsBreakCount := -1]
]

{ #category : #'debug support' }
BitBltSimulator >> dstLongAt: dstIndex [
	interpreterProxy isInterpreterProxy ifTrue:
		[^dstIndex long32At: 0].
	^super dstLongAt: dstIndex
]

{ #category : #'debug support' }
BitBltSimulator >> dstLongAt: dstIndex put: value [
	interpreterProxy isInterpreterProxy ifTrue:
		[^dstIndex long32At: 0 put: value].
	^super dstLongAt: dstIndex put: value
]

{ #category : #'memory access' }
BitBltSimulator >> halftoneAt: idx [
	interpreterProxy isInterpreterProxy ifTrue:
		[^(halftoneBase + (idx \\ halftoneHeight * 4)) long32At: 0].
	^super halftoneAt: idx
]

{ #category : #'memory access' }
BitBltSimulator >> incDestIndex: offset [
	"if offset is a CObject, this avoids a copy, making the simulation massively faster"
	^ destIndex isCObjectAccessor
		ifTrue: [destIndex += offset]
		ifFalse: [super incDestIndex: offset]

]

{ #category : #'memory access' }
BitBltSimulator >> incSrcIndex: offset [
	"if offset is a CObject, this avoids a copy, making the simulation massively faster"
	^ sourceIndex isCObjectAccessor
		ifTrue: [sourceIndex += offset]
		ifFalse: [super incSrcIndex: offset]

]

{ #category : #simulation }
BitBltSimulator >> initBBOpTable [
	opTable := OpTable.
	maskTable := Array new: 32.
	#(1 2 4 5 8 16 32) do:[:i| maskTable at: i put: (1 << i)-1].
	self initializeDitherTables.
	warpBitShiftTable := CArrayAccessor on: (Array new: 32).
]

{ #category : #'initialize-release' }
BitBltSimulator >> initialiseModule [

	self class isInitialised ifFalse: [| ivars |
		ivars := #(opTable maskTable warpBitShiftTable ditherMatrix4x4 ditherThresholds16 ditherValues16 dither8Lookup).
		super initialiseModule.
		ivars do: [:symbol | self class instVarNamed: symbol put: (self instVarNamed: symbol)].
		self class setInitialised].
	opTable := self class opTable.
	maskTable := self class maskTable.
	warpBitShiftTable := self class warpBitShiftTable.
	ditherMatrix4x4 := self class ditherMatrix4x4.
	ditherThresholds16 := self class ditherThresholds16.
	ditherValues16 := self class ditherValues16.
	dither8Lookup := self class dither8Lookup.
	^true
]

{ #category : #simulation }
BitBltSimulator >> initializeDitherTables [
	ditherMatrix4x4 := CArrayAccessor on:
		#(	0	8	2	10
			12	4	14	6
			3	11	1	9
			15	7	13	5).
	ditherThresholds16 := CArrayAccessor on:#(0 2 4 6 8 10 12 14 16).
	ditherValues16 := CArrayAccessor on: 
		#(0 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14
		15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30).
	dither8Lookup := CArrayAccessor on: (Array new: 4096).
]

{ #category : #'memory access' }
BitBltSimulator >> long32At: byteAddress [
	^interpreterProxy long32At: byteAddress
]

{ #category : #'memory access' }
BitBltSimulator >> long32At: byteAddress put: a32BitValue [
	^interpreterProxy long32At: byteAddress put: a32BitValue
]

{ #category : #simulation }
BitBltSimulator >> mergeFn: arg1 with: arg2 [
	^ self perform: (opTable at: combinationRule+1) with: arg1 with: arg2
]

{ #category : #simulation }
BitBltSimulator >> primitive: primitiveName parameters: parameterTypesArray receiver: rcvrType [
	"This exists just to check the set of methods that use smart syntax for which
	 marshallers have been written.  If a case cannot be found you'll have to write
	 a marshaller for the case in question that follows the approach taken in the
	 marshallers below."
	simulator forMap ifTrue:
		[Notification new
			tag: {#forMap. primitiveName. parameterTypesArray. rcvrType};
			signal].
	primitiveName caseOf: {
		['primitivePixelValueAt']		-> [^self].
		['primitiveCompareColors']	-> [^self] }
]

{ #category : #primitives }
BitBltSimulator >> primitiveCompareColors [
	"This is a hack to mimic the SmartSyntaxPlugin support for primitive:parameters:receiver:
	 which is hacked here at BitBltSimulator>>primitive:parameters:receiver:"
	"rcvr := self
				primitive: 'primitiveCompareColors'
				parameters: #(#Unsigned #Unsigned #SmallInteger )
				receiver: #Oop."
	| unsignedBlock colorA colorB testID |
	unsignedBlock := simulator ccgLoad: nil expr: nil asUnsignedValueFrom: nil.
	colorA := unsignedBlock value: (interpreterProxy stackValue: 2).
	colorB := unsignedBlock value: (interpreterProxy stackValue: 1).
	testID := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifFalse:
		[self primitiveCompareColorA: colorA to: colorB test: testID]
]

{ #category : #primitives }
BitBltSimulator >> primitiveCopyBits [
	"Override to provide a convenience to investigate primitive failures.
	 Comment out the first statement to be able to loop, examining e.g. why a BitBlt fails to load."
	true ifTrue:
		[^super primitiveCopyBits].
	[super primitiveCopyBits.
	 interpreterProxy failed] whileTrue:
		[self halt. interpreterProxy coInterpreter initPrimCall]
]

{ #category : #primitives }
BitBltSimulator >> primitivePixelValueAt [
	"This is a hack to mimic the SmartSyntaxPlugin support for primitive:parameters:receiver:
	 which is hacked here at BitBltSimulator>>primitive:parameters:receiver:"
	| xVal yVal |
	xVal := interpreterProxy stackIntegerValue: 1.
	yVal := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifFalse:
		[self primitivePixelValueAtX: xVal y: yVal]
]

{ #category : #'debug support' }
BitBltSimulator >> srcLongAt: srcIndex [
	interpreterProxy isInterpreterProxy ifTrue:
		[^srcIndex long32At: 0].
	^super srcLongAt: srcIndex
]
