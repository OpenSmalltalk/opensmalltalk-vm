"
This subclass is for the PowerPC ABI in BigEndian mode.  It typically uses 8 integer registers and 8 single-precision floating-point registers that shadow the top 8 words on the stack.
"
Class {
	#name : #ThreadedPPCBEFFIPlugin,
	#superclass : #ThreadedFFIPlugin,
	#classVars : [
		'NumRegArgs'
	],
	#category : 'VMMaker-Plugins-FFI'
}

{ #category : #translation }
ThreadedPPCBEFFIPlugin class >> calloutStateClass [
	^ThreadedFFICalloutStateForPPC
]

{ #category : #'class initialization' }
ThreadedPPCBEFFIPlugin class >> initialize [
	NumRegArgs := 8
]

{ #category : #translation }
ThreadedPPCBEFFIPlugin class >> moduleName [
	^'PPC32FFIPlugin'
]

{ #category : #accessing }
ThreadedPPCBEFFIPlugin class >> numRegArgs [
	^NumRegArgs
]

{ #category : #marshalling }
ThreadedPPCBEFFIPlugin >> ffiPushDoubleFloat: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedPPCBEFFIPlugin >> ffiPushPointer: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedPPCBEFFIPlugin >> ffiPushSignedByte: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedPPCBEFFIPlugin >> ffiPushSignedChar: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedPPCBEFFIPlugin >> ffiPushSignedInt: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedPPCBEFFIPlugin >> ffiPushSignedLongLong: value in: calloutState [
	<var: #value type: #sqLong>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedPPCBEFFIPlugin >> ffiPushSignedShort: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedPPCBEFFIPlugin >> ffiPushSingleFloat: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedPPCBEFFIPlugin >> ffiPushUnsignedByte: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedPPCBEFFIPlugin >> ffiPushUnsignedChar: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedPPCBEFFIPlugin >> ffiPushUnsignedInt: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedPPCBEFFIPlugin >> ffiPushUnsignedLongLong: value in: calloutState [
	<var: #value type: #usqLong>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedPPCBEFFIPlugin >> ffiPushUnsignedShort: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self shouldBeImplemented.
	^0
]

{ #category : #marshalling }
ThreadedPPCBEFFIPlugin >> registerArgsSlop [
	"Answer any space needed to prevent the alloca'ed outgoing arguments marshalling area from
	 being overwritten by any register arguments during calls during marshalling.  On PowerPC, which
	 has 8 register arguments in the calling convention, register arguments are also written to the stack.
	 So we must leave room for 8 * 4 bytes to avoid overwriting the marshalling stack as register
	 arguments are written to the stack during calls to interpreterProxy etc."
	^32
]

{ #category : #marshalling }
ThreadedPPCBEFFIPlugin >> returnStructInRegisters: returnStructSize [
	"Answer if a struct result of a given size is returned in memory or not.
	 The ABI spec defines return in registers, but some linux gcc versions implemented an
	 erroneous draft which does not return any struct in memory.  Implement the SysV ABI."
	^returnStructSize <= 8
]
