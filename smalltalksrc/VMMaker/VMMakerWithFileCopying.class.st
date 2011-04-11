"
This subclass of VMMaker is a hopefully temporary way to provide the copying of files from platforms/{Cross|foo} to src/ until all platforms are able to do their compiling with the platforms tree in place.

The default class will NOT do the file copies and gradually the platform specific classes can be removed as they all catch up.
"
Class {
	#name : #VMMakerWithFileCopying,
	#superclass : #VMMaker,
	#category : #'VMMaker-Building'
}

{ #category : #'copying files' }
VMMakerWithFileCopying >> copyCrossPlatformFilesFor: plugin internal: aBoolean [
	| srcDir targetDir |
	[srcDir := self crossPlatformPluginsDirectory directoryNamed: plugin moduleName.
	targetDir := aBoolean ifTrue:[self internalPluginsDirectoryFor: plugin]
					ifFalse:[self externalPluginsDirectoryFor: plugin].
	logger show: 'Copy any cross platform files from: ' , srcDir printString , ' to ' , targetDir printString; cr.
	self copyFilesFromSourceDirectory: srcDir toTargetDirectory: targetDir]
		on: FileStreamException
		do: ["If any file related exceptions get here, we've had some problem, probably path of permissions. Raise the general exception"
			^ self couldNotFindPlatformFilesFor: plugin]
]

{ #category : #'copying files' }
VMMakerWithFileCopying >> copyCrossPlatformVMFiles [
	| srcDir targetDir vmDirName |
	vmDirName := self class coreVMDirName.

	"Is there a crossPlatformDirectory subdirectory called 'vmDirName'?"
	(self crossPlatformDirectory directoryExists: vmDirName)
		ifTrue: [srcDir := self crossPlatformDirectory directoryNamed: vmDirName.
			targetDir := self coreVMDirectory.
			self copyFilesFromSourceDirectory: srcDir toTargetDirectory: targetDir]
]

{ #category : #'copying files' }
VMMakerWithFileCopying >> copyPlatformFilesFor: plugin internal: aBoolean [
	| srcDir targetDir |
	[srcDir := self platformPluginsDirectory directoryNamed: plugin moduleName.
	targetDir := aBoolean ifTrue:[self internalPluginsDirectoryFor: plugin]
					ifFalse:[self externalPluginsDirectoryFor: plugin].
	logger show: 'Copy any platform files from: ' , srcDir printString , ' to ' , targetDir printString; cr.
	self copyFilesFromSourceDirectory: srcDir toTargetDirectory: targetDir]
		on: FileStreamException
		do: ["If any file related exceptions get here, we've had some problem, probably path of permissions. Raise the general exception"
			^ self couldNotFindPlatformFilesFor: plugin]
]

{ #category : #'copying files' }
VMMakerWithFileCopying >> copyPlatformVMFiles [
	| srcDir targetDir vmDirName |
	vmDirName := self class coreVMDirName.

	"Is there a platformDirectory subdirectory called 'vmDirName'?"
	(self platformDirectory directoryExists: vmDirName)
		ifTrue: [srcDir := self platformDirectory directoryNamed: vmDirName.
			targetDir := self coreVMDirectory.
			self copyFilesFromSourceDirectory: srcDir toTargetDirectory: targetDir]
]

{ #category : #'copying files' }
VMMakerWithFileCopying >> processAssortedFiles [
	"See the comment in VMMaker> processAssortedFiles first.
	This version of the method will copy any miscellaneous files/dirs from the cross-platformDirectory -  readme files etc, then from the platform specific directory - makefiles, utils etc. "
	 
	| srcDir |
	"Is there a crossPlatformDirectory subdirectory called 'misc'?"
	(self crossPlatformDirectory directoryExists: 'misc')
		ifTrue: [srcDir := self crossPlatformDirectory directoryNamed: 'misc'.
			self copyFilesFromSourceDirectory: srcDir toTargetDirectory: self sourceDirectory].
	"Is there a platformDirectory subdirectory called 'misc'?"
	(self platformDirectory directoryExists: 'misc')
		ifTrue: [srcDir := self platformDirectory directoryNamed: 'misc'.
			self copyFilesFromSourceDirectory: srcDir toTargetDirectory: self sourceDirectory].

	"Now copy any files that are always copied for all platforms"
	super processAssortedFiles

]

{ #category : #'copying files' }
VMMakerWithFileCopying >> processFilesForCoreVM [
	"When using a copying version of VMMaker, copy any cross-platform files from the crossPlatformDir and then copy any files relating to the core vm from the platformDirectory's vm subdirectory."
	super processFilesForCoreVM.

	"Is there a crossPlatformDirectory subdirectory called 'vmDirName'?"
	self copyCrossPlatformVMFiles.

	"Is there a platformDirectory subdirectory called 'vmDirName'?"
	self copyPlatformVMFiles

]

{ #category : #'copying files' }
VMMakerWithFileCopying >> processFilesForExternalPlugin: plugin [ 
	"See comment in VMMaker>processFileForExternalPlugin: first.
	When using a copying version of VMMaker, copy any files relating to the external plugin from the crossPlatform & platformDirectory subdir 'plugins'"

	super processFilesForExternalPlugin: plugin.

	"This version of the method has to actually copy files around"
	self copyCrossPlatformFilesFor: plugin internal: false;
		copyPlatformFilesFor: plugin internal: false
]

{ #category : #'copying files' }
VMMakerWithFileCopying >> processFilesForInternalPlugin: plugin [ 
	"See comment in VMMaker>processFileForInternalPlugin: first.
	When using a copying version of VMMaker, copy any files relating to the internal plugin from the crossPlatform & platformDirectory subdir 'plugins'"

	super processFilesForInternalPlugin: plugin.

	"This version of the method has to actually copy files around"
	self copyCrossPlatformFilesFor: plugin internal: true;
		copyPlatformFilesFor: plugin internal: true
]
