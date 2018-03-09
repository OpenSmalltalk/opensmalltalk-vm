"
Common superclass of all compactors to define apis and simulation variables.

The full GC in Spur is split in two, the marking phase and the compactor phase. The subclasses of SpurCompactor are implementations of the second phase, so they are called once the marking phase is finished. SpurCompactor is reponsible for:
- freeing unmarked objects
- compacting the live old space objects (though each subclass define what it does, some spurCompactor may not compact)
- unmarking all objects remaining live
- updating oops directly referred by the VM when they are moved (remapObj:/shouldRemapObj: thingy)

The main apis are the following:
- biasForGC/biasForSnapshot: tells the compactor if the GC is performed for snapshots or not, in general we want to compact more aggressively for snapshots to avoid saving large files with many unused space.
- compact: main API, should free the unmarked object, unmark the objects remaining live and potentially compact the heap
- remapObj:/shouldRemapObj: => Not really sure what this does, it seems it has to do with updating oops directly referred by the VM when they are moved. 


Instance Variables
	coInterpreter:				<StackInterpreter>
	compactedCopySpace:		<SpurNewSpaceSpace>
	manager:					<SpurMemoryManager>
"
Class {
	#name : #SpurCompactor,
	#superclass : #CogClass,
	#instVars : [
		'manager',
		'scavenger',
		'coInterpreter'
	],
	#pools : [
		'SpurMemoryManagementConstants',
		'VMBasicConstants',
		'VMSpurObjectRepresentationConstants'
	],
	#category : 'VMMaker-SpurMemoryManager'
}

{ #category : #'as yet unclassified' }
SpurCompactor class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #api }
SpurCompactor >> biasForGC [
	self subclassResponsibility
]

{ #category : #api }
SpurCompactor >> biasForSnapshot [
	self subclassResponsibility
]

{ #category : #initialization }
SpurCompactor >> coInterpreter: aVMSimulator [
	<doNotGenerate>
	coInterpreter := aVMSimulator
]

{ #category : #api }
SpurCompactor >> compact [
	self subclassResponsibility
]

{ #category : #initialization }
SpurCompactor >> manager: aSpurNBitMMXEndianSimulator [
	<doNotGenerate>
	manager := aSpurNBitMMXEndianSimulator.
	aSpurNBitMMXEndianSimulator coInterpreter ifNotNil:
		[:coint| coInterpreter := coint].
	aSpurNBitMMXEndianSimulator scavenger ifNotNil:
		[:scav| scavenger := scav]
]

{ #category : #debugging }
SpurCompactor >> printTheBogons: aBogon [
	<inline: true>
	coInterpreter
		print: 'bogon '; printHexnp: aBogon; cr
]

{ #category : #api }
SpurCompactor >> remapObj: objOop [
	self subclassResponsibility
]

{ #category : #api }
SpurCompactor >> shouldRemapObj: objOop [
	self subclassResponsibility
]
