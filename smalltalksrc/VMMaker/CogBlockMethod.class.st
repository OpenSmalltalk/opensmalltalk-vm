"
I am the rump method header for a block method embedded in a full CogMethod.  I am the superclass of CogMethod, which is a Cog method header proper.  Instances of both classes have the same second word.  The homeOffset and startpc fields are overlaid on the objectHeader in a CogMethod.  See Cogit class>>structureOfACogMethod for more information.  In C I look like

	typedef struct {
		union {
			struct {
				unsigned short	homeOffset;
				unsigned short	startpc;
	#if SpurVM
				unsigned int	padToWord;
	#endif
			};
			sqInt/sqLong	objectHeader;
		};
		unsigned		cmNumArgs : 8;
		unsigned		cmType : 3;
		unsigned		cmRefersToYoung : 1;
		unsigned		cpicHasMNUCaseOrCMIsFullBlock : 1;
		unsigned		cmUsageCount : 3;
		unsigned		cmUsesPenultimateLit : 1;
		unsigned		cbUsesInstVars : 1;
		unsigned		cmUnusedFlags : 2;
		unsigned		stackCheckOffset : 12;
	 } CogBlockMethod;

My instances are not actually used.  The methods exist only as input to Slang.  The simulator uses my surrogates (CogBlockMethodSurrogate32 and CogBlockMethodSurrogate64) to reference CogBlockMethod and CogMethod structures in the code zone.  The start of the structure is 32-bits in the V3 memory manager and 64-bits in the Spour memory manager.  In a CMMethod these bits are set to the object header of a marked bits objects, allowing code to masquerade as objects when referred to from the first field of a CompiledMethod.  In a CMBlock, they hold the homeOffset and the startpc.

cbUsesInstVars
	- a flag set to true in blocks that refer to instance variables.

cmNumArgs
	- the byte containing the block or method arg count

cmRefersToYoung
	- a flag set to true in methods which contain a reference to an object in new space

cmType
	- one of CMFree, CMMethod, CMBlock, CMClosedPIC, CMOpenPIC

cmUnusedFlags
	- as yet unused bits

cmUsageCount
	- a count used to identify older methods in code compaction.  The count decays over time, and compaction frees methods with lower usage counts

cmUsesPenultimateLit
	- a flag that states whether the penultimate literal in the corresponding bytecode method is used.  This in turn is used to check that a become of a method does not alter its bytecode.

cpicHasMNUCaseOrCMIsFullBlock
	- a flag that states whether a CMClosedPIC contains one or more MNU cases which are PIC dispatches used to speed-up MNU processing,
	  or states whether a CMMethod is for a full block instead of for a compiled method.

homeOffset
	- the distance a CMBlock header is away from its enclosing CMMethod header

objectHeader
	- an object header used to fool the garbage collector into thinking that a CMMethod is a normal bits object, so that the first field (the header word) of a bytecoded method can refer directly to a CMMethod without special casing the garbage collector's method scanning code more than it already is.

padToWord
	- a pad that may be necessary to make the homeOffset, startpc, padToWord triple as large as a CMMethod's objectHeader field

stackCheckOffset
	- the distance from the header to the stack limit check in a frame building method or block, used to reenter execution in methods or blocks that have checked for events at what is effectively the first bytecode

