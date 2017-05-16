Class {
	#name : #PharoVMProfiler,
	#superclass : #VMProfiler,
	#category : #'CogTools-VMProfiler'
}

{ #category : #reports }
PharoVMProfiler class >> amOnSpur [
	^(Smalltalk vm parameterAt: 41) anyMask: 16.
]

{ #category : #accessing }
PharoVMProfiler class >> default [
	"will do something when I take care of the UI"
	^self new. 
]

{ #category : #'as yet unclassified' }
PharoVMProfiler >> createParagraph [
	
	^Paragraph new
]

{ #category : #'as yet unclassified' }
PharoVMProfiler >> getVMParameters [

	^Smalltalk vm getParameters 
]
