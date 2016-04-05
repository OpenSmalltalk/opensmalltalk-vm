"
/*	Regular Expression Plugin (This class comment becomes part of rePlugin.c)

	RePlugin translate: 'RePlugin.c' doInlining: true.

See documentation and source code for the PCRE C Library Code.  This plugin is designed to serve an object such as RePattern:

	patternStr		A 0-terminated string comprising the pattern to be compiled.
	compileFlags	An Integer representing re compiler options
	PCREBuffer		A ByteArray of regular expression bytecodes
	extraPtr			A ByteArray of match optimization data (or nil)
	errorString		A String Object For Holding an Error Message (when compile failed)
	errorOffset		The index in patternStr (0-based) where the error ocurred (when compile failed)
	matchFlags		An Integer representing re matcher options
	matchSpaceObj	An Integer array for match results and workspace during matching.

The instance variables must appear in the preceding order.  MatchSpaceObj must be allocated by the calling routine and contain at least 6*(numGroups+1) bytes.
*/
#include ""pcre.h""
#include ""internal.h""

/* Slight machine-specific hack for MacOS Memory Management */
#ifdef TARGET_OS_MAC
#define	malloc(ptr) NewPtr(ptr)
#define free(ptr) DisposePtr(aPointer)
#endif

/* Adjust malloc and free routines as used by PCRE */
void rePluginFree(void * aPointer);
void * rePluginMalloc(size_t anInteger);
void *(*pcre_malloc)(size_t) = rePluginMalloc;
void  (*pcre_free)(void *) = rePluginFree;

"
Class {
	#name : #RePlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#instVars : [
		'netMemory',
		'numAllocs',
		'numFrees',
		'lastAlloc',
		'patternStr',
		'rcvr',
		'compileFlags',
		'pcrePtr',
		'extraPtr',
		'errorStr',
		'errorOffset',
		'matchFlags',
		'patternStrPtr',
		'errorStrBuffer'
	],
	#category : 'VMMaker-Plugins'
}

