"
I am an abstract superclass for all classes in the VM that want to maintain a source timeStamp.
"
Class {
	#name : #VMClass,
	#superclass : #Object,
	#classVars : [
		'DefaultBase'
	],
	#pools : [
		'VMBasicConstants'
	],
	#classInstVars : [
		'timeStamp'
	],
	#category : #'VMMaker-Support'
}

{ #category : #translation }
VMClass class >> ancilliaryClasses [
	"Answer any extra classes to be included in the translation."
	^#()
]

{ #category : #translation }
VMClass class >> ancilliaryStructClasses [
	^#()
]

{ #category : #translation }
VMClass class >> apiExportHeaderName [
	"VM classesd that want to generate an api export header override this."
	^nil
]

{ #category : #translation }
VMClass class >> coreInterpreterClass [
	"While the interpreterClass/vmClass for translation may be
	 a subclass that holds a few primitives we want the actual
	 interpreter name at the head of the generated file."
	^((name endsWith: 'Primitives')
	   and: [name beginsWith: superclass name])
		ifTrue: [superclass]
		ifFalse: [self]
]

{ #category : #translation }
VMClass class >> declareC: arrayOfVariableNames as: aCType in: aCCodeGenerator [
	"Declare the variables in arrayOfVariableNames with the given type."

	arrayOfVariableNames
		do: [:varName | aCCodeGenerator var: varName type: aCType]
]

{ #category : #translation }
VMClass class >> declareCVarsIn: aCCodeGenerator [ 
	"Declare any additional variables and/or add type declarations for existing variables."
]

{ #category : #translation }
VMClass class >> declareInterpreterVersionIn: aCCodeGenerator defaultName: defaultName [
	NewspeakVM ifTrue:
		["Newspeak as of mid 2011 derives SystemScope systemName from the interpreterVersion
		  (via system attribute 1004) by copying up to but not including the last space, provided the
		  string ends with a digit.  So spaces must be eliminated from the Monitcello version string,
		  and we can't surround it with square brackets."
		(aCCodeGenerator shortMonticelloDescriptionForClass: self) last isDigit ifFalse:
			[self error: 'Newspeak expects interpreterVersion ends with a digit'].
		aCCodeGenerator
			var: #interpreterVersion
			declareC: 'const char *interpreterVersion = "Newspeak Virtual Machine ',
							((aCCodeGenerator shortMonticelloDescriptionForClass: self) copyReplaceAll: ' ' with: '_'),
							'"'.
		^self].
	
	aCCodeGenerator
		var: #interpreterVersion
		declareC: 'const char *interpreterVersion = "Croquet Closure ', defaultName, ' VM [',
					(aCCodeGenerator shortMonticelloDescriptionForClass: self),']"'.
]

{ #category : #debugger }
VMClass class >> defaultIntegerBaseInDebugger [
	"DefaultBase := 16."
	"DefaultBase := 10."
	DefaultBase isNil ifTrue: [DefaultBase := 16].
	^DefaultBase
]

{ #category : #translation }
VMClass class >> emitExportPragma [	
	"#pragma export -- seems only to have been for CodeWarrior on Mac."
	^false
]

{ #category : #'api version' }
VMClass class >> emitInterpreterProxyVersionOn: aStream [ 
	aStream
		nextPutAll: '#define VM_PROXY_MAJOR '; print: self vmProxyMajorVersion; cr;
		nextPutAll: '#define VM_PROXY_MINOR '; print: self vmProxyMinorVersion; cr; cr
]

{ #category : #translation }
VMClass class >> exportAPISelectors [
	^self exportAPISelectorsFor: self
]

{ #category : #translation }
VMClass class >> exportAPISelectorsFor: aClass [
	^(aClass selectors select:
		[:s| | m |
		((m := aClass compiledMethodAt: s) pragmaAt: #api) notNil or: [(m pragmaAt: #api:) notNil]]) asSet
]

{ #category : #translation }
VMClass class >> getVMMaker [
	^Notification new tag: #getVMMaker; signal
]

{ #category : #translation }
VMClass class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#sqInt
]

{ #category : #initialization }
VMClass class >> initializeMiscConstantsWith: optionsDictionary [
	"Falsify the `what type of VM is this?' flags that are defined in the various interp.h files,
	 or in the case of VMBIGENDIAN the various sqConfig.h files.
	 Subclass implementations need to include a super initializeMiscConstantsWith:."

	VMBIGENDIAN class. "Mention this for the benefit of CCodeGenerator>>emitCConstantsOn:"
	self isInterpreterClass ifTrue:
		[STACKVM := COGVM := COGMTVM := false].
	NewspeakVM := optionsDictionary at: #NewspeakVM ifAbsent: [false].
	MULTIPLEBYTECODESETS := optionsDictionary at: #MULTIPLEBYTECODESETS ifAbsent: [false].
	"N.B.  Not yet implemented."
	IMMUTABILITY := optionsDictionary at: #IMMUTABILITY ifAbsent: [false].

	"These for scripts etc... Usually they should get set by an Interpreter class's initializeMiscConstantsWith:"
	(optionsDictionary includesKey: #STACKVM) ifTrue:
		[STACKVM := optionsDictionary at: #STACKVM].
	(optionsDictionary includesKey: #COGVM) ifTrue:
		[COGVM := optionsDictionary at: #COGVM].
	(optionsDictionary includesKey: #COGMTVM) ifTrue:
		[COGMTVM := optionsDictionary at: #COGMTVM]
]

{ #category : #initialization }
VMClass class >> initializeWithOptions: optionsDictionary [
	"Initialize the receiver, typically initializing class variables. Initialize any class variables
	 whose names occur in optionsDictionary with the corresponding values there-in."
]

{ #category : #translation }
VMClass class >> isAccessor: aSelector [
	"Answer if aSelector is simply an accessor method for one of our fields.
	 Answer false by default.  VMStructType classes redefine this appropriately."
	^false
]

{ #category : #translation }
VMClass class >> isCogitClass [
	"The various Cogit classes override this."
	^false
]

{ #category : #translation }
VMClass class >> isInterpreterClass [
	"The various Interpreter classes override this."
	^false
]

{ #category : #translation }
VMClass class >> isPluginClass [
	"InterpreterPlugin class override this."
	^false
]

{ #category : #translation }
VMClass class >> isStructClass [
	"The various VMStructType classes override this."
	^false
]

{ #category : #translation }
VMClass class >> monticelloDescription [
	"Answer the Monticello version of the packlage containing the receiver.
	 This is a hook to allow subclasses to expand upon the default monticello description."
	^CCodeGenerator monticelloDescriptionFor: self
]

{ #category : #translation }
VMClass class >> noteCompilationOf: aSelector meta: isMeta [
	"note the recompiliation by resetting the timeStamp "
	timeStamp := Time totalSeconds.
	^super noteCompilationOf: aSelector meta: isMeta
]

{ #category : #'accessing class hierarchy' }
VMClass class >> objectMemoryClass [
	"Default for all-in-one VMs where the interpreter inherits from the object memory."
	^nil
]

{ #category : #utilities }
VMClass class >> openCogMultiWindowBrowser [
	"Answer a new multi-window browser on the ObjectMemory classes, the Cog Interpreter classes, and the main JIT classes"
	| b |
	b := Browser open.
	#(	ObjectMemory NewObjectMemory NewCoObjectMemory
		InterpreterPrimitives StackInterpreter StackInterpreterPrimitives CoInterpreter CoInterpreterPrimitives CoInterpreterMT
		Cogit SimpleStackBasedCogit StackToRegisterMappingCogit
		VMStructType VMMaker CCodeGenerator TMethod)
		do: [:className|
			(Smalltalk classNamed: className) ifNotNil:
				[:class| b selectCategoryForClass: class; selectClass: class]]
		separatedBy:
			[b multiWindowState addNewWindow].
	b multiWindowState selectWindowIndex: 1
]

{ #category : #utilities }
VMClass class >> openObjectMemoriesInterpretersBrowser [
	"Answer a new multi-window browser on the ObjectMemory classes and the Cog Interpreter classes"
	| b |
	b := Browser open.
	#(	ObjectMemory NewObjectMemory NewCoObjectMemory
		InterpreterPrimitives StackInterpreter StackInterpreterPrimitives
		CoInterpreter CoInterpreterPrimitives CoInterpreterMT)
		do: [:className|
			(Smalltalk classNamed: className) ifNotNil:
				[:class| b selectCategoryForClass: class; selectClass: class]]
		separatedBy:
			[b multiWindowState addNewWindow].
	b multiWindowState selectWindowIndex: 1
]

{ #category : #translation }
VMClass class >> prepareToBeAddedToCodeGenerator: aCCodeGenerator [ 
	"Hook for translation.  e.g. allows a subclass to override its
	 superclass's methods by deleting them before it adds its own."
]

{ #category : #utilities }
VMClass class >> removeThreadedSubSystem [
	"VMClass removeQwaqPlugins.
	 VMClass removeThreadedSubSystem"
	"For releasing/merging OSCog"
	SystemChangeNotifier uniqueInstance doSilently:
		[CogVMSimulator
			removeSelector: #isThreadedVM;
			removeSelector: #initializeThreadSupport;
			removeSelector: #initialEnterSmalltalkExecutive;
			removeSelector: #ensureMultiThreadingOverridesAreUpToDate.
		(CogVMSimulator organization listAtCategoryNamed: #'multi-threading simulation switch') do:
			[:s| CogVMSimulator removeSelector: s].
		CoInterpreterPrimitives
			subclass: #CogVMSimulator
			instanceVariableNames: CogVMSimulator instanceVariablesString
			classVariableNames: CogVMSimulator classVariablesString
			poolDictionaries: CogVMSimulator sharedPoolsString
			category: CogVMSimulator category.
		SystemOrganization removeSystemCategory: #'VMMaker-Multithreading'.
		self class removeSelector: thisContext selector].
	(Smalltalk classNamed: #MCWorkingCopy) ifNotNil:
		[:mcwc|
		(mcwc forPackage: (MCPackage named: 'VMMaker')) modified: true]
]

{ #category : #translation }
VMClass class >> requiredMethodNames [
	"Answer a list of method names that should be retained for export or other
	 support reasons.  These are typically entry-points that unless explicitly noted
	 will be deleted by the code generator since it will assume these are not used."
	^#()
]

{ #category : #translation }
VMClass class >> shouldGenerateTypedefFor: aStructClass [
	"Hack to work-around multiple definitions.  Sometimes a type has been defined in an include."
	^true
]

{ #category : #translation }
VMClass class >> specialValueForConstant: constantName default: defaultValue [
	^nil
]

{ #category : #translation }
VMClass class >> timeStamp [
	^timeStamp ifNil:[0]
]

{ #category : #translation }
VMClass class >> touch [
	"Reset the timeStamp"
	"Smalltalk allClasses select:
		[:c| (c category includesSubString: 'VMMaker-JIT') ifTrue: [c touch]]"
	"InterpreterPlugin withAllSubclassesDo:[:pl| pl touch]"
	timeStamp := Time totalSeconds
]

{ #category : #translation }
VMClass class >> translationClass [
	"Return the class to use as the interpreterCLass when translating.  For the all-in-one
	 VMs that inherit from ObjectMemory this is the receiver.  But for the separate VMs
	 where most primitives are in a subclass it will be the subclass with the primitives."
	^self
]

{ #category : #translation }
VMClass class >> typeForSelf [
	"Answer the type to give self if appropriate, or nil if not."
	^nil
]

{ #category : #translation }
VMClass class >> writeVMHeaderTo: aStream bytesPerWord: bytesPerWord [
	"Generate the contents of interp.h on aStream.  Specific Interpreter subclasses
	 override to add more stuff."
	aStream
		nextPutAll: '#define VM_PROXY_MAJOR '; print: self vmProxyMajorVersion; cr;
		nextPutAll: '#define VM_PROXY_MINOR '; print: self vmProxyMinorVersion; cr;
		cr;
		nextPutAll: '#define SQ_VI_BYTES_PER_WORD '; print: bytesPerWord; cr;
		cr.
	((VMBasicConstants classPool associations select: [:a| a key beginsWith: 'PrimErr'])
		asSortedCollection: [:a1 :a2| a1 value <= a2 value])
		do: [:a|
			aStream nextPutAll: '#define '; nextPutAll: a key; space; print: a value; cr].
	aStream cr
]

{ #category : #'translation support' }
VMClass >> addressOf: anObject [
	<doNotGenerate>
	"Translates into &anObject in C."
	^anObject
]

{ #category : #'C library simulation' }
VMClass >> alloca: size [
	"Simulation of alloca(3)"
	<doNotGenerate>
	^ByteArray new: size
]

{ #category : #'C library simulation' }
VMClass >> asString: stringIndex size: stringSize [
	"stringIndex is an address in the heap.  Create a String of the requested length
	form the bytes in the heap starting at stringIndex."
	<doNotGenerate>
	^self st: (ByteString new: stringSize) rn: stringIndex cpy: stringSize
]

{ #category : #'translation support' }
VMClass >> asmLabel: aBoolean [
	"For translation only; noop when running in Smalltalk."
]

{ #category : #'debug support' }
VMClass >> assert: aBooleanExpression l: linenum [
	<doNotGenerate>
	^self assert: aBooleanExpression
]

{ #category : #'debug support' }
VMClass >> asserta: aBooleanExpression [
	<doNotGenerate>
	| result |
	(result := aBooleanExpression value) ifFalse:
		[AssertionFailure signal: 'Assertion failed'].
	^result
]

{ #category : #'debug support' }
VMClass >> asserta: aBooleanExpression l: linenum [
	<doNotGenerate>
	^self asserta: aBooleanExpression
]

{ #category : #accessing }
VMClass >> bytesPerOop [
	^BytesPerOop
]

{ #category : #'translation support' }
VMClass >> cCode: codeString [
	"Support for Smalltalk-to-C translation.
	 For translation only; noop when running in Smalltalk.
	 The argument is output literally when generating C code."
]

{ #category : #'translation support' }
VMClass >> cCode: codeStringOrBlock inSmalltalk: aBlock [
	"Support for Smalltalk-to-C translation. The first argument is output when generating C code.
	  But if this code is being simulated in Smalltalk, answer the result of evaluating the given block.
	  If the first argument is a string it is output literally, and if it is a block it is translated.
	  N.B.  If the first argument is a block then replacement happens at TMethod creation time so the use
	  of cCode:inSmalltalk: with a block first argument does not prevent inlining and is hence preferred."

	^aBlock value
]

{ #category : #'translation support' }
VMClass >> cPreprocessorDirective: codeString [
	"For translation only; noop when running in Smalltalk."
]

{ #category : #'translation support' }
VMClass >> cppIf: conditionBlockOrValue ifTrue: trueExpressionOrBlock [
	"When translated, produces #if (condition) #else #endif CPP directives.
	 Example usage:

		self cppIf: IMMUTABILITY
			ifTrue: [(self internalIsImmutable: obj) ifTrue:
						[^self primitiveFailFor: PrimErrNoModification]]"
	^self cppIf: conditionBlockOrValue ifTrue: trueExpressionOrBlock ifFalse: nil
]

{ #category : #'translation support' }
VMClass >> cppIf: conditionBlockOrSymbolValue ifTrue: trueExpressionOrBlock ifFalse: falseExpressionOrBlockOrNil [
	"When translated, produces #if (condition) #else #endif CPP directives.
	 Example usage:

		self cppIf: [BytesPerWord = 8]
			ifTrue: [self doSomethingFor64Bit]
			ifFalse: [self doSomethingFor32Bit]
		self cppIf: BytesPerWord = 8
			ifTrue: [self doSomethingFor64Bit]
			ifFalse: [self doSomethingFor32Bit]
		self cppIf: #A_GLOBAL
			ifTrue: [self doSomethingFor64Bit]
			ifFalse: [self doSomethingFor32Bit]"
	^(conditionBlockOrSymbolValue value
		ifNil: [false]
		ifNotNil: [:value|
			value isInteger
				ifTrue: [value ~= 0]
				ifFalse:
					[value isSymbol
						ifTrue: [(self class bindingOf: value)
									ifNil: [false]
									ifNotNil: [:binding| binding value]]
						ifFalse: [value]]])
		ifTrue: trueExpressionOrBlock
		ifFalse: falseExpressionOrBlockOrNil
]

{ #category : #'simulation support' }
VMClass >> doOrDefer: aBlock [
	<doNotGenerate>
	"Either evaluate aBlock immediately if in the uiProcess or defer aBlock as a UI message"
	Processor activeProcess == Project uiProcess
		ifTrue: [aBlock value]
		ifFalse: [WorldState addDeferredUIMessage: aBlock]
]

{ #category : #'memory access' }
VMClass >> fetchSingleFloatAtPointer: pointer into: aFloat [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and aFloat is a 32-bit single precision float."
	<doNotGenerate>

	^self fetchSingleFloatAt: pointer into: aFloat
]

{ #category : #testing }
VMClass >> isCurrentImageFacade [
	^false
]

{ #category : #'plugin support' }
VMClass >> isInterpreterProxy [
	<doNotGenerate>
	"Return false since I am a real Interpreter simulation"
	^false
]

{ #category : #'memory access' }
VMClass >> longAtPointer: pointer [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and the result is the width of a machine word."
	<doNotGenerate>

	^self longAt: pointer
]

{ #category : #'memory access' }
VMClass >> longAtPointer: pointer put: longValue [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and longValue is the width of a machine word."
	<doNotGenerate>

	^self longAt: pointer put: longValue
]

{ #category : #'simulation support' }
VMClass >> majorVersion [
	"This is implemented in sqVirtualMachine.c, so this form is for simulation only."
	<doNotGenerate>
	^self class vmProxyMajorVersion
]

{ #category : #'C library simulation' }
VMClass >> mem: aString cp: bString y: n [
	<doNotGenerate>
	"implementation of memcpy(3)"
	aString isString
		ifTrue:
			[1 to: n do:
				[:i| | v |
				v := bString isString
						ifTrue: [bString at: i]
						ifFalse: [Character value: (self byteAt: bString + i - 1)].
				aString at: i put: v]]
		ifFalse:
			[1 to: n do:
				[:i| | v |
				v := bString isString
						ifTrue: [(bString at: i) asInteger]
						ifFalse: [self byteAt: bString + i - 1].
				self byteAt: aString + i - 1 put: v]].
	^aString
]

{ #category : #'C library simulation' }
VMClass >> mem: destAddress mo: sourceAddress ve: bytes [
	<doNotGenerate>
	| dst src  |
	dst := destAddress asInteger.
	src := sourceAddress asInteger.
	"Emulate the c library memmove function"
	self assert: bytes \\ 4 = 0.
	destAddress > sourceAddress
		ifTrue:
			[bytes - 4 to: 0 by: -4 do:
				[:i| self longAt: dst + i put: (self longAt: src + i)]]
		ifFalse:
			[0 to: bytes - 4 by: 4 do:
				[:i| self longAt: dst + i put: (self longAt: src + i)]]
]

{ #category : #'simulation support' }
VMClass >> minorVersion [
	"This is implemented in sqVirtualMachine.c, so this form is for simulation only."
	<doNotGenerate>
	^self class vmProxyMinorVersion
]

{ #category : #'translation support' }
VMClass >> numElementsIn: anArray [
	<cmacro: '(anArray) (sizeof(anArray)/sizeof(anArray[0]))'>
	^anArray size
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isGreaterThan: otherOop [
	"Compare two oop values, treating them as object memory locations.
	Use #cCoerce:to: to ensure comparison of unsigned magnitudes. This
	method will be inlined during C translation."
	<inline: true>
	^(self cCoerce: anOop to: #usqInt)
		> (self cCoerce: otherOop to: #usqInt)
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isGreaterThan: baseOop andLessThan: limitOop [
	"Compare two oop values, treating them as object memory locations.
	Use #cCoerce:to: to ensure comparison of unsigned magnitudes. This
	method will be inlined during C translation."
	<inline: true>
	^(self cCoerce: anOop to: #usqInt) > (self cCoerce: baseOop to: #usqInt)
	  and: [(self cCoerce: anOop to: #usqInt) < (self cCoerce: limitOop to: #usqInt)]
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isGreaterThanOrEqualTo: otherOop [
	"Compare two oop values, treating them as object memory locations.
	Use #cCoerce:to: to ensure comparison of unsigned magnitudes. This
	method will be inlined during C translation."
	<inline: true>
	^(self cCoerce: anOop to: #usqInt)
		>= (self cCoerce: otherOop to: #usqInt)
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isLessThan: otherOop [
	"Compare two oop values, treating them as object memory locations.
	Use #cCoerce:to: to ensure comparison of unsigned magnitudes. This
	method will be inlined during C translation."
	<inline: true>
	^(self cCoerce: anOop to: #usqInt) < (self cCoerce: otherOop to: #usqInt)
]

{ #category : #'oop comparison' }
VMClass >> oop: anOop isLessThanOrEqualTo: otherOop [
	"Compare two oop values, treating them as object memory locations.
	Use #cCoerce:to: to ensure comparison of unsigned magnitudes. This
	method will be inlined during C translation."
	<inline: true>
	^(self cCoerce: anOop to: #usqInt)
		<= (self cCoerce: otherOop to: #usqInt)
]

{ #category : #'memory access' }
VMClass >> oopForPointer: pointerOrSurrogate [
	"This gets implemented by Macros in C, where its types will also be checked.
	 oop is the width of a machine word, and pointer is a raw address."
	<doNotGenerate>
	^pointerOrSurrogate asInteger
]

{ #category : #'translation support' }
VMClass >> pointerForOop: oop [
	"This gets implemented by Macros in C, where its types will also be checked.
	 oop is the width of a machine word, and pointer is a raw address."
	<doNotGenerate>

	^oop
]

{ #category : #'simulation support' }
VMClass >> promptHex: string [
	<doNotGenerate>
	| s |
	s := UIManager default request: string, ' (hex)'.
	^s notEmpty ifTrue:
		[(s includes: $r)
			ifTrue:
				[Number readFrom: s readStream]
			ifFalse:
				[(#('0x' '-0x') detect: [:prefix| s beginsWith: prefix] ifNone: []) ifNotNil:
					[:prefix|
					s := s allButFirst: prefix size.
					prefix first = $- ifTrue: [s := '-', s]].
				Integer readFrom: s readStream base: 16]]
]

{ #category : #arithmetic }
VMClass >> safe: signedInteger mod: positiveModulus [
	<inline>
	| remainder |
	^(remainder := signedInteger \\ positiveModulus) < 0
		ifTrue: [remainder + positiveModulus]
		ifFalse: [remainder]
]

{ #category : #'translation support' }
VMClass >> sharedCodeNamed: label inCase: caseNumber [
	"For translation only; noop when running in Smalltalk."
]

{ #category : #'translation support' }
VMClass >> sizeof: objectSymbolOrClass [
	<doNotGenerate>
	| index |
	objectSymbolOrClass isInteger ifTrue:
		[self flag: #Dan.
		 ^BytesPerWord].
	objectSymbolOrClass isSymbol ifTrue:
		[(objectSymbolOrClass last == $*
		 or: [#long == objectSymbolOrClass
		 or: [#'unsigned long' == objectSymbolOrClass]]) ifTrue:
			[^BytesPerWord].
		index := #(	#sqLong #usqLong #double
					#int #'unsigned int' #float
					#short #'unsigned short'
					#char #'unsigned char' #'signed char')
						indexOf: objectSymbolOrClass
						ifAbsent:
							[objectSymbolOrClass = #sqInt ifTrue: [^BytesPerOop].
							 self error: 'unrecognized C type name'].
		^#(8 8 8
			4 4 4
			2 2
			1 1 1) at: index].
	^(objectSymbolOrClass isBehavior
		ifTrue: [objectSymbolOrClass]
		ifFalse: [objectSymbolOrClass class])
			alignedByteSizeOf: objectSymbolOrClass
			forClient: self
]

{ #category : #'simulation support' }
VMClass >> sqLowLevelMFence [
	<doNotGenerate>
	"A no-op in the simulator"
]

{ #category : #'C library simulation' }
VMClass >> st: aString rn: bString cpy: n [
	<doNotGenerate>
	"implementation of strncpy(3)"
	aString isString
		ifTrue:
			[1 to: n do:
				[:i| | v |
				v := bString isString
						ifTrue: [bString at: i]
						ifFalse: [Character value: (self byteAt: bString + i - 1)].
				aString at: i put: v.
				v asInteger = 0 ifTrue: [^aString]]]
		ifFalse:
			[1 to: n do:
				[:i| | v |
				v := bString isString
						ifTrue: [(bString at: i) asInteger]
						ifFalse: [self byteAt: bString + i - 1].
				self byteAt: aString + i - 1 put: v.
				v = 0 ifTrue: [^aString]]].
	^aString
]

{ #category : #'memory access' }
VMClass >> storeFloatAtPointer: pointer from: aFloat [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and aFloat is a 64-bit double precision float."
	<doNotGenerate>

	^self storeFloatAt: pointer from: aFloat
]

{ #category : #'memory access' }
VMClass >> storeSingleFloatAtPointer: pointer from: aFloat [
	"This gets implemented by Macros in C, where its types will also be checked.
	 pointer is a raw address, and aFloat is a 32-bit single precision float."
	<doNotGenerate>

	^self storeSingleFloatAt: pointer from: aFloat
]

{ #category : #'C library simulation' }
VMClass >> str: aString n: bString cmp: n [
	<doNotGenerate>
	"implementation of strncmp(3)"
	bString isString ifTrue:
		[^(aString first: (n min: aString size)) ~= (bString first: (n min: bString size))].
	1 to: n do:
		[:i| | v |
		v := (aString at: i) asInteger - (self byteAt: bString + i - 1).
		v ~= 0 ifTrue: [^v]].
	^0
]

{ #category : #'C library simulation' }
VMClass >> strlen: aCString [
	"Simulate strlen(3)"
	<doNotGenerate>
	| len |
	aCString isString ifTrue:
		[^aCString size].
	len := 0.
	[(self byteAt: aCString + len) = 0 ifTrue: [^len].
	len := len + 1] repeat
]
