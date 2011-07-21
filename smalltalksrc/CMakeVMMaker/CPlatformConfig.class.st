"
Base class, defining some common properties and behavior for all kinds of VM build configurations. These classes are used to generate the VM sources and the CMMake files. 

Notice that this configuration classes expect that you have download the ""platofroms code"" which is in Gitorious: https://gitorious.org/cogvm
You can load it executing: git clone git://gitorious.org/cogvm/blessed.git

Once that is done it should have created a directory /blessed. In order to get all the directories by default, place this image under /blessed/image 

To generate a sources/build configuration use one of my subclasses with:
<config> generate.   - to generate a build configuration
<config> generateWithSources - to generate VMMaker sources and then build configuration.

Once you do that, go to /blessed/build and execute:  cmake .    or cmake -G""MSYS Makefiles"" if you are in Windows 

Since some plugins require extra settings (like additional source files etc), there is two ways to add that:

- add custom rules on plugin class side:

PluginClass>>generateFor: aCMakeVMGenerator internal: aBoolean 

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |   ... your rules come here ... ]
		
- define rules by adding #configure<PluginClass>: method in config class (see my 'plugin extra rules' category)

The last one is more compact and also avoids inter-package dependency, so you can load and use
CMakeVMMaker even if some 3rd-party plugins are not loaded into image.


Links of interest:

Official Cog Website: http://www.mirandabanda.org/cog
Official Cog Blog: http://www.mirandabanda.org/cogblog
Cog issue tracker: http://code.google.com/p/cog
Cog Wiki: http://code.google.com/p/cog/w/list
Cog binaries: http://www.mirandabanda.org/files/Cog/VM
Cog binaries in Pharo Hudson server: https://pharo-ic.lille.inria.fr/hudson/view/Cog
Cog SVN branch: http://squeakvm.org/svn/squeak/branches/Cog
VM mailing list: http://lists.squeakfoundation.org/mailman/listinfo/vm-dev
VM-beginners mailing list: http://lists.squeakfoundation.org/mailman/listinfo/vm-beginners
Guide step by step about how to build the Cog VM using CMakeVMMaker and Git: http://code.google.com/p/cog/wiki/Guide




"
Class {
	#name : #CPlatformConfig,
	#superclass : #Object,
	#instVars : [
		'topDir',
		'buildDir',
		'srcDir',
		'platformsDir',
		'outputDir',
		'internalPlugins',
		'externalPlugins',
		'pluginsDir',
		'externalLibs'
	],
	#category : #CMakeVMMaker
}

