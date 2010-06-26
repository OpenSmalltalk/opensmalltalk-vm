'From Squeak3.4 of 1 March 2003 [latest update: #5170] on 8 April 2003 at 11:09:18 pm'!
TestInterpreterPlugin subclass: #RePlugin
	instanceVariableNames: 'netMemory numAllocs numFrees lastAlloc patternStr rcvr compileFlags pcrePtr extraPtr errorStr errorOffset matchFlags patternStrPtr errorStrBuffer '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Werdna-Re'!
!RePlugin commentStamp: '<historical>' prior: 0!
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
#include "pcre.h"
#include "internal.h"

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
!


!RePlugin methodsFor: 're primitives' stamp: 'acg 3/12/1999 23:36'!
primPCRECompile

"<rcvr primPCRECompile>, where rcvr is an object with instance variables:

	'patternStr compileFlags pcrePtr extraPtr errorStr errorOffset matchFlags'	

Compile the regular expression in patternStr, and if the compilation is successful, attempt to optimize the compiled expression.  Store the results in <pcrePtr> and <extratr>, or fill errorStr with a meaningful errorString and errorOffset with an indicator where the error was found, applying compileFlags throughout.  Answer nil with a clean compile (regardless of whether an optimization is possible, and answer with the string otherwise."


	self export: true.
	self loadRcvrFromStackAt: 0.
	patternStrPtr _ self rcvrPatternStrPtr.
	compileFlags _ self rcvrCompileFlags.
	interpreterProxy failed ifTrue:[^ nil].

	pcrePtr _ self cCode: '(int) pcre_compile(patternStrPtr, compileFlags, 
					&errorStrBuffer, &errorOffset, NULL)'.
	pcrePtr
		ifTrue: [
			self allocateByteArrayAndSetRcvrPCREPtrFromPCRE: pcrePtr.
			extraPtr _ self cCode: '(int) pcre_study((pcre *)pcrePtr, compileFlags, &errorStrBuffer)'.
			self allocateByteArrayAndSetRcvrExtraPtrFrom: extraPtr.
			self rePluginFree: (self cCoerce: pcrePtr to: 'void *').
			extraPtr ifTrue: [self rePluginFree: (self cCoerce: extraPtr to: 'void *')].
			interpreterProxy failed ifTrue:[^ nil].
			interpreterProxy pop: 1 thenPush: interpreterProxy nilObject]
		ifFalse: [
			errorStr _ self allocateStringAndSetRcvrErrorStrFromCStr: errorStrBuffer.
			self rcvrErrorOffsetFrom: errorOffset.
			interpreterProxy failed ifTrue:[^ nil].
			interpreterProxy pop: 1 thenPush: errorStr].! !

!RePlugin methodsFor: 're primitives' stamp: 'acg 8/17/2002 16:12'!
primPCREExec

"<rcvr primPCREExec: searchObject>, where rcvr is an object with instance variables:

	'patternStr compileFlags pcrePtr extraPtr errorStr errorOffset matchFlags'	

Apply the regular expression (stored in <pcrePtr> and <extratr>, generated from calls to primPCRECompile), to smalltalk String searchObject using <matchOptions>.  If there is no match, answer nil.  Otherwise answer a ByteArray of offsets representing the results of the match."

	| searchObject searchBuffer length  result matchSpacePtr matchSpaceSize |
	self export: true.
	self var:#searchBuffer	declareC: 'char *searchBuffer'.
	self var:#matchSpacePtr	declareC: 'int *matchSpacePtr'.
	self var:#result			declareC: 'int result'.
	
	"Load Parameters"
	searchObject _ interpreterProxy stackObjectValue: 0.	
	searchBuffer _ interpreterProxy arrayValueOf: searchObject.
	length _ interpreterProxy byteSizeOf: searchObject.
	self loadRcvrFromStackAt: 1.
	"Load Instance Variables"
	pcrePtr _ self rcvrPCREBufferPtr.
	extraPtr _ self rcvrExtraPtr.
	matchFlags _ self rcvrMatchFlags.
	matchSpacePtr _ self rcvrMatchSpacePtr.
	matchSpaceSize _ self rcvrMatchSpaceSize.

	interpreterProxy failed ifTrue:[^ nil].
	
	result _ self 
		cCode: 'pcre_exec((pcre *)pcrePtr, (pcre_extra *)extraPtr, 
				searchBuffer, length, 0, matchFlags, matchSpacePtr, matchSpaceSize)'.

	interpreterProxy pop: 2; pushInteger: result.

	"empty call so compiler doesn't bug me about variables not used"
	self touch: searchBuffer; touch: matchSpacePtr; touch: matchSpaceSize; touch: length
