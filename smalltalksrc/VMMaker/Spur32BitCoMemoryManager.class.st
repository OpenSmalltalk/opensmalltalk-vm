"
Spur32BitCoMemoryManager is a refinement of Spur32BitMemoryManager that supports the CoInterpreter/Cogit just-in-time compiler.  The significant difference from Spur32BitMemoryManager is the memory layout.  Spur32BitCoMemoryManager adds the cogCodeZone beneath newSpace:

low address:
	cogCodeZone:
		generated run-time
		cog methods
		free space
		young referrers
	newSpace:
		past/future survivor space
		future/past survivor space
		eden
	first oldSpace segment
	...
	subsequent oldSpace segment
high address:

It would be convenient if the code zone were placed between newSpace and oldSpace; then Cog methods could be onsidered neither old nor young, filtering them out of copyAndForward: and the store check with single bounds checks.  But the CoInterpreter already assumes Cog methods are less than all objects (e.g. in its isMachineCodeFrame:).  If the dynamic frequency of isMachineCodeFrame: is higher (likely because this is used in e.g. scanning for unwind protects in non-local return) then it should keep the single bounds check.  So the coder zone remains beneath newSpace and Spur32BitCoMemoryManager ocerrides isReallyYoungObject: to filter-out Cog methods for copyAndForward:.

Instance Variables
	cogit:		<SimpleStackBasedCogit or subclass>

cogit
	- the just-in-time compiler
"
Class {
	#name : #Spur32BitCoMemoryManager,
	#superclass : #Spur32BitMemoryManager,
	#instVars : [
		'cogit'
	],
	#pools : [
		'CogMethodConstants'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #simulation }
Spur32BitCoMemoryManager class >> defaultISA [
	"Answer the default instruction set architecture to use for simulation."
	^#IA32
]

