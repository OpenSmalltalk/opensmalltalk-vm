Class {
	#name : #VMMakerDecompilerTests,
	#superclass : #DecompilerTests,
	#category : #'VMMaker-Tests'
}

{ #category : #utilities }
VMMakerDecompilerTests >> classNames [
	"A list of the classes in most of the base packages; excluding EToys arbitrarily for now"
	^(PackageInfo named: 'VMMaker') classes collect: [:ea| ea name]
]

{ #category : #utilities }
VMMakerDecompilerTests >> decompilerFailures [
	"Here is the list of failures: either a syntax error, a hard error or some failure to decompile correctly.
	 Collected via 
		DecompilerTestFailuresCollector new computeFailures."

	"class name, selector, error class name or nil"
	^  #(
		#(BitBltSimulator primitive:parameters:receiver: ResumableTestFailure)  "expr ifTrue: [^foo] ifFalse: [bar] => expr ifTrue: [^foo]. bar"
		)


]

{ #category : #tests }
VMMakerDecompilerTests >> testDecompilationOfClasses [
	self decompileClassesSelect: [:cn| true]
]
