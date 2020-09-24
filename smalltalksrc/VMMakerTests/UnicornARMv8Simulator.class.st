Class {
	#name : #UnicornARMv8Simulator,
	#superclass : #UnicornSimulator,
	#category : #'VMMakerTests-Unicorn'
}

{ #category : #registers }
UnicornARMv8Simulator >> arg0Register [
	
	^ UcARM64Registers x3
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> argument0RegisterValue [
	
	^ self x3
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

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> popBytes [

	| stackAddressIntegerValue aByteArray |

	"Getting address from stack register"
	stackAddressIntegerValue := self stackPointerRegisterValue.
	"Putting the value from the stack memory"
	aByteArray := self memoryAt: stackAddressIntegerValue readNext: self wordSize.
	
	"Updating SP"
	stackAddressIntegerValue := stackAddressIntegerValue + self wordSize.
	self stackPointerRegisterValue: stackAddressIntegerValue.
	
	^ aByteArray
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> postCallArgumentsNumArgs: numArgs "<Integer>" in: aMemory [ "<ByteArray|Bitmap>"
	"Answer an argument vector of the requested size after a vanilla
	 ABI call. For ARM the Procedure Calling Specification can be found in IHI0042D_aapcs.pdf.
	On ARM this typically means accessing r0 through r3 and fetching additional arguments from the stack, acording to pages 20f. aapcs.
	We assume that all arguments are single word arguments, which can not be supplied on co-processor-registers.
	 For compatibility with Cog/Slang we answer unsigned values."
	^(1 to: numArgs) collect: [:i |
		i < 5 
			ifTrue: [self perform: (self registerStateGetters at: i)]
			"ARM uses a full descending stack. Directly after calling a procedure, nothing but the arguments are pushed."
			ifFalse: [memory unsignedLongAt: self sp + (i-5)*4 bigEndian: false]].
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> pushBytes: aByteArray [ 

	| stackAddressIntegerValue |
	self assert: aByteArray size = self wordSize.

	"Getting address from stack register"
	stackAddressIntegerValue := self stackPointerRegisterValue.

	"Updating SP"
	stackAddressIntegerValue := stackAddressIntegerValue - self wordSize.
	self stackPointerRegisterValue: stackAddressIntegerValue.
	
	"Putting the value in the stack memory"
	self
		memoryAt: stackAddressIntegerValue
		write: aByteArray
		size: self wordSize

]

{ #category : #registers }
UnicornARMv8Simulator >> receiverRegister [
	
	^ UcARM64Registers x5
]

{ #category : #accessing }
UnicornARMv8Simulator >> registerList [

	^ #(lr pc sp fp x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x10 x11 x12 x28 zero negative carry overflow)
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> registerStateGetters [

	^#(	x0 x1 x2 x3 x4 x5 x6 x7 x8 x9 x12 sp lr pc)
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> retpcIn: aMemory [ 

	^ aMemory unsignedLongAt: self fp + 9 
]

{ #category : #registers }
UnicornARMv8Simulator >> sendNumberOfArgumentsRegister [
	
	^ UcARM64Registers x6
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> simulateJumpCallOf: address memory: aMemory [
	"Simulate a frame-building jump of address.  Build a frame since
	a) this is used for calls into the run-time which are unlikely to be leaf-calls"
	"This method builds a stack frame as expected by the simulator, not as defined by ARM aapcs-abi.
	In ARM aapcs, every method can define for itself, wether it wants to push lr (nextpc), and wether it 
	uses a frame pointer. The standard never mentions a fp. It merely defines r4-r11 to be callee-saved."
	
	self assert: self sp \\ 8 = 0. "This check ensures, that we conform with ARM abi. Before doing anything to the stack, we ensure 2-word alignment."

	self pushWord: self linkRegisterValue.
	self pushWord: self fp.
	self framePointerRegisterValue: self stackPointerRegisterValue.

	self instructionPointerValue: address
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> simulateLeafCallOf: address nextpc: nextpc memory: aMemory [
	
	self lr: nextpc.
	self pc: address
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> simulateReturnIn: aSpurSimulatedMemory [ 

	self framePointerRegisterValue: self popWord.
	self linkRegisterValue: self popWord.

	self instructionPointerValue: self linkRegisterValue

]

{ #category : #'calling convention' }
UnicornARMv8Simulator >> smashCallerSavedRegistersWithValuesFrom: base by: step in: aMemory [

	self smashRegistersWithValuesFrom: base by: step
]

{ #category : #'calling convention' }
UnicornARMv8Simulator >> smashRegisterAccessors [
	
	^ #(x0: x1: x2: x3: x4: x5: x6: x7: x8: x9: x10: x11: x12: x13: x14: x15: x16: x17: x18:)
]

{ #category : #'calling convention' }
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

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> w6: anInteger [ 

	self writeRegister: UcARM64Registers w6 value: anInteger
]

{ #category : #accessing }
UnicornARMv8Simulator >> wordSize [
	^ 8
]

{ #category : #accessing }
UnicornARMv8Simulator >> x0 [

	^ self readRegister: UcARM64Registers x0
]

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> x0: anInteger [ 
	
	self writeRegister: UcARM64Registers x0 value: anInteger 
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

{ #category : #'as yet unclassified' }
UnicornARMv8Simulator >> x30: anInteger [ 
	
	self writeRegister: UcARM64Registers x30 value: anInteger
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
