"
I am the rump method header for a block method embedded in a full CogMethod.  I am the superclass of CogMethod, which is a Cog method header proper.  Instances of both classes have the same first two words.  In C I look like

	typedef struct {
	    sqInt   objectHeader;
	
	    unsigned        cmNumArgs : 8;
	    unsigned        cmType : 3;
	    unsigned        cmRefersToYoung : 1;
	    unsigned        cmIsUnlinked : 1;
	    unsigned        cmUsageCount : 3;

	    unsigned        stackCheckOffset : 16;
	} CogBlockMethod;

The objectHeader is a fake object header for a marked object with no fields.  Bytecoded methods which have been compiled to Cog methods have their header field point directly to their Cog method.  The fake objectHeader fools the garbage collector into thinking this reference is to an object it doesn't have to examine further.

However, in a CogBlockMethod the objectHeader field is a direct reference to the CogMethod in which the block occurs.
"
Class {
	#name : #CogBlockMethod,
	#superclass : #VMStructType,
	#instVars : [
		'objectHeader',
		'cmNumArgs',
		'cmType',
		'cmRefersToYoung',
		'cmIsUnlinked',
		'cmUsageCount',
		'stackCheckOffset'
	],
	#pools : [
		'CogMethodConstants',
		'VMBasicConstants'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #accessing }
CogBlockMethod class >> alignedByteSize [
	^self surrogateClass alignedByteSize
]

{ #category : #'class initialization' }
CogBlockMethod class >> initialize [
	"CogBlockMethod initialize"
	"CogBlockMethod initialize. CogMethod initialize"
	(Smalltalk classNamed: #CogBlockMethodSurrogate32) ifNotNil:
		[:cbms32|
		self checkGenerateSurrogate: cbms32 bytesPerWord: 4].
	(Smalltalk classNamed: #CogBlockMethodSurrogate64) ifNotNil:
		[:cbms64|
		self checkGenerateSurrogate: cbms64 bytesPerWord: 8].

	CMMaxUsageCount := 7 "see instVarNamesAndTypesForTranslationDo:"

	"{ CogBlockMethodSurrogate32 selectors reject: [:s| CogBlockMethod includesSelector: s].
	    CogBlockMethodSurrogate64 selectors reject: [:s| CogBlockMethod includesSelector: s].
	    CogMethodSurrogate32 selectors reject: [:s| CogMethod includesSelector: s].
	    CogMethodSurrogate64 selectors reject: [:s| CogMethod includesSelector: s]. }"
]

{ #category : #translation }
CogBlockMethod class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a CogMethod or CogBlockMethod struct."

	self allInstVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['cmNumArgs']		-> [#('unsigned' ' : 8')]. "SqueakV3 needs only 5 bits"
						['cmType']			-> [#('unsigned' ' : 3')].
						['cmRefersToYoung']	-> [#('unsigned' #Boolean ' : 1')].
						['cmIsUnlinked']		-> [#('unsigned' #Boolean ' : 1')].
						['cmUsageCount']	-> [#('unsigned' ' : 3')]. "see CMMaxUsageCount in initialize"
						['stackCheckOffset']	-> [#('unsigned' ' : 16')]. "a.k.a. cPICNumCases"
						['blockSize']			-> ['unsigned short'].
						['blockEntryOffset']	-> ['unsigned short']}
					otherwise:
						[#sqInt])]
]

{ #category : #translation }
CogBlockMethod class >> isAccessor: aSelector [
	"Answer if aSelector is simply an accessor method for one of our fields."
	^(#(cPICNumCases cPICNumCases: nextOpenPIC nextOpenPIC:) includes: aSelector)
	  or: [super isAccessor: aSelector]
]

{ #category : #accessing }
CogBlockMethod class >> surrogateClass [
	^BytesPerWord = 4
		ifTrue: [CogBlockMethodSurrogate32]
		ifFalse: [CogBlockMethodSurrogate64]
]

{ #category : #accessing }
CogBlockMethod >> cPICNumCases [
	"Answer the value of cPICNumCases (a.k.a. stackCheckOffset)"
	<cmacro: ' stackCheckOffset'>
	^stackCheckOffset
]

{ #category : #accessing }
CogBlockMethod >> cPICNumCases: anObject [
	"Set the value of cPICNumCases (a.k.a. stackCheckOffset)"
	<cmacro: 'Hack hack hack hack i.e. the getter macro does all the work'>
	^stackCheckOffset := anObject
]

{ #category : #accessing }
CogBlockMethod >> cmIsUnlinked [
	"Answer the value of cmIsUnlinked"

	^cmIsUnlinked
]

{ #category : #accessing }
CogBlockMethod >> cmIsUnlinked: anObject [
	"Set the value of cmIsUnlinked"

	^cmIsUnlinked := anObject
]

{ #category : #accessing }
CogBlockMethod >> cmNumArgs [
	"Answer the value of cmNumArgs"

	^ cmNumArgs
]

{ #category : #accessing }
CogBlockMethod >> cmNumArgs: anObject [
	"Set the value of cmNumArgs"

	^cmNumArgs := anObject
]

{ #category : #accessing }
CogBlockMethod >> cmRefersToYoung [
	"Answer the value of cmRefersToYoung"

	^cmRefersToYoung
]

{ #category : #accessing }
CogBlockMethod >> cmRefersToYoung: anObject [
	"Set the value of cmRefersToYoung"

	^cmRefersToYoung := anObject
]

{ #category : #accessing }
CogBlockMethod >> cmType [
	"Answer the value of cmType"

	^cmType
]

{ #category : #accessing }
CogBlockMethod >> cmType: anInteger [
	"Set the value of cmType"

	^cmType := anInteger
]

{ #category : #accessing }
CogBlockMethod >> cmUsageCount [
	"Answer the value of cmUsageCount"

	^cmUsageCount
]

{ #category : #accessing }
CogBlockMethod >> cmUsageCount: anInteger [
	"Set the value of cmUsageCount"

	^cmUsageCount := anInteger
]

{ #category : #accessing }
CogBlockMethod >> objectHeader [
	"Answer the value of objectHeader"

	^objectHeader
]

{ #category : #accessing }
CogBlockMethod >> objectHeader: anObject [
	"Set the value of objectHeader"

	^objectHeader := anObject
]

{ #category : #accessing }
CogBlockMethod >> stackCheckOffset [
	"Answer the value of stackCheckOffset"

	^stackCheckOffset
]

{ #category : #accessing }
CogBlockMethod >> stackCheckOffset: anObject [
	"Set the value of stackCheckOffset"

	^stackCheckOffset := anObject
]

{ #category : #accessing }
CogBlockMethod >> typeEtAlWord [
	<cmacro: '(cm) (((long *)(cm))[1])'>
	self halt
]
