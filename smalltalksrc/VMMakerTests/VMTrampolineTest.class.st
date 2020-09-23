Class {
	#name : #VMTrampolineTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#instVars : [
		'registerMask',
		'isAligned',
		'pushedBytes'
	],
	#pools : [
		'CogAbstractRegisters',
		'VMSqueakClassIndices'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #'building suites' }
VMTrampolineTest class >> testParameters [ 

	^ super testParameters * { 
		{ #isAligned -> true }.
		{ #isAligned -> false }
	}
]

{ #category : #tests }
VMTrampolineTest >> isAligned [

	^ isAligned
]

{ #category : #tests }
VMTrampolineTest >> isAligned: aBoolean [

	isAligned := aBoolean
]

{ #category : #tests }
VMTrampolineTest >> jitCompilerClass [

	^ StackToRegisterMappingCogit
]

{ #category : #tests }
VMTrampolineTest >> setUp [

	super setUp.
	
	"Precondition for all tests. SP should be aligned to the stack alignment required by the platform"
	[isAligned := self stackPointerRegisterValue \\ cogit stackPointerAlignment = 0]
		whileFalse: [ self pushAddress: 16rBEEF "a small integer to mark..." ].
	
	pushedBytes := cogit stackPointerAlignment.
	self isAligned ifFalse: [
		pushedBytes := pushedBytes + self wordSize ].

	registerMask := 0.
	self wordSize to: pushedBytes by: self wordSize do: [ :i | | registerIndex |
		registerIndex := i / self wordSize.
		registerMask := registerMask bitOr: (cogit registerMaskFor: registerIndex).
	].

]

{ #category : #tests }
VMTrampolineTest >> testLoadStackPointersShouldLoadFramePointer [
	
	self compile: [ cogit backend genLoadStackPointers ].
	
	"We reset the stack pointer and run our code"
	
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	self interpreter stackPointer: 0.
	self interpreter framePointer: 42.
	self framePointerRegisterValue: 0.

	self runFrom: initialAddress until: self getLastAddress.

	"The generated code should load in FP the value stored in `framePointer`"
	self assert: self framePointerRegisterValue equals: 42
]

{ #category : #tests }
VMTrampolineTest >> testLoadStackPointersShouldLoadStackPointer [
	
	self compile: [ cogit backend genLoadStackPointers ].
	
	"We reset the stack pointer and run our code"
	
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	self interpreter stackPointer: 17.
	self interpreter framePointer: 0.
	self stackPointerRegisterValue: 0.
	
	self runFrom: initialAddress until: self getLastAddress.

	"The generated code should load in SP the value stored in `stackPointer`"
	self assert: self stackPointerRegisterValue equals: 17
]

{ #category : #tests }
VMTrampolineTest >> testRestoreRegistersProducesAlignedStackPointer [

	| initialStackPointer |

	initialStackPointer := self stackPointerRegisterValue.
	self stackPointerRegisterValue: initialStackPointer.

	self compile: [ 
		cogit backend genSaveRegs: registerMask.
		cogit backend genRestoreRegs: registerMask.
	].	

	self runGeneratedCode.

	self assert: self stackPointerRegisterValue equals: initialStackPointer
]

{ #category : #tests }
VMTrampolineTest >> testSendTrampolineShouldNotOverrideLinkRegisterWhenCallDereferenceSelectorRoutine [
	
	| dereferenceRoutine previousLinkRegister trampoline |
	
	cogit hasLinkRegister ifFalse: [ ^ self skip ].
	
	dereferenceRoutine := self compile: [ cogit RetN: 0 ].
	cogit ceDereferenceSelectorIndex: dereferenceRoutine.
	
	[trampoline := self compile: [ cogit
			genSendTrampolineFor: #ceSend:super:to:numArgs:
			numArgs: 4
			called: 'test'
			arg: ClassReg
			arg: (cogit trampolineArgConstant: true)
			arg: ReceiverResultReg
			arg: (cogit numArgsOrSendNumArgsReg: 1) ].]
	on: AssertionFailure do: [ :e | e resumeUnchecked: nil ].
	
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	machineSimulator linkRegisterValue: (previousLinkRegister := 42).

	self runFrom: trampoline until: cogit ceDereferenceSelectorIndex.

	"The generated code should load in FP the value stored in `framePointer`"
	self assert: machineSimulator linkRegisterValue equals: previousLinkRegister
]

{ #category : #tests }
VMTrampolineTest >> testSmalltalkToCStackShouldPushLinkRegister [

	cogit backend hasLinkRegister ifFalse: [ ^ self skip ].
	
	self compile: [ cogit genSmalltalkToCStackSwitch: true "do not push link register" ].
	
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	machineSimulator linkRegisterValue: 42.

	self runFrom: initialAddress until: self getLastAddress.

	"The generated code should push the link register in the interpreter stack"
	self assert: self interpreter stackTop equals: 42
]

{ #category : #tests }
VMTrampolineTest >> testSmalltalkToCStackSwitchShouldUpdateInterpreterFramePointer [
	
	self compile: [ cogit genSmalltalkToCStackSwitch: false "do not push link register" ].
	
	"Initialize the state of the interpreter"
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	self cogit setCStackPointer: 108.
	self cogit setCFramePointer: 116.
	self framePointerRegisterValue: 42.

	self runFrom: initialAddress until: self getLastAddress.

	"The generated code should load in the interpreter stackPointer the value stored in the SP register"
	self assert: self interpreter framePointer equals: 42
]

{ #category : #tests }
VMTrampolineTest >> testSmalltalkToCStackSwitchShouldUpdateInterpreterStackPointer [
	
	self compile: [ cogit genSmalltalkToCStackSwitch: false "do not push link register" ].
	
	"Initialize the state of the interpreter"
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	self cogit setCStackPointer: 108.
	self cogit setCFramePointer: 116.
	self stackPointerRegisterValue: 42.

	self runFrom: initialAddress until: self getLastAddress.

	"The generated code should load in the interpreter stackPointer the value stored in the SP register"
	self assert: self interpreter stackPointer equals: 42
]

{ #category : #tests }
VMTrampolineTest >> testStoreRegistersProducesAlignedStackPointer [

	"Some architectures such as ARMv8 require that the SP is always aligned to some value even in between calls.
	In aarch64, such alignment is 16 bytes, while in other architectures this value is the word size.
	
	This test tests that saving the registers state in the stack leaves always the SP register aligned even if more/less things are moved to the stack"
	self compile: [ cogit backend genSaveRegs: registerMask ].	

	self runGeneratedCode.
	self assert: self stackPointerRegisterValue \\ cogit stackPointerAlignment equals: 0
]

{ #category : #tests }
VMTrampolineTest >> testStoreRegistersPushesValuesToStack [

	| initialStackPointer actualPushedBytes |

	self compile: [ cogit backend genSaveRegs: registerMask ].	
	
	initialStackPointer := self stackPointerRegisterValue.
	self runGeneratedCode.
	actualPushedBytes := initialStackPointer - self stackPointerRegisterValue.
	
	self assert: actualPushedBytes >= pushedBytes
]
