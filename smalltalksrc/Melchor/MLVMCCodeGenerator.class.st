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

	vmClass ifNil: [^self].

	UIManager default
		displayProgress: 'Inlining bytecodes'
		from: 1 to: 2
		during: [:bar |
			self inlineDispatchesInMethodNamed: #interpret
				localizingVars: vmClass namesOfVariablesToLocalize.
			bar value: 1.
			removed := self removeMethodsReferingToGlobals: vmClass namesOfVariablesToLocalize
							except: #interpret.
			bar value: 2].

	"only prune when generating the interpreter itself"
	self pruneUnreachableMethods.

	self reportShouldNotBeRemoved: removed  varList: vmClass namesOfVariablesToLocalize
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
	vmClass isInterpreterClass ifTrue:
		[self maybePutPreambleFor: vmClass on: aStream].

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
MLVMCCodeGenerator >> kernelReturnTypes [
	
	^ kernelReturnTypes ifNil: [ kernelReturnTypes := self computeKernelReturnTypes ]
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
		and: [vmClass shouldGenerateTypedefFor: structClass]
]
