Class {
	#name : #VMTrampolineTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#pools : [
		'VMSqueakClassIndices'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #tests }
VMTrampolineTest >> testAlignedNumberOfRegistersProducesAlignedStackPointer [

	| registerMask bytesAlignment registerIndex |
	registerMask := 0.
	bytesAlignment := cogit stackPointerAlignment.

	self wordSize to: bytesAlignment by: self wordSize do: [ :i |
		registerIndex := i / self wordSize.
		registerMask := registerMask bitOr: (cogit registerMaskFor: registerIndex).
	].

	self compile: [ cogit backend genSaveRegs: registerMask ].	
	self stackPointerRegisterValue: cogit stackPointerAlignment * 200.
	self runGeneratedCode.

	self assert: self stackPointerRegisterValue \\ cogit stackPointerAlignment equals: 0
]

{ #category : #tests }
VMTrampolineTest >> testUnalignedNumberOfRegistersProducesAlignedStackPointer [

	| registerMask bytesAlignment registerIndex |
	
	"Some architectures such as ARMv8 require that the SP is always aligned to some value even in between calls.
	In aarch64, such alignment is 16 bytes, while in other architectures this value is the word size.
	
	This test tests that saving the registers state in the stack leaves always the SP register aligned even if more/less things are moved to the stack"
	
	registerMask := 0.
	bytesAlignment := cogit stackPointerAlignment.

	self wordSize to: bytesAlignment + self wordSize by: self wordSize do: [ :i |
		registerIndex := i / self wordSize.
		registerMask := registerMask bitOr: (cogit registerMaskFor: registerIndex).
	].

	self compile: [ cogit backend genSaveRegs: registerMask ].	

	self stackPointerRegisterValue: cogit stackPointerAlignment * 200.
	self runGeneratedCode.
	self assert: self stackPointerRegisterValue \\ cogit stackPointerAlignment equals: 0
]
