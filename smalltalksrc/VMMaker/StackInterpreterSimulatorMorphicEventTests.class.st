Class {
	#name : #StackInterpreterSimulatorMorphicEventTests,
	#superclass : #TestCase,
	#pools : [
		'EventSensorConstants'
	],
	#category : #'VMMaker-InterpreterSimulation-Morphic'
}

{ #category : #'test event' }
StackInterpreterSimulatorMorphicEventTests >> testKeyEventDegeneration [
	|aMorphicEvent evtBuf type|
	aMorphicEvent := HandMorph new generateKeyboardEvent: {2 . 0. 0. 0. 0. 0. 0. 0}.
	evtBuf := (StackInterpreterSimulatorEventTransformer default) degenerateEvent: aMorphicEvent. 
	type := evtBuf at:1.
	self assert:(type = EventTypeKeyboard).

]

{ #category : #'test event' }
StackInterpreterSimulatorMorphicEventTests >> testMouseEventDegeneration [
	|aMorphicEvent evtBuf type|
	"see class comment in EventSensor browse"
	aMorphicEvent := HandMorph new generateMouseEvent: {1 . 0. 0. 0. 0. 0. 0. 0}.
	evtBuf := (StackInterpreterSimulatorEventTransformer default) degenerateEvent: aMorphicEvent. 
	type := evtBuf at:1.
	self assert:(type = EventTypeMouse).

]

{ #category : #'test event' }
StackInterpreterSimulatorMorphicEventTests >> testNullEventDegeneration [
	|aMorphicEvent evtBuf type|
	"Test a bad morphic event returns a null event"	"see class comment in EventSensor browse"
	aMorphicEvent := UserInputEvent new.
	evtBuf := (StackInterpreterSimulatorEventTransformer default) degenerateEvent: aMorphicEvent. 
	type := evtBuf at:1.
	self assert:(type = EventTypeNone).


]

{ #category : #'test tight coupling' }
StackInterpreterSimulatorMorphicEventTests >> testStackInterpreterSimulatorDisplayViewAccess [
	"There is tight coupling between the morph,model and vm simulator on the simulators displayView variable
	 this test makes sure it is accesible and is an ImageMorph."
	
self assert: ((SystemNavigation allImplementorsOf: #displayView localTo: StackInterpreterSimulator) size = 1).
self assert: ((SystemNavigation allImplementorsOf: #displayView: localTo: StackInterpreterSimulator)size = 1).


]
