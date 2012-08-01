"
My subclasses describing a configuration/settings necessary to build some third-party library used by VM
or by one of it's plugins.

We cannot use cmake configuration for those libraries, since most of them having own 
configuration/make scripts which build that library.

I serve as a convenience layer for building those libraries and connecting them with cmake configuration,
as well as provide necessary information, what output file(s) should be bundled with virtual machine.

"
Class {
	#name : #CMThirdpartyLibrary,
	#superclass : #Object,
	#instVars : [
		'gen',
		'vmGen',
		'configurationFlags'
	],
	#category : #'CMakeVMMaker-Libs'
}

{ #category : #'as yet unclassified' }
CMThirdpartyLibrary class >> canonicalName [
	"answer the library canonical name, like 
		'freetype2'
		or 'cairo' 
		etc.
		
	Note , this method is used to find the corresponding library
	from all subclasses of CMThirdpartyLibrary	
	"
	^ self subclassResponsibility
]

{ #category : #'as yet unclassified' }
CMThirdpartyLibrary class >> named: aName config: aCPlatformConfig [

	^ (self allSubclasses detect: [:cls | 
		cls canonicalName = aName and: [ cls supports: aCPlatformConfig ] ])
		new
]

{ #category : #'as yet unclassified' }
CMThirdpartyLibrary class >> platformName [ 
	^nil
]

{ #category : #testing }
CMThirdpartyLibrary class >> supports: aConfig [
	"default implementation"
	^ self platformName = aConfig platformName 
]

{ #category : #'package properties' }
CMThirdpartyLibrary >> archiveMD5Sum [
	"answer the MD5 checksum (in string) for downloaded library archive 
	(to check that downloaded file is not corrupt).
	
	You can take this sum by issuing:
	  md5 filename
	from command line
	"
	^ self subclassResponsibility
]

{ #category : #'generating actions' }
CMThirdpartyLibrary >> build [

	self subclassResponsibility
]

{ #category : #'package properties' }
CMThirdpartyLibrary >> buildTarget [
	^ self canonicalName
]

{ #category : #'package properties' }
CMThirdpartyLibrary >> canonicalName [
	"answer the library canonical name, like 
		'freetype2'
		or 'cairo' 
		etc"
	^ self class canonicalName
]

{ #category : #settings }
CMThirdpartyLibrary >> configurationFlags [ 
	^(configurationFlags 
		ifNil: [ self defaultConfigurationFlags ])
		reduce: [ :a :b | a, ' ', b]
]

{ #category : #settings }
CMThirdpartyLibrary >> configurationFlags: aCollection [
	configurationFlags := aCollection
	
]

{ #category : #'generating actions' }
CMThirdpartyLibrary >> copyArtefacts [

	self subclassResponsibility
]

{ #category : #settings }
CMThirdpartyLibrary >> defaultConfigurationFlags [ 
	^#(
		'CFLAGS=''-arch i386''' 
		'LDFLAGS=''-arch i386''')
]

{ #category : #'generating actions' }
CMThirdpartyLibrary >> defineAsTarget [

	self subclassResponsibility
]

{ #category : #'generating actions' }
CMThirdpartyLibrary >> defineGlobalTargets [
	self subclassResponsibility
]

{ #category : #'package properties' }
CMThirdpartyLibrary >> dependencies [
	^ #()
]

{ #category : #'generating actions' }
CMThirdpartyLibrary >> download [

	"Produce output to download library archive.
	By default, we use .tgz extension.. since it is most often used by OSS.
	Note, that we check if file is already present, to not download it every time
	we build"	
	
	gen puts:
'if (NOT EXISTS "${workDir}/${libName}.tgz")
	Message("Downloading ${url} ....")
	Message("Into: ${workDir}/${libName}.tgz")
	
	FILE(DOWNLOAD
		${url}
	 	"${workDir}/${libName}.tgz"
		SHOW_PROGRESS
		EXPECTED_MD5 ${md5sum}
	)
endif (NOT EXISTS "${workDir}/${libName}.tgz")
'
]

{ #category : #'package properties' }
CMThirdpartyLibrary >> downloadURL [
	"answer the url where given library can be downloaded from"
	^ self subclassResponsibility
]

{ #category : #'generating cmake file' }
CMThirdpartyLibrary >> generate [

	gen message: 'Configuring thirdparty package: ', self canonicalName.
	
	self 
		setVariables;
		download;
		unpack;
		build;
		copyArtefacts;
		defineAsTarget.
]

{ #category : #'generating cmake file' }
CMThirdpartyLibrary >> generateFor: aVMGenerator [

	| libDir stream |
	
	vmGen := aVMGenerator.
	
	gen := CMakeGenerator new
		output: (String new writeStream).
	
	libDir := (aVMGenerator thirdpartyDir / self canonicalName) assureExistence.

	stream := libDir forceNewFileNamed: gen outputFileName.
	stream ifNil: [ self error: 'Cannot write ',  gen outputFileName , 'to: ', libDir fullName ].

	self generate.

	stream nextPutAll: (vmGen config fixLineEndsOf: gen output contents); close.

	vmGen addSubdirectory:  vmGen thirdpartyDirName , '/' , self canonicalName.
	self defineGlobalTargets.
	
]

{ #category : #'package properties' }
CMThirdpartyLibrary >> libraryFileName [
	"answer the built library file name"

	self subclassResponsibility
]

{ #category : #'generating actions' }
CMThirdpartyLibrary >> setVariables [

	gen
		set: #libName toString: self canonicalName;
		set: #workDir toString: '${thirdpartyDir}/${libName}';
		set: #unpackedDirName toString: self unpackedDirName;
		set: #libSourcesDir toString: '${workDir}/${unpackedDirName}';
		set: #url toString: self downloadURL;
		set: #md5sum toString: self archiveMD5Sum;
		set: #installPrefix toString: '${thirdpartyDir}/out'.
]

{ #category : #exports }
CMThirdpartyLibrary >> targetForLinking [
	"Answer a target or path to library to link with, which can be used by 
	external plugins or VM module"

	^ '${externalModulesDir}/', self libraryFileName
]

{ #category : #'generating actions' }
CMThirdpartyLibrary >> unpack [
	"produce commands for unpacking the library archive.
	
	the output of this command should use a directory
	${workDir}/${libName}
	where the unpacked library sources will be located.
	
	see #setVariables method for understanding what variables used here
	"

	gen set: #unpackTarget toString: '${libSourcesDir}/touch.cmake'.
	
	gen puts:
'add_custom_command(OUTPUT "${unpackTarget}"
		COMMAND tar -xzf "${libName}.tgz" 
		COMMAND touch "${unpackTarget}"
		COMMENT "Unpacking ${libName} ... "
	)
'.

]

{ #category : #'package properties' }
CMThirdpartyLibrary >> unpackedDirName [
	"answer the directory name, which is created after unpacking
	downloaded archive i.e.
	
	the archive downloaded from 
	
	http://ftp.igh.cnrs.fr/pub/nongnu/freetype/freetype-2.4.9.tar.gz
	
	if untarred, will create
	freetype-2.4.9
	subdirectory. But since there is no conventions, it could be anything,
	so we should specify it here, so build system will know where to look for unpacked files"

	^ self subclassResponsibility
]
