Class {
	#name : #BochsX64Alien,
	#superclass : #CogProcessorAlien,
	#type : #bytes,
	#classVars : [
		'ExtendedOpcodeExceptionMap',
		'OpcodeExceptionMap',
		'PostBuildStackDelta'
	],
	#category : #'Cog-Processors'
}

{ #category : #'instance creation' }
BochsX64Alien class >> dataSize [
	^22672
]

{ #category : #'Cog API' }
BochsX64Alien >> abstractInstructionCompilerClass [
	^CogX64Compiler
]

{ #category : #'Cog API' }
BochsX64Alien >> bitsInWord [
	^64
]

{ #category : #accessing }
BochsX64Alien >> cr0 [
	^self unsignedLongLongAt: 1225
]

{ #category : #accessing }
BochsX64Alien >> cr0: anUnsignedInteger [
	^self unsignedLongLongAt: 1225 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> cr1 [
	^self unsignedLongLongAt: 1229
]

{ #category : #accessing }
BochsX64Alien >> cr1: anUnsignedInteger [
	^self unsignedLongLongAt: 1229 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> cr2 [
	^self unsignedLongLongAt: 1233
]

{ #category : #accessing }
BochsX64Alien >> cr2: anUnsignedInteger [
	^self unsignedLongLongAt: 1233 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> cr3 [
	^self unsignedLongLongAt: 1241
]

{ #category : #accessing }
BochsX64Alien >> cr3: anUnsignedInteger [
	^self unsignedLongLongAt: 1241 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> cr4 [
	^self unsignedLongLongAt: 1253
]

{ #category : #accessing }
BochsX64Alien >> cr4: anUnsignedInteger [
	^self unsignedLongLongAt: 1253 put: anUnsignedInteger
]

{ #category : #primitives }
BochsX64Alien >> primitiveDisassembleAt: address inMemory: memoryArray [ "<Bitmap|ByteArray>"
	"Answer an Array of the size and the disassembled code string for the instruction at the current instruction pointer in memory."
	<primitive: 'primitiveDisassembleAtInMemory' module: 'BochsX64Plugin'>
	^self primitiveFailed
]

{ #category : #primitives }
BochsX64Alien >> primitiveErrorAndLog [
	"Answer an array of the current error code and log contents"
	<primitive: 'primitiveErrorAndLog' module: 'BochsX64Plugin'>
	^self primitiveFailed
]

{ #category : #primitives }
BochsX64Alien >> primitiveFlushICacheFrom: startAddress "<Integer>" To: endAddress [ "<Integer>"
	"Flush the icache in the requested range"
	<primitive: 'primitiveFlushICacheFromTo' module: 'BochsX64Plugin'>
	^self primitiveFailed
]

{ #category : #primitives }
BochsX64Alien >> primitiveResetCPU [
	"Reset the receiver to registers all zero, and protected 32-bit mode."
	<primitive: 'primitiveResetCPU' module: 'BochsX64Plugin'>
	^self reportPrimitiveFailure
]

{ #category : #primitives }
BochsX64Alien >> primitiveRunInMemory: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress "<Integer>" readOnlyBelow: minimumWritableAddress [ "<Integer>"
	"Run the receiver using the argument as the store.  Origin the argument at 0. i.e. the first byte of the
	 memoryArray is address 0.  Make addresses below minimumAddress illegal.  Convert out-of-range
	 calls, jumps and memory read/writes into ProcessorSimulationTrap signals."
	<primitive: 'primitiveRunInMemoryMinimumAddressReadWrite' module: 'BochsX64Plugin' error: ec>
	^ec == #'inappropriate operation'
		ifTrue: [self handleExecutionPrimitiveFailureIn: memoryArray
					minimumAddress: minimumAddress]
		ifFalse: [self reportPrimitiveFailure]

	"self printRegistersOn: Transcript"
]

{ #category : #primitives }
BochsX64Alien >> primitiveSingleStepInMemory: memoryArray "<Bitmap|ByteArray>" minimumAddress: minimumAddress "<Integer>" readOnlyBelow: minimumWritableAddress [ "<Integer>"
	"Single-step the receiver using the argument as the store.  Origin the argument at 0. i.e. the first byte of the
	 memoryArray is address 0.  Make addresses below minimumAddress illegal.  Convert out-of-range
	 calls, jumps and memory read/writes into ProcessorSimulationTrap signals."
	<primitive: 'primitiveSingleStepInMemoryMinimumAddressReadWrite' module: 'BochsX64Plugin' error: ec>
	^ec == #'inappropriate operation'
		ifTrue: [self handleExecutionPrimitiveFailureIn: memoryArray
					minimumAddress: minimumAddress]
		ifFalse: [self reportPrimitiveFailure]
]

{ #category : #accessing }
BochsX64Alien >> r10 [
	^self unsignedLongLongAt: 549
]

{ #category : #accessing }
BochsX64Alien >> r10: anUnsignedInteger [
	^self unsignedLongLongAt: 549 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> r11 [
	^self unsignedLongLongAt: 557
]

{ #category : #accessing }
BochsX64Alien >> r11: anUnsignedInteger [
	^self unsignedLongLongAt: 557 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> r12 [
	^self unsignedLongLongAt: 565
]

{ #category : #accessing }
BochsX64Alien >> r12: anUnsignedInteger [
	^self unsignedLongLongAt: 565 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> r13 [
	^self unsignedLongLongAt: 573
]

{ #category : #accessing }
BochsX64Alien >> r13: anUnsignedInteger [
	^self unsignedLongLongAt: 573 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> r14 [
	^self unsignedLongLongAt: 581
]

{ #category : #accessing }
BochsX64Alien >> r14: anUnsignedInteger [
	^self unsignedLongLongAt: 581 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> r15 [
	^self unsignedLongLongAt: 589
]

{ #category : #accessing }
BochsX64Alien >> r15: anUnsignedInteger [
	^self unsignedLongLongAt: 589 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> r8 [
	^self unsignedLongLongAt: 533
]

{ #category : #accessing }
BochsX64Alien >> r8: anUnsignedInteger [
	^self unsignedLongLongAt: 533 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> r9 [
	^self unsignedLongLongAt: 541
]

{ #category : #accessing }
BochsX64Alien >> r9: anUnsignedInteger [
	^self unsignedLongLongAt: 541 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rax [
	^self unsignedLongLongAt: 469
]

{ #category : #accessing }
BochsX64Alien >> rax: anUnsignedInteger [
	^self unsignedLongLongAt: 469 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rbp [
	^self unsignedLongLongAt: 509
]

{ #category : #accessing }
BochsX64Alien >> rbp: anUnsignedInteger [
	^self unsignedLongLongAt: 509 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rbx [
	^self unsignedLongLongAt: 493
]

{ #category : #accessing }
BochsX64Alien >> rbx: anUnsignedInteger [
	^self unsignedLongLongAt: 493 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rcx [
	^self unsignedLongLongAt: 477
]

{ #category : #accessing }
BochsX64Alien >> rcx: anUnsignedInteger [
	^self unsignedLongLongAt: 477 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rdi [
	^self unsignedLongLongAt: 525
]

{ #category : #accessing }
BochsX64Alien >> rdi: anUnsignedInteger [
	^self unsignedLongLongAt: 525 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rdx [
	^self unsignedLongLongAt: 485
]

{ #category : #accessing }
BochsX64Alien >> rdx: anUnsignedInteger [
	^self unsignedLongLongAt: 485 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rflags [
	^self unsignedLongLongAt: 621
]

{ #category : #accessing }
BochsX64Alien >> rip [
	^self unsignedLongLongAt: 597
]

{ #category : #accessing }
BochsX64Alien >> rip: anUnsignedInteger [
	^self unsignedLongLongAt: 597 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rsi [
	^self unsignedLongLongAt: 517
]

{ #category : #accessing }
BochsX64Alien >> rsi: anUnsignedInteger [
	^self unsignedLongLongAt: 517 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> rsp [
	^self unsignedLongLongAt: 501
]

{ #category : #accessing }
BochsX64Alien >> rsp: anUnsignedInteger [
	^self unsignedLongLongAt: 501 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> saveRip [
	^self unsignedLongAt: 1913
]

{ #category : #accessing }
BochsX64Alien >> saveRip: anUnsignedInteger [
	^self unsignedLongAt: 1913 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> saveRsp [
	^self unsignedLongAt: 1921
]

{ #category : #accessing }
BochsX64Alien >> saveRsp: anUnsignedInteger [
	^self unsignedLongAt: 1921 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> stopReason [
	^self unsignedByteAt: 1973
]

{ #category : #accessing }
BochsX64Alien >> stopReason: anUnsignedInteger [
	^self unsignedByteAt: 1973 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm0high [
	^self unsignedLongLongAt: 1421
]

{ #category : #accessing }
BochsX64Alien >> xmm0high: anUnsignedInteger [
	^self unsignedLongLongAt: 1421 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm0low [
	^self unsignedLongLongAt: 1413
]

{ #category : #accessing }
BochsX64Alien >> xmm0low: anUnsignedInteger [
	^self unsignedLongLongAt: 1413 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm1high [
	^self unsignedLongLongAt: 1437
]

{ #category : #accessing }
BochsX64Alien >> xmm1high: anUnsignedInteger [
	^self unsignedLongLongAt: 1437 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm1low [
	^self unsignedLongLongAt: 1429
]

{ #category : #accessing }
BochsX64Alien >> xmm1low: anUnsignedInteger [
	^self unsignedLongLongAt: 1429 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm2high [
	^self unsignedLongLongAt: 1453
]

{ #category : #accessing }
BochsX64Alien >> xmm2high: anUnsignedInteger [
	^self unsignedLongLongAt: 1453 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm2low [
	^self unsignedLongLongAt: 1445
]

{ #category : #accessing }
BochsX64Alien >> xmm2low: anUnsignedInteger [
	^self unsignedLongLongAt: 1445 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm3high [
	^self unsignedLongLongAt: 1469
]

{ #category : #accessing }
BochsX64Alien >> xmm3high: anUnsignedInteger [
	^self unsignedLongLongAt: 1469 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm3low [
	^self unsignedLongLongAt: 1461
]

{ #category : #accessing }
BochsX64Alien >> xmm3low: anUnsignedInteger [
	^self unsignedLongLongAt: 1461 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm4high [
	^self unsignedLongLongAt: 1485
]

{ #category : #accessing }
BochsX64Alien >> xmm4high: anUnsignedInteger [
	^self unsignedLongLongAt: 1485 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm4low [
	^self unsignedLongLongAt: 1477
]

{ #category : #accessing }
BochsX64Alien >> xmm4low: anUnsignedInteger [
	^self unsignedLongLongAt: 1477 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm5high [
	^self unsignedLongLongAt: 1501
]

{ #category : #accessing }
BochsX64Alien >> xmm5high: anUnsignedInteger [
	^self unsignedLongLongAt: 1501 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm5low [
	^self unsignedLongLongAt: 1493
]

{ #category : #accessing }
BochsX64Alien >> xmm5low: anUnsignedInteger [
	^self unsignedLongLongAt: 1493 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm6high [
	^self unsignedLongLongAt: 1517
]

{ #category : #accessing }
BochsX64Alien >> xmm6high: anUnsignedInteger [
	^self unsignedLongLongAt: 1517 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm6low [
	^self unsignedLongLongAt: 1509
]

{ #category : #accessing }
BochsX64Alien >> xmm6low: anUnsignedInteger [
	^self unsignedLongLongAt: 1509 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm7high [
	^self unsignedLongLongAt: 1533
]

{ #category : #accessing }
BochsX64Alien >> xmm7high: anUnsignedInteger [
	^self unsignedLongLongAt: 1533 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien >> xmm7low [
	^self unsignedLongLongAt: 1525
]

{ #category : #accessing }
BochsX64Alien >> xmm7low: anUnsignedInteger [
	^self unsignedLongLongAt: 1525 put: anUnsignedInteger
]
