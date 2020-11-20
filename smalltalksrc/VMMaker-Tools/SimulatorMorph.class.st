"
A SimulatorMorph is a copy of PreferenceBrowserMorph that has been mangled into something that will support the simulator.  I provide some UI features inspired by Bert Freudenberg's Lively Squeak VM at http://lively-web.org/users/bert/squeak.html.

See class protocol 'documentation' for examples of invoking me.

My model is SimulatorMorphicModel. 
My model has a reference to the Simulator and itermediates all (?) interaction with it.

The simulator renders the simulated World on a SimulatorImageMorph that I contain. 

There is some cruft (tight coupling via direct references along all three layers UI-Model-VM) in me that exists to support Eliot's original Simulator>>openAsMorph functionality and use-case.
Rumors that said cruft is an artifact of tty's rudimentary Morphic skills are entirely credible.

I hold out the barest glimmer of hope that Bert Freudenberg's SqueakJS functionality can be integrated into my functionality as well. 
see http://lively-web.org/users/bert/squeak.html for the inspiration.

I am not amenable to Flaps or the WorldMenu as there is a lot of pre-run configuration that is done to the Simulator prior to its being run.
Managing that ability with a GUI is counter-productive. If said functionality is desired in the future, then inspiration can be gleaned by cut-n-paste from PreferenceBrowser and PreferenceBrowserModel.
"
Class {
	#name : #SimulatorMorph,
	#superclass : #SystemWindow,
	#instVars : [
		'loadButton',
		'helpButton',
		'resetButton',
		'stepButton',
		'overButton',
		'sendButton',
		'returnButton',
		'runButton',
		'toggleTranscriptButton',
		'optionsButton',
		'transcriptPanel',
		'commandPanel',
		'contextPanel',
		'stackPanel',
		'callStackPanel',
		'displayForm',
		'displayView',
		'eventEncoder',
		'ioExitButton',
		'fullDisplayUpdateButton',
		'forceInterruptCheckButton',
		'hackButton'
	],
	#category : #'VMMaker-Tools-Old'
}

