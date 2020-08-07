Class {
	#name : #SpurImageSegmentTests,
	#superclass : #LongTestCase,
	#classVars : [
		'CheckForLeaks'
	],
	#pools : [
		'VMBasicConstants',
		'VMSqueakClassIndices'
	],
	#category : #'VMMaker-OriginalTests'
}

{ #category : #accessing }
SpurImageSegmentTests class >> resources [
	^{SpurTrunkImageTestResource}
]

{ #category : #private }
SpurImageSegmentTests >> initializedVM [
	^self resources anyOne current initializedVM cloneSimulation
]

{ #category : #tests }
SpurImageSegmentTests >> testSaveHashedCollectionAndAllSubclasses [
	SimulatorHarnessForTests new
		withExecutableInterpreter: self initializedVM
		do: [:vm :harness| | error objects |
			CheckForLeaks == true ifTrue: "CheckForLeaks := self confirm: 'Check for leaks?'"
				[vm objectMemory setCheckForLeaks: (vm objectMemory class bindingOf: #GCModeImageSegment) value].
			error := harness findSymbol: #error.
			self deny: error isNil.
			objects := harness
				interpreter: vm
				object: (harness findClassNamed: 'Compiler')
				perform: (harness findSymbol: #evaluate:)
				withArguments: {vm objectMemory stringForCString:
					'[| seg out roots result |
					 seg := WordArray new: 1024 * 1024.
					 out := Array new: 512.
					 roots := HashedCollection withAllSubclasses asArray.
					 roots := roots, (roots collect: [:ea| ea class]).
					 (thisContext isPrimFailToken: (nil tryPrimitive: 98 withArgs: { roots. seg. out })) ifTrue:
						[^#error].
					 result := { seg. out }.
					 (thisContext isPrimFailToken: (nil tryPrimitive: 99 withArgs: result)) ifTrue:
						[^#error].
					 result]
						on: Error
						do: [:ex| ^#error]'}.
			self deny: objects = error]
]

{ #category : #tests }
SpurImageSegmentTests >> testSaveHashedCollectionSubclasses [
	SimulatorHarnessForTests new
		withExecutableInterpreter: self initializedVM
		do: [:vm :harness| | error objects |
			CheckForLeaks == true ifTrue: "CheckForLeaks := self confirm: 'Check for leaks?'"
				[vm objectMemory setCheckForLeaks: (vm objectMemory class bindingOf: #GCModeImageSegment) value].
			error := harness findSymbol: #error.
			self deny: error isNil.
			objects := harness
				interpreter: vm
				object: (harness findClassNamed: 'Compiler')
				perform: (harness findSymbol: #evaluate:)
				withArguments: {vm objectMemory stringForCString:
					'[| seg out roots result |
					 seg := WordArray new: 1024 * 1024.
					 out := Array new: 256.
					 roots := HashedCollection subclasses asArray.
					 roots := roots, (roots collect: [:ea| ea class]).
					 (thisContext isPrimFailToken: (nil tryPrimitive: 98 withArgs: { roots. seg. out })) ifTrue:
						[^#error].
					 result := { seg. out }.
					 (thisContext isPrimFailToken: (nil tryPrimitive: 99 withArgs: result)) ifTrue:
						[^#error].
					 result]
						on: Error
						do: [:ex| ^#error]'}.
			self deny: objects = error]
]
