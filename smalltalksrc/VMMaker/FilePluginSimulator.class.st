"
File plugin simulation for the VM simulator
"
Class {
	#name : #FilePluginSimulator,
	#superclass : #FilePlugin,
	#instVars : [
		'openFiles'
	],
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #translation }
FilePluginSimulator class >> shouldBeTranslated [
"This class should not be translated"
	^false
]

{ #category : #'initialize-release' }
FilePluginSimulator >> close [  "close any files that ST may have opened"
	openFiles do: [:f | f close]
]

{ #category : #'file primitives' }
FilePluginSimulator >> fileOpenName: nameIndex size: nameSize write: writeFlag secure: secureFlag [
	"Open the named file, possibly checking security. Answer the file oop."
	| path f index |
	path := interpreterProxy interpreter asString: nameIndex size: nameSize.
	f := writeFlag
			ifTrue: [FileStream fileNamed: path]
			ifFalse:
				[(StandardFileStream isAFileNamed: path) ifTrue:
					[FileStream readOnlyFileNamed: path]].
	f ifNil: [^interpreterProxy primitiveFail].
	f binary.
	index := openFiles size + 1.
	openFiles at: index put: f.
	^interpreterProxy integerObjectOf: index
]

{ #category : #simulation }
FilePluginSimulator >> fileValueOf: objectPointer [
	| index |
	index := (interpreterProxy isIntegerObject: objectPointer)
				ifTrue: [interpreterProxy integerValueOf: objectPointer]
				ifFalse:
					[((interpreterProxy isBytes: objectPointer)
					  and: [(interpreterProxy byteSizeOf: objectPointer) = BytesPerWord]) ifFalse:
						[interpreterProxy primitiveFail.
						 ^nil].
					interpreterProxy longAt: objectPointer + BaseHeaderSize].
	^openFiles at: index
]

{ #category : #'initialize-release' }
FilePluginSimulator >> initialiseModule [
	"See FilePluginSimulator>>sqFileStdioHandlesInto:"
	(openFiles := Dictionary new)
		at: 0 put: (FakeStdinStream for: interpreterProxy interpreter); "stdin"
		at: 1 put: Transcript; "stdout"
		at: 2 put: Transcript. "stderr"
	^super initialiseModule
]

{ #category : #'file security' }
FilePluginSimulator >> ioCanCreatePath: dirNameIndex OfSize: dirNameSize [
	"Return true if we're allowed to create a directory with the given name"
	^true
]

{ #category : #'file security' }
FilePluginSimulator >> ioCanDeleteFile: nameIndex OfSize: nameSize [
	"Return true if we're allowed to delete the file with the given name"
	^true
]

{ #category : #'file security' }
FilePluginSimulator >> ioCanDeletePath: dirNameIndex OfSize: dirNameSize [
	"Return true if we're allowed to delete the directory with the given name"
	^true
]

{ #category : #'file security' }
FilePluginSimulator >> ioCanGetFileType: fileNameIndex OfSize: fileNameSize [
	"Return true if we're allowed to retrieve the (mac) file type of the given file."
	^true
]

{ #category : #'file security' }
FilePluginSimulator >> ioCanListPath: pathNameIndex OfSize: pathNameSize [
	"Return true if we're allowed to list the contents of the given directory"
	^true
]

{ #category : #'file security' }
FilePluginSimulator >> ioCanOpenFile: nameIndex OfSize: nameSize Writable: writeFlag [
	"Return true if we're allowed to open the given file (possibly in write mode)"
	^true
]

{ #category : #'file security' }
FilePluginSimulator >> ioCanRenameFile: oldNameIndex OfSize: oldNameSize [
	"Return true if we're allowed to rename the given file"
	^true
]

{ #category : #'file security' }
FilePluginSimulator >> ioCanSetFileType: fileNameIndex OfSize: fileNameSize [
	"Return true if we're allowed to set the (mac) file type and creator on the given file"
	^true
]

{ #category : #simulation }
FilePluginSimulator >> makeDirEntryName: entryName size: entryNameSize
	createDate: createDate modDate: modifiedDate
	isDir: dirFlag fileSize: fileSize [

	^interpreterProxy
		makeDirEntryName: entryName size: entryNameSize
		createDate: createDate modDate: modifiedDate
		isDir: dirFlag fileSize: fileSize

]

{ #category : #simulation }
FilePluginSimulator >> primitiveDirectoryEntry [
	^interpreterProxy interpreter primitiveDirectoryEntry
]

{ #category : #simulation }
FilePluginSimulator >> primitiveDirectoryLookup [
	^interpreterProxy interpreter primitiveDirectoryLookup
]

{ #category : #simulation }
FilePluginSimulator >> primitiveFileRename [
	^interpreterProxy primitiveFileRename
]

{ #category : #simulation }
FilePluginSimulator >> sizeof: objectSymbolOrClass [
	"In the simulator file handles are just integer indices into openFiles and so need only be BytesPerWord big."
	^objectSymbolOrClass == #SQFile
		ifTrue: [BytesPerWord]
		ifFalse: [super sizeof: objectSymbolOrClass]
]

{ #category : #simulation }
FilePluginSimulator >> sqFile: file Read: count Into: byteArrayIndex At: startIndex [
	| interpreter |
	interpreter := interpreterProxy interpreter.
	startIndex to: startIndex + count - 1 do:
		[ :i |
		file atEnd ifTrue: [^i - startIndex].
		interpreter byteAt: byteArrayIndex + i put: file next asInteger].
	^count
]

{ #category : #simulation }
FilePluginSimulator >> sqFile: file SetPosition: newPosition [
	file position: newPosition
]

{ #category : #simulation }
FilePluginSimulator >> sqFile: file Truncate: truncatePosition [
	file truncate: truncatePosition
]

{ #category : #simulation }
FilePluginSimulator >> sqFile: file Write: count From: byteArrayIndex At: startIndex [
	| interpreter |
	interpreter := interpreterProxy interpreter.
	file isBinary
		ifTrue:
			[startIndex to: startIndex + count - 1 do:
				[ :i | file nextPut: (interpreter byteAt: byteArrayIndex + i)]]
		ifFalse:
			[startIndex to: startIndex + count - 1 do:
				[ :i | | byte |
				byte := interpreter byteAt: byteArrayIndex + i.
				file nextPut: (Character value: (byte == 12 "lf" ifTrue: [15"cr"] ifFalse: [byte]))]].
	^count
]

{ #category : #simulation }
FilePluginSimulator >> sqFileAtEnd: file [
	^file atEnd
]

{ #category : #simulation }
FilePluginSimulator >> sqFileClose: file [
	file close
]

{ #category : #simulation }
FilePluginSimulator >> sqFileDeleteName: nameIndex Size: nameSize [
	| path |
	path := interpreterProxy interpreter asString: nameIndex size: nameSize.
	(StandardFileStream isAFileNamed: path) ifFalse:
		[^interpreterProxy primitiveFail].
	[FileDirectory deleteFilePath: path]
		on: Error
		do: [:ex| interpreterProxy primitiveFail]
]

{ #category : #simulation }
FilePluginSimulator >> sqFileFlush: file [
	^file flush
]

{ #category : #simulation }
FilePluginSimulator >> sqFileGetPosition: file [
	^file position
]

{ #category : #simulation }
FilePluginSimulator >> sqFileRenameOld: oldNameIndex Size: oldNameSize New: newNameIndex Size: newNameSize [
	| oldPath newPath |
	oldPath := FileDirectory default fullNameFor: (interpreterProxy interpreter asString: oldNameIndex size: oldNameSize).
	newPath := FileDirectory default fullNameFor: (interpreterProxy interpreter asString: newNameIndex size: newNameSize).
	((StandardFileStream isAFileNamed: oldPath)
	 and: [(StandardFileStream isAFileNamed: newPath) not]) ifFalse:
		[^interpreterProxy primitiveFail].
	[FileDirectory default primRename: oldPath to: newPath]
		on: Error
		do: [:ex| interpreterProxy primitiveFail]
]

{ #category : #simulation }
FilePluginSimulator >> sqFileSize: file [
	^file size
]

{ #category : #simulation }
FilePluginSimulator >> sqFileStdioHandlesInto: anArray [
	Transcript clear.
	"See FilePluginSimulator>>initialiseModule"
	anArray
		at: 1 put: 0;
		at: 2 put: 1;
		at: 3 put: 2.
	^7
]
