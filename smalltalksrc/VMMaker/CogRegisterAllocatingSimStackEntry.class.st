Class {
	#name : #CogRegisterAllocatingSimStackEntry,
	#superclass : #CogSimStackEntry,
	#instVars : [
		'liveRegister'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'compile abstract instructions' }
CogRegisterAllocatingSimStackEntry >> ensureSpilledAt: baseOffset from: baseRegister [
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
					[ liveRegister = NoReg
						ifTrue: 
							[cogit MoveMw: offset r: register R: TempReg.
					 		 inst := cogit PushR: TempReg ]
						ifFalse: [ inst := cogit PushR: liveRegister]]
				ifFalse:
					[self assert: type = SSRegister.
					 inst := cogit PushR: register].
			 type := SSSpill.
			 offset := baseOffset.
			 register := baseRegister].
	spilled := true.
]

{ #category : #accessing }
CogRegisterAllocatingSimStackEntry >> liveRegister [

	^ liveRegister
]

{ #category : #accessing }
CogRegisterAllocatingSimStackEntry >> liveRegister: anObject [

	^liveRegister := anObject
]

{ #category : #'compile abstract instructions' }
CogRegisterAllocatingSimStackEntry >> popToReg: reg [
	| inst |
	<var: #inst type: #'AbstractInstruction *'>
	liveRegister ~= NoReg
		ifTrue: 
			[inst := reg ~= liveRegister
				ifTrue: [cogit MoveR: liveRegister R: reg]
				ifFalse: [cogit Label] ]
		ifFalse: 
			[spilled
				ifTrue:
					[inst := cogit PopR: reg]
				ifFalse:
					[type caseOf: {
						[SSBaseOffset]	-> [inst := cogit MoveMw: offset r: register R: reg].
						[SSConstant]	-> [inst := cogit genMoveConstant: constant R: reg].
						[SSRegister]	-> [inst := reg ~= register
														ifTrue: [cogit MoveR: register R: reg]
														ifFalse: [cogit Label]] }]].
	reg ~= TempReg ifTrue: [ liveRegister := reg ]
]

{ #category : #printing }
CogRegisterAllocatingSimStackEntry >> printStateOn: aStream [
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
	liveRegister ~= NoReg ifTrue:
		[aStream nextPutAll: ' (live: '; nextPutAll: (cogit backEnd nameForRegister: liveRegister); nextPut: $)].
	bcptr ifNotNil:
		[aStream space; nextPut: ${; print: bcptr; nextPut: $}].
	aStream nextPut: $)
]

{ #category : #'compile abstract instructions' }
CogRegisterAllocatingSimStackEntry >> storeToReg: reg [
	| inst |
	<var: #inst type: #'AbstractInstruction *'>
	liveRegister ~= NoReg
		ifTrue:
			[inst := reg ~= liveRegister
							ifTrue: [cogit MoveR: liveRegister R: reg]
							ifFalse: [cogit Label]]
		ifFalse:
			[type caseOf: {
				[SSBaseOffset]	-> [inst := cogit MoveMw: offset r: register R: reg].
				[SSSpill]		-> [inst := cogit MoveMw: offset r: register R: reg].
				[SSConstant]	-> [inst := cogit genMoveConstant: constant R: reg].
				[SSRegister]	-> [inst := reg ~= register
												ifTrue: [cogit MoveR: register R: reg]
												ifFalse: [cogit Label]] }].
	reg ~= TempReg ifTrue: [ liveRegister := reg ]
]
