"
I serve as a facade to ease building Cog VM with CMakeVMMakerSqueak configs


"
Class {
	#name : #SqueakBSDX86Builder,
	#superclass : #Object,
	#category : #'CMakeVMMakerSqueak-Builder'
}

{ #category : #building }
SqueakBSDX86Builder class >> buildBSD [
	^ self new buildBSD
]

{ #category : #documentation }
SqueakBSDX86Builder class >> buildDirNameForBSD [
	^ self new buildDirNameForBSD
]

{ #category : #building }
SqueakBSDX86Builder >> buildBSD [
	SqueakFreeBSDCogV3Config new  
		addExternalPlugins: #(  FT2Plugin );
		addInternalPlugins: #( UnixOSProcessPlugin );
		generateSources; generate.

]

{ #category : #building }
SqueakBSDX86Builder >> buildDirNameForBSD [
	^SqueakFreeBSDCogV3Config new  buildDirName

]

{ #category : #initialization }
SqueakBSDX86Builder >> initialize [

	"a stupid temporary hack to workaround initialization problems"

	Cogit allSubclassesDo: [ :each | each initializeWithOptions: (VMMaker new instVarNamed: 'optionsDictionary') ]
]
