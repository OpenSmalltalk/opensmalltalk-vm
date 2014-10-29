"
A CurrentImageCoInterpreterFacade is a stand-in for an object memory (ObjectMemory, SpurMemoryManager, etc) that allows the Cogits to access image objects as if they were in the simulator VM's heap.  hence it allows the Cogits to generate code for methdos in the current image, for testing, etc.

Instance Variables
	cachedObject:			<Object>
	cachedOop:			<Integer>
	coInterpreter:			<CoInterpreter>
	cogit:					<Cogit>
	headerToMethodMap:	<Dictionary>
	memory:				<ByteArray>
	objectMap:				<IdentityDictionary>
	objectMemory:			<NewObjectMemory|SpurMemoryManager>
	variables:				<Dictionary>

cachedObject
	- the object matching cachedOop, to speed-up oop to obejct mapping

cachedOop
	- the last used oop

coInterpreter
	- the CoInterpreter simulator used by the cogit.

cogit
	- the code egnerator in use

headerToMethodMap
	- a map from header to CompiledMethod

memory
	- a rump memory for holding various interpreter variables (e.g. stackLimit) that are accessed as memory locations by generated code

objectMap
	- map from objects to their oops

objectMemory
	- the object memory used to encode various values, answer queries, etc

variables
	- a map from the names of variables to their addresses in memory

"
Class {
	#name : #CurrentImageCoInterpreterFacade,
	#superclass : #CogClass,
	#instVars : [
		'memory',
		'cogit',
		'coInterpreter',
		'objectMemory',
		'objectMap',
		'headerToMethodMap',
		'cachedObject',
		'cachedOop',
		'variables'
	],
	#pools : [
		'VMBasicConstants',
		'VMObjectIndices',
		'VMSqueakClassIndices'
	],
	#category : #'VMMaker-Support'
}

