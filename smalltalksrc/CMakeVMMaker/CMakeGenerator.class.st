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
	^ self  puts: 'add_definitions(', aString ,')'
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

	^ self puts: 'add_subdirectory("',aDir,'")'. 

]

{ #category : #'as yet unclassified' }
CMakeGenerator >> buildDir [
	^ (self rootDir / 'build') assureExistence
]

{ #category : #'as yet unclassified' }
CMakeGenerator >> contents [

	^ output contents copyReplaceAll: String cr with: String lf
]

{ #category : #'as yet unclassified' }
CMakeGenerator >> generate [
	self subclassResponsibility.
]

{ #category : #'as yet unclassified' }
CMakeGenerator >> ifMac: aBlock [
 	^ self config ifMac: aBlock
]

{ #category : #'cmake commands' }
CMakeGenerator >> includeDirectories: aString [
	^ self puts: 'include_directories(',aString,')'
]

{ #category : #'as yet unclassified' }
CMakeGenerator >> internalPluginMacro [
	^ '
macro (INTERNAL_PLUGIN plugin)

#create a plugin build subdir
	set(pluginDir ${build}/${plugin})
	set(pluginSources ${src}/plugins/${plugin} ${cross}/plugins/${plugin} ${targetPlatform}/plugins/${plugin})
	
	file(MAKE_DIRECTORY ${pluginDir})
	
	file(COPY ${config}/${plugin}.cmake DES
	add_subdirectory(${build}/${plugin})	
add_custom_target(${plugin}

TARGET ${plugin} PRE_LINK
	
	WORKING_DIRECTORY ${build}/${plugin})	

ADD_DEFINITIONS (-DSQUEAK_BUILTIN_PLUGIN=1 ${@plugin@_definitions})
LINK_DIRECTORIES (${@plugin@_link_directories})
INCLUDE_DIRECTORIES (${@plugin@_include_directories}
    ${bld}
    ${src}/vm
    ${cross}/vm
    ${src}/plugins/@plugin@
    ${src}/vm/intplugins/@plugin@
    ${unix}/vm
    ${unix}/plugins/@plugin@
    ${unix}/@plugin@
    ${cross}/plugins/@plugin@
)

ADD_LIBRARY (@plugin@ STATIC @plugin_sources@)


  

FILE (WRITE ${bld}/${plugin}/CMakeLists.in "")
  FOREACH (dir ${unix}/plugins ${unix})
    FILE_APPEND (${bld}/${plugin}/CMakeLists.in ${dir}/${plugin}/build.cmake)
  ENDFOREACH (dir)
  FILE_APPEND (${bld}/${plugin}/CMakeLists.in ${config}/PluginInternal.cmake)
  CONFIGURE_FILE (${bld}/${plugin}/CMakeLists.in ${bld}/${plugin}/CMakeLists.txt @ONLY)
  ADD_SUBDIRECTORY (${bld}/${plugin} ${bld}/${plugin})
ENDMACRO (INTERNAL_PLUGIN)

'
]

{ #category : #'as yet unclassified' }
CMakeGenerator >> message: aString [

	self puts: 'message( "', aString , '")'
]

{ #category : #'as yet unclassified' }
CMakeGenerator >> outputFileName [
	^ 'CMakeLists.txt'
]

{ #category : #'as yet unclassified' }
CMakeGenerator >> platformName [
	^ 'Mac OS'
]

{ #category : #'as yet unclassified' }
CMakeGenerator >> printHeader [
	
	self puts: '# This is automatically generated file using CVMMaker on ',
		Date current asString, ' ' , Time current asString;
		puts: 'cmake_minimum_required(VERSION 2.6)';
		puts: 'include(CMakeDetermineSystem)'.
]

{ #category : #'as yet unclassified' }
CMakeGenerator >> printProjectName [
	
	self puts: 'project(Cog)'
]

{ #category : #'cmake commands' }
CMakeGenerator >> project: aProjectName [
	self puts: 'project(', aProjectName , ')'.

]

{ #category : #'as yet unclassified' }
CMakeGenerator >> puts: aString [
	output nextPutAll: aString; cr
]

{ #category : #'as yet unclassified' }
CMakeGenerator >> rootDir [
	"assume that image runs in one of subdirs, like 'image' "
	^ FileDirectory default containingDirectory
]

{ #category : #'cmake commands' }
CMakeGenerator >> set: variableName to: aValueString [

	self puts: 'set(', variableName , ' ' , aValueString , ')'
]

{ #category : #'cmake commands' }
CMakeGenerator >> set: variableName toString: aValueString [

	^ self set: variableName to: '"', (aValueString copyReplaceAll: '"' with: '\"'), '"'
]

{ #category : #'as yet unclassified' }
CMakeGenerator >> setupDirectories [
"
setup  a common directories, relative to the ${topDir}

"
	self 
		set: #platformsDir toString: '${topDir}/platforms';
		set: #srcDir toString: '${topDir}/src';
		set: #srcPluginsDir toString: '${srcDir}/plugins';
		set: #srcVMDir toString: '${srcDir}/vm';
		set: #platformName toString: self platformName;
		set: #targetPlatform to: '${platformsDir}/${platformName}';
		set: #crossDir toString: '${platformsDir}/Cross';
		set: #buildDir toString: '${topDir}/build';
		set: #platformVMDir toString: '${targetPlatform}/vm'.

]
