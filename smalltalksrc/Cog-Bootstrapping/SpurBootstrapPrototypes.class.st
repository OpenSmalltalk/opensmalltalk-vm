Class {
	#name : #SpurBootstrapPrototypes,
	#superclass : #Object,
	#category : #'Cog-Bootstrapping'
}

{ #category : #accessing }
SpurBootstrapPrototypes class >> imageType [ 
	^ self subclassResponsibility
]

{ #category : #'instance creation' }
SpurBootstrapPrototypes class >> prototypesFor: type [ 
	^ (self allSubclasses 
		detect: [ :aClass | aClass imageType = type ])
		new
	
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEallInstances [
	"Answer all instances of the receiver."
	<primitive: 177>
	"The primitive can fail because memory is low.  If so, fall back on the old
	 enumeration code, which gives the system a chance to GC and/or grow.
	 Because aBlock might change the class of inst (for example, using become:),
	 it is essential to compute next before aBlock value: inst."
	| inst insts next |
	insts := WriteStream on: (Array new: 64).
	inst := self someInstance.
	[inst == nil] whileFalse:
		[next := inst nextInstance.
		 (inst == insts or: [inst == insts originalContents]) ifFalse: [insts nextPut: inst].
		 inst := next].
	^insts contents
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEallInstancesDo: aBlock [
	"Evaluate aBlock with each of the current instances of the receiver."
	| instances inst next |
	instances := self allInstancesOrNil.
	instances ifNotNil:
		[instances do: aBlock.
		 ^self].
	"allInstancesOrNil can fail because memory is low.  If so, fall back on the old
	 enumeration code.  Because aBlock might change the class of inst (for example,
	 using become:), it is essential to compute next before aBlock value: inst."
	inst := self someInstance.
	[inst == nil] whileFalse:
		[next := inst nextInstance.
		 aBlock value: inst.
		 inst := next]
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEallInstancesOrNil [
	"Answer all instances of the receiver, or nil if the primitive
	 fails, which it may be due to being out of memory."
	<primitive: 177>
	^nil
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEbasicNew [
	"Primitive. Answer an instance of the receiver (which is a class) with no 
	 indexable variables. Fail if the class is indexable. Essential. See Object 
	 documentation whatIsAPrimitive.
	
	 If the primitive fails because space is low then the scavenger will run
	 before the method is activated.  Check that space was low and retry
	 via handleFailingBasicNew if so."

	<primitive: 70 error: ec>
	ec == #'insufficient object memory' ifTrue:
		[^self handleFailingBasicNew].
	self isVariable ifTrue: [^self basicNew: 0].
	self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEbasicNew: sizeRequested [
	"Primitive. Answer an instance of this class with the number of indexable
	 variables specified by the argument, sizeRequested.  Fail if this class is not
	 indexable or if the argument is not a positive Integer, or if there is not
	 enough memory available. Essential. See Object documentation whatIsAPrimitive.
	
	 If the primitive fails because space is low then the scavenger will run before the
	 method is activated.  Check args and retry via handleFailingBasicNew: if they're OK."

	<primitive: 71 error: ec>
	ec == #'insufficient object memory' ifTrue:
		[^self handleFailingBasicNew: sizeRequested].
	self isVariable ifFalse:
		[self error: self printString, ' cannot have variable sized instances'].
	self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEbyteSizeOfInstance [
	"Answer the total memory size of an instance of the receiver."

	<primitive: 181 error: ec>
	self isVariable ifTrue:
		[^self byteSizeOfInstanceOfSize: 0].
	self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEbyteSizeOfInstanceOfSize: basicSize [
	"Answer the total memory size of an instance of the receiver
	 with the given number of indexable instance variables."

	<primitive: 181 error: ec>
	self isVariable
		ifTrue: "If the primitive overflowed answer a close approximation"
			[(basicSize isInteger
			  and: [basicSize >= 16r1000000]) ifTrue:
				[^2 * (self byteSizeOfInstanceOfSize: basicSize + 1 // 2)
				   - (self byteSizeOfInstanceOfSize: 0)]]
		ifFalse:
			[basicSize = 0 ifTrue:
				[^self byteSizeOfInstance]].
	self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEelementSize [
	"Answer the size in bytes of an element in the receiver.  The formats are
			0	= 0 sized objects (UndefinedObject True False et al)
			1	= non-indexable objects with inst vars (Point et al)
			2	= indexable objects with no inst vars (Array et al)
			3	= indexable objects with inst vars (MethodContext AdditionalMethodState et al)
			4	= weak indexable objects with inst vars (WeakArray et al)
			5	= weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
			6	= unused
			7	= immediates (SmallInteger, Character)
			8	= unused
			9	= 64-bit indexable
		10-11	= 32-bit indexable (Bitmap)
		12-15	= 16-bit indexable
		16-23	= 8-bit indexable
		24-31	= compiled methods (CompiledMethod)"
	| instSpec |
	instSpec := self instSpec.
	instSpec < 9 ifTrue: [^Smalltalk wordSize].
	instSpec >= 16 ifTrue: [^1].
	instSpec >= 12 ifTrue: [^2].
	instSpec >= 10 ifTrue: [^4].
	^8
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEhandleFailingBasicNew [
	"handleFailingBasicNew gets sent after basicNew has failed and allowed
	 a scavenging garbage collection to occur.  The scavenging collection
	 will have happened as the VM is activating the (failing) basicNew.  If
	 handleFailingBasicNew fails then the scavenge failed to reclaim sufficient
	 space and a global garbage collection is required.  Retry after garbage
	 collecting and growing memory if necessary.

	 Primitive. Answer an instance of this class with the number of indexable
	 variables specified by the argument, sizeRequested.  Fail if this class is not
	 indexable or if the argument is not a positive Integer, or if there is not
	 enough memory available. Essential. See Object documentation whatIsAPrimitive."

	<primitive: 70>
	Smalltalk garbageCollect < 1048576 ifTrue:
		[Smalltalk growMemoryByAtLeast: 1048576].
	^self handleFailingFailingBasicNew "retry after global garbage collect"
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEhandleFailingBasicNew: sizeRequested [
	"handleFailingBasicNew: gets sent after basicNew: has failed and allowed
	 a scavenging garbage collection to occur.  The scavenging collection
	 will have happened as the VM is activating the (failing) basicNew:.  If
	 handleFailingBasicNew: fails then the scavenge failed to reclaim sufficient
	 space and a global garbage collection is required.  Retry after garbage
	 collecting and growing memory if necessary.

	 Primitive. Answer an instance of this class with the number of indexable
	 variables specified by the argument, sizeRequested.  Fail if this class is not
	 indexable or if the argument is not a positive Integer, or if there is not
	 enough memory available. Essential. See Object documentation whatIsAPrimitive."

	<primitive: 71>
	| bytesRequested |
	bytesRequested := self byteSizeOfInstanceOfSize: sizeRequested.
	Smalltalk garbageCollect < bytesRequested ifTrue:
		[Smalltalk growMemoryByAtLeast: bytesRequested].
	"retry after global garbage collect and possible grow"
	^self handleFailingFailingBasicNew: sizeRequested
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEhandleFailingFailingBasicNew [
	"This basicNew gets sent after handleFailingBasicNew: has done a full
	 garbage collection and possibly grown memory.  If this basicNew fails
	 then the system really is low on space, so raise the OutOfMemory signal.

	 Primitive. Answer an instance of this class with the number of indexable
	 variables specified by the argument, sizeRequested.  Fail if this class is not
	 indexable or if the argument is not a positive Integer, or if there is not
	 enough memory available. Essential. See Object documentation whatIsAPrimitive."

	<primitive: 70>
	"space must be low"
	OutOfMemory signal.
	^self basicNew  "retry if user proceeds"
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEhandleFailingFailingBasicNew: sizeRequested [
	"This basicNew: gets sent after handleFailingBasicNew: has done a full
	 garbage collection and possibly grown memory.  If this basicNew: fails
	 then the system really is low on space, so raise the OutOfMemory signal.

	 Primitive. Answer an instance of this class with the number of indexable
	 variables specified by the argument, sizeRequested.  Fail if this class is not
	 indexable or if the argument is not a positive Integer, or if there is not
	 enough memory available. Essential. See Object documentation whatIsAPrimitive."

	<primitive: 71>
	"space must be low."
	OutOfMemory signal.
	^self basicNew: sizeRequested  "retry if user proceeds"
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEindexIfCompact [
	"Backward compatibility with the Squeak V3 object format.
	 Spur does not have a distinction between compact and non-compact classes."
	^0
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEinstSize [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEinstSpec [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEisBits [
	"Answer whether the receiver contains just bits (not pointers).
	 Above Cog Spur the class format is
		<5 bits inst spec><16 bits inst size>
	 where the 5-bit inst spec is
			0	= 0 sized objects (UndefinedObject True False et al)
			1	= non-indexable objects with inst vars (Point et al)
			2	= indexable objects with no inst vars (Array et al)
			3	= indexable objects with inst vars (MethodContext AdditionalMethodState et al)
			4	= weak indexable objects with inst vars (WeakArray et al)
			5	= weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
			6	= unused
			7	= immediates (SmallInteger, Character)
			8	= unused
			9	= 64-bit indexable
		10-11	= 32-bit indexable (Bitmap)
		12-15	= 16-bit indexable
		16-23	= 8-bit indexable
		24-31	= compiled methods (CompiledMethod)"
	^self instSpec >= 7
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEisBytes [
	"Answer whether the receiver has 8-bit instance variables.
	 Above Cog Spur the class format is
		<5 bits inst spec><16 bits inst size>
	 where the 5-bit inst spec is
			0	= 0 sized objects (UndefinedObject True False et al)
			1	= non-indexable objects with inst vars (Point et al)
			2	= indexable objects with no inst vars (Array et al)
			3	= indexable objects with inst vars (MethodContext AdditionalMethodState et al)
			4	= weak indexable objects with inst vars (WeakArray et al)
			5	= weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
			6	= unused
			7	= immediates (SmallInteger, Character)
			8	= unused
			9	= 64-bit indexable
		10-11	= 32-bit indexable (Bitmap)
		12-15	= 16-bit indexable
		16-23	= 8-bit indexable
		24-31	= compiled methods (CompiledMethod)"
	^self instSpec >= 16
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEisEphemeronClass [
	"Answer whether the receiver has ephemeral instance variables.  The garbage collector will
	 fire (queue for finalization) any ephemeron whose first instance variable is not referenced
	 other than from the transitive closure of references from ephemerons. Hence referring to
	 an object from the first inst var of an ephemeron will cause the ephemeron to fire when
	 the rest of the system does not refer to the object and that object is ready to be collected.
	 Since references from the remaining inst vars of an ephemeron will not prevent the ephemeron
	 from firing, ephemerons may act as the associations in weak dictionaries such that the value
	 (e.g. properties attached to the key) will not prevent firing when the key is no longer referenced
	 other than from ephemerons.  Ephemerons can therefore be used to implement instance-based
	 pre-mortem finalization."
	^self instSpec = 5
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEisImmediateClass [
	"Answer whether the receiver has immediate instances.  Immediate instances
	 store their value in their object pointer, not in an object body.  Hence immediates
	 take no space and are immutable.  The immediates are distinguished by tag bits
	 in the pointer. They include SmallIntegers and Characters.  Hence in the 32-bit
	 system SmallIntegers are 31-bit signed integers and Characters are 30-bit
	 unsigned character codes."
	^self instSpec = 7
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEisVariable [
	"Answer whether the receiver has indexable variables.
	 Above Cog Spur the class format is
		<5 bits inst spec><16 bits inst size>
	 where the 5-bit inst spec is
			0	= 0 sized objects (UndefinedObject True False et al)
			1	= non-indexable objects with inst vars (Point et al)
			2	= indexable objects with no inst vars (Array et al)
			3	= indexable objects with inst vars (MethodContext AdditionalMethodState et al)
			4	= weak indexable objects with inst vars (WeakArray et al)
			5	= weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
			6	= unused
			7	= immediates (SmallInteger, Character)
			8	= unused
			9	= 64-bit indexable
		10-11	= 32-bit indexable (Bitmap)
		12-15	= 16-bit indexable
		16-23	= 8-bit indexable
		24-31	= compiled methods (CompiledMethod)"
	| instSpec |
	instSpec := self instSpec.
	^instSpec >= 2 and: [instSpec <= 4 or: [instSpec >= 9]]
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEkindOfSubclass [
	"Answer a String that is the keyword that describes the receiver's kind of subclass,
	 either a regular subclass, a variableSubclass, a variableByteSubclass,
	 a variableWordSubclass, a weakSubclass, an ephemeronSubclass or an immediateSubclass.
	 c.f. typeOfClass"
	^self isVariable
		ifTrue:
			[self isBits
				ifTrue:
					[self isBytes
						ifTrue: [' variableByteSubclass: ']
						ifFalse: [' variableWordSubclass: ']]
				ifFalse:
					[self isWeak
						ifTrue: [' weakSubclass: ']
						ifFalse: [' variableSubclass: ']]]
		ifFalse:
			[self isImmediateClass
				ifTrue: [' immediateSubclass: ']
				ifFalse:
					[self isEphemeronClass
						ifTrue: [' ephemeronSubclass: ']
						ifFalse: [' subclass: ']]]
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEshouldNotBeRedefined [
	"Answer if the receiver should not be redefined.
	 The assumption is that classes in Smalltalk specialObjects and 
	 instance-specific Behaviors should not be redefined"

	^(Smalltalk specialObjectsArray
		identityIndexOf: self
		ifAbsent: [(self isKindOf: self) ifTrue: [1] ifFalse: [0]]) ~= 0
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BehaviorPROTOTYPEtypeOfClass [
	"Answer a symbol uniquely describing the type of the receiver. c.f. kindOfSubclass"
	self isBytes ifTrue:
		[^self instSpec = CompiledMethod instSpec
			ifTrue: [#compiledMethod] "Very special!"
			ifFalse: [#bytes]].
	(self isWords and: [self isPointers not]) ifTrue:
		[^self instSpec = SmallInteger instSpec
			ifTrue: [#immediate] "Very special!"
			ifFalse: [#words]].
	self isWeak ifTrue: [^#weak].
	self isVariable ifTrue: [^#variable].
	self isEphemeronClass ifTrue: [^#ephemeron].
	^#normal
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BytecodeEncoderPROTOTYPEcomputeMethodHeaderForNumArgs: numArgs numTemps: numTemps numLits: numLits primitive: primitiveIndex [
	numArgs > 15 ifTrue:
		[^self error: 'Cannot compile -- too many arguments'].
	numTemps > 63 ifTrue:
		[^self error: 'Cannot compile -- too many temporary variables'].	
	numLits > 65535 ifTrue:
		[^self error: 'Cannot compile -- too many literals'].
	^(CompiledMethod headerFlagForEncoder: self)
	+ (numArgs bitShift: 24)
	+ (numTemps bitShift: 18)
	"+ (largeBit bitShift: 17)" "largeBit gets filled in later"
	+ (primitiveIndex > 0 ifTrue: [1 bitShift: 16] ifFalse: [0])
	+ numLits
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BytecodeEncoderPROTOTYPEsizeCallPrimitive: primitiveIndex [
	^self sizeOpcodeSelector: #genCallPrimitive: withArguments: {primitiveIndex}
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CharacterPROTOTYPEDollarEquals: aCharacter [ 
	"Primitive. Answer if the receiver and the argument are the
	 same object (have the same object pointer). Optional. See
	 Object documentation whatIsAPrimitive."
	<primitive: 110>
	^self == aCharacter
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CharacterPROTOTYPEasInteger [
	"Answer the receiver's character code."
	<primitive: 171>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CharacterPROTOTYPEasciiValue [
	"Answer the receiver's character code.
	 This will be ascii for characters with value <= 127,
	 and Unicode for those with higher values."
	<primitive: 171>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CharacterPROTOTYPEcopy [
	"Answer the receiver, because Characters are unique."
	^self
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CharacterPROTOTYPEdeepCopy [
	"Answer the receiver, because Characters are unique."
	^self
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CharacterPROTOTYPEhash [
	"Hash is reimplemented because = is implemented.
	 Answer the receiver's character code."
	<primitive: 171>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CharacterPROTOTYPEidentityHash [
	"Answer the receiver's character code."
	<primitive: 171>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CharacterPROTOTYPEshallowCopy [
	"Answer the receiver, because Characters are unique."
	^self
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CharacterPROTOTYPEveryDeepCopyWith: deepCopier [
	"Answer the receiver, because Characters are unique."
	^self
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CharacterclassPROTOTYPEdigitValue: x [ 
	"Answer the Character whose digit value is x. For example,
	 answer $9 for x=9, $0 for x=0, $A for x=10, $Z for x=35."

	| n |
	n := x asInteger.
	^self value: (n < 10 ifTrue: [n + 48] ifFalse: [n + 55])
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CharacterclassPROTOTYPEinitialize [
	"Create the DigitsValues table."
	"Character initialize"
	self initializeDigitValues
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CharacterclassPROTOTYPEvalue: anInteger [
	"Answer the Character whose value is anInteger."
	<primitive: 170>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> ClassBuilderPROTOTYPEcomputeFormat: type instSize: newInstSize forSuper: newSuper ccIndex: ccIndex [
	"Compute the new format for making oldClass a subclass of newSuper.
	 Answer the format or nil if there is any problem."
	| instSize isVar isWords isPointers isWeak |
	type == #compiledMethod ifTrue:
		[newInstSize > 0 ifTrue:
			[self error: 'A compiled method class cannot have named instance variables'.
			^nil].
		^CompiledMethod format].
	instSize := newInstSize + (newSuper ifNil:[0] ifNotNil:[newSuper instSize]).
	instSize > 65535 ifTrue:
		[self error: 'Class has too many instance variables (', instSize printString,')'.
		^nil].
	type == #normal ifTrue:[isVar := isWeak := false. isWords := isPointers := true].
	type == #bytes ifTrue:[isVar := true. isWords := isPointers := isWeak := false].
	type == #words ifTrue:[isVar := isWords := true. isPointers := isWeak := false].
	type == #variable ifTrue:[isVar := isPointers := isWords := true. isWeak := false].
	type == #weak ifTrue:[isVar := isWeak := isWords := isPointers := true].
	type == #ephemeron ifTrue:[isVar := false. isWeak := isWords := isPointers := true].
	type == #immediate ifTrue:[isVar := isWeak := isPointers := false. isWords := true].
	(isPointers not and: [instSize > 0]) ifTrue:
		[self error: 'A non-pointer class cannot have named instance variables'.
		^nil].
	^self format: instSize variable: isVar words: isWords pointers: isPointers weak: isWeak
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> ClassBuilderPROTOTYPEformat: nInstVars variable: isVar words: is32BitWords pointers: isPointers weak: isWeak [
	"Compute the format for the given instance specfication.
	 Above Cog Spur the class format is
		<5 bits inst spec><16 bits inst size>
	 where the 5-bit inst spec is
			0	= 0 sized objects (UndefinedObject True False et al)
			1	= non-indexable objects with inst vars (Point et al)
			2	= indexable objects with no inst vars (Array et al)
			3	= indexable objects with inst vars (MethodContext AdditionalMethodState et al)
			4	= weak indexable objects with inst vars (WeakArray et al)
			5	= weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
			6	= unused
			7	= immediates (SmallInteger, Character)
			8	= unused
			9	= reserved for 64-bit indexable
		10-11	= 32-bit indexable (Bitmap)
		12-15	= 16-bit indexable
		16-23	= 8-bit indexable
		24-31	= compiled methods (CompiledMethod)"
	| instSpec |
	instSpec := isWeak
					ifTrue:
						[isVar
							ifTrue: [4]
							ifFalse: [5]]
					ifFalse:
						[isPointers
							ifTrue:
								[isVar
									ifTrue: [nInstVars > 0 ifTrue: [3] ifFalse: [2]]
									ifFalse: [nInstVars > 0 ifTrue: [1] ifFalse: [0]]]
							ifFalse:
								[isVar
									ifTrue: [is32BitWords ifTrue: [10] ifFalse: [16]]
									ifFalse: [7]]].
	^(instSpec bitShift: 16) + nInstVars
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> ClassBuilderPROTOTYPEsuperclass: aClass
	immediateSubclass: t instanceVariableNames: f 
	classVariableNames: d poolDictionaries: s category: cat [
	"This is the standard initialization message for creating a
	 new immediate class as a subclass of an existing class."
	| env |
	aClass instSize > 0
		ifTrue: [^self error: 'cannot make an immediate subclass of a class with named fields'].
	aClass isVariable
		ifTrue: [^self error: 'cannot make an immediate subclass of a class with indexed instance variables'].
	aClass isPointers
		ifFalse: [^self error: 'cannot make an immediate subclass of a class without pointer fields'].
	"Cope with pre-environment and environment versions. Simplify asap."
	env := (Smalltalk classNamed: #EnvironmentRequest)
				ifNil: [aClass environment]
				ifNotNil: [:erc| erc signal ifNil: [aClass environment]].
	^self 
		name: t
		inEnvironment: env
		subclassOf: aClass
		type: #immediate
		instanceVariableNames: f
		classVariableNames: d
		poolDictionaries: s
		category: cat
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> ClassBuilderPROTOTYPEupdate: oldClass to: newClass [
	"Convert oldClass, all its instances and possibly its meta class into newClass,
	 instances of newClass and possibly its meta class. The process is surprisingly
	 simple in its implementation and surprisingly complex in its nuances and potentially
	 bad side effects.
	 We can rely on two assumptions (which are critical):
		#1: The method #updateInstancesFrom: will not create any lasting pointers to
			 'old' instances ('old' is quote on quote since #updateInstancesFrom: will do
			 a become of the old vs. the new instances and therefore it will not create
			 pointers to *new* instances before the #become: which are *old* afterwards)
		#2: The non-preemptive execution of the critical piece of code guarantees that
			 nobody can get a hold by 'other means' (such as process interruption and
			 reflection) on the old instances.
	 Given the above two, we know that after #updateInstancesFrom: there are no pointers
	 to any old instances. After the forwarding become there will be no pointers to the old
	 class or meta class either.
	 Andreas Raab, 2/27/2003 23:42"
	| meta |
	meta := oldClass isMeta.
	"Note: Everything from here on will run without the ability to get interrupted
	to prevent any other process to create new instances of the old class."
	["Note: The following removal may look somewhat obscure and needs an explanation.
	  When we mutate the class hierarchy we create new classes for any existing subclass.
	  So it may look as if we don't have to remove the old class from its superclass. However,
	  at the top of the hierarchy (the first class we reshape) that superclass itself is not newly
	  created so therefore it will hold both the oldClass and newClass in its (obsolete or not)
	  subclasses. Since the #become: below will transparently replace the pointers to oldClass
	  with newClass the superclass would have newClass in its subclasses TWICE. With rather
	  unclear effects if we consider that we may convert the meta-class hierarchy itself (which
	  is derived from the non-meta class hierarchy).
	  Due to this problem ALL classes are removed from their superclass just prior to converting
	  them. Here, breaking the superclass/subclass invariant really doesn't matter since we will
	  effectively remove the oldClass (becomeForward:) just a few lines below."

		oldClass superclass removeSubclass: oldClass.
		oldClass superclass removeObsoleteSubclass: oldClass.

		"make sure that the VM cache is clean"
		oldClass methodDict do: [:cm | cm flushCache].
		
		"Convert the instances of oldClass into instances of newClass"
		newClass updateInstancesFrom: oldClass.

		meta
			ifTrue:
				[oldClass becomeForward: newClass.
				 oldClass updateMethodBindingsTo: oldClass binding]
			ifFalse:
				[{oldClass. oldClass class} elementsForwardIdentityTo: {newClass. newClass class}.
				 oldClass updateMethodBindingsTo: oldClass binding.
				 oldClass class updateMethodBindingsTo: oldClass class binding].

		"eem 5/31/2014 07:22 At this point there used to be a garbage collect whose purpose was
		 to ensure no old instances existed after the becomeForward:.  Without the GC it was possible
		 to resurrect old instances using e.g. allInstancesDo:.  This was because the becomeForward:
		 updated references from the old objects to new objects but didn't destroy the old objects.
		 But as of late 2013/early 2014 becomeForward: has been modified to free all the old objects."]
			valueUnpreemptively
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CompiledMethodPROTOTYPEnumLiterals [
	"Answer the number of literals used by the receiver."
	^self header bitAnd: 65535
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CompiledMethodPROTOTYPEprimitive [
	"Answer the primitive index associated with the receiver.
	 Zero indicates that this is not a primitive method."
	| initialPC |
	^(self header anyMask: 65536) "Is the hasPrimitive? flag set?"
		ifTrue: [(self at: (initialPC := self initialPC) + 1) + ((self at: initialPC + 2) bitShift: 8)]
		ifFalse: [0]
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CompiledMethodclassPROTOTYPEhandleFailingFailingNewMethod: numberOfBytes header: headerWord [
	"This newMethod:header: gets sent after handleFailingBasicNew: has done a full
	 garbage collection and possibly grown memory.  If this basicNew: fails then the
	 system really is low on space, so raise the OutOfMemory signal.

	 Primitive. Answer an instance of this class with the number of indexable variables
	 specified by the argument, headerWord, and the number of bytecodes specified
	 by numberOfBytes.  Fail if this if the arguments are not Integers, or if numberOfBytes
	 is negative, or if the receiver is not a CompiledMethod class, or if there is not enough
	 memory available. Essential. See Object documentation whatIsAPrimitive."

	<primitive: 79>
	"space must be low."
	OutOfMemory signal.
	"retry if user proceeds"
	^self newMethod: numberOfBytes header: headerWord
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CompiledMethodclassPROTOTYPEhandleFailingNewMethod: numberOfBytes header: headerWord [
	"This newMethod:header: gets sent after newMethod:header: has failed
	 and allowed a scavenging garbage collection to occur.  The scavenging
	 collection will have happened as the VM is activating the (failing) basicNew:.
	 If handleFailingBasicNew: fails then the scavenge failed to reclaim sufficient
	 space and a global garbage collection is required.  Retry after garbage
	 collecting and growing memory if necessary.

	 Primitive. Answer an instance of this class with the number of indexable variables
	 specified by the argument, headerWord, and the number of bytecodes specified
	 by numberOfBytes.  Fail if this if the arguments are not Integers, or if numberOfBytes
	 is negative, or if the receiver is not a CompiledMethod class, or if there is not enough
	 memory available. Essential. See Object documentation whatIsAPrimitive."

	<primitive: 79>
	| bytesRequested |
	bytesRequested := (headerWord bitAnd: 16rFFFF) + 1 * Smalltalk wordSize + numberOfBytes + 16.
	Smalltalk garbageCollect < bytesRequested ifTrue:
		[Smalltalk growMemoryByAtLeast: bytesRequested].
	"retry after global garbage collect and possible grow"
	^self handleFailingFailingNewMethod: numberOfBytes header: headerWord
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CompiledMethodclassPROTOTYPEheaderFlagForEncoder: anEncoder [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CompiledMethodclassPROTOTYPEinitialize [    "CompiledMethod initialize"
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CompiledMethodclassPROTOTYPEinstallPrimaryBytecodeSet: aBytecodeEncoderSubclass [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CompiledMethodclassPROTOTYPEinstallSecondaryBytecodeSet: aBytecodeEncoderSubclass [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CompiledMethodclassPROTOTYPEnewBytes: numberOfBytes trailerBytes: trailer nArgs: nArgs nTemps: nTemps nStack: stackSize nLits: nLits primitive: primitiveIndex [
	"Since this method refers to ClassVariables things are easier if it lives in the actual class."

	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CompiledMethodclassPROTOTYPEnewBytes: numberOfBytes trailerBytes: trailer nArgs: nArgs nTemps: nTemps nStack: stackSize nLits: nLits primitive: primitiveIndex flag: flag [
	"Since this method refers to ClassVariables things are easier if it lives in the actual class."

	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CompiledMethodclassPROTOTYPEnewMethod: numberOfBytes header: headerWord [
	"Primitive. Answer an instance of me. The number of literals (and other 
	 information) is specified by the headerWord (see my class comment).
	 The first argument specifies the number of fields for bytecodes in the
	 method. Fail if either argument is not a SmallInteger, or if numberOfBytes
	 is negative, or if memory is low. Once the header of a method is set by
	 this primitive, it cannot be changed to change the number of literals.
	 Essential. See Object documentation whatIsAPrimitive."

	<primitive: 79 error: ec>
	ec == #'insufficient object memory' ifTrue:
		[^self handleFailingNewMethod: numberOfBytes header: headerWord].
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CompiledMethodclassPROTOTYPEtoReturnConstant: index trailerBytes: trailer [
	"Answer an instance of me that is a quick return of the constant
	indexed in (true false nil -1 0 1 2)."

	^self newBytes: 3 trailerBytes: trailer nArgs: 0 nTemps: 0 nStack: 0 nLits: 2 primitive: 256 + index
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CompiledMethodclassPROTOTYPEtoReturnField: field trailerBytes: trailer [
	"Answer an instance of me that is a quick return of the instance variable 
	indexed by the argument, field."

	^self newBytes: 3 trailerBytes: trailer nArgs: 0 nTemps: 0 nStack: 0 nLits: 2 primitive: 264 + field
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CompiledMethodclassPROTOTYPEtoReturnSelfTrailerBytes: trailer [
	"Answer an instance of me that is a quick return of the instance (^self)."

	^self newBytes: 3 trailerBytes: trailer nArgs: 0 nTemps: 0 nStack: 0 nLits: 2 primitive: 256
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> EncoderForV3PROTOTYPEcomputeMethodHeaderForNumArgs: numArgs numTemps: numTemps numLits: numLits primitive: primitiveIndex [
	<remove>
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> EncoderForV3PlusClosuresPROTOTYPEgenCallPrimitive: primitiveIndex [
	"Since this method has inst var refs the prototype must live in the actual class."

	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> EncoderForV3PlusClosuresclassPROTOTYPEbytecodeSize: bytecode [
	"Answer the number of bytes in the bytecode."
	bytecode <= 125 ifTrue:
		[^1].
	bytecode >= 176 ifTrue:
		[^1].
	bytecode >= 160 ifTrue: "long jumps"
		[^2].
	bytecode >= 144 ifTrue: "short jumps"
		[^1].
	"extensions"
	bytecode >= 128 ifTrue:
		[^#(2 2 2 2 3 2 2 1 1 1 2 3 3 3 3 4) at: bytecode - 127].
	^nil
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> EncoderForV3PlusClosuresclassPROTOTYPEcallPrimitiveCode [
	"139	11101111	iiiiiiii jjjjjjjj	Call Primitive #iiiiiiii + (jjjjjjjj * 256)"
	^139
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> InstructionClientPROTOTYPEcallPrimitive: pimIndex [
	"V3PlusClosures:	139 10001011	iiiiiiii   jjjjjjjj  Call Primitive #iiiiiiii + (jjjjjjjj * 256)
	 NewsqueakV4:		249 11111001	iiiiiiii   jjjjjjjj  Call Primitive #iiiiiiii + (jjjjjjjj * 256)
	 SistaV1:			248 11111000 iiiiiiii mjjjjjjj  Call Primitive #iiiiiiii + ( jjjjjjj * 256)
							m=1 means inlined primitive, no hard return after execution."
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> InstructionPrinterPROTOTYPEcallPrimitive: index [
	"Print the callPrimitive."

	self print: 'callPrimtive: ' , index printString
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> InstructionStreamPROTOTYPEinterpretV3ClosuresExtension: offset in: method for: client [
	"Since this method has inst var refs the prototype must live in the actual class."

	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> MethodNodeOLDSQUEAKPROTOTYPEgenerate: trailer [ 
	"The receiver is the root of a parse tree. Answer a CompiledMethod.
	 The argument, trailer, is arbitrary but is typically either the reference
	 to the source code that is stored with every CompiledMethod, or an
	 encoding of the method's temporary names."

	^self generate: trailer using: CompiledMethod
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> MethodNodePROTOTYPEgenerate: trailer using: aCompiledMethodClass [
	"Since this method has inst var refs the prototype must live in the actual class."

	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SmallIntegerPROTOTYPEasCharacter [
	<primitive: 170>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SmalltalkImagePROTOTYPEcompactClassesArray [
	"Smalltalk compactClassesArray"
	"Backward-compatibility support.  Spur does not have compact classes."
	^{}
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SmalltalkImagePROTOTYPEgrowMemoryByAtLeast: numBytes [
	"Grow memory by at least the requested number of bytes.
	 Primitive.  Essential. Fail if no memory is available."
	<primitive: 180>
	(numBytes isInteger and: [numBytes > 0]) ifTrue:
		[OutOfMemory signal].
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SmalltalkImagePROTOTYPEmaxIdentityHash [
	"Answer the maximum identityHash value supported by the VM."
	<primitive: 176>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SpaceTallyPROTOTYPEspaceForInstancesOf: aClass [
	"Answer a pair of the number of bytes consumed by all instances of the
	 given class, including their object headers, and the number of instances."

	| instances total |
	instances := aClass allInstances.
	instances isEmpty ifTrue: [^#(0 0)].
	total := 0.
	aClass isVariable
		ifTrue:
			[instances do:
				[:i| total := total + (aClass byteSizeOfInstanceOfSize: i basicSize)]]
		ifFalse:
			[total := instances size * aClass byteSizeOfInstance].
	^{ total. instances size }
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SystemDictionaryPROTOTYPEgrowMemoryByAtLeast: numBytes [
	"Grow memory by at least the requested number of bytes.
	 Primitive.  Fail if no memory is available.  Essential."
	<primitive: 180>
	^(numBytes isInteger and: [numBytes > 0])
		ifTrue: [OutOfMemory signal]
		ifFalse: [self primitiveFailed]
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SystemDictionaryPROTOTYPEmaxIdentityHash [
	"Answer the maximum identityHash value supported by the VM."
	<primitive: 176>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SystemNavigationPROTOTYPEallObjects [
	"Answer an Array of all objects in the system.  Fail if
	 there isn't enough memory to instantiate the result."
	<primitive: 178>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SystemNavigationPROTOTYPEallObjectsDo: aBlock [ 
	"Evaluate the argument, aBlock, for each object in the system, excluding immediates
	 such as SmallInteger and Character."
	self allObjectsOrNil
		ifNotNil: [:allObjects| allObjects do: aBlock]
		ifNil:
			["Fall back on the old single object primitive code.  With closures, this needs
			  to use an end marker (lastObject) since activation of the block will create
			  new contexts and cause an infinite loop.  The lastObject must be created
			  before calling someObject, so that the VM can settle the enumeration (e.g.
			  by flushing new space) as a side effect of  someObject"
			| object lastObject |
			lastObject := Object new.
			object := self someObject.
			[lastObject == object or: [0 == object]] whileFalse:
				[aBlock value: object.
				 object := object nextObject]]
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SystemNavigationPROTOTYPEallObjectsOrNil [
	"Answer an Array of all objects in the system.  Fail if there isn't
	 enough memory to instantiate the result and answer nil."
	<primitive: 178>
	^nil
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> WideStringPROTOTYPEat: index [
	"Answer the Character stored in the field of the receiver indexed by the
	 argument.  Primitive.  Fail if the index argument is not an Integer or is out
	 of bounds.  Essential.  See Object documentation whatIsAPrimitive."

	<primitive: 63>
	^index isInteger
		ifTrue:
			[self errorSubscriptBounds: index]
		ifFalse:
			[index isNumber
				ifTrue: [self at: index asInteger]
				ifFalse: [self errorNonIntegerIndex]]
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> WideStringPROTOTYPEat: index put: aCharacter [
	"Store the Character into the field of the receiver indicated by the index.
	 Primitive.  Fail if the index is not an Integer or is out of bounds, or if the
	 argument is not a Character.  Essential.  See Object documentation whatIsAPrimitive."

	<primitive: 64>
	^aCharacter isCharacter
		ifTrue:
			[index isInteger
				ifTrue: [self errorSubscriptBounds: index]
				ifFalse: [self errorNonIntegerIndex]]
		ifFalse:
			[self errorImproperStore]
]

{ #category : #accessing }
SpurBootstrapPrototypes >> allMethodPrototypes [ 
	^[self class allMethods "Pharo"
		select: [ :each | each category = 'method prototypes' ]]
		on: MessageNotUnderstood
		do: [:ex|
			ex message selector == #allMethods
				ifTrue:
					[self class selectors "Squeak"
						collect: [:s| self class >> s]
						thenSelect: [:m| m protocol = 'method prototypes']]
				ifFalse:
					[ex pass]]
]
