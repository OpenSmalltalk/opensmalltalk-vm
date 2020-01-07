Class {
	#name : #VMSpurScavengerTest,
	#superclass : #VMSpurMemoryManagerTest,
	#category : #VMMakerTests
}

{ #category : #'tests-3-scavenge-basic' }
VMSpurScavengerTest >> assertPastSpaceHasOnlyNil [
	self
		assert: memory pastSpaceStart
		equals: memory scavenger pastSpace start + emptyObjectSize
]

{ #category : #'tests-3-scavenge-basic' }
VMSpurScavengerTest >> initializeOldSpaceForScavenger [

	"Create a nil object required to initialize several fields"
	memory nilObject: self newZeroSizedObject.

	"Initialize Stack"
	memory coInterpreter desiredNumStackPages: 8.
	memory coInterpreter initStackPages.
	memory coInterpreter bootstrapping: true.

	"Initialize Special Root objects"
	memory coInterpreter method: memory nilObject.
	memory coInterpreter instructionPointer: memory nilObject.
	memory coInterpreter newMethod: memory nilObject.
	memory coInterpreter profileProcess: memory nilObject.
	memory coInterpreter profileMethod: memory nilObject.
	memory coInterpreter profileSemaphore: memory nilObject.
	memory mournQueue: memory nilObject.
	memory specialObjectsOop: memory nilObject.
	
	"Initialize old space with free list, class table, hidden roots and remembered set to be able to scavenge"
	memory initializeFreeList.
	memory segmentManager collapseSegmentsPostSwizzle.
	memory updateFreeLists.
	memory computeFreeSpacePostSwizzle.
	memory initializeOldSpaceFirstFree: memory freeOldSpaceStart.
	memory allocateClassTable.	
	memory scavenger initializeRememberedSet.
]

{ #category : #'tests-4-scavenge-stack' }
VMSpurScavengerTest >> makeBaseFrameWithMethod: aMethodOop context: aContextOop receiver: aReceiverOop args: argsOops andStack: stackOops [
	
	| page pointer |
	page := memory coInterpreter stackPages newStackPage.
	pointer := page baseAddress.
	memory coInterpreter stackPointer: pointer + memory wordSize.
	"Receiver"
	memory coInterpreter push: aReceiverOop.
	argsOops do: [ :e | memory coInterpreter push: e ].
	"sender context"
	memory coInterpreter push: memory nilObject.
	"base frame's saved fp is null"
	memory coInterpreter push: 0.
	page
		baseFP: memory coInterpreter stackPointer;
		headFP: memory coInterpreter stackPointer.
	"method"
	memory coInterpreter push: aMethodOop.
	"Flags: this stack frame is single. I.e., it has no context object.
	Otherwise GC fails with an assertion looking for it in the heap"
	memory coInterpreter push: (memory coInterpreter 
		encodeFrameFieldHasContext: (aContextOop ~= memory nilObject)
		isBlock: false
		numArgs: argsOops size).
	"context"
	memory coInterpreter push: aContextOop.
	"rcvr"
	memory coInterpreter push: aReceiverOop.
	"frame stack => empty"
	stackOops do: [ :e | memory coInterpreter push: e ].
	"ip"
	memory coInterpreter push: (aMethodOop + memory baseHeaderSize - 2).
	page headSP: memory coInterpreter stackPointer.
	memory coInterpreter setStackPageAndLimit: page.
	memory coInterpreter setStackPointersFromPage: page.
	memory coInterpreter popStack.
	
	"Mark context as married by setting its sender to the frame pointer plus SmallInteger
	 tags and the InstructionPointer to the saved fp (which ensures correct alignment
	 w.r.t. the frame when we check for validity) plus SmallInteger tags."
	(aContextOop ~= memory nilObject) ifTrue: [ 
		memory
			storePointerUnchecked: 0 "SenderIndex"
			ofObject: aContextOop
			withValue: (memory coInterpreter withSmallIntegerTags: page baseFP) ]
]

{ #category : #'tests-4-scavenge-stack' }
VMSpurScavengerTest >> setUp [

	super setUp.
	self initializeOldSpaceForScavenger.
	memory lastHash: 1.
]

{ #category : #'tests-4-scavenge-stack' }
VMSpurScavengerTest >> testArgumentInStackShouldSurviveScanvenge [

	| newObjectOop newObjectHash newObjectAddress |	
	newObjectOop := self newZeroSizedObject.
	newObjectHash := (memory hashBitsOf: newObjectOop).
	
	self
		makeBaseFrameWithMethod: memory nilObject
		context: memory nilObject
		receiver: memory nilObject
		args: { newObjectOop }
		andStack: #().

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1 "TenureByAge".
	
	"Remap our object address to its new location"
	newObjectAddress := memory remapObj: newObjectOop.
	self assert: (memory hashBitsOf: newObjectAddress) equals: newObjectHash
]

{ #category : #'tests-4-scavenge-stack' }
VMSpurScavengerTest >> testContextInStackShouldSurviveScanvenge [

	| newObjectOop newObjectHash newObjectAddress |	
	newObjectOop := self newZeroSizedObject.
	newObjectHash := (memory hashBitsOf: newObjectOop).
	
	self
		makeBaseFrameWithMethod: memory nilObject
		context: newObjectOop
		receiver: memory nilObject
		args: #()
		andStack: #().

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1 "TenureByAge".
	
	"Remap our object address to its new location"
	newObjectAddress := memory remapObj: newObjectOop.
	self assert: (memory hashBitsOf: newObjectAddress) equals: newObjectHash
]

{ #category : #'tests-5-scavenge-specialObjects' }
VMSpurScavengerTest >> testInterpreterMethodShouldSurviveScanvenge [

	| newObjectOop newObjectHash newObjectAddress |	
	newObjectOop := self newZeroSizedObject.
	newObjectHash := (memory hashBitsOf: newObjectOop).
	
	memory coInterpreter method: newObjectOop.

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1 "TenureByAge".
	
	"Remap our object address to its new location"
	newObjectAddress := memory remapObj: newObjectOop.
	self assert: (memory hashBitsOf: newObjectAddress) equals: newObjectHash
]

{ #category : #'tests-5-scavenge-specialObjects' }
VMSpurScavengerTest >> testInterpreterNewMethodShouldSurviveScanvenge [

	| newObjectOop newObjectHash newObjectAddress |	
	newObjectOop := self newZeroSizedObject.
	newObjectHash := (memory hashBitsOf: newObjectOop).
	
	memory coInterpreter newMethod: newObjectOop.

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1 "TenureByAge".
	
	"Remap our object address to its new location"
	newObjectAddress := memory remapObj: newObjectOop.
	self assert: (memory hashBitsOf: newObjectAddress) equals: newObjectHash
]

{ #category : #'tests-5-scavenge-specialObjects' }
VMSpurScavengerTest >> testInterpreterProfileMethodShouldSurviveScanvenge [

	| newObjectOop newObjectHash newObjectAddress |	
	newObjectOop := self newZeroSizedObject.
	newObjectHash := (memory hashBitsOf: newObjectOop).
	
	memory coInterpreter profileMethod: newObjectOop.

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1 "TenureByAge".
	
	"Remap our object address to its new location"
	newObjectAddress := memory remapObj: newObjectOop.
	self assert: (memory hashBitsOf: newObjectAddress) equals: newObjectHash
]

{ #category : #'tests-5-scavenge-specialObjects' }
VMSpurScavengerTest >> testInterpreterProfileProcessShouldSurviveScanvenge [

	| newObjectOop newObjectHash newObjectAddress |	
	newObjectOop := self newZeroSizedObject.
	newObjectHash := (memory hashBitsOf: newObjectOop).
	
	memory coInterpreter profileProcess: newObjectOop.

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1 "TenureByAge".
	
	"Remap our object address to its new location"
	newObjectAddress := memory remapObj: newObjectOop.
	self assert: (memory hashBitsOf: newObjectAddress) equals: newObjectHash
]

{ #category : #'tests-5-scavenge-specialObjects' }
VMSpurScavengerTest >> testInterpreterProfileSemaphoreShouldSurviveScanvenge [

	| newObjectOop newObjectHash newObjectAddress |
	newObjectOop := self newZeroSizedObject.
	newObjectHash := (memory hashBitsOf: newObjectOop).
	
	memory coInterpreter profileSemaphore: newObjectOop.

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1 "TenureByAge".
	
	"Remap our object address to its new location"
	newObjectAddress := memory remapObj: newObjectOop.
	self assert: (memory hashBitsOf: newObjectAddress) equals: newObjectHash
]

{ #category : #'tests-4-scavenge-stack' }
VMSpurScavengerTest >> testMethodInStackShouldSurviveScanvenge [

	| newObjectOop newObjectHash newObjectAddress |
	newObjectOop := self newZeroSizedObject.
	newObjectHash := (memory hashBitsOf: newObjectOop).
	
	self
		makeBaseFrameWithMethod: newObjectOop
		context: memory nilObject
		receiver: memory nilObject
		args: #()
		andStack: #().

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1 "TenureByAge".
	
	"Remap our object address to its new location"
	newObjectAddress := memory remapObj: newObjectOop.
	self assert: (memory hashBitsOf: newObjectAddress) equals: newObjectHash
]

{ #category : #'tests-4-scavenge-stack' }
VMSpurScavengerTest >> testObjectInStackShouldSurviveScanvenge [

	| newObjectOop newObjectHash newObjectAddress |
	newObjectOop := self newZeroSizedObject.
	newObjectHash := (memory hashBitsOf: newObjectOop).
	
	self
		makeBaseFrameWithMethod: memory nilObject
		context: memory nilObject
		receiver: memory nilObject
		args: #()
		andStack: { newObjectOop }.

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1 "TenureByAge".

	"Remap our object address to its new location"
	newObjectAddress := memory remapObj: newObjectOop.
	self assert: (memory hashBitsOf: newObjectAddress) equals: newObjectHash
]

{ #category : #'tests-4-scavenge-stack' }
VMSpurScavengerTest >> testReceiverInStackShouldSurviveScanvenge [

	| newObjectOop newObjectHash newObjectAddress |
	newObjectOop := self newZeroSizedObject.
	newObjectHash := (memory hashBitsOf: newObjectOop).
	
	self
		makeBaseFrameWithMethod: memory nilObject
		context: memory nilObject
		receiver: newObjectOop
		args: #()
		andStack: #().

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1 "TenureByAge".
	
	"Remap our object address to its new location"
	newObjectAddress := memory remapObj: newObjectOop.
	self assert: (memory hashBitsOf: newObjectAddress) equals: newObjectHash
]

{ #category : #'tests-3-scavenge-basic' }
VMSpurScavengerTest >> testReferencedObjectShouldSurviveScavenge [

	| rootObjectAddress rootObjectHash newRootObjectAddress referencedObjectAddress referencedObjectHash newReferencedObjectAddress |
	rootObjectAddress := self newObjectWithSlots: 1.
	rootObjectHash := (memory hashBitsOf: rootObjectAddress).

	referencedObjectAddress := self newZeroSizedObject.
	referencedObjectHash := (memory hashBitsOf: referencedObjectAddress).
	
	memory storePointer: 0 ofObject: rootObjectAddress withValue: referencedObjectAddress.
	
	memory coInterpreter method: rootObjectAddress.

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1 "TenureByAge".
	
	"Remap our object address to its new location"
	newRootObjectAddress := memory remapObj: rootObjectAddress.
	newReferencedObjectAddress := memory remapObj: referencedObjectAddress.
	self assert: (memory hashBitsOf: newRootObjectAddress) equals: rootObjectHash.
	self assert: (memory hashBitsOf: newReferencedObjectAddress) equals: referencedObjectHash
]

{ #category : #'tests-3-scavenge-basic' }
VMSpurScavengerTest >> testScavengeEmptyMemoryShouldExchangePastAndFutureSpaces [

	| oldPastSpaceStart oldFutureSpaceStart |
	oldPastSpaceStart := memory scavenger pastSpace start.
	oldFutureSpaceStart := memory scavenger futureSpace start.
	
	memory doScavenge: 1 "TenureByAge".
	
	self assert: memory scavenger pastSpace start equals: oldFutureSpaceStart.
	self assert: memory scavenger futureSpace start equals: oldPastSpaceStart.
]

{ #category : #'tests-3-scavenge-basic' }
VMSpurScavengerTest >> testScavengeNonSurvivorShouldEmptyEden [
	"Nil should survive."
	"A new object not referenced should not survive."
	self newZeroSizedObject.
	
	memory doScavenge: 1 "TenureByAge".
	
	self assert: memory freeStart equals: memory scavenger eden start
]

{ #category : #'tests-3-scavenge-basic' }
VMSpurScavengerTest >> testScavengeNonSurvivorShouldOnlyCopySurvivorObjectToPastSpace [

	"Only Nil should survive."
	"A new object not referenced should not survive."
	self newObjectWithSlots: 1.
	
	memory doScavenge: 1 "TenureByAge".
	
	self assertPastSpaceHasOnlyNil
]

{ #category : #'tests-3-scavenge-basic' }
VMSpurScavengerTest >> testScavengeShouldCopySurvivorObjectToPastSpace [	
	"Nil should survive.
	It is referenced by the roots because many of their slots are nilled."
	memory doScavenge: 1 "TenureByAge".
	
	self assertPastSpaceHasOnlyNil
]

{ #category : #'tests-3-scavenge-basic' }
VMSpurScavengerTest >> testScavengeSurvivorShouldEmptyEden [

	memory doScavenge: 1 "TenureByAge".
	
	self assert: memory freeStart equals: memory scavenger eden start
]

{ #category : #'tests-3-scavenge-basic' }
VMSpurScavengerTest >> testScavengeTwiceShouldExchangePastAndFutureSpacesBackAndForth [

	| oldPastSpaceStart oldFutureSpaceStart |	
	oldPastSpaceStart := memory scavenger pastSpace start.
	oldFutureSpaceStart := memory scavenger futureSpace start.
	
	2 timesRepeat: [ memory doScavenge: 1 "TenureByAge" ].
	
	self assert: memory scavenger pastSpace start equals: oldPastSpaceStart.
	self assert: memory scavenger futureSpace start equals: oldFutureSpaceStart.
]

{ #category : #'tests-3-scavenge-basic' }
VMSpurScavengerTest >> testUnreferencedObjectCycleShouldNotSurviveScavenge [
	| objectA objectB |
	objectA := self newObjectWithSlots: 1.
	objectB := self newObjectWithSlots: 1.
	memory
		storePointer: 0
		ofObject: objectA
		withValue: objectB.
	memory
		storePointer: 0
		ofObject: objectB
		withValue: objectA.


	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1. "TenureByAge"
	
	self assertPastSpaceHasOnlyNil
]

{ #category : #'tests-3-scavenge-basic' }
VMSpurScavengerTest >> testUnreferencedObjectGraphShouldNotSurviveScavenge [
	| unreferencedRootObjectAddress referencedObjectAddress |
	unreferencedRootObjectAddress := self newObjectWithSlots: 1.
	referencedObjectAddress := self newZeroSizedObject.
	memory
		storePointer: 0
		ofObject: unreferencedRootObjectAddress
		withValue: referencedObjectAddress.

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1. "TenureByAge"
	
	self assertPastSpaceHasOnlyNil
]