! !

!RePlugin methodsFor: 're primitives' stamp: 'acg 8/17/2002 16:13'!
primPCREExecfromto

"<rcvr primPCREExec: searchObject> from: fromInteger to: toInteger>, where rcvr is an object with instance variables:

	'patternStr compileFlags pcrePtr extraPtr errorStr errorOffset matchFlags'	

Apply the regular expression (stored in <pcrePtr> and <extratr>, generated from calls to primPCRECompile), to smalltalk String searchObject using <matchOptions>, beginning at offset <fromInteger> and continuing until offset <toInteger>.  If there is no match, answer nil.  Otherwise answer a ByteArray of offsets representing the results of the match."

	| searchObject searchBuffer length  result matchSpacePtr matchSpaceSize fromInteger toInteger |
	self export: true.
	self var:#searchBuffer	declareC: 'char *searchBuffer'.
	self var:#fromInteger declareC: 'int fromInteger'.
	self var:#toInteger declareC: 'int toInteger'.
	self var:#matchSpacePtr	declareC: 'int *matchSpacePtr'.
	self var:#result			declareC: 'int result'.
	
	"Load Parameters"
	toInteger _ interpreterProxy stackIntegerValue: 0.
	fromInteger _ interpreterProxy stackIntegerValue: 1.
	searchObject _ interpreterProxy stackObjectValue: 2.	
	searchBuffer _ interpreterProxy arrayValueOf: searchObject.
	length _ interpreterProxy byteSizeOf: searchObject.
	self loadRcvrFromStackAt: 3.

	"Validate parameters"
	interpreterProxy success: (1 <= fromInteger).
	interpreterProxy success: (toInteger<=length).
	fromInteger _ fromInteger - 1. "Smalltalk offsets are 1-based"
	interpreterProxy success: (fromInteger<=toInteger).

	"adjust length, searchBuffer"
	length _ toInteger - fromInteger.
	searchBuffer _ searchBuffer + fromInteger.

	"Load Instance Variables"
	pcrePtr _ self rcvrPCREBufferPtr.
	extraPtr _ self rcvrExtraPtr.
	matchFlags _ self rcvrMatchFlags.
	matchSpacePtr _ self rcvrMatchSpacePtr.
	matchSpaceSize _ self rcvrMatchSpaceSize.
	interpreterProxy failed ifTrue:[^ nil].
	
	result _ self 
		cCode: 'pcre_exec((pcre *)pcrePtr, (pcre_extra *)extraPtr, 
				searchBuffer, length, 0, matchFlags, matchSpacePtr, matchSpaceSize)'.
	interpreterProxy pop: 2; pushInteger: result.

	"empty call so compiler doesn't bug me about variables not used"
	self touch: searchBuffer; touch: matchSpacePtr; touch: matchSpaceSize; touch: length
! !

!RePlugin methodsFor: 're primitives' stamp: 'acg 3/12/1999 23:32'!
primPCRENumSubPatterns

"<rcvr primPCRENumSubPatterns>, where rcvr is an object with instance variables:

	'patternStr compileFlags pcrePtr extraPtr errorStr errorOffset matchFlags'	

Return the number of subpatterns captured by the compiled pattern."

	self export: true.
	
	"Load Parameters"
	self loadRcvrFromStackAt: 0.
	"Load Instance Variables"
	pcrePtr _ self rcvrPCREBufferPtr.
	interpreterProxy pop: 1; pushInteger: (self cCode: 'pcre_info((pcre *)pcrePtr, NULL, NULL)').
