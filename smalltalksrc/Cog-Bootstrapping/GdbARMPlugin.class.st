"
I provide access to the ARMulator ARM emulator and the libopcodes ARM disassembler.
"
Class {
	#name : #GdbARMPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#instVars : [
		'prevInterruptCheckChain'
	],
	#pools : [
		'VMBasicConstants'
	],
	#category : #'Cog-ProcessorPlugins'
}

{ #category : #translation }
GdbARMPlugin class >> declareCVarsIn: aCCodeGenerator [
	"prevInterruptCheckChain lives in sqGdbARMPlugin.c"
	super declareCVarsIn: aCCodeGenerator.
	aCCodeGenerator removeVariable: 'prevInterruptCheckChain'
]

{ #category : #translation }
GdbARMPlugin class >> hasHeaderFile [
	"We need a header to declare newcpu and pull in bochs.h & cpu.h"
	^true
]

{ #category : #interruption }
GdbARMPlugin >> forceStopOnInterrupt [
	<returnTypeC: #void>
	interpreterProxy getInterruptPending ifTrue:
		[self forceStopRunning]
]

{ #category : #primitives }
GdbARMPlugin >> primitiveDisassembleAt: address "<Integer>" InMemory: memory [ "<Bitmap|ByteArray|WordArray>"
	"Return an Array of the instruction length and its decompilation as a string for the instruction at address in memory."
	| cpuAlien cpu instrLenOrErr resultObj log logLen logObj logObjData |
	<var: #cpu type: #'void *'>
	cpuAlien := self primitive: #primitiveDisassembleAtInMemory
					parameters: #(Unsigned WordsOrBytes)
					receiver: #Oop.
	(cpu := self startOfData: cpuAlien) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	instrLenOrErr := self disassembleFor: cpu
						At: address
						In: memory
						Size: (interpreterProxy byteSizeOf: memory cPtrAsOop).
	instrLenOrErr < 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrInappropriate].
	log := self getlog: (self cCode: [self addressOf: logLen] inSmalltalk: [logLen := 0]).
	resultObj := interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: 2.
	resultObj = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoMemory].

	"Easier keeping the damn thing on the stack than using pushRemappableOop:/popRemappableOop.
	 Where is topRemappableOop when you need it?"
	interpreterProxy pushRemappableOop: resultObj.
	logObj := interpreterProxy
				instantiateClass: interpreterProxy classString
				indexableSize: logLen.
	interpreterProxy failed ifTrue:
		[interpreterProxy popRemappableOop.
		 ^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	logObjData := interpreterProxy arrayValueOf: logObj.
	self mem: logObjData cp: log y: logLen.
	resultObj := interpreterProxy popRemappableOop.
	interpreterProxy
		storePointer: 0
		ofObject: resultObj
		withValue: (interpreterProxy integerObjectOf: instrLenOrErr).
	interpreterProxy storePointer: 1 ofObject: resultObj withValue: logObj.

	^resultObj
]

{ #category : #primitives }
GdbARMPlugin >> primitiveErrorAndLog [
	| log logLen resultObj logObj logObjData |
	<var: #log type: #'char *'>
	<var: #logObjData type: #'char *'>
	self primitive: #primitiveErrorAndLog parameters: #().

	log := self getlog: (self cCode: [self addressOf: logLen] inSmalltalk: [logLen := 0]).
	resultObj := interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: 2.
	resultObj = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoMemory].

	interpreterProxy
		storePointer: 0
		ofObject: resultObj
		withValue: (interpreterProxy integerObjectOf: self errorAcorn).

	logLen > 0 ifTrue:
		[interpreterProxy pushRemappableOop: resultObj.
		logObj := interpreterProxy
					instantiateClass: interpreterProxy classString
					indexableSize: logLen.
		interpreterProxy failed ifTrue:
			[interpreterProxy popRemappableOop.
			 ^interpreterProxy primitiveFailFor: PrimErrNoMemory].

		resultObj := interpreterProxy popRemappableOop.
		logObjData := interpreterProxy arrayValueOf: logObj.
		self mem: logObjData cp: log y: logLen.
		interpreterProxy storePointer: 1 ofObject: resultObj withValue: logObj].
	interpreterProxy pop: 1 thenPush: resultObj
]

{ #category : #primitives }
GdbARMPlugin >> primitiveFlushICacheFrom: startAddress "<Integer>" To: endAddress [ "<Integer>"
	"Flush the icache in the requested range"
	| cpuAlien cpu |
	<var: #cpu type: 'void *'>
	cpuAlien := self primitive: #primitiveFlushICacheFromTo
					parameters: #(Unsigned Unsigned)
					receiver: #Oop.
	(cpu := self startOfData: cpuAlien) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	self flushICache: cpu From: startAddress To: endAddress
]

{ #category : #primitives }
GdbARMPlugin >> primitiveNewCPU [
	| cpu |
	<var: #cpu type: 'void *'>
	self primitive: #primitiveNewCPU parameters: #().

	cpu := self cCode: 'newCPU()' inSmalltalk: [0].
	cpu = 0 ifTrue:
		[^interpreterProxy primitiveFail].
	interpreterProxy
		pop: 1
		thenPush: (interpreterProxy positiveMachineIntegerFor:
										(self cCoerceSimple: cpu
											to: 'usqIntptr_t'))
]

{ #category : #primitives }
GdbARMPlugin >> primitiveResetCPU [
	| cpuAlien cpu maybeErr |
	<var: #cpu type: 'void *'>
	cpuAlien := self primitive: #primitiveResetCPU parameters: #() receiver: #Oop.
	(cpu := self startOfData: cpuAlien) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	maybeErr := self resetCPU: cpu.
	maybeErr ~= 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrInappropriate].
	^cpuAlien
]

{ #category : #primitives }
GdbARMPlugin >> primitiveRunInMemory: memory "<Bitmap|ByteArray|WordArray>" minimumAddress: minAddress "<Integer>" maximumAddress: maxAddress "<Integer>" readOnlyBelow: minWriteMaxExecAddress [ "<Integer>"
	"Run the cpu using the first argument as the memory and the following arguments defining valid addresses, running until it halts or hits an exception."
	| cpuAlien cpu memorySize maybeErr |
	<var: #cpu type: #'void *'>
	cpuAlien := self primitive: #primitiveRunInMemoryMinAddressMaxAddressReadWrite
					parameters: #(WordsOrBytes Unsigned Unsigned Unsigned)
					receiver: #Oop.
	(cpu := self startOfData: cpuAlien) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	prevInterruptCheckChain := interpreterProxy setInterruptCheckChain: #forceStopOnInterrupt asSymbol.
	prevInterruptCheckChain = #forceStopOnInterrupt asSymbol ifTrue:
		[prevInterruptCheckChain = 0].
	memorySize := interpreterProxy byteSizeOf: memory cPtrAsOop.
	maybeErr := self runCPU: cpu
					In: memory
					Size: (memorySize min: maxAddress)
					MinAddressRead: minAddress
					Write: minWriteMaxExecAddress.
	interpreterProxy setInterruptCheckChain: prevInterruptCheckChain.
	maybeErr ~= 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrInappropriate].
	^cpuAlien
]

{ #category : #primitives }
GdbARMPlugin >> primitiveRunInMemory: memory "<Bitmap|ByteArray|WordArray>" minimumAddress: minAddress "<Integer>" readOnlyBelow: minWriteMaxExecAddress [ "<Integer>"
	"Run the cpu using the first argument as the memory and the following arguments defining valid addresses, running until it halts or hits an exception.
	Note that minWriteMaxExecAddress is both the minimum writeable address AND the maximum executable address"
	| cpuAlien cpu maybeErr |
	<var: #cpu type: #'void *'>
	cpuAlien := self primitive: #primitiveRunInMemoryMinimumAddressReadWrite
					parameters: #(WordsOrBytes Unsigned Unsigned)
					receiver: #Oop.
	(cpu := self startOfData: cpuAlien) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	prevInterruptCheckChain := interpreterProxy setInterruptCheckChain: #forceStopOnInterrupt asSymbol.
	prevInterruptCheckChain = #forceStopOnInterrupt asSymbol ifTrue:
		[prevInterruptCheckChain = 0].
	maybeErr := self runCPU: cpu
					In: memory
					Size: (interpreterProxy byteSizeOf: memory cPtrAsOop)
					MinAddressRead: minAddress
					Write: minWriteMaxExecAddress.
	interpreterProxy setInterruptCheckChain: prevInterruptCheckChain.
	maybeErr ~= 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrInappropriate].
	^cpuAlien
]

{ #category : #primitives }
GdbARMPlugin >> primitiveSingleStepInMemory: memory "<Bitmap|ByteArray|WordArray>" minimumAddress: minAddress "<Integer>" maximumAddress: maxAddress "<Integer>" readOnlyBelow: minWriteMaxExecAddress [ "<Integer>"
	"Single-step the cpu using the first argument as the memory and the following arguments defining valid addresses, running until it halts or hits an exception."
	| cpuAlien cpu memorySize maybeErr |
	<var: #cpu type: #'void *'>
	cpuAlien := self primitive: #primitiveSingleStepInMemoryMinAddressMaxAddressReadWrite
					parameters: #(WordsOrBytes Unsigned Unsigned Unsigned)
					receiver: #Oop.
	(cpu := self startOfData: cpuAlien) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	prevInterruptCheckChain := interpreterProxy setInterruptCheckChain: #forceStopOnInterrupt asSymbol.
	prevInterruptCheckChain = #forceStopOnInterrupt asSymbol ifTrue:
		[prevInterruptCheckChain = 0].
	memorySize := interpreterProxy byteSizeOf: memory cPtrAsOop.
	maybeErr := self singleStepCPU: cpu
					In: memory
					Size: (memorySize min: maxAddress)
					MinAddressRead: minAddress
					Write: minWriteMaxExecAddress.
	interpreterProxy setInterruptCheckChain: prevInterruptCheckChain.
	maybeErr ~= 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrInappropriate].
	^cpuAlien
]

{ #category : #primitives }
GdbARMPlugin >> primitiveSingleStepInMemory: memory "<Bitmap|ByteArray|WordArray>" minimumAddress: minAddress "<Integer>"  readOnlyBelow: minWriteMaxExecAddress [ "<Integer>"
	"Single-step the cpu using the first argument as the memory and the following arguments defining valid addresses."
	| cpuAlien cpu maybeErr |
	<var: #cpu type: #'void *'>
	cpuAlien := self primitive: #primitiveSingleStepInMemoryMinimumAddressReadWrite
					parameters: #(WordsOrBytes Unsigned Unsigned)
					receiver: #Oop.
	(cpu := self startOfData: cpuAlien) = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadReceiver].
	maybeErr := self singleStepCPU: cpu
					In: memory
					Size: (interpreterProxy byteSizeOf: memory cPtrAsOop)
					MinAddressRead: minAddress
					Write: minWriteMaxExecAddress.
	maybeErr ~= 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrInappropriate].
	^cpuAlien
]

{ #category : #'alien support' }
GdbARMPlugin >> sizeField: rcvr [
	"Answer the first field of rcvr which is assumed to be an Alien of at least 8 bytes"
	<inline: true>
	^self longAt: rcvr + interpreterProxy baseHeaderSize
]

{ #category : #'alien support' }
GdbARMPlugin >> startOfData: rcvr [ "<Alien oop> ^<Integer>"
	"Answer the start of rcvr's data.  For direct aliens this is the address of
	 the second field.  For indirect and pointer aliens it is what the second field points to."
	<inline: true>
	^(self sizeField: rcvr) > 0
	 	ifTrue: [rcvr + interpreterProxy baseHeaderSize + interpreterProxy bytesPerOop]
		ifFalse: [self longAt: rcvr + interpreterProxy baseHeaderSize + interpreterProxy bytesPerOop]
]
