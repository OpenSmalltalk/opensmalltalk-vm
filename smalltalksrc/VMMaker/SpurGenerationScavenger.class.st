Class {
	#name : #SpurGenerationScavenger,
	#superclass : #VMClass,
	#instVars : [
		'coInterpreter',
		'manager',
		'memory',
		'eden',
		'futureSpace',
		'pastSpace',
		'rememberedSet',
		'rememberedSetSize',
		'tenuringThreshold',
		'tenuringProportion'
	],
	#classVars : [
		'RememberedSetLimit',
		'RememberedSetRedZone'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #'class initialization' }
SpurGenerationScavenger class >> initialize [
	"SpurGenerationScavenger initialize"
	RememberedSetLimit := 4096.
	RememberedSetRedZone := 1024 * 3
]

{ #category : #scavenger }
SpurGenerationScavenger >> copyAndForward: survivor [
	"copyAndForward: survivor copies a survivor object either to
	 futureSurvivorSpace or, if it is to be promoted, to oldSpace.
	 It leaves a forwarding pointer behind."
	| newLocation |
	newLocation := (self shouldBeTenured: survivor)
						ifTrue: [self copyToOldSpace: survivor]
						ifFalse: [self copyToFutureSpace: survivor].
	manager forward: survivor to: newLocation
]

{ #category : #accessing }
SpurGenerationScavenger >> eden [
	<returnTypeC: #'SpurNewSpaceSpace *'>
	^self addressOf: eden
]

{ #category : #accessing }
SpurGenerationScavenger >> futureSpace [
	<returnTypeC: #'SpurNewSpaceSpace *'>
	^self addressOf: futureSpace
]

{ #category : #initialization }
SpurGenerationScavenger >> initPastSpaceForObjectEnumeration [
	"For SuurMemoryManager allNewSpaceObjectsDo: fill pastSpace with
	 a single empty object."
	| objOop |
	manager initFreeChunkWithBytes: pastSpace limit - pastSpace start at: pastSpace start.
	objOop := manager objectStartingAt: pastSpace start.
	self assert: (manager addressAfter: objOop) = pastSpace limit
]

{ #category : #initialization }
SpurGenerationScavenger >> initialize [
	rememberedSet := CArrayAccessor on: (Array new: RememberedSetLimit).
	rememberedSetSize := 0.
	tenuringThreshold := 0
]

{ #category : #initialization }
SpurGenerationScavenger >> manager: aSpurMemoryManager memory: memoryArray newSpaceStart: startAddress newSpaceBytes: totalBytes edenBytes: requestedEdenBytes [ 
	| edenBytes edenLimit edenStart survivorBytes |
	manager := aSpurMemoryManager.
	memory := memoryArray.
	edenBytes := requestedEdenBytes.
	edenStart := startAddress.
	survivorBytes := totalBytes - edenBytes // 2 truncateTo: manager allocationUnit.
	edenBytes := totalBytes - survivorBytes - survivorBytes truncateTo: manager allocationUnit.
	edenLimit := edenStart + edenBytes roundUpTo: manager allocationUnit.
	self assert: totalBytes - (edenLimit - edenStart) - survivorBytes - survivorBytes < manager allocationUnit.
	eden := SpurNewSpaceSpace new.
	pastSpace := SpurNewSpaceSpace new.
	futureSpace := SpurNewSpaceSpace new.
	eden start: edenStart limit: edenLimit.
	pastSpace start: edenLimit limit: edenLimit + survivorBytes.
	futureSpace start: pastSpace limit limit: pastSpace limit + survivorBytes.
	self assert: futureSpace limit <= (startAddress + totalBytes).
	self assert: eden start \\ manager allocationUnit
				+ (eden limit \\ manager allocationUnit) = 0.
	self assert: pastSpace start \\ manager allocationUnit
				+ (pastSpace limit \\ manager allocationUnit) = 0.
	self assert: futureSpace start \\ manager allocationUnit
				+ (futureSpace limit \\ manager allocationUnit) = 0.
	self initPastSpaceForObjectEnumeration.
	manager initSpaceForAllocationCheck: eden
]

{ #category : #accessing }
SpurGenerationScavenger >> pastSpace [
	<returnTypeC: #'SpurNewSpaceSpace *'>
	^self addressOf: pastSpace
]

{ #category : #accessing }
SpurGenerationScavenger >> pastSpaceBytes [
	^pastSpace limit - pastSpace start
]

{ #category : #'store check' }
SpurGenerationScavenger >> remember: objOop [
	rememberedSetSize < RememberedSetLimit
		ifTrue:
			[rememberedSet at: rememberedSetSize put: objOop.
			 (rememberedSetSize := rememberedSetSize + 1) >= RememberedSetRedZone ifTrue:
				[manager scheduleScavenge]]
		ifFalse:
			[self error: 'remembered set overflow' "for now"]
]

{ #category : #scavenger }
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
	self exchange: pastSpace with: futureSpace.
	self computeTenuringThreshold
]

{ #category : #scavenger }
SpurGenerationScavenger >> scavengeFutureSurvivorSpaceStartingAt: initialAddress [
	"scavengeFutureSurvivorSpaceStartingAt: does a depth-first traversal of the
	 new objects starting at the one at initialAddress in futureSurvivorSpace."
	| ptr |
	ptr := initialAddress.
	[ptr < futureSpace limit] whileTrue:
		[| obj |
		 obj := manager objectStartingAt: ptr.
		 ptr := manager addressAfter: obj.
		 self cCoerceSimple: (self scavengeReferentsOf: obj) to: #void]
]

{ #category : #scavenger }
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

{ #category : #scavenger }
SpurGenerationScavenger >> scavengeReferentsOf: referrer [
	"scavengeReferentsOf: referrer inspects all the pointers in referrer.
	 If any are new objects, it has them moved to FutureSurvivorSpace,
	 and returns truth. If there are no new referents, it returns falsity."
	| foundNewReferent |
	"manager isPointersNonImm: referrer) ifFalse:
		[^false]."
	foundNewReferent := false.
	0 to: (manager numPointerSlotsOf: referrer) do:
		[:i| | referent |
		referent := manager fetchPointer: i ofObject: referrer.
		((manager isNonImmediate: referent)
		 and: [manager isYoung: referent]) ifTrue:
			[foundNewReferent := true.
			 (manager isForwarded: referent) ifFalse:
				[self copyAndForward: referent].
			 manager
				storePointerUnchecked: i
				ofObject: referrer
				withValue: (manager forwardingPointerOf: referent)]].
	^foundNewReferent
]

{ #category : #scavenger }
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
				[manager setIsRememberedOf: referree to: false].
		 sourceIndex := sourceIndex + 1].
	rememberedSetSize := destIndex
]

{ #category : #accessing }
SpurGenerationScavenger >> scavengerTenuringThreshold [ "(Slang flattens so need unique selectors)"
	<returnTypeC: #float>
	^tenuringThreshold >= pastSpace start
		ifTrue: [(tenuringThreshold - pastSpace start) asFloat / (pastSpace limit - pastSpace start)]
		ifFalse: [0]
]

{ #category : #accessing }
SpurGenerationScavenger >> scavengerTenuringThreshold: aProportion [ "(Slang flattens so need unique selectors)"
	<var: 'aProportion' type: #float>
	tenuringProportion := aProportion.
	tenuringThreshold := aProportion = 0.0
							ifTrue: [0]
							ifFalse: [((pastSpace limit - pastSpace start) * aProportion) rounded + pastSpace start]
]

{ #category : #scavenger }
SpurGenerationScavenger >> shouldBeTenured: survivor [
	"Answer if an object should be tenured.  Use the tenuringThreshold to decide.
	 If the survivors (measured in bytes) are above some fraction of the survivor
	 space then objects below the threshold (older objects, since allocation grows
	 upwards and hence new objects are later than old) are scavenged.  Otherwise,
	 the threshold is set to 0 and no objects are tenured.  See e.g.
	 An adaptive tenuring policy for generation scavengers, David Ungar & Frank Jackson.
	 ACM TOPLAS, Volume 14 Issue 1, Jan. 1992, pp 1 - 27."

	^survivor < tenuringThreshold
]
