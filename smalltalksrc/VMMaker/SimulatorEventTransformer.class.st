"
A SimulatorEventTransformer takes events as wrapped by HandMorph and converts them to a form a StackInterpreterSimulator can deal with.

See HandMorph >> handleEvent to see what the wrapping entails.
See HandMorph >> ProcessEvents  or EventSensor >> fetchMoreEvents for examples of what an unwrapped event looks like when given to the system for pre-wrapping.

Instance Variables

"
Class {
	#name : #SimulatorEventTransformer,
	#superclass : #Object,
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
	| evt type |
	self flag:'tty'.

	evt := nil.	
	type := aMorphicEvent type.
"	Transcript show:type;cr."
	(('mouse' charactersExactlyMatching: type asString) > 4)  "mous"
		ifTrue: [^self degenerateMouseEvent: aMorphicEvent].
	(('key' charactersExactlyMatching: type asString) > 2)  "key"
		ifTrue: [^self degenerateKeyboardEvent: aMorphicEvent].
"	type = EventTypeDragDropFiles ifTrue: [evt := self generateDropFilesEvent: evtBuf].
	type = EventTypeWindow	ifTrue:[evt := self generateWindowEvent: evtBuf]."

	^ #(0 0 0 0 0 0 0 0).
]

{ #category : #'event transformation' }
SimulatorEventTransformer >> degenerateKeyboardEvent: aMorphicEvent [
	| evt |
	"see HandMorph>>generateKeyboardEvent and EventSensor class comment"
	evt := {2 . 0 . 0 . 0 . 0. 0 . 0 . 0}.
	
	evt at:2 put: aMorphicEvent timeStamp.
	evt at:3 put: aMorphicEvent keyValue.    "<--this is wrong. See Sensor FirstEvt: for what needs to happen. hooo boy"
	evt at:4 put: aMorphicEvent position y.
	evt at:5 put: (aMorphicEvent buttons bitAnd: 7).  "thanks Ron T."
	evt at:6 put: (aMorphicEvent buttons >> 3).     "Thanks dtl"
	^evt



]

{ #category : #'event transformation' }
SimulatorEventTransformer >> degenerateMouseButtonEvent: aMorphicEvent [
	| evt |
	"see HandMorph>>generateMouseEvent"
	evt := {1 . 0 . 0 . 0 . 0. 0 . 0 . 0}.
	
	evt at:2 put: aMorphicEvent timeStamp.
	evt at:3 put: aMorphicEvent position x.
	evt at:4 put: aMorphicEvent position y.
	evt at:5 put: (aMorphicEvent buttons bitAnd: 7).  "thanks Ron T."
	evt at:6 put: (aMorphicEvent buttons >> 3).     "Thanks dtl"
	^evt



]

{ #category : #'event transformation' }
SimulatorEventTransformer >> degenerateMouseEvent: aMorphicEvent [
	"see HandMorph>>generateMouseEvent"

	(aMorphicEvent type) = #mouseMove
		ifTrue:[^self degenerateMouseMoveEvent: aMorphicEvent].	

	((aMorphicEvent type) = #mouseUp) |  ((aMorphicEvent type) = #mouseDown)
		ifTrue:[^self degenerateMouseButtonEvent: aMorphicEvent].	
"	(aMorphicEvent type) = #mouseDrag
		ifTrue:[evt := self degenerateMouseDragEvent: aMorphicEvent].	
"
	^{0 . 0. 0. 0. 0. 0. 0. 0}.
]

{ #category : #'event transformation' }
SimulatorEventTransformer >> degenerateMouseMoveEvent: aMorphicEvent [
	| evt |
	"see HandMorph>>generateMouseEvent"
	evt := {1 . 0 . 0 . 0 . 0. 0 . 0 . 0}.
	
	evt at:2 put: aMorphicEvent timeStamp.
	evt at:3 put: aMorphicEvent position x.
	evt at:4 put: aMorphicEvent position y.
	evt at:5 put: (aMorphicEvent buttons bitAnd: 7).  "thanks Ron T."
	evt at:6 put: (aMorphicEvent buttons >> 3).     "Thanks dtl"
	^evt



]
