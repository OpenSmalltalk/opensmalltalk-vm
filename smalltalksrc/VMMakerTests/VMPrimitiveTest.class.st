Class {
	#name : #VMPrimitiveTest,
	#superclass : #VMAbstractPrimitiveTest,
	#category : #VMMakerTests
}

{ #category : #'building suites' }
VMPrimitiveTest class >> testParameters [ 

	^ ParametrizedTestMatrix new
			forSelector: #wordSize addOptions: { 4 . 8 };
			yourself

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

{ #category : #'tests - primitiveNew' }
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
