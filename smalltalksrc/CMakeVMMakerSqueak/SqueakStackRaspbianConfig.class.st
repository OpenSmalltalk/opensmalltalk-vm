"
This is a concrete class which generates a StackVM for Raspbian (debian on RaspberryPi).

Usage: 
SqueakStackRaspbianConfig generateWithSources
or:
SqueakStackRaspbianConfig generate

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #SqueakStackRaspbianConfig,
	#superclass : #SqueakStackUnixConfig,
	#category : #'CMakeVMMakerSqueak-Unix'
}

{ #category : #'as yet unclassified' }
SqueakStackRaspbianConfig >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [
	super addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs

]

{ #category : #'as yet unclassified' }
SqueakStackRaspbianConfig >> commonCompilerFlags [

	"Common compiler flags
	
	
	LSB_FIRST=1 means that target platform is little endian. 
	set it to 0 for big-endian platforms
	
	"
	
	^ {
		'-DLSB_FIRST=1'. 
		'-DUSE_GLOBAL_STRUCT=0'. 
		'-DCOGMTVM=0' } 
]

{ #category : #'as yet unclassified' }
SqueakStackRaspbianConfig >> compilerFlagsDebug [

	^ {
		'-g3'. 
		'-O0'. 
		'-D_GNU_SOURCE'. 
		'-DITIMER_HEARTBEAT=1'. 
		'-DNO_VM_PROFILE=1'. 
		'-DDEBUGVM=1' }
]

{ #category : #'as yet unclassified' }
SqueakStackRaspbianConfig >> compilerFlagsRelease [
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

{ #category : #'as yet unclassified' }
SqueakStackRaspbianConfig >> configureBitBltSimulation: maker [
	"extra rules for BitBltSimulation"

	maker includeDirectories: '${pluginCross}'.

	maker addCrossSources: #(
		'BitBltGeneric.c'
		'BitBltDispatch.c'
	).
	
]

{ #category : #'as yet unclassified' }
SqueakStackRaspbianConfig >> defaultExternalPlugins [
	self flag:'tty'. "InternetConfigPlugin not available default svn co of Cog for unix. "
	^ #(
		B3DAcceleratorPlugin
		JPEGReaderPlugin 
		JPEGReadWriter2Plugin 			
		RePlugin
"		InternetConfigPlugin"
	)
]

{ #category : #'as yet unclassified' }
SqueakStackRaspbianConfig >> defaultInternalPlugins [
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

{ #category : #'as yet unclassified' }
SqueakStackRaspbianConfig >> extraPluginSettings: maker [

	maker isExternal ifTrue: [
		"copy lib to results dir "
		maker set: 'LIBRARY_OUTPUT_PATH' to: '${outputDir}' 
	].	
	
	maker set: #linkFlags toString: '${linkFlags}'

]

{ #category : #'as yet unclassified' }
SqueakStackRaspbianConfig >> linkFlags [
	 ^ '-lSM -lICE -ldl -lGL -lpthread -lm -lnsl -lX11'
]

{ #category : #'as yet unclassified' }
SqueakStackRaspbianConfig >> setExtraTargetProperties: maker [

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
