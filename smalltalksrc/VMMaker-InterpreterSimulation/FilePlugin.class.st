"
Provide access to the host machine file system. Requires both the Cross platform support files from platforms - Cross - plugins - FilePlugin (or some suitable replacement) and the platform specific fils from platforms - {your platform} - plugins - FilePlugin.
"
Class {
	#name : #FilePlugin,
	#superclass : #InterpreterPlugin,
	#instVars : [
		'sCCPfn',
		'sCDPfn',
		'sCGFTfn',
		'sCLPfn',
		'sCSFTfn',
		'sDFAfn',
		'sCDFfn',
		'sCOFfn',
		'sCRFfn',
		'sHFAfn'
	],
	#classVars : [
		'DirBadPath',
		'DirEntryFound',
		'DirNoMoreEntries'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
FilePlugin class >> declareCVarsIn: aCCodeGenerator [

	aCCodeGenerator var: 'sCCPfn'	type: 'void *'.
	aCCodeGenerator var: 'sCDPfn'	type: 'void *'.
	aCCodeGenerator var: 'sCGFTfn'	type: 'void *'.
	aCCodeGenerator var: 'sCLPfn'	type: 'void *'.
	aCCodeGenerator var: 'sCSFTfn'	type: 'void *'.
	aCCodeGenerator var: 'sDFAfn'	type: 'void *'.
	aCCodeGenerator var: 'sCDFfn'	type: 'void *'.
	aCCodeGenerator var: 'sCOFfn'	type: 'void *'.
	aCCodeGenerator var: 'sCRFfn'	type: 'void *'.
	aCCodeGenerator var: 'sHFAfn'	type: 'void *'.
	aCCodeGenerator addHeaderFile: '"FilePlugin.h"'
]

