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
SocketPlugin class >> declareCVarsIn: aCCodeGenerator [

	aCCodeGenerator var: 'sDSAfn'	type: 'void *'.
	aCCodeGenerator var: 'sHSAfn'	type: 'void *'.
	aCCodeGenerator var: 'sCCTPfn'	type: 'void *'.
	aCCodeGenerator var: 'sCCLOPfn'	type: 'void *'.
	aCCodeGenerator var: 'sCCSOTfn'	type: 'void *'.
	aCCodeGenerator addHeaderFile: '"SocketPlugin.h"'
]

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
	<export: true>
	sDSAfn := interpreterProxy ioLoadFunction: 'secDisableSocketAccess' From: 'SecurityPlugin'.
	sHSAfn := interpreterProxy ioLoadFunction: 'secHasSocketAccess' From: 'SecurityPlugin'.
	sCCTPfn := interpreterProxy ioLoadFunction: 'secCanConnectToPort' From: 'SecurityPlugin'.
	sCCLOPfn := interpreterProxy ioLoadFunction: 'secCanListenOnPort' From: 'SecurityPlugin'.
	sCCSOTfn := interpreterProxy ioLoadFunction: 'secCanCreateSocketOfType' From: 'SecurityPlugin'.
	^self cCode: 'socketInit()' inSmalltalk:[true]
]

