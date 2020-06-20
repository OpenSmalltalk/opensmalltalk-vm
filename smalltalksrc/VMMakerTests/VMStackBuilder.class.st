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
	frame := VMFrame new initializeWithInterepreter: interpreter andMemory: memory.
	frame page: page.
	frames add: frame.
	^ frame "the frame is then configured by the caller"
]

{ #category : #Frames }
VMStackBuilder >> buildStack [
	| lastFrame |
	self createStackPage.
	self pushFrames.

	lastFrame := frames last.
	
	interpreter push: lastFrame method + memory baseHeaderSize - 2.
	interpreter setStackPageAndLimit: page.
	interpreter setStackPointersFromPage: page.
"	interpreter popStack."
	"should return last frame in use" 
	
	^ lastFrame
]

{ #category : #Frames }
VMStackBuilder >> createStackPage [
	| sp |
	page := interpreter stackPages newStackPage.
	"set base stackPointer"

	frames ifEmpty:[ self error ].
	sp := page baseAddress - (memory wordSize * (frames first args size + 2)).
	interpreter stackPointer: sp."is it useful?"
	page
		baseFP: sp;
		headFP: sp;
		headSP: sp.

	
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

{ #category : #Frames }
VMStackBuilder >> pushFrames [
	frames do: [ :aFrame | aFrame pushYourself ] separatedBy: [ "put jump return" ].
	
]
