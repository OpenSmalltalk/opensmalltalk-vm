Class {
	#name : #VMTHiddenRootTable,
	#superclass : #Object,
	#instVars : [
		'memory'
	],
	#category : #'VMMaker-Tools'
}

{ #category : #'instance-creation' }
VMTHiddenRootTable class >> on: aMemory [ 

	^ self new
		memory: aMemory;
		yourself
]

{ #category : #accessing }
VMTHiddenRootTable >> children [
	| roots |
	roots := OrderedCollection new.
	1 to: memory classTableRootSlots do: [ :index | | oop |
		oop := memory fetchPointer: index - 1 ofObject: memory hiddenRootsObject.
		roots add: (VMTHiddenRoot new
			memory: memory;
			index: index;
			label: 'Class Table Page ', index asString;
			oop: oop;
			yourself).
	].

	roots add: (VMTHiddenRoot new
			memory: memory;
			index: 4096;
			label: 'Mark Stack';
			oop: (memory fetchPointer: 4096 ofObject: memory hiddenRootsObject);
			yourself).

	roots add: (VMTHiddenRoot new
			memory: memory;
			index: 4097;
			label: 'Weakling Stack';
			oop: (memory fetchPointer: 4097 ofObject: memory hiddenRootsObject);
			yourself).

	roots add: (VMTHiddenRoot new
			memory: memory;
			index: 4097;
			label: 'Weakling Stack';
			oop: (memory fetchPointer: 4097 ofObject: memory hiddenRootsObject);
			yourself).

	roots add: (VMTHiddenRoot new
			memory: memory;
			index: 4098;
			label: 'Mourn Queue';
			oop: (memory fetchPointer: 4098 ofObject: memory hiddenRootsObject);
			yourself).
			
	roots add: (VMTHiddenRoot new
			memory: memory;
			index: 4099;
			label: 'Remembered Set';
			oop: (memory fetchPointer: 4099 ofObject: memory hiddenRootsObject);
			yourself).
			
	^ roots
]

{ #category : #accessing }
VMTHiddenRootTable >> memory: aMemory [ 
	memory := aMemory
]
