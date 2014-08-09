Class {
	#name : #SpurOldToNewMethodFormatMunger,
	#superclass : #Object,
	#instVars : [
		'interpreter',
		'heap'
	],
	#pools : [
		'VMObjectIndices'
	],
	#category : #'Cog-Bootstrapping'
}

{ #category : #munging }
SpurOldToNewMethodFormatMunger >> convertOldMethodHeader: methodHeader [
	^heap integerObjectOf:
		   ((interpreter argumentCountOfMethodHeader: methodHeader) << 24)
		+ ((interpreter temporaryCountOfMethodHeader: methodHeader) << 18)
		+ ((interpreter methodHeaderIndicatesLargeFrame: methodHeader) ifTrue: [1 << 17] ifFalse: [0])
		+ ((heap primitiveIndexOfMethodHeader: methodHeader) > 0 ifTrue: [1 << 16] ifFalse: [0])
		+ (heap literalCountOfMethodHeader: methodHeader)
]

{ #category : #munging }
SpurOldToNewMethodFormatMunger >> incrementPCField: fieldIndex ofObject: newObj by: n [
	| value |
	value := heap fetchPointer: fieldIndex ofObject: newObj.
	(heap isIntegerObject: value)
		ifTrue:
			[heap
				storePointerUnchecked: fieldIndex
				ofObject: newObj
				withValue: (heap integerObjectOf: n + (heap integerValueOf: value))]
		ifFalse:
			[self assert: value = heap nilObject]
]

{ #category : #munging }
SpurOldToNewMethodFormatMunger >> mapPCs [
	| cbc cmc |
	cmc := 36.
	cbc := 37.
	heap allObjectsDo:
		[:obj| | ci |
		ci := heap classIndexOf: obj.
		(ci <= 37 and: [ci >= 36]) ifTrue:
			[ci = 37 ifTrue: [self mungeClosure: obj].
			 ci = 36 ifTrue: [self mungeContext: obj]]]
]

{ #category : #'public access' }
SpurOldToNewMethodFormatMunger >> munge: imageName [
	interpreter := StackInterpreterSimulator newWithOptions: #(ObjectMemory Spur32BitMemoryManager).
	interpreter desiredNumStackPages: 4; initStackPages.
	heap := interpreter objectMemory.
	self assert: heap class == Spur32BitMMLESimulator.
	SpurOldFormat32BitMMLESimulator adoptInstance: heap.
	interpreter openOn: imageName extraMemory: 0.
	self mapPCs.
	self updateAndForwardMethods.
	self snapshot
]

{ #category : #munging }
SpurOldToNewMethodFormatMunger >> mungeClosure: obj [
	| method |
	method := heap
					fetchPointer: MethodIndex
					ofObject: (heap
								fetchPointer: ClosureOuterContextIndex
								ofObject: obj).
	(heap primitiveIndexOfMethodHeader: (heap methodHeaderOf: method)) > 0 ifTrue:
		[self incrementPCField: ClosureStartPCIndex ofObject: obj by: 3]
]

{ #category : #munging }
SpurOldToNewMethodFormatMunger >> mungeContext: obj [
	| method |
	method := heap fetchPointer: MethodIndex ofObject: obj.
	(heap primitiveIndexOfMethodHeader: (heap methodHeaderOf: method)) > 0 ifTrue:
		[self incrementPCField: InstructionPointerIndex ofObject: obj by: 3]
]

{ #category : #munging }
SpurOldToNewMethodFormatMunger >> mungePrimitiveMethod: obj [
	| numBytes copy firstByteIndex primIndex numPointerSlots header |
	numBytes := heap byteSizeOf: obj.
	copy := heap allocateSlotsInOldSpace: (heap numSlotsForBytes: numBytes + 3)
				format: (heap compiledMethodFormatForNumBytes: numBytes + 3)
				classIndex: (heap classIndexOf: obj).
	header := heap methodHeaderOf: obj.
	numPointerSlots := (heap literalCountOfMethodHeader: header) + LiteralStart.
	heap
		storePointerUnchecked: 0
		ofObject: copy
		withValue: (self convertOldMethodHeader: header).
	1 to: numPointerSlots - 1 do:
		[:i|
		heap storePointer: i
			ofObject: copy
			withValue: (heap fetchPointer: i ofObject: obj)].
	primIndex := heap primitiveIndexOfMethodHeader: header.
	firstByteIndex := numPointerSlots * heap bytesPerOop.
	heap
		storeByte: firstByteIndex + 0 ofObject: copy withValue: 139;
		storeByte: firstByteIndex + 1 ofObject: copy withValue: (primIndex bitAnd: 255);
		storeByte: firstByteIndex + 2 ofObject: copy withValue: (primIndex bitShift: -8).
	firstByteIndex to: numBytes - 1 do:
		[:i|
		heap storeByte: i + 3 ofObject: copy withValue: (heap fetchByte: i ofObject: obj)].
	heap forward: obj to: copy.
	^copy
]

{ #category : #saving }
SpurOldToNewMethodFormatMunger >> snapshot [
	Spur32BitMMLESimulator adoptInstance: heap.
	interpreter imageName: 'munged-', (FileDirectory default localNameFor: interpreter imageName).
	[heap parent: heap; setCheckForLeaks: 15; fullGC; fullGC]
		on: Halt
		do: [:ex|
			"suppress halts from the usual suspects (development time halts)"
			(#(fullGC globalGarbageCollect) includes: ex signalerContext sender selector)
				ifTrue: [ex resume]
				ifFalse: [ex pass]].
	interpreter halt; writeImageFileIO
]

{ #category : #munging }
SpurOldToNewMethodFormatMunger >> updateAndForwardMethods [
	| new now lastDotTime |
	new := Set new: 1000.
	lastDotTime := Time now asSeconds.
	heap allObjectsDo:
		[:obj|
		obj = 16rAC9A30 ifTrue: [self halt].
		((heap isCompiledMethod: obj)
		 and: [(new includes: obj) not]) ifTrue:
			[| header |
			 (heap primitiveIndexOfMethodHeader: (header := heap methodHeaderOf: obj)) > 0
				ifTrue:
					[new add: (self mungePrimitiveMethod: obj).
					 (now := Time now asSeconds) > lastDotTime ifTrue:
						[Transcript nextPut: $.; flush.
						 lastDotTime := now]]
				ifFalse:
					[heap
						storePointerUnchecked: 0
						ofObject: obj
						withValue: (self convertOldMethodHeader: header)]]]
]
