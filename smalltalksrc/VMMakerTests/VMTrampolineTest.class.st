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
	]
]

{ #category : #tests }
VMTrampolineTest >> testCallEnilopmartSucceedsExecution [
	| inc baseMethod baseMethodIP ctx page |
	"Add 1 to the receiver result reg as a small integer"
	inc := self compile: [ 
		cogit AddCq: 1 << memory numSmallIntegerTagBits R: ReceiverResultReg.
		"Force a return to our call"
		cogit PushCw: callerAddress.
		cogit RetN: 0 ].

	initialAddress := self compileWithoutOutput: [ cogit
		genEnilopmartFor: ReceiverResultReg
		forCall: false
		called: 'ceEnterCogCodePopReceiverReg' ] bytecodes: 10.

	"Initialize with some stack pointer and frame pointer"
	baseMethod := methodBuilder newMethod
		literals: { memory nilObject. memory nilObject }; 
		buildMethod.
	
	baseMethodIP := memory lastPointerOf: baseMethod.
	
	"The context has 5 (in 32 bits) or 9 (in 64 bits) as initial IP, as method has at least one literal"
	ctx := self newSmallContextReceiver: memory nilObject method: baseMethod arguments: #() temporaries: #() ip: baseMethodIP + 1.

	"The base context has a trampoline as the savedIP so it can return to a context that is in the heap"
	cogit ceBaseFrameReturnTrampoline: 16rAABBCCDD.	
	cogit setCStackPointer: interpreter rumpCStackAddress.
	cogit setCFramePointer: interpreter rumpCStackAddress.
	
	page := interpreter makeBaseFrameFor: ctx.
	interpreter setStackPointersFromPage: page.
	interpreter setStackPageAndLimit: page.
	interpreter instructionPointer: interpreter popStack.

	"Initialize Stack to the correct pointers in the selected page"
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	
	"Calling convention of enilopmarts: target address and arguments are pushed to the stack"	
	interpreter push: inc.
	interpreter push: (memory integerObjectOf: 2).

	self prepareCall.
	self runUntilReturn.

	self assert: machineSimulator receiverRegisterValue equals: (memory integerObjectOf: 3)
]

{ #category : #tests }
VMTrampolineTest >> testDetectFrameNotPointerInUse [

	"The code in generateStackPointerCapture detects if the C Frame pointer is in use.
	If we use the simulation mode that does not update it, the VM should detect it is not in use"
	cogit simulateFPInUse: false.
	
	"This routine is always called by C, so this is always aligned"
	machineSimulator stackPointerRegisterValue: (machineSimulator stackPointerRegisterValue bitAnd: -16). 
	
	self compileWithoutOutput: [ cogit generateStackPointerCapture ] bytecodes: 10.
	
	self deny: cogit isCFramePointerInUse
]

{ #category : #tests }
VMTrampolineTest >> testDetectFramePointerInUse [

	"The code in generateStackPointerCapture detects if the C Frame pointer is in use.
	If we use the simulation mode that does not update it, the VM should detect it is not in use"
	cogit simulateFPInUse: true.
	
	"This routine is always called by C, so this is always aligned"
	machineSimulator stackPointerRegisterValue: (machineSimulator stackPointerRegisterValue bitAnd: -16). 
	
	self compileWithoutOutput: [ cogit generateStackPointerCapture ] bytecodes: 10.
	
	self assert: cogit isCFramePointerInUse
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
	machineSimulator smalltalkStackPointerRegisterValue: 0.
	
	self runFrom: initialAddress until: self getLastAddress.

	"The generated code should load in SP the value stored in `stackPointer`"
	self assert: machineSimulator smalltalkStackPointerRegisterValue equals: 17
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
	
	"This trampoline is only valid for ARMv8"
	cogit backend hasLinkRegister ifFalse: [ ^ self skip ].
	self wordSize = 8 ifFalse: [ ^ self skip ].
	
	dereferenceRoutine := self compile: [ cogit RetN: 0 ].
	cogit ceDereferenceSelectorIndex: dereferenceRoutine.
	
	trampoline := self compileWithoutOutput: [ cogit
			genSendTrampolineFor: #ceSend:super:to:numArgs:
			numArgs: 1
			called: 'test'
			arg: ClassReg
			arg: ClassReg
			arg: ReceiverResultReg
			arg: ReceiverResultReg ] bytecodes: 1 "hint for IR allocation".
	
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	machineSimulator linkRegisterValue: (previousLinkRegister := 42).

	self runFrom: trampoline until: (cogit simulatedTrampolineFor: #ceSend:super:to:numArgs:).

	"The generated code should push the correct link register in the stack.
	The link register should now reference the IP where the trampoline is suspended."
	self assert: self interpreter stackTop equals: previousLinkRegister
]

{ #category : #tests }
VMTrampolineTest >> testSmalltalkToCStackShouldLoadCFramePointer [
	
	self compile: [ cogit genSmalltalkToCStackSwitch: false "do not push link register" ].
	
	cogit setCStackPointer: 777.
	cogit setCFramePointer: 888.
	machineSimulator baseRegisterValue: cogit varBaseAddress.

	self runFrom: initialAddress until: self getLastAddress.

	self assert: machineSimulator framePointerRegisterValue equals: 888
]

{ #category : #tests }
VMTrampolineTest >> testSmalltalkToCStackShouldLoadCStackPointer [
	
	self compile: [ cogit genSmalltalkToCStackSwitch: false "do not push link register" ].
	
	cogit setCStackPointer: 777.
	cogit setCFramePointer: 888.
	machineSimulator baseRegisterValue: cogit varBaseAddress.

	self runFrom: initialAddress until: self getLastAddress.

	self assert: machineSimulator stackPointerRegisterValue equals: 777
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
	machineSimulator smalltalkStackPointerRegisterValue: 42.

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
	
	initialStackPointer := machineSimulator smalltalkStackPointerRegisterValue.
	self runGeneratedCode.
	actualPushedBytes := initialStackPointer - machineSimulator smalltalkStackPointerRegisterValue.
	
	self assert: actualPushedBytes >= pushedBytes
]
