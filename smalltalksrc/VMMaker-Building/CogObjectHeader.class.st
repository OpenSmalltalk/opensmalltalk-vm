Class {
	#name : #CogObjectHeader,
	#superclass : #VMStructType,
	#instVars : [
		'classIndex',
		'unused0',
		'format',
		'isWeak',
		'isEphemeron',
		'isPointers',
		'isPinned',
		'isMarked',
		'isGrey',
		'isRemembered',
		'isImmutable',
		'objHash',
		'objSize'
	],
	#category : #'VMMaker-MemoryManager'
}

{ #category : #'class initialization' }
CogObjectHeader class >> initialize [
	(Smalltalk classNamed: #CogObjectHeaderSurrogate) ifNotNil:
		[:cohs|
		self checkGenerateSurrogate: cohs bytesPerWord: 4].

	"CogObjectHeader initialize"
]

{ #category : #translation }
CogObjectHeader class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a BytecodeDescriptor struct."

	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
							['classIndex']	->	[#'unsigned short']. "for speed; can extend to 20 bits by absorbing unused0"
							['unused0']		->	[#(unsigned ' : 4')].
							['format']		->	[#(unsigned ' : 4')].
							['objHash']		->	[#(unsigned ' : 24')].
							['objSize']		->	[#'unsigned char'] }
						otherwise: [#(#unsigned #Boolean ' : 1')])]
]
