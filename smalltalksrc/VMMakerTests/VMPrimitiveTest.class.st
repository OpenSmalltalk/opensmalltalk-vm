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

{ #category : #tests }
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
		withValue: (interpreter withSmallIntegerTags: anIp << 3).

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
	| newMethod ctx page |
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
	"A new method with a literal (8 bytes) and 2 bytecodes, so the IP can be 9 "
	newMethod := self newMethodWithBytecodes: #[ 1 2 3 4 5 6 7 8 9 0 ].
	"The context has 9 as initial IP, as method has at least one literal"
	ctx := self newSmallContextReceiver: memory nilObject method: newMethod arguments: #() temporaries: #() ip: 9.
	page := interpreter makeBaseFrameFor: ctx.
	interpreter setStackPointersFromPage: page.
]

{ #category : #tests }
VMPrimitiveTest >> testPrimitiveNewAllocatesInOldSpaceIfNewSpaceIsFull [
	| class |
	"Allocate enough space to generate a full new space"
	self assert: (memory
				allocateSlots: (memory scavengeThreshold - memory freeStart) // 8 - 1
				format: memory arrayFormat
				classIndex: memory arrayClassIndexPun) isNotNil.

	(memory newSpaceLimit - memory freeStart) // 8.

	class := self newClassInOldSpaceWithSlots: 256 format: memory nonIndexablePointerFormat.
	interpreter push: class.
	interpreter primitiveNew.
	
	self deny: interpreter failed.
	self deny: (memory isYoung: interpreter stackTop)
]

{ #category : #tests }
VMPrimitiveTest >> testPrimitiveNewCreatesTheObjectInYoungSpace [
	| class |
	class := self newClassInOldSpaceWithSlots: 0 format: memory nonIndexablePointerFormat.

	interpreter push: class.
	interpreter primitiveNew.

	self deny: interpreter failed.
	self assert: (memory isYoung: interpreter stackTop)
]

{ #category : #tests }
VMPrimitiveTest >> testPrimitiveNewCreatesTheObjectWithCorrectSize [
	| class |
	class := self newClassInOldSpaceWithSlots: 4 format: memory nonIndexablePointerFormat.

	interpreter push: class.
	interpreter primitiveNew.

	self assert: (memory numSlotsOf: interpreter stackTop) equals: 4
]

{ #category : #tests }
VMPrimitiveTest >> testPrimitiveNewInFullNewSpaceScheduleGC [
	| class |
	"Allocate enough space to generate a full new space"
	self assert: (memory
				allocateSlots: (memory scavengeThreshold - memory freeStart) // 8 - 1
				format: memory arrayFormat
				classIndex: memory arrayClassIndexPun) isNotNil.
	
	(memory newSpaceLimit - memory freeStart) // 8.
	
	class := self newClassInOldSpaceWithSlots: 256 format: memory nonIndexablePointerFormat.
	
	interpreter push: class.
	interpreter primitiveNew.

	self assert: memory needGCFlag
]

{ #category : #tests }
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

{ #category : #tests }
VMPrimitiveTest >> testPrimitiveNewWithArgCreatesTheObjectWithCorrectSize [
	| newObj class |

	class := self newClassInOldSpaceWithSlots: 0 format: memory arrayFormat.

	interpreter push: class.
	interpreter push: (memory integerObjectOf: 7).

	interpreter primitiveNewWithArg.

	newObj := interpreter stackTop.

	self assert: (memory numSlotsOf: newObj) equals: 7
]
