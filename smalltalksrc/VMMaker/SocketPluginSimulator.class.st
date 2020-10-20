Class {
	#name : #SocketPluginSimulator,
	#superclass : #SocketPlugin,
	#instVars : [
		'openSocketHandles',
		'externalSemaphores',
		'hostSocketToSimSocketMap',
		'simSocketToHostSocketMap',
		'fakeAddressCounter',
		'resolverSemaphoreIndex',
		'ipv6support',
		'resolverStatus',
		'addressForName'
	],
	#classVars : [
		'ResolverBusy',
		'ResolverError',
		'ResolverReady',
		'ResolverUninitialized'
	],
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #'class initialization' }
SocketPluginSimulator class >> initialize [
	ResolverUninitialized := 0.	"network is not initialized"
	ResolverReady := 1.		"resolver idle, last request succeeded"
	ResolverBusy := 2.			"lookup in progress"
	ResolverError := 3.			"resolver idle, last request failed"
]

{ #category : #translation }
SocketPluginSimulator class >> shouldBeTranslated [
	^false
]

{ #category : #simulation }
SocketPluginSimulator >> cCoerce: value to: cTypeString [
	"Type coercion for translation only; just return the value when running in Smalltalk.
	 This overrides the generic coercion method in VMClass.  For some reason we are the exception.
	 If we want that style of coercion we can send cCoerce:to: to interpreterProxy, not self."

	^cTypeString = #SocketPtr
		ifTrue: [value coerceTo: #'char *' sim: interpreterProxy]
		ifFalse: [super cCoerce: value to: cTypeString]
]

{ #category : #'initialize-release' }
SocketPluginSimulator >> close [  "close any sockets that ST may have opened"
	openSocketHandles do: [:h | self closeAndDestroy: h].
	Smalltalk unregisterExternalObjects: externalSemaphores
]

{ #category : #'initialize-release' }
SocketPluginSimulator >> closeAndDestroy: socketHandle [
	"c.f. Socket closeAndDestroy: timeoutSeconds"
	| fakeSocket |
	fakeSocket := Socket basicNew.
	[(fakeSocket primSocketConnectionStatus: socketHandle) = (Socket classPool at: #Connected) ifTrue:
		[fakeSocket primSocketCloseConnection: socketHandle].
	 fakeSocket
		primSocketAbortConnection: socketHandle;
		primSocketDestroy: socketHandle]
		on: SocketPrimitiveFailed
		do: [:ex| Transcript cr; show: ex message]
]

{ #category : #'simulation support' }
SocketPluginSimulator >> hostSocketHandleFromSimSocketHandle: socketHandleCArray [
	"Answer the corresponding host socketHandle for the simulation socketHandle, or nil if none, failing the primitive."
	^simSocketToHostSocketMap
		at: (self simSocketHandleFrom: socketHandleCArray)
		ifAbsent: [interpreterProxy primitiveFail. nil]
]

{ #category : #accessing }
SocketPluginSimulator >> ipv6support [
	
	^ ipv6support

]

{ #category : #accessing }
SocketPluginSimulator >> ipv6support: anObject [
	
	ipv6support := anObject.

]

{ #category : #'simulation support' }
SocketPluginSimulator >> map: hostSocketHandle to: simSockPtr type: socketType register: semaphores spawning: blockOne and: blockTwo and: blockThree [
	| simSocket |
	"SQSocket is typedef struct { int sessionID; int socketType; void *privateSocketPtr; } SQSocket"
	simSocket := ByteArray new: (self sizeof: #SQSocket).
	simSocket
		unsignedLongAt: 1 put: interpreterProxy getThisSessionID;
		unsignedLongAt: 5 put: socketType.
	simSocket size = 12
		ifTrue: [simSocket unsignedLongAt: 9 put: (fakeAddressCounter := fakeAddressCounter + 64)]
		ifFalse: [simSocket unsignedLongLongAt: 9 put: (fakeAddressCounter := fakeAddressCounter + 80)].
	self assert: ((interpreterProxy isBytes: simSockPtr cPtrAsOop)
				and: [(interpreterProxy numBytesOf: simSockPtr cPtrAsOop) = simSocket size]).
	1 to: simSocket size do:
		[:i| simSockPtr at: i - 1 put: (simSocket at: i)].
	self assert: (self simSocketHandleFrom: simSockPtr) = simSocket.
	openSocketHandles add: hostSocketHandle.
	hostSocketToSimSocketMap at: hostSocketHandle put: simSocket.
	simSocketToHostSocketMap at: simSocket put: hostSocketHandle.
	externalSemaphores addAll: semaphores.
	"N.B. These don't need registering.  Eventually they will end up
	 waiting on semaphores that have been unregistered, and hence
	 will get garbage collected, along with these processes."
	blockOne fork.
	blockTwo fork.
	blockThree fork
]

{ #category : #'simulation support' }
SocketPluginSimulator >> netAddressAsByteArrayFromInt: netAddress [
	^ByteArray
		with: ((netAddress bitShift: -24) bitAnd: 16rFF)
		with: ((netAddress bitShift: -16) bitAnd: 16rFF)
		with: ((netAddress bitShift: -8) bitAnd: 16rFF)
		with:  (netAddress bitAnd: 16rFF)
]

{ #category : #'simulation support' }
SocketPluginSimulator >> simSocketHandleFrom: socketHandleCArray [
	| simSocket |
	"SQSocket is typedef struct { int sessionID; int socketType; void *privateSocketPtr; } SQSocket"
	simSocket := ByteArray new: (self sizeof: #SQSocket).
	1 to: simSocket size do:
		[:i|
		simSocket at: i put: (socketHandleCArray at: i - 1)].
	^simSocket
]

{ #category : #accessing }
SocketPluginSimulator >> simulator: aSmartSyntaxPluginSimulator [
	super simulator: aSmartSyntaxPluginSimulator.
	"aSmartSyntaxPluginSimulator logging: true"
]

{ #category : #'initialize-release' }
SocketPluginSimulator >> socketInit [
	openSocketHandles := Set new.
	externalSemaphores := Set new.
	hostSocketToSimSocketMap := Dictionary new.
	simSocketToHostSocketMap := Dictionary new.
	fakeAddressCounter := 16r50C4E70. "Socket, if you squint at it right..."
	"Set all the security functions to zero so simulation does't need to work fully."
	sDSAfn := sHSAfn := sCCTPfn := sCCLOPfn := sCCSOTfn := 0.
	"for now..."
	ipv6support := false.
	resolverStatus := ResolverUninitialized.
	^true
]

{ #category : #simulation }
SocketPluginSimulator >> sqNetworkInit: resolverSemaIndex [
	"Simply assume the network is initialized."
	(NetNameResolver classPool at: #HaveNetwork) ifNil:
		[NetNameResolver initializeNetwork].
	resolverSemaphoreIndex
		ifNil: [resolverSemaphoreIndex := resolverSemaIndex]
		ifNotNil: [self assert: resolverSemaphoreIndex = resolverSemaIndex].
	resolverStatus := ResolverReady.
	^0
]

{ #category : #simulation }
SocketPluginSimulator >> sqResolverHostNameSize [
	ipv6support ifTrue: [^NetNameResolver primHostNameSize].
	interpreterProxy primitiveFail
]

{ #category : #simulation }
SocketPluginSimulator >> sqResolverLocalAddress [
	"For now don't simulate the implicit semaphore."
	| bytes |
	bytes := NetNameResolver primLocalAddress.
	self assert: bytes size = 4.
	"Effectively netAddressToInt: bytes"
	^	((bytes at: 4)) +
		((bytes at: 3) <<8) +
		((bytes at: 2) <<16) +
		((bytes at: 1) <<24)
]

{ #category : #simulation }
SocketPluginSimulator >> sqResolverNameLookupResult [
	"For now don't simulate the implicit semaphore."
	addressForName ifNil: [^interpreterProxy primitiveFail].
	self assert: addressForName size = 4.
	"Effectively netAddressToInt: bytes"
	^	((addressForName at: 4)) +
		((addressForName at: 3) <<8) +
		((addressForName at: 2) <<16) +
		((addressForName at: 1) <<24)
]

{ #category : #simulation }
SocketPluginSimulator >> sqResolverStartName: aCArray Lookup: size [
	"For now don't simulate the implicit semaphore."
	| hostName |
	hostName := self strncpy: (String new: size) _: aCArray _: size.
	addressForName := NetNameResolver addressForName: hostName timeout: 30.
	resolverSemaphoreIndex ifNotNil:
		[resolverStatus := ResolverReady.
		 interpreterProxy signalSemaphoreWithIndex: resolverSemaphoreIndex]
]

{ #category : #simulation }
SocketPluginSimulator >> sqResolverStatus [
	^resolverStatus 
]

{ #category : #simulation }
SocketPluginSimulator >> sqSocket: socketHandle ConnectTo: addr Port: port [
	^[Socket basicNew
			primSocket: ((self hostSocketHandleFromSimSocketHandle: socketHandle) ifNil: [^self])
			connectTo: (self netAddressAsByteArrayFromInt: addr)
			port: port]
		on: SocketPrimitiveFailed
		do: [:ex|
			interpreterProxy primitiveFail.
			0]
]

{ #category : #simulation }
SocketPluginSimulator >> sqSocket: sockPtr CreateNetType: netType SocketType: socketType RecvBytes: recvBufSize SendBytes: sendBufSize SemaID: semaIndex ReadSemaID: readSemaIndex WriteSemaID: writeSemaIndex [
	"Simulate the sqSocketCreateNetTypeSocketTypeRecvBytesSendBytesSemaIDReadSemaIDWriteSemaID function.
	 We descend beneath the Socket abstraftion to simulate as accurately as possible."
	| semaphoresAndIndexes semaphores indexes socketHandle |
	semaphoresAndIndexes := Smalltalk newExternalSemaphores: 3.
	semaphores := semaphoresAndIndexes first.
	indexes := semaphoresAndIndexes second.
	socketHandle := [Socket basicNew
						primSocketCreateNetwork: netType
						type: socketType
						receiveBufferSize: recvBufSize
						sendBufSize: sendBufSize
						semaIndex: indexes first
						readSemaIndex: indexes second
						writeSemaIndex: indexes third]
			on: SocketPrimitiveFailed
			do: [:ex|
				#failed].
	socketHandle == #failed ifTrue:
		[interpreterProxy primitiveFail.
		 Smalltalk unregisterExternalObjects: semaphores.
		 ^self].
	"N.B. There is now a Processor yield in doSignalExternalSemaphores: every 100 virtual microseconds.
	 This allows these to make progress.  Their job is to map a host signal into a signal of the relevant index."
	self map:		socketHandle
		to:			sockPtr
		type:		socketType
		register:	semaphores
		spawning:	[[semaphores first wait. interpreterProxy  signalSemaphoreWithIndex: semaIndex] repeat]
		and:		[[semaphores second wait. interpreterProxy  signalSemaphoreWithIndex: readSemaIndex] repeat]
		and:		[[semaphores third wait. interpreterProxy  signalSemaphoreWithIndex: writeSemaIndex] repeat]
]

{ #category : #simulation }
SocketPluginSimulator >> sqSocket: socketHandleCArray ReceiveDataBuf: bufferStartCArray Count: numBytes [
	^[| buffer n |
	  buffer := ByteArray new: numBytes.
	  n := Socket basicNew
			primSocket: ((self hostSocketHandleFromSimSocketHandle: socketHandleCArray) ifNil: [^0])
			receiveDataInto: buffer
			startingAt: 1
			count: numBytes.
	  1 to: n do:
		[:i|
		bufferStartCArray at: i - 1 put: (buffer at: i)].
	  n]
		on: SocketPrimitiveFailed
		do: [:ex|
			interpreterProxy primitiveFail.
			0]
]

{ #category : #simulation }
SocketPluginSimulator >> sqSocket: socketHandleCArray SendDataBuf: bufferStartCArray Count: numBytes [
	| data |
	data := ByteArray new: numBytes.
	1 to: numBytes do:
		[:i| data at: i put: (bufferStartCArray at: i - 1)].
	^[Socket basicNew
			primSocket: ((self hostSocketHandleFromSimSocketHandle: socketHandleCArray) ifNil: [^0])
			sendData: data
			startIndex: 1
			count: numBytes]
		on: SocketPrimitiveFailed
		do: [:ex|
			interpreterProxy primitiveFail.
			0]
]

{ #category : #simulation }
SocketPluginSimulator >> sqSocketAbortConnection: socketHandleCArray [
	^[Socket basicNew
			primSocketAbortConnection: ((self hostSocketHandleFromSimSocketHandle: socketHandleCArray) ifNil: [^false])]
		on: SocketPrimitiveFailed
		do: [:ex|
			interpreterProxy primitiveFail.
			false]
]

{ #category : #simulation }
SocketPluginSimulator >> sqSocketCloseConnection: socketHandleCArray [
	^[Socket basicNew
			primSocketCloseConnection: ((self hostSocketHandleFromSimSocketHandle: socketHandleCArray) ifNil: [^false])]
		on: SocketPrimitiveFailed
		do: [:ex|
			interpreterProxy primitiveFail.
			false]
]

{ #category : #simulation }
SocketPluginSimulator >> sqSocketConnectionStatus: socketHandleCArray [
	^[Socket basicNew
			primSocketConnectionStatus: ((self hostSocketHandleFromSimSocketHandle: socketHandleCArray) ifNil: [^-1])]
		on: SocketPrimitiveFailed
		do: [:ex|
			interpreterProxy primitiveFail.
			-1]
]

{ #category : #simulation }
SocketPluginSimulator >> sqSocketDestroy: socketHandleCArray [ 
	| simHandle hostHandle |
	simHandle := self simSocketHandleFrom: socketHandleCArray.
	hostHandle := simSocketToHostSocketMap removeKey: simHandle ifAbsent: [].
	hostHandle ifNil:
		[interpreterProxy primitiveFail.
		 ^self].
	hostSocketToSimSocketMap removeKey: hostHandle ifAbsent: [].
	[Socket basicNew primSocketDestroy: hostHandle]
		on: SocketPrimitiveFailed
		do: [:ex|
			interpreterProxy primitiveFail]
]

{ #category : #simulation }
SocketPluginSimulator >> sqSocketReceiveDataAvailable: socketHandleCArray [ 
	^[Socket basicNew
			primSocketReceiveDataAvailable: ((self hostSocketHandleFromSimSocketHandle: socketHandleCArray) ifNil: [^false])]
		on: SocketPrimitiveFailed
		do: [:ex|
			interpreterProxy primitiveFail.
			false]
]

{ #category : #simulation }
SocketPluginSimulator >> sqSocketSendDone: socketHandleCArray [
	^[Socket basicNew
			primSocketSendDone: ((self hostSocketHandleFromSimSocketHandle: socketHandleCArray) ifNil: [^false])]
		on: SocketPrimitiveFailed
		do: [:ex|
			interpreterProxy primitiveFail.
			false]
]
