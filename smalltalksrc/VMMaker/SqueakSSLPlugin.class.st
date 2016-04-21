Class {
	#name : #SqueakSSLPlugin,
	#superclass : #InterpreterPlugin,
	#category : 'VMMaker-Plugins'
}

{ #category : #translation }
SqueakSSLPlugin class >> hasHeaderFile [
	^true
]

{ #category : #translation }
SqueakSSLPlugin class >> moduleName [
	^'SqueakSSL'
]

{ #category : #primitives }
SqueakSSLPlugin >> primitiveAccept [
	"Primitive. Starts or continues a server handshake using the current session.
	Will eventually produce output to be sent to the client. Requires the host
	and cert name to be set for the session. Returns a code indicating the sate
	of the connection:
		> 0	 - Number of bytes to be sent to the client.
		0	 - Success. The connection is established.
		-1 	 - More input is required.
		< -1 - Other errors.
	"
	| start srcLen dstLen srcOop dstOop handle srcPtr dstPtr result |
	<var: #srcPtr type: 'char *'>
	<var: #dstPtr type: 'char *'>
	<export: true>
	interpreterProxy methodArgumentCount = 5
		ifFalse:[^interpreterProxy primitiveFail].
	dstOop := interpreterProxy stackObjectValue: 0.
	srcLen := interpreterProxy stackIntegerValue: 1.
	start := interpreterProxy stackIntegerValue: 2.
	srcOop := interpreterProxy stackObjectValue: 3.
	handle := interpreterProxy stackIntegerValue: 4.
	interpreterProxy failed ifTrue:[^nil].
	((start > 0 and:[srcLen >= 0])
		and:[(interpreterProxy isBytes: srcOop) 
		and:[(interpreterProxy isBytes: dstOop) 
		and:[(interpreterProxy byteSizeOf: srcOop) >= (start + srcLen - 1)]]])
			ifFalse:[^interpreterProxy primitiveFail].
	srcPtr := interpreterProxy firstIndexableField: srcOop.
	dstPtr := interpreterProxy firstIndexableField: dstOop.
	srcPtr := srcPtr + start - 1.
	dstLen := interpreterProxy byteSizeOf: dstOop.
	result := self cCode: 'sqAcceptSSL(handle, srcPtr, srcLen, dstPtr, dstLen)' 
					inSmalltalk:[handle. srcPtr. srcLen. dstPtr. dstLen. -2].
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy pop: interpreterProxy methodArgumentCount+1.
	interpreterProxy pushInteger: result.
]

{ #category : #primitives }
SqueakSSLPlugin >> primitiveConnect [
	"Primitive. Starts or continues a client handshake using the provided data.
	Will eventually produce output to be sent to the server. Requires the host
	name to be set for the session. 
	Returns:
		> 0	 - Number of bytes to be sent to the server
		0	 - Success. The connection is established.
		-1 	 - More input is required.
		< -1 - Other errors.
	"
	| start srcLen dstLen srcOop dstOop handle srcPtr dstPtr result |
	<var: #srcPtr type: 'char *'>
	<var: #dstPtr type: 'char *'>
	<export: true>
	interpreterProxy methodArgumentCount = 5
		ifFalse:[^interpreterProxy primitiveFail].
	dstOop := interpreterProxy stackObjectValue: 0.
	srcLen := interpreterProxy stackIntegerValue: 1.
	start := interpreterProxy stackIntegerValue: 2.
	srcOop := interpreterProxy stackObjectValue: 3.
	handle := interpreterProxy stackIntegerValue: 4.
	interpreterProxy failed ifTrue:[^nil].
	((start > 0 and:[srcLen >= 0])
		and:[(interpreterProxy isBytes: srcOop) 
		and:[(interpreterProxy isBytes: dstOop) 
		and:[(interpreterProxy byteSizeOf: srcOop) >= (start + srcLen - 1)]]])
			ifFalse:[^interpreterProxy primitiveFail].
	srcPtr := interpreterProxy firstIndexableField: srcOop.
	dstPtr := interpreterProxy firstIndexableField: dstOop.
	srcPtr := srcPtr + start - 1.
	dstLen := interpreterProxy byteSizeOf: dstOop.
	result := self cCode: 'sqConnectSSL(handle, srcPtr, srcLen, dstPtr, dstLen)' 
					inSmalltalk:[handle. srcPtr. srcLen. dstPtr. dstLen. -2].
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy pop: interpreterProxy methodArgumentCount+1.
	interpreterProxy pushInteger: result.
]

{ #category : #primitives }
SqueakSSLPlugin >> primitiveCreate [
	"Primitive. Creates a new SSL session and returns its handle."
	| handle |
	<export: true>
	interpreterProxy methodArgumentCount = 0 
		ifFalse:[^interpreterProxy primitiveFail].
	handle := self cCode: 'sqCreateSSL()' inSmalltalk:[0].
	handle = 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: interpreterProxy methodArgumentCount+1.
	interpreterProxy pushInteger: handle.

]

{ #category : #primitives }
SqueakSSLPlugin >> primitiveDecrypt [
	"Primitive. Decrypts a buffer sent via the connection.
	Requires the session to be established.
	Returns:
		>=0 - Number of bytes decrypted in the result buffer
		< -1 - Other errors.
	"
	| start srcLen dstLen srcOop dstOop handle srcPtr dstPtr result |
	<var: #srcPtr type: 'char *'>
	<var: #dstPtr type: 'char *'>
	<export: true>
	interpreterProxy methodArgumentCount = 5
		ifFalse:[^interpreterProxy primitiveFail].
	dstOop := interpreterProxy stackObjectValue: 0.
	srcLen := interpreterProxy stackIntegerValue: 1.
	start := interpreterProxy stackIntegerValue: 2.
	srcOop := interpreterProxy stackObjectValue: 3.
	handle := interpreterProxy stackIntegerValue: 4.
	interpreterProxy failed ifTrue:[^nil].
	((start > 0 and:[srcLen >= 0])
		and:[(interpreterProxy isBytes: srcOop) 
		and:[(interpreterProxy isBytes: dstOop) 
		and:[(interpreterProxy byteSizeOf: srcOop) >= (start + srcLen - 1)]]])
			ifFalse:[^interpreterProxy primitiveFail].
	srcPtr := interpreterProxy firstIndexableField: srcOop.
	dstPtr := interpreterProxy firstIndexableField: dstOop.
	srcPtr := srcPtr + start - 1.
	dstLen := interpreterProxy byteSizeOf: dstOop.
	result := self cCode: 'sqDecryptSSL(handle, srcPtr, srcLen, dstPtr, dstLen)' 
					inSmalltalk:[handle. srcPtr. srcLen. dstPtr. dstLen. -2].
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy pop: interpreterProxy methodArgumentCount+1.
	interpreterProxy pushInteger: result.
]

{ #category : #primitives }
SqueakSSLPlugin >> primitiveDestroy [
	"Primitive. Destroys an SSL session."

	| handle result |
	<export: true>
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	handle := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode: 'sqDestroySSL(handle)' inSmalltalk:[handle. 0].
	result = 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: interpreterProxy methodArgumentCount.


]

{ #category : #primitives }
SqueakSSLPlugin >> primitiveEncrypt [
	"Primitive. Encrypts a buffer to be sent to the via the connection.
	Requires the session to be established.
	Returns:
		>=0 - Number of bytes encrypted in the result buffer
		< -1 - Other errors.
	"
	| start srcLen dstLen srcOop dstOop handle srcPtr dstPtr result |
	<var: #srcPtr type: 'char *'>
	<var: #dstPtr type: 'char *'>
	<export: true>
	interpreterProxy methodArgumentCount = 5
		ifFalse:[^interpreterProxy primitiveFail].
	dstOop := interpreterProxy stackObjectValue: 0.
	srcLen := interpreterProxy stackIntegerValue: 1.
	start := interpreterProxy stackIntegerValue: 2.
	srcOop := interpreterProxy stackObjectValue: 3.
	handle := interpreterProxy stackIntegerValue: 4.
	interpreterProxy failed ifTrue:[^nil].
	((start > 0 and:[srcLen >= 0])
		and:[(interpreterProxy isBytes: srcOop) 
		and:[(interpreterProxy isBytes: dstOop) 
		and:[(interpreterProxy byteSizeOf: srcOop) >= (start + srcLen - 1)]]])
			ifFalse:[^interpreterProxy primitiveFail].
	srcPtr := interpreterProxy firstIndexableField: srcOop.
	dstPtr := interpreterProxy firstIndexableField: dstOop.
	srcPtr := srcPtr + start - 1.
	dstLen := interpreterProxy byteSizeOf: dstOop.
	result := self cCode: 'sqEncryptSSL(handle, srcPtr, srcLen, dstPtr, dstLen)' 
					inSmalltalk:[handle. srcPtr. srcLen. dstPtr. dstLen. -2].
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy pop: interpreterProxy methodArgumentCount+1.
	interpreterProxy pushInteger: result.
]

{ #category : #primitives }
SqueakSSLPlugin >> primitiveGetIntProperty [
	"Primitive. Returns an integer property for the session"

	| propID handle value |
	<export: true>
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	propID := interpreterProxy stackIntegerValue: 0.
	handle := interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	value := self cCode: 'sqGetIntPropertySSL(handle, propID)' 
					inSmalltalk:[handle. propID. 0].
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy 
		pop: interpreterProxy methodArgumentCount + 1
		thenPush: (interpreterProxy signed32BitIntegerFor: value)

]

{ #category : #primitives }
SqueakSSLPlugin >> primitiveGetStringProperty [
	"Primitive. Returns a string property for the session"

	| stringLen stringOop propID handle stringPtr oopPtr |
	<var: #stringPtr type: 'char *'>
	<var: #oopPtr type: 'char *'>
	<export: true>
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	propID := interpreterProxy stackIntegerValue: 0.
	handle := interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	stringPtr := self cCode: 'sqGetStringPropertySSL(handle, propID)' 
					inSmalltalk:[handle. propID. nil].
	interpreterProxy failed ifTrue:[^nil].
	stringPtr == nil ifTrue:[
		stringOop := interpreterProxy nilObject.
	] ifFalse:[
		stringLen := self strlen: stringPtr.
		stringOop := interpreterProxy 
			instantiateClass: (interpreterProxy classString)
			indexableSize: stringLen.
		oopPtr := interpreterProxy firstIndexableField: stringOop.
		0 to: stringLen-1 do:[:i| oopPtr at: i put: (stringPtr at: i)].
	].
	interpreterProxy 
		pop: interpreterProxy methodArgumentCount + 1
		thenPush: stringOop.

]

{ #category : #primitives }
SqueakSSLPlugin >> primitiveSetIntProperty [
	"Primitive. Sets a integer property for the session"

	| propID handle result value |
	<export: true>
	interpreterProxy methodArgumentCount = 3
		ifFalse:[^interpreterProxy primitiveFail].
	value := interpreterProxy signed32BitValueOf: (interpreterProxy stackValue: 0).
	propID := interpreterProxy stackIntegerValue: 1.
	handle := interpreterProxy stackIntegerValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	result := self cCode: 'sqSetIntPropertySSL(handle, propID, value)' 
					inSmalltalk:[handle. propID. value. false].
	result ifFalse:[^interpreterProxy primitiveFail].
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy pop: interpreterProxy methodArgumentCount.

]

{ #category : #primitives }
SqueakSSLPlugin >> primitiveSetStringProperty [
	"Primitive. Sets a string property for the session"

	| srcLen srcOop propID handle srcPtr result |
	<var: #srcPtr type: 'char *'>
	<export: true>
	interpreterProxy methodArgumentCount = 3
		ifFalse:[^interpreterProxy primitiveFail].
	srcOop := interpreterProxy stackObjectValue: 0.
	propID := interpreterProxy stackIntegerValue: 1.
	handle := interpreterProxy stackIntegerValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isBytes: srcOop) 
		ifFalse:[^interpreterProxy primitiveFail].
	srcPtr := interpreterProxy firstIndexableField: srcOop.
	srcLen := interpreterProxy byteSizeOf: srcOop.
	result := self cCode: 'sqSetStringPropertySSL(handle, propID, srcPtr, srcLen)' 
					inSmalltalk:[handle. srcPtr. propID. srcLen. false].
	result ifFalse:[^interpreterProxy primitiveFail].
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy pop: interpreterProxy methodArgumentCount.

]
