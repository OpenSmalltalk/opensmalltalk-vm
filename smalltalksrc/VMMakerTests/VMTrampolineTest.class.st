Class {
	#name : #VMTrampolineTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#instVars : [
		'registerMask',
		'isAligned',
		'pushedBytes'
	],
	#pools : [
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
VMTrampolineTest >> setUp [

	super setUp.
	
	"Precondition for all tests. SP should be aligned to the stack alignment required by the platform"
	self assert: self stackPointerRegisterValue \\ cogit stackPointerAlignment equals: 0.
	
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
