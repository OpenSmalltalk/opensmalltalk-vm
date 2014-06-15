"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakWin32x86Builder 
	configureABuildFor: #MYCLASSNAMEHERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
"
Class {
	#name : #Win32x86NewspeakCogSpurConfig,
	#superclass : #SqueakWin32x86CogFamilyConfig,
	#category : #'CMakeVMMakerSqueak-Win32x86'
}

{ #category : #'source generation' }
Win32x86NewspeakCogSpurConfig >> cogitClass [
	"answer a class for machine code generation or nil"
	
	^ StackToRegisterMappingCogit 
]

{ #category : #plugins }
Win32x86NewspeakCogSpurConfig >> compilerFlagsDebug [
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
Win32x86NewspeakCogSpurConfig >> compilerFlagsRelease [
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
Win32x86NewspeakCogSpurConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #cmake }
Win32x86NewspeakCogSpurConfig >> dirBuildLanguageVMMM [
	^self newspeakCogSpur
]

{ #category : #cmake }
Win32x86NewspeakCogSpurConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #accessing }
Win32x86NewspeakCogSpurConfig >> executableName [
	^ 'CogVM'
]

{ #category : #accessing }
Win32x86NewspeakCogSpurConfig >> externalLibraries [
	
	^ #( 
		ddraw dinput opengl32 wsock32 comdlg32 ole32 winmm
		version wininet user32 gdi32 psapi kernel32 crtdll dsound secur32
	).
]

{ #category : #plugins }
Win32x86NewspeakCogSpurConfig >> extraPluginSettings: maker [


	maker isExternal ifTrue: [
		"copy result to results dir "
		maker set: 'LIBRARY_OUTPUT_PATH' toString: '${outputDir}'.
		
		maker cmd: 'set_target_properties' params:  maker moduleName , ' PROPERTIES PREFIX "" '
	]
]

{ #category : #'source files' }
Win32x86NewspeakCogSpurConfig >> extraSources [

	^ 
	'${resources}'
]

{ #category : #settings }
Win32x86NewspeakCogSpurConfig >> extraVMSettings: maker [

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
Win32x86NewspeakCogSpurConfig >> iconFileName [
	^ 'Cog.ico'
]

{ #category : #'source generation' }
Win32x86NewspeakCogSpurConfig >> interpreterClass [
	^ CoInterpreter
]

{ #category : #'source files' }
Win32x86NewspeakCogSpurConfig >> platformSources [
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
Win32x86NewspeakCogSpurConfig >> prepareForGeneration [
	^ self prepareForCogGeneration
]

{ #category : #resources }
Win32x86NewspeakCogSpurConfig >> resourceFile [

	^ self resourceFileTemplate
		copyReplaceAll: '@ICON@' with: self iconFileName
]

{ #category : #resources }
Win32x86NewspeakCogSpurConfig >> resourceFileTemplate [

	^ '
#ifdef _WIN32
1                       ICON    DISCARDABLE     "@ICON@"
2                       ICON    DISCARDABLE     "@ICON@"
3                       ICON    DISCARDABLE     "@ICON@"
#endif
'
]

{ #category : #utils }
Win32x86NewspeakCogSpurConfig >> setExtraTargetProperties: maker [

	maker addExternalLibraries: self externalLibraries.
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: '${outputDir}'.

"	maker puts: 'set_source_files_properties(${srcVMDir}/cogit.c PROPERTIES COMPILE_FLAGS -O1)'."
	maker puts: 'set_source_files_properties(${srcVMDir}/gcc3x-cointerp.c PROPERTIES COMPILE_FLAGS -O1)'

]
