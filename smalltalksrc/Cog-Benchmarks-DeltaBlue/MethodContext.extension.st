Extension { #name : #MethodContext }

{ #category : #'*Cog-method prototypes' }
MethodContext >> MethodContextPROTOTYPEfailPrimitiveWith: maybePrimFailToken [
	"The receiver is a freshly-created context on a primitive method.  Skip the callPrimitive:
	 bytecode and store the primitive fail code if there is one and the method consumes it."
	self skipCallPrimitive.
	((self isPrimFailToken: maybePrimFailToken)
	  and: [method encoderClass isStoreAt: pc in: method]) ifTrue:
		[self at: stackp put: maybePrimFailToken last]
]

{ #category : #'*Cog-Tests-xrays' }
MethodContext >> xray [
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
MethodContext >> xrayIsDivorced [
	^(self xray bitAnd: 3) = 1
]

{ #category : #'*Cog-Tests-xrays' }
MethodContext >> xrayIsExecutingMachineCode [
	^self xray anyMask: 4
]

{ #category : #'*Cog-Tests-xrays' }
MethodContext >> xrayIsMarried [
	^self xray anyMask: 2
]

{ #category : #'*Cog-Tests-xrays' }
MethodContext >> xrayLastExecutedMachineCode [
	^self xray anyMask: 8
]

{ #category : #'*Cog-Tests-xrays' }
MethodContext >> xrayMethodIsCompiledToMachineCode [
	^self xray anyMask: 16
]
