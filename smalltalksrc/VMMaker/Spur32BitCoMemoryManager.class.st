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

{ #category : #'garbage collection' }
Spur32BitCoMemoryManager >> headerWhileForwardingOf: aCompiledMethodObjOop [
	"Answer the header of the argument even though
	 it may have its header word in a forwarding block
	 (which shouldn't happen with Spur)."
	self assert: (self isForwarded: aCompiledMethodObjOop) not.
	^self baseHeader: aCompiledMethodObjOop
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
