"
I am an abstract superclass for object representations whose job it is to generate abstract instructions for accessing objects.  It is hoped that this level of indirection between the Cogit code generator and object access makes it easier to adapt the code generator to different garbage collectors, object representations and languages.
"
Class {
	#name : #CogObjectRepresentation,
	#superclass : #CogClass,
	#instVars : [
		'cogit',
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
CogObjectRepresentation class >> for: aCogit [
	^self new setCogit: aCogit
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

{ #category : #'primitive generators' }
CogObjectRepresentation >> genInnerPrimitiveNew: retNoffset [
	self subclassResponsibility.
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genInnerPrimitiveNewMethod: retNoffset [
	self subclassResponsibility.
	^0
]

{ #category : #'primitive generators' }
CogObjectRepresentation >> genInnerPrimitiveNewWithArg: retNoffset [
	self subclassResponsibility
]

{ #category : #initialization }
CogObjectRepresentation >> generateObjectRepresentationTrampolines [
	ceStoreCheckTrampoline := cogit
									genTrampolineFor: #ceStoreCheck:
									called: 'ceStoreCheckTrampoline'
									arg: ReceiverResultReg
									result: cogit returnRegForStoreCheck
]

{ #category : #initialization }
CogObjectRepresentation >> implementsNew [
	^false
]

{ #category : #initialization }
CogObjectRepresentation >> implementsNewMethod [
	^false
]

{ #category : #initialization }
CogObjectRepresentation >> implementsNewWithArg [
	^false
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
CogObjectRepresentation >> setCogit: aCogit [
	<doNotGenerate>
	cogit := aCogit.
	objectMemory := (aCogit coInterpreter isKindOf: ObjectMemory)
						ifTrue: [aCogit coInterpreter]
						ifFalse: [aCogit coInterpreter objectMemory]
]

{ #category : #testing }
CogObjectRepresentation >> smallIntegerIsOnlyImmediateType [
	self subclassResponsibility
]
