Class {
	#name : #SpurBootstrapPrototypes,
	#superclass : #Object,
	#category : 'Cog-Bootstrapping'
}

{ #category : #'accessing method dictionary' }
SpurBootstrapPrototypes class >> allMethodPrototypes [
	^(self canUnderstand: #allMethods)
		ifTrue: "Pharo"
			[self allMethods select:
				[:each| each category = 'method prototypes']]
		ifFalse: "Squeak" "%$#@*! collect: on IdentitySet answers a *Set*, not an IdentitySet %$#@*!"
			[(self allSelectors collect: [:s| self lookupSelector: s] as: IdentitySet)
				select: [:m| m protocol = 'method prototypes']]
]

{ #category : #accessing }
SpurBootstrapPrototypes class >> imageType [ 
	^ self subclassResponsibility
]

{ #category : #'instance creation' }
SpurBootstrapPrototypes class >> prototypeClassFor: type [ 
	| deepest |
	deepest := nil.
	self allSubclassesDo:
		[:aClass | aClass imageType = type ifTrue: [deepest := aClass]].
	^deepest
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> ArrayPROTOTYPEelementsExchangeIdentityWith: otherArray [
	"This primitive performs a bulk mutation, causing all pointers to the elements of the
	 receiver to be replaced by pointers to the corresponding elements of otherArray.
	 At the same time, all pointers to the elements of otherArray are replaced by
	 pointers to the corresponding elements of this array.  The identityHashes remain
	 with the pointers rather than with the objects so that objects in hashed structures
	 should still be properly indexed after the mutation."

	<primitive: 128 error: ec>
	ec == #'bad receiver' ifTrue:
		[^self error: 'receiver must be of class Array'].
	ec == #'bad argument' ifTrue:
		[^self error: (otherArray class == Array
						ifTrue: ['arg must be of class Array']
						ifFalse: ['receiver and argument must have the same size'])].
	ec == #'inappropriate operation' ifTrue:
		[^self error: 'can''t become immediates such as SmallIntegers or Characters'].
	ec == #'no modification' ifTrue:
		[^self error: 'can''t become immutable objects'].
	ec == #'object is pinned' ifTrue:
		[^self error: 'can''t become pinned objects'].
	ec == #'insufficient object memory' ifTrue:
		[Smalltalk garbageCollect < 1048576 ifTrue:
			[Smalltalk growMemoryByAtLeast: 1048576].
		 ^self elementsExchangeIdentityWith: otherArray].
	self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> ArrayPROTOTYPEelementsForwardIdentityTo: otherArray [
	"This primitive performs a bulk mutation, causing all pointers to the elements of the
	 receiver to be replaced by pointers to the corresponding elements of otherArray.
	 The identityHashes remain with the pointers rather than with the objects so that
	 the objects in this array should still be properly indexed in any existing hashed
	 structures after the mutation."
	<primitive: 72 error: ec>
	ec == #'bad receiver' ifTrue:
		[^self error: 'receiver must be of class Array'].
	ec == #'bad argument' ifTrue:
		[^self error: (otherArray class == Array
						ifTrue: ['arg must be of class Array']
						ifFalse: ['receiver and argument must have the same size'])].
	ec == #'inappropriate operation' ifTrue:
		[^self error: 'can''t become immediates such as SmallIntegers or Characters'].
	ec == #'no modification' ifTrue:
		[^self error: 'can''t become immutable objects'].
	ec == #'object is pinned' ifTrue:
		[^self error: 'can''t become pinned objects'].
	ec == #'insufficient object memory' ifTrue:
		[Smalltalk garbageCollect < 1048576 ifTrue:
			[Smalltalk growMemoryByAtLeast: 1048576].
		 ^self elementsForwardIdentityTo: otherArray].
	self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> ArrayPROTOTYPEelementsForwardIdentityTo: otherArray copyHash: copyHash [
	"This primitive performs a bulk mutation, causing all pointers to the elements of the
	 receiver to be replaced by pointers to the corresponding elements of otherArray.
	 If copyHash is true, the identityHashes remain with the pointers rather than with the
	 objects so that the objects in the receiver should still be properly indexed in any
	 existing hashed structures after the mutation.  If copyHash is false, then the hashes
	 of the objects in otherArray remain unchanged.  If you know what you're doing this
	 may indeed be what you want."
	<primitive: 249 error: ec>
	ec == #'bad receiver' ifTrue:
		[^self error: 'receiver must be of class Array'].
	ec == #'bad argument' ifTrue:
		[^self error: (otherArray class == Array
						ifTrue: ['arg must be of class Array']
						ifFalse: ['receiver and argument must have the same size'])].
	ec == #'inappropriate operation' ifTrue:
		[^self error: 'can''t become immediates such as SmallIntegers or Characters'].
	ec == #'no modification' ifTrue:
		[^self error: 'can''t become immutable objects'].
	ec == #'object is pinned' ifTrue:
		[^self error: 'can''t become pinned objects'].
	ec == #'insufficient object memory' ifTrue:
		[Smalltalk garbageCollect < 1048576 ifTrue:
			[Smalltalk growMemoryByAtLeast: 1048576].
		 ^self elementsForwardIdentityTo: otherArray copyHash: copyHash].
	self primitiveFailed
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
SpurBootstrapPrototypes >> BehaviorPROTOTYPEisCompiledMethodClass [
	"Answer whether the receiver has compiled method instances that mix pointers and bytes."
	^self instSpec >= 24
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
SpurBootstrapPrototypes >> BoxedFloat64classPROTOTYPEbasicNew [
	^self basicNew: 2
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> BoxedFloat64classPROTOTYPEbasicNew: sizeRequested [ 
	"Primitive. Answer an instance of this class with the number
	 of indexable variables specified by the argument, sizeRequested.
	 Fail if this class is not indexable or if the argument is not a
	 positive Integer, or if there is not enough memory available. 
	 Essential. See Object documentation whatIsAPrimitive."

	<primitive: 71>
	sizeRequested isInteger ifTrue:
		[^sizeRequested = 2
			ifTrue: "arg okay; space must be low."
				[OutOfMemory signal.
				 self basicNew: sizeRequested]  "retry if user proceeds"
			ifFalse:
				[self error: 'a Float shall always have two slots']].
	self primitiveFailed
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
SpurBootstrapPrototypes >> CharacterPROTOTYPEcomeFullyUpOnReload: smartRefStream [
	"Now Characters are immediates, this can be deleted."
	<remove>
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
SpurBootstrapPrototypes >> ClassDescriptionPROTOTYPEupdateInstances: oldInstances from: oldClass isMeta: isMeta [
	"Recreate any existing instances of the argument, oldClass, as instances of the receiver,
	 which is a newly changed class. Permute variables as necessary, and forward old instances
	 to new instances.  Answer nil to defeat old clients that expect an array of old instances.
	 The old behaviour, which necessitated a global GC, exchanged identities and answered
	 the old instances.  But no clients used the result.  This way we avoid the unnecessary GC,"
	| map variable instSize newInstances |

	oldInstances isEmpty ifTrue:
		[^nil]. "no instances to convert"
	isMeta ifTrue:
		[(oldInstances size = 1
		  and: [self soleInstance class == self
				or: [self soleInstance class == oldClass]]) ifFalse:
			[^self error: 'Metaclasses can only have one instance']].
	map := self instVarMappingFrom: oldClass.
	variable := self isVariable.
	instSize := self instSize.
	newInstances := Array new: oldInstances size.
	1 to: oldInstances size do:
		[:i|
		newInstances
			at: i
			put: (self newInstanceFrom: (oldInstances at: i) variable: variable size: instSize map: map)].
	"Now perform a bulk mutation of old instances into new ones"
	oldInstances elementsForwardIdentityTo: newInstances.
	^nil
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> ClassDescriptionPROTOTYPEupdateInstancesFrom: oldClass [
	"Recreate any existing instances of the argument, oldClass, as instances of 
	 the receiver, which is a newly changed class. Permute variables as necessary,
	 and forward old instances to new instances.. Answer nil to defeat any clients
	 that expected the old behaviour of answering the array of old instances."
	"ar 7/15/1999: The updating below is possibly dangerous. If there are any
	contexts having an old instance as receiver it might crash the system if
	the new receiver in which the context is executed has a different layout.
	See bottom below for a simple example:"
	self updateInstances: oldClass allInstances asArray from: oldClass isMeta: self isMeta.
	"Now fix up instances in segments that are out on the disk."
	ImageSegment allSubInstancesDo:
		[:seg |
		seg segUpdateInstancesOf: oldClass toBe: self isMeta: self isMeta].
	^nil

"This attempts to crash the VM by stepping off the end of an instance.
 As the doctor says, do not do this."
"	| crashingBlock class |
	class := Object subclass: #CrashTestDummy
		instanceVariableNames: 'instVar'
		classVariableNames: ''
		poolDictionaries: ''
		category: 'Crash-Test'.
	class compile:'instVar: value instVar := value'.
	class compile:'crashingBlock ^[instVar]'.
	crashingBlock := (class new) instVar: 42; crashingBlock.
	Object subclass: #CrashTestDummy
		instanceVariableNames: ''
		classVariableNames: ''
		poolDictionaries: ''
		category: 'Crash-Test'.
	crashingBlock value"
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> CompiledMethodPROTOTYPEnumLiterals [
	"Answer the number of literals used by the receiver."
	^self header bitAnd: 16r7FFF
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
SpurBootstrapPrototypes >> FloatclassPROTOTYPEbasicNew [
	^BoxedFloat64 basicNew: 2
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> FloatclassPROTOTYPEbasicNew: anInteger [
	^BoxedFloat64 basicNew: 2
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> FloatclassPROTOTYPEfromIEEE32Bit: word [
	"Convert the given 32 bit word (which is supposed to be a positive 32-bit value) from
	 a 32 bit IEEE floating point representation into an actual Squeak float object (being
	 64 bits wide). Should only be used for conversion in FloatArrays or likewise objects."
	
	| sign mantissa exponent delta |
	word <= 0 ifTrue:
		[^word negative
			ifTrue: [self error: 'Cannot deal with negative numbers']
			ifFalse: [self zero]].
	sign := word bitAnd: 16r80000000.
	word = sign ifTrue:
		[^self negativeZero].
	
	exponent := ((word bitShift: -23) bitAnd: 16rFF) - 127.
	mantissa := word bitAnd:  16r7FFFFF.

	exponent = 128 ifTrue: "Either NAN or INF"
		[^mantissa = 0
			ifTrue:
				[sign = 0 
					ifTrue: [self infinity]
					ifFalse: [self negativeInfinity]]
			ifFalse: [self nan]].

	exponent = -127 ifTrue:
		"gradual underflow (denormalized number)
		 Remove first bit of mantissa and adjust exponent"
		[delta := mantissa highBit.
		 mantissa := (mantissa bitAnd: (1 bitShift: delta - 1) - 1) bitShift: 24 - delta.
		 exponent := exponent + delta - 23].
	
	"Create new float"
	^(self basicNew: 2)
		basicAt: 1 put: ((sign bitOr: (1023 + exponent bitShift: 20)) bitOr: (mantissa bitShift: -3));
		basicAt: 2 put: ((mantissa bitAnd: 7) bitShift: 29);
		* 1.0 "reduce to SmallFloat64 if possible"
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> InstructionClientPROTOTYPEcallPrimitive: pimIndex [
	"V3PlusClosures:	139 10001011	iiiiiiii   jjjjjjjj  Call Primitive #iiiiiiii + (jjjjjjjj * 256)
	 NewsqueakV4:		249 11111001	iiiiiiii   jjjjjjjj  Call Primitive #iiiiiiii + (jjjjjjjj * 256)
	 SistaV1:			248 11111000 iiiiiiii mjjjjjjj  Call Primitive #iiiiiiii + ( jjjjjjj * 256)
							m=1 means inlined primitive, no hard return after execution."
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> InstructionStreamPROTOTYPEinterpretV3ClosuresExtension: offset in: method for: client [
	"Since this method has inst var refs the prototype must live in the actual class."

	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> LargeNegativeIntegerPROTOTYPEnormalize [
	"Check for leading zeroes and return shortened copy if so"
	| sLen val len oldLen minVal |
	<primitive: 'primNormalizeNegative' module: 'LargeIntegers'>
	"First establish len = significant length"
	len := oldLen := self digitLength.
	[len = 0 ifTrue: [^0].
	(self digitAt: len) = 0]
		whileTrue: [len := len - 1].

	"Now check if in SmallInteger range.
	 Fast compute SmallInteger minVal digitLength"
	sLen := SmallInteger minVal < -16r40000000
				ifTrue: [8]
				ifFalse: [4].
	len <= sLen ifTrue:
		[minVal := SmallInteger minVal.
		(len < sLen
		 or: [(self digitAt: sLen) < minVal lastDigit])
			ifTrue: ["If high digit less, then can be small"
					val := 0.
					len to: 1 by: -1 do:
						[:i | val := (val *256) - (self digitAt: i)].
					^ val].
		1 to: sLen do:  "If all digits same, then = minVal"
			[:i | (self digitAt: i) = (minVal digitAt: i)
					ifFalse: ["Not so; return self shortened"
							len < oldLen
								ifTrue: [^ self growto: len]
								ifFalse: [^ self]]].
		^ minVal].

	"Return self, or a shortened copy"
	len < oldLen
		ifTrue: [^ self growto: len]
		ifFalse: [^ self]
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> LargePositiveIntegerPROTOTYPEnormalize [
	"Check for leading zeroes and return shortened copy if so"
	| sLen val len oldLen |
	<primitive: 'primNormalizePositive' module:'LargeIntegers'>
	"First establish len = significant length"
	len := oldLen := self digitLength.
	[len = 0 ifTrue: [^0].
	(self digitAt: len) = 0]
		whileTrue: [len := len - 1].

	"Now check if in SmallInteger range.  Fast compute SmallInteger maxVal digitLength"
	sLen := SmallInteger maxVal > 16r3FFFFFFF
				ifTrue: [8]
				ifFalse: [4].
	(len <= sLen
	 and: [(self digitAt: sLen) <= (SmallInteger maxVal digitAt: sLen)])
		ifTrue: ["If so, return its SmallInt value"
				val := 0.
				len to: 1 by: -1 do:
					[:i | val := (val *256) + (self digitAt: i)].
				^ val].

	"Return self, or a shortened copy"
	len < oldLen
		ifTrue: [^ self growto: len]
		ifFalse: [^ self]
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
SpurBootstrapPrototypes >> ObjectPROTOTYPEclone [
	"Answer a shallow copy of the receiver."
	<primitive: 148 error: ec>
	| class newObject |
	ec == #'insufficient object memory' ifFalse:
		[^self primitiveFailed].
	"If the primitive fails due to insufficient memory, instantiate via basicNew: to invoke
	 the garbage collector before retrying, and use copyFrom: to copy state."
	newObject := (class := self class) isVariable
					ifTrue: 
						[class isCompiledMethodClass
							ifTrue:
								[class newMethod: self basicSize - self initialPC + 1 header: self header]
							ifFalse:
								[class basicNew: self basicSize]]
					ifFalse:
						[class basicNew].
	^newObject copyFrom: self
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> ObjectPROTOTYPEinstVarAt: index [
	"Primitive. Answer a fixed variable in an object. The numbering of the variables
	 corresponds to the named instance variables, followed by the indexed instance
	 variables. Fail if the index is not an Integer or is not the index of a fixed variable.
	 Essential. See Object documentation whatIsAPrimitive."

	<primitive: 173 error: ec>
	self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> ObjectPROTOTYPEinstVarAt: index put: anObject [
	"Primitive. Store a value into a fixed variable in an object. The numbering of the
	 variables corresponds to the named instance variables, followed by the indexed
	 instance variables. Fail if the index is not an Integer or is not the index of a fixed
	 variable. Essential. See Object documentation whatIsAPrimitive."

	<primitive: 174 error: ec>
	self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> ObjectPROTOTYPEisPinned [
	"Answer if the receiver is pinned.  The VM's garbage collector routinely moves
	 objects as it reclaims and compacts memory.  But it can also pin an object so
	 that it will not be moved, which can make it easier to pass objects out through
	 the FFI."
	<primitive: 183 error: ec>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> ObjectPROTOTYPEoopAge [
	<remove>
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> ObjectPROTOTYPEoopTimestamp [
	<remove>
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> ObjectPROTOTYPEpin [
	"The VM's garbage collector routinely moves objects as it reclaims and compacts
	 memory. But it can also pin an object so that it will not be moved, which can make
	 it easier to pass objects out through the FFI.  Objects are unpinnned when created.
	 This method ensures an object is pinned, and answers whether it was already pinned."
	^self setPinned: true
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> ObjectPROTOTYPEsetPinned: aBoolean [
	"The VM's garbage collector routinely moves objects as it reclaims and compacts
	 memory. But it can also pin an object so that it will not be moved, which can make
	 it easier to pass objects out through the FFI.  Objects are unpinnned when created.
	 This primitive either pins or unpins an object, and answers if it was already pinned."
	<primitive: 184 error: ec>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> ObjectPROTOTYPEunpin [
	"The VM's garbage collector routinely moves objects as it reclaims and compacts
	 memory. But it can also pin an object so that it will not be moved, which can make
	 it easier to pass objects out through the FFI.  Objects are unpinnned when created.
	 This method ensures an object is unpinned, and answers whether it was pinned."
	^self setPinned: false
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SmallFloat64PROTOTYPEclone [
	"Answer the receiver, because SmallFloat64s are unique."
	^self
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SmallFloat64PROTOTYPEcopy [
	"Answer the receiver, because SmallFloat64s are unique."
	^self
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SmallFloat64PROTOTYPEdeepCopy [
	"Answer the receiver, because SmallFloat64s are unique."
	^self
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SmallFloat64PROTOTYPEidentityHash [
	"Answer an integer unique to the receiver."
	<primitive: 171>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SmallFloat64PROTOTYPEshallowCopy [
	"Answer the receiver, because SmallFloat64s are unique."
	^self
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SmallFloat64PROTOTYPEveryDeepCopyWith: deepCopier [
	"Answer the receiver, because SmallFloat64s are unique."
	^self
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SmallFloat64classPROTOTYPEbasicNew [
	self error: 'SmallFloat64s can only be created by performing arithmetic'
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SmallFloat64classPROTOTYPEbasicNew: anInteger [
	^self basicNew
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SmallIntegerPROTOTYPEasCharacter [
	<primitive: 170>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SmallIntegerPROTOTYPEdecimalDigitLength [
	"Answer the number of digits printed out in base 10.
	 Note that this only works for positive SmallIntegers up to 64-bits."
	
	^self < 10000
		ifTrue:
			[self < 100
				ifTrue:
					[self < 10 ifTrue: [1] ifFalse: [2]]
				ifFalse:
					[self < 1000 ifTrue: [3] ifFalse: [4]]]
		ifFalse:
			[self < 100000000
				ifTrue:
					[self < 1000000
						ifTrue: [self < 100000 ifTrue: [5] ifFalse: [6]]
						ifFalse: [self < 10000000 ifTrue: [7] ifFalse: [8]]]
				ifFalse:
					[self < 1000000000000
						ifTrue:
							[self < 10000000000
								ifTrue: [self < 1000000000 ifTrue: [9] ifFalse: [10]]
								ifFalse: [self < 100000000000 ifTrue: [11] ifFalse: [12]]]
						ifFalse:
							[self < 10000000000000000
								ifTrue:
									[self < 100000000000000
										ifTrue: [self < 10000000000000 ifTrue: [13] ifFalse: [14]]
										ifFalse: [self < 1000000000000000 ifTrue: [15] ifFalse: [16]]]
								ifFalse:
									[self < 1000000000000000000
										ifTrue: [self < 100000000000000000 ifTrue: [17] ifFalse: [18]]
										ifFalse: [self < 10000000000000000000 ifTrue: [19] ifFalse: [20]]]]]]
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SmallIntegerPROTOTYPEdigitLength [
	"Answer the number of indexable fields in the receiver. This value is the 
	 same as the largest legal subscript. Included so that a SmallInteger can 
	 behave like a LargePositiveInteger or LargeNegativeInteger."

	| value length |
	length := 1.
	value := self.
	value >= 0
		ifTrue:
			[[value > 255] whileTrue:
				[value := value bitShift: -8.
				 length := length + 1]]
		ifFalse:
			[[value < -255] whileTrue:
				[value := value bitShift: -8.
				 length := length + 1]].
	^length
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
SpurBootstrapPrototypes >> SmalltalkImagePROTOTYPEprimBytesLeft [
	"Primitive. Answer the number of free bytes available in old space.
	 Not accurate unless preceded by
		Smalltalk garbageCollectMost (for reasonable accuracy), or
		Smalltalk garbageCollect (for real accuracy).
	 See Object documentation whatIsAPrimitive."

	<primitive: 112>
	^0
]

{ #category : #'method prototypes' }
SpurBootstrapPrototypes >> SmalltalkImagePROTOTYPEprimitiveGarbageCollect [
	"Primitive. Reclaims all garbage and answers the size of the largest free chunk in old space.."

	<primitive: 130>
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
