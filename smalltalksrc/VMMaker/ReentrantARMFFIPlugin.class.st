Class {
	#name : #ReentrantARMFFIPlugin,
	#superclass : #ReentrantFFIPlugin,
	#classVars : [
		'NumRegArgs'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
ReentrantARMFFIPlugin class >> calloutStateClass [
	^ReentrantFFICalloutStateForARM
]

{ #category : #'class initialization' }
ReentrantARMFFIPlugin class >> initialize [
	NumRegArgs := 8
]

{ #category : #accessing }
ReentrantARMFFIPlugin class >> numRegArgs [
	^NumRegArgs
]

{ #category : #marshalling }
ReentrantARMFFIPlugin >> ffiPushDoubleFloat: value in: calloutState [
	<arg: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantARMFFIPlugin >> ffiPushPointer: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantARMFFIPlugin >> ffiPushSignedByte: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantARMFFIPlugin >> ffiPushSignedChar: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantARMFFIPlugin >> ffiPushSignedLongLong: value in: calloutState [
	<var: #value type: #sqLong>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantARMFFIPlugin >> ffiPushSignedShort: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantARMFFIPlugin >> ffiPushSingleFloat: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantARMFFIPlugin >> ffiPushUnsignedByte: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantARMFFIPlugin >> ffiPushUnsignedChar: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantARMFFIPlugin >> ffiPushUnsignedLong: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantARMFFIPlugin >> ffiPushUnsignedLongLong: value in: calloutState [
	<var: #value type: #usqLong>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantARMFFIPlugin >> ffiPushUnsignedShort: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantARMFFIPlugin >> registerArgsSlop [
	"Answer any space needed to prevent the alloca'ed outgoing arguments marshalling area from
	 being overwritten by any register arguments during calls during marshalling.  On ARM we
	 believe this is zero."
	^0
]
