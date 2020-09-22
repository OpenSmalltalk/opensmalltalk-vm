Class {
	#name : #UnicornARMv8Simulator,
	#superclass : #UnicornSimulator,
	#category : #'VMMakerTests-Unicorn'
}

{ #category : #registers }
UnicornARMv8Simulator >> arg0Register [
	
	^ UcARM64Registers x3
]

{ #category : #registers }
UnicornARMv8Simulator >> baseRegister [

	^ UcARM64Registers x10
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> carry [

	^ (self nzcv bitAnd: (1<<29))~= 0
]

{ #category : #registers }
UnicornARMv8Simulator >> classRegister [
	
	^ UcARM64Registers x2
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> createUnicorn [

	^ Unicorn arm64
]

{ #category : #disassembling }
UnicornARMv8Simulator >> disassembler [
	
	^ LLVMDisassembler aarch64
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> extractDestinationRegisterFromAssembly: aLLVMInstruction [ 
	
	"In ARM, instructions are usually encoded asSpotterCandidateLink 
	
	INST Destination, Source
	"
	
	^ (aLLVMInstruction assemblyCodeString substrings: String tab, ',') second trimBoth.
]

{ #category : #registers }
UnicornARMv8Simulator >> fp [
	^ self readRegister: UcARM64Registers x29
]

{ #category : #registers }
UnicornARMv8Simulator >> framePointerRegister [
	
	^ UcARM64Registers fp
]

{ #category : #accessing }
UnicornARMv8Simulator >> getLastAddress: abstractInstructions [ 
	
	| last |
	last := (abstractInstructions reject: [ :e | e isLiteral ]) last.
	^ last address + last machineCodeSize 
]

{ #category : #accessing }
UnicornARMv8Simulator >> getReturnAddress [
	
	^ self linkRegisterValue
]

{ #category : #testing }
UnicornARMv8Simulator >> hasLinkRegister [
	^ true
]

{ #category : #initialization }
UnicornARMv8Simulator >> initializeRegisterAliases [

	registerAliases
		at: #x2 put: #classRegister;
		at: #x5 put: #receiverRegister;
		at: #x6 put: #sendNumberOfArgumentsRegister;
		at: #x10 put: #baseRegister;
		at: #x28 put: #vmStackPointer;
		at: #x29 put: #framePointerRegister;
		at: #x30 put: #linkRegister
]

{ #category : #registers }
UnicornARMv8Simulator >> instructionPointerRegister [

	^ UcARM64Registers pc
]

{ #category : #registers }
UnicornARMv8Simulator >> linkRegister [
	
	^ UcARM64Registers x30
]

{ #category : #accessing }
UnicornARMv8Simulator >> linkRegisterValue [

	^ self readRegister: self linkRegister 
]

{ #category : #registers }
UnicornARMv8Simulator >> linkRegisterValue: aValue [ 

	^ self writeRegister: self linkRegister value: aValue
]

{ #category : #registers }
UnicornARMv8Simulator >> lr [
	^ self readRegister: self linkRegister
]

{ #category : #registers }
UnicornARMv8Simulator >> lr: aValue [
	^ self writeRegister: self linkRegister value: aValue
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> negative [

	^ (self nzcv bitAnd: (1<<31))~= 0
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> nzcv [

	^ self readRegister: UcARM64Registers nzcv 
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> overflow [

	^ (self nzcv bitAnd: (1<<28)) ~= 0
]

{ #category : #registers }
UnicornARMv8Simulator >> pc [
	^ self readRegister: self instructionPointerRegister
]

{ #category : #registers }
UnicornARMv8Simulator >> pc: aValue [
	^ self writeRegister: self instructionPointerRegister value: aValue
]

{ #category : #registers }
UnicornARMv8Simulator >> receiverRegister [
	
	^ UcARM64Registers x5
]

{ #category : #accessing }
UnicornARMv8Simulator >> registerList [

	^ #(lr pc sp fp x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x28 zero negative carry overflow)
]

{ #category : #registers }
UnicornARMv8Simulator >> sendNumberOfArgumentsRegister [
	
	^ UcARM64Registers x6
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> simulateLeafCallOf: address nextpc: nextpc memory: aMemory [
	
	self lr: nextpc.
	self pc: address
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> smashRegisterAccessors [
	
	^#( x1: x2: x3: x4: x5: x6: x7: x8: x9: x10: x11: x12: )
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> smashRegistersWithValuesFrom: base by: step [ 
	
	self smashRegisterAccessors withIndexDo: [:accessor :index|
		self perform: accessor with: index - 1 * step + base]
]

{ #category : #registers }
UnicornARMv8Simulator >> sp [
	^ self readRegister: UcARM64Registers sp
]

{ #category : #registers }
UnicornARMv8Simulator >> stackPointerRegister [
	
	^ UcARM64Registers x28
]

{ #category : #accessing }
UnicornARMv8Simulator >> wordSize [
	^ 8
]

{ #category : #accessing }
UnicornARMv8Simulator >> x0 [

	^ self readRegister: UcARM64Registers x0
]

{ #category : #accessing }
UnicornARMv8Simulator >> x1 [

	^ self readRegister: UcARM64Registers x1
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> x10 [

	^ self readRegister: UcARM64Registers x10
]

{ #category : #registers }
UnicornARMv8Simulator >> x10: anInteger [ 

	^ self writeRegister: UcARM64Registers x10 value: anInteger
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> x11 [

	^ self readRegister: UcARM64Registers x11
]

{ #category : #registers }
UnicornARMv8Simulator >> x11: anInteger [ 

	^ self writeRegister: UcARM64Registers x11 value: anInteger
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> x12 [

	^ self readRegister: UcARM64Registers x12
]

{ #category : #registers }
UnicornARMv8Simulator >> x12: anInteger [ 

	^ self writeRegister: UcARM64Registers x12 value: anInteger
]

{ #category : #registers }
UnicornARMv8Simulator >> x1: anInteger [ 

	^ self writeRegister: UcARM64Registers x1 value: anInteger
]

{ #category : #accessing }
UnicornARMv8Simulator >> x2 [

	^ self readRegister: UcARM64Registers x2
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> x28 [

	^ self readRegister: UcARM64Registers x28
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> x28: anInteger [ 
	
	self writeRegister: UcARM64Registers x28 value: anInteger
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> x29: anInteger [ 
	
	^ self writeRegister: UcARM64Registers x29 value: anInteger
]

{ #category : #registers }
UnicornARMv8Simulator >> x2: anInteger [ 

	^ self writeRegister: UcARM64Registers x2 value: anInteger
]

{ #category : #accessing }
UnicornARMv8Simulator >> x3 [

	^ self readRegister: UcARM64Registers x3
]

{ #category : #registers }
UnicornARMv8Simulator >> x3: anInteger [ 

	^ self writeRegister: UcARM64Registers x3 value: anInteger
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> x4 [

	^ self readRegister: UcARM64Registers x4
]

{ #category : #registers }
UnicornARMv8Simulator >> x4: anInteger [ 

	^ self writeRegister: UcARM64Registers x4 value: anInteger
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> x5 [

	^ self readRegister: UcARM64Registers x5
]

{ #category : #registers }
UnicornARMv8Simulator >> x5: anInteger [ 

	^ self writeRegister: UcARM64Registers x5 value: anInteger
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> x6 [

	^ self readRegister: UcARM64Registers x6
]

{ #category : #registers }
UnicornARMv8Simulator >> x6: anInteger [ 

	^ self writeRegister: UcARM64Registers x6 value: anInteger
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> x7 [

	^ self readRegister: UcARM64Registers x7
]

{ #category : #registers }
UnicornARMv8Simulator >> x7: anInteger [ 

	^ self writeRegister: UcARM64Registers x7 value: anInteger
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> x8 [

	^ self readRegister: UcARM64Registers x8
]

{ #category : #registers }
UnicornARMv8Simulator >> x8: anInteger [ 

	^ self writeRegister: UcARM64Registers x8 value: anInteger
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> x9 [

	^ self readRegister: UcARM64Registers x9
]

{ #category : #registers }
UnicornARMv8Simulator >> x9: anInteger [ 

	^ self writeRegister: UcARM64Registers x9 value: anInteger
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> xzr [
	
	^ self readRegister: UcARM64Registers xzr
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> xzr: anInteger [ 

	^ self writeRegister: UcARM64Registers xzr value: anInteger
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> zero [

	^ (self nzcv bitAnd: (1<<30))~= 0
]
