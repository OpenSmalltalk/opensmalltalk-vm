"
I am a class that helps organize the CoInterpreter's collection of stack pages.  I hold the set of stack pages represented by CogStackPageSurrogate instances/StackPage structs.  The pages are held in a doubly-linked list that notionally has two heads:

mostRecentlyUsedPage-->used page<->used page<->used page<->used page<--leastRecentlyUsedPage
                                       ^                        <-next-prev->                         ^
                                        |                                                                       |
                                        v                        <-prev-next->                         v
                                        free page<->free page<->free page<->free page

In fact we don't need the least-recently-used page, and so it is only present conceptually.  The point is that there is a possibly empty but contiguous sequence of free pages starting at mostRecentlyUsedPage nextPage.  New pages are allocated preferentially from the free page next to the MRUP.
If there are no free pages then (effectively) the LRUP's frames are flushed to contexts and it is used instead.

Instance Variables
	maxStackAddress:		<Integer>
	minStackAddress:		<Integer>
	pageMap:				<Dictionary>
	stackBasePlus1:		<Integer>

maxStackAddress
	- the maximum valid byte address in the stack zone

minStackAddress
	- the minimum valid byte address in the stack zone

pageMap
	- a map from address to the CogStackPageSurrogate for that address

stackBasePlus1
	- the address of the 2nd byte in the stack memory, used for mapping stack addresses to page indices
"
Class {
	#name : #CoInterpreterStackPages,
	#superclass : #CogStackPages,
	#instVars : [
		'stackBasePlus1',
		'pageMap',
		'minStackAddress',
		'maxStackAddress'
	],
	#pools : [
		'VMBasicConstants'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
CoInterpreterStackPages class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator
		var: #stackBasePlus1 type: #'char *';
		removeVariable: 'pageMap'; "These are simulation/debugging things only"
		removeVariable: 'maxStackAddress'; "These are simulation/debugging things only"
		removeVariable: 'minStackAddress' "These are simulation/debugging things only"
]