startpc
	- the bytecode pc of the start of a CMBlock's bytecode in the bytecode method
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
		'cpicHasMNUCaseOrCMIsFullBlock',
		'cmUsageCount',
		'cmUsesPenultimateLit',
		'cbUsesInstVars',
		'cmUnusedFlags',
		'stackCheckOffset'
	],
	#pools : [
		'CogMethodConstants',
		'VMBasicConstants',
		'VMBytecodeConstants'
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
	"enumerate aBinaryBlock with the names and C type strings for the
	 inst vars to include in a CogMethod or CogBlockMethod struct."

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
								['objectHeader']			-> [self objectMemoryClass baseHeaderSize = 8
																ifTrue: [#sqLong]
																ifFalse: [#sqInt]].
								['cmNumArgs']				-> [#(unsigned ' : 8')].		"SqueakV3 needs only 5 bits"
								['cmType']					-> [#(unsigned ' : 3')].
								['cmRefersToYoung']		-> [#(unsigned #Boolean ' : 1')].
								['cpicHasMNUCaseOrCMIsFullBlock']
															-> [#(unsigned #Boolean ' : 1')].
								['cmUsageCount']			-> [#(unsigned ' : 3')].		"See CMMaxUsageCount in initialize"
								['cmUsesPenultimateLit']	-> [#(unsigned #Boolean ' : 1')].
								['cbUsesInstVars']			-> [#(unsigned #Boolean ' : 1')].
								['cmUnusedFlags']			-> [#(unsigned ' : 2')].
								['stackCheckOffset']		-> [#(unsigned ' : 12')].	"See MaxStackCheckOffset in initialize. a.k.a. cPICNumCases"
								['blockSize']				-> [#'unsigned short'].		"See MaxMethodSize in initialize"
								['blockEntryOffset']			-> [#'unsigned short'].
								['homeOffset']				-> [#'unsigned short'].
								['startpc']					-> [#'unsigned short'].
								['padToWord']				-> [#(#BaseHeaderSize 8 'unsigned int')].
								['counters']					-> [#usqInt]}				"See SistaCogMethod"
							otherwise:
								[#sqInt])]]
]

{ #category : #translation }
CogBlockMethod class >> isAccessor: aSelector [
	"Answer if aSelector is simply an accessor method for one of our fields."
	^(#(cPICNumCases cPICNumCases: nextOpenPIC nextOpenPIC:) includes: aSelector)
	  or: [super isAccessor: aSelector]
]

{ #category : #'code generation' }
CogBlockMethod class >> offsetForInstVar: instVarName [
	"Hack to offset accesses to variables by certain values.  The inst vars following
	 the objectHeader must be offset by the baseHeaderSize."
	^(#('objectHeader' 'homeOffset' 'startpc' 'padToWord') includes: instVarName) ifFalse:
		['baseHeaderSize']
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
CogBlockMethod >> cbUsesInstVars [

	^cbUsesInstVars
]

{ #category : #accessing }
CogBlockMethod >> cbUsesInstVars: anObject [

	^cbUsesInstVars := anObject
]

{ #category : #accessing }
CogBlockMethod >> cmHomeMethod [
	^SistaV1BytecodeSet
		ifTrue: [self cmIsFullBlock
					ifTrue: [self cCoerceSimple: self to: #'CogMethod *']
					ifFalse: [self cCoerceSimple: self asUnsignedInteger - self homeOffset to: #'CogMethod *']]
		ifFalse: [self cCoerceSimple: self asUnsignedInteger - self homeOffset to: #'CogMethod *']
]

{ #category : #accessing }
CogBlockMethod >> cmIsFullBlock [
	"Answer the value of cpicHasMNUCaseOrCMIsFullBlock"
	<inline: true>
	^SistaV1BytecodeSet
		ifTrue: [self cpicHasMNUCaseOrCMIsFullBlock]
		ifFalse: [false]
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
	"Answer if the receiver has an MNU case."
	<inline: true>

	^SistaV1BytecodeSet
		ifTrue: [self cpicHasMNUCaseOrCMIsFullBlock and: [self cmType = CMClosedPIC]]
		ifFalse: [cpicHasMNUCaseOrCMIsFullBlock]
]

{ #category : #accessing }
CogBlockMethod >> cpicHasMNUCase: anObject [
	"Set if the receiver has an MNU case."
	<inline: true>
	^cpicHasMNUCaseOrCMIsFullBlock := anObject
]

{ #category : #accessing }
CogBlockMethod >> cpicHasMNUCaseOrCMIsFullBlock [
	"Answer the value of cpicHasMNUCaseOrCMIsFullBlock"

	^cpicHasMNUCaseOrCMIsFullBlock
]

{ #category : #accessing }
CogBlockMethod >> cpicHasMNUCaseOrCMIsFullBlock: anObject [
	"Set the value of cpicHasMNUCaseOrCMIsFullBlock"

	^cpicHasMNUCaseOrCMIsFullBlock := anObject
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
