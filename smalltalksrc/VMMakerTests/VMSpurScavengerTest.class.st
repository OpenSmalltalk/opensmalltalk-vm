Class {
	#name : #VMSpurScavengerTest,
	#superclass : #VMSpurInitializedOldSpaceTest,
	#category : #'VMMakerTests-MemoryTests'
}

{ #category : #asserting }
VMSpurScavengerTest >> assertPastSpaceIsEmpty [
	self
		assert: memory pastSpaceStart
		equals: memory scavenger pastSpace start
]

{ #category : #helpers }
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
VMSpurScavengerTest >> testAllocatingObjectsBelowThresholdDoesNotScheduleScavenge [

	| times |
	times := ((memory scavengeThreshold - memory freeStart) / 16) floor.
	
	times timesRepeat: [ self newZeroSizedObject ].
	
	"We are just below the threshold and we do not need a GC"
	self deny: memory needGCFlag
]

{ #category : #'tests-4-scavenge-stack' }
VMSpurScavengerTest >> testAllocatingObjectsBelowThresholdShouldBeYoung [

	| times anObjectOop |
	times := ((memory scavengeThreshold - memory freeStart) / 16) floor.
	
	times timesRepeat: [ anObjectOop := self newZeroSizedObject ].
	
	self assert: (memory isYoungObject: anObjectOop)
]

{ #category : #'tests-4-scavenge-stack' }
VMSpurScavengerTest >> testAllocatingObjectsOverThresholdShouldBeOld [

	| times anObject |
	times := ((memory scavengeThreshold - memory freeStart) / 16) floor.
	times timesRepeat: [ self newZeroSizedObject ].
	
	"We are just below the threshold and we do not need a GC"
	"We will allocate a new one forcing the allocation in the old space and asking the GC"
	
	anObject := memory
		allocateSlots: 0
		format: 0 "zero sized object"
		classIndex: self zeroSizedObjectClassIndex.
		
	self assert: (memory isOldObject: anObject)
]

{ #category : #'tests-4-scavenge-stack' }
VMSpurScavengerTest >> testAllocatingObjectsOverThresholdShouldScheduleScavenge [

	| times |
	times := ((memory scavengeThreshold - memory freeStart) / 16) floor.
	times timesRepeat: [ self newZeroSizedObject ].
	
	"We are just below the threshold and we do not need a GC"
	"We will allocate a new one forcing the allocation in the old space and asking the GC"
	
	memory
		allocateSlots: 0
		format: 0 "zero sized object"
		classIndex: self zeroSizedObjectClassIndex.
		
	self assert: memory needGCFlag
]

{ #category : #'tests-4-scavenge-stack' }
VMSpurScavengerTest >> testArgumentInStackShouldSurviveScanvenge [

	| newObjectOop newObjectHash newObjectAddress |	
	newObjectOop := self newZeroSizedObject.
	newObjectHash := (memory hashBitsOf: newObjectOop).

	stackBuilder args: { newObjectOop }.
	stackBuilder addNewFrame.
	stackBuilder buildStack.

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
	
	stackBuilder addNewFrame method: methodBuilder newMethod buildMethod.
	stackBuilder buildStack.
	newObjectOop := interpreter ensureFrameIsMarried: interpreter framePointer  SP: interpreter stackPointer.
	newObjectHash := (memory hashBitsOf: newObjectOop).

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
	
	stackBuilder addNewFrame method: newObjectOop.
	stackBuilder buildStack.

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1 "TenureByAge".
	
	"Remap our object address to its new location"
	newObjectAddress := memory remapObj: newObjectOop.
	self assert: (memory hashBitsOf: newObjectAddress) equals: newObjectHash
]

{ #category : #'tests-3-scavenge-basic' }
VMSpurScavengerTest >> testMovingReferencedObjectShouldUpdateReference [

	| rootObjectAddress newRootObjectAddress referencedObjectAddress referencedObjectHash |
	rootObjectAddress := self newObjectWithSlots: 1.

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
	
	self
		assert: (memory hashBitsOf: (memory fetchPointer: 0 ofObject: newRootObjectAddress))
		equals: referencedObjectHash
]

{ #category : #'tests-4-scavenge-stack' }
VMSpurScavengerTest >> testObjectInStackShouldSurviveScanvenge [

	| newObjectOop newObjectHash newObjectAddress |
	newObjectOop := self newZeroSizedObject.
	newObjectHash := (memory hashBitsOf: newObjectOop).
	
	stackBuilder addNewFrame stack: { newObjectOop }.
	stackBuilder buildStack.

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1 "TenureByAge".

	"Remap our object address to its new location"
	newObjectAddress := memory remapObj: newObjectOop.
	self assert: (memory hashBitsOf: newObjectAddress) equals: newObjectHash
]

{ #category : #'tests-6-scavenge-rememberedset' }
VMSpurScavengerTest >> testOldObjectIsNotRemembered [

	| oldObjectAddress |
	
	"Create an object, reference it, and move it to old space"
	oldObjectAddress := self newObjectWithSlots: 1.
	memory coInterpreter newMethod: oldObjectAddress.
	memory flushNewSpace.
	oldObjectAddress := memory remapObj: oldObjectAddress.

	self deny: (memory isRemembered: oldObjectAddress).
]

{ #category : #'tests-6-scavenge-rememberedset' }
VMSpurScavengerTest >> testOldObjectReferenceToYoungObjectShouldBeRemappedAfterScanvenge [

	| oldObjectAddress rememberedObjectAddress rememberedObjectHash newRememberedObjectAddress maybeMappedReferenceToYoungObject |
	
	"Create an object, reference it, and move it to old space"
	oldObjectAddress := self newObjectWithSlots: 1.
	memory coInterpreter newMethod: oldObjectAddress.
	memory flushNewSpace.
	oldObjectAddress := memory remapObj: oldObjectAddress.

	"Create a young object and reference it from the old object"
	rememberedObjectAddress := self newZeroSizedObject.
	rememberedObjectHash := memory hashBitsOf: rememberedObjectAddress.
	memory storePointer: 0 ofObject: oldObjectAddress withValue: rememberedObjectAddress.
	

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1 "TenureByAge".
	
	"Remap our object address to its new location"
	maybeMappedReferenceToYoungObject := memory fetchPointer: 0 ofObject: oldObjectAddress.
	newRememberedObjectAddress := memory remapObj: rememberedObjectAddress.
	self assert: maybeMappedReferenceToYoungObject equals: newRememberedObjectAddress
]

{ #category : #'tests-6-scavenge-rememberedset' }
VMSpurScavengerTest >> testOverflowRememberedSetShouldMakeItGrow [

	| oldObjectRootAddress originalLimit youngObjectAddress |
	originalLimit := memory scavenger rememberedSetLimit.

	"Create as many objects for the remembered set + 1"
	oldObjectRootAddress := self newObjectWithSlots: originalLimit + 1.
	1 to: originalLimit + 1 do: [ :i | 
		memory
			storePointer: i - 1
			ofObject: oldObjectRootAddress
			withValue: (self newObjectWithSlots: 1).
	].
	"Flush them to the old space"
	memory coInterpreter method: oldObjectRootAddress.
	memory flushNewSpace.
	
	"Make old objects reference a young object"
	youngObjectAddress := self newZeroSizedObject.
	1 to: originalLimit + 1 do: [ :i | | oldObjectAddress |
		oldObjectAddress := memory fetchPointer: i - 1 ofObject: oldObjectRootAddress.
		memory storePointer: 0
			ofObject: oldObjectAddress
			withValue: youngObjectAddress ].

	self assert: memory scavenger rememberedSetLimit equals: originalLimit * 2
]

{ #category : #'tests-4-scavenge-stack' }
VMSpurScavengerTest >> testReceiverInStackShouldSurviveScanvenge [

	| newObjectOop newObjectHash newObjectAddress |
	newObjectOop := self newZeroSizedObject.
	newObjectHash := (memory hashBitsOf: newObjectOop).
	
	stackBuilder addNewFrame receiver: newObjectOop.
	stackBuilder buildStack.

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

{ #category : #'tests-6-scavenge-rememberedset' }
VMSpurScavengerTest >> testRememberedObjectShouldSurviveScanvenge [

	| oldObjectAddress rememberedObjectAddress rememberedObjectHash newRememberedObjectAddress |
	
	"Create an object, reference it, and move it to old space"
	oldObjectAddress := self newObjectWithSlots: 1.
	memory coInterpreter newMethod: oldObjectAddress.
	memory flushNewSpace.
	oldObjectAddress := memory remapObj: oldObjectAddress.

	"Create a young object and reference it from the old object"
	rememberedObjectAddress := self newZeroSizedObject.
	rememberedObjectHash := memory hashBitsOf: rememberedObjectAddress.
	memory storePointer: 0 ofObject: oldObjectAddress withValue: rememberedObjectAddress.
	

	"Nil should survive, but newObjectOop should survive too.
	Nil is referenced by the roots because many of their slots are nilled.
	newObjectOop is referenced by the stack"
	memory doScavenge: 1 "TenureByAge".
	
	"Remap our object address to its new location"
	newRememberedObjectAddress := memory remapObj: rememberedObjectAddress.
	self assert: (memory hashBitsOf: newRememberedObjectAddress) equals: rememberedObjectHash
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
	
	self assertPastSpaceIsEmpty
]

{ #category : #'tests-7-scavenge-order' }
VMSpurScavengerTest >> testScavengeObjectInRememberedSetShouldBeInvertedToBeBeforeObjectInStack [

	| objectInTheStack oldObjectAddress objectInRememberedSet |
	"Create an object, reference it, and move it to old space"
	oldObjectAddress := self newObjectWithSlots: 1.
	memory coInterpreter newMethod: oldObjectAddress.
	memory flushNewSpace.
	oldObjectAddress := memory remapObj: oldObjectAddress.

	"Instantiate first the object in the stack, then the object in the remembered set.
	They will be inverted in memory when the scavenger copies them to future space"
	objectInTheStack := self newZeroSizedObject.
	objectInRememberedSet := self newZeroSizedObject.

	stackBuilder addNewFrame method: objectInTheStack.
	stackBuilder buildStack.
		
	memory storePointer: 0 ofObject: oldObjectAddress withValue: objectInRememberedSet.
	
	memory doScavenge: 1 "TenureByAge".
	
	self assert: (memory remapObj: objectInRememberedSet) < (memory remapObj: objectInTheStack)
]

{ #category : #'tests-7-scavenge-order' }
VMSpurScavengerTest >> testScavengeObjectInRemembererdSetShouldBeBeforeObjectInStack [

	| objectInTheStack oldObjectAddress objectInRememberedSet |
	"Create an object, reference it, and move it to old space"
	oldObjectAddress := self newObjectWithSlots: 1.
	memory coInterpreter newMethod: oldObjectAddress.
	memory flushNewSpace.
	oldObjectAddress := memory remapObj: oldObjectAddress.

	"Instantiate first the object in the remembered set, then the object in the stack.
	They will be copied to future space in the same order by the scavenger"
	objectInRememberedSet := self newZeroSizedObject.
	objectInTheStack := self newZeroSizedObject.
	
	stackBuilder addNewFrame method: objectInTheStack.
	stackBuilder buildStack.
	
	memory storePointer: 0 ofObject: oldObjectAddress withValue: objectInRememberedSet.
	
	memory doScavenge: 1 "TenureByAge".
	
	self assert: (memory remapObj: objectInRememberedSet) < (memory remapObj: objectInTheStack)
]

{ #category : #'tests-7-scavenge-order' }
VMSpurScavengerTest >> testScavengeObjectInStackShouldBeBeforeObjectInSpecialVariable [

	| objectInTheStack objectInSpecialVariable |
	objectInTheStack := self newZeroSizedObject.
	objectInSpecialVariable := self newZeroSizedObject.
	
	stackBuilder addNewFrame method: objectInTheStack.
	stackBuilder buildStack.
		
	memory coInterpreter method: objectInSpecialVariable.
	
	memory doScavenge: 1 "TenureByAge".
	
	self assert: (memory remapObj: objectInTheStack) < (memory remapObj: objectInSpecialVariable)
]

{ #category : #'tests-7-scavenge-order' }
VMSpurScavengerTest >> testScavengeObjectInStackShouldBeInvertedToBeBeforeObjectInSpecialVariable [

	| objectInTheStack objectInSpecialVariable |
	objectInSpecialVariable := self newZeroSizedObject.
	objectInTheStack := self newZeroSizedObject.
	
	stackBuilder addNewFrame method: objectInTheStack.
	stackBuilder buildStack.
		
	memory coInterpreter method: objectInSpecialVariable.
	
	memory doScavenge: 1 "TenureByAge".
	
	self assert: (memory remapObj: objectInTheStack) < (memory remapObj: objectInSpecialVariable)
]

{ #category : #'tests-3-scavenge-basic' }
VMSpurScavengerTest >> testScavengeShouldCopySurvivorObjectToPastSpace [	
	"Nil should survive.
	It is referenced by the roots because many of their slots are nilled."
	memory doScavenge: 1 "TenureByAge".
	
	self assertPastSpaceIsEmpty
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

{ #category : #'tests-7-scavenge-order' }
VMSpurScavengerTest >> testScavengedObjectsShouldBeCopiedInInstanceVariableOrder [

	| rootObjectAddress objectThatShouldGoSecond objectThatShouldGoFirst |
	rootObjectAddress := self newObjectWithSlots: 2.
	objectThatShouldGoSecond := self newZeroSizedObject.
	objectThatShouldGoFirst := self newZeroSizedObject.
	
	memory storePointer: 0 ofObject: rootObjectAddress withValue: objectThatShouldGoFirst.
	memory storePointer: 1 ofObject: rootObjectAddress withValue: objectThatShouldGoSecond.
	
	memory coInterpreter method: rootObjectAddress.
	
	memory doScavenge: 1 "TenureByAge".
	
	self assert: (memory remapObj: objectThatShouldGoFirst) < (memory remapObj: objectThatShouldGoSecond)
]

{ #category : #'tests-7-scavenge-order' }
VMSpurScavengerTest >> testScavengedRootObjectsShouldBeCopiedBeforeOtherObjects [

	| firstRootObjectAddress nonRootObjectAddress secondRootObjectAddress |
	firstRootObjectAddress := self newObjectWithSlots: 1.
	nonRootObjectAddress := self newZeroSizedObject.
	secondRootObjectAddress := self newZeroSizedObject.
	
	memory storePointer: 0 ofObject: firstRootObjectAddress withValue: nonRootObjectAddress.
	
	memory coInterpreter method: firstRootObjectAddress.
	memory coInterpreter newMethod: secondRootObjectAddress.
	
	memory doScavenge: 1 "TenureByAge".
	
	self assert: (memory remapObj: secondRootObjectAddress) < (memory remapObj: nonRootObjectAddress)
]

{ #category : #'tests-6-scavenge-rememberedset' }
VMSpurScavengerTest >> testStoreOldObjectInYoungObjectShouldNotRememberOldObject [

	| oldObjectAddress youngObjectAddress |
	
	"Create an object, reference it, and move it to old space"
	oldObjectAddress := self newObjectWithSlots: 1.
	memory coInterpreter newMethod: oldObjectAddress.
	memory flushNewSpace.
	oldObjectAddress := memory remapObj: oldObjectAddress.

	"Create a young object and reference it from the old object"
	youngObjectAddress := self newZeroSizedObject.
	memory storePointer: 0 ofObject: youngObjectAddress withValue: oldObjectAddress.
	
	self deny: (memory isRemembered: oldObjectAddress).
]

{ #category : #'tests-6-scavenge-rememberedset' }
VMSpurScavengerTest >> testStoreOldObjectInYoungObjectShouldNotRememberYoungObject [

	| oldObjectAddress youngObjectAddress |
	
	"Create an object, reference it, and move it to old space"
	oldObjectAddress := self newObjectWithSlots: 1.
	memory coInterpreter newMethod: oldObjectAddress.
	memory flushNewSpace.
	oldObjectAddress := memory remapObj: oldObjectAddress.

	"Create a young object and reference it from the old object"
	youngObjectAddress := self newZeroSizedObject.
	memory storePointer: 0 ofObject: youngObjectAddress withValue: oldObjectAddress.
	
	self deny: (memory isRemembered: youngObjectAddress).
]

{ #category : #'tests-6-scavenge-rememberedset' }
VMSpurScavengerTest >> testStoreYoungObjectInOldObjectShouldRememberOldObject [

	| oldObjectAddress rememberedObjectAddress |
	
	"Create an object, reference it, and move it to old space"
	oldObjectAddress := self newObjectWithSlots: 1.
	memory coInterpreter newMethod: oldObjectAddress.
	memory flushNewSpace.
	oldObjectAddress := memory remapObj: oldObjectAddress.

	"Create a young object and reference it from the old object"
	rememberedObjectAddress := self newZeroSizedObject.
	memory storePointer: 0 ofObject: oldObjectAddress withValue: rememberedObjectAddress.
	
	self assert: (memory isRemembered: oldObjectAddress).
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
	
	self assertPastSpaceIsEmpty
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
	
	self assertPastSpaceIsEmpty
]

{ #category : #'tests-6-scavenge-rememberedset' }
VMSpurScavengerTest >> testYoungObjectIsNotRemembered [

	| newObjectAddress |
	newObjectAddress := self newObjectWithSlots: 1.

	self deny: (memory isRemembered: newObjectAddress).
]
