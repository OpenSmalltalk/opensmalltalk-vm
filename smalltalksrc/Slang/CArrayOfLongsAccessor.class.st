"
A CArrayOfLongsAccessor is a class that wraps an Array stored in the heap.  It maps at:[put:] into a suitably aligned and offset longAt:[put:], for accessing Arrays stored in the heap, such as the primTraceLog.

Instance Variables
	address:			<Integer>
	entryByteSize:		<Integer>
	objectMemory:		<NewCoObjectMemorySimulator|Spur64BitMMLECoSimulator|Spur64BitMMLECoSimulator|Spur64BitMMBECoSimulator|Spur64BitMMBECoSimulator>

address
	- the base address in the heap of the start of the array

entryByteSize
	- the size of an element, in bytes

objectMemory
	- the memory manager whose heap is being accessed

"
Class {
	#name : #CArrayOfLongsAccessor,
	#superclass : #CObjectAccessor,
	#instVars : [
		'objectMemory',
		'address',
		'elementByteSize'
	],
	#category : #'Slang-Types'
}

{ #category : #accessing }
CArrayOfLongsAccessor >> address [
	^address
]

{ #category : #accessing }
CArrayOfLongsAccessor >> at: index [
	"Map at: into a suitably aligned and offset longAt:, for accessing Arrays stored in the heap, such as the primTraceLog."
	^objectMemory longAt: index * elementByteSize + address
]

{ #category : #accessing }
CArrayOfLongsAccessor >> at: index put: aValue [
	"Map at:put: into a suitably aligned and offset longAt:put:, for accessing Arrays stored in the heap, such as the primTraceLog."
	^objectMemory longAt: index * elementByteSize + address put: aValue
]

{ #category : #'initialize-release' }
CArrayOfLongsAccessor >> objectMemory: anObjectMemory at: anAddress [
	objectMemory := anObjectMemory.
	object := anObjectMemory memory.
	offset := anAddress / anObjectMemory wordSize.
	elementByteSize := anObjectMemory wordSize.
	address := anAddress
]
