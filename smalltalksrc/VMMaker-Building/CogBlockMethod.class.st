"
I am the rump method header for a block method embedded in a full CogMethod.  I am the superclass of CogMethod, which is a Cog method header proper.  Instances of both classes have the same second word.  The homeOffset abd startpc fields are overlaid on the objectHeader in a CogMethod.  In C I look like

	typedef struct {
		unsigned short	homeOffset;
		unsigned short	startpc;

		unsigned		cmNumArgs : 8;
		unsigned		cmType : 3;
		unsigned		cmRefersToYoung : 1;
		unsigned		cmIsUnlinked : 1;
		unsigned		cmUsageCount : 3;
		unsigned		stackCheckOffset : 16;
	} CogBlockMethod;

My instances are not actually used.  The methods exist only as input to Slang.  The simulator uses my surrogates (CogBlockMethodSurrogate32 and CogBlockMethodSurrogate64.
"
Class {
	#name : #CogBlockMethod,
	#superclass : #VMStructType,
	#instVars : [
		'objectHeader',
		'homeOffset',
		'startpc',
		'padToWord',
		'cmNumArgs',
		'cmType',
		'cmRefersToYoung',
		'cpicHasMNUCase',
		'cmUsageCount',
		'cmUsesPenultimateLit',
		'cmUnusedFlags',
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
	self shouldNotImplement
]

{ #category : #accessing }
CogBlockMethod class >> alignedByteSizeOf: anObject forClient: aVMClass [
	^aVMClass cogit cogBlockMethodSurrogateClass alignedByteSize
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

	"see instVarNamesAndTypesForTranslationDo:"
	CMMaxUsageCount		:= (2 raisedTo: 3) - 1.
	MaxStackCheckOffset	:= (2 raisedTo: 12) - 1.
	MaxMethodSize		:= (2 raisedTo: 16) - 1

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
		"Notionally objectHeader is in a union with homeOffset and startpc but
		 we don't have any convenient support for unions.  So hack, hack, hack, hack."
		((self == CogBlockMethod
			ifTrue: [#('objectHeader')]
			ifFalse: [#('homeOffset' 'startpc' 'padToWord')]) includes: ivn) ifFalse:
				[aBinaryBlock
					value: ivn
					value: (ivn caseOf: {
								['cmNumArgs']				-> [#(unsigned ' : 8')]. "SqueakV3 needs only 5 bits"
								['cmType']					-> [#(unsigned ' : 3')].
								['cmRefersToYoung']		-> [#(unsigned #Boolean ' : 1')].
								['cpicHasMNUCase']		-> [#(unsigned #Boolean ' : 1')].
								['cmUsageCount']			-> [#(unsigned ' : 3')]. "see CMMaxUsageCount in initialize"
								['cmUsesPenultimateLit']	-> [#(unsigned #Boolean ' : 1')].
								['cmUnusedFlags']			-> [#(unsigned ' : 3')].
								['stackCheckOffset']		-> [#(unsigned ' : 12')]. "See MaxStackCheckOffset in initialize. a.k.a. cPICNumCases"
								['blockSize']				-> [#'unsigned short']. "See MaxMethodSize in initialize"
								['blockEntryOffset']			-> [#'unsigned short'].
								['homeOffset']				-> [#'unsigned short'].
								['startpc']					-> [#'unsigned short'].
								['padToWord']				-> [#(#BytesPerWord 8 'unsigned int')]}
							otherwise:
								[#sqInt])]]
]

{ #category : #translation }
CogBlockMethod class >> isAccessor: aSelector [
	"Answer if aSelector is simply an accessor method for one of our fields."
	^(#(cPICNumCases cPICNumCases: nextOpenPIC nextOpenPIC:) includes: aSelector)
	  or: [super isAccessor: aSelector]
]

{ #category : #accessing }
CogBlockMethod class >> surrogateClass [
	self shouldNotImplement
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
CogBlockMethod >> cmHomeMethod [
	<returnTypeC: #'CogMethod *'>
	^self cCoerceSimple: self asUnsignedInteger - self homeOffset to: #'CogMethod *'
]

{ #category : #accessing }
CogBlockMethod >> cmNumArgs [
	"Answer the value of cmNumArgs"

	^cmNumArgs
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
CogBlockMethod >> cmUsesPenultimateLit [
	"Answer the value of cmUsesPenultimateLit"

	^cmUsesPenultimateLit
]

{ #category : #accessing }
CogBlockMethod >> cmUsesPenultimateLit: anObject [
	"Set the value of cmUsesPenultimateLit"

	^cmUsesPenultimateLit := anObject
]

{ #category : #accessing }
CogBlockMethod >> cpicHasMNUCase [
	"Answer the value of cpicHasMNUCase"

	^cpicHasMNUCase
]

{ #category : #accessing }
CogBlockMethod >> cpicHasMNUCase: anObject [
	"Set the value of cpicHasMNUCase"

	^cpicHasMNUCase := anObject
]

{ #category : #accessing }
CogBlockMethod >> homeOffset [
	"Answer the value of homeOffset"

	^homeOffset
]

{ #category : #accessing }
CogBlockMethod >> homeOffset: anObject [
	"Set the value of homeOffset"

	^homeOffset := anObject
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
CogBlockMethod >> startpc [
	"Answer the value of startpc"

	^startpc
]

{ #category : #accessing }
CogBlockMethod >> startpc: anObject [
	"Set the value of startpc"

	^startpc := anObject
]