{ #category : #assertions }
CoInterpreterStackPages >> couldBeFramePointer: pointer [
	"Answer if the argument is a properly aligned pointer into the stack zone."
	<var: #pointer type: #'void *'>
	^(pointer asUnsignedInteger bitAnd: objectMemory wordSize - 1) = 0
	   and: [pointer asUnsignedInteger
				between: (stackBasePlus1 - 1) asUnsignedInteger
				and: (self cCode: [pages asUnsignedInteger]
							inSmalltalk: [(self stackPageAt: 0) asUnsignedInteger])]
]

{ #category : #initialization }
CoInterpreterStackPages >> initializeStack: theStackPages numSlots: stackSlots pageSize: slotsPerPage [
	"Initialize the stack pages.  In the C VM theStackPages will be alloca'ed memory to hold the
	 stack pages on the C stack.  In the simulator they are housed in the memory between the
	 cogMethodZone and the heap."

	<var: #theStackPages type: #'char *'>
	<returnTypeC: #void>
	| numPages page structStackPageSize pageStructBase count |
	<var: #page type: #'StackPage *'>
	<var: #pageStructBase type: #'char *'>
	self cCode: []
		inSmalltalk:
			["self assert: objectMemory startOfMemory - coInterpreter cogCodeSize - Cogit guardPageSize - coInterpreter methodCacheSize - coInterpreter primTraceLogSize - coInterpreter rumpCStackSize
					= (stackSlots * objectMemory wordSize roundUpTo: objectMemory allocationUnit)"].
	structStackPageSize := coInterpreter sizeof: CogStackPage.
	bytesPerPage := slotsPerPage * objectMemory wordSize.
	numPages := coInterpreter numStkPages.

	"Because stack pages grow down baseAddress is at the top of a stack page and so to avoid
	 subtracting BytesPerWord from baseAddress and lastAddress in the init loop below we simply
	 push the stackPage array up one word to avoid the overlap.  This word is extraStackBytes."
	pageStructBase := theStackPages + (numPages * bytesPerPage) + objectMemory wordSize.
	pages := self cCode: [self cCoerceSimple: pageStructBase to: #'StackPage *']
				  inSmalltalk:
					[pageMap := Dictionary new.
					 ((0 to: numPages - 1) collect:
						[:i|
						 CogStackPage surrogateClass new
							address: pageStructBase + (i * structStackPageSize)
							simulator: coInterpreter
							zoneBase: coInterpreter stackZoneBase
							zoneLimit: objectMemory startOfMemory])
						do: [:pageSurrogate|
							pageMap at: pageSurrogate address put: pageSurrogate];
						yourself].
	"make sure there's enough headroom"
	self assert: coInterpreter stackPageByteSize - coInterpreter stackLimitBytes - coInterpreter stackLimitOffset
				>= coInterpreter stackPageHeadroom.
	0 to: numPages - 1 do:
		[:index|
		 page := self stackPageAt: index.
		 page
			lastAddress: theStackPages + (index * bytesPerPage);
			baseAddress: page lastAddress + bytesPerPage;
			stackLimit: page baseAddress - coInterpreter stackLimitBytes;
			realStackLimit: page stackLimit;
			baseFP: 0;
			nextPage: (self stackPageAt: (index = (numPages - 1) ifTrue: [0] ifFalse: [index + 1]));
			prevPage: (self stackPageAt: (index = 0 ifTrue: [numPages - 1] ifFalse: [index - 1]))].

	"Now compute stackBasePlus1 so that the pageIndexFor: call maps all addresses from
	 aPage baseAddress to aBase limitAddress + 1 to the same index (stacks grow down)"
	stackBasePlus1 := (self cCoerceSimple: theStackPages to: #'char *') + 1.
	self cCode: []
		inSmalltalk:
			[minStackAddress := theStackPages.
			 maxStackAddress := theStackPages + (numPages * bytesPerPage) + objectMemory wordSize - 1].

	"The overflow limit is the amount of stack to retain when moving frames from an overflowing
	 stack to reduce thrashing.  See stackOverflowOrEvent:mayContextSwitch:"
	page := self stackPageAt: 0.
	overflowLimit := page baseAddress - page realStackLimit * 3 // 5.
	0 to: numPages - 1 do:
		[:index|
		 page := self stackPageAt: index.
		 self assert: (self pageIndexFor: page baseAddress) == index.
		 self assert: (self pageIndexFor: page baseAddress - (slotsPerPage - 1 * objectMemory wordSize)) == index.
		 self assert: (self stackPageFor: page baseAddress) == page.
		 self assert: (self stackPageFor: page stackLimit) == page.
		 self cCode: []
			inSmalltalk:
				[| memIndex |
				 memIndex := index * slotsPerPage + 1. "this is memIndex in the block above"
				 self assert: (self memIndexFor: (self oopForPointer: page baseAddress))
							== (memIndex + slotsPerPage - 1).
				 index < (numPages - 1) ifTrue:
					[self assert: (self stackPageFor: page baseAddress + objectMemory wordSize) == (self stackPageAt: index + 1)]].
		coInterpreter initializePageTraceToInvalid: page].

	mostRecentlyUsedPage := self stackPageAt: 0.
	page := mostRecentlyUsedPage.
	count := 0.
	[| theIndex |
	 count := count + 1.
	 theIndex := self pageIndexFor: page baseAddress.
	 self assert: (self stackPageAt: theIndex) == page.
	 self assert: (self pageIndexFor: page baseAddress) == theIndex.
	 self assert: (self pageIndexFor: page stackLimit) == theIndex.
	 self assert: (self pageIndexFor: page lastAddress + 1) == theIndex.
	 (page := page nextPage) ~= mostRecentlyUsedPage] whileTrue.
	self assert: count == numPages.
	self assert: self pageListIsWellFormed
]

{ #category : #initialization }
CoInterpreterStackPages >> initializeWithByteSize: byteSize "<Integer>" for: anInterpreter [ "<CoInterpreter>" "^<Array of: <Integer>"
	"Initialize the stackPages memory for simulation.  To keep access monitoring
	 in one place we defer to the coInterpreter for accessing memory.  Answer the
	 base address of th ememory."
	<doNotGenerate>
	coInterpreter := anInterpreter.
	objectMemory := coInterpreter objectMemory.
	^anInterpreter stackZoneBase
]

{ #category : #'memory access' }
CoInterpreterStackPages >> longAt: byteAddress [
	<doNotGenerate>
	"Note: Adjusted for Smalltalk's 1-based array indexing."
	self assert: (byteAddress >= minStackAddress and: [byteAddress < maxStackAddress]).
	^objectMemory longAt: byteAddress
]

{ #category : #'memory access' }
CoInterpreterStackPages >> longAt: byteAddress put: a32Or64BitValue [
	<doNotGenerate>
	self assert: (byteAddress >= minStackAddress and: [byteAddress < maxStackAddress]).
	^objectMemory longAt: byteAddress put: a32Or64BitValue
]

{ #category : #'page access' }
CoInterpreterStackPages >> memIndexFor: byteAddress [
	"Map an address into the stack zone into a word index into the slots in the stack zone."
	<doNotGenerate>
	^(self oopForPointer: byteAddress) - coInterpreter stackZoneBase - 1 // objectMemory wordSize + 1
]

{ #category : #'page access' }
CoInterpreterStackPages >> pageIndexFor: pointer [ "<Integer>"
	"Answer the page index for a pointer into stack memory, i.e. the index
	 for the page the address is in.  N.B.  This is a zero-relative index."
	<var: #pointer type: #'void *'>
	<inline: true>
	self assert: ((self cCoerceSimple: pointer to: #'char *')
					between: stackBasePlus1 - 1
					and: (self cCode: [self cCoerceSimple: pages to: #'char *']
							inSmalltalk: [(self stackPageAt: 0) asInteger])).
	^self pageIndexFor: pointer stackBasePlus1: stackBasePlus1 bytesPerPage: bytesPerPage
]

{ #category : #'page access' }
CoInterpreterStackPages >> pageIndexFor: pointer "<Integer>" stackBasePlus1: stkBasePlus1 "<Integer>" bytesPerPage: pageByteSize [ "<Integer>"
	"Answer the page index for a pointer into stack memory, i.e. the index
	 for the page the address is in.  N.B.  This is a zero-relative index."
	<cmacro: '(pointer,stkBasePlus1,pageByteSize) (((char *)(pointer) - (stkBasePlus1)) / (pageByteSize))'>
	^pointer - stkBasePlus1 // pageByteSize
]

{ #category : #accessing }
CoInterpreterStackPages >> surrogateAtAddress: anAddress [
	<doNotGenerate>
	^pageMap at: anAddress
]

{ #category : #'debug printing' }
CoInterpreterStackPages >> whereIsMaybeStackThing: anOop [
	"If anOop is an address within the stack zone answer a string stating that, otherwise answer nil."
	<returnTypeC: 'char *'>
	(self oop: anOop
		isGreaterThanOrEqualTo: (stackBasePlus1 - 1)
		andLessThan: (self cCode: [pages]
							inSmalltalk: [(self stackPageAt: 0) asUnsignedInteger])) ifTrue:
		[^' is in the stack zone'].
	^nil
]
