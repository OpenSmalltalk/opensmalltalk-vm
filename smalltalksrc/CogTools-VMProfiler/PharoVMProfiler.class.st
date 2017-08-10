"
I am the VMProfiler called when using a Pharo image.

I can only be used headless for the moment.
* for instance, inspect on : String streamContents: [ :s | VMProfiler headlessSpyOn: [ 1 to: 10000000 do: [ :i | Object new ] ] reportOn: s ]
* If you want to get a profiling report providing detailed data about the time spent in a function, inspect on : String streamContents: [ :s | VMProfiler headlessSpyOn: [ 1 to: 10000000 do: [ :i | Object new ] ] reportOn: s withDetails: true].


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
