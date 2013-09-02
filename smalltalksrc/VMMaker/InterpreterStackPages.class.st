"
I am a class that helps organize the StackInterpreter's collection of stack pages.  I hold the set of stack pages represented by InterpreterStackPage instances/StackPage structs.  The pages are held in a doubly-linked list that notionally has two heads:

mostRecentlyUsedPage-->used page<->used page<->used page<->used page<--leastRecentlyUsedPage
                                       ^                        <-next-prev->                         ^
                                        |                                                                       |
                                        v                        <-prev-next->                         v
                                        free page<->free page<->free page<->free page

In fact we don't need the least-recently-used page, and so it is only present conceptually.  The point is that there is a possibly empty but contiguous sequence of free pages starting at mostRecentlyUsedPage nextPage.  New pages are allocated preferentially from the free page next to the MRUP.
If there are no free pages then (effectively) the LRUP's frames are flushed to contexts and it is used instead.
"
Class {
	#name : #InterpreterStackPages,
	#superclass : #VMClass,
	#instVars : [
		'interpreter',
		'stackMemory',
		'indexOffset',
		'pages',
		'mostRecentlyUsedPage',
		'overflowLimit',
		'numPages',
		'pageSizeInSlots',
		'bytesPerPage'
	],
	#pools : [
		'VMBasicConstants'
	],
	#category : #'VMMaker-Interpreter'
}

{ #category : #translation }
InterpreterStackPages class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator
		var: #stackMemory type: 'char *';
		var: #mostRecentlyUsedPage type: 'StackPage *';
		var: #pages type: 'StackPage *'.
	aCCodeGenerator	"These are simulation/debugging things only"
		removeVariable: 'interpreter';
		removeVariable: 'indexOffset';
		removeVariable: 'pageSizeInSlots';
		removeMethodForSelector: #memIndexFor:
]

