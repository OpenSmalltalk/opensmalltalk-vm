"
This is a concrete class which generates a StackVM for Raspbian (debian on RaspberryPi).

Usage: 
Linux32ARMv6StackV3RaspbianConfig generateWithSources
Or:
Linux32ARMv6StackV3RaspbianConfig generate

Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me

"
Class {
	#name : #Linux32ARMv6StackV3RaspbianConfig,
	#superclass : #Linux32x86SqueakStackV3Configz,
	#category : #'CMakeVMMakerSqueak-Linux32ARMv6'
}

{ #category : #'squeak compatibility' }
Linux32ARMv6StackV3RaspbianConfig >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [
	super addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs

]

{ #category : #cmake }
Linux32ARMv6StackV3RaspbianConfig >> availableBuilds [
	^SqueakCMakeVMMakerAbstractBuilder  default  noBuildConfigurations

]

{ #category : #'compiler flags' }
Linux32ARMv6StackV3RaspbianConfig >> commonCompilerFlags [

	"Common compiler flags
	
	
	LSB_FIRST=1 means that target platform is little endian. 
	set it to 0 for big-endian platforms
	
	"
	
	^ {
		'-DLSB_FIRST=1'. 
		'-DUSE_GLOBAL_STRUCT=0'. 
		'-DCOGMTVM=0' } 
]

{ #category : #'compiler flags' }
Linux32ARMv6StackV3RaspbianConfig >> compilerFlagsDebug [

	^ {
		'-g3'. 
		'-O0'. 
		'-D_GNU_SOURCE'. 
		'-DITIMER_HEARTBEAT=1'. 
		'-DNO_VM_PROFILE=1'. 
		'-DDEBUGVM=1' }
]

{ #category : #'compiler flags' }
Linux32ARMv6StackV3RaspbianConfig >> compilerFlagsRelease [
"
THIS FLAGS ARE CRASHING COMPILER 
-fschedule-insns2 
-fschedule-insns 

THIS FLAGS ARE CRASHING VM
-ftree-pre  
-fcaller-saves 

THIS FLAGS ARE WORKING 
-O1 -fthread-jumps -falign-functions -falign-jumps -falign-loops -falign-labels -fcrossjumping -fcse-follow-jumps -fcse-skip-blocks -fdelete-null-pointer-checks -fdevirtualize -fexpensive-optimizations -fgcse -fgcse-lm -finline-small-functions -findirect-inlining -fipa-sra -foptimize-sibling-calls -fpeephole2 -fregmove -freorder-blocks -frerun-cse-after-loop -freorder-functions  -fsched-interblock -fsched-spec -fstrict-aliasing -fstrict-overflow  -ftree-switch-conversion -ftree-vrp

THIS IS LIKE: -O2 -fno-tree-pre -fno-caller-saves 

"

	^ {
		'-g0'. 
		'-O2'. 
		'-fno-tree-pre'. 
		'-fno-caller-saves'. 
		'-D_GNU_SOURCE'. 
		'-DNDEBUG'. 
		'-DITIMER_HEARTBEAT=1'. 
		'-DNO_VM_PROFILE=1'. 
		'-DDEBUGVM=0' }
]

{ #category : #'plugin extra rules' }
Linux32ARMv6StackV3RaspbianConfig >> configureBitBltSimulation: maker [
	"extra rules for BitBltSimulation"

	maker includeDirectories: '${pluginCross}'.

	maker addCrossSources: #(
		'BitBltGeneric.c'
		'BitBltDispatch.c'
	).
	
]

{ #category : #plugins }
Linux32ARMv6StackV3RaspbianConfig >> defaultExternalPlugins [
	self flag:'tty'. "InternetConfigPlugin not available default svn co of Cog for unix. "
	^ #(
		B3DAcceleratorPlugin
		JPEGReaderPlugin 
		JPEGReadWriter2Plugin 			
		RePlugin
"		InternetConfigPlugin"
	)
]

{ #category : #plugins }
Linux32ARMv6StackV3RaspbianConfig >> defaultInternalPlugins [
" took from unixbuild/bld/plugins.int"
	^ #(
		ADPCMCodecPlugin 
		AsynchFilePlugin 
		BalloonEnginePlugin "B2DPlugin" 
		BitBltSimulation "BitBltPlugin"
		BMPReadWriterPlugin 
		CroquetPlugin 
		DeflatePlugin  "ZipPlugin"
		DropPlugin 
		DSAPlugin "DSAPrims" 
		FFTPlugin 
		FileCopyPlugin 
		FilePlugin 
		FloatArrayPlugin 
		FloatMathPlugin 
		JoystickTabletPlugin 
		KlattSynthesizerPlugin "Klatt"
		LargeIntegersPlugin "LargeIntegers"
		Matrix2x3Plugin 
		MIDIPlugin 
		MiscPrimitivePlugin 
		Mpeg3Plugin  	
		SecurityPlugin 
		SerialPlugin 
		SocketPlugin 
		SoundCodecPlugin "SoundCodecPrims"
		SoundGenerationPlugin 
		SoundPlugin 
		StarSqueakPlugin 
		SurfacePlugin	
		LocalePlugin
		)
]

{ #category : #cmake }
Linux32ARMv6StackV3RaspbianConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
Linux32ARMv6StackV3RaspbianConfig >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	^self dirARMv6
]

{ #category : #cmake }
Linux32ARMv6StackV3RaspbianConfig >> excludeFromBuild [
	^false

]

{ #category : #'plugin extra rules' }
Linux32ARMv6StackV3RaspbianConfig >> extraPluginSettings: maker [

	maker isExternal ifTrue: [
		"copy lib to results dir "
		maker set: 'LIBRARY_OUTPUT_PATH' to: '${outputDir}' 
	].	
	
	maker set: #linkFlags toString: '${linkFlags}'

]

{ #category : #accessing }
Linux32ARMv6StackV3RaspbianConfig >> linkFlags [
	 ^ '-lSM -lICE -ldl -lGL -lpthread -lm -lnsl -lX11'
]

{ #category : #utils }
Linux32ARMv6StackV3RaspbianConfig >> setExtraTargetProperties: maker [

	"maker setTargetProperties: 'LINK_FLAGS ""'."
		
	maker puts: 'set_source_files_properties( ${srcVMDir}/cogit.c PROPERTIES 
		COMPILE_FLAGS "-O1 -fno-omit-frame-pointer -momit-leaf-frame-pointer")'.
		
	
	maker 
		cmd: 'set_source_files_properties'
		params: ' ${targetPlatform}/vm/sqUnixHeartbeat.c PROPERTIES 
		COMPILE_FLAGS "-O1 -fno-omit-frame-pointer"'.
						
	
	maker addExternalLibraries: 
		#(
			'm'  "math lib"
			'dl'  "dynamic loader"
			'pthread' "posix threads" 
		).
		
	maker set: 'EXECUTABLE_OUTPUT_PATH' toString: self outputDir fullName.
	self addVMDrivers: maker.
]
