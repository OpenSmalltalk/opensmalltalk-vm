Class {
	#name : #CogIA32CompilerForTests,
	#superclass : #CogIA32Compiler,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #'test support' }
CogIA32CompilerForTests class >> byteRegistersWithNamesDo: aBinaryBlock [
	(self registers first: 4)
		with: #('%al' '%cl' '%dl' '%bl')
		do: aBinaryBlock
]

{ #category : #'test support' }
CogIA32CompilerForTests class >> dataRegistersWithAccessorsDo: aTrinaryBlock [
	self registers withIndexDo:
		[:reg :i|
		aTrinaryBlock
			value: reg
			value: (#(eax ecx edx ebx esp ebp esi edi) at: i)
			value: (#(eax: ecx: edx: ebx: esp: ebp: esi: edi:) at: i)]
]

{ #category : #'test support' }
CogIA32CompilerForTests class >> dataRegistersWithAccessorsExcept: accessorsToExclude do: aTrinaryBlock [
	self registers withIndexDo:
		[:reg :i| | getter setter |
		getter := #(eax ecx edx ebx esp ebp esi edi) at: i.
		setter := #(eax: ecx: edx: ebx: esp: ebp: esi: edi:) at: i.
		(accessorsToExclude includes: getter) ifFalse:
			[aTrinaryBlock value: reg value: getter value: setter]]
]

{ #category : #'test support' }
CogIA32CompilerForTests class >> fp64RegistersWithAccessorsDo: aTrinaryBlock [
	self fp64registers withIndexDo:
		[:reg :i|
		aTrinaryBlock
			value: reg
			value: (#(xmm0low xmm1low xmm2low xmm3low xmm4low xmm5low xmm6low xmm7low) at: i)
			value: (#(xmm0low: xmm1low: xmm2low: xmm3low: xmm4low: xmm5low: xmm6low: xmm7low:) at: i)]
]

{ #category : #'test support' }
CogIA32CompilerForTests class >> fp64registers [
	^{ DPFPReg0. DPFPReg1. DPFPReg2. DPFPReg3. DPFPReg4. DPFPReg5. DPFPReg6. DPFPReg7 } "a.k.a. (-9 to: -16 by: -1)"
]

{ #category : #'test support' }
CogIA32CompilerForTests class >> registers [
	^(0 to: 7) "a.k.a. { EAX. ECX. EDX. EBX. ESP. EBP. ESI. EDI }"
]

{ #category : #'test support' }
CogIA32CompilerForTests class >> registersWithNamesDo: aBinaryBlock [
	self registers
		with: #('%eax' '%ecx' '%edx' '%ebx' '%esp' '%ebp' '%esi' '%edi')
		do: aBinaryBlock
]

{ #category : #'test support' }
CogIA32CompilerForTests class >> xmmRegistersWithNamesDo: aBinaryBlock [
	{XMM0L. XMM1L. XMM2L. XMM3L. XMM4L. XMM5L. XMM6L. XMM7L}
		with: #('%xmm0' '%xmm1' '%xmm2' '%xmm3' '%xmm4' '%xmm5' '%xmm6' '%xmm7')
		do: aBinaryBlock
]

{ #category : #'generate machine code' }
CogIA32CompilerForTests >> concretizeAt: actualAddress [
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
CogIA32CompilerForTests >> hasSSE2Instructions [
	"Answer if we support SSE2"
	^true
]
