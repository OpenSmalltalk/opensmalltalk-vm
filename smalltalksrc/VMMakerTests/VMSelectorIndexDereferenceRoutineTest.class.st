Class {
	#name : #VMSelectorIndexDereferenceRoutineTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#pools : [
		'VMSqueakClassIndices'
	],
	#category : #'VMMakerTests-JitTests'
}

{ #category : #tests }
VMSelectorIndexDereferenceRoutineTest >> test32BitsDoesNotGenerateRoutine [

	"32 bit platforms use a direct selector reference and not an index"
	self wordSize = 4 ifFalse: [ ^ self skip ].
	
	cogit objectRepresentation maybeGenerateSelectorIndexDereferenceRoutine.
	
	self assert: cogit ceDereferenceSelectorIndex isNil
]

{ #category : #tests }
VMSelectorIndexDereferenceRoutineTest >> test64BitsGeneratesRoutine [

	"64 bit platforms use a selector index and a routine to map it to the real selector"
	self wordSize = 8 ifFalse: [ ^ self skip ].
	
	cogit objectRepresentation maybeGenerateSelectorIndexDereferenceRoutine.
	
	self assert: cogit ceDereferenceSelectorIndex notNil
]

{ #category : #tests }
VMSelectorIndexDereferenceRoutineTest >> testNegativeSelectorIndexIsLookedUpInSpecialSelectorTable [

	"64 bit platforms use a selector index and a routine to map it to the real selector"
	| index specialSelectorsArray twoComplementIndex |
	self wordSize = 8 ifFalse: [ ^ self skip ].
	
	cogit objectRepresentation maybeGenerateSelectorIndexDereferenceRoutine.
	
	"Smalltalk 1-based array index where the selector should be."
	index := 3.
	
	"Setup a special selector array with enough space for `index` pairs of objects.
	Each pair has a selector and its arity.
	Put as selector some marker object such as false"
	specialSelectorsArray := self newOldSpaceObjectWithSlots: index * 2.
	memory coInterpreter
		specialSelectorArray: specialSelectorsArray;
		specialSelector: (index - 1 "0-based") put: memory falseObject.

	twoComplementIndex := 16rffffffffffffffff - index + 1.
	machineSimulator classRegisterValue: twoComplementIndex.
	machineSimulator baseRegisterValue: cogit varBaseAddress.

	self runFrom: cogit ceDereferenceSelectorIndex until: callerAddress.

	self assert: machineSimulator classRegisterValue equals: memory falseObject
]

{ #category : #tests }
VMSelectorIndexDereferenceRoutineTest >> testPositiveSelectorIndexIsLookedUpInMethodLiterals [

	"64 bit platforms use a selector index and a routine to map it to the real selector"
	| index method builder cogMethod |
	self wordSize = 8 ifFalse: [ ^ self skip ].
	
	self setUpCogMethodEntry.
	cogit objectRepresentation maybeGenerateSelectorIndexDereferenceRoutine.
	
	"Smalltalk 1-based array index where the selector should be."
	index := 3.

	"Create a compiled bytecode method with a marker object at a given index, and a machine code method linked to it."	
	method := methodBuilder literalAt: index put: memory falseObject; buildMethod.
	cogMethod := self generateCogMethod: [ cogit RetN: 0 ] selector: memory nilObject.
	cogit coInterpreter rawHeaderOf: method put: cogMethod asInteger.
	cogMethod methodObject: method.
	
	builder := self machineCodeFrameBuilder.
	builder returnAddress: callerAddress.
	builder method: cogMethod.
	builder buildFrame.
	
	machineSimulator classRegisterValue: index.
	machineSimulator baseRegisterValue: cogit varBaseAddress.
	
	self prepareCall.
	self runFrom: cogit ceDereferenceSelectorIndex until: callerAddress.

	self assert: machineSimulator classRegisterValue equals: memory falseObject
]
