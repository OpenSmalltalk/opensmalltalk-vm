"
SpurBootstrap bootstraps an image in SpurMemoryManager format from a Squeak V3 + closures format.

e.g.
	(SpurBootstrap32 new on: '/Users/eliot/Cog/startreader.image')
		transform;
		launch

Bootstrap issues:
- should it implement a deterministic Symbol identityHash? This means set a Symbol's identityHash at instance creation time
  based on its string hash so that e.g. MethodDIctionary instances have a deterministic order and don't need to be rehashed on load.
- should it collapse ContextPart and MethodContext down onto Context (and perhaps eliminate BlockContext)?

Instance Variables
	classToIndex:			<Dictionary>
	lastClassTablePage:	<Integer>
	map:					<Dictionary>
	methodClasses:		<Set>
	newHeap:				<SpurMemoryManager>
	oldHeap:				<NewObjectMemory>
	oldInterpreter:			<StackInterpreterSimulator>
	reverseMap:			<Dictionary>
	symbolMap:				<Dictionary>

classToIndex
	- oldClass to new classIndex map

lastClassTablePage
	- oop in newHeap of last classTable page.  U<sed in validation to filter-out class table.

methodClasses
	- cache of methodClassAssociations for classes in which modified methods are installed

map
	- oldObject to newObject map

newHeap
	- the output, bootstrapped image

oldHeap
	- the input, image

oldInterpreter
	- the interpreter associated with oldHeap, needed for a hack to grab WeakArray

reverseMap
	- newObject to oldObject map

symbolMap
	- symbol toi symbol oop in oldHeap, used to map prototype methdos to methods in oldHeap
