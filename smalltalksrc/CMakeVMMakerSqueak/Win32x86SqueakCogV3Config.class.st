"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

Usage:
Win32x86SqueakCogV3Config generateWithSources
Or:
Win32x86SqueakCogV3Config generate.
Or: 
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me
"
Class {
	#name : #Win32x86SqueakCogV3Config,
	#superclass : #SqueakWin32x86CogFamilyConfig,
	#category : #'CMakeVMMakerSqueak-Win32x86'
}

{ #category : #'source generation' }
Win32x86SqueakCogV3Config >> cogitClass [
	"answer a class for machine code generation or nil"
	
	^ StackToRegisterMappingCogit 
]

{ #category : #plugins }
Win32x86SqueakCogV3Config >> compilerFlagsDebug [
	"Define NDEBUG for production to exclude asserts "
	^ {
		'-g3'. 
		'-O0'. 
		'-march=pentium4'. 
		'-momit-leaf-frame-pointer'. 
		'-maccumulate-outgoing-args'. 
		'-funroll-loops'. 
		'-DDEBUGVM=1' }
]

{ #category : #'compiler flags' }
Win32x86SqueakCogV3Config >> compilerFlagsRelease [
	"Define NDEBUG for production to exclude asserts "
	^ {
		'-g0'. 
		'-O2'. 
		'-march=pentium4'. 
		'-momit-leaf-frame-pointer'. 
		'-maccumulate-outgoing-args'. 
		'-funroll-loops'.
		'-DNDEBUG -DDEBUGVM=0'}
]

{ #category : #'source files' }
Win32x86SqueakCogV3Config >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #cmake }
Win32x86SqueakCogV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogV3
]

{ #category : #cmake }
Win32x86SqueakCogV3Config >> excludeFromBuild [
	^false

]

{ #category : #accessing }
Win32x86SqueakCogV3Config >> executableName [
	^ 'CogVM'
]

{ #category : #accessing }
Win32x86SqueakCogV3Config >> externalLibraries [
	
	^ #( 
		ddraw dinput opengl32 wsock32 comdlg32 ole32 winmm
		version wininet user32 gdi32 psapi kernel32 crtdll dsound secur32
	).
]

{ #category : #plugins }
Win32x86SqueakCogV3Config >> extraPluginSettings: maker [


	maker isExternal ifTrue: [
		"copy result to results dir "
		maker set: 'LIBRARY_OUTPUT_PATH' toString: '${outputDir}'.
		
		maker cmd: 'set_target_properties' params:  maker moduleName , ' PROPERTIES PREFIX "" '
	]
]

{ #category : #'source files' }
Win32x86SqueakCogV3Config >> extraSources [

	^ 
	'${resources}'
]

{ #category : #settings }
Win32x86SqueakCogV3Config >> extraVMSettings: maker [

	| res |
	
	res := '"${buildDir}/resource.o"'.
	
	self write: self resourceFile toFile: 'Cog.rc'.
		
	maker cmd: 'add_custom_command' params: 'OUTPUT ', res ,
	'
		COMMAND 	windres --include-dir ${targetPlatform}/misc -D_WIN32 -i ${buildDir}/Cog.rc -o ', res , '
		COMMENT "Generating resource file..."
	'.
	
	maker set:  #resources to: res.
	
	maker includeDirectories: '${targetPlatform}/third-party/dx9sdk/Include'.
	
]

{ #category : #resources }
Win32x86SqueakCogV3Config >> iconFileName [
	^ 'Cog.ico'
]

{ #category : #'source generation' }
Win32x86SqueakCogV3Config >> interpreterClass [
	^ CoInterpreter
]

{ #category : #'source files' }
Win32x86SqueakCogV3Config >> platformSources [
	"files added from platform/win32/vm dir "
	^ #(
		'sqWin32Alloc.c'
		'sqWin32Directory.c'
		'sqWin32Heartbeat.c'
		'sqWin32Service.c'
		'sqWin32VMProfile.c'
		'sqWin32Args.c'
		'sqWin32Exports.c'
		'sqWin32Intel.c'
		'sqWin32Stubs.c'
		'sqWin32Window.c'
		'sqWin32Backtrace.c'
		'sqWin32ExternalPrims.c'
		'sqWin32PluginSupport.c'
		'sqWin32Threads.c'
		'version.c'
		'sqWin32DirectInput.c'
		'sqWin32GUID.c'
		'sqWin32Prefs.c'
		'sqWin32Utils.c'
	)
]

{ #category : #'source generation' }
Win32x86SqueakCogV3Config >> prepareForGeneration [
	^ self prepareForCogGeneration
]

{ #category : #resources }
Win32x86SqueakCogV3Config >> resourceFile [

	^ self resourceFileTemplate
		copyReplaceAll: '@ICON@' with: self iconFileName
]

{ #category : #resources }
Win32x86SqueakCogV3Config >> resourceFileTemplate [

	^ '
#ifdef _WIN32
1                       ICON    DISCARDABLE     "@ICON@"
2                       ICON    DISCARDABLE     "@ICON@"
3                       ICON    DISCARDABLE     "@ICON@"
#endif
'
]

{ #category : #utils }
Win32x86SqueakCogV3Config >> setExtraTargetProperties: maker [

	maker addExternalLibraries: self externalLibraries.
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: '${outputDir}'.

"	maker puts: 'set_source_files_properties(${srcVMDir}/cogit.c PROPERTIES COMPILE_FLAGS -O1)'."
	maker puts: 'set_source_files_properties(${srcVMDir}/gcc3x-cointerp.c PROPERTIES COMPILE_FLAGS -O1)'

]