{ #category : #assertions }
InterpreterStackPages >> allPagesFree [
	<doNotGenerate>
	^pages allSatisfy: [:page| (self isFree: page)]
]

{ #category : #'memory access' }
InterpreterStackPages >> byteAt: byteAddress [ "<Integer>" 
	self subclassResponsibility
]

{ #category : #assertions }
InterpreterStackPages >> couldBeFramePointer: pointer [
	"Answer if the argument is a properly aligned pointer into the stack zone."
	<var: #pointer type: #'void *'>
	^self
		cCode:
			[(pointer asUnsignedInteger bitAnd: BytesPerWord - 1) = 0
			   and: [pointer asUnsignedInteger
						between: stackMemory asUnsignedInteger
						and: pages asUnsignedInteger]]
		inSmalltalk:
			[(pointer  bitAnd: BytesPerWord - 1) = 0
			 and: [(self memIndexFor: pointer)
					between: 1 and: stackMemory size]]
]

{ #category : #initialization }
InterpreterStackPages >> extraStackBytes [
	"See initializeStack:numSlots:pageSize:stackLimitOffset:stackPageHeadroom:
	``Because stack pages grow down...''"
	^self cCode: 'BytesPerWord' inSmalltalk: [0]
]

{ #category : #'page access' }
InterpreterStackPages >> freeStackPage: aPage [ "<InterpreterStackPage>"
	"MRUP-->used page<->used page<->used page<->used page<--LRUP
	               ^                        <-next-prev->                         ^
	                |                                                                       |
	                v                        <-prev-next->                         v
	                free page<->free page<->free page<->free page"
	<var: #aPage type: #'StackPage *'>
	self freeStackPageNoAssert: aPage.
	self assert: self pageListIsWellFormed
]

{ #category : #'page access' }
InterpreterStackPages >> freeStackPageNoAssert: aPage [ "<InterpreterStackPage>"
	"MRUP-->used page<->used page<->used page<->used page<--LRUP
	               ^                        <-next-prev->                         ^
	                |                                                                       |
	                v                        <-prev-next->                         v
	                free page<->free page<->free page<->free page"
	| prev |
	<var: #aPage type: #'StackPage *'>
	<var: #prev type: #'StackPage *'>
	aPage baseFP: 0.
	aPage == mostRecentlyUsedPage ifTrue:
		[mostRecentlyUsedPage := mostRecentlyUsedPage prevPage.
		 ^nil].
	"lack of type inferrence means ``self isFree: aPage prevPage''
	 isn't turned into a direct field test; sigh..."
	prev := aPage prevPage.
	(self isFree: prev) ifTrue:
		[^nil].
	prev nextPage: aPage nextPage.
	aPage nextPage prevPage: prev.
	aPage nextPage: mostRecentlyUsedPage nextPage.
	mostRecentlyUsedPage nextPage prevPage: aPage.
	aPage prevPage: mostRecentlyUsedPage.
	mostRecentlyUsedPage nextPage: aPage
]

{ #category : #initialization }
InterpreterStackPages >> initializeStack: theStackPages numSlots: stackSlots pageSize: slotsPerPage [
	"Initialize the stack pages.  For testing I want stack addresses to be disjoint from
	 normal memory addresses so stack addresses are negative.  The first address is
	 -pageSize bytes.  So for example if there are 1024 bytes per page and 3 pages
	 then the pages are organized as

		byte address: -1024 <-> -2047 | -2048 <-> -3071 | -3072 <-> -4096 |
							page 3			page 2			page 1
		mem index:        769 <-> 513  |     512 <->  257  |   256 <->        1 |

	 The byte address is the external address corresponding to a real address in the VM.
	 mem index is the index in the memory Array holding the stack, an index internal to
	 the stack pages.  The first stack page allocated will be the last page in the array of pages
	 at the highest effective address.  Its base address be -1024  and grow down towards -2047."

	"The lFoo's are to get around the foo->variable scheme in the C call to allocStackPages below."
	<var: #theStackPages type: #'char *'>
	| page structStackPageSize pageStructBase count |
	<var: #page type: #'StackPage *'>
	<var: #pageStructBase type: #'char *'>
	self cCode: ''
		inSmalltalk:
			[self assert: stackMemory size = stackSlots.
			 self assert: stackMemory == theStackPages].
	stackMemory := theStackPages. "For initialization in the C code."
	self cCode: '' inSmalltalk: [pageSizeInSlots := slotsPerPage].
	structStackPageSize := interpreter sizeof: InterpreterStackPage.
	bytesPerPage := slotsPerPage * BytesPerWord.
	numPages := stackSlots // (slotsPerPage + (structStackPageSize / BytesPerWord)).

	"Because stack pages grow down baseAddress is at the top of a stack page and so to avoid
	 subtracting BytesPerWord from baseAddress and lastAddress in the init loop below we simply
	 push the stackPage array up one word to avoid the overlap.  This word is extraStackBytes."
	pageStructBase := theStackPages + (numPages * bytesPerPage) + BytesPerWord.
	pages := self cCode: '(StackPage *)pageStructBase'
				  inSmalltalk:
						[pageStructBase class.
						 (1 to: numPages) collect: [:i| InterpreterStackPage new]].

	"Simulation only.  Since addresses are negative the offset is positive.  To make all
	 stack addresses negative we make the offset a page more than it needs to be so the
	 address of the last slot in memory (the highest address in the stack, or its start) is
		- pageByteSize
	 and the address of the first slot (the lowest address, or its end) is
		- pageByteSize * (numPages + 1)"
	self cCode: '' inSmalltalk: [indexOffset := (numPages + 1) * slotsPerPage].
	"make sure there's enough headroom"
	self assert: interpreter stackPageByteSize - interpreter stackLimitBytes - interpreter stackLimitOffset
				>= interpreter stackPageHeadroom.
	0 to: numPages - 1 do:
		[:index|
		 page := self stackPageAt: index.
		 page
			lastAddress: (self cCode: '(char *)theStackPages + (index * GIV(bytesPerPage))'
							inSmalltalk: [(index * slotsPerPage - indexOffset) * BytesPerWord]);
			baseAddress: (page lastAddress + bytesPerPage);
			stackLimit: page baseAddress - interpreter stackLimitBytes;
			realStackLimit: page stackLimit;
			baseFP: 0;
			nextPage: (self stackPageAt: (index = (numPages - 1) ifTrue: [0] ifFalse: [index + 1]));
			prevPage: (self stackPageAt: (index = 0 ifTrue: [numPages - 1] ifFalse: [index - 1]))].
	self cCode: ''
		inSmalltalk:
			[| lowestAddress highestAddress |
			lowestAddress := (pages at: 1) lastAddress + BytesPerWord.
			highestAddress := (pages at: numPages) baseAddress.
			"see InterpreterStackPages>>longAt:"
			self assert: lowestAddress // BytesPerWord + indexOffset = 1.
			self assert: highestAddress // BytesPerWord + indexOffset = (numPages * slotsPerPage)].

	"The overflow limit is the amount of stack to retain when moving frames from an overflowing
	 stack to reduce thrashing.  See stackOverflowOrEvent:mayContextSwitch:"
	page := self stackPageAt: 0.
	overflowLimit := page baseAddress - page realStackLimit * 3 // 5.

	0 to: numPages - 1 do:
		[:index|
		 page := self stackPageAt: index.
		 self assert: (self pageIndexFor: page baseAddress) == index.
		 self assert: (self pageIndexFor: page baseAddress - (slotsPerPage - 1 * BytesPerWord)) == index.
		 self assert: (self stackPageFor: page baseAddress) == page.
		 self assert: (self stackPageFor: page stackLimit) == page.
		 self cCode: ''
			inSmalltalk:
				[| memIndex |
				 memIndex := index * slotsPerPage + 1. "this is memIndex in the block above"
				 self assert: (self memIndexFor: (self oopForPointer: page baseAddress))
							== (memIndex + slotsPerPage - 1).
				 index < (numPages - 1) ifTrue:
					[self assert: (self stackPageFor: page baseAddress + BytesPerWord) == (self stackPageAt: index + 1)]].
		self assert: (page trace: -1) ~= 0 "for assert checking of the page tracing flags. -1 == invalid state"].

	mostRecentlyUsedPage := self stackPageAt: 0.
	page := mostRecentlyUsedPage.
	count := 0.
	[| theIndex |
	 count := count + 1.
	 theIndex := self pageIndexFor: page baseAddress.
	 self assert: (self stackPageAt: theIndex) == page.
	 self assert: (self pageIndexFor: page baseAddress) == theIndex.
	 self assert: (self pageIndexFor: page stackLimit) == theIndex.
	 self assert: (self pageIndexFor: page lastAddress + BytesPerWord) == theIndex.
	 (page := page nextPage) ~= mostRecentlyUsedPage] whileTrue.
	self assert: count == numPages.
	self assert: self pageListIsWellFormed
]

{ #category : #initialization }
InterpreterStackPages >> initializeWithByteSize: byteSize "<Integer>" for: anInterpreter [ "<StackInterpreter>" "^<Array of: <Integer>"
	"Initialize the stackPages memory for simulation."
	<doNotGenerate>
	interpreter := anInterpreter.
	^stackMemory := Array new: byteSize / BytesPerWord withAll: 0
]

{ #category : #'page access' }
InterpreterStackPages >> isFree: thePage [
	"This is an anachronism.  Previously Slang couldn't generate the method correctly
	 from e.g. InterpreterStackPage>>isFree since Slang didn't do substitution on self.
	 Now it does, but there are still callers of isFree: so we keep this for simulation."
	<doNotGenerate>
	^thePage baseFP = 0
]

{ #category : #'memory access' }
InterpreterStackPages >> longAt: byteAddress [
	"Note: Adjusted for Smalltalk's 1-based array indexing."
	self assert: (byteAddress bitAnd: BytesPerWord - 1) == 0.
	^stackMemory at: byteAddress // BytesPerWord + indexOffset
]

{ #category : #'memory access' }
InterpreterStackPages >> longAt: byteAddress put: a32BitValue [
	"Note: Adjusted for Smalltalk's 1-based array indexing."
	self assert: (byteAddress bitAnd: BytesPerWord - 1) == 0.
	^stackMemory at: byteAddress // BytesPerWord + indexOffset put: a32BitValue
]

{ #category : #'page access' }
InterpreterStackPages >> markStackPageLeastMostRecentlyUsed: page [ "<InterpreterStackPage>"
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
InterpreterStackPages >> markStackPageMostRecentlyUsed: page [ "<InterpreterStackPage>"
	"MRUP-->used page<->used page<->used page<->used page<--LRUP
	               ^                        <-next-prev->                         ^
	                |                                                                       |
	                v                        <-prev-next->                         v
	                free page<->free page<->free page<->free page"
	<var: #page type: #'StackPage *'>
	<asmLabel: false>
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
InterpreterStackPages >> markStackPageNextMostRecentlyUsed: page [ "<InterpreterStackPage>"
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
InterpreterStackPages >> memIndexFor: byteAddress [
	^(self oopForPointer: byteAddress) // BytesPerWord + indexOffset
]

{ #category : #'page access' }
InterpreterStackPages >> mostRecentlyUsedPage [
	<cmacro: '() GIV(mostRecentlyUsedPage)'>
	<returnTypeC: #'StackPage *'> "this is to guide Slang's inliner"
	^mostRecentlyUsedPage
]

{ #category : #'page access' }
InterpreterStackPages >> overflowLimit [
	^overflowLimit
]

{ #category : #'page access' }
InterpreterStackPages >> pageIndexFor: pointer [ "<Integer>"
	"Answer the page index for a pointer into stack memory, i.e. the index
	 for the page the address is in.  N.B.  This is a zero-relative index."
	<var: #pointer type: #'void *'>
	^self pageIndexFor: pointer stackMemory: stackMemory bytesPerPage: bytesPerPage
]

{ #category : #'page access' }
InterpreterStackPages >> pageIndexFor: pointer "<Integer>" stackMemory: stackmem "<Integer>" bytesPerPage: pageByteSize [ "<Integer>"
	"Answer the page index for a pointer into stack memory, i.e. the index
	 for the page the address is in.  N.B.  This is a zero-relative index."
	| memIndex |
	<cmacro: '(pointer,stackmem,pageByteSize) (((char *)(pointer) - (stackmem) - 1) / (pageByteSize))'>
	memIndex := self memIndexFor: pointer.
	self assert: (memIndex between: 1 and: stackMemory size).
	^memIndex - 1 // pageSizeInSlots
]

{ #category : #assertions }
InterpreterStackPages >> pageListIsWellFormed [
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
	limit := numPages * 2.
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
				[(self asserta: (self stackPageFor: page baseFP) == page) ifFalse:
					[ok := false].
				 (self asserta: (self stackPageFor: page headSP) == page) ifFalse:
					[ok := false]]
			ifFalse:
				[ok := false].
		 page := page nextPage.
		 count := count + 1].
	(self asserta: count = numPages) ifFalse:
		[ok := false].
	^ok
]

{ #category : #assertions }
InterpreterStackPages >> somePageHasHeadFrameFP: theFP [
	<doNotGenerate>
	^pages anySatisfy: [:page| page headFP = theFP]

]

{ #category : #'page access' }
InterpreterStackPages >> stackPageAt: index [
	"Answer the page for a page index.
	 N.B.  This is a zero-relative index."
	<returnTypeC: #'StackPage *'>
	^self stackPageAt: index pages: pages
]

{ #category : #'page access' }
InterpreterStackPages >> stackPageAt: index pages: thePages [
	"Answer the page for a page index.
	 N.B.  This is a zero-relative index."
	<cmacro: '(index,pages) ((pages) + (index))'>
	<returnTypeC: #'StackPage *'> "for Slang..."
	^thePages at: index + 1
]

{ #category : #initialization }
InterpreterStackPages >> stackPageClass [
	<doNotGenerate>
	^InterpreterStackPage
]

{ #category : #'page access' }
InterpreterStackPages >> stackPageFor: pointer [ "<Integer>"
	<inline: true>
	<var: #pointer type: #'void *'>
	<returnTypeC: #'StackPage *'>
	^self stackPageAt: (self pageIndexFor: pointer)
]

{ #category : #'memory access' }
InterpreterStackPages >> writeEnableMemory [
	<doNotGenerate>
	stackMemory := stackMemory array
]

{ #category : #'memory access' }
InterpreterStackPages >> writeProtectMemory [
	<doNotGenerate>
	stackMemory := ReadOnlyArrayWrapper around: stackMemory
]
