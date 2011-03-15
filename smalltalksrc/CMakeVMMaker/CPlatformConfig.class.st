"
Base class, defining some common properties and behavior for all kinds of VM build configurations.

To generate a sources/build configuration use one of my subclasses with:
<config> generate.   - to generate a build configuration
<config> generateWithSources - to generate VMMaker sources and then build configuration.


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



"
Class {
	#name : #CPlatformConfig,
	#superclass : #Object,
	#instVars : [
		'topDir',
		'buildDir',
		'srcDir',
		'platformsDir',
		'internalPlugins',
		'externalPlugins',
		'pluginsDir',
		'externalLibs'
	],
	#category : #CMakeVMMaker
}

{ #category : #'as yet unclassified' }
CPlatformConfig class >> generate [

	^ CMakeVMGenerator new generate: self.
]

{ #category : #'as yet unclassified' }
CPlatformConfig class >> generateWithSources [
	| me |
	
	me := self new.
	
	"answer 'yes' to all VMMaker questions" 
	
	[[
		me generateSourceFiles.
	] on: ProvideAnswerNotification do: [:ex | ex resume: true ]]
	on: Warning do: [:ex | ex resume ].
	
	^ CMakeVMGenerator new generate: me.
]

{ #category : #directories }
CPlatformConfig >> buildDir [
	
	^ buildDir ifNil: [ buildDir := (self topDir / 'build') assureExistence ].

]

{ #category : #accessing }
CPlatformConfig >> buildDir: anObject [
	"Set the value of buildDir"

	buildDir := anObject
]

{ #category : #accessing }
CPlatformConfig >> cMakeMacros [
	^nil	
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
	maker addCrossSources: #('tribox.c').
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
	maker addDefinitions: '-O0 -mno-fused-madd'.
	
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
CPlatformConfig >> generateSourceFiles [
	" generate all interpreter source files and put them in to sources dir (srcDir ) "

	self subclassResponsibility
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

{ #category : #plugins }
CPlatformConfig >> internalPlugins [
	^ internalPlugins ifNil: [ internalPlugins := self defaultInternalPlugins ]
]

{ #category : #plugins }
CPlatformConfig >> internalPlugins: aColl [

	internalPlugins := aColl
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

{ #category : #'source files' }
CPlatformConfig >> platformSources [
	^#()
]

{ #category : #accessing }
CPlatformConfig >> platformsDir [
	"by default , answer the {topdir}/platforms subdir"

	^ platformsDir ifNil: [ platformsDir := self topDir / 'platforms' ]
]

{ #category : #accessing }
CPlatformConfig >> platformsDir: anObject [
	"Set the value of platformsDir"

	platformsDir := anObject
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
			set: #buildDir toString: (buildDir ifNil: ['${topDir}/build']);
			set: #platformsDir toString: self platformsDir fullName;
			set: #srcDir toString: self srcDir fullName;
			set: #srcPluginsDir toString: (pluginsDir ifNil: [ '${srcDir}/plugins' ]);
			set: #srcVMDir toString: '${srcDir}/vm';
			set: #platformName toString: self platformName;
			set: #targetPlatform to: '${platformsDir}/${platformName}';
			set: #crossDir toString: '${platformsDir}/Cross';
			set: #platformVMDir toString: '${targetPlatform}/vm'.
	].

	self write: dirsInclude toFile: 'directories.cmake'
]

{ #category : #accessing }
CPlatformConfig >> srcDir [
	"Answer the value of srcDir"

	^ srcDir ifNil: [ srcDir := self topDir / 'src' ]
]

{ #category : #accessing }
CPlatformConfig >> srcDir: aStringOrDir [
	"Set the value of topDir"

	srcDir := self dirFrom: aStringOrDir.
	
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
