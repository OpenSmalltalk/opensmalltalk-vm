Class {
	#name : #CogARMCompilerForTests,
	#superclass : #CogInLineLiteralsARMCompiler,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #'test support' }
CogARMCompilerForTests class >> dataRegistersWithAccessorsDo: aTrinaryBlock [
	"r0 ... sp. We can't use pc or RISCTempReg, because some opcodes may be encoded as multiple instructions and this, we need to be able to step."
	#(0 1 2 3 4 5 6 7 8 9 11 12 13 14) withIndexDo:
		[:reg :i|
		aTrinaryBlock
			value: reg
			value: (#(r0 r1 r2 r3 r4 r5 r6 r7 r8 r9 fp r12 sp lr) at: i)
			value: (#(r0: r1: r2: r3: r4: r5: r6: r7: r8: r9: fp: r12: sp: lr:) at: i)]
]

{ #category : #'test support' }
CogARMCompilerForTests class >> fp64RegistersWithAccessorsDo: aBlock [
	"there are none, because we do not support VFP, yet"
]

{ #category : #'test support' }
CogARMCompilerForTests class >> registers [
	^0 to: 15 "a.k.a. { R0. R1. R2. R3. R4. R5. R6. R7. R8. R9. R10. R11. R12. SP. LR. PC }"
]

{ #category : #'test support' }
CogARMCompilerForTests class >> registersWithNamesDo: aBinaryBlock [
	self registers
		with: #('r0' 'r1' 'r2' 'r3' 'r4' 'r5' 'r6' 'r7' 'r8' 'r9' 'sl' 'fp' 'ip' 'sp' 'lr' 'pc')
		do: aBinaryBlock
]

{ #category : #'generate machine code' }
CogARMCompilerForTests >> concretizeAt: actualAddress [
	"Override to check maxSize and machineCodeSize"

	| result |
	maxSize ifNil: [maxSize := self computeMaximumSize].
	result := super concretizeAt: actualAddress.
	self assert: (maxSize notNil
				and: [self isPCDependent
						ifTrue: [maxSize >= machineCodeSize]
						ifFalse: [maxSize = machineCodeSize]]).
	^result
]
