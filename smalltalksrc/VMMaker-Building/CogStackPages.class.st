"
I am a class that helps organize the StackInterpreter's collection of stack pages.  I hold the set of stack pages represented by InterpreterStackPage instances/StackPage structs.  The pages are held in a doubly-linked list that notionally has two heads:

mostRecentlyUsedPage-->used page<->used page<->used page<->used page<--leastRecentlyUsedPage
                                       ^                        <-next-prev->                         ^
                                        |                                                                       |
                                        v                        <-prev-next->                         v
                                        free page<->free page<->free page<->free page

In fact we don't need the least-recently-used page, and so it is only present conceptually.  The point is that there is a possibly empty but contiguous sequence of free pages starting at mostRecentlyUsedPage nextPage.  New pages are allocated preferentially from the free page next to the MRUP.
If there are no free pages then (effectively) the LRUP's frames are flushed to contexts and it is used instead.

I have two concrete classes, one for the StackInterpreter and one for the CoInterpreter.

Instance Variables
	bytesPerPage:						<Integer>
	coInterpreter:						<StackInterpreter>
	mostRecentlyUsedPage:			<CogStackPage>
	objectMemory:						<ObjectMemory|SpurMemoryManager>
	overflowLimit:						<Integer>
	pages:								<Array of: CogStackPage>
	statNumMaps:						<Integer>
	statPageCountWhenMappingSum:		<Integer>

bytesPerPage
	- the size of a page in bytes

coInterpreter
	- the interpreter the receiver is holding pages for

mostRecentlyUsedPage
	- the most recently used stack page

objectMemory
	- the objectMemory of the interpreter

overflowLimit
	- the length in bytes of the portion of teh stack that can be used for frames before the page is judged to have overflowed

pages
	- the collection of stack pages the receiver is managing

statNumMaps
	- the number of mapStackPages calls

statPageCountWhenMappingSum:
	- the sum of the number of in use pages at each mapStackPages, used to estimate the average number of in use pages at scavenge, which heavily influences scavenger performance

"
Class {
	#name : #CogStackPages,
	#superclass : #CogClass,
	#instVars : [
		'coInterpreter',
		'objectMemory',
		'pages',
		'mostRecentlyUsedPage',
		'overflowLimit',
		'bytesPerPage',
		'statNumMaps',
		'statPageCountWhenMappingSum',
		'statMaxPageCountWhenMapping'
	],
	#pools : [
		'VMBasicConstants'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #translation }
CogStackPages class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator
		var: #mostRecentlyUsedPage type: #'StackPage *';
		var: #pages type: #'StackPage *'.
	aCCodeGenerator
		removeVariable: 'coInterpreter'; "These are simulation/debugging things only"
		removeVariable: 'objectMemory' "These are simulation/debugging things only"
]

