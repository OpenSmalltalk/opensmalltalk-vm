"
A SpurOldToNewMethodFormatMunger is a one-off for mirating a Spur image prior to the two formats to single format CompiledMethod header putsch.

"
Class {
	#name : #SpurOldToNewMethodFormatMunger,
	#superclass : #SimulatorHarness,
	#instVars : [
		'interpreter',
		'heap',
		'prototypes',
		'replacements',
		'symbolOops'
	],
	#pools : [
		'VMObjectIndices'
	],
	#category : 'Cog-Bootstrapping'
}

{ #category : #munging }
SpurOldToNewMethodFormatMunger >> cloneArrayLiteral: anArray [
	"Currently serves only to clone the #(0 0) literal in SpaceTallyPROTOTYPEspaceForInstancesOf:"
	| array |
	array := heap instantiateClass: (heap splObj: ClassArray) indexableSize: anArray size.
	1 to: anArray size do:
		[:i| | lit |
		lit := anArray at: i.
		lit class caseOf: {
			[SmallInteger] -> [heap
									storePointerUnchecked: i - 1
									ofObject: array
									withValue: (heap integerObjectOf: lit)].
			[ByteSymbol] -> [heap
									storePointer: i - 1
									ofObject: array
									withValue: (symbolOops at: lit)].
			[UndefinedObject] -> [heap
									storePointerUnchecked: i - 1
									ofObject: array
									withValue: heap nilObject] }].
	^array

]

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
SpurOldToNewMethodFormatMunger >> indexOfSelector: selectorOop in: methodDict [
	SelectorStart to: (heap numSlotsOf: methodDict) - 1 do:
		[:i|
		(heap fetchPointer: i ofObject: methodDict) = selectorOop ifTrue:
			[^i]].
	self error: 'could not find selector in method dict'
]

{ #category : #munging }
SpurOldToNewMethodFormatMunger >> installableMethodFor: methodWithSource selector: selectorOop siblingMethod: sibling [ 
	| method classOop clone delta numBytes |
	method := methodWithSource copyWithTempsFromMethodNode: methodWithSource methodNode.
	delta := (method primitive > 0
			  and: [(method at: method initialPC) ~= method methodClass callPrimitiveCode])
				ifTrue: [3]
				ifFalse: [0].
	clone := heap
				allocateSlots: (heap numSlotsForBytes: (numBytes := method size) + delta)
				format: (heap compiledMethodFormatForNumBytes: numBytes + delta)
				classIndex: (heap classIndexOf: sibling).
	classOop := interpreter methodClassOf: sibling.
	method methodClass isMeta ifTrue:
		[classOop := heap fetchPointer: interpreter thisClassIndex ofObject: classOop].
	heap storePointer: 0
		ofObject: clone
		withValue: (self methodHeaderForMethod: method).
	1 to: method numLiterals - 2 do:
		[:i|
		heap storePointer: i
			ofObject: clone
			withValue: (self literalFor: (method literalAt: i) inClass: classOop)].
	heap
		storePointer: method numLiterals - 1
			ofObject: clone
				withValue: selectorOop;
		storePointer: method numLiterals
			ofObject: clone
				withValue: (interpreter methodClassAssociationOf: sibling).

	delta > 0 ifTrue:
		[heap
			storeByte: method initialPC - 1 ofObject: clone 	withValue: 139;
			storeByte: method initialPC + 0 ofObject: clone withValue: (method primitive bitAnd: 255);
			storeByte: method initialPC + 1 ofObject: clone withValue: (method primitive bitShift: -8)].
	method initialPC to: method size do:
		[:i|
		 heap storeByte: i - 1 + delta ofObject: clone withValue: (method at: i)].

	^clone
]

{ #category : #munging }
SpurOldToNewMethodFormatMunger >> literalFor: aLiteral inClass: classOop [
	| bindingOrNil |
	aLiteral isSymbol ifTrue:
		[^symbolOops at: aLiteral].
	aLiteral isString ifTrue:
		[^heap stringForCString: aLiteral].
	(aLiteral isInteger and: [aLiteral class == SmallInteger]) ifTrue:
		[^heap integerObjectOf: aLiteral].
	aLiteral isFloat ifTrue:
		[^heap floatObjectOf: aLiteral].
	aLiteral isArray ifTrue:
		[^self cloneArrayLiteral: aLiteral].
	self assert: aLiteral isVariableBinding.
	"interpreter
		ensureDebugAtEachStepBlock;
		instVarNamed: 'printBytecodeAtEachStep' put: true;
		instVarNamed: 'printFrameAtEachStep' put: true."
	bindingOrNil := self interpreter: interpreter
						object: classOop
						perform: (symbolOops at: #bindingOf:)
						withArguments: {symbolOops at: aLiteral key}.
	bindingOrNil ~= heap nilObject ifTrue:
		[^bindingOrNil].
	self error: 'couldn''t find literal ', aLiteral printString
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

{ #category : #munging }
SpurOldToNewMethodFormatMunger >> methodHeaderForMethod: method [
	^heap integerObjectOf:
		   (method numArgs << 24)
		+ (method numTemps << 18)
		+ (method frameSize > method class smallFrameSize ifTrue: [1 << 17] ifFalse: [0])
		+ (method primitive > 0 ifTrue: [1 << 16] ifFalse: [0])
		+ method numLiterals
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
	self preparePrototypes.
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

{ #category : #munging }
SpurOldToNewMethodFormatMunger >> preparePrototypes [
	replacements := OrderedCollection new.
	heap classTableObjectsDo:
		[:class| | name isMeta |
		name := heap
					fetchPointer: interpreter classNameIndex
					ofObject: ((isMeta := (heap numSlotsOf: class) = interpreter metaclassNumSlots)
								ifTrue: [heap fetchPointer: interpreter thisClassIndex ofObject: class]
								ifFalse: [class]).
		name := interpreter stringOf: name.
		self prototypeClassNameMetaSelectorMethodDo:
			[:protoClassName :protoIsMeta :selector :method|
			 (protoClassName = name
			  and: [protoIsMeta = isMeta]) ifTrue:
				[replacements addLast: {class. selector. method}]]]
]

{ #category : #munging }
SpurOldToNewMethodFormatMunger >> prototypeClassNameMetaSelectorMethodDo: quaternaryBlock [
	prototypes ifNil:
		[prototypes := OrderedCollection new.
		SpurBootstrap new prototypeClassNameMetaSelectorMethodDo:
			[:className :isMeta :selector :method| 
			(#(BytecodeEncoder CompiledMethod EncoderForSqueakV4PlusClosures
				InstructionClient InstructionStream MethodNode) includes: className) ifTrue:
					[prototypes addLast: {className. isMeta. selector. method}]]].
	prototypes do: [:tuple| quaternaryBlock valueWithArguments: tuple]
]

{ #category : #munging }
SpurOldToNewMethodFormatMunger >> replaceMethods [
	| byteSymbolClassIndex symbols symbolSizes |
	byteSymbolClassIndex := heap classIndexOf: (heap splObj: SelectorDoesNotUnderstand).
	symbols := Set with: #bindingOf:.
	replacements do:
		[:tuple| | method adder |
		symbols add: tuple second.
		method := tuple last.
		adder := [:lit|
				   (lit isSymbol and: [lit ~~ method selector]) ifTrue: [symbols add: lit].
				   (lit isVariableBinding and: [lit key isSymbol]) ifTrue: [symbols add: lit key].
				   lit isArray ifTrue: [lit do: adder]].
		method literals do: adder].
	symbolSizes := symbols collect: [:ea| ea size].
	symbolOops := Dictionary new.
	heap allObjectsDo:
		[:obj| | sz |
		((heap classIndexOf: obj) = byteSymbolClassIndex
		 and: [symbolSizes includes: (sz := heap numBytesOf: obj)]) ifTrue:
			[symbols do:
				[:s|
				 (sz = s size
				  and: [(interpreter stringOf: obj) = s]) ifTrue:
					[symbolOops at: s put: obj]]]].
	replacements do:
		[:tuple|
		[:classOop :selector :method| | replacement methodDict methodArray index |
		methodDict := heap fetchPointer: MethodDictionaryIndex ofObject: classOop.
		methodArray := heap fetchPointer: MethodArrayIndex ofObject: methodDict.
		index := (0 to: (heap numSlotsOf: methodArray) - 1) detect: [:i| (heap fetchPointer: i ofObject: methodArray) ~= heap nilObject].
		replacement := self installableMethodFor: method
							selector: (symbolOops at: selector)
							siblingMethod: (heap fetchPointer: index ofObject: methodArray).
		index := self indexOfSelector: (symbolOops at: selector) in: methodDict.
		heap
			storePointer: index - SelectorStart
			ofObject: methodArray
			withValue: replacement] valueWithArguments: tuple]
]

{ #category : #saving }
SpurOldToNewMethodFormatMunger >> snapshot [
	Spur32BitMMLESimulator adoptInstance: heap.
	interpreter imageName: 'munged-', (FileDirectory default localNameFor: interpreter imageName).
	[heap parent: heap; setCheckForLeaks: 15; garbageCollectForSnapshot]
		on: Halt
		do: [:ex|
			"suppress halts from the usual suspects (development time halts)"
			(#(fullGC globalGarbageCollect) includes: ex signalerContext sender selector)
				ifTrue: [ex resume]
				ifFalse: [ex pass]].
	interpreter
		setDisplayForm: nil; "gets it to use savedWindowSize"
		writeImageFileIO.
	Transcript cr; show: 'Done!'
]

{ #category : #munging }
SpurOldToNewMethodFormatMunger >> updateAndForwardMethods [
	| new now lastDotTime |
	new := Set new: 1000.
	lastDotTime := Time now asSeconds.
	heap allObjectsDo:
		[:obj|
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
						withValue: (self convertOldMethodHeader: header)]]].
	Spur32BitMMLESimulator adoptInstance: interpreter objectMemory.
	self withExecutableInterpreter: interpreter
		do: [self replaceMethods]
]
