"
File plugin simulation for the VM simulator
"
Class {
	#name : #FilePluginSimulator,
	#superclass : #FilePlugin,
	#instVars : [
		'openFiles',
		'states',
		'maxOpenFiles'
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

{ #category : #simulation }
FilePluginSimulator >> dir_Create: dirNameIndex _: dirNameSize [
	^[
		(interpreterProxy interpreter
								asString: dirNameIndex
								size: dirNameSize) asFileReference ensureCreateDirectory.
	   true]
		on: Error
		do: [:ex| false]
]

{ #category : #simulation }
FilePluginSimulator >> dir_EntryLookup: pathString _: pathStringLength _: entryNameString _: entryNameStringLength _: name _: nameLength _: creationDate _: modificationDate _: isDirectory _: sizeIfFile _: posixPermissions _: isSymlink [
	"sqInt dir_EntryLookup(char *pathString, sqInt pathStringLength, char *nameString, sqInt nameStringLength,
		/* outputs: */		char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
  						      sqInt *isDirectory, squeakFileOffsetType *sizeIfFile, sqInt *posixPermissions, sqInt *isSymlink)"
	| result pathName entryName |
	pathName := ((0 to: pathStringLength - 1) collect: [:i| (pathString at: i) asCharacter]) as: ByteString.
	entryName := ((0 to: entryNameStringLength - 1) collect: [:i| (entryNameString at: i) asCharacter]) as: ByteString.
	result := self primLookupEntryIn: pathName name: entryName.
	result ifNil: [^DirNoMoreEntries].
	result isInteger ifTrue:
		[result > 1 ifTrue:
			[interpreterProxy primitiveFailFor: result].
		 ^DirBadPath].
	name replaceFrom: 1 to: result first size with: result first startingAt: 1.
	nameLength at: 0 put: result first size.
	creationDate at: 0 put: (result at: 2).
	modificationDate at: 0 put: (result at: 3).
	isDirectory at: 0 put: (result at: 4).
	sizeIfFile at: 0 put: (result at: 5).
	posixPermissions at: 0 put: (result at: 6 ifAbsent: [(result at: 4) ifTrue: [8r755] ifFalse: [8r644]]).
	isSymlink at: 0 put: (result at: 7 ifAbsent: [false]).
	^DirEntryFound
]

{ #category : #simulation }
FilePluginSimulator >> dir_Lookup: pathString _: pathStringLength _: index _: name _: nameLength _: creationDate _: modificationDate _: isDirectory _: sizeIfFile _: posixPermissions _: isSymlink [
	"sqInt dir_Lookup(	char *pathString, sqInt pathStringLength, sqInt index,
		/* outputs: */	char *name, sqInt *nameLength, sqInt *creationDate, sqInt *modificationDate,
		   				sqInt *isDirectory, squeakFileOffsetType *sizeIfFile, sqInt * posixPermissions, sqInt *isSymlink)"
	| result pathName |
	pathName := ((0 to: pathStringLength - 1) collect: [:i| (pathString at: i) asCharacter]) as: ByteString.
	result := self primLookupEntryIn: pathName index: index.
	result ifNil: [^DirNoMoreEntries].
	result isInteger ifTrue:
		[result > 1 ifTrue:
			[interpreterProxy primitiveFailFor: result].
		 ^DirBadPath].
	name replaceFrom: 1 to: result first size with: result first startingAt: 1.
	nameLength at: 0 put: result first size.
	creationDate at: 0 put: (result at: 2).
	modificationDate at: 0 put: (result at: 3).
	isDirectory at: 0 put: (result at: 4).
	sizeIfFile at: 0 put: (result at: 5).
	posixPermissions at: 0 put: (result at: 6 ifAbsent: [(result at: 4) ifTrue: [8r755] ifFalse: [8r644]]).
	isSymlink at: 0 put: (result at: 7 ifAbsent: [false]).
	^DirEntryFound
]

{ #category : #'file primitives' }
FilePluginSimulator >> fileOpenName: nameIndex size: nameSize write: writeFlag [
	"Open the named file, possibly checking security. Answer the file oop."
	| path f index |
	openFiles size >= maxOpenFiles ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrLimitExceeded].
	path := (interpreterProxy asByteArray: nameIndex size: nameSize) utf8Decoded.
	(writeFlag
	 or: [StandardFileStream isAFileNamed: path]) ifFalse:
		[^interpreterProxy primitiveFail].
	f := StandardFileStream new open: path forWrite: writeFlag.
	f ifNil: [^interpreterProxy primitiveFail].
	f binary.
	self assert: f isReadOnly = writeFlag not.
	index := (3 to: openFiles size + 1) detect: [:n| (openFiles includesKey: n) not].
	openFiles at: index put: f.
	^interpreterProxy integerObjectOf: index
]

{ #category : #'file primitives' }
FilePluginSimulator >> fileOpenNewName: nameIndex size: nameSize [
	"Open the new named file. Answer the file oop."
	| path f index |
	openFiles size >= maxOpenFiles ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrLimitExceeded].
	path := (interpreterProxy interpreter asByteArray: nameIndex size: nameSize) utf8Decoded.
	"the #defaultAction for FileExistsException creates a dialog,
	so it is caught and resignaled as a generic Error"
	[f := StandardFileStream newFileNamed: path]
		on: FileExistsException
		do: [:error | ^ interpreterProxy primitiveFailFor: PrimErrInappropriate].
	f ifNil: [^interpreterProxy primitiveFail].
	self deny: f isReadOnly.
	f binary.
	index := (3 to: openFiles size + 1) detect: [:n| (openFiles includesKey: n) not].
	openFiles at: index put: f.
	^interpreterProxy integerObjectOf: index
]

{ #category : #simulation }
FilePluginSimulator >> fileValueOf: objectPointer [
	| index file |
	index := (interpreterProxy isIntegerObject: objectPointer)
				ifTrue: [interpreterProxy integerValueOf: objectPointer]
				ifFalse:
					[((interpreterProxy isBytes: objectPointer)
					  and: [(interpreterProxy byteSizeOf: objectPointer) = (self sizeof: #SQFile)]) ifFalse:
						[interpreterProxy primitiveFail.
						 ^nil].
					interpreterProxy longAt: objectPointer + interpreterProxy baseHeaderSize].
	file := openFiles at: index ifAbsent: [ interpreterProxy primitiveFail. ^ nil ].
	"this attempts to preserve file positions across snapshots when debugging the VM
	 requires saving an image in full flight and pushing it over the cliff time after time..."
	(file closed and: [states includesKey: file]) ifTrue:
		[[:pos :isBinary|
		  file reopen; position: pos.
		  isBinary ifTrue:
			[file binary]] valueWithArguments: (states at: file)].
	^file
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
FilePluginSimulator >> primLookupEntryIn: fullPath index: index [
	"Look up the index-th entry of the directory with the given fully-qualified path (i.e., starting from the root of the file hierarchy) and return an array containing:

	<name> <creationTime> <modificationTime> <dirFlag> <fileSize>

	The empty string enumerates the top-level files or drives. (For example, on Unix, the empty path enumerates the contents of '/'. On Macs and PCs, it enumerates the mounted volumes/drives.)

	The creation and modification times are in seconds since the start of the Smalltalk time epoch. DirFlag is true if the entry is a directory. FileSize the file size in bytes or zero for directories. The primitive returns nil when index is past the end of the directory. It fails if the given path is bad."

 	<primitive: 'primitiveDirectoryLookup' module: 'FilePlugin' error: ec>
	^ec isInteger
		ifTrue: [ec]
		ifFalse:
			[Smalltalk primitiveErrorTable
				indexOf: ec
				ifAbsent: [Smalltalk primitiveErrorTable size + 1]]
]

{ #category : #simulation }
FilePluginSimulator >> primLookupEntryIn: fullPath name: fName [
	"Look up <fName> (a simple file name) in the directory identified by <fullPath>
 	 and return an array containing:

	<fName> <creationTime> <modificationTime> <dirFlag> <fileSize>

	On Unix, the empty path denotes '/'. 
      On Macs and PCs, it is the container of the system volumes.)

	The creation and modification times are in seconds since the start of the Smalltalk time epoch. DirFlag is true if the entry is a directory. FileSize the file size in bytes or zero for directories. The primitive returns nil when index is past the end of the directory. It fails if the given path is bad."

 	<primitive: 'primitiveDirectoryEntry' module: 'FilePlugin' error: ec>
	^ec isInteger
		ifTrue: [ec]
		ifFalse:
			[Smalltalk primitiveErrorTable
				indexOf: ec
				ifAbsent: [Smalltalk primitiveErrorTable size + 1]]
]

{ #category : #'file primitives' }
FilePluginSimulator >> primitiveFileGetPosition [
	super primitiveFileGetPosition.
	interpreterProxy failed ifTrue:
		[self halt]
]

{ #category : #simulation }
FilePluginSimulator >> recordStateOf: file [
	([file position]
			on: Error
			do: [:ex| nil]) ifNotNil:
		[:position|
		states at: file put: {position. file isBinary}]
]

{ #category : #simulation }
FilePluginSimulator >> sqFile: file Read: countArg Into: byteArrayIndexArg At: startIndex [
	| byteArrayIndex count |
	count := file isFakeStdinStream
		ifTrue: [1]
		ifFalse: [countArg].
	byteArrayIndex := byteArrayIndexArg asInteger. "Coerces CArray et al correctly"
	[[startIndex to: startIndex + count - 1 do:
		[ :i |
		file atEnd ifTrue: [^i - startIndex].
		interpreterProxy
			byteAt: byteArrayIndex + i
			put: (file next ifNil: [file isFakeStdinStream ifTrue: [^0]] ifNotNil: [:c| c asInteger])]]
			on: Error
			do: [:ex|
				(file isStream and: [file isTranscriptStream]) ifFalse:
					[ex pass].
				^0]]
		ensure: [self recordStateOf: file].
	^count
]

{ #category : #simulation }
FilePluginSimulator >> sqFile: file SetPosition: newPosition [
	file position: newPosition.
	self recordStateOf: file
]

{ #category : #simulation }
FilePluginSimulator >> sqFile: file Truncate: truncatePosition [
	file truncate: truncatePosition.
	self recordStateOf: file
]

{ #category : #simulation }
FilePluginSimulator >> sqFile: file Write: count From: byteArrayIndexArg At: startIndex [
	| byteArrayIndex |
	byteArrayIndex := byteArrayIndexArg asInteger. "Coerces CArray et al correctly"
	file isBinary
		ifTrue:
			[startIndex to: startIndex + count - 1 do:
				[ :i | file nextPut: (interpreterProxy byteAt: byteArrayIndex + i)]]
		ifFalse:
			[startIndex to: startIndex + count - 1 do:
				[ :i | | byte |
				byte := interpreterProxy byteAt: byteArrayIndex + i.
				file nextPut: (Character value: (byte == 12 "lf" ifTrue: [15"cr"] ifFalse: [byte]))]].
	self recordStateOf: file.
	^count
]

{ #category : #simulation }
FilePluginSimulator >> sqFileAtEnd: file [
	^file atEnd
]

{ #category : #simulation }
FilePluginSimulator >> sqFileClose: file [
	| index |
	index := openFiles keyAtValue: file.
	openFiles removeKey: index.
	states removeKey: file ifAbsent: [].
	file close
]

{ #category : #simulation }
FilePluginSimulator >> sqFileDeleteName: nameIndex Size: nameSize [
	| path |
	path := (interpreterProxy asString: nameIndex size: nameSize) asByteArray utf8Decoded.
	(StandardFileStream isAFileNamed: path) ifFalse:
		[^interpreterProxy primitiveFail].
	self halt: 'Deleting ', (path contractTo: 64).
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

{ #category : #'initialize-release' }
FilePluginSimulator >> sqFileInit [
	"See FilePluginSimulator>>sqFileStdioHandlesInto:"
	(openFiles := Dictionary new)
		at: 0 put: (FakeStdinStream for: interpreterProxy interpreter); "stdin"
		at: 1 put: interpreterProxy interpreter transcript; "stdout"
		at: 2 put: interpreterProxy interpreter transcript. "stderr"
	states := IdentityDictionary new.
	maxOpenFiles := VMClass initializationOptions at: #MaxFileDescriptors ifAbsent: [1024].
	^true
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
	"See FilePluginSimulator>>initialiseModule"
	anArray
		at: 1 put: 0;
		at: 2 put: 1;
		at: 3 put: 2.
	^7
]

{ #category : #simulation }
FilePluginSimulator >> sqFileSync: file [
	^file sync
]