{ #category : #assertions }
CogStackPages >> allPagesFree [
	<doNotGenerate>
	^pages allSatisfy: [:page| (self isFree: page)]
]

{ #category : #'memory access' }
CogStackPages >> byteAt: byteAddress [ "<Integer>" 
	self subclassResponsibility
]

{ #category : #initialization }
CogStackPages >> extraStackBytes [
	"See initializeStack:numSlots:pageSize:stackLimitOffset:stackPageHeadroom:
	``Because stack pages grow down...''"
	^objectMemory wordSize
]

{ #category : #'page access' }
CogStackPages >> freeStackPage: aPage [ "<InterpreterStackPage>"
	"MRUP-->used page<->used page<->used page<->used page<--LRUP
	               ^                        <-next-prev->                         ^
	                |                                                                       |
	                v                        <-prev-next->                         v
	                free page<->free page<->free page<->free page"
	<var: #aPage type: #'StackPage *'>
	<inline: false>
	self freeStackPageNoAssert: aPage.
	self assert: self pageListIsWellFormed
]

{ #category : #'page access' }
CogStackPages >> freeStackPageNoAssert: aPage [ "<InterpreterStackPage>"
	"MRUP-->used page<->used page<->used page<->used page<--LRUP
	               ^                        <-next-prev->                         ^
	                |                                                                       |
	                v                        <-prev-next->                         v
	                free page<->free page<->free page<->free page"
	<var: #aPage type: #'StackPage *'>
	<returnTypeC: #void>
	| prev |
	<var: #prev type: #'StackPage *'>
	aPage baseFP: 0.
	aPage == mostRecentlyUsedPage ifTrue:
		[mostRecentlyUsedPage := mostRecentlyUsedPage prevPage.
		 ^nil].
	(prev := aPage prevPage) isFree ifTrue:
		[^nil].
	prev nextPage: aPage nextPage.
	aPage nextPage prevPage: prev.
	aPage nextPage: mostRecentlyUsedPage nextPage.
	mostRecentlyUsedPage nextPage prevPage: aPage.
	aPage prevPage: mostRecentlyUsedPage.
	mostRecentlyUsedPage nextPage: aPage
]

{ #category : #initialization }
CogStackPages >> initialize [
	"Here we can initialize the variables C initializes to zero.  #initialize methods do /not/ get translated."
	statNumMaps := statPageCountWhenMappingSum := statMaxPageCountWhenMapping := 0
]

{ #category : #initialization }
CogStackPages >> initializeStack: theStackPages numSlots: stackSlots pageSize: slotsPerPage [
	"Initialize the stack pages.  In the C VM theStackPages will be alloca'ed memory to hold the
	 stack pages on the C stack.  In the simulator they are housed in the memory between the
	 cogMethodZone and the heap."
	<returnTypeC: #void>
	self subclassResponsibility
]

{ #category : #initialization }
CogStackPages >> initializeWithByteSize: byteSize "<Integer>" for: anInterpreter [ "<CoInterpreter>" "^<Array of: <Integer>"
	"Initialize the stackPages memory for simulation. Answer the base address of the memory."
	self subclassResponsibility
]

{ #category : #'page access' }
CogStackPages >> isFree: thePage [
	"This is an anachronism.  Previously Slang couldn't generate the method correctly
	 from e.g. CogStackPageSurrogate>>isFree since Slang didn't do substitution on self.
	 Now it does, but there are still callers of isFree: so we keep this for simulation."
	<doNotGenerate>
	^thePage baseFP = 0
]

{ #category : #'page access' }
CogStackPages >> markStackPageLeastMostRecentlyUsed: page [ "<InterpreterStackPage>"
	"This method is used to move a page to the end of the used pages.
	 This is to keep asserts checking pageListIsWellFormed happy."

	"MRUP-->used page<->used page<->used page<->used page<--LRUP
	               ^                        <-next-prev->                         ^
	                |                                                                       |
	                v                        <-prev-next->                         v
	                free page<->free page<->free page<->free page"

	<var: #page type: #'StackPage *'>
	<returnTypeC: #void>
	| lastUsedPage |
	<var: #lastUsedPage type: #'StackPage *'>
	self assert: page = mostRecentlyUsedPage nextPage.
	lastUsedPage := page nextPage.
	[lastUsedPage isFree] whileTrue:
		[lastUsedPage := lastUsedPage nextPage].
	lastUsedPage nextPage = page ifTrue:
		[^nil].
	page prevPage nextPage: page nextPage.
	page nextPage prevPage: page prevPage.
	lastUsedPage prevPage nextPage: page.
	page prevPage: lastUsedPage prevPage.
	page nextPage: lastUsedPage.
	lastUsedPage prevPage: page.
	self assert: self pageListIsWellFormed
]

{ #category : #'page access' }
CogStackPages >> markStackPageMostRecentlyUsed: page [ "<InterpreterStackPage>"
	"MRUP-->used page<->used page<->used page<->used page<--LRUP
	               ^                        <-next-prev->                         ^
	                |                                                                       |
	                v                        <-prev-next->                         v
	                free page<->free page<->free page<->free page"
	<var: #page type: #'StackPage *'>
	<returnTypeC: #void>
	page == mostRecentlyUsedPage ifTrue:
		[^nil].
	"Common case; making new page most recently used."
	page prevPage == mostRecentlyUsedPage ifTrue:
		[mostRecentlyUsedPage := page.
		 self assert: self pageListIsWellFormed.
		 ^nil].
	page prevPage nextPage: page nextPage.
	page nextPage prevPage: page prevPage.
	mostRecentlyUsedPage nextPage prevPage: page.
	page prevPage: mostRecentlyUsedPage.
	page nextPage: mostRecentlyUsedPage nextPage.
	mostRecentlyUsedPage nextPage: page.
	mostRecentlyUsedPage := page.
	self assert: self pageListIsWellFormed
]

{ #category : #'page access' }
CogStackPages >> markStackPageNextMostRecentlyUsed: page [ "<InterpreterStackPage>"
	"This method is used to move a page to a position in the list such that it cannot
	 be deallocated when a new page is allocated, without changing the most recently
	 used page.  There must be at least 3 pages in the system.  So making the page
	 the MRU's prevPage is sufficient to ensure it won't be deallocated."

	"MRUP-->used page<->used page<->used page<->used page<--LRUP
	               ^                        <-next-prev->                         ^
	                |                                                                       |
	                v                        <-prev-next->                         v
	                free page<->free page<->free page<->free page"

	<var: #page type: #'StackPage *'>
	<returnTypeC: #void>
	self assert: page ~~ mostRecentlyUsedPage.
	page nextPage == mostRecentlyUsedPage ifTrue:
		[^nil].
	page prevPage nextPage: page nextPage.
	page nextPage prevPage: page prevPage.
	mostRecentlyUsedPage prevPage nextPage: page.
	page prevPage: mostRecentlyUsedPage prevPage.
	page nextPage: mostRecentlyUsedPage.
	mostRecentlyUsedPage prevPage: page.
	self assert: self pageListIsWellFormed
]

{ #category : #'page access' }
CogStackPages >> memIndexFor: byteAddress [
	"Map an address into the stack zone into a word index into the slots in the stack zone."
	<doNotGenerate>
	self subclassResponsibility
]

{ #category : #'page access' }
CogStackPages >> mostRecentlyUsedPage [
	<cmacro: '() GIV(mostRecentlyUsedPage)'>
	<returnTypeC: #'StackPage *'> "this is to guide Slang's inliner"
	^mostRecentlyUsedPage
]

{ #category : #'page access' }
CogStackPages >> newStackPage [
	"MRUP-->used page<->used page<->used page<->used page<--LRUP
	               ^                        <-next-prev->                         ^
	                |                                                                       |
	                v                        <-prev-next->                         v
	                free page<->free page<->free page<->free page"
	<returnTypeC: #'StackPage *'>
	| lruOrFree |
	<var: #lruOrFree type: #'StackPage *'>
	lruOrFree := mostRecentlyUsedPage nextPage.
	lruOrFree isFree ifTrue:
		[^lruOrFree].
	coInterpreter divorceFramesIn: lruOrFree.
	^lruOrFree
]

{ #category : #'page access' }
CogStackPages >> overflowLimit [
	^overflowLimit
]

{ #category : #'page access' }
CogStackPages >> pageIndexFor: pointer [ "<Integer>"
	"Answer the page index for a pointer into stack memory, i.e. the index
	 for the page the address is in.  N.B.  This is a zero-relative index."
	<var: #pointer type: #'void *'>
	<inline: true>
	self subclassResponsibility
]

{ #category : #assertions }
CogStackPages >> pageListIsWellFormed [
	"Answer if the stack page list is well-formed.
	 MRUP-->used page<->used page<->used page<->used page<--LRUP
	               ^                        <-next-prev->                         ^
	                |                                                                       |
	                v                        <-prev-next->                         v
	                free page<->free page<->free page<->free page"
	| ok page count limit |
	<inline: false>
	<var: #page type: #'StackPage *'>
	ok := true.
	page := mostRecentlyUsedPage nextPage.
	count := 1.
	limit := coInterpreter numStkPages * 2.
	[page isFree
	 and: [page ~= mostRecentlyUsedPage
	 and: [count <= limit]]] whileTrue:
		[(self asserta: page nextPage prevPage == page) ifFalse:
			[ok := false].
		 page := page nextPage.
		 count := count + 1].
	[page ~= mostRecentlyUsedPage
	 and: [count <= limit]] whileTrue:
		[(self asserta: page nextPage prevPage == page) ifFalse:
			[ok := false].
		 (self asserta: page isFree not)
			ifTrue:
				[(self asserta: ((page addressIsInPage: page baseFP)
								and: [page addressIsInPage: page headSP])) ifFalse:
					[ok := false]]
			ifFalse:
				[ok := false].
		 page := page nextPage.
		 count := count + 1].
	(self asserta: count = coInterpreter numStkPages) ifFalse:
		[ok := false].
	^ok
]

{ #category : #accessing }
CogStackPages >> pages [
	<doNotGenerate>
	^pages
]

{ #category : #statistics }
CogStackPages >> recordLivePagesOnMapping: numLivePages [
	<inline: true>
	statNumMaps := statNumMaps + 1.
	statPageCountWhenMappingSum := statPageCountWhenMappingSum + numLivePages.
	statMaxPageCountWhenMapping := statMaxPageCountWhenMapping max: numLivePages
]

{ #category : #initialization }
CogStackPages >> setInterpreter: anInterpreter [
	"Initialize the stackPages memory for simulation.  To keep access monitoring
	 in one place we defer to the coInterpreter for accessing memory."
	<doNotGenerate>
	coInterpreter := anInterpreter.
	objectMemory := coInterpreter objectMemory
]

{ #category : #assertions }
CogStackPages >> somePageHasHeadFrameFP: theFP [
	<doNotGenerate>
	^pages anySatisfy: [:page| page headFP = theFP]

]

{ #category : #'page access' }
CogStackPages >> stackPageAt: index [
	"Answer the page for a page index.
	 N.B.  This is a zero-relative index."
	<returnTypeC: #'StackPage *'>
	<inline: true>
	^self stackPageAt: index pages: pages
]

{ #category : #'page access' }
CogStackPages >> stackPageAt: index pages: thePages [
	"Answer the page for a page index.
	 N.B.  This is a zero-relative index."
	<cmacro: '(index,pages) ((pages) + (index))'>
	<returnTypeC: #'StackPage *'> "for Slang..."
	^thePages at: index + 1
]

{ #category : #'page access' }
CogStackPages >> stackPageFor: pointer [ "<Integer>"
	<inline: true>
	<var: #pointer type: #'void *'>
	<returnTypeC: #'StackPage *'>
	^self stackPageAt: (self pageIndexFor: pointer)
]

{ #category : #statistics }
CogStackPages >> statAverageLivePagesWhenMapping [
	<returnTypeC: #double>
	^statNumMaps = 0
		ifTrue: [0.0]
		ifFalse: [statPageCountWhenMappingSum asFloat / statNumMaps]
]

{ #category : #statistics }
CogStackPages >> statAverageLivePagesWhenMapping: aFloat [
	<var: #aFloat type: #double>
	aFloat == 0.0
		ifTrue: [statPageCountWhenMappingSum := statNumMaps := 0]
		ifFalse: [coInterpreter primitiveFailFor: PrimErrBadArgument]
]

{ #category : #statistics }
CogStackPages >> statMaxPageCountWhenMapping [
	<cmacro: '() GIV(statMaxPageCountWhenMapping)'>
	^statMaxPageCountWhenMapping
]

{ #category : #statistics }
CogStackPages >> statMaxPageCountWhenMapping: num [
	statMaxPageCountWhenMapping := num
]

{ #category : #'debug printing' }
CogStackPages >> whereIsMaybeStackThing: anOop [
	"If anOop is an address within the stack zone answer a string stating that, otherwise answer nil."
	<returnTypeC: 'char *'>
	self subclassResponsibility
]