! !


!RePlugin methodsFor: 'memory management' stamp: 'acg 2/25/1999 08:36'!
primLastAlloc
	
	self export: true.
	interpreterProxy pop:1; pushInteger: lastAlloc
! !

!RePlugin methodsFor: 'memory management' stamp: 'acg 2/21/1999 23:20'!
primNetMemory 
	
	self export: true.
	interpreterProxy pop:1; pushInteger: netMemory
! !

!RePlugin methodsFor: 'memory management' stamp: 'acg 2/21/1999 23:20'!
primNumAllocs

	self export: true.
	interpreterProxy pop:1; pushInteger: numAllocs
! !

!RePlugin methodsFor: 'memory management' stamp: 'acg 2/21/1999 23:20'!
primNumFrees 
	
	self export: true.
	interpreterProxy pop:1; pushInteger: numFrees
! !

!RePlugin methodsFor: 'memory management' stamp: 'acg 3/5/1999 09:18'!
rePluginFree: aPointer
	"Free a block of fixed memory allocated with rePluginMalloc.  Instrumented version of C free() to facilitate leak analysis from Smalltalk.   OS-specific variations on malloc/free, such as with MacOS, are handled by adding a C macro to the header file redefining malloc/free -- see the class comment"

	self inline: true.
	self var: #aPointer declareC: 'void * aPointer'.
	self returnTypeC: 'void'.

	numFrees _ numFrees + 1.
	(aPointer)
		ifTrue: [self cCode: 'free(aPointer)']	! !

!RePlugin methodsFor: 'memory management' stamp: 'acg 3/5/1999 09:19'!
rePluginMalloc: anInteger
	"Allocate a block of fixed memory using C calls to malloc().  Instrumented to facilitate leak analysis from Smalltalk.  Set global lastAlloc to anInteger.  OS-specific variations on malloc/free, such as with MacOS, are handled by adding a C macro to the header file redefining malloc/free -- see the class comment"

	| aPointer |
	self inline: true.
	self var: #anInteger declareC: 'size_t anInteger'.
	self var: #aPointer declareC: 'void *aPointer'.
	self returnTypeC: 'void *'.
	numAllocs _ numAllocs + 1.
	(aPointer _ self cCode: 'malloc(anInteger)')
		ifTrue: [lastAlloc _ anInteger].
	^aPointer
! !


!RePlugin methodsFor: 'rcvr linkage' stamp: 'acg 2/27/1999 23:22'!
allocateByteArrayAndSetRcvrExtraPtrFrom: anExtraPtr

	| extraObject extraByteArrayPtr |
	self var: #extraByteArrayPtr declareC: 'void *extraByteArrayPtr'.

	anExtraPtr
		ifFalse: [extraObject _ interpreterProxy nilObject]
		ifTrue: [
			"Allocate a Smalltalk ByteArray -- lastAlloc contains the length"
			extraObject _ interpreterProxy
						instantiateClass: (interpreterProxy classByteArray) 
						indexableSize: (self cCode: 'sizeof(real_pcre_extra)').
			self loadRcvrFromStackAt: 0. "Assume garbage collection after instantiation"

			"Copy from the C bytecode buffer to the Smalltalk ByteArray"
			extraByteArrayPtr _ interpreterProxy arrayValueOf: extraObject.	
			self cCode:'memcpy(extraByteArrayPtr, (void *) anExtraPtr, sizeof(real_pcre_extra))'].
 
	"Set rcvrErrorStr from errorStr and Return"
	self rcvrExtraPtrFrom: extraObject.
	self touch: extraByteArrayPtr.	
	^extraObject.
! !