{ #category : #'as yet unclassified' }
CPlatformConfig class >> generate [

	^ self new generate
]

{ #category : #'as yet unclassified' }
CPlatformConfig class >> generateWithSources [

	^ self new generateSources; generate.

]

{ #category : #plugins }
CPlatformConfig >> addExternalPlugin: aPluginName [

	| plugins |
	plugins := self externalPlugins.
	(self internalPlugins includes: aPluginName) ifTrue: [
		self error: 'Cannot add plugin ', aPluginName , ' as external, because it is already included as internal one'
		].
	(plugins includes: aPluginName) ifFalse: [ externalPlugins := externalPlugins copyWith: aPluginName ]
]

{ #category : #plugins }
CPlatformConfig >> addExternalPlugins: aPluginNames [

	aPluginNames do: [:each | self addExternalPlugin: each ]
]

{ #category : #plugins }
CPlatformConfig >> addInternalPlugin: aPluginName [

	| plugins |
	plugins := self internalPlugins.

	(self externalPlugins includes: aPluginName) ifTrue: [
		self error: 'Cannot add plugin ', aPluginName , ' as internal, because it is already included as external one'
		].
	
	(plugins includes: aPluginName) ifFalse: [ internalPlugins := internalPlugins copyWith: aPluginName ]
]

{ #category : #plugins }
CPlatformConfig >> addInternalPlugins: aPluginNames [

	aPluginNames do: [:each | self addInternalPlugin: each ]
]

{ #category : #directories }
CPlatformConfig >> buildDir [
	
	^ buildDir ifNil: [ buildDir := (self topDir / self buildDirName) assureExistence ].

]

{ #category : #accessing }
CPlatformConfig >> buildDir: anObject [
	"Set the value of buildDir"

	buildDir := self dirFrom: anObject
]

{ #category : #directories }
CPlatformConfig >> buildDirName [
	^ 'build'

]

{ #category : #'source generation' }
CPlatformConfig >> cogitClass [
	"answer a class for machine code generation or nil"
	
	^ nil
]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureB3DAcceleratorPlugin: maker [
	"extra rules for B3DAcceleratorPlugin"
	maker 
		addCrossSources: #( 'sqOpenGLRenderer.c' ) 
	

]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureBochsIA32Plugin: maker [

	"this stuff is not ready for use yet" 
	
" 	maker addCrossSources:
		#( 'sqBochsIA32Plugin.cpp'  )

"
	maker doNotGenerate:true
]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureCroquetPlugin: maker [ 
	"extra rules for CroquetPlugin"
	maker addCrossSources: #('TriBoxStub.c').
]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureDropPlugin: maker [
	"extra rules for DropPlugin"

]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureFFIPlugin: maker [
	"extra rules for FFIPlugin"

	" it is incomplete right now, because in Cog this plugin are not used anymore"
	maker doNotGenerate: true.
	maker addCrossSources: #('sqFFIPlugin.c').
]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureFT2Plugin: maker [ 
	"extra rules for FT2Plugin"


]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureFilePlugin: maker [
	"extra rules for FilePlugin"

	maker addCrossSources: #( 'sqFilePluginBasicPrims.c').

]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureFloatMathPlugin: maker [
	"extra rules for FloatMathPlugin"

	maker addCrossSources: #(
		'acos.c' 'acosh.c' 'asin.c' 'asinh.c' 'atan.c' 'atan2.c' 'atanh.c'
		'copysign.c' 'cos.c' 'cosh.c' 'exp.c' 'expm1.c' 'finite.c' 'fmod.c'
		'hypot.c' 'isnan.c' 'k_cos.c' 'k_rem_pio2.c' 'k_sin.c' 'k_tan.c' 'ldexp.c'
		'log.c' 'log10.c' 'log1p.c' 'modf.c' 'pow.c' 'rem_pio2.c' 'rint.c'
		'scalb.c' 'scalbn.c' 'sin.c' 'sinh.c' 'sqrt.c' 'tan.c' 'tanh.c' ).

	
	"according to http://www.netlib.org/fdlibm/readme
	it should be compiled with no optimizations"
	maker addDefinitions: '-O0'.
	
	" compile with -D__LITTLE_ENDIAN
		This macro is set automatically in fdlibm.h when compiled ith -m32 but
		not when compiled with -m64 (Nicolas Cellier)
	"
	self isLittleEndian ifTrue: [
		maker addDefinitions: '-D__LITTLE_ENDIAN=1' ].
	
	"On *nix & mac with -DNO_ISNAN "
	maker puts:'
if (${WIN32})
	add_definitions(-Werror-implicit-function-declaration)	
else(${WIN32})
	add_definitions(-DNO_ISNAN)
endif (${WIN32})'.


]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureHostWindowPlugin: maker [
	"extra rules for HostWindowPlugin"

]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureIA32ABIPlugin: maker [
	"extra rules for IA32ABIPlugin"

	maker addCrossSources:
		#( 'ia32abicc.c')

]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureInternetConfigPlugin: maker [
	"extra rules for InternetConfigPlugin"
]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureJPEGReadWriter2Plugin: maker [ 
	"extra rules for JPEGReadWriter2Plugin"

maker addCrossSources: #(
'Error.c'
'jcapimin.c'
'jcapistd.c'
'jccoefct.c'
'jccolor.c'
'jcdctmgr.c'
'jchuff.c'
'jcinit.c'
'jcmainct.c'
'jcmarker.c'
'jcmaster.c'
'jcomapi.c'
'jcparam.c'
'jcphuff.c'
'jcprepct.c'
'jcsample.c'
'jctrans.c'
'jdapimin.c'
'jdapistd.c'
'jdatadst.c'
'jdatasrc.c'
'jdcoefct.c'
'jdcolor.c'
'jddctmgr.c'
'jdhuff.c'
'jdinput.c'
'jdmainct.c'
'jdmarker.c'
'jdmaster.c'
'jdmerge.c'
'jdphuff.c'
'jdpostct.c'
'jdsample.c'
'jdtrans.c'
'jerror.c'
'jfdctflt.c'
'jfdctfst.c'
'jfdctint.c'
'jidctflt.c'
'jidctfst.c'
'jidctint.c'
'jidctred.c'
'jmemdatadst.c'
'jmemdatasrc.c'
'jmemmgr.c'
'jmemnobs.c'
'jquant1.c'
'jquant2.c'
'jutils.c'
) 

]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureJoystickTabletPlugin: maker [ 
	"extra rules for JoystickTabletPlugin"

]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureLocalePlugin: maker [ 
	"extra rules for LocalePlugin"

]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureMIDIPlugin: maker [ 
	"extra rules for MIDIPlugin"

]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureMpeg3Plugin: maker [
	"extra rules for Mpeg3Plugin"

	maker includeDirectories: '${pluginCross}/libmpeg ${pluginCross}/libmpeg/audio ${pluginCross}/libmpeg/video'.

	maker addCrossSources: 
		#( 
		'libmpeg/bitstream.c' 
		'libmpeg/changesForSqueak.c'
		'libmpeg/audio/dct.c'
		'libmpeg/video/getpicture.c'
		'libmpeg/audio/header.c'
		'libmpeg/video/headers.c'
		'libmpeg/video/idct.c'
		'libmpeg/audio/layer1.c'
		'libmpeg/audio/layer2.c'
		'libmpeg/audio/layer3.c'
		'libmpeg/libmpeg3.c'
		'libmpeg/video/macroblocks.c'
		'libmpeg/video/mmxtest.c'
		'libmpeg/video/motion.c'
		'libmpeg/mpeg3atrack.c'
		'libmpeg/audio/mpeg3audio.c'
		'libmpeg/mpeg3demux.c'
		'libmpeg/mpeg3io.c'
		'libmpeg/mpeg3title.c'
		'libmpeg/video/mpeg3video.c'
		'libmpeg/mpeg3vtrack.c'
		'libmpeg/video/output.c'
		'libmpeg/audio/pcm.c'
		'libmpeg/video/reconstruct.c'
		'libmpeg/video/seek.c'
		'libmpeg/video/slice.c'
		
		'libmpeg/audio/synthesizers.c'
		'libmpeg/audio/tables.c'
		'libmpeg/video/vlc.c'
	).
	
	

]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configurePlugin: aPlugin with: generator [

	^ self perform: ( 'configure' , aPlugin name , ':' ) asSymbol with: generator.
	
]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureRePlugin: maker [ 
	"extra rules for RePlugin"

	maker addCrossSources: #(
		'pcre.c' 'study.c' 'get.c' 'chartables.c').

]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureReentrantIA32FFIPlugin: maker [
	"extra rules for ReentrantIA32FFIPlugin"
	
	maker addCrossSources: #(
		'sqFFIPlugin.c' 'sqFFITestFuncs.c' 'sqManualSurface.c'
	).


]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureSecurityPlugin: maker [ 
	"extra rules for SecurityPlugin"

]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureSerialPlugin: maker [ 
	"extra rules for SerialPlugin"


]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureSocketPlugin: maker [ 
	"extra rules for SocketPlugin"

]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureSoundCodecPlugin: maker [ 
	"extra rules for SoundCodecPlugin"

	maker addCrossSources:
		#( 'sqSoundCodecPluginBasicPrims.c' )



]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureSoundPlugin: maker [ 
	"extra rules for SoundPlugin"

]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureSurfacePlugin: maker [ 
	"extra rules for SurfacePlugin"

	maker set: #sources toString: ''. "remove default source file"
	maker addCrossSources: #('SurfacePlugin.c')



]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureThreadedIA32FFIPlugin: maker [
	"extra rules for ThreadedIA32FFIPlugin"
	
	maker addCrossSources: #(
		'sqFFIPlugin.c' 'sqFFITestFuncs.c' 'sqManualSurface.c'
	).


]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureUUIDPlugin: maker [ 
	"extra rules for UUIDPlugin"

]

{ #category : #'plugin extra rules' }
CPlatformConfig >> configureUnixOSProcessPlugin: maker [
	"extra rules for UnixOSProcessPlugin"

	maker includeDirectories: '${crossDir}/plugins/FilePlugin'.
	
	
	
	"THIS IS UGLY AND LAME!!! "
	maker set: #linkFlags toString: '-undefined dynamic_lookup'
]

{ #category : #'source files' }
CPlatformConfig >> coreSources [
	^#()
]

{ #category : #'source files' }
CPlatformConfig >> crossSources [ 
	^#(
			'sqHeapMap.c'
			'sqTicker.c'
			'sqExternalSemaphores.c'
			'sqNamedPrims.c'
			'sqVirtualMachine.c'
		)
]

{ #category : #plugins }
CPlatformConfig >> defaultExternalPlugins [
	self shouldBeImplemented 
]

{ #category : #plugins }
CPlatformConfig >> defaultInternalPlugins [
	self shouldBeImplemented 
]

{ #category : #utils }
CPlatformConfig >> dirFrom: aStringOrDir [
	
	^ aStringOrDir isString ifTrue: [
		FileDirectory on: ( FileDirectory fullPathForURI: aStringOrDir)] 
	ifFalse: [ aStringOrDir ]
]

{ #category : #utils }
CPlatformConfig >> doesNotUnderstand: aMessage [
	" ignore configureXYZ: messages "

	| sel  |
	sel := aMessage selector.
	
	((sel beginsWith: 'configure') and: [
		(sel indexOf: $: ) = sel size ] ) ifTrue: [ ^ self ].
	
	^ super doesNotUnderstand: aMessage
]

{ #category : #accessing }
CPlatformConfig >> executableName [
	"default one"
	^ 'Squeak'
]

{ #category : #accessing }
CPlatformConfig >> executableType [
	^ ''
]

{ #category : #plugins }
CPlatformConfig >> externalPlugins [
	^ externalPlugins ifNil: [ externalPlugins := self defaultExternalPlugins ]
]

{ #category : #plugins }
CPlatformConfig >> externalPlugins: aColl [

	externalPlugins := aColl
]

{ #category : #plugins }
CPlatformConfig >> extraPluginSettings: maker [
	"override in subclasses to apply extra settings for all plugins targets"
]

{ #category : #'source files' }
CPlatformConfig >> extraSources [
	^''
]

{ #category : #utils }
CPlatformConfig >> fixLineEndsOf: string [
	^ string 
]

{ #category : #accessing }
CPlatformConfig >> frameworks [
	"leave empty for all platforms but Mac OS"
	^ #()
]

{ #category : #public }
CPlatformConfig >> generate [
	^ CMakeVMGenerator generate: self 
]

{ #category : #'source generation' }
CPlatformConfig >> generateSources [
	"Generate whole VM + plugins sources"
	| maker |

	self validateSourcesPresent.
	self prepareForGeneration.
	
	"suppress questions and deprecation warnings during generation "
	[[
		
		maker := self prepareVMMaker.
	
		maker interpreterClass: self interpreterClass.
		self cogitClass ifNotNil: [:cg | 
			maker cogitClass: cg.
			"this is ugly, before VMMaker will be fixed to initialize stuff properly"
			Cogit initializeCompilationConstants.
			cg initializeWithOptions: (maker instVarNamed: 'optionsDictionary')
		].
		
		maker generateEntire

	] on: ProvideAnswerNotification do: [:ex | ex resume: true ]]
	on: Deprecation do: [:ex | ex resume ].
	
	

]

{ #category : #'source generation' }
CPlatformConfig >> generateStackSources [
	" generate sources for Stack Interpreter"

	StackInterpreter initialize.
	
	VMMaker
		generate: StackInterpreter
		to: self srcDir fullName
		platformDir: self platformsDir fullName
		excluding: #(BrokenPlugin IA32ABIPluginSimulator SlangTestPlugin TestOSAPlugin
			FFIPlugin ReentrantARMFFIPlugin ReentrantFFIPlugin ReentrantPPCBEFFIPlugin).
]

{ #category : #'source generation' }
CPlatformConfig >> generateVMOnlySources [
	"Generate source code for VM only, without plugins"
	| maker |

	self validateSourcesPresent.
	self prepareForGeneration.
	
	"suppress questions and deprecation warnings during generation "
	[[
		
		maker := self prepareVMMaker.
	
		maker interpreterClass: self interpreterClass.
		self cogitClass ifNotNil: [:cg | maker cogitClass: cg ].

	
		maker generateMainVM

	] on: ProvideAnswerNotification do: [:ex | ex resume: true ]]
	on: Deprecation do: [:ex | ex resume ].
	


]

{ #category : #plugins }
CPlatformConfig >> internalPlugins [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #plugins }
CPlatformConfig >> internalPlugins: aColl [

	internalPlugins := aColl
]

{ #category : #'source generation' }
CPlatformConfig >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	self subclassResponsibility 
]

{ #category : #testing }
CPlatformConfig >> isLittleEndian [
	"default is true. Override if necessary"
	^ true
]

{ #category : #accessing }
CPlatformConfig >> linkFlags [ 
	^''
]

{ #category : #accessing }
CPlatformConfig >> outputDir: anObject [
	"Set the value of outputDir"

	outputDir := anObject
]

{ #category : #accessing }
CPlatformConfig >> outputDirName [
	^ 'results'
]

{ #category : #'source files' }
CPlatformConfig >> platformSources [
	^#()
]

{ #category : #accessing }
CPlatformConfig >> platformsDir [ 
	"Answer the value of srcDir"

	^ platformsDir ifNil: [ platformsDir := (self topDir / self platformsDirName) fullName ]
	
]

{ #category : #accessing }
CPlatformConfig >> platformsDir: anObject [
	"Set the value of platformsDir"

	platformsDir := anObject
]

{ #category : #accessing }
CPlatformConfig >> platformsDirName [
	^ 'platforms'
]

{ #category : #accessing }
CPlatformConfig >> pluginsDir [ 
	^pluginsDir

]

{ #category : #accessing }
CPlatformConfig >> pluginsDir: aStringOrDir [
	"Set the value of topDir"

	pluginsDir := self dirFrom: aStringOrDir.
	
]

{ #category : #'source files' }
CPlatformConfig >> preferredIncludes [
	^#()
]

{ #category : #'source generation' }
CPlatformConfig >> prepareForCogGeneration. [
	"make sure these classes are initialized properly "	
	CogRTLOpcodes initialize.
	CogIA32Compiler initialize.
	

]

{ #category : #'source generation' }
CPlatformConfig >> prepareForGeneration [
	self subclassResponsibility 
]

{ #category : #'source generation' }
CPlatformConfig >> prepareForStackVMGeneration [
	"make sure these classes are initialized properly "	
		
	StackInterpreter initialize

]

{ #category : #'source generation' }
CPlatformConfig >> prepareVMMaker [

	| maker allPlugins |
	
	"In CogVMs (in contrast to Interpreter VM) the generated sources are platform independent, therefore Cross is ok"
	maker := VMMaker forPlatform: 'Cross'.
	
	maker sourceDirectoryName: self srcDir.
	maker platformRootDirectoryName: self platformsDir.
	
	
	allPlugins := self internalPlugins , self externalPlugins.
	
	"touch plugins to force their source generation unconditionally"
	allPlugins do: [:name | (Smalltalk globals at: name) touch ].
	
	" Why we put all plugins as external?   Because the generated sources are not different whether the plugins were defined as internal or external. VMMaker used to need this to to generate plugins.int and plugins.ext files. But since this is achieved in another way with CMakeVMMaker, there is no different at all to put all plugins as internal or as external."
	maker externalModules addAll:  allPlugins.
	
	^ maker
]

{ #category : #utils }
CPlatformConfig >> setExtraTargetProperties: maker [


]

{ #category : #directories }
CPlatformConfig >> setupDirectories: gen [
	| dirsInclude |

	" write the directories in separate include file"
	dirsInclude := gen captureOutputDuring: [
		gen
			set: #topDir toString: (self topDir fullName); 
			set: #buildDir toString: (self buildDir ifNil: ['${topDir}/build'] ifNotNil: [self buildDir fullName] );
			set: #platformsDir toString: self platformsDir;
			set: #srcDir toString: self srcDir;
			set: #srcPluginsDir toString: (pluginsDir ifNil: [ '${srcDir}/plugins' ]);
			set: #srcVMDir toString: '${srcDir}/vm';
			set: #platformName toString: self platformName;
			set: #targetPlatform to: '${platformsDir}/${platformName}';
			set: #crossDir toString: '${platformsDir}/Cross';
			set: #platformVMDir toString: '${targetPlatform}/vm';
			set: #outputDir toString: self outputDir.
	].

	self write: dirsInclude toFile: 'directories.cmake'
]

{ #category : #accessing }
CPlatformConfig >> srcDir [
	"Answer the value of srcDir"

	^ srcDir ifNil: [ srcDir := (self topDir / self srcDirName) assureExistence fullName ]
]

{ #category : #accessing }
CPlatformConfig >> srcDir: aStringOrDir [
	"Set the value of topDir"

	srcDir :=  aStringOrDir.
	
]

{ #category : #accessing }
CPlatformConfig >> srcDirName [
	^ 'src'
]

{ #category : #'source files' }
CPlatformConfig >> standardIncludes [ 
	^#()
]

{ #category : #directories }
CPlatformConfig >> topDir [
	
	^ topDir ifNil: [ topDir := FileDirectory default containingDirectory ].

]

{ #category : #directories }
CPlatformConfig >> topDir: pathString [

	topDir :=
		FileDirectory on: (FileDirectory fullPathForURI: pathString).
	topDir assureExistence.
]

{ #category : #'source generation' }
CPlatformConfig >> validateSourcesPresent [
	| sources |
	sources := FileDirectory openSources: SmalltalkImage current sourcesName forImage: SmalltalkImage current imageName.
	
	((sources == nil or: [sources atEnd])
			and: [ SmalltalkImage current checkSourcesFileAvailability])
		ifTrue: [
		self error: 'VM source code cannot be generated without .sources file'.
	]		
]

{ #category : #directories }
CPlatformConfig >> write: aContents toFile: aFileName [

	"write a file to current output directory (buildDir).
	use line end convention appropriate for config platform"
	

	| bldDir |
	
	bldDir := self buildDir.
	
 	bldDir isString ifTrue: [ bldDir := FileDirectory on: (FileDirectory fullPathForURI: bldDir) ].
	bldDir assureExistence.
	
	bldDir forceNewFileNamed: aFileName 
		do: [:stream | stream nextPutAll: (self fixLineEndsOf: aContents) ].
]
