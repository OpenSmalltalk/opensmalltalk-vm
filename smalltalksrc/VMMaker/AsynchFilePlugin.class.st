"
Implements the asynchronous file primitives available on a few platforms. See the platform specific files in platforms- {your platform} - plugins - Asynchplugin
"
Class {
	#name : #AsynchFilePlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#instVars : [
		'sCOAFfn'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
AsynchFilePlugin class >> declareCVarsIn: cg [
	super declareCVarsIn: cg.
	cg var: #sCOAFfn type: #'void *'.

]

{ #category : #translation }
AsynchFilePlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
AsynchFilePlugin class >> requiresPlatformFiles [
	"this plugin requires platform specific files in order to work"
	^true
]

{ #category : #primitives }
AsynchFilePlugin >> asyncFileValueOf: oop [
	"Answer a pointer to the first byte of the async file record within the given
	 Smalltalk bytes object, or fail and answer nil if oop is not an async file record."

	<returnTypeC: 'AsyncFile *'>
	((interpreterProxy isBytes: oop)
	 and: [(interpreterProxy byteSizeOf: oop) = (self sizeof: #AsyncFile)]) ifTrue:
		[^self cCoerceSimple: (interpreterProxy firstIndexableField: oop) to: 'AsyncFile *'].
	interpreterProxy primitiveFailFor: PrimErrBadArgument.
	^nil
]

{ #category : #'initialize-release' }
AsynchFilePlugin >> initialiseModule [
	"Initialise the module"
	<export: true>
	sCOAFfn := interpreterProxy ioLoadFunction: 'secCanOpenAsyncFileOfSizeWritable' From: 'SecurityPlugin'.
	^self cCode: 'asyncFileInit()' inSmalltalk:[true]
]

{ #category : #'initialize-release' }
AsynchFilePlugin >> moduleUnloaded: aModuleName [ 
	"The module with the given name was just unloaded. 
	Make sure we have no dangling references."
	<export: true>
	<var: #aModuleName type: 'char *'>
	(aModuleName strcmp: 'SecurityPlugin') = 0
		ifTrue: ["The security plugin just shut down. How odd. Zero the function pointer we have into it"
			sCOAFfn := 0]
]

{ #category : #primitives }
AsynchFilePlugin >> primitiveAsyncFileClose: fh [ 
	| f |
	<var: #f type: 'AsyncFile *'>
	self primitive: 'primitiveAsyncFileClose' parameters: #(Oop ).
	f := self asyncFileValueOf: fh.
	interpreterProxy failed ifTrue: [^nil].
	self asyncFileClose: f
]

{ #category : #primitives }
AsynchFilePlugin >> primitiveAsyncFileOpen: fileName forWrite: writeFlag semaIndex: semaIndex [ 
	| fileNameSize fOop f okToOpen |
	<var: #f type: 'AsyncFile *'>
	self primitive: 'primitiveAsyncFileOpen' parameters: #(#String #Boolean #SmallInteger ).
	fileNameSize := interpreterProxy byteSizeOf: (fileName asOop: String).
	"If the security plugin can be loaded, use it to check for permission.
	If not, assume it's ok"
	sCOAFfn ~= 0 ifTrue:
		[okToOpen := self cCode: '((sqInt (*) (char *, sqInt, sqInt)) sCOAFfn)(fileName, fileNameSize, writeFlag)'
							inSmalltalk: [true].
		 okToOpen ifFalse:
			[^interpreterProxy primitiveFail]].
	fOop := interpreterProxy
				instantiateClass: interpreterProxy classByteArray
				indexableSize: (self sizeof: #AsyncFile).
	f := self asyncFileValueOf: fOop.
	interpreterProxy failed ifFalse:
		[self cCode: 'asyncFileOpen(f, fileName, fileNameSize, writeFlag, semaIndex)'].
	^fOop
]

{ #category : #primitives }
AsynchFilePlugin >> primitiveAsyncFileReadResult: fhandle intoBuffer: buffer at: start count: num [ 
	| bufferSize bufferPtr r f count startIndex |
	<var: #f type: 'AsyncFile *'>
	self primitive: 'primitiveAsyncFileReadResult' parameters: #(Oop Oop SmallInteger SmallInteger ).

	f := self asyncFileValueOf: fhandle.
	count := num.
	startIndex := start.
	bufferSize := interpreterProxy slotSizeOf: buffer. "in bytes or words"
	(interpreterProxy isWords: buffer) ifTrue: "covert word counts to byte counts"
		[count := count * 4.
		 startIndex := startIndex - 1 * 4 + 1.
		 bufferSize := bufferSize * 4].
	interpreterProxy success: (startIndex >= 1 and: [startIndex + count - 1 <= bufferSize]).

	interpreterProxy failed ifTrue: [^nil].
	"adjust for zero-origin indexing"
	bufferPtr := (self cCoerce: (interpreterProxy firstIndexableField: buffer) to:#sqInt) + startIndex - 1.
	r := self asyncFile: f Read: bufferPtr asVoidPointer Result: count.
	^r asOop: SmallInteger
]

{ #category : #primitives }
AsynchFilePlugin >> primitiveAsyncFileReadStart: fHandle fPosition: fPosition count: count [
	| f |
	<var: #f type: 'AsyncFile *'>
	self primitive: 'primitiveAsyncFileReadStart' parameters: #(Oop SmallInteger SmallInteger).
	f := self asyncFileValueOf: fHandle.
	interpreterProxy failed ifTrue: [^nil].
	self asyncFile: f Read: fPosition Start: count
]

{ #category : #primitives }
AsynchFilePlugin >> primitiveAsyncFileWriteResult: fHandle [
	| f r |
	<var: #f type: 'AsyncFile *'>
	self primitive: 'primitiveAsyncFileWriteResult' parameters:#(Oop).

	f := self asyncFileValueOf: fHandle.
	interpreterProxy failed ifTrue: [^nil].
	r := self asyncFileWriteResult: f.
	^r asOop: SmallInteger
]

{ #category : #primitives }
AsynchFilePlugin >> primitiveAsyncFileWriteStart: fHandle fPosition: fPosition fromBuffer: buffer at: start count: num [ 
	| f bufferSize bufferPtr count startIndex |
	<var: #f type: 'AsyncFile *'>
	self primitive: 'primitiveAsyncFileWriteStart' parameters: #(Oop SmallInteger Oop SmallInteger SmallInteger ).
	f := self asyncFileValueOf: fHandle.
	count := num.
	startIndex := start.
	bufferSize := interpreterProxy slotSizeOf: buffer.	"in bytes or words"
	(interpreterProxy isWords: buffer) ifTrue: "covert word counts to byte counts"
		[count := count * 4.
		 startIndex := startIndex - 1 * 4 + 1.
		 bufferSize := bufferSize * 4].
	interpreterProxy success: (startIndex >= 1 and: [startIndex + count - 1 <= bufferSize]).

	interpreterProxy failed ifTrue: [^nil].
	"adjust for zero-origin indexing"
	bufferPtr := (self cCoerce: (interpreterProxy firstIndexableField: buffer) to: #sqInt) + startIndex - 1.
	self async: f File: fPosition Write: bufferPtr asVoidPointer Start: count
]

{ #category : #'initialize-release' }
AsynchFilePlugin >> shutdownModule [
	"Initialise the module"
	<export: true>
	^self cCode: 'asyncFileShutdown()' inSmalltalk:[true]
]

{ #category : #simulation }
AsynchFilePlugin >> sizeof: objectSymbolOrClass [
	<doNotGenerate>
	objectSymbolOrClass isInteger ifTrue:
		[^interpreterProxy wordSize].
	objectSymbolOrClass == #AsyncFile ifTrue:
		[^interpreterProxy wordSize * 2].
	^super sizeof: objectSymbolOrClass
]
