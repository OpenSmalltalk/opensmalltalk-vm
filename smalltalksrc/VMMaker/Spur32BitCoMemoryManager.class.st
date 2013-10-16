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
	self assert: (self oop: anOop isGreaterThan: newSpaceLimit).
	self assert: (self isRemembered: anOop) not.
	scavenger remember: anOop.
	self setIsRememberedOf: anOop to: true.
	^anOop
]

{ #category : #'debug support' }
Spur32BitCoMemoryManager >> clearLeakMapAndMapAccessibleObjects [
	"Perform an integrity/leak check using the heapMap.  Set a bit at each object's header.
	 Override to set a bit at each Cog method"
	super clearLeakMapAndMapAccessibleObjects.
	cogit addCogMethodsToHeapMap
]

{ #category : #snapshot }
Spur32BitCoMemoryManager >> edenBytes: edenBytes [
	newSpaceLimit := edenBytes + coInterpreter cogCodeSize
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

{ #category : #'growing/shrinking memory' }
Spur32BitCoMemoryManager >> growOldSpaceByAtLeast: minAmmount [
	"Attempt to grow memory by at least minAmmount.
	 Answer the size of the new segment, or nil if the attempt failed.
	 Override to remove execute permission from the new segment."
	| ammount |
	<var: #segInfo type: #'SpurSegmentInfo *'>
	statGrowMemory := statGrowMemory + 1.
	ammount := minAmmount max: growHeadroom.
	^(segmentManager addSegmentOfSize: ammount) ifNotNil:
		[:segInfo|
		 freeOldSpaceStart :=
		 endOfMemory := segInfo segStart + segInfo segSize - self bridgeSize.
		 coInterpreter sqMakeMemoryNotExecutableFrom: segInfo segStart To: segInfo segStart + segInfo segSize.
		 segInfo segSize]
]

{ #category : #'garbage collection' }
Spur32BitCoMemoryManager >> headerWhileForwardingOf: aCompiledMethodObjOop [
	"Answer the header of the argument even though
	 it may have its header word in a forwarding block
	 (which shouldn't happen with Spur)."
	self assert: (self isForwarded: aCompiledMethodObjOop) not.
	^self baseHeader: aCompiledMethodObjOop
]

{ #category : #accessing }
Spur32BitCoMemoryManager >> newSpaceBytes [
	"during snapshot load newSpaceLimit holds newSpace size + cogCodeSize temporarily."
	^newSpaceLimit - coInterpreter cogCodeSize - coInterpreter interpreterAllocationReserveBytes
]

{ #category : #'trampoline support' }
Spur32BitCoMemoryManager >> newSpaceLimitAddress [
	<api>
	<returnTypeC: #usqInt>
	^self cCode: [(self addressOf: newSpaceLimit) asUnsignedInteger]
		inSmalltalk: [cogit simulatedReadWriteVariableAddress: #newSpaceLimit in: self]
]

{ #category : #'garbage collection' }
Spur32BitCoMemoryManager >> nullHeaderForMachineCodeMethod [
	<api>
	^self firstLongFormat << self formatShift + ClassBitmapCompactIndex
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
