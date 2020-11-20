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
		'buttons',
		'modifiers'
	],
	#classVars : [
		'Default'
	],
	#pools : [
		'EventSensorConstants'
	],
	#category : #'VMMaker-Tools-Old'
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
SimulatorEventTransformer >> degenerateEvent: aMorphicEvent for: client [
	"Handle ''degenerating'' events for aClient.  This interface gets the client
	 to queue the event via queueForwardedEvent:, and may generate more
	 than one event for the input event (i.e. a fake mouse move before a
	 button down), in addition to filtering-out excessive mouse moves."
	aMorphicEvent isMouse ifTrue:
		[^self degenerateMouseEvent: aMorphicEvent for: client].
	aMorphicEvent isKeyboard ifTrue:
		[^self degenerateKeyboardEvent: aMorphicEvent for: client].
	^self degenerateUnknownEvent: aMorphicEvent for: client
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
		modifiers.
		aMorphicEvent keyValue.
		0.
		0 }
]

{ #category : #'event transformation' }
SimulatorEventTransformer >> degenerateKeyboardEvent: aMorphicEvent for: aClient [
	"Convert the keyboard event into a low-level event for the VM simulator (aClient).
	 See HandMorph>>generateKeyboardEvent and EventSensor class comment"
	aClient queueForwardedEvent:
		{	2.
			aMorphicEvent timeStamp.
			aMorphicEvent keyValue.		"<--this is wrong. See Sensor FirstEvt: for what needs to happen. hooo boy"
			aMorphicEvent type caseOf: {
						[#keyDown]	->	[EventKeyDown].
						[#keyUp]		->	[EventKeyUp].
						[#keystroke]	->	[EventKeyChar] }.
			modifiers.
			aMorphicEvent keyValue.
			0.
			self windowIndex }
]

{ #category : #'event transformation' }
SimulatorEventTransformer >> degenerateMouseEvent: aMorphicEvent [
	"see HandMorph>>generateMouseEvent"

	modifiers := aMorphicEvent buttons >> 3. "Sad, but modifiers come in on mouse move events..."
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

{ #category : #'event transformation' }
SimulatorEventTransformer >> degenerateMouseEvent: aMorphicEvent for: aClient [
	"Convert the mouse event into low-level events for the VM simulator (aClient).  Filter-out mouse moves,
	 and generate a fake mouse move before each button press.
	 See HandMorph>>generateMouseEvent"
	| translated |
	translated := aMorphicEvent position - aClient displayView bounds origin.
	modifiers := aMorphicEvent buttons >> 3. "Sad, but modifiers come in on mouse move events..."

	aMorphicEvent type == #mouseMove
		ifTrue: "filter-out mouse moves unless buttons are pressed, so simulation doesn't get window leave events when we leave its window"
			[buttons = 0 ifTrue: [^nil]]
		ifFalse:"If the buttons are going down, make sure to add a mouse move event to the current position before the buttons are pressed."
			[((buttons bitAnd: 7) = 0 and: [(aMorphicEvent buttons bitAnd: 7) ~= 0]) ifTrue:
				[aClient queueForwardedEvent:
							{	1.
								aMorphicEvent timeStamp.
								translated x.
								translated y.
								0.
								buttons >> 3.     "Thanks dtl"
								0.
								self windowIndex }].
				 buttons := aMorphicEvent buttons].
	aClient queueForwardedEvent:
			{	1.
				aMorphicEvent timeStamp.
				translated x.
				translated y.
				buttons bitAnd: 7.  "thanks Ron T."
				buttons >> 3.     "Thanks dtl"
				0.
				self windowIndex }
]

{ #category : #'initialize-release' }
SimulatorEventTransformer >> initialize [
	buttons := modifiers := 0
]

{ #category : #'event transformation' }
SimulatorEventTransformer >> windowIndex [
	^1
]
