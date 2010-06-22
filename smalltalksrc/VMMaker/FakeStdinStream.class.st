"
Fake Standard input using a dialog to prompt for a line of input at a time.
"
Class {
	#name : #FakeStdinStream,
	#superclass : #ReadStream,
	#instVars : [
		'atEnd',
		'simulator'
	],
	#pools : [
		'VMBasicConstants'
	],
	#category : #'VMMaker-JITSimulation'
}

{ #category : #'instance creation' }
FakeStdinStream class >> for: aCogVMSimulator [
	^(self basicNew simulator: aCogVMSimulator)
		on: (String new: 80) from: 1 to: 0

	"self new next"
]

{ #category : #'instance creation' }
FakeStdinStream class >> new [
	^super on: (String new: 80) from: 1 to: 0

	"self new next"
]

{ #category : #testing }
FakeStdinStream >> atEnd [
	^atEnd ifNil: [atEnd := false]
]

{ #category : #accessing }
FakeStdinStream >> close [
	atEnd := true
]

{ #category : #accessing }
FakeStdinStream >> next [
	"Answer the next object in the Stream represented by the receiver.
	 If there are no more elements in the stream fill up the buffer by prompting for input"
	| threadIndex inputLine |
	position >= readLimit ifTrue:
		[simulator isThreadedVM ifTrue:
			["(simulator cogit singleStep not
			  and: [UIManager confirm: 'Single step?']) ifTrue:
				[simulator cogit singleStep: true]."
			 threadIndex := simulator disownVM: DisownVMLockOutFullGC.
			 simulator forceInterruptCheckFromHeartbeat].
		 inputLine := UIManager default request: 'Input please!'.
		 collection size <= inputLine size ifTrue:
			[collection := collection species new: inputLine size + 1].
		 collection
			replaceFrom: 1 to: inputLine size with: inputLine startingAt: 1;
		 	at: (readLimit := inputLine size + 1) put: Character lf.
		 position := 0.
		 simulator isThreadedVM ifTrue:
			[simulator ownVM: threadIndex]].
	^collection at: (position := position + 1)
]

{ #category : #'initialize-release' }
FakeStdinStream >> simulator: aCogVMSimulator [
	simulator := aCogVMSimulator.
	atEnd := false
]
