"
A CMakePluginGeneratorForSqueak overides some CMakeVMPluginGenerator methods for squeak compatibility. 

I also add Dictionary for storing a plugins config.cmake file



"
Class {
	#name : #CMakePluginGeneratorForSqueak,
	#superclass : #CMakeGeneratorForSqueak,
	#instVars : [
		'plugin',
		'vmGen',
		'internal',
		'extraRules',
		'doNotGenerate',
		'externalDependencies',
		'configDotCMake',
		'templates'
	],
	#category : #CMakeVMMakerSqueak
}

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> addCrossSources: sources [

	^ self addSources: sources prefixed: '${pluginCross}/'

]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> addExternalDependency: aString [ 
	"We need to collect external dependencies to internal plugins because we need to force its 
	resolve before, and if we just add teh dependency in executable some times is not enough. 
	check StackIPhoneConfig>>#configureFT2Plugin: as an example"
	externalDependencies := externalDependencies copyWith: aString.
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> addExternalLibrary: aLibrary [ 
	self isInternal 
		ifTrue: [ vmGen addExternalLibrary: aLibrary ]
		ifFalse: [ super addExternalLibrary: aLibrary ].
]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> addPlatformSources: sources [

	^ self addSources: sources prefixed: '${pluginPlatform}/'

]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> config [
	^ vmGen config
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotAioPlugin [
	^'
 PLUGIN_DEFINITIONS (-DSQAIO_H=\"sqaio.h\")
 PLUGIN_INCLUDE_DIRECTORIES (${crossDir}/plugins/FilePlugin ${crossDir}/plugins/SocketPlugin)
'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotB3DAcceleratorPlugin [
	^'	  
	IF (OPENGL_FOUND OR AGL_FOUND)
	    SET (USE_OPENGL 1)
	    PLUGIN_INCLUDE_DIRECTORIES (${OPENGL_INCLUDE_DIR})
	  ELSE ()
	    PLUGIN_DISABLE ()
	  ENDIF ()

	  IF (OPENGL_FOUND)
	    SET (USE_X11_GLX 1)
	  ENDIF ()

	  IF (AGL_FOUND)
	    SET (USE_QUARTZ_CGL 1)
	    SET (HAVE_OPENGL_GL_H 1)
	  ENDIF ()

	  IF (OPENGL_FOUND OR AGL_FOUND)
	    CHECK_INCLUDE_FILE (GL/gl.h HAVE_GL_GL_H -I${OPENGL_INCLUDE_DIR})
	  ENDIF (OPENGL_FOUND OR AGL_FOUND)

	  CONFIG_DEFINE (USE_OPENGL)
	  CONFIG_DEFINE (USE_X11_GLX)
	  CONFIG_DEFINE (USE_QUARTZ_CGL)
	  CONFIG_DEFINE (HAVE_GL_GL_H)
	  CONFIG_DEFINE (HAVE_OPENGL_GL_H)

'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotBitBltSimulation [
	self flag:'tty'. "how to hand vm-hos-os STREQUAL linux"
	^'
SET(${plugin}_sources "${${plugin}_source_dir}/${plugin}.c")

SET(xbbp "${crossDir}/plugins/${plugin}")

IF (DEFINED ENABLE-FAST-BLT)
  LIST(APPEND ${plugin}_extra_sources ${xbbp}/BitBltDispatch.c ${xbbp}/BitBltGeneric.c)
  IF (vm-host-cpu MATCHES "arm")
    ENABLE_LANGUAGE (ASM)
    SET (CMAKE_ASM_COMPILE_OBJECT "asasm -cpu 6 -I ${xbbp} -o <OBJECT> <SOURCE>")
    LIST(APPEND ${plugin}_extra_sources
        ${xbbp}/BitBltArm.c ${xbbp}/BitBltArmSimd.c ${xbbp}/BitBltArmSimdAlphaBlend.s
        ${xbbp}/BitBltArmSimdBitLogical.s ${xbbp}/BitBltArmSimdPixPaint.s
        ${xbbp}/BitBltArmSimdSourceWord.s
    )
    PLUGIN_DEFINITIONS("-DENABLE_FAST_BLT")
    IF (vm-host-os STREQUAL "linux")
      LIST (APPEND ${plugin}_extra_sources ${xbbp}/BitBltArmLinux.c)
    ELSE ()
      LIST (APPEND ${plugin}_extra_sources ${xbbp}/BitBltArmOther.c)
    ENDIF ()


  ELSE ()
    MESSAGE (FATAL_ERROR "
  --enableFastBlt is not supported on this platform
"   )
  ENDIF ()
ENDIF ()

'
]

{ #category : #accessing }
CMakePluginGeneratorForSqueak >> configDotCMake [
	^ configDotCMake
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotCameraPlugin [
	^'PLUGIN_REQUIRE_INCLUDE(V4L2 linux/videodev2.h /usr/include)'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotClipboardExtendedPlugin [
	^'
IF (NOT X11_FOUND)
  PLUGIN_DISABLE()
ENDIF ()'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotCmakeEmpty [
	"most config.cmake files are empty files"
	^''
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotDropPlugin [
	^'PLUGIN_INCLUDE_DIRECTORIES (${cross}/plugins/FilePlugin)'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotFT2Plugin [
	^'PLUGIN_FIND_PACKAGE (FREETYPE freetype2)
IF (NOT FREETYPE_FOUND)
  CHECK_INCLUDE_FILE (ft2build.h HAVE_FT2BUILD_H)
  IF (NOT HAVE_FT2BUILD_H)
    PLUGIN_DISABLE ()
  ELSE ()
    PLUGIN_REQUIRE_LIBRARY (FREETYPE freetype)
    PLUGIN_REQUIRE_LIBRARY (Z z)
  ENDIF ()
ENDIF ()'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotFilePlugin [
	^'
CHECK_INCLUDE_FILE (dirent.h    HAVE_DIRENT_H)
CHECK_INCLUDE_FILE (sys/ndir.h  HAVE_SYS_NDIR_H)
CHECK_INCLUDE_FILE (sys/dir.h   HAVE_SYS_DIR_H)
CHECK_INCLUDE_FILE (ndir.h      HAVE_NDIR_H)
CHECK_INCLUDE_FILE (unistd.h    HAVE_UNISTD_H)

CONFIG_DEFINE (HAVE_DIRENT_H)
CONFIG_DEFINE (HAVE_SYS_NDIR_H)
CONFIG_DEFINE (HAVE_SYS_DIR_H)
CONFIG_DEFINE (HAVE_NDIR_H)
CONFIG_DEFINE (HAVE_UNISTD_H)
'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotFloatMathPlugin [
	^'
PLUGIN_DEFINITIONS (-DNO_ISNAN=1)

# fdlibm.h does not recognize x86_64, so set endianness here for all platforms.

TEST_BIG_ENDIAN (IS_BIG_ENDIAN)
IF (NOT IS_BIG_ENDIAN)
  PLUGIN_DEFINITIONS (-D__LITTLE_ENDIAN=1)
ENDIF ()

SET (LIBM_CFLAGS "${CMAKE_C_FLAGS}")

# GCC optimizations break fdlibm so disable them for now.
# 
# IF (CMAKE_COMPILER_IS_GNUCC AND CMAKE_SYSTEM_NAME STREQUAL "Linux")
#   SET (LIBM_CFLAGS "${CMAKE_C_FLAGS} -O0 -mno-fused-madd")
# ENDIF ()'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotGStreamerPlugin [
	^'PLUGIN_REQUIRE_PACKAGE (GLIB2 glib-2.0)
PLUGIN_REQUIRE_PACKAGE (XML2 libxml-2.0)
PLUGIN_REQUIRE_PACKAGE (GSTREAMER gstreamer-0.10)'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotHostWindowPlugin [
	^'
IF (NOT X11_FOUND)
    PLUGIN_DISABLE ()
ENDIF (NOT X11_FOUND)
'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotMIDIPlugin [
	^'	  
PLUGIN_REQUIRE_INCLUDE (ALSA_SOUNDLIB alsa/asoundlib.h)
PLUGIN_REQUIRE_LIBRARY (ASOUND asound)
IF (HAVE_ALSA_SOUNDLIB_H AND HAVE_LIBASOUND)
    SET           (USE_MIDI_ALSA 1)
    CONFIG_DEFINE (USE_MIDI_ALSA)
ENDIF ()
'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotMpeg3Plugin [
	^'	  
IF (VM_HOST_CPU MATCHES "i[3456789]86")
  PLUGIN_DEFINITIONS (-DUSE_MMX=1)
ENDIF ()

PLUGIN_DEFINITIONS (-DNOPTHREADS=1)

SET (lmp3 "${cross}/plugins/Mpeg3Plugin/libmpeg")

LIST(APPEND ${plugin}_extra_sources
  ${lmp3}/bitstream.c ${lmp3}/libmpeg3.c ${lmp3}/mpeg3atrack.c ${lmp3}/mpeg3demux.c ${lmp3}/mpeg3io.c
  ${lmp3}/mpeg3title.c ${lmp3}/mpeg3vtrack.c ${lmp3}/changesForSqueak.c
  ${lmp3}/audio/dct.c ${lmp3}/audio/header.c ${lmp3}/audio/layer2.c ${lmp3}/audio/layer3.c
  ${lmp3}/audio/mpeg3audio.c ${lmp3}/audio/pcm.c ${lmp3}/audio/synthesizers.c ${lmp3}/audio/tables.c
  ${lmp3}/video/getpicture.c ${lmp3}/video/headers.c ${lmp3}/video/idct.c ${lmp3}/video/macroblocks.c
  ${lmp3}/video/mmxtest.c ${lmp3}/video/motion.c ${lmp3}/video/mpeg3video.c ${lmp3}/video/output.c
  ${lmp3}/video/reconstruct.c ${lmp3}/video/seek.c ${lmp3}/video/slice.c ${lmp3}/video/vlc.c
)

PLUGIN_INCLUDE_DIRECTORIES (${lmp3} ${lmp3}/audio ${lmp3}/video)

'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotRomePlugin [
	^'	 
PLUGIN_REQUIRE_PACKAGE (PANGOCAIRO pangocairo)
PLUGIN_REQUIRE_PACKAGE (FREETYPE freetype2)
PLUGIN_REQUIRE_INCLUDE (CAIRO_FT cairo-ft.h)
PLUGIN_INCLUDE_DIRECTORIES (${cross}/plugins/SurfacePlugin)
 '
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotSocketPlugin [
	^'	 
PLUGIN_FIND_LIBRARY(SOCKET socket)
PLUGIN_FIND_LIBRARY(NSL nsl)
'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotSqueakSSL [
	^'PLUGIN_REQUIRE_PACKAGE (OPENSSL openssl)'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotUUIDPlugin [
	^'
PLUGIN_FIND_INCLUDE (UUID uuid.h)
CONFIG_DEFINE (HAVE_UUID_H)

PLUGIN_FIND_INCLUDE (SYS_UUID sys/uuid.h)
CONFIG_DEFINE (HAVE_SYS_UUID_H)

PLUGIN_FIND_INCLUDE (UUID_UUID uuid/uuid.h)
CONFIG_DEFINE (HAVE_UUID_UUID_H)

PLUGIN_FIND_LIBRARY (UUID uuid)

IF (HAVE_UUID_H OR HAVE_SYS_UUID_H OR HAVE_UUID_UUID_H)
  IF (HAVE_LIBUUID)
    SET (CMAKE_REQUIRED_LIBRARIES uuid)
  ENDIF (HAVE_LIBUUID)
ELSE ()
  PLUGIN_DISABLE ()
ENDIF (HAVE_UUID_H OR HAVE_SYS_UUID_H OR HAVE_UUID_UUID_H)

CHECK_FUNCTION_EXISTS (uuidgen HAVE_UUIDGEN)
CONFIG_DEFINE (HAVE_UUIDGEN)

CHECK_FUNCTION_EXISTS (uuid_generate HAVE_UUID_GENERATE)
CONFIG_DEFINE (HAVE_UUID_GENERATE)

CHECK_FUNCTION_EXISTS (uuid_create HAVE_UUID_CREATE)
CONFIG_DEFINE (HAVE_UUID_CREATE)

IF (NOT HAVE_UUIDGEN AND NOT HAVE_UUID_GENERATE AND NOT HAVE_UUID_CREATE)
  PLUGIN_DISABLE ()
ENDIF (NOT HAVE_UUIDGEN AND NOT HAVE_UUID_GENERATE AND NOT HAVE_UUID_CREATE)

# IF (UUID_UUID_GENERATE)
#   SET (HAVE_UUID_GENERATE 1)
#   PLUGIN_LINK_LIBRARIES (uuid)
# ENDIF (UUID_UUID_GENERATE)'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotVmDisplayFbdev [
	^'
PLUGIN_REQUIRE_INCLUDE (LINUX_FB linux/fb.h)
PLUGIN_SOURCES (${unix}/${plugin}/sqUnixFBDev.c)
'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotVmDisplayQuartz [
	^'IF (NOT APPLE)
  PLUGIN_DISABLE ()
ELSE ()
  PLUGIN_INCLUDE_DIRECTORIES (${cross}/plugins/B3DAcceleratorPlugin ${AGL_INCLUDE_DIR})
  PLUGIN_LINK_LIBRARIES (${AGL_LIBRARIES} "-framework Cocoa")
ENDIF (NOT APPLE)'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotVmDisplayX11 [
	^'SET (${plugin}_sources ${unix}/${plugin}/sqUnixX11.c ${unix}/${plugin}/sqUnixMozilla.c)

IF (NOT X11_FOUND)
  PLUGIN_DISABLE ()
ELSE ()
  SET (USE_X11 1)
  IF (X11_Xext_FOUND)
    SET (HAVE_LIBXEXT 1)
    CHECK_LIBRARY_EXISTS (Xext XShmAttach ${X11_LIBRARY_DIR} USE_XSHM)
  ENDIF ()
  CHECK_INCLUDE_FILE (X11/extensions/Xrender.h HAVE_X11_EXTENSIONS_XRENDER_H -I${X11_INCLUDE_DIR})
  IF (HAVE_X11_EXTENSIONS_XRENDER_H)
    CHECK_LIBRARY_EXISTS (Xrender XRenderQueryVersion ${X11_LIBRARY_DIR} HAVE_LIBXRENDER)
    IF (HAVE_LIBXRENDER)
      PLUGIN_LINK_LIBRARIES (${X11_Xrender_LIB})
    ENDIF ()
  ENDIF (HAVE_X11_EXTENSIONS_XRENDER_H)
  IF (OPENGL_FOUND)
    CHECK_INCLUDE_FILE (GL/gl.h HAVE_GL_GL_H -I${X11_INCLUDE_DIR})
    CHECK_INCLUDE_FILE (GL/glx.h HAVE_GL_GLX_H -I${X11_INCLUDE_DIR})
    IF (HAVE_GL_GL_H AND HAVE_GL_GLX_H)
      SET (USE_X11_GLX 1)
    ENDIF (HAVE_GL_GL_H AND HAVE_GL_GLX_H)
  ENDIF (OPENGL_FOUND)
  IF (DEFINED ENABLE-FAST-BLT)
    SET (USE_FAST_BLT 1)
    IF (vm-host-cpu MATCHES "arm")
      ENABLE_LANGUAGE (ASM)
      SET (CMAKE_ASM_COMPILE_OBJECT "asasm -cpu 6 -I ${cross}/plugins/BitBltPlugin -o <OBJECT> <SOURCE>")
      SET (${plugin}_sources ${${plugin}_sources} "${unix}/${plugin}/sqUnixX11Arm.S")
    ELSE ()
      MESSAGE (FATAL_ERROR "
  --enableFastBlt is not supported on this platform
"     )
    ENDIF ()
  ENDIF (DEFINED ENABLE-FAST-BLT)
  PLUGIN_INCLUDE_DIRECTORIES (${cross}/plugins/B3DAcceleratorPlugin ${cross}/plugins/FilePlugin)
  PLUGIN_INCLUDE_DIRECTORIES (${X11_INCLUDE_DIR} ${OPENGL_INCLUDE_DIR})
  PLUGIN_LINK_LIBRARIES (${X11_LIBRARIES} ${OPENGL_LIBRARIES})
ENDIF ()

CONFIG_DEFINE (USE_X11)
CONFIG_DEFINE (USE_X11_GLX)
CONFIG_DEFINE (USE_FAST_BLT)

CONFIG_DEFINE (HAVE_LIBXEXT)
CONFIG_DEFINE (HAVE_LIBXRENDER)

CONFIG_DEFINE (USE_XSHM)

CONFIG_DEFINE (USE_XICFONT_OPTION)
CONFIG_DEFINE (USE_XICFONT_DEFAULT)
CONFIG_DEFINE (USE_XICFONT_RESOURCE)

CHECK_FUNCTION_EXISTS (snprintf HAVE_SNPRINTF)
CHECK_FUNCTION_EXISTS (__snprintf       HAVE___SNPRINTF)

CONFIG_DEFINE (HAVE_SNPRINTF)
CONFIG_DEFINE (HAVE___SNPRINTF)

CHECK_INCLUDE_FILE (sys/select.h HAVE_SYS_SELECT_H)

CONFIG_DEFINE (HAVE_SYS_SELECT_H)'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotVmSoundALSA [
	^'PLUGIN_REQUIRE_INCLUDE (ALSA_SOUNDLIB alsa/asoundlib.h)
PLUGIN_REQUIRE_LIBRARY (ASOUND asound)
'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotVmSoundMacOSX [
	^'
IF (NOT APPLE)
  PLUGIN_DISABLE ()
ENDIF ()'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotVmSoundNAS [
	^'PLUGIN_REQUIRE_INCLUDE (AUDIO_AUDIO_H audio/audio.h)
PLUGIN_REQUIRE_LIBRARY (AUDIO audio)
'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotVmSoundOSS [
	^'PLUGIN_REQUIRE_INCLUDE (ALSA_SOUNDLIB alsa/asoundlib.h)
PLUGIN_REQUIRE_LIBRARY (ASOUND asound)
'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotVmSoundPulse [
	^'PLUGIN_REQUIRE_LIBRARY (PULSE pulse-simple)'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotVmSoundSun [
	^'PLUGIN_FIND_INCLUDE (SYS_AUDIOIO sys/audioio.h)
PLUGIN_FIND_INCLUDE (SUN_AUDIOIO sun/audioio.h)
PLUGIN_REQUIRE_INCLUDE (STROPTS stropts.h)

IF (NOT VM_HOST_OS MATCHES "solaris.*")
  PLUGIN_DISABLE ()
ELSE ()
  IF (NOT HAVE_SYS_AUDIOIO_H AND NOT HAVE_SUN_AUDIOIO_H)
    PLUGIN_DISABLE ()
  ENDIF ()
ENDIF ()

CONFIG_DEFINE (HAVE_SYS_AUDIOIO_H)
'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotWeDoPlugin [
	^'PLUGIN_REQUIRE_INCLUDE(HIDDEV linux/hiddev.h /usr/include)'
]

{ #category : #'cmake commands' }
CMakePluginGeneratorForSqueak >> configDotXDisplayControlPlugin [
	^'IF (NOT X11_FOUND)
    PLUGIN_DISABLE ()
ELSE ()
    PLUGIN_INCLUDE_DIRECTORIES (${cross}/plugins/FilePlugin ${cross}/plugins/SocketPlugin)
ENDIF ()'
]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> configurationName [
	^ vmGen configurationName
]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> doNotGenerate [

	"Forcely exclude plugin form build. Use this method only for debugging purposes.
	
	Front-end users should simply specify different list of plugins for building VM,
	effectively excluding any unwanted stuff "
	
	^doNotGenerate
]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> doNotGenerate: aValue [

	"Forcely exclude plugin form build. Use this method only for debugging purposes.
	
	Front-end users should simply specify different list of plugins for building VM,
	effectively excluding any unwanted stuff "
	
	doNotGenerate := aValue
]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> externalDependencies [
	^ externalDependencies
]

{ #category : #'squeak compatibility' }
CMakePluginGeneratorForSqueak >> generate: aPlugin for: aCMakeVMGenerator internal: aBoolean extraRules: aBlock [

	doNotGenerate := false.
	internal := aBoolean.
	plugin := aPlugin.
	vmGen := aCMakeVMGenerator.
	extraRules := aBlock.
		
	^ self generateByTemplate
]

{ #category : #'squeak compatibility' }
CMakePluginGeneratorForSqueak >> generateByTemplate [
	| name  |

	output := String new writeStream.
	name := plugin moduleName.
	templates:= OrderedCollection new.
      
	templates
		addLast:((CMakeMessage new) message: (internal ifTrue: [ 'Adding internal plugin: '] ifFalse: ['Adding external plugin: '])  , name);
		addLast:((CMakeSet new) variable: #pluginName quotedValue: name);
		addLast:((CMakeSet new) variable: #pluginSrc quotedValue:  '${srcPluginsDir}/', name);
		addLast:((CMakeSet new) variable: #pluginCross quotedValue: '${crossDir}/plugins/', name );
		addLast:((CMakeSet new) variable: #pluginPlatform quotedValue: '${targetPlatform}/plugins/', name );
		addLast:((CMakeSet new) variable: #LINKLIBS value: '' ).  "clear LINKLIBS variable"
	internal ifTrue: [ templates addLast:((CMakeAddDefinitions new) definitions: (OrderedCollection with: '-DSQUEAK_BUILTIN_PLUGIN' ))].
      templates 
		addLast:((CMakeListAppend new) list: 'sources' elements: (OrderedCollection with: '${pluginSrc}/', name , '.c' ));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${pluginSrc} ${pluginCross} ${targetPlatform}/plugins/${pluginName}'))." default include directories for plugin "
	vmGen config configureByTemplatePlugin: plugin with: self. 
	extraRules ifNotNil: [ extraRules value: self ].
	" generate a static lib for internal plugin, or shared for external"
	internal 
		ifTrue: [	templates addLast:((CMakeAddLibrary new) library: name type: 'STATIC' sources: (OrderedCollection with: '${sources}'))]
		ifFalse: [templates addLast:((CMakeAddLibrary new) library: name type: 'SHARED' sources: (OrderedCollection with: '${sources}'))].
	vmGen config extraPluginSettings: self.   
	self isExternal 
		ifTrue: [	templates addLast:((CMakeTargetLinkLibraries new) target: self moduleName  items: (OrderedCollection with: '${LINKLIBS}'))].
       templates
		addLast:((CMakeSetProperty new) scope: 'TARGET ', name property: 'LINK_FLAGS' values: (OrderedCollection with: '${linkFlags}')); " see senders of #linkFlags "
		addLast:((CMakeIfPluginDependencies new) plugin: self moduleName dependencies: (OrderedCollection with: ' ${', self moduleName , '_dependencies}')).
	templates do: [:each | self puts: each content].
	self saveFile.



]

{ #category : #'initialize-release' }
CMakePluginGeneratorForSqueak >> initialize [ 
	super initialize.
	externalDependencies := #().
	configDotCMake:=self initializeConfigDotCmakeFiles.
]

{ #category : #'initialize-release' }
CMakePluginGeneratorForSqueak >> initializeConfigDotCmakeFiles [
	"simple hard-coded Dictionary keyed by plugin name containing the contents of a Plugin's config.cmake file.
	is this true? Currently we are dumping the below into the master CMakeLists.txt file. Should it be in config.cmake? 
	Should each plugin have its own config.cmake in its subdirectory?
	
	Take a look at configDotCameraPlugin and the non-portable /usr/include therein.
	
	This has to be rethought and specified correctly. 
	
	In PostBuildActions the config.cmake file is included in the CMakeLists.txt.
	
	config.cmake is not from pharo, it is from the original CMake work done by Ian.
	
	This leads me to speculate that each plugin should write its 'config.cmake' data into the config.cmake file.
	This data should be configuration commands like config_define(THIS_THAT_ETC)
	
	Looking at configDotB3DAcceleratorPlugin this makes sense.
	
	
		"
	|d|
	self flag:'tty. see this method comment.'.
	d:=Dictionary new.
	d 
		at: #ADPCMCodecPlugin put: self configDotCmakeEmpty;
		at: #AioPlugin put: self configDotCmakeEmpty;
		at: #UnixAioPlugin put: self configDotCmakeEmpty;
		at: #B3DAcceleratorPlugin put: self configDotCmakeEmpty;
		at: #BMPReadWriterPlugin put: self configDotCmakeEmpty;
		at: #BalloonEngineBase put: self configDotCmakeEmpty;
		at: #BalloonEnginePlugin put: self configDotCmakeEmpty;
		at: #BalloonEngineSimulation put: self configDotCmakeEmpty;
		at: #BrokenPlugin put: self configDotCmakeEmpty;
		at: #CameraPlugin put: self configDotCmakeEmpty;
		at: #CroquetPlugin put: self configDotCmakeEmpty;
		at: #DSAPlugin put: self configDotCmakeEmpty;
		at: #DropPlugin put: self configDotCmakeEmpty;
		at: #FFIPlugin put: self configDotFilePlugin;
		at: #FFTPlugin put: self configDotCmakeEmpty;
		at: #FilePlugin put: self configDotFilePlugin;
		at: #FilePluginSimulator put: self configDotCmakeEmpty;
		at: #FloatArrayPlugin put: self configDotCmakeEmpty;
		at: #FloatMathPlugin put: self configDotCmakeEmpty;
		at: #FloatMathPluginSimulator put: self configDotCmakeEmpty;
		at: #IA32ABIPlugin put: self configDotCmakeEmpty;
		at: #IA32ABIPluginSimulator put: self configDotCmakeEmpty;
		at: #InflatePlugin put: self configDotCmakeEmpty;
		at: #DeflatePlugin put: self configDotCmakeEmpty;
		at: #JPEGReaderPlugin put: self configDotCmakeEmpty;
		at: #KlattSynthesizerPlugin put: self configDotCmakeEmpty;
		at: #Matrix2x3Plugin put: self configDotCmakeEmpty;
		at: #MiscPrimitivePlugin put: self configDotCmakeEmpty;
		at: #NewsqueakIA32ABIPlugin put: self configDotCmakeEmpty;
		at: #NewsqueakIA32ABIPluginAttic put: self configDotCmakeEmpty;
		at: #NewsqueakIA32ABIPluginSimulator put: self configDotCmakeEmpty;
		at: #OSProcessPlugin put: self configDotCmakeEmpty;
		at: #UnixOSProcessPlugin put: self configDotCmakeEmpty;
		at: #Win32OSProcessPlugin put: self configDotCmakeEmpty;
		at: #ScratchPlugin put: self configDotCmakeEmpty;
		at: #SecurityPlugin put: self configDotCmakeEmpty;
		at: #SlangTestPlugin put: self configDotCmakeEmpty;
		at: #SmartSyntaxInterpreterPlugin put: self configDotCmakeEmpty;
		at: #AsynchFilePlugin put: self configDotCmakeEmpty;
		at: #BitBltSimulation put: self configDotCmakeEmpty;
		at: #BitBltSimulator put: self configDotCmakeEmpty;
		at: #BochsIA32Plugin put: self configDotCmakeEmpty;
		at: #ClipboardExtendedPlugin put: self configDotCmakeEmpty;
		at: #FT2Plugin put: self configDotCmakeEmpty;
		at: #FileCopyPlugin put: self configDotCmakeEmpty;
		at: #GdbARMPlugin put: self configDotCmakeEmpty;
		at: #GeniePlugin put: self configDotCmakeEmpty;
		at: #HostWindowPlugin put: self configDotCmakeEmpty;
		at: #IOSPlugin put: self configDotCmakeEmpty;
		at: #ImmX11Plugin put: self configDotCmakeEmpty;
		at: #InternetConfigPlugin put: self configDotCmakeEmpty;
		at: #JPEGReadWriter2Plugin put: self configDotCmakeEmpty;
		at: #JoystickTabletPlugin put: self configDotCmakeEmpty;
		at: #LargeIntegersPlugin put: self configDotCmakeEmpty;
		at: #LocalePlugin put: self configDotCmakeEmpty;
		at: #MIDIPlugin put: self configDotCmakeEmpty;
		at: #MacMenubarPlugin put: self configDotCmakeEmpty;
		at: #Mpeg3Plugin put: self configDotCmakeEmpty;
		at: #ObjectiveCPlugin put: self configDotCmakeEmpty;
		at: #QuicktimePlugin put: self configDotCmakeEmpty;
		at: #RePlugin put: self configDotCmakeEmpty;
		at: #SerialPlugin put: self configDotCmakeEmpty;
		at: #SocketPlugin put: self configDotCmakeEmpty;
		at: #SoundPlugin put: self configDotCmakeEmpty;
		at: #TestOSAPlugin put: self configDotCmakeEmpty;
		at: #UUIDPlugin put: self configDotCmakeEmpty;
		at: #SmartSyntaxPluginSimulator put: self configDotCmakeEmpty;
		at: #SoundCodecPlugin put: self configDotCmakeEmpty;
		at: #SoundGenerationPlugin put: self configDotCmakeEmpty;
		at: #SqueakSSLPlugin put: self configDotCmakeEmpty;
		at: #StarSqueakPlugin put: self configDotCmakeEmpty;
		at: #SurfacePlugin put: self configDotCmakeEmpty;
		at: #ThreadedFFIPlugin put: self configDotCmakeEmpty;
		at: #ThreadedARMFFIPlugin put: self configDotCmakeEmpty;
		at: #ThreadedIA32FFIPlugin put: self configDotCmakeEmpty;
		at: #ThreadedPPCBEFFIPlugin put: self configDotCmakeEmpty;
		at: #UnicodePlugin put: self configDotCmakeEmpty;
		at: #VMProfileLinuxSupportPlugin put: self configDotCmakeEmpty;
		at: #VMProfileMacSupportPlugin put: self configDotCmakeEmpty;
		at: #WeDoPlugin put: self configDotCmakeEmpty;
		at: #XDisplayControlPlugin put: self configDotCmakeEmpty.
	^d.

]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> isExternal [
	^ internal not
]

{ #category : #accessing }
CMakePluginGeneratorForSqueak >> isInternal [
	^ internal
]

{ #category : #accessing }
CMakePluginGeneratorForSqueak >> isInternal: aBoolean [
	internal:= aBoolean
]

{ #category : #accessing }
CMakePluginGeneratorForSqueak >> moduleName [ 
	^plugin moduleName
]

{ #category : #'as yet unclassified' }
CMakePluginGeneratorForSqueak >> plugin [
	^ plugin
]

{ #category : #'squeak compatibility' }
CMakePluginGeneratorForSqueak >> saveFile [
	
	| reference |
	reference := ((vmGen config dirFrom: vmGen buildDir) / plugin moduleName).
	reference assureExistence.
	reference 
		forceNewFileNamed: (self outputFileName)
		do:[:s | s nextPutAll:(self config fixLineEndsOf: output contents)]

]

{ #category : #accessing }
CMakePluginGeneratorForSqueak >> templates [
	^templates
]

{ #category : #accessing }
CMakePluginGeneratorForSqueak >> templates: anOrderedCollection [
	templates := anOrderedCollection
]

{ #category : #accessing }
CMakePluginGeneratorForSqueak >> vmGenerator [
	"Make it accessible from plugin generator side"
	^ vmGen
]

{ #category : #accessing }
CMakePluginGeneratorForSqueak >> vmGenerator: aCMakeVMGeneratorForSqueak [
	"needed for tests"
	vmGen := aCMakeVMGeneratorForSqueak
]
