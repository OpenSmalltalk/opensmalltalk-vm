"
SpurGenerationScavenger is an implementation of David Ungar's Generation Scavenging garbage collection algorithm.  See
	Generation Scavenging, A Non-disruptive, High-Performance Storage Reclamation Algorithm
	David Ungar
	Proceeding
	SDE 1 Proceedings of the first ACM SIGSOFT/SIGPLAN software engineering symposium on Practical software development environments
	Pages 157 - 167 
	ACM New York, NY, USA ©1984 

Also relevant are
	An adaptive tenuring policy for generation scavengers
	David Ungar & Frank Jackson
	ACM Transactions on Programming Languages and Systems (TOPLAS) TOPLAS Homepage archive
	Volume 14 Issue 1, Jan. 1992 
	Pages 1 - 27 
	ACM New York, NY, USA ©1992
and
	Ephemerons: a new finalization mechanism
	Barry Hayes
	Proceedings of the 12th ACM SIGPLAN conference on Object-oriented programming, systems, languages, and applications
	Pages 176-183 
	ACM New York, NY, USA ©1997

See text below the variable definitions and explanation below for a full explanation of weak and ephemeron processing.

Instance Variables
	coInterpreter:					<StackInterpreterSimulator|CogVMSimulator>
	eden:							<SpurNewSpaceSpace>
	ephemeronList:					<Integer|nil>
	futureSpace:					<SpurNewSpaceSpace>
	futureSurvivorStart:				<Integer address>
	manager:						<SpurMemoryManager|Spur32BitMMLESimulator et al>
	numRememberedEphemerons:	<Integer>
	pastSpace:						<SpurNewSpaceSpace>
	previousRememberedSetSize:	<Integer>
	rememberedSet:				<CArrayAccessor on: Array>
	rememberedSetSize:			<Integer>
	tenuringProportion:				<Float>
	tenuringThreshold:				<Integer address>
	weakList:						<Integer|nil>

coInterpreter
	- the interpreter/vm, in this context, the mutator

manager
	- the Spur memory manager

eden
	- the space containing newly created objects

futureSpace
	- the space to which surviving objects are copied during a scavenge

futureSurvivorStart
	- the allocation pointer into futureSpace

pastSpace
	- the space surviving objects live in until the next scavenge

rememberedSet
	- the root old space objects that refer to objects in new space; a scavenge starts form these roots and the interpreter's stack

rememberedSetSize
	- the size of the remembered set, also the first unused index in the rememberedSet

previousRememberedSetSize:
	- the size of the remembered set before scavenging objects in future space.

numRememberedEphemerons
	- the number of unscavenged ephemerons at the front of the rememberedSet.

ephemeronList
	- the head of the list of corpses of unscavenged ephemerons reached in the current phase

weakList
	- the head of the list of corpses of weak arrays reached during the scavenge.

tenuringProportion
	- the amount of pastSpace below which the system will not tenure unless futureSpace fills up, and above which it will eagerly tenure

tenuringThreshold
	- the pointer into pastSpace below which objects will be tenured

Weakness and Ephemerality in the Scavenger.
Weak arrays should not hold onto their referents (except from their strong fileds, their named inst vars).  Ephemerons are objects that implement instance-based finalization; attaching an ephemeron to an object keeps that object alive and causes the ephemeron to ""fire"" when the object is only reachable from the ephemeron (or other ephemerons & weak arrays).  They are a special kind of Associations that detect when their keys are about to die, i.e. when an ephemeron's key is not reachable from the roots except from weak arrays and other ephemerons with about-to-die keys.  Note that if an ephemeron's key is not about to die then references from the rest of the ephemeron can indeed prevent ephemeron keys from dying.

The scavenger is concerned with collecting objects in new space, therefore it ony deals with weak arrays and ephemerons that are either in the remembered set or in new space.  By deferring scanning these objects until other reachable objects have been scavenged, the scavenger can detect dead or dying references.

Weak Array Processing
In the case of weak arrays this is simple.  The scavenger refuses to scavenge the referents of weak arrays in scavengeReferentsOf: until the entire scavenge is over.  It then scans the weak arrays in the remembered set and in future space and nils all fields in them that are referring to unforwarded objects in eden and past space, because these objects have not survived the scavenge.  The root weak arrays remaining to be scavenged are in the remembered table.  Surviving weak arrays in future space are collected on a list.  The list is threaded through the corpses of weak arrays in eden and/or past space.  weakList holds the slot offset of the first weak array found in eden and/or past space.  The next offset is stored in the weak array corpse's identityHash and format fields (22 bits & 5 bits of allocationUnits, for a max new space size of 2^28 bytes, 256Mb).  The list is threaded throguh corpses, but the surviving arrays are pointed to by the corpses' forwarding pointers.

Ephemeron Processing
The case of ephemerons is a little more complicated because an ephemeron's key should survive.  The scavenger is cyclical.  It scavenges the remembered set, which may copy and forward surviving objects in past and/or eden spaces to future space.  It then scavenges those promoted objects in future space until no more are promoted, which may in turn remember more objects.  The cycles continue until no more objects get promoted to future space and no more objects get remembered.  At this point all surviving objecta are in futureSpace.

