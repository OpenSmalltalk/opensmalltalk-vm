Class {
	#name : #VMContext,
	#superclass : #Object,
	#instVars : [
		'contextOop',
		'interpreter'
	],
	#category : #'VMMakerTests-Frame'
}

{ #category : #'instance creation' }
VMContext class >> newOnContext: anInteger withInterpreter: aStackInterpreterSimulatorLSB [
	^ self new
		contextOop: anInteger;
		interpreter: aStackInterpreterSimulatorLSB;
		yourself
]

{ #category : #accessing }
VMContext >> contextOop: anInteger [ 
	contextOop := anInteger
]

{ #category : #accessing }
VMContext >> interpreter: aStackInterpreterSimulatorLSB [ 
	interpreter := aStackInterpreterSimulatorLSB
]

{ #category : #testing }
VMContext >> isMarried [
	^interpreter isStillMarriedContext: contextOop.
]

{ #category : #testing }
VMContext >> isNilObject [
	^interpreter objectMemory nilObject = contextOop.
]
