"
A CMakeVMDriver is a composite template that simplifies outputing vm drivers like vm-display-X11 to a CMakeLists.txt file.
I replace the output of pharo's CMakeVMMaker 

CogFamilyUnixConfig addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs which was invoked like so:

	aMaker message: 'addVMDrivers: aMaker'.
	 self 
		addDriver: 'vm-display-null' 
		sources: #( 
			'${targetPlatform}/vm-display-null/sqUnixDisplayNull' )
		generator: aMaker
		externalLibs: #();
		
"
Class {
	#name : #CMakeVMDriver,
	#superclass : #CMakeTemplate,
	#instVars : [
		'config',
		'definitions',
		'driver',
		'sources',
		'includedirectories'
	],
	#category : #'CMakeVMMakerSqueak-CMakeCompositeTemplates'
}

{ #category : #accessing }
CMakeVMDriver >> config [

	^ config
]

{ #category : #accessing }
CMakeVMDriver >> config: anObject definitions: dOrderedCollection driver: dString sources: sOrderedCollection  includedirectories: iOrderedCollection [
	config:= anObject.
	definitions:= dOrderedCollection.
	driver:=dString.
	sources :=sOrderedCollection.
	includedirectories := iOrderedCollection.
	^self template


]

{ #category : #accessing }
CMakeVMDriver >> definitions [
	^ definitions
]

{ #category : #accessing }
CMakeVMDriver >> driver [

	^ driver
]

{ #category : #accessing }
CMakeVMDriver >> includedirectories [

	^ includedirectories
]

{ #category : #accessing }
CMakeVMDriver >> sources [

	^ sources
]

{ #category : #accessing }
CMakeVMDriver >> template [
	|temp sourcesString|
	sourcesString := String streamContents: [:stream | sources asStringOn: stream delimiter: ' ' ].
	temp := OrderedCollection new.
	temp
		addLast: ((CMakeHeader new)  configurationName:  config class name );
		addLast: ((CMakeProject new)variable:  config executableName  );
		addLast: ((CMakeInclude new) file: ((config buildDirName), FileDirectory slash, 'directories.cmake')); "??"
		addLast:((CMakeAddDefinitions new) definitions: config compilerFlags asOrderedCollection);
		addLast:((CMakeAddDefinitions new) definitions: definitions); 
		addLast:((CMakeSet new) variable:'sources' quotedValue: sourcesString);
		addLast:((CMakeAddLibrary new) 
			library: driver
			type: 'SHARED' 
			sources:  sources);
		addLast: ((CMakeIncludeDirectories new) dirs: includedirectories);
		addLast:((CMakeSet new) variable: 'LIBRARY_OUTPUT_PATH' quotedValue: (config outputDir fullName));
		addLast:((CMakeListAppend new) list: 'LINKLIBS' elements: (config externalLibs));
		addLast:((CMakeTargetLinkLibraries new) target: driver  items: (OrderedCollection with: '${LINKLIBS}'));
		addLast:((CMakeSetTargetProperties new) 
			target: driver 
			propertiesandvalues: (OrderedCollection with: 'PREFIX "" '  with: 'SUFFIX "" ' with: 'LINK_FLAGS ' , (config compilerFlags))).
	^temp
]
