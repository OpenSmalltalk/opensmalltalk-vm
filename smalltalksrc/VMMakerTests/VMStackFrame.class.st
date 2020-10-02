Class {
	#name : #VMStackFrame,
	#superclass : #Object,
	#instVars : [
		'framePointer',
		'interpreter'
	],
	#pools : [
		'VMStackFrameOffsets'
	],
	#category : #'VMMakerTests-Visualisation'
}

{ #category : #'instance creation' }
VMStackFrame class >> newFramePointer: anInteger withInterpreter: aStackInterpreterSimulatorLSB [
	^self new
		framePointer: anInteger;
		interpreter: aStackInterpreterSimulatorLSB;
		yourself
]

{ #category : #accessing }
VMStackFrame >> context [
	^VMContext newOnContext: (interpreter frameContext: framePointer) withInterpreter: interpreter 
]

{ #category : #accesing }
VMStackFrame >> framePointer: anInteger [ 
	framePointer := anInteger
]

{ #category : #testing }
VMStackFrame >> hasContext [
	^interpreter frameHasContext: framePointer 
]

{ #category : #accessing }
VMStackFrame >> instructionPointer [

	^ interpreter framePointer = framePointer
		ifTrue: [ interpreter instructionPointer ]
		ifFalse: [ interpreter frameCallerSavedIP: ( interpreter findFrameAbove: framePointer inPage: self stackPage) ]
]

{ #category : #acccessing }
VMStackFrame >> interpreter: aStackInterpreterSimulatorLSB [ 
	interpreter := aStackInterpreterSimulatorLSB
]

{ #category : #accessing }
VMStackFrame >> method [
	^interpreter stackPages longAt: framePointer + FoxMethod
]

{ #category : #accessing }
VMStackFrame >> receiver [
	^ interpreter framePointer = framePointer
		ifTrue: [ interpreter receiver ]
		ifFalse: [ self halt. interpreter frameCallerSavedIP: ( interpreter findFrameAbove: framePointer inPage: self stackPage) ]
]

{ #category : #accessing }
VMStackFrame >> sender [
	^ VMStackFrame newFramePointer:(interpreter frameCallerFP: framePointer) withInterpreter: interpreter
	 
]

{ #category : #accessing }
VMStackFrame >> stackPage [
	^interpreter stackPages stackPageFor: framePointer.
]
