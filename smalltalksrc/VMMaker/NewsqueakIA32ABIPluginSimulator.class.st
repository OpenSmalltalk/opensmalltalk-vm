Class {
	#name : #NewsqueakIA32ABIPluginSimulator,
	#superclass : #NewsqueakIA32ABIPlugin,
	#category : #'VMMaker-Plugins-Alien'
}

{ #category : #translation }
NewsqueakIA32ABIPluginSimulator class >> shouldBeTranslated [
	^false
]

{ #category : #'memory access' }
NewsqueakIA32ABIPluginSimulator >> longAt: byteAddress [
	^interpreterProxy longAt: byteAddress
]

{ #category : #'memory access' }
NewsqueakIA32ABIPluginSimulator >> longAt: byteAddress put: a32BitValue [
	^interpreterProxy longAt: byteAddress put: a32BitValue
]