So if the scavenger does not scan ephemerons in the remembered set or in future space until the scavenger finishes cycling, it can detect ephemerons whose keys are about to die because these will be unforwarded objects in eden and/or past space.  Ephemerons encountered in the remembered set are either processed like ordinary objects if their keys have been promoted to futureSpace, or are moved to the front of the rememberedSet (because, dear reader, it is a sequence) if their keys have not been promoted.  Ephemerons encountered in scavengeReferentsOf: are either scanned like normal objects if their keys have been promoted, or added to the ephemeronList, organized identically to the weakList, if their keys are yet to be promoted.  Since references from other ephemerons with surviving keys to ephemeron keys can and should prevent the ephemerons whose keys they are from firing the scavenger does not fire ephemerons unless all unscavenged ephemerons have unscavenged keys.  So the unscavenged ephemerons (the will be at the beginning of the remembered set and on the ephemeronList) are scanned and any that have promoted keys are scavenged.  But if no unscavenged ephemerons have surviving keys then all the unscavenged ephemerons are fired and then scavenged.  This in turn may remember more objects and promote more objects to future space, and encounter more unscavenged ephemerons.  So the scavenger continues until no more objects are remembered, no more objects are promoted to future space and no more unscavenged ephemerons exist.
"
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
		'previousRememberedSetSize',
		'weakList',
		'ephemeronList',
		'tenureCriterion',
		'tenureThreshold',
		'tenuringClassIndex',
		'tenuringProportion',
		'numRememberedEphemerons'
	],
	#classVars : [
		'RememberedSetLimit',
		'RememberedSetRedZone'
	],
	#pools : [
		'SpurMemoryManagementConstants'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #translation }
