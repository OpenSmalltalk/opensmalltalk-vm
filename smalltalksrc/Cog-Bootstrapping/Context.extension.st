Extension { #name : #Context }

{ #category : #'*Cog-Tests-xrays' }
Context >> xray [
	"Lift the veil from a context and answer an integer describing its interior state.
	 Used for e.g. VM tests so they can verify they're testing what they think they're testing.
	 0 implies a vanilla heap context.
	 Bit 0 = is or was married to a frame
	 Bit 1 = is still married to a frame
	 Bit 2 = frame is executing machine code
	 Bit 3 = has machine code pc (as opposed to nil or a bytecode pc)
	 Bit 4 = method is currently compiled to machine code"
	<primitive: 213>
	^0 "Can only fail if unimplemented; therefore simply answer 0"
]

{ #category : #'*Cog-Tests-xrays' }
Context >> xrayIsDivorced [
	^(self xray bitAnd: 3) = 1
]

{ #category : #'*Cog-Tests-xrays' }
Context >> xrayIsExecutingMachineCode [
	^self xray anyMask: 4
]

{ #category : #'*Cog-Tests-xrays' }
Context >> xrayIsMarried [
	^self xray anyMask: 2
]

{ #category : #'*Cog-Tests-xrays' }
Context >> xrayLastExecutedMachineCode [
	^self xray anyMask: 8
]

{ #category : #'*Cog-Tests-xrays' }
Context >> xrayMethodIsCompiledToMachineCode [
	^self xray anyMask: 16
]
