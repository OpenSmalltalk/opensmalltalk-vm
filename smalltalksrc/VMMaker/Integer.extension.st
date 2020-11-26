Extension { #name : #Integer }

{ #category : #'*VMMaker-bit manipulation' }
Integer >> >>> shiftAmount [  "right shift, but causes CCodeGenerator to generate a signed shift"
	shiftAmount < 0 ifTrue: [self error: 'negative arg'].
	^self bitShift: 0 - shiftAmount
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> addBreakpoint: address [
	^{self. address}
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asC_int [
	^self >= 0
		ifTrue: [self bitAnd: 16rFFFFFFFF]
		ifFalse: [(self bitAnd: 16rFFFFFFFF) - 16r100000000]
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asC_unsigned_int [
	^self bitAnd: 16rFFFFFFFF
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asCharPtr [
	^(Notification new tag: #getInterpreter; signal)
		ifNotNil: [:interpreter|
				(interpreter firstIndexableField: self) asInteger
					coerceTo: #'char *'
					sim: interpreter]
		ifNil: [self]
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asIntegerPtr [
	^self
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
Integer >> asSmallIntegerObj [
	^(Notification new tag: #getInterpreter; signal)
		ifNotNil: [:interpreter| interpreter integerObjectOf: self]
		ifNil: [self]
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asUnsignedInteger [
	"Since the simulator deals with positive integers most of the time we assert that the receiver is greater than zero.
	 But one major exception is stack pointers in the StackInterpreterSimulator, which are negative.  So don't fail
	 if the sender is a StackInterpreter and the receiver could be a stack pointer."
	self >= 0 ifFalse:
		[self assert: (((thisContext sender methodClass includesBehavior: CoInterpreter)
					   and: [self between: Cogit maxNegativeErrorCode and: -1])
					or: [(thisContext sender methodClass includesBehavior: StackInterpreter)
					   and: [thisContext sender receiver stackPages couldBeFramePointer: self]])].
	^self
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asUnsignedIntegerPtr [
	"Since the simulator deals with positive integers most of the time we assert that the receiver is greater than zero.
	 But one major exception is stack pointers in the StackInterpreterSimulator, which are negative.  So don't fail
	 if the sender is a StackInterpreter and the receiver could be a stack pointer."
	self >= 0 ifFalse:
		[self assert: ((thisContext sender methodClass includesBehavior: StackInterpreter)
					and: [thisContext sender receiver stackPages couldBeFramePointer: self])].
	^self
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asUnsignedLong [
	self assert: self >= 0.
	^self
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> asUnsignedLongLong [
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

{ #category : #'*VMMaker-bit manipulation' }
Integer >> byteSwap32 [
	"swap the bytes of a 32 bit unsigned integer"
	
	^((self << 24) bitAnd: 16rFF000000) bitOr:
	  (((self << 8) bitAnd: 16rFF0000) bitOr:
	  (((self >> 8) bitAnd: 16rFF00) bitOr:
	  (((self >> 24) bitAnd: 16rFF))))
]

{ #category : #'*VMMaker-bit manipulation' }
Integer >> byteSwap64 [
	"swap the bytes of a 64 bit unsigned integer"
	
	^(((self << 56) bitAnd: 16rFF00000000000000) bitOr:
	  (((self << 40) bitAnd: 16rFF000000000000) bitOr:
	  (((self << 24) bitAnd: 16rFF0000000000) bitOr:
	  (((self << 8) bitAnd: 16rFF00000000) bitOr:
	  (((self >> 8) bitAnd: 16rFF000000) bitOr:
	  (((self >> 24) bitAnd: 16rFF0000) bitOr:
	  (((self >> 40) bitAnd: 16rFF00) bitOr:
	  ((self >> 56) bitAnd: 16rFF))))))))
]

{ #category : #'*VMMaker-plugin generation' }
Integer class >> ccg: cg prolog: aBlock expr: aString index: anInteger [

	^cg ccgLoad: aBlock expr: aString asKindOfIntegerFrom: anInteger
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> coerceTo: cTypeString sim: interpreter [

	| unitSize |
	cTypeString last = $* ifTrue:  "C pointer"
		[unitSize := cTypeString caseOf: {
		[#'char *'] -> [1].
		[#'short *'] -> [2].
		[#'int *'] -> [4].
		[#'long long *'] -> [8].
		[#'float *'] -> [^CFloatArray basicNew interpreter: interpreter address: self unitSize: 4; yourself].
		[#'double *'] -> [^CFloatArray basicNew interpreter: interpreter address: self unitSize: 8; yourself].
		[#'unsigned *'] -> [4].
		[#'unsigned int *'] -> [4].
		[#'unsigned char *'] -> [1].
		[#'signed char *'] -> [1].
		[#'unsigned short *'] -> [2].
		[#'unsigned long long *'] -> [8].
		[#'oop *'] -> [interpreter objectMemory bytesPerOop].
		}
		otherwise: [interpreter objectMemory wordSize].
		^CArray basicNew
			interpreter: interpreter address: self unitSize: unitSize;
			yourself].
	^self  "C number (int, char, float, etc)"
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
Integer >> isActiveBreakpoint [
	^true
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> isBreakpointFor: address [
	^self = address
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> menuPrompt [
	^' (', self hex, ')'
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> removeBreakpoint: address [
	^nil
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedBitShift: anInteger [
	"For historical reasons Slang generates an unsigned shift from all of the shift operators >>, << & bitShift:.
	 These are too deeply entrenched to try and redefine the semantics.  So instead we provide a signed bitShift:
	 that signals to Slang that its argument should be cast to signed, not to unsigned, when being shifted."
	^self bitShift: anInteger
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntFromChar [
	"Self is an unsigned 8-bit integer in twos-comp form"

	| shortBits |
	shortBits := self bitAnd: 16rFF.
	^(self bitAnd: 16r80) "sign bit" = 0
		ifTrue: [shortBits]
		ifFalse: [shortBits - 16r100]
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntFromLong [
	"Self is a signed or unsigned 32-bit integer"

	| bits |
	(self >= -1073741824 and: [self <= 1073741823]) ifTrue: "These are known to be SmallIntegers..."
		[^self].
	bits := self bitAnd: 16rFFFFFFFF.
	(bits byteAt: 4) <= 16r7F ifTrue: [^bits].
	^bits - 16r100000000
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntFromLong64 [
	"Self is a signed or unsigned 64-bit integer"

	| bits |
	"This case is handled by the SmallInteger subclass..."
	"(self >= -1073741824 and: [self <= 1073741823]) ifTrue:
		[^self]."
	bits := self bitAnd: 16rFFFFFFFFFFFFFFFF.
	(bits byteAt: 8) <= 16r7F ifTrue: [^bits].
	^bits - 16r10000000000000000
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
Integer >> signedIntToChar [
	"Produces an 8-bit value in twos-comp form. Truncates if out-of-range as per a C cast"

	^self bitAnd: 16rFF
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntToLong [
	"Produces a 32-bit value in twos-comp form. Truncates if out-of-range as per a C cast"

	^self bitAnd: 16rFFFFFFFF
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntToLong64 [
	"Produces a 64-bit value in twos-comp form. Truncates if out-of-range as per a C cast"

	^self bitAnd: 16rFFFFFFFFFFFFFFFF
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> signedIntToShort [
	"Produces a 16-bit value in twos-comp form. Truncates if out-of-range as per a C cast"

	^self bitAnd: 16rFFFF
]

{ #category : #'*VMMaker-interpreter simulator' }
Integer >> singleStepRequiredToTriggerIn: aCogit [
	^self between: aCogit cogCodeBase and: aCogit methodZone limitZony
]

{ #category : #'*VMMaker' }
Integer >> twoComplementOfBitSize: aBitSize [

	| mask result |

	self >= 0 ifTrue: [ ^ self ].
	
	mask := (1 << aBitSize) - 1.
	result := mask - self abs + 1.
	
	(result < 0 or: [ result > mask ]) 
		ifTrue: [ self error: 'The number does not fit in the required size' ].
	
	
	^ result.
]
