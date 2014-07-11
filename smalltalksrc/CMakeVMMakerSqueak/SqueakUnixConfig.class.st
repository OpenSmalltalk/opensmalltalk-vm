"
A SqueakUnixConfig is a top level configuration for *nix configuratons.

"
Class {
	#name : #SqueakUnixConfig,
	#superclass : #CPlatformConfigForSqueak,
	#category : #CMakeVMMakerSqueak
}

{ #category : #nil }
SqueakUnixConfig class >> vmConfigCmake [
	"move the CXX_FLAGS out later
"
	^'

IF (NOT DEFINED __sq_config_h)

	  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}  -Wall -m32")
	  SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}  -Wall -m32")
	  SET(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}  -Wall -m32")
	  SET(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}  -Wall -m32")
	  SET(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}  -Wall -m32")
	  SET(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -Wall -m32")
	  MESSAGE("CMAKE_C_FLAGS=${CMAKE_C_FLAGS}")
	  MESSAGE("CMAKE_C_FLAGS_RELEASE=${CMAKE_C_FLAGS_RELEASE}")
	  MESSAGE("CMAKE_C_FLAGS_DEBUG=${CMAKE_C_FLAGS_DEBUG}")
	  MESSAGE("CMAKE_CXX_FLAGS_RELEASE=${CMAKE_CXX_FLAGS_RELEASE}")
	  MESSAGE("CMAKE_CXX_FLAGS_DEBUG=${CMAKE_CXX_FLAGS_DEBUG}")
	  GET_DIRECTORY_PROPERTY( DirDefs DIRECTORY ${CMAKE_SOURCE_DIR} COMPILE_DEFINITIONS )
	  FOREACH( d ${DirDefs} )
	      MESSAGE( STATUS "Found Define: " ${d} )
	  ENDFOREACH()
	  MESSAGE( STATUS "DirDefs: " ${DirDefs} )

	SET(__sq_config_h 1)
	CONFIG_DEFINE(__sq_config_h)

	SET (OS_TYPE \"unix\")
	CONFIG_DEFINE (OS_TYPE)

	SET (version  \"1.2.3.4\")

	SET (without_gl "")
	STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\1" major   ${version})
	STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\2" minor   ${version})
	STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\3" patch   ${version})
	STRING (REGEX REPLACE "(.*)\\.(.*)\\.(.*)-(.*)" "\\4" release ${version})


	IF (CMAKE_COMPILER_IS_GNUCC)
	  SET (interp gnu-interp)
	ELSE ()
	  SET (interp interp)
 	 MESSAGE ("!! Cannot optimise interpreter performance for GCC")
	ENDIF (CMAKE_COMPILER_IS_GNUCC)

#LIBRARIES
#define HAVE_LANGINFO_CODESET 1
#define	TIME_WITH_SYS_TIME 1
#define	HAVE_LIBDL 1
	CHECK_LIBRARY_EXISTS (dl dlopen "" HAVE_LIBDL)
	IF (HAVE_LIBDL)
 	 CONFIG_DEFINE(HAVE_LIBDL)
	ENDIF (HAVE_LIBDL)

#HEADERS
	check_include_file("unistd.h" HAVE_UNISTD_H)
	if(HAVE_UNISTD_H)
	 CONFIG_DEFINE(HAVE_UNISTD_H)
	endif()

	check_include_file("dirent.h" HAVE_DIRENT_H)
	if(HAVE_DIRENT_H)
	 CONFIG_DEFINE(HAVE_DIRENT_H)
	endif()

	check_include_file("pty.h" HAVE_PTY_H)
	if(HAVE_PTY_H)
	 CONFIG_DEFINE(HAVE_PTY_H)
	endif()

	check_include_file("stropts.h" HAVE_STROPTS_H)
	if(HAVE_STROPTS_H)
	 CONFIG_DEFINE(HAVE_STROPTS_H)
	endif()

#PACKAGES
	FIND_PACKAGE (X11)
	IF (X11_FOUND)
 	 LIST (REMOVE_DUPLICATES X11_INCLUDE_DIR)
	 SET(USE_X11 1)
	 CONFIG_DEFINE(USE_X11)
	ENDIF ()

	message("without-gl = ${without_gl}")

	IF (NOT without-gl)
	  FIND_PACKAGE (OpenGL)
 	 LIST (REMOVE_DUPLICATES OPENGL_INCLUDE_DIR)
	ENDIF ()


	IF (NOT OPENGL_FOUND)
	  SET (OPENGL_INCLUDE_DIR "")
	ENDIF ()

	MESSAGE("OPENGL variables:")
	 FOREACH (var AGL_FOUND AGL_INCLUDE_DIR AGL_LIBRARIES OPENGL_FOUND OPENGL_INCLUDE_DIR OPENGL_LIBRARIES)
	    MESSAGE ("${var} = ${${var}}")
	  ENDFOREACH ()

	TEST_BIG_ENDIAN (WORDS_BIGENDIAN)
	IF (WORDS_BIGENDIAN)
	  SET (MSB_FIRST 1)
	ELSE ()
	  SET (LSB_FIRST 1)
	ENDIF ()

	CONFIG_DEFINE (WORDS_BIGENDIAN)
	CONFIG_DEFINE (LSB_FIRST)
	CONFIG_DEFINE (MSB_FIRST)

	CHECK_FUNCTION_EXISTS (atexit		HAVE_ATEXIT)
	CHECK_FUNCTION_EXISTS (on_exit		HAVE_ON_EXIT)

	IF (HAVE_ATEXIT)
	  SET (AT_EXIT atexit)
	ELSEIF (HAVE_ON_EXIT)
	  SET (AT_EXIT on_exit)
	ENDIF ()

	CONFIG_DEFINE (AT_EXIT)

	MESSAGE("# sqMemoryAccess.h")
	CHECK_INCLUDE_FILE (interp.h HAVE_INTERP_H -I${srcVMDir})
	CONFIG_DEFINE (HAVE_INTERP_H)

	CHECK_TYPE_SIZE (int SIZEOF_INT)
	CHECK_TYPE_SIZE (long SIZEOF_LONG)
	CHECK_TYPE_SIZE ("long long" SIZEOF_LONG_LONG)
	CHECK_TYPE_SIZE ("void *" SIZEOF_VOID_P)

	CONFIG_DEFINE (SIZEOF_INT)
	CONFIG_DEFINE (SIZEOF_LONG)
	CONFIG_DEFINE (SIZEOF_LONG_LONG)
	CONFIG_DEFINE (SIZEOF_VOID_P)

	TRY_RUN (DOUBLE_WORD_ALIGNMENT tmp ${CMAKE_BINARY_DIR}  ${CMAKE_BINARY_DIR}/testDoubleWordAlignment.c)
	TRY_RUN (DOUBLE_WORD_ORDER tmp ${CMAKE_BINARY_DIR}  ${CMAKE_BINARY_DIR}/testDoubleWordOrder.c)

	CONFIG_DEFINE (DOUBLE_WORD_ALIGNMENT)
	CONFIG_DEFINE (DOUBLE_WORD_ORDER)

	MESSAGE("# sqPlatformSpecific.h")

	CHECK_INCLUDE_FILE (alloca.h HAVE_ALLOCA_H)
	CONFIG_DEFINE (HAVE_ALLOCA_H)
	IF (HAVE_ALLOCA_H)
 	 SET (HAVE_ALLOCA 1)
	ELSE ()
	  CHECK_FUNCTION_EXISTS (alloca HAVE_ALLOCA)
	ENDIF ()

	CONFIG_DEFINE (HAVE_ALLOCA)

	MESSAGE("# aio.c")

	CHECK_INCLUDE_FILE (sys/time.h HAVE_SYS_TIME_H)
	CHECK_INCLUDE_FILE (sys/filio.h HAVE_SYS_FILIO_H)

	CONFIG_DEFINE (HAVE_SYS_TIME_H)
	CONFIG_DEFINE (HAVE_SYS_FILIO_H)

	CHECK_FUNCTION_EXISTS (nanosleep HAVE_NANOSLEEP)

	CONFIG_DEFINE (HAVE_NANOSLEEP)

	MESSAGE("# sqUnixCharConv.c")

	CHECK_INCLUDE_FILE (iconv.h HAVE_ICONV_H)
	CHECK_INCLUDE_FILE (langinfo.h HAVE_LANGINFO_H)

	IF (HAVE_LANGINFO_H)
 	 TRY_COMPILE (HAVE_LANGINFO_CODESET ${CMAKE_BINARY_DIR}  ${CMAKE_BINARY_DIR}/testLanginfoCodeset.c)
	ENDIF (HAVE_LANGINFO_H)

	CHECK_LIBRARY_EXISTS (iconv libiconv_open "" HAVE_LIBICONV)
	IF (HAVE_LIBICONV)
 	 USE_LIBRARY (iconv)
	ENDIF (HAVE_LIBICONV)

	CONFIG_DEFINE (HAVE_ICONV_H)
	CONFIG_DEFINE (HAVE_LANGINFO_CODESET)

	MESSAGE("# sqUnixExternalPrims.c")

	CHECK_INCLUDE_FILE (dlfcn.h HAVE_DLFCN_H)

	CHECK_LIBRARY_EXISTS (dl dlopen "" HAVE_LIBDL)
	IF (HAVE_LIBDL)
 	 USE_LIBRARY (dl)
	ENDIF (HAVE_LIBDL)
	IF (HAVE_LIBDL)
 	 SET (HAVE_DLOPEN 1)
	ELSE ()
	  CHECK_FUNCTION_EXISTS (dlopen HAVE_DLOPEN)
	ENDIF (HAVE_LIBDL)

	CHECK_FUNCTION_EXISTS (_dyld_present HAVE_DYLD)
	CHECK_FUNCTION_EXISTS (snprintf HAVE_SNPRINTF)
	CHECK_FUNCTION_EXISTS (__snprintf HAVE___SNPRINTF)

	CONFIG_DEFINE (HAVE_DLFCN_H)
	CONFIG_DEFINE (HAVE_DLOPEN)
	CONFIG_DEFINE (HAVE_DYLD)
	CONFIG_DEFINE (HAVE_SNPRINTF)
	CONFIG_DEFINE (HAVE___SNPRINTF)

	SET (VM_X11DIR \"${X11_LIBRARY_DIR}\")

	CONFIG_DEFINE (VM_X11DIR)

	SET (VM_MODULE_PREFIX \"${CMAKE_SHARED_MODULE_PREFIX}\")

	CONFIG_DEFINE (VM_MODULE_PREFIX)

	SET (CMAKE_SHARED_MODULE_PREFIX "so.")
	SET (CMAKE_SHARED_MODULE_SUFFIX "")

	SET (MODULE_PREFIX  \"${CMAKE_SHARED_MODULE_PREFIX}\")
	SET (MODULE_SUFFIX  \"${CMAKE_SHARED_MODULE_SUFFIX}\")
	SET (LIBRARY_PREFIX \"${CMAKE_SHARED_LIBRARY_PREFIX}\")
	SET (LIBRARY_SUFFIX \"${CMAKE_SHARED_LIBRARY_SUFFIX}\")

	CONFIG_DEFINE (MODULE_PREFIX)
	CONFIG_DEFINE (MODULE_SUFFIX)
	CONFIG_DEFINE (LIBRARY_PREFIX)
	CONFIG_DEFINE (LIBRARY_SUFFIX)

	MESSAGE("# sqUnixMain.c")

	SET (VM_BUILD_STRING "\"Unix built on \"__DATE__ \" \"__TIME__\" Compiler: \"__VERSION__")

	CONFIG_DEFINE (VM_BUILD_STRING)


	SET (VM_LIBDIR "\"${prefix}/${plgdir}\"")

	CONFIG_DEFINE (VM_LIBDIR)

	SET (VM_HOST        \"${VM_HOST}\")
	SET (VM_HOST_CPU    \"${VM_HOST_CPU}\")
	SET (VM_HOST_VENDOR \"${VM_HOST_VENDOR}\")
	SET (VM_HOST_OS     \"${VM_HOST_OS}\")

	CONFIG_DEFINE (VM_HOST)
	CONFIG_DEFINE (VM_HOST_CPU)
	CONFIG_DEFINE (VM_HOST_VENDOR)
	CONFIG_DEFINE (VM_HOST_OS)

	SET (VM_VERSION_INFO \"${VM_VERSION}${versionsuffix}\")
	SET (VM_VERSION \"${VM_VERSION}\")
	SET (PLATFORM_SOURCE_VERSION \"${PLATFORM_SOURCE_VERSION}\")

	CONFIG_DEFINE (VM_VERSION)
	CONFIG_DEFINE (VM_VERSION_INFO)
	CONFIG_DEFINE (PLATFORM_SOURCE_VERSION)
	CONFIG_DEFINE (SQ_VERSION)

	CHECK_FUNCTION_EXISTS (tzset	HAVE_TZSET)
	CHECK_VARIABLE_EXISTS (timezone	HAVE_TIMEZONE)
	CHECK_STRUCT_HAS_MEMBER ("struct tm" tm_gmtoff time.h HAVE_TM_GMTOFF)

	CONFIG_DEFINE (HAVE_TZSET)
	CONFIG_DEFINE (HAVE_TIMEZONE)
	CONFIG_DEFINE (HAVE_TM_GMTOFF)

	CONFIG_DEFINE (IMAGE_DUMP)

	MESSAGE("# sqUnixMemory.c")

	CHECK_FUNCTION_EXISTS (mmap HAVE_MMAP)
	CONFIG_DEFINE (HAVE_MMAP)

	MESSAGE("# OLPC")

	IF (NOT without-SUGAR)
 	 SET (SUGAR 1)
	ENDIF ()

	CONFIG_DEFINE (SUGAR)

	IF (DEFINED SQ_VI_BYTES_PER_WORD)
 	 CONFIG_DEFINE (SQ_VI_BYTES_PER_WORD)
	ENDIF (DEFINED SQ_VI_BYTES_PER_WORD)




ENDIF (NOT DEFINED __sq_config_h)
'
]

{ #category : #'compiler flags' }
SqueakUnixConfig >> commonCompilerFlags [
	"avoid premature optimization. push this decision down lower if it is needed at all"
	self deprecated: ' its much easier to have all the flags in your configuration class.  '.
	^{}


]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureAsynchFilePlugin: maker [

	maker addPlatformSources:
	#( 
		'sqUnixAsynchFile.c'
	)


]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureB3DAcceleratorPlugin: maker [
	"extra rules for B3DAcceleratorPlugin"
	
	super configureB3DAcceleratorPlugin: maker.
	
	maker 
		addPlatformSources: #( 'sqUnixOpenGL.c' ) 
		

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureDropPlugin: maker [
	"extra rules for DropPlugin"
	super configureDropPlugin: maker.  
	maker includeDirectories: '${crossDir}/plugins/FilePlugin'. 
	maker addPlatformSources: #( 'sqUnixDragDrop')

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureFT2Plugin: maker [ 

	"extra rules for FT2Plugin" 
	
	maker addExternalLibraries: #('freetype' ).
	
	"
	ft2build.h. says: 
	<prefix>/include/freetype2' must be in your current inclusion path "
	self flag:'tty'. "is this generic?"
	maker includeDirectories:  '/usr/include/freetype2'
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureFileCopyPlugin: maker [
	"extra rules for DropPlugin"

	maker addPlatformSources: #( 'sqUnixFileCopyPlugin')

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureFilePlugin: maker [
	"extra rules for FilePlugin"

	super configureFilePlugin: maker.  
	
	maker addPlatformSources: #( 'sqUnixFile')
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configureForBuildType: aSymbol [
	"Set my internal state appropriate for my build type".
	self configureNoBuildType.                "reset all internal flags"
	buildType:= aSymbol.                       "error checking was handled previously"
	self
		preferredIncludes;
		standardIncludes;
		configureFlags;     "  configure --without-npsqueak --with-src=stacksrc --with-plugins=src/plugins --disable-cogi --without-vm-display-fbdev  --x-libraries=/usr/lib --without-gl "
		compilerFlags;
		linkFlags;                         " LIBS=''-lpthread -luuid''"
		internalPlugins;
		externalPlugins.


]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureInternetConfigPlugin: maker [
	super configureInternetConfigPlugin: maker.
	maker addPlatformSources: #( 'sqUnixInternetConfiguration' )
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureJoystickTabletPlugin: maker [ 
	"extra rules for JoystickTabletPlugin"
	
	super configureJoystickTabletPlugin: maker.  
	maker addPlatformSources:
		#( 'sqUnixJoystickTablet' )

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureLocalePlugin: maker [ 
	"extra rules for LocalePlugin"

	super configureLocalePlugin:  maker.
	
	maker addPlatformSources: #( 'sqUnixLocale.c')
	
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureMIDIPlugin: maker [ 
	"extra rules for MIDIPlugin"

	super configureMIDIPlugin: maker.  

	"requires ALSA"

	maker addPlatformSources: #( 'sqUnixMIDI')
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureSecurityPlugin: maker [ 
	"extra rules for MIDIPlugin"

	super configureSecurityPlugin: maker.
	
	maker addPlatformSources: #( 'sqUnixSecurity')
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureSerialPlugin: maker [ 
	"extra rules for SerialPlugin"
	
	maker addPlatformSources: #( 'sqUnixSerial')
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureSocketPlugin: maker [ 
	"extra rules for SocketPlugin"
	
	maker addPlatformSources: #( 'sqUnixSocket')
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureSoundPlugin: maker [ 
	"extra rules for SoundPlugin"
	
	maker addPlatformSources: #( 'sqUnixSound').
	maker addExternalLibraries: #( 'asound' )
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureSqueakSSLPlugin: maker [ 
	"extra rules for SqueakSSLPlugin"
	
	maker addPlatformSources: #( 'sqUnixOpenSSL.c').
	
	maker addExternalLibraries: #('ssl' ).
	
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureUUIDPlugin: maker [ 
	"extra rules for UUIDPlugin"

	super configureUUIDPlugin: maker.    
	
	maker includeDirectories: '/usr/include/uuid'.
	
	maker addPlatformSources:
		#( 'sqUnixUUID.c')



]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureUnixOSProcessPlugin: maker [ 
	"extra rules for UnixOSProcessPlugin"

	maker includeDirectories: '${crossDir}/plugins/FilePlugin'.
	maker includeDirectories: '${crossDir}/plugins/SocketPlugin'.
	
	maker addDefinitions: '-DSQAIO_H=\"sqaio.h\"'

]

{ #category : #accessing }
SqueakUnixConfig >> executableType [
	^ ''

]

{ #category : #accessing }
SqueakUnixConfig >> externalModulesDir [
	"answer the location in VM bundle, where plugins and rest of dynamic libs will be copied,
	"
	^ '${outputDir}'
]

{ #category : #'source files' }
SqueakUnixConfig >> extraSources [	
	"platforms/unix/vm/sqUnixMain.c.o: In function `getVersionInfo': requires this"
	^ 'version.c'
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuild [
	"leave empty for all platforms but Mac OS"
	^ #()
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildAssert [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildAssertITimerHeartbeat [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildDebug [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildDebugITimerHeartbeat [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildITimerHeartbeat [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildMultiThreaded [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildMultiThreadedAssert [
	^ self frameworksBuild
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuildMultiThreadedDebug [
	^ self frameworksBuild
]

{ #category : #accessing }
SqueakUnixConfig >> platformName [
	^self unixPlatformName
]

{ #category : #'source files' }
SqueakUnixConfig >> platformSources [
	"files added from platform/unix/vm dir "
	^ #(
	'aio.c'
	'debug.c'
"	'dlfcn-dyld.c'
	'mac-alias.c' "
	'osExports.c'
	'sqUnixCharConv.c'
"	'sqUnixEvent.c' "
	'sqUnixExternalPrims.c'
	'sqUnixHeartbeat.c'
	'sqUnixMain.c'
	'sqUnixMemory.c'
	'sqUnixThreads.c'
	'sqUnixVMProfile.c'
	)
]

{ #category : #'squeak compatability' }
SqueakUnixConfig >> setupDirectories: gen [
	super setupDirectories: gen.
	gen set: #externalModulesDir toString: self externalModulesDir.
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuild [
	^ thirdpartyLibs ifNil: [ thirdpartyLibs := OrderedCollection new ].
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildAssert [
	^ self thirdpartyLibsBuild 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildAssertITimerHeartbeat [
	^ self thirdpartyLibsBuild 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildDebug [
	^ self thirdpartyLibsBuild 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildDebugITimerHeartbeat [
	^ self thirdpartyLibsBuild 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildITimerHeartbeat [
	^ self thirdpartyLibsBuild 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildMultiThreaded [
	^ self thirdpartyLibsBuild 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildMultiThreadedAssert [
	^ self thirdpartyLibsBuild 
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuildMultiThreadedDebug [
	^ self thirdpartyLibsBuild 
]
