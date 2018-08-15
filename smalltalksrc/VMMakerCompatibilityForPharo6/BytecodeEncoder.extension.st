Extension { #name : #BytecodeEncoder }

{ #category : #'*VMMakerCompatibilityForPharo6-instruction stream support' }
BytecodeEncoder class >> extensionsAt: pc in: aCompiledMethod into: trinaryBlock [
	"If the bytecode at pc is an extension then evaluate aTrinaryBlock
	 with the values of extA and extB and number of extension *bytes*.
	 If the bytecode at pc is not an extension then evaluate with 0, 0, 0."

	self subclassResponsibility
]
