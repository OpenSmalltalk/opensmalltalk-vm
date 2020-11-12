Class {
	#name : #MLVMCCodeGenerator,
	#superclass : #CCodeGenerator,
	#category : #Melchor
}

{ #category : #'spur primitive compilation' }
MLVMCCodeGenerator >> accessorDepthCalculator [

	^ MLAccessorDepthCalculator forCodeGenerator: self 
]

{ #category : #'C code generator' }
MLVMCCodeGenerator >> computeKernelReturnTypes [
	| dictionary |
	dictionary := Dictionary newFromPairs:
		#(oopAt: #sqInt oopAt:put: #sqInt
			oopAtPointer: #sqInt oopAtPointer:put: #sqInt
		 byteAt: #sqInt byteAt:put: #sqInt
			byteAtPointer: #sqInt byteAtPointer:put: #sqInt
		 shortAt: #sqInt shortAt:put: #sqInt
			shortAtPointer: #sqInt shortAtPointer:put: #sqInt
		 intAt: #sqInt intAt:put: #sqInt
			intAtPointer: #sqInt intAtPointer:put: #sqInt
		 longAt: #sqInt longAt:put: #sqInt
			longAtPointer: #sqInt longAtPointer:put: #sqInt
				long32At: #int long32At:put: #int
					unalignedLongAt: #sqInt unalignedLongAt:put: #sqInt
						unalignedLong32At: #int unalignedLong32At:put: #int

		 long64At: #sqLong long64At:put: #sqLong
		 long64AtPointer: #sqLong long64AtPointer:put: #sqLong
	
		singleFloatAtPointer: #float singleFloatAtPointerPut: #float		
		floatAtPointer: #double floatAtPointerPut: #double
				
		 fetchFloatAt:into: #void storeFloatAt:from: #void
			fetchFloatAtPointer:into: #void storeFloatAtPointer:from: #void
		 fetchSingleFloatAt:into: #void storeSingleFloatAt:from: #void
			fetchSingleFloatAtPointer:into: #void storeSingleFloatAtPointer:from: #void

		 pointerForOop: #'char *' oopForPointer: #sqInt
		 baseHeaderSize #sqInt wordSize #sqInt bytesPerOop #sqInt).
	self vmmakerConfiguration bytesPerWord = 8 ifTrue:
		[#(long32At: long32At:put: unalignedLong32At: unalignedLong32At:put:) do:
			[:accessor|
			dictionary at: accessor put: #int]].
	^dictionary
]

{ #category : #'C code generator' }
MLVMCCodeGenerator >> constants [

	| unused |
	"and VMBasicConstants mostBasicConstantNames *must* be taken from interp.h"
	unused := self unusedConstants.
	^ super constants keys reject: [ :any | unused includes: any ]
]

{ #category : #'C code generator' }
MLVMCCodeGenerator >> defaultType [
	
	^ #sqInt
]

{ #category : #'compile-time-options' }
MLVMCCodeGenerator >> defineAtCompileTime: aString [ 
	"Define if the code generator should define the option at compile time or at generation time.
	If true, the decision of the option will be delayed to compilation time.
	Otherwise, do it at transpilation time, 
	 - the code with the option is generated if the value of the option is true
	 - if not true or unset, do not generate"
	(super defineAtCompileTime: aString)
		ifTrue: [ ^ true ].
		
	^ (self vmClass ifNil: [self constantClass]) defineAtCompileTime: aString
]

{ #category : #inlining }
MLVMCCodeGenerator >> doInlining: inlineFlagOrSymbol [
	"Inline the bodies of all methods that are suitable for inlining."
	"Modified slightly for the core VM translator, since the first level of inlining for the interpret loop must be performed in order that the instruction implementations can easily discover their addresses. Remember to inline the bytecode routines as well"

	| removed |
	inlineFlagOrSymbol isSymbol ifTrue:
		[self inlineDispatchesInMethodNamed: #interpret localizingVars: #().	
		 self doBasicInlining: inlineFlagOrSymbol.
		 self pruneUnreachableMethods.
		 ^self].

	inlineFlagOrSymbol ifFalse:
		[self inlineDispatchesInMethodNamed: #interpret localizingVars: #().	
		self pruneUnreachableMethods.
		^self].

	self doBasicInlining: inlineFlagOrSymbol.

	self vmClass ifNil: [^self].

	UIManager default
		displayProgress: 'Inlining bytecodes'
		from: 1 to: 2
		during: [:bar |
			self inlineDispatchesInMethodNamed: #interpret
				localizingVars: self vmClass namesOfVariablesToLocalize.
			bar value: 1.
			removed := self removeMethodsReferingToGlobals: self vmClass namesOfVariablesToLocalize
							except: #interpret.
			bar value: 2].

	"only prune when generating the interpreter itself"
	self pruneUnreachableMethods.

	self reportShouldNotBeRemoved: removed  varList: self vmClass namesOfVariablesToLocalize
]

{ #category : #'C code generator' }
MLVMCCodeGenerator >> emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag [
	"Emit C code for all methods in the code base onto the given stream. All inlined method calls should already have been expanded."

	super emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag.
	self emitExportsOn: aStream
]

{ #category : #'C code generator' }
MLVMCCodeGenerator >> emitCHeaderOn: aStream [
	
	self addHeaderFileFirst: '"sq.h"'.
	super emitCHeaderOn: aStream.
	self vmClass isInterpreterClass ifTrue:
		[self maybePutPreambleFor: self vmClass on: aStream].

	aStream cr
]

{ #category : #'C code generator' }
MLVMCCodeGenerator >> emitExportNamed: exportsNamePrefix forMethod: method pluginName: pluginName on: aStream [

	| excludeDepth primName |
	"Don't include the depth in the vm's named primitives if the vm is non-Spur."
	excludeDepth := exportsNamePrefix = 'vm' and: [ 
		                pluginName isEmpty and: [ self shouldExcludeDepth ] ].

	primName := self cFunctionNameFor: method selector.
	aStream
		tab;
		nextPutAll: '{(void*)_m, "';
		nextPutAll: primName.
	excludeDepth ifFalse: [ 
		(self accessorDepthCalculator accessorDepthForSelector:
			 primName asSymbol) ifNotNil: [ :depth | "store the accessor depth in a hidden byte immediately after the primName"
			self assert: depth < 128.
			aStream
				nextPutAll: '\000\';
				nextPutAll: ((depth bitAnd: 255) printStringBase: 8 nDigits: 3) ] ].
	aStream
		nextPutAll: '", (void*)';
		nextPutAll: primName;
		nextPutAll: '},';
		cr
]

{ #category : #'C code generator' }
MLVMCCodeGenerator >> harmonizeReturnTypesIn: aSetOfTypes [
	"Eliminate signed/unsigned conflicts in aSetOfTypes. Non-negative integers can be either
	 signed or unsigned. Ignore them unless there are no types, in which case default to sqInt."
	| constantIntegers sqs usqs |
	constantIntegers := aSetOfTypes select: [:element| element isInteger].
	aSetOfTypes removeAll: constantIntegers.
	"N.B. Because of LP64 vs LLP64 issues do *not* rename #long to #sqInt or #'unsigned long' to #usqInt"
	#(char short int #'long long' #'unsigned char' #'unsigned short' #'unsigned int' #'unsigned long long')
		with: #(sqInt sqInt sqInt sqLong usqInt usqInt usqInt usqLong)
		do: [:type :replacement|
			(aSetOfTypes includes: type) ifTrue:
				[aSetOfTypes remove: type; add: replacement]].
	sqs := aSetOfTypes select: [:t| t beginsWith: 'sq'].
	usqs := aSetOfTypes select: [:t| t beginsWith: 'usq'].
	^(sqs size + usqs size = aSetOfTypes size
	   and: [sqs notEmpty
	   and: [sqs allSatisfy: [:t| usqs includes: 'u', t]]])
		ifTrue: [sqs]
		ifFalse: [(aSetOfTypes isEmpty and: [constantIntegers notEmpty])
					ifTrue: [Set with: self defaultType]
					ifFalse: [aSetOfTypes]]
]

{ #category : #'C code generator' }
MLVMCCodeGenerator >> kernelReturnTypes [
	
	^ kernelReturnTypes ifNil: [ kernelReturnTypes := self computeKernelReturnTypes ]
]

{ #category : #translating }
MLVMCCodeGenerator >> mostBasicConstantSelectors [

	^ self constantClass mostBasicConstantSelectors
]

{ #category : #'C code generator' }
MLVMCCodeGenerator >> nilTranslation [
	"Defined in some header file as a macro?"
	^ 'null'
]

{ #category : #'C code generator' }
MLVMCCodeGenerator >> optionIsTrue: pragma in: aClass [
	"Answer whether an option: or notOption: pragma is true in the context of aClass.
	 The argument to the option: pragma is interpreted as either a Cogit class name
	 or a class variable name or a variable name in VMBasicConstants."
	| key constantClass |
	key := pragma argumentAt: 1.

	(super optionIsTrue: pragma in: aClass) ifTrue:
		[^true].

	"If the option is the name of a subclass of Cogit, include it if it inherits from the Cogit class."
	(self environment classNamed: key) ifNotNil:
		[:optionClass|
		 aClass cogitClass ifNotNil:
			[:cogitClass|
			 (cogitClass includesBehavior: optionClass) ifTrue:
				[ ^ true]].
		 aClass objectMemoryClass ifNotNil:
			[:objectMemoryClass|
			 (objectMemoryClass includesBehavior: optionClass) ifTrue:
				[^true]]].
	"Lookup options in options, class variables of the defining class, VMBasicConstants, the interpreterClass and the objectMemoryClass"
	{aClass initializationOptions.
	  aClass.
	  self constantClass.
	  aClass interpreterClass.
	  aClass objectMemoryClass} do:
		[:scopeOrNil|
		 scopeOrNil ifNotNil:
			[:scope|
			 (scope bindingOf: key) ifNotNil:
				[:binding|
				binding value ~~ false ifTrue: [^true]]]].
	^false
]

{ #category : #'C code generator' }
MLVMCCodeGenerator >> returnTypeForSend: sendNode in: aTMethod boundTo: aCalledMethod typeIfNil: typeIfNil [
	"Answer the return type for a send.  Unbound sends default to typeIfNil.
	 Methods with types as yet unknown have a type determined either by the
	 kernelReturnTypes or by the common definitions in the superclass.

	 The inferred type should match as closely as possible the C type of
	 generated expessions so that inlining would not change the expression"

	^ self kernelReturnTypes
		at: sendNode selector
		ifAbsent: [
			super
				returnTypeForSend: sendNode
				in: aTMethod
				boundTo: aCalledMethod
				typeIfNil: typeIfNil ]
]

{ #category : #'C code generator' }
MLVMCCodeGenerator >> shouldGenerateStruct: structClass [

	^ (super shouldGenerateStruct: structClass)
		and: [self vmClass shouldGenerateTypedefFor: structClass]
]
