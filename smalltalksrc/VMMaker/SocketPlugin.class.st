"
Implement the socket and resolver primitives.  Since it requires platform support it will only be built when supported on your platform
"
Class {
	#name : #SocketPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#instVars : [
		'sDSAfn',
		'sHSAfn',
		'sCCTPfn',
		'sCCLOPfn',
		'sCCSOTfn'
	],
	#category : 'VMMaker-Plugins'
}

{ #category : #translation }
SocketPlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
SocketPlugin class >> requiresPlatformFiles [
	"this plugin requires platform specific files in order to work"
	^true
]

{ #category : #'initialize-release' }
SocketPlugin >> initialiseModule [
	self export: true.
	sDSAfn _ interpreterProxy ioLoadFunction: 'secDisableSocketAccess' From: 'SecurityPlugin'.
	sHSAfn _ interpreterProxy ioLoadFunction: 'secHasSocketAccess' From: 'SecurityPlugin'.
	sCCTPfn _ interpreterProxy ioLoadFunction: 'secCanConnectToPort' From: 'SecurityPlugin'.
	sCCLOPfn _ interpreterProxy ioLoadFunction: 'secCanListenOnPort' From: 'SecurityPlugin'.
	sCCSOTfn _ interpreterProxy ioLoadFunction: 'secCanCreateSocketOfType' From: 'SecurityPlugin'.
	^self cCode: 'socketInit()' inSmalltalk:[true]
]

{ #category : #primitives }
SocketPlugin >> intToNetAddress: addr [
	"Convert the given 32-bit integer into an internet network address represented as a four-byte ByteArray."

	| netAddressOop naPtr|
	self var: #naPtr declareC: 'char * naPtr'.

	netAddressOop _
		interpreterProxy instantiateClass: interpreterProxy classByteArray
			indexableSize: 4.
	naPtr _ netAddressOop asCharPtr.
	naPtr at: 0 put: (self cCoerce: ((addr >> 24) bitAnd: 16rFF) to: 'char').
	naPtr at: 1 put: (self cCoerce: ((addr >> 16) bitAnd: 16rFF) to: 'char').
	naPtr at: 2 put: (self cCoerce: ((addr >> 8) bitAnd: 16rFF) to: 'char').
	naPtr at: 3 put: (self cCoerce: (addr bitAnd: 16rFF) to: 'char').
	^ netAddressOop
]

{ #category : #'initialize-release' }
SocketPlugin >> moduleUnloaded: aModuleName [
	"The module with the given name was just unloaded.
	Make sure we have no dangling references."
	self export: true.
	self var: #aModuleName type: 'char *'.
	(aModuleName strcmp: 'SecurityPlugin') = 0 ifTrue:[
		"The security plugin just shut down. How odd."
		sDSAfn _ sHSAfn _ sCCTPfn _ sCCLOPfn _ sCCSOTfn _ 0.
	].
]

{ #category : #primitives }
SocketPlugin >> netAddressToInt: ptrToByteArray [
	"Convert the given internet network address (represented as a four-byte ByteArray) into a 32-bit integer. Fail if the given ptrToByteArray does not appear to point to a four-byte ByteArray."

	| sz |
	self var: #ptrToByteArray declareC: 'unsigned char * ptrToByteArray'.
	sz _ interpreterProxy byteSizeOf: ptrToByteArray cPtrAsOop.
	sz = 4 ifFalse: [^ interpreterProxy primitiveFail].
	^ (ptrToByteArray at: 3	) +
		((ptrToByteArray at: 2) <<8) +
		((ptrToByteArray at: 1) <<16) +
		((ptrToByteArray at: 0) <<24)
]

{ #category : #'security primitives' }
SocketPlugin >> primitiveDisableSocketAccess [

	self export: true.
	"If the security plugin can be loaded, use it to turn off socket access
	If 
	not, assume it's ok"
	sDSAfn ~= 0
		ifTrue: [self cCode: ' ((int (*) (void)) sDSAfn)()'].
	interpreterProxy failed
		ifFalse: [interpreterProxy pop: 1]
]

{ #category : #'security primitives' }
SocketPlugin >> primitiveHasSocketAccess [
	|  hasAccess |
	self export: true.
	interpreterProxy pop: 1.
	"If the security plugin can be loaded, use it to check . 
	If not, assume it's ok"
	sHSAfn ~= 0
		ifTrue: [hasAccess _ self cCode: ' ((int (*) (void)) sHSAfn)()' inSmalltalk:[true]]
		ifFalse: [hasAccess _ true].
	interpreterProxy pop: 1.
	interpreterProxy pushBool: hasAccess
]

{ #category : #primitives }
SocketPlugin >> primitiveInitializeNetwork: resolverSemaIndex [

	| err |
	self primitive: 'primitiveInitializeNetwork'
		parameters: #(SmallInteger).
	err _ self sqNetworkInit: resolverSemaIndex.
	interpreterProxy success: err = 0
]

{ #category : #primitives }
SocketPlugin >> primitiveResolverAbortLookup [

	self primitive: 'primitiveResolverAbortLookup'.

	self sqResolverAbort
]

{ #category : #primitives }
SocketPlugin >> primitiveResolverAddressLookupResult [
	| sz s |
	self primitive: 'primitiveResolverAddressLookupResult'.
	sz _ self sqResolverAddrLookupResultSize.

	interpreterProxy failed
		ifFalse: [s _ interpreterProxy instantiateClass: interpreterProxy classString indexableSize: sz.
			self sqResolverAddrLookup: s asCharPtr Result: sz].
	^ s
]

{ #category : #primitives }
SocketPlugin >> primitiveResolverError [

	self primitive: 'primitiveResolverError'.
	^ self sqResolverError asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveResolverLocalAddress [

	| addr |
	self primitive: 'primitiveResolverLocalAddress'.
	addr _ self sqResolverLocalAddress.
	^self intToNetAddress: addr
]

{ #category : #primitives }
SocketPlugin >> primitiveResolverNameLookupResult [

	| addr |
	self primitive: 'primitiveResolverNameLookupResult'.
	addr _ self sqResolverNameLookupResult.
	^self intToNetAddress: addr
]

{ #category : #primitives }
SocketPlugin >> primitiveResolverStartAddressLookup: address [

	| addr |
	self primitive: 'primitiveResolverStartAddressLookup'
		parameters: #(ByteArray).
	addr _ self netAddressToInt: (self cCoerce: address to: 'unsigned char *').
	interpreterProxy failed ifFalse: [
		self sqResolverStartAddrLookup: addr]
]

{ #category : #primitives }
SocketPlugin >> primitiveResolverStartNameLookup: name [

	| sz |
	self primitive: 'primitiveResolverStartNameLookup'
		parameters: #(String).
	interpreterProxy failed ifFalse:  [
		sz _ interpreterProxy byteSizeOf: name cPtrAsOop.
		self sqResolverStartName: name Lookup: sz]
]

{ #category : #primitives }
SocketPlugin >> primitiveResolverStatus [

	| status |
	self primitive: 'primitiveResolverStatus'.
	status _ self sqResolverStatus.
	^status asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket connectTo: address port: port [ 
	| addr s okToConnect  |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketConnectToPort' parameters: #(#Oop #ByteArray #SmallInteger ).
	addr _ self
				netAddressToInt: (self cCoerce: address to: 'unsigned char *').
	"If the security plugin can be loaded, use it to check for permission.
	If 
	not, assume it's ok"
	sCCTPfn ~= 0
		ifTrue: [okToConnect _ self cCode: ' ((int (*) (int, int)) sCCTPfn)(addr, port)'.
			okToConnect
				ifFalse: [^ interpreterProxy primitiveFail]].
	s _ self socketValueOf: socket.
	interpreterProxy failed
		ifFalse: [self
				sqSocket: s
				ConnectTo: addr
				Port: port]
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket getOptions: optionName [

	| s optionNameStart optionNameSize returnedValue errorCode results |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketGetOptions'
		parameters: #(Oop Oop).

	s _ self socketValueOf: socket.
	interpreterProxy success: (interpreterProxy isBytes: optionName).
	optionNameStart _ self cCoerce: (interpreterProxy firstIndexableField: optionName) to: 'int'.
	optionNameSize _ interpreterProxy slotSizeOf: optionName.

	interpreterProxy failed ifTrue: [^nil].
	returnedValue _ 0.

	errorCode _ self sqSocketGetOptions: s 
			optionNameStart: optionNameStart 
			optionNameSize: optionNameSize
			returnedValue: (self cCode: '&returnedValue').

	interpreterProxy pushRemappableOop: returnedValue asSmallIntegerObj.
	interpreterProxy pushRemappableOop: errorCode asSmallIntegerObj.
	interpreterProxy pushRemappableOop: (interpreterProxy instantiateClass: (interpreterProxy classArray) indexableSize: 2).
	results _ interpreterProxy popRemappableOop.
	interpreterProxy storePointer: 0 ofObject: results withValue: interpreterProxy popRemappableOop.
	interpreterProxy storePointer: 1 ofObject: results withValue: interpreterProxy popRemappableOop.
	^ results
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket listenOnPort: port [ 
	"one part of the wierdass dual prim primitiveSocketListenOnPort which 
	was warped by some demented evil person determined to twist the very 
	nature of reality"
	| s  okToListen |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketListenOnPort' parameters: #(#Oop #SmallInteger ).
	s _ self socketValueOf: socket.
	"If the security plugin can be loaded, use it to check for permission.
	If 
	not, assume it's ok"
	sCCLOPfn ~= 0
		ifTrue: [okToListen _ self cCode: ' ((int (*) (SocketPtr, int)) sCCLOPfn)(s, port)'.
			okToListen
				ifFalse: [^ interpreterProxy primitiveFail]].
	self sqSocket: s ListenOnPort: port
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket listenOnPort: port backlogSize: backlog [ 
	"second part of the wierdass dual prim primitiveSocketListenOnPort 
	which was warped by some demented evil person determined to twist the 
	very nature of reality"
	| s okToListen |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketListenOnPortBacklog' parameters: #(#Oop #SmallInteger #SmallInteger ).
	s _ self socketValueOf: socket.
	"If the security plugin can be loaded, use it to check for permission.
	If 
	not, assume it's ok"
	sCCLOPfn ~= 0
		ifTrue: [okToListen _ self cCode: ' ((int (*) (SocketPtr, int)) sCCLOPfn)(s, port)'.
			okToListen
				ifFalse: [^ interpreterProxy primitiveFail]].
	self
		sqSocket: s
		ListenOnPort: port
		BacklogSize: backlog
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket listenOnPort: port backlogSize: backlog interface: ifAddr [
	"Bind a socket to the given port and interface address with no more than backlog pending connections.  The socket can be UDP, in which case the backlog should be specified as zero."

	| s okToListen addr |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketListenOnPortBacklogInterface' parameters: #(#Oop #SmallInteger #SmallInteger #ByteArray).
	s _ self socketValueOf: socket.
	"If the security plugin can be loaded, use it to check for permission.
	If 
	not, assume it's ok"
	sCCLOPfn ~= 0
		ifTrue: [okToListen _ self cCode: ' ((int (*) (SocketPtr, int)) sCCLOPfn)(s, port)'.
			okToListen
				ifFalse: [^ interpreterProxy primitiveFail]].
	addr _ self netAddressToInt: (self cCoerce: ifAddr to: 'unsigned char *').
	self
		sqSocket: s
		ListenOnPort: port
		BacklogSize: backlog
		Interface: addr
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket receiveDataBuf: array start: startIndex count: count [ 
	| s byteSize arrayBase bufStart bytesReceived |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketReceiveDataBufCount'
		parameters: #(Oop Oop SmallInteger SmallInteger ).
	s _ self socketValueOf: socket.

	"buffer can be any indexable words or bytes object"
	interpreterProxy success: (interpreterProxy isWordsOrBytes: array).
	(interpreterProxy isWords: array)
		ifTrue: [byteSize _ 4]
		ifFalse: [byteSize _ 1].
	interpreterProxy success: (startIndex >= 1
			and: [count >= 0 and: [startIndex + count - 1 <= (interpreterProxy slotSizeOf: array)]]).
	interpreterProxy failed
		ifFalse: ["Note: adjust bufStart for zero-origin indexing"
			arrayBase _ self cCoerce: (interpreterProxy firstIndexableField: array)
						to: 'int'.
			bufStart _ arrayBase + (startIndex - 1 * byteSize).
			bytesReceived _ self
						sqSocket: s
						ReceiveDataBuf: bufStart
						Count: count * byteSize].
	^ (bytesReceived // byteSize) asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket receiveUDPDataBuf: array start: startIndex count: count [ 
	| s byteSize arrayBase bufStart bytesReceived results address port moreFlag |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketReceiveUDPDataBufCount'
		parameters: #(Oop Oop SmallInteger SmallInteger ).
	s _ self socketValueOf: socket.

	"buffer can be any indexable words or bytes object"
	interpreterProxy success: (interpreterProxy isWordsOrBytes: array).
	(interpreterProxy isWords: array)
		ifTrue: [byteSize _ 4]
		ifFalse: [byteSize _ 1].
	interpreterProxy success: (startIndex >= 1
			and: [count >= 0 and: [startIndex + count - 1 <= (interpreterProxy slotSizeOf: array)]]).
	interpreterProxy failed
		ifFalse: ["Note: adjust bufStart for zero-origin indexing"
			arrayBase _ self cCoerce: (interpreterProxy firstIndexableField: array)
						to: 'int'.
			bufStart _ arrayBase + (startIndex - 1 * byteSize).
			"allocate storage for results, remapping newly allocated
			 oops in case GC happens during allocation"
			address		  _ 0.
			port			  _ 0.
			moreFlag	  _ 0.
			bytesReceived _ self
						sqSocket: s
						ReceiveUDPDataBuf: bufStart
						Count: count * byteSize
						address: (self cCode: '&address')
						port: (self cCode: '&port')
						moreFlag: (self cCode: '&moreFlag').
				
			interpreterProxy pushRemappableOop: port asSmallIntegerObj.
			interpreterProxy pushRemappableOop: (self intToNetAddress: address).
			interpreterProxy pushRemappableOop: (bytesReceived // byteSize) asSmallIntegerObj.
			interpreterProxy pushRemappableOop:
				(interpreterProxy instantiateClass: (interpreterProxy classArray) indexableSize: 4).
			results         _ interpreterProxy popRemappableOop.
			interpreterProxy storePointer: 0 ofObject: results withValue: interpreterProxy popRemappableOop.
			interpreterProxy storePointer: 1 ofObject: results withValue: interpreterProxy popRemappableOop.
			interpreterProxy storePointer: 2 ofObject: results withValue: interpreterProxy popRemappableOop.
			moreFlag
				ifTrue: [ interpreterProxy storePointer: 3 ofObject: results withValue: interpreterProxy trueObject ]
				ifFalse: [ interpreterProxy storePointer: 3 ofObject: results withValue: interpreterProxy falseObject ].
			].
	^ results
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket sendData: array start: startIndex count: count [ 
	| s byteSize arrayBase bufStart bytesSent |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketSendDataBufCount'
		parameters: #(Oop Oop SmallInteger SmallInteger ).
	s _ self socketValueOf: socket.

	"buffer can be any indexable words or bytes object except CompiledMethod "
	interpreterProxy success: (interpreterProxy isWordsOrBytes: array).
	(interpreterProxy isWords: array)
		ifTrue: [byteSize _ 4]
		ifFalse: [byteSize _ 1].
	interpreterProxy success: (startIndex >= 1
			and: [count >= 0 and: [startIndex + count - 1 <= (interpreterProxy slotSizeOf: array)]]).
	interpreterProxy failed
		ifFalse: ["Note: adjust bufStart for zero-origin indexing"
			arrayBase _ self cCoerce: (interpreterProxy firstIndexableField: array)
						to: 'int'.
			bufStart _ arrayBase + (startIndex - 1 * byteSize).
			bytesSent _ self
						sqSocket: s
						SendDataBuf: bufStart
						Count: count * byteSize].
	^ (bytesSent // byteSize) asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket sendUDPData: array toHost: hostAddress  port: portNumber start: startIndex count: count [ 
	| s byteSize arrayBase bufStart bytesSent address |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketSendUDPDataBufCount'
		parameters: #(Oop Oop ByteArray SmallInteger SmallInteger SmallInteger ).
	s _ self socketValueOf: socket.

	"buffer can be any indexable words or bytes object except CompiledMethod "
	interpreterProxy success: (interpreterProxy isWordsOrBytes: array).
	(interpreterProxy isWords: array)
		ifTrue: [byteSize _ 4]
		ifFalse: [byteSize _ 1].
	interpreterProxy success: (startIndex >= 1
			and: [count >= 0 and: [startIndex + count - 1 <= (interpreterProxy slotSizeOf: array)]]).
	interpreterProxy failed
		ifFalse: ["Note: adjust bufStart for zero-origin indexing"
			arrayBase _ self cCoerce: (interpreterProxy firstIndexableField: array)
						to: 'int'.
			bufStart _ arrayBase + (startIndex - 1 * byteSize).
			address _ self netAddressToInt: (self cCoerce: hostAddress to: 'unsigned char *').
			bytesSent _ self
						sqSocket: s
						toHost: address
						port: portNumber
						SendDataBuf: bufStart
						Count: count * byteSize].
	^ (bytesSent // byteSize) asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket setOptions: optionName value: optionValue [

	| s optionNameStart optionNameSize optionValueStart optionValueSize returnedValue errorCode results |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketSetOptions'
		parameters: #(Oop Oop Oop).

	s _ self socketValueOf: socket.
	interpreterProxy success: (interpreterProxy isBytes: optionName).
	optionNameStart _ self cCoerce: (interpreterProxy firstIndexableField: optionName) to: 'int'.
	optionNameSize _ interpreterProxy slotSizeOf: optionName.
	interpreterProxy success: (interpreterProxy isBytes: optionValue).
	optionValueStart_ self cCoerce: (interpreterProxy firstIndexableField: optionValue) to: 'int'.
	optionValueSize _ interpreterProxy slotSizeOf: optionValue.

	interpreterProxy failed ifTrue: [^nil].
	returnedValue _ 0.

	errorCode _ self sqSocketSetOptions: s 
			optionNameStart: optionNameStart 
			optionNameSize: optionNameSize
			optionValueStart: optionValueStart
			optionValueSize: optionValueSize
			returnedValue: (self cCode: '&returnedValue').

	interpreterProxy pushRemappableOop: returnedValue asSmallIntegerObj.
	interpreterProxy pushRemappableOop: errorCode asSmallIntegerObj.
	interpreterProxy pushRemappableOop: (interpreterProxy instantiateClass: (interpreterProxy classArray) indexableSize: 2).
	results _ interpreterProxy popRemappableOop.
	interpreterProxy storePointer: 0 ofObject: results withValue: interpreterProxy popRemappableOop.
	interpreterProxy storePointer: 1 ofObject: results withValue: interpreterProxy popRemappableOop.
	^ results
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketAbortConnection: socket [

	| s |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketAbortConnection'
		parameters: #(Oop).
	s _ self socketValueOf: socket.
	interpreterProxy failed ifFalse: [
		self sqSocketAbortConnection: s]
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketAcceptFrom: sockHandle rcvBufferSize: recvBufSize sndBufSize: sendBufSize semaIndex: semaIndex [ 
	| socketOop s serverSocket |
	self var: #s declareC: 'SocketPtr s'.
	self var: #serverSocket declareC: 'SocketPtr serverSocket'.
	self primitive: 'primitiveSocketAccept'
		parameters: #(Oop SmallInteger SmallInteger SmallInteger ).
	serverSocket _ self socketValueOf: sockHandle.

	interpreterProxy failed
		ifFalse: [socketOop _ interpreterProxy instantiateClass: interpreterProxy classByteArray indexableSize: self socketRecordSize.
			s _ self socketValueOf: socketOop.
			self
				sqSocket: s
				AcceptFrom: serverSocket
				RecvBytes: recvBufSize
				SendBytes: sendBufSize
				SemaID: semaIndex].
	^ socketOop
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketAcceptFrom: sockHandle rcvBufferSize: recvBufSize sndBufSize: sendBufSize semaIndex: semaIndex readSemaIndex: aReadSema writeSemaIndex: aWriteSema [
	| socketOop s serverSocket |
	self var: #s declareC: 'SocketPtr s'.
	self var: #serverSocket declareC: 'SocketPtr serverSocket'.
	self primitive: 'primitiveSocketAccept3Semaphores'
		parameters: #(Oop SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger).
	serverSocket _ self socketValueOf: sockHandle.

	interpreterProxy failed
		ifFalse: [socketOop _ interpreterProxy instantiateClass: interpreterProxy classByteArray indexableSize: self socketRecordSize.
			s _ self socketValueOf: socketOop.
			self
				sqSocket: s
				AcceptFrom: serverSocket
				RecvBytes: recvBufSize
				SendBytes: sendBufSize
				SemaID: semaIndex
				ReadSemaID: aReadSema
				WriteSemaID: aWriteSema].
	^ socketOop
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketCloseConnection: socket [

	| s |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketCloseConnection'
		parameters: #(Oop).
	s _ self socketValueOf: socket.
	interpreterProxy failed ifFalse: [
		self sqSocketCloseConnection: s]
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketConnectionStatus: socket [

	| s status |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketConnectionStatus'
		parameters: #(Oop).
	s _ self socketValueOf: socket.
	interpreterProxy failed ifFalse: [
		status _ self sqSocketConnectionStatus: s].
	^ status asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketCreateNetwork: netType type: socketType receiveBufferSize: recvBufSize sendBufSize: sendBufSize semaIndex: semaIndex [ 
	| socketOop s okToCreate |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketCreate' parameters: #(#SmallInteger #SmallInteger #SmallInteger #SmallInteger #SmallInteger ).
	"If the security plugin can be loaded, use it to check for permission.
	If 
	not, assume it's ok"
	sCCSOTfn ~= 0
		ifTrue: [okToCreate _ self cCode: ' ((int (*) (int, int)) sCCSOTfn)(netType, socketType)'.
			okToCreate
				ifFalse: [^ interpreterProxy primitiveFail]].
	socketOop _ interpreterProxy instantiateClass: interpreterProxy classByteArray indexableSize: self socketRecordSize.
	s _ self socketValueOf: socketOop.
	self
		sqSocket: s
		CreateNetType: netType
		SocketType: socketType
		RecvBytes: recvBufSize
		SendBytes: sendBufSize
		SemaID: semaIndex.
	^ socketOop
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketCreateNetwork: netType type: socketType receiveBufferSize: recvBufSize sendBufSize: sendBufSize semaIndex: semaIndex readSemaIndex: aReadSema writeSemaIndex: aWriteSema [ 
	| socketOop s okToCreate |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketCreate3Semaphores' parameters: #(#SmallInteger #SmallInteger #SmallInteger #SmallInteger #SmallInteger #SmallInteger #SmallInteger ).
	"If the security plugin can be loaded, use it to check for permission.
	If 
	not, assume it's ok"
	sCCSOTfn ~= 0
		ifTrue: [okToCreate _ self cCode: ' ((int (*) (int, int)) sCCSOTfn)(netType, socketType)'.
			okToCreate
				ifFalse: [^ interpreterProxy primitiveFail]].
	socketOop _ interpreterProxy instantiateClass: interpreterProxy classByteArray indexableSize: self socketRecordSize.
	s _ self socketValueOf: socketOop.
	self
		sqSocket: s
		CreateNetType: netType
		SocketType: socketType
		RecvBytes: recvBufSize
		SendBytes: sendBufSize
		SemaID: semaIndex
		ReadSemaID: aReadSema
		WriteSemaID: aWriteSema.
	^ socketOop
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketDestroy: socket [

	| s |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketDestroy'
		parameters: #(Oop).
	s _ self socketValueOf: socket.
	interpreterProxy failed ifFalse: [
		self sqSocketDestroy: s]
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketError: socket [

	| s err |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketError'
		parameters: #(Oop).
	s _ self socketValueOf: socket.
	interpreterProxy failed ifFalse: [
		err _ self sqSocketError: s].
	^err asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketListenWithOrWithoutBacklog [
	"Backward compatibility"
	self export: true.
	interpreterProxy methodArgumentCount = 2
		ifTrue:[^self primitiveSocketListenOnPort]
		ifFalse:[^self primitiveSocketListenOnPortBacklog]

]

{ #category : #primitives }
SocketPlugin >> primitiveSocketLocalAddress: socket [

	| s addr |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketLocalAddress'
		parameters: #(Oop).
	s _ self socketValueOf: socket.
	addr _ self sqSocketLocalAddress: s.
	^self intToNetAddress: addr
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketLocalPort: socket [

	| s port |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketLocalPort'
		parameters: #(Oop).
	s _ self socketValueOf: socket.
	port _ self sqSocketLocalPort: s.
	^port asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketReceiveDataAvailable: socket [

	| s dataIsAvailable |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketReceiveDataAvailable'
		parameters: #(Oop).
	s _ self socketValueOf: socket.
	dataIsAvailable _ self sqSocketReceiveDataAvailable: s.
	^dataIsAvailable asBooleanObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketRemoteAddress: socket [

	| s addr |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketRemoteAddress'
		parameters: #(Oop).
	s _ self socketValueOf: socket.
	addr _ self sqSocketRemoteAddress: s.
	^self intToNetAddress: addr
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketRemotePort: socket [

	| s port |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketRemotePort'
		parameters: #(Oop).
	s _ self socketValueOf: socket.
	port _ self sqSocketRemotePort: s.
	^port asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketSendDone: socket [

	| s done |
	self var: #s declareC: 'SocketPtr s'.
	self primitive: 'primitiveSocketSendDone'
		parameters: #(Oop).
	s _ self socketValueOf: socket.
	done _ self sqSocketSendDone: s.
	^done asBooleanObj
]

{ #category : #'initialize-release' }
SocketPlugin >> shutdownModule [
	self export: true.
	^self cCode: 'socketShutdown()' inSmalltalk:[true]
]

{ #category : #primitives }
SocketPlugin >> socketRecordSize [
	"Return the size of a Smalltalk socket record in bytes."

	^ self cCode: 'sizeof(SQSocket)' inSmalltalk: [12]
]

{ #category : #primitives }
SocketPlugin >> socketValueOf: socketOop [ 
	"Return a pointer to the first byte of of the socket record within the  
	given Smalltalk object, or nil if socketOop is not a socket record."
	| socketIndex |
	self returnTypeC: 'SQSocket *'.
	interpreterProxy success: ((interpreterProxy isBytes: socketOop)
			and: [(interpreterProxy byteSizeOf: socketOop)
					= self socketRecordSize]).
	interpreterProxy failed
		ifTrue: [^ nil]
		ifFalse: [socketIndex _ self cCoerce: (interpreterProxy firstIndexableField: socketOop)
						to: 'int'.
			^ self cCode: '(SQSocket *) socketIndex']
]
