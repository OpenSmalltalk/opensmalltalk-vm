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
	spilled ifTrue:
		[type = SSSpill ifTrue:
			[self assert: (offset = baseOffset and: [register = baseRegister]).
			 liveRegister := NoReg.
			 ^self]].
	self assert: type ~= SSSpill.
	cogit traceSpill: self.
	type = SSConstant
		ifTrue:
			[cogit genPushConstant: constant]
		ifFalse:
			[type = SSBaseOffset
				ifTrue:
					[liveRegister = NoReg
						ifTrue: 
							[cogit MoveMw: offset r: register R: TempReg.
					 		 cogit PushR: TempReg]
						ifFalse: [cogit PushR: liveRegister]]
				ifFalse:
					[self assert: type = SSRegister.
					 cogit PushR: register].
			 type := SSSpill.
			 offset := baseOffset.
			 register := baseRegister].
	liveRegister := NoReg.
	spilled := true
]

{ #category : #comparing }
CogRegisterAllocatingSimStackEntry >> isSameEntryAs: ssEntry [
	^type = ssEntry type
	  and: [((type = SSBaseOffset or: [type == SSSpill]) and: [offset = ssEntry offset and: [register = ssEntry register]])
		or: [(type = SSRegister and: [register = ssEntry register])
		or: [(type = SSConstant and: [constant = ssEntry constant])]]]
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
CogRegisterAllocatingSimStackEntry >> noteLiveRegisterIn: simStackEntry [
	"Copy the liveRegister state in simStackEntry into the receiver if it is the same value at a different location on the stack."
	<inline: true>
	self flag: 'should this also apply to SSConstant entries assigned to registers?'.
	(self ~~ simStackEntry
	 and: [type = simStackEntry type
	 and: [type = SSBaseOffset
	 and: [register = simStackEntry register and: [offset = simStackEntry offset]]]]) ifTrue:
		[liveRegister := simStackEntry liveRegister]
]

{ #category : #accessing }
CogRegisterAllocatingSimStackEntry >> offset [
	"Answer the value of offset"
	self assert: (type = SSBaseOffset or: [type = SSSpill]).
	^offset
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
	reg ~= TempReg ifTrue:
		[liveRegister := reg.
		 cogit observeLiveRegisterIn: self]
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
CogRegisterAllocatingSimStackEntry >> reconcileWith: simStackEntry [
	"Make the state of each simStackEntry, a stack entry along the non-inlined special selector path,
	 the same as the corresponding simStackEntry along the inlined path (the receiver)."
	<var: #simStackEntry type: #'SimStackEntry *'>
	type = SSConstant ifTrue:
		[cogit AddCw: BytesPerWord R: SPReg.
		 ^self].
	liveRegister ~= NoReg ifTrue:
		[simStackEntry popToReg: liveRegister.
		 ^self].
	type = SSRegister ifTrue:
		[simStackEntry popToReg: register.
		 ^self].
	self halt
]

{ #category : #accessing }
CogRegisterAllocatingSimStackEntry >> register [
	"Answer the value of register"
	self assert: (type = SSBaseOffset or: [type = SSRegister or: [type = SSSpill]]).
	^register
]

{ #category : #accessing }
CogRegisterAllocatingSimStackEntry >> registerMask [
	"Answer a bit mask for the receiver's register, if any."
	liveRegister ~= NoReg ifTrue:
		[^cogit registerMaskFor: liveRegister].
	^super registerMask
]

{ #category : #accessing }
CogRegisterAllocatingSimStackEntry >> registerOrNone [
	liveRegister ~= NoReg ifTrue:
		[^liveRegister].
	^super registerOrNone
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
	reg ~= TempReg ifTrue:
		[liveRegister := reg.
		 cogit observeLiveRegisterIn: self]
]
