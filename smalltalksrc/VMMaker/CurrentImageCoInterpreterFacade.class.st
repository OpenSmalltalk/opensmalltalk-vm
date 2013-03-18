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
		'VMObjectIndices'
	],
	#category : #'VMMaker-Support'
}

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
	^variables at: l ifAbsentPut: [variables size * 4 + 131072]
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
CurrentImageCoInterpreterFacade >> byteAt: index [
	^memory at: index + 1
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> byteAt: index put: value [
	^memory at: index + 1 put: value
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> byteLengthOf: anOop [
	| obj |
	obj := self objectForOop: anOop.
	obj class isBytes ifTrue:
		[^obj basicSize].
	self error: 'cannot determine byte size of argument'
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> byteSizeOf: anOop [
	^(self objectForOop: anOop) basicSize
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
	^self oopForObject: Character characterTable
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> classFieldOffset [
	^objectMemory classFieldOffset
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> classFloat [
	^self oopForObject: Float
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> classFloatCompactIndex [
	^objectMemory classFloatCompactIndex
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
	^memory size / 2
]

{ #category : #'initialize-release' }
CurrentImageCoInterpreterFacade >> cogit [
	^cogit
]

{ #category : #'initialize-release' }
CurrentImageCoInterpreterFacade >> cogit: aCogit [
	cogit := aCogit.
	coInterpreter cogit: aCogit.
	objectMemory cogit: aCogit
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> compactClassFieldLSB [
	^objectMemory compactClassFieldLSB
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> compactClassFieldWidth [
	^objectMemory compactClassFieldWidth
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> compactClassTable [
	^self oopForObject: Smalltalk compactClassesArray
]

{ #category : #'debug support' }
CurrentImageCoInterpreterFacade >> compilationBreak: aString point: length [ 
	^self
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> debugStackPointersFor: anOop [
	^CArrayAccessor on:
		(((NewspeakVM
				ifTrue: [NewspeakStackDepthFinder]
				ifFalse: [StackDepthFinder]) on: (objectMap keyAtValue: anOop))
			stackPointers)
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> eeInstantiateClass: classOop indexableSize: numSlots [
	^self oopForObject: ((self objectForOop: classOop) new: numSlots)
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> endPCOf: methodOop [
	^(objectMap keyAtValue: methodOop) endPC - 1
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
CurrentImageCoInterpreterFacade >> formatOfClass: classOop [ 
	^(self objectForOop: classOop) format << 1
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

{ #category : #testing }
CurrentImageCoInterpreterFacade >> headerIndicatesAlternateBytecodeSet: methodHeader [
	"A negative header selects the alternate bytecode set."
	^(self objectForOop: methodHeader) < 0
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> headerOf: aMethodOop [
	^self rawHeaderOf: aMethodOop
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
CurrentImageCoInterpreterFacade >> initialPCForHeader: methodHeaderOop method: aMethodOop [
	self assert: (self objectForOop: aMethodOop) == (headerToMethodMap at: methodHeaderOop).
	^{ self objectForOop: aMethodOop. (self objectForOop: aMethodOop) initialPC }
]

{ #category : #'initialize-release' }
CurrentImageCoInterpreterFacade >> initialize [
	memory := ByteArray new: 262144.
	objectMemory := NewCoObjectMemory new.
	coInterpreter := CoInterpreter new.
	coInterpreter
		instVarNamed: 'objectMemory'
			put: objectMemory;
		instVarNamed: 'primitiveTable'
			put: (CArrayAccessor on: CoInterpreter primitiveTable copy).
	variables := Dictionary new.
	#('stackLimit') do:
		[:l| self addressForLabel: l].
	headerToMethodMap := Dictionary new.
	self initializeObjectMap
]

{ #category : #'initialize-release' }
CurrentImageCoInterpreterFacade >> initializeObjectMap [
	objectMap := IdentityDictionary new.
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
CurrentImageCoInterpreterFacade >> isIntegerObject: anOop [
	^objectMemory isIntegerObject: anOop
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> isIntegerValue: anInteger [
	^objectMemory isIntegerValue: anInteger
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> isNonIntegerObject: anOop [
	^objectMemory isNonIntegerObject: anOop
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> isQuickPrimitiveIndex: primNum [
	^coInterpreter isQuickPrimitiveIndex: primNum
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> isThreadedVM [
	^false
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> isYoung: anOop [
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
CurrentImageCoInterpreterFacade >> literalCountOfHeader: methodHeader [
	^(headerToMethodMap at: methodHeader) numLiterals
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> long32At: index put: value [
	^memory longAt: index + 1 put: value bigEndian: false
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> longAt: index [ 
	^memory unsignedLongAt: index + 1
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> longAt: index put: value [
	^memory longAt: index + 1 put: value bigEndian: false
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> longStoreBytecodeForHeader: methodHeaderOop [
	"Answer the relevant long store temp bytecode, which indicates it has a primitive error code."
	"234		11101010	i i i i i i i i	Store Temporary Variable #iiiiiiii"
	"129 		10000001 jjkkkkkk 	Store (Receiver Variable, Temporary Location, Illegal, Literal Variable) [jj] #kkkkkk"
	^(headerToMethodMap at: methodHeaderOop) usesAlternateBytecodeSet
		ifTrue: [234]
		ifFalse: [129]
]

{ #category : #labels }
CurrentImageCoInterpreterFacade >> lookupAddress: address [
	^(objectMap
		keyAtValue: address
		ifAbsent:
			[variables
				keyAtValue: address
				ifAbsent: [^nil]]) asString
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> memory [
	^memory
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> methodCacheAddress [
	^memory size * 3 / 4
]

{ #category : #testing }
CurrentImageCoInterpreterFacade >> methodHasCogMethod: aCompiledMethod [ 
	^false
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
CurrentImageCoInterpreterFacade >> nullHeaderForMachineCodeMethod [
	^objectMemory nullHeaderForMachineCodeMethod
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

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> objectRepresentationClass [
	^CogObjectRepresentationForSqueakV3
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
	^memory size / 2 + 1024
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
		[ClassArray]		-> [self oopForObject: Array].
		[CompactClasses]	-> [self oopForObject: Smalltalk compactClassesArray]
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
	^memory size
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> startPCOfMethod: anOop [
	^(objectMap keyAtValue: anOop) initialPC - 1
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> startPCOfMethodHeader: aSmallIntegerOop [
	^(headerToMethodMap at: aSmallIntegerOop) initialPC - 1
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

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> unalignedLongAt: index [ 
	^memory unsignedLongAt: index + 1
]

{ #category : #accessing }
CurrentImageCoInterpreterFacade >> youngStartAddress [
	^16r4E5E400
]
