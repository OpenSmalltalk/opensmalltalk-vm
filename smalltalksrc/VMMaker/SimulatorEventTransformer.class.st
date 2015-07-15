"
A SimulatorEventTransformer takes events as wrapped by HandMorph and converts them to a form a StackInterpreterSimulator can deal with.

See HandMorph >> handleEvent to see what the wrapping entails.
See HandMorph >> ProcessEvents  or EventSensor >> fetchMoreEvents for examples of what an unwrapped event looks like when given to the system for pre-wrapping.

Instance Variables

"
Class {
	#name : #SimulatorEventTransformer,
	#superclass : #Object,
	#instVars : [
		'buttons'
	],
	#classVars : [
		'Default'
	],
	#pools : [
		'EventSensorConstants'
	],
	#category : #'VMMaker-InterpreterSimulation-Morphic'
}

{ #category : #'initialize-release' }
SimulatorEventTransformer class >> default [
	^Default ifNil:[Default := self new]
]

{ #category : #accessing }
SimulatorEventTransformer class >> eventTypeMouse [
	^EventTypeMouse
]

{ #category : #'event transformation' }
SimulatorEventTransformer >> degenerateEvent: aMorphicEvent [
	"tty. Bert had mentioned a distinction between events and polling events and that Morphic could handle both.
	I don't know what he is talking about."
	aMorphicEvent isMouse ifTrue:
		[^self degenerateMouseEvent: aMorphicEvent].
	aMorphicEvent isKeyboard ifTrue:
		[^self degenerateKeyboardEvent: aMorphicEvent].
"	type = EventTypeDragDropFiles ifTrue: [evt := self generateDropFilesEvent: evtBuf].
	type = EventTypeWindow	ifTrue:[evt := self generateWindowEvent: evtBuf]."

	^nil
]

{ #category : #'event transformation' }
SimulatorEventTransformer >> degenerateKeyboardEvent: aMorphicEvent [
	"see HandMorph>>generateKeyboardEvent and EventSensor class comment"
	^{	2.
		aMorphicEvent timeStamp.
		aMorphicEvent keyValue.		"<--this is wrong. See Sensor FirstEvt: for what needs to happen. hooo boy"
		aMorphicEvent type caseOf: {
					[#keyDown]	->	[EventKeyDown].
					[#keyUp]		->	[EventKeyUp].
					[#keystroke]	->	[EventKeyChar] }.
		aMorphicEvent buttons bitAnd: 7.
		aMorphicEvent keyValue.
		0.
		0 }
]

{ #category : #'event transformation' }
SimulatorEventTransformer >> degenerateMouseEvent: aMorphicEvent [
	"see HandMorph>>generateMouseEvent"

	aMorphicEvent type == #mouseMove
		ifTrue: [buttons = 0 ifTrue: [^nil]] "filter-out mouse moves unless buttons are pressed, so simulation doersn't get window leave events when we leave its window"
		ifFalse: [buttons := aMorphicEvent buttons].
	^{	1.
		aMorphicEvent timeStamp.
		aMorphicEvent position x.
		aMorphicEvent position y.
		buttons bitAnd: 7.  "thanks Ron T."
		buttons >> 3.     "Thanks dtl"
		0.
		0 }
]

{ #category : #'initialize-release' }
SimulatorEventTransformer >> initialize [
	buttons := 0
]
