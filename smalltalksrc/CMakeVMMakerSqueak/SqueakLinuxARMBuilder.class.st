"
I serve as a facade to ease building Cog VM with CMakeVMMakerSqueak configs


"
Class {
	#name : #SqueakLinuxARMBuilder,
	#superclass : #Object,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #documentation }
SqueakLinuxARMBuilder class >> buildDirNameForLinux32 [
	^ self new buildDirNameForLinux32
]

{ #category : #building }
SqueakLinuxARMBuilder class >> buildLinux32 [
	^ self new buildLinux32
]

{ #category : #documentation }
SqueakLinuxARMBuilder >> buildDirNameForBSD32 [
	^SqueakFreeBSDCogV3Config new  buildDirName

]

{ #category : #building }
SqueakLinuxARMBuilder >> buildStackV3CrossRaspbian [ 

	Linux32ARMv6StackV3CrossRaspbianConfig new  
		generateForRelease;
		"generateForDebug;"
		addExternalPlugins: #(  FT2Plugin );
		addInternalPlugins: #( UnixOSProcessPlugin );
		generateSources; generate.

]

{ #category : #initialization }
SqueakLinuxARMBuilder >> initialize [

	"a stupid temporary hack to workaround initialization problems"

	Cogit allSubclassesDo: [ :each | each initializeWithOptions: (VMMaker new instVarNamed: 'optionsDictionary') ]
]
