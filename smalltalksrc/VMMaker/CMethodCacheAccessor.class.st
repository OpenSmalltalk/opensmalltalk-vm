"
I am used to simulate accesses to the methodCache so it can live partly in memory, partly in a Smalltalk Array.  This is necessary because in simulation function pointers are Smalltalk symbols (under simulation primitive dispatch is done via perform:).

"
Class {
	#name : #CMethodCacheAccessor,
	#superclass : #CArrayOfLongsAccessor,
	#instVars : [
		'methodCacheArray',
		'entrySize',
		'functionPointerIndex'
	],
	#category : 'VMMaker-JITSimulation'
}

{ #category : #accessing }
CMethodCacheAccessor >> at: index [
	"The special handling of functionPointerIndex is necessary because in simulation function
	 pointers are Smalltalk symbols (under simulation primitive dispatch is done via perform:)."
	index - 1 \\ entrySize = functionPointerIndex ifTrue:
		[^methodCacheArray at: index].
	^objectMemory longAt: index * elementByteSize + address
]

{ #category : #accessing }
CMethodCacheAccessor >> at: index put: value [
	"The special handling of functionPointerIndex is necessary because in simulation function
	 pointers are Smalltalk symbols (under simulation primitive dispatch is done via perform:)."
	(index = 16r44F and: [value = 16r1D]) ifTrue:
		[self halt].
	index - 1 \\ entrySize = functionPointerIndex ifTrue:
		[objectMemory longAt: index * elementByteSize + address put: (0 = value ifTrue: [value] ifFalse: [value identityHash]).
		 ^methodCacheArray at: index put: value].
	^objectMemory longAt: index * elementByteSize + address put: value
]

{ #category : #'initialize-release' }
CMethodCacheAccessor >> objectMemory: anObjectMemory at: anAddress array: cacheArray functionPointerIndex: fpIndex entrySize: wordsPerCacheEntry [
	self objectMemory: anObjectMemory
		at: anAddress - anObjectMemory wordSize. "implicit -1 for indices in at:[put:]; the MethodCache is one-relative"
	methodCacheArray := cacheArray.
	functionPointerIndex := fpIndex - 1.
	entrySize := wordsPerCacheEntry
]
