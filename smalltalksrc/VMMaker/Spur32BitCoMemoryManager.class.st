"
Spur32BitCoMemoryManager is a refinement of Spur32BitMemoryManager that supports the CoInterpreter/Cogit just-in-time compiler.  The signifiant difference from Spur32BitMemoryManager is the memory layout.  Spur32BitCoMemoryManager adds the cgCodeZone between newSpace and the firts oldSpace segment:

low address:
	newSpace:
		past/future survivor space
		future/past survivor space
		eden
	cogCodeZone:
		generated run-time
		cog methods
		free space
		young referrers
	first oldSpace segment
	...
	subsequent oldSpace segment
high address:

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

{ #category : #'accessing class hierarchy' }
Spur32BitCoMemoryManager class >> objectRepresentationClass [
	^CogObjectRepresentationFor32BitSpur
]

{ #category : #'simulation only' }
Spur32BitCoMemoryManager class >> simulatorClass [
	^Spur32BitMMLECoSimulator
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
Spur32BitCoMemoryManager >> ceClassAtIndex: classIndex [
	<api>
	| result |
	result := self classAtIndex: classIndex.
	self assert: (coInterpreter addressCouldBeClassObj: result).
	^result
]

{ #category : #trampolines }
Spur32BitCoMemoryManager >> ceStoreCheck: anOop [
	<api>
	"Do the store check.  Answer the argument for the benefit of the code generator;
	 ReceiverResultReg may be caller-saved and hence smashed by this call.  Answering
	 it allows the code generator to reload ReceiverResultReg cheaply."
	self assert: (self isNonImmediate: anOop).
	self assert: (self oop: anOop isGreaterThanOrEqualTo: oldSpaceStart).
	self assert: (self isRemembered: anOop) not.
	scavenger remember: anOop.
	self setIsRememberedOf: anOop to: true.
	^anOop
]

{ #category : #accessing }
Spur32BitCoMemoryManager >> checkForLeaks [
	^checkForLeaks
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

	self assert: (self isYoungObject: cogit minCogMethodAddress) not.
	self assert: (self isYoungObject: cogit maxCogMethodAddress) not.
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

{ #category : #'cog jit support' }
Spur32BitCoMemoryManager >> freeStart: aValue [
	^freeStart := aValue
]

{ #category : #'trampoline support' }
Spur32BitCoMemoryManager >> freeStartAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: freeStart) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #freeStart in: self]
]

{ #category : #'garbage collection' }
Spur32BitCoMemoryManager >> headerWhileForwardingOf: aCompiledMethodObjOop [
	"Answer the header of the argument even though
	 it may have its header word in a forwarding block
	 (which shouldn't happen with Spur)."
	self assert: (self isForwarded: aCompiledMethodObjOop) not.
	^self baseHeader: aCompiledMethodObjOop
]

{ #category : #'garbage collection' }
Spur32BitCoMemoryManager >> nullHeaderForMachineCodeMethod [
	<api>
	<returnTypeC: #sqLong>
	^(self firstLongFormat << self formatShift)
	+ (1 << self markedBitFullShift)
	+ ClassBitmapCompactIndex
]

{ #category : #'cog jit support' }
Spur32BitCoMemoryManager >> scavengeThreshold [
	^scavengeThreshold
]

{ #category : #'trampoline support' }
Spur32BitCoMemoryManager >> scavengeThresholdAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: scavengeThreshold) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #scavengeThreshold in: self]
]

{ #category : #snapshot }
Spur32BitCoMemoryManager >> setHeapBase: baseOfHeap memoryLimit: memLimit endOfMemory: memEnd [
	"Set the dimensions of the heap, answering the start of oldSpace.
	 Override to position oldSpace above the cog code zone."
	super setHeapBase: baseOfHeap memoryLimit: memLimit endOfMemory: memEnd.
	^oldSpaceStart := newSpaceLimit + coInterpreter cogCodeSize
]

{ #category : #accessing }
Spur32BitCoMemoryManager >> startOfMemory [
	"Return the start of object memory.  This is immediately after the native code zone.
	 N.B. the stack zone is alloca'ed. Use a macro so as not to punish the debug VM."
	<cmacro: '() heapBase'>
	<returnTypeC: #usqInt>
	^coInterpreter heapBase
]

{ #category : #'cog jit support' }
Spur32BitCoMemoryManager >> withoutForwardingOn: obj1 and: obj2 sendToCogit: selector [
	"For the purposes of become: send selector to the cogit with obj1 and obj2
	 and answer the result.  Undo forwarding for the selector."
	<api>
	<var: #selector declareC: 'sqInt (*selector)(sqInt,sqInt)'>
	| targetA targetB |
	targetA := self followForwarded: obj1.
	targetB := self followForwarded: obj2.
	^cogit perform: selector with: targetA with: targetB
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
