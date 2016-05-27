Class {
	#name : #IA32ABIPluginSimulator,
	#superclass : #IA32ABIPlugin,
	#category : 'VMMaker-Plugins-FFI'
}

{ #category : #translation }
IA32ABIPluginSimulator class >> shouldBeTranslated [
	^false
]

{ #category : #'memory access' }
IA32ABIPluginSimulator >> longAt: byteAddress [
	^interpreterProxy longAt: byteAddress
]

{ #category : #'memory access' }
IA32ABIPluginSimulator >> longAt: byteAddress put: a32BitValue [
	^interpreterProxy longAt: byteAddress put: a32BitValue
]