"
Class {
	#name : #SpurBootstrap,
	#superclass : #SimulatorHarness,
	#instVars : [
		'oldHeap',
		'newHeap',
		'oldHeapSize',
		'newHeapSize',
		'oldHeapNumObjs',
		'newHeapNumObjs',
		'map',
		'reverseMap',
		'classToIndex',
		'oldInterpreter',
		'lastClassTablePage',
		'literalMap',
		'methodClasses',
		'installedPrototypes',
		'installedMethodOops',
		'classMetaclass',
		'imageTypes',
		'classMethodContextIndex',
		'classBlockClosureIndex',
		'toBeInitialized'
	],
	#classVars : [
		'ImageHeaderFlags',
		'ImageName',
		'ImageScreenSize',
		'TransformedImage'
	],
	#pools : [
		'VMObjectIndices'
	],
	#category : #'Cog-Bootstrapping'
}

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEallInstances [
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
SpurBootstrap class >> BehaviorPROTOTYPEallInstancesDo: aBlock [
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
SpurBootstrap class >> BehaviorPROTOTYPEallInstancesOrNil [
	"Answer all instances of the receiver, or nil if the primitive
	 fails, which it may be due to being out of memory."
	<primitive: 177>
	^nil
]

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> BehaviorPROTOTYPEbasicIdentityHash [
	"Answer a SmallInteger whose value is related to the receiver's identity.
	 Behavior implements identityHash to allow the VM to use an object representation which
	 does not include a direct reference to an object's class in an object.  If the VM is using
	 this implementation then classes are held in a class table and instances contain the index
	 of their class in the table.  A class's class table index is its identityHash so that an instance
	 can be created without searching the table for a class's index.  The VM uses this primitive
	 to enter the class into the class table, assigning its identityHash with an as yet unused
	 class table index. If this primitive fails it means that the class table is full.  In Spur as of
	 2014 there are 22 bits of classTable index and 22 bits of identityHash per object.

	 Primitive. Essential. Do not override. See Object documentation whatIsAPrimitive."

	<primitive: 175>
	self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEbasicNew [
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
SpurBootstrap class >> BehaviorPROTOTYPEbasicNew: sizeRequested [
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
SpurBootstrap class >> BehaviorPROTOTYPEbyteSizeOfInstance [
	"Answer the total memory size of an instance of the receiver."

	<primitive: 181 error: ec>
	self isVariable ifTrue:
		[^self byteSizeOfInstanceOfSize: 0].
	self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEbyteSizeOfInstanceOfSize: basicSize [
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
SpurBootstrap class >> BehaviorPROTOTYPEelementSize [
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
SpurBootstrap class >> BehaviorPROTOTYPEhandleFailingBasicNew [
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
SpurBootstrap class >> BehaviorPROTOTYPEhandleFailingBasicNew: sizeRequested [
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
SpurBootstrap class >> BehaviorPROTOTYPEhandleFailingFailingBasicNew [
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
SpurBootstrap class >> BehaviorPROTOTYPEhandleFailingFailingBasicNew: sizeRequested [
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

{ #category : #'method prototypes squeak' }
SpurBootstrap class >> BehaviorPROTOTYPEidentityHash [
	"Answer a SmallInteger whose value is related to the receiver's identity.
	 Behavior implements identityHash to allow the VM to use an object representation which
	 does not include a direct reference to an object's class in an object.  If the VM is using
	 this implementation then classes are held in a class table and instances contain the index
	 of their class in the table.  A class's class table index is its identityHash so that an instance
	 can be created without searching the table for a class's index.  The VM uses this primitive
	 to enter the class into the class table, assigning its identityHash with an as yet unused
	 class table index. If this primitive fails it means that the class table is full.  In Spur as of
	 2014 there are 22 bits of classTable index and 22 bits of identityHash per object.

	 Primitive. Essential. Do not override. See Object documentation whatIsAPrimitive."

	<primitive: 175>
	self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEindexIfCompact [
	"Backward compatibility with the Squeak V3 object format.
	 Spur does not have a distinction between compact and non-compact classes."
	^0
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEinstSize [
	"Answer the number of named instance variables
	(as opposed to indexed variables) of the receiver.
	 Above Cog Spur the class format is
		<5 bits inst spec><16 bits inst size>"
	^format bitAnd: 16rFFFF
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEinstSpec [
	"Answer the instance specification part of the format that defines what kind of object
	 an instance of the receiver is.  The formats are
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
	^(format bitShift: -16) bitAnd: 16r1F
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEisBits [
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
SpurBootstrap class >> BehaviorPROTOTYPEisBytes [
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
SpurBootstrap class >> BehaviorPROTOTYPEisEphemeronClass [
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
SpurBootstrap class >> BehaviorPROTOTYPEisImmediateClass [
	"Answer whether the receiver has immediate instances.  Immediate instances
	 store their value in their object pointer, not in an object body.  Hence immediates
	 take no space and are immutable.  The immediates are distinguished by tag bits
	 in the pointer. They include SmallIntegers and Characters.  Hence in the 32-bit
	 system SmallIntegers are 31-bit signed integers and Characters are 30-bit
	 unsigned character codes."
	^self instSpec = 7
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEisVariable [
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
SpurBootstrap class >> BehaviorPROTOTYPEkindOfSubclass [
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

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> BehaviorPROTOTYPElargeIdentityHash [
	"Answer a SmallInteger whose value is related to the receiver's identity.
	 Behavior implements identityHash to allow the VM to use an object representation which
	 does not include a direct reference to an object's class in an object.  If the VM is using
	 this implementation then classes are held in a class table and instances contain the index
	 of their class in the table.  A class's class table index is its identityHash so that an instance
	 can be created without searching the table for a class's index.  The VM uses this primitive
	 to enter the class into the class table, assigning its identityHash with an as yet unused
	 class table index. If this primitive fails it means that the class table is full.  In Spur as of
	 2014 there are 22 bits of classTable index and 22 bits of identityHash per object."

	<primitive: 175>
	self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEshouldNotBeRedefined [
	"Answer if the receiver should not be redefined.
	 The assumption is that classes in Smalltalk specialObjects and 
	 instance-specific Behaviors should not be redefined"

	^(Smalltalk specialObjectsArray
		identityIndexOf: self
		ifAbsent: [(self isKindOf: self) ifTrue: [1] ifFalse: [0]]) ~= 0
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BehaviorPROTOTYPEtypeOfClass [
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
SpurBootstrap class >> BlockClosurePROTOTYPEsimulateValueWithArguments: anArray caller: aContext [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrap class >> BytecodeEncoderPROTOTYPEcomputeMethodHeaderForNumArgs: numArgs numTemps: numTemps numLits: numLits primitive: primitiveIndex [
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
SpurBootstrap class >> BytecodeEncoderPROTOTYPEsizeCallPrimitive: primitiveIndex [
	^self sizeOpcodeSelector: #genCallPrimitive: withArguments: {primitiveIndex}
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CharacterPROTOTYPEDollarEquals: aCharacter [ 
	"Primitive. Answer if the receiver and the argument are the
	 same object (have the same object pointer). Optional. See
	 Object documentation whatIsAPrimitive."
	<primitive: 110>
	^self == aCharacter
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CharacterPROTOTYPEasInteger [
	"Answer the receiver's character code."
	<primitive: 171>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CharacterPROTOTYPEasciiValue [
	"Answer the receiver's character code.
	 This will be ascii for characters with value <= 127,
	 and Unicode for those with higher values."
	<primitive: 171>
	^self primitiveFailed
]

{ #category : #'method prototypes squeak' }
SpurBootstrap class >> CharacterPROTOTYPEclone [
	"Answer the receiver, because Characters are unique."
	^self
]

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> CharacterPROTOTYPEcodePoint [
	"Just for ANSI Compliance"	
	^self
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CharacterPROTOTYPEcopy [
	"Answer the receiver, because Characters are unique."
	^self
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CharacterPROTOTYPEdeepCopy [
	"Answer the receiver, because Characters are unique."
	^self
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CharacterPROTOTYPEhash [
	"Hash is reimplemented because = is implemented.
	 Answer the receiver's character code."
	<primitive: 171>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CharacterPROTOTYPEidentityHash [
	"Answer the receiver's character code."
	<primitive: 171>
	^self primitiveFailed
]

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> CharacterPROTOTYPEsetValue: newValue [
	self error: 'Characters are immutable'
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CharacterPROTOTYPEshallowCopy [
	"Answer the receiver, because Characters are unique."
	^self
]

{ #category : #'method prototypes squeak 4.3' }
SpurBootstrap class >> CharacterPROTOTYPEshouldBePrintedAsLiteral [

	^(self asInteger between: 33 and: 255) and: [self asInteger ~= 127]
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CharacterPROTOTYPEveryDeepCopyWith: deepCopier [
	"Answer the receiver, because Characters are unique."
	^self
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CharacterclassPROTOTYPEdigitValue: x [ 
	"Answer the Character whose digit value is x. For example,
	 answer $9 for x=9, $0 for x=0, $A for x=10, $Z for x=35."

	| n |
	n := x asInteger.
	^self value: (n < 10 ifTrue: [n + 48] ifFalse: [n + 55])
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CharacterclassPROTOTYPEinitialize [
	"Create the DigitsValues table."
	"Character initialize"
	self initializeDigitValues
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CharacterclassPROTOTYPEvalue: anInteger [
	"Answer the Character whose value is anInteger."
	<primitive: 170>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> ClassBuilderPROTOTYPEcomputeFormat: type instSize: newInstSize forSuper: newSuper ccIndex: ccIndex [
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
SpurBootstrap class >> ClassBuilderPROTOTYPEformat: nInstVars variable: isVar words: is32BitWords pointers: isPointers weak: isWeak [
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
SpurBootstrap class >> ClassBuilderPROTOTYPEsuperclass: aClass
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
SpurBootstrap class >> ClassBuilderPROTOTYPEupdate: oldClass to: newClass [
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

{ #category : #'method prototypes squeak' }
SpurBootstrap class >> ClassDescriptionPROTOTYPEupdateMethodBindingsTo: aBinding [
	"ClassBuilder support for maintaining valid method bindings."
	methodDict do: [:method| method methodClassAssociation: aBinding]
]

{ #category : #'method prototypes squeak' }
SpurBootstrap class >> ClassPROTOTYPEimmediateSubclass: t instanceVariableNames: f classVariableNames: d poolDictionaries: s category: cat [ 
	"This is the standard initialization message for creating a new
	 immediate class as a subclass of an existing class (the receiver)."
	^ClassBuilder new
		superclass: self
		immediateSubclass: t
		instanceVariableNames: f
		classVariableNames: d
		poolDictionaries: s
		category: cat
]

{ #category : #'method prototypes squeak 4.3' }
SpurBootstrap class >> CompiledMethodPROTOTYPEencoderClass [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CompiledMethodPROTOTYPEnumLiterals [
	"Answer the number of literals used by the receiver."
	^self header bitAnd: 65535
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CompiledMethodPROTOTYPEprimitive [
	"Answer the primitive index associated with the receiver.
	 Zero indicates that this is not a primitive method."
	| initialPC |
	^(self header anyMask: 65536) "Is the hasPrimitive? flag set?"
		ifTrue: [(self at: (initialPC := self initialPC) + 1) + ((self at: initialPC + 2) bitShift: 8)]
		ifFalse: [0]
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CompiledMethodclassPROTOTYPEhandleFailingFailingNewMethod: numberOfBytes header: headerWord [
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
SpurBootstrap class >> CompiledMethodclassPROTOTYPEhandleFailingNewMethod: numberOfBytes header: headerWord [
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
SpurBootstrap class >> CompiledMethodclassPROTOTYPEheaderFlagForEncoder: anEncoder [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CompiledMethodclassPROTOTYPEinitialize [    "CompiledMethod initialize"
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CompiledMethodclassPROTOTYPEinstallPrimaryBytecodeSet: aBytecodeEncoderSubclass [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CompiledMethodclassPROTOTYPEinstallSecondaryBytecodeSet: aBytecodeEncoderSubclass [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CompiledMethodclassPROTOTYPEnewBytes: numberOfBytes trailerBytes: trailer nArgs: nArgs nTemps: nTemps nStack: stackSize nLits: nLits primitive: primitiveIndex [
	"Since this method refers to ClassVariables things are easier if it lives in the actual class."

	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CompiledMethodclassPROTOTYPEnewBytes: numberOfBytes trailerBytes: trailer nArgs: nArgs nTemps: nTemps nStack: stackSize nLits: nLits primitive: primitiveIndex flag: flag [
	"Since this method refers to ClassVariables things are easier if it lives in the actual class."

	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CompiledMethodclassPROTOTYPEnewMethod: numberOfBytes header: headerWord [
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
SpurBootstrap class >> CompiledMethodclassPROTOTYPEtoReturnConstant: index trailerBytes: trailer [
	"Answer an instance of me that is a quick return of the constant
	indexed in (true false nil -1 0 1 2)."

	^self newBytes: 3 trailerBytes: trailer nArgs: 0 nTemps: 0 nStack: 0 nLits: 2 primitive: 256 + index
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CompiledMethodclassPROTOTYPEtoReturnField: field trailerBytes: trailer [
	"Answer an instance of me that is a quick return of the instance variable 
	indexed by the argument, field."

	^self newBytes: 3 trailerBytes: trailer nArgs: 0 nTemps: 0 nStack: 0 nLits: 2 primitive: 264 + field
]

{ #category : #'method prototypes' }
SpurBootstrap class >> CompiledMethodclassPROTOTYPEtoReturnSelfTrailerBytes: trailer [
	"Answer an instance of me that is a quick return of the instance (^self)."

	^self newBytes: 3 trailerBytes: trailer nArgs: 0 nTemps: 0 nStack: 0 nLits: 2 primitive: 256
]

{ #category : #'method prototypes' }
SpurBootstrap class >> ContextPartPROTOTYPEactivateReturn: aContext value: value [
	"Activate 'aContext return: value' in place of self, so execution will return to aContext's sender"

	^MethodContext 
		sender: self
		receiver: aContext
		method: MethodContext theReturnMethod
		arguments: {value}
]

{ #category : #'method prototypes' }
SpurBootstrap class >> ContextPartPROTOTYPEdoPrimitive: primitiveIndex method: meth receiver: receiver args: arguments [ 
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrap class >> ContextPartPROTOTYPEisPrimFailToken: anObject [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrap class >> ContextPartPROTOTYPEsend: selector to: rcvr with: arguments lookupIn: lookupClass [
	"Simulate the action of sending a message with selector and arguments
	 to rcvr. The argument, lookupClass, is the class in which to lookup the
	 message.  This is the receiver's class for normal messages, but for super
	 messages it will be some specific class related to the source method."

	| meth primIndex val ctxt |
	(meth := lookupClass lookupSelector: selector) ifNil:
		[^self send: #doesNotUnderstand:
				to: rcvr
				with: {Message selector: selector arguments: arguments}
				lookupIn: lookupClass].
	(primIndex := meth primitive) > 0 ifTrue:
		[val := self doPrimitive: primIndex method: meth receiver: rcvr args: arguments.
		 (self isPrimFailToken: val) ifFalse:
			[^val]].
	(selector == #doesNotUnderstand: and: [lookupClass == ProtoObject]) ifTrue:
		[^self error: 'Simulated message ', arguments first selector, ' not understood'].
	ctxt := MethodContext sender: self receiver: rcvr method: meth arguments: arguments.
	primIndex > 0 ifTrue:
		[ctxt failPrimitiveWith: val].
	^ctxt
]

{ #category : #'method prototypes' }
SpurBootstrap class >> ContextPartPROTOTYPEsend: selector to: rcvr with: arguments super: superFlag [ 
	"Simulate the action of sending a message with selector arguments
	 to rcvr. The argument, superFlag, tells whether the receiver of the
	 message was specified with 'super' in the source method."

	^self send: selector
		to: rcvr
		with: arguments
		lookupIn: (superFlag
					ifTrue: [self method methodClassAssociation value superclass]
					ifFalse: [self objectClass: rcvr])
]

{ #category : #'method prototypes' }
SpurBootstrap class >> ContextPartPROTOTYPEtryNamedPrimitiveIn: aCompiledMethod for: aReceiver withArgs: arguments [
	"Invoke the named primitive for aCompiledMethod, answering its result, or,
	 if the primiitve fails, answering the error code."
	<primitive: 218 error: ec>
	ec ifNotNil:
		["If ec is an integer other than -1 there was a problem with primitive 218,
		  not with the external primitive itself.  -1 indicates a generic failure (where
		  ec should be nil) but ec = nil means primitive 218 is not implemented.  So
		  interpret -1 to mean the external primitive failed with a nil error code."
		 ec isInteger ifTrue:
			[ec = -1
				ifTrue: [ec := nil]
				ifFalse: [self primitiveFailed]]].
	^self class primitiveFailTokenFor: ec
]

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> ContextclassPROTOTYPEallInstances [
	"Answer all instances of the receiver."
	<primitive: 177>
	"The primitive can fail because memory is low.  If so, fall back on the old
	 enumeration code, which gives the system a chance to GC and/or grow.
	 Because aBlock might change the class of inst (for example, using become:),
	 it is essential to compute next before aBlock value: inst.
	 Only count until thisContext since this context has been created only to
	 compute the existing instances."
	| inst insts next |
	insts := WriteStream on: (Array new: 64).
	inst := self someInstance.
	[inst == thisContext or: [inst == nil]] whileFalse:
		[next := inst nextInstance.
		 insts nextPut: inst.
		 inst := next].
	^insts contents
]

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> ContextclassPROTOTYPEallInstancesDo: aBlock [
	"Evaluate aBlock with each of the current instances of the receiver."
	| instances inst next |
	instances := self allInstancesOrNil.
	instances ifNotNil:
		[instances do: aBlock.
		 ^self].
	"allInstancesOrNil can fail because memory is low.  If so, fall back on the old
	 enumeration code.  Because aBlock might change the class of inst (for example,
	 using become:), it is essential to compute next before aBlock value: inst.
	 Only count until thisContext since evaluation of aBlock will create new contexts."
	inst := self someInstance.
	[inst == thisContext or: [inst == nil]] whileFalse:
		[next := inst nextInstance.
		 aBlock value: inst.
		 inst := next]
]

{ #category : #'method prototypes squeak 4.3' }
SpurBootstrap class >> DecompilerPROTOTYPEdecompile: aSelector in: aClass method: aMethod using: aConstructor [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrap class >> EncoderForV3PROTOTYPEcomputeMethodHeaderForNumArgs: numArgs numTemps: numTemps numLits: numLits primitive: primitiveIndex [
	<remove>
]

{ #category : #'method prototypes' }
SpurBootstrap class >> EncoderForV3PlusClosuresPROTOTYPEgenCallPrimitive: primitiveIndex [
	"Since this method has inst var refs the prototype must live in the actual class."

	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrap class >> EncoderForV3PlusClosuresclassPROTOTYPEbytecodeSize: bytecode [
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
SpurBootstrap class >> EncoderForV3PlusClosuresclassPROTOTYPEcallPrimitiveCode [
	"139	11101111	iiiiiiii jjjjjjjj	Call Primitive #iiiiiiii + (jjjjjjjj * 256)"
	^139
]

{ #category : #'method prototypes' }
SpurBootstrap class >> InstructionClientPROTOTYPEcallPrimitive: pimIndex [
	"V3PlusClosures:	139 10001011	iiiiiiii   jjjjjjjj  Call Primitive #iiiiiiii + (jjjjjjjj * 256)
	 NewsqueakV4:		249 11111001	iiiiiiii   jjjjjjjj  Call Primitive #iiiiiiii + (jjjjjjjj * 256)
	 SistaV1:			248 11111000 iiiiiiii mjjjjjjj  Call Primitive #iiiiiiii + ( jjjjjjj * 256)
							m=1 means inlined primitive, no hard return after execution."
]

{ #category : #'method prototypes' }
SpurBootstrap class >> InstructionPrinterPROTOTYPEcallPrimitive: index [
	"Print the callPrimitive."

	self print: 'callPrimtive: ' , index printString
]

{ #category : #'method prototypes squeak 4.3' }
SpurBootstrap class >> InstructionStreamPROTOTYPEinterpretExtension: offset in: method for: client [
	^self interpretV3ClosuresExtension: offset in: method for: client
]

{ #category : #'method prototypes' }
SpurBootstrap class >> InstructionStreamPROTOTYPEinterpretV3ClosuresExtension: offset in: method for: client [
	"Since this method has inst var refs the prototype must live in the actual class."

	<indirect>
]

{ #category : #'method prototypes squeak 4.3' }
SpurBootstrap class >> InstructionStreamPROTOTYPEnextPc: currentByte [
	<indirect>
]

{ #category : #'method prototypes squeak 4.3' }
SpurBootstrap class >> InstructionStreamPROTOTYPEskipCallPrimitive [
	<indirect>
]

{ #category : #'method prototypes squeak' }
SpurBootstrap class >> IntegerclassPROTOTYPEinitialize [
	"Integer initialize"	
	self initializeLowBitPerByteTable
]

{ #category : #'method prototypes squeak 4.3' }
SpurBootstrap class >> MCClassDefinitionPROTOTYPEkindOfSubclass [
	<indirect>
]

{ #category : #'method prototypes squeak 4.3' }
SpurBootstrap class >> MCMethodDefinitionPROTOTYPEinitializeWithClassName: classString classIsMeta: metaBoolean selector: selectorString category: catString timeStamp: timeString source: sourceString [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrap class >> MethodContextPROTOTYPEfailPrimitiveWith: maybePrimFailToken [
	<indirect>
]

{ #category : #'method prototypes squeak' }
SpurBootstrap class >> MethodContextclassPROTOTYPEallInstances [
	"Answer all instances of the receiver."
	<primitive: 177>
	"The primitive can fail because memory is low.  If so, fall back on the old
	 enumeration code, which gives the system a chance to GC and/or grow.
	 Because aBlock might change the class of inst (for example, using become:),
	 it is essential to compute next before aBlock value: inst.
	 Only count until thisContext since this context has been created only to
	 compute the existing instances."
	| inst insts next |
	insts := WriteStream on: (Array new: 64).
	inst := self someInstance.
	[inst == thisContext or: [inst == nil]] whileFalse:
		[next := inst nextInstance.
		 insts nextPut: inst.
		 inst := next].
	^insts contents
]

{ #category : #'method prototypes squeak' }
SpurBootstrap class >> MethodContextclassPROTOTYPEallInstancesDo: aBlock [
	"Evaluate aBlock with each of the current instances of the receiver."
	| instances inst next |
	instances := self allInstancesOrNil.
	instances ifNotNil:
		[instances do: aBlock.
		 ^self].
	"allInstancesOrNil can fail because memory is low.  If so, fall back on the old
	 enumeration code.  Because aBlock might change the class of inst (for example,
	 using become:), it is essential to compute next before aBlock value: inst.
	 Only count until thisContext since evaluation of aBlock will create new contexts."
	inst := self someInstance.
	[inst == thisContext or: [inst == nil]] whileFalse:
		[next := inst nextInstance.
		 aBlock value: inst.
		 inst := next]
]

{ #category : #'method prototypes' }
SpurBootstrap class >> MethodNodeOLDSQUEAKPROTOTYPEgenerate: trailer [ 
	"The receiver is the root of a parse tree. Answer a CompiledMethod.
	 The argument, trailer, is arbitrary but is typically either the reference
	 to the source code that is stored with every CompiledMethod, or an
	 encoding of the method's temporary names."

	^self generate: trailer using: CompiledMethod
]

{ #category : #'method prototypes' }
SpurBootstrap class >> MethodNodePROTOTYPEgenerate: trailer using: aCompiledMethodClass [
	"Since this method has inst var refs the prototype must live in the actual class."

	<indirect>
]

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> ProtoObjectPROTOTYPEidentityHash [
	"Answer a SmallInteger whose value is related to the receiver's identity.
	 This method must not be overridden, except by SmallInteger.  As of
	 2014, the 32-bit Spur VM has 22 bits of hash and 31-bit SmallIntegers
	 (30 bits + 1 sign bit).  Shifting by 8 will not create large integers.
	
	 Do not override."

	^self basicIdentityHash bitShift: 8
]

{ #category : #'method prototypes squeak' }
SpurBootstrap class >> ProtoObjectPROTOTYPEscaledIdentityHash [
	"For identityHash values returned by primitive 75, answer
	 such values times 2^8.  Otherwise, match the existing
	 identityHash implementation"

	^self identityHash * 256 "bitShift: 8"
]

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> SlotClassBuilderPROTOTYPEcomputeFormat: type instSize: newInstSize forSuper: newSuper ccIndex: ccIndex [
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

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> SlotClassBuilderPROTOTYPEformat: nInstVars variable: isVar words: isWords pointers: isPointers weak: isWeak [
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
									ifTrue: [isWords ifTrue: [12] ifFalse: [16]]
									ifFalse: [7]]].
	^(instSpec bitShift: 16) + nInstVars
]

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> SlotClassBuilderPROTOTYPEsuperclass: aClass
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

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> SlotClassBuilderPROTOTYPEupdate: oldClass to: newClass [
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
SpurBootstrap class >> SmallIntegerPROTOTYPEasCharacter [
	<primitive: 170>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> SmalltalkImagePROTOTYPEcompactClassesArray [
	"Smalltalk compactClassesArray"
	"Backward-compatibility support.  Spur does not have compact classes."
	^{}
]

{ #category : #'method prototypes' }
SpurBootstrap class >> SmalltalkImagePROTOTYPEgrowMemoryByAtLeast: numBytes [
	"Grow memory by at least the requested number of bytes.
	 Primitive.  Essential. Fail if no memory is available."
	<primitive: 180>
	(numBytes isInteger and: [numBytes > 0]) ifTrue:
		[OutOfMemory signal].
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> SmalltalkImagePROTOTYPEmaxIdentityHash [
	"Answer the maximum identityHash value supported by the VM."
	<primitive: 176>
	^self primitiveFailed
]

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> SmalltalkImagePROTOTYPEnewSpecialObjectsArray [
	"Smalltalk recreateSpecialObjectsArray"
	
	"To external package developers:
	**** DO NOT OVERRIDE THIS METHOD.  *****
	If you are writing a plugin and need additional special object(s) for your own use, 
	use addGCRoot() function and use own, separate special objects registry "
	
	"The Special Objects Array is an array of objects used by the Squeak virtual machine.
	 Its contents are critical and accesses to it by the VM are unchecked, so don't even
	 think of playing here unless you know what you are doing."
	| newArray |
	newArray := Array new: 60.
	"Nil false and true get used throughout the interpreter"
	newArray at: 1 put: nil.
	newArray at: 2 put: false.
	newArray at: 3 put: true.
	"This association holds the active process (a ProcessScheduler)"
	newArray at: 4 put: (self globals associationAt: #Processor).
	"Numerous classes below used for type checking and instantiation"
	newArray at: 5 put: Bitmap.
	newArray at: 6 put: SmallInteger.
	newArray at: 7 put: ByteString.
	newArray at: 8 put: Array.
	newArray at: 9 put: Smalltalk.
	newArray at: 10 put: Float.
	newArray at: 11 put: (self globals at: #MethodContext ifAbsent: [self globals at: #Context]).
	newArray at: 12 put: nil. "was BlockContext."
	newArray at: 13 put: Point.
	newArray at: 14 put: LargePositiveInteger.
	newArray at: 15 put: Display.
	newArray at: 16 put: Message.
	newArray at: 17 put: CompiledMethod.
	newArray at: 18 put: ((self primitiveGetSpecialObjectsArray at: 18) ifNil: [Semaphore new]). "low space Semaphore"
	newArray at: 19 put: Semaphore.
	newArray at: 20 put: Character.
	newArray at: 21 put: #doesNotUnderstand:.
	newArray at: 22 put: #cannotReturn:.
	newArray at: 23 put: nil. "This is the process signalling low space."
	"An array of the 32 selectors that are compiled as special bytecodes,
	 paired alternately with the number of arguments each takes."
	newArray at: 24 put: #(	#+ 1 #- 1 #< 1 #> 1 #<= 1 #>= 1 #= 1 #~= 1
							#* 1 #/ 1 #\\ 1 #@ 1 #bitShift: 1 #// 1 #bitAnd: 1 #bitOr: 1
							#at: 1 #at:put: 2 #size 0 #next 0 #nextPut: 1 #atEnd 0 #== 1 #class 0
							#blockCopy: 1 #value 0 #value: 1 #do: 1 #new 0 #new: 1 #x 0 #y 0 ).
	"An array of the 255 Characters in ascii order.
	 Cog inlines table into machine code at: prim so do not regenerate it.
	 This is nil in Spur, which has immediate Characters."
	newArray at: 25 put: (self primitiveGetSpecialObjectsArray at: 25).
	newArray at: 26 put: #mustBeBoolean.
	newArray at: 27 put: ByteArray.
	newArray at: 28 put: Process.
	"An array of up to 31 classes whose instances will have compact headers; an empty array in Spur"
	newArray at: 29 put: self compactClassesArray.
	newArray at: 30 put: ((self primitiveGetSpecialObjectsArray at: 30) ifNil: [Semaphore new]). "delay Semaphore"
	newArray at: 31 put: ((self primitiveGetSpecialObjectsArray at: 31) ifNil: [Semaphore new]). "user interrupt Semaphore"
	"Entries 32 - 34 unreferenced. Previously these contained prototype instances to be copied for fast initialization"
	newArray at: 32 put: nil. "was the prototype Float"
	newArray at: 33 put: nil. "was the prototype 4-byte LargePositiveInteger"
	newArray at: 34 put: nil. "was the prototype Point"
	newArray at: 35 put: #cannotInterpret:.
	newArray at: 36 put: nil. "was the prototype MethodContext"
	newArray at: 37 put: BlockClosure.
	newArray at: 38 put: nil. "was the prototype BlockContext"
	"array of objects referred to by external code"
	newArray at: 39 put: (self primitiveGetSpecialObjectsArray at: 39).	"external semaphores"
	newArray at: 40 put: nil. "Reserved for Mutex in Cog VMs"
	newArray at: 41 put: ((self primitiveGetSpecialObjectsArray at: 41) ifNil: [LinkedList new]). "Reserved for a LinkedList instance for overlapped calls in CogMT"
	newArray at: 42 put: ((self primitiveGetSpecialObjectsArray at: 42) ifNil: [Semaphore new]). "finalization Semaphore"
	newArray at: 43 put: LargeNegativeInteger.
	"External objects for callout.
	 Note: Written so that one can actually completely remove the FFI."
	newArray at: 44 put: (self at: #ExternalAddress ifAbsent: []).
	newArray at: 45 put: (self at: #ExternalStructure ifAbsent: []).
	newArray at: 46 put: (self at: #ExternalData ifAbsent: []).
	newArray at: 47 put: (self at: #ExternalFunction ifAbsent: []).
	newArray at: 48 put: (self at: #ExternalLibrary ifAbsent: []).
	newArray at: 49 put: #aboutToReturn:through:.
	newArray at: 50 put: #run:with:in:.
	"51 reserved for immutability message"
	newArray at: 51 put: #attemptToAssign:withIndex:.
	newArray at: 52 put: #(nil "nil => generic error" #'bad receiver'
							#'bad argument' #'bad index'
							#'bad number of arguments'
							#'inappropriate operation'  #'unsupported operation'
							#'no modification' #'insufficient object memory'
							#'insufficient C memory' #'not found' #'bad method'
							#'internal error in named primitive machinery'
							#'object may move' #'resource limit exceeded'
							#'object is pinned' #'primitive write beyond end of object').
	"53 to 55 are for Alien"
	newArray at: 53 put: (self at: #Alien ifAbsent: []).
	newArray at: 54 put: #invokeCallbackContext::. "use invokeCallback:stack:registers:jmpbuf: for old Alien callbacks."
	newArray at: 55 put: (self at: #UnsafeAlien ifAbsent: []).

	"Used to be WeakFinalizationList for WeakFinalizationList hasNewFinalization, obsoleted by ephemeron support."
	newArray at: 56 put: nil.

	"reserved for foreign callback process"
	newArray at: 57 put: (self primitiveGetSpecialObjectsArray at: 57 ifAbsent: []).

	newArray at: 58 put: #unusedBytecode.
	"59 reserved for Sista counter tripped message"
	newArray at: 59 put: #conditionalBranchCounterTrippedOn:.
	"60 reserved for Sista class trap message"
	newArray at: 60 put: #classTrapFor:.

	^newArray
]

{ #category : #'method prototypes squeak' }
SpurBootstrap class >> SmalltalkImagePROTOTYPErecreateSpecialObjectsArray [
	"Smalltalk recreateSpecialObjectsArray"
	
	"To external package developers:
	**** DO NOT OVERRIDE THIS METHOD.  *****
	If you are writing a plugin and need additional special object(s) for your own use, 
	use addGCRoot() function and use own, separate special objects registry "
	
	"The Special Objects Array is an array of objects used by the Squeak virtual machine.
	 Its contents are critical and accesses to it by the VM are unchecked, so don't even
	 think of playing here unless you know what you are doing."
	| newArray |
	newArray := Array new: 60.
	"Nil false and true get used throughout the interpreter"
	newArray at: 1 put: nil.
	newArray at: 2 put: false.
	newArray at: 3 put: true.
	"This association holds the active process (a ProcessScheduler)"
	newArray at: 4 put: (self specialObjectsArray at: 4) "(self bindingOf: #Processor) but it answers an Alias".
	"Numerous classes below used for type checking and instantiation"
	newArray at: 5 put: Bitmap.
	newArray at: 6 put: SmallInteger.
	newArray at: 7 put: ByteString.
	newArray at: 8 put: Array.
	newArray at: 9 put: Smalltalk.
	newArray at: 10 put: Float.
	newArray at: 11 put: (self globals at: #MethodContext ifAbsent: [self globals at: #Context]).
	newArray at: 12 put: nil. "was BlockContext."
	newArray at: 13 put: Point.
	newArray at: 14 put: LargePositiveInteger.
	newArray at: 15 put: Display.
	newArray at: 16 put: Message.
	newArray at: 17 put: CompiledMethod.
	newArray at: 18 put: ((self specialObjectsArray at: 18) ifNil: [Semaphore new]). "low space Semaphore"
	newArray at: 19 put: Semaphore.
	newArray at: 20 put: Character.
	newArray at: 21 put: #doesNotUnderstand:.
	newArray at: 22 put: #cannotReturn:.
	newArray at: 23 put: nil. "This is the process signalling low space."
	"An array of the 32 selectors that are compiled as special bytecodes,
	 paired alternately with the number of arguments each takes."
	newArray at: 24 put: #(	#+ 1 #- 1 #< 1 #> 1 #<= 1 #>= 1 #= 1 #~= 1
							#* 1 #/ 1 #\\ 1 #@ 1 #bitShift: 1 #// 1 #bitAnd: 1 #bitOr: 1
							#at: 1 #at:put: 2 #size 0 #next 0 #nextPut: 1 #atEnd 0 #== 1 #class 0
							#blockCopy: 1 #value 0 #value: 1 #do: 1 #new 0 #new: 1 #x 0 #y 0 ).
	"An array of the 255 Characters in ascii order.
	 Cog inlines table into machine code at: prim so do not regenerate it.
	 This is nil in Spur, which has immediate Characters."
	newArray at: 25 put: (self specialObjectsArray at: 25).
	newArray at: 26 put: #mustBeBoolean.
	newArray at: 27 put: ByteArray.
	newArray at: 28 put: Process.
	"An array of up to 31 classes whose instances will have compact headers; an empty array in Spur"
	newArray at: 29 put: self compactClassesArray.
	newArray at: 30 put: ((self specialObjectsArray at: 30) ifNil: [Semaphore new]). "delay Semaphore"
	newArray at: 31 put: ((self specialObjectsArray at: 31) ifNil: [Semaphore new]). "user interrupt Semaphore"
	"Entries 32 - 34 unreferenced. Previously these contained prototype instances to be copied for fast initialization"
	newArray at: 32 put: nil. "was the prototype Float"
	newArray at: 33 put: nil. "was the prototype 4-byte LargePositiveInteger"
	newArray at: 34 put: nil. "was the prototype Point"
	newArray at: 35 put: #cannotInterpret:.
	newArray at: 36 put: nil. "was the prototype MethodContext"
	newArray at: 37 put: BlockClosure.
	newArray at: 38 put: nil. "was the prototype BlockContext"
	"array of objects referred to by external code"
	newArray at: 39 put: (self specialObjectsArray at: 39).	"external semaphores"
	newArray at: 40 put: nil. "Reserved for Mutex in Cog VMs"
	newArray at: 41 put: ((self specialObjectsArray at: 41) ifNil: [LinkedList new]). "Reserved for a LinkedList instance for overlapped calls in CogMT"
	newArray at: 42 put: ((self specialObjectsArray at: 42) ifNil: [Semaphore new]). "finalization Semaphore"
	newArray at: 43 put: LargeNegativeInteger.
	"External objects for callout.
	 Note: Written so that one can actually completely remove the FFI."
	newArray at: 44 put: (self at: #ExternalAddress ifAbsent: []).
	newArray at: 45 put: (self at: #ExternalStructure ifAbsent: []).
	newArray at: 46 put: (self at: #ExternalData ifAbsent: []).
	newArray at: 47 put: (self at: #ExternalFunction ifAbsent: []).
	newArray at: 48 put: (self at: #ExternalLibrary ifAbsent: []).
	newArray at: 49 put: #aboutToReturn:through:.
	newArray at: 50 put: #run:with:in:.
	"51 reserved for immutability message"
	newArray at: 51 put: #attemptToAssign:withIndex:.
	newArray at: 52 put: #(nil "nil => generic error" #'bad receiver'
							#'bad argument' #'bad index'
							#'bad number of arguments'
							#'inappropriate operation'  #'unsupported operation'
							#'no modification' #'insufficient object memory'
							#'insufficient C memory' #'not found' #'bad method'
							#'internal error in named primitive machinery'
							#'object may move' #'resource limit exceeded'
							#'object is pinned' #'primitive write beyond end of object').
	"53 to 55 are for Alien"
	newArray at: 53 put: (self at: #Alien ifAbsent: []).
	newArray at: 54 put: #invokeCallbackContext::. "use invokeCallback:stack:registers:jmpbuf: for old Alien callbacks."
	newArray at: 55 put: (self at: #UnsafeAlien ifAbsent: []).

	"Used to be WeakFinalizationList for WeakFinalizationList hasNewFinalization, obsoleted by ephemeron support."
	newArray at: 56 put: nil.

	"reserved for foreign callback process"
	newArray at: 57 put: (self specialObjectsArray at: 57 ifAbsent: []).

	newArray at: 58 put: #unusedBytecode.
	"59 reserved for Sista counter tripped message"
	newArray at: 59 put: #conditionalBranchCounterTrippedOn:.
	"60 reserved for Sista class trap message"
	newArray at: 60 put: #classTrapFor:.

	"Now replace the interpreter's reference in one atomic operation"
	self specialObjectsArray becomeForward: newArray
]

{ #category : #'method prototypes squeak' }
SpurBootstrap class >> SmalltalkImagePROTOTYPEsetGCParameters [
	"Adjust the VM's default GC parameters to avoid too much tenuring.
	 Maybe this should be left to the VM?"

	| proportion edenSize survivorSize averageObjectSize numObjects |
	proportion := 0.9. "tenure when 90% of pastSpace is full"
	edenSize := SmalltalkImage current vmParameterAt: 44.
	survivorSize := edenSize / 5.0. "David's paper uses 140Kb eden + 2 x 28kb survivor spaces; Spur uses the same ratios :-)"
	averageObjectSize := 8 * self wordSize. "a good approximation"
	numObjects := (proportion * survivorSize / averageObjectSize) rounded.
	SmalltalkImage current vmParameterAt: 6 put: numObjects  "tenure when more than this many objects survive the GC"
]

{ #category : #'method prototypes' }
SpurBootstrap class >> SpaceTallyPROTOTYPEspaceForInstancesOf: aClass [
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
SpurBootstrap class >> SystemDictionaryPROTOTYPEgrowMemoryByAtLeast: numBytes [
	"Grow memory by at least the requested number of bytes.
	 Primitive.  Fail if no memory is available.  Essential."
	<primitive: 180>
	^(numBytes isInteger and: [numBytes > 0])
		ifTrue: [OutOfMemory signal]
		ifFalse: [self primitiveFailed]
]

{ #category : #'method prototypes' }
SpurBootstrap class >> SystemDictionaryPROTOTYPEmaxIdentityHash [
	"Answer the maximum identityHash value supported by the VM."
	<primitive: 176>
	^self primitiveFailed
]

{ #category : #'method prototypes squeak' }
SpurBootstrap class >> SystemDictionaryPROTOTYPEsetGCParameters [
	"Adjust the VM's default GC parameters to avoid too much tenuring.
	 Maybe this should be left to the VM?"

	| proportion edenSize survivorSize averageObjectSize numObjects |
	proportion := 0.9. "tenure when 90% of pastSpace is full"
	edenSize := SmalltalkImage current vmParameterAt: 44.
	survivorSize := edenSize / 5.0. "David's paper uses 140Kb eden + 2 x 28kb survivor spaces; Spur uses the same ratios :-)"
	averageObjectSize := 8 * self wordSize. "a good approximation"
	numObjects := (proportion * survivorSize / averageObjectSize) rounded.
	SmalltalkImage current vmParameterAt: 6 put: numObjects  "tenure when more than this many objects survive the GC"
]

{ #category : #'method prototypes' }
SpurBootstrap class >> SystemNavigationPROTOTYPEallObjects [
	"Answer an Array of all objects in the system.  Fail if
	 there isn't enough memory to instantiate the result."
	<primitive: 178>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrap class >> SystemNavigationPROTOTYPEallObjectsDo: aBlock [ 
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
SpurBootstrap class >> SystemNavigationPROTOTYPEallObjectsOrNil [
	"Answer an Array of all objects in the system.  Fail if there isn't
	 enough memory to instantiate the result and answer nil."
	<primitive: 178>
	^nil
]

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> TraitBehaviorPROTOTYPEallInstances [
	"Answer all instances of the receiver."
	self error: 'Traits does not have instances.'
]

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> TraitBehaviorPROTOTYPEallInstancesDo: aBlock [
	"Evaluate aBlock with each of the current instances of the receiver."
	self error: 'Traits does not have instances.'
]

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> TraitBehaviorPROTOTYPEinstSpec [
	"Answer the instance specification part of the format that defines what kind of object
	 an instance of the receiver is.  The formats are
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
	^(format bitShift: -16) bitAnd: 16r1F
]

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> TraitBehaviorPROTOTYPEisBits [
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

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> TraitBehaviorPROTOTYPEisBytes [
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

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> TraitBehaviorPROTOTYPEisEphemeronClass [
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

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> TraitBehaviorPROTOTYPEisImmediateClass [
	"Answer whether the receiver has immediate instances.  Immediate instances
	 store their value in their object pointer, not in an object body.  Hence immediates
	 take no space and are immutable.  The immediates are distinguished by tag bits
	 in the pointer. They include SmallIntegers and Characters.  Hence in the 32-bit
	 system SmallIntegers are 31-bit signed integers and Characters are 30-bit
	 unsigned character codes."
	^self instSpec = 7
]

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> TraitBehaviorPROTOTYPEisVariable [
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

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> TraitBehaviorPROTOTYPEkindOfSubclass [
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

{ #category : #'method prototypes pharo' }
SpurBootstrap class >> VirtualMachinePROTOTYPEsetGCParameters [
	"Adjust the VM's default GC parameters to avoid too much tenuring.
	 Maybe this should be left to the VM?"

	| proportion edenSize survivorSize averageObjectSize numObjects |
	proportion := 0.9. "tenure when 90% of pastSpace is full"
	edenSize := self parameterAt: 44.
	survivorSize := edenSize / 5.0. "David's paper uses 140Kb eden + 2 x 28kb survivor spaces; Spur uses the same ratios :-)"
	averageObjectSize := 8 * self wordSize. "a good approximation"
	numObjects := (proportion * survivorSize / averageObjectSize) rounded.
	self tenuringThreshold: numObjects  "tenure when more than this many objects survive the GC"
]

{ #category : #'method prototypes' }
SpurBootstrap class >> WideStringPROTOTYPEat: index [
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
SpurBootstrap class >> WideStringPROTOTYPEat: index put: aCharacter [
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

{ #category : #utilities }
SpurBootstrap class >> bootstrapImage: imageFileNameOrBaseName type: typeName [
	"SpurBootstrap bootstrapImage: '/Users/eliot/Squeak/Squeak4.5/Squeak4.5-13680'"
	| imageFileBaseName imageFormat |
	imageFileBaseName := (imageFileNameOrBaseName endsWith: '.image')
								ifTrue: [imageFileNameOrBaseName allButLast: 6]
								ifFalse: [imageFileNameOrBaseName].
	imageFormat := ImageFormat fromFile: imageFileBaseName, '.image'.
	imageFormat requiresClosureSupport ifFalse:
		[self error: 'Can''t bootstrap this image since Spur assumes closure support.'].
	imageFormat requiresSpurSupport ifTrue:
		[self error: 'This image is already in Spur format.'].
	imageFormat is32Bit ifTrue:
		[^SpurBootstrap32 new bootstrapImage: imageFileBaseName type: typeName].
	self error: '64-bit support and 64-bit generation as-yet-unimplemented'
]

{ #category : #utilities }
SpurBootstrap class >> bootstrapOldSqueakImage: imageFileBaseName [
	"Try asnd bootstrap a pre-CompiledMethodTrailer Squeak image."
	self bootstrapImage: imageFileBaseName type: #('squeak' 'old squeak')
]

{ #category : #utilities }
SpurBootstrap class >> bootstrapPharoImage: imageFileBaseName [
	self bootstrapImage: imageFileBaseName type: 'pharo'
]

{ #category : #utilities }
SpurBootstrap class >> bootstrapSqueakImage: imageFileBaseName [
	self bootstrapImage: imageFileBaseName type: 'squeak'
]

{ #category : #'method prototype categorization' }
SpurBootstrap class >> categoryForClass: className meta: isMeta selector: selector [ 
	^(isMeta
			ifTrue: [{ className. #class. selector }]
			ifFalse: [{ className. selector }])
		caseOf: {
			[#(Behavior allInstancesOrNil)]					-> [#enumerating].
			[#(Behavior byteSizeOfInstance)]				-> [#'accessing instances and variables'].
			[#(Behavior byteSizeOfInstanceOfSize:)]		-> [#'accessing instances and variables'].
			[#(Behavior elementSize)]						-> [#'accessing instances and variables'].
			[#(Behavior handleFailingBasicNew)]			-> [#private].
			[#(Behavior handleFailingBasicNew:)]			-> [#private].
			[#(Behavior handleFailingFailingBasicNew)]		-> [#private].
			[#(Behavior handleFailingFailingBasicNew:)]		-> [#private].
			[#(Behavior identityHash)]						-> [#comparing].
			[#(Behavior isEphemeronClass)]				-> [#testing].
			[#(Behavior isImmediateClass)]					-> [#testing].
			[#(Character identityHash)]						-> [#comparing].
			[#(Class immediateSubclass:instanceVariableNames:classVariableNames:poolDictionaries:category:)]
															-> [#'subclass creation'].
			[#(ClassBuilder superclass:immediateSubclass:instanceVariableNames:classVariableNames:poolDictionaries:category:)]
															-> [#public].
			[#(CompiledMethod class handleFailingFailingNewMethod:header:)]
															-> [#private].
			[#(CompiledMethod class handleFailingNewMethod:header:)]
															-> [#private].
			[#(Context class allInstances)]					-> [#enumerating].
			[#(Context class allInstancesDo:)]				-> [#enumerating].
			[#(Context failPrimitiveWith:)]					-> [#'system simulation'].
			[#(Context isPrimFailToken:)]					-> [#private].
			[#(Context send:to:with:lookupIn:)]				-> [#controlling].
			[#(ContextPart isPrimFailToken:)]				-> [#private].
			[#(ContextPart send:to:with:lookupIn:)]			-> [#controlling].
			[#(CompiledMethod class headerFlagForEncoder:)]
															-> [#'method encoding'].
			[#(CompiledMethod class installPrimaryBytecodeSet:)]
															-> [#'class initialization'].
			[#(CompiledMethod class installSecondaryBytecodeSet:)]
															-> [#'class initialization'].
			[#(EncoderForV3PlusClosures genCallPrimitive:)]
															-> [#'bytecode generation'].
			[#(EncoderForV3PlusClosures class callPrimitiveCode)]
															-> [#'bytecode decoding'].
			[#(MethodContext failPrimitiveWith:)]			-> [#'system simulation'].
			[#(MethodContext class allInstances)]			-> [#enumerating].
			[#(MethodContext class allInstancesDo:)]		-> [#enumerating].
			[#(SmallInteger asCharacter)]					-> [#converting].
			[#(SmalltalkImage growMemoryByAtLeast:)]	-> [#'memory space'].
			[#(SmalltalkImage maxIdentityHash)]			-> [#'system attributes'].
			[#(SystemDictionary growMemoryByAtLeast:)]	-> [#'memory space'].
			[#(SystemDictionary maxIdentityHash)]			-> [#'system attributes'].
			[#(SystemDictionary setGCParameters)]		-> [#'snapshot and quit'].
			[#(SystemNavigation allObjects)]				-> [#query].
			[#(SystemNavigation allObjectsOrNil)]			-> [#query].
			 }
		otherwise:
			[Transcript nextPutAll: className.
			 isMeta ifTrue: [Transcript nextPutAll: ' class'].
			 Transcript nextPutAll: '>>'; store: selector; nextPutAll: ' is unclassified'; cr; flush.
			 ^Categorizer default]
]

{ #category : #debugger }
SpurBootstrap class >> defaultIntegerBaseInDebugger [
	^16
]

{ #category : #utilities }
SpurBootstrap class >> isolatedPrototypes [
	"SpurBootstrap isolatedPrototypes"
	| prototypes |
	prototypes := (self systemNavigation allMethodsSelect:
						[:m| m selector includesSubString: 'PROTOTYPE'])
							collect: [:mr| mr compiledMethod].
	^prototypes select:
		[:m|
		m methodClass == self class
			ifTrue:
				[(m pragmaAt: #indirect) notNil
				  and: [prototypes noneSatisfy:
						[:p|
						p selector == m selector
						and: [p methodClass ~~ m methodClass]]]]
			ifFalse:
				[prototypes noneSatisfy:
					[:p|
					p selector == m selector
					and: [p methodClass == self class
					and: [(p pragmaAt: #indirect) notNil]]]]]
]

{ #category : #tests }
SpurBootstrap class >> testComputeFormat [
	"self testComputeFormat"
	#(	(normal 0)
		(bytes 16)
		(words 12)
		(variable 2)
		(weak 4)
		(ephemeron 5)
		(immediate 7)
		(compiledMethod 24)) do:
		[:tuple|
		 [:type :instSpec| | fmt |
		   fmt := [self ClassBuilderPROTOTYPEcomputeFormat: type instSize: 0 forSuper: Object ccIndex: 0]
					on: MessageNotUnderstood
					do: [:ex|
						ex message selector ~~ #format:variable:words:pointers:weak: ifTrue:
							[ex pass].
						self perform: #ClassBuilderPROTOTYPEformat:variable:words:pointers:weak:
							withArguments: ex message arguments].
		   self assert: (fmt >> 16 = instSpec
						or: [type = #compiledMethod and: [fmt = CompiledMethod format]]).
		 ] valueWithArguments: tuple]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> addMissingClassVars: classVars [
	"Add any missing class vars given classVars, a Dictionary from nonMetaClass to binding.
	 Initialize any classes that get inst vars added."
	| addClassVarNameSym bindingOfSym |
	classVars isEmpty ifTrue:
		[^self].
	addClassVarNameSym := self findSymbol: #addClassVarName:.
	addClassVarNameSym ifNil: 
		[addClassVarNameSym := self findSymbol: #addClassVarNamed:].
	bindingOfSym := self findSymbol: #bindingOf:.
	classVars keysAndValuesDo:
		[:binding :class| 
		Transcript cr;  nextPutAll: 'ADDING CLASS VAR '; store: binding key; nextPutAll: ' TO '; print: class; flush.
		self interpreter: oldInterpreter
			object: (self oldClassOopFor: class)
			perform: addClassVarNameSym
			withArguments: {oldHeap stringForCString: binding key}.
		literalMap
			at: binding
			put: (self interpreter: oldInterpreter
					object: (self oldClassOopFor: class)
					perform: bindingOfSym
					withArguments: {self findSymbol: binding key})].
	toBeInitialized := classVars asSet
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> addNewMethods [
	"Get the simulator to add any and all missing methods immediately."
	| cmaiaSym basSym |
	cmaiaSym := self findSymbol: #compiledMethodAt:ifAbsent:.
	basSym := self findSymbol: #basicAddSelector:withMethod:.
	basSym ifNil:
		[basSym := self findSymbol: #addSelectorSilently:withMethod:].
	self allPrototypeClassNamesDo:
		[:sym :symIsMeta|
		(self findClassNamed: (literalMap at: sym))
			ifNil: [Transcript
					cr;
					nextPutAll: 'not installing any methods for ';
					nextPutAll: sym;
					nextPutAll: '; class not found in image';
					flush.]
			ifNotNil:
				[:theClass| | class |
				class := symIsMeta ifTrue: [oldHeap fetchClassOfNonImm: theClass] ifFalse: [theClass].
				self prototypeClassNameMetaSelectorMethodDo:
					[:className :isMeta :selector :method| | methodOrNil |
					(className = sym
					 and: [symIsMeta = isMeta
					 and: [(method pragmaAt: #remove) isNil]]) ifTrue:
						["probe method dictionary of the class for each method, installing a dummy if not found."
						 "Transcript cr; nextPutAll: 'checking for '; nextPutAll: selector; flush."
						 methodOrNil := self interpreter: oldInterpreter
											object: class
											perform: cmaiaSym
											withArguments: {literalMap at: selector. oldHeap nilObject}.
						 methodOrNil = oldHeap nilObject
							ifTrue: "no method.  install the real thing now"
								[Transcript
									cr;
									nextPutAll: 'installing ';
									nextPutAll: className;
									nextPutAll: (isMeta ifTrue: [' class>>'] ifFalse: ['>>']);
									store: selector;
									flush.
								 self interpreter: oldInterpreter
									object: class
									perform: basSym
									withArguments: { literalMap at: selector.
													   self installableMethodFor: method
														selector: selector
														className: className
														isMeta: isMeta}.
								installedPrototypes add: method selector]
							ifFalse: "existing method; collect the methodClassAssociation; its needed later"
								[methodClasses add: (oldInterpreter methodClassAssociationOf: methodOrNil)]]]]]
]

{ #category : #'method prototypes' }
SpurBootstrap >> allPrototypeClassNamesDo: aBlock [
	"self basicNew allPrototypeClassNames"
	| pairs |
	pairs := Set new.
	self prototypeClassNameMetaSelectorMethodDo:
		[:className :isMeta :selector :method |
		pairs add: {className. isMeta}].
	pairs do: [:pair| aBlock value: pair first value: pair last]
]

{ #category : #'method prototypes' }
SpurBootstrap >> allPrototypeMethodSymbols [
	"self basicNew allPrototypeMethodSymbols"
	| symbols |
	self assert: SpurBootstrap isolatedPrototypes isEmpty.
	symbols := Set new.
	self prototypeClassNameMetaSelectorMethodDo:
		[:className :isMeta :selector :method | | adder |
		symbols
			add: className;
			add: selector.	
		adder := [:lit|
				   (lit isSymbol and: [lit ~~ method selector]) ifTrue: [symbols add: lit].
				   lit isArray ifTrue: [lit do: adder]].
		method literals do: adder].
	^symbols
]

{ #category : #'method prototypes' }
SpurBootstrap >> allPrototypeSelectors [
	"Answer all prototype selectors, including those marked <remove>"
	^imageTypes
		inject: (SpurBootstrap class organization listAtCategoryNamed: #'method prototypes')
		into: [:prototypes :type|
				prototypes, (SpurBootstrap class organization listAtCategoryNamed: #'method prototypes ', type)]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> allocateClassTable [
	"Allocate the root of the classTable plus enough pages to accomodate all classes in
	 the classToIndex map.  Don't fill in the entries yet; the classes have yet to be cloned."
	| tableRoot page maxSize numPages |
	tableRoot := newHeap
					allocateSlots: newHeap classTableRootSlots + newHeap hiddenRootSlots
					format: newHeap arrayFormat
					classIndex: newHeap arrayClassIndexPun.
	self assert: (newHeap numSlotsOf: tableRoot) = (newHeap classTableRootSlots + newHeap hiddenRootSlots).
	self assert: (newHeap formatOf: tableRoot) = newHeap arrayFormat.
	self assert: (newHeap classIndexOf: tableRoot) = newHeap arrayClassIndexPun.
	newHeap nilFieldsOf: tableRoot.
	"first page is strong"
	page := newHeap
					allocateSlots: newHeap classTablePageSize
					format: newHeap arrayFormat
					classIndex: newHeap arrayClassIndexPun.
	self assert: (newHeap numSlotsOf: page) = newHeap classTablePageSize.
	self assert: (newHeap formatOf: tableRoot) = newHeap arrayFormat.
	self assert: (newHeap classIndexOf: tableRoot) = newHeap arrayClassIndexPun.
	self assert: (newHeap objectAfter: tableRoot limit: newHeap freeStart) = page.
	lastClassTablePage := page.
	newHeap nilFieldsOf: page.
	newHeap storePointer: 0 ofObject: tableRoot withValue: page.
	newHeap hiddenRootsObj: tableRoot.
	maxSize := classToIndex inject: 0 into: [:a :b| a max: b].
	numPages := (maxSize + newHeap classTableMinorIndexMask / newHeap classTablePageSize) truncated.
	2 to: numPages do:
		[:i|
		page := newHeap
					allocateSlots: newHeap classTablePageSize
					format: newHeap arrayFormat
					classIndex: newHeap arrayClassIndexPun.
		self assert: (newHeap numSlotsOf: page) = newHeap classTablePageSize.
		self assert: (newHeap formatOf: page) = newHeap arrayFormat.
		self assert: (newHeap classIndexOf: page) = newHeap arrayClassIndexPun.
		newHeap fillObj: page numSlots: newHeap classTablePageSize with: newHeap nilObject.
		newHeap storePointer: i - 1 ofObject: tableRoot withValue: page.
		self assert: (newHeap objectAfter: (newHeap fetchPointer: i - 2 ofObject: tableRoot)  limit: newHeap freeStart) = page.
		lastClassTablePage := page].
	"and once again to recompute numClassTablePages post building the class table."
	newHeap instVarNamed: 'numClassTablePages' put: nil.
	newHeap hiddenRootsObj: tableRoot
]

{ #category : #'bootstrap image' }
SpurBootstrap >> allocateFreeLists [
	"Allocate the freeLists array."
	| freeListsOop |
	freeListsOop := newHeap
						allocateSlots: newHeap numFreeLists
						format: newHeap wordIndexableFormat
						classIndex: newHeap wordSizeClassIndexPun.
	self assert: (newHeap objectAfter: newHeap trueObject) = freeListsOop.
	0 to: newHeap numFreeLists - 1 do:
		[:i|
		newHeap
			storePointerUnchecked: freeListsOop
			ofObject: freeListsOop
			withValue: 0]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> bootstrapImage [
	oldHeap fullGC.
	self measureOldHeapPostGC.
	self initMaps.
	Transcript cr; nextPutAll: 'transforming image...'; flush.
	self cloneNilTrueAndFalse.
	self allocateFreeLists.
	self buildClassMap.
	self allocateClassTable.
	self cloneObjects.
	self fillInObjects.
	self fillInClassTable.
	newHeapSize := newHeap freeStart.
	newHeap initializePostBootstrap.
	self measureNewHeapPostInitPostBootstrap
]

{ #category : #'public access' }
SpurBootstrap >> bootstrapImage: imageName [
	(Smalltalk classNamed: #FileReference) ifNotNil:
		[^self bootstrapImageUsingFileReference: imageName].
	(Smalltalk classNamed: #FileDirectory) ifNotNil:
		[^self bootstrapImageUsingFileDirectory: imageName].
	self error: 'at a loss as to what file system support to use'
]

{ #category : #'public access' }
SpurBootstrap >> bootstrapImage: imageName type: typeNameOrArrayOfTypeNames [
	"type can be:
		- 'squeak'
		- {'old squeak' 'squeak' }
		- 'pharo'
		- it might be 'newspeak', if needed (but is not implemented)"
	imageTypes := typeNameOrArrayOfTypeNames isArray
						ifTrue: [typeNameOrArrayOfTypeNames]
						ifFalse: [{typeNameOrArrayOfTypeNames}].
	self bootstrapImage: imageName
	
]

{ #category : #'public access' }
SpurBootstrap >> bootstrapImageUsingFileDirectory: imageName [
	| dirName baseName dir |
	dirName := FileDirectory dirPathFor: imageName.
	baseName := (imageName endsWith: '.image')
					ifTrue: [FileDirectory baseNameFor: imageName]
					ifFalse: [FileDirectory localNameFor: imageName].
	dir := dirName isEmpty ifTrue: [FileDirectory default] ifFalse: [FileDirectory on: dirName].
	self on: (dir fullNameFor: baseName, '.image').
	[self transform]
		on: Halt
		do: [:ex|
			"suppress halts from the usual suspects (development time halts)"
			(#(fullGC compactImage) includes: ex signalerContext sender selector)
				ifTrue: [ex resume]
				ifFalse: [ex pass]].
	self writeSnapshot: (dir fullNameFor: baseName, '-spur.image')
		ofTransformedImage: newHeap
		headerFlags: oldInterpreter getImageHeaderFlags
		screenSize: oldInterpreter savedWindowSize.
	dir deleteFileNamed: baseName, '-spur.changes';
		copyFileNamed: baseName, '.changes' toFileNamed: baseName, '-spur.changes'
]

{ #category : #'public access' }
SpurBootstrap >> bootstrapImageUsingFileReference: imageName [
	| dirName baseName dir |
	dirName := imageName asFileReference parent fullName.
	baseName := (imageName endsWith: '.image')
		ifTrue: [ imageName asFileReference base ]
		ifFalse: [ (imageName, '.image') asFileReference base ].
	dir := dirName asFileReference.
	self on: (dir / (baseName, '.image')) fullName.
	[self transform]
		on: Halt
		do: [:ex|
			"suppress halts from the usual suspects (development time halts)"
			(#(fullGC compactImage) includes: ex signalerContext sender selector)
				ifTrue: [ex resume]
				ifFalse: [ex pass]].
	self writeSnapshot: (dir / (baseName, '-spur.image')) fullName
		ofTransformedImage: newHeap
		headerFlags: oldInterpreter getImageHeaderFlags
		screenSize: oldInterpreter savedWindowSize.
	(dir / (baseName, '.changes')) copyTo: (dir / (baseName, '-spur.changes'))
]

{ #category : #'bootstrap image' }
SpurBootstrap >> buildClassMap [
	"enumerate all objects asking isBehavior:?  (class == Metaclass or class class == Metaclass) doesn't work for Newspeak"
	"Build a map from all classes in oldHeap to a class index.
	 ONLY DEALS WITH CLASSES THAT HAVE INSTANCES!! (can walk superclass chain?  Can walk subclasses set? Can ask class == Metaclass or class class == Metaclass class?)"
	| classes classTableIndex |
	self defineKnownClassIndices.
	classes := classToIndex keys asSet.
	classTableIndex := classToIndex inject: 0 into: [:a :b| a max: b].
	oldHeap allObjectsDo:
		[:oldObj| | oldClass |
		 oldClass := oldHeap fetchClassOfNonImm: oldObj.
		 self assert: (oldHeap isPointersNonImm: oldClass).
		 (classes includes: oldClass) ifFalse:
			[classes add: oldClass.
			 classToIndex at: oldClass put: (classTableIndex := classTableIndex + 1)]]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> checkReshapeOf: ourMethodClasses [
	"Check the shape of all our method classes match the shape of those in the image to be bootstrapped.
	 Use the simulator to redefine any that need it.  Does /not/ reshape metaclasses; these we assume are ok."
	| toReshape |
	toReshape := Set new.
	ourMethodClasses do:
		[:mc|
		(literalMap at: mc binding ifAbsent: []) ifNotNil:
			[:binding|
			(mc ~~ Character "Character will reshape anyway"
			 and: [mc instSize ~= (oldHeap instanceSizeOf: (oldHeap fetchPointer: ValueIndex ofObject: binding))]) ifTrue:
				[toReshape add: mc]]].
	toReshape isEmpty ifTrue:
		[^self].
	"Assume only one class in any subtree needs reshaping.  Fast and loose but gets us there for now."
	toReshape copy do:
		[:class|
		toReshape removeAll: (toReshape select: [:ea| ea inheritsFrom: class])].
	toReshape do:
		[:class|
		Transcript cr;  nextPutAll: 'RESHAPING '; print: class; flush.
		self interpreter: oldInterpreter
			object: (self oldClassOopFor: Compiler)
			perform: (self findSymbol: #evaluate:)
			withArguments: {oldHeap stringForCString: class definition}]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> classMetaclass [
	^classMetaclass ifNil:
		[classMetaclass := oldHeap fetchClassOfNonImm: (oldHeap fetchClassOfNonImm: oldHeap classArray)]
]

{ #category : #'method prototypes' }
SpurBootstrap >> classNameForPrototypeMethod: protoMethod [
	| protoSelector |
	protoSelector := protoMethod selector.
	#('OLDSQUEAKPROTOTYPE' 'SQUEAKPROTOTYPE' 'PHAROPROTOTYPE' 'PROTOTYPE') do:
		[:prototype| | index |
		(index := protoSelector indexOfSubCollection: prototype) ~= 0 ifTrue:
			[^(protoSelector first: index - 1) asSymbol]].
	self error: 'really??'
]

{ #category : #'class indices' }
SpurBootstrap >> classTableSize [
	^newHeap classIndexMask + 1
]

{ #category : #'bootstrap image' }
SpurBootstrap >> clone: oldObj classIndex: classIndex [
	| newObj format numBytes |
	((format := oldHeap formatOf: oldObj) >= oldHeap firstLongFormat
	 and: [numBytes := oldHeap numBytesOf: oldObj.
		format >= oldHeap firstCompiledMethodFormat
		and: [(oldInterpreter primitiveIndexOf: oldObj) > 0]]) ifTrue:
			[numBytes := numBytes + 3].
	newObj := newHeap
				allocateSlots: (format >= oldHeap firstLongFormat
								ifTrue: [newHeap numSlotsForBytes: numBytes]
								ifFalse: [oldHeap numSlotsOf: oldObj])
				format: (self newFormatFor: oldObj numBytes: numBytes)
				classIndex: classIndex.
	reverseMap at: newObj put: oldObj.
	^map at: oldObj put: newObj
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> cloneArrayLiteral: anArray [
	"Currently serves only to clone the #(0 0) literal in SpaceTallyPROTOTYPEspaceForInstancesOf:"
	| array |
	array := oldHeap instantiateClass: (oldHeap splObj: ClassArray) indexableSize: anArray size.
	1 to: anArray size do:
		[:i| | lit |
		lit := anArray at: i.
		lit class caseOf: {
			[SmallInteger] -> [oldHeap
									storePointerUnchecked: i - 1
									ofObject: array
									withValue: (oldHeap integerObjectOf: lit)].
			[ByteSymbol] -> [oldHeap
									storePointer: i - 1
									ofObject: array
									withValue: (self findSymbol: lit)].
			[UndefinedObject] -> [oldHeap
									storePointerUnchecked: i - 1
									ofObject: array
									withValue: oldHeap nilObject] }].
	^array

]

{ #category : #'bootstrap methods' }
SpurBootstrap >> cloneMethodProxy: proxy [ "<VMCompiledMethodProxy>"
	| bytes newMethod delta |
	bytes := proxy size - proxy initialPC + 1.
	delta := proxy primitive > 0
				ifTrue: [3]
				ifFalse: [0].
	newMethod := CompiledMethod
						newMethod: bytes + delta
						header: (self headerForOldMethodHeader: (oldHeap integerObjectOf: proxy header)).
	1 to: proxy numLiterals - 1 do:
		[:i| newMethod literalAt: i put: (proxy literalAt: i)].
	newMethod
		literalAt: proxy numLiterals
		put: (Smalltalk bindingOf: #Character).
	delta > 0 ifTrue:
		[newMethod
			at: newMethod initialPC + 0 put: 139;
			at: newMethod initialPC + 1 put: (proxy primitive bitAnd: 16rFF);
			at: newMethod initialPC + 2 put: (proxy primitive bitShift: -8)].
	proxy initialPC to: proxy size do:
		[:i| newMethod at: i + delta put: (proxy at: i)].
	^newMethod
]

{ #category : #'bootstrap image' }
SpurBootstrap >> cloneNilTrueAndFalse [
	{	oldHeap nilObject.
		oldHeap falseObject.
		oldHeap trueObject. }
		with: (self firstOrdinaryClassIndex to: self firstOrdinaryClassIndex + 2)
		do: [:obj :classIndex|
			classToIndex at: (oldHeap fetchClassOfNonImm: obj) put: classIndex.
			self clone: obj classIndex: classIndex].
	newHeap
		nilObject: (map at: oldHeap nilObject); "needed for nilling objects etc"
		falseObject: (map at: oldHeap falseObject);
		trueObject: (map at: oldHeap trueObject)
]

{ #category : #'bootstrap image' }
SpurBootstrap >> cloneObjects [
	| specialObjectsArray characterClass characterTable compactClasses oldObj oldClass |
	specialObjectsArray := oldHeap specialObjectsOop.
	characterClass := oldHeap classCharacter.
	characterTable := oldHeap characterTable.
	compactClasses := oldHeap splObj: CompactClasses.
	self clone: specialObjectsArray
		classIndex: (classToIndex at: (oldHeap fetchClassOfNonImm: specialObjectsArray)).
	oldObj := oldHeap objectAfter: oldHeap trueObject.
	[oldObj < oldHeap freeStart] whileTrue:
		[oldClass := oldHeap fetchClassOfNonImm: oldObj.
		 (oldObj ~= characterTable
		 and: [oldObj ~= specialObjectsArray
		 and: [oldObj ~= compactClasses
		 and: [oldClass ~= characterClass]]]) ifTrue:
			[self clone: oldObj classIndex: (classToIndex at: oldClass)].
		 oldObj := oldHeap objectAfter: oldObj].
	newHeap
		specialObjectsOop: (map at: oldHeap specialObjectsOop);
		lastHash: oldHeap lastHash
]

{ #category : #testing }
SpurBootstrap >> coHeapFrom: aSpur32BitMMLESimulator [
	| coHeap |
	coHeap := Spur32BitMMLECoSimulator new.
	aSpur32BitMMLESimulator class allInstVarNames do:
		[:ivn|
		coHeap instVarNamed: ivn put: (aSpur32BitMMLESimulator instVarNamed: ivn)].
	coHeap scavenger instVarNamed: 'manager' put: coHeap.
	^coHeap
]

{ #category : #'bootstrap image' }
SpurBootstrap >> compactImage [
	| firstFree lastUsed |
	newHeap allHeapEntitiesDo:
		[:o|
		(newHeap isFreeObject: o)
			ifTrue: [firstFree ifNil: [firstFree := o]]
			ifFalse: [lastUsed := o]].
	lastUsed < firstFree ifTrue: "nothing to do"
		[^self].
	self halt
]

{ #category : #'bootstrap image' }
SpurBootstrap >> convertOldMethodHeader: methodHeader [
	^((oldInterpreter argumentCountOfMethodHeader: methodHeader) << 24)
	 + ((oldInterpreter temporaryCountOfMethodHeader: methodHeader) << 18)
	 + ((oldInterpreter methodHeaderIndicatesLargeFrame: methodHeader) ifTrue: [1 << 17] ifFalse: [0])
	 + ((oldInterpreter methodHeaderHasPrimitive: methodHeader) ifTrue: [1 << 16] ifFalse: [0])
	 + (oldHeap literalCountOfMethodHeader: methodHeader)
]

{ #category : #'class indices' }
SpurBootstrap >> defineKnownClassIndices [
	"The classTable is laid out
		- to make it easy to map immediates to classes; the tag pattern of an immediate is its class index.
		  hence there are two entries for SmallInteger
		- to assign small indices to well-known classes such as Array, Message et al
		- to leave plenty of room for new known classes; hence the first page contains only well-known classes
		- to enable overlaps and avoid conflicts with indices in the specialObjectsArray (?really? eem)
		- to provide a WeakArray pun for the pages of the table itself so that these do not show up as instances of WeakArray"
	| classMethodContext classBlockClosure classMessage "no api method for these" |
	classMessage := oldHeap splObj: (VMObjectIndices bindingOf: #ClassMessage) value.
	classMethodContext := oldHeap splObj: (VMObjectIndices bindingOf: #ClassMethodContext) value.
	classBlockClosure := oldHeap splObj: (VMObjectIndices bindingOf: #ClassBlockClosure) value.
	"c.f. SpurMemoryManager class>>intializeCompactClassIndices".
	classToIndex keysDo:
		[:oldClass|
		self assert: (oldInterpreter addressCouldBeClassObj: oldClass)].
	classToIndex
		at: oldHeap classSmallInteger put: 1; "N.B. must fill-in index 3 manually"
		at: oldHeap classCharacter put: 2;
		"at: oldHeap classSmallInteger put: 3" "N.B. must fill-in index 3 manually"
		"leave room for up to 15 tagged classes"
		"leave room for up to 16 puns"
		at: oldHeap classLargeNegativeInteger put: 32;
		at: oldHeap classLargePositiveInteger put: 33;
		at: oldHeap classFloat put: 34;

		at: "oldHeap" classMessage put: 35;
		at: "oldHeap" classMethodContext put: (classMethodContextIndex := 36);
		at: "oldHeap" classBlockClosure put: (classBlockClosureIndex := 37);

		at: oldHeap classSemaphore put: 48;
		"at: oldHeap classMutex put: 49; see below"

		at: oldHeap classByteArray put: 50;
		at: oldHeap classArray put: 51;
		at: oldHeap classString put: 52;
		at: oldHeap classBitmap put: 53;
		at: oldHeap classPoint put: 54.

	{{oldHeap classMutex. 49}.
	 {oldHeap classExternalAddress. 128}.
	 {oldHeap classExternalData. 129}.
	 {oldHeap classExternalFunction. 130}.
	 {oldHeap classExternalLibrary. 131}.
	 {oldHeap classExternalStructure. 132}.
	 {oldHeap classAlien. 133}.
	 {oldHeap classUnsafeAlien. 134}}
		do: [:pair|
			[:oop :index|
			oop ~= oldHeap nilObject ifTrue:
				[classToIndex at: oop put: index]] valueWithArguments: pair].

	classToIndex keysDo:
		[:oldClass|
		self assert: (oldInterpreter addressCouldBeClassObj: oldClass)]
]

{ #category : #'public access' }
SpurBootstrap >> fileOutPrototypesFor: imageTypeOrArrayOfTypes [
	"SpurBootstrap new fileOutPrototypesFor: 'squeak'"
	| internalStream |
	imageTypes := imageTypeOrArrayOfTypes isString
						ifTrue: [{imageTypeOrArrayOfTypes}]
						ifFalse: [imageTypeOrArrayOfTypes asArray].
	internalStream := WriteStream on: (String new: 1000).
	internalStream header; timeStamp.
	self prototypeClassNameMetaSelectorMethodDo:
		[:className :isMeta :selector :method| | class category preamble source |
		class := Smalltalk classNamed: className.
		isMeta ifTrue: [class := class class].
		(method pragmaAt: #remove)
			ifNil:
				[category := (class organization categoryOfElement: selector) ifNil:
								[self class categoryForClass: className meta: isMeta selector: selector].
				preamble := class name, ' methodsFor: ' , category asString printString, ' stamp: ''', method timeStamp, ''''.
				internalStream nextPut: $!; nextChunkPut: preamble; cr.
				source := method getSourceFromFile asString.
				source := source copyFrom: (source indexOfSubCollection: 'PROTOTYPE') + 9 to: source size.
				(self selectorForPrototypeMethod: method) isBinary ifTrue:
					[source := (self selectorForPrototypeMethod: method), (source copyFrom: (source indexOf: Character space) to: source size)].
				internalStream nextChunkPut: source; space; nextPut: $!; cr; cr]
			ifNotNil:
				[source := class name, ' removeSelector: ', selector storeString.
				 internalStream nextChunkPut: source; cr; cr]].
	internalStream trailer.

	FileStream
		writeSourceCodeFrom: internalStream
		baseName: 'SpurBootstrapPrototypes'
		isSt: true
		useHtml: false
]

{ #category : #'bootstrap image' }
SpurBootstrap >> fillInClassTable [
	| firstPage maxIndex |
	maxIndex := 0.
	classToIndex keysAndValuesDo:
		[:oldClass :index| | newClass page |
		maxIndex := maxIndex max: index.
		newClass := map at: oldClass.
		self assert: (newHeap isPointersNonImm: newClass).
		newHeap setHashBitsOf: newClass to: index.
		page := newHeap
					fetchPointer: index >> newHeap classTableMajorIndexShift
					ofObject: newHeap classTableRootObj.
		newHeap
			storePointer: (index bitAnd: newHeap classTableMinorIndexMask)
			ofObject: page
			withValue: newClass.
		self assert: (newHeap classAtIndex: index) = newClass].
	firstPage := newHeap
					fetchPointer: 0
					ofObject: newHeap classTableRootObj.
	newHeap
		storePointer: 1
			ofObject: firstPage
				withValue: (map at: oldHeap classSmallInteger);
		storePointer: 2
			ofObject: firstPage
				withValue: (map at: oldHeap classCharacter);
		storePointer: 3
			ofObject: firstPage
				withValue: (map at: oldHeap classSmallInteger);
		storePointer: newHeap arrayClassIndexPun
			ofObject: firstPage
				withValue: (map at: oldHeap classArray);
		storePointer: newHeap arrayClassIndexPun
			ofObject: firstPage
				withValue: (map at: oldHeap classArray).

	newHeap classTableIndex: maxIndex
]

{ #category : #'bootstrap image' }
SpurBootstrap >> fillInCompiledMethod: newObj from: oldObj [
	| firstByteIndex primIndex |
	self fillInPointerObject: newObj from: oldObj.
	"Now convert the CompiledMethod's format.  First write the header in the new format"
	newHeap
		storePointerUnchecked: 0
		ofObject: newObj
		withValue: (newHeap integerObjectOf: (self convertOldMethodHeader: (oldHeap fetchPointer: 0 ofObject: oldObj))).
	"Then if necessary prepend the callPrimitive: bytecode"
	(primIndex := oldInterpreter primitiveIndexOf: oldObj) > 0
		ifTrue:
			[firstByteIndex := oldHeap lastPointerOf: oldObj.
			 newHeap
				storeByte: firstByteIndex + 0 ofObject: newObj withValue: 139;
				storeByte: firstByteIndex + 1 ofObject: newObj withValue: (primIndex bitAnd: 255);
				storeByte: firstByteIndex + 2 ofObject: newObj withValue: (primIndex bitShift: -8).
			 firstByteIndex to: (oldHeap numBytesOf: oldObj) - 1 do:
				[:i|
				newHeap storeByte: i + 3 ofObject: newObj withValue: (oldHeap fetchByte: i ofObject: oldObj)]]
		ifFalse:
			[(oldHeap lastPointerOf: oldObj) / oldHeap wordSize to: (oldHeap numSlotsOf: oldObj) - 1 do:
				[:i|
				newHeap storeLong32: i ofObject: newObj withValue: (oldHeap fetchLong32: i ofObject: oldObj)]]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> fillInObjects [
	oldHeap allObjectsDo:
		[:oldObj|
		(map at: oldObj ifAbsent: nil) ifNotNil:
			[:newObj| | format classIndex |
			format := newHeap formatOf: newObj.
			(newHeap isPointersFormat: format)
				ifTrue:
					[((newHeap isIndexableFormat: format)
						and: [(classIndex := newHeap classIndexOf: newObj) <= classBlockClosureIndex
						and: [classIndex >= classMethodContextIndex]])
						ifTrue: [self fillInPointerObjectWithPC: newObj from: oldObj]
						ifFalse: [self fillInPointerObject: newObj from: oldObj]]
				ifFalse:
					[(newHeap isCompiledMethodFormat: format)
						ifTrue: [self fillInCompiledMethod: newObj from: oldObj]
						ifFalse: [self fillInBitsObject: newObj from: oldObj]]]]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> fillInPointerObject: newObj from: oldObj [
	"Fill-in a newObj with appropriately mapped contents from oldObj.
	 Filter-out the character table and the compact classes array.
	 Map character objects to immediate characters."
	0 to: (oldHeap lastPointerOf: oldObj) / oldHeap wordSize - 1 do:
		[:i| | oldValue newValue |
		oldValue := oldHeap fetchPointer: i ofObject: oldObj.
		newValue := (oldHeap isIntegerObject: oldValue)
						ifTrue: [oldValue]
						ifFalse:
							[map at: oldValue ifAbsent:
								[(oldValue = oldHeap characterTable
								  or: [oldValue = (oldHeap splObj: CompactClasses)])
									ifTrue: [newHeap nilObject]
									ifFalse:
										[self assert: (oldHeap fetchClassOfNonImm: oldValue) = oldHeap classCharacter.
										 newHeap characterObjectOf:
											(oldHeap integerValueOf:
												(oldHeap fetchPointer: CharacterValueIndex ofObject: oldValue))]]].
		newHeap
			storePointerUnchecked: i
			ofObject: newObj
			withValue: newValue].
	(self isOldObjABehavior: oldObj) ifTrue:
		[self mapOldBehavior: oldObj toNewBehavior: newObj]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> fillInPointerObjectWithPC: newObj from: oldObj [
	"Fill-in a newObj with appropriately mapped contents from oldObj.
	 If the object has a pc and its method has a primitive, increment the
	 pc by the size of the callPrimitive: bytecode."
	| method |
	self fillInPointerObject: newObj from: oldObj.
	(newHeap classIndexOf: newObj) = classBlockClosureIndex ifTrue:
		[method := oldHeap
						fetchPointer: MethodIndex
						ofObject: (oldHeap
									fetchPointer: ClosureOuterContextIndex
									ofObject: oldObj).
		 (oldInterpreter primitiveIndexOf: method) > 0 ifTrue:
			[self incrementPCField: ClosureStartPCIndex ofObject: newObj by: 3]].
	(newHeap classIndexOf: newObj) = classMethodContextIndex ifTrue:
		[method := oldHeap
						fetchPointer: MethodIndex
						ofObject: oldObj.
		 (oldInterpreter primitiveIndexOf: method) > 0 ifTrue:
			[self incrementPCField: InstructionPointerIndex ofObject: newObj by: 3]].
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> findClassNamed: symbolOop [ 
	oldHeap allObjectsDo:
		[:o|
		((oldHeap isPointersNonImm: o)
		 and: [(oldInterpreter addressCouldBeClassObj: o)
		 and: [(oldHeap fetchPointer: oldInterpreter classNameIndex ofObject: o) = symbolOop]]) ifTrue:
			[^o]].
	^nil
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> findLiteral: aLiteral inClass: classOop [
	| bindingOrNil |
	aLiteral isString ifTrue:
		[^self stringFor: aLiteral].
	aLiteral isFloat ifTrue:
		[^oldInterpreter floatObjectOf: aLiteral].
	aLiteral isArray ifTrue:
		[^self cloneArrayLiteral: aLiteral].
	self assert: aLiteral isVariableBinding.
	bindingOrNil := self interpreter: oldInterpreter
						object: classOop
						perform: (self findSymbol: #bindingOf:)
						withArguments: {self findSymbol: aLiteral key}.
	bindingOrNil ~= oldHeap nilObject ifTrue:
		[^bindingOrNil].
	self error: 'couldn''t find literal ', aLiteral printString
]

{ #category : #'bootstrap image' }
SpurBootstrap >> findRequiredGlobals [
	"Look for the necessary gobal bindings in the prototype methods in the old image.
	 This has to be done early by sending bindingOf: to Smalltalk.  Collect the class
	 hierarchy of all prototypes that access inst vars (non-local prototypes) to check
	 their shapes.  Also find out Metaclass, needed for identifying classes."
	| globals ourMethodClasses classVars bindingOfSym |
	globals := Set new.
	ourMethodClasses := Set new.
	classVars := Dictionary new.
	self prototypeClassNameMetaSelectorMethodDo:
		[:c :m :s :method| | allNonMetaSupers |
		(Smalltalk classNamed: c) ifNotNil:
			[ :nonMetaClass|
			allNonMetaSupers := nonMetaClass withAllSuperclasses.
			method methodClass ~= SpurBootstrap class ifTrue:
				[ourMethodClasses addAll: allNonMetaSupers].
			globals addAll: (allNonMetaSupers collect: [:sc| sc binding]).
			method literals do:
				[:l|
				(l isVariableBinding and: [l key isSymbol]) ifTrue:
					[(Smalltalk bindingOf: l key) == l
						ifTrue: [globals add: l]
						ifFalse:
							[self assert: (nonMetaClass bindingOf: l key) == l.
							classVars at: l put: nonMetaClass]]]]].
	globals add: Compiler binding. "For potential reshaping in checkReshapeOf:"
	bindingOfSym := self findSymbol: #bindingOf:.
	self withExecutableInterpreter: oldInterpreter
		do:	[| toBeAdded |
			globals do:
				[:global| | bindingOop |
				bindingOop := self interpreter: oldInterpreter
									object: (oldHeap splObj: 8) "Smalltalk"
									perform: bindingOfSym
									withArguments: {self findSymbol: global key}.
				bindingOop ~= oldHeap nilObject ifTrue:
					[literalMap at: global put: bindingOop]].
			 toBeAdded := Dictionary new.
			 classVars keysAndValuesDo:
				[:var :class| | val |
				(self findSymbol: var key) "New class inst vars may not yet be interned."
					ifNil: [toBeAdded at: var put: class]
					ifNotNil:
						[:varName|
						val := self interpreter: oldInterpreter
									object: (self oldClassOopFor: class)
									perform: bindingOfSym
									withArguments: {varName}.
						val ~= oldHeap nilObject
							ifTrue: [literalMap at: var put: val]
							ifFalse: [toBeAdded at: var put: class]]].
			"May have to redefine to add missing inst vars and/or add any missing class vars."
			self checkReshapeOf: ourMethodClasses.
			self addMissingClassVars: toBeAdded]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> findSymbol: aString [
	"Find the Symbol equal to aString in oldHeap."
	| symbolClass |
	(literalMap at: aString ifAbsent: nil) ifNotNil:
		[:oop| ^oop].
	symbolClass := self symbolClass.
	oldHeap allObjectsDo:
		[:obj|
		(symbolClass = (oldHeap fetchClassOfNonImm: obj)
		 and: [(oldHeap numBytesOf: obj) = aString size
		 and: [aString = (oldHeap stringOf: obj)]]) ifTrue:
			[aString isSymbol ifTrue:
				[literalMap at: aString asSymbol put: obj].
			 ^obj]].
	Transcript cr; nextPutAll: 'Warning, could not find '; store: aString; flush.
	^nil
]

{ #category : #'class indices' }
SpurBootstrap >> firstOrdinaryClassIndex [
	^newHeap classTablePageSize
]

{ #category : #'bootstrap image' }
SpurBootstrap >> followForwardingPointers [
	newHeap allObjectsDo:
		[:o|
		(newHeap isForwarded: o) ifFalse:
			[0 to: (newHeap numPointerSlotsOf: o) - 1 do:
				[:i| | field |
				field := newHeap fetchPointer: i ofObject: o.
				(newHeap isOopForwarded: field) ifTrue:
					[newHeap
						storePointer: i
						ofObject: o
						withValue: (newHeap followForwarded: field)]]]]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> freeForwarders [
	"Check that all forwarders have been followed.  Then free them."
	| numForwarders numFreed |
	numForwarders := numFreed := 0.
	newHeap allObjectsDo:
		[:o|
		(newHeap isForwarded: o)
			ifTrue: [numForwarders := numForwarders + 1]
			ifFalse:
				[0 to: (newHeap numPointerSlotsOf: o) - 1 do:
					[:i|
					self assert: (newHeap isOopForwarded: (newHeap fetchPointer: i ofObject: o)) not]]].
	Transcript ensureCr;  nextPutAll: 'freeing '; print: numForwarders; nextPutAll: ' forwarders'; cr; flush.
	newHeap allObjectsDo:
		[:o|
		(newHeap isForwarded: o) ifTrue:
			[numFreed := numFreed + 1.
			 newHeap freeObject: o]].
	self assert: numFreed = numForwarders
]

{ #category : #'bootstrap image' }
SpurBootstrap >> headerForOldMethodHeader: methodHeaderOop [
	^self isOnSpur
		ifTrue: [self convertOldMethodHeader: methodHeaderOop]
		ifFalse: [oldHeap integerValueOf: methodHeaderOop]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> imageTypes: anArray [
	imageTypes := anArray
]

{ #category : #'bootstrap image' }
SpurBootstrap >> incrementPCField: fieldIndex ofObject: newObj by: n [
	| value |
	value := newHeap fetchPointer: fieldIndex ofObject: newObj.
	(newHeap isIntegerObject: value)
		ifTrue:
			[newHeap
				storePointerUnchecked: fieldIndex
				ofObject: newObj
				withValue: (newHeap integerObjectOf: n + (newHeap integerValueOf: value))]
		ifFalse:
			[self assert: value = newHeap nilObject]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> indexOfSelector: selectorOop in: methodDict [
	SelectorStart to: (oldHeap numSlotsOf: methodDict) - 1 do:
		[:i|
		(oldHeap fetchPointer: i ofObject: methodDict) = selectorOop ifTrue:
			[^i]].
	self error: 'could not find selector in method dict'
]

{ #category : #'initialize-release' }
SpurBootstrap >> initMaps [
	map := Dictionary new: oldHeap memory size // 4.
	reverseMap := Dictionary new: oldHeap memory size // 4.
	classToIndex := Dictionary new: 1024.
	literalMap := IdentityDictionary new.
	methodClasses := Set new.
	installedPrototypes := Set new.
	installedMethodOops := Set new.
	classMetaclass := nil
]

{ #category : #'initialize-release' }
SpurBootstrap >> initialize [
	super initialize.
	imageTypes := {'squeak'}. "By default, image is Squeak (so Eliot does not kick me :P)"
]

{ #category : #'bootstrap image' }
SpurBootstrap >> initializeClasses [
	toBeInitialized ifNil: [^self].
	self withExecutableInterpreter: oldInterpreter
		do: [toBeInitialized do:
				[:class|
				self interpreter: oldInterpreter
					object: (self oldClassOopFor: class)
					perform: (self findSymbol: #initialize)
					withArguments: #()]]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> installModifiedMethods [
	"Install all the methods in the class-side method prototypes protocol in the relevant classes
	 in the new image.  First use the simulator to get the image to intern all symbols and add
	 dummy methods under new selectors.  With that done we can manually replace the relevant
	 methods with the prototypes, mapping selectors and global variables as required."
	self withExecutableInterpreter: oldInterpreter
		do: [self internAllSymbols.
			 self addNewMethods.
			 self removeMethods.
			 self replaceMethods.
			 self modifyCharacterMethods]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> installableMethodFor: aCompiledMethod selector: selector className: className isMeta: isMeta [
	"Create a sourceless method to install in the bootstrapped image.  It will allow the
	 bootstrap to limp along until the relevant transformed Monticello package is loaded."
	| compiledMethodClass methodClassBinding methodClass sourcelessMethod bytes newMethod delta initialPC |
	compiledMethodClass := self findClassNamed: (self findSymbol: #CompiledMethod).
	methodClassBinding := self methodClassBindingForClassName: className isMeta: isMeta.
	methodClass := oldHeap fetchPointer: ValueIndex ofObject: methodClassBinding.
	"the prototypes have source pointers.  the Character methods to be replaced don't."
	sourcelessMethod := aCompiledMethod trailer hasSourcePointer
							ifTrue: [aCompiledMethod copyWithTempsFromMethodNode: aCompiledMethod methodNode]
							ifFalse: [aCompiledMethod].
	initialPC := sourcelessMethod initialPC.
	bytes := sourcelessMethod size - initialPC + 1.
	"Ugh, this is complicated.  We could be running on Spur with the new method format
	 or on non-Spur with the old format.  Make both work."
	delta := (sourcelessMethod primitive > 0
			 and: [(sourcelessMethod at: initialPC) = sourcelessMethod encoderClass callPrimitiveCode])
				ifTrue: [3]
				ifFalse: [0].
	newMethod := self
					interpreter: oldInterpreter
					object: compiledMethodClass
					perform: (self findSymbol: #newMethod:header:)
					withArguments: { oldHeap integerObjectOf: bytes - delta.
									   oldHeap integerObjectOf: (self oldFormatHeaderFor: sourcelessMethod) }.
	1 to: sourcelessMethod numLiterals - 2 do:
		[:i| | literal oop |
		literal := sourcelessMethod literalAt: i.
		oop := (literal isLiteral or: [literal isVariableBinding])
					ifTrue:
						[literal isInteger
							ifTrue: [oldHeap integerObjectOf: literal]
							ifFalse: [literalMap
										at: literal
										ifAbsent: [self findLiteral: literal
														inClass: methodClass]]]
					ifFalse: "should be a VMObjectProxy"
						[literal oop].
		oldHeap storePointer: i ofObject: newMethod withValue: oop].
	oldHeap
		storePointer: sourcelessMethod numLiterals - 1
		ofObject: newMethod
		withValue: (selector isSymbol
						ifTrue: [self findSymbol: selector]
						ifFalse: [selector oop]);
		storePointer: sourcelessMethod numLiterals
		ofObject: newMethod
		withValue: methodClassBinding.
	initialPC to: sourcelessMethod size - delta do:
		[:i|
		oldHeap storeByte: i - 1 ofObject: newMethod withValue: (sourcelessMethod byteAt: i + delta)].
	installedMethodOops add: newMethod.
	^newMethod
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> internAllSymbols [
	"Ensure that all symbols in the method prototypes are interned so that later we can install them.
	 Enter them into the map, this system's symbol -> oldHeap's version.
	 Do this by interpreting Symbol intern: 'aSymbol' for each symbol."
	| internSym all symbolClass |
	internSym := self findSymbol: #intern:.
	symbolClass := self symbolClass.
	all := self allPrototypeMethodSymbols.
	oldHeap allObjectsDo:
		[:objOop| | sz |
		symbolClass = (oldHeap fetchClassOfNonImm: objOop) ifTrue:
			[sz := oldHeap numBytesOf: objOop.
			 (all detect: [:sym| sym size = sz and: [sym = (oldHeap stringOf: objOop)]]
				ifNone: nil) ifNotNil:
					[:sym|
					literalMap at: sym put: objOop.
					all remove: sym]]].
	all do: [:sym|
		(self findSymbol: sym)
			ifNotNil: [:imageSym| literalMap at: sym put: imageSym]
			ifNil:[Transcript cr; nextPutAll: 'interning '; nextPutAll: sym; flush.
				"Interpret Symbol intern: sym to ... intern it :-)"
				literalMap
					at: sym
					put: (self interpreter: oldInterpreter
							object: self symbolClass
							perform: internSym
							withArguments: {self stringFor: sym})]].
	literalMap keysAndValuesDo:
		[:symOrGlobal :imageSymOrGlobal|
		symOrGlobal isSymbol ifTrue:
			[self assert: symOrGlobal = (oldHeap stringOf: imageSymOrGlobal)]]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> isOldObjABehavior: oldObj [
	| oldObjClass |
	^(classToIndex includesKey: oldObj)
	or: [(oldObjClass := oldHeap fetchClassOfNonImm: oldObj) = self classMetaclass
	or: [(oldHeap fetchClassOfNonImm: oldObjClass) = classMetaclass]]
]

{ #category : #testing }
SpurBootstrap >> isOnSpur [
	^$c class instSize = 0
]

{ #category : #testing }
SpurBootstrap >> launch [
	self launch: newHeap
		simulatorClass: StackInterpreterSimulator
		headerFlags: oldInterpreter getImageHeaderFlags
]

{ #category : #testing }
SpurBootstrap >> launch: heap simulatorClass: simulatorClass headerFlags: headerFlags [
	| sim methodCacheSize |
	sim := simulatorClass onObjectMemory: heap.
	heap coInterpreter: sim.
	(sim class allInstVarNames includes: 'cogCodeSize')
		ifTrue:
			[sim initializeInterpreter: 0.
			 methodCacheSize := sim methodCache size * heap wordSize.
			 sim instVarNamed: 'heapBase' put: heap startOfMemory;
				instVarNamed: 'numStackPages' put: 8;
				instVarNamed: 'cogCodeSize' put: 1024*1024;
				moveMethodCacheToMemoryAt: sim cogCodeSize + sim computeStackZoneSize;
				movePrimTraceLogToMemoryAt: sim cogCodeSize + sim computeStackZoneSize + methodCacheSize;
				"sendTrace: 1+ 2 + 8 + 16;"
			 	initializeCodeGenerator]
		ifFalse:
			[sim initializeInterpreter: 0].
	heap
		initializeNewSpaceVariables;
		bootstrapping: false;
		assimilateNewSegment: (heap segmentManager segments at: 0).
	sim
		setImageHeaderFlagsFrom: headerFlags;
		imageName: ImageName;
		flushExternalPrimitives;
		openAsMorph;
		transcript: Transcript. "deep copy copies this"
	"sim
		instVarNamed: 'printSends' put: true;
		instVarNamed: 'printReturns' put: true;
		instVarNamed: 'methodDictLinearSearchLimit' put: SmallInteger maxVal." "for now"
	heap
		setCheckForLeaks: 0;
		runLeakCheckerForFullGC: true.

	sim halt; run
]

{ #category : #testing }
SpurBootstrap >> launchSaved [
	self launch: TransformedImage veryDeepCopy
		simulatorClass: StackInterpreterSimulator
		headerFlags: ImageHeaderFlags
]

{ #category : #testing }
SpurBootstrap >> launchSavedWithJIT [
	self launch: (self coHeapFrom: TransformedImage veryDeepCopy)
		simulatorClass: CogVMSimulator
		headerFlags: ImageHeaderFlags
]

{ #category : #'bootstrap image' }
SpurBootstrap >> mapOldBehavior: oldObj toNewBehavior: newObj [
	"Map the old format inst var's value to the new value.
	 In addition, for Character, make it immediate and remove its instance variable."
	newHeap
		storePointerUnchecked: InstanceSpecificationIndex
		ofObject: newObj
		withValue: (self newClassFormatFor: oldObj).
	oldObj = oldHeap classCharacter ifTrue:
		[InstanceSpecificationIndex + 1 to: (oldHeap numSlotsOf: oldObj) do:
			[:i| | var field |
			var := oldHeap fetchPointer: i ofObject: oldObj.
			((oldHeap fetchClassOf: var) = oldHeap classArray
			 and: [(oldHeap numSlotsOf: var) = 1
			 and: [field := oldHeap fetchPointer: 0 ofObject: var.
				(oldHeap fetchClassOf: field) = oldHeap classString
			 and: [(oldHeap lengthOf: field) = 5
			 and: [(oldHeap str: 'value'  n: (oldHeap firstIndexableField: field) cmp: 5) = 0]]]]) ifTrue:
				[newHeap
					storePointerUnchecked: i
					ofObject: newObj
					withValue: newHeap nilObject.
				 ^self]]]
]

{ #category : #stats }
SpurBootstrap >> measureNewHeapPostInitPostBootstrap [
	| savedEndOfMemory |
	"need to hack around the fact that newHeap isn't all there yet.
	 In particular, it has no freeList so can't free space from
	 freeOldSpaceStart to endOfMemory to make oldSpace enumerable."
	newHeapNumObjs := 0.
	savedEndOfMemory := newHeap endOfMemory.
	newHeap setEndOfMemory: newHeap freeOldSpaceStart.
	newHeap allObjectsDo: [:o| newHeapNumObjs := newHeapNumObjs + 1].
	newHeap setEndOfMemory: savedEndOfMemory
]

{ #category : #stats }
SpurBootstrap >> measureOldHeapPostGC [
	oldHeapSize := oldHeap freeStart.
	oldHeapNumObjs := 0.
	oldHeap allObjectsDo: [:o| oldHeapNumObjs := oldHeapNumObjs + 1]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> methodClassBindingForClassName: classNameSymbol isMeta: isMeta [ 
	| class |
	class := self findClassNamed: (literalMap at: classNameSymbol).
	isMeta ifTrue: [class := oldHeap fetchClassOfNonImm: class].
	^self interpreter: oldInterpreter
		object: class
		perform: (self findSymbol: #binding)
		withArguments: #()
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> modifyCharacterMethods [
	| cc md mda |
	cc := oldHeap classCharacter.
	md := oldHeap fetchPointer: MethodDictionaryIndex ofObject: cc.
	mda := oldHeap fetchPointer: MethodArrayIndex ofObject: md..
	0 to: (oldHeap numSlotsOf: mda) - 1 do:
		[:i| | method |
		method := oldHeap fetchPointer: i ofObject: mda.
		method ~= oldHeap nilObject ifTrue:
			[(self replacementForCharacterMethod: method) ifNotNil:
				[:replacement|
				Transcript
					cr;
					nextPutAll: 'replacing Character>>#';
					nextPutAll: (oldHeap stringOf: (oldHeap fetchPointer: i + SelectorStart ofObject: md));
					flush. 
				oldHeap
					storePointer: i
					ofObject: mda
					withValue: replacement]]]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> newClassFormatFor: oldClassObj [
	"OLD: 		<2 bits=instSize//64><5 bits=cClass><4 bits=instSpec><6 bits=instSize\\64><1 bit=0>
	 NEW: 		<5 bits inst spec><16 bits inst size>"
	| oldFormat instSize newInstSpec |
	((oldInterpreter classNameOf: oldClassObj Is: 'SmallInteger')
	 or: [oldInterpreter classNameOf: oldClassObj Is: 'Character']) ifTrue:
		[^newHeap integerObjectOf: newHeap instSpecForImmediateClasses << 16].
	oldFormat := oldHeap formatOfClass: oldClassObj. "N.B. SmallInteger with tag bit cleared"
	oldFormat := oldFormat >> 1.
	instSize := ((oldFormat bitShift: -10) bitAnd: 16rC0) + ((oldFormat bitShift: -1) bitAnd: 16r3F) - 1.
	newInstSpec := #(0 1 2 3 4 nil 10 9 16 16 16 16 24 24 24 24) at: ((oldFormat bitShift: -7) bitAnd: 16rF) + 1.
	^newHeap integerObjectOf: newInstSpec << 16 + instSize
]

{ #category : #'bootstrap image' }
SpurBootstrap >> newFormatFor: oldObj numBytes: numBytesIfBits [
	"OLD:
	 0	no fields
	 1	fixed fields only (all containing pointers)
	 2	indexable fields only (all containing pointers)
	 3	both fixed and indexable fields (all containing pointers)
	 4	both fixed and indexable weak fields (all containing pointers).

	 5	unused
	 6	indexable word fields only (no pointers)
	 7	indexable long (64-bit) fields (only in 64-bit images)
 
	 8-11	indexable byte fields only (no pointers) (low 2 bits are low 2 bits of size)
	 12-15	compiled methods:
	 	    # of literal oops specified in method header,
	 	    followed by indexable bytes (same interpretation of low 2 bits as above)"

	"NEW:
	 0 = 0 sized objects (UndefinedObject True False et al)
	 1 = non-indexable objects with inst vars (Point et al)
	 2 = indexable objects with no inst vars (Array et al)
	 3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
	 4 = weak indexable objects with inst vars (WeakArray et al)
	 5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
	 6 = reserved
	 7 = forwarder format (also immediate class format)
	 9          64-bit indexable
	 10 - 11 32-bit indexable
	 12 - 15 16-bit indexable
	 16 - 23 byte indexable
	 24 - 31 compiled method"
	| oldFormat |
	oldFormat := oldHeap formatOf: oldObj.
	oldFormat <= 4 ifTrue:
		[^oldFormat].
	oldFormat >= 12 ifTrue: "CompiledMethod"
		[^24 + (self wordSize - numBytesIfBits bitAnd: self wordSizeMask)].
	oldFormat >= 8 ifTrue: "ByteArray et al"
		[^16 + (self wordSize - numBytesIfBits bitAnd: self wordSizeMask)].
	oldFormat = 6 ifTrue: "32-bit indexable"
		[^10 + (numBytesIfBits bitAnd: self wordSizeMask) sign].
	oldFormat = 7 ifTrue: "64-bit indexable"
		[^9].
	self error: 'illegal old format'
]

{ #category : #'bootstrap image' }
SpurBootstrap >> oldClassOopFor: aClass [
	^oldHeap fetchPointer: ValueIndex ofObject: (literalMap at: aClass binding).
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> oldFormatHeaderFor: method [
	| primBits primitive |
	primitive := method primitive.
	primBits := primitive <= 16r1FF
					ifTrue: [primitive]
					ifFalse: [(primitive bitAnd: 16r1FF) + ((primitive bitAnd: 16r200) bitShift: 19)].
	^(method numArgs bitShift: 24)
	+ (method numTemps bitShift: 18)
	+ (method frameSize > method class smallFrameSize ifTrue: [1 << 17] ifFalse: [0])
	+ (method numLiterals bitShift: 9)
	+ primBits
]

{ #category : #'initialize-release' }
SpurBootstrap >> on: imageName [
	StackInterpreter initializeWithOptions: Dictionary new.
	(oldInterpreter := StackInterpreterSimulator new)
		openOn: imageName extraMemory: 0;
		assertValidExecutionPointersAtEachStep: false.
	oldHeap := oldInterpreter objectMemory.
	newHeap := Spur32BitMMLESimulator new.
	newHeap
		allocateMemoryOfSize: (oldHeap youngStart * 3 / 2 roundUpTo: 1024 * 1024)
		newSpaceSize: 4 * 1024 * 1024
		stackSize: 16 * 1024
		codeSize: 0.
	newHeap setCheckForLeaks: 15 - 6. "don't check become; or newSpace; soooo many rehashes in bootstrap"
	newHeap bootstrapping: true.
	self initMaps
]

{ #category : #'method prototypes' }
SpurBootstrap >> prototypeClassNameMetaSelectorMethodDo: quaternaryBlock [
	"Evaluate aBlock with class name, class is meta, method and selector.
	 For now find methods in class-side category #'method prototypes'.
	 Scheme could be extended to have different protocols for different
	 Squeak/Pharo versions."
	self allPrototypeSelectors do:
		[:protoSelector| | method className isMeta |
		method := SpurBootstrap class >> protoSelector.
		className := self classNameForPrototypeMethod: method.
		(isMeta := className endsWith: 'class') ifTrue:
			[className := (className allButLast: 5) asSymbol].
		(method pragmaAt: #indirect) ifNotNil:
			[method := (isMeta
							ifTrue: [(Smalltalk classNamed: className) class]
							ifFalse: [Smalltalk classNamed: className]) >> protoSelector].
		quaternaryBlock
			value: className
			value: isMeta
			value: (self selectorForPrototypeMethod: method)
			value: method]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> recreateSpecialObjectsArray [
	"This is tricky.  We want to recreate the specialObjectsArray according to
	 the class side SmalltalkImagePROTOTYPErecreateSpecialObjectsArray.
	 But that version destroys the CompactClassesArray upon which the V3
	 image depends.  The bootstrap will get rid of it later.  So save it before
	 the recreation and restore it."
	self withExecutableInterpreter: oldInterpreter
		do: [| compactClassesArray |
			compactClassesArray := oldHeap splObj: CompactClasses.
			self
				interpreter: oldInterpreter
				object: (oldHeap splObj: 8)
				perform: (self findSymbol: #recreateSpecialObjectsArray)
				withArguments: #().
			oldHeap splObj: CompactClasses put: compactClassesArray]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> rehashImage [
	"Rehash all collections in newHeap.
	 Find out which classes implement rehash, entering a 1 against their classIndex in rehashFlags.
	 Enumerate all objects, rehashing those whose class has a bit set in rehashFlags."
	| n sim rehashFlags dotDate rehashSym sizeSym |
	rehashSym := map at: (self findSymbol: #rehash).
	sizeSym := map at: (self findSymbol: #size).
	sim := StackInterpreterSimulator onObjectMemory: newHeap.
	sim 
		setImageHeaderFlagsFrom: oldInterpreter getImageHeaderFlags;
		imageName: 'spur image';
		assertValidExecutionPointersAtEachStep: false..
	newHeap coInterpreter: sim.
	sim bootstrapping: true.
	sim initializeInterpreter: 0.
	sim instVarNamed: 'methodDictLinearSearchLimit' put: SmallInteger maxVal.

	newHeap
		setHashBitsOf: newHeap nilObject to: 1;
		setHashBitsOf: newHeap falseObject to: 2;
		setHashBitsOf: newHeap trueObject to: 3.

	rehashFlags := ByteArray new: newHeap numClassTablePages * newHeap classTablePageSize.
	n := 0.
	newHeap classTableObjectsDo:
		[:class| | classIndex |
		sim messageSelector: rehashSym.
		"Lookup rehash but don't be fooled by ProtoObject>>rehash, which is just ^self."
		((sim lookupMethodNoMNUEtcInClass: class) = 0
		 and: [(sim isQuickPrimitiveIndex: (sim primitiveIndexOf: (sim instVarNamed: 'newMethod'))) not]) ifTrue:
			[n := n + 1.
			 classIndex := newHeap rawHashBitsOf: class.
			 rehashFlags
				at: classIndex >> 3 + 1
				put: ((rehashFlags at: classIndex >> 3 + 1)
						bitOr: (1 << (classIndex bitAnd: 7)))]].
	Transcript cr; print: n; nextPutAll: ' classes understand rehash. rehashing instances...'; flush.
	dotDate := Time now asSeconds.
	n := 0.
	self withExecutableInterpreter: sim
		do: [sim setBreakSelector: 'error:'.
			 "don't rehash twice (actually without limit), so don't rehash any new objects created."
			 newHeap allExistingOldSpaceObjectsDo:
				[:o| | classIndex |
				classIndex := newHeap classIndexOf: o.
				((rehashFlags at: classIndex >> 3 + 1) anyMask: 1 << (classIndex bitAnd: 7)) ifTrue:
					[Time now asSeconds > dotDate ifTrue:
					 	[Transcript nextPut: $.; flush.
						 dotDate := Time now asSeconds].
					 "2845 = n ifTrue: [self halt]."
					 "Rehash an object if its size is > 0.
					  Symbol implements rehash, but let's not waste time rehashing it; in Squeak
					  up to 2013 symbols are kept in a set which will get reashed anyway..
					  Don't rehash empty collections; they may be large for a reason and rehashing will shrink them."
					 ((sim addressCouldBeClassObj: o)
					   or: [(self interpreter: sim
							object: o
							perform: sizeSym
							withArguments: #()) = (newHeap integerObjectOf: 0)]) ifFalse:
						[self interpreter: sim
							object: o
							perform: rehashSym
							withArguments: #()]]]]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> removeMethods [
	"Get the simulator to remove any methods marked with <remove>."
	| removeSym |
	removeSym := self findSymbol: #removeSelectorSilently:.
	removeSym ifNil:
		[removeSym := self findSymbol: #removeSelector:].
	self prototypeClassNameMetaSelectorMethodDo:
		[:className :isMeta :selector :method| | class |
		(method pragmaAt: #remove) ifNotNil:
			[(self findClassNamed: (literalMap at: className)) ifNotNil:
				[:theClass|
				 class := isMeta ifTrue: [oldHeap fetchClassOfNonImm: theClass] ifFalse: [theClass].
				 Transcript
					cr;
					nextPutAll: 'removing ';
					nextPutAll: className;
					nextPutAll: (isMeta ifTrue: [' class>>'] ifFalse: ['>>']);
					store: selector;
					flush.
				 self interpreter: oldInterpreter
					object: class
					perform: removeSym
					withArguments: {literalMap at: selector}]]]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> replaceMethods [
	"Replace all the modified method prototypes."
	self allPrototypeClassNamesDo:
		[:sym :symIsMeta|
		(self findClassNamed: (literalMap at: sym))
			ifNil: [Transcript
					cr;
					nextPutAll: 'not replacing any methods for ';
					nextPutAll: sym;
					nextPutAll: '; class not found in image';
					flush.]
			ifNotNil:
				[:theClass| | class |
				class := symIsMeta ifTrue: [oldHeap fetchClassOfNonImm: theClass] ifFalse: [theClass].
				self prototypeClassNameMetaSelectorMethodDo:
					[:className :isMeta :selector :method| | replacement methodDict index |
					(className = sym
					 and: [symIsMeta = isMeta
					 and: [(method pragmaAt: #remove) isNil]]) ifTrue:
						[(installedPrototypes includes: method selector) ifFalse:
							["probe method dictionary of the class for each method, installing a dummy if not found."
							Transcript
								cr;
								nextPutAll: 'replacing ';
								nextPutAll: className;
								nextPutAll: (isMeta ifTrue: [' class>>'] ifFalse: ['>>']);
								store: selector;
								flush.
							replacement := self installableMethodFor: method
												selector: selector
												className: className
												isMeta: isMeta.
							methodDict := oldHeap fetchPointer: MethodDictionaryIndex ofObject: class.
							index := self indexOfSelector: (literalMap at: selector) in: methodDict.
							oldHeap
								storePointer: index - SelectorStart
								ofObject: (oldHeap fetchPointer: MethodArrayIndex ofObject: methodDict)
								withValue: replacement.
							installedPrototypes add: method selector]]]]]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> replacementForCharacterMethod: characterMethodOop [
	"Answer a replacement method for the argument if it refers
	 to Character's old inst var value.  Otherwise answer nil."
	| proxy asIntegerProxy clone assembly newInsts newMethod |
	"(oldHeap stringOf: (oldHeap longAt: characterMethodOop + (oldHeap lastPointerOf: characterMethodOop) - 4)) = 'isOctetCharacter' ifTrue:
		[self halt]."
	"Don't replace something already installed."
	(installedMethodOops includes: characterMethodOop) ifTrue:
		[^nil].
	proxy := VMCompiledMethodProxy new
				for: characterMethodOop
				coInterpreter: oldInterpreter
				objectMemory: oldHeap.
	self assert: (oldHeap literalCountOf: characterMethodOop) = proxy numLiterals.
	clone := self cloneMethodProxy: proxy.
	self assert: proxy numLiterals = clone numLiterals.
	clone isReturnSpecial ifTrue:
		[^nil].
	"Quick methods accessing value should have been replaced.  The halt will fire if there
	 is a missing prototype for such a method on the class side of SpurBootstrap.  The
	 relevant Character prototypes there so far are Character>>asInteger, Character>>
	 asciiValue, Character>>hash & Character>>identityHash.  Conceivably the bootstrap
	 could be applied to an image that has others; hence the halt."
	clone isReturnField ifTrue: [self halt].
	clone hasInstVarRef ifFalse:
		[^nil].
	clone setSourcePointer: 0.
	asIntegerProxy := VMObjectProxy new
							for: (literalMap at: #asInteger)
							coInterpreter: oldInterpreter
							objectMemory: oldHeap.
	assembly := BytecodeDisassembler new disassemble: clone.
	assembly literals: (assembly literals allButLast: 2), {asIntegerProxy}, (assembly literals last: 2).
		"Do this by looking for index of pushReceiverVariable: and replacing it by pushSelf, send asInteger"
	newInsts := (assembly instructions piecesCutWhere:
					[:msgOrLabelAssoc :nextInst|
					 msgOrLabelAssoc isVariableBinding not
					 and: [msgOrLabelAssoc selector == #pushReceiverVariable:]]) fold:
				[:a :b|
				 a allButLast,
				 {	Message selector: #pushReceiver.
					Message
						selector: #send:super:numArgs:
						arguments: {asIntegerProxy. false. 0}},
				 b].
	assembly instructions: newInsts.
	newMethod := assembly assemble.
	self assert: clone numLiterals + 1 = newMethod numLiterals.
	^self
		installableMethodFor: newMethod
		selector: clone selector
		className: #Character
		isMeta: false
]

{ #category : #'bootstrap image' }
SpurBootstrap >> reportSizes [
	| change oldAvgBytes newAvgBytes |
	change := newHeapSize - oldHeapSize / oldHeapSize.
	oldAvgBytes := oldHeapSize asFloat / oldHeapNumObjs.
	Transcript
		nextPutAll: 'done.'; cr;
		nextPutAll: 'old heap size: '; nextPutAll: oldHeapSize asStringWithCommas; tab;
		nextPutAll: ' (avg obj bytes '; print: oldAvgBytes maxDecimalPlaces: 2; nextPutAll: ' words '; print: oldAvgBytes / self wordSize maxDecimalPlaces: 2; nextPut: $); cr;
		nextPutAll: 'initial new heap size: '; nextPutAll: newHeapSize asStringWithCommas; cr;
		nextPutAll: 'change: '; print: change * 100.0 maxDecimalPlaces: 2; nextPut: $%; cr;
		flush.
	newHeapSize := newHeap endOfMemory
					- newHeap scavenger eden limit
					- newHeap totalFreeListBytes.
	change := newHeapSize - oldHeapSize / oldHeapSize.
	newAvgBytes := newHeapSize asFloat / newHeapNumObjs.
	Transcript
		nextPutAll: 'final new heap size: '; nextPutAll: newHeapSize asStringWithCommas; tab;
		nextPutAll: ' (avg obj bytes '; print: newAvgBytes maxDecimalPlaces: 2; nextPutAll: ' words '; print: newAvgBytes / self wordSize maxDecimalPlaces: 2; nextPut: $); cr;
		nextPutAll: 'change: '; print: change * 100.0 maxDecimalPlaces: 2; nextPut: $%; cr;
		flush
]

{ #category : #'development support' }
SpurBootstrap >> saveTransformedImage [
	ImageHeaderFlags := oldInterpreter getImageHeaderFlags.
	ImageScreenSize := oldInterpreter savedWindowSize.
	ImageName := oldInterpreter imageName.
	newHeap coInterpreter: nil.
	(newHeap class allInstVarNames select: [:ivn| ivn beginsWith: 'stat']) do:
		[:ivn| newHeap instVarNamed: ivn put: 0].
	TransformedImage := newHeap veryDeepCopy
]

{ #category : #'bootstrap image' }
SpurBootstrap >> scavengeImage [
	"Scavenge the image to get it into a simpler state."
	newHeap coInterpreter voidVMStateForSnapshotFlushingExternalPrimitivesIf: false.
	newHeap flushNewSpace
]

{ #category : #'method prototypes' }
SpurBootstrap >> selectorForPrototypeMethod: protoMethod [
	| protoSelector |
	protoSelector := protoMethod selector.
	protoSelector := protoSelector last: protoSelector size
						- (protoSelector indexOfSubCollection: 'PROTOTYPE')
						- 'PROTOTYPE' size
						+ 1.
	(protoSelector beginsWith: 'Dollar') ifTrue:
		[protoSelector := (Dictionary newFromPairs: #('DollarEquals:' #=))
							at: protoSelector].
	^protoSelector asSymbol
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> stringFor: aString [
	| string |
	string := oldHeap instantiateClass: (oldHeap splObj: ClassByteString) indexableSize: aString size.
	1 to: aString size do:
		[:i| oldHeap storeByte: i - 1 ofObject: string withValue: (aString at: i) asInteger].
	^string

]

{ #category : #'bootstrap methods' }
SpurBootstrap >> symbolClass [
	^oldHeap fetchClassOfNonImm: (oldHeap splObj: SelectorDoesNotUnderstand)
]

{ #category : #'bootstrap image' }
SpurBootstrap >> transform [
	self findRequiredGlobals.
	self installModifiedMethods.
	self recreateSpecialObjectsArray.
	self initializeClasses.
	self bootstrapImage.
	self validate.
	self rehashImage.
	self followForwardingPointers.
	self scavengeImage.
	self freeForwarders.
	self compactImage.
	self reportSizes
]

{ #category : #'bootstrap image' }
SpurBootstrap >> validate [
	| p n duplicates maxClassIndex savedEndOfMemory |
	self assert: (reverseMap at: newHeap specialObjectsOop) = oldHeap specialObjectsOop.
	self assert: (map at: oldHeap specialObjectsOop) = newHeap specialObjectsOop.
	self assert: (reverseMap at: newHeap classTableRootObj ifAbsent: []) isNil.

	duplicates := { 3. newHeap arrayClassIndexPun. newHeap weakArrayClassIndexPun }.
	maxClassIndex := classToIndex inject: 0 into: [:a :b| a max: b].
	self assert: ((newHeap arrayClassIndexPun to: maxClassIndex) select:
					[:idx| | classObj |
					(classObj := newHeap classOrNilAtIndex: idx) ~= newHeap nilObject
					and: [(newHeap classIndexOf: classObj) = (newHeap rawHashBitsOf: classObj)]]) isEmpty.
	0 to: maxClassIndex do:
		[:index| | classObj |
		(index <= newHeap tagMask
		 and: [index > newHeap isForwardedObjectClassIndexPun]) ifTrue:
			[(classObj := newHeap classOrNilAtIndex: index) = newHeap nilObject
				ifTrue:
					[self assert: (classToIndex keyAtValue: index ifAbsent: []) isNil]
				ifFalse:
					[self assert: (newHeap classIndexOf: classObj) ~= (newHeap rawHashBitsOf: classObj).
					(duplicates includes: index) ifFalse:
						[self assert: (newHeap rawHashBitsOf: classObj) = index]]]].
	classToIndex keysAndValuesDo:
		[:oldClass :idx|
		self assert: (newHeap rawHashBitsOf: (map at: oldClass)) = idx. 
		self assert: oldClass = (reverseMap at: (newHeap classAtIndex: idx))].
	n := 0.
	savedEndOfMemory := newHeap endOfMemory.
	newHeap setEndOfMemory: newHeap freeOldSpaceStart.
	newHeap allObjectsDo:
		[:o|
		(o <= newHeap trueObject
		 or: [o > lastClassTablePage]) ifTrue:
			[self assert: (reverseMap includesKey: o).
			 self assert: (newHeap fetchClassOfNonImm: o) = (map at: (oldHeap fetchClassOfNonImm: (reverseMap at: o)))].
		n := n + 1.
		p := o].
	newHeap setEndOfMemory: savedEndOfMemory.
	self touch: p.
	self assert: (n between: map size and: map size + ((imageTypes includes: 'squeak')
														ifTrue: [6]
														ifFalse: [8])). "+ 6 or 8 is room for freelists & classTable"

	"check some class properties to ensure the format changes are correct"
	self assert: (newHeap fixedFieldsOfClassFormat: (newHeap formatOfClass: newHeap classArray)) = 0.
	self assert: (newHeap instSpecOfClassFormat: (newHeap formatOfClass: newHeap classArray)) = newHeap arrayFormat
]

{ #category : #'word size' }
SpurBootstrap >> wordSize [
	^self subclassResponsibility
]

{ #category : #'word size' }
SpurBootstrap >> wordSizeMask [
	^self subclassResponsibility
]

{ #category : #testing }
SpurBootstrap >> writeSnapshot: imageFileName ofTransformedImage: spurHeap headerFlags: headerFlags screenSize: screenSizeInteger [
	"The bootstrapped image typically contains a few big free chunks and one huge free chunk.
	 Test snapshot writing and loading by turning the largest non-huge chunks into segment bridges
	 and saving."
	| penultimate ultimate sizes counts barriers sim |
	sim := StackInterpreterSimulator onObjectMemory: spurHeap.
	sim bootstrapping: true.
	spurHeap
		coInterpreter: sim;
		setEndOfMemory: spurHeap endOfMemory + spurHeap bridgeSize. "hack; initializeInterpreter: cuts it back by bridgeSize"
	sim initializeInterpreter: 0;
		setImageHeaderFlagsFrom: headerFlags;
		setDisplayForm: nil.
	spurHeap allOldSpaceEntitiesDo: [:e| penultimate := ultimate. ultimate := e].
	(spurHeap isFreeObject: penultimate) ifTrue: "old, pre-pigCompact segmented save"
		[self assert: (spurHeap isSegmentBridge: ultimate).
		 sizes := Bag new.
		 spurHeap allObjectsInFreeTree: (spurHeap freeLists at: 0) do:
			[:f|
			sizes add: (spurHeap bytesInObject: f)].
		 counts := sizes sortedCounts.
		 self assert: counts last key = 1. "1 huge chunk"
		 counts size > 1
			ifTrue:
				[self assert: ((counts at: counts size - 1) key > 2
							and: [(counts at: counts size - 1) value > 1024]).
				barriers := (1 to: (counts at: counts size - 1) key) collect:
								[:ign| spurHeap allocateOldSpaceChunkOfExactlyBytes: (counts at: counts size - 1) value].
				barriers := barriers, {spurHeap allocateOldSpaceChunkOfExactlyBytes: (spurHeap bytesInObject: penultimate)}]
			ifFalse:
				[barriers := {spurHeap allocateOldSpaceChunkOfExactlyBytes: (spurHeap bytesInObject: penultimate)}].
		 barriers last ifNotNil:
			[:end|
			spurHeap setEndOfMemory: end.
			spurHeap allOldSpaceEntitiesDo: [:e| penultimate := ultimate. ultimate := e].
			self assert: (spurHeap addressAfter: ultimate) = end]].
	spurHeap checkFreeSpace.
	spurHeap runLeakCheckerForFullGC: true.
	barriers ifNotNil: "old, pre-pigCompact segmented save"
		[spurHeap segmentManager initializeFromFreeChunks: (barriers sort collect: [:b| spurHeap objectStartingAt: b])].
	spurHeap checkFreeSpace.
	spurHeap runLeakCheckerForFullGC: true.
	sim bereaveAllMarriedContextsForSnapshotFlushingExternalPrimitivesIf: true.
	sim imageName: imageFileName.
	sim writeImageFileIO.
	Transcript cr; show: 'Done!'
]

{ #category : #testing }
SpurBootstrap >> writeSnapshotOfTransformedImage [
	self writeSnapshotOfTransformedImageAs: 'spur.image'
]

{ #category : #testing }
SpurBootstrap >> writeSnapshotOfTransformedImageAs: imageFileName [
	"The bootstrapped image typically contains a few big free chunks and one huge free chunk.
	 Test snapshot writing and loading by turning the largest non-huge chunks into segment bridges
	 and saving."
	| penultimate ultimate heap sizes counts barriers sim |
	heap := TransformedImage veryDeepCopy.
	sim := StackInterpreterSimulator onObjectMemory: heap.
	sim bootstrapping: true.
	heap coInterpreter: sim.
	sim initializeInterpreter: 0;
		setImageHeaderFlagsFrom: ImageHeaderFlags;
		setDisplayForm: nil;
		setSavedWindowSize: ImageScreenSize >> 16 @ (ImageScreenSize bitAnd: 16rFFFF).
	heap allOldSpaceEntitiesDo: [:e| penultimate := ultimate. ultimate := e].
	self assert: (heap isFreeObject: penultimate).
	self assert: (heap isSegmentBridge: ultimate).
	sizes := Bag new.
	heap allObjectsInFreeTree: (heap freeLists at: 0) do:
		[:f|
		sizes add: (heap bytesInObject: f)].
	counts := sizes sortedCounts.
	self assert: counts last key = 1. "1 huge chunk"
	counts size > 1
		ifTrue:
			[self assert: ((counts at: counts size - 1) key > 2
						and: [(counts at: counts size - 1) value > 1024]).
			barriers := (1 to: (counts at: counts size - 1) key) collect:
							[:ign| heap allocateOldSpaceChunkOfExactlyBytes: (counts at: counts size - 1) value].
			barriers := barriers, {heap allocateOldSpaceChunkOfExactlyBytes: (heap bytesInObject: penultimate)}]
		ifFalse:
			[barriers := {heap allocateOldSpaceChunkOfExactlyBytes: (heap bytesInObject: penultimate)}].
	heap setEndOfMemory: barriers last.
	heap allOldSpaceEntitiesDo: [:e| penultimate := ultimate. ultimate := e].
	self assert: (heap addressAfter: ultimate) = barriers last.
	heap checkFreeSpace.
	heap runLeakCheckerForFullGC: true.
	heap segmentManager initializeFromFreeChunks: (barriers sort collect: [:b| heap objectStartingAt: b]).
	heap checkFreeSpace.
	heap runLeakCheckerForFullGC: true.
	sim bereaveAllMarriedContextsForSnapshotFlushingExternalPrimitivesIf: true.
	sim imageName: imageFileName.
	sim writeImageFileIO
]
