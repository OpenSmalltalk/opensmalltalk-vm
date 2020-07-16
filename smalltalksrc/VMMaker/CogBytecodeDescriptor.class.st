"
I am an entry in the Cogit's dispatch table for bytecodes.  I hold the routine to call to generate code for the partcular bytecode I represent and the number of bytes the bytecode has.  For eliminating temps in frameless blocks I maintain a stack delta for bytecodes that are valid in a frameless block.  The order of my instance variables is chosen for compact struct packing.
"
Class {
	#name : #CogBytecodeDescriptor,
	#superclass : #VMStructType,
	#instVars : [
		'generator',
		'spanFunction',
		'needsFrameFunction',
		'stackDelta',
		'opcode',
		'numBytes',
		'isBranchTrue',
		'isBranchFalse',
		'isReturn',
		'isBlockCreation',
		'isMapped',
		'isMappedInBlock',
		'isExtension',
		'isInstVarRef',
		'is1ByteInstVarStore',
		'hasUnsafeJump'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
CogBytecodeDescriptor class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a BytecodeDescriptor struct."
	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
							['generator']			->	[#('sqInt (*' ')(void)')].
							['spanFunction']			->	[#('sqInt NoDbgRegParms (*' ')(struct _BytecodeDescriptor *,sqInt,sqInt,sqInt)')].
							['needsFrameFunction']	->	[#('sqInt NoDbgRegParms (*' ')(sqInt)')].
							['numBytes']			->	['unsigned char'].
							['stackDelta']			->	['signed char'].
							['opcode']				->	['unsigned char'] }
						otherwise: [#('unsigned' ' : 1')])]
]

{ #category : #translation }
CogBytecodeDescriptor class >> structTypeName [
	^self name allButFirst: 3 "Drop initial Cog"
]

{ #category : #accessing }
CogBytecodeDescriptor >> generator [
	"Answer the value of generator"

	^ generator
]

{ #category : #accessing }
CogBytecodeDescriptor >> generator: anObject [
	"Set the value of generator"

	^generator := anObject
]

{ #category : #accessing }
CogBytecodeDescriptor >> hasUnsafeJump [

	^ hasUnsafeJump
]

{ #category : #accessing }
CogBytecodeDescriptor >> hasUnsafeJump: anObject [

	^hasUnsafeJump := anObject
]

{ #category : #accessing }
CogBytecodeDescriptor >> is1ByteInstVarStore [
	"Answer the value of is1ByteInstVarStore"

	^ is1ByteInstVarStore
]

{ #category : #accessing }
CogBytecodeDescriptor >> is1ByteInstVarStore: anObject [
	"Set the value of is1ByteInstVarStore"

	^is1ByteInstVarStore := anObject
]

{ #category : #accessing }
CogBytecodeDescriptor >> isBlockCreation [
	"Answer the value of isBlockCreation"

	^isBlockCreation
]

{ #category : #accessing }
CogBytecodeDescriptor >> isBlockCreation: anObject [
	"Set the value of isBlockCreation"

	^isBlockCreation := anObject
]

{ #category : #accessing }
CogBytecodeDescriptor >> isBranch [
	^self spanFunction notNil and: [self isBlockCreation not]
]

{ #category : #accessing }
CogBytecodeDescriptor >> isBranchFalse [
	"Answer the value of isBranchFalse"

	^ isBranchFalse
]

{ #category : #accessing }
CogBytecodeDescriptor >> isBranchFalse: anObject [
	"Set the value of isBranchFalse"

	^isBranchFalse := anObject
]

{ #category : #accessing }
CogBytecodeDescriptor >> isBranchTrue [
	"Answer the value of isBranchTrue"

	^ isBranchTrue
]

{ #category : #accessing }
CogBytecodeDescriptor >> isBranchTrue: anObject [
	"Set the value of isBranchTrue"

	^isBranchTrue := anObject
]

{ #category : #accessing }
CogBytecodeDescriptor >> isCallPrimitive [

	^generator == #genCallPrimitiveBytecode
]

{ #category : #accessing }
CogBytecodeDescriptor >> isConditionalBranch [
	<inline: true>
	^isBranchTrue or: [isBranchFalse]
]

{ #category : #accessing }
CogBytecodeDescriptor >> isExtension [
	"Answer the value of isExtension"

	^ isExtension
]

{ #category : #accessing }
CogBytecodeDescriptor >> isExtension: anObject [
	"Set the value of isExtension"

	^isExtension := anObject
]

{ #category : #accessing }
CogBytecodeDescriptor >> isInstVarRef [
	"Answer the value of isInstVarRef"

	^ isInstVarRef
]

{ #category : #accessing }
CogBytecodeDescriptor >> isInstVarRef: anObject [
	"Set the value of isInstVarRef"

	^isInstVarRef := anObject
]

{ #category : #accessing }
CogBytecodeDescriptor >> isMapped [
	"Answer the value of isMapped.  Note we send value because this may be the binding for #IMMUTABILITY"
	^isMapped value
]

{ #category : #accessing }
CogBytecodeDescriptor >> isMapped: anObject [
	"Set the value of isMapped"

	^isMapped := anObject
]

{ #category : #accessing }
CogBytecodeDescriptor >> isMappedInBlock [
	"Answer the value of isMappedInBlock"

	^isMappedInBlock
]

{ #category : #accessing }
CogBytecodeDescriptor >> isMappedInBlock: anObject [
	"Set the value of isMappedInBlock"

	^isMappedInBlock := anObject
]

{ #category : #accessing }
CogBytecodeDescriptor >> isReturn [
	"Answer the value of isReturn"

	^ isReturn
]

{ #category : #accessing }
CogBytecodeDescriptor >> isReturn: anObject [
	"Set the value of isReturn"

	^isReturn := anObject
]

{ #category : #accessing }
CogBytecodeDescriptor >> isUnconditionalBranch [
	<inline: true>
	^self isBranch and: [(isBranchTrue or: [isBranchFalse]) not]
]

{ #category : #accessing }
CogBytecodeDescriptor >> needsFrameFunction [
	"Answer the value of needsFrameFunction"

	^needsFrameFunction
]

{ #category : #accessing }
CogBytecodeDescriptor >> needsFrameFunction: aSymbol [
	"Set the value of needsFrameFunction"

	^needsFrameFunction := aSymbol
]

{ #category : #accessing }
CogBytecodeDescriptor >> numBytes [
	"Answer the value of numBytes"

	^ numBytes
]

{ #category : #accessing }
CogBytecodeDescriptor >> numBytes: anObject [
	"Set the value of numBytes"

	^numBytes := anObject
]

{ #category : #accessing }
CogBytecodeDescriptor >> opcode [
	"Answer the value of opcode"

	^ opcode
]

{ #category : #accessing }
CogBytecodeDescriptor >> opcode: anObject [
	"Set the value of opcode"

	^opcode := anObject
]

{ #category : #translation }
CogBytecodeDescriptor >> printCInitializerOn: aStream in: aCCodeGenerator [
	<doNotGenerate>
	| first |
	first := true.
	aStream nextPut: ${; space.
	self class instVarNamesAndTypesForTranslationDo:
		[:ivn :type| | value |
		first ifTrue: [first := false] ifFalse: [aStream nextPut: $,; space].
		value := self instVarNamed: ivn.
		value isVariableBinding
			ifTrue: [aStream nextPutAll: value key]
			ifFalse:
				[(#(#'unsigned char' #'signed char' #('unsigned' ' : 1')) includes: type)
					ifTrue: [value isInteger
								ifTrue: [ivn = 'opcode'
											ifTrue: [aStream nextPutAll: (CogRTLOpcodes nameForOpcode: value)]
											ifFalse: [aStream print: value]]
								ifFalse: [aStream nextPut: ((value notNil and: [value]) ifTrue: [$1] ifFalse: [$0])]]
					ifFalse: [(false and: [#('spanFunction' 'isBackwardBranchFunction') includes: ivn]) ifTrue:
								[aStream nextPut: $(; nextPutAll: type first; nextPutAll: type last; nextPut: $)].
							aStream nextPutAll: (value
													ifNotNil: [aCCodeGenerator cFunctionNameFor: value]
													ifNil: ['0'])]]].
	aStream space; nextPut: $}
]

{ #category : #'debug printing' }
CogBytecodeDescriptor >> printStateOn: aStream [
	<doNotGenerate> "Smalltalk-side only"
	generator ifNil:
		[^self].
	aStream space; nextPut: $(; nextPutAll: generator; space; print: numBytes.
	needsFrameFunction ifNotNil: [aStream space; nextPutAll: needsFrameFunction].
	spanFunction ifNotNil: [:func| aStream space; nextPutAll: func].
	isReturn ifTrue: [aStream nextPutAll: ' isReturn'].
	opcode ifNotNil: [aStream space; nextPutAll: (CogRTLOpcodes nameForOpcode: opcode)].
	aStream nextPut: $)
]

{ #category : #accessing }
CogBytecodeDescriptor >> spanFunction [
	"Answer the value of spanFunction"
	<returnTypeC: 'sqInt (*)(BytecodeDescriptor *,sqInt,sqInt,sqInt)'>
	^spanFunction
]

{ #category : #accessing }
CogBytecodeDescriptor >> spanFunction: functionPointer [
	"Set the value of spanFunction"
	<returnTypeC: 'sqInt (*)(BytecodeDescriptor *,sqInt,sqInt,sqInt)'>
	<var: #functionPointer declareC: 'sqInt (*functionPointer)(BytecodeDescriptor *,sqInt,sqInt,sqInt)'>
	^spanFunction := functionPointer
]

{ #category : #accessing }
CogBytecodeDescriptor >> stackDelta [
	"Answer the value of stackDelta"

	^stackDelta
]

{ #category : #accessing }
CogBytecodeDescriptor >> stackDelta: anObject [
	"Set the value of  stackDelta"

	^ stackDelta := anObject
]
