Class {
	#name : #CogObjectHeader,
	#superclass : #VMStructType,
	#instVars : [
		'classIndex',
		'unused0',
		'isPinned',
		'isImmutable',
		'format',
		'isMarked',
		'isGrey',
		'isRemembered',
		'objHash',
		'slotSize'
	],
	#category : #'VMMaker-SpurMemoryManager'
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
	"self typedef"

	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
							['classIndex']	->	[#'unsigned short']. "for speed; can extend to 22 bits by absorbing unused0"
							['unused0']		->	[#(unsigned ' : 6')].
							['format']		->	[#(unsigned ' : 5')].
							['objHash']		->	[#(unsigned ' : 24')].
							['slotSize']		->	[#'unsigned char'] }
						otherwise: [#(#unsigned #Boolean ' : 1')])]
]

{ #category : #accessing }
CogObjectHeader >> isForwarded [
	^self classIndex = 0
]

{ #category : #accessing }
CogObjectHeader >> setIsForwarded [
	self classIndex: 0
]
