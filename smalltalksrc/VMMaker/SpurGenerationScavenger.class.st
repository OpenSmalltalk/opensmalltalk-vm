Class {
	#name : #SpurGenerationScavenger,
	#superclass : #VMClass,
	#instVars : [
		'coInterpreter',
		'manager',
		'memory',
		'futureSpace',
		'pastSpace',
		'rememberedSet',
		'rememberedSetSize'
	],
	#category : #'VMMaker-MemoryManager'
}

{ #category : #api }
SpurGenerationScavenger >> copyAndForward: survivor [
	"copyAndForward: survivor copies a survivor object either to
	 futureSurvivorSpace or, if it is to be promoted, to oldSpace.
	 It leaves a forwarding pointer behind."
	<var: #survivor type: #'object *'>
	| newLocation |
	newLocation := (self shouldBeTenured: survivor)
						ifTrue: [self copyToOldSpace: survivor]
						ifFalse: [self copyToFutureSpace: survivor].
	manager forward: survivor to: newLocation
			
]

{ #category : #api }
SpurGenerationScavenger >> scavenge [
	"The main routine, scavenge, scavenges young objects reachable from the roots (the stack zone
	 and the rememberedTable).  It first scavenges the new objects immediately reachable from the
	 stack zone, then those directly from old ones (all in the remembered table).  Then it scavenges
	 those that are transitively reachable.  If this results in a promotion, the promotee gets remembered,
	 and it first scavenges objects adjacent to the promotee, then scavenges the ones reachable from
	 the promoted.  This loop continues until no more reachable objects are left.  At that point,
	 pastSurvivorSpace is exchanged with futureSurvivorSpace.

	 Notice that each pointer in a live object is inspected once and only once.  The previousRememberedSetSize
	 and previousFutureSurvivorSpaceSize variables ensure that no object is scanned twice, as well as
	 detecting closure.  If this were not true, some pointers might get forwarded twice."

	coInterpreter scavengeStacks.
	self scavengeLoop.
	self exchange: pastSpace with: futureSpace
]

{ #category : #api }
SpurGenerationScavenger >> scavengeFutureSurvivorSpaceStartingAt: initialAddress [
	"scavengeFutureSurvivorSpaceStartingAt: does a depth-first traversal of the
	 new objects starting at the one at the nth word of futureSurvivorSpace."
	| ptr |
	<var: #ptr type: #'char *'>
	ptr := initialAddress.
	[ptr < futureSpace limit] whileTrue:
		[| obj |
		 obj := manager objectAt: ptr.
		 ptr := ptr + (manager byteLengthOf: obj).
		 self cCoerceSimple: (self scavengeReferentsOf: obj)
			to: #void]
]

{ #category : #api }
SpurGenerationScavenger >> scavengeLoop [
	"This is the inner loop of the main routine, scavenge.  It first scavenges the new objects immediately
	 reachable from old ones. Then it scavenges those that are transitively reachable.  If this results in a
	 promotion, the promotee gets remembered, and it first scavenges objects adjacent to the promotee,
	 then scavenges the ones reachable from the promoted.  This loop continues until no more reachable
	 objects are left.  At that point, pastSurvivorSpace is exchanged with futureSurvivorSpace.

	 Notice that each pointer in a live object is inspected once and only once.  The previousRememberedSetSize
	 and previousFutureSurvivorSpaceLimit variables ensure that no object is scanned twice, as well as
	 detecting closure.  If this were not true, some pointers might get forwarded twice."

	| previousRememberedSetSize previousFutureSurvivorSpaceLimit |
	previousRememberedSetSize := 0.
	previousFutureSurvivorSpaceLimit := futureSpace limit.
	self assert: futureSpace limit = futureSpace start.
	[self scavengeRememberedSetStartingAt: previousRememberedSetSize.
	 previousFutureSurvivorSpaceLimit = futureSpace limit ifTrue:
		[^self].
		
	 previousRememberedSetSize := rememberedSetSize.
	 self scavengeFutureSurvivorSpaceStartingAt: previousFutureSurvivorSpaceLimit.
	 previousFutureSurvivorSpaceLimit = rememberedSetSize ifTrue:
		[^self].

	 previousFutureSurvivorSpaceLimit := futureSpace size] repeat
]

{ #category : #api }
SpurGenerationScavenger >> scavengeReferentsOf: referrer [
	"scavengeReferentsOf: referrer inspects all the pointers in referrer.
	 If any are new objects, it has them moved to FutureSurvivorSpace,
	 and returns truth. If there are no new referents, it returns falsity."
	<var: #referrer type: #'object *'>
	| foundNewReferent referent |
	referrer isPointers ifFalse:
		[^self].
	foundNewReferent := false.
	0 to: (manager lengthOf: referrer) do:
		[:i|
		referent := manager fetchPointer: i ofObject: referrer.
		(manager isYoung: referent) ifTrue:
			[foundNewReferent := true.
			 referent isForwarded ifFalse:
				[self copyAndForward: referent].
			 manager
				storePointerUnchecked: i
				ofObject: referrer
				withValue: (manager forwardingPointerOf: referent)]].
	^foundNewReferent
]

{ #category : #api }
SpurGenerationScavenger >> scavengeRememberedSetStartingAt: n [
	"scavengeRememberedSetStartingAt: n traverses objects in the remembered
	 set starting at the nth one.  If the object does not refer to any new objects, it
	 is removed from the set. Otherwise, its new referents are scavenged."
	| destIndex sourceIndex |
	sourceIndex := destIndex := n.
	[sourceIndex < rememberedSetSize] whileTrue:
		[| referree |
		referree := rememberedSet at: sourceIndex.
		(self scavengeReferentsOf: referree)
			ifTrue:
				[rememberedSet at: destIndex put: referree.
				 destIndex := destIndex + 1]
			ifFalse:
				[referree isRemembered: false].
		 sourceIndex := sourceIndex + 1].
	rememberedSetSize := destIndex
]
