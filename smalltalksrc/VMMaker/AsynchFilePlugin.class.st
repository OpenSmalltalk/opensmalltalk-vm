"
Implements the asynchronous file primitives available on a few platforms. See the platform specific files in platforms- {your platform} - plugins - Asynchplugin
"
Class {
	#name : #AsynchFilePlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#instVars : [
		'sCOAFfn'
	],
	#category : 'VMMaker-Plugins'
}

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
	"Return a pointer to the first byte of the async file record within the given Smalltalk bytes object, or nil if oop is not an async file record."

	self returnTypeC: 'AsyncFile *'.
	interpreterProxy success:
		((interpreterProxy isIntegerObject: oop) not and:
		 [(interpreterProxy isBytes: oop) and:
		 [(interpreterProxy slotSizeOf: oop) = (self cCode: 'sizeof(AsyncFile)')]]).
	interpreterProxy failed ifTrue: [^ nil].
	^ self cCode: '(AsyncFile *) (oop + 4)'

]

{ #category : #'initialize-release' }
AsynchFilePlugin >> initialiseModule [
	"Initialise the module"
	self export: true.
	sCOAFfn _ interpreterProxy ioLoadFunction: 'secCanOpenAsyncFileOfSizeWritable' From: 'SecurityPlugin'.
	^self cCode: 'asyncFileInit()' inSmalltalk:[true]
]

{ #category : #'initialize-release' }
AsynchFilePlugin >> moduleUnloaded: aModuleName [
	"The module with the given name was just unloaded.
	Make sure we have no dangling references."
	self export: true.
	self var: #aModuleName type: 'char *'.
	(aModuleName strcmp: 'SecurityPlugin') = 0 ifTrue:[
		"The security plugin just shut down. How odd."
		sCOAFfn _ 0.
	].
]

{ #category : #primitives }
AsynchFilePlugin >> primitiveAsyncFileClose: fh [ 
	| f |
	self var: #f declareC: 'AsyncFile *f'.
	self primitive: 'primitiveAsyncFileClose'
		parameters: #(Oop ).
	f _ self asyncFileValueOf: fh.
	self asyncFileClose: f
]

{ #category : #primitives }
AsynchFilePlugin >> primitiveAsyncFileOpen: fileName forWrite: writeFlag semaIndex: semaIndex [ 
	| fileNameSize fOop f okToOpen |
	self var: #f declareC: 'AsyncFile *f'.
	self primitive: 'primitiveAsyncFileOpen' parameters: #(#String #Boolean #SmallInteger ).
	fileNameSize _ interpreterProxy
				slotSizeOf: (fileName asOop: String).
	"If the security plugin can be loaded, use it to check for permission.
	If 
	not, assume it's ok"
	sCOAFfn ~= 0
		ifTrue: [okToOpen _ self cCode: ' ((int (*) (char *, int, int)) sCOAFfn)(fileName, fileNameSize, writeFlag)'.
			okToOpen
				ifFalse: [^ interpreterProxy primitiveFail]].
	fOop _ interpreterProxy
				instantiateClass: interpreterProxy classByteArray
				indexableSize: (self cCode: 'sizeof(AsyncFile)').
	f _ self asyncFileValueOf: fOop.
	interpreterProxy failed
		ifFalse: [self cCode: 'asyncFileOpen(f, (int)fileName, fileNameSize, writeFlag, semaIndex)'].
	^ fOop
]

{ #category : #primitives }
AsynchFilePlugin >> primitiveAsyncFileReadResult: fhandle intoBuffer: buffer at: start count: num [ 
	| bufferSize bufferPtr r f count startIndex |
	self var: #f declareC: 'AsyncFile *f'.
	self primitive: 'primitiveAsyncFileReadResult'
		parameters: #(Oop Oop SmallInteger SmallInteger ).
	f _ self asyncFileValueOf: fhandle.

	count _ num.
	startIndex _ start.
	bufferSize _ interpreterProxy slotSizeOf: buffer. "in bytes or words"
	(interpreterProxy isWords: buffer)
		ifTrue: ["covert word counts to byte counts"
			count _ count * 4.
			startIndex _ startIndex - 1 * 4 + 1.
			bufferSize _ bufferSize * 4].
	interpreterProxy success: (startIndex >= 1 and: [startIndex + count - 1 <= bufferSize]).

	bufferPtr _ (self cCoerce: (interpreterProxy firstIndexableField: buffer)
				to: 'int')
				+ startIndex - 1. 	"adjust for zero-origin indexing"
	interpreterProxy failed ifFalse: [r _ self cCode: 'asyncFileReadResult(f, bufferPtr, count)'].
	^ r asOop: SmallInteger
]

{ #category : #primitives }
AsynchFilePlugin >> primitiveAsyncFileReadStart: fHandle fPosition: fPosition count: count [
	| f |
	self var: #f declareC: 'AsyncFile *f'.
	self primitive: 'primitiveAsyncFileReadStart'
		parameters: #(Oop SmallInteger SmallInteger).
	f _ self asyncFileValueOf: fHandle.
	self cCode: 'asyncFileReadStart(f, fPosition, count)'

]

{ #category : #primitives }
AsynchFilePlugin >> primitiveAsyncFileWriteResult: fHandle [

	| f r |
	self var: #f declareC: 'AsyncFile *f'.
	self primitive: 'primitiveAsyncFileWriteResult'
		parameters:#(Oop).

	f _ self asyncFileValueOf: fHandle.
	r _ self cCode:' asyncFileWriteResult(f)'.
	^r asOop: SmallInteger
]

{ #category : #primitives }
AsynchFilePlugin >> primitiveAsyncFileWriteStart: fHandle fPosition: fPosition fromBuffer: buffer at: start count: num [ 
	| f bufferSize bufferPtr count startIndex |
	self var: #f declareC: 'AsyncFile *f'.
	self primitive: 'primitiveAsyncFileWriteStart'
		parameters: #(Oop SmallInteger Oop SmallInteger SmallInteger ).
	f _ self asyncFileValueOf: fHandle.
	interpreterProxy failed ifTrue: [^ nil].

	count _ num.
	startIndex _ start.
	bufferSize _ interpreterProxy slotSizeOf: buffer.	"in bytes or words"
	(interpreterProxy isWords: buffer)
		ifTrue: ["covert word counts to byte counts"
			count _ count * 4.
			startIndex _ startIndex - 1 * 4 + 1.
			bufferSize _ bufferSize * 4].
	interpreterProxy success: (startIndex >= 1 and: [startIndex + count - 1 <= bufferSize]).
	bufferPtr _ (self cCoerce: (interpreterProxy firstIndexableField: buffer)
				to: 'int')
				+ startIndex - 1.	"adjust for zero-origin indexing"
	interpreterProxy failed ifFalse: [self cCode: 'asyncFileWriteStart(f, fPosition, bufferPtr, count)']
]

{ #category : #'initialize-release' }
AsynchFilePlugin >> shutdownModule [
	"Initialise the module"
	self export: true.
	^self cCode: 'asyncFileShutdown()' inSmalltalk:[true]
]
