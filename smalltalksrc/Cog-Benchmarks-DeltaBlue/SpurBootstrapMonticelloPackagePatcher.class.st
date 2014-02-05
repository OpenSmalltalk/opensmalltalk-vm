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

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> modifiedCharacterDefinitionsIn: definitions [
	| rewriter |
	rewriter := RBParseTreeRewriter new.
	rewriter replace: 'value' with: 'self asInteger'.
	^((definitions select: [:d| d isMethodDefinition and: [d fullClassName = #Character]])
		collect: [:d| { d. self patchDefinition: d withRewriter: rewriter} ]
		thenSelect: [:pair| pair first source ~= pair second source])
			collect: [:pair| pair second]
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
		[:className :isMeta :selector :method| | class methodReference source |
		 class := Smalltalk classNamed: className.
		 isMeta ifTrue:
			[class := class class].
		 methodReference := (class includesSelector: selector) ifTrue:
								[(class >> selector) methodReference].
		 source := method getSourceFromFile asString allButFirst: method selector size - selector size.
		 source first ~= selector first ifTrue:
			[source replaceFrom: 1 to: selector size with: selector startingAt: 1].
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
									source: source))].
	^packagesAndPatches
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> patch [
	"(SpurBootstrapMonticelloPackagePatcher new
			from: '/Users/eliot/Glue/repositories/nsboot/smalltalk'
			to: '/Users/eliot/Glue/repositories/spurnsboot/smalltalk')
		patch"
	"(SpurBootstrapMonticelloPackagePatcher new
			from: '/Users/eliot/Glue/repositories/nsboot/Squeak4.3/squeak-package-cache'
			to: '/Users/eliot/Glue/repositories/nsboot/Squeak4.3/package-cache')
		patch"
	self packagesAndPatches keysAndValuesDo:
		[:package :patches|
		 (self filesForPackage: package in: sourceDir) do:
			[:packageFile|
			 self patchPackage: packageFile with: patches for: package]]
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> patchDefinition: aMCMethodDefinition withRewriter: aRBParseTreeRewriter [ 
	| parseTree |
	parseTree := RBParser
					parseMethod: aMCMethodDefinition source
					onError: [:str :pos | self halt].
	aRBParseTreeRewriter executeTree: parseTree.
	^MCMethodDefinition 
		className: aMCMethodDefinition className
		classIsMeta:aMCMethodDefinition classIsMeta
		selector: aMCMethodDefinition selector
		category: aMCMethodDefinition category
		timeStamp: aMCMethodDefinition timeStamp
		source: aRBParseTreeRewriter tree newSource
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> patchForPackage: package withPatches: patches snapshot: snapshot [
	(package includesClass: Character) ifTrue:
		[patches addAll: ((self modifiedCharacterDefinitionsIn: snapshot definitions) 
							select:
								[:def|
								 patches noneSatisfy:
									[:addition|
									addition definition selector = def selector
									and: [addition definition className = def className
									and: [addition definition classIsMeta = def classIsMeta]]]]
							thenCollect:
								[:def| MCAddition of: def])].
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
				message:	version info name,
							' patched for Spur by ',
							(CCodeGenerator new shortMonticelloDescriptionForClass: self class))
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
