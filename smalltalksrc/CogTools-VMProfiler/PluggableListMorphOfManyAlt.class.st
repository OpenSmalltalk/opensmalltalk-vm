"
A variant of its superclass that allows multiple items to be selected simultaneously.  There is still a distinguished element which is selected, but each other element in the list may be flagged on or off.  This is a clone of PluggableListMorphOfMany that sends the changePrimarySelection: selector only when the mouse is first pushed and sends the changeListSelection: selector while the mouse is being dragged.  This allows the model to choose to respond to a new selection by deselecting existing selections.  This differs from PluggableListMorphOfMany which sends both selectors all the time.
"
Class {
	#name : #PluggableListMorphOfManyAlt,
	#superclass : #PluggableListMorph,
	#instVars : [
		'dragOnOrOff',
		'getSelectionListSelector',
		'setSelectionListSelector',
		'currentRow'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #'instance creation' }
PluggableListMorphOfManyAlt class >> on: anObject list: listSel primarySelection: getSelectionSel changePrimarySelection: setSelectionSel listSelection: getListSel changeListSelection: setListSel getListElement: listElemSel menu: getMenuSel [
	^ self new
		on: anObject
		list: listSel
		primarySelection: getSelectionSel
		changePrimarySelection: setSelectionSel
		listSelection: getListSel
		changeListSelection: setListSel
		getListElement: listElemSel
		menu: getMenuSel
		keystroke: #arrowKey:from:		"default"
]

{ #category : #'instance creation' }
PluggableListMorphOfManyAlt class >> on: anObject list: listSel primarySelection: getSelectionSel changePrimarySelection: setSelectionSel listSelection: getListSel changeListSelection: setListSel menu: getMenuSel [
	^ self new
		on: anObject
		list: listSel
		primarySelection: getSelectionSel
		changePrimarySelection: setSelectionSel
		listSelection: getListSel
		changeListSelection: setListSel
		getListElement: nil "default"
		menu: getMenuSel
		keystroke: #arrowKey:from:		"default"
]

{ #category : #'instance creation' }
PluggableListMorphOfManyAlt class >> on: anObject list: listSel primarySelection: getSelectionSel changePrimarySelection: setSelectionSel listSelection: getListSel changeListSelection: setListSel menu: getMenuSel keystroke: keyActionSel [ 
	^ self new
		on: anObject
		list: listSel
		primarySelection: getSelectionSel
		changePrimarySelection: setSelectionSel
		listSelection: getListSel
		changeListSelection: setListSel
		getListElement: nil "default"
		menu: getMenuSel
		keystroke: keyActionSel
]

{ #category : #'model access' }
PluggableListMorphOfManyAlt >> getList [
	"Answer the list to be displayed.  Caches the returned list in the 'list' ivar"
	getListSelector == nil ifTrue: [^ #()].
	list := model perform: getListSelector.
	list == nil ifTrue: [^ #()].
	getListElementSelector ifNil:
		[list := list collect: [ :item | item asStringOrText ]].
	^ list
]

{ #category : #'model access' }
PluggableListMorphOfManyAlt >> itemSelectedAmongMultiple: index [
	^self listSelectionAt: index
]

{ #category : #initialization }
PluggableListMorphOfManyAlt >> list: listOfStrings [
	scroller removeAllMorphs.
	list := listOfStrings ifNil: [Array new].
	list isEmpty ifTrue: [^ self selectedMorph: nil].
	super list: listOfStrings.

	"At this point first morph is sensitized, and all morphs share same handler."
	scroller firstSubmorph on: #mouseEnterDragging
						send: #mouseEnterDragging:onItem:
						to: self.
	scroller firstSubmorph on: #mouseUp
						send: #mouseUp:onItem:
						to: self.
	"This should add this behavior to the shared event handler thus affecting all items"
]

{ #category : #drawing }
PluggableListMorphOfManyAlt >> listSelectionAt: index [
	getSelectionListSelector ifNil:[^false].
	^model perform: getSelectionListSelector with: index
]

{ #category : #drawing }
PluggableListMorphOfManyAlt >> listSelectionAt: index put: value [
	setSelectionListSelector ifNil:[^false].
	^model perform: setSelectionListSelector with: index with: value
]

{ #category : #'event handling' }
PluggableListMorphOfManyAlt >> mouseDown: event [
	| oldIndex oldVal row |
	Transcript cr; show: 'mouseDown:'.
	event yellowButtonPressed ifTrue: [^ self yellowButtonActivity: event shiftPressed].
	row := self rowAtLocation: event position.

	row = 0 ifTrue: [^super mouseDown: event].

	model okToChange ifFalse: [^ self].  "No change if model is locked"

	"Set meaning for subsequent dragging of selection"
	dragOnOrOff := (self listSelectionAt: row) not.
	currentRow := row.
	oldIndex := self getCurrentSelectionIndex.
	oldVal := oldIndex ~= 0 ifTrue: [self listSelectionAt: oldIndex] ifFalse: [false].

	"Need to restore the old one, due to how model works, and set new one."
	oldIndex ~= 0 ifTrue: [self listSelectionAt: oldIndex put: oldVal].

	"Set or clear new primary selection (listIndex)"
	self listSelectionAt: row put: oldVal not
]

{ #category : #'event handling' }
PluggableListMorphOfManyAlt >> mouseMove: event [ 
	"The mouse has moved, as characterized by the event provided.  Adjust the scrollbar, and alter the selection as appropriate"

	| row |
	Transcript cr; show: 'mouseMove:'.
	event position y < self top 
		ifTrue: 
			[scrollBar scrollUp: 1.
			row := self rowAtLocation: scroller topLeft + (1 @ 1)]
		ifFalse: 
			[row := event position y > self bottom 
				ifTrue: 
					[scrollBar scrollDown: 1.
					self rowAtLocation: scroller bottomLeft + (1 @ -1)]
				ifFalse: [ self rowAtLocation: event position]].
	row = 0 ifTrue: [^super mouseDown: event].

	model okToChange ifFalse: [^self].	"No change if model is locked"

	currentRow = row ifTrue:
		[^self].

	currentRow := row.

	dragOnOrOff ifNil: 
		["Don't treat a mouse move immediately after a mouse down to the same index."
		row = self getCurrentSelectionIndex ifTrue: [^self].

		"Was not set at mouse down, which means the mouse must have gone down in an area where there was no list item"
		 dragOnOrOff := (self listSelectionAt: row) not].

	"Set or clear new primary selection (listIndex)"
	dragOnOrOff 
		ifTrue: [self changeModelSelection: row]
		ifFalse: [self changeModelSelection: 0].

	row changed
]

{ #category : #'event handling' }
PluggableListMorphOfManyAlt >> mouseUp: event [

	dragOnOrOff := nil.  "So improperly started drags will have no effect"
	currentRow := nil	"So mouseMove won't trigger more than once"
]

{ #category : #initialization }
PluggableListMorphOfManyAlt >> on: anObject list: listSel primarySelection: getSelectionSel changePrimarySelection: setSelectionSel listSelection: getListSel changeListSelection: setListSel getListElement: listElemSel menu: getMenuSel keystroke: keyActionSel [
	"setup a whole load of pluggability options"
	getSelectionListSelector := getListSel.
	setSelectionListSelector := setListSel.
	getListElementSelector := listElemSel.
	self on: anObject list: listSel selected: getSelectionSel changeSelected: setSelectionSel menu: getMenuSel keystroke: keyActionSel

]

{ #category : #selection }
PluggableListMorphOfManyAlt >> scrollSelectionIntoView [
	"Make sure that the current selection is visible.
	 If the selections() will fit in the scroll region then scroll the selection(s)
	 to the middle of the visible region.  If it is larger, make the first part visible."
	| row rowBounds innerBounds i |
	(row := self getCurrentSelectionIndex) = 0 ifTrue:
		[^self].
	rowBounds := self listMorph drawBoundsForRow: row.
	innerBounds := self innerBounds.
	i := row + 1.
	[(model perform: getSelectionListSelector with: i)
	 and: [(self listMorph drawBoundsForRow: i) bottom - rowBounds top < innerBounds height]] whileTrue:
		[i := i + 1].
	rowBounds := rowBounds merge: (self listMorph drawBoundsForRow: i - 1).
	self scrollToShow: (innerBounds align: innerBounds center with: rowBounds center)
]

{ #category : #updating }
PluggableListMorphOfManyAlt >> update: aSymbol [ 
	aSymbol == #allSelections ifTrue:
		[^self updateList; selectionIndex: self getCurrentSelectionIndex].
	^super update: aSymbol
]