{ #category : #primitives }
SocketPlugin >> intToNetAddress: addr [
	"Convert the given 32-bit integer into an internet network address represented as a four-byte ByteArray."

	| netAddressOop naPtr |
	<var: #naPtr type: 'char * '>

	netAddressOop :=
		interpreterProxy instantiateClass: interpreterProxy classByteArray
			indexableSize: 4.
	naPtr := netAddressOop asCharPtr.
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
	<export: true>
	<var: #aModuleName type: 'char *'>
	(aModuleName strcmp: 'SecurityPlugin') = 0 ifTrue:[
		"The security plugin just shut down. How odd."
		sDSAfn := sHSAfn := sCCTPfn := sCCLOPfn := sCCSOTfn := 0.
	].
]

{ #category : #primitives }
SocketPlugin >> netAddressToInt: ptrToByteArray [
	"Convert the given internet network address (represented as a four-byte ByteArray) into a 32-bit integer. Fail if the given ptrToByteArray does not appear to point to a four-byte ByteArray."

	| sz |
	<var: #ptrToByteArray type: 'unsigned char * '>
	sz := interpreterProxy byteSizeOf: ptrToByteArray cPtrAsOop.
	sz = 4 ifFalse: [^ interpreterProxy primitiveFail].
	^ (ptrToByteArray at: 3	) +
		((ptrToByteArray at: 2) <<8) +
		((ptrToByteArray at: 1) <<16) +
		((ptrToByteArray at: 0) <<24)
]

{ #category : #'security primitives' }
SocketPlugin >> primitiveDisableSocketAccess [
	<export: true>
	"If the security plugin can be loaded, use it to turn off socket access
	 If not, assume it's ok"
	sDSAfn ~= 0 ifTrue:
		[self cCode: '((sqInt (*) (void)) sDSAfn)()']
]

{ #category : #'security primitives' }
SocketPlugin >> primitiveHasSocketAccess [
	| hasAccess |
	<export: true>
	"If the security plugin can be loaded, use it to check . 
	 If not, assume it's ok"
	hasAccess :=	sHSAfn = 0
					or: [self cCode: ' ((sqInt (*) (void)) sHSAfn)()' inSmalltalk:[true]].
	interpreterProxy pop: 1.
	interpreterProxy pushBool: hasAccess
]

{ #category : #primitives }
SocketPlugin >> primitiveInitializeNetwork: resolverSemaIndex [

	| err |
	self primitive: 'primitiveInitializeNetwork'
		parameters: #(SmallInteger).
	err := self sqNetworkInit: resolverSemaIndex.
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
	sz := self sqResolverAddrLookupResultSize.

	interpreterProxy failed
		ifFalse: [s := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: sz.
			self sqResolverAddrLookup: s asCharPtr Result: sz].
	^ s
]

{ #category : #primitives }
SocketPlugin >> primitiveResolverError [

	self primitive: 'primitiveResolverError'.
	^ self sqResolverError asSmallIntegerObj
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveResolverGetAddressInfoFamily [

	| family |
	self primitive: 'primitiveResolverGetAddressInfoFamily'
		parameters: #().
	interpreterProxy failed
		ifFalse:
			[family := self sqResolverGetAddressInfoFamily.
			 ^family asSmallIntegerObj]
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveResolverGetAddressInfoHost: hostName service: servName flags: flags family: family type: type protocol: protocol [

	| hostSize servSize |
	self primitive: 'primitiveResolverGetAddressInfo'
		parameters: #(String String SmallInteger SmallInteger SmallInteger SmallInteger).
	interpreterProxy failed
		ifFalse:
			[hostSize := interpreterProxy byteSizeOf: hostName cPtrAsOop.
			 servSize := interpreterProxy byteSizeOf: servName cPtrAsOop.
			 self
			 	sqResolverGetAddressInfoHost: hostName Size: hostSize Service: servName Size: servSize
					Flags: flags Family: family Type: type Protocol: protocol]
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveResolverGetAddressInfoNext [

	| more |
	self primitive: 'primitiveResolverGetAddressInfoNext'
		parameters: #().
	more := self sqResolverGetAddressInfoNext.
	interpreterProxy failed ifTrue: [^nil].
	^more asBooleanObj
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveResolverGetAddressInfoProtocol [

	| protocol |
	self primitive: 'primitiveResolverGetAddressInfoProtocol'
		parameters: #().
	interpreterProxy failed
		ifFalse:
			[protocol := self sqResolverGetAddressInfoProtocol.
			 ^protocol asSmallIntegerObj]
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveResolverGetAddressInfoResult: socketAddress [

	| addrSize |
	self primitive: 'primitiveResolverGetAddressInfoResult'
		parameters: #(ByteArray).
	interpreterProxy failed
		ifFalse:
			[addrSize := interpreterProxy byteSizeOf: socketAddress cPtrAsOop.
			 self sqResolverGetAddressInfoResult: socketAddress Size: addrSize]
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveResolverGetAddressInfoSize [

	| size |
	self primitive: 'primitiveResolverGetAddressInfoSize'
		parameters: #().
	interpreterProxy failed
		ifFalse:
			[size := self sqResolverGetAddressInfoSize.
			 ^size asSmallIntegerObj]
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveResolverGetAddressInfoType [

	| type |
	self primitive: 'primitiveResolverGetAddressInfoType'
		parameters: #().
	interpreterProxy failed
		ifFalse:
			[type := self sqResolverGetAddressInfoType.
			 ^type asSmallIntegerObj]
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveResolverGetNameInfo: socketAddress flags: flags [

	| addrSize addrBase |
	<var: #addrBase type: 'char *'>
	self primitive: 'primitiveResolverGetNameInfo'
		parameters: #(Oop SmallInteger).
	interpreterProxy failed
		ifFalse:
			[addrSize := interpreterProxy byteSizeOf: socketAddress.
			 addrBase := self cCoerce: (interpreterProxy firstIndexableField: socketAddress) to: 'char *'.
			 self sqResolverGetNameInfo: addrBase Size: addrSize Flags: flags]
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveResolverGetNameInfoHostResult: socketName [

	| addrSize |
	self primitive: 'primitiveResolverGetNameInfoHostResult'
		parameters: #(String).
	interpreterProxy failed
		ifFalse:
			[addrSize := interpreterProxy byteSizeOf: socketName cPtrAsOop.
			 self sqResolverGetNameInfoHostResult: socketName Size: addrSize]
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveResolverGetNameInfoHostSize [

	| size |
	self primitive: 'primitiveResolverGetNameInfoHostSize'
		parameters: #().
	interpreterProxy failed
		ifFalse:
			[size := self sqResolverGetNameInfoHostSize.
			 ^size asSmallIntegerObj]
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveResolverGetNameInfoServiceResult: socketName [

	| addrSize |
	self primitive: 'primitiveResolverGetNameInfoServiceResult'
		parameters: #(String).
	interpreterProxy failed
		ifFalse:
			[addrSize := interpreterProxy byteSizeOf: socketName cPtrAsOop.
			 self sqResolverGetNameInfoServiceResult: socketName Size: addrSize]
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveResolverGetNameInfoServiceSize [

	| size |
	self primitive: 'primitiveResolverGetNameInfoServiceSize'
		parameters: #().
	interpreterProxy failed
		ifFalse:
			[size := self sqResolverGetNameInfoServiceSize.
			 ^size asSmallIntegerObj]
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveResolverHostNameResult: nameString [

	| nameSize |
	self primitive: 'primitiveResolverHostNameResult'
		parameters: #(String).
	interpreterProxy failed
		ifFalse:
			[nameSize := interpreterProxy byteSizeOf: nameString cPtrAsOop.
			 self sqResolverHostNameResult: nameString Size: nameSize]
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveResolverHostNameSize [

	| size |
	self primitive: 'primitiveResolverHostNameSize'
		parameters: #().
	interpreterProxy failed
		ifFalse:
			[size := self sqResolverHostNameSize.
			 interpreterProxy failed ifFalse: [^size asSmallIntegerObj]]
]

{ #category : #primitives }
SocketPlugin >> primitiveResolverLocalAddress [

	| addr |
	self primitive: 'primitiveResolverLocalAddress'.
	addr := self sqResolverLocalAddress.
	^self intToNetAddress: addr
]

{ #category : #primitives }
SocketPlugin >> primitiveResolverNameLookupResult [

	| addr |
	self primitive: 'primitiveResolverNameLookupResult'.
	addr := self sqResolverNameLookupResult.
	^self intToNetAddress: addr
]

{ #category : #primitives }
SocketPlugin >> primitiveResolverStartAddressLookup: address [

	| addr |
	self primitive: 'primitiveResolverStartAddressLookup'
		parameters: #(ByteArray).
	addr := self netAddressToInt: (self cCoerce: address to: 'unsigned char *').
	interpreterProxy failed ifFalse: [
		self sqResolverStartAddrLookup: addr]
]

{ #category : #primitives }
SocketPlugin >> primitiveResolverStartNameLookup: name [

	| sz |
	self primitive: 'primitiveResolverStartNameLookup'
		parameters: #(String).
	interpreterProxy failed ifFalse:  [
		sz := interpreterProxy byteSizeOf: name cPtrAsOop.
		self sqResolverStartName: name Lookup: sz]
]

{ #category : #primitives }
SocketPlugin >> primitiveResolverStatus [

	| status |
	self primitive: 'primitiveResolverStatus'.
	status := self sqResolverStatus.
	^status asSmallIntegerObj
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveSocket: socket bindTo: socketAddress [

	| addrSize addrBase s  |
	<var: #addrBase type: 'char *'>
	<var: #s type: 'SocketPtr'>
	self primitive: 'primitiveSocketBindTo' parameters: #(#Oop #Oop).
	s := self socketValueOf: socket.
	addrSize := interpreterProxy byteSizeOf: socketAddress.
	addrBase := self cCoerce: (interpreterProxy firstIndexableField: socketAddress) to: 'char *'.
	interpreterProxy failed ifFalse: [self sqSocket: s BindToAddress: addrBase Size: addrSize]
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket bindTo: address port: port [ 
	| addr s  |
	<var: #s declareC: 'SocketPtr s'>
	self primitive: 'primitiveSocketBindToPort' parameters: #(#Oop #ByteArray #SmallInteger ).
	addr := self
				netAddressToInt: (self cCoerce: address to: 'unsigned char *').
	s := self socketValueOf: socket.
	interpreterProxy failed 
		ifFalse:[self sqSocket: s BindTo: addr Port: port]
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveSocket: socket connectTo: socketAddress [

	| addrSize addrBase s  |
	<var: #addrBase type: 'char *'>
	<var: #s type: 'SocketPtr'>
	self primitive: 'primitiveSocketConnectTo' parameters: #(#Oop #Oop).
	s := self socketValueOf: socket.
	addrSize := interpreterProxy byteSizeOf: socketAddress.
	addrBase := self cCoerce: (interpreterProxy firstIndexableField: socketAddress) to: 'char *'.
	interpreterProxy failed ifFalse: [self sqSocket: s ConnectToAddress: addrBase Size: addrSize]
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket connectTo: address port: port [ 
	| addr s okToConnect  |
	<var: #s type: 'SocketPtr'>
	self primitive: 'primitiveSocketConnectToPort' parameters: #(#Oop #ByteArray #SmallInteger ).
	addr := self netAddressToInt: (self cCoerce: address to: 'unsigned char *').
	"If the security plugin can be loaded, use it to check for permission.
	If not, assume it's ok"
	sCCTPfn ~= 0 ifTrue:
		[okToConnect := self cCode: ' ((sqInt (*) (sqInt, sqInt)) sCCTPfn)(addr, port)'.
		 okToConnect ifFalse:
			[^ interpreterProxy primitiveFail]].
	s := self socketValueOf: socket.
	interpreterProxy failed ifFalse:
		[self sqSocket: s ConnectTo: addr Port: port]
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket getOptions: optionName [

	| s optionNameStart optionNameSize returnedValue errorCode results |
	<var: #s type: #SocketPtr>
	<var: #optionNameStart type: #'char *'>
	self primitive: 'primitiveSocketGetOptions'
		parameters: #(Oop Oop).

	s := self socketValueOf: socket.
	interpreterProxy success: (interpreterProxy isBytes: optionName).
	optionNameStart := self cCoerce: (interpreterProxy firstIndexableField: optionName) to: #'char *'.
	optionNameSize := interpreterProxy slotSizeOf: optionName.

	interpreterProxy failed ifTrue: [^nil].
	returnedValue := 0.

	errorCode := self sqSocketGetOptions: s 
					optionNameStart: optionNameStart 
					optionNameSize: optionNameSize
					returnedValue: (self addressOf: returnedValue).

	results := interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: 2.
	interpreterProxy storePointer: 0 ofObject: results withValue: errorCode asSmallIntegerObj.
	interpreterProxy storePointer: 1 ofObject: results withValue: returnedValue asSmallIntegerObj.
	^ results
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket listenOnPort: port [ 
	"one part of the wierdass dual prim primitiveSocketListenOnPort which 
	was warped by some demented evil person determined to twist the very 
	nature of reality"
	| s  okToListen |
	<var: #s type: 'SocketPtr '>
	self primitive: 'primitiveSocketListenOnPort' parameters: #(#Oop #SmallInteger ).
	s := self socketValueOf: socket.
	"If the security plugin can be loaded, use it to check for permission.
	If  not, assume it's ok"
	sCCLOPfn ~= 0 ifTrue:
		[okToListen := self cCode: ' ((sqInt (*) (sqInt, sqInt)) sCCLOPfn)((sqInt)s, port)'.
		 okToListen ifFalse:
			[^ interpreterProxy primitiveFail]].
	interpreterProxy failed ifFalse:
		[self sqSocket: s ListenOnPort: port]
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket listenOnPort: port backlogSize: backlog [ 
	"second part of the wierdass dual prim primitiveSocketListenOnPort 
	which was warped by some demented evil person determined to twist the 
	very nature of reality"
	| s okToListen |
	<var: #s type: 'SocketPtr'>
	self primitive: 'primitiveSocketListenOnPortBacklog' parameters: #(#Oop #SmallInteger #SmallInteger ).
	s := self socketValueOf: socket.
	"If the security plugin can be loaded, use it to check for permission.
	If not, assume it's ok"
	sCCLOPfn ~= 0 ifTrue:
		[okToListen := self cCode: ' ((sqInt (*) (sqInt, sqInt)) sCCLOPfn)((sqInt)s, port)'.
		 okToListen ifFalse:
			[^interpreterProxy primitiveFail]].
	self sqSocket: s ListenOnPort: port BacklogSize: backlog
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket listenOnPort: port backlogSize: backlog interface: ifAddr [
	"Bind a socket to the given port and interface address with no more than backlog pending connections.  The socket can be UDP, in which case the backlog should be specified as zero."

	| s okToListen addr |
	<var: #s type: 'SocketPtr'>
	self primitive: 'primitiveSocketListenOnPortBacklogInterface' parameters: #(#Oop #SmallInteger #SmallInteger #ByteArray).
	s := self socketValueOf: socket.
	"If the security plugin can be loaded, use it to check for permission.
	If  not, assume it's ok"
	sCCLOPfn ~= 0 ifTrue:
		[okToListen := self cCode: ' ((sqInt (*) (sqInt, sqInt)) sCCLOPfn)((sqInt)s, port)'.
		 okToListen ifFalse:
			[^ interpreterProxy primitiveFail]].
	addr := self netAddressToInt: (self cCoerce: ifAddr to: 'unsigned char *').
	self sqSocket: s ListenOnPort: port BacklogSize: backlog Interface: addr
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveSocket: socket listenWithBacklog: backlogSize [

	| s  |
	<var: #s type: 'SocketPtr'>
	self primitive: 'primitiveSocketListenWithBacklog' parameters: #(#Oop #SmallInteger).
	s := self socketValueOf: socket.
	interpreterProxy failed ifFalse: [self sqSocket: s ListenBacklog: backlogSize]
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveSocket: socket localAddressResult: socketAddress [

	| addrSize addrBase s  |
	<var: #addrBase type: 'char *'>
	<var: #s type: 'SocketPtr'>
	self primitive: 'primitiveSocketLocalAddressResult' parameters: #(#Oop #Oop).
	s := self socketValueOf: socket.
	addrSize := interpreterProxy byteSizeOf: socketAddress.
	addrBase := self cCoerce: (interpreterProxy firstIndexableField: socketAddress) to: 'char *'.
	interpreterProxy failed ifFalse: [self sqSocket: s LocalAddressResult: addrBase Size: addrSize]
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket receiveDataBuf: array start: startIndex count: count [ 
	| s byteSize arrayBase bufStart bytesReceived |
	<var: #s type: 'SocketPtr'>
	<var: #arrayBase type: 'char *'>
	<var: #bufStart type: 'char *'>
	self primitive: 'primitiveSocketReceiveDataBufCount'
		parameters: #(Oop Oop SmallInteger SmallInteger ).
	s := self socketValueOf: socket.

	"buffer can be any indexable words or bytes object"
	interpreterProxy success: (interpreterProxy isWordsOrBytes: array).
	(interpreterProxy isWords: array)
		ifTrue: [byteSize := 4]
		ifFalse: [byteSize := 1].
	interpreterProxy success: (startIndex >= 1
			and: [count >= 0 and: [startIndex + count - 1 <= (interpreterProxy slotSizeOf: array)]]).
	interpreterProxy failed
		ifFalse: ["Note: adjust bufStart for zero-origin indexing"
			arrayBase := self cCoerce: (interpreterProxy firstIndexableField: array) to: 'char *'.
			bufStart := arrayBase + (startIndex - 1 * byteSize).
			bytesReceived := self
						sqSocket: s
						ReceiveDataBuf: bufStart
						Count: count * byteSize].
	^ (bytesReceived // byteSize) asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket receiveUDPDataBuf: array start: startIndex count: count [ 
	| s elementSize arrayBase bufStart bytesReceived results address port moreFlag |
	<var: #s type: #SocketPtr>
	<var: #arrayBase type: #'char *'>
	<var: #bufStart type: #'char *'>
	self primitive: 'primitiveSocketReceiveUDPDataBufCount'
		parameters: #(Oop Oop SmallInteger SmallInteger).
	s := self socketValueOf: socket.

	"buffer can be any indexable words or bytes object"
	interpreterProxy success: (interpreterProxy isWordsOrBytes: array).
	(interpreterProxy isWords: array)
		ifTrue: [elementSize := 4]
		ifFalse: [elementSize := 1].
	interpreterProxy success: (startIndex >= 1
			and: [count >= 0 and: [startIndex + count - 1 <= (interpreterProxy slotSizeOf: array)]]).
	interpreterProxy failed
		ifFalse: ["Note: adjust bufStart for zero-origin indexing"
			arrayBase		:= self cCoerce: (interpreterProxy firstIndexableField: array) to: #'char *'.
			bufStart		:= arrayBase + (startIndex - 1 * elementSize).
			address		:= 0.
			port			:= 0.
			moreFlag		:= 0.
			bytesReceived := self sqSocket: s
									ReceiveUDPDataBuf: bufStart
									Count: count * elementSize
									address: (self addressOf: address)
									port: (self addressOf: port)
									moreFlag: (self addressOf: moreFlag).

			"allocate storage for results, remapping newly allocated
			 oops in case GC happens during allocation"
			interpreterProxy pushRemappableOop: (self intToNetAddress: address).
			results := interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: 4.
			interpreterProxy storePointer: 0 ofObject: results withValue: (bytesReceived // elementSize) asSmallIntegerObj.
			interpreterProxy storePointer: 1 ofObject: results withValue: interpreterProxy popRemappableOop.
			interpreterProxy storePointer: 2 ofObject: results withValue: port asSmallIntegerObj.
			interpreterProxy storePointer: 3 ofObject: results withValue: (moreFlag
																			ifTrue: [interpreterProxy trueObject]
																			ifFalse: [interpreterProxy falseObject]).
			].
	^ results
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveSocket: socket remoteAddressResult: socketAddress [

	| addrSize addrBase s  |
	<var: #addrBase type: 'char *'>
	<var: #s type: 'SocketPtr'>
	self primitive: 'primitiveSocketRemoteAddressResult' parameters: #(#Oop #Oop).
	s := self socketValueOf: socket.
	addrSize := interpreterProxy byteSizeOf: socketAddress.
	addrBase := self cCoerce: (interpreterProxy firstIndexableField: socketAddress) to: 'char *'.
	interpreterProxy failed ifFalse: [self sqSocket: s RemoteAddressResult: addrBase Size: addrSize]
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket sendData: array start: startIndex count: count [ 
	| s byteSize arrayBase bufStart bytesSent |
	<var: #s type: 'SocketPtr'>
	<var: #arrayBase type: 'char *'>
	<var: #bufStart type: 'char *'>
	self primitive: 'primitiveSocketSendDataBufCount'
		parameters: #(Oop Oop SmallInteger SmallInteger ).
	s := self socketValueOf: socket.

	"buffer can be any indexable words or bytes object except CompiledMethod "
	interpreterProxy success: (interpreterProxy isWordsOrBytes: array).
	(interpreterProxy isWords: array)
		ifTrue: [byteSize := 4]
		ifFalse: [byteSize := 1].
	interpreterProxy success: (startIndex >= 1
			and: [count >= 0 and: [startIndex + count - 1 <= (interpreterProxy slotSizeOf: array)]]).
	interpreterProxy failed
		ifFalse: ["Note: adjust bufStart for zero-origin indexing"
			arrayBase := self cCoerce: (interpreterProxy firstIndexableField: array) to: 'char *'.
			bufStart := arrayBase + (startIndex - 1 * byteSize).
			bytesSent := self
						sqSocket: s
						SendDataBuf: bufStart
						Count: count * byteSize].
	^ (bytesSent // byteSize) asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket sendUDPData: array toHost: hostAddress  port: portNumber start: startIndex count: count [ 
	| s byteSize arrayBase bufStart bytesSent address |
	<var: #s type: 'SocketPtr'>
	<var: #arrayBase type: 'char *'>
	<var: #bufStart type: 'char *'>
	self primitive: 'primitiveSocketSendUDPDataBufCount'
		parameters: #(Oop Oop ByteArray SmallInteger SmallInteger SmallInteger ).
	s := self socketValueOf: socket.

	"buffer can be any indexable words or bytes object except CompiledMethod "
	interpreterProxy success: (interpreterProxy isWordsOrBytes: array).
	(interpreterProxy isWords: array)
		ifTrue: [byteSize := 4]
		ifFalse: [byteSize := 1].
	interpreterProxy success: (startIndex >= 1
			and: [count >= 0 and: [startIndex + count - 1 <= (interpreterProxy slotSizeOf: array)]]).
	interpreterProxy failed
		ifFalse: ["Note: adjust bufStart for zero-origin indexing"
			arrayBase := self cCoerce: (interpreterProxy firstIndexableField: array) to: 'char *'.
			bufStart := arrayBase + (startIndex - 1 * byteSize).
			address := self netAddressToInt: (self cCoerce: hostAddress to: 'unsigned char *').
			bytesSent := self
						sqSocket: s
						toHost: address
						port: portNumber
						SendDataBuf: bufStart
						Count: count * byteSize].
	^ (bytesSent // byteSize) asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocket: socket setOptions: optionName value: optionValue [
	"THIS BADLY NEEDS TO BE REWRITTEN TO TAKE Booleans AND Integers AS WELL AS (OR INSTEAD OF) Strings.
	 It is only used with booleans and integers and parsing these back out of strings in
	 sqSocketSetOptions:optionNameStart:optionNameSize:optionValueStart:optionValueSize:returnedValue:
	 is STUPID."
	| s optionNameStart optionNameSize optionValueStart optionValueSize returnedValue errorCode results |
	<var: #s type: #SocketPtr>
	<var: #optionNameStart type: #'char *'>
	<var: #optionValueStart type: #'char *'>
	self primitive: 'primitiveSocketSetOptions'
		parameters: #(Oop Oop Oop).

	s := self socketValueOf: socket.
	interpreterProxy success: (interpreterProxy isBytes: optionName).
	optionNameStart := self cCoerce: (interpreterProxy firstIndexableField: optionName) to: #'char *'.
	optionNameSize := interpreterProxy slotSizeOf: optionName.
	interpreterProxy success: (interpreterProxy isBytes: optionValue).
	optionValueStart:= self cCoerce: (interpreterProxy firstIndexableField: optionValue) to: #'char *'.
	optionValueSize := interpreterProxy slotSizeOf: optionValue.

	interpreterProxy failed ifTrue: [^nil].
	returnedValue := 0.

	errorCode := self sqSocketSetOptions: s 
					optionNameStart: optionNameStart 
					optionNameSize: optionNameSize
					optionValueStart: optionValueStart
					optionValueSize: optionValueSize
					returnedValue: (self addressOf: returnedValue).

	results := interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: 2.
	interpreterProxy storePointer: 0 ofObject: results withValue: errorCode asSmallIntegerObj.
	interpreterProxy storePointer: 1 ofObject: results withValue: returnedValue asSmallIntegerObj.
	^ results
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketAbortConnection: socket [

	| s |
	<var: #s type: 'SocketPtr '>
	self primitive: 'primitiveSocketAbortConnection'
		parameters: #(Oop).
	s := self socketValueOf: socket.
	interpreterProxy failed ifFalse: [
		self sqSocketAbortConnection: s]
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketAcceptFrom: sockHandle rcvBufferSize: recvBufSize sndBufSize: sendBufSize semaIndex: semaIndex [ 
	| socketOop s serverSocket |
	<var: #s type: 'SocketPtr '>
	<var: #serverSocket type: 'SocketPtr '>
	self primitive: 'primitiveSocketAccept'
		parameters: #(Oop SmallInteger SmallInteger SmallInteger ).
	serverSocket := self socketValueOf: sockHandle.

	interpreterProxy failed
		ifFalse: [socketOop := interpreterProxy instantiateClass: interpreterProxy classByteArray indexableSize: self socketRecordSize.
			s := self socketValueOf: socketOop.
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
	<var: #s type: 'SocketPtr '>
	<var: #serverSocket type: 'SocketPtr '>
	self primitive: 'primitiveSocketAccept3Semaphores'
		parameters: #(Oop SmallInteger SmallInteger SmallInteger SmallInteger SmallInteger).
	serverSocket := self socketValueOf: sockHandle.

	interpreterProxy failed
		ifFalse: [socketOop := interpreterProxy instantiateClass: interpreterProxy classByteArray indexableSize: self socketRecordSize.
			s := self socketValueOf: socketOop.
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

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveSocketAddressGetPort [

	| addr addrSize addrBase port |
	<var: #addrBase type: 'char *'>
	addr := self primitive: 'primitiveSocketAddressGetPort' parameters: #() receiver: #Oop.
	addrSize := interpreterProxy byteSizeOf: addr.
	addrBase := self cCoerce: (interpreterProxy firstIndexableField: addr) to: 'char *'.
	interpreterProxy failed
		ifFalse:
			[port := self sqSocketAddress: addrBase SizeGetPort: addrSize.
			 interpreterProxy failed ifFalse: [^port asSmallIntegerObj]]
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveSocketAddressSetPort: portNumber [

	| addr addrSize addrBase |
	<var: #addrBase type: 'char *'>
	addr := self primitive: 'primitiveSocketAddressSetPort' parameters: #(SmallInteger) receiver: #Oop.
	addrSize := interpreterProxy byteSizeOf: addr.
	addrBase := self cCoerce: (interpreterProxy firstIndexableField: addr) to: 'char *'.
	interpreterProxy failed ifFalse: [self sqSocketAddress: addrBase Size: addrSize SetPort: portNumber]
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketCloseConnection: socket [

	| s |
	<var: #s type: 'SocketPtr '>
	self primitive: 'primitiveSocketCloseConnection'
		parameters: #(Oop).
	s := self socketValueOf: socket.
	interpreterProxy failed ifFalse: [
		self sqSocketCloseConnection: s]
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketConnectionStatus: socket [

	| s status |
	<var: #s type: 'SocketPtr '>
	self primitive: 'primitiveSocketConnectionStatus'
		parameters: #(Oop).
	s := self socketValueOf: socket.
	interpreterProxy failed ifFalse: [
		status := self sqSocketConnectionStatus: s].
	^ status asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketCreateNetwork: netType type: socketType receiveBufferSize: recvBufSize sendBufSize: sendBufSize semaIndex: semaIndex [ 
	| socketOop s okToCreate |
	<var: #s type: 'SocketPtr '>
	self primitive: 'primitiveSocketCreate' parameters: #(#SmallInteger #SmallInteger #SmallInteger #SmallInteger #SmallInteger ).
	"If the security plugin can be loaded, use it to check for permission.
	If  not, assume it's ok"
	sCCSOTfn ~= 0 ifTrue:
		[okToCreate := self cCode: ' ((sqInt (*) (sqInt, sqInt)) sCCSOTfn)(netType, socketType)'.
		 okToCreate ifFalse:
			[^ interpreterProxy primitiveFail]].
	socketOop := interpreterProxy instantiateClass: interpreterProxy classByteArray indexableSize: self socketRecordSize.
	s := self socketValueOf: socketOop.
	interpreterProxy failed ifFalse:
		[self
			sqSocket: s
			CreateNetType: netType
			SocketType: socketType
			RecvBytes: recvBufSize
			SendBytes: sendBufSize
			SemaID: semaIndex].
	^socketOop
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketCreateNetwork: netType type: socketType receiveBufferSize: recvBufSize sendBufSize: sendBufSize semaIndex: semaIndex readSemaIndex: aReadSema writeSemaIndex: aWriteSema [ 
	| socketOop s okToCreate |
	<var: #s type: 'SocketPtr '>
	self primitive: 'primitiveSocketCreate3Semaphores' parameters: #(#SmallInteger #SmallInteger #SmallInteger #SmallInteger #SmallInteger #SmallInteger #SmallInteger ).
	"If the security plugin can be loaded, use it to check for permission.
	If not, assume it's ok"
	sCCSOTfn ~= 0 ifTrue:
		[okToCreate := self cCode: ' ((sqInt (*) (sqInt, sqInt)) sCCSOTfn)(netType, socketType)'.
		 okToCreate ifFalse:
			[^ interpreterProxy primitiveFail]].
	socketOop := interpreterProxy instantiateClass: interpreterProxy classByteArray indexableSize: self socketRecordSize.
	s := self socketValueOf: socketOop.
	interpreterProxy failed ifFalse:
		[self
			sqSocket: s
			CreateNetType: netType
			SocketType: socketType
			RecvBytes: recvBufSize
			SendBytes: sendBufSize
			SemaID: semaIndex
			ReadSemaID: aReadSema
			WriteSemaID: aWriteSema].
	^socketOop
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketCreateRaw: netType type: protoType receiveBufferSize: recvBufSize sendBufSize: sendBufSize semaIndex: semaIndex readSemaIndex: aReadSema writeSemaIndex: aWriteSema [ 
	| socketOop s okToCreate |
	<var: #s type: 'SocketPtr '>
	self primitive: 'primitiveSocketCreateRAW' parameters: #(#SmallInteger #SmallInteger #SmallInteger #SmallInteger #SmallInteger #SmallInteger #SmallInteger ).
	"If the security plugin can be loaded, use it to check for permission.
	If not, assume it's ok"
	sCCSOTfn ~= 0 ifTrue:
		[okToCreate := self cCode: ' ((sqInt (*) (sqInt, sqInt)) sCCSOTfn)(netType, protoType)'.
		 okToCreate ifFalse:
			[^ interpreterProxy primitiveFail]].
	socketOop := interpreterProxy instantiateClass: interpreterProxy classByteArray indexableSize: self socketRecordSize.
	s := self socketValueOf: socketOop.
	interpreterProxy failed ifFalse:
		[self
			sqSocket: s
			CreateRaw: netType
			ProtoType: protoType
			RecvBytes: recvBufSize
			SendBytes: sendBufSize
			SemaID: semaIndex
			ReadSemaID: aReadSema
			WriteSemaID: aWriteSema].
	^ socketOop
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketDestroy: socket [

	| s |
	<var: #s type: 'SocketPtr'>
	self primitive: 'primitiveSocketDestroy'
		parameters: #(Oop).
	s := self socketValueOf: socket.
	interpreterProxy failed ifFalse: [
		self sqSocketDestroy: s]
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketError: socket [

	| s err |
	<var: #s type: 'SocketPtr '>
	self primitive: 'primitiveSocketError'
		parameters: #(Oop).
	s := self socketValueOf: socket.
	interpreterProxy failed ifFalse: [
		err := self sqSocketError: s].
	^err asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketListenWithOrWithoutBacklog [
	"Backward compatibility"
	<export: true>
	interpreterProxy methodArgumentCount = 2
		ifTrue:[^self primitiveSocketListenOnPort]
		ifFalse:[^self primitiveSocketListenOnPortBacklog]

]

{ #category : #primitives }
SocketPlugin >> primitiveSocketLocalAddress: socket [

	| s addr |
	<var: #s type: 'SocketPtr'>
	self primitive: 'primitiveSocketLocalAddress'
		parameters: #(Oop).
	s := self socketValueOf: socket.
	addr := self sqSocketLocalAddress: s.
	^self intToNetAddress: addr
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveSocketLocalAddressSize: socket [

	| s size |
	<var: #s type: 'SocketPtr'>
	self primitive: 'primitiveSocketLocalAddressSize' parameters: #(#Oop).
	s := self socketValueOf: socket.
	interpreterProxy failed ifTrue: [^nil].
	size := self sqSocketLocalAddressSize: s.
	interpreterProxy failed ifTrue: [^nil].
	^size asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketLocalPort: socket [

	| s port |
	<var: #s type: 'SocketPtr '>
	self primitive: 'primitiveSocketLocalPort'
		parameters: #(Oop).
	s := self socketValueOf: socket.
	port := self sqSocketLocalPort: s.
	^port asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketReceiveDataAvailable: socket [

	| s dataIsAvailable |
	<var: #s type: 'SocketPtr'>
	self primitive: 'primitiveSocketReceiveDataAvailable'
		parameters: #(Oop).
	s := self socketValueOf: socket.
	dataIsAvailable := self sqSocketReceiveDataAvailable: s.
	^dataIsAvailable asBooleanObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketRemoteAddress: socket [

	| s addr |
	<var: #s type: 'SocketPtr'>
	self primitive: 'primitiveSocketRemoteAddress'
		parameters: #(Oop).
	s := self socketValueOf: socket.
	addr := self sqSocketRemoteAddress: s.
	^self intToNetAddress: addr
]

{ #category : #'ipv6 primitives' }
SocketPlugin >> primitiveSocketRemoteAddressSize: socket [

	| s size |
	<var: #s type: 'SocketPtr'>
	self primitive: 'primitiveSocketRemoteAddressSize' parameters: #(#Oop).
	s := self socketValueOf: socket.
	interpreterProxy failed ifTrue: [^nil].
	size := self sqSocketRemoteAddressSize: s.
	interpreterProxy failed ifTrue: [^nil].
	^size asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketRemotePort: socket [

	| s port |
	<var: #s type: 'SocketPtr'>
	self primitive: 'primitiveSocketRemotePort'
		parameters: #(Oop).
	s := self socketValueOf: socket.
	port := self sqSocketRemotePort: s.
	^port asSmallIntegerObj
]

{ #category : #primitives }
SocketPlugin >> primitiveSocketSendDone: socket [

	| s done |
	<var: #s type: 'SocketPtr'>
	self primitive: 'primitiveSocketSendDone'
		parameters: #(Oop).
	s := self socketValueOf: socket.
	done := self sqSocketSendDone: s.
	^done asBooleanObj
]

{ #category : #'initialize-release' }
SocketPlugin >> shutdownModule [
	<export: true>
	^self cCode: 'socketShutdown()' inSmalltalk:[true]
]

{ #category : #primitives }
SocketPlugin >> socketRecordSize [
	"Return the size of a Smalltalk socket record in bytes."
	<inline: true>
	^ self sizeof: #SQSocket
]

{ #category : #primitives }
SocketPlugin >> socketValueOf: socketOop [ 
	"Return a pointer to the first byte of of the socket record within the  
	 given Smalltalk object, or nil if socketOop is not a socket record."
	<returnTypeC: 'SocketPtr'>
	interpreterProxy success: ((interpreterProxy isBytes: socketOop)
			and: [(interpreterProxy byteSizeOf: socketOop)
					= self socketRecordSize]).
	^interpreterProxy failed
		ifTrue: [nil]
		ifFalse: [self cCoerce: (interpreterProxy firstIndexableField: socketOop) to: 'SocketPtr']
]
