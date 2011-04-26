"
This is a concrete configuration for building a CogVM on Win32 platform.

Built artifacts are placed in ${build}/results dir.
Note, that executable contains debug info. Stript it (using strip command) before packaging for distribution.


Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #CogWindowsConfig,
	#superclass : #CogFamilyWindowsConfig,
	#category : #'CMakeVMMaker-Windows'
}

{ #category : #'source generation' }
CogWindowsConfig >> cogitClass [
	"answer a class for machine code generation or nil"
	
	^ StackToRegisterMappingCogit 
]

{ #category : #'compiler flags' }
CogWindowsConfig >> compilerFlags [
	"depends on config ..."
	^ self commonCompilerFlags, ' ' ,self compilerFlagsRelease
]

{ #category : #'compiler flags' }
CogWindowsConfig >> compilerFlagsRelease [
	"Define NDEBUG for production to exclude asserts "
	^ ' -O2 -march=pentium4 -momit-leaf-frame-pointer -maccumulate-outgoing-args -funroll-loops ',
	'-DNDEBUG -DDEBUGVM=0'
]

{ #category : #'source files' }
CogWindowsConfig >> coreSources [
	"files to include from src/vm dir"
	
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #plugins }
CogWindowsConfig >> defaultExternalPlugins [

	^ #(
		ReentrantIA32FFIPlugin "SqueakFFIPrims"
	
		"Win32OSProcessPlugin"
	)
]

{ #category : #plugins }
CogWindowsConfig >> defaultInternalPlugins [

	^ #(
	
ADPCMCodecPlugin 
AsynchFilePlugin
B3DAcceleratorPlugin 
BalloonEnginePlugin "B2DPlugin" 
BitBltSimulation "BitBltPlugin"
BMPReadWriterPlugin 
CroquetPlugin 
DeflatePlugin  "ZipPlugin"
DropPlugin 
DSAPlugin "DSAPrims" 
FFTPlugin 
FilePlugin 
FloatArrayPlugin 
FloatMathPlugin 
HostWindowPlugin 
IA32ABIPlugin "IA32ABI"
JoystickTabletPlugin 
JPEGReaderPlugin 
JPEGReadWriter2Plugin 
KlattSynthesizerPlugin "Klatt"
LargeIntegersPlugin "LargeIntegers"
LocalePlugin 
Matrix2x3Plugin 
MIDIPlugin 
MiscPrimitivePlugin 
Mpeg3Plugin 
RePlugin 
SecurityPlugin 
SerialPlugin 
SocketPlugin 
SoundCodecPlugin "SoundCodecPrims"
SoundGenerationPlugin 
StarSqueakPlugin 
SurfacePlugin 
UUIDPlugin

	)
]

{ #category : #accessing }
CogWindowsConfig >> executableName [
	^ 'CogVM'
]

{ #category : #accessing }
CogWindowsConfig >> externalLibraries [
	
	^ #( 
		ddraw dinput opengl32 wsock32 comdlg32 ole32 winmm
		version wininet user32 gdi32 psapi kernel32 crtdll dsound secur32
	).
]

{ #category : #plugins }
CogWindowsConfig >> extraPluginSettings: maker [


	maker isExternal ifTrue: [
		"copy result to results dir "
		maker set: 'LIBRARY_OUTPUT_PATH' toString: self outputDir.
		
		maker cmd: 'set_target_properties' params:  maker moduleName , ' PROPERTIES PREFIX "" '
	]
]

{ #category : #'source files' }
CogWindowsConfig >> extraSources [

	^ 
	'${resources}'
]

{ #category : #settings }
CogWindowsConfig >> extraVMSettings: maker [

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
CogWindowsConfig >> iconFileName [
	^ 'Cog.ico'
]

{ #category : #'source generation' }
CogWindowsConfig >> interpreterClass [
	^ CoInterpreter
]

{ #category : #'source files' }
CogWindowsConfig >> platformSources [
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
CogWindowsConfig >> prepareForGeneration [

	CrLfFileStream defaultToLF. "For strange reason it works like that"

	^ self prepareForCogGeneration
]

{ #category : #resources }
CogWindowsConfig >> resourceFile [

	^ self resourceFileTemplate
		copyReplaceAll: '@ICON@' with: self iconFileName
]

{ #category : #resources }
CogWindowsConfig >> resourceFileTemplate [

	^ '
#ifdef _WIN32
1                       ICON    DISCARDABLE     "@ICON@"
2                       ICON    DISCARDABLE     "@ICON@"
3                       ICON    DISCARDABLE     "@ICON@"
#endif
'
]

{ #category : #utils }
CogWindowsConfig >> setExtraTargetProperties: maker [

	maker addExternalLibraries: self externalLibraries.
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: self outputDir.

]
