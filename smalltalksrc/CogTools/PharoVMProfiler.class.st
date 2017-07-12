"
I am the VMProfiler called when using a Pharo image.

I can only be used headless for the moment.
Try inspecting on : String streamContents: [ :s | VMProfiler headlessSpyOn: [ 1 to: 10000000 do: [ :i | Object new ] ] reportOn: s ]


"
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
	"will do something when a UI will be added for Pharo"
	^self new. 
]

{ #category : #'as yet unclassified' }
PharoVMProfiler class >> spyOn: aBlock [

	self shouldBeImplemented
]

{ #category : #'as yet unclassified' }
PharoVMProfiler >> createParagraph [
	
	^Paragraph new
]

{ #category : #'as yet unclassified' }
PharoVMProfiler >> getVMParameters [

	^Smalltalk vm getParameters 
]

{ #category : #initialization }
PharoVMProfiler >> initialize [

	self initializeMost.
	CompatibilityClass := PharoVMMethodConverter new.
	self initializeSymbols.
]
