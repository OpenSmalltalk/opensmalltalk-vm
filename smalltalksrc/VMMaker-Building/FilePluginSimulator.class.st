"
File plugin simulation for the VM simulator
"
Class {
	#name : #FilePluginSimulator,
	#superclass : #FilePlugin,
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #translation }
FilePluginSimulator class >> shouldBeTranslated [
"This class should not be translated"
	^false
]

{ #category : #'as yet unclassified' }
FilePluginSimulator >> fileValueOf: objectPointer [
	^interpreterProxy fileValueOf: objectPointer
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

{ #category : #'as yet unclassified' }
FilePluginSimulator >> makeDirEntryName: entryName size: entryNameSize
	createDate: createDate modDate: modifiedDate
	isDir: dirFlag fileSize: fileSize [

	^interpreterProxy
		makeDirEntryName: entryName size: entryNameSize
		createDate: createDate modDate: modifiedDate
		isDir: dirFlag fileSize: fileSize

]

{ #category : #'as yet unclassified' }
FilePluginSimulator >> primitiveDirectoryLookup [
	^interpreterProxy primitiveDirectoryLookup
]

{ #category : #'as yet unclassified' }
FilePluginSimulator >> primitiveFileDelete [ 
	^interpreterProxy primitiveFileDelete 
]

{ #category : #'as yet unclassified' }
FilePluginSimulator >> primitiveFileOpen [
	^interpreterProxy primitiveFileOpen
]

{ #category : #'as yet unclassified' }
FilePluginSimulator >> primitiveFileRename [
	^interpreterProxy primitiveFileRename
]

{ #category : #'as yet unclassified' }
FilePluginSimulator >> sqFile: file Read: count Into: byteArrayIndex At: startIndex [
	^interpreterProxy sqFile: file Read: count Into: byteArrayIndex At: startIndex
]

{ #category : #'as yet unclassified' }
FilePluginSimulator >> sqFile: file SetPosition: newPosition [
	^interpreterProxy sqFile: file SetPosition: newPosition
]

{ #category : #'as yet unclassified' }
FilePluginSimulator >> sqFile: file Truncate: truncatePosition [
	^interpreterProxy sqFile: file Truncate: truncatePosition
]

{ #category : #'as yet unclassified' }
FilePluginSimulator >> sqFile: file Write: count From: byteArrayIndex At: startIndex [
	^interpreterProxy sqFile: file Write: count From: byteArrayIndex At: startIndex
]

{ #category : #'as yet unclassified' }
FilePluginSimulator >> sqFileAtEnd: file [
	^interpreterProxy sqFileAtEnd: file
]

{ #category : #'as yet unclassified' }
FilePluginSimulator >> sqFileClose: file [
	^interpreterProxy sqFileClose: file
]

{ #category : #'as yet unclassified' }
FilePluginSimulator >> sqFileFlush: file [
	^interpreterProxy sqFileFlush: file
]

{ #category : #'as yet unclassified' }
FilePluginSimulator >> sqFileGetPosition: file [
	^interpreterProxy sqFileGetPosition: file
]

{ #category : #'as yet unclassified' }
FilePluginSimulator >> sqFileSize: file [
	^interpreterProxy sqFileSize: file
]