{ #category : #'accessing class hierarchy' }
Spur32BitCoMemoryManager class >> objectRepresentationClass [
	^CogObjectRepresentationFor32BitSpur
]

{ #category : #simulation }
Spur32BitCoMemoryManager class >> simulatorClass [
	^ Spur32BitMMLECoSimulator
]

{ #category : #'growing/shrinking memory' }
Spur32BitCoMemoryManager >> assimilateNewSegment: segInfo [
	"Update after adding a segment.
	 Here we make sure the new segment is not executable."
	<var: #segInfo type: #'SpurSegmentInfo *'>
	super assimilateNewSegment: segInfo.
	coInterpreter sqMakeMemoryNotExecutableFrom: segInfo segStart To: segInfo segLimit
]

{ #category : #trampolines }
Spur32BitCoMemoryManager >> ceScheduleScavenge [
	<api>
	self assert: freeStart >= scavengeThreshold.
	self scheduleScavenge
]

{ #category : #'debug support' }
Spur32BitCoMemoryManager >> checkMemoryMap [
	"Override to check that Cog methods are considered neither young nor old.
	 Being young would cause them to be scavenged.
	 Being old would cause them to be remembered if stored into (but wait, they don't get stored into)."

	self assert: (self isYoungObject: newSpaceStart).
	self assert: (self isYoungObject: newSpaceLimit - self wordSize).
	self assert: (self isOldObject: newSpaceStart) not.
	self assert: (self isOldObject: newSpaceLimit - self wordSize) not.
	self assert: (self isYoungObject: newSpaceLimit) not.
	self assert: (self isYoungObject: oldSpaceStart) not.
	self assert: (self isYoungObject: endOfMemory) not.
	self assert: (self isOldObject: oldSpaceStart).
	self assert: (self isOldObject: endOfMemory).

	"we would like the following to be true, but we either choose one boundary check for
	 cogMethods vs objects (isMachineCodeFrame: et al) or one boundary check for
	 copyAndForward:.  We can't have both, and the former is likely the highest dynamic
	 frequency."
	false ifTrue:
		[self assert: (self isYoungObject: cogit minCogMethodAddress) not.
		 self assert: (self isYoungObject: cogit maxCogMethodAddress) not].
	self assert: (self isOldObject: cogit minCogMethodAddress) not.
	self assert: (self isOldObject: cogit maxCogMethodAddress) not
]

{ #category : #'debug support' }
Spur32BitCoMemoryManager >> clearLeakMapAndMapAccessibleObjects [
	"Perform an integrity/leak check using the heapMap.  Set a bit at each object's header.
	 Override to set a bit at each Cog method"
	super clearLeakMapAndMapAccessibleObjects.
	cogit addCogMethodsToHeapMap
]

{ #category : #accessing }
Spur32BitCoMemoryManager >> cogit: aCogit [ 
	<doNotGenerate>
	cogit := aCogit
]

{ #category : #'cog jit support' }
Spur32BitCoMemoryManager >> ensureNoForwardedLiteralsIn: aMethodObj [
	"Ensure there are no forwarded literals in the argument."
	<api>
	self followForwardedObjectFields: aMethodObj toDepth: 0
]

{ #category : #'cog jit support' }
Spur32BitCoMemoryManager >> freeStart: aValue [
	self assert: (aValue >= scavenger eden start and: [aValue < (scavengeThreshold + 1024)]).
	self assert: (scavengeThreshold max: aValue) + coInterpreter interpreterAllocationReserveBytes <= scavenger eden limit.
	^freeStart := aValue
]

{ #category : #'trampoline support' }
Spur32BitCoMemoryManager >> freeStartAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: freeStart) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #freeStart in: self]
]

{ #category : #'cog jit support' }
Spur32BitCoMemoryManager >> getScavengeThreshold [
	<api>
	<returnTypeC: #usqInt>
	^scavengeThreshold
]

{ #category : #'garbage collection' }
Spur32BitCoMemoryManager >> headerWhileForwardingOf: aCompiledMethodObjOop [
	"Answer the header of the argument even though
	 it may have its header word in a forwarding block
	 (which shouldn't happen with Spur)."
	self assert: (self isForwarded: aCompiledMethodObjOop) not.
	^self baseHeader: aCompiledMethodObjOop
]

{ #category : #'image segment in/out' }
Spur32BitCoMemoryManager >> ifAProxy: objOop updateCopy: copy [
	"If the object being copied to the segment is weird and has exotic state,
	 i.e. a married context or a jitted method, update the copy with the vanilla state."

	super ifAProxy: objOop updateCopy: copy.
	(self isCompiledMethod: objOop) ifTrue:
		[| methodHeader |
		 methodHeader := coInterpreter rawHeaderOf: objOop.
		 (coInterpreter isCogMethodReference: methodHeader) ifTrue:
			[self storePointerUnchecked: HeaderIndex
				ofObject: copy
				withValue: (coInterpreter cCoerceSimple: methodHeader to: #'CogMethod *') methodHeader]]
]

{ #category : #'simulation only' }
Spur32BitCoMemoryManager >> initializeFreeSpaceForFacadeFrom: base to: limit [
	"c.f. initializeFreeSpacePostLoad: freeListObj."
	| freeListObj freeBytes |
	newSpaceLimit := oldSpaceStart := freeStart := base.
	endOfMemory := limit.
	scavengeThreshold := limit * 3 // 4.
	segmentManager initSegmentForInImageCompilationFrom: base to: limit.
	freeListObj := self allocateSlots: self numFreeLists
						format: self wordIndexableFormat
						classIndex: self wordSizeClassIndexPun.
	freeLists := self firstIndexableField: freeListObj.
	freeListsMask := 0.
	0 to: self numFreeLists - 1 do:
		[:i|
		(freeLists at: i) ~= 0 ifTrue:
			[freeListsMask := freeListsMask bitOr: (1 << i).
			 freeLists at: i put: (segmentManager swizzleObj: (freeLists at: i))]].
	freeBytes := segmentManager lastSegment segLimit - self bridgeSize - freeStart.
	freeLists at: 0 put: (self initFreeChunkWithBytes: freeBytes at: freeStart).
	totalFreeOldSpace := freeBytes
]

{ #category : #'class table' }
Spur32BitCoMemoryManager >> isForwardedClassIndex: maybeClassIndex [
	"A lenient tester of forwarded class indices for inline cache management in the Cogit."
	<api>
	| classTablePage entry |
	maybeClassIndex asUnsignedInteger >= self classTableRootSlots ifTrue:
		[^false].
	classTablePage := self fetchPointer: maybeClassIndex >> self classTableMajorIndexShift
							ofObject: hiddenRootsObj.
	classTablePage = nilObj ifTrue:
		[^false].
	entry := self
				fetchPointer: (maybeClassIndex bitAnd: self classTableMinorIndexMask)
				ofObject: classTablePage.
	^self isForwarded: entry
]

{ #category : #'cog jit support' }
Spur32BitCoMemoryManager >> isImmediateClass: classObj [
	<api>
	^(self instSpecOfClass: classObj) = self instSpecForImmediateClasses
]

{ #category : #'object testing' }
Spur32BitCoMemoryManager >> isReallyYoungObject: objOop [
	<api>
	"Answer if obj is young. Require that obj is non-immediate. Override to filter-out Cog methods"
	self assert: (self isNonImmediate: objOop).
	^(self oop: objOop isLessThan: newSpaceLimit)
	  and: [self oop: objOop isGreaterThanOrEqualTo: newSpaceStart]
]

{ #category : #compaction }
Spur32BitCoMemoryManager >> methodHeaderFromSavedFirstField: field [
	(self isIntegerObject: field) ifTrue:
		[^field].
	self assert: ((self isNonImmediate: field) and: [field < newSpaceStart]).
	self assert: (coInterpreter cCoerceSimple: field to: #'CogMethod *') objectHeader
				= self nullHeaderForMachineCodeMethod.
	^(coInterpreter cCoerceSimple: field to: #'CogMethod *') methodHeader
]

{ #category : #'growing/shrinking memory' }
Spur32BitCoMemoryManager >> methodHeaderOf: methodObj [
	"Answer the method header of a CompiledMethod object.
	 If the method has been cogged then the header is a pointer to
	 the CogMethod and the real header will be stored in the CogMethod."
	<api>
	<inline: true>
	| header |
	self assert: (self isCompiledMethod: methodObj).
	header := self fetchPointer: HeaderIndex ofObject: methodObj.
	^(self isIntegerObject: header)
		ifTrue: [header]
		ifFalse:
			[self assert: header asUnsignedInteger < newSpaceStart.
			 self assert: (coInterpreter cCoerceSimple: header to: #'CogMethod *') objectHeader
						= self nullHeaderForMachineCodeMethod.
			(coInterpreter cCoerceSimple: header to: #'CogMethod *') methodHeader]
]

{ #category : #'trampoline support' }
Spur32BitCoMemoryManager >> needGCFlagAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: needGCFlag) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #needGCFlag in: self]
]

{ #category : #'garbage collection' }
Spur32BitCoMemoryManager >> nullHeaderForMachineCodeMethod [
	<api>
	<returnTypeC: #sqLong>
	^(self firstLongFormat << self formatShift)
	+ (1 << self markedBitFullShift)
	+ ClassBitmapCompactIndex
]

{ #category : #'object enumeration' }
Spur32BitCoMemoryManager >> objectBytesForSlots: numSlots [
	"Answer the total number of bytes in an object with the given
	 number of slots, including header and possible overflow size header."
	<api>
	<option: #SistaVM>
	^super objectBytesForSlots: numSlots
]

{ #category : #'cog jit support' }
Spur32BitCoMemoryManager >> receiverTagBitsForMethod: aMethodObj [
	"Answer the tag bits for the receiver based on the method's methodClass, if any."
	<api>
	| methodClassOrNil |
	methodClassOrNil := coInterpreter methodClassOf: aMethodObj.
	(methodClassOrNil = nilObj
			 or: [(self instSpecOfClass: methodClassOrNil) ~= self forwardedFormat]) ifTrue:
				[^0].
	^methodClassOrNil = (self fetchPointer: self smallIntegerTag ofObject: classTableFirstPage)
		ifTrue: [self smallIntegerTag]
		ifFalse: [self assert: methodClassOrNil = (self fetchPointer: self characterTag ofObject: classTableFirstPage).
				self characterTag]
]

{ #category : #'cog jit support' }
Spur32BitCoMemoryManager >> remember: objOop [
	<doNotGenerate>
	^scavenger remember: objOop
]

{ #category : #'trampoline support' }
Spur32BitCoMemoryManager >> scavengeThresholdAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: scavengeThreshold) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #getScavengeThreshold in: self]
]

{ #category : #'cog jit support' }
Spur32BitCoMemoryManager >> smallIntegerTag [
	"Beware, SmallInteger tags are 1 or 3.  But SmallInteger's identityHash is 1."
	<api>
	<cmacro>
	^1
]

{ #category : #accessing }
Spur32BitCoMemoryManager >> startOfMemory [
	"Return the start of object memory.  This is immediately after the native code zone.
	 N.B. the stack zone is alloca'ed. Use a macro so as not to punish the debug VM."
	<api>
	<cmacro: '() heapBase'>
	<returnTypeC: #usqInt>
	^coInterpreter heapBase
]

{ #category : #'simulation only' }
Spur32BitCoMemoryManager >> unalignedLongAt: byteAddress [
	<doNotGenerate>
	| rem |
	rem := byteAddress \\ 4.
	^rem = 0
		ifTrue: [self longAt: byteAddress]
		ifFalse: [((self longAt: byteAddress - rem) + ((self longAt: byteAddress - rem + 4) bitShift: 32) bitShift: rem * -8) bitAnd: 16rFFFFFFFF]
]

{ #category : #'simulation only' }
Spur32BitCoMemoryManager >> unalignedLongAt: byteAddress put: aLong [
	<doNotGenerate>
	| rem mask |
	rem := byteAddress \\ 4.
	^rem = 0
		ifTrue: [self longAt: byteAddress put: aLong]
		ifFalse:
			[mask := 16rFFFFFFFF bitAnd: (-1 bitShift: rem * 8).
			 self longAt: byteAddress - rem
				put: ((self longAt: byteAddress - rem) bitAnd: mask bitInvert)
					+ ((aLong bitShift: rem * 8) bitAnd: mask).
			 self longAt: byteAddress - rem + 4
				put: ((self longAt: byteAddress - rem + 4) bitAnd: mask)
					+ ((aLong bitShift: 4 - rem * -8) bitAnd: mask bitInvert).
			 aLong]
]

{ #category : #'cog jit support' }
Spur32BitCoMemoryManager >> withoutForwardingOn: obj1 and: obj2 with: aBool sendToCogit: selector [
	"For the purposes of become: send selector to the cogit with obj1, obj2
	 and aBool and answer the result.  Undo forwarding for the selector."
	<api>
	<var: #selector declareC: 'sqInt (*selector)(sqInt,sqInt,sqInt)'>
	| targetA targetB |
	targetA := self followForwarded: obj1.
	targetB := self followForwarded: obj2.
	^cogit perform: selector with: targetA with: targetB with: aBool
]
