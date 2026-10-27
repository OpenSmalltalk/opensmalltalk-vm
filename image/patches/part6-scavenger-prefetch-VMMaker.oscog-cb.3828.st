'From Squeak6.0 of 27 October 2026 [latest update: #23976] on 27 October 2026 at 10:55:00 pm'!

!SpurGenerationScavenger methodsFor: 'scavenger' stamp: 'cb 10/27/2026 22:45'!
scavengeDequeuedReferent: warmReferent slot: warmSlot of: referrer
	"Resolve, scavenge, and store back a dequeued warm referent.
	 Answer if the referent is still a young object."
	<inline: true>
	| referent foundNew |
	(manager isForwarded: warmReferent)
		ifFalse:
			[referent := self copyAndForward: warmReferent.
			 foundNew := manager isReallyYoungObject: referent]
		ifTrue:
			[referent := manager followForwarded: warmReferent.
			 foundNew := false.
			 (manager isReallyYoung: referent) ifTrue:
				[(manager isInFutureSpace: referent)
					ifTrue: [foundNew := true]
					ifFalse:
						[referent := self copyAndForward: referent.
						 foundNew := manager isReallyYoungObject: referent]]].
	manager storePointerUnchecked: warmSlot ofMaybeForwardedObject: referrer withValue: referent.
	^foundNew! !

!SpurGenerationScavenger methodsFor: 'scavenger' stamp: 'cb 10/27/2026 22:45'!
scavengeReferentsOf: referrer numSlots: numSlots
	"Scavenge the referents of an object with numSlots using a 16-entry FIFO prefetch queue.
	 Answer if it still refers to young objects."
	<inline: true>
	| foundNewReferent prefetchQueue prefetchSlots prefetchHead prefetchTail warmReferent warmSlot hasNewReferent |
	<var: 'prefetchQueue' declareC: 'sqInt prefetchQueue[16]'>
	<var: 'prefetchSlots' declareC: 'sqInt prefetchSlots[16]'>
	self cCode: [] inSmalltalk:
		[prefetchQueue := CArrayAccessor on: (Array new: 16).
		 prefetchSlots := CArrayAccessor on: (Array new: 16)].
	foundNewReferent := false.
	prefetchHead := prefetchTail := 0.
	0 to: numSlots - 1 do:
		[:i| | referent |
		referent := manager fetchPointer: i ofMaybeForwardedObject: referrer.
		((manager isNonImmediate: referent)
		 and: [manager isReallyYoungObject: referent]) ifTrue:
			[(manager isInFutureSpace: referent)
				ifTrue: [foundNewReferent := true]
				ifFalse:
					[self cCode: [self cppIf: #'defined(__GNUC__) || defined(__clang__)'
									ifTrue: [self __builtin_prefetch: referent asVoidPointer _: 0 _: 3]]
						inSmalltalk: [].
					 prefetchQueue at: (prefetchHead bitAnd: 15) put: referent.
					 prefetchSlots at: (prefetchHead bitAnd: 15) put: i.
					 prefetchHead := prefetchHead + 1.
					 prefetchHead - prefetchTail >= 8 ifTrue:
						[warmReferent := prefetchQueue at: (prefetchTail bitAnd: 15).
						 warmSlot := prefetchSlots at: (prefetchTail bitAnd: 15).
						 prefetchTail := prefetchTail + 1.
						 hasNewReferent := self scavengeDequeuedReferent: warmReferent slot: warmSlot of: referrer.
						 hasNewReferent ifTrue:
							[foundNewReferent := true]]]]].
	[prefetchTail < prefetchHead] whileTrue:
		[warmReferent := prefetchQueue at: (prefetchTail bitAnd: 15).
		 warmSlot := prefetchSlots at: (prefetchTail bitAnd: 15).
		 prefetchTail := prefetchTail + 1.
		 hasNewReferent := self scavengeDequeuedReferent: warmReferent slot: warmSlot of: referrer.
		 hasNewReferent ifTrue:
			[foundNewReferent := true]].
	^foundNewReferent! !

!SpurGenerationScavenger methodsFor: 'scavenger' stamp: 'cb 10/27/2026 22:45'!
scavengeReferentsOfIndexablePointers: referrer
	"Scavenge the referents of an indexable pointer object, which could be a context.
	 Answer if it still refers to young objects."
	<inline: true>
	^self scavengeReferentsOf: referrer numSlots: (manager numSlotsOfIndexablePointerObj: referrer)! !

!SpurGenerationScavenger methodsFor: 'scavenger' stamp: 'cb 10/27/2026 22:45'!
scavengeReferentsOfPointers: referrer
	"Scavenge the referents of a normal pointer object.
	 Answer if it still refers to young objects."
	<inline: true>
	^self scavengeReferentsOf: referrer numSlots: (manager numSlotsOf: referrer)! !

!Spur64BitMemoryManager methodsFor: 'snapshot' stamp: 'cb 10/27/2026 22:50'!
defaultEdenBytes
	"Answer the default amount of memory to allocate for the eden space.
	 The actual value can be set via vmParameterAt: and/or a preference in the ini file.
	 With the 16-entry lookahead prefetch queue in the scavenger, the cache-cliff
	 at larger Eden sizes is eliminated (80 cycles/pointer at 16MB vs 139 baseline).
	 Bumping to 16Mb provides fewer scavenges and higher throughput."
	<inline: false>
	^16 * 1024 * 1024! !
