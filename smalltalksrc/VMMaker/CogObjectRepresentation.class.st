"
I am an abstract superclass for object representations whose job it is to generate abstract instructions for accessing objects.  It is hoped that this level of indirection between the Cogit code generator and object access makes it easier to adapt the code generator to different garbage collectors, object representations and languages.
"
Class {
	#name : #CogObjectRepresentation,
	#superclass : #CogClass,
	#instVars : [
		'cogit',
		'methodZone',
		'objectMemory',
		'ceStoreCheckTrampoline'
	],
	#pools : [
		'CogMethodConstants',
		'CogRTLOpcodes',
		'VMBasicConstants',
		'VMObjectIndices'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #'instance creation' }
CogObjectRepresentation class >> forCogit: aCogit methodZone: methodZone [
	^self new setCogit: aCogit methodZone: methodZone
]

{ #category : #translation }
CogObjectRepresentation class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #translation }
CogObjectRepresentation class >> typeForSelf [
	^#implicit
]

{ #category : #'garbage collection' }
CogObjectRepresentation >> allYoungObjectsAgeInFullGC [
	^self subclassResponsibility
]

{ #category : #'in-line cacheing' }
CogObjectRepresentation >> canLinkToYoungClasses [
	^self subclassResponsibility
]

{ #category : #'compile abstract instructions' }
CogObjectRepresentation >> genEnsureObjInRegRegNotForwarded: reg scratchReg: scratch [
	"Make sure that the object in reg is not forwarded.  By default there is
	 nothing to do.  Subclasses for memory managers that forward will override."
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genInnerPrimitiveNew: retNoffset [
	"subclasses override if they can"
	^cogit unimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genInnerPrimitiveNewMethod: retNoffset [
	"subclasses override if they can"
	^cogit unimplementedPrimitive
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genInnerPrimitiveNewWithArg: retNoffset [
	"subclasses override if they can"
	^cogit unimplementedPrimitive
]

{ #category : #initialization }
CogObjectRepresentation >> generateObjectRepresentationTrampolines [
	ceStoreCheckTrampoline := cogit
									genTrampolineFor: #ceStoreCheck:
									called: 'ceStoreCheckTrampoline'
									arg: ReceiverResultReg
									result: cogit returnRegForStoreCheck
]

{ #category : #'in-line cacheing' }
CogObjectRepresentation >> inlineCacheTagForInstance: oop [
	"c.f. getInlineCacheClassTagFrom:into:"
	^self subclassResponsibility
]

{ #category : #'in-line cacheing' }
CogObjectRepresentation >> inlineCacheTagIsYoung: cacheTag [
	^self subclassResponsibility
]

{ #category : #'in-line cacheing' }
CogObjectRepresentation >> inlineCacheTagsMayBeObjects [
	^self subclassResponsibility
]

{ #category : #testing }
CogObjectRepresentation >> isHashSetOnInstanceCreation [
	self subclassResponsibility
]

{ #category : #testing }
CogObjectRepresentation >> isImmediate: oop [
	<doNotGenerate>
	^objectMemory isImmediate: oop
]

{ #category : #testing }
CogObjectRepresentation >> isSmallIntegerTagNonZero [
	self subclassResponsibility
]

{ #category : #'garbage collection' }
CogObjectRepresentation >> markAndTraceLiteral: literal [
	self subclassResponsibility
]

{ #category : #'garbage collection' }
CogObjectRepresentation >> markAndTraceLiteralIfYoung: literal [
	self subclassResponsibility
]

{ #category : #initialization }
CogObjectRepresentation >> setCogit: aCogit methodZone: aMethodZone [
	<doNotGenerate>
	cogit := aCogit.
	methodZone := aMethodZone.
	objectMemory := (aCogit coInterpreter isKindOf: StackInterpreter)
						ifTrue: [aCogit coInterpreter objectMemory]
						ifFalse: [aCogit coInterpreter]
]

{ #category : #testing }
CogObjectRepresentation >> smallIntegerIsOnlyImmediateType [
	self subclassResponsibility
]
