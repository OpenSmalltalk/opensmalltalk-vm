"
FileAttributesPlugin defines the named primitives used by the FileAttributes.

For information on stat(), see http://man7.org/linux/man-pages/man2/stat.2.html
For information on access(), see http://man7.org/linux/man-pages/man2/access.2.html

For information on design considerations, see FileAttributes class comments.

Public interface:

The set of primitives available to the image are located in the 'file primitives' protocol.


Return codes:

Methods called within FileAttributesPlugin will return 0 on success, or one of the codes contained in the 'errors' protocol on failure.

Public primitives should never return 0.  See each primitive for the success return types.  Failure codes are returned as an integer, or integer wrapped in an array (see FileAttributes class comments for further discussion).

"
Class {
	#name : #FileAttributesPlugin,
	#superclass : #InterpreterPlugin,
	#instVars : [
		'hasSecurityPlugin',
		'sCOFfn',
		'sCLPfn'
	],
	#category : #FileAttributesPlugin
}

{ #category : #translation }
FileAttributesPlugin class >> declareCVarsIn: cg [

	self declareC:  #('sCLPfn' 'sCOFfn')
		as: #'void *'
		in: cg.
	"Assume the security plugin can be loaded until proven otherwise"
	cg var: 'hasSecurityPlugin' declareC: 'int hasSecurityPlugin = 1'.

	cg addHeaderFile: '<errno.h>'.
	cg addHeaderFile: '<limits.h>'.
	cg addHeaderFile: '<sys/types.h>'.
	cg addHeaderFile: '<unistd.h>'.
	cg addHeaderFile: '<dirent.h>
#if _WIN32 || _WIN64
# include <windows.h>
# include <winbase.h>
# define FAIL() { return -1; }
# include "sqWin32File.h"
# if !defined(PATH_MAX) /* work around bug in 64-bit cygwin; sigh :-( */
#	define PATH_MAX 4096
# endif
# define HAVE_CHMOD 0
# define HAVE_CHOWN 0
#else
#define HAVE_CHMOD 1
#define HAVE_CHOWN 1
#endif'.
	cg addHeaderFile: '"faCommon.h"'.
	cg addHeaderFile: '<sys/stat.h>
#if !defined(HAVE_LSTAT) && !defined(_WIN32) && !defined(_WIN64)
# define HAVE_LSTAT 1
#endif'.
	cg addHeaderFile: '<unistd.h>
/* AKG 2018 - ', self moduleName, '.c translated from class ', self name, ' */'
]

{ #category : #testing }
FileAttributesPlugin class >> installedModuleVersionString [
	"Answer the version string for the plugin which is actually running in the VM"

	"self installedModuleVersionString"

	<primitive: 'primitiveVersionString' module: 'FileAttributesPlugin'>
	^ nil

]

{ #category : #translation }
FileAttributesPlugin class >> isStructType: typeName [
	^#('struct stat' 'struct dirent' 'osdir') includes: typeName
]

{ #category : #translation }
FileAttributesPlugin class >> moduleName [

	^ 'FileAttributesPlugin'
]

{ #category : #testing }
FileAttributesPlugin class >> primFileAttributeOf: pathString number: attributeNumber [
	"Answer a single file attribute.
	 pathString is the path to the file
	 attributeNumber identifies which attribute to return:
	 1 - 12: stat(): name, mode, ino, dev, nlink, uid, gid, size, accessDate, modifiedDate, changeDate, creationDate
	 13 - 15: access(): R_OK, W_OK, X_OK
	 16: isSymlink
	 On error, fail with an error code containing the appropriate OS error code."

	"(1 to: 16) collect: [:i| self primFileAttributeOf: '.' number: i]"
	"(1 to: 16) collect: [:i| self primFileAttributeOf: 'THIS HAS A GOOD CHANCE OF FAILING' number: i]"

	<primitive: 'primitiveFileAttribute' module: 'FileAttributesPlugin' error: ec>
	^self primitiveFailed
]

{ #category : #testing }
FileAttributesPlugin class >> primFileAttributes: pathString attributeNumber: attributeNumber [
	"Answer a single file attribute.
	primFileAttributes: aString attributeNumber: attributeNumber
	pathString is the path to the file
	attributeNumber identifies which attribute to return:
	1 - 12: stat(): name, mode, ino, dev, nlink, uid, gid, size, accessDate, modifiedDate, changeDate, creationDate
	13 - 15: access(): R_OK, W_OK, X_OK
	16: isSymlink
	On error, fail with an error code containing the appropriate OS error code."

	"(1 to: 16) collect: [:i| self installedFileAttributeFor: '.' numbered: i]"
	"(1 to: 16) collect: [:i| self installedFileAttributeFor: 'THIS HAS A GOOD CHANCE OF FAILING' numbered: i]"

	<primitive: 'primitiveFileAttribute' module: 'FileAttributesPlugin' error: ec>
	^self primitiveFailed
]

{ #category : #simulation }
FileAttributesPlugin class >> simulatorClass [
	^FileAttributesPluginSimulator
]

{ #category : #testing }
FileAttributesPlugin class >> versionString [
	"Answer version string for this class. If the installed module is up to date, it
	will match this version string."

	"self versionString"

	^ self new versionString

]

{ #category : #'private - directory' }
FileAttributesPlugin >> addressObjectFor: aMachineAddress [
	"Answer an ExternalAddress object which represents aMachineAddress"

	| addressOop addressOopArrayPointer addressUnion idx |
	<var: 'aMachineAddress' type: #'void *'>
	<var: 'addressUnion' type: 'union {void *address; unsigned char bytes[sizeof(void *)];}'>
	<var: 'addressOopArrayPointer' type: #'unsigned char *'>
	self touch: addressUnion.
	addressOop := interpreterProxy
		instantiateClass: interpreterProxy classByteArray
		indexableSize: self sizeOfPointer.
	addressOop ifNil:
		[^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	addressOopArrayPointer := interpreterProxy arrayValueOf: addressOop.
	self cCode: 'addressUnion.address = aMachineAddress'.
	idx := 0.
	[idx < self sizeOfPointer] whileTrue:
		[self cCode: 'addressOopArrayPointer[idx] = addressUnion.bytes[idx]'.
		idx := idx + 1].
	^ addressOop

]

{ #category : #private }
FileAttributesPlugin >> attributeArray: attributeArrayPtr for: faPath mask: attributeMask [
	"Create the attributes array for the specified file (faPath) and set attributeArrayPtr.
	Which attributes are retrieved are specified in attributeMask.
	On error, set the error in interpreterProxy and answer the appropriate status (some callers check the status, others interpreterProxy)"

	| status getAccess getStats getLinkStats attributeArray accessArray resultOop  |
	<var: 'faPath' type: #'fapath *'>
	<var: 'attributeArrayPtr' type: #'sqInt *'>

	"Determine which attributes to retrieve"
	getStats := attributeMask anyMask: 1.
	getAccess := attributeMask anyMask: 2.
	(getStats or: [getAccess]) ifFalse:
		["No information has been requested, which doesn't make sense"
		interpreterProxy primitiveFailForOSError: self invalidArguments.
		^self invalidArguments].
	getLinkStats := attributeMask anyMask: 4.

	getStats ifTrue:
		[ attributeArray := interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: 13.
		attributeArray ifNil:
			[interpreterProxy primitiveFailFor: PrimErrNoMemory.
			^self interpreterError].
		self remapOop: attributeArray in:
			[status := self faFileStatAttributes: faPath _: getLinkStats _: attributeArray].
		status ~= 0 ifTrue:
			[^status].
		"Set resultOop in case only stat attributes have been requested"
		resultOop := attributeArray ].

	getAccess ifTrue:
		[self remapOop: attributeArray in:
			[accessArray := interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: 3].
		accessArray ifNil:
			[interpreterProxy primitiveFailFor: PrimErrNoMemory.
			self interpreterError].
		self faAccessAttributes: faPath _: accessArray _: 0.
		interpreterProxy failed ifTrue: 
			[^self interpreterError].
		"Set resultOop in case only access attributes have been requested"
		resultOop := accessArray ].

	(getStats and: [getAccess]) ifTrue: 
		[self remapOop: #(attributeArray accessArray) in:
			[resultOop := interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: 2].
		resultOop ifNil:
			[interpreterProxy primitiveFailFor: PrimErrNoMemory.
			self interpreterError].
		interpreterProxy
			storePointer: 0 ofObject: resultOop withValue: attributeArray;
			storePointer: 1 ofObject: resultOop withValue: accessArray
		].

	attributeArrayPtr at: 0 put: resultOop.
	^self faSuccess
]

{ #category : #'errors / status' }
FileAttributesPlugin >> badSessionId [
	"The supplied session Id doesn't match the current VM session Id"
	
	^-17
]

{ #category : #'private - directory' }
FileAttributesPlugin >> canOpenDirectoryStreamFor: aPathCString length: length [
	"Answer non-zero if security permits the directory to be listed."

	"FIXME: This function has not been tested. -dtl"

	<var: 'aPathCString' type: #'char *'>
	"If the security plugin can be loaded, use it to check . 
	If not, assume it's ok"
	"The hasSecurityPlugin flag is set to 1 by default"
	(hasSecurityPlugin = 0) ifTrue: [^ true].
	sCLPfn ~= 0
		ifTrue:
			[^ self cCode: ' ((int (*) (char *, int)) sCLPfn)(aPathCString, length)'
				inSmalltalk: [true]]
		ifFalse:
			[hasSecurityPlugin := 0.	"Reset the flag so we do not try again next time"
			^ true]

]

{ #category : #'private - file' }
FileAttributesPlugin >> canStatFilePath: aPathCString length: length [
	"Answer non-zero if security permits the a stat() call on the file path. Allow a
	stat() call only on files which we are permitted to open."

	"FIXME: This function has not been tested. -dtl"

	<var: 'aPathCString' type: #'char *'>
	"If the security plugin can be loaded, use it to check . 
	If not, assume it's ok"
	"The hasSecurityPlugin flag is set to 1 by default"
	(hasSecurityPlugin = 0) ifTrue: [^ true].
	sCOFfn ~= 0
		ifTrue:
			[^ self cCode: ' ((int (*) (char *, int, int)) sCOFfn)(aPathCString, length, 0)'
				inSmalltalk: [true]]
		ifFalse: 
			[hasSecurityPlugin := 0.	"Reset the flag so we do not try again next time"
			^ true]

]

{ #category : #'errors / status' }
FileAttributesPlugin >> cantAllocateMemory [
	<inline: #always>
	^-10
]

{ #category : #'errors / status' }
FileAttributesPlugin >> cantOpenDir [
	<inline: #always>
	^-9
]

{ #category : #'errors / status' }
FileAttributesPlugin >> cantReadlink [
	<inline: #always>
	^-8
]

{ #category : #'errors / status' }
FileAttributesPlugin >> cantStatPath [
	"SecurityPlugin determined that the requested path cannot be accessed."
	<inline: #always>
	^-3
]

{ #category : #'private - windows' }
FileAttributesPlugin >> convertWinToSqueakTime: st [
	"Convert the supplied Windows SYSTEMTIME to Squeak time"
	<option: #_WIN32>

	| dy secs nDaysPerMonth |

	<returnTypeC: #'sqLong'>
	<var: 'st' type: #'SYSTEMTIME'>
	<var: 'dy' type: #'sqLong'>
	<var: 'secs' type: #'sqLong'>
	<var: 'nDaysPerMonth' declareC: 'static sqLong nDaysPerMonth[14] = { 
		0,  0,  31,  59,  90, 120, 151,
		181, 212, 243, 273, 304, 334, 365 }'>
	self touch: nDaysPerMonth.

	"Squeak epoch is Jan 1, 1901"
	"compute delta year"
	dy := (self cCode: 'st.wYear') - 1901.
	secs := (dy * 365 * 24 * 60 * 60)       "base seconds"
			+ ((dy bitShift: -2) * 24 * 60 * 60).   "seconds of leap years"
	"check if month > 2 and current year is a leap year"
	[ (self cCode: 'st.wMonth') > 2 and: [ (dy bitAnd: 16r0003) = 16r0003 ]] ifTrue: [
		"add one day"
		secs := secs + (24 * 60 * 60) ].
	"add the days from the beginning of the year"
	secs := secs + (self cCode: '(nDaysPerMonth[st.wMonth] + st.wDay - 1) * 24 * 60 * 60').
	"add the hours, minutes, and seconds"
	secs := secs + (self cCode: 'st.wSecond + 60*(st.wMinute + 60*st.wHour)').
	^secs

]

{ #category : #'errors / status' }
FileAttributesPlugin >> corruptValue [
	<inline: #always>
	^-7
]

{ #category : #private }
FileAttributesPlugin >> faPathMax [
	"Answer the value of the platform support's definition of FA_PATH_MAX, defined in
	 platforms/{unix.win32,etc}/plugins/FileAttributesPlugin/faSupport.h"
	<inline: #always>
	^#FA_PATH_MAX
]

{ #category : #'errors / status' }
FileAttributesPlugin >> faSuccess [

	^0
]

{ #category : #'private - file' }
FileAttributesPlugin >> fileExecutableFlag [
	<inline: #always>
	^ self cCode: [#X_OK] inSmalltalk: [1]
]

{ #category : #'private - file' }
FileAttributesPlugin >> fileOKFlag [
	<inline: #always>
	^ self cCode: [#F_OK] inSmalltalk: [0]
]

{ #category : #'private - file' }
FileAttributesPlugin >> fileReadableFlag [
	<inline: #always>
	^ self cCode: [#R_OK] inSmalltalk: [4]
]

{ #category : #'private - file' }
FileAttributesPlugin >> fileWriteableFlag [
	<inline: #always>
	^ self cCode: [#W_OK] inSmalltalk: [2]
]

{ #category : #'errors / status' }
FileAttributesPlugin >> getAttributesFailed [
	<inline: #always>
	^-4
]

{ #category : #'initialize-release' }
FileAttributesPlugin >> initialiseModule [
	<export: true>

	sCOFfn := interpreterProxy ioLoadFunction: 'secCanOpenFileOfSizeWritable' From: 'SecurityPlugin'.
	sCLPfn := interpreterProxy ioLoadFunction: 'secCanListPathOfSize' From: 'SecurityPlugin'.
	^true
]

{ #category : #'errors / status' }
FileAttributesPlugin >> interpreterError [
	"The actual error code is stored by the interpreterProxy"
	<inline: #always>
	^-15
]

{ #category : #'errors / status' }
FileAttributesPlugin >> invalidArguments [
	<inline: #always>
	^-6
]

{ #category : #'errors / status' }
FileAttributesPlugin >> invalidRequest [
	<inline: #always>
	^-11
]

{ #category : #'errors / status' }
FileAttributesPlugin >> noMoreData [
	<inline: #always>
	^1
]

{ #category : #'private - directory' }
FileAttributesPlugin >> objectFromStruct: aMachineAddress size: structSize [
	"Answer a ByteArray object which copies the structure at aMachineAddress"

	| addressOop addressOopArrayPointer |
	<var: 'aMachineAddress' type: #'void *'>
	<var: 'addressOopArrayPointer' type: #'unsigned char *'>

	addressOop := interpreterProxy
		instantiateClass: interpreterProxy classByteArray
		indexableSize: structSize.
	addressOop ifNil:
		[^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	addressOopArrayPointer := interpreterProxy arrayValueOf: addressOop.
	self memcpy: addressOopArrayPointer _: aMachineAddress _: structSize.
	^ addressOop

]

{ #category : #'private - file' }
FileAttributesPlugin >> pathOop: pathNameOop toBuffer: cPathName maxLen: maxLen [
	"Copy the supplied path name string object to the supplied c string buffer"

	| len sPtr |
	<var: 'cPathName' type: #'char *'>
	<var: 'sPtr' type: #'char *'>
	<returnTypeC: #'int'>

	len := interpreterProxy stSizeOf: pathNameOop.
	(len >= maxLen) ifTrue: [^self stringTooLong].
	"Copy pathName to the new string"
	sPtr := interpreterProxy arrayValueOf: pathNameOop.
	((self canStatFilePath: sPtr length: len) = 0) ifTrue: [^self cantStatPath].
	self memcpy: cPathName _: sPtr _: len.
	cPathName at: len put: 0.
	^0.

]

{ #category : #'private - directory' }
FileAttributesPlugin >> pointerFrom: directoryPointerBytes [
	"Answer the machine address contained in anExternalAddressOop."

	| ptr addressUnion idx |
	<returnTypeC: #'void *'>
	<var: 'ptr' type: #'unsigned char *'>
	<var: 'addressUnion' type: 'union {void *address; unsigned char bytes[sizeof(void *)];}'>
	((interpreterProxy is: directoryPointerBytes KindOf: 'ByteArray') and:
		[(interpreterProxy stSizeOf: directoryPointerBytes) = self sizeOfPointer])
		ifFalse: [^ nil].
	ptr := interpreterProxy arrayValueOf: directoryPointerBytes.
	idx := 0.
	[idx < self sizeOfPointer] whileTrue:
		[self cCode: 'addressUnion.bytes[idx] = ptr[idx]'.
		idx := idx + 1].
	^ self cCode: 'addressUnion.address' inSmalltalk: [addressUnion]

]

{ #category : #'file primitives' }
FileAttributesPlugin >> primitiveChangeMode [
	"Set the mode of the supplied file using chmod()."

	| fileNameOop newMode status faPath |
	<export: true>
	<var: 'newMode' type: #'sqInt'>
	<var: 'faPath' type: #'fapath'>

	fileNameOop := interpreterProxy stackObjectValue: 1.
	newMode := interpreterProxy stackIntegerValue: 0.
	(interpreterProxy failed
		or: [(interpreterProxy isBytes: fileNameOop) not]) ifTrue:
			[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self cppIf: #HAVE_CHMOD ifTrue: [
		self cCode: '' inSmalltalk: [faPath := self simulatedFaPath].
		self faSetStPathOop: (self addressOf: faPath) _: fileNameOop.
		interpreterProxy failed ifTrue:
			[^interpreterProxy primitiveFailureCode].

		status := self chmod: (self faGetPlatPath: (self addressOf: faPath)) _: newMode.
		status ~= 0 ifTrue: 
			[^interpreterProxy primitiveFailForOSError: (self cCode: 'errno')].
		^interpreterProxy methodReturnValue: interpreterProxy nilObject.
		].
	^interpreterProxy primitiveFailForOSError: self unsupportedOperation.

]

{ #category : #'file primitives' }
FileAttributesPlugin >> primitiveChangeOwner [
	"Set the owner of the supplied file using chown()."

	| fileNameOop ownerId groupId faPath status |
	<export: true>
	<var: 'faPath' type: #'fapath'>

	fileNameOop := interpreterProxy stackObjectValue: 2.
	ownerId := interpreterProxy stackIntegerValue: 1.
	groupId := interpreterProxy stackIntegerValue: 0.
	(interpreterProxy failed
		or: [(interpreterProxy isBytes: fileNameOop) not]) ifTrue:
			[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self cppIf: #HAVE_CHOWN ifTrue: [
		self cCode: '' inSmalltalk: [faPath := self simulatedFaPath].
		self faSetStPathOop: (self addressOf: faPath) _: fileNameOop.
		interpreterProxy failed ifTrue: 
			[^interpreterProxy primitiveFailureCode].

		status := self chown: (self faGetPlatPath: (self addressOf: faPath)) _: ownerId _: groupId.
		status ~= 0 ifTrue: 
			[^interpreterProxy primitiveFailForOSError: (self cCode: 'errno')].
		^interpreterProxy methodReturnValue: interpreterProxy nilObject.
		].
	^interpreterProxy primitiveFailForOSError: self unsupportedOperation.

]

{ #category : #'file primitives' }
FileAttributesPlugin >> primitiveClosedir [
	"Close the directory stream for dirPointerOop. Answer dirPointerOop on success.
	Raise PrimErrBadArgument if the parameter is not a ByteArray length size(void *).
	If closedir() returns an error raise PrimitiveOSError."

	| dirPointerOop faPathPtr faPath result |
	<export: true>
	<var: 'faPath' type: #'fapath *'>
	<var: 'faPathPtr' type: #'FAPathPtr *'>

	dirPointerOop := interpreterProxy stackValue: 0.
	faPathPtr := self structFromObject: dirPointerOop 
		size: (self cCode: 'sizeof(FAPathPtr)' inSmalltalk: [self sizeOfFaPathPtr]).
	faPathPtr = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self cCode: '' inSmalltalk: [faPathPtr := FAPathPtr fromArray: faPathPtr plugin: self].
	(self faValidateSessionId: faPathPtr sessionId) ifFalse:
		[^interpreterProxy primitiveFailForOSError: self badSessionId].
	faPath := faPathPtr faPath.

	result := self faCloseDirectory: faPath.
	self faInvalidateSessionId: (self cCode: '&faPathPtr->sessionId' inSmalltalk: [faPathPtr]).
	result = 0 ifFalse:
		[^interpreterProxy primitiveFailForOSError: result].
	self free: faPath.
	interpreterProxy methodReturnValue: dirPointerOop
]

{ #category : #'file primitives' }
FileAttributesPlugin >> primitiveFileAttribute [
	"Answer a single file attribute.
	primFileAttributes: aString attributeNumber: attributeNumber
	aString is the path to the file
	attributeNumber identifies which attribute to return:
	1 - 12: stat(): name, mode, ino, dev, nlink, uid, gid, size, accessDate, modifiedDate, changeDate, creationDate
	13 - 15: access(): R_OK, W_OK, X_OK
	16: isSymlink
	On error, answer a single element array containing the appropriate error code."

	| fileName attributeNumber resultOop faPath |
	<export: true>
	<var: 'faPath' type: #'fapath'>

	fileName := interpreterProxy stackObjectValue: 1.
	attributeNumber := interpreterProxy stackIntegerValue: 0.
	(interpreterProxy failed
		or: [(attributeNumber between: 1 and: 16) not
		or: [(interpreterProxy isBytes: fileName) not]]) ifTrue:
			[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	self cCode: '' inSmalltalk: [faPath := self simulatedFaPath].
	self faSetStPathOop: (self addressOf: faPath) _: fileName.
	interpreterProxy failed ifTrue: 
		[^interpreterProxy primitiveFailureCode].

	resultOop := self faFileAttribute: (self addressOf: faPath) _: attributeNumber.
	interpreterProxy failed ifTrue: 
		[^interpreterProxy primitiveFailureCode].

	resultOop = 0
		ifTrue: ["It shouldn't be possible to get here"
			interpreterProxy primitiveFailForOSError: self unexpectedError]
		ifFalse: [interpreterProxy methodReturnValue: resultOop]
]

{ #category : #'file primitives' }
FileAttributesPlugin >> primitiveFileAttributes [
	"Answer an array of file attributes.
	primFileAttributes: aString mask: attributeMask
	aString is the path to the file
	attributeMask indicates which attributes to retrieve:
	bit 0 - get stat() attributes
	bit 1 - get access() attributes
	bit 2 - use lstat() instead of stat()
	On error answer the appropriate error code (Integer)"

	| fileName attributeMask faPath status resultOop  |
	<export: true>
	<var: 'faPath' type: #'fapath'>

	fileName := interpreterProxy stackObjectValue: 1.
	attributeMask := interpreterProxy stackIntegerValue: 0.
	(interpreterProxy failed
	or: [(interpreterProxy isBytes: fileName) not]) ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	self cCode: '' inSmalltalk: [faPath := self simulatedFaPath].
	self faSetStPathOop: (self addressOf: faPath) _: fileName.
	interpreterProxy failed ifTrue: 
		[^interpreterProxy primitiveFailureCode].

	status := self attributeArray: (self addressOf: resultOop put: [ :val | resultOop := val]) 
					for: (self addressOf: faPath) 
					mask: attributeMask.
	status ~= 0 ifTrue:
		[^interpreterProxy primitiveFailForOSError: status].
	^interpreterProxy methodReturnValue: resultOop
]

{ #category : #'file primitives' }
FileAttributesPlugin >> primitiveFileExists [
	"Check for existence of a file with a call to access(), or the appropriate platform function."

	<export: true>
	| fileNameOop faPath |
	<var: 'faPath' type: #'fapath'>

	self cCode: '' inSmalltalk: [faPath := self simulatedFaPath].
	fileNameOop := interpreterProxy stackValue: 0.
	(interpreterProxy isBytes: fileNameOop) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	self faSetStPathOop: (self addressOf: faPath) _: fileNameOop.
	interpreterProxy failed ifFalse:
		[^interpreterProxy methodReturnBool: (self faExists: (self addressOf: faPath))]
]

{ #category : #'file primitives' }
FileAttributesPlugin >> primitiveFileMasks [
	"Answer an array of well known file masks"

	| masks |
	<export: true>
	masks := interpreterProxy instantiateClass: (interpreterProxy classArray) indexableSize: 8.
	masks ifNil: [^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	interpreterProxy
		storePointer: 0
		ofObject: masks
		withValue: (interpreterProxy positive32BitIntegerFor: (self cCode: [#S_IFMT] inSmalltalk: [16rF000])).
	self cppIf: #_WIN32 defined not
		ifTrue: [
			interpreterProxy
				storePointer: 1
				ofObject: masks
				withValue: (interpreterProxy positive32BitIntegerFor: (self cCode: [#S_IFSOCK] inSmalltalk: [16rC000])).
			interpreterProxy
				storePointer: 2
				ofObject: masks
				withValue: (interpreterProxy positive32BitIntegerFor: (self cCode: [#S_IFLNK] inSmalltalk: [16rA000]))].
	interpreterProxy
		storePointer: 3
		ofObject: masks
		withValue: (interpreterProxy positive32BitIntegerFor: (self cCode: [#S_IFREG] inSmalltalk: [16r8000])).
	interpreterProxy
		storePointer: 4
		ofObject: masks
		withValue: (interpreterProxy positive32BitIntegerFor: (self cCode: [#S_IFBLK] inSmalltalk: [16r6000])).
	interpreterProxy
		storePointer: 5
		ofObject: masks
		withValue: (interpreterProxy positive32BitIntegerFor: (self cCode: [#S_IFDIR] inSmalltalk: [16r4000])).
	interpreterProxy
		storePointer: 6
		ofObject: masks
		withValue: (interpreterProxy positive32BitIntegerFor: (self cCode: [#S_IFCHR] inSmalltalk: [16r2000])).
	interpreterProxy
		storePointer: 7
		ofObject: masks
		withValue: (interpreterProxy positive32BitIntegerFor: (self cCode: [#S_IFIFO] inSmalltalk: [16r1000])).
	interpreterProxy pop: 1 thenPush: masks
]

{ #category : #'file primitives' }
FileAttributesPlugin >> primitiveLogicalDrives [
	"Answer the logical drive mask on windows"

	| mask |
	<export: true>
	<var: 'mask' type: #'unsigned int'>
	self cppIf: #_WIN32 defined
		ifTrue:
			[
			 mask := self GetLogicalDrives.
			 mask ~= 0 ifTrue:
				[^interpreterProxy pop: 1 thenPush: (interpreterProxy positive32BitIntegerFor: mask)]].
	interpreterProxy primitiveFail
]

{ #category : #'file primitives' }
FileAttributesPlugin >> primitiveOpendir [
	"Open the supplied directory and answer the first entry and directory pointer.
	If the directory is empty, answer nil as the first entry.
	If the directory can't be opened, answer an error (cantOpenDir)"
	"self primOpendir: '/etc'"

	| dirName faPath faPathPtr dirOop status resultOop |
	<export: true>
	<var: 'faPath' type: #'fapath *'>
	<var: 'faPathPtr' type: #'FAPathPtr'>
	"Process the parameters"
	dirName := interpreterProxy stackObjectValue: 0.
	(interpreterProxy isBytes: dirName) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	"Allocate and initialise faPath"
	faPath := self cCode: '(fapath *) calloc(1, sizeof(fapath))'
				inSmalltalk: [self simulatedFaPath].
	faPath = nil ifTrue: [^interpreterProxy primitiveFailForOSError: self cantAllocateMemory].
	self faSetStDirOop: faPath _: dirName.
	interpreterProxy failed ifTrue: [^interpreterProxy primitiveFailureCode].

	(self canOpenDirectoryStreamFor: (self faGetStPath: faPath) length: (self faGetStPathLen: faPath)) ifFalse: [
		self free: faPath.
		^interpreterProxy primitiveFailForOSError: self cantOpenDir].

	"Open the directory and process the first entry"
	status := self faOpenDirectory: faPath.
	status = self noMoreData ifTrue: [
		self free: faPath.
		^interpreterProxy methodReturnValue: interpreterProxy nilObject].
	status < 0 ifTrue: [
		self free: faPath.
		^interpreterProxy primitiveFailForOSError: status].
	resultOop := self processDirectory: faPath.
	interpreterProxy failed ifTrue: [
		self free: faPath.
		^interpreterProxy primitiveFailureCode ].

	"Set the faPathPtr"
	self cCode: '' inSmalltalk: [faPathPtr := FAPathPtr plugin: self].
	self faInitSessionId: (self cCode: '&faPathPtr.sessionId' inSmalltalk: [faPathPtr]).
	faPathPtr faPath: faPath.
	self remapOop: resultOop in:
		[ dirOop := self objectFromStruct: (self addressOf: faPathPtr) size: self sizeOfFaPathPtr ].

	^interpreterProxy 
		storePointer: 2 ofObject: resultOop withValue: dirOop;
		methodReturnValue: resultOop.
]

{ #category : #'file primitives' }
FileAttributesPlugin >> primitivePathMax [
	"Answer the value of FA_PATH_MAX (PATH_MAX) for the current VM"

	<export: true>
	^interpreterProxy methodReturnInteger: self faPathMax
]

{ #category : #'file primitives' }
FileAttributesPlugin >> primitivePlatToStPath [
	"Convert the supplied file name (platform encoded) to the St UTF8 encoded byte array"

	| fileName faPath resultOop byteArrayPtr |
	<export: true>
	<var: 'faPath' type: #'fapath'>
	<var: 'byteArrayPtr' type: #'unsigned char *'>

	fileName := interpreterProxy stackObjectValue: 0.
	(interpreterProxy failed
		or: [(interpreterProxy isBytes: fileName) not]) ifTrue:
			[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	self cCode: '' inSmalltalk: [faPath := self simulatedFaPath].
	self faSetPlatPathOop: (self addressOf: faPath) _: fileName.
	interpreterProxy failed ifTrue: 
		[^interpreterProxy primitiveFailureCode].

	resultOop := interpreterProxy
		instantiateClass: interpreterProxy classByteArray
		indexableSize: (self faGetStPathLen: (self addressOf: faPath)).
	resultOop ifNil: [^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	byteArrayPtr := interpreterProxy arrayValueOf: resultOop.
	self memcpy: byteArrayPtr 
		_: (self faGetStPath: (self addressOf: faPath)) 
		_: (self faGetStPathLen: (self addressOf: faPath)).

	^interpreterProxy methodReturnValue: resultOop.

]

{ #category : #'file primitives' }
FileAttributesPlugin >> primitiveReaddir [
	"Get the next entry in the directory stream. Answer the name of the entry, or
	nil for the end of the directory stream.
	Arguments:
	- directoryPointer (ByteArray)"

	| dirPointerOop faPathPtr faPath resultArray status |
	<export: true>
	<var: 'faPath' type: #'fapath *'>
	<var: 'faPathPtr' type: #'FAPathPtr *'>
	dirPointerOop := interpreterProxy stackValue: 0.
	faPathPtr := self structFromObject: dirPointerOop 
		size: (self cCode: 'sizeof(FAPathPtr)' inSmalltalk: [self sizeOfFaPathPtr]).
	faPathPtr = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self cCode: '' inSmalltalk: [faPathPtr := FAPathPtr fromArray: faPathPtr plugin: self].
	(self faValidateSessionId: faPathPtr sessionId) ifFalse:
		[^interpreterProxy primitiveFailForOSError: self badSessionId].
	faPath := faPathPtr faPath.

	status := self faReadDirectory: faPath.
	status = self noMoreData ifTrue:
		[^interpreterProxy methodReturnValue: interpreterProxy nilObject].
	status < 0 ifTrue:
		[^interpreterProxy primitiveFailForOSError: status].
	resultArray := self processDirectory: faPath.
	"no need to check the status of #processDirectory: as it will have flagged an error with interpreterProxy"
	^interpreterProxy methodReturnValue: resultArray.

]

{ #category : #'file primitives' }
FileAttributesPlugin >> primitiveRewinddir [
	"Set directoryStream to first entry. Answer dirPointerOop."

	| dirPointerOop faPathPtr faPath status resultOop |
	<export: true>
	<var: 'faPath' type: #'fapath *'>
	<var: 'faPathPtr' type: #'FAPathPtr *'>

	dirPointerOop := interpreterProxy stackValue: 0.
	faPathPtr := self structFromObject: dirPointerOop 
		size: (self cCode: 'sizeof(FAPathPtr)' inSmalltalk: [self sizeOfFaPathPtr]).
	faPathPtr = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self cCode: '' inSmalltalk: [faPathPtr := FAPathPtr fromArray: faPathPtr plugin: self].
	(self faValidateSessionId: faPathPtr sessionId) ifFalse:
		[^interpreterProxy primitiveFailForOSError: self badSessionId].
	faPath := faPathPtr faPath.

	status := self faRewindDirectory: faPath.
	status < 0 ifTrue: 
		[^interpreterProxy primitiveFailForOSError: status].
	resultOop := self processDirectory: faPath.
	"no need to check the status of #processDirectory: as it will have flagged an error with interpreterProxy"
	^interpreterProxy methodReturnValue: resultOop.
]

{ #category : #'file primitives' }
FileAttributesPlugin >> primitiveStToPlatPath [
	"Convert the supplied file name (UTF8 encoded) to the platform encoded byte array"

	| fileName faPath resultOop byteArrayPtr |
	<export: true>
	<var: 'faPath' type: #'fapath'>
	<var: 'byteArrayPtr' type: #'unsigned char *'>

	fileName := interpreterProxy stackObjectValue: 0.
	(interpreterProxy failed
		or: [(interpreterProxy isBytes: fileName) not]) ifTrue:
			[^interpreterProxy primitiveFailFor: PrimErrBadArgument].

	self cCode: '' inSmalltalk: [faPath := self simulatedFaPath].
	self faSetStPathOop: (self addressOf: faPath) _: fileName.
	interpreterProxy failed ifTrue: 
		[^interpreterProxy primitiveFailureCode].

	resultOop := interpreterProxy
		instantiateClass: interpreterProxy classByteArray
		indexableSize: (self faGetPlatPathByteCount: (self addressOf: faPath)).
	resultOop ifNil: [^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	byteArrayPtr := interpreterProxy arrayValueOf: resultOop.
	self memcpy: byteArrayPtr 
		_: (self faGetPlatPath: (self addressOf: faPath)) 
		_: (self faGetPlatPathByteCount: (self addressOf: faPath)).

	^interpreterProxy methodReturnValue: resultOop.

]

{ #category : #'file primitives' }
FileAttributesPlugin >> primitiveSymlinkChangeOwner [
	"Set the owner of the supplied file using chown()."

	| fileNameOop ownerId groupId faPath status |
	<export: true>
	<var: 'faPath' type: #'fapath'>

	fileNameOop := interpreterProxy stackObjectValue: 2.
	ownerId := interpreterProxy stackIntegerValue: 1.
	groupId := interpreterProxy stackIntegerValue: 0.
	(interpreterProxy failed
		or: [(interpreterProxy isBytes: fileNameOop) not]) ifTrue:
			[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	self cppIf: #HAVE_CHOWN ifTrue: [
		self cCode: '' inSmalltalk: [faPath := self simulatedFaPath].
		self faSetStPathOop: (self addressOf: faPath) _: fileNameOop.
		interpreterProxy failed ifTrue: [^interpreterProxy primitiveFailureCode].

		status := self lchown: (self faGetPlatPath: (self addressOf: faPath)) _: ownerId _: groupId.
		status ~= 0 ifTrue:
			[^interpreterProxy primitiveFailForOSError: (self cCode: 'errno')].
		^interpreterProxy methodReturnValue: interpreterProxy nilObject.
		].
	^interpreterProxy primitiveFailForOSError: self unsupportedOperation.

]

{ #category : #'file primitives' }
FileAttributesPlugin >> primitiveVersionString [
	"Answer a string containing the version string for this plugin."

	<export: true>
	interpreterProxy pop: 1 thenPush: (self stringFromCString: self versionString)

]

{ #category : #private }
FileAttributesPlugin >> processDirectory: faPath [
	"The supplied faPath contains the full path to the current entry while iterating over a directory.
	Convert the file name to an object, get the attributes and answer the resulting array."

	| status entryName attributeArray resultArray |
	<var: 'faPath' type: #'fapath *'>

	status := self faCharToByteArray: (self faGetStFile: faPath) 
				_: (self addressOf: entryName put: [:val | entryName := val]).
	status ~= 0 ifTrue:
		[ ^interpreterProxy primitiveFailForOSError: status].

	status := self attributeArray: (self addressOf: attributeArray put: [ :val | attributeArray := val ]) for: faPath mask: 1.
	"If the stat() fails, still return the filename, just no attributes"
	status ~= 0 ifTrue:
		[status = self cantStatPath ifTrue:	
			[attributeArray := interpreterProxy nilObject]
		ifFalse:
			[^interpreterProxy primitiveFailForOSError: status]].

	"resultArray: entryName, attributeArray, dirPtrOop"
	self remapOop: #(entryName attributeArray)
		in: [resultArray := interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: 3].
	resultArray ifNil:
		[^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	interpreterProxy
		storePointer: 0 ofObject: resultArray withValue: entryName;
		storePointer: 1 ofObject: resultArray withValue: attributeArray.
	^resultArray
]

{ #category : #'private - file' }
FileAttributesPlugin >> readLink: cPathName into: cLinkPtr maxLength: maxLength [
	"Get the target filename of the supplied symbolic link."

	| len |
	<var: 'cPathName' type: #'char *'>
	<var: 'cLinkPtr' type: #'char *'>
	<var: 'maxLength' type: #'size_t'>
	<var: 'len' type: #sqInt> "len must be signed so that -1 can be communicated as an error."

	len := self cppIf: #_WIN32 defined
				ifTrue: [-1]
				ifFalse: [self read: cPathName li: cLinkPtr nk: maxLength].
	len < 0 ifTrue:
		[self cppIf: #'INDEBUG' defined ifTrue: 
			[self cCode: 'fprintf(stderr, "FileAttributesPlugin: unable to readlink(): %d, errno=%d\n", len, errno)'].
		^self cantReadlink].
	cLinkPtr at: len put: 0.
	^len
]

{ #category : #private }
FileAttributesPlugin >> sizeOfFaPath [
	"Answer the size of fapath"

	^self cCode: 'sizeof(fapath)'
			inSmalltalk: [6].
]

{ #category : #private }
FileAttributesPlugin >> sizeOfFaPathPtr [
	"Answer the size of fapathptr.
	The simulation uses a two element array."

	^self cCode: 'sizeof(FAPathPtr)'
			inSmalltalk: [2].
]

{ #category : #'private - directory' }
FileAttributesPlugin >> sizeOfPointer [
	"Size of a C pointer on this machine"
	<inline: #always>
	^self sizeof: #'void *'
]

{ #category : #'errors / status' }
FileAttributesPlugin >> statFailed [
	"A call to stat() failed"
	<inline: #always>
	^-2
]

{ #category : #private }
FileAttributesPlugin >> stringFromCString: aCString [
	"Answer a new String copied from a null-terminated C string.
	Caution: This may invoke the garbage collector."

	| len newString |
	<var: 'aCString' type: #'const char *'>
	len := self strlen: aCString.
	newString := interpreterProxy
		instantiateClass: interpreterProxy classString
		indexableSize: len.
	newString ifNil: [^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	self strncpy: (interpreterProxy arrayValueOf: newString)
		_: aCString
		_: len. "(char *)strncpy()"
	^ newString

]

{ #category : #'errors / status' }
FileAttributesPlugin >> stringTooLong [
	"String too long.  A file path name was longer than PATH_MAX"
	<inline: #always>
	^-1
]

{ #category : #'private - directory' }
FileAttributesPlugin >> structFromObject: anObject size: structSize [
	"Allocate memory of the requiested size and copy the contents of anObject in to it.
	anObject is expected to be bytes, e.g. ByteArray or String.
	The structure is allocated on the stack using alloca(), thus this method must always be inlined so that the memory is valid in the calling method."

	| buffer |
	<inline: #always>
	<returnTypeC: #'void *'>
	<var: 'buffer' type: #'void *'>

	(interpreterProxy stSizeOf: anObject) = structSize ifFalse:
		[interpreterProxy primitiveFailFor: PrimErrBadArgument.
		^0].
	buffer := self alloca: structSize.
	buffer = 0 ifTrue:
		[interpreterProxy primitiveFailFor: PrimErrNoCMemory]
	ifFalse:
		[self memcpy: buffer
			_: (interpreterProxy arrayValueOf: anObject)
			_: structSize].
	^buffer
]

{ #category : #'errors / status' }
FileAttributesPlugin >> timeConversionFailed [
	<inline: #always>
	^-5
]

{ #category : #'errors / status' }
FileAttributesPlugin >> unableToCloseDir [
	"The call to closedir() failed"
	<inline: #always>
	^-12
]

{ #category : #'errors / status' }
FileAttributesPlugin >> unexpectedError [
	"This is normally used where a catch-all is placed, but not expected to be used"
	<inline: #always>
	^-14
]

{ #category : #'errors / status' }
FileAttributesPlugin >> unsupportedOperation [
	"The requested operation is not supported on the current platform"
	<inline: #always>
	^-13
]

{ #category : #'version string' }
FileAttributesPlugin >> versionString [
	"Answer a string containing the version string for this plugin."
	<inline: #always>
	^'2.0.9'
]
