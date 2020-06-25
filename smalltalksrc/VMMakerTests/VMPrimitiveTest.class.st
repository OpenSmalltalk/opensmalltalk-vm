Class {
	#name : #VMPrimitiveTest,
	#superclass : #VMSpurMemoryManagerTest,
	#pools : [
		'VMBasicConstants',
		'VMBytecodeConstants',
		'VMObjectIndices'
	],
	#category : #VMMakerTests
}

{ #category : #'building suites' }
VMPrimitiveTest class >> testParameters [ 

	^ ParametrizedTestMatrix new
			forSelector: #wordSize addOptions: { 4 . 8 };
			yourself

]

{ #category : #'as yet unclassified' }
VMPrimitiveTest >> newArrayWith: aCollection [ 
	| array |
	array := self newObjectWithSlots: aCollection size format: memory arrayFormat classIndex: memory arrayClassIndexPun.
	aCollection withIndexDo: [ :item :index | 
		memory storePointer: index - 1 ofObject: array withValue: item	
	].
	^ array
	
]

{ #category : #'helpers - classes' }
VMPrimitiveTest >> newClassInOldSpaceWithSlots: numberOfSlots format: format [
	| newClass formatWithSlots |

	newClass := memory
		allocateSlotsInOldSpace: 3
		format: memory nonIndexablePointerFormat
		classIndex: memory arrayClassIndexPun.
	
	memory storePointer: 0 ofObject: newClass withValue: memory nilObject.
	memory storePointer: 1 ofObject: newClass withValue: memory nilObject.
	
	formatWithSlots := format << 16 + numberOfSlots. 
	memory storePointer: 2 ofObject: newClass withValue: (memory integerObjectOf: formatWithSlots ).
		
	^ newClass	
]

{ #category : #'helpers - frames' }
VMPrimitiveTest >> newSmallContextReceiver: anOop method: aMethodOop arguments: aCollectionOfArgumentsOop temporaries: aCollectionOfTemporariesOop ip: anIp [

	| newCtx numArgs numTemps |
	newCtx := memory eeInstantiateMethodContextSlots: SmallContextSlots.

	numArgs := aCollectionOfArgumentsOop size.
	numTemps := aCollectionOfTemporariesOop size.

	memory storePointerUnchecked: SenderIndex
		ofObject: newCtx
		withValue: memory nilObject.
		
	memory storePointerUnchecked: InstructionPointerIndex
		ofObject: newCtx
		withValue: (memory integerObjectOf: anIp).

	memory storePointerUnchecked: StackPointerIndex
		ofObject: newCtx
		withValue: (memory integerObjectOf: numArgs + numTemps).
		
	memory storePointerUnchecked: MethodIndex
		ofObject: newCtx
		withValue: aMethodOop.

	memory storePointerUnchecked: ClosureIndex ofObject: newCtx withValue: memory nilObject.

	memory storePointerUnchecked: ReceiverIndex
		ofObject: newCtx
		withValue: anOop.
	
	1 to: numArgs do:
		[:i|
		memory storePointerUnchecked: ReceiverIndex + i
			ofObject: newCtx
			withValue: (aCollectionOfArgumentsOop at: i)].

	1 to: numTemps do:
			[:i|
			memory storePointerUnchecked: ReceiverIndex + i + numArgs
				ofObject: newCtx
				withValue: (aCollectionOfTemporariesOop at: i)].
	
	^ newCtx
]

{ #category : #running }
VMPrimitiveTest >> setUp [
	
	"taken from VMSimpleStackBasedCogitBytecodeTest >> #setup"
	| newMethod ctx page processorOopAssociation processorOop processorListArray processorListPriority1 processorListPriority2 |
	super setUp.
	
	memory nilObject: (self newObjectWithSlots: 0).
	memory trueObject: (self newObjectWithSlots: 0).
	memory falseObject: (self newObjectWithSlots: 0).
	
	"We don't access its contents, but we need it to be after nil, true and false"
	memory hiddenRootsObject: (self newObjectWithSlots: 0).
	interpreter := memory interpreter.
	
	"stackMemoryStartAddress := initialAddress + self initialCodeSize.
	stackMemoryEndAddress := stackMemoryStartAddress + stackSpaceSize."
	
	self initializeOldSpaceForScavenger.

	"Create the root context with a valid method"
	"Let's create a method with enough size. It should have at least a literal (4 or 8 bytes depending the word size) and some bytecodes, so we can put the IP inside the method"
	newMethod := self newMethodWithBytecodes: #[ 1 2 3 4 5 6 7 8 9 0 ].
	
	"The context has 5 (in 32 bits) or 9 (in 64 bits) as initial IP, as method has at least one literal"
	ctx := self newSmallContextReceiver: memory nilObject method: newMethod arguments: #() temporaries: #() ip: self wordSize + 1.
	
	page := interpreter makeBaseFrameFor: ctx.
	interpreter setStackPointersFromPage: page.
	
	
	"The ScheduleAssocation should be initialized to a valid Processor object"
	processorOopAssociation := self newObjectWithSlots: 2.
	processorOop := self newObjectWithSlots: 2.
	processorListArray := self newObjectWithSlots: 2.
	
	processorListPriority1 := self newObjectWithSlots: 2.
	processorListPriority2 := self newObjectWithSlots: 2.
	
	memory storePointer: 0 ofObject: processorListArray withValue: processorListPriority1. 
	memory storePointer: 1 ofObject: processorListArray withValue: processorListPriority2.
	
	memory splObj: SchedulerAssociation put: processorOopAssociation.
	memory storePointer: ValueIndex ofObject: processorOopAssociation withValue: processorOop.
	memory storePointer: ProcessListsIndex ofObject: processorOop withValue: processorListArray.
	memory lastHash: 1
]

{ #category : #'tests - become' }
VMPrimitiveTest >> testPrimitiveArrayBecomeCreatesForwardersForObjectsOfDifferentSize [
	| class1 class2 object1 object2 array1 array2 |
	class1 := self newClassInOldSpaceWithSlots: 1 format: memory nonIndexablePointerFormat.
	class2 := self newClassInOldSpaceWithSlots: 2 format: memory nonIndexablePointerFormat.
	
	object1 := memory instantiateClass: class1.
	object2 := memory instantiateClass: class2.
	
	array1 := self newArrayWith: { object1 }.
	array2 := self newArrayWith: { object2 }.
	
	interpreter push: array1.
	interpreter push: array2.
	
	interpreter primitiveArrayBecome.
	
	self assert: (memory isForwarded: object1) equals: true.
	self assert: (memory isForwarded: object2) equals: true
]

{ #category : #'tests - become' }
VMPrimitiveTest >> testPrimitiveArrayBecomeExchangesClass [
	| class1 class2 object1 object2 array1 array2 |
	class1 := self newClassInOldSpaceWithSlots: 1 format: memory nonIndexablePointerFormat.
	class2 := self newClassInOldSpaceWithSlots: 1 format: memory nonIndexablePointerFormat.
	
	object1 := memory instantiateClass: class1.
	object2 := memory instantiateClass: class2.
	
	array1 := self newArrayWith: { object1 }.
	array2 := self newArrayWith: { object2 }.
	
	interpreter push: array1.
	interpreter push: array2.
	
	interpreter primitiveArrayBecome.
	
	self assert: (memory fetchClassOf: object1) equals: class2.
	self assert: (memory fetchClassOf: object2) equals: class1
]

{ #category : #'tests - become' }
VMPrimitiveTest >> testPrimitiveArrayBecomeExchangesClassForObjectsOfDifferentSize [
	| class1 class2 object1 object2 array1 array2 |
	class1 := self newClassInOldSpaceWithSlots: 1 format: memory nonIndexablePointerFormat.
	class2 := self newClassInOldSpaceWithSlots: 2 format: memory nonIndexablePointerFormat.
	
	object1 := memory instantiateClass: class1.
	object2 := memory instantiateClass: class2.
	
	array1 := self newArrayWith: { object1 }.
	array2 := self newArrayWith: { object2 }.
	
	interpreter push: array1.
	interpreter push: array2.
	
	interpreter primitiveArrayBecome.
	
	self assert: (memory fetchClassOf: (memory followForwarded: object1)) equals: class2.
	self assert: (memory fetchClassOf: (memory followForwarded: object2)) equals: class1
]

{ #category : #'tests - become' }
VMPrimitiveTest >> testPrimitiveArrayBecomeExchangesContents [
	| class object1 object2 array1 array2 |
	class := self newClassInOldSpaceWithSlots: 1 format: memory nonIndexablePointerFormat.
	object1 := memory instantiateClass: class.
	memory storeInteger: 0 ofObject: object1 withValue: 42.
	
	object2 := memory instantiateClass: class.
	memory storeInteger: 0 ofObject: object2 withValue: 75.
	
	array1 := self newArrayWith: { object1 }.
	array2 := self newArrayWith: { object2 }.
	
	interpreter push: array1.
	interpreter push: array2.
	
	interpreter primitiveArrayBecome.
	
	self assert: (memory fetchInteger: 0 ofObject: object1) equals: 75.
	self assert: (memory fetchInteger: 0 ofObject: object2) equals: 42.
]

{ #category : #'tests - become' }
VMPrimitiveTest >> testPrimitiveArrayBecomeExchangesContentsForObjectsOfDifferentSize [
	| class1 class2 object1 object2 array1 array2 |
	class1 := self newClassInOldSpaceWithSlots: 1 format: memory nonIndexablePointerFormat.
	class2 := self newClassInOldSpaceWithSlots: 2 format: memory nonIndexablePointerFormat.
	
	object1 := memory instantiateClass: class1.
	memory storeInteger: 0 ofObject: object1 withValue: 42.
	
	object2 := memory instantiateClass: class2.
	memory storeInteger: 0 ofObject: object2 withValue: 75.
	memory storeInteger: 1 ofObject: object2 withValue: 76.
	
	array1 := self newArrayWith: { object1 }.
	array2 := self newArrayWith: { object2 }.
	
	interpreter push: array1.
	interpreter push: array2.
	
	interpreter primitiveArrayBecome.
	
	self assert: (memory fetchInteger: 0 ofObject: (memory followForwarded: object1)) equals: 75.
	self assert: (memory fetchInteger: 1 ofObject: (memory followForwarded: object1)) equals: 76.
	self assert: (memory fetchInteger: 0 ofObject: (memory followForwarded: object2)) equals: 42
]

{ #category : #'tests - become' }
VMPrimitiveTest >> testPrimitiveArrayBecomeExchangesIdentityHash [
	| class object1 object2 hash1 hash2 array1 array2 |
	class := self newClassInOldSpaceWithSlots: 1 format: memory nonIndexablePointerFormat.
	
	object1 := memory instantiateClass: class.
	object2 := memory instantiateClass: class.
	
	hash1 := memory rawHashBitsOf: object1.
	hash2 := memory rawHashBitsOf: object2.
	
	array1 := self newArrayWith: { object1 }.
	array2 := self newArrayWith: { object2 }.
	
	interpreter push: array1.
	interpreter push: array2.
	
	interpreter primitiveArrayBecome.
	
	self assert: (memory rawHashBitsOf: object1) equals: hash2.
	self assert: (memory rawHashBitsOf: object2) equals: hash1
]

{ #category : #'tests - become' }
VMPrimitiveTest >> testPrimitiveArrayBecomeExchangesIdentityHashForObjectsOfDifferentSize [
	| class1 class2 object1 object2 hash1 hash2 array1 array2 |
	class1 := self newClassInOldSpaceWithSlots: 1 format: memory nonIndexablePointerFormat.
	class2 := self newClassInOldSpaceWithSlots: 2 format: memory nonIndexablePointerFormat.
	
	object1 := memory instantiateClass: class1.
	hash1 := memory rawHashBitsOf: object1.
	
	object2 := memory instantiateClass: class2.
	hash2 := memory rawHashBitsOf: object2.
	
	array1 := self newArrayWith: { object1 }.
	array2 := self newArrayWith: { object2 }.
	
	interpreter push: array1.
	interpreter push: array2.
	
	interpreter primitiveArrayBecome.
	
	self assert: (memory rawHashBitsOf: (memory followForwarded: object1)) equals: hash2.
	self assert: (memory rawHashBitsOf: (memory followForwarded: object2)) equals: hash1
]

{ #category : #'tests - become' }
VMPrimitiveTest >> testPrimitiveArrayBecomeFailsForImmediates [
	| class immediate array1 array2 |
	class := self newClassInOldSpaceWithSlots: 1 format: memory nonIndexablePointerFormat.
	immediate := memory integerObjectOf: 42.
	
	array1 := self newArrayWith: { class }.
	array2 := self newArrayWith: { immediate }.
	
	interpreter push: array1.
	interpreter push: array2.
	
	interpreter primitiveArrayBecome.
	
	self assert: interpreter failed.
	self assert: interpreter primFailCode equals: PrimErrInappropriate.
	
]

{ #category : #'tests - become' }
VMPrimitiveTest >> testPrimitiveArrayBecomeFailsForImmutableObject [
	| class object1 object2 array1 array2 |
	class := self newClassInOldSpaceWithSlots: 1 format: memory nonIndexablePointerFormat.
	
	object1 := memory instantiateClass: class.
	object2 := memory instantiateClass: class.
	memory setIsImmutableOf: object2 to: true. 
	
	array1 := self newArrayWith: { object2 }.
	array2 := self newArrayWith: { object1 }.
	
	interpreter push: array1.
	interpreter push: array2.
	
	interpreter primitiveArrayBecome.
	
	self assert: interpreter failed.
	self assert: interpreter primFailCode equals: PrimErrNoModification
]

{ #category : #'tests - become' }
VMPrimitiveTest >> testPrimitiveArrayBecomeFailsForPinnedObject [
	| class object1 object2 array1 array2 |
	class := self newClassInOldSpaceWithSlots: 1 format: memory nonIndexablePointerFormat.
	
	object1 := memory instantiateClass: class.
	object2 := memory instantiateClass: class isPinned: true.
	 
	array1 := self newArrayWith: { object1 }.
	array2 := self newArrayWith: { object2 }.
	
	interpreter push: array1.
	interpreter push: array2.
	
	interpreter primitiveArrayBecome.
	
	self assert: interpreter failed.
	self assert: interpreter primFailCode equals: PrimErrObjectIsPinned
]

{ #category : #'tests - become' }
VMPrimitiveTest >> testPrimitiveArrayBecomeOneWayCopyHashIfCopyHasIsFalseDoesNotCopyHash [
	| class object1 object2 hash2BeforeBecome array1 array2 object2FromForwarder |
	class := self
		newClassInOldSpaceWithSlots: 1
		format: memory nonIndexablePointerFormat.
	object1 := memory instantiateClass: class.
	object2 := memory instantiateClass: class.
	hash2BeforeBecome := memory hashBitsOf: object2.
	array1 := self newArrayWith: {object1}.
	array2 := self newArrayWith: {object2}.
	interpreter push: array1.
	interpreter push: array2.
	interpreter push: memory falseObject.
	interpreter primitiveArrayBecomeOneWayCopyHash.
	object2FromForwarder := memory followForwarded: object1.
	
	self
		assert: (memory hashBitsOf: object2FromForwarder)
		equals: hash2BeforeBecome.
	self assert: (memory hashBitsOf: object2) equals: hash2BeforeBecome
]

{ #category : #'tests - become' }
VMPrimitiveTest >> testPrimitiveArrayBecomeOneWayCopyHashIfCopyHasIsTrueCopiesHash [
	| class object1 object2 hash1 hash2 array1 array2 |
	class := self newClassInOldSpaceWithSlots: 1 format: memory nonIndexablePointerFormat.
	
	object1 := memory instantiateClass: class.
	object2 := memory instantiateClass: class.
	hash1 := memory hashBitsOf: object1.
	hash2 := memory hashBitsOf: object2.
	
	array1 := self newArrayWith: { object1 }.
	array2 := self newArrayWith: { object2 }.
	
	interpreter push: array1.
	interpreter push: array2.
	interpreter push: memory trueObject.
	
	interpreter primitiveArrayBecomeOneWayCopyHash.
	
	self assert: (memory hashBitsOf: object2) equals: hash1.
	self deny: (memory hashBitsOf: object2) equals: hash2
]

{ #category : #'tests - become' }
VMPrimitiveTest >> testPrimitiveArrayBecomeOneWayCreatesForwardThatPointsToOriginalObject [
	| class object1 object2 array1 array2 |
	class := self newClassInOldSpaceWithSlots: 1 format: memory nonIndexablePointerFormat.
	
	object1 := memory instantiateClass: class.
	object2 := memory instantiateClass: class.
	
	array1 := self newArrayWith: { object1 }.
	array2 := self newArrayWith: { object2 }.
	
	interpreter push: array1.
	interpreter push: array2.
	interpreter push: memory trueObject.
	
	interpreter primitiveArrayBecomeOneWayCopyHash.
	
	self assert: (memory followForwarded: object1)  equals: object2
]

{ #category : #'tests - primitiveAtPut' }
VMPrimitiveTest >> testPrimitiveAtPutFailsForImmutableObject [
	| class object |
	class := self newClassInOldSpaceWithSlots: 0 format: memory arrayFormat.
	
	object := memory instantiateClass: class indexableSize: 1.

	memory setIsImmutableOf: object to: true. 

	interpreter push: object.
	interpreter push: (memory integerObjectOf: 1).
	interpreter push: memory falseObject.
	interpreter primitiveAtPut.
	
	self assert: interpreter failed.
]

{ #category : #'tests - primitiveAtPut' }
VMPrimitiveTest >> testPrimitiveAtPutFailsForNonIndexableObject [
	| class object |
	class := self newClassInOldSpaceWithSlots: 0 format: memory nonIndexablePointerFormat.
	
	object := memory instantiateClass: class.

	interpreter push: object.
	interpreter push: (memory integerObjectOf: 1).
	interpreter push: memory falseObject.
	interpreter primitiveAtPut.
	
	self assert: interpreter failed.
]

{ #category : #'tests - primitiveAtPut' }
VMPrimitiveTest >> testPrimitiveAtPutPutsTheValueForAnIndexableObject [
	| class object |
	class := self newClassInOldSpaceWithSlots: 0 format: memory arrayFormat.
	
	object := memory instantiateClass: class indexableSize: 1.

	interpreter push: object.
	interpreter push: (memory integerObjectOf: 1).
	interpreter push: memory falseObject.
	interpreter primitiveAtPut.
	
	self deny: interpreter failed.
	self assert: (memory fetchPointer: 0 ofObject: object) equals: memory falseObject.
]

{ #category : #'tests - primitiveImmutability' }
VMPrimitiveTest >> testPrimitiveGetImmutabilityOfImmediateReturnsTrue [

	interpreter push: (memory integerObjectOf: 1).
	interpreter primitiveGetImmutability.
	
	self assert: interpreter stackTop equals: memory trueObject
]

{ #category : #'tests - primitiveImmutability' }
VMPrimitiveTest >> testPrimitiveGetImmutabilityOnANewObjectIsFalse [
	| class object |
	class := self newClassInOldSpaceWithSlots: 0 format: memory nonIndexablePointerFormat.
	
	object := memory instantiateClass: class.

	interpreter push: object.
	interpreter primitiveGetImmutability.

	self assert: interpreter stackTop equals: memory falseObject
]

{ #category : #'tests - primitiveImmutability' }
VMPrimitiveTest >> testPrimitiveGetImmutabilityReturnsTrueIfObjectIsImmutable [
	| class object |
	class := self newClassInOldSpaceWithSlots: 0 format: memory nonIndexablePointerFormat.
	
	object := memory instantiateClass: class.
	memory setIsImmutableOf: object to: true. 

	interpreter push: object.
	interpreter primitiveGetImmutability.
	
	self assert: interpreter stackTop equals: memory trueObject
]

{ #category : #'tests - primitiveAtPut' }
VMPrimitiveTest >> testPrimitiveInstVarAtPutOverBoundShouldFailForIndexable [
	| class object |
	class := self newClassInOldSpaceWithSlots: 1 format: memory arrayFormat .
	
	object := memory instantiateClass: class indexableSize: 1.

	interpreter push: object.
	interpreter push: (memory integerObjectOf: 2).
	interpreter push: memory falseObject.
	interpreter primitiveInstVarAtPut.
	
	self assert: interpreter failed.
]

{ #category : #'tests - primitiveAtPut' }
VMPrimitiveTest >> testPrimitiveInstVarAtPutOverBoundShouldFailNonIndexable [
	| class object |
	class := self newClassInOldSpaceWithSlots: 1 format: memory nonIndexablePointerFormat.
	
	object := memory instantiateClass: class.

	interpreter push: object.
	interpreter push: (memory integerObjectOf: 2).
	interpreter push: memory falseObject.
	interpreter primitiveInstVarAtPut.
	
	self assert: interpreter failed.
]

{ #category : #'tests - primitiveAtPut' }
VMPrimitiveTest >> testPrimitiveInstVarAtPutPutsTheValueForNonIndexable [
	| class object |
	class := self newClassInOldSpaceWithSlots: 1 format: memory nonIndexablePointerFormat.
	
	object := memory instantiateClass: class.

	interpreter push: object.
	interpreter push: (memory integerObjectOf: 1).
	interpreter push: memory falseObject.
	interpreter primitiveInstVarAtPut.
	
	self deny: interpreter failed.
	self assert: (memory fetchPointer: 0 ofObject: object) equals: memory falseObject.
]

{ #category : #'tests - primitiveNew' }
VMPrimitiveTest >> testPrimitiveNewCreatesTheObjectInYoungSpace [
	| class |
	class := self newClassInOldSpaceWithSlots: 0 format: memory nonIndexablePointerFormat.

	interpreter push: class.
	interpreter primitiveNew.

	self deny: interpreter failed.
	self assert: (memory isYoung: interpreter stackTop)
]

{ #category : #'tests - primitiveNew' }
VMPrimitiveTest >> testPrimitiveNewCreatesTheObjectWithCorrectSize [
	| class |
	class := self newClassInOldSpaceWithSlots: 4 format: memory nonIndexablePointerFormat.

	interpreter push: class.
	interpreter primitiveNew.

	self assert: (memory numSlotsOf: interpreter stackTop) equals: 4
]

{ #category : #'tests - primitiveNew' }
VMPrimitiveTest >> testPrimitiveNewInFullNewSpaceAllocatesInOldSpace [
	| class |
	"Allocate enough space to generate a full new space"
	self assert: (memory
				allocateSlots: (memory scavengeThreshold - memory freeStart) // self wordSize - 1
				format: memory arrayFormat
				classIndex: memory arrayClassIndexPun) isNotNil.

	class := self newClassInOldSpaceWithSlots: 256 format: memory nonIndexablePointerFormat.
	interpreter push: class.
	interpreter primitiveNew.
	
	self deny: interpreter failed.
	self deny: (memory isYoung: interpreter stackTop)
]

{ #category : #'tests - primitiveNew' }
VMPrimitiveTest >> testPrimitiveNewInFullNewSpaceScheduleGC [
	| class |
	"Allocate enough space to generate a full new space"
	self assert: (memory
				allocateSlots: (memory scavengeThreshold - memory freeStart) // self wordSize - 1
				format: memory arrayFormat
				classIndex: memory arrayClassIndexPun) isNotNil.
	
	class := self newClassInOldSpaceWithSlots: 256 format: memory nonIndexablePointerFormat.
	
	interpreter push: class.
	interpreter primitiveNew.

	self assert: memory needGCFlag
]

{ #category : #'tests - primitiveNewWithArgs' }
VMPrimitiveTest >> testPrimitiveNewIsNotPinned [
	| class |
	class := self newClassInOldSpaceWithSlots: 0 format: memory nonIndexablePointerFormat.

	interpreter push: class.
	interpreter primitiveNew.

	self deny: (memory isPinned: interpreter stackTop)
]

{ #category : #'tests - primitiveNewPinned' }
VMPrimitiveTest >> testPrimitiveNewPinnedCreatesTheObjectInOldSpace [
	| class |
	class := self newClassInOldSpaceWithSlots: 0 format: memory nonIndexablePointerFormat.

	interpreter push: class.
	interpreter primitiveNewPinned.

	self deny: interpreter failed.
	self deny: (memory isYoung: interpreter stackTop)
]

{ #category : #'tests - primitiveNewPinned' }
VMPrimitiveTest >> testPrimitiveNewPinnedObjectInFullNewSpaceIsSchedulingGC [
	| class |
	class := self newClassInOldSpaceWithSlots: 3 format: memory nonIndexablePointerFormat.

	"Allocate enough space to generate a full new space"
	self assert: (memory
				allocateSlots: (memory scavengeThreshold - memory freeStart) // self wordSize - 3
				format: memory arrayFormat
				classIndex: memory arrayClassIndexPun) isNotNil.

	self deny: memory needGCFlag.
	
	interpreter push: class.
	interpreter primitiveNewPinned.

	self deny: interpreter failed.
	self assert: memory needGCFlag 
]

{ #category : #'tests - primitiveNewPinned' }
VMPrimitiveTest >> testPrimitiveNewPinnedObjectIsNotSchedulingGC [
	| class |
	class := self newClassInOldSpaceWithSlots: 0 format: memory nonIndexablePointerFormat.

	interpreter push: class.
	interpreter primitiveNewPinned.

	self deny: interpreter failed.
	self deny: memory needGCFlag 
]

{ #category : #'tests - primitiveNewPinned' }
VMPrimitiveTest >> testPrimitiveNewPinnedObjectIsPinned [
	| class |
	class := self newClassInOldSpaceWithSlots: 0 format: memory nonIndexablePointerFormat.

	interpreter push: class.
	interpreter primitiveNewPinned.

	self deny: interpreter failed.
	self assert: (memory isPinned: interpreter stackTop)
]

{ #category : #'tests - primitiveNewPinned' }
VMPrimitiveTest >> testPrimitiveNewPinnedWithArgsCreatesTheObjectInOldSpace [
	| class |
	class := self newClassInOldSpaceWithSlots: 0 format: memory arrayFormat.

	interpreter push: class.
	interpreter push: (memory integerObjectOf: 7).
	interpreter primitiveNewWithArgPinned.

	self deny: interpreter failed.
	self deny: (memory isYoung: interpreter stackTop)
]

{ #category : #'tests - primitiveNewPinned' }
VMPrimitiveTest >> testPrimitiveNewPinnedWithArgsObjectIsNotSchedulingGC [
	| class |
	class := self newClassInOldSpaceWithSlots: 0 format: memory arrayFormat.

	interpreter push: class.
	interpreter push: (memory integerObjectOf: 7).
	interpreter primitiveNewWithArgPinned.

	self deny: interpreter failed.
	self deny: memory needGCFlag 
]

{ #category : #'tests - primitiveNewPinned' }
VMPrimitiveTest >> testPrimitiveNewPinnedWithArgsObjectIsPinned [
	| class |
	class := self newClassInOldSpaceWithSlots: 0 format: memory arrayFormat.

	interpreter push: class.
	interpreter push: (memory integerObjectOf: 7).
	interpreter primitiveNewWithArgPinned.

	self deny: interpreter failed.
	self assert: (memory isPinned: interpreter stackTop)
]

{ #category : #'tests - primitiveNewWithArgs' }
VMPrimitiveTest >> testPrimitiveNewWithArgCreatesTheObjectInYoungSpace [
	| newObj class |

	class := self newClassInOldSpaceWithSlots: 0 format: memory arrayFormat.

	interpreter push: class.
	interpreter push: (memory integerObjectOf: 7).

	interpreter primitiveNewWithArg.

	newObj := interpreter stackTop.

	self deny: interpreter failed.
	self assert: (memory isYoung: newObj)
]

{ #category : #'tests - primitiveNewWithArgs' }
VMPrimitiveTest >> testPrimitiveNewWithArgCreatesTheObjectWithCorrectSize [
	| newObj class |

	class := self newClassInOldSpaceWithSlots: 0 format: memory arrayFormat.

	interpreter push: class.
	interpreter push: (memory integerObjectOf: 7).

	interpreter primitiveNewWithArg.

	newObj := interpreter stackTop.

	self assert: (memory numSlotsOf: newObj) equals: 7
]

{ #category : #'tests - primitiveNewWithArgs' }
VMPrimitiveTest >> testPrimitiveNewWithArgInFullNewSpaceAllocatesInOldSpace [
	| newObj class |

	"Allocate enough space to generate a full new space"
	self assert: (memory
				allocateSlots: (memory scavengeThreshold - memory freeStart) // self wordSize - 1
				format: memory arrayFormat
				classIndex: memory arrayClassIndexPun) isNotNil.

	class := self newClassInOldSpaceWithSlots: 0 format: memory arrayFormat.

	interpreter push: class.
	interpreter push: (memory integerObjectOf: 256).

	interpreter primitiveNewWithArg.

	newObj := interpreter stackTop.

	self assert: (memory isOldObject: newObj)
]

{ #category : #'tests - primitiveNewWithArgs' }
VMPrimitiveTest >> testPrimitiveNewWithArgInFullNewSpaceScheduleGC [
	| class |

	"Allocate enough space to generate a full new space"
	self assert: (memory
				allocateSlots: (memory scavengeThreshold - memory freeStart) // self wordSize - 1
				format: memory arrayFormat
				classIndex: memory arrayClassIndexPun) isNotNil.

	class := self newClassInOldSpaceWithSlots: 0 format: memory arrayFormat.

	interpreter push: class.
	interpreter push: (memory integerObjectOf: 256).

	interpreter primitiveNewWithArg.

	self assert: memory needGCFlag
]

{ #category : #'tests - primitiveNewWithArgs' }
VMPrimitiveTest >> testPrimitiveNewWithArgWithInvalidClassFails [
	| class |

	class := self newClassInOldSpaceWithSlots: 0 format: memory nonIndexablePointerFormat.

	interpreter push: class.
	interpreter push: (memory integerObjectOf: 256).

	interpreter primitiveNewWithArg.

	self assert: interpreter primFailCode equals: PrimErrBadReceiver
]

{ #category : #'tests - primitiveNewWithArgs' }
VMPrimitiveTest >> testPrimitiveNewWithArgWithNegativeArgumentFails [
	| class |

	class := self newClassInOldSpaceWithSlots: 0 format: memory arrayFormat.

	interpreter push: class.
	interpreter push: (memory integerObjectOf: -256).

	interpreter primitiveNewWithArg.

	self assert: interpreter primFailCode equals: PrimErrBadArgument
]

{ #category : #'tests - primitiveNew' }
VMPrimitiveTest >> testPrimitiveNewWithInvalidClassFails [
	| class |
	class := self newClassInOldSpaceWithSlots: 0 format: memory arrayFormat.

	interpreter push: class.
	interpreter primitiveNew.

	self assert: interpreter primFailCode equals: PrimErrBadReceiver
]

{ #category : #'tests - primitiveImmutability' }
VMPrimitiveTest >> testPrimitiveSetImmutabilityOfImmediateShouldFail [

	interpreter push: (memory integerObjectOf: 1).
	interpreter push: memory trueObject.
	interpreter primitiveSetImmutability.
	
	self assert: interpreter failed
]

{ #category : #'tests - primitiveImmutability' }
VMPrimitiveTest >> testPrimitiveSetImmutabilityOfObjectAsTrueSetsImmutability [

	| class object |
	class := self newClassInOldSpaceWithSlots: 0 format: memory nonIndexablePointerFormat.
	
	object := memory instantiateClass: class.

	interpreter push: object.
	interpreter push: memory trueObject.
	interpreter primitiveSetImmutability.
	
	self assert: (memory isImmutable: object)
]
