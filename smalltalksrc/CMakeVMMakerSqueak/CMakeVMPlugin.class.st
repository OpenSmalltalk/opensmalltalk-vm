"
A CMakeVMPlugin is a  data bucket for things like:

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
	#name : #CMakeVMPlugin,
	#superclass : #Object,
	#instVars : [
		'module',
		'sources',
		'compilerdefinitions',
		'compilerflags',
		'externallibraries',
		'linkerflags',
		'includedirectories'
	],
	#category : #'CMakeVMMakerSqueak-VMPlugins'
}

{ #category : #accessing }
CMakeVMPlugin >> compilerdefinitions [

	^ compilerdefinitions
]

{ #category : #accessing }
CMakeVMPlugin >> compilerdefinitions: anObject [

	compilerdefinitions := anObject
]

{ #category : #accessing }
CMakeVMPlugin >> compilerflags [

	^ compilerflags
]

{ #category : #accessing }
CMakeVMPlugin >> compilerflags: anObject [

	compilerflags := anObject
]

{ #category : #accessing }
CMakeVMPlugin >> externallibraries [

	^ externallibraries
]

{ #category : #accessing }
CMakeVMPlugin >> externallibraries: anObject [

	externallibraries := anObject
]

{ #category : #accessing }
CMakeVMPlugin >> includedirectories [

	^ includedirectories
]

{ #category : #accessing }
CMakeVMPlugin >> includedirectories: anObject [

	includedirectories := anObject
]

{ #category : #'initialize-release' }
CMakeVMPlugin >> initialize [
"force CPlatformConfigurations to set my internal state explicitly by filling me with initial nonsense values. 
 If you see these in your CMakeLists.txt, then your configuration needs to replace them"
	sources := OrderedCollection with: 'sources' with: 'paths'.
	compilerdefinitions := OrderedCollection with:'-DCompiler' with: '-DDefinitions'.
	compilerflags := OrderedCollection with:'-compiler' with: '-flags'.
	externallibraries := OrderedCollection with:'cxternal'with:'library'.
	linkerflags := OrderedCollection with:'linker' with:'flags'.
	includedirectories := OrderedCollection with:'include' with:'directories'.
]

{ #category : #accessing }
CMakeVMPlugin >> linkerflags [

	^ linkerflags
]

{ #category : #accessing }
CMakeVMPlugin >> linkerflags: anObject [

	linkerflags := anObject
]

{ #category : #accessing }
CMakeVMPlugin >> module [
	^module
]

{ #category : #accessing }
CMakeVMPlugin >> module: anObject [

	module := anObject
]

{ #category : #accessing }
CMakeVMPlugin >> module:mString sources:sCollection compilerdefinitions: cdCollection compilerflags: cfCollection externallibraries:elCollection linkerflags: lfCollection includedirectories: idCollection [
	module:= mString.
	sources:= sCollection.
	compilerdefinitions:= cdCollection.
	compilerflags:= cfCollection.
	externallibraries := elCollection.
	linkerflags:= lfCollection.
	includedirectories := idCollection.
]

{ #category : #accessing }
CMakeVMPlugin >> sources [

	^ sources
]

{ #category : #accessing }
CMakeVMPlugin >> sources: anObject [

	sources := anObject
]
