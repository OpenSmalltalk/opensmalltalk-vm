"
I am a native Cog method or polymorphic inline cache.  If the former I have been produced by compiling a bytecoded CompiledMethod into machine code by the JIT, and I have a circular reference to that CompiledMethod.  The CompiledMethod's header field is a pointer to me, the CogMethod, and my methodHeader field holds the compiled method's actual header.  My objectHeader field looks like a single word object with a compact header with the mark bit set so as to placate the GC, i.e. make a CogMethod look like an object so that the reference to a CogMethod from a compiled method doesn't break the GC.  The cmType, stackCheckOffset, cmNumArgs & cmNumTemps fields are early in the structure because we place dummy two-word CogMethod headers within a method for each block within it to record this information for each block method (see my superclass CogBlockMethod).  In this case the objectHeader field is overlaid by the homeOffset and startpc fields.  The objectHeader field is also used to hold the relocation distance when compacting methods since when functioning as an obhject header it is a constant value and so can easily be reinitialized.  See Cogit class>>structureOfACogMethod for more information.

In C I look like

	typedef struct {
	    sqInt   objectHeader;
	
	    unsigned        cmNumArgs : 8;
	    unsigned        cmType : 3;
	    unsigned        cmRefersToYoung : 1;
	    unsigned        cmIsUnlinked : 1;
	    unsigned        cmUsageCount : 3;
	    unsigned        stackCheckOffset : 16;
	
	    unsigned short blockSize;
	    unsigned short blockEntryOffset;
	
	    sqInt   methodObject;
	    sqInt   methodHeader;
	    sqInt   selector;
	 } CogMethod;

Note that in a 64-bit system all fields from cmNumArgs through blockEntry fit in a single 64-bit word.

My instances are not actually used.  The methods exist only as input to Slang.  The simulator uses my surrogates (CogMethodSurrogate32 and CogMethodSurrogate64.
"
Class {
	#name : #CogMethod,
	#superclass : #CogBlockMethod,
	#instVars : [
		'blockSize',
		'blockEntryOffset',
		'methodObject',
		'methodHeader',
		'selector'
	],
	#category : 'VMMaker-JIT'
}

{ #category : #accessing }
CogMethod class >> alignedByteSizeOf: anObject forClient: aVMClass [
	^aVMClass cogit cogMethodSurrogateClass alignedByteSize
]

{ #category : #translation }
CogMethod class >> cogMethodHeader [
	^String streamContents:
		[:s|
		CogBlockMethod printTypedefOn: s.
		s cr.
		self printTypedefOn: s]
]

{ #category : #'class initialization' }
CogMethod class >> initialize [
	"self initialize"
	(Smalltalk classNamed: #CogMethodSurrogate32) ifNotNil:
		[:cms32|
		self checkGenerateSurrogate: cms32 bytesPerWord: 4].
	(Smalltalk classNamed: #CogMethodSurrogate64) ifNotNil:
		[:cms64|
		self checkGenerateSurrogate: cms64 bytesPerWord: 8]
]

{ #category : #accessing }
CogMethod class >> surrogateClass [
	self shouldNotImplement
]

{ #category : #accessing }
CogMethod >> blockEntryOffset [
	"Answer the value of blockEntryOffset"

	^blockEntryOffset
]

{ #category : #accessing }
CogMethod >> blockEntryOffset: anObject [
	"Set the value of blockEntryOffset"

	^blockEntryOffset := anObject
]

{ #category : #accessing }
CogMethod >> blockSize [
	"Answer the value of blockSize"

	^ blockSize
]

{ #category : #accessing }
CogMethod >> blockSize: anObject [
	"Set the value of blockSize"

	^blockSize := anObject
]

{ #category : #testing }
CogMethod >> containsAddress: anAddress [
	"is anAddress within my bounds; not a test of addresses referred to within instructions in the method"
	<inline: true>
	^self asUnsignedInteger <= anAddress asUnsignedInteger
	  and: [self asUnsignedInteger + self blockSize >= anAddress asUnsignedInteger]
]

{ #category : #accessing }
CogMethod >> methodHeader [
	"Answer the value of methodHeader"

	^ methodHeader
]

{ #category : #accessing }
CogMethod >> methodHeader: anObject [
	"Set the value of methodHeader"

	^methodHeader := anObject
]

{ #category : #accessing }
CogMethod >> methodObject [
	"Answer the value of methodObject"

	^methodObject
]

{ #category : #accessing }
CogMethod >> methodObject: anObject [
	"Set the value of methodObject"

	^methodObject := anObject
]

{ #category : #accessing }
CogMethod >> nextOpenPIC [
	"Answer the value of nextOpenPIC (a.k.a. methodObject)"
	<cmacro: ' methodObject'>
	^methodObject
]

{ #category : #accessing }
CogMethod >> nextOpenPIC: anObject [
	"Set the value of nextOpenPIC (a.k.a. methodObject)"
	<cmacro: 'Hack hack hack hack i.e. the getter macro does all the work'>
	^methodObject := anObject
]

{ #category : #accessing }
CogMethod >> objectHeader [
	"Answer the value of objectHeader"

	^objectHeader
]

{ #category : #accessing }
CogMethod >> objectHeader: anObject [
	"Set the value of objectHeader"

	^objectHeader := anObject
]

{ #category : #accessing }
CogMethod >> selector [
	"Answer the value of selector"

	^ selector
]

{ #category : #accessing }
CogMethod >> selector: anObject [
	"Set the value of selector"

	^selector := anObject
]
