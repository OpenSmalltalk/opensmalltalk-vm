Extension { #name : #Integer }

{ #category : #'*VMMaker-bit manipulation' }
Integer >> >>> shiftAmount [  "right shift, but causes CCodeGenerator to generate a signed shift"
	shiftAmount < 0 ifTrue: [self error: 'negative arg'].
	^self bitShift: 0 - shiftAmount
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asLong [
	^self
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asPositiveIntegerObj [
	"This is a SmartSyntaxPlugin convenience, invented with little thought for simulation (grrr).
	  In the VM this is equivalent to
		interpreterProxy methodReturnValue: (interpreterProxy positive32BitIntegerFor: self)
	 but if a plugin is being developed I /think/ it is just
		^self
	 So search the stack to discover what context it is being used in."
	(thisContext findContextSuchThat: [:ctxt| ctxt receiver isInterpreterPlugin]) ifNotNil:
		[:ctxt| | interpreter |
		interpreter := ctxt receiver getInterpreter.
		interpreter methodReturnValue: (interpreter positive32BitIntegerFor: self)].
	^self
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asUnsignedInteger [
	self assert: self >= 0.
	^self
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asUnsignedLong [
	self assert: self >= 0.
	^self
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asVoidPointer [
	^self
]

{ #category : #'*VMMaker-bit manipulation' }
Integer >> bitInvert64 [
	"Answer the 64-bit complement of the receiver."

	^self bitXor: 16rFFFFFFFFFFFFFFFF
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> coerceTo: cTypeString sim: interpreter [

	| unitSize |
	cTypeString last = $* ifTrue: [  "C pointer"
		unitSize := cTypeString caseOf: {
		['char *'] -> [1].
		['short *'] -> [2].
		['int *'] -> [4].
		['long *'] -> [interpreter wordSize].
		['float *'] -> [4].
		['double *'] -> [8].
		['unsigned *'] -> [4].
		['oop *'] -> [interpreter bytesPerOop].
		}
		otherwise: [ (cTypeString beginsWith: 'char') ifTrue: [1] ifFalse: [interpreter wordSize] ].
		^(CArray basicNew)
			interpreter: interpreter address: self unitSize: unitSize;
			yourself.
	].
	^ self  "C number (int, char, float, etc)"
]

{ #category : #'*VMMaker-printing' }
Integer >> hex8 [
	"Print the receiver in base 16 with prefixed base, using at least 8 digits.
	 DO NOT CHANGE THIS!  The Cog VMMaker depends on this.
	 Consider using storeStringBase: 16 length: 11 padded: true instead."
	  "16r3333 hex8"
	| hex |
	hex := self hex.  "16rNNN"
	^hex size < 11
		ifTrue: [hex copyReplaceFrom: 4 to: 3
						 with: ('00000000' copyFrom: 1 to: 11-hex size)]
		ifFalse: [hex]
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedBitShift: anInteger [
	"For historical reasons Slang generates an unsigned shift from all of the shift operators >>, << & bitShift:.
	 These are too deeply entrenched to try and redefine the semantics.  So instead we provide a signed bitShift:
	 that signals to Slang that its argument should be cast to signed, not to unsigned, when being shifted."
	^self bitShift: anInteger
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntFromLong [
	"Self is a signed or unsigned 32-bit integer"

	| sign |
	self < 0 ifTrue: [^self].
	sign := self bitAnd: 16r80000000.
	sign = 0 ifTrue: [^ self].
	^ self - sign - sign
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntFromLong64 [
	"Self is a signed or unsigned 64-bit integer"

	| sign |
	self < 0 ifTrue: [^self].
	sign := self bitAnd: 16r8000000000000000.
	sign = 0 ifTrue: [^self].
	^self - sign - sign
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntFromShort [
	"Self is an unsigned 16-bit integer in twos-comp form"

	| shortBits |
	shortBits := self bitAnd: 16rFFFF.
	^(self bitAnd: 16r8000) "sign bit" = 0
		ifTrue: [shortBits]
		ifFalse: [shortBits - 16r10000]
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntToLong [
	"Produces a 32-bit value in twos-comp form.  Sorry no error checking"

	self >= 0
		ifTrue: [^ self]
		ifFalse: [^ self + 16r80000000 + 16r80000000]

]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntToLong64 [
	"Produces a 64-bit value in twos-comp form.  Sorry no error checking"

	self >= 0
		ifTrue: [^ self]
		ifFalse: [^ self + 16r8000000000000000 + 16r8000000000000000]

]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntToShort [
	"Produces a 16-bit value (0-65k) in twos-comp form.  Sorry no error checking"

	^self bitAnd: 16rFFFF
]
