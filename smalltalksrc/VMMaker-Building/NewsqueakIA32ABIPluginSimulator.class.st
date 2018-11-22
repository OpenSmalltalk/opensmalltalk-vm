Class {
	#name : #NewsqueakIA32ABIPluginSimulator,
	#superclass : #NewsqueakIA32ABIPlugin,
	#category : #'VMMaker-Plugins-Alien'
}

{ #category : #translation }
NewsqueakIA32ABIPluginSimulator class >> shouldBeTranslated [
	^false
]

{ #category : #'private-support' }
NewsqueakIA32ABIPluginSimulator >> index: byteIndex length: length inRange: rcvr [
	"Answer if the indices byteIndex to byteIndex + length - 1 are valid zero-relative indices into the rcvr."
	| dataSize |
	<inline: true>
	dataSize := self sizeField: rcvr.
	^dataSize = 0 or: [byteIndex > 0 and: [byteIndex + length <= dataSize abs]]
]

{ #category : #'memory access' }
NewsqueakIA32ABIPluginSimulator >> longAt: byteAddress [
	^interpreterProxy longAt: byteAddress
]

{ #category : #'memory access' }
NewsqueakIA32ABIPluginSimulator >> longAt: byteAddress put: a32BitValue [
	^interpreterProxy longAt: byteAddress put: a32BitValue
]
