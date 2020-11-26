"
A SimulatorImageMorph is an ImageMorph that suppresses halos.
"
Class {
	#name : #SimulatorImageMorph,
	#superclass : #ImageMorph,
	#category : #'VMMaker-Tools-Old'
}

{ #category : #geometry }
SimulatorImageMorph >> extent: aPoint [
	"Override to restore the default resizing behaviour."
	^self perform: #extent: withArguments: {aPoint} inSuperclass: ImageMorph superclass
]

{ #category : #'event handling' }
SimulatorImageMorph >> handleMouseDown: anEvent [
	anEvent wasHandled: true
]

{ #category : #'event handling' }
SimulatorImageMorph >> handleMouseEnter: anEvent [
	anEvent wasHandled: true
]

{ #category : #'event handling' }
SimulatorImageMorph >> handleMouseLeave: anEvent [
	^super handleMouseLeave: anEvent
]

{ #category : #'event handling' }
SimulatorImageMorph >> handleMouseOver: anEvent [
	anEvent wasHandled: true
]

{ #category : #'event handling' }
SimulatorImageMorph >> handleMouseUp: anEvent [
	anEvent wasHandled: true
]

{ #category : #'event handling' }
SimulatorImageMorph >> handlerForMouseDown: anEvent [
	"Override all mouse button shenanigans like halos by handling any and all mouse down events."
	^self
]