{ #category : #translation }
FilePlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #'class initialization' }
FilePlugin class >> initialize [
	"FilePlugin initialize"
	DirEntryFound _ 0.
	DirNoMoreEntries _ 1.
	DirBadPath _ 2.
]

{ #category : #translation }
FilePlugin class >> requiresCrossPlatformFiles [
	"this plugin requires cross platform files in order to work"
	^true
]

{ #category : #translation }
FilePlugin class >> requiresPlatformFiles [
	"this plugin requires platform specific files in order to work"
	^true
]

{ #category : #'instance creation' }
FilePlugin class >> simulatorClass [
	^FilePluginSimulator
]

{ #category : #'directory primitives' }
FilePlugin >> asciiDirectoryDelimiter [
	^ self cCode: 'dir_Delimitor()' inSmalltalk: [FileDirectory pathNameDelimiter asciiValue]
]

{ #category : #'file primitives' }
FilePlugin >> fileOpenName: nameIndex size: nameSize write: writeFlag secure: secureFlag [
	"Open the named file, possibly checking security. Answer the file oop."
	| file fileOop okToOpen |
	self var: #file type: 'SQFile *'.
	self var: 'nameIndex' type: 'char *'.
	self export: true.
	fileOop _ interpreterProxy instantiateClass: interpreterProxy classByteArray indexableSize: self fileRecordSize.
	file _ self fileValueOf: fileOop.
	interpreterProxy failed
		ifFalse: [ secureFlag ifTrue: [
				"If the security plugin can be loaded, use it to check for permission.
				If not, assume it's ok"
				sCOFfn ~= 0 
					ifTrue: [okToOpen _ self cCode: '((sqInt (*) (char *, sqInt, sqInt)) sCOFfn)(nameIndex, nameSize, writeFlag)' inSmalltalk:[true].
						okToOpen
							ifFalse: [interpreterProxy primitiveFail]]]].
	interpreterProxy failed
		ifFalse: [self cCode: 'sqFileOpen(file, nameIndex, nameSize, writeFlag)' inSmalltalk: [file]].
	^ fileOop
]

{ #category : #'file primitives' }
FilePlugin >> fileRecordSize [
	"Return the size of a Smalltalk file record in bytes."
	self static: false.
	^ self cCode: 'sizeof(SQFile)'.
]

{ #category : #'file primitives' }
FilePlugin >> fileValueOf: objectPointer [
	"Return a pointer to the first byte of of the file record within the given Smalltalk object, or nil if objectPointer is not a file record."
	self returnTypeC: 'SQFile *'.
	self static: false.
	(((interpreterProxy isBytes: objectPointer) and:
		 [(interpreterProxy byteSizeOf: objectPointer) = self fileRecordSize]))
			ifFalse:[interpreterProxy primitiveFail. ^nil].
	^interpreterProxy firstIndexableField: objectPointer
]

{ #category : #'file primitives' }
FilePlugin >> getThisSession [
	"Exported entry point for the VM. Only used by AsynchFilePlugin and needs to be reowrked now we have a VM global session Id capability"
	self export: true. 
	^self cCode: 'sqFileThisSession()'.
]

{ #category : #'initialize-release' }
FilePlugin >> initialiseModule [
	self export: true.
	sCCPfn _ interpreterProxy ioLoadFunction: 'secCanCreatePathOfSize' From: 'SecurityPlugin'.
	sCDPfn _ interpreterProxy ioLoadFunction: 'secCanDeletePathOfSize' From: 'SecurityPlugin'.
	sCGFTfn _ interpreterProxy ioLoadFunction: 'secCanGetFileTypeOfSize' From: 'SecurityPlugin'.
	sCLPfn _ interpreterProxy ioLoadFunction: 'secCanListPathOfSize' From: 'SecurityPlugin'.
	sCSFTfn _ interpreterProxy ioLoadFunction: 'secCanSetFileTypeOfSize' From: 'SecurityPlugin'.
	sDFAfn _ interpreterProxy ioLoadFunction: 'secDisableFileAccess' From: 'SecurityPlugin'.
	sCDFfn _ interpreterProxy ioLoadFunction: 'secCanDeleteFileOfSize' From: 'SecurityPlugin'.
	sCOFfn _ interpreterProxy ioLoadFunction: 'secCanOpenFileOfSizeWritable' From: 'SecurityPlugin'.
	sCRFfn _ interpreterProxy ioLoadFunction: 'secCanRenameFileOfSize' From: 'SecurityPlugin'.
	sHFAfn _ interpreterProxy ioLoadFunction: 'secHasFileAccess' From: 'SecurityPlugin'.
	^self cCode: 'sqFileInit()' inSmalltalk:[true]
]

{ #category : #'directory primitives' }
FilePlugin >> makeDirEntryName: entryName size: entryNameSize
	createDate: createDate modDate: modifiedDate
	isDir: dirFlag fileSize: fileSize [

	| modDateOop createDateOop nameString results stringPtr fileSizeOop |
	self var: 'entryName' type: 'char *'.
	self var: 'stringPtr' type:'char *'.
	self var: 'fileSize' type:'squeakFileOffsetType '.

	"allocate storage for results, remapping newly allocated
	 oops in case GC happens during allocation"
	interpreterProxy pushRemappableOop:
		(interpreterProxy instantiateClass: (interpreterProxy classArray) indexableSize: 5).
	interpreterProxy pushRemappableOop:
		(interpreterProxy instantiateClass: (interpreterProxy classString) indexableSize: entryNameSize)..
	interpreterProxy pushRemappableOop: 
		(interpreterProxy positive32BitIntegerFor: createDate).
	interpreterProxy pushRemappableOop: 
		(interpreterProxy positive32BitIntegerFor: modifiedDate).
	interpreterProxy pushRemappableOop:
		(interpreterProxy positive64BitIntegerFor: fileSize).

	fileSizeOop   _ interpreterProxy popRemappableOop.
	modDateOop   _ interpreterProxy popRemappableOop.
	createDateOop _ interpreterProxy popRemappableOop.
	nameString    _ interpreterProxy popRemappableOop.
	results         _ interpreterProxy popRemappableOop.

	"copy name into Smalltalk string"
	stringPtr _ interpreterProxy firstIndexableField: nameString.
	0 to: entryNameSize - 1 do: [ :i |
		stringPtr at: i put: (entryName at: i).
	].

	interpreterProxy storePointer: 0 ofObject: results withValue: nameString.
	interpreterProxy storePointer: 1 ofObject: results withValue: createDateOop.
	interpreterProxy storePointer: 2 ofObject: results withValue: modDateOop.
	dirFlag
		ifTrue: [ interpreterProxy storePointer: 3 ofObject: results withValue: interpreterProxy trueObject ]
		ifFalse: [ interpreterProxy storePointer: 3 ofObject: results withValue: interpreterProxy falseObject ].
	interpreterProxy storePointer: 4 ofObject: results withValue: fileSizeOop.
	^ results
]

{ #category : #'initialize-release' }
FilePlugin >> moduleUnloaded: aModuleName [
	"The module with the given name was just unloaded.
	Make sure we have no dangling references."
	self export: true.
	self var: #aModuleName type: 'char *'.
	(aModuleName strcmp: 'SecurityPlugin') = 0 ifTrue:[
		"The security plugin just shut down. How odd."
		sCCPfn _ sCDPfn _ sCGFTfn _ sCLPfn _ sCSFTfn _ sDFAfn _ sCDFfn _ sCOFfn _ sCRFfn _ sHFAfn _ 0.
	].
]

{ #category : #'directory primitives' }
FilePlugin >> primitiveDirectoryCreate [

	| dirName dirNameIndex dirNameSize okToCreate |
	self var: #dirNameIndex type: 'char *'.
	self export: true.

	dirName _ interpreterProxy stackValue: 0.
	(interpreterProxy isBytes: dirName)
		ifFalse: [^interpreterProxy primitiveFail].
	dirNameIndex _ interpreterProxy firstIndexableField: dirName.
	dirNameSize _ interpreterProxy byteSizeOf: dirName.
	"If the security plugin can be loaded, use it to check for permission.
	If not, assume it's ok"
	sCCPfn ~= 0
		ifTrue: [okToCreate _ self cCode: ' ((sqInt (*)(char *, sqInt))sCCPfn)(dirNameIndex, dirNameSize)'.
			okToCreate
				ifFalse: [^interpreterProxy primitiveFail]].
	(self
			cCode: 'dir_Create(dirNameIndex, dirNameSize)'
			inSmalltalk: [false])
		ifFalse: [^interpreterProxy primitiveFail].
	interpreterProxy pop: 1
]

{ #category : #'directory primitives' }
FilePlugin >> primitiveDirectoryDelete [

	| dirName dirNameIndex dirNameSize okToDelete |
	self var: #dirNameIndex type: 'char *'.
	self export: true.

	dirName _ interpreterProxy stackValue: 0.
	(interpreterProxy isBytes: dirName)
		ifFalse: [^interpreterProxy primitiveFail].
	dirNameIndex _ interpreterProxy firstIndexableField: dirName.
	dirNameSize _ interpreterProxy byteSizeOf: dirName.
	"If the security plugin can be loaded, use it to check for permission.
	If not, assume it's ok"
	sCDPfn ~= 0
		ifTrue: [okToDelete _ self cCode: ' ((sqInt (*)(char *, sqInt))sCDPfn)(dirNameIndex, dirNameSize)'.
			okToDelete
				ifFalse: [^interpreterProxy primitiveFail]].
	(self
			cCode: 'dir_Delete(dirNameIndex, dirNameSize)'
			inSmalltalk: [false])
		ifFalse: [^interpreterProxy primitiveFail].
	interpreterProxy pop: 1
]

{ #category : #'directory primitives' }
FilePlugin >> primitiveDirectoryDelimitor [

	| ascii |
	self export: true.
	ascii _ self asciiDirectoryDelimiter.
	((ascii >= 0) and: [ascii <= 255])
		ifFalse:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 1.  "pop rcvr"
	interpreterProxy push: (interpreterProxy fetchPointer: ascii ofObject: (interpreterProxy characterTable)).
]

{ #category : #'directory primitives' }
FilePlugin >> primitiveDirectoryGetMacTypeAndCreator [

	| creatorString typeString fileName creatorStringIndex typeStringIndex fileNameIndex fileNameSize okToGet |
	self var: 'creatorStringIndex' type: 'char *'.
	self var: 'typeStringIndex' type: 'char *'.
	self var: 'fileNameIndex' type: 'char *'.
	self export: true.

	creatorString _ interpreterProxy stackValue: 0.
	typeString _ interpreterProxy stackValue: 1.
	fileName _ interpreterProxy stackValue: 2.
	((interpreterProxy isBytes: creatorString)
			and: [(interpreterProxy byteSizeOf: creatorString) = 4])
		ifFalse: [^interpreterProxy primitiveFail].
	((interpreterProxy isBytes: typeString)
			and: [(interpreterProxy byteSizeOf: typeString) = 4])
		ifFalse: [^interpreterProxy primitiveFail].
	(interpreterProxy isBytes: fileName)
		ifFalse: [^interpreterProxy primitiveFail].
	creatorStringIndex _ interpreterProxy firstIndexableField: creatorString.
	typeStringIndex _ interpreterProxy firstIndexableField: typeString.
	fileNameIndex _ interpreterProxy firstIndexableField: fileName.
	fileNameSize _ interpreterProxy byteSizeOf: fileName.
	"If the security plugin can be loaded, use it to check for permission.
	If not, assume it's ok"
	sCGFTfn ~= 0
		ifTrue: [okToGet _ self cCode: ' ((sqInt (*)(char *, sqInt))sCGFTfn)(fileNameIndex, fileNameSize)'.
			okToGet
				ifFalse: [^interpreterProxy primitiveFail]].
	(self
			cCode: 'dir_GetMacFileTypeAndCreator(fileNameIndex, fileNameSize, typeStringIndex, creatorStringIndex)'
			inSmalltalk: [true])
		ifFalse: [^interpreterProxy primitiveFail].
	interpreterProxy pop: 3
]

{ #category : #'directory primitives' }
FilePlugin >> primitiveDirectoryLookup [

	| index pathName pathNameIndex pathNameSize status entryName entryNameSize createDate modifiedDate dirFlag fileSize okToList |
	self var: 'entryName' declareC: 'char entryName[256]'.
	self var: 'pathNameIndex' type: 'char *'.
	self var: 'fileSize' type: 'squeakFileOffsetType'.
	self export: true.

	index _ interpreterProxy stackIntegerValue: 0.
	pathName _ interpreterProxy stackValue: 1.
	(interpreterProxy isBytes: pathName)
		ifFalse: [^interpreterProxy primitiveFail].
	pathNameIndex _ interpreterProxy firstIndexableField: pathName.
	pathNameSize _ interpreterProxy byteSizeOf: pathName.
	"If the security plugin can be loaded, use it to check for permission. 
	If not, assume it's ok"
	sCLPfn ~= 0
		ifTrue: [okToList _ self cCode: '((sqInt (*)(char *, sqInt))sCLPfn)(pathNameIndex, pathNameSize)']
		ifFalse: [okToList _ true].
	okToList
		ifTrue: [status _ self cCode: 'dir_Lookup(pathNameIndex, pathNameSize, index,
												entryName, &entryNameSize, &createDate,
												&modifiedDate, &dirFlag, &fileSize)']
		ifFalse: [status _ DirNoMoreEntries].
	interpreterProxy failed
		ifTrue: [^nil].
	status = DirNoMoreEntries
		ifTrue: ["no more entries; return nil"
			interpreterProxy pop: 3 "pop pathName, index, rcvr"
				thenPush: interpreterProxy nilObject.
			^nil].
	status = DirBadPath
		ifTrue: [^interpreterProxy primitiveFail]."bad path"

	interpreterProxy pop: 3	"pop pathName, index, rcvr" 
		thenPush: (self
				makeDirEntryName: entryName
				size: entryNameSize
				createDate: createDate
				modDate: modifiedDate
				isDir: dirFlag
				fileSize: fileSize)
]

{ #category : #'directory primitives' }
FilePlugin >> primitiveDirectorySetMacTypeAndCreator [

	| creatorString typeString fileName creatorStringIndex typeStringIndex fileNameIndex fileNameSize  okToSet |
	self var: 'creatorStringIndex' type: 'char *'.
	self var: 'typeStringIndex' type: 'char *'.
	self var: 'fileNameIndex' type: 'char *'.
	self export: true.

	creatorString _ interpreterProxy stackValue: 0.
	typeString _ interpreterProxy stackValue: 1.
	fileName _ interpreterProxy stackValue: 2.
	((interpreterProxy isBytes: creatorString)
			and: [(interpreterProxy byteSizeOf: creatorString)
					= 4])
		ifFalse: [^interpreterProxy primitiveFail].
	((interpreterProxy isBytes: typeString)
			and: [(interpreterProxy byteSizeOf: typeString)
					= 4])
		ifFalse: [^interpreterProxy primitiveFail].
	(interpreterProxy isBytes: fileName)
		ifFalse: [^interpreterProxy primitiveFail].
	creatorStringIndex _ interpreterProxy firstIndexableField: creatorString.
	typeStringIndex _ interpreterProxy firstIndexableField: typeString.
	fileNameIndex _ interpreterProxy firstIndexableField: fileName.
	fileNameSize _ interpreterProxy byteSizeOf: fileName.
	"If the security plugin can be loaded, use it to check for permission.
	If not, assume it's ok"
	sCSFTfn ~= 0
		ifTrue: [okToSet _ self cCode: ' ((sqInt (*)(char *, sqInt))sCSFTfn)(fileNameIndex, fileNameSize)'.
			okToSet
				ifFalse: [^interpreterProxy primitiveFail]].
	(self
			cCode: 'dir_SetMacFileTypeAndCreator(fileNameIndex, fileNameSize,typeStringIndex, creatorStringIndex)'
			inSmalltalk: [true])
		ifFalse: [^interpreterProxy primitiveFail].
	interpreterProxy pop: 3
]

{ #category : #'security primitives' }
FilePlugin >> primitiveDisableFileAccess [
	self export: true.
	"If the security plugin can be loaded, use it to turn off file access
	If not, assume it's ok"
	sDFAfn ~= 0
		ifTrue: [self cCode: ' ((sqInt (*)(void))sDFAfn)()'].
	interpreterProxy failed
		ifFalse: [interpreterProxy pop: 1]
]

{ #category : #'file primitives' }
FilePlugin >> primitiveFileAtEnd [
	| file atEnd |
	self export: true.
	self var: 'file' type: 'SQFile *'.
	file := self fileValueOf: (interpreterProxy stackValue: 0).
	interpreterProxy failed
		ifFalse: [atEnd := self sqFileAtEnd: file].
	interpreterProxy failed
		ifFalse: [interpreterProxy pop: 2. "rcvr, file"
			interpreterProxy pushBool: atEnd]
]

{ #category : #'file primitives' }
FilePlugin >> primitiveFileClose [

	| file |
	self export: true.
	self var: 'file' type: 'SQFile *'.
	file _ self fileValueOf: (interpreterProxy stackValue: 0).
	interpreterProxy failed ifFalse: [ self sqFileClose: file ].
	interpreterProxy failed ifFalse: [ interpreterProxy pop: 1  "pop file; leave rcvr on stack" ].
]

{ #category : #'file primitives' }
FilePlugin >> primitiveFileDelete [

	| namePointer nameIndex nameSize  okToDelete |
	self var: 'nameIndex' type: 'char *'.
	self export: true.

	namePointer _ interpreterProxy stackValue: 0.
	(interpreterProxy isBytes: namePointer)
		ifFalse: [^ interpreterProxy primitiveFail].
	nameIndex _ interpreterProxy firstIndexableField: namePointer.
	nameSize _ interpreterProxy byteSizeOf: namePointer.
	"If the security plugin can be loaded, use it to check for permission.
	If not, assume it's ok"
	sCDFfn ~= 0
		ifTrue: [okToDelete _ self cCode: ' ((sqInt (*)(char *, sqInt))sCDFfn)(nameIndex, nameSize)'.
			okToDelete
				ifFalse: [^ interpreterProxy primitiveFail]].
	self
		sqFileDeleteName: nameIndex
		Size: nameSize.
	interpreterProxy failed
		ifFalse: [interpreterProxy pop: 1]
]

{ #category : #'file primitives' }
FilePlugin >> primitiveFileFlush [
	| file |
	self var: 'file' type: 'SQFile *'.
	self export: true.
	file _ self fileValueOf: (interpreterProxy stackValue: 0).
	interpreterProxy failed ifFalse:[self sqFileFlush: file].
	interpreterProxy failed ifFalse: [interpreterProxy pop: 1].
]

{ #category : #'file primitives' }
FilePlugin >> primitiveFileGetPosition [
	| file position |
	self var: 'file' type: 'SQFile *'.
	self var: 'position' type: 'squeakFileOffsetType'.
	self export: true.
	file _ self fileValueOf: (interpreterProxy stackValue: 0).
	interpreterProxy failed ifFalse: [position _ self sqFileGetPosition: file].
	interpreterProxy failed ifFalse: [
		interpreterProxy pop: 2 thenPush: (interpreterProxy positive64BitIntegerFor: position)].
]

{ #category : #'file primitives' }
FilePlugin >> primitiveFileOpen [
	| writeFlag namePointer filePointer nameIndex nameSize |
	self var: 'nameIndex' type: 'char *'.
	self export: true.
	writeFlag _ interpreterProxy
				booleanValueOf: (interpreterProxy stackValue: 0).
	namePointer _ interpreterProxy stackValue: 1.
	(interpreterProxy isBytes: namePointer)
		ifFalse: [^ interpreterProxy primitiveFail].
	nameIndex _ interpreterProxy firstIndexableField: namePointer.
	nameSize _ interpreterProxy byteSizeOf: namePointer.
	filePointer _ self fileOpenName: nameIndex size: nameSize write: writeFlag secure: true.
	interpreterProxy failed
		ifFalse: [interpreterProxy pop: 3 "rcvr, name, writeFlag"
			thenPush: filePointer]

]

{ #category : #'file primitives' }
FilePlugin >> primitiveFileRead [

	| count startIndex array file byteSize arrayIndex bytesRead |
	self var: 'file' type: 'SQFile *'.
	self var: 'arrayIndex' type: 'char *'.
	self var: 'count' type: 'size_t'.
	self var: 'startIndex' type: 'size_t'.
	self var: 'byteSize' type: 'size_t'.
	self export: true.

	count		_ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	startIndex	_ interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 1).
	array		_ interpreterProxy stackValue: 2.
	file			_ self fileValueOf: (interpreterProxy stackValue: 3).

	"buffer can be any indexable words or bytes object except CompiledMethod"
	(interpreterProxy isWordsOrBytes: array) 
		ifFalse: [^interpreterProxy primitiveFail].

	(interpreterProxy isWords: array)
		ifTrue: [byteSize _ 4]
		ifFalse: [byteSize _ 1].
	((startIndex >= 1) and:
		[(startIndex + count - 1) <= (interpreterProxy slotSizeOf: array)])
			ifFalse: [^interpreterProxy primitiveFail].

	arrayIndex _ interpreterProxy firstIndexableField: array.
	"Note: adjust startIndex for zero-origin indexing"
	bytesRead _ self
		sqFile: file Read: (count * byteSize)
		Into: arrayIndex
		At: ((startIndex - 1) * byteSize).
	interpreterProxy failed ifFalse: [
		interpreterProxy pop: 5 "pop rcvr, file, array, startIndex, count"
			thenPush:(interpreterProxy integerObjectOf: bytesRead // byteSize).  "push # of elements read"].
]

{ #category : #'file primitives' }
FilePlugin >> primitiveFileRename [

	| oldNamePointer newNamePointer oldNameIndex oldNameSize newNameIndex newNameSize  okToRename |
	self var: 'oldNameIndex' type: 'char *'.
	self var: 'newNameIndex' type: 'char *'.
	self export: true.

	newNamePointer _ interpreterProxy stackValue: 0.
	oldNamePointer _ interpreterProxy stackValue: 1.
	((interpreterProxy isBytes: newNamePointer)
			and: [interpreterProxy isBytes: oldNamePointer])
		ifFalse: [^interpreterProxy primitiveFail].
	newNameIndex _ interpreterProxy firstIndexableField: newNamePointer.
	newNameSize _ interpreterProxy byteSizeOf: newNamePointer.
	oldNameIndex _ interpreterProxy firstIndexableField: oldNamePointer.
	oldNameSize _ interpreterProxy byteSizeOf: oldNamePointer.
	"If the security plugin can be loaded, use it to check for rename permission.
	If not, assume it's ok"
	sCRFfn ~= 0
		ifTrue: [okToRename _ self cCode: ' ((sqInt (*)(char *, sqInt))sCRFfn)(oldNameIndex, oldNameSize)'.
			okToRename
				ifFalse: [^interpreterProxy primitiveFail]].
	self
		sqFileRenameOld: oldNameIndex Size: oldNameSize
		New: newNameIndex Size: newNameSize.
	interpreterProxy failed
		ifFalse: [interpreterProxy pop: 2]
]

{ #category : #'file primitives' }
FilePlugin >> primitiveFileSetPosition [
	| newPosition file sz |
	self var: 'file' type: 'SQFile *'.
	self var: 'newPosition' type: 'squeakFileOffsetType'.
	self export: true.
	(interpreterProxy isIntegerObject: (interpreterProxy stackValue: 0)) ifFalse:
		[sz _ self cCode: 'sizeof(squeakFileOffsetType)'.
		(interpreterProxy byteSizeOf: (interpreterProxy stackValue: 0)) > sz 
			ifTrue: [^interpreterProxy primitiveFail]].
	newPosition _ interpreterProxy positive64BitValueOf: (interpreterProxy stackValue: 0).
	file _ self fileValueOf: (interpreterProxy stackValue: 1).
	interpreterProxy failed ifFalse:[
		self sqFile: file SetPosition: newPosition ].
	interpreterProxy failed ifFalse:[
		interpreterProxy pop: 2 "pop position, file; leave rcvr on stack" ].
]

{ #category : #'file primitives' }
FilePlugin >> primitiveFileSize [
	| file size |
	self var: 'file' type: 'SQFile *'.
	self var: 'size' type: 'squeakFileOffsetType'.
	self export: true.
	file _ self fileValueOf: (interpreterProxy stackValue: 0).
	interpreterProxy failed ifFalse:[size _ self sqFileSize: file].
	interpreterProxy failed ifFalse: [
		interpreterProxy pop: 2 thenPush: (interpreterProxy positive64BitIntegerFor: size)].
]

{ #category : #'file primitives' }
FilePlugin >> primitiveFileTruncate [
"ftruncate is not an ansi function so we have a macro to point to a suitable platform implementation" 
	| truncatePosition file sz |
	self var: 'file' type: 'SQFile *'.
	self var: 'truncatePosition' type: 'squeakFileOffsetType'.
	self export: true.
	(interpreterProxy isIntegerObject: (interpreterProxy stackValue: 0))
		ifFalse: [sz := self cCode: 'sizeof(squeakFileOffsetType)'.
			(interpreterProxy byteSizeOf: (interpreterProxy stackValue: 0)) > sz
				ifTrue: [^ interpreterProxy primitiveFail]].
	truncatePosition := interpreterProxy
				positive64BitValueOf: (interpreterProxy stackValue: 0).
	file := self fileValueOf: (interpreterProxy stackValue: 1).
	interpreterProxy failed
		ifFalse: [self sqFile: file Truncate: truncatePosition].
	interpreterProxy failed
		ifFalse: [interpreterProxy pop: 2 "pop position, file; leave rcvr on stack"]
]

{ #category : #'file primitives' }
FilePlugin >> primitiveFileWrite [
	| count startIndex array file byteSize arrayIndex bytesWritten |
	self var: 'file' type: 'SQFile *'.
	self var: 'arrayIndex' type: 'char *'.
	self var: 'count' type: 'size_t'.
	self var: 'startIndex' type: 'size_t'.
	self var: 'byteSize' type: 'size_t'.
	self export: true.
	count := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	startIndex := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 1).
	array := interpreterProxy stackValue: 2.
	file := self fileValueOf: (interpreterProxy stackValue: 3).
	"buffer can be any indexable words or bytes object except CompiledMethod "
	(interpreterProxy isWordsOrBytes: array)
		ifFalse: [^ interpreterProxy primitiveFail].
	(interpreterProxy isWords: array)
		ifTrue: [byteSize := 4]
		ifFalse: [byteSize := 1].
	(startIndex >= 1 and: [startIndex + count - 1 <= (interpreterProxy slotSizeOf: array)])
		ifFalse: [^ interpreterProxy primitiveFail].
	interpreterProxy failed
		ifFalse: [arrayIndex := interpreterProxy firstIndexableField: array.
			"Note: adjust startIndex for zero-origin indexing"
			bytesWritten := self
						sqFile: file
						Write: count * byteSize
						From: arrayIndex
						At: startIndex - 1 * byteSize].
	interpreterProxy failed
		ifFalse: [interpreterProxy pop: 5 thenPush:( interpreterProxy integerObjectOf: bytesWritten // byteSize)]
]

{ #category : #'security primitives' }
FilePlugin >> primitiveHasFileAccess [
	|  hasAccess |
	self export: true.
	"If the security plugin can be loaded, use it to check . 
	If not, assume it's ok"
	sHFAfn ~= 0
		ifTrue: [hasAccess _ self cCode: ' ((sqInt (*)(void))sHFAfn)()' inSmalltalk: [true]]
		ifFalse: [hasAccess _ true].
	interpreterProxy pop: 1.
	interpreterProxy pushBool: hasAccess
]

{ #category : #'file primitives' }
FilePlugin >> setMacFile: fileName Type: typeString AndCreator: creatorString [
	"Exported entry point for the VM. Needed for image saving only and no-op on anything but Macs."
	self export: true. "Must be exported for image file write"
	self var: #fileName type: 'char *'.
	self var: #typeString type: 'char *'.
	self var: #creatorString type: 'char *'.
	^self cCode: 'dir_SetMacFileTypeAndCreator(fileName, strlen(fileName), typeString, creatorString)'.
]

{ #category : #'initialize-release' }
FilePlugin >> shutdownModule [
	self export: true.
	^self cCode: 'sqFileShutdown()' inSmalltalk:[true]
]
