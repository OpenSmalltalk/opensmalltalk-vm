"
a base class for generating cmake files.
Mainly provides a helper methods of cmake commands api.
"
Class {
	#name : #CMakeGeneratorForSqueak,
	#superclass : #Object,
	#instVars : [
		'output'
	],
	#category : #CMakeVMMakerSqueak
}

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> addDefinitions: aString [
	^ self cmd: 'add_definitions' params: aString
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> addDependency: aName [

	self cmd: 'list'
		params: 'APPEND ', self moduleName , '_dependencies ' , aName.

]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> addExternalLibraries: libs [

	libs do: [:each | self addExternalLibrary: each ]
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> addExternalLibrary: aLibrary [ 
	self cmd: 'list'
		params: 'APPEND LINKLIBS ' , aLibrary .
		
"	self cmd: 'target_link_libraries' 
		params: self moduleName , ' ' , aLibrary.
"	

]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> addFrameworks: aCollection [ 
	"for mac only "
	aCollection
		do: [:each | 
			self cmd: 'find_library' params:  each , '_FMWK ', each.
			self addExternalLibrary: '${', each , '_FMWK}' ]
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> addProperty: propertyString value: valueString [ 
	self puts: 'set_target_properties(' , self moduleName , ' PROPERTIES ' , propertyString , ' "' , valueString, '")'

]

{ #category : #'sources management' }
CMakeGeneratorForSqueak >> addSource: aFileName [

	^ self addSources: { aFileName }
]

{ #category : #'sources management' }
CMakeGeneratorForSqueak >> addSources: aFileNames [

	^ self addSources: aFileNames prefixed: ''
]

{ #category : #'sources management' }
CMakeGeneratorForSqueak >> addSources: aFileNames prefixed: aPrefix [

	| names |
	names := aFileNames inject: '' into: [:res :each | res , ' "' , aPrefix, each, '"' ].
	
	self puts: 'list(APPEND sources ', names , ')'
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> addSubdirectory: aDir [

	^ self cmd: 'add_subdirectory' qparams: aDir. 

]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> addXCodeProperty: propertyString value: valueString [ 
	self 
		addProperty: 'XCODE_ATTRIBUTE_' , propertyString 
		value: valueString

]

{ #category : #'code generation' }
CMakeGeneratorForSqueak >> captureOutputDuring: aBlock [
	| old result |
	
	old := output.
	output :=  String new writeStream.
	
	aBlock value.
	
	result := output.
	output := old.
	
	^ result contents
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> cmd: cmdName params: aString [

	output nextPutAll: cmdName;
		nextPut: $(;
		nextPutAll: aString;
		nextPut: $);
		cr

]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> cmd: cmdName qparams: aString [
	"quoted params"
	output nextPutAll: cmdName;
		nextPutAll: '("';
		nextPutAll: aString;
		nextPutAll: '")';
		cr

]

{ #category : #'code generation' }
CMakeGeneratorForSqueak >> generate [
	self subclassResponsibility.
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> include: aFileName [
	^ self cmd: 'include' params: aFileName
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> includeDirectories: aString [
	^ self cmd: 'include_directories' params: aString
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> linkDirectories: aString [
	^ self cmd: 'link_directories' params: aString
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> message: aString [
	
	self cmd: 'message' qparams: aString.
]

{ #category : #accessing }
CMakeGeneratorForSqueak >> moduleName [
	self subclassResponsibility
]

{ #category : #accessing }
CMakeGeneratorForSqueak >> output [
	^ output
]

{ #category : #accessing }
CMakeGeneratorForSqueak >> output: aStream [

	output := aStream
]

{ #category : #accessing }
CMakeGeneratorForSqueak >> outputFileName [
	^ 'CMakeLists.txt'
]

{ #category : #'as yet unclassified' }
CMakeGeneratorForSqueak >> printHeader [
	
	self puts: '# This is automatically generated file using ', self configurationName, ' on ',
		Date current asString, ' ' , Time current asString;
		puts: 'cmake_minimum_required(VERSION 2.6.2)'
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> project: aProjectName [
	self cmd: 'project' qparams: aProjectName

]

{ #category : #'as yet unclassified' }
CMakeGeneratorForSqueak >> puts: aString [
	output nextPutAll: aString; cr
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> set: variableName to: aValueString [

	self cmd: 'set' params: variableName , ' ' , aValueString
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> set: variableName toString: aValueString [

	^ self set: variableName to: '"', (aValueString copyReplaceAll: '"' with: '\"'), '"'
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> setTargetProperties: properties [ 
	self cmd: 'set_target_properties' params: self moduleName, ' PROPERTIES ', properties 
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> setTargetProperty: propertyString to: aString [
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
CMakeGeneratorForSqueak >> setTargetProperty: propertyString toAll: aCollection [
	^self 
		setTargetProperty: propertyString 
		to: (String streamContents: [ :stream | 
			aCollection 
				do: [ :each | stream nextPutAll: each ]
				separatedBy: [ stream nextPut: $, ] ])
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> setTargetProperty: propertyString toString: aString [
	self 
		cmd: 'set_target_properties'
		params: (String streamContents: [ :stream |
			stream 
				nextPutAll: self moduleName;
				nextPutAll: ' PROPERTIES ';
				nextPutAll: propertyString;
				space;
				nextPut: $";  
				nextPutAll: (aString copyReplaceAll: '"' with: '\"');
				nextPut: $"
				 ])
]
