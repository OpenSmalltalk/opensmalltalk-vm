"
Common superclass of all compactors to define apis and common behaviors.

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
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #'as yet unclassified' }
SpurCompactor class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #api }
SpurCompactor >> biasForGC [
]

{ #category : #api }
SpurCompactor >> biasForSnapshot [
]

{ #category : #initialization }
SpurCompactor >> coInterpreter: aVMSimulator [
	<doNotGenerate>
	coInterpreter := aVMSimulator
]

{ #category : #api }
SpurCompactor >> compact [
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
SpurCompactor >> printTheBogons: bogon [
]

{ #category : #debugging }
SpurCompactor >> remapObj: objOop [
]

{ #category : #debugging }
SpurCompactor >> shouldRemapObj: objOop [
]
