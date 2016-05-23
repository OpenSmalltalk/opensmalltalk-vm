Class {
	#name : #SpurBootstrapCuisPrototypes,
	#superclass : #SpurBootstrapSqueakFamilyPrototypes,
	#category : #'Cog-Bootstrapping'
}

{ #category : #accessing }
SpurBootstrapCuisPrototypes class >> imageType [
	^ 'cuis'
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> ArrayPROTOTYPEcreateMethod: numberOfBytesForAllButTrailer class: aCompiledMethodClass header: headerWord [ 
	| meth delta |
	meth := aCompiledMethodClass newMethod: numberOfBytesForAllButTrailer + self size header: headerWord.
	"copy the trailer data"
	delta := meth size - self size.
	1 to: self size do:
		[:i | meth at: delta + i put: (self at: i)].
	^meth
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> BehaviorPROTOTYPEidentityHash [
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
SpurBootstrapCuisPrototypes >> BlockClosurePROTOTYPEsimulateValueWithArguments: anArray caller: aContext [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> CharacterPROTOTYPEclone [
	"Answer the receiver, because Characters are unique."
	^self
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> CharacterPROTOTYPEsetValue: v [
	<remove>
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> CharacterPROTOTYPEvalue [
	"Answer the value of the receiver that represents its ISO 8859-15 (Latin-9) encoding."
	<primitive: 171>
	^self primitiveFailed
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> CharacterclassPROTOTYPEinitialize [
	<ignore>
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> ClassDescriptionPROTOTYPEupdateInstancesFrom: oldClass [
	"Recreate any existing instances of the argument, oldClass, as instances of 
	 the receiver, which is a newly changed class. Permute variables as necessary,
	 and forward old instances to new instances.. Answer nil to defeat any clients
	 that expected the old behaviour of answering the array of old instances."
	"ar 7/15/1999: The updating below is possibly dangerous. If there are any
	contexts having an old instance as receiver it might crash the system if
	the new receiver in which the context is executed has a different layout.
	See bottom below for a simple example:"
	self updateInstances: oldClass allInstances asArray from: oldClass isMeta: self isMeta.
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
SpurBootstrapCuisPrototypes >> ClassDescriptionPROTOTYPEupdateMethodBindingsTo: aBinding [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> ClassPROTOTYPEimmediateSubclass: t instanceVariableNames: f classVariableNames: d poolDictionaries: s category: cat [ 
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

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> CompiledMethodPROTOTYPEbytecodeSetName [
	^self encoderClass name copyReplaceAll: 'EncoderFor' with: ''
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> CompiledMethodPROTOTYPEheaderDescription [
	"Answer a description containing the information about the form of the
	 receiver and the form of the context needed to run the receiver."

	^(String new: 128) writeStream
		print: self header; cr;
		nextPutAll: '"primitive: '; print: self primitive; cr;
		nextPutAll: ' numArgs: '; print: self numArgs; cr;
		nextPutAll: ' numTemps: '; print: self numTemps; cr;
		nextPutAll: ' numLiterals: '; print: self numLiterals; cr;
		nextPutAll: ' frameSize: '; print: self frameSize; cr;
		nextPutAll: ' bytecodeSet: '; nextPutAll: self bytecodeSetName;
		nextPut: $"; cr;
		contents
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> ContextPartPROTOTYPEactivateReturn: aContext value: value [
	"Activate 'aContext return: value' in place of self, so execution will return to aContext's sender"

	^MethodContext 
		sender: self
		receiver: aContext
		method: MethodContext theReturnMethod
		arguments: {value}
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> ContextPartPROTOTYPEdoPrimitive: primitiveIndex method: meth receiver: receiver args: arguments [
	"Simulate a primitive method whose index is primitiveIndex.  The simulated receiver and
	 arguments are given as arguments to this message. If successful, push result and return
	 resuming context, else ^ {errCode, PrimitiveFailToken}. Any primitive which provokes
	 execution needs to be intercepted and simulated to avoid execution running away."

	| value |
	"Judicious use of primitive 19 (a null primitive that doesn't do anything) prevents
	 the debugger from entering various run-away activities such as spawning a new
	 process, etc.  Injudicious use results in the debugger not being able to debug
	 interesting code, such as the debugger itself.  hence use primitive 19 with care :-)"
	"SystemNavigation new browseAllSelect: [:m| m primitive = 19]"
	primitiveIndex = 19 ifTrue:
		[Debugger 
			openContext: self
			label:'Code simulation error'
			contents: nil].

	((primitiveIndex between: 201 and: 222)
	 and: [(self objectClass: receiver) includesBehavior: BlockClosure]) ifTrue:
		[((primitiveIndex between: 201 and: 205)			 "BlockClosure>>value[:value:...]"
		  or: [primitiveIndex between: 221 and: 222]) ifTrue: "BlockClosure>>valueNoContextSwitch[:]"
			[^receiver simulateValueWithArguments: arguments caller: self].
		 primitiveIndex = 206 ifTrue:						"BlockClosure>>valueWithArguments:"
			[^receiver simulateValueWithArguments: arguments first caller: self]].

	primitiveIndex = 83 ifTrue: "afr 9/11/1998 19:50" "Object>>perform:[with:...]"
		[^self send: arguments first to: receiver with: arguments allButFirst super: false].
	primitiveIndex = 84 ifTrue: "afr 9/11/1998 19:50 & eem 8/18/2009 17:04" "Object>>perform:withArguments:"
		[^self send: arguments first to: receiver with: (arguments at: 2) lookupIn: (self objectClass: receiver)].
	primitiveIndex = 100 ifTrue: "eem 8/18/2009 16:57" "Object>>perform:withArguments:inSuperclass:"
		[^self send: arguments first to: receiver with: (arguments at: 2) lookupIn: (arguments at: 3)].

	"Mutex>>primitiveEnterCriticalSection
	 Mutex>>primitiveTestAndSetOwnershipOfCriticalSection"
	(primitiveIndex = 186 or: [primitiveIndex = 187]) ifTrue:
		[| active effective |
		 active := Processor activeProcess.
		 effective := active effectiveProcess.
		 "active == effective"
		 value := primitiveIndex = 186
					ifTrue: [receiver primitiveEnterCriticalSectionOnBehalfOf: effective]
					ifFalse: [receiver primitiveTestAndSetOwnershipOfCriticalSectionOnBehalfOf: effective].
		 ^(self isPrimFailToken: value)
			ifTrue: [value]
			ifFalse: [self push: value]].

	primitiveIndex = 188 ifTrue: "eem 5/27/2008 11:10 Object>>withArgs:executeMethod:"
		[^MethodContext
			sender: self
			receiver: receiver
			method: (arguments at: 2)
			arguments: (arguments at: 1)].

	"Closure primitives"
	(primitiveIndex = 200 and: [self == receiver]) ifTrue:
		"ContextPart>>closureCopy:copiedValues:; simulated to get startpc right"
		[^self push: (BlockClosure
						outerContext: receiver
						startpc: self pc + 2
						numArgs: arguments first
						copiedValues: arguments last)].

	primitiveIndex = 118 ifTrue: "tryPrimitive:withArgs:; avoid recursing in the VM"
		[(arguments size = 2
		 and: [arguments first isInteger
		 and: [(self objectClass: arguments last) == Array]]) ifFalse:
			[^ContextPart primitiveFailTokenFor: nil].
		 ^self doPrimitive: arguments first method: meth receiver: receiver args: arguments last].

	value := primitiveIndex = 120 "FFI method"
				ifTrue: [(meth literalAt: 1) tryInvokeWithArguments: arguments]
				ifFalse:
					[primitiveIndex = 117 "named primitives"
						ifTrue: [self tryNamedPrimitiveIn: meth for: receiver withArgs: arguments]
						ifFalse: [receiver tryPrimitive: primitiveIndex withArgs: arguments]].

	^(self isPrimFailToken: value)
		ifTrue: [value]
		ifFalse: [self push: value]
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> ContextPartPROTOTYPEisPrimFailToken: anObject [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> ContextPartPROTOTYPEsend: selector to: rcvr with: arguments lookupIn: lookupClass [
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
SpurBootstrapCuisPrototypes >> ContextPartPROTOTYPEsend: selector to: rcvr with: arguments super: superFlag [ 
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
SpurBootstrapCuisPrototypes >> ContextPartPROTOTYPEtryNamedPrimitiveIn: aCompiledMethod for: aReceiver withArgs: arguments [
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

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> IntegerclassPROTOTYPEinitialize [
	"Integer initialize"	
	self initializeLowBitPerByteTable
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> MethodContextPROTOTYPEfailPrimitiveWith: maybePrimFailToken [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> MethodContextclassPROTOTYPEallInstances [
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

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> MethodContextclassPROTOTYPEallInstancesDo: aBlock [
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
SpurBootstrapCuisPrototypes >> MethodNodePROTOTYPEgenerate: trailer using: aCompiledMethodClass ifQuick: methodBlock [
	<indirect>
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> ProtoObjectPROTOTYPEscaledIdentityHash [
	"For identityHash values returned by primitive 75, answer
	 such values times 2^8.  Otherwise, match the existing
	 identityHash implementation"

	^self identityHash * 256 "bitShift: 8"
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> SmallIntegerPROTOTYPEclone [
	"Answer the receiver, because SmallIntegers are unique."
	^self
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> SmalltalkImagePROTOTYPErecreateSpecialObjectsArray [
	<remove>
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> SmalltalkImagePROTOTYPEsetGCParameters [
	"Adjust the VM's default GC parameters to avoid too much tenuring.
	 Maybe this should be left to the VM?"
	<remove>
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> SystemDictionaryPROTOTYPErecreateSpecialObjectsArray [
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
	newArray at: 4 put: (self associationAt: #Processor).
	"Numerous classes below used for type checking and instantiation"
	newArray at: 5 put: Bitmap.
	newArray at: 6 put: SmallInteger.
	newArray at: 7 put: String.
	newArray at: 8 put: Array.
	newArray at: 9 put: Smalltalk.
	newArray at: 10 put: BoxedFloat64.
	newArray at: 11 put: MethodContext.
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
	newArray at: 54 put: #invokeCallbackContext:. "use invokeCallback:stack:registers:jmpbuf: for old Alien callbacks."
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

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> SystemDictionaryPROTOTYPEsetGCParameters [
	"Adjust the VM's default GC parameters to avoid too much tenuring.
	 Maybe this should be left to the VM?"

	| proportion edenSize survivorSize averageObjectSize numObjects |
	proportion := 0.9. "tenure when 90% of pastSpace is full"
	edenSize := Smalltalk vmParameterAt: 44.
	survivorSize := edenSize / 5.0. "David's paper uses 140Kb eden + 2 x 28kb survivor spaces; Spur uses the same ratios :-)"
	averageObjectSize := 8 * self wordSize. "a good approximation"
	numObjects := (proportion * survivorSize / averageObjectSize) rounded.
	Smalltalk vmParameterAt: 6 put: numObjects  "tenure when more than this many objects survive the GC"
]

{ #category : #'method prototypes' }
SpurBootstrapCuisPrototypes >> SystemDictionaryPROTOTYPEwordSize [
	"Answer the size in bytes of an object pointer or word in the object memory.
	 The value does not change for a given image, but may be modified by a SystemTracer
	 when converting the image to another format."

	"Smalltalk wordSize"

	^self vmParameterAt: 40
]
