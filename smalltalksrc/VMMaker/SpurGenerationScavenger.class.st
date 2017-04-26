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
		'rememberedSetRedZone',
		'rememberedSetLimit',
		'refCountToShrinkRT',
		'weakList',
		'ephemeronList',
		'tenureCriterion',
		'tenureThreshold',
		'tenuringClassIndex',
		'tenuringProportion',
		'numRememberedEphemerons',
		'statSurvivorCount',
		'statTenures'
	],
	#pools : [
		'SpurMemoryManagementConstants'
	],
	#category : 'VMMaker-SpurMemoryManager'
}

{ #category : #translation }
SpurGenerationScavenger class >> declareCVarsIn: aCCodeGenerator [
	#(eden futureSpace pastSpace) do:
		[:var| aCCodeGenerator var: var type: #SpurNewSpaceSpace].
	aCCodeGenerator var: #rememberedSet type: #'sqInt *'.
	aCCodeGenerator var: #tenuringProportion type: #double
]

{ #category : #translation }
SpurGenerationScavenger class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #'class initialization' }
SpurGenerationScavenger class >> initialize [
	"SpurGenerationScavenger initialize"
	TenureByAge := 1.
	TenureByClass := 2.
	TenureToShrinkRT := 3.
	DontTenure := 4.
	MarkOnTenure := 5.
	MaxRTRefCount := 7 "The field comprised of {isGrey,isPinned,isRemembered}"
]

{ #category : #translation }
SpurGenerationScavenger class >> isNonArgumentImplicitReceiverVariableName: instVarName [
	^#('self' 'coInterpreter' 'manager') includes: instVarName
]

{ #category : #simulation }
SpurGenerationScavenger class >> simulatorClass [
	^SpurGenerationScavengerSimulator
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> addToEphemeronList: ephemeronCorpse [
	"ephemeronCorpse is the corpse of an ephemeron that was copied and forwarded.
	 Later on its surviving copy must be scanned to nil weak references.
	 Thread the corpse onto the weakList.  Later, the weakList can be followed, and
	 the forwarding pointer followed to locate the survivor."
	<inline: #never> "Should be too infrequent to lower icache density of copyAndForward:"
	| ephemeronListOffset |
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
	<inline: #never> "Should be too infrequent to lower icache density of copyAndForward:"
	| weakListOffset |

	weakListOffset := weakList ifNil: 0.
	self setCorpseOffsetOf: weakCorpse to: weakListOffset.
	weakList := self corpseOffsetOf: weakCorpse.
	self assert: (self firstCorpse: weakList) = weakCorpse
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> allFutureSpaceEntitiesDo: aBlock [
	"Enumerate all future space objects, including free objects."
	<inline: true>
	| prevObj prevPrevObj objOop limit |
	prevPrevObj := prevObj := nil.
	objOop := manager objectStartingAt: futureSpace start.
	limit := futureSurvivorStart.
	[self oop: objOop isLessThan: limit] whileTrue:
		[aBlock value: objOop.
		 prevPrevObj := prevObj.
		 prevObj := objOop.
		 objOop := manager objectAfter: objOop limit: limit]
]

{ #category : #'remembered set' }
SpurGenerationScavenger >> allNewSpaceObjectsHaveZeroRTRefCount [
	manager allNewSpaceObjectsDo:
		[:obj|
		(manager rtRefCountOf: obj) > 0 ifTrue:
			[^false]].
	^true
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> allWeakSurvivorsOnWeakList [
	self allFutureSpaceEntitiesDo:
		[:survivor|
		(manager isWeakNonImm: survivor) ifTrue:
			[(self is: survivor onWeaklingList: weakList) ifFalse:
				[^false]]].
	^true
]

{ #category : #accessing }
SpurGenerationScavenger >> coInterpreter: aCoInterpreter [
	coInterpreter := aCoInterpreter
]

{ #category : #'remembered set' }
SpurGenerationScavenger >> computeRefCountToShrinkRT [
	"Some time in every scavenger's life there may come a time when someone writes code that stresses
	 the remembered table.  One might conclude that if the remembered table is full, then the right thing
	 to do is simply to tenure everything, emptying the remembered table.  Bt in some circumstances this
	 can be counter-productive, and result in the same situation arising soon after tenuring everything.
	 Instead, we can try and selectively prune the remembered table, tenuring only those objects that
	 are referenced by many objects in the remembered table.  That's what this algorithm does.  It
	 reference counts young objects referenced from the remembered set, and then sets a threshold
	 used to tenure objects oft referenced from the remembered set, thereby allowing  the remembered
	 set to shrink, while not tenuring everything.

	 Once in a network monitoring application in a galaxy not dissimilar from the one this code inhabits,
	 a tree of nodes referring to large integers was in precisely this situation.  The nodes were old, and
	 the integers were in new space.  Some of the nodes referred to shared numbers, some their own
	 unique numbers.  The numbers were updated frequently. Were new space simply tenured when the
	 remembered table was full, the remembered table would soon fill up as new numbers were computed.
	 Only by selectively pruning the remembered table of nodes that shared data, was a balance achieved
	 whereby the remembered table population was kept small, and tenuring rates were low."
	<inline: #never>
	| population |
	<var: 'population' declareC: 'long population[MaxRTRefCount + 1]'>
	self cCode: [self me: population ms: 0 et: (self sizeof: #long) * (MaxRTRefCount + 1)]
		inSmalltalk: [population := CArrayAccessor on: (Array new: MaxRTRefCount + 1 withAll: 0)].
	self assert: self allNewSpaceObjectsHaveZeroRTRefCount.
	self referenceCountRememberedReferents: population.
	self setRefCountToShrinkRT: population

	"For debugging:
	(manager allNewSpaceObjectsDo: [:o| manager rtRefCountOf: o put: 0])"
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
	| bytesInObj format tenure newLocation |
	self assert: ((manager isInEden: survivor) "cog methods should be excluded."
				or: [manager isInPastSpace: survivor]).
	bytesInObj := manager bytesInObject: survivor.
	format := manager formatOf: survivor.
	tenure := self shouldBeTenured: survivor. "Allow Slang to inline."
	newLocation := (tenure or: [futureSurvivorStart + bytesInObj > futureSpace limit])
						ifTrue: [self copyToOldSpace: survivor bytes: bytesInObj format: format]
						ifFalse: [self copyToFutureSpace: survivor bytes: bytesInObj].
	manager forwardSurvivor: survivor to: newLocation.
	"if weak or ephemeron add to the relevant list for subsequent scanning."
	(manager isWeakFormat: format) ifTrue:
		[self addToWeakList: survivor].
	((manager isEphemeronFormat: format)
	 and: [(self isScavengeSurvivor: (manager keyOfEphemeron: newLocation)) not]) ifTrue:
		[self addToEphemeronList: survivor].
	^newLocation
]

{ #category : #scavenger }
SpurGenerationScavenger >> copyAndForwardMourner: mourner [
	"A special version of copyAndForward: for objects in the mournQueue.  If we're
	 in the good times tenuring regime then copy to futureSpace, otherwise tenure.
	 Also, don't repeat any of the ephemeron processing."
	<inline: false>
	| bytesInObj format tenure newLocation |
	self assert: ((manager isInEden: mourner) "cog methods should be excluded."
				or: [manager isInPastSpace: mourner]).
	bytesInObj := manager bytesInObject: mourner.
	format := manager formatOf: mourner.
	tenure := self shouldMournerBeTenured: mourner. "Allow Slang to inline."
	newLocation := (tenure or: [futureSurvivorStart + bytesInObj > futureSpace limit])
						ifTrue: [self copyToOldSpace: mourner bytes: bytesInObj format: format]
						ifFalse: [self copyToFutureSpace: mourner bytes: bytesInObj].
	manager forwardSurvivor: mourner to: newLocation.
	"if weak or ephemeron add to the relevant list for subsequent scanning."
	(manager isWeakFormat: format) ifTrue:
		[self addToWeakList: mourner].
	^newLocation
]

{ #category : #scavenger }
SpurGenerationScavenger >> copyToFutureSpace: survivor bytes: bytesInObject [
	"Copy survivor to futureSpace.  Assume it will fit (checked by sender).
	 Answer the new oop of the object (it may have an overflow size field)."
	<inline: true>
	| startOfSurvivor newStart |
	statSurvivorCount := statSurvivorCount + 1. "we hope writes are cheap..."
	self assert: futureSurvivorStart + bytesInObject <= futureSpace limit.
	startOfSurvivor := manager startOfObject: survivor.
	newStart := futureSurvivorStart.
	futureSurvivorStart := futureSurvivorStart + bytesInObject.
	manager mem: newStart asVoidPointer cp: startOfSurvivor asVoidPointer y: bytesInObject.
	tenureCriterion = TenureToShrinkRT ifTrue:
		[manager rtRefCountOf: newStart + (survivor - startOfSurvivor) put: 0].
	^newStart + (survivor - startOfSurvivor)
]

{ #category : #scavenger }
SpurGenerationScavenger >> copyToOldSpace: survivor bytes: bytesInObject format: formatOfSurvivor [
	"Copy survivor to oldSpace.  Answer the new oop of the object."
	<inline: #never> "Should be too infrequent to lower icache density of copyAndForward:"
	| nTenures startOfSurvivor newStart newOop |
	self assert: (formatOfSurvivor = (manager formatOf: survivor)
				and: [((manager isMarked: survivor) not or: [tenureCriterion = MarkOnTenure])
				and: [tenureCriterion = TenureToShrinkRT
					or: [(manager isPinned: survivor) not
						and: [(manager isRemembered: survivor) not]]]]).
	nTenures := statTenures.
	startOfSurvivor := manager startOfObject: survivor.
	newStart := manager allocateOldSpaceChunkOfBytes: bytesInObject.
	newStart ifNil:
		[manager growOldSpaceByAtLeast: 0. "grow by growHeadroom"
		 newStart := manager allocateOldSpaceChunkOfBytes: bytesInObject.
		 newStart ifNil:
			[self error: 'out of memory']].
	"manager checkFreeSpace."
	manager mem: newStart asVoidPointer cp: startOfSurvivor asVoidPointer y: bytesInObject.
	newOop := newStart + (survivor - startOfSurvivor).
	tenureCriterion >= (TenureToShrinkRT min: MarkOnTenure) ifTrue:
		[tenureCriterion = TenureToShrinkRT ifTrue:
			[manager rtRefCountOf: newOop put: 0].
		 tenureCriterion = MarkOnTenure ifTrue:
			[manager setIsMarkedOf: newOop to: true]].
	statTenures := nTenures + 1.
	(manager isAnyPointerFormat: formatOfSurvivor) ifTrue:
		["A very quick and dirty scan to find young referents.  If we misidentify bytes
		  in a CompiledMethod as young we don't care; it's unlikely, and a subsequent
		  scan of the rt will filter the object out.  But it's good to filter here because
		  otherwise an attempt to shrink the RT may simply fill it up with new objects,
		  and here the data is likely in the cache."
		 manager baseHeaderSize to: bytesInObject - (survivor - startOfSurvivor) - manager wordSize by: manager wordSize do:
			[:p| | field |
			field := manager longAt: survivor + p.
			(manager isReallyYoung: field) ifTrue:
				[self remember: newOop.
				 ^newOop]]].
	^newOop
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> corpseForCorpseOffset: corpseOffset [
	"Use the identityHash and format fields to construct a 27 bit offset through
	 non-future newSpace and use this to implement lists for weak array and
	 ephemeron processing.  27 bits of 8 byte allocationUnits units is 2 ^ 30
	 bytes, or 1Gb, big enough for newSpace for a good few years yet."
	^corpseOffset - 1 << manager shiftForAllocationUnit + manager newSpaceStart
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> corpseOffsetOf: corpse [
	"Answer the offset of the corpse in newSpace as a multiple of allocationUnits.
	 Use the identityHash and format fields to construct a 27 bit offset through
	 non-future newSpace and use this to implement lists for weak array and
	 ephemeron processing.  27 bits of 8 byte allocationUnits units is 2 ^ 30
	 bytes or 1Gb, big enough for newSpace for a good few years yet.  Add
	 one to ensure that a corpse offset is always non-zero, even when it is
	 that of the first object in newSpace."
	^corpse - manager newSpaceStart >> manager shiftForAllocationUnit + 1
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
		[ | ephemeron key |
		 ephemeron := rememberedSet at: i.
		 self assert: (manager isEphemeron: ephemeron).
		 key := manager keyOfEphemeron: ephemeron.
		 (self isScavengeSurvivor: key) ifFalse:
			[coInterpreter fireEphemeron: ephemeron.
			 manager
				storePointerUnchecked: 0
				ofObject: ephemeron
				withValue: (self copyAndForward: key)].
		 "Fired ephemerons should have had their format changed."
		 self deny: ((self isScavengeSurvivor: key) and: [manager isEphemeron: ephemeron]).
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
	| ephemeron ephemeronCorpse key oldList oldCorpse | "old ones for debugging"
	ephemeronList ifNil:
		[^self].
	oldCorpse := nil.
	ephemeronCorpse := self firstCorpse: ephemeronList.
	"Reset the list head so that new ephemerons will get added
	 to a new list, not concatenated on the one we are scanning."
	oldList := ephemeronList.
	ephemeronList := nil.
	[ephemeronCorpse notNil] whileTrue:
		[self assert: ((manager isYoung: ephemeronCorpse) and: [manager isForwarded: ephemeronCorpse]).
		 ephemeron := manager followForwarded: ephemeronCorpse.
		 key := manager keyOfMaybeFiredEphemeron: ephemeron.
		 (self isScavengeSurvivor: key) ifFalse:
			[coInterpreter fireEphemeron: ephemeron.
			 manager
				storePointerUnchecked: 0
				ofObject: ephemeron
				withValue: (self copyAndForward: key)].
		 "Fired ephemerons should have had their format changed."
		 self deny: ((self isScavengeSurvivor: key) and: [manager isEphemeron: ephemeron]).
		 self cCoerceSimple: (self scavengeReferentsOf: ephemeron) to: #void.
		 oldCorpse := ephemeronCorpse.
		 ephemeronCorpse := self nextCorpseOrNil: ephemeronCorpse]
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> firstCorpse: headOfCorpseList [
	^self corpseForCorpseOffset: headOfCorpseList
]

{ #category : #'gc - global' }
SpurGenerationScavenger >> followRememberedForwardersAndForgetFreeObjects [
	"Scan the remembered set. Follow any forwarded objects,
	 and remove free objects.  This is for global scan-mark GC."
	| index obj |
	index := 0.
	[index < rememberedSetSize] whileTrue:
		[obj := rememberedSet at: index.
		 (manager isFreeObject: obj) "free; remove by overwriting with last element"
			ifTrue:
				[rememberedSetSize := rememberedSetSize - 1.
				 rememberedSet at: index put: (rememberedSet at: rememberedSetSize)]
			ifFalse:
				[(manager isForwarded: obj) ifTrue:
					[obj := manager followForwarded: obj.
					 manager setIsRememberedOf: obj to: true.
					 rememberedSet at: index put: obj].
				 index := index + 1]]
]

{ #category : #'gc - global' }
SpurGenerationScavenger >> followRememberedForwardersAndForgetFreeObjectsForPigCompact [
	"Scan the remembered set. Follow any forwarded objects,
	 and remove free objects.  This is for global scan-mark GC."
	| index obj |
	index := 0.
	[index < rememberedSetSize] whileTrue:
		[obj := rememberedSet at: index.
		 (manager isFreeObject: obj) "free; remove by overwriting with last element"
			ifTrue:
				[rememberedSetSize := rememberedSetSize - 1.
				 rememberedSet at: index put: (rememberedSet at: rememberedSetSize)]
			ifFalse:
				[(manager isForwarded: obj) ifTrue:
					[manager setIsRememberedOf: obj to: false.
					 obj := manager followForwarded: obj.
					 self assert: (manager isRemembered: obj).
					 rememberedSet at: index put: obj].
				 index := index + 1]]
]

{ #category : #'gc - global' }
SpurGenerationScavenger >> forgetObject: objOop [
	"Forget the argument."
	self assert: rememberedSetSize > 0.
	self assert: (manager isRemembered: objOop).
	manager setIsRememberedOf: objOop to: false.
	objOop = (rememberedSet at: rememberedSetSize - 1) ifFalse:
		[| index |
		 index := 0.
		 [index < rememberedSetSize] whileTrue:
			[objOop = (rememberedSet at: index) ifTrue:
				[rememberedSet at: index put: (rememberedSet at: rememberedSetSize - 1).
				 index := rememberedSetSize]]].
	rememberedSetSize := rememberedSetSize - 1.
	self assert: rememberedSetSize >= 0
]

{ #category : #'gc - global' }
SpurGenerationScavenger >> forgetUnmarkedRememberedObjects [
	"Remove all unmarked objects from the remembered set.
	 This is for global scan-mark GC."
	| index |
	index := 0.
	[index < rememberedSetSize] whileTrue:
		[| obj |
		 obj := rememberedSet at: index.
		 (manager isMarked: obj)
			ifTrue: [index := index + 1]
			ifFalse: "unmarked; remove by overwriting with last element."
				[manager setIsRememberedOf: obj to: false.
				 rememberedSetSize := rememberedSetSize - 1.
				 rememberedSet at: index put: (rememberedSet at: rememberedSetSize)]].
	self assert: rememberedSetSize >= 0
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
	<cmacro: '() GIV(futureSurvivorStart)'>
	^futureSurvivorStart
]

{ #category : #accessing }
SpurGenerationScavenger >> getRawTenuringThreshold [
	^tenureThreshold
]

{ #category : #'remembered set' }
SpurGenerationScavenger >> growRememberedSet [
	| obj numSlots newObj base |
	<inline: false> "Don't ruin locality in remember:"
	<var: #base type: #'sqInt *'>
	obj := manager rememberedSetObj.
	numSlots := manager numSlotsOf: obj.
	self assert: numSlots >= 1024.
	newObj := manager allocatePinnedSlots: numSlots * 2.
	newObj ifNil:
		[newObj := manager allocatePinnedSlots: numSlots + 1024.
		 newObj ifNil:
			[self error: 'could not grow remembered set']].
	manager rememberedSetObj: newObj.
	base := manager firstIndexableField: newObj.
	0 to: rememberedSetSize - 1 do:
		[:i| base at: i put: (rememberedSet at: i)].
	"if growing in the middle of a GC, need to preserve marked status."
	(manager isMarked: obj) ifTrue:
		[manager
			setIsMarkedOf: newObj to: true;
			setIsMarkedOf: obj to: false].
	manager freeObject: obj.
	rememberedSet := base.
	rememberedSetLimit := manager numSlotsOf: newObj.
	self setRememberedSetRedZone
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
	rememberedSetSize := 0.
	tenureThreshold := 0.
	statSurvivorCount := statTenures := 0
]

{ #category : #initialization }
SpurGenerationScavenger >> initializeRememberedSet [
	| obj |
	obj := manager rememberedSetObj.
	obj = manager nilObject ifTrue:
		[obj := manager allocatePinnedSlots: 1024.
		 manager rememberedSetObj: obj].
	rememberedSet := manager firstIndexableField: obj.
	rememberedSetSize := 0.
	rememberedSetLimit := manager numSlotsOf: obj.
	self setRememberedSetRedZone
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
SpurGenerationScavenger >> isMaybeOldScavengeSurvivor: oop [
	"Answer whether the oop has survived a scavenge.  This version is
	 for processing weak survivors and must cope with the scavenge in
	 freeUnmarkedObjectsAndSortAndCoalesceFreeSpaceForPigCompact."
	| target |
	(manager isImmediate: oop) ifTrue:
		[^true].
	(manager isForwarded: oop)
		ifTrue:
			[target := manager followForwarded: oop.
			 (manager isImmediate: oop) ifTrue:
				[^true]]
		ifFalse: [target := oop].
	^(manager isOldObject: target)
		ifTrue:
			[tenureCriterion ~= MarkOnTenure
			 or: [manager isMarked: target]]
		ifFalse:
			[manager isInFutureSpace: target]
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
	^(manager isReallyYoung: target) not
	  or: [manager isInFutureSpace: target]
]

{ #category : #accessing }
SpurGenerationScavenger >> newSpaceCapacity [
	<inline: false>
	<returnTypeC: #usqInt>
	^eden limit - (futureSpace start min: pastSpace start)
]

{ #category : #initialization }
SpurGenerationScavenger >> newSpaceStart: startAddress newSpaceBytes: totalBytes survivorBytes: requestedSurvivorBytes [
	| actualEdenBytes survivorBytes |
	survivorBytes := requestedSurvivorBytes truncateTo: manager allocationUnit.
	actualEdenBytes := totalBytes - survivorBytes - survivorBytes truncateTo: manager allocationUnit.
	self assert: totalBytes - actualEdenBytes - survivorBytes - survivorBytes < manager allocationUnit.

	"for tenuring we require older objects below younger objects.  since allocation
	 grows up this means that the survivor spaces must precede eden."

	pastSpace start: startAddress; limit: startAddress + survivorBytes.
	futureSpace start: pastSpace limit; limit: pastSpace limit + survivorBytes.
	eden start: futureSpace limit; limit: startAddress + totalBytes.

	self assert: self futureSpace limit <= (startAddress + totalBytes).
	self assert: self eden start \\ manager allocationUnit
				+ (self eden limit \\ manager allocationUnit) = 0.
	self assert: self pastSpace start \\ manager allocationUnit
				+ (self pastSpace limit \\ manager allocationUnit) = 0.
	self assert: self futureSpace start \\ manager allocationUnit
				+ (self futureSpace limit \\ manager allocationUnit) = 0.

	self initFutureSpaceStart.
	manager initSpaceForAllocationCheck: (self addressOf: eden) limit: eden limit.

	tenuringProportion := 0.9
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
SpurGenerationScavenger >> printRememberedSet [
	"Print the objects in the remembered set."
	<api>
	0 to: rememberedSetSize - 1 do:
		[:i|
		coInterpreter printNum: i; space; shortPrintOop: (rememberedSet at: i)]
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
	<inline: false>
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
	 are, the coInterpreter should be informed via fireFinalization:.
	 Answer if the weakObj has any young referents."
	| weakObjShouldMourn hasYoungReferents numStrongSlots  |
	weakObjShouldMourn := hasYoungReferents := false.
	"N.B. generateToByDoLimitExpression:negative:on: guards against (unsigned)0 - 1 going +ve"
	numStrongSlots := manager numFixedSlotsOf: weakObj.
	0 to: numStrongSlots - 1 do:
		[:i| | referent |
		 referent := manager fetchPointer: i ofObject: weakObj.
		 ((manager isNonImmediate: referent)
		  and: [manager isYoungObject: referent]) ifTrue:
			[hasYoungReferents := true]].
	numStrongSlots
		to: (manager numSlotsOf: weakObj) - 1
		do: [:i| | referent |
			referent := manager fetchPointer: i ofObject: weakObj.
			"Referent could be forwarded due to scavenging or a become:, don't assume."
			(manager isNonImmediate: referent) ifTrue:
				[(manager isForwarded: referent) ifTrue:
					[referent := manager followForwarded: referent.
					 "weakObj is either young or already in remembered table; no need to check"
					 self assert: ((manager isReallyYoungObject: weakObj)
								or: [manager isRemembered: weakObj]).
					 manager storePointerUnchecked: i ofObject: weakObj withValue: referent].
				(self isMaybeOldScavengeSurvivor: referent)
					ifTrue:
						[(manager isYoungObject: referent) ifTrue:
							[hasYoungReferents := true]]
					ifFalse:
						[weakObjShouldMourn := true.
						 manager
							storePointerUnchecked: i
							ofObject: weakObj
							withValue: manager nilObject]]].
	weakObjShouldMourn ifTrue:
		[coInterpreter fireFinalization: weakObj].
	^hasYoungReferents
]

{ #category : #'weakness and ephemerality' }
SpurGenerationScavenger >> processWeaklings [
	"Go through the remembered set and the weak list, nilling references to
	 any objects that didn't survive the scavenge. Read the class comment
	 for a more in-depth description of the algorithm."
	<inline: false>
	| i rootObj weakCorpse weakObj |
	self assert: self allWeakSurvivorsOnWeakList.
	i := 0.
	[i < rememberedSetSize] whileTrue:
		[rootObj := rememberedSet at: i.
		(manager isWeakNonImm: rootObj)
			ifTrue:
				["If no more referents, remove by overwriting with the last element in the set."
				 (self processWeakSurvivor: rootObj)
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
			 "weakObj may have been tenured..."
			 ((self processWeakSurvivor: weakObj)
			  and: [(manager isOldObject: weakObj)
			  and: [(manager isRemembered: weakObj) not]]) ifTrue:
				[self remember: weakObj].
			 weakCorpse := self nextCorpseOrNil: weakCorpse].
		weakList := nil]
]

{ #category : #'remembered set' }
SpurGenerationScavenger >> referenceCountRememberedReferents: population [
	"Both reference count young objects reachable from the RT,
	 and count the populations of each ref count, in a single pass."
	<var: 'population' declareC: 'long population[MaxRTRefCount + 1]'>
	<inline: true>
	0 to: rememberedSetSize - 1 do:
		[:i| | elephant |
		elephant := rememberedSet at: i.
		(manager isForwarded: elephant) ifTrue:
			[elephant := manager followForwarded: elephant.
			 (manager isImmediate: elephant) ifTrue: "take care if elephant forwarded to an immediate"
				[elephant := manager nilObject]].
		0 to: (manager numPointerSlotsOf: elephant) - 1 do:
			[:j| | referent refCount |
			referent := manager fetchPointer: j ofObject: elephant.
			(manager isReallyYoung: referent) ifTrue:
				[refCount := manager rtRefCountOf: referent.
				 refCount < MaxRTRefCount ifTrue:
					[refCount > 0 ifTrue:
						[population at: refCount put: (population at: refCount) - 1].
					 refCount := refCount + 1.
					 manager rtRefCountOf: referent put: refCount.
					 population at: refCount put: (population at: refCount) + 1]]]].
]

{ #category : #'remembered set' }
SpurGenerationScavenger >> relocateRememberedSet [
	"For SpurPanningCompactor"
	rememberedSet := manager firstIndexableField: manager rememberedSetObj
]

{ #category : #'store check' }
SpurGenerationScavenger >> remember: objOop [
	"Add the argument to the remembered set and set its isRemembered bit to true.
	 Answer the argument for the benefit of the Cogit."
	<api>
	<inline: false>
	self assert: (manager isNonImmediate: objOop).
	self deny: (manager isYoungObject: objOop).
	self deny: (manager isRemembered: objOop).
	self deny: (self isInRememberedSet: objOop).
	manager setIsRememberedOf: objOop to: true.
	rememberedSetSize >= rememberedSetLimit ifTrue:
		[self growRememberedSet].
	rememberedSet at: rememberedSetSize put: objOop.
	(rememberedSetSize := rememberedSetSize + 1) >= rememberedSetRedZone ifTrue:
		[manager scheduleScavenge].
	^objOop
]

{ #category : #accessing }
SpurGenerationScavenger >> rememberedSetLimit [
	<cmacro: '() GIV(rememberedSetLimit)'>
	^rememberedSetLimit
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
	statSurvivorCount := 0.
	tenureCriterion := tenuringCriterion.
	self strategizeToLimitRememberedTable.
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
	<inline: false>
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
	<inline: false>
	| previousFutureSurvivorStart firstTime |
	self assert: futureSurvivorStart = futureSpace start. "future space should be empty at the start"

	weakList := ephemeronList := nil.
	numRememberedEphemerons := 0.
	firstTime := true.
	previousRememberedSetSize := 0.
	previousFutureSurvivorStart := futureSurvivorStart.

	coInterpreter initStackPageGC.

	[self scavengeRememberedSetStartingAt: previousRememberedSetSize.
	 previousRememberedSetSize := rememberedSetSize.
	 firstTime ifTrue:
		[coInterpreter mapInterpreterOops.
		 manager mapMournQueue.
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
	| fmt foundNewReferentOrIsWeakling numSlots |
	"forwarding objects should be followed by callers,
	 unless the forwarder is a root in the remembered table."
	self assert: ((manager isForwarded: referrer) not
				or: [manager isRemembered: referrer]).
	"unscanned ephemerons should be scanned later."
	self assert: ((manager isEphemeron: referrer) not
				or: [(self isScavengeSurvivor: (manager keyOfEphemeron: referrer))
				or: [self is: referrer onWeaklingList: ephemeronList]]).
	fmt := manager formatOf: referrer.
	foundNewReferentOrIsWeakling := manager isWeakFormat: fmt.
	numSlots := manager numStrongSlotsOf: referrer format: fmt ephemeronInactiveIf: #isScavengeSurvivor:.
	0 to: numSlots - 1 do:
		[:i| | referent newLocation |
		referent := manager fetchPointer: i ofMaybeForwardedObject: referrer.
		(manager isNonImmediate: referent) ifTrue:
			["a forwarding pointer could be because of become: or scavenging."
			 (manager isForwarded: referent) ifTrue:
				[referent := manager followForwarded: referent].
			 (manager isReallyYoungObject: referent)
				ifTrue: "if target is already in future space forwarding pointer was due to a become:."
					[(manager isInFutureSpace: referent)
						ifTrue: [newLocation := referent. foundNewReferentOrIsWeakling := true]
						ifFalse:
							[newLocation := self copyAndForward: referent.
							 (manager isYoung: newLocation) ifTrue:
								[foundNewReferentOrIsWeakling := true]].
					 manager storePointerUnchecked: i ofMaybeForwardedObject: referrer withValue: newLocation]
				ifFalse:
					[manager storePointerUnchecked: i ofMaybeForwardedObject: referrer withValue: referent]]].
	^foundNewReferentOrIsWeakling
]

{ #category : #scavenger }
SpurGenerationScavenger >> scavengeRememberedSetStartingAt: n [
	"scavengeRememberedSetStartingAt: n traverses objects in the remembered
	 set starting at the nth one.  If the object does not refer to any new objects, it
	 is removed from the set.  Otherwise, its new referents are scavenged.  Defer
	 scavenging ephemerons until after a complete scavenge has been performed,
	 so that triggered ephemerons can be fired.  Move them to the front of the set
	 and count them in numRememberedEphemerons for later scanning."
	<inline: false>
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
	<var: 'aProportion' type: #double>
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
	<inline: true>
	self assert: (manager isYoung: corpse).
	self assert: (manager isForwarded: corpse).
	manager wordSize = 4
		ifTrue: "On 64-bit gcc 4.4.7-4 the following is miscompiled at -O2; the first assignment is lost"
			[manager
				setHashBitsOf: corpse
					to: offset >> manager formatFieldWidthShift;
				setFormatOf: corpse
					to: (offset bitAnd: manager formatMask)]
		ifFalse: "So we use the single assignment"
			[manager
				long64At: corpse
				put: (manager
						headerForSlots: (manager rawNumSlotsOf: corpse)
						hash: (offset >> manager formatFieldWidthShift)
						format: (offset bitAnd: manager formatMask)
						classIndex: manager isForwardedObjectClassIndexPun)]
]

{ #category : #accessing }
SpurGenerationScavenger >> setRawTenuringThreshold: threshold [
	tenureThreshold := threshold
]

{ #category : #'remembered set' }
SpurGenerationScavenger >> setRefCountToShrinkRT: population [
	"Choose a refCount that should shrink the rt by at least  half.
	 i.e. find the maximum reference count that half the population have at least."
	<var: 'population' declareC: 'long population[MaxRTRefCount + 1]'>
	<inline: true>
	| entirePopulation i count |
	self assert: (population at: 0) = 0.
	entirePopulation := 0.
	1 to: MaxRTRefCount do:
		[:j| entirePopulation := entirePopulation + (population at: j)].
	count := 0.
	i := MaxRTRefCount + 1.
	[count < (entirePopulation // 2) and: [(i := i - 1) >= 0]] whileTrue:
		[count := count + (population at: i)].
	refCountToShrinkRT := i max: 0
]

{ #category : #'remembered set' }
SpurGenerationScavenger >> setRememberedSetRedZone [
	| fudge |
	<inline: true>
	"fudge is a minimum below which we don't care about growing the RT.
	 It is chosen so that with a default 4Mb new space, the RT is not considered
	 full until it has from 512 to 1024 entries."
	fudge := eden limit - eden start / manager wordSize // 1024.
	rememberedSetRedZone := rememberedSetLimit * 3 // 4 max: fudge
]

{ #category : #scavenger }
SpurGenerationScavenger >> shouldBeTenured: survivor [
	"Answer if an object should be tenured.  The default policy tenuring policy
	 is to use the tenuringThreshold to decide. If the survivors (measured in
	 bytes) are above some fraction of the survivor space then objects below
	 the threshold (older objects, since allocation grows upwards and hence
	 new objects are later than old) are scavenged.  Otherwise, the threshold
	 is set to 0 and no objects are tenured.  e.g. see
		An adaptive tenuring policy for generation scavengers,
		David Ungar & Frank Jackson.
		ACM TOPLAS, Volume 14 Issue 1, Jan. 1992, pp 1 - 27.

	 The other policies are for special purposes."
	^tenureCriterion
		caseOf: {
			[TenureByAge]	->
				[survivor < tenureThreshold]. 
			[TenureByClass] ->
				[(manager classIndexOf: survivor) = tenuringClassIndex].
			[TenureToShrinkRT]	->
				[(manager rtRefCountOf: survivor) >= refCountToShrinkRT]  }
		otherwise: [false]
]

{ #category : #scavenger }
SpurGenerationScavenger >> shouldMournerBeTenured: survivor [
	"Answer if an object in the mourn queue should be tenured.  If we're
	 in the good times tenuring regime then copy to futureSpace, otherwise tenure."
	^(tenureCriterion = TenureByAge and: [tenureThreshold = 0]) not
]

{ #category : #accessing }
SpurGenerationScavenger >> statSurvivorCount [
	^statSurvivorCount
]

{ #category : #accessing }
SpurGenerationScavenger >> statTenures [
	^statTenures
]

{ #category : #'remembered set' }
SpurGenerationScavenger >> strategizeToLimitRememberedTable [
	<inline: true>
	(tenureCriterion = TenureByAge
	 and: [rememberedSetSize >= rememberedSetRedZone]) ifTrue:
		[tenureCriterion := TenureToShrinkRT.
		 self computeRefCountToShrinkRT]
]

{ #category : #accessing }
SpurGenerationScavenger >> tenuringClassIndex [
	^tenuringClassIndex
]

{ #category : #accessing }
SpurGenerationScavenger >> tenuringClassIndex: anInteger [
	tenuringClassIndex := anInteger
]
