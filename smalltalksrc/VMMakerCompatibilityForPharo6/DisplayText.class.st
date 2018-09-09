"
I represent Text whose emphasis changes are mapped to a set of fonts. My instances have an offset used in determining screen placement for displaying. They get used two different ways in the system. In the user interface, they mainly hold onto some text which is viewed by some form of ParagraphEditor. However, as a DisplayObject, they may need to display efficiently, so my instances have a cache for the bits.
"
Class {
	#name : #DisplayText,
	#superclass : #DisplayObject,
	#instVars : [
		'text',
		'textStyle',
		'offset',
		'form',
		'foreColor',
		'backColor'
	],
	#pools : [
		'TextConstants'
	],
	#category : #VMMakerCompatibilityForPharo6
}

{ #category : #examples }
DisplayText class >> example [
	"Continually prints two lines of text wherever you point with the cursor.  Terminate by pressing any button on the
	mouse."
	| tx |
	tx := 'this is a line of characters and
this is the second line.' asDisplayText.
	tx foregroundColor: Color black backgroundColor: Color transparent.
	tx := tx alignedTo: #center.
	[Sensor anyButtonPressed]
		whileFalse:
			[tx displayOn: Display at: Sensor cursorPoint]

	"DisplayText example."
]

{ #category : #'instance creation' }
DisplayText class >> text: aText [ 
	"Answer an instance of me such that the text displayed is aText 
	according to the system's default text style."

	^self new
		setText: aText
		textStyle: DefaultTextStyle copy
		offset: 0 @ 0
]

{ #category : #'instance creation' }
DisplayText class >> text: aText textStyle: aTextStyle [ 
	"Answer an instance of me such that the text displayed is aText 
	according to the style specified by aTextStyle."

	^self new
		setText: aText
		textStyle: aTextStyle
		offset: 0 @ 0
]

{ #category : #'instance creation' }
DisplayText class >> text: aText textStyle: aTextStyle offset: aPoint [ 
	"Answer an instance of me such that the text displayed is aText 
	according to the style specified by aTextStyle. The display of the 
	information should be offset by the amount given as the argument, 
	aPoint."

	^self new
		setText: aText
		textStyle: aTextStyle
		offset: aPoint
]

{ #category : #accessing }
DisplayText >> alignedTo: alignPointSelector [
	"Return a copy with offset according to alignPointSelector which is one of...
	#(topLeft, topCenter, topRight, leftCenter, center, etc)"
	| boundingBox |
	boundingBox := 0@0 corner: self form extent.
	^ self shallowCopy offset: (0@0) - (boundingBox perform: alignPointSelector)
]

{ #category : #color }
DisplayText >> backgroundColor [
	backColor == nil ifTrue: [^ Color transparent].
	^ backColor
]

{ #category : #'display box access' }
DisplayText >> boundingBox [ 
	"Refer to the comment in DisplayObject|boundingBox."

	^self form boundingBox
]

{ #category : #private }
DisplayText >> composeForm [
	| tmpText canvas |
	tmpText := TextMorph new contentsAsIs: self text deepCopy.
	self foregroundColor ifNotNil: [:color |
		tmpText text addAttribute: (TextColor color: color)].
	self backgroundColor ifNotNil: [:color |
		tmpText backgroundColor: color].
	tmpText setTextStyle: "displayText textStyle" TextStyle default.
	canvas := FormCanvas on: (Form extent: tmpText extent depth: 32).
	tmpText drawOn: canvas.
	form := canvas form
]

{ #category : #'display box access' }
DisplayText >> computeBoundingBox [ 
	"Compute minimum enclosing rectangle around characters."

	| character font width carriageReturn lineWidth lineHeight |
	carriageReturn := Character cr.
	width := lineWidth := 0.
	font := textStyle defaultFont.
	lineHeight := textStyle lineGrid.
	1 to: text size do: 
		[:i | 
		character := text at: i.
		character = carriageReturn
		  ifTrue: 
			[lineWidth := lineWidth max: width.
			lineHeight := lineHeight + textStyle lineGrid.
			width := 0]
		  ifFalse: [width := width + (font widthOf: character)]].
	lineWidth := lineWidth max: width.
	^offset extent: lineWidth @ lineHeight
]

{ #category : #displaying }
DisplayText >> displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipRectangle rule: ruleInteger fillColor: aForm [
	"For TT font, rule 34 is used if possible."
	"Refer to the comment in 
	DisplayObject|displayOn:at:clippingBox:rule:mask:."

	| form1 rule |
	form1 := self form.
	rule := (ruleInteger = Form over and: [backColor isTransparent])
				ifTrue: [form1 depth = 32 ifTrue: [rule := 34] ifFalse: [Form paint]]
				ifFalse: [ruleInteger].
	form1 depth = 32 ifTrue: [rule := 34].
	form1
		displayOn: aDisplayMedium
		at: aDisplayPoint + offset
		clippingBox: clipRectangle
		rule: rule
		fillColor: aForm
]

{ #category : #displaying }
DisplayText >> displayOn: aDisplayMedium transformation: displayTransformation clippingBox: clipRectangle align: alignmentPoint with: relativePoint rule: ruleInteger fillColor: aForm [ 
	"Refer to the comment in 
	DisplayObject|displayOn:transformation:clippingBox:align:with:rule:mask:."

	| absolutePoint |
	absolutePoint := displayTransformation applyTo: relativePoint.
	absolutePoint := absolutePoint x asInteger @ absolutePoint y asInteger.
	self displayOn: aDisplayMedium
		at: absolutePoint - alignmentPoint
		clippingBox: clipRectangle
		rule: ruleInteger
		fillColor: aForm
]

{ #category : #displaying }
DisplayText >> displayOnPort: aPort at: location [
	self form displayOnPort: aPort at: location + offset
]

{ #category : #accessing }
DisplayText >> fontsUsed [
	"Return a list of all fonts used currently in this text.  8/19/96 tk"

	^ text runs values asSet collect: [:each | textStyle fontAt: each]
]

{ #category : #color }
DisplayText >> foregroundColor [
	foreColor == nil ifTrue: [^ Color black].
	^ foreColor
]

{ #category : #color }
DisplayText >> foregroundColor: cf backgroundColor: cb [
	foreColor := cf.
	backColor := cb
]

{ #category : #accessing }
DisplayText >> form [ 
	"Answer the form into which the receiver's display bits are cached."

	form == nil ifTrue: [self composeForm].
	^form
]

{ #category : #accessing }
DisplayText >> lineGrid [
	"Answer the relative space between lines of the receiver's text."

	^textStyle lineGrid
]

{ #category : #accessing }
DisplayText >> numberOfLines [ 
	"Answer the number of lines of text in the receiver."

	^self height // text lineGrid
]

{ #category : #accessing }
DisplayText >> offset [ 
	"Refer to the comment in DisplayObject|offset."

	^offset
]

{ #category : #accessing }
DisplayText >> offset: aPoint [ 
	"Refer to the comment in DisplayObject|offset:."

	offset := aPoint
]

{ #category : #private }
DisplayText >> setText: aText textStyle: aTextStyle offset: aPoint [

	text := aText.
	textStyle := aTextStyle.
	offset := aPoint.
	form := nil
]

{ #category : #accessing }
DisplayText >> string [
	"Answer the string of the characters displayed by the receiver."

	^text string
]

{ #category : #accessing }
DisplayText >> text [ 
	"Answer the text displayed by the receiver."

	^text
]

{ #category : #accessing }
DisplayText >> text: aText [ 
	"Set the receiver to display the argument, aText."
	
	text := aText.
	form := nil.
	self changed.
	
]

{ #category : #accessing }
DisplayText >> textStyle [ 
	"Answer the style by which the receiver displays its text."

	^textStyle
]

{ #category : #accessing }
DisplayText >> textStyle: aTextStyle [ 
	"Set the style by which the receiver should display its text."

	textStyle := aTextStyle.
	form := nil.
	self changed.
	
]
