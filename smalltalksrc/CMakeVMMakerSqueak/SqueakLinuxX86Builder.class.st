"
I serve as a facade to ease building Cog VM with CMakeVMMakerSqueak configs


"
Class {
	#name : #SqueakLinuxX86Builder,
	#superclass : #Object,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #documentation }
SqueakLinuxX86Builder class >> buildDirNameForLinux32 [
	^ self new buildDirNameForLinux32
]

{ #category : #building }
SqueakLinuxX86Builder class >> buildLinux32 [
	^ self new buildLinux32
]

{ #category : #building }
SqueakLinuxX86Builder >> buildBSD32 [ 

	SqueakFreeBSDCogV3Config new  
		generateForRelease;
		"generateForDebug;"
		addExternalPlugins: #(  FT2Plugin );
		addInternalPlugins: #( UnixOSProcessPlugin );
		generateSources; generate.

]

{ #category : #documentation }
SqueakLinuxX86Builder >> buildDirNameForBSD32 [
	^SqueakFreeBSDCogV3Config new  buildDirName

]

{ #category : #initialization }
SqueakLinuxX86Builder >> initialize [

	"a stupid temporary hack to workaround initialization problems"

	Cogit allSubclassesDo: [ :each | each initializeWithOptions: (VMMaker new instVarNamed: 'optionsDictionary') ]
]
