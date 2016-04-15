"
This is a subclass that uses CPUID to serialize instruction modification.  This is not needed with Intel processors on systems where code and data have the same linear address, hence Cog uses the superclass by default.
"
Class {
	#name : #CogICacheFlushingIA32Compiler,
	#superclass : #CogIA32Compiler,
	#category : 'VMMaker-JIT'
}

{ #category : #'inline cacheing' }
CogICacheFlushingIA32Compiler >> flushICacheFrom: startAddress "<Integer>" to: endAddress [ "<Integer>"
	<cmacro: '(me,startAddress,endAddress) ceFlushICache(startAddress,endAddress)'>
	self halt: #ceFlushICache
]

{ #category : #'inline cacheing' }
CogICacheFlushingIA32Compiler >> generateICacheFlush [
	"Use CPUID as a serializing instruction for instruction modification.
	 MFENCE doesn't work which is a shame because CPUID updates registers."
	cogit
		PushR: EDX;
		PushR: ECX;
		PushR: EBX;
		XorR: EAX R: EAX;
		gen: CPUID;
		PopR: EBX;
		PopR: ECX;
		PopR: EDX;
		RetN: 8 "pop from,to args"

	"self hasSSE2Instructions
		ifTrue:
			[cogit
				gen: MFENCE]
		ifFalse:
			[cogit
				PushR: EDX;
				PushR: ECX;
				PushR: EBX;
				XorR: EAX R: EAX;
				gen: CPUID;
				PopR: EBX;
				PopR: ECX;
				PopR: EDX].
	cogit RetN: 8 ``pop from,to args''"
]

{ #category : #'inline cacheing' }
CogICacheFlushingIA32Compiler >> numICacheFlushOpcodes [
	^10
]
