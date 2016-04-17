Class {
	#name : #CogSimStackEntry,
	#superclass : #VMStructType,
	#instVars : [
		'cogit',
		'objectRepresentation',
		'type',
		'spilled',
		'annotateUse',
		'register',
		'offset',
		'constant',
		'bcptr'
	],
	#pools : [
		'CogAbstractRegisters',
		'CogCompilationConstants',
		'CogRTLOpcodes'
	],
	#category : 'VMMaker-JIT'
}

{ #category : #'simulation only' }
CogSimStackEntry class >> byteSizeForSimulator: aVMClass [
	"Answer an approximation of the byte size of an AbstractInstruction struct.
	 This is for estimating the alloca in allocateOpcodes:bytecodes:ifFail:"
	^self instSize * (aVMClass sizeof: #'void *')
]

{ #category : #translation }
CogSimStackEntry class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a CogSimStackEntry struct."
	"self printTypedefOn: Transcript"
	self filteredInstVarNames do:
		[:ivn|
		aBinaryBlock
			value: (ivn = 'register' ifTrue: ['registerr'] ifFalse: [ivn]) "avoid reservedWord conflict"
			value: (ivn caseOf: {
						['type']			-> [#char].
						['spilled']		-> [#char].
						['annotateUse']	-> [#char]}
					otherwise:
						[#sqInt])]
]

{ #category : #accessing }
CogSimStackEntry >> annotateUse [
	"Answer the value of annotateUse"

	^ annotateUse
]

{ #category : #accessing }
CogSimStackEntry >> annotateUse: anObject [
	"Set the value of annotateUse"

	^annotateUse := anObject
]

{ #category : #accessing }
CogSimStackEntry >> bcptr [
	"Answer the value of bcptr"

	^ bcptr
]

{ #category : #accessing }
CogSimStackEntry >> bcptr: anObject [
	"Set the value of bcptr"

	^bcptr := anObject
]

{ #category : #accessing }
CogSimStackEntry >> cogit [
	"Answer the value of cogit"
	<doNotGenerate>
	^cogit
]

{ #category : #'initialize-release' }
CogSimStackEntry >> cogit: aCogit [
	<doNotGenerate>
	cogit := aCogit.
	objectRepresentation := cogit objectRepresentation.
	^self
]

{ #category : #accessing }
CogSimStackEntry >> constant [
	"Answer the value of constant"
	self assert: type = SSConstant.
	^constant
]

{ #category : #accessing }
CogSimStackEntry >> constant: anObject [
	"Set the value of constant"

	^constant := anObject
]

{ #category : #'compile abstract instructions' }
CogSimStackEntry >> ensureSpilledAt: baseOffset from: baseRegister [
	| inst |
	<var: #inst type: #'AbstractInstruction *'>
	spilled ifTrue:
		[type = SSSpill ifTrue:
			[self assert: (offset = baseOffset and: [register = baseRegister]).
			 ^self]].
	self assert: type ~= SSSpill.
	cogit traceSpill: self.
	type = SSConstant
		ifTrue:
			[inst := cogit genPushConstant: constant]
		ifFalse:
			[type = SSBaseOffset
				ifTrue:
					[cogit MoveMw: offset r: register R: TempReg.
					 inst := cogit PushR: TempReg]
				ifFalse:
					[self assert: type = SSRegister.
					 inst := cogit PushR: register].
			 type := SSSpill.
			 offset := baseOffset.
			 register := baseRegister].
	spilled := true.
	self maybeAnnotateUse: inst
]

{ #category : #'compile abstract instructions' }
CogSimStackEntry >> maybeAnnotateUse: inst [
	<inline: true>
	annotateUse ifTrue:
		[inst annotation = 0
			ifTrue: [cogit annotateBytecode: inst]
			ifFalse: [cogit annotateBytecode: cogit Label].
		 annotateUse := false]
]

{ #category : #accessing }
CogSimStackEntry >> maybeConstant [
	"Answer the value of constant, no assert check."
	<cmacro: '(sse) ((sse)->constant)'>
	^constant
]

{ #category : #accessing }
CogSimStackEntry >> offset [
	"Answer the value of offset"
	self assert: type = SSBaseOffset.
	^offset
]

{ #category : #accessing }
CogSimStackEntry >> offset: anObject [
	"Set the value of offset"

	^offset := anObject
]

{ #category : #'compile abstract instructions' }
CogSimStackEntry >> popToReg: reg [
	| inst |
	<var: #inst type: #'AbstractInstruction *'>
	spilled
		ifTrue:
			[inst := cogit PopR: reg]
		ifFalse:
			[type caseOf: {
				[SSBaseOffset]	-> [inst := cogit MoveMw: offset r: register R: reg].
				[SSConstant]	-> [inst := cogit genMoveConstant: constant R: reg].
				[SSRegister]	-> [inst := reg ~= register
												ifTrue: [cogit MoveR: register R: reg]
												ifFalse: [cogit Label]] }].
	self maybeAnnotateUse: inst
]

{ #category : #printing }
CogSimStackEntry >> printStateOn: aStream [
	<doNotGenerate> "Smalltalk-side only"
	type isInteger ifFalse: [^self].
	aStream nextPut: $(.
	type caseOf: {
		[SSBaseOffset]	-> [aStream
								nextPutAll: 'bo ';
								nextPutAll: (cogit backEnd nameForRegister: register).
							offset negative ifFalse: [aStream nextPut: $+].
							aStream print: offset].
		[SSConstant]	-> [aStream
								nextPutAll: 'const ';
								print: constant].
		[SSRegister]	-> [aStream
								nextPutAll: 'reg ';
								nextPutAll: (cogit backEnd nameForRegister: register)].
		[SSSpill]		-> [aStream
								nextPutAll: 'spill @ ';
								nextPutAll: (cogit backEnd nameForRegister: register).
							offset negative ifFalse: [aStream nextPut: $+].
							aStream print: offset] }.
	(spilled and: [type ~= SSSpill]) ifTrue:
		[aStream nextPutAll: ' (spilled)'].
	annotateUse ifTrue:
		[aStream nextPutAll: ' (ANNOTATED)'].
	bcptr ifNotNil:
		[aStream space; nextPut: ${; print: bcptr; nextPut: $}].
	aStream nextPut: $)
]

{ #category : #accessing }
CogSimStackEntry >> register [
	"Answer the value of register"
	self assert: (type = SSBaseOffset or: [type = SSRegister]).
	^register
]

{ #category : #accessing }
CogSimStackEntry >> register: anObject [
	"Set the value of register"

	^register := anObject
]

{ #category : #accessing }
CogSimStackEntry >> registerMask [
	"Answer a bit mask for the receiver's register, if any."
	^(type = SSBaseOffset
		or: [type = SSRegister])
			ifTrue: [cogit registerMaskFor: register]
			ifFalse: [0]
]

{ #category : #accessing }
CogSimStackEntry >> registerOrNone [
	^type = SSRegister ifTrue: [register] ifFalse: [NoReg]
]

{ #category : #accessing }
CogSimStackEntry >> spilled [
	"Answer the value of spilled"

	^ spilled
]

{ #category : #accessing }
CogSimStackEntry >> spilled: anObject [
	"Set the value of spilled"

	^spilled := anObject
]

{ #category : #'compile abstract instructions' }
CogSimStackEntry >> storeToReg: reg [
	| inst |
	<var: #inst type: #'AbstractInstruction *'>
	type caseOf: {
		[SSBaseOffset]	-> [inst := cogit MoveMw: offset r: register R: reg].
		[SSSpill]		-> [inst := cogit MoveMw: offset r: register R: reg].
		[SSConstant]	-> [inst := cogit genMoveConstant: constant R: reg].
		[SSRegister]	-> [inst := reg ~= register
										ifTrue: [cogit MoveR: register R: reg]
										ifFalse: [cogit Label]] }.
	self maybeAnnotateUse: inst
]

{ #category : #accessing }
CogSimStackEntry >> type [
	"Answer the value of type"

	^ type
]

{ #category : #accessing }
CogSimStackEntry >> type: anObject [
	"Set the value of type"

	^type := anObject
]