SpurGenerationScavenger class >> declareCVarsIn: aCCodeGenerator [
	#(eden futureSpace pastSpace) do:
		[:var| aCCodeGenerator var: var type: #SpurNewSpaceSpace].
	aCCodeGenerator
		var: #rememberedSet
		declareC: 'sqInt rememberedSet[RememberedSetLimit + 1 /* ', (RememberedSetLimit + 1) printString, ' */]'
]

{ #category : #'class initialization' }
SpurGenerationScavenger class >> initialize [
	"SpurGenerationScavenger initialize"
	RememberedSetLimit := 16384.
	RememberedSetRedZone := RememberedSetLimit - (RememberedSetLimit // 2).

	TenureByAge := 1.
	TenureByClass := 2
]

{ #category : #translation }
SpurGenerationScavenger class >> isNonArgumentImplicitReceiverVariableName: instVarName [
	^#('self' 'coInterpreter' 'manager') includes: instVarName
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> addToEphemeronList: ephemeronCorpse [
	"ephemeronCorpse is the corpse of an ephemeron that was copied and forwarded.
	 Later on its surviving copy must be scanned to nil weak references.
	 Thread the corpse onto the weakList.  Later, the weakList can be followed, and
	 the forwarding pointer followed to locate the survivor."
	<inline: false>
	| ephemeronListOffset |
	self assert: (manager isYoung: ephemeronCorpse).
	self assert: (manager isForwarded: ephemeronCorpse).
	self assert: (self isScavengeSurvivor: (manager keyOfEphemeron: (manager followForwarded: ephemeronCorpse))) not.

	ephemeronListOffset := ephemeronList ifNil: 0.
	self setCorpseOffsetOf: ephemeronCorpse to: ephemeronListOffset.
	ephemeronList := self corpseOffsetOf: ephemeronCorpse.
	self assert: (self firstCorpse: ephemeronList) = ephemeronCorpse
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> addToWeakList: weakCorpse [
	"weakCorpse is the corpse of a weak array that was copied and forwarded.
	 Later on its surviving copy must be scanned to nil weak references.
	 Thread the corpse onto the weakList.  Later, the weakList can be followed, and
	 the forwarding pointer followed to locate the survivor."
	<inline: false>
	| weakListOffset |
	self assert: (manager isYoung: weakCorpse).
	self assert: (manager isForwarded: weakCorpse).

	weakListOffset := weakList ifNil: 0.
	self setCorpseOffsetOf: weakCorpse to: weakListOffset.
	weakList := self corpseOffsetOf: weakCorpse.
	self assert: (self firstCorpse: weakList) = weakCorpse
]

{ #category : #accessing }
SpurGenerationScavenger >> coInterpreter: aCoInterpreter [
	coInterpreter := aCoInterpreter
]

{ #category : #scavenger }
SpurGenerationScavenger >> computeTenuringThreshold [
	| fractionSurvived |
	<var: 'fractionSurvived' type: #float>
	fractionSurvived := futureSpace limit = futureSpace start
							ifTrue:
								[0.0]
							ifFalse:
								[(futureSurvivorStart - futureSpace start) asFloat
									/ (futureSpace limit - futureSpace start)].
	tenureThreshold := fractionSurvived > 0.9
							ifTrue: [((pastSpace limit - pastSpace start) * (1.0 - tenuringProportion)) rounded + pastSpace start]
							ifFalse: [0]
]

{ #category : #scavenger }
SpurGenerationScavenger >> copyAndForward: survivor [
	"copyAndForward: survivor copies a survivor object either to
	 futureSurvivorSpace or, if it is to be promoted, to oldSpace.
	 It leaves a forwarding pointer behind.  If the object is weak
	 then corpse is threaded onto the weakList for later treatment."
	<inline: false>
	| bytesInObj newLocation hash |
	self assert: survivor >= manager startOfMemory. "cog methods should be excluded."
	bytesInObj := manager bytesInObject: survivor.
	"Must remember hash before copying because threading
	 on to the weak & ephemeron lists smashes the hash field."
	hash := manager rawHashBitsOf: survivor.
	((self shouldBeTenured: survivor)
	 or: [futureSurvivorStart + bytesInObj > futureSpace limit])
		ifTrue:
			[newLocation := self copyToOldSpace: survivor.
			 manager forwardSurvivor: survivor to: newLocation]
		ifFalse:
			[newLocation := self copyToFutureSpace: survivor bytes: bytesInObj.
			 manager forwardSurvivor: survivor to: newLocation.
			 "if weak or ephemeron add to the relevant lists if newLocation is young.  If
			  old, newLocation will be remembered and dealt with in the rememberedSet."
			 (manager isWeakNonImm: newLocation) ifTrue:
				[self addToWeakList: survivor].
			 ((manager isEphemeron: newLocation)
			  and: [(self isScavengeSurvivor: (manager keyOfEphemeron: newLocation)) not]) ifTrue:
				[self addToEphemeronList: survivor]].
	hash ~= 0 ifTrue:
		[manager setHashBitsOf: newLocation to: hash].
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

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> corpseForCorpseOffset: corpseOffset [
	"Use the identityHash and format fields to construct a 27 bit offset through
	 non-future newSpace and use this to implement lists for weak array and
	 ephemeron processing.  27 bits of 8 byte allocationUnits units is 2 ^ 30 bytes
	 or 1Gb, big enough for newSpace for a good few years yet."
	^corpseOffset << manager shiftForAllocationUnit + manager startOfMemory
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> corpseOffsetOf: corpse [
	"Answer the offset of the corpse in newSpace as a multiple of allocationUnits.
	 Use the identityHash and format fields to construct a 27 bit offset through
	 non-future newSpace and use this to implement lists for weak array and
	 ephemeron processing.  27 bits of 8 byte allocationUnits units is 2 ^ 30
	 bytes or 1Gb, big enough for newSpace for a good few years yet."
	^corpse - manager startOfMemory >> manager shiftForAllocationUnit.
]

{ #category : #accessing }
SpurGenerationScavenger >> eden [
	<returnTypeC: #SpurNewSpaceSpace>
	<cmacro: '() GIV(eden)'>
	^eden
]

{ #category : #accessing }
SpurGenerationScavenger >> edenBytes [
	^eden limit - eden start
]

{ #category : #scavenger }
SpurGenerationScavenger >> exchangeSurvivorSpaces [
	| temp |
	<var: #temp type: #SpurNewSpaceSpace>
	temp := pastSpace.
	pastSpace := futureSpace.
	futureSpace := temp
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> fireEphemeronsInRememberedSet [
	"There are ephemerons to be fired in the remembered set.
	 Fire them and scavenge their keys.  Leave it to scavengeLoop
	 to remove any scavenged ephemerons that no longer have
	 new referents."
	| i |
	self assert: self noUnfiredEphemeronsAtEndOfRememberedSet.

	i := 0.
	[i < numRememberedEphemerons] whileTrue:
		[ | ephemeron |
		 ephemeron := rememberedSet at: i.
		 self assert: (manager isEphemeron: ephemeron).
		 self assert: (self isScavengeSurvivor: (manager keyOfEphemeron: ephemeron)) not.
		 coInterpreter fireEphemeron: ephemeron.
		 self copyAndForward: (manager keyOfEphemeron: ephemeron).
		 (self scavengeReferentsOf: ephemeron)
			ifTrue: "keep in set"
				[i := i + 1]
			ifFalse:
				[manager setIsRememberedOf: ephemeron to: false.
				"remove from set by overwriting with next-to-be scanned"
				 numRememberedEphemerons := numRememberedEphemerons - 1.
				 previousRememberedSetSize := previousRememberedSetSize - 1.
				 rememberedSetSize := rememberedSetSize - 1.
				 "First overwrite with last firable ephemeron (could be a noop if this is the last one).
				  Then overwrite last firable entry with next unscanned rememberedSet entry (could also be a noop).
				  Then overwrite next unscanned entry with last unscanned rememberedSet entry (could also be a noop)."
				 rememberedSet
					at: i
						put: (rememberedSet at: numRememberedEphemerons);
					at: numRememberedEphemerons
						put: (rememberedSet at: previousRememberedSetSize);
					at: previousRememberedSetSize
						put: (rememberedSet at: rememberedSetSize)]].

	"no more firable ephemerons in this cycle.
	 scavengeRememberedSetStartingAt: may find new ones."
	numRememberedEphemerons := 0
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> fireEphemeronsOnEphemeronList [
	"There are ephemerons to be fired in the remembered set.
	 Fire them and scavenge their keys.  Be careful since copyAndForward:
	 can remember ephemerons (ephemerons pointing to ephemerons)."
	| ephemeron ephemeronCorpse |
	ephemeronList ifNil:
		[^self].
	ephemeronCorpse := self firstCorpse: ephemeronList.
	"Reset the list head so that new ephemerons will get added
	 to a new list, not concatenated on the one we are scanning."
	ephemeronList := nil.
	[ephemeronCorpse notNil] whileTrue:
		[self assert: (manager isForwarded: ephemeronCorpse).
		 ephemeron := manager followForwarded: ephemeronCorpse.
		 self assert: (self isScavengeSurvivor: (manager keyOfEphemeron: ephemeron)) not.
		 coInterpreter fireEphemeron: ephemeron.
		 self copyAndForward: (manager keyOfEphemeron: ephemeron).
		 self cCoerceSimple: (self scavengeReferentsOf: ephemeron) to: #void.
		 ephemeronCorpse := self nextCorpseOrNil: ephemeronCorpse]
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> firstCorpse: headOfCorpseList [
	^self corpseForCorpseOffset: headOfCorpseList
]

{ #category : #accessing }
SpurGenerationScavenger >> futureSpace [
	<returnTypeC: #SpurNewSpaceSpace>
	<cmacro: '() GIV(futureSpace)'>
	^futureSpace
]

{ #category : #'debug support' }
SpurGenerationScavenger >> futureSpaceObjectsDo: aBlock [
	| obj |
	futureSurvivorStart > futureSpace start ifTrue:
		[obj := manager objectStartingAt: futureSpace start.
		 [obj < futureSurvivorStart] whileTrue:
			[aBlock value: obj.
			 obj := manager objectAfter: obj limit: futureSurvivorStart]]
]

{ #category : #accessing }
SpurGenerationScavenger >> futureSurvivorStart [
	^futureSurvivorStart
]

{ #category : #accessing }
SpurGenerationScavenger >> getRawTenuringThreshold [
	^tenureThreshold
]

{ #category : #initialization }
SpurGenerationScavenger >> initFutureSpaceStart [
	| oldStart |
	oldStart := futureSurvivorStart.
	futureSurvivorStart := futureSpace start.
	^oldStart
]

{ #category : #initialization }
SpurGenerationScavenger >> initialize [
	pastSpace := SpurNewSpaceSpace new.
	futureSpace := SpurNewSpaceSpace new.
	eden := SpurNewSpaceSpace new.
	rememberedSet := CArrayAccessor on: (Array new: RememberedSetLimit).
	rememberedSetSize := 0.
	tenureThreshold := 0.
	tenuringProportion := 0.9
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> is: oop onWeaklingList: listHead [
	| corpse |
	corpse := self firstCorpse: listHead.
	[corpse notNil] whileTrue:
		[oop = (manager followForwarded: corpse) ifTrue:
			[^true].
		 corpse := self nextCorpseOrNil: corpse].
	^false
]

{ #category : #'store check' }
SpurGenerationScavenger >> isInRememberedSet: objOop [
	0 to: rememberedSetSize - 1 do:
		[:i|
		(rememberedSet at: i) = objOop ifTrue:
			[^true]].
	^false
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> isScavengeSurvivor: oop [
	"Answer whether the oop has survived a scavenge.  This is equivalent to
		| target |
		(manager isImmediate: oop) ifTrue:
			[^true].
		target := (manager isForwarded: oop)
					ifTrue: [manager followForwarded: oop]
					ifFalse: [oop].
	 	^((manager isInEden: target)
		  or: [(manager isInPastSpace: target)]) not"
	| target |
	(manager isImmediate: oop) ifTrue:
		[^true].
	(manager isForwarded: oop)
		ifTrue: [target := manager followForwarded: oop]
		ifFalse: [target := oop].
	^(manager isYoung: target) not
	  or: [manager isInFutureSpace: target]
]

{ #category : #initialization }
SpurGenerationScavenger >> manager: aSpurMemoryManager newSpaceStart: startAddress newSpaceBytes: totalBytes edenBytes: requestedEdenBytes [ 	self manager: aSpurMemoryManager.
	self newSpaceStart: startAddress newSpaceBytes: totalBytes edenBytes: requestedEdenBytes
]

{ #category : #accessing }
SpurGenerationScavenger >> newSpaceCapacity [
	^eden limit - (futureSpace start min: pastSpace start)
]

{ #category : #initialization }
SpurGenerationScavenger >> newSpaceStart: startAddress newSpaceBytes: totalBytes edenBytes: requestedEdenBytes [ 
	| edenBytes survivorBytes |

	edenBytes := requestedEdenBytes.
	survivorBytes := totalBytes - edenBytes // 2 truncateTo: manager allocationUnit.
	edenBytes := totalBytes - survivorBytes - survivorBytes truncateTo: manager allocationUnit.
	self assert: totalBytes - edenBytes - survivorBytes - survivorBytes < manager allocationUnit.

	"for tenuring we require older objects below younger objects.  since allocation
	 grows up this means that the survivor spaces must preceed eden."

	pastSpace start: startAddress; limit: startAddress + survivorBytes.
	futureSpace start: pastSpace limit; limit: pastSpace limit + survivorBytes.
	eden start: futureSpace limit; limit: futureSpace limit + edenBytes.

	self assert: futureSpace limit <= (startAddress + totalBytes).
	self assert: eden start \\ manager allocationUnit
				+ (eden limit \\ manager allocationUnit) = 0.
	self assert: pastSpace start \\ manager allocationUnit
				+ (pastSpace limit \\ manager allocationUnit) = 0.
	self assert: futureSpace start \\ manager allocationUnit
				+ (futureSpace limit \\ manager allocationUnit) = 0.

	self initFutureSpaceStart.
	manager initSpaceForAllocationCheck: (self addressOf: eden)
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> nextCorpseOffset: corpse [
	"Answer the offset of the next corpse to corpse, which is zero if none.
	 Use the identityHash and format fields to construct a 27 bit offset through
	 non-future newSpace and use this to implement lists for weak array and
	 ephemeron processing.  27 bits of 8 byte allocationUnits units is 2 ^ 30 bytes
	 or 1Gb, big enough for newSpace for a good few years yet."
	^(manager rawHashBitsOf: corpse) << manager formatFieldWidthShift
	 + (manager formatOf: corpse)
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> nextCorpseOrNil: corpse [
	"corpse is the corpse of a weak array that has been added to the weakList.
	 Answer the next object on the list, or nil if none."
	| listOffset |
	self assert: (manager isYoung: corpse).
	listOffset := self nextCorpseOffset: corpse.
	^listOffset ~= 0 ifTrue:
		[self corpseForCorpseOffset: listOffset]
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> noUnfiredEphemeronsAtEndOfRememberedSet [
	"For assert checking only."
	numRememberedEphemerons to: rememberedSetSize - 1 do:
		[:i| | referrer |
		referrer := rememberedSet at: i.
		(manager isEphemeron: referrer) ifTrue:
			[(self isScavengeSurvivor: (manager keyOfEphemeron: referrer)) ifFalse:
				[^false]]].
	^true
]

{ #category : #accessing }
SpurGenerationScavenger >> pastSpace [
	<returnTypeC: #SpurNewSpaceSpace>
	<cmacro: '() GIV(pastSpace)'>
	^pastSpace
]

{ #category : #accessing }
SpurGenerationScavenger >> pastSpaceBytes [
	^pastSpace limit - pastSpace start
]

{ #category : #'debug support' }
SpurGenerationScavenger >> printWeaklingList: listHead [
	"Print the objects on either the weakList or the ephemeronList."
	| corpse |
	corpse := self firstCorpse: listHead.
	corpse ifNil:
		[coInterpreter print: 'empty'; cr.
		 ^self].
	[corpse notNil] whileTrue:
		[coInterpreter printHexnp: corpse; print: ' -> '; shortPrintOop: (manager followForwarded: corpse).
		 corpse := self nextCorpseOrNil: corpse]
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> processEphemerons [
	"There are ephemerons to be scavenged.  Scavenge them and fire any whose keys are
	 still in pastSpace and/or eden.  The unscavenged ephemerons in this cycle can only be
	 fired if all the unscavenged ephemerons in this cycle are firable, because references
	 to ephemeron keys from unfired ephemerons should prevent the ephemerons with
	 those keys from firing.  So scavenge ephemerons with surviving keys, and only if none
	 are found, fire ephemerons with unreferenced keys, and scavenge them.   Read the
	 class comment for a more in-depth description of the algorithm."
	| unfiredEphemeronsScavenged |
	unfiredEphemeronsScavenged := self scavengeUnfiredEphemeronsInRememberedSet.
	self scavengeUnfiredEphemeronsOnEphemeronList ifTrue:
		[unfiredEphemeronsScavenged := true].
	unfiredEphemeronsScavenged ifFalse:
		[self fireEphemeronsInRememberedSet.
		 self fireEphemeronsOnEphemeronList]
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> processWeakSurvivor: weakObj [
	"Process a weak survivor on the weakList.  Those of its fields
	 which have not survived the scavenge should be nilled, and if any
	 are, the coInterpreter should be informed via signalFinalization:."
	| weakObjShouldMourn |
	weakObjShouldMourn := false.
	(manager numFixedSlotsOf: weakObj)
		to: (manager numSlotsOf: weakObj) - 1
		do: [:i| | referent |
			referent := manager fetchPointer: i ofObject: weakObj.
			"Referent could be forwarded due to scavenging or a become:, don't assume."
			((manager isNonImmediate: referent)
			and: [manager isForwarded: referent]) ifTrue:
				[referent := manager followForwarded: referent.
				 (self isScavengeSurvivor: referent) ifTrue:
					[manager storePointer: i ofObject: weakObj withValue: referent]].
			(self isScavengeSurvivor: referent)
				ifFalse:
					[weakObjShouldMourn := true.
					 manager
						storePointerUnchecked: i
						ofObject: weakObj
						withValue: manager nilObject]
				ifTrue:
					[self assert: referent = (manager fetchPointer: i ofObject: weakObj)]].
	weakObjShouldMourn ifTrue:
		[coInterpreter signalFinalization: weakObj]
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> processWeaklings [
	"Go through the remembered set and the weak list, nilling references to
	 any objects that didn't survive the scavenge. Read the class comment
	 for a more in-depth description of the algorithm."
	| i rootObj weakCorpse weakObj |
	i := 0.
	[i < rememberedSetSize] whileTrue:
		[rootObj := rememberedSet at: i.
		(manager isWeakNonImm: rootObj)
			ifTrue:
				[self processWeakSurvivor: rootObj.
				 "If no more referents, remove by overwriting with the last element in the set."
				 (manager hasYoungReferents: rootObj)
					ifFalse:
						[manager setIsRememberedOf: rootObj to: false.
						 i + 1 < rememberedSetSize ifTrue:
							[rememberedSet at: i put: (rememberedSet at: rememberedSetSize - 1)].
						 rememberedSetSize := rememberedSetSize - 1]
					ifTrue: [i := i + 1]]
			ifFalse: [i := i + 1]].
	weakList ifNotNil:
		[weakCorpse := self firstCorpse: weakList.
		 [weakCorpse notNil] whileTrue:
			[self assert: (manager isForwarded: weakCorpse).
			 weakObj := manager followForwarded: weakCorpse.
			 self processWeakSurvivor: weakObj.
			 weakCorpse := self nextCorpseOrNil: weakCorpse].
		weakList := nil]
]

{ #category : #'store check' }
SpurGenerationScavenger >> remember: objOop [
	self assert: ((manager isNonImmediate: objOop)
				and: [(manager isYoung: objOop) not]).
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
	<cmacro: '() GIV(rememberedSetSize)'>
	^rememberedSetSize
]

{ #category : #'debug support' }
SpurGenerationScavenger >> rememberedSetWithIndexDo: aBlock [
	0 to: rememberedSetSize - 1 do:
		[:i| aBlock value: (rememberedSet at: i) value: i]
]

{ #category : #scavenger }
SpurGenerationScavenger >> scavenge: tenuringCriterion [
	"The main routine, scavenge, scavenges young objects reachable from the roots (the stack zone
	 and the rememberedTable).  It first scavenges the new objects immediately reachable from old
	 ones (all in the remembered table), then the stack zone.  Then it scavenges those that are
	 transitively reachable.  If this results in a promotion, the promotee gets remembered, and it first
	 scavenges objects adjacent to the promotee, then scavenges the ones reachable from the
	 promoted.  This loop continues until no more reachable objects are left.  At that point,
	 pastSurvivorSpace is exchanged with futureSurvivorSpace.  Then any surviving weakArrays and
	 weakArrays in the remembered set can be processed and their dead elements nilled.

	 By default promotion (tenuring) is based on age and ammount of objects scavenged.  But
	 tenuring can be based on e.g. a particular class.  The argument selects the tenuring criterion.

	 Answer the limit of pastSpace, to allow the memory manager to bounds check survivors."
	tenureCriterion := tenuringCriterion.
	self scavengeLoop.
	self processWeaklings.
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
	 detecting closure.  If this were not true, some pointers might get forwarded twice.

	 An extension of the algorithm presented in David's original paper is to handle weak arrays and ephemerons.
	 Weak arrays should not have their weak referents scavenged unless there are strong references to them.
	 Ephemerons should fire if their key is not reachable other than from ephemerons and weak arrays.
	 Handle this by maintaining a list for weak arrays and a list for ephemerons, which allow scavenging these
	 objects once all other objects in new space have been scavenged, hence allowing the scavenger to
	 detect which referents in new space of weak arrays are dead and of ephemeron keys are only live due to
	 ephemerons.  Read the class comment for a more in-depth description of the algorithm."

	| previousFutureSurvivorStart firstTime |
	self assert: futureSurvivorStart = futureSpace start. "future space should be empty at the start"

	weakList := ephemeronList := nil.
	numRememberedEphemerons := 0.
	firstTime := true.
	previousRememberedSetSize := 0.
	previousFutureSurvivorStart := futureSurvivorStart.

	[self scavengeRememberedSetStartingAt: previousRememberedSetSize.
	 previousRememberedSetSize := rememberedSetSize.
	 firstTime ifTrue:
		[coInterpreter mapInterpreterOops.
		 manager mapExtraRoots.
		 firstTime := false].
	 "if nothing more copied and forwarded (or remembered by mapInterpreterOops)
	  to scavenge, and no ephemerons to process, scavenge is done."
	 (previousRememberedSetSize = rememberedSetSize
	  and: [previousFutureSurvivorStart = futureSurvivorStart
	  and: [numRememberedEphemerons = 0
	  and: [ephemeronList isNil]]]) ifTrue:
		[^self].

	 self scavengeFutureSurvivorSpaceStartingAt: previousFutureSurvivorStart.
	 previousFutureSurvivorStart := futureSurvivorStart.

	 "no more roots created to scavenge..."
	 previousRememberedSetSize = rememberedSetSize ifTrue:
		[(numRememberedEphemerons = 0
		  and: [ephemeronList isNil]) ifTrue:
			[^self]. "no ephemerons to process, scavenge is done."

		 "all reachable objects in this cycle have been promoted to futureSpace.
		  ephemerons can now be processed."
		 self processEphemerons]] repeat
]

{ #category : #scavenger }
SpurGenerationScavenger >> scavengeReferentsOf: referrer [
	"scavengeReferentsOf: referrer inspects all the pointers in referrer.  If
	 any are new objects, it has them moved to FutureSurvivorSpace, and
	 answers truth. If there are no new referents, it answers falsity. To handle
	 weak arrays, if the referrer is weak only scavenge strong slots and answer
	 true so that it won't be removed from the remembered set until later."
	| foundNewReferent |
	"forwarding objects should be followed by callers,
	 unless the forwarder is a root in the remembered table."
	self assert: ((manager isForwarded: referrer) not
				or: [manager isRemembered: referrer]).
	"unscanned ephemerons should be scanned later."
	self assert: ((manager isEphemeron: referrer) not
				or: [(self isScavengeSurvivor: (manager keyOfEphemeron: referrer))
				or: [self is: referrer onWeaklingList: ephemeronList]]).
	foundNewReferent := false.
	0 to: (manager numStrongSlotsOf: referrer ephemeronInactiveIf: #isScavengeSurvivor:) - 1
	   do: [:i| | referent newLocation |
		referent := manager fetchPointer: i ofMaybeForwardedObject: referrer.
		(manager isNonImmediate: referent) ifTrue:
			["a forwarding pointer could be because of become: or scavenging."
			 (manager isForwarded: referent) ifTrue:
				[referent := manager followForwarded: referent].
			 ((manager isNonImmediate: referent)
			  and: [manager isYoung: referent])
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
	^foundNewReferent or: [manager isWeakNonImm: referrer]
]

{ #category : #scavenger }
SpurGenerationScavenger >> scavengeRememberedSetStartingAt: n [
	"scavengeRememberedSetStartingAt: n traverses objects in the remembered
	 set starting at the nth one.  If the object does not refer to any new objects, it
	 is removed from the set.  Otherwise, its new referents are scavenged.  Defer
	 scavenging ephemerons until after a complete scavenge has been performed,
	 so that triggered ephemerons can be fired.  Move them to the front of the set
	 and count them in numRememberedEphemerons for later scanning."
	| destIndex sourceIndex referrer |
	sourceIndex := destIndex := n.
	[sourceIndex < rememberedSetSize] whileTrue:
		["*Don't* follow forwarding pointers here. oldSpace objects may refer
		  to these roots, and so they can't be removed in the scavenge."
		referrer := rememberedSet at: sourceIndex.
		"Any potential firing ephemerons should not be scanned yet.
		 Move any to the front of the set to save time in later scanning."
		((manager isEphemeron: referrer)
		 and: [(self isScavengeSurvivor: ((manager keyOfEphemeron: referrer))) not])
			ifTrue:
				[self assert: destIndex >= numRememberedEphemerons.
				 rememberedSet
					at: destIndex put: (rememberedSet at: numRememberedEphemerons);
					at: numRememberedEphemerons put: referrer.
				 numRememberedEphemerons := numRememberedEphemerons + 1.
				 destIndex := destIndex + 1]
			ifFalse:
				[(self scavengeReferentsOf: referrer)
					ifTrue:
						[rememberedSet at: destIndex put: referrer.
						 destIndex := destIndex + 1]
					ifFalse:
						[manager setIsRememberedOf: referrer to: false]].
		 sourceIndex := sourceIndex + 1].
	rememberedSetSize := destIndex.
	self assert: self noUnfiredEphemeronsAtEndOfRememberedSet
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> scavengeUnfiredEphemeronsInRememberedSet [
	"There are ephemerons to be scavenged in the remembered set.
	 Scavenge any with unfired (live) keys, removing them from the
	 unscavenged ephemerons, and from the set if they no longer refer
	 to new objects, and answer if any with unfired keys were found."
	| unfiredEphemeronsScavenged i referrer hasNewReferents |
	unfiredEphemeronsScavenged := false.
	i := 0.
	[i < numRememberedEphemerons] whileTrue:
		[referrer := rememberedSet at: i.
		 self assert: (manager isEphemeron: referrer).
		 (self isScavengeSurvivor: (manager keyOfEphemeron: referrer))
			ifTrue:
				[unfiredEphemeronsScavenged := true.
				 hasNewReferents := self scavengeReferentsOf: referrer.
				 "remove from unscanned ephemerons in set by swapping with last ephemeron"
				 numRememberedEphemerons := numRememberedEphemerons - 1.
				 rememberedSet
					at: i
					put: (rememberedSet at: numRememberedEphemerons).
				 hasNewReferents
					ifTrue: "keep in set"
						[rememberedSet
							at: numRememberedEphemerons
							put: referrer]
					ifFalse: "remove from set by overwriting with next-to-be scanned"
						[previousRememberedSetSize := previousRememberedSetSize - 1.
						 rememberedSetSize := rememberedSetSize - 1.
						 rememberedSet
							at: numRememberedEphemerons
								put: (rememberedSet at: previousRememberedSetSize);
							at: previousRememberedSetSize
								put: (rememberedSet at: rememberedSetSize).
						 manager setIsRememberedOf: referrer to: false]]
				ifFalse:
					[i := i + 1]].
	^unfiredEphemeronsScavenged
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> scavengeUnfiredEphemeronsOnEphemeronList [
	"There may be ephemerons to be scavenged on the ephemeronList.
	 Scavenge any with unfired (live) keys, removing them from the
	 list, and answer if any with unfired keys were found."
	| unfiredEphemeronsScavenged corpseOffset previousCorpse |
	ephemeronList ifNil:
		[^false].
	unfiredEphemeronsScavenged := false.
	corpseOffset := ephemeronList.
	[corpseOffset ~= 0] whileTrue:
		[| ephemeronCorpse ephemeron nextCorpseOffset  |
		 ephemeronCorpse := self corpseForCorpseOffset: corpseOffset.
		 self assert: (manager isForwarded: ephemeronCorpse).
		 ephemeron := manager followForwarded: ephemeronCorpse.
		 nextCorpseOffset := self nextCorpseOffset: ephemeronCorpse.
		 (self isScavengeSurvivor: (manager keyOfEphemeron: ephemeron))
			ifTrue:
				[corpseOffset = ephemeronList
					ifTrue: [ephemeronList := nextCorpseOffset ~= 0 ifTrue: [nextCorpseOffset]]
					ifFalse: [self setCorpseOffsetOf: previousCorpse to: nextCorpseOffset].
				 unfiredEphemeronsScavenged := true.
				 self cCoerceSimple: (self scavengeReferentsOf: ephemeron) to: #void]
			ifFalse:
				[previousCorpse := ephemeronCorpse].
		 corpseOffset := nextCorpseOffset].
	^unfiredEphemeronsScavenged
]

{ #category : #accessing }
SpurGenerationScavenger >> scavengerTenuringThreshold [ "(Slang flattens so need unique selectors)"
	<returnTypeC: #float>
	^tenureThreshold >= pastSpace start
		ifTrue: [(tenureThreshold - pastSpace start) asFloat / (pastSpace limit - pastSpace start)]
		ifFalse: [0]
]

{ #category : #accessing }
SpurGenerationScavenger >> scavengerTenuringThreshold: aProportion [ "(Slang flattens so need unique selectors)"
	<var: 'aProportion' type: #float>
	tenuringProportion := aProportion.
	tenureThreshold := aProportion = 0.0
							ifTrue: [0]
							ifFalse: [((pastSpace limit - pastSpace start) * (1.0 - aProportion)) rounded + pastSpace start]
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> setCorpseOffsetOf: corpse to: offset [
	"Set the offset of the corpse's next corpse to offset.  Use the identityHash
	 and format fields to construct a 27 bit offset through non-future newSpace
	 and use this to implement the list.  27 bits of 8 byte allocationUnits units is
	 2 ^ 30 bytes or 1Gb, big enough for newSpace for a good few years yet."
	manager
		setHashBitsOf: corpse
			to: offset >> manager formatFieldWidthShift;
		setFormatOf: corpse
			to: (offset bitAnd: manager formatMask)
]

{ #category : #accessing }
SpurGenerationScavenger >> setRawTenuringThreshold: threshold [
	tenureThreshold := threshold
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

	^tenureCriterion
		caseOf: {
			[TenureByAge]	->
				[survivor < tenureThreshold]. 
			[TenureByClass] ->
				[(manager classIndexOf: survivor) = tenuringClassIndex] }
		otherwise: [false]
]

{ #category : #accessing }
SpurGenerationScavenger >> tenuringClassIndex [
	^tenuringClassIndex
]

{ #category : #accessing }
SpurGenerationScavenger >> tenuringClassIndex: anInteger [
	tenuringClassIndex := anInteger
]
