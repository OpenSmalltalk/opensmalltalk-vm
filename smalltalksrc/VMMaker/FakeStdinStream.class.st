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
	#category : 'VMMaker-JITSimulation'
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
FakeStdinStream >> atEnd: aBoolean [
	atEnd := aBoolean
]

{ #category : #accessing }
FakeStdinStream >> close [
	atEnd := true
]

{ #category : #testing }
FakeStdinStream >> isFakeStdinStream [
	^true
]

{ #category : #accessing }
FakeStdinStream >> next [
	"Answer the next object in the Stream represented by the receiver.
	 If there are no more elements in the stream fill up the buffer by prompting for input"
	| sem threadIndex inputLine next |
	position >= readLimit ifTrue:
		[simulator isThreadedVM
			ifTrue:
				["(simulator cogit singleStep not
				  and: [UIManager confirm: 'Single step?']) ifTrue:
					[simulator cogit singleStep: true]."
				 threadIndex := simulator disownVM: DisownVMLockOutFullGC.
				 simulator forceInterruptCheckFromHeartbeat.
				 sem := Semaphore new.
				 WorldState addDeferredUIMessage:
					[inputLine := UIManager default request: 'Input please!'.
					 sem signal].
				 sem wait]
			ifFalse: "simulate line-oriented input"
				[inputLine := ((Smalltalk classNamed: #FillInTheBlankMorph)
								ifNotNil: "Squeak"
									[:fITBM|
									 fITBM
										request: 'Input please!'
										initialAnswer: ''
										centerAt: ActiveHand cursorPoint
										inWorld: ActiveWorld
										onCancelReturn: nil
										acceptOnCR: true]
								ifNil: "Pharo; onCancelReturn: nil is the default here"
									[UIManager default 
										request: 'Input please!' 
										initialAnswer: '']).
				inputLine ifNil: [self atEnd: true. ^nil]].
		 collection size <= inputLine size ifTrue:
			[collection := collection species new: inputLine size + 1].
		 collection
			replaceFrom: 1 to: inputLine size with: inputLine startingAt: 1;
		 	at: (readLimit := inputLine size + 1) put: Character lf.
		 position := 0.
		 simulator isThreadedVM ifTrue:
			[simulator ownVM: threadIndex]].
	next := collection at: (position := position + 1).
	^next
	

" This does it with workspaces:
| ws r s |
s := Semaphore new.
ws := Workspace new contents: ''.
ws acceptAction: [:t| r := t asString. s signal].
[ws openLabel: 'Yo!'; shouldStyle: false.
(ws dependents detect: [:dep | dep isKindOf: PluggableTextMorph] ifNone: [nil]) ifNotNil:
	[:textMorph| textMorph acceptOnCR: true; hasUnacceptedEdits: true]] fork.
Processor activeProcess ==  Project uiProcess
	ifTrue: [[r isNil] whileTrue: [World doOneCycle]]
	ifFalse: [s wait].
ws topView delete.
s wait. s signal.
r"
]

{ #category : #'initialize-release' }
FakeStdinStream >> simulator: aCogVMSimulator [
	simulator := aCogVMSimulator.
	atEnd := false
]
