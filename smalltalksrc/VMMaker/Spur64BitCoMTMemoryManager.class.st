Class {
	#name : #Spur64BitCoMTMemoryManager,
	#superclass : #Spur64BitCoMemoryManager,
	#instVars : [
		'fullGCLock'
	],
	#category : #'VMMaker-Multithreading'
}

{ #category : #'gc - global' }
Spur64BitCoMTMemoryManager >> decrementFullGCLock [
	self assert: fullGCLock > 0.
	(fullGCLock := fullGCLock - 1) < 0 ifTrue:
		[fullGCLock := 0]
]

{ #category : #'gc - global' }
Spur64BitCoMTMemoryManager >> fullGC [
	"Do a mark/sweep garbage collection of the entire object memory.
	 Free inaccessible objects but do not move them."

	<inline: false>
	fullGCLock > 0 ifTrue:
		[self warning: 'aborting fullGC because fullGCLock > 0'.
		 ^nil].
	super fullGC.
]

{ #category : #'gc - global' }
Spur64BitCoMTMemoryManager >> fullGCLock [
	^fullGCLock
]

{ #category : #'gc - global' }
Spur64BitCoMTMemoryManager >> incrementFullGCLock [
	fullGCLock := fullGCLock + 1
]

{ #category : #'gc - global' }
Spur64BitCoMTMemoryManager >> initialize [
	"Initialize NewObjectMemory when simulating the VM inside Smalltalk."
	super initialize.
	fullGCLock := 0.
]
