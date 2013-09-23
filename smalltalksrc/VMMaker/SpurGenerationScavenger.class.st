Class {
	#name : #SpurGenerationScavenger,
	#superclass : #CogClass,
	#instVars : [
		'coInterpreter',
		'manager',
		'eden',
		'futureSpace',
		'pastSpace',
		'futureSurvivorStart',
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
	RememberedSetLimit := 16384.
	RememberedSetRedZone := RememberedSetLimit - (RememberedSetLimit // 2)
]

{ #category : #accessing }
SpurGenerationScavenger >> coInterpreter: aCoInterpreter [
	coInterpreter := aCoInterpreter
]

{ #category : #scavenger }
SpurGenerationScavenger >> computeTenuringThreshold [
	| fractionSurvived |
	<var: 'fractionSurvived' type: #float>
	fractionSurvived := (futureSurvivorStart - futureSpace start) asFloat
						/ (futureSpace limit - futureSpace start).
	tenuringThreshold := fractionSurvived > 0.9
							ifTrue: [((pastSpace limit - pastSpace start) * tenuringProportion) rounded + pastSpace start]
							ifFalse: [0]
]

{ #category : #scavenger }
SpurGenerationScavenger >> copyAndForward: survivor [
	"copyAndForward: survivor copies a survivor object either to
	 futureSurvivorSpace or, if it is to be promoted, to oldSpace.
	 It leaves a forwarding pointer behind."
	<inline: true>
	| bytesInObject newLocation |
	bytesInObject := manager bytesInObject: survivor.
	newLocation := ((self shouldBeTenured: survivor)
					  or: [futureSurvivorStart + bytesInObject > futureSpace limit])
						ifTrue: [self copyToOldSpace: survivor]
						ifFalse: [self copyToFutureSpace: survivor bytes: bytesInObject].
	manager forward: survivor to: newLocation.
	^newLocation
]

{ #category : #scavenger }
SpurGenerationScavenger >> copyToFutureSpace: survivor bytes: bytesInObject [
	"Copy survivor to futureSpace.  Assume it will fit (checked by sender).
	 Answer the new oop of the object (it may have an overflow size field)."
	<inline: true>
	| startOfSurvivor newStart |
	self assert: futureSurvivorStart + bytesInObject <= futureSpace limit.
	startOfSurvivor := manager startOfObject: survivor.
	newStart := futureSurvivorStart.
	futureSurvivorStart := futureSurvivorStart + bytesInObject.
	manager mem: newStart cp: startOfSurvivor y: bytesInObject.
	^newStart + (survivor - startOfSurvivor)
]

{ #category : #scavenger }
SpurGenerationScavenger >> copyToOldSpace: survivor [
	"Copy survivor to oldSpace.  Answer the new oop of the object."
	<inline: true>
	| numSlots newOop |
	self flag: 'why not just pass header??'.
	numSlots := manager numSlotsOf: survivor.
	newOop := manager
					allocateSlotsInOldSpace: numSlots
					format: (manager formatOf: survivor)
					classIndex: (manager classIndexOf: survivor).
	newOop ifNil:
		[self error: 'out of memory'].
	manager
		mem: newOop + manager baseHeaderSize
		cp: survivor + manager baseHeaderSize
		y: numSlots * manager wordSize.
	self remember: newOop.
	manager setIsRememberedOf: newOop to: true.
	^newOop
]

{ #category : #accessing }
SpurGenerationScavenger >> eden [
	<returnTypeC: #'SpurNewSpaceSpace *'>
	^self addressOf: eden
]

{ #category : #accessing }
SpurGenerationScavenger >> edenBytes [
	^eden limit - eden start
]

{ #category : #scavenger }
SpurGenerationScavenger >> exchangeSurvivorSpaces [
	| temp |
	temp := pastSpace.
	pastSpace := futureSpace.
	futureSpace := temp
]

{ #category : #accessing }
SpurGenerationScavenger >> futureSpace [
	<returnTypeC: #'SpurNewSpaceSpace *'>
	^self addressOf: futureSpace
]

{ #category : #accessing }
SpurGenerationScavenger >> futureSurvivorStart [
	^futureSurvivorStart
]

{ #category : #accessing }
SpurGenerationScavenger >> getRawTenuringThreshold [
	^tenuringThreshold
]

{ #category : #initialization }
SpurGenerationScavenger >> initFutureSpaceStart [
	| oldStart |
	oldStart := futureSurvivorStart.
	futureSurvivorStart := futureSpace start.
	^oldStart
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
	tenuringThreshold := 0.
	tenuringProportion := 0.9
]

{ #category : #'store check' }
SpurGenerationScavenger >> isInRememberedTable: objOop [
	0 to: rememberedSetSize - 1 do:
		[:i|
		(rememberedSet at: i) = objOop ifTrue:
			[^true]].
	^false
]

{ #category : #initialization }
SpurGenerationScavenger >> manager: aSpurMemoryManager newSpaceStart: startAddress newSpaceBytes: totalBytes edenBytes: requestedEdenBytes [ 
	| edenBytes survivorBytes |
	manager := aSpurMemoryManager.

	edenBytes := requestedEdenBytes.
	survivorBytes := totalBytes - edenBytes // 2 truncateTo: manager allocationUnit.
	edenBytes := totalBytes - survivorBytes - survivorBytes truncateTo: manager allocationUnit.
	self assert: totalBytes - edenBytes - survivorBytes - survivorBytes < manager allocationUnit.

	"for tenuring we require older objects below younger objects.  since allocation
	 grows up this means that the survivor spaces must preceed eden."
	pastSpace := SpurNewSpaceSpace new.
	futureSpace := SpurNewSpaceSpace new.
	eden := SpurNewSpaceSpace new.

	pastSpace start: startAddress limit: startAddress + survivorBytes.
	futureSpace start: pastSpace limit limit: pastSpace limit + survivorBytes.
	eden start: futureSpace limit limit: futureSpace limit + edenBytes.

	self assert: futureSpace limit <= (startAddress + totalBytes).
	self assert: eden start \\ manager allocationUnit
				+ (eden limit \\ manager allocationUnit) = 0.
	self assert: pastSpace start \\ manager allocationUnit
				+ (pastSpace limit \\ manager allocationUnit) = 0.
	self assert: futureSpace start \\ manager allocationUnit
				+ (futureSpace limit \\ manager allocationUnit) = 0.

	self initFutureSpaceStart.
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

{ #category : #accessing }
SpurGenerationScavenger >> rememberedSetSize [
	^rememberedSetSize
]

{ #category : #'debug support' }
SpurGenerationScavenger >> rememberedSetWithIndexDo: aBlock [
	0 to: rememberedSetSize - 1 do:
		[:i| aBlock value: (rememberedSet at: i) value: i]
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
	 detecting closure.  If this were not true, some pointers might get forwarded twice.

	 Answer the limit of pastSpace, to allow the memory manager to bounds check survivors."

	self scavengeLoop.
	self computeTenuringThreshold.
	self exchangeSurvivorSpaces.
	^self initFutureSpaceStart
]

{ #category : #scavenger }
SpurGenerationScavenger >> scavengeFutureSurvivorSpaceStartingAt: initialAddress [
	"scavengeFutureSurvivorSpaceStartingAt: does a depth-first traversal of the
	 new objects starting at the one at initialAddress in futureSurvivorSpace."
	| ptr obj |
	ptr := initialAddress.
	[ptr < futureSurvivorStart] whileTrue:
		[obj := manager objectStartingAt: ptr.
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

	| firstTime previousRememberedSetSize previousFutureSurvivorStart |
	self assert: futureSurvivorStart = futureSpace start. "future space should be empty at the start"
	firstTime := true.
	previousRememberedSetSize := 0.
	previousFutureSurvivorStart := futureSurvivorStart.
	[self scavengeRememberedSetStartingAt: previousRememberedSetSize.
	 previousRememberedSetSize := rememberedSetSize.
	 firstTime ifTrue:
		[coInterpreter mapInterpreterOops.
		 firstTime := false].
	 "nothing more copied and forwarded (or remembered by mapInterpreterOops)
	  to scavenge so scavenge is done."
	 (previousRememberedSetSize = rememberedSetSize
	  and: [previousFutureSurvivorStart = futureSurvivorStart]) ifTrue:
		[^self].

	 self scavengeFutureSurvivorSpaceStartingAt: previousFutureSurvivorStart.
	 "no more roots created to scavenge, so scavenge is done."
	 previousRememberedSetSize = rememberedSetSize ifTrue:
		[^self].

	 previousFutureSurvivorStart := futureSurvivorStart] repeat
]

{ #category : #scavenger }
SpurGenerationScavenger >> scavengeReferentsOf: referrer [
	"scavengeReferentsOf: referrer inspects all the pointers in referrer.
	 If any are new objects, it has them moved to FutureSurvivorSpace,
	 and answers truth. If there are no new referents, it answers falsity."
	| foundNewReferent |
	"forwarding objects should be followed by callers,
	 unless the forwarder is a root in the remembered table."
	self assert: ((manager isForwarded: referrer) not
				or: [manager isRemembered: referrer]).
	foundNewReferent := false.
	0 to: (manager numPointerSlotsOf: referrer) - 1 do:
		[:i| | referent newLocation |
		referent := manager fetchPointer: i ofMaybeForwardedObject: referrer.
		(manager isNonImmediate: referent) ifTrue:
			["a forwarding pointer could be because of become: or scavenging."
			 referent := (manager isForwarded: referent)
								ifTrue: [manager followForwarded: referent]
								ifFalse: [referent].
			 (manager isYoung: referent)
				ifTrue:
					["if target is already in future space forwarding pointer was due to a become:."
					 (manager isInFutureSpace: referent)
						ifTrue: [newLocation := referent]
						ifFalse:
							[(manager isForwarded: referent)
								ifTrue: [self halt. "can this even happen?"
									newLocation := manager followForwarded: referent]
								ifFalse: [newLocation := self copyAndForward: referent]].
					 (manager isYoung: newLocation) ifTrue:
						[foundNewReferent := true].
					 manager storePointerUnchecked: i ofMaybeForwardedObject: referrer withValue: newLocation]
				ifFalse:
					[manager storePointerUnchecked: i ofMaybeForwardedObject: referrer withValue: referent]]].
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
		"*Don't* follow forwarding pointers here. oldSpace objects may refer
		 to these roots, and so they can't be removed in the scavenge."
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

{ #category : #accessing }
SpurGenerationScavenger >> setRawTenuringThreshold: threshold [
	tenuringThreshold := threshold
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
