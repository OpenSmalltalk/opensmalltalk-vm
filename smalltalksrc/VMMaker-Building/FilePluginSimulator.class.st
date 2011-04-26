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

{ #category : #simulation }
FilePluginSimulator >> fileValueOf: objectPointer [
	^interpreterProxy interpreter fileValueOf: objectPointer
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
FilePluginSimulator >> primitiveFileDelete [ 
	^interpreterProxy interpreter primitiveFileDelete 
]

{ #category : #simulation }
FilePluginSimulator >> primitiveFileOpen [
	^interpreterProxy interpreter primitiveFileOpen
]

{ #category : #simulation }
FilePluginSimulator >> primitiveFileRename [
	^interpreterProxy primitiveFileRename
]

{ #category : #simulation }
FilePluginSimulator >> primitiveFileStdioHandles [
	^interpreterProxy interpreter primitiveFileStdioHandles
]

{ #category : #simulation }
FilePluginSimulator >> sqFile: file Read: count Into: byteArrayIndex At: startIndex [
	^interpreterProxy interpreter sqFile: file Read: count Into: byteArrayIndex At: startIndex
]

{ #category : #simulation }
FilePluginSimulator >> sqFile: file SetPosition: newPosition [
	^interpreterProxy interpreter sqFile: file SetPosition: newPosition
]

{ #category : #simulation }
FilePluginSimulator >> sqFile: file Truncate: truncatePosition [
	^interpreterProxy sqFile: file Truncate: truncatePosition
]

{ #category : #simulation }
FilePluginSimulator >> sqFile: file Write: count From: byteArrayIndex At: startIndex [
	^interpreterProxy interpreter sqFile: file Write: count From: byteArrayIndex At: startIndex
]

{ #category : #simulation }
FilePluginSimulator >> sqFileAtEnd: file [
	^interpreterProxy interpreter sqFileAtEnd: file
]

{ #category : #simulation }
FilePluginSimulator >> sqFileClose: file [
	^interpreterProxy interpreter sqFileClose: file
]

{ #category : #simulation }
FilePluginSimulator >> sqFileFlush: file [
	^interpreterProxy interpreter sqFileFlush: file
]

{ #category : #simulation }
FilePluginSimulator >> sqFileGetPosition: file [
	^interpreterProxy interpreter sqFileGetPosition: file
]

{ #category : #simulation }
FilePluginSimulator >> sqFileSize: file [
	^interpreterProxy sqFileSize: file
]
