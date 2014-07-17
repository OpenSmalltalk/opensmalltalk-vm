"
A CMakeVMDriverWrapper is a data bucket for things like:

'vm-display-Quartz' 
'vm-display-X11'  
'vm-display-custom'  
'vm-display-fbdev'  
'vm-display-null'  
'vm-sound-ALSA'  
'vm-sound-MacOSX'  
'vm-sound-NAS'  
'vm-sound-OSS'  
'vm-sound-Sun'  
'vm-sound-custom'
'vm-sound-null'



"
Class {
	#name : #CMakeVMDriverWrapper,
	#superclass : #Object,
	#instVars : [
		'driver',
		'sources',
		'compilerdefinitions',
		'compilerflags',
		'externallibraries',
		'linkerflags',
		'includedirectories'
	],
	#category : #'CMakeVMMakerSqueak-VMDriver'
}

{ #category : #accessing }
CMakeVMDriverWrapper >> compilerdefinitions [

	^ compilerdefinitions
]

{ #category : #accessing }
CMakeVMDriverWrapper >> compilerdefinitions: anObject [

	compilerdefinitions := anObject
]

{ #category : #accessing }
CMakeVMDriverWrapper >> compilerflags [

	^ compilerflags
]

{ #category : #accessing }
CMakeVMDriverWrapper >> compilerflags: anObject [

	compilerflags := anObject
]

{ #category : #accessing }
CMakeVMDriverWrapper >> driver [

	^ driver
]

{ #category : #accessing }
CMakeVMDriverWrapper >> driver: anObject [

	driver := anObject
]

{ #category : #accessing }
CMakeVMDriverWrapper >> driver:dString sources:sCollection compilerdefinitions: cdCollection compilerflags: cfCollection externallibraries:elCollection linkerflags: lfCollection includedirectories: idCollection [
	driver:= dString.
	sources:= sCollection.
	compilerdefinitions:= cdCollection.
	compilerflags:= cfCollection.
	externallibraries := elCollection.
	linkerflags:= lfCollection.
	includedirectories := idCollection.
]

{ #category : #accessing }
CMakeVMDriverWrapper >> externallibraries [

	^ externallibraries
]

{ #category : #accessing }
CMakeVMDriverWrapper >> externallibraries: anObject [

	externallibraries := anObject
]

{ #category : #accessing }
CMakeVMDriverWrapper >> includedirectories [

	^ includedirectories
]

{ #category : #accessing }
CMakeVMDriverWrapper >> includedirectories: anObject [

	includedirectories := anObject
]

{ #category : #'initialize-release' }
CMakeVMDriverWrapper >> initialize [
"force CPlatformConfigurations to set my internal state explicitly by filling me with initial nonsense values"
	sources := OrderedCollection with: 'sources' with: 'paths'.
	compilerdefinitions := OrderedCollection with:'-DCompiler' with: '-DDefinitions'.
	compilerflags := OrderedCollection with:'-compiler' with: '-flags'.
	externallibraries := OrderedCollection with:'cxternal'with:'library'.
	linkerflags := OrderedCollection with:'linker' with:'flags'.
	includedirectories := OrderedCollection with:'include' with:'directories'.
]

{ #category : #accessing }
CMakeVMDriverWrapper >> linkerflags [

	^ linkerflags
]

{ #category : #accessing }
CMakeVMDriverWrapper >> linkerflags: anObject [

	linkerflags := anObject
]

{ #category : #accessing }
CMakeVMDriverWrapper >> sources [

	^ sources
]

{ #category : #accessing }
CMakeVMDriverWrapper >> sources: anObject [

	sources := anObject
]