!RePlugin methodsFor: 'rcvr linkage' stamp: 'acg 2/27/1999 22:57'!
allocateByteArrayAndSetRcvrPCREPtrFromPCRE: aPCREPtr

	| patObject patByteArrayPtr |
	self var: #patByteArrayPtr declareC: 'void *patByteArrayPtr'.

	"Allocate a Smalltalk ByteArray -- lastAlloc contains the length"
	patObject _ interpreterProxy
				instantiateClass: (interpreterProxy classByteArray) 
				indexableSize: lastAlloc.
	self loadRcvrFromStackAt: 0. "Assume garbage collection after instantiation"

	"Copy from the C bytecode buffer to the Smalltalk ByteArray"
	patByteArrayPtr _ interpreterProxy arrayValueOf: patObject.	
	self cCode:'memcpy(patByteArrayPtr, (void *) aPCREPtr, lastAlloc)'.
 
	"Set rcvrErrorStr from errorStr and Return"
	self rcvrPCREBufferFrom: patObject.
	self touch: patByteArrayPtr.	
	^patObject.
! !

!RePlugin methodsFor: 'rcvr linkage' stamp: 'tpr 8/17/2002 18:01'!
allocateStringAndSetRcvrErrorStrFromCStr: aCStrBuffer

	|length errorStrObj errorStrObjPtr |
	self var: #aCStrBuffer declareC: 'const char *aCStrBuffer'.
	self var: #errorStrObjPtr declareC: 'void *errorStrObjPtr'.
	"Allocate errorStrObj"
	length _ self cCode: 'strlen(aCStrBuffer)'.
	errorStrObj _ interpreterProxy
				instantiateClass: (interpreterProxy classString) 
				indexableSize: length.
	self loadRcvrFromStackAt: 0. "Assume garbage collection after instantiation"

	"Copy aCStrBuffer to errorStrObj's buffer"
	errorStrObjPtr _ interpreterProxy arrayValueOf: errorStrObj.	
	self cCode:'memcpy(errorStrObjPtr,aCStrBuffer,length)'.
	self touch: errorStrObjPtr; touch: errorStrObj.
	"Set rcvrErrorStr from errorStrObj and Return"
	self rcvrErrorStrFrom: errorStrObj.
	^errorStrObj.! !

!RePlugin methodsFor: 'rcvr linkage' stamp: 'acg 2/21/1999 22:58'!
loadRcvrFromStackAt: stackInteger

	self inline:true.
	rcvr _ interpreterProxy stackObjectValue: stackInteger.
! !

!RePlugin methodsFor: 'rcvr linkage' stamp: 'acg 2/21/1999 21:20'!
rcvrCompileFlags

	self inline:true.
	^interpreterProxy fetchInteger: 1 ofObject: rcvr.
! !

!RePlugin methodsFor: 'rcvr linkage' stamp: 'acg 2/21/1999 22:46'!
rcvrErrorOffsetFrom: anInteger

	self inline: true.
	interpreterProxy storeInteger: 5 ofObject: rcvr withValue: anInteger.
! !

!RePlugin methodsFor: 'rcvr linkage' stamp: 'acg 2/24/1999 20:53'!
rcvrErrorStrFrom: aString

	self inline: true.
	interpreterProxy 
		storePointer: 4
		ofObject: rcvr 
		withValue: aString.
! !

!RePlugin methodsFor: 'rcvr linkage' stamp: 'ikp 8/21/2002 22:40'!
rcvrExtraPtr

	|extraObj|
	self inline: true.
	extraObj _ interpreterProxy fetchPointer: 3 ofObject: rcvr.
	(extraObj = (interpreterProxy nilObject))
		ifTrue: [^ self cCode: '(int) NULL'].
	^self 
		cCoerce:(interpreterProxy arrayValueOf: extraObj)
		to: 'int'.! !

!RePlugin methodsFor: 'rcvr linkage' stamp: 'acg 2/27/1999 23:42'!
rcvrExtraPtrFrom: aByteArrayOrNilObject

	self inline: true.
	interpreterProxy 
		storePointer: 3 
		ofObject: rcvr 
		withValue: aByteArrayOrNilObject! !