{ #category : #documentation }
SimulatorMorph class >> ttyOne [
"Script tty uses to run the stackIntepreter using this class"
| vm |
Transcript clear.
vm := StackInterpreterSimulator newWithOptions: #(#STACKVM).
vm openOn: '/home/tty/usr/src/smalltalk/buildCogDevelopmentImageCog.app/Contents/Resources/targets/Squeak4.5.image'.
"vm setBreakSelector: #&."
vm 
	openAsSimulatorMorph "; 
	toggleTranscript;
	halt;
	run"

]

{ #category : #'instance creation' }
SimulatorMorph class >> withVMSimulator: aSimulatorMorphicModel title: aString transcript: aTranscript [
	^self new initializeWithVMSimulator: aSimulatorMorphicModel title: aString aTranscript: aTranscript;
		yourself.
		

]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> basicButton [
	| button |
	button := SimpleButtonMorph new.
	button
		borderWidth: 2;
		borderColor: #raised;
		on: #mouseEnter send: #value to: [button borderColor: self paneColor];
		on: #mouseLeave send: #value to: [button borderColor: #raised];
		vResizing: #spaceFill;
		useRoundedCorners;
		clipSubmorphs: true;
		color: self paneColor muchLighter;
		target: self model.
	^button
]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> buttonRowLayoutFrame [ 
	^LayoutFrame fractions: (0@0 corner: 1@0) offsets: (0@0 corner: 0@ (TextStyle defaultFont height * 2.5))

]

{ #category : #'submorphs - squeakJS' }
SimulatorMorph >> callStackPanel [
	"If any Morphic gurus exist, please have at it."
	^callStackPanel ifNil: 
		[callStackPanel :=  (PluggableTextMorph
				on: self model
				text: #processesAndContextStack
				accept: nil
				readSelection: nil
				menu: nil) hideScrollBarsIndefinitely.
		callStackPanel		
			color: Color transparent;
			hResizing: #spaceFill;
			vResizing: #spaceFill;
			cellInset: 5;
			yourself].


]

{ #category : #'submorphs - simulator panel' }
SimulatorMorph >> commandPanel [
	self flag: 'tty'. "does this hybrid of PreferenceBrowser layout and Simulato openAsMorph stuff make sense?"
	^commandPanel ifNil: 
		[commandPanel :=  (PluggableTextMorph
				on: self model vm
				text: #byteCountText
				accept: nil
				readSelection: nil
				menu: #utilitiesMenu:) hideScrollBarsIndefinitely.
		commandPanel		
			color: Color transparent;
			hResizing: #spaceFill;
			vResizing: #spaceFill;
			cellInset: 5;
			yourself].

]

{ #category : #'submorphs - squeakJS' }
SimulatorMorph >> contextPanel [
	"This should show the currentContext and Special Objects array. as seen at SqueakJS
	  Doing that requires real talent. talent tty is lacking at the moment
							on: [ Array with:  (MorphWithSubmorphsWrapper with: self)  ]	
	Array with: (ObjectExplorerWrapper with: rootObject name: 'root' model: self parent: nil)
	"
	^contextPanel ifNil: 
		[contextPanel := (SimpleHierarchicalListMorph
							on: [ Array with: (ObjectExplorerWrapper with: (self model vm) name: 'root' model: (self model vm) parent: nil) ]
							list: #value
							selected: nil
							changeSelected: nil
							menu: nil
							keystroke: nil) showScrollBarsOnlyWhenNeeded: true.
		contextPanel		
			color: Color transparent;
			hResizing: #spaceFill;
			vResizing: #spaceFill;
			cellInset: 5;
			yourself]



]

{ #category : #'submorphs - simulator display view' }
SimulatorMorph >> displayView [
	"The VM SImulator draws directly on an imageMorph named displayView
	  displayView is housed on a Form named displayForm
	   displayForm is initialized in StackInterpreterSimulator >> initialize.
	  see StackInterpreterSimulator >>openAsMorph for original constructs."
	^displayView ifNil: 
		[displayView :=  SimulatorImageMorph new image: model vm displayForm. 
		self model displayView: displayView.					
		self model morph: displayView. "<-- N.B.. morph bounds are used to filter events in the model. tty"
	      displayView activeHand addEventListener: self model.		

 		displayView		
			color: Color transparent;
			hResizing: #spaceFill;
			vResizing: #spaceFill;
			cellInset: 5;
			yourself]
]

{ #category : #'submorphs - simulator display view' }
SimulatorMorph >> displayViewLayoutFrame [ 
	| squeakJSFrame buttonFrame simulatorFrame|
	"if any Morphic guru's understand layouts and offsets, please fix this. tty"
	buttonFrame := self buttonRowLayoutFrame.
	squeakJSFrame := self squeakJSRowLayoutFrame.
	simulatorFrame := self simulatorLayoutFrame.
	^LayoutFrame fractions: (0@0 corner: 1@1) 
				    offsets: (0@(buttonFrame bottomOffset) corner: simulatorFrame leftOffset@squeakJSFrame topOffset)
]

{ #category : #geometry }
SimulatorMorph >> extent: aPoint [
	super extent: aPoint.
	self fullBounds.

]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> forceInterruptCheckButton [
	self flag: 'tty'.
	^forceInterruptCheckButton ifNil: 
		[forceInterruptCheckButton := self basicButton 
						label: 'vm forceInterruptCheck' translated; 
						actionSelector: #forceInterruptCheck;						
						setBalloonText: 
							'Invoke forceInterruptCheck on Simulator.' translated]
]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> fullDisplayUpdateButton [
	self flag: 'tty'.
	^fullDisplayUpdateButton ifNil: 
		[fullDisplayUpdateButton := self basicButton 
						label: 'vm fullDisplayUpdate' translated; 
						actionSelector: #fullDisplayUpdate;						
						setBalloonText: 
							'Invoke fullDisplayUpdate on Simulator.' translated]
]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> hackButton [
	self flag: 'tty'.
	^hackButton ifNil: 
		[hackButton := self basicButton 
						label: 'Display ImageMorph Bounds' translated; 
						actionSelector: #hack;						
						setBalloonText: 
							'tty needs a hack button.' translated]
]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> helpButton [
	^helpButton ifNil: 
		[helpButton := self basicButton 
						label: 'help' translated; 
						setBalloonText: 
							'Click here to get some hints on use of me ',
							'Panel' translated;
						actionSelector: #help]
]

{ #category : #initialization }
SimulatorMorph >> initializeWithVMSimulator: aStackInterpreterSimulator title: aString aTranscript: aTranscript [
	self flag: 'tty'. "need to get the layout right at this point. resizers and scroll bars would be nice. Layout offsets need a gimlet eye as well"
	self 
		model: (SimulatorMorphicModel on: aStackInterpreterSimulator title: aString transcript: aTranscript);
		clipSubmorphs: true;
		setLabel: self model windowTitle;
		name: aString;
		addMorph: self newButtonRow fullFrame: self buttonRowLayoutFrame;
		addMorph: self squeakJSRow fullFrame: self squeakJSRowLayoutFrame;
		addMorph: self simulatorPanel fullFrame: self simulatorLayoutFrame;
		addMorph: self displayView fullFrame: self displayViewLayoutFrame.	
	^self
]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> ioExitButton [
	self flag: 'tty'.
	^ioExitButton ifNil: 
		[ioExitButton := self basicButton 
						label: 'vm ioExit' translated; 
						actionSelector: #ioExit;						
						setBalloonText: 
							'Invoke ioExit on Simulator.' translated]
]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> loadButton [
	^loadButton ifNil: 
		[loadButton := self basicButton 
						label: 'Load Image' translated; 
						actionSelector: #loadImage;						
						setBalloonText: 
							'Select an image to load.' translated]
]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> newButtonRow [
	^BorderedMorph new
		color: Color transparent;
		cellInset: 2;
		layoutInset: 2;
		layoutPolicy: TableLayout new;
		listDirection: #leftToRight;
		listCentering: #topLeft;
		cellPositioning: #topLeft;
		on: #mouseEnter send: #paneTransition: to: self;
		on: #mouseLeave send: #paneTransition: to: self;
		addMorphBack: self hackButton;
		addMorphBack: self newSeparator;

"		addMorphBack: self resetButton;
		addMorphBack: self newSeparator;
		addMorphBack: self forceInterruptCheckButton;
		addMorphBack: self newSeparator;
		addMorphBack: self fullDisplayUpdateButton;
		addMorphBack: self newSeparator;
		addMorphBack: self toggleTranscriptButton;"  
		addMorphBack: self runButton;				
		addMorphBack: self newSeparator; 
		addMorphBack: self ioExitButton;
		addMorphBack: self newTransparentFiller;		
		addMorphBack: self stepButton;
		addMorphBack: self newSeparator;		
		addMorphBack: self overButton;
		addMorphBack: self newSeparator;
		addMorphBack: self newSeparator;		
		addMorphBack: self sendButton;
		addMorphBack: self newSeparator;		
		addMorphBack: self returnButton;		
		addMorphBack: self newTransparentFiller;
"		addMorphBack: self loadButton;
		addMorphBack: self newSeparator;				
		addMorphBack: self optionsButton;     too complex to implement now. See StackInterpreterSimulator class comment for examples"										
		addMorphBack: self newTransparentFiller;
		addMorphBack: self helpButton;
		yourself.
]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> newSeparator [
	^BorderedMorph new
		borderWidth: 2;
		borderColor: Color transparent;
		color: self paneColor;
		hResizing: #rigid;
		width: 5;
		vResizing: #spaceFill;
		yourself
]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> newTransparentFiller [
	^Morph new
		color: Color transparent;
		vResizing: #spaceFill;
		hResizing: #spaceFill;
		yourself.
]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> optionsButton [
	^optionsButton ifNil: 
		[optionsButton := self basicButton 
						label: 'VM Options' translated; 
						actionSelector: #options;						
						setBalloonText: 
							'VM Options.' translated]
]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> overButton [
	^overButton ifNil: 
		[overButton := self basicButton 
						label: 'Over' translated; 
						actionSelector: #over;						
						setBalloonText: 
							'Step Over.' translated]
]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> resetButton [
	^resetButton ifNil: 
		[resetButton := self basicButton 
						label: 'Reset' translated; 
						actionSelector: #reset;						
						setBalloonText: 
							'Reset running simulation.' translated]
]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> returnButton [
	self flag: 'tty'.
	^returnButton ifNil: 
		[returnButton := self basicButton 
						label: 'Return' translated; 
						actionSelector: #return;						
						setBalloonText: 
							'Return from what?.' translated]
]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> runButton [
	self flag: 'tty'.
	^runButton ifNil: 
		[runButton := self basicButton 
						label: 'vm run' translated; 
						actionSelector: #run;						
						setBalloonText: 
							'Run Simulation.' translated]
]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> sendButton [
	self flag: 'tty'.
	^sendButton ifNil: 
		[sendButton := self basicButton 
						label: 'Send' translated; 
						actionSelector: #send;						
						setBalloonText: 
							'Send what exactly?.' translated]
]

{ #category : #'submorphs - simulator panel' }
SimulatorMorph >> simulatorLayoutFrame [ 
	| squeakJSFrame buttonFrame |
	"I don't understand offsets in the LayoutFrame. I just fiddled until it looked ok. If anybody knows what they are doing, please refactor."
	self flag: 'tty'.
	buttonFrame := self buttonRowLayoutFrame.
	squeakJSFrame := self squeakJSRowLayoutFrame.
	^LayoutFrame fractions: (0.7@0 corner: 1@squeakJSFrame topOffset) 
				    offsets: (0@(buttonFrame bottomOffset) corner: 0.70@squeakJSFrame topOffset)

]

{ #category : #'submorphs - simulator panel' }
SimulatorMorph >> simulatorPanel [
	"standard controls from StackInterpreterSimulator >> openAsMorph"
	^BorderedMorph new
		color: Color transparent;
		layoutInset: 10;
		cellInset: 10;
		layoutPolicy: TableLayout new;
		listDirection: #topToBottom;
		listCentering: #topLeft;
		cellPositioning: #topLeft;
		on: #mouseEnter send: #paneTransition: to: self;
		on: #mouseLeave send: #paneTransition: to: self;		
		addMorphBack: self transcriptPanel;
		addMorphBack: self commandPanel;
		yourself.
]

{ #category : #'submorphs - squeakJS' }
SimulatorMorph >> squeakJSRow [
	"row fo SqueakJS context, stack and call-stack panels"
	^BorderedMorph new
		color: Color blue;
		cellInset: 2;
		layoutInset: 2;
		layoutPolicy: TableLayout new;
		listDirection: #leftToRight;
		listCentering: #topLeft;
		cellPositioning: #topLeft;
		on: #mouseEnter send: #paneTransition: to: self;
		on: #mouseLeave send: #paneTransition: to: self;
		addMorphBack: self callStackPanel;
		addMorphBack: self contextPanel;
		addMorphBack: self stackPanel;		
		yourself.
]

{ #category : #'submorphs - squeakJS' }
SimulatorMorph >> squeakJSRowLayoutFrame [ 
	^LayoutFrame fractions: (0@0.8 corner: 1@1) offsets: (0@0.8 corner: 1@ (TextStyle defaultFont height * 2.5))

]

{ #category : #'submorphs - squeakJS' }
SimulatorMorph >> stackPanel [
	"If any Morphic gurus exist, please have at it."
	^stackPanel ifNil: 
		[stackPanel :=  (PluggableTextMorph
				on: self model
				text: #currentContextStack
				accept: nil
				readSelection: nil
				menu: nil) hideScrollBarsIndefinitely.
		stackPanel		
			color: Color transparent;
			hResizing: #spaceFill;
			vResizing: #spaceFill;
			cellInset: 5;
			yourself].


]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> stepButton [
	self flag: 'tty'.
	^stepButton ifNil: 
		[stepButton := self basicButton 
						label: 'Step' translated; 
						actionSelector: #step;						
						setBalloonText: 
							'Step Into.' translated]
]

{ #category : #'submorphs - buttons' }
SimulatorMorph >> toggleTranscriptButton [
	"tty I dont like this. I have diabled the button"
	self flag: 'tty'.
	^toggleTranscriptButton ifNil: 
		[toggleTranscriptButton := self basicButton 
						label: 'Toggle Transcript' translated; 
						actionSelector: #toggleTranscript;						
						setBalloonText: 
							'Use External Transcript Instead of Internal.' translated]
]

{ #category : #'submorphs - simulator panel' }
SimulatorMorph >> transcriptPanel [
	self flag: 'tty'. "does this hybrid of PreferenceBrowser layout and Simulato openAsMorph stuff make sense?"
	^transcriptPanel ifNil: 
		[transcriptPanel := (PluggableTextMorph
				on:  self model vm transcript
				text: nil
				accept: nil
				readSelection: nil
				menu: #codePaneMenu:shifted:).
		transcriptPanel	
			name: 'transcriptPanel';	
			color: Color transparent;
			hResizing: #spaceFill;
			vResizing: #spaceFill;
			cellInset: 5;
			yourself].

]
