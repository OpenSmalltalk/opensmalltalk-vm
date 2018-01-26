"
A CogSimStackEntry represents an object pushed on the stack, but during the partial evaluation that occurs as part of the StackToRegisterMappingCogit's compilation.  Bytecodes that produce operands (push items onto the stack) push suitably descriptive instances of CogSimStackEntry onto the simStack (simulation stack).  Bytecodes that consume operands (sends, assignments, returns, etc) take items off the simStack.  Hence the generated code avoids pushing items onto the real stack, and the StackToRegisterMappngCogit can put the operands found on the simStack in registers, etc.  Hence actual stack traffic is much reduced, a much more efficient calling convention is enabled, and so overall performance is increased.  This scheme is due to L. Peter Deutsch and extended here.

Instance Variables
	bcptr:					<Integer>
	cogit:					<StackToRegisterMappingCogit>
	constant:				<Oop>
	liveRegister:			<Integer>
	objectRepresentation:	<CogObjectRepresentation>
	offset:					<Integer>
	register:				<Integer>
	spilled:					<Boolean>
	type:					<Integer from SSBaseOffset, SSConstant, SSRegister or SSSpill>

bcptr
	- the bytecode PC at which this particular entry was created (pushed onto the stack).

cogit
	- the StackToRegisterMappingCogit using this instance

constant
	- if type = SSConstant then this is the constant's oop

liveRegister
	- unused other than for simSelf.  This is here for simSelf and for the subclass CogRegisterAllocatingSimStackEntry

objectRepresentation
	- the CogObjectRepresentation in use for the current object model

offset
	- if type = SSBaseOffset or type = SSSpill then this is the offset from register

register
	- type = SSBaseOffset or type = SSSpill or type = SSRegister then this is the register's code (NoReg, TempReg, ReceiverResultReg et al)

spilled
	- if true, then this entry has been spilled onto the actual stack (or rather code has been generated to push the entry onto the real stack)

type
	- SSBaseOffset, SSConstant, SSRegister or SSSpill
"
Class {
	#name : #CogSimStackEntry,
	#superclass : #VMStructType,
	#instVars : [
		'cogit',
		'objectRepresentation',
		'type',
		'spilled',
		'liveRegister',
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
	#category : #'VMMaker-JIT'
}

{ #category : #'simulation only' }
CogSimStackEntry class >> byteSizeForSimulator: aVMClass [
	"Answer an approximation of the byte size of an AbstractInstruction struct.
	 This is for estimating the alloca in allocateOpcodes:bytecodes:ifFail:"
	^self instSize * (aVMClass sizeof: #'void *')
]

{ #category : #translation }
CogSimStackEntry class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"Enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a CogSimStackEntry struct."
	"self typedef"
	self filteredInstVarNames do:
		[:ivn|
		aBinaryBlock
			value: (ivn = 'register' ifTrue: ['registerr'] ifFalse: [ivn]) "avoid reservedWord conflict"
			value: (ivn caseOf: {
						['type']			-> [#char].
						['spilled']		-> [#char].
						['register']		-> [#'signed char']. "because NoReg = -1"
						['liveRegister']	-> [#'signed char'].}
					otherwise:
						[#sqInt])]
]

{ #category : #translation }
CogSimStackEntry class >> structTypeName [
	^'SimStackEntry'
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
			[self assert: ((offset = baseOffset and: [register = baseRegister]) or: [cogit violatesEnsureSpilledSpillAssert]).
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
]

{ #category : #accessing }
CogSimStackEntry >> floatRegisterMask [
	^ 0
]

{ #category : #comparing }
CogSimStackEntry >> isFrameTempVar [
	"Answer if the receiver is a temporary variable.  This
	 only works in a frameful method, hence the weird name."
	<inline: true>
	^type = SSBaseOffset and: [register = FPReg]
]

{ #category : #comparing }
CogSimStackEntry >> isSameEntryAs: ssEntry [
	<var: 'ssEntry' type: #'CogSimStackEntry *'>
	^type = ssEntry type
	  and: [((type = SSBaseOffset or: [type == SSSpill]) and: [offset = ssEntry offset and: [register = ssEntry register]])
		or: [(type = SSRegister and: [register = ssEntry register])
		or: [(type = SSConstant and: [constant = ssEntry constant])]]]
]

{ #category : #accessing }
CogSimStackEntry >> liveRegister [

	^ liveRegister
]

{ #category : #accessing }
CogSimStackEntry >> liveRegister: anObject [

	^liveRegister := anObject
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
	spilled
		ifTrue:
			[cogit PopR: reg]
		ifFalse:
			[type caseOf: {
				[SSBaseOffset]	-> [cogit MoveMw: offset r: register R: reg].
				[SSConstant]	-> [cogit genMoveConstant: constant R: reg].
				[SSRegister]	-> [reg ~= register
										ifTrue: [cogit MoveR: register R: reg]
										ifFalse: [cogit Label]] }]
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
								nextPutAll: (cogit coInterpreter shortPrint: constant)].
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
CogSimStackEntry >> registerMaskOrNone [
	^type = SSRegister ifTrue: [cogit registerMaskFor: register] ifFalse: [0]
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
	type caseOf: {
		[SSBaseOffset]	-> [cogit MoveMw: offset r: register R: reg].
		[SSSpill]		-> [cogit MoveMw: offset r: register R: reg].
		[SSConstant]	-> [cogit genMoveConstant: constant R: reg].
		[SSRegister]	-> [reg ~= register
								ifTrue: [cogit MoveR: register R: reg]
								ifFalse: [cogit Label]] }
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
