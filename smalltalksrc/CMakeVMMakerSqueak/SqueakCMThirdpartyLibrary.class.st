"
N.B. tty: I have not parsed these in depth as of 2014.12.09

A SqueakCMThirdpartyLibrary is the root library for copies of classes in CMakeVMMaker-Libs.  
I replace only the Squeak incompatible methods of my parent


"
Class {
	#name : #SqueakCMThirdpartyLibrary,
	#superclass : #CMThirdpartyLibrary,
	#category : #'CMakeVMMakerSqueak-Libs'
}

{ #category : #'as yet unclassified' }
SqueakCMThirdpartyLibrary class >> canonicalName [
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
SqueakCMThirdpartyLibrary class >> named: aName config: aCPlatformConfig [

	^ (self allSubclasses detect: [:cls | 
		cls canonicalName = aName and: [ cls supports: aCPlatformConfig ] ])
		new
]

{ #category : #'as yet unclassified' }
SqueakCMThirdpartyLibrary class >> platformName [ 
	^nil
]

{ #category : #'as yet unclassified' }
SqueakCMThirdpartyLibrary class >> supports: aConfig [
	"default implementation"
	^ self platformName = aConfig platformName 
]

{ #category : #'as yet unclassified' }
SqueakCMThirdpartyLibrary >> generateFor: aVMGenerator [

	| libDir stream contents |
	self flag:'tty'. "This l must be transformed to generateByTemplateFor: and the output converted to CMakeTemplates"
	self break.
	vmGen := aVMGenerator.
	
	gen := CMakeGeneratorForSqueak new
		output: (String new writeStream).
	
	libDir := (aVMGenerator thirdpartyDir / self canonicalName) assureExistence.

	stream := String new writeStream.
	
	self generate.

	stream nextPutAll: (vmGen config fixLineEndsOf: gen output contents).

	contents := stream contents. 
	
	(self isFile: (libDir  / gen outputFileName) fullName hasContents: contents) ifFalse: [
		"contents changed, update the file. Because fucking cmake will force rebuild everything if we change its modification date
		without changing its contents"
		(FileStream forceNewFileNamed: (libDir  / gen outputFileName) pathName) nextPutAll: contents; close.
		].
	

	vmGen addSubdirectory:  vmGen thirdpartyDirName , '/' , self canonicalName.
	self defineGlobalTargets.
	
]
