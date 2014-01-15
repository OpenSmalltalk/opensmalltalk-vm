"
A SpurBootstrapMonticelloPackagePatcher is used to construct a new set of patched Monticello packages for Spur.  The use case is some bootstrap process loads a set of Monticello packages.  To repeat the bootstrap with a Spur image the bootstrap must use suitably patched Monticello packages containing the new method versions on the class side of SpurBootstrap.

Instance Variables
	destDir:			<FileDirectory>
	sourceDir:		<FileDirectory>

destDir
	- directory to which patched packages are to be written

sourceDir
	- directory from which packages to be patched are to be read
"
Class {
	#name : #SpurBootstrapMonticelloPackagePatcher,
	#superclass : #Object,
	#instVars : [
		'sourceDir',
		'destDir'
	],
	#category : #'Cog-Bootstrapping'
}

{ #category : #'private-accessing' }
SpurBootstrapMonticelloPackagePatcher >> filesForPackage: package in: aDirectory [
	^aDirectory fileNames select:
		[:fileName|
		(fileName beginsWith: package name)
		 and: [(fileName at: package name size + 1) isLetter not]]
]

{ #category : #initialization }
SpurBootstrapMonticelloPackagePatcher >> from: sourceDirName to: destDirName [
	sourceDir := FileDirectory on: sourceDirName.
	destDir := FileDirectory on: destDirName
]

{ #category : #'private-accessing' }
SpurBootstrapMonticelloPackagePatcher >> packages [
	"SpurBootstrapMonticelloPackagePatcher new packages"
	| packages |
	packages := Set new.
	SpurBootstrap new prototypeClassNameMetaSelectorMethodDo:
		[:className :isMeta :selector :method| | class |
		 class := Smalltalk classNamed: className.
		 isMeta ifTrue:
			[class := class class].
		 packages add: ((class includesSelector: selector)
							ifTrue: [PackageOrganizer default packageOfMethod: (class >> selector) methodReference]
							ifFalse: [PackageOrganizer default  packageOfClass: class])].
	^packages
]

{ #category : #'private-accessing' }
SpurBootstrapMonticelloPackagePatcher >> packagesAndPatches [
	"SpurBootstrapMonticelloPackagePatcher new packagesAndPatches"
	| packagesAndPatches |
	packagesAndPatches := Dictionary new.
	SpurBootstrap new prototypeClassNameMetaSelectorMethodDo:
		[:className :isMeta :selector :method| | class methodReference |
		 class := Smalltalk classNamed: className.
		 isMeta ifTrue:
			[class := class class].
		 methodReference := (class includesSelector: selector) ifTrue:
								[(class >> selector) methodReference].
		 (packagesAndPatches
				at: (methodReference
						ifNotNil: [PackageOrganizer default packageOfMethod: methodReference]
						ifNil: [PackageOrganizer default  packageOfClass: class])
				ifAbsentPut: [OrderedCollection new])
			add: (MCAddition of: (MCMethodDefinition
									className: className
									classIsMeta: isMeta
									selector: selector
									category: (methodReference
												ifNotNil: [methodReference category]
												ifNil: [Categorizer default])
									timeStamp: method timeStamp
									source: (method getSourceFromFile asString allButFirst: method selector size - selector size)))].
	^packagesAndPatches
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> patch [
	"(SpurBootstrapMonticelloPackagePatcher new
			from: '/Users/eliot/Glue/repositories/nsboot/smalltalk'
			to: '/Users/eliot/Glue/repositories/spurnsboot/smalltalk')
		patch"
	self packagesAndPatches keysAndValuesDo:
		[:package :patches|
		 (self filesForPackage: package in: sourceDir) do:
			[:packageFile|
			 self patchPackage: packageFile with: patches for: package]]
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> patchForPackage: package withPatches: patches snapshot: snapshot [
	(package includesClass: Character) ifTrue:
		[snapshot halt].
	^MCPatch operations: patches
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> patchPackage: packageFileName with: patches for: package [
	| version newVersion |
	version := self versionFor: packageFileName.
	newVersion := self version: version withPatches: patches for: package.
	self storeVersion: newVersion
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> storeVersion: newVersion [
	[(MCDirectoryRepository new directory: destDir) storeVersion: newVersion]
		on: FileExistsException
		do: [:ex| ex resume: (ex fileClass forceNewFileNamed: ex fileName)]
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> version: version withPatches: patches for: package [
	| snapshot ancestry |
	snapshot := MCPatcher
					apply: (self patchForPackage: package withPatches: patches snapshot: version snapshot)
					to: version snapshot.
	ancestry := MCWorkingAncestry new addAncestor: version info.
	^MCVersion
		package: version package
		info: (ancestry
				infoWithName: version info name
				message: version info name, ' patched for Spur')
		snapshot: snapshot
		dependencies: {} "punt on computing dependencies; there are't any so far"

]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> versionFor: packageFileName [
	^sourceDir
		readOnlyFileNamed: packageFileName
		do: [:fs|
			((MCVersionReader readerClassForFileNamed: fs fullName)
				on: fs fileName: fs fullName)
					version]
]
