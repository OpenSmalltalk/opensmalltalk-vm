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
	#superclass : #CogStackPages,
	#instVars : [
		'stackMemory',
		'indexOffset',
		'pageSizeInSlots'
	],
	#pools : [
		'VMBasicConstants'
	],
	#category : 'VMMaker-Interpreter'
}

{ #category : #translation }
InterpreterStackPages class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator
		var: #stackMemory type: 'char *';
		removeVariable: 'indexOffset'; "These are simulation/debugging things only"
		removeVariable: 'pageSizeInSlots' "These are simulation/debugging things only"
]

{ #category : #assertions }
InterpreterStackPages >> couldBeFramePointer: pointer [
	"Answer if the argument is a properly aligned pointer into the stack zone."
	<var: #pointer type: #'void *'>
	^self
		cCode:
			[(pointer asUnsignedInteger bitAnd: objectMemory wordSize - 1) = 0
			   and: [pointer asUnsignedInteger
						between: stackMemory asUnsignedInteger
						and: pages asUnsignedInteger]]
		inSmalltalk:
			[(pointer  bitAnd: objectMemory wordSize - 1) = 0
			 and: [(self memIndexFor: pointer)
					between: 1 and: stackMemory size]]
]

{ #category : #initialization }
InterpreterStackPages >> extraStackBytes [
	"See initializeStack:numSlots:pageSize:stackLimitOffset:stackPageHeadroom:
	``Because stack pages grow down...''"
	^self cCode: [objectMemory wordSize] inSmalltalk: [0]
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
	| numPages page structStackPageSize pageStructBase count |
	<var: #page type: #'StackPage *'>
	<var: #pageStructBase type: #'char *'>
	self cCode: ''
		inSmalltalk:
			[self assert: stackMemory size = stackSlots.
			 self assert: stackMemory == theStackPages].
	stackMemory := theStackPages. "For initialization in the C code."
	self cCode: '' inSmalltalk: [pageSizeInSlots := slotsPerPage].
	structStackPageSize := coInterpreter sizeof: CogStackPage.
	bytesPerPage := slotsPerPage * objectMemory wordSize.
	numPages := coInterpreter numStkPages.

	"Because stack pages grow down baseAddress is at the top of a stack page and so to avoid
	 subtracting BytesPerWord from baseAddress and lastAddress in the init loop below we simply
	 push the stackPage array up one word to avoid the overlap.  This word is extraStackBytes."
	pageStructBase := theStackPages + (numPages * bytesPerPage) + objectMemory wordSize.
	pages := self cCode: '(StackPage *)pageStructBase'
				  inSmalltalk:
						[pageStructBase class.
						 (1 to: numPages) collect: [:i| CogStackPage new]].

	"Simulation only.  Since addresses are negative the offset is positive.  To make all
	 stack addresses negative we make the offset a page more than it needs to be so the
	 address of the last slot in memory (the highest address in the stack, or its start) is
		- pageByteSize
	 and the address of the first slot (the lowest address, or its end) is
		- pageByteSize * (numPages + 1)"
	self cCode: '' inSmalltalk: [indexOffset := (numPages + 1) * slotsPerPage].
	"make sure there's enough headroom"
	self assert: coInterpreter stackPageByteSize - coInterpreter stackLimitBytes - coInterpreter stackLimitOffset
				>= coInterpreter stackPageHeadroom.
	0 to: numPages - 1 do:
		[:index|
		 page := self stackPageAt: index.
		 page
			lastAddress: (self cCode: '(char *)theStackPages + (index * GIV(bytesPerPage))'
							inSmalltalk: [(index * slotsPerPage - indexOffset) * objectMemory wordSize]);
			baseAddress: (page lastAddress + bytesPerPage);
			stackLimit: page baseAddress - coInterpreter stackLimitBytes;
			realStackLimit: page stackLimit;
			baseFP: 0;
			nextPage: (self stackPageAt: (index = (numPages - 1) ifTrue: [0] ifFalse: [index + 1]));
			prevPage: (self stackPageAt: (index = 0 ifTrue: [numPages - 1] ifFalse: [index - 1]))].
	self cCode: ''
		inSmalltalk:
			[| lowestAddress highestAddress |
			lowestAddress := (pages at: 1) lastAddress + objectMemory wordSize.
			highestAddress := (pages at: numPages) baseAddress.
			"see InterpreterStackPages>>longAt:"
			self assert: lowestAddress // objectMemory wordSize + indexOffset = 1.
			self assert: highestAddress // objectMemory wordSize + indexOffset = (numPages * slotsPerPage)].

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
		 self cCode: ''
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
	 self assert: (self pageIndexFor: page lastAddress + objectMemory wordSize) == theIndex.
	 (page := page nextPage) ~= mostRecentlyUsedPage] whileTrue.
	self assert: count == numPages.
	self assert: self pageListIsWellFormed
]

{ #category : #initialization }
InterpreterStackPages >> initializeWithByteSize: byteSize "<Integer>" for: anInterpreter [ "<StackInterpreter>" "^<Array of: <Integer>"
	"Initialize the stackPages memory for simulation. Answer the base address of the memory."
	<doNotGenerate>
	coInterpreter := anInterpreter.
	objectMemory := anInterpreter objectMemory.
	^stackMemory := Array new: byteSize / objectMemory wordSize withAll: 0
]

{ #category : #'memory access' }
InterpreterStackPages >> longAt: byteAddress [
	<doNotGenerate>
	"Note: Adjusted for Smalltalk's 1-based array indexing."
	self assert: (byteAddress bitAnd: objectMemory wordSize - 1) == 0.
	^stackMemory at: byteAddress // objectMemory wordSize + indexOffset
]

{ #category : #'memory access' }
InterpreterStackPages >> longAt: byteAddress put: a32BitValue [
	<doNotGenerate>
	"Note: Adjusted for Smalltalk's 1-based array indexing."
	self assert: a32BitValue isInteger.
	self assert: (byteAddress bitAnd: objectMemory wordSize - 1) == 0.
	^stackMemory at: byteAddress // objectMemory wordSize + indexOffset put: a32BitValue
]

{ #category : #'page access' }
InterpreterStackPages >> memIndexFor: byteAddress [
	"Map an address into the stack zone into a word index into the slots in the stack zone."
	<doNotGenerate>
	^(self oopForPointer: byteAddress) // objectMemory wordSize + indexOffset
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

{ #category : #'debug printing' }
InterpreterStackPages >> whereIsMaybeStackThing: anOop [
	"If anOop is an address within the stack zone answer a string stating that, otherwise answer nil."
	<returnTypeC: 'char *'>
	(self cCode:
			[self oop: anOop isGreaterThanOrEqualTo: stackMemory andLessThan: pages]
		 inSmalltalk:
			[(self memIndexFor: anOop) between: 1 and: stackMemory size]) ifTrue:
		[^' is in the stack zone'].
	^nil
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
