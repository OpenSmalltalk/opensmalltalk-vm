"
This class is a much simpler implementation of Transcript protocol that supports multiple views and very simple conversion to morphic.  Because it inherits from Stream, it is automatically compatible with code that is designed to write to streams.
"
Class {
	#name : #TranscriptStream,
	#superclass : #WriteStream,
	#instVars : [
		'lastChar'
	],
	#classVars : [
		'AccessSema',
		'CharacterLimit',
		'ForceUpdate',
		'RedirectToStdOut'
	],
	#category : #VMMakerLoadingDependencies
}

{ #category : #preferences }
TranscriptStream class >> characterLimit [
	<preference: 'Maximum number of characters in a transcript'
		categoryList: #(printing morphic debug)
		description: 'When the number of characters in a transcript exceeds this limit, characters at the start of the text are discarded.'
		type: #Number>
	^CharacterLimit ifNil: [20000]
]

{ #category : #preferences }
TranscriptStream class >> characterLimit: anInteger [

	CharacterLimit := anInteger.
]

{ #category : #preferences }
TranscriptStream class >> forceUpdate [

	<preference: 'Force transcript updates to screen'
		categoryList: #(printing morphic debug)
		description: 'When enabled, transcript updates will immediately shown in the screen no matter how busy the UI process is.'
		type: #Boolean>
	^ ForceUpdate ifNil: [true]
]

{ #category : #preferences }
TranscriptStream class >> forceUpdate: aBoolean [

	ForceUpdate := aBoolean.
]

{ #category : #'class initialization' }
TranscriptStream class >> initialize [

	self registerInFlapsRegistry.	
]

{ #category : #'instance creation' }
TranscriptStream class >> new [
	^ self on: (String new: 1000)
"
INSTALLING:
TextCollector allInstances do:
	[:t | t breakDependents.
	t become: TranscriptStream new].

TESTING: (Execute this text in a workspace)
Do this first...
	tt := TranscriptStream new.
	tt openLabel: 'Transcript test 1'.
Then this will open a second view -- ooooh...
	tt openLabel: 'Transcript test 2'.
And finally make them do something...
	tt clear.
	[Sensor anyButtonPressed] whileFalse:
		[1 to: 20 do: [:i | tt print: (2 raisedTo: i-1); cr; endEntry]].
"
]

{ #category : #'instance creation' }
TranscriptStream class >> newTranscript: aTextCollector [ 
	"Store aTextCollector as the value of the system global Transcript."
	Smalltalk at: #Transcript put: aTextCollector
]

{ #category : #preferences }
TranscriptStream class >> redirectToStdOut [
	<preference: 'Redirect transcript to stdout'
		categoryList: #(printing morphic debug)
		description: 'When enabled, anything sent to the transcript will be redirected to the stdout stream and (hopefully) the OS terminal.'
		type: #Boolean>
	^ RedirectToStdOut ifNil: [false]
]

{ #category : #preferences }
TranscriptStream class >> redirectToStdOut: aBoolean [
	"In setting up redirection, first remove all dependents that are stdout,
	 which may include stale files from the last session.  Then add a dependency
	 only if asked to redirect to stdout. Blithely doing
		Transcript removeDependent: FileStream stdout
	 raises an error if stdout is unavailable."
	Transcript dependents do:
		[:dep|
		 (dep isStream and: [dep name = #stdout]) ifTrue:
			[Transcript removeDependent: dep]].
	(RedirectToStdOut := aBoolean) ifTrue:
		[Transcript addDependent: FileStream stdout]
]

{ #category : #'class initialization' }
TranscriptStream class >> registerInFlapsRegistry [
	"Register the receiver in the system's flaps registry"
	self environment
		at: #Flaps
		ifPresent: [:cl | cl registerQuad: {#TranscriptStream. #openMorphicTranscript.	'Transcript' translatedNoop.			'A Transcript is a window usable for logging and debugging; browse references to #Transcript for examples of how to write to it.' translatedNoop}
						forFlapNamed: 'Tools']

]

{ #category : #preferences }
TranscriptStream class >> themeProperties [
	
	^ Model themeProperties
]

{ #category : #'class initialization' }
TranscriptStream class >> unload [
	"Unload the receiver from global registries"

	self environment at: #Flaps ifPresent: [:cl |
	cl unregisterQuadsWithReceiver: self] 
]

{ #category : #'model protocol' }
TranscriptStream >> applyUserInterfaceTheme [

	self dependents do: [:ea |
		ea isSystemWindow ifTrue: [
			ea refreshWindowColor]].
]

{ #category : #'stream extensions' }
TranscriptStream >> bs [
	self position > 0 ifTrue: [^ self skip: -1].
	self changed: #bs
]

{ #category : #accessing }
TranscriptStream >> characterLimit [
	"Tell the views how much to retain on screen"
	^self class characterLimit
]

{ #category : #'stream extensions' }
TranscriptStream >> clear [
	"Clear all characters and redisplay the view"
	self changed: #clearText.
	self reset
]

{ #category : #initialization }
TranscriptStream >> closeAllViews [
	"Transcript closeAllViews"

	self changed: #close

]

{ #category : #'Tools compatibility' }
TranscriptStream >> codePaneMenu: aMenu shifted: shifted [
	"Note that unless we override perform:orSendTo:, PluggableTextController will respond to all menu items"

	| donorMenu |
	donorMenu := shifted
						ifTrue: [SmalltalkEditor shiftedYellowButtonMenu]
						ifFalse: [SmalltalkEditor yellowButtonMenu].
	^aMenu addAllFrom: donorMenu
]

{ #category : #accessing }
TranscriptStream >> contents [
	"Override to update lastChar."
	position > 0 ifTrue:
		[lastChar := collection at: position].
	^super contents
]

{ #category : #private }
TranscriptStream >> countOpenTranscripts [
	"Transcript countOpenTranscripts"

	^ (self dependents select: [:e | e isTextView]) size

]

{ #category : #'stream extensions' }
TranscriptStream >> endEntry [
	"Display all the characters since the last endEntry, and reset the stream"
	self semaphore critical:[
		self class forceUpdate
			ifTrue: [self changed: #appendEntry]
			ifFalse: [self changed: #appendEntryLater].
		self reset.
	].
]

{ #category : #'stream extensions' }
TranscriptStream >> flush [
	self endEntry

]

{ #category : #'stream extensions' }
TranscriptStream >> nextPut: anObject [ 
	self target == self ifFalse: [self target nextPut: anObject]. "delegated to stdout"
	^ super nextPut: anObject.
]

{ #category : #'stream extensions' }
TranscriptStream >> nextPutAll: aCollection [
	self target == self ifFalse: [self target nextPutAll: aCollection]. "delegated to stdout"
	^ super nextPutAll: aCollection.
]

{ #category : #'stream extensions' }
TranscriptStream >> pastEndPut: anObject [
	"If the stream reaches its limit, just output the contents and reset."
	self endEntry.
	^ self nextPut: anObject
]

{ #category : #'character writing' }
TranscriptStream >> peekLast [
	"Return that item just put at the end of the stream"

	^ position > 0 
		ifTrue: [collection at: position]
		ifFalse: [lastChar]
]

{ #category : #'model protocol' }
TranscriptStream >> perform: selector orSendTo: otherTarget [
	"Selector was just chosen from a menu by a user.  If can respond, then
perform it on myself. If not, send it to otherTarget, presumably the
editPane from which the menu was invoked."

	(self respondsTo: selector)
		ifTrue: [^ self perform: selector]
		ifFalse: [^ otherTarget perform: selector]
]

{ #category : #'model protocol' }
TranscriptStream >> release [

	self dependents do:
		[:view | (view isMorph and: [view isInWorld not])
					ifTrue: [self removeDependent: view]]
]

{ #category : #positioning }
TranscriptStream >> reset [
	"Override to set lastChar"
	position > 0 ifTrue:
		[lastChar := collection at: position].
	^super reset
]

{ #category : #private }
TranscriptStream >> semaphore [
	^AccessSema ifNil:[AccessSema := Semaphore forMutualExclusion]
]

{ #category : #'stream extensions' }
TranscriptStream >> show: anObject [
	"TextCollector compatibility"
	
	[
		self nextPutAll: anObject asString.
		self endEntry
	] on: FileWriteError do: [self class redirectToStdOut: false].
]

{ #category : #'stream extensions' }
TranscriptStream >> showln: anObject [
	"TextCollector compatibility. Ensure a new line before inserting a message."
	
	[
		self
			cr;
			nextPutAll: anObject asString.
		self endEntry.
	] on: FileWriteError do: [self class redirectToStdOut: false].
]

{ #category : #'model protocol' }
TranscriptStream >> step [
	"Objects that may be models of SystemWindows need to respond to this, albeit vacuously"
]

{ #category : #'stream extensions' }
TranscriptStream >> target [

	^ self class redirectToStdOut
		ifTrue: [FileStream stdout]
		ifFalse: [self]
]

{ #category : #'model protocol' }
TranscriptStream >> windowActiveOnFirstClick [

	^ Model windowActiveOnFirstClick
]

{ #category : #'model protocol' }
TranscriptStream >> windowColorToUse [

	^ Color colorFrom: (Model useColorfulWindows
		ifTrue: [self userInterfaceTheme customWindowColor ifNil: [Color r: 0.9 g: 0.75 b: 0.45]]
		ifFalse: [self userInterfaceTheme uniformWindowColor ifNil: [Color veryVeryLightGray]])
]
