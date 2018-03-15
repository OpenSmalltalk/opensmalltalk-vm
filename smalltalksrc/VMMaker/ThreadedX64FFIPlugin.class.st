"
This is an abstract superclass for the System V and WIN64 x86-64 ABIs that share a lot of code other than for structure passing.
"
Class {
	#name : #ThreadedX64FFIPlugin,
	#superclass : #ThreadedFFIPlugin,
	#classVars : [
		'NumFloatRegArgs',
		'NumIntRegArgs',
		'WordSize'
	],
	#category : 'VMMaker-Plugins-FFI'
}

{ #category : #translation }
ThreadedX64FFIPlugin class >> calloutStateClass [
	^ThreadedFFICalloutStateForX64
]

{ #category : #translation }
ThreadedX64FFIPlugin class >> identifyingPredefinedMacros [
	"Answer the predefined macros that identify the platforms a subclass handles, if any.
	 If the subclass isn't yet ready for production (a work in progress) simply answer nil.
	 Override to filter-out this abstract class."
	^nil
]

{ #category : #'class initialization' }
ThreadedX64FFIPlugin class >> initialize [
	WordSize := 8.
	NumIntRegArgs := 6.
	NumFloatRegArgs := 8
]

{ #category : #translation }
ThreadedX64FFIPlugin class >> moduleName [
	^'X64SysVFFIPlugin'
]

{ #category : #accessing }
ThreadedX64FFIPlugin class >> numFloatRegArgs [
	^NumFloatRegArgs
]

{ #category : #accessing }
ThreadedX64FFIPlugin class >> numRegArgs [
	^NumIntRegArgs
]

{ #category : #marshalling }
ThreadedX64FFIPlugin >> ffiPushDoubleFloat: value in: calloutState [
	<var: #value type: #double>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>

	calloutState floatRegisterIndex < NumFloatRegArgs
		ifTrue:
			[calloutState floatRegisters at: calloutState floatRegisterIndex put: value.
			 calloutState incrementFloatRegisterIndex]
		ifFalse:
			[calloutState currentArg + WordSize > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy storeFloatAtPointer: calloutState currentArg from: value.
			 calloutState currentArg: calloutState currentArg + WordSize].
	^0
]

{ #category : #marshalling }
ThreadedX64FFIPlugin >> ffiPushPointer: pointer in: calloutState [
	<var: #pointer type: #'void *'>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: pointer asInteger.
			 calloutState incrementIntegerRegisterIndex]
		ifFalse:
			[calloutState currentArg + WordSize > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: pointer.
			 calloutState currentArg: calloutState currentArg + WordSize].
	^0
]

{ #category : #marshalling }
ThreadedX64FFIPlugin >> ffiPushSignedByte: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: (self cCoerceSimple: value to: #'signed char').
			 calloutState incrementIntegerRegisterIndex]
		ifFalse:
			[calloutState currentArg + WordSize > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: (self cCoerceSimple: value to: #'signed char').
			 calloutState currentArg: calloutState currentArg + WordSize].
	^0
]

{ #category : #marshalling }
ThreadedX64FFIPlugin >> ffiPushSignedChar: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: (self cCoerceSimple: value to: #'signed char').
			 calloutState incrementIntegerRegisterIndex]
		ifFalse:
			[calloutState currentArg + WordSize > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: (self cCoerceSimple: value to: #'signed char').
			 calloutState currentArg: calloutState currentArg + WordSize].
	^0
]

{ #category : #marshalling }
ThreadedX64FFIPlugin >> ffiPushSignedInt: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: value.
			 calloutState incrementIntegerRegisterIndex]
		ifFalse:
			[calloutState currentArg + WordSize > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: value.
			 calloutState currentArg: calloutState currentArg + WordSize].
	^0

]

{ #category : #marshalling }
ThreadedX64FFIPlugin >> ffiPushSignedLongLong: value in: calloutState [
	<var: #value type: #sqLong>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: (self cCoerceSimple: value to: #usqInt).
			 calloutState incrementIntegerRegisterIndex]
		ifFalse:
			[calloutState currentArg + WordSize > calloutState limit ifTrue: [^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: value.
			 calloutState currentArg: calloutState currentArg + WordSize].
	^0
]

{ #category : #marshalling }
ThreadedX64FFIPlugin >> ffiPushSignedShort: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: (self cCoerceSimple: value to: #'signed short').
			 calloutState incrementIntegerRegisterIndex]
		ifFalse:
			[calloutState currentArg + WordSize > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: (self cCoerceSimple: value to: #'signed short').
			 calloutState currentArg: calloutState currentArg + WordSize].
	^0
]

{ #category : #marshalling }
ThreadedX64FFIPlugin >> ffiPushSingleFloat: value in: calloutState [
	<var: #value type: #float>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>

	calloutState floatRegisterIndex < NumFloatRegArgs
		ifTrue:
			[(self cCoerce: calloutState floatRegisters + calloutState floatRegisterIndex to: #'float *') at: 0 put: value.
			 calloutState incrementFloatRegisterIndex]
		ifFalse:
			[calloutState currentArg + WordSize > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy storeFloatAtPointer: calloutState currentArg from: value.
			 calloutState currentArg: calloutState currentArg + WordSize].
	^0
]

{ #category : #marshalling }
ThreadedX64FFIPlugin >> ffiPushStructure: pointer ofSize: structSize typeSpec: argSpec ofLength: argSpecSize in: calloutState [
	<var: #pointer type: #'void *'>
	<var: #argSpec type: #'sqInt *'>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	self subclassResponsibility
]

{ #category : #marshalling }
ThreadedX64FFIPlugin >> ffiPushUnsignedByte: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: (self cCoerceSimple: value to: #'unsigned char').
			 calloutState incrementIntegerRegisterIndex]
		ifFalse:
			[calloutState currentArg + WordSize > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: (self cCoerceSimple: value to: #'unsigned char').
			 calloutState currentArg: calloutState currentArg + WordSize].
	^0

]

{ #category : #marshalling }
ThreadedX64FFIPlugin >> ffiPushUnsignedChar: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: (self cCoerceSimple: value to: #'unsigned char').
			 calloutState incrementIntegerRegisterIndex]
		ifFalse:
			[calloutState currentArg + WordSize > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: (self cCoerceSimple: value to: #'unsigned char').
			 calloutState currentArg: calloutState currentArg + WordSize].
	^0
]

{ #category : #marshalling }
ThreadedX64FFIPlugin >> ffiPushUnsignedInt: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: value.
			 calloutState incrementIntegerRegisterIndex]
		ifFalse:
			[calloutState currentArg + WordSize > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: value.
			 calloutState currentArg: calloutState currentArg + WordSize].
	^0


]

{ #category : #marshalling }
ThreadedX64FFIPlugin >> ffiPushUnsignedLongLong: value in: calloutState [
	<var: #value type: #usqLong>
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: value.
			 calloutState incrementIntegerRegisterIndex]
		ifFalse:
			[calloutState currentArg + WordSize > calloutState limit ifTrue: [^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: value.
			 calloutState currentArg: calloutState currentArg + WordSize].
	^0
]

{ #category : #marshalling }
ThreadedX64FFIPlugin >> ffiPushUnsignedShort: value in: calloutState [
	<var: #calloutState type: #'CalloutState *'>
	<inline: true>
	calloutState integerRegisterIndex < NumIntRegArgs
		ifTrue:
			[calloutState integerRegisters at: calloutState integerRegisterIndex put: (self cCoerceSimple: value to: #'unsigned short').
			 calloutState incrementIntegerRegisterIndex]
		ifFalse:
			[calloutState currentArg + WordSize > calloutState limit ifTrue:
				[^FFIErrorCallFrameTooBig].
			 interpreterProxy longAt: calloutState currentArg put: (self cCoerceSimple: value to: #'unsigned short').
			 calloutState currentArg: calloutState currentArg + WordSize].
	^0
]

{ #category : #marshalling }
ThreadedX64FFIPlugin >> returnStructInRegisters: returnStructSize [
	"Answer if a struct result of a given size is returned in memory or not."
	self subclassResponsibility
]
