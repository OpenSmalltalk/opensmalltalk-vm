"
A StackInterpreterSimulatorMorphicModel handles Morphic callbacks and UI  for (some parts of ) the StackInterpreterSimulator.

I   handle event forwarding management..

Currently, I am a listener to HandMorphs>>addPrimitiveEventListener. 
I am added as a listener by StackInterpreterSimulatorMorph>>displayView (which probably  needs to change. tty)


instance vars:

stepping   when true the vm is running, but the user is stepping throught the stack--like a debugger. (not implemented: tty)


sharedPools: EventSensorConstants
"
Class {
	#name : #StackInterpreterSimulatorMorphicModel,
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
	#category : #'VMMaker-InterpreterSimulation-Morphic'
}

{ #category : #'class initialization' }
StackInterpreterSimulatorMorphicModel class >> initialize [
	"I want to keep it launchable by script only for now.
	Eliot has a bunch of options that aren't really feasible for a Morphic first approach.
	"
	"self
		registerWindowColor;
		registerInOpenMenu;
		registerInFlaps"
]

{ #category : #'instance creation' }
StackInterpreterSimulatorMorphicModel class >> on: aStackInterpreterSimulator title: aString transcript: aTranscriptStream [
	| simmodel |
	simmodel := self new.
	simmodel 
		vm: aStackInterpreterSimulator;
		title: aString;
		transcript: aTranscriptStream.
	^simmodel.	
]

{ #category : #'class initialization' }
StackInterpreterSimulatorMorphicModel class >> registerInFlaps [
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
StackInterpreterSimulatorMorphicModel class >> registerInOpenMenu [
	(TheWorldMenu respondsTo: #registerOpenCommand:) ifTrue: [
		TheWorldMenu unregisterOpenCommand: 'StackInterpreter Simulator'.
		TheWorldMenu registerOpenCommand: {'StackInterpreter Simulator'. {self. #open}}].
		
]

{ #category : #'class initialization' }
StackInterpreterSimulatorMorphicModel class >> registerWindowColor [
	(Preferences windowColorFor: self name) = Color white
		ifTrue: [ Preferences setWindowColorFor: self name to: (Color colorFrom: self windowColorSpecification brightColor) ].
]

{ #category : #'class initialization' }
StackInterpreterSimulatorMorphicModel class >> unload [
	self 
		unregisterFromOpenMenu;
		unregisterFromFlaps.
]

{ #category : #'class initialization' }
StackInterpreterSimulatorMorphicModel class >> unregisterFromFlaps [
	"Flaps 
		unregisterQuadsWithReceiver: self;
		replaceToolsFlap"
]

{ #category : #'class initialization' }
StackInterpreterSimulatorMorphicModel class >> unregisterFromOpenMenu [
	 (TheWorldMenu respondsTo: #registerOpenCommand:)
		ifTrue: [TheWorldMenu unregisterOpenCommand: 'StackInterpreter Simulator'].

]

{ #category : #'window color' }
StackInterpreterSimulatorMorphicModel class >> windowColorSpecification [
	"Answer a WindowColorSpec object that declares my preference"

	^ WindowColorSpec classSymbol: self name wording: 'StackInterpreter Simulator' brightColor: #(0.645 1.0 1.0)	pastelColor: #(0.886 1.0 1.0) helpMessage: 'A tool for simulating a Stack Interpreter Virtual Machine.'
]

{ #category : #accessing }
StackInterpreterSimulatorMorphicModel >> bounds [
	^morph bounds.
]

{ #category : #'user interface' }
StackInterpreterSimulatorMorphicModel >> byteCountText [
	^vm byteCountText
]

{ #category : #'user interface - squeakJS' }
StackInterpreterSimulatorMorphicModel >> currentContextStack [
	self flag: 'tty'.
	^ 'Current Context Stack' printString asText
]

{ #category : #accessing }
StackInterpreterSimulatorMorphicModel >> displayForm [
	^ vm displayForm
]

{ #category : #accessing }
StackInterpreterSimulatorMorphicModel >> displayView [
	^ vm displayView
]

{ #category : #accessing }
StackInterpreterSimulatorMorphicModel >> displayView: anImageMorph [
	vm displayView: anImageMorph
]

{ #category : #'buttons callbacks' }
StackInterpreterSimulatorMorphicModel >> forceInterruptCheck [
	vm forceInterruptCheck
"^UserDialogBoxMorph inform: 'Toggle Transcript' title: 'TODO:'"
]

{ #category : #'buttons callbacks' }
StackInterpreterSimulatorMorphicModel >> fullDisplayUpdate [
	vm fullDisplayUpdate
"^UserDialogBoxMorph inform: 'Toggle Transcript' title: 'TODO:'"
]

{ #category : #'buttons callbacks' }
StackInterpreterSimulatorMorphicModel >> hack [
	UserDialogBoxMorph inform: (morph bounds printString) title: 'Hack:'
]

{ #category : #'event-forwarding' }
StackInterpreterSimulatorMorphicModel >> handleListenEvent: aMorphicEvent [
"The StackInterpreterSimulatorImageMorph  regsitered me (a StackInterpreterSimulatorMorphicModel ) with HandMorph>>addEventListener
HandMorph then broadcasts events to all registered listeners at this method. See HandMorph>>sendListenPrimitiveEvent
"
	|evtBuf xtranslated ytranslated|
	morph
		ifNotNil:[
			evtBuf := (StackInterpreterSimulatorEventTransformer default) degenerateEvent: aMorphicEvent. 
			((evtBuf at: 1) = EventTypeMouse) & (morph bounds containsPoint: aMorphicEvent position)
				ifTrue:[
						xtranslated :=  (evtBuf at:3) - (morph bounds left) - 2 .  "<--heh"  
						ytranslated :=  (evtBuf at:4) - (morph bounds top). 
						evtBuf at: 3 put: xtranslated.
						evtBuf at: 4 put: ytranslated.
						vm queueForwardedEvent: evtBuf]]




]

{ #category : #'buttons callbacks' }
StackInterpreterSimulatorMorphicModel >> help [
	"Open up a workspace with explanatory info in it about the StackInterpreterSimulator"
	Workspace new
		contents: self helpText;
		openLabel: self windowTitle, ' Help'.
]

{ #category : #'buttons callbacks' }
StackInterpreterSimulatorMorphicModel >> helpText [
	^(String streamContents: [:str |
		str nextPutAll:
'Stack Intepreter Simulator Help Contents Go Here.']) translated
]

{ #category : #'user interface' }
StackInterpreterSimulatorMorphicModel >> initialExtent [
	^ 1286@938
]

{ #category : #'initialize-release' }
StackInterpreterSimulatorMorphicModel >> initialize [
	
	title := 'StackInterpreter Simulator (Beta))'.
]

{ #category : #'buttons callbacks' }
StackInterpreterSimulatorMorphicModel >> ioExit [
	vm ioExit
	displayView activeHand removeEventListener: self model.	"This is a bug as the user in vm ioExit may have cancelled the confirm t.m."
"^UserDialogBoxMorph inform: 'Toggle Transcript' title: 'TODO:'"
]

{ #category : #'buttons callbacks' }
StackInterpreterSimulatorMorphicModel >> loadImage [
	^UserDialogBoxMorph inform: 'load image' title: 'TODO:'
]

{ #category : #accessing }
StackInterpreterSimulatorMorphicModel >> morph [
	"I need the bounds of my morph for filtering mouse events.
       If there is a canned way of doing this besides this tight binding to my StackInterpreterSimulatorMorph,
	then please refactor me.

      see my protocol event-forwarding for the gory details"
	self flag:'tty'.
	^morph.
]

{ #category : #accessing }
StackInterpreterSimulatorMorphicModel >> morph: aMorph [
	"I need the bounds of my morph for filtering mouse events.
       If there is a canned way of doing this besides this tight binding to my StackInterpreterSimulatorMorph,
	then please refactor me.

      see my protocol event-forwarding for the gory details"
	self flag:'tty'.
	morph := aMorph.
]

{ #category : #'user interface - squeakJS' }
StackInterpreterSimulatorMorphicModel >> onItemClicked: anItem [
	"I am an item in the current context display on the SqueakJS tree view".
]

{ #category : #'buttons callbacks' }
StackInterpreterSimulatorMorphicModel >> options [
^UserDialogBoxMorph inform: 'Options Popup--need checkboxes?' title: 'TODO:'
]

{ #category : #'buttons callbacks' }
StackInterpreterSimulatorMorphicModel >> over [
	stepping:=true.
^UserDialogBoxMorph inform: 'Step Over' title: 'TODO:'
]

{ #category : #'user interface - squeakJS' }
StackInterpreterSimulatorMorphicModel >> processesAndContextStack [
	"just a stub. see top right panel at http://lively-web.org/users/bert/squeak.html  for what I intend to present"
	self flag: 'tty'.
	^ 'Processes and ContextStack' printString asText

]

{ #category : #'buttons callbacks' }
StackInterpreterSimulatorMorphicModel >> reset [
	^UserDialogBoxMorph inform: 'Reset' title: 'TODO:'
]

{ #category : #'buttons callbacks' }
StackInterpreterSimulatorMorphicModel >> return [
^UserDialogBoxMorph inform: 'Return' title: 'TODO:'
]

{ #category : #'buttons callbacks' }
StackInterpreterSimulatorMorphicModel >> run [
	stepping:=false.
	vm run
"^UserDialogBoxMorph inform: 'Run' title: 'TODO:'"
]

{ #category : #'buttons callbacks' }
StackInterpreterSimulatorMorphicModel >> send [
^UserDialogBoxMorph inform: 'Send' title: 'TODO:'
]

{ #category : #'user interface - squeakJS' }
StackInterpreterSimulatorMorphicModel >> specialObjectsAndActiveContext [
	"just a stub. see top left panel at http://lively-web.org/users/bert/squeak.html  for what I intend to present"
	self flag: 'tty'.
	^ 'Special Objects and Active Context' printString asText

]

{ #category : #'buttons callbacks' }
StackInterpreterSimulatorMorphicModel >> step [
	stepping:=true.
^UserDialogBoxMorph inform: 'Step' title: 'TODO:'
]

{ #category : #accessing }
StackInterpreterSimulatorMorphicModel >> stepping [
	^stepping
]

{ #category : #accessing }
StackInterpreterSimulatorMorphicModel >> stepping: aBoolean [
	stepping := aBoolean
]

{ #category : #accessing }
StackInterpreterSimulatorMorphicModel >> title: aString [
	title := aString
]

{ #category : #'buttons callbacks' }
StackInterpreterSimulatorMorphicModel >> toggleTranscript [
	vm toggleTranscriptForSimulatorMorph: self transcript.
"^UserDialogBoxMorph inform: 'Toggle Transcript' title: 'TODO:'"
]

{ #category : #accessing }
StackInterpreterSimulatorMorphicModel >> transcript [
	^vm transcript
]

{ #category : #accessing }
StackInterpreterSimulatorMorphicModel >> transcript: aTranscriptStream [
	vm transcript: aTranscriptStream.
]

{ #category : #'user interface' }
StackInterpreterSimulatorMorphicModel >> utilitiesMenu: aMenuMorph [ 
	^vm utilitiesMenu: aMenuMorph
]

{ #category : #accessing }
StackInterpreterSimulatorMorphicModel >> vm [
	^vm
]

{ #category : #accessing }
StackInterpreterSimulatorMorphicModel >> vm: aVMSimulator [
	vm := aVMSimulator
]

{ #category : #'user interface' }
StackInterpreterSimulatorMorphicModel >> windowTitle [
	^ title translated
]
