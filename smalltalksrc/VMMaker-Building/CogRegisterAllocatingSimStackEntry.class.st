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
	"(bo ReceiverResultReg+296 (live: Extra5Reg) {88} vs reg ReceiverResultReg {84}"
	((type = SSConstant and: [targetEntry type = SSRegister and: [liveRegister ~= targetEntry registerOrNone]])
	 or: [(type = SSRegister and: [targetEntry type = SSRegister and: [register ~= targetEntry registerOrNone]])
	 or: [type = SSBaseOffset and: [register = ReceiverResultReg and: [targetEntry type = SSRegister]]]]) ifFalse:
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
CogRegisterAllocatingSimStackEntry >> reconcileBackwardsWith: targetEntry [
	"Make the state of the receiver, a stack entry at a backward jump,
	 the same as the corresponding simStackEntry at the target of the jump"
	<var: #targetEntry type: #'SimStackEntry *'>
	| targetReg |
	(targetReg := targetEntry registerOrNone) = NoReg ifTrue:
		[^self].
	targetEntry type = SSConstant ifTrue:
		[self assert: (type = SSConstant and: [constant = targetEntry constant]).
		 ^self].
	liveRegister ~= NoReg ifTrue:
		[liveRegister ~= targetReg ifTrue:
			[cogit MoveR: liveRegister R: targetReg].
		 ^self].
	type caseOf: {
		[SSBaseOffset]	-> [cogit MoveMw: offset r: register R: targetReg].
		[SSSpill]		-> [cogit MoveMw: offset r: register R: targetReg].
		[SSConstant]	-> [cogit genMoveConstant: constant R: targetReg].
		[SSRegister]	-> [register ~= targetReg ifTrue:
								[cogit MoveR: register R: targetReg]] }
]

