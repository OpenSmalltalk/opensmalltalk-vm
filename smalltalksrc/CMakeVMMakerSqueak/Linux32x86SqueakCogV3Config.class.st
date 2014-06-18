"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf


I am not meant to be built.

SqueakLinux32x86Builder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

"
Class {
	#name : #Linux32x86SqueakCogV3Config,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'source generation' }
Linux32x86SqueakCogV3Config >> cogitClass [
	"answer a class for machine code generation or nil"
	
	^ StackToRegisterMappingCogit 
]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3Config >> commonCompilerFlags [
	^ {
		'-DLSB_FIRST=1'. 
		'-DUSE_GLOBAL_STRUCT=0'. 
		'-DCOGMTVM=0'. 
		'-m32'.
		'-DENABLE_FAST_BLT ' } 	
	
]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3Config >> compilerFlagsDebug [
"
SystemNavigation default browseMethodsWhoseNamesContain: ''compilerFlagsRelease''
"
	

	^ {
		'-g3'. 
		'-O0'. 
		'-msse2'. 
		'-D_GNU_SOURCE'. 
		'-DITIMER_HEARTBEAT=1'. 
		'-DNO_VM_PROFILE=1'. 
		'-DDEBUGVM=1' }
]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3Config >> compilerFlagsRelease [
"
SystemNavigation default browseMethodsWhoseNamesContain: ''compilerFlagsRelease''
"
	^ {
		'-g0'. 
		'-O2'. 
		'-fno-tree-pre'. 
		'-fno-caller-saves'. 
		'-msse2'. 
		'-D_GNU_SOURCE'. 
		'-DNDEBUG'. 
		'-DITIMER_HEARTBEAT=1'. 
		'-DNO_VM_PROFILE=1'. 
		'-DDEBUGVM=0' }
]

{ #category : #sources }
Linux32x86SqueakCogV3Config >> coreSources [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'gcc3x-cointerp.c'
		)
]

{ #category : #plugins }
Linux32x86SqueakCogV3Config >> defaultExternalPlugins [
	""
	self flag:'tty'. "UUIDPlugin does not build on my linux system. fix this"
	^ (super defaultExternalPlugins copyWithoutAll: #(#UUIDPlugin #UnixOSProcessPlugin))
]

{ #category : #plugins }
Linux32x86SqueakCogV3Config >> defaultInternalPlugins [
	""
	self flag:'tty'. "UUIDPlugin does not build on my linux system. fix this"
	^ (super defaultInternalPlugins copyWithoutAll: #(#VMProfileLinuxSupportPlugin))
]

{ #category : #cmake }
Linux32x86SqueakCogV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogV3
]

{ #category : #cmake }
Linux32x86SqueakCogV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
Linux32x86SqueakCogV3Config >> executableName [
	^ self vmCogExecutableName
]

{ #category : #'source generation' }
Linux32x86SqueakCogV3Config >> interpreterClass [
	^ CoInterpreter
]

{ #category : #utils }
Linux32x86SqueakCogV3Config >> setExtraTargetProperties: maker [

	maker setTargetProperties: 'LIBS "-lptrhead -luuid"'.
	maker setTargetProperties: 'LDFLAGS "-Wl -z now"'.

	super setExtraTargetProperties: maker.

]
