"
A SimulatorMorphicModel handles Morphic callbacks and UI  for (some parts of ) the simulator.

I   handle event forwarding management..

Currently, I am a listener to HandMorphs>>addPrimitiveEventListener. 
I am added as a listener by SimulatorMorph>>displayView (which probably  needs to change. tty)
"
Class {
	#name : #SimulatorMorphicModel,
	#superclass : #Model,
	#instVars : [
		'vm',
		'title',
		'stepping',
		'morph'
	],
	#pools : [
		'EventSensorConstants'
	],
	#category : #'VMMaker-Tools-Old'
}

{ #category : #'class initialization' }
SimulatorMorphicModel class >> initialize [
	"I want to keep it launchable by script only for now.
	Eliot has a bunch of options that aren't really feasible for a Morphic first approach.
	"
	"self
		registerWindowColor;
		registerInOpenMenu;
		registerInFlaps"
]

{ #category : #'instance creation' }
SimulatorMorphicModel class >> on: aStackInterpreterSimulator title: aString transcript: aTranscriptStream [
	| simmodel |
	simmodel := self new.
	simmodel 
		vm: aStackInterpreterSimulator;
		title: aString;
		transcript: aTranscriptStream.
	^simmodel.	
]

{ #category : #'class initialization' }
SimulatorMorphicModel class >> registerInFlaps [
"	Flaps 
		registerQuad: 
			{ #StackInterpreterSimulator. 
			#prototypicalToolWindow.
			'StackInterpreter Simulator' translated.
			'A Morphic Wrapper for VM Simulations' translated }
	 	forFlapNamed: 'Tools' translated.
	Flaps replaceToolsFlap"
]

{ #category : #'class initialization' }
SimulatorMorphicModel class >> registerInOpenMenu [
	(TheWorldMenu respondsTo: #registerOpenCommand:) ifTrue: [
		TheWorldMenu unregisterOpenCommand: 'StackInterpreter Simulator'.
		TheWorldMenu registerOpenCommand: {'StackInterpreter Simulator'. {self. #open}}].
		
]

{ #category : #'class initialization' }
SimulatorMorphicModel class >> unload [
	self 
		unregisterFromOpenMenu;
		unregisterFromFlaps.
]

{ #category : #'class initialization' }
SimulatorMorphicModel class >> unregisterFromFlaps [
	"Flaps 
		unregisterQuadsWithReceiver: self;
		replaceToolsFlap"
]

{ #category : #'class initialization' }
SimulatorMorphicModel class >> unregisterFromOpenMenu [
	 (TheWorldMenu respondsTo: #registerOpenCommand:)
		ifTrue: [TheWorldMenu unregisterOpenCommand: 'StackInterpreter Simulator'].

]

{ #category : #accessing }
SimulatorMorphicModel >> bounds [
	^morph bounds.
]

{ #category : #'user interface' }
SimulatorMorphicModel >> byteCountText [
	^vm byteCountText
]

{ #category : #'user interface - squeakJS' }
SimulatorMorphicModel >> currentContextStack [
	self flag: 'tty'.
	^ 'Current Context Stack' printString asText
]

{ #category : #'user interface' }
SimulatorMorphicModel >> defaultWindowColor [
	^ (Color r: 0.645 g: 1.0 b: 1.0)
]

{ #category : #accessing }
SimulatorMorphicModel >> displayForm [
	^ vm displayForm
]

{ #category : #accessing }
SimulatorMorphicModel >> displayView [
	^ vm displayView
]

{ #category : #accessing }
SimulatorMorphicModel >> displayView: anImageMorph [
	vm displayView: anImageMorph
]

{ #category : #'buttons callbacks' }
SimulatorMorphicModel >> forceInterruptCheck [
	vm forceInterruptCheck
"^UserDialogBoxMorph inform: 'Toggle Transcript' title: 'TODO:'"
]

{ #category : #'buttons callbacks' }
SimulatorMorphicModel >> fullDisplayUpdate [
	vm fullDisplayUpdate
"^UserDialogBoxMorph inform: 'Toggle Transcript' title: 'TODO:'"
]

{ #category : #'buttons callbacks' }
SimulatorMorphicModel >> hack [
	UserDialogBoxMorph inform: (morph bounds printString) title: 'Hack:'
]

{ #category : #'event-forwarding' }
SimulatorMorphicModel >> handleListenEvent: aMorphicEvent [
"The SimulatorImageMorph  regsitered me (a SimulatorMorphicModel ) with HandMorph>>addEventListener
HandMorph then broadcasts events to all registered listeners at this method. See HandMorph>>sendListenPrimitiveEvent
"
	morph ifNotNil:
		[(SimulatorEventTransformer default degenerateEvent: aMorphicEvent) ifNotNil:
			[:evtBuf|
			 ((evtBuf at: 1) = EventTypeMouse and: [morph bounds containsPoint: aMorphicEvent position]) ifTrue:
				[| xtranslated ytranslated |
				xtranslated :=  (evtBuf at:3) - (morph bounds left) - 2 .  "<--heh"  
				ytranslated :=  (evtBuf at:4) - (morph bounds top). 
				evtBuf at: 3 put: xtranslated.
				evtBuf at: 4 put: ytranslated].
			vm queueForwardedEvent: evtBuf]]
]

{ #category : #'buttons callbacks' }
SimulatorMorphicModel >> help [
	"Open up a workspace with explanatory info in it about the StackInterpreterSimulator"
	Workspace new
		contents: self helpText;
		openLabel: self windowTitle, ' Help'.
]

{ #category : #'buttons callbacks' }
SimulatorMorphicModel >> helpText [
	^(String streamContents: [:str |
		str nextPutAll:
'Stack Intepreter Simulator Help Contents Go Here.']) translated
]

{ #category : #'user interface' }
SimulatorMorphicModel >> initialExtent [
	^ 1286@938
]

{ #category : #'initialize-release' }
SimulatorMorphicModel >> initialize [
	
	title := 'StackInterpreter Simulator (Beta))'.
]

{ #category : #'buttons callbacks' }
SimulatorMorphicModel >> ioExit [
	vm ioExit
	displayView activeHand removeEventListener: self model.	"This is a bug as the user in vm ioExit may have cancelled the confirm t.m."
"^UserDialogBoxMorph inform: 'Toggle Transcript' title: 'TODO:'"
]

{ #category : #'buttons callbacks' }
SimulatorMorphicModel >> loadImage [
	^UserDialogBoxMorph inform: 'load image' title: 'TODO:'
]

{ #category : #accessing }
SimulatorMorphicModel >> morph [
	"I need the bounds of my morph for filtering mouse events.
       If there is a canned way of doing this besides this tight binding to my SimulatorMorph,
	then please refactor me.

      see my protocol event-forwarding for the gory details"
	self flag:'tty'.
	^morph.
]

{ #category : #accessing }
SimulatorMorphicModel >> morph: aMorph [
	"I need the bounds of my morph for filtering mouse events.
       If there is a canned way of doing this besides this tight binding to my SimulatorMorph,
	then please refactor me.

      see my protocol event-forwarding for the gory details"
	self flag:'tty'.
	morph := aMorph.
]

{ #category : #'user interface - squeakJS' }
SimulatorMorphicModel >> onItemClicked: anItem [
	"I am an item in the current context display on the SqueakJS tree view".
]

{ #category : #'buttons callbacks' }
SimulatorMorphicModel >> options [
^UserDialogBoxMorph inform: 'Options Popup--need checkboxes?' title: 'TODO:'
]

{ #category : #'buttons callbacks' }
SimulatorMorphicModel >> over [
	stepping:=true.
^UserDialogBoxMorph inform: 'Step Over' title: 'TODO:'
]

{ #category : #'user interface - squeakJS' }
SimulatorMorphicModel >> processesAndContextStack [
	"just a stub. see top right panel at http://lively-web.org/users/bert/squeak.html  for what I intend to present"
	self flag: 'tty'.
	^ 'Processes and ContextStack' printString asText

]

{ #category : #'buttons callbacks' }
SimulatorMorphicModel >> reset [
	^UserDialogBoxMorph inform: 'Reset' title: 'TODO:'
]

{ #category : #'buttons callbacks' }
SimulatorMorphicModel >> return [
^UserDialogBoxMorph inform: 'Return' title: 'TODO:'
]

{ #category : #'buttons callbacks' }
SimulatorMorphicModel >> run [
	stepping:=false.
	vm run
"^UserDialogBoxMorph inform: 'Run' title: 'TODO:'"
]

{ #category : #'buttons callbacks' }
SimulatorMorphicModel >> send [
^UserDialogBoxMorph inform: 'Send' title: 'TODO:'
]

{ #category : #'user interface - squeakJS' }
SimulatorMorphicModel >> specialObjectsAndActiveContext [
	"just a stub. see top left panel at http://lively-web.org/users/bert/squeak.html  for what I intend to present"
	self flag: 'tty'.
	^ 'Special Objects and Active Context' printString asText

]

{ #category : #'buttons callbacks' }
SimulatorMorphicModel >> step [
	stepping:=true.
^UserDialogBoxMorph inform: 'Step' title: 'TODO:'
]

{ #category : #accessing }
SimulatorMorphicModel >> stepping [
	^stepping
]

{ #category : #accessing }
SimulatorMorphicModel >> stepping: aBoolean [
	stepping := aBoolean
]

{ #category : #accessing }
SimulatorMorphicModel >> title: aString [
	title := aString
]

{ #category : #'buttons callbacks' }
SimulatorMorphicModel >> toggleTranscript [
	vm toggleTranscriptForSimulatorMorph: self transcript.
"^UserDialogBoxMorph inform: 'Toggle Transcript' title: 'TODO:'"
]

{ #category : #accessing }
SimulatorMorphicModel >> transcript [
	^vm transcript
]

{ #category : #accessing }
SimulatorMorphicModel >> transcript: aTranscriptStream [
	vm transcript: aTranscriptStream.
]

{ #category : #'user interface' }
SimulatorMorphicModel >> utilitiesMenu: aMenuMorph [ 
	^vm utilitiesMenu: aMenuMorph
]

{ #category : #accessing }
SimulatorMorphicModel >> vm [
	^vm
]

{ #category : #accessing }
SimulatorMorphicModel >> vm: aVMSimulator [
	vm := aVMSimulator
]

{ #category : #'user interface' }
SimulatorMorphicModel >> windowTitle [
	^ title translated
]