{ #category : #'compile abstract instructions' }
CogRegisterAllocatingSimStackEntry >> reconcileForwardsWith: targetEntry [
	"Make the state of the receiver, a stack entry at the end of a basic block,
	 the same as the corresponding simStackEntry at the target of a preceding
	 jump to the beginning of the next basic block.  Make sure targetEntry
	 reflects the state of the merged simStack; it will be installed as the current
	 entry by restoreSimStackAtMergePoint: in mergeWithFixupIfRequired:.

	 Answer if the liveRegister for the targetEntry (if any) should be deassigned;
	 this is because if merging a non-temp with a temp that has a live register we
	 can assign to the register, but must unassign the register from the temp,
	 otherwise the temp will acquire the merged value without an assignment."
	<var: #targetEntry type: #'SimStackEntry *'>
	| targetReg |
	(targetReg := targetEntry registerOrNone) = NoReg ifTrue:
		[| reg |
		 self assert: targetEntry spilled.
		 (self isSameEntryAs: targetEntry) ifTrue:
			[self assert: spilled.
			 ^false].
		 (reg := self registerOrNone) = NoReg ifTrue: [reg := TempReg].
		 self storeToReg: reg.
		 spilled
			ifTrue: [cogit MoveR: reg Mw: targetEntry offset r: targetEntry register]
			ifFalse: [cogit PushR: reg].
		 ^false].
	liveRegister ~= NoReg ifTrue:
		[liveRegister ~= targetReg ifTrue:
			[cogit MoveR: liveRegister R: targetReg].
		 (spilled and: [targetEntry spilled not]) ifTrue:
			[cogit AddCq: objectRepresentation wordSize R: SPReg].
		 ^false].
	spilled
		ifTrue:
			[targetEntry spilled ifFalse:
				[cogit PopR: targetReg. "KISS; generate the least number of instructions..."
				 ^false]]
		ifFalse:
			[targetEntry spilled ifTrue:
				[cogit SubCq: objectRepresentation wordSize R: SPReg]].
	type caseOf: {
		[SSBaseOffset]	-> [cogit MoveMw: offset r: register R: targetReg].
		[SSSpill]		-> [cogit MoveMw: offset r: register R: targetReg].
		[SSConstant]	-> [cogit genMoveConstant: constant R: targetReg].
		[SSRegister]	-> [register ~= targetReg ifTrue:
								[cogit MoveR: register R: targetReg]] }.
	(targetEntry type = SSConstant
	 and: [type ~= SSConstant or: [constant ~= targetEntry constant]]) ifTrue:
		[targetEntry
			register: targetReg;
			type: SSRegister].
	"If merging a constant with a constant assigned to a register, then the register must be deassigned from any temps."
	^targetEntry type = SSConstant
	"If merging a non-temp with a temp that has a live register we can assign
	 to the register, but must unassign the register from the temp, otherwise
	 the temp will acquire the merged value without an assignment."
	 or: [targetEntry isFrameTempVar and: [(self isSameEntryAs: targetEntry) not]]
]

{ #category : #'compile abstract instructions' }
CogRegisterAllocatingSimStackEntry >> reconcilePoppingWith: targetEntry [
	"Make the state of a targetEntry, a stack entry following a non-inlined special selector
	 send, the same as the corresponding entry (the receiver) along the inlined path."
	<var: #targetEntry type: #'SimStackEntry *'>
	| targetReg |
	spilled = targetEntry spilled ifTrue:
		[self assert: ((self isSameEntryAs: targetEntry)
					 or: [targetEntry spilled not and: [targetEntry registerOrNone ~= NoReg]]).
		 (targetReg := targetEntry registerOrNone) = NoReg ifTrue:
			[^self].
		 type caseOf: {
				[SSBaseOffset]	-> [cogit MoveMw: offset r: register R: targetReg].
				[SSSpill]		-> [cogit MoveMw: offset r: register R: targetReg].
				[SSConstant]	-> [cogit genMoveConstant: constant R: targetReg].
				[SSRegister]	-> [targetReg ~= register ifTrue:
										[cogit MoveR: register R: targetReg]] }.
		 ^self].
	self assert: spilled.
	(targetEntry type ~= SSConstant
	 and: [(targetReg := targetEntry registerOrNone) ~= NoReg])
		ifTrue: [cogit PopR: targetReg]
		ifFalse: [cogit AddCq: objectRepresentation wordSize R: SPReg]
]

{ #category : #'compile abstract instructions' }
CogRegisterAllocatingSimStackEntry >> reconcilePushingWith: targetEntry [
	"Make the state of the receiver, a stack entry at the end of a basic block,
	 the same as the corresponding simStackEntry at the target of a preceding
	 jump to the beginning of the next basic block.  Make sure targetEntry
	 reflects the state of the merged simStack; it will be installed as the current
	 entry by restoreSimStackAtMergePoint: in mergeWithFixupIfRequired:.

	 Answer if the liveRegister for the targetEntry (if any) should be deassigned;
	 this is because if merging a non-temp with a temp that has a live register we
	 can assign to the register, but must unassign the register from the temp,
	 otherwise the temp will acquire the merged value without an assignment."
	<var: #targetEntry type: #'SimStackEntry *'>
	| targetReg |
	(targetReg := targetEntry registerOrNone) = NoReg ifTrue:
		[| reg |
		 self assert: targetEntry spilled.
		 (self isSameEntryAs: targetEntry) ifTrue:
			[self assert: spilled.
			 ^false].
		 (reg := self registerOrNone) = NoReg ifTrue: [reg := TempReg].
		 self storeToReg: reg.
		 spilled
			ifTrue: [cogit MoveR: reg Mw: targetEntry offset r: targetEntry register]
			ifFalse: [cogit PushR: reg].
		 ^false].
	liveRegister ~= NoReg ifTrue:
		[liveRegister ~= targetReg ifTrue:
			[cogit MoveR: liveRegister R: targetReg].
		 (spilled and: [targetEntry spilled not]) ifTrue:
			[cogit AddCq: objectRepresentation wordSize R: SPReg].
		 ^false].
	spilled
		ifTrue:
			[targetEntry spilled ifFalse:
				[cogit PopR: targetReg. "KISS; generate the least number of instructions..."
				 ^false]]
		ifFalse:
			[targetEntry spilled ifTrue:
				[cogit SubCq: objectRepresentation wordSize R: SPReg]].
	type caseOf: {
		[SSBaseOffset]	-> [cogit MoveMw: offset r: register R: targetReg].
		[SSSpill]		-> [cogit MoveMw: offset r: register R: targetReg].
		[SSConstant]	-> [cogit genMoveConstant: constant R: targetReg].
		[SSRegister]	-> [register ~= targetReg ifTrue:
								[cogit MoveR: register R: targetReg]] }.
	(targetEntry type = SSConstant
	 and: [type ~= SSConstant or: [constant ~= targetEntry constant]]) ifTrue:
		[targetEntry
			register: targetReg;
			type: SSRegister].
	"If merging a constant with a constant assigned to a register, then the register must be deassigned from any temps."
	^targetEntry type = SSConstant
	"If merging a non-temp with a temp that has a live register we can assign
	 to the register, but must unassign the register from the temp, otherwise
	 the temp will acquire the merged value without an assignment."
	 or: [targetEntry isFrameTempVar and: [(self isSameEntryAs: targetEntry) not]]
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
