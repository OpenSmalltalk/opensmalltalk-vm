Class {
	#name : #CogRegisterAllocatingSimStackEntry,
	#superclass : #CogSimStackEntry,
	#category : #'VMMaker-JIT'
}

{ #category : #'compile abstract instructions' }
CogRegisterAllocatingSimStackEntry >> copyLiveRegisterIfSameAs: simStackEntry [
	<inline: true>
	self flag: 'should this also apply to SSConstant entries assigned to registers?'.
	(self ~~ simStackEntry
	 and: [type = simStackEntry type
	 and: [type = SSBaseOffset
	 and: [register = simStackEntry register and: [offset = simStackEntry offset]]]]) ifTrue:
		[liveRegister := simStackEntry liveRegister]
]

{ #category : #'compile abstract instructions' }
CogRegisterAllocatingSimStackEntry >> ensureSpilledAt: baseOffset from: baseRegister [
	spilled ifTrue:
		[type = SSSpill ifTrue:
			[self assert: ((offset = baseOffset and: [register = baseRegister]) or: [cogit violatesEnsureSpilledSpillAssert]).
			 liveRegister := NoReg.
			 ^self]].
	self assert: type ~= SSSpill.
	cogit traceSpill: self.
	"N.B. Keep the type of SSConstant spills as SSConstant so that when joins occur
	 as a result of expressions with constants on the stack, the constant on stack
	 can be recovered.  e.g. as in
		self at: 1 put: (self foo ifTrue: [self bar] ifFalse: [self baz])."
	type = SSConstant
		ifTrue:
			[liveRegister = NoReg
				ifTrue: [cogit genPushConstant: constant]
				ifFalse: [cogit PushR: liveRegister]]
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
			 type := SSSpill].
	liveRegister := NoReg.
	spilled := true.
	offset := baseOffset.
	register := baseRegister
]

{ #category : #comparing }
CogRegisterAllocatingSimStackEntry >> isIdenticalEntryAs: ssEntry [
	<var: 'ssEntry' type: #'CogSimStackEntry *'>
	^type = ssEntry type
	  and: [liveRegister = ssEntry liveRegister
	  and: [((type = SSBaseOffset or: [type == SSSpill]) and: [offset = ssEntry offset and: [register = ssEntry register]])
		or: [(type = SSRegister and: [register = ssEntry register])
		or: [(type = SSConstant and: [constant = ssEntry constant])]]]]
]

{ #category : #comparing }
CogRegisterAllocatingSimStackEntry >> isMergedWithTargetEntry: targetEntry [
	"The receiver is a simStackEntry at a jump to the corresponding simStackEntry at the jump's target.
	 Answer if no merge is required for the jump."
	<var: 'ssEntry' type: #'CogSimStackEntry *'>
	spilled ~= targetEntry spilled ifTrue: "push or pop required"
		[^false].
	(liveRegister = NoReg and: [targetEntry liveRegister ~= NoReg]) ifTrue: "register load required"
		[^false].
	(self isSameEntryAs: targetEntry) ifTrue:
		[^liveRegister = targetEntry liveRegister].
	(type = SSConstant and: [targetEntry type = SSRegister and: [liveRegister = targetEntry register]]) ifTrue:
		[^true].
	"self: const =1 (16r1) (live: Extra4Reg) {172} vs reg ReceiverResultReg {127}"
	"self: reg ReceiverResultReg {95} vs reg Extra5Reg {85}"
	"self: (bo ReceiverResultReg+296 (live: Extra5Reg) {88} vs reg ReceiverResultReg {84}"
	"self: const =1 (16r1) (spilled) {167} vs spill @ FPReg-48 {122}"
	((type = SSConstant and: [targetEntry type = SSRegister and: [liveRegister ~= targetEntry registerOrNone]])
	 or: [(type = SSRegister and: [targetEntry type = SSRegister and: [register ~= targetEntry registerOrNone]])
	 or: [(type = SSBaseOffset and: [register = ReceiverResultReg and: [targetEntry type = SSRegister]])
	 or: [(type = SSConstant and: [targetEntry type = SSSpill])]]]) ifFalse:
		[self halt: 'comment the incompatible pair please'].
	^false
]

{ #category : #accessing }
CogRegisterAllocatingSimStackEntry >> liveRegister [

	^ liveRegister
]

{ #category : #accessing }
CogRegisterAllocatingSimStackEntry >> offset [
	"Answer the value of offset"
	self assert: (type = SSBaseOffset or: [type = SSSpill]).
	^offset
]

{ #category : #'compile abstract instructions' }
CogRegisterAllocatingSimStackEntry >> popToReg: reg [
	liveRegister ~= NoReg
		ifTrue: 
			[self deny: (type = SSRegister and: [register ~= liveRegister and: [cogit needsFrame]]).
			 spilled ifTrue: "This is rare, and in some cases it isn't even needed (e.g. frameful return) but we can't tell as yet."
				[cogit AddCq: objectRepresentation wordSize R: SPReg].
			 reg ~= liveRegister
				ifTrue: [cogit MoveR: liveRegister R: reg]
				ifFalse: [cogit Label]]
		ifFalse: 
			[spilled
				ifTrue:
					[cogit PopR: reg]
				ifFalse:
					[type caseOf: {
						[SSBaseOffset]	-> [cogit MoveMw: offset r: register R: reg].
						[SSSpill]		-> [cogit MoveMw: offset r: register R: reg].
						[SSConstant]	-> [cogit genMoveConstant: constant R: reg].
						[SSRegister]	-> [reg ~= register
												ifTrue: [cogit MoveR: register R: reg]
												ifFalse: [cogit Label]] }]].

	(reg ~= TempReg and: [liveRegister = NoReg and: [type ~= SSRegister]]) ifTrue:
		[liveRegister := reg.
		 cogit copyLiveRegisterToCopiesOf: self]
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
		[aStream nextPutAll: ' (live: '; nextPutAll: (liveRegister ifNil: ['NIL!!'] ifNotNil: [cogit backEnd nameForRegister: liveRegister]); nextPut: $)].
	bcptr ifNotNil:
		[aStream space; nextPut: ${; print: bcptr; nextPut: $}].
	aStream nextPut: $)
]

{ #category : #'compile abstract instructions' }
CogRegisterAllocatingSimStackEntry >> reconcileWith: targetEntry spillOffset: spillOffset onSpillOrUnspill: spillOrUnspillBlock [
	"Make the state of a targetEntry, a stack entry following a non-inlined special selector
	 send, the same as the corresponding entry (the receiver) along the inlined path.
	 spillOffset is zero for non-spill locations (self & temps), and the offset of the spill for
	 volatile stack entries. spillOrUnspillBlock is a block evaluated with the target's
	 registerOrNone if the receiver and target have different spilledness.
	 Answer if the reconciliation merged a register; merged registers must be deassigned."
	<var: #targetEntry type: #'SimStackEntry *'>
	<inline: true>
	| targetReg mergedRegister |
	spilled = targetEntry spilled ifTrue:
		[self assert: ((self isSameEntryAs: targetEntry)
					 or: [(targetEntry spilled not and: [targetEntry registerOrNone ~= NoReg])
					 or: [spilled and: [type = SSConstant and: [offset = targetEntry offset]]]]).
		 (targetReg := targetEntry registerOrNone) = NoReg ifTrue:
			[liveRegister := NoReg.
			 ^false].
		 mergedRegister := false.
		 type caseOf: {
			[SSBaseOffset]	-> [liveRegister ~= targetReg ifTrue:
									[cogit MoveMw: offset r: register R: targetReg.
									 mergedRegister := true].
								targetEntry type caseOf: {
									[SSBaseOffset]	-> [liveRegister := targetReg.
														(self isSameEntryAs: targetEntry) ifFalse:
															[type := SSSpill.
															 offset := spillOffset]].
									[SSSpill]		-> [liveRegister := targetReg. type := SSSpill.
														offset := spillOffset].
									[SSConstant]	-> [liveRegister := targetReg. type := SSSpill.
														offset := spillOffset].
									[SSRegister]	-> [register := targetReg. type := SSRegister] }].
			[SSSpill]		-> [cogit MoveMw: offset r: register R: targetReg.
								liveRegister := targetReg.
								mergedRegister := true].
			[SSConstant]	-> [liveRegister = NoReg
									ifTrue: [cogit genMoveConstant: constant R: targetReg]
									ifFalse: [cogit MoveR: liveRegister R: targetReg].
								type := SSRegister. register := targetReg. liveRegister := NoReg.
								mergedRegister := true].
			[SSRegister]	-> [targetReg ~= register ifTrue:
									[cogit MoveR: register R: targetReg.
									 register := targetReg.
									 mergedRegister := true]] }.
		 ^mergedRegister].
	targetReg := targetEntry registerOrNone.
	spillOrUnspillBlock value: targetReg.
	(type = SSConstant
	 and: [targetEntry type ~= SSConstant or: [targetEntry constant ~= constant]]) ifTrue:
		[type := SSSpill. offset := spillOffset. register := FPReg].
	liveRegister ~= targetReg ifTrue:
		[liveRegister := NoReg].
	^false
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
CogRegisterAllocatingSimStackEntry >> registerMaskOrNone [
	liveRegister ~= NoReg ifTrue:
		[^cogit registerMaskFor: liveRegister].
	^super registerMaskOrNone
]

{ #category : #accessing }
CogRegisterAllocatingSimStackEntry >> registerOrNone [
	liveRegister ~= NoReg ifTrue:
		[^liveRegister].
	^super registerOrNone
]

{ #category : #'compile abstract instructions' }
CogRegisterAllocatingSimStackEntry >> storeToReg: reg [
	liveRegister ~= NoReg
		ifTrue:
			[self deny: (type = SSRegister and: [register ~= liveRegister]).
			 reg ~= liveRegister
				ifTrue: [cogit MoveR: liveRegister R: reg]
				ifFalse: [cogit Label]]
		ifFalse:
			[type caseOf: {
				[SSBaseOffset]	-> [cogit MoveMw: offset r: register R: reg].
				[SSSpill]		-> [cogit MoveMw: offset r: register R: reg].
				[SSConstant]	-> [cogit genMoveConstant: constant R: reg].
				[SSRegister]	-> [reg ~= register
											ifTrue: [cogit MoveR: register R: reg]
											ifFalse: [cogit Label]] }].

	(reg ~= TempReg and: [liveRegister = NoReg and: [type ~= SSRegister]]) ifTrue:
		[liveRegister := reg.
		 cogit copyLiveRegisterToCopiesOf: self]
]
