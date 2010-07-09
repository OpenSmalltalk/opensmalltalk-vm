Class {
	#name : #ReentrantPPCBEFFIPlugin,
	#superclass : #ReentrantFFIPlugin,
	#classVars : [
		'NumRegArgs'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
ReentrantPPCBEFFIPlugin class >> calloutStateClass [
	^ReentrantFFICalloutStateForPPC
]

{ #category : #'class initialization' }
ReentrantPPCBEFFIPlugin class >> initialize [
	NumRegArgs := 8
]

{ #category : #accessing }
ReentrantPPCBEFFIPlugin class >> numRegArgs [
	^NumRegArgs
]

{ #category : #marshalling }
ReentrantPPCBEFFIPlugin >> ffiPushDoubleFloat: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantPPCBEFFIPlugin >> ffiPushPointer: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantPPCBEFFIPlugin >> ffiPushSignedByte: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantPPCBEFFIPlugin >> ffiPushSignedChar: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantPPCBEFFIPlugin >> ffiPushSignedInt: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantPPCBEFFIPlugin >> ffiPushSignedLongLong: value in: calloutState [
	<var: #value type: #sqLong>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantPPCBEFFIPlugin >> ffiPushSignedShort: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantPPCBEFFIPlugin >> ffiPushSingleFloat: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantPPCBEFFIPlugin >> ffiPushUnsignedByte: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantPPCBEFFIPlugin >> ffiPushUnsignedChar: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantPPCBEFFIPlugin >> ffiPushUnsignedInt: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantPPCBEFFIPlugin >> ffiPushUnsignedLong: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantPPCBEFFIPlugin >> ffiPushUnsignedLongLong: value in: calloutState [
	<var: #value type: #usqLong>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantPPCBEFFIPlugin >> ffiPushUnsignedShort: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ReentrantPPCBEFFIPlugin >> registerArgsSlop [
	"Answer any space needed to prevent the alloca'ed outgoing arguments marshalling area from
	 being overwritten by any register arguments during calls during marshalling.  On PowerPC, which
	 has 8 register arguments in the calling convention, register arguments are also written to the stack.
	 So we must leave room for 8 * 4 bytes to avoid overwriting the marshalling stack as register
	 arguments are written to the stack during calls to interpreterProxy etc."
	^32
]

{ #category : #marshalling }
ReentrantPPCBEFFIPlugin >> returnStructInRegisters: returnStructSize [
	"Answer if a struct result of a given size is returned in memory or not.
	 The ABI spec defines return in registers, but some linux gcc versions implemented an
	 erroneous draft which does not return any struct in memory.  Implement the SysV ABI."
	^returnStructSize <= 8
]
