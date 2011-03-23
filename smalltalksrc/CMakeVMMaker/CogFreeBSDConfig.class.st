Class {
	#name : #CogFreeBSDConfig,
	#superclass : #CogUnixConfig,
	#category : #'CMakeVMMaker-FreeBSD-Cog'
}

{ #category : #'as yet unclassified' }
CogFreeBSDConfig >> compilerFlags [

	"Common compiler flags
	
	
	LSB_FIRST=1 means that target platform is little endian. 
	set it to 0 for big-endian platforms
	
	"
	
	^ super compilerFlags, ' -DNOEXECINFO'
]
