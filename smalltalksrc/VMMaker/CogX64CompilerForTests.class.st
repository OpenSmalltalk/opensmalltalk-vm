Class {
	#name : #CogX64CompilerForTests,
	#superclass : #CogInLineLiteralsX64Compiler,
	#category : #'VMMaker-Tests'
}

{ #category : #'test support' }
CogX64CompilerForTests class >> dataRegistersWithAccessorsDo: aTrinaryBlock [
	self registers withIndexDo:
		[:reg :i|
		aTrinaryBlock
			value: reg
			value: (#(rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r10 r11 r12 r13 r14 r15) at: i)
			value: (#(rax: rcx: rdx: rbx: rsp: rbp: rsi: rdi:  r8: r9: r10: r11: r12: r13: r14: r15:) at: i)]
]

{ #category : #'test support' }
CogX64CompilerForTests class >> dataRegistersWithAccessorsExcept: accessorsToExclude do: aTrinaryBlock [
	self registers withIndexDo:
		[:reg :i| | getter setter |
		getter := #(rax rcx rdx rbx rsp rbp rsi rdi r8 r9 r10 r11 r12 r13 r14 r15) at: i.
		setter := #(rax: rcx: rdx: rbx: rsp: rbp: rsi: rdi:  r8: r9: r10: r11: r12: r13: r14: r15:) at: i.
		(accessorsToExclude includes: getter) ifFalse:
			[aTrinaryBlock value: reg value: getter value: setter]]
]

{ #category : #'test support' }
CogX64CompilerForTests class >> fp64RegistersWithAccessorsDo: aTrinaryBlock [
	self fp64registers withIndexDo:
		[:reg :i|
		aTrinaryBlock
			value: reg
			value: (#(xmm0low xmm1low xmm2low xmm3low xmm4low xmm5low xmm6low xmm7low) at: i)
			value: (#(xmm0low: xmm1low: xmm2low: xmm3low: xmm4low: xmm5low: xmm6low: xmm7low:) at: i)]
]

{ #category : #'test support' }
CogX64CompilerForTests class >> fp64registers [
	^{ DPFPReg0. DPFPReg1. DPFPReg2. DPFPReg3. DPFPReg4. DPFPReg5. DPFPReg6. DPFPReg7 } "a.k.a. (-9 to: -16 by: -1)"
]

{ #category : #'test support' }
CogX64CompilerForTests class >> registers [
	^(0 to: 15) "a.k.a. { RAX. RCX. RDX. RBX. RSP. RBP. RSI. RDI. R8. R9. R10. R11. R12. R13. R14. R15 }"
]

{ #category : #'test support' }
CogX64CompilerForTests class >> registersWithNamesDo: aBinaryBlock [
	self registers
		with: #('%rax' '%rcx' '%rdx' '%rbx' '%rsp' '%rbp' '%rsi' '%rdi' '%r8' '%r9' '%r10' '%r11' '%r12' '%r13' '%r14' '%r15')
		do: aBinaryBlock
]

{ #category : #'test support' }
CogX64CompilerForTests class >> xmmRegistersWithNamesDo: aBinaryBlock [
	{XMM0L. XMM1L. XMM2L. XMM3L. XMM4L. XMM5L. XMM6L. XMM7L}
		with: #('%xmm0' '%xmm1' '%xmm2' '%xmm3' '%xmm4' '%xmm5' '%xmm6' '%xmm7')
		do: aBinaryBlock
]

{ #category : #encoding }
CogX64CompilerForTests >> concreteRegister: value [
	^value
]

{ #category : #'generate machine code' }
CogX64CompilerForTests >> concretizeAt: actualAddress [
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

{ #category : #testing }
CogX64CompilerForTests >> hasSSE2Instructions [
	"Answer if we support SSE2"
	^true
]
