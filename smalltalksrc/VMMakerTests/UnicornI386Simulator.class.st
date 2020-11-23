Class {
	#name : #UnicornI386Simulator,
	#superclass : #UnicornSimulator,
	#category : #'VMMakerTests-Unicorn'
}

{ #category : #registers }
UnicornI386Simulator >> arg0Register [
	
	^ UcX86Registers esi
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> argument0RegisterValue [
	
	^ self esi
]

{ #category : #accessing }
UnicornI386Simulator >> argument0RegisterValue: anInteger [ 

	self writeRegister: UcX86Registers esi value: anInteger
]

{ #category : #registers }
UnicornI386Simulator >> baseRegister [

	^ UcX86Registers ebx
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> cResultRegister [

	^ self eax
]

{ #category : #registers }
UnicornI386Simulator >> classRegister [

	^ UcX86Registers ecx
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> createUnicorn [

	^ Unicorn x86
]

{ #category : #disassembling }
UnicornI386Simulator >> disassembler [
	
	^ LLVMDisassembler i386
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> doublePrecisionFloatingPointRegister0Value [

	^ self readFloat64Register: UcX86Registers xmm0
]

{ #category : #accessing }
UnicornI386Simulator >> eax [
	
	^ self readRegister: UcX86Registers eax
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> eax: anInteger [ 

	self writeRegister: UcX86Registers eax value: anInteger
]

{ #category : #accessing }
UnicornI386Simulator >> ebp [
	^ self readRegister: UcX86Registers ebp
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> ebp: anInteger [ 
	
	self framePointerRegisterValue: anInteger
]

{ #category : #accessing }
UnicornI386Simulator >> ebx [
	
	^ self readRegister: UcX86Registers ebx
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> ebx: anInteger [ 

	self writeRegister: UcX86Registers ebx value: anInteger
]

{ #category : #accessing }
UnicornI386Simulator >> ecx [
	^ self readRegister: UcX86Registers ecx
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> ecx: anInteger [ 

	self writeRegister: UcX86Registers ecx value: anInteger
]

{ #category : #accessing }
UnicornI386Simulator >> edi [
	
	^ self readRegister: UcX86Registers edi
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> edi: anInteger [ 
	
	self writeRegister: UcX86Registers edi value: anInteger
]

{ #category : #accessing }
UnicornI386Simulator >> edx [
	^ self readRegister: UcX86Registers edx
]

{ #category : #registers }
UnicornI386Simulator >> edx: anInteger [ 
	
	^ self writeRegister: UcX86Registers edx value: anInteger
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> eflags [
	
	^ self readRegister: UcX86Registers eflags
]

{ #category : #registers }
UnicornI386Simulator >> eip [
	
	^ self readRegister: UcX86Registers eip
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> eip: anInteger [ 
	
	self writeRegister: UcX86Registers eip value: anInteger
]

{ #category : #accessing }
UnicornI386Simulator >> esi [
	
	^ self readRegister: UcX86Registers esi
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> esi: anInteger [ 
	
	self writeRegister: UcX86Registers esi value: anInteger
]

{ #category : #accessing }
UnicornI386Simulator >> esp [
	
	^ self readRegister: UcX86Registers esp
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> esp: anInteger [ 
	
	self stackPointerRegisterValue: anInteger
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> extractDestinationRegisterFromAssembly: aLLVMInstruction [ 
	
	| registerName |
	registerName := (aLLVMInstruction assemblyCodeString substrings: ',') last trimBoth.
	(registerName beginsWith: '%')
		ifTrue: [ registerName := registerName allButFirst ].
	^ registerName
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> fp [
	^ self readRegister: UcX86Registers ebp
]

{ #category : #registers }
UnicornI386Simulator >> framePointerRegister [
	
	^ UcX86Registers ebp
]

{ #category : #accessing }
UnicornI386Simulator >> getReturnAddress [
	
	^ self peekAddress
]

{ #category : #registers }
UnicornI386Simulator >> instructionPointerRegister [
	
	^ UcX86Registers eip
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> integerRegisterState [

	^{	self eax. self ebx. self ecx. self edx. self esp. self ebp. self esi. self edi.
		self eip. self eflags }
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> pc [
	^ self readRegister: UcX86Registers eip
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> postCallArgumentsNumArgs: numArgs in: aMemory [
	"Answer an argument vector of the requested size after a vanilla
	 ABI call.  On IA32 this typically means accessing stacked arguments
	 beyond the pushed return address and saved frame pointer.
	 For compatibility with Cog/Slang we answer unsigned values."

	^ (9 to: numArgs * 4 + 5 by: 4) collect: [ :i | 
		  aMemory unsignedLongAt: self ebp + i ]
]

{ #category : #registers }
UnicornI386Simulator >> receiverRegister [
	
	^ UcX86Registers edx
]

{ #category : #accessing }
UnicornI386Simulator >> registerList [
	
	^ #(eip eax ebx ecx edx esp ebp esi edi)
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> retpcIn: aMemory [

	^ aMemory unsignedLongAt: self ebp + 5
]

{ #category : #registers }
UnicornI386Simulator >> sendNumberOfArgumentsRegister [

	^ UcX86Registers ebx
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> simulateJumpCallOf: address memory: aMemory [
	"Simulate a frame-building jump call of address (i.e. do not push the return pc
	 as this has already been done).  Build a frame since
	a) this is used for calls into the run-time which are unlikely to be leaf-calls, and
	b) stack alignment needs to be realistic for assert checking for platforms such as Mac OS X"

	self pushWord: self ebp.
	self ebp: self esp.
	self eip: address
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> simulateLeafCallOf: address nextpc: nextpc memory: aMemory [

	self pushWord: nextpc.
	self eip: address
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> simulateReturnIn: aMemory [

	self ebp: self popWord.
	self eip: self popWord
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> smashCallerSavedRegistersWithValuesFrom: base by: step in: aMemory [
	#(eax: ecx: edx:)
	   withIndexDo:
		[:accessor :index|
		self perform: accessor with: index - 1 * step + base]
]

{ #category : #registers }
UnicornI386Simulator >> smashRegisterAccessors [

	^#(eax: ebx: ecx: edx: esi: edi:)
]

{ #category : #'as yet unclassified' }
UnicornI386Simulator >> sp [
	^ self readRegister: UcX86Registers esp
]

{ #category : #registers }
UnicornI386Simulator >> stackPointerRegister [
	
	^ UcX86Registers esp
]

{ #category : #accessing }
UnicornI386Simulator >> temporaryRegisterValue [
	
	^ self eax
]

{ #category : #accessing }
UnicornI386Simulator >> wordSize [
	
	^ 4
]
