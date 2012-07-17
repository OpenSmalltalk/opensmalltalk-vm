Class {
	#name : #CogARMCompilerForTests,
	#superclass : #CogARMCompiler,
	#category : #'VMMaker-Tests'
}

{ #category : #'test support' }
CogARMCompilerForTests class >> registers [
	^{ R0. R1. R2. R3. R4. R5. R6. R7. R8. R9. R10. R11. R12. SP. LR. PC } "a.k.a. (0 to: 15)"
]

{ #category : #'test support' }
CogARMCompilerForTests class >> registersWithNamesDo: aBinaryBlock [
	self registers
		with: #('r0' 'r1' 'r2' 'r3' 'r4' 'r5' 'r6' 'r7' 'r8' 'r9' 'r10' 'fp' 'r12' 'sp' 'lr' 'pc')
		do: aBinaryBlock
]
