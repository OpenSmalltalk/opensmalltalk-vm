Class {
	#name : #VMMakerDecompilerTestFailuresCollector,
	#superclass : #DecompilerTestFailuresCollector,
	#category : #'VMMaker-Tests'
}

{ #category : #utilities }
VMMakerDecompilerTestFailuresCollector >> classNames [
	"A list of the classes in most of the base packages; excluding EToys arbitrarily for now"
	^(PackageInfo named: 'VMMaker') classes collect: [:ea| ea name]
]
