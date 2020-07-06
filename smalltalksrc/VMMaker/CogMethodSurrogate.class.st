Class {
	#name : #CogMethodSurrogate,
	#superclass : #VMClass,
	#instVars : [
		'address',
		'memory',
		'baseHeaderSize',
		'cogit'
	],
	#pools : [
		'CogMethodConstants',
		'VMBytecodeConstants'
	],
	#category : #'VMMaker-JITSimulation'
}

{ #category : #accessing }
CogMethodSurrogate class >> alignedByteSizeOf: anObject forClient: aVMClass [
	^self alignedByteSize
]

{ #category : #accessing }
CogMethodSurrogate class >> baseHeaderSize [
	^self objectMemoryClass baseHeaderSize
]

{ #category : #arithmetic }
CogMethodSurrogate >> + anInteger [
	"N.B. Mimic C semantics so that aCogMethod + 1 is a pointer to the byte past the CogMethod header."
	^address + (anInteger * self class alignedByteSize)
]

{ #category : #comparing }
CogMethodSurrogate >> < aCogMethodOrAddress [
	^address < aCogMethodOrAddress asInteger
]

{ #category : #comparing }
CogMethodSurrogate >> <= aCogMethodOrAddress [
	^address <= aCogMethodOrAddress asInteger
]

{ #category : #comparing }
CogMethodSurrogate >> = aCogMethodOrAddressOrNil [
	^address = (aCogMethodOrAddressOrNil
					ifNil: [0]
					ifNotNil: [aCogMethodOrAddressOrNil asInteger])
]

{ #category : #comparing }
CogMethodSurrogate >> > aCogMethodOrAddress [
	^address > aCogMethodOrAddress asInteger
]

{ #category : #comparing }
CogMethodSurrogate >> >= aCogMethodOrAddress [
	^address >= aCogMethodOrAddress asInteger
]

{ #category : #arithmetic }
CogMethodSurrogate >> adaptToInteger: rcvr andSend: selector [
	"If no method has been provided for adapting an object to a Integer,
	then it may be adequate to simply adapt it to a number."
	^rcvr perform: selector with: address
]

{ #category : #accessing }
CogMethodSurrogate >> address [
	^address
]

{ #category : #accessing }
CogMethodSurrogate >> asInteger [
	"Answer the surrogate's adress. This is equivalent to a C cast to sqInt,
	 which is precisely what Slang generates for asInteger"
	^address
]

{ #category : #accessing }
CogMethodSurrogate >> asIntegerPtr [
	"Answer the surrogate's adress. This is equivalent to a C cast to usqIntptr_t,
	 which is precisely what Slang generates for asIntegerPtr"
	^address
]

{ #category : #accessing }
CogMethodSurrogate >> asUnsignedInteger [
	"Answer the surrogate's adress. This is equivalent to a C cast to usqInt,
	 which is precisely what Slang generates for asUnsignedInteger"
	^address
]

{ #category : #accessing }
CogMethodSurrogate >> asUnsignedIntegerPtr [
	"Answer the surrogate's adress. This is equivalent to a C cast to usqIntptr_t,
	 which is precisely what Slang generates for asUnsignedIntegerPtr"
	^address
]

{ #category : #coercing }
CogMethodSurrogate >> asVoidPointer [
	^self
]

{ #category : #'instance initialization' }
CogMethodSurrogate >> at: anAddress memory: memoryArray headerSize: headerSize cogit: aCogit [
	address := anAddress.
	memory := memoryArray.
	baseHeaderSize := headerSize.
	cogit := aCogit
]

{ #category : #'instance initialization' }
CogMethodSurrogate >> at: anAddress objectMemory: objectMemory cogit: aCogit [
	address := anAddress.
	memory := objectMemory memory.
	baseHeaderSize := objectMemory baseHeaderSize.
	cogit := aCogit
]

{ #category : #accessing }
CogMethodSurrogate >> cPICNumCases [
	^self stackCheckOffset
]

{ #category : #accessing }
CogMethodSurrogate >> cPICNumCases: n [
	^self stackCheckOffset: n
]

{ #category : #accessing }
CogMethodSurrogate >> cmHomeMethod [
	^cogit cogMethodSurrogateAt: ((SistaV1BytecodeSet and: [self cmIsFullBlock])
										ifTrue: [address]
										ifFalse: [address - self homeOffset])
]

{ #category : #accessing }
CogMethodSurrogate >> cmIsFullBlock [
	"Answer the value of cpicHasMNUCaseOrCMIsFullBlock"

	^SistaV1BytecodeSet
		ifTrue: [self cpicHasMNUCaseOrCMIsFullBlock]
		ifFalse: [false]
]

{ #category : #testing }
CogMethodSurrogate >> containsAddress: anAddress [
	^address <= anAddress asUnsignedInteger
	  and: [address + self blockSize >= anAddress asUnsignedInteger]
]

{ #category : #accessing }
CogMethodSurrogate >> cpicHasMNUCase [
	"Answer if the receiver has an MNU case."
	<inline: true>

	^SistaV1BytecodeSet
		ifTrue: [self cpicHasMNUCaseOrCMIsFullBlock and: [self cmType = CMClosedPIC]]
		ifFalse: [self cpicHasMNUCaseOrCMIsFullBlock]
]

{ #category : #accessing }
CogMethodSurrogate >> cpicHasMNUCase: anObject [
	"Set if the receiver has an MNU case."

	^self cpicHasMNUCaseOrCMIsFullBlock: anObject
]

{ #category : #testing }
CogMethodSurrogate >> isVMSimulationAddress [
	"Answer a boolean indicating whether the receiver is a kind of address in the VM simulation"

	^true
]

{ #category : #comparing }
CogMethodSurrogate >> isZero [
	^address = 0
]

{ #category : #accessing }
CogMethodSurrogate >> nextOpenPIC [
	| moField |
	moField := self methodObject.
	^moField ~= 0 ifTrue:
		[cogit cogMethodSurrogateAt: moField]
]

{ #category : #accessing }
CogMethodSurrogate >> nextOpenPIC: cogMethodSurrogateOrNil [
	^self methodObject: (cogMethodSurrogateOrNil ifNil: [0] ifNotNil: [cogMethodSurrogateOrNil asUnsignedInteger])
]

{ #category : #accessing }
CogMethodSurrogate >> objectHeader [
	^baseHeaderSize = 8
		ifTrue: [memory long64At: address + 1]
		ifFalse: [memory longAt: address + 1]
]

{ #category : #accessing }
CogMethodSurrogate >> objectHeader: aValue [
	^baseHeaderSize = 8
		ifTrue: [memory long64At: address + 1 put: aValue]
		ifFalse: [memory longAt: address + 1 put: aValue]
]

{ #category : #printing }
CogMethodSurrogate >> printOn: aStream [
	super printOn: aStream.
	aStream nextPutAll: ' @'; print: address; nextPut: $/; nextPutAll: address hex
]
