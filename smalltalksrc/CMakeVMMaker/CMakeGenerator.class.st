"
a base class for generating cmake files.
Mainly provides a helper methods of cmake commands api.
"
Class {
	#name : #CMakeGenerator,
	#superclass : #Object,
	#instVars : [
		'output'
	],
	#category : #CMakeVMMaker
}

{ #category : #'cmake commands' }
CMakeGenerator >> addDefinitions: aString [
	^ self cmd: 'add_definitions' params: aString
]

{ #category : #'cmake commands' }
CMakeGenerator >> addExternalLibraries: libs [

	libs do: [:each | self addExternalLibrary: each ]
]

{ #category : #'cmake commands' }
CMakeGenerator >> addExternalLibrary: aLibrary [ 

	self cmd: 'target_link_libraries' 
		params: self moduleName , ' ' , aLibrary.
		

]

{ #category : #'cmake commands' }
CMakeGenerator >> addFrameworks: aCollection [ 
	"for mac only "
	aCollection
		do: [:each | 
			self cmd: 'find_library' params:  each , '_FMWK ', each.
			self addExternalLibrary: '${', each , '_FMWK}' ]
]

{ #category : #'cmake commands' }
CMakeGenerator >> addProperty: propertyString value: valueString [ 
	self puts: 'set_target_properties(' , self moduleName , ' PROPERTIES ' , propertyString , ' "' , valueString, '")'

]

{ #category : #'sources management' }
CMakeGenerator >> addSource: aFileName [

	^ self addSources: { aFileName }
]

{ #category : #'sources management' }
CMakeGenerator >> addSources: aFileNames [

	^ self addSources: aFileNames prefixed: ''
]

{ #category : #'sources management' }
CMakeGenerator >> addSources: aFileNames prefixed: aPrefix [

	| names |
	names := aFileNames inject: '' into: [:res :each | res , ' "' , aPrefix, each, '"' ].
	
	self puts: 'list(APPEND sources ', names , ')'
]

{ #category : #'cmake commands' }
CMakeGenerator >> addSubdirectory: aDir [

	^ self cmd: 'add_subdirectory' qparams: aDir. 

]

{ #category : #'cmake commands' }
CMakeGenerator >> addXCodeProperty: propertyString value: valueString [ 
	self 
		addProperty: 'XCODE_ATTRIBUTE_' , propertyString 
		value: valueString

]

{ #category : #'code generation' }
CMakeGenerator >> captureOutputDuring: aBlock [
	| old result |
	
	old := output.
	output :=  String new writeStream.
	
	aBlock value.
	
	result := output.
	output := old.
	
	^ result contents
]

{ #category : #'cmake commands' }
CMakeGenerator >> cmd: cmdName params: aString [

	output nextPutAll: cmdName;
		nextPut: $(;
		nextPutAll: aString;
		nextPut: $);
		cr

]

{ #category : #'cmake commands' }
CMakeGenerator >> cmd: cmdName qparams: aString [
	"quoted params"
	output nextPutAll: cmdName;
		nextPutAll: '("';
		nextPutAll: aString;
		nextPutAll: '")';
		cr

]

{ #category : #'code generation' }
CMakeGenerator >> generate [
	self subclassResponsibility.
]

{ #category : #'cmake commands' }
CMakeGenerator >> include: aFileName [
	^ self cmd: 'include' params: aFileName
]

{ #category : #'cmake commands' }
CMakeGenerator >> includeDirectories: aString [
	^ self cmd: 'include_directories' params: aString
]

{ #category : #'cmake commands' }
CMakeGenerator >> message: aString [
	
	self cmd: 'message' qparams: aString.
]

{ #category : #accessing }
CMakeGenerator >> moduleName [
	self subclassResponsibility
]

{ #category : #accessing }
CMakeGenerator >> outputFileName [
	^ 'CMakeLists.txt'
]

{ #category : #'as yet unclassified' }
CMakeGenerator >> printHeader [
	
	self puts: '# This is automatically generated file using ', self configurationName, ' on ',
		Date current asString, ' ' , Time current asString;
		puts: 'cmake_minimum_required(VERSION 2.6.2)';
		puts: 'include(CMakeDetermineSystem)'.
]

{ #category : #'cmake commands' }
CMakeGenerator >> project: aProjectName [
	self cmd: 'project' qparams: aProjectName

]

{ #category : #'as yet unclassified' }
CMakeGenerator >> puts: aString [
	output nextPutAll: aString; cr
]

{ #category : #'cmake commands' }
CMakeGenerator >> set: variableName to: aValueString [

	self cmd: 'set' params: variableName , ' ' , aValueString
]

{ #category : #'cmake commands' }
CMakeGenerator >> set: variableName toString: aValueString [

	^ self set: variableName to: '"', (aValueString copyReplaceAll: '"' with: '\"'), '"'
]

{ #category : #'cmake commands' }
CMakeGenerator >> setTargetProperties: properties [ 
	self cmd: 'set_target_properties' params: self moduleName, ' PROPERTIES ', properties 
]

{ #category : #'cmake commands' }
CMakeGenerator >> setTargetProperty: propertyString to: aString [
	self 
		cmd: 'set_target_properties'
		params: (String streamContents: [ :stream |
			stream 
				nextPutAll: self moduleName;
				nextPutAll: ' PROPERTIES ';
				nextPutAll: propertyString;
				space;  
				nextPutAll: aString ])
]

{ #category : #'cmake commands' }
CMakeGenerator >> setTargetProperty: propertyString toAll: aCollection [
	^self 
		setTargetProperty: propertyString 
		to: (String streamContents: [ :stream | 
			aCollection 
				do: [ :each | stream nextPutAll: each ]
				separatedBy: [ stream nextPut: $, ] ])
]
