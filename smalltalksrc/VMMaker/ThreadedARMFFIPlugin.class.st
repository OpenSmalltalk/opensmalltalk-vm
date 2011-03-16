"
This subclass is for the 32-bit ARM ABI.  It typically has 4 integer registers.
"
Class {
	#name : #ThreadedARMFFIPlugin,
	#superclass : #ThreadedFFIPlugin,
	#classVars : [
		'NumRegArgs'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
ThreadedARMFFIPlugin class >> calloutStateClass [
	^ThreadedFFICalloutStateForARM
]

{ #category : #'class initialization' }
ThreadedARMFFIPlugin class >> initialize [
	NumRegArgs := 4
]

{ #category : #accessing }
ThreadedARMFFIPlugin class >> numRegArgs [
	^NumRegArgs
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushDoubleFloat: value in: calloutState [
	<arg: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushPointer: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushSignedByte: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushSignedChar: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushSignedLongLong: value in: calloutState [
	<var: #value type: #sqLong>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushSignedShort: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushSingleFloat: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushUnsignedByte: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushUnsignedChar: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushUnsignedLong: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushUnsignedLongLong: value in: calloutState [
	<var: #value type: #usqLong>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> ffiPushUnsignedShort: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedARMFFIPlugin >> registerArgsSlop [
	"Answer any space needed to prevent the alloca'ed outgoing arguments marshalling area from
	 being overwritten by any register arguments during calls during marshalling.  On ARM we
	 believe this is zero."
	^0
]
