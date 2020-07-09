Class {
	#name : #VMStackBuilder,
	#superclass : #Object,
	#instVars : [
		'page',
		'frames',
		'interpreter',
		'memory'
	],
	#category : #'VMMakerTests-Frame'
}

{ #category : #Frames }
VMStackBuilder >> addFrame: aFrame [
	frames add: aFrame
]

{ #category : #Frames }
VMStackBuilder >> addNewFrame [
	| frame |
	"'add' a new frame in the sense of an OrderedCollection, which will be iterated with #do:
	The last frame added, will be the stackTop"
	frame := VMFrame new initializeWithInterpreter: interpreter andMemory: memory.
	frames add: frame.
	^ frame "the frame is then configured by the caller"
]

{ #category : #Frames }
VMStackBuilder >> buildStack [
	| lastFrame |
	self createStackPage.
	self pushFrames.

	lastFrame := frames last.
	
"	interpreter push: lastFrame method + memory baseHeaderSize - 2.
	interpreter setStackPageAndLimit: page.
	interpreter setStackPointersFromPage: page.
""	interpreter popStack."
	"should return last frame in use" 
	
	"page
		headFP: lastFrame temps size + 5 + interpreter stackPointer;
		headSP: interpreter stackPointer.
	"
	"interpreter stackTop.
	interpreter stackPages.
	"
	interpreter internalizeIPandSP.
	^ lastFrame
]

{ #category : #Frames }
VMStackBuilder >> createStackPage [
	| sp |
	page := interpreter stackPages newStackPage.
	"set base stackPointer"

	frames ifEmpty:[ self error ].
	sp := page baseAddress - (memory wordSize * (frames first args size + 2)).
	interpreter stackPointer: sp.
	interpreter framePointer: sp

	
]

{ #category : #Frames }
VMStackBuilder >> initialize [
	super initialize.
	frames := OrderedCollection new. "will be treated in reverse"
]

{ #category : #Frames }
VMStackBuilder >> interpreter [
	^ interpreter
]

{ #category : #Frames }
VMStackBuilder >> interpreter: anInterpreter [
	interpreter := anInterpreter
]

{ #category : #Frames }
VMStackBuilder >> memory [
	^ memory
]

{ #category : #Frames }
VMStackBuilder >> memory: aMemory [
	memory := aMemory
]

{ #category : #accessing }
VMStackBuilder >> page [
	^ page
]

{ #category : #Frames }
VMStackBuilder >> pushFrames [
	| first |
	first := true.
	page
		headSP: interpreter stackPointer;
		headFP: interpreter stackPointer.
	frames
		do: [ :aFrame |
			
			first ifTrue:[ 
					interpreter push: 0.
					interpreter push: interpreter framePointer.
					page baseFP: interpreter stackPointer.
					first := false.
				]
				ifFalse:[ 
					interpreter push: interpreter instructionPointer.
					interpreter push: interpreter framePointer.
				].
			
			aFrame callerFP: interpreter framePointer.
			interpreter framePointer: interpreter stackPointer.
			page headFP: interpreter stackPointer.

			aFrame pushYourself.
			]
]