!RePlugin methodsFor: 'rcvr linkage' stamp: 'acg 2/21/1999 21:19'!
rcvrMatchFlags

	self inline: true.
	^interpreterProxy fetchInteger: 6 ofObject: rcvr.
! !

!RePlugin methodsFor: 'rcvr linkage' stamp: 'acg 2/25/1999 00:49'!
rcvrMatchSpacePtr

	self inline: true.
	self returnTypeC: 'int *'.
	^self
		cCoerce: (interpreterProxy fetchArray: 7 ofObject: rcvr)
		to: 'int *'.! !

!RePlugin methodsFor: 'rcvr linkage' stamp: 'acg 2/25/1999 00:52'!
rcvrMatchSpaceSize

	self inline: true.
	^(interpreterProxy byteSizeOf: (interpreterProxy fetchPointer: 7 ofObject: rcvr))//4.! !

!RePlugin methodsFor: 'rcvr linkage' stamp: 'acg 2/24/1999 21:33'!
rcvrPCREBufferFrom: aByteArray

	self inline: true.
	interpreterProxy 
		storePointer: 2 
		ofObject: rcvr 
		withValue: aByteArray! !

!RePlugin methodsFor: 'rcvr linkage' stamp: 'acg 2/24/1999 21:33'!
rcvrPCREBufferPtr

	self inline: true.
	^self
		cCoerce: (interpreterProxy fetchArray: 2 ofObject: rcvr)
		to: 'int'.! !

!RePlugin methodsFor: 'rcvr linkage' stamp: 'acg 2/24/1999 21:34'!
rcvrPatternStrPtr

	self inline: true.
	self returnTypeC: 'char *'.
	^self 
		cCoerce: (interpreterProxy fetchArray: 0 ofObject: rcvr) 
		to: 'char *'.! !


!RePlugin methodsFor: 'private' stamp: 'acg 3/12/1999 23:32'!
touch: anOop
	"Do nothing but fool the compiler into thinking my parameter was used.  Since I am inlined, I add no overhead whatsoever."

	self inline: true.! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RePlugin class
	instanceVariableNames: ''!

!RePlugin class methodsFor: 'plugin code generation' stamp: 'tpr 8/17/2002 18:02'!
declareCVarsIn: cg

	cg addHeaderFile:'"rePlugin.h"'.

	"Memory Managament Error Checking"
	cg var: 'netMemory' 	declareC: 'int netMemory = 0'.
	cg var: 'numAllocs' 	declareC: 'int numAllocs = 0'.
	cg var: 'numFrees' 		declareC: 'int numFrees = 0'.
	cg var: 'lastAlloc'		declareC: 'int lastAlloc = 0'.

	"The receiver Object Pointer"
	cg var: 'rcvr'			declareC: 'int rcvr'.

	"Instance Variables of Receiver Object"
	cg var: 'patternStr'		declareC: 'int patternStr'.
	cg var: 'compileFlags'	declareC: 'int compileFlags'.
	cg var: 'pcrePtr'		declareC: 'int pcrePtr'.
	cg var: 'extraPtr'		declareC: 'int extraPtr'.
	cg var: 'errorStr'		declareC: 'int errorStr'.
	cg var: 'errorOffset'	declareC: 'int errorOffset'.
	cg var: 'matchFlags'	declareC: 'int matchFlags'.

	"Support Variables for Access to Receiver Instance Variables"
	cg var: 'patternStrPtr' declareC: 'const char * patternStrPtr'.
	cg var: 'errorStrBuffer'	declareC: 'const char * errorStrBuffer'.! !

!RePlugin class methodsFor: 'plugin code generation' stamp: 'acg 8/16/2002 22:51'!
hasHeaderFile
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true! !

!RePlugin class methodsFor: 'plugin code generation' stamp: 'nk 11/21/2002 15:54'!
moduleName

	^'RePlugin'! !

!RePlugin class methodsFor: 'plugin code generation' stamp: 'acg 7/27/2002 20:09'!
requiresCrossPlatformFiles
	"default is ok for most, any plugin needing cross platform files must say so"
	^true! !
