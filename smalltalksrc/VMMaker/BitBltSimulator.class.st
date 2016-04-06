"
Provide bitblt support for the vm simulator
"
Class {
	#name : #BitBltSimulator,
	#superclass : #BitBltSimulation,
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

{ #category : #'translation support' }
BitBltSimulator >> cppIf: conditionBlockOrSymbolValue ifTrue: trueExpressionOrBlock ifFalse: falseExpressionOrBlockOrNil [
	"The simulator does not have fast blt defines"
	^ conditionBlockOrSymbolValue = #'ENABLE_FAST_BLT'
		ifTrue: falseExpressionOrBlockOrNil
		ifFalse: [super
					cppIf: conditionBlockOrSymbolValue
					ifTrue: trueExpressionOrBlock
					ifFalse: falseExpressionOrBlockOrNil]
]

{ #category : #'debug support' }
BitBltSimulator >> dstLongAt: dstIndex [

	interpreterProxy isInterpreterProxy
		ifTrue:[^dstIndex long32At: 0].
	((dstIndex anyMask: 3) or:[dstIndex + 4 < destBits or:[
		dstIndex > (destBits + (destPitch * destHeight))]])
			ifTrue:[self error:'Out of bounds'].
	^self long32At: dstIndex
]

{ #category : #'debug support' }
BitBltSimulator >> dstLongAt: dstIndex put: value [

	interpreterProxy isInterpreterProxy
		ifTrue:[^dstIndex long32At: 0 put: value].
	((dstIndex anyMask: 3) or:[dstIndex < destBits or:[
		dstIndex >= (destBits + (destPitch * destHeight))]])
			ifTrue:[self error:'Out of bounds'].
	^self long32At: dstIndex put: value
]

{ #category : #'memory access' }
BitBltSimulator >> halftoneAt: idx [

	^self
		cCode: [(halftoneBase + (idx \\ halftoneHeight * 4)) long32At: 0]
		inSmalltalk: [super halftoneAt: idx]
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
	primitiveName caseOf: {
		['primitivePixelValueAt'] -> [^self] }
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

{ #category : #simulation }
BitBltSimulator >> primitivePixelValueAt [
	self primitivePixelValueAtX: (interpreterProxy stackValue: 1) y: (interpreterProxy stackValue: 0)
]

{ #category : #'debug support' }
BitBltSimulator >> srcLongAt: srcIndex [

	interpreterProxy isInterpreterProxy
		ifTrue:[^srcIndex long32At: 0].
	((srcIndex anyMask: 3) or:[srcIndex + 4 < sourceBits or:[
		srcIndex > (sourceBits + (sourcePitch * sourceHeight))]])
			ifTrue:[self error:'Out of bounds'].
	^self long32At: srcIndex
]
