"
I represent a specific node in a VMProfiler profiling result tree : the result wrapped in this VMProfilerResultCM is supposed to be a compiled method.

method : the compiledMetod referring to the VMProfilerResult. This way, it is easy to access the compiledMethod data (AST, IR, Bytecode) when inspecting the VMProfilerResult tree. 
"
Class {
	#name : #VMProfilerResultCM,
	#superclass : #VMProfilerResult,
	#instVars : [
		'method'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #'as yet unclassified' }
VMProfilerResultCM class >> name: aName label: aLabel content: aMethod [

	^ VMProfilerResultCM new 
			name: aName ;
			label: aLabel;	
			content: aMethod ;
			yourself.
]

{ #category : #accessing }
VMProfilerResultCM >> content: aMethod [

	method := aMethod 
]

{ #category : #initialization }
VMProfilerResultCM >> initialize [

	super initialize.
	method := nil.
]
