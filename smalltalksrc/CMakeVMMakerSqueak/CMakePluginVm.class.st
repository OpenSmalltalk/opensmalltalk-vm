"
A CMakePluginVm is a composite template that simplifies outputing vm drivers like vm-display-X11 to a CMakeLists.txt file.



		
"
Class {
	#name : #CMakePluginVm,
	#superclass : #CMakeTemplate,
	#instVars : [
		'config',
		'definitions',
		'module',
		'sources',
		'includedirectories'
	],
	#category : #'CMakeVMMakerSqueak-CMakeCompositeTemplates'
}

{ #category : #accessing }
CMakePluginVm >> config [

	^ config
]

{ #category : #accessing }
CMakePluginVm >> config: anObject definitions: dOrderedCollection module: mString sources: sOrderedCollection  includedirectories: iOrderedCollection [
	config:= anObject.
	definitions:= dOrderedCollection.
	module := mString.
	sources :=sOrderedCollection.
	includedirectories := iOrderedCollection.
	^self template


]

{ #category : #accessing }
CMakePluginVm >> definitions [
	^ definitions
]

{ #category : #accessing }
CMakePluginVm >> includedirectories [

	^ includedirectories
]

{ #category : #'as yet unclassified' }
CMakePluginVm >> initialize [
	"initialize to nonsense values to aid in debugging."
	config := 'a config'.
	definitions := 'vm plugin compiler definitions'.
	module := ' vm plugin module'.
	sources := 'vm plugin sources'.
	includedirectories:= 'vm plugin include directories'.
	self content:' Customize a CMakePluginVm(', config, ' ' , ' ' , definitions, ' ' , ' ' ,  module , ' ' ,self sources, ' ' , includedirectories,')'
]

{ #category : #accessing }
CMakePluginVm >> module [

	^ module
]

{ #category : #accessing }
CMakePluginVm >> sources [

	^ sources
]

{ #category : #accessing }
CMakePluginVm >> template [
	|temp sourcesString cflags|
	cflags:= String streamContents: [:stream | config compilerFlags asStringOn: stream delimiter: ' ' ].
	cflags := '"' , cflags , '"'.
	sourcesString := String streamContents: [:stream | sources asStringOn: stream delimiter: ' ' ].
	temp := OrderedCollection new.
	temp
		addLast: ((CMakeHeader new)  configurationName:  config class name );
		addLast: ((CMakeProject new)variable:  module  );
		addLast: ((CMakeMinimumRequired new) version: '2.8.12');
		addLast: ((CMakeInclude new) file: ((config buildDir fullName), FileDirectory slash, 'directories.cmake')) ; 
		addLast:((CMakeAddDefinitions new) definitions: config compilerDefinitions asOrderedCollection);
		addLast:((CMakeAddDefinitions new) definitions: config compilerFlags asOrderedCollection);
		addLast:((CMakeAddDefinitions new) definitions: definitions); 
"		addLast:((CMakeSet new) variable:'sources' quotedValue: sourcesString);"
		addLast:((CMakeSet new) variable:'sources' value: sourcesString);
		addLast:((CMakeAddLibrary new) 
			library: module
			type: 'SHARED' 
			sources: (OrderedCollection with: '${sources}'));
		addLast: ((CMakeIncludeDirectories new) dirs: includedirectories);
		addLast:((CMakeSet new) variable: 'LIBRARY_OUTPUT_PATH' quotedValue: (config outputDir fullName));
"		addLast:((CMakeListAppend new) list: 'LINKLIBS' elements: (config externalLibs));"
		addLast:((CMakeTargetLinkLibraries new) target: module  items: (OrderedCollection with: '${LINKLIBS}'));
		addLast:((CMakeSetTargetProperties new) 
			target: module 
			propertiesandvalues: (OrderedCollection with: 'PREFIX "" '  with: 'SUFFIX "" ' with: 'LINK_FLAGS ' , cflags)) .
	^temp
]