{ #category : #'instance creation' }
CurrentImageCoInterpreterFacade class >> forCogit: aCogit [
	| class |
	class := self allSubclasses
				detect: [:subclass| aCogit class objectMemoryClass = subclass objectRepresentationClass objectMemoryClass]
				ifNone: [self error: 'cannot find subclass for the Cogit''s objectRepresentation and/or objectMemory'].
	^class new
		cogit: aCogit;
		yourself
]

{ #category : #'accessing class hierarchy' }
CurrentImageCoInterpreterFacade class >> objectMemoryClass [
	^self subclassResponsibility
]

{ #category : #'accessing class hierarchy' }
CurrentImageCoInterpreterFacade class >> objectRepresentationClass [
	^self subclassResponsibility
]

{ #category : #labels }
CurrentImageCoInterpreterFacade >> addLabel: l [
	(variables includesKey: l) ifFalse:
		[variables at: l put: variables size * 4 + 65536]
]

{ #category : #'debug support' }
CurrentImageCoInterpreterFacade >> addressCouldBeObj: address [
	^(address bitAnd: 3) = 0
	  and: [self addressCouldBeOop: address]
]

{ #category : #'debug support' }
CurrentImageCoInterpreterFacade >> addressCouldBeOop: anOop [ 
	[self objectForOop: anOop]
		on: Error
		do: [:ex| ^false].
	^true
]

{ #category : #labels }
CurrentImageCoInterpreterFacade >> addressForLabel: l [
	^variables at: l ifAbsentPut: [variables size * 4 + self variablesBase]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> argumentCountAddress [
	^self addressForLabel: #argumentCount
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> argumentCountOf: anOop [
	^(self objectForOop: anOop) numArgs
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> argumentCountOfMethodHeader: aSmallIntegerOop [
	^(headerToMethodMap at: aSmallIntegerOop) numArgs
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> baseHeaderSize [
	^self subclassResponsibility
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> byteAt: index [
	^objectMemory byteAt: index
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> byteAt: index put: value [
	^objectMemory byteAt: index put: value
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> byteSizeOf: anOop [
	| obj elementSize |
	obj := self objectForOop: anOop.
	([obj class isImmediateClass]
		on: MessageNotUnderstood
		do: [:ex| obj class == SmallInteger]) ifTrue:
		[^0].
	elementSize := 
		[obj class elementSize]
			on: MessageNotUnderstood
			do: [:ex| obj class isBytes ifTrue: [1] ifFalse: [Smalltalk wordSize]].
	^obj basicSize * elementSize
]

{ #category : #'debug support' }
CurrentImageCoInterpreterFacade >> cCoerceSimple: value to: cTypeString [
	"Type coercion for translation and simulation.
	 For simulation answer a suitable surrogate for the struct types"
	^cTypeString
		caseOf:
		   {	[#'CogMethod *']		->	[cogit cogMethodSurrogateAt: value asUnsignedInteger].
			[#'CogBlockMethod *']	->	[cogit cogBlockMethodSurrogateAt: value asUnsignedInteger] }
		otherwise: [super cCoerceSimple: value to: cTypeString]
]

{ #category : #'cog jit support' }
CurrentImageCoInterpreterFacade >> callForCogCompiledCodeCompaction [
	cogit methodZone quickClearCogCompiledCode
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> canContextSwitchIfActivating: method header: header [
	^coInterpreter canContextSwitchIfActivating: method header: header
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> characterTable [
	^self subclassResponsibility
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> classFieldOffset [
	^objectMemory classFieldOffset
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> classFloat [
	^self oopForObject: Float
]

{ #category : #'object map' }
CurrentImageCoInterpreterFacade >> classSmallInteger [
	^self oopForObject: SmallInteger
]

{ #category : #'cog jit support' }
CurrentImageCoInterpreterFacade >> clearCogCompiledCodeCompactionCalledFor [
	^self
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> cogCodeSize [
	^memory byteSize / 4
]

{ #category : #'initialize-release' }
CurrentImageCoInterpreterFacade >> cogit [
	^cogit
]

{ #category : #'initialize-release' }
CurrentImageCoInterpreterFacade >> cogit: aCogit [
	cogit := aCogit.
	coInterpreter cogit: aCogit.
	(objectMemory respondsTo: #cogit:) ifTrue:
		[objectMemory cogit: aCogit].
	(objectMemory respondsTo: #coInterpreter:) ifTrue:
		[objectMemory coInterpreter: coInterpreter]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> compactClassFieldLSB [
	^objectMemory compactClassFieldLSB
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> compactClassFieldWidth [
	^objectMemory compactClassFieldWidth
]

{ #category : #'debug support' }
CurrentImageCoInterpreterFacade >> compilationBreak: aString point: length [ 
	^self
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> debugStackPointersFor: anOop [
	^CArrayAccessor on:
		((StackDepthFinder on: (objectMap keyAtValue: anOop))
			encoderClass: (coInterpreter encoderClassForHeader: (objectMap keyAtValue: anOop) header);
			stackPointers)
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> eeInstantiateClass: classOop indexableSize: numSlots [
	^self oopForObject: ((self objectForOop: classOop) new: numSlots)
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> encoderClassForHeader: headerInteger [
	^coInterpreter encoderClassForHeader: headerInteger
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> endPCOf: methodOop [
	^(objectMap keyAtValue: methodOop) endPC - 1
]

{ #category : #'cog jit support' }
CurrentImageCoInterpreterFacade >> ensureNoForwardedLiteralsIn: methodOop [
]

{ #category : #'object map' }
CurrentImageCoInterpreterFacade >> falseObject [
	^objectMap at: false
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> fetchByte: index ofObject: anOop [
	^(self objectForOop: anOop)
		at: index + 1
		ifAbsent:
			[Transcript
				ensureCr;
				nextPutAll: 'warning, accessing past end of '; print: (objectMap keyAtValue: anOop);
				cr;
				flush.
			255]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> fetchPointer: index ofObject: anOop [
	| obj |
	obj := (objectMap keyAtValue: anOop).
	^self oopForObject: (obj isCompiledMethod
							ifTrue: [obj objectAt: index + 1]
							ifFalse: [obj instVarAt: index + 1])
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> formatOfClass: classOop [
	^self subclassResponsibility
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> framePointerAddress [
	^self addressForLabel: #framePointer
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> freeStartAddress [
	^self addressForLabel: #freeStart
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> functionPointerFor: primIndex inClass: lookupClass [
	^primIndex = 0
		ifTrue: [#primitiveFail]
		ifFalse: [coInterpreter functionPointerFor: primIndex inClass: lookupClass]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> functionPointerForCompiledMethod: methodOop primitiveIndex: primIndex [
	^([coInterpreter functionPointerForCompiledMethod: methodOop primitiveIndex: primIndex]
			on: MessageNotUnderstood
			do: [:ex|
				#someExternalPrimitive]) ifNotNil:
		[:symbol|
		self addressForLabel: symbol]
]

{ #category : #'cog jit support' }
CurrentImageCoInterpreterFacade >> getCheckAllocFiller [
	^coInterpreter getCheckAllocFiller ifNil: [false]
]

{ #category : #testing }
CurrentImageCoInterpreterFacade >> headerIndicatesAlternateBytecodeSet: methodHeader [
	"A negative header selects the alternate bytecode set."
	^(self objectForOop: methodHeader) < 0
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> inMemoryCFramePointerAddress [
	^self addressForLabel: #CFramePointer
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> inMemoryCStackPointerAddress [
	^self addressForLabel: #CStackPointer
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> indexablePointersFormat [
	^objectMemory indexablePointersFormat
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> initialPCForHeader: methodHeaderOop method: aMethodOop [
	self assert: (self objectForOop: aMethodOop) == (headerToMethodMap at: methodHeaderOop).
	^{ self objectForOop: aMethodOop. (self objectForOop: aMethodOop) initialPC }
]

{ #category : #'initialize-release' }
CurrentImageCoInterpreterFacade >> initialize [
	memory := (VMBIGENDIAN
					ifTrue: [Bitmap]
					ifFalse: [LittleEndianBitmap]) new: 1024*1024/4.
	objectMemory := self class objectMemoryClass simulatorClass new.
	objectMemory
		initializeFreeSpaceForFacadeFrom: self startOfMemory
		to: self variablesBase.
	objectMemory memory: memory.
	coInterpreter := CoInterpreter new.
	coInterpreter
		instVarNamed: 'objectMemory'
			put: objectMemory;
		instVarNamed: 'primitiveTable'
			put: (CArrayAccessor on: CoInterpreter primitiveTable copy).
	variables := Dictionary new.
	#('stackLimit') do:
		[:l| self addressForLabel: l].
	self initializeObjectMap
]

{ #category : #'initialize-release' }
CurrentImageCoInterpreterFacade >> initializeObjectMap [
	objectMap := IdentityDictionary new.
	headerToMethodMap := Dictionary new.
	{ nil. false. true. Smalltalk primitiveErrorTable. Float } do:
		[:o| self oopForObject: o]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> instFormatFieldLSB [
	^objectMemory instFormatFieldLSB
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> instFormatFieldWidth [
	^objectMemory instFormatFieldWidth
]

{ #category : #instantiation }
CurrentImageCoInterpreterFacade >> instantiateClass: classPointer indexableSize: size [
	(self objectForOop: classPointer) caseOf:
		{[Array]	->	[^self oopForObject: (Array new: size)]}
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> instructionPointerAddress [
	^self addressForLabel: #instructionPointer
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> integerObjectOf: anInteger [
	^objectMemory integerObjectOf: anInteger
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> integerValueOf: anInteger [
	^objectMemory integerValueOf: anInteger
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> interpretAddress [
	^self addressForLabel: #interpret
]

{ #category : #testing }
CurrentImageCoInterpreterFacade >> isArrayNonImm: anOop [
	^(self objectForOop: anOop) class instSpec = Array instSpec
]

{ #category : #'cog jit support' }
CurrentImageCoInterpreterFacade >> isCogCompiledCodeCompactionCalledFor [
	^true
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> isCogMethodReference: methodHeader [
	^coInterpreter isCogMethodReference: methodHeader
]

{ #category : #testing }
CurrentImageCoInterpreterFacade >> isCurrentImageFacade [
	^true
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> isImmediate: anOop [
	^objectMemory isImmediate: anOop
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> isIntegerObject: anOop [
	^objectMemory isIntegerObject: anOop
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> isIntegerValue: anInteger [
	^objectMemory isIntegerValue: anInteger
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> isNonImmediate: anOop [
	^objectMemory isNonImmediate: anOop
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> isNonIntegerObject: anOop [
	^objectMemory isNonIntegerObject: anOop
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> isQuickPrimitiveIndex: primNum [
	^coInterpreter isQuickPrimitiveIndex: primNum
]

{ #category : #'frame access' }
CurrentImageCoInterpreterFacade >> isReadMediatedContextInstVarIndex: index [
	"Reading the sender, instructionPointer and stackPointer inst vars of a context must take
	 account of potentially married contexts and fetch the state from the frame. method,
	 closureOrNil and receiver can safely be fetched from the context without checking."
	^index <= StackPointerIndex
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> isThreadedVM [
	^false
]

{ #category : #'frame access' }
CurrentImageCoInterpreterFacade >> isWriteMediatedContextInstVarIndex: index [
	"Writing any inst vars of a context must take account of potentially married contexts
	 and set the state in the frame. Inst vars in subclasses don't need mediation; subclasses
	 can't marry."
	^index <= ReceiverIndex
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> isYoung: anOop [
	^false
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> isYoungObject: anOop [
	^false
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> lengthOf: anOop [
	^(self objectForOop: anOop) basicSize
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> literal: index ofMethod: anOop [
	| lit |
	lit := (self objectForOop: anOop) literalAt: index + 1.
	^lit class == SmallInteger
		ifTrue: [objectMemory integerObjectOf: lit]
		ifFalse: [self oopForObject: lit]
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> literalCountOf: anOop [
	^(objectMap keyAtValue: anOop) numLiterals
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> literalCountOfMethodHeader: headerIntegerOop [
	^objectMemory literalCountOfMethodHeader: headerIntegerOop
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> long32At: index [
	^objectMemory long32At: index
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> long32At: index put: value [
	^objectMemory long32At: index put: value
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> longAt: index [
	^objectMemory longAt: index
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> longAt: index put: value [
	^objectMemory longAt: index put: value
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> longStoreBytecodeForHeader: methodHeaderOop [
	"Answer the relevant long store temp bytecode, which indicates it has a primitive error code."
	"234		11101010	i i i i i i i i	Store Temporary Variable #iiiiiiii"
	"129 		10000001 jjkkkkkk 	Store (Receiver Variable, Temporary Location, Illegal, Literal Variable) [jj] #kkkkkk"
	^coInterpreter longStoreBytecodeForHeader: methodHeaderOop
	"was: ^(headerToMethodMap at: methodHeaderOop) usesAlternateBytecodeSet
		ifTrue: [234]
		ifFalse: [129]"
]

{ #category : #labels }
CurrentImageCoInterpreterFacade >> lookupAddress: address [
	| thing |
	thing := objectMap
				keyAtValue: address
				ifAbsent:
					[variables
						keyAtValue: address
						ifAbsent: [^nil]].
	^(thing isLiteral
		ifTrue: [thing storeString]
		ifFalse: [thing asString]) contractTo: 64
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> memory [
	^memory
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> methodCacheAddress [
	"Use the top half of memory for variables, methodcache and rumpCStack,
	 and the bottom half for allocating code and objects:

		0 - 256k:			code zone
		256k to 512k		object zone
		512k to 768k		variables
		768k to 1023k		method cache
		 1023k to 1024k	rump C stack"
	^memory byteSize * 3 / 4
]

{ #category : #testing }
CurrentImageCoInterpreterFacade >> methodHasCogMethod: aCompiledMethod [ 
	^false
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> methodHeaderOf: oop [
	^(self objectForOop: oop) header
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> methodNeedsLargeContext: aMethodOop [ 
	^(self objectForOop: aMethodOop) frameSize > CompiledMethod smallFrameSize
]

{ #category : #testing }
CurrentImageCoInterpreterFacade >> methodUsesAlternateBytecodeSet: methodObjOop [
	"A negative header selects the alternate bytecode set."
	^(self objectForOop: methodObjOop) signFlag
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> newMethodAddress [
	^self addressForLabel: #newMethod
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> nextProfileTickAddress [
	^self addressForLabel: #nextProfileTick
]

{ #category : #'object map' }
CurrentImageCoInterpreterFacade >> nilObject [
	^objectMap at: nil
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> noAssertHeaderOf: aMethodOop [
	^self rawHeaderOf: aMethodOop
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> nullHeaderForMachineCodeMethod [
	^objectMemory nullHeaderForMachineCodeMethod
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> numBytesOf: objOop [ 
	"Answer the number of indexable bytes in the given non-immediate object.
	 Does not adjust the size of contexts by stackPointer."
	| obj elementSize |
	obj := self objectForOop: objOop.
	self deny: ([obj class isImmediateClass]
				on: MessageNotUnderstood
				do: [:ex| obj class == SmallInteger]).
	elementSize := 
		[obj class elementSize]
			on: MessageNotUnderstood
			do: [:ex| obj class isBytes ifTrue: [1] ifFalse: [Smalltalk wordSize]].
	^obj basicSize * elementSize
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> numSlotsOf: objOop [
	"Answer the number of slots in the given non-immediate object.
	 Does not adjust the size of contexts by stackPointer."
	| obj elementSize wordSize |
	obj := self objectForOop: objOop.
	obj = objOop ifTrue:
		[^objectMemory numSlotsOf: objOop].
	self deny: ([obj class isImmediateClass]
				on: MessageNotUnderstood
				do: [:ex| obj class == SmallInteger]).
	wordSize := Smalltalk wordSize.
	elementSize := 
		[obj class elementSize]
			on: MessageNotUnderstood
			do: [:ex| obj class isBytes ifTrue: [1] ifFalse: [wordSize]].
	wordSize = 4 ifTrue:
		[^elementSize caseOf: {
			[1]	->	[obj basicSize + 3 // wordSize].
			[2]	->	[obj basicSize * 2 + 3 // wordSize].
			[4]	->	[obj basicSize + obj class instSize] }].
	^elementSize caseOf: {
		[1]	->	[obj basicSize + (wordSize - 1) // wordSize].
		[2]	->	[obj basicSize * 2 + (wordSize - 1) // wordSize].
		[4]	->	[obj basicSize * 2 + (wordSize - 1) // wordSize].
		[8]	->	[obj basicSize + obj class instSize] }
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> objectAfter: anOop [
	^anOop + 8
]

{ #category : #'private-cacheing' }
CurrentImageCoInterpreterFacade >> objectForOop: anOop [
	"This is a keyAtValue: search and so needs speeding up either by a reverse map or a simple cache."
	^(anOop bitAnd: 3) caseOf: {
		[0] -> [anOop = cachedOop
				ifTrue: [cachedObject]
				ifFalse: [cachedObject := objectMap keyAtValue: anOop. "may raise Error"
						cachedOop := anOop. "Dom't assign until accessed without error"
						cachedObject]].
		[1] -> [anOop signedIntFromLong >> 1].
		[3] -> [anOop signedIntFromLong >> 1] }
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> objectMemory [
	^self
]

{ #category : #'object map' }
CurrentImageCoInterpreterFacade >> oopForObject: o [
	^o isInteger
		ifTrue: [o << 1 bitOr: 1]
		ifFalse: [objectMap at: o ifAbsentPut: [objectMap size * 8 + (1024 * 1024)]]
]

{ #category : #testing }
CurrentImageCoInterpreterFacade >> picDataFor: cogMethod [
	| cm nBytes nEntries oversizeData |
	cm := cogMethod methodObject.
	nBytes := (self byteSizeOf: cm) - (self startPCOfMethod: cm).
	oversizeData := Array new: nBytes.
	nEntries := cogit picDataFor: cogMethod into: (self oopForObject: oversizeData).
	^oversizeData copyFrom: 1 to: nEntries
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> primErrTable [
	^objectMap at: Smalltalk primitiveErrorTable
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> primFailCodeAddress [
	^self addressForLabel: #primFailCode
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> primTraceLogAddress [
	^self addressForLabel: #primTraceLog
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> primTraceLogIndexAddress [
	^coInterpreter primTraceLogIndexAddress
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> primitiveFailAddress [
	^self addressForLabel: #primitiveFail
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> primitiveFunctionPointerAddress [
	^self addressForLabel: #primitiveFunctionPointer
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> primitiveIndexOf: anOop [
	^(self objectForOop: anOop) primitive
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> primitivePropertyFlags: primIndex [
	^coInterpreter primitivePropertyFlags: primIndex
]

{ #category : #printing }
CurrentImageCoInterpreterFacade >> printHex: anInteger [
	coInterpreter printHex: anInteger
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> quickPrimitiveConstantFor: aQuickPrimitiveIndex [
	^self oopForObject: (coInterpreter quickPrimitiveConstantFor: aQuickPrimitiveIndex)
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> quickPrimitiveGeneratorFor: aQuickPrimitiveIndex [
	^coInterpreter quickPrimitiveGeneratorFor: aQuickPrimitiveIndex
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> quickPrimitiveInstVarIndexFor: aQuickPrimitiveIndex [
	^coInterpreter quickPrimitiveInstVarIndexFor: aQuickPrimitiveIndex
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> rawHeaderOf: aMethodOop [
	| method headerOop |
	method := self objectForOop: aMethodOop.
	headerOop := objectMemory integerObjectOf: (self objectForOop: aMethodOop) header.
	self assert: method = (headerToMethodMap at: headerOop ifAbsentPut: [method]).
	^headerOop
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> rawHeaderOf: anOop put: aCogMethodSurrogate [
	^self
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> rumpCStackAddress [
	"Use the top half of memory for variables, methodcache and rumpCStack,
	 and the bottom half for allocating code and objects:

		0 - 256k:			code zone
		256k to 512k		object zone
		512k to 768k		variables
		768k to 1023k		method cache
		 1023k to 1024k	rump C stack"
	^memory byteSize - 1024
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> scavengeThresholdAddress [
	^self addressForLabel: #scavengeThreshold
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> sizeOfCallPrimitiveBytecode: methodHeaderOop [
	^coInterpreter sizeOfCallPrimitiveBytecode: methodHeaderOop
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> sizeOfLongStoreTempBytecode: methodHeaderOop [ 
	^coInterpreter sizeOfLongStoreTempBytecode: methodHeaderOop
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> specialSelector: index [ 
	^self oopForObject: (Smalltalk specialSelectors at: index * 2 + 1)
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> specialSelectorNumArgs: index [ 
	^Smalltalk specialSelectors at: index * 2 + 2
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> splObj: splObjIndex [
	^splObjIndex caseOf: {
		[ClassArray]					-> [self oopForObject: Array].
		[ClassCharacter]				-> [self oopForObject: Character].
		[ClassLargeNegativeInteger]	-> [self oopForObject: LargeNegativeInteger].
		[ClassLargePositiveInteger]	-> [self oopForObject: LargePositiveInteger].
		[ClassSmallInteger]				-> [self oopForObject: SmallInteger].
		[CompactClasses]				-> [self oopForObject: Smalltalk compactClassesArray]
		}
]

{ #category : #labels }
CurrentImageCoInterpreterFacade >> stackLimitAddress [
	^variables at: 'stackLimit'
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> stackPointerAddress [
	^self addressForLabel: #stackPointer
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> startOfMemory [
	"Use the top half of memory for variables, methodcache and rumpCStack,
	 and the bottom half for allocating code and objects:

		0 - 256k:			code zone
		256k to 512k		object zone
		512k to 768k		variables
		768k to 1023k		method cache
		 1023k to 1024k	rump C stack"
	^memory byteSize / 4
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> startPCOfMethod: anOop [
	^(objectMap keyAtValue: anOop) initialPC - 1
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> startPCOfMethodHeader: aSmallIntegerOop [
	^(headerToMethodMap at: aSmallIntegerOop) initialPC - 1
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> startPCOrNilOfLiteral: literalOop in: methodOop [
	^(literalOop isClosure
	   and: [literalOop method == (objectMap keyAtValue: methodOop)]) ifTrue:
		[literalOop startpc]
]

{ #category : #testing }
CurrentImageCoInterpreterFacade >> storePointer: index ofObject: objOop withValue: valueOop [ 
	(self objectForOop: objOop)
		at: index + 1
		put: (self objectForOop: valueOop)
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> storePointerUnchecked: zeroRelativeIndex ofObject: targetOop withValue: valueOop [
	(self objectForOop: targetOop) at: zeroRelativeIndex + 1 put: (self objectForOop: valueOop)
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> stringOf: anOop [
	^self lookupAddress: anOop
]

{ #category : #testing }
CurrentImageCoInterpreterFacade >> tempCountForBlockStartingAt: startpc in: methodOop [
	^BlockLocalTempCounter
		tempCountForBlockStartingAt: startpc
		in: (self objectForOop: methodOop)
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> tempCountOf: anOop [
	^(self objectForOop: anOop) numTemps
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> temporaryCountOfMethodHeader: header [
	^(CompiledMethod
			newMethod: 8
			header: (header <= SmallInteger maxVal
						ifTrue: [header]
						ifFalse: [(header bitAnd: SmallInteger maxVal) + SmallInteger minVal]))
		numTemps
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> threadManager [
	^nil
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> transcript [
	^Transcript
]

{ #category : #'object map' }
CurrentImageCoInterpreterFacade >> trueObject [
	^objectMap at: true
]

{ #category : #private }
CurrentImageCoInterpreterFacade >> variablesBase [
	"Use the top half of memory for variables, methodcache and rumpCStack, and the bottom half for allocating code and objects:

		0 - 256k:			code zone
		256k to 512k		object zone
		512k to 768k		variables
		768k to 1023k		method cache
		 1023k to 1024k	rump C stack"
	^memory byteSize / 2
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> wordSize [
	^objectMemory wordSize
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> youngStartAddress [
	^self subclassResponsibility
]
