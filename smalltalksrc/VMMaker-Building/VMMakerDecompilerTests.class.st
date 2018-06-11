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

{ #category : #tests }
VMMakerDecompilerTests >> testDecompilationOfClasses [
	self decompileClassesSelect: [:cn| true]
]
