"
I am used to simulate accesses to the methodCache so it can live partly in memory, partly in a Smalltalk Array.  This is necessary because in simulation function pointers are Smalltalk symbols (under simulation primitive dispatch is done via perform:).

"
Class {
	#name : #CMethodCacheAccessor,
	#superclass : #CObjectAccessor,
	#instVars : [
		'methodCacheArray',
		'functionPointerIndex',
		'entrySize'
	],
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
CMethodCacheAccessor >> at: index [
	"The special handling of functionPointerIndex is necessary because in simulation function
	 pointers are Smalltalk symbols (under simulation primitive dispatch is done via perform:)."
	index - 1 \\ entrySize = functionPointerIndex ifTrue:
		[^methodCacheArray at: index].
	^object at: index + offset
]

{ #category : #accessing }
CMethodCacheAccessor >> at: index put: value [
	"The special handling of functionPointerIndex is necessary because in simulation function
	 pointers are Smalltalk symbols (under simulation primitive dispatch is done via perform:)."
	index - 1 \\ entrySize = functionPointerIndex ifTrue:
		[^methodCacheArray at: index put: value].
	^object at: index + offset put: value
]

{ #category : #'initialize-release' }
CMethodCacheAccessor >> memory: anObject offset: baseIndex array: cacheArray functionPointerIndex: fpIndex entrySize: esz [
	object := anObject.
	offset := baseIndex.
	methodCacheArray := cacheArray.
	functionPointerIndex := fpIndex - 1.
	entrySize := esz
]
