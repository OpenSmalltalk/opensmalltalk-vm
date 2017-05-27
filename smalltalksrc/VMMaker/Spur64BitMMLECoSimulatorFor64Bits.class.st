Class {
	#name : #Spur64BitMMLECoSimulatorFor64Bits,
	#superclass : #Spur64BitMMLECoSimulator,
	#category : 'VMMaker-SpurMemoryManagerSimulation'
}

{ #category : #'memory access' }
Spur64BitMMLECoSimulatorFor64Bits >> byteAt: byteAddress [
	| lowBits long64 |
	lowBits := byteAddress bitAnd: 7.
	long64 := self long64At: byteAddress - lowBits.
	^(long64 bitShift: -8 * lowBits) bitAnd: 16rFF
]

{ #category : #'memory access' }
Spur64BitMMLECoSimulatorFor64Bits >> byteAt: byteAddress put: byte [
	| lowBits long64 longAddress mask value |
	lowBits := byteAddress bitAnd: 7.
	longAddress := byteAddress - lowBits.
	long64 := self long64At: longAddress.
	mask := (16rFF bitShift: 8 * lowBits) bitInvert.
	value := byte bitShift: 8 * lowBits.
	self long64At: longAddress put: ((long64 bitAnd: mask) bitOr: value).
	^byte
]

{ #category : #'memory access' }
Spur64BitMMLECoSimulatorFor64Bits >> long32At: byteAddress [
	"Answer the 32-bit word at byteAddress which must be a multiple of four."
	| lowBits long |
	lowBits := byteAddress bitAnd: 4.
	long := self long64At: byteAddress - lowBits.
	^lowBits = 4
		ifTrue: [long bitShift: -32]
		ifFalse: [long bitAnd: 16rFFFFFFFF]
]

{ #category : #'memory access' }
Spur64BitMMLECoSimulatorFor64Bits >> long32At: byteAddress put: a32BitValue [
 	"Store the 32-bit word at byteAddress which must be a multiple of four."
	| lowBits long longAddress |
	lowBits := byteAddress bitAnd: 4.
	lowBits = 0
		ifTrue: "storing into LS word"
			[long := self long64At: byteAddress.
			 self long64At: byteAddress
				put: ((long bitAnd: 16rFFFFFFFF00000000) bitOr: a32BitValue)]
		ifFalse: "storing into MS word"
			[longAddress := byteAddress - 4.
			long := self long64At: longAddress.
			self long64At: longAddress
				put: ((long bitAnd: 16rFFFFFFFF) bitOr: (a32BitValue bitShift: 32))].
	^a32BitValue
]

{ #category : #'memory access' }
Spur64BitMMLECoSimulatorFor64Bits >> long64At: byteAddress [
	"memory is a DobleWordArray, a 64-bit indexable array of bits"
	byteAddress \\ 8 ~= 0 ifTrue: [self unalignedAccessError].
	^memory at: byteAddress // 8 + 1
]

{ #category : #'memory access' }
Spur64BitMMLECoSimulatorFor64Bits >> long64At: byteAddress put: a64BitValue [
	"memory is a DobleWordArray, a 64-bit indexable array of bits"
	byteAddress \\ 8 ~= 0 ifTrue: [self unalignedAccessError].
	^memory at: byteAddress // 8 + 1 put: a64BitValue
]

{ #category : #simulation }
Spur64BitMMLECoSimulatorFor64Bits >> memoryClass [
	"Answer the class to use for the memory inst var in simulation.
	 Answer nil if a suitable class isn't available.  This version uses a 64-bit element class if available."
	<doNotGenerate>
	^Smalltalk classNamed: #DoubleWordArray
]

{ #category : #'memory access' }
Spur64BitMMLECoSimulatorFor64Bits >> shortAt: byteAddress [
	| lowBits long64 |
	lowBits := byteAddress bitAnd: 6.
	long64 := self long64At: byteAddress - lowBits.
	^(long64 bitShift: -8 * lowBits) bitAnd: 16rFFFF
]

{ #category : #'memory access' }
Spur64BitMMLECoSimulatorFor64Bits >> shortAt: byteAddress put: short [
	| lowBits long64 longAddress mask value |
	lowBits := byteAddress bitAnd: 6.
	longAddress := byteAddress - lowBits.
	long64 := self long64At: longAddress.
	mask := (16rFFFF bitShift: 8 * lowBits) bitInvert.
	value := short bitShift: 8 * lowBits.
	self long64At: longAddress put: ((long64 bitAnd: mask) bitOr: value).
	^short
]
