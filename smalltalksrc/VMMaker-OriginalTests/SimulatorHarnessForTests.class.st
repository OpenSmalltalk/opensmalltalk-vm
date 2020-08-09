Class {
	#name : #SimulatorHarnessForTests,
	#superclass : #SimulatorHarness,
	#instVars : [
		'simulator'
	],
	#category : #'VMMaker-OriginalTests'
}

{ #category : #utilities }
SimulatorHarnessForTests >> findClassNamed: classNameString [
	| className classNameIndex om |
	(className := self findSymbol: classNameString) ifNil:
		[^nil].
	classNameIndex := simulator classNameIndex.
	(om := simulator objectMemory) allObjectsDo:
		[:obj|
		((om numSlotsOf: obj) > classNameIndex
		 and: [(simulator objCouldBeClassObj: obj)
		 and: [(om fetchPointer: simulator classNameIndex ofObject: obj) = className]]) ifTrue:
			[^obj]].
	^nil
]

{ #category : #utilities }
SimulatorHarnessForTests >> findSymbol: aString [
	"Find the Symbol equal to aString in oldHeap."
	| om size symbolClassTag |
	symbolClassTag := (om := simulator objectMemory) rawClassTagForClass: self symbolClass.
	size := aString size.
	om allObjectsDo:
		[:obj|
		(symbolClassTag = (om fetchClassTagOfNonImm: obj)
		 and: [(om numBytesOf: obj) = size
		 and: ["(om fetchByte: 0 ofObject: obj) asCharacter == $C ifTrue:
				[simulator printOopShort: obj; halt]."
			(om strncmp: aString _: obj + om baseHeaderSize _: size) = 0]]) ifTrue:
			[^obj]].
	^nil
]

{ #category : #execution }
SimulatorHarnessForTests >> interpreter: sim object: receiver perform: selector withArguments: arguments [
	simulator := sim.
	^super interpreter: sim object: receiver perform: selector withArguments: arguments
]

{ #category : #utilities }
SimulatorHarnessForTests >> symbolClass [
	^simulator objectMemory fetchClassOfNonImm: (simulator objectMemory splObj: SelectorDoesNotUnderstand)
]

{ #category : #execution }
SimulatorHarnessForTests >> withExecutableInterpreter: sim do: aBlock [
	simulator := sim.
	^super withExecutableInterpreter: sim do: aBlock
]