{ #category : #'plugin code generation' }
RePlugin class >> declareCVarsIn: cg [

	cg addHeaderFile:'"rePlugin.h"'.

	"Memory Management Error Checking"
	cg var: 'netMemory' 	declareC: 'int netMemory = 0'.
	cg var: 'numAllocs' 	declareC: 'int numAllocs = 0'.
	cg var: 'numFrees' 		declareC: 'int numFrees = 0'.
	cg var: 'lastAlloc'		declareC: 'int lastAlloc = 0'.

	"Support Variables for Access to Receiver Instance Variables"
	cg var: 'patternStrPtr' type: 'const char * '.
	cg var: 'errorStrBuffer'	type: 'const char * '.
]

{ #category : #'plugin code generation' }
RePlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
RePlugin class >> moduleName [

	^'RePlugin'
]

{ #category : #'plugin code generation' }
RePlugin class >> requiresCrossPlatformFiles [
	"default is ok for most, any plugin needing cross platform files must say so"
	^true
]

{ #category : #'rcvr linkage' }
RePlugin >> allocateByteArrayAndSetRcvrExtraPtrFrom: anExtraPtr [

	| extraObject extraByteArrayPtr |
	<var: #extraByteArrayPtr type: 'void *'>

	anExtraPtr
		ifFalse: [extraObject := interpreterProxy nilObject]
		ifTrue: [
			"Allocate a Smalltalk ByteArray -- lastAlloc contains the length"
			extraObject := interpreterProxy
						instantiateClass: (interpreterProxy classByteArray) 
						indexableSize: (self cCode: 'sizeof(real_pcre_extra)').
			self loadRcvrFromStackAt: 0. "Assume garbage collection after instantiation"

			"Copy from the C bytecode buffer to the Smalltalk ByteArray"
			extraByteArrayPtr := interpreterProxy arrayValueOf: extraObject.	
			self cCode:'memcpy(extraByteArrayPtr, (void *) anExtraPtr, sizeof(real_pcre_extra))'].
 
	"Set rcvrErrorStr from errorStr and Return"
	self rcvrExtraPtrFrom: extraObject.
	self touch: extraByteArrayPtr.	
	^extraObject.

]

{ #category : #'rcvr linkage' }
RePlugin >> allocateByteArrayAndSetRcvrPCREPtrFromPCRE: aPCREPtr [

	| patObject patByteArrayPtr |
	<var: #patByteArrayPtr type: 'void *'>

	"Allocate a Smalltalk ByteArray -- lastAlloc contains the length"
	patObject := interpreterProxy
				instantiateClass: (interpreterProxy classByteArray) 
				indexableSize: lastAlloc.
	self loadRcvrFromStackAt: 0. "Assume garbage collection after instantiation"

	"Copy from the C bytecode buffer to the Smalltalk ByteArray"
	patByteArrayPtr := interpreterProxy arrayValueOf: patObject.	
	self cCode:'memcpy(patByteArrayPtr, (void *) aPCREPtr, lastAlloc)'.
 
	"Set rcvrErrorStr from errorStr and Return"
	self rcvrPCREBufferFrom: patObject.
	self touch: patByteArrayPtr.	
	^patObject.

]

{ #category : #'rcvr linkage' }
RePlugin >> allocateStringAndSetRcvrErrorStrFromCStr: aCStrBuffer [

	|length errorStrObj errorStrObjPtr |
	<var: #aCStrBuffer type: 'const char *'>
	<var: #errorStrObjPtr type: 'void *'>
	"Allocate errorStrObj"
	length := self cCode: 'strlen(aCStrBuffer)'.
	errorStrObj := interpreterProxy
				instantiateClass: (interpreterProxy classString) 
				indexableSize: length.
	self loadRcvrFromStackAt: 0. "Assume garbage collection after instantiation"

	"Copy aCStrBuffer to errorStrObj's buffer"
	errorStrObjPtr := interpreterProxy arrayValueOf: errorStrObj.	
	self cCode:'memcpy(errorStrObjPtr,aCStrBuffer,length)'.
	self touch: errorStrObjPtr; touch: errorStrObj.
	"Set rcvrErrorStr from errorStrObj and Return"
	self rcvrErrorStrFrom: errorStrObj.
	^errorStrObj.
]

{ #category : #'rcvr linkage' }
RePlugin >> loadRcvrFromStackAt: stackInteger [

	<inline:true>
	rcvr := interpreterProxy stackObjectValue: stackInteger.

]

{ #category : #'memory management' }
RePlugin >> primLastAlloc [
	
	<export: true>
	interpreterProxy pop:1; pushInteger: lastAlloc

]

{ #category : #'memory management' }
RePlugin >> primNetMemory [ 
	
	<export: true>
	interpreterProxy pop:1; pushInteger: netMemory

]

{ #category : #'memory management' }
RePlugin >> primNumAllocs [

	<export: true>
	interpreterProxy pop:1; pushInteger: numAllocs

]

{ #category : #'memory management' }
RePlugin >> primNumFrees [ 
	
	<export: true>
	interpreterProxy pop:1; pushInteger: numFrees

]

{ #category : #'re primitives' }
RePlugin >> primPCRECompile [

"<rcvr primPCRECompile>, where rcvr is an object with instance variables:

	'patternStr compileFlags pcrePtr extraPtr errorStr errorOffset matchFlags'	

Compile the regular expression in patternStr, and if the compilation is successful, attempt to optimize the compiled expression.  Store the results in <pcrePtr> and <extratr>, or fill errorStr with a meaningful errorString and errorOffset with an indicator where the error was found, applying compileFlags throughout.  Answer nil with a clean compile (regardless of whether an optimization is possible, and answer with the string otherwise."


	<export: true>
	self loadRcvrFromStackAt: 0.
	patternStrPtr := self rcvrPatternStrPtr.
	compileFlags := self rcvrCompileFlags.
	interpreterProxy failed ifTrue:[^ nil].

	pcrePtr := self cCode: '(sqInt) pcre_compile(patternStrPtr, compileFlags, &errorStrBuffer, &errorOffset, NULL)'.
	pcrePtr
		ifTrue: [
			self allocateByteArrayAndSetRcvrPCREPtrFromPCRE: pcrePtr.
			extraPtr := self cCode: '(sqInt) pcre_study((pcre *)pcrePtr, compileFlags, &errorStrBuffer)'.
			self allocateByteArrayAndSetRcvrExtraPtrFrom: extraPtr.
			self rePluginFree: pcrePtr asVoidPointer.
			extraPtr ifTrue: [self rePluginFree: extraPtr asVoidPointer].
			interpreterProxy failed ifTrue:[^ nil].
			interpreterProxy pop: 1 thenPush: interpreterProxy nilObject]
		ifFalse: [
			errorStr := self allocateStringAndSetRcvrErrorStrFromCStr: errorStrBuffer.
			self rcvrErrorOffsetFrom: errorOffset.
			interpreterProxy failed ifTrue:[^ nil].
			interpreterProxy pop: 1 thenPush: errorStr].
]

{ #category : #'re primitives' }
RePlugin >> primPCREExec [

"<rcvr primPCREExec: searchObject>, where rcvr is an object with instance variables:

	'patternStr compileFlags pcrePtr extraPtr errorStr errorOffset matchFlags'	

Apply the regular expression (stored in <pcrePtr> and <extratr>, generated from calls to primPCRECompile), to smalltalk String searchObject using <matchOptions>.  If there is no match, answer nil.  Otherwise answer a ByteArray of offsets representing the results of the match."

	| searchObject searchBuffer length  result matchSpacePtr matchSpaceSize |
	<export: true>
	<var:#searchBuffer	type: 'char *'>
	<var:#matchSpacePtr	type: 'int *'>
	
	"Load Parameters"
	searchObject := interpreterProxy stackObjectValue: 0.	
	searchBuffer := interpreterProxy arrayValueOf: searchObject.
	length := interpreterProxy byteSizeOf: searchObject.
	self loadRcvrFromStackAt: 1.
	"Load Instance Variables"
	pcrePtr := self rcvrPCREBufferPtr.
	extraPtr := self rcvrExtraPtr.
	matchFlags := self rcvrMatchFlags.
	matchSpacePtr := self rcvrMatchSpacePtr.
	matchSpaceSize := self rcvrMatchSpaceSize.

	interpreterProxy failed ifTrue:[^ nil].
	
	result := self 
		cCode: 'pcre_exec((pcre *)pcrePtr, (pcre_extra *)extraPtr, 
				searchBuffer, length, 0, matchFlags, matchSpacePtr, matchSpaceSize)'.

	interpreterProxy pop: 2; pushInteger: result.

	"empty call so compiler doesn't bug me about variables not used"
	self touch: searchBuffer; touch: matchSpacePtr; touch: matchSpaceSize; touch: length

]

{ #category : #'re primitives' }
RePlugin >> primPCREExecfromto [

"<rcvr primPCREExec: searchObject from: fromInteger to: toInteger>, where rcvr is an object with instance variables:

	'patternStr compileFlags pcrePtr extraPtr errorStr errorOffset matchFlags'	

Apply the regular expression (stored in <pcrePtr> and <extratr>, generated from calls to primPCRECompile), to smalltalk String searchObject using <matchOptions>, beginning at offset <fromInteger> and continuing until offset <toInteger>.  If there is no match, answer nil.  Otherwise answer a ByteArray of offsets representing the results of the match."

	| searchObject searchBuffer length  result matchSpacePtr matchSpaceSize fromInteger toInteger |
	<export: true>
	<var:#searchBuffer	type: 'char *'>
	<var:#matchSpacePtr	type: 'int *'>
	
	"Load Parameters"
	toInteger := interpreterProxy stackIntegerValue: 0.
	fromInteger := interpreterProxy stackIntegerValue: 1.
	searchObject := interpreterProxy stackObjectValue: 2.	
	searchBuffer := interpreterProxy arrayValueOf: searchObject.
	length := interpreterProxy byteSizeOf: searchObject.
	self loadRcvrFromStackAt: 3.

	"Validate parameters"
	interpreterProxy success: (1 <= fromInteger).
	interpreterProxy success: (toInteger<=length).
	fromInteger := fromInteger - 1. "Smalltalk offsets are 1-based"
	interpreterProxy success: (fromInteger<=toInteger).

	"adjust length, searchBuffer"
	length := toInteger - fromInteger.
	searchBuffer := searchBuffer + fromInteger.

	"Load Instance Variables"
	pcrePtr := self rcvrPCREBufferPtr.
	extraPtr := self rcvrExtraPtr.
	matchFlags := self rcvrMatchFlags.
	matchSpacePtr := self rcvrMatchSpacePtr.
	matchSpaceSize := self rcvrMatchSpaceSize.
	interpreterProxy failed ifTrue:[^ nil].
	
	result := self 
		cCode: 'pcre_exec((pcre *)pcrePtr, (pcre_extra *)extraPtr, 
				searchBuffer, length, 0, matchFlags, matchSpacePtr, matchSpaceSize)'.
	interpreterProxy pop: 4; pushInteger: result.

	"empty call so compiler doesn't bug me about variables not used"
	self touch: searchBuffer; touch: matchSpacePtr; touch: matchSpaceSize; touch: length

]

{ #category : #'re primitives' }
RePlugin >> primPCRENumSubPatterns [

"<rcvr primPCRENumSubPatterns>, where rcvr is an object with instance variables:

	'patternStr compileFlags pcrePtr extraPtr errorStr errorOffset matchFlags'	

Return the number of subpatterns captured by the compiled pattern."

	<export: true>
	| ncap |
	"Load Parameters"
	self loadRcvrFromStackAt: 0.
	"Load Instance Variables"
	pcrePtr := self rcvrPCREBufferPtr.
	self cCode: 'pcre_fullinfo((const pcre *)pcrePtr, NULL, PCRE_INFO_CAPTURECOUNT, &ncap)'
		inSmalltalk: [ncap := -1].
	interpreterProxy pop: 1; pushInteger: ncap.

]

{ #category : #'rcvr linkage' }
RePlugin >> rcvrCompileFlags [

	<inline:true>
	^interpreterProxy fetchInteger: 1 ofObject: rcvr.

]

{ #category : #'rcvr linkage' }
RePlugin >> rcvrErrorOffsetFrom: anInteger [

	<inline: true>
	interpreterProxy storeInteger: 5 ofObject: rcvr withValue: anInteger.

]

{ #category : #'rcvr linkage' }
RePlugin >> rcvrErrorStrFrom: aString [

	<inline: true>
	interpreterProxy 
		storePointer: 4
		ofObject: rcvr 
		withValue: aString.

]

{ #category : #'rcvr linkage' }
RePlugin >> rcvrExtraPtr [

	|extraObj|
	<inline: true>
	extraObj := interpreterProxy fetchPointer: 3 ofObject: rcvr.
	^self 
		cCoerce: (extraObj = interpreterProxy nilObject
					ifTrue: [nil]
					ifFalse: [interpreterProxy arrayValueOf: extraObj])
		to: #sqInt
]

{ #category : #'rcvr linkage' }
RePlugin >> rcvrExtraPtrFrom: aByteArrayOrNilObject [

	<inline: true>
	interpreterProxy 
		storePointer: 3 
		ofObject: rcvr 
		withValue: aByteArrayOrNilObject
]

{ #category : #'rcvr linkage' }
RePlugin >> rcvrMatchFlags [

	<inline: true>
	^interpreterProxy fetchInteger: 6 ofObject: rcvr.

]

{ #category : #'rcvr linkage' }
RePlugin >> rcvrMatchSpacePtr [

	<inline: true>
	<returnTypeC: 'int *'>
	^self
		cCoerce: (interpreterProxy fetchArray: 7 ofObject: rcvr)
		to: 'int *'.
]

{ #category : #'rcvr linkage' }
RePlugin >> rcvrMatchSpaceSize [

	<inline: true>
	^(interpreterProxy byteSizeOf: (interpreterProxy fetchPointer: 7 ofObject: rcvr))//4.
]

{ #category : #'rcvr linkage' }
RePlugin >> rcvrPCREBufferFrom: aByteArray [

	<inline: true>
	interpreterProxy 
		storePointer: 2 
		ofObject: rcvr 
		withValue: aByteArray
]

{ #category : #'rcvr linkage' }
RePlugin >> rcvrPCREBufferPtr [
	<inline: true>
	^self
		cCoerce: (interpreterProxy fetchArray: 2 ofObject: rcvr)
		to: #sqInt
]

{ #category : #'rcvr linkage' }
RePlugin >> rcvrPatternStrPtr [

	<inline: true>
	<returnTypeC: 'char *'>
	^self 
		cCoerce: (interpreterProxy fetchArray: 0 ofObject: rcvr) 
		to: 'char *'.
]

{ #category : #'memory management' }
RePlugin >> rePluginFree: aPointer [
	"Free a block of fixed memory allocated with rePluginMalloc.  Instrumented version of C free() to facilitate leak analysis from Smalltalk.   OS-specific variations on malloc/free, such as with MacOS, are handled by adding a C macro to the header file redefining malloc/free -- see the class comment"

	<inline: true>
	<var: #aPointer type: 'void * '>
	<returnTypeC: 'void'>

	numFrees := numFrees + 1.
	aPointer notNil ifTrue: [self free: aPointer]	
]

{ #category : #'memory management' }
RePlugin >> rePluginMalloc: anInteger [
	"Allocate a block of fixed memory using C calls to malloc().  Instrumented to facilitate leak analysis from Smalltalk.  Set global lastAlloc to anInteger.  OS-specific variations on malloc/free, such as with MacOS, are handled by adding a C macro to the header file redefining malloc/free -- see the class comment"

	| aPointer |
	<inline: true>
	<var: #anInteger type: 'size_t '>
	<var: #aPointer type: 'void *'>
	<returnTypeC: 'void *'>
	numAllocs := numAllocs + 1.
	(aPointer := self malloc: anInteger) notNil ifTrue:
		[lastAlloc := anInteger].
	^aPointer

]
