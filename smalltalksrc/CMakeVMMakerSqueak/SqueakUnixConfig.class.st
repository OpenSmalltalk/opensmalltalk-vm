"
A SqueakUnixConfig is a top level configuration for *nix configuratons.
My immediate sub-classes are Abstract Base classes for specific *nix variants.
The sub-classes of my Abstract Base Classes are concrete configurations of the form
[Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf
I am not meant to be built.


HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp

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

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> cmakeIncludeModulesBuild [
	"include CMake Modules. on my system they are in /usr/local/share/cmake-3.0/Modules/"
	(enabledebugmessages)
		ifTrue:[	
	templates 
	addLast: ((CMakeMessage new) message: (self class name), '  cmakeIncludeModulesBuild: aMaker')
	].
	templates
		addLast: ((CMakeInclude new) file:'Utils.cmake');
  	    	addLast: ((CMakeInclude new) file:'Plugins.cmake');
		addLast: ((CMakeInclude new) file:'TestBigEndian');
		addLast: ((CMakeInclude new) file:'CheckIncludeFile');
		addLast: ((CMakeInclude new) file:'CheckLibraryExists');
		addLast: ((CMakeInclude new) file:'CheckTypeSize');
		addLast: ((CMakeInclude new) file:'CheckFunctionExists');
		addLast: ((CMakeInclude new) file:'CheckVariableExists');
		addLast: ((CMakeInclude new) file:'CheckStructHasMember');
		addLast: ((CMakeInclude new) file:'FindPkgConfig').



]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> cmakeIncludePathBuild [
	"
cmake --help-variable  CMAKE_INCLUDE_PATH 
 This is used when searching for include files e.g. using the FIND_PATH() command. If you have headers in non-standard locations, it may be useful to set this variable to this directory (e.g. /sw/include on Mac OS X). If you need several directories, separate them by the platform specific separators (e.g. ':' on UNIX) "
	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: (self class name), '  cmakeIncludePathBuild');
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_PATH=${CMAKE_INCLUDE_PATH}')
	].

"override me if necessary"
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> cmakeLibraryPathBuild [
	"
cmake --help-variable   CMAKE_LIBRARY_PATH 
 This is used when searching for libraries e.g. using the FIND_LIBRARY() command. If you have libraries in non-standard locations, it may be useful to set this variable to this directory (e.g. /sw/lib on Mac OS X). If you need several directories, separate them by the platform specific separators (e.g. '':'' on UNIX)  "	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: (self class name), '  cmakeLibraryPathBuild');
		addLast: ((CMakeMessage new) message: 'CMAKE_LIBRARY_PATH=${CMAKE_LIBRARY_PATH}')
	].

"override me if necessary"
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> cmakeModulePathBuild [
	"
cmake --help-variable   CMAKE_LIBRARY_PATH 
 This is used when searching for libraries e.g. using the FIND_LIBRARY() command. If you have libraries in non-standard locations, it may be useful to set this variable to this directory (e.g. /sw/lib on Mac OS X). If you need several directories, separate them by the platform specific separators (e.g. '':'' on UNIX)  "	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: (self class name), '  cmakeModulePathBuild');
		addLast: ((CMakeMessage new) message: 'CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}')
	].

"override me if necessary"
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> cmakePrefixPathBuild [
"
cmake --help-variable   CMAKE_PREFIX_PATH 
 (since CMake 2.6.0) This is used when searching for include files, binaries, or libraries using either the FIND_PACKAGE(), FIND_PATH(), FIND_PROGRAM(), or FIND_LIBRARY() commands. For each path in the CMAKE_PREFIX_PATH list, CMake will check ''PATH/include'' and ''PATH'' when FIND_PATH() is called, ''PATH/bin'' and ''PATH'' when FIND_PROGRAM() is called, and ''PATH/lib'' and ''PATH'' when FIND_LIBRARY() is called. See the documentation for FIND_PACKAGE(), FIND_LIBRARY(), FIND_PATH(), and FIND_PROGRAM() for more details."
	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: (self class name), '  cmakePrefixPathBuild');
		addLast: ((CMakeMessage new) message: 'CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}')
	].

"override me if necessary"


]

{ #category : #cmake }
SqueakUnixConfig >> cmakeWriteDirectoriesDotCmake: aMaker [
	|temp o|
	"We could put these inline, but other components include the directories.cmake file. So, we continue that convention"
	o := String new writeStream.
	temp := OrderedCollection new.
	temp
		addLast: ((CMakeSet new) variable: 'topDir' quotedValue: (self topDir fullName));
		addLast: ((CMakeSet new) variable: 'buildDir' quotedValue: (self buildDir ifNil: ['${topDir}/build'] ifNotNil: [self buildDir fullName]));
		addLast: ((CMakeSet new) variable: 'thirdpartyDir' quotedValue: '${buildDir}/thirdParty');
		addLast: ((CMakeSet new) variable: 'platformsDir' quotedValue: (self platformsDir));
		addLast: ((CMakeSet new) variable: 'srcDir' quotedValue: (self dirSource pathName));    "where the vm source directory lives"
		addLast: ((CMakeSet new) variable: 'cogDir' quotedValue: (self cogDir pathName));        "oscogvm/src  for historical reasons" 
		addLast: ((CMakeSet new) variable: 'srcPluginsDir' quotedValue: (pluginsDir ifNil: [ '${cogDir}/plugins' ]));  "plugin source directory only in oscogvm/src/plugins"
		addLast: ((CMakeSet new) variable: 'srcVMDir' quotedValue: '${srcDir}/vm');
		addLast: ((CMakeSet new) variable: 'platformName' quotedValue: (self platformName));
		addLast: ((CMakeSet new) variable: 'targetPlatform' quotedValue: '${platformsDir}/${platformName}');
		addLast: ((CMakeSet new) variable: 'crossDir' quotedValue: '${platformsDir}/Cross');
		addLast: ((CMakeSet new) variable: 'platformVMDir' quotedValue: '${targetPlatform}/vm}');
		addLast: ((CMakeSet new) variable: 'outputDir' quotedValue: (self outputDir fullName));
		addLast: ((CMakeSet new) variable: 'externalModulesDir' quotedValue: (self externalModulesDir)).
	temp do: [:each |  o nextPutAll: (each content); cr].
	self write: (o contents) toFile: 'directories.cmake'.
	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast:((CMakeMessage new) message: (self class name), ' setDirectories: aMaker' )
	].
	templates addLast: ((CMakeInclude new) file: 'directories.cmake').


]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configAioC [
	"holdover from Ian's work"
	|templates|
	templates:= OrderedCollection new.
	templates 
		addLast:((CMakeMessage new) message:'#aio.c');
		addLast: ((CMakeCheckIncludeFile new) include:'sys/time.h' variable:'HAVE_SYS_TIME_H');		
		addLast: ((CMakeCheckIncludeFile new) include:'sys/filio.h' variable:'HAVE_SYS_FILIO_H');		
		addLast:((CMakeCheckFunctionExists new) function: 'nanosleep' variable: 'HAVE_NANOSLEEP').
	^ templates
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configCheckIncludeFileTemplates [
	|templates|
	templates:= OrderedCollection new.
	templates 
		addLast: ((CMakeMessage new) message: 'CHECK_INCLUDE_FILES');
		addLast: ((CMakeCheckIncludeFile new) include:'unistd.h' variable:'HAVE_UNISTD_H');
		addLast: ((CMakeCheckIncludeFile new) include:'dirent.h' variable:'HAVE_DIRENT_H');
		addLast: ((CMakeCheckIncludeFile new) include:'pty.h' variable:'HAVE_PTY_H');
		addLast: ((CMakeCheckIncludeFile new) include:'stropts.h' variable:'HAVE_STROPTS_H').
	^ templates
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configCheckLibraryExistsTemplates [
	|templates|
	templates:= OrderedCollection new.
	templates 
		addLast: ((CMakeMessage new) message: 'CHECK_LIBRARY_EXISTS');
		addLast: ((CMakeCheckLibraryExists new) library: 'dl' function: 'dlopen' location:'' variable: 'HAVE_LIBDL' ).
	^ templates
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configExplicitImageWidth [
	|templates|
	templates:= OrderedCollection new.
	templates 
		addLast:((CMakeMessage new) message:'# explicit image width');
		addLast: ((CMakeCheckIncludeFile new) include:'unistd.h' variable:'HAVE_UNISTD_H').
	^ templates
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configFindPackageTemplates [
	|templates|
	templates:= OrderedCollection new.
	templates 
		addLast: ((CMakeMessage new) message: 'FIND_PACKAGE');
		addLast: ((CMakeFindPackage new) packagename: 'X11');
		addLast: (CMakeFindPackageOpenGL new).
	^ templates
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configIanPiumartasTemplates [
	|templates|
	self flag:'tty'. "fix this version stuff. get ostype from elsewhere.  does the without-gl flag need to be here?"
	templates:= OrderedCollection new.
	templates 
		addLast:((CMakeMessage new) message:'DebugTemplate');
		addLast: (CMakeDebug new);
		addLast:((CMakeMessage new) message:'Global Configs');
		addLast: ((CMakeSetConfigDefine new) variable: 'OS_TYPE' value:'\"${platformName}\"');  "defined in INCLUDE(directories.cmake) in CMakeLists.txt"
		addLast: ((CMakeVersion new) version: '1.2.3.4');
		addLast: ((CMakeSet new) variable:'without-gl' value: ''); 
		addLast: ((CMakeSetConfigDefine new) variable: 'NoDbgRegParms' value:''); 
		addLast: ((CMakeCompilerIsGNUCC new));
		addLast:((CMakeMessage new) message:'Tests');
		addLast:(CMakeTestBigEndian new);
		addLast:(CMakeCheckFunctionAtExitOnExit new);
		addAllLast: self configCheckIncludeFileTemplates;
		addAllLast: self configCheckLibraryExistsTemplates;
		addAllLast: self configFindPackageTemplates;
		addAllLast: self configSqMemoryAccess;
		addAllLast: self configPlatformSpecific;
		addAllLast: self configAioC;
		addAllLast: self configSqUnixCharConv;
		addAllLast: self configSqExternalPrims;
		addAllLast: self configSqUnixMainC;
		addAllLast: self configSqUnixMMemoryC;
		addAllLast: self configOLPC.
	^ templates
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configOLPC [
	"holdover from Ian's work"
	|templates|
	templates:= OrderedCollection new.
	templates 
		addLast:((CMakeMessage new) message:'# OLPC');
		addLast:((CMakeIfNotFlagSetConfigDefine new)  flag: 'without-SUGAR' variable:'SUGAR');
		addLast:((CMakeIfDefinedConfigDefine new)  variable:'SQ_VI_BYTES_PER_WORD').
	^ templates
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configPackageOptions [
	|templates|
	templates:= OrderedCollection new.
	templates 
		addLast:((CMakeMessage new) message:'# package options');
		addLast: ((CMakeFindPackage new) packagename: 'X11');
		addLast: ((CMakeFindPackage new) packagename: 'X11_GLX');
		addLast: ((CMakeFindPackage new) packagename: 'QUARTZ');
		addLast: ((CMakeFindPackage new) packagename: 'QUARTZ_CGL');
		addLast: ((CMakeFindPackage new) packagename: 'RFB').
	^ templates
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configPlatformSpecific [
	"holdover from Ian's work"
	|templates|
	templates:= OrderedCollection new.
	templates 
		addLast:((CMakeMessage new) message:'# sqPlatformSpecific.h');
		addLast:(CMakeCheckAlloca new).
	^ templates
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configSqExternalPrims [
	"holdover from Ian's work"
	|templates|
	templates:= OrderedCollection new.
	templates 
		addLast:((CMakeMessage new) message:'#sqUnixExternalPrims.c');
		addLast: ((CMakeCheckIncludeFile new) include:'dlfcn.h' variable:'HAVE_DLFCN_H' );		
		addLast: (CMakeCheckLibDL new);
		addLast:((CMakeCheckFunctionExists new) function:'_dyld_present' variable:'HAVE_DYLD');
		addLast:((CMakeCheckFunctionExists new) function:'snprintf' variable:'HAVE_SNPRINTF');
		addLast:((CMakeCheckFunctionExists new) function:'__snprintf' variable:'HAVE___SNPRINTF');
		addLast:((CMakeSetConfigDefine new) variable: 'VM_X11DIR' value:'\"${X11_LIBRARY_DIR}\"');
		addLast:((CMakeSetConfigDefine new) variable: 'VM_MODULE_PREFIX' value:'\"${CMAKE_SHARED_MODULE_PREFIX}\"');
		addLast:((CMakeSet new) variable:'CMAKE_SHARED_MODULE_PREFIX' value:'so.');
		addLast:((CMakeSet new) variable:'CMAKE_SHARED_MODULE_SUFFIX' value:'');
		addLast:((CMakeSetConfigDefine new) variable:'MODULE_PREFIX' value:'\"${CMAKE_SHARED_MODULE_PREFIX}\"');
		addLast:((CMakeSetConfigDefine new) variable:'MODULE_SUFFIX' value:'\"${CMAKE_SHARED_MODULE_SUFFIX}\"');
		addLast:((CMakeSetConfigDefine new) variable:'LIBRARY_PREFIX' value:'\"${CMAKE_SHARED_LIBRARY_PREFIX}\"');
		addLast:((CMakeSetConfigDefine new) variable:'LIBRARY_SUFFIX' value:'\"${CMAKE_SHARED_LIBRARY_SUFFIX}\"').

	^ templates
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configSqMemoryAccess [
	"holdover from Ian's work"
	|templates|
	templates:= OrderedCollection new.
	templates 
		addLast:((CMakeMessage new) message:'#sqMemoryAccess.h');
		addLast: ((CMakeCheckIncludeFile new) include:'interp.h' variable:'HAVE_INTERP_H' path: '-I',(self srcDir pathName));		
		addLast:(CMakeCheckTypeSize new);
		addLast:(CMakeCheckTryRunDoubleWordAlignmentOrder new).
	^ templates
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configSqUnixCharConv [
	"holdover from Ian's work"
	|templates|
	templates:= OrderedCollection new.
	templates 
		addLast:((CMakeMessage new) message:'#sqUnixCharConv.c');
		addLast: ((CMakeCheckIncludeFile new) include:'iconv.h' variable:'HAVE_ICONV_H' );		
		addLast: ((CMakeCheckIncludeFile new) include:'langinfo.h' variable:'HAVE_LANGINFO_H' );		
		addLast:(CMakeCheckTryCompileHaveLangInfoCodeset new);
		addLast:((CMakeCheckLibraryExists new) library:'iconv' function:'libiconv_open' location:'' variable:'HAVE_LIBICONV').
	^ templates
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configSqUnixMMemoryC [
	"holdover from Ian's work"
	|templates|
	templates:= OrderedCollection new.
	templates 
		addLast:((CMakeMessage new) message:'# sqUnixMain.c');
		addLast:((CMakeCheckFunctionExists new) function:'mmap' variable:'HAVE_MMAP').
	^ templates
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configSqUnixMainC [
	"holdover from Ian's work"
	|templates|
	templates:= OrderedCollection new.
	templates 
		addLast:((CMakeMessage new) message:'# sqUnixMain.c');
		addLast:((CMakeSetConfigDefine new) variable:'VM_BUILD_STRING' value:'"\"Unix built on \"__DATE__ \" \"__TIME__\" Compiler: \"__VERSION__"');
		addLast:((CMakeSetConfigDefine new) variable:'VM_LIBDIR' value:'"\"${prefix}/${plgdir}\""');
		addLast:((CMakeSetConfigDefine new) variable:'VM_HOST' value:'\"${VM_HOST}\"');
		addLast:((CMakeSetConfigDefine new) variable:'VM_HOST_CPU' value:'\"${VM_HOST_CPU}\"');
		addLast:((CMakeSetConfigDefine new) variable:'VM_HOST_VENDOR' value:' \"${VM_HOST_VENDOR}\"');
		addLast:((CMakeSetConfigDefine new) variable:'VM_HOST_OS' value:' \"${VM_HOST_OS}\"');
		addLast:((CMakeSetConfigDefine new) variable:'VM_VERSION' value: '\"${VM_VERSION}\"');
		addLast:((CMakeSetConfigDefine new) variable:'VM_VERSION_INFO' value: '\"${VM_VERSION}${versionsuffix}\"');
		addLast:((CMakeSetConfigDefine new) variable:'PLATFORM_SOURCE_VERSION' value: '\"${PLATFORM_SOURCE_VERSION}\"');
		addLast:((CMakeConfigDefine new) variable:'SQ_VERSION');
		addLast:((CMakeCheckFunctionExists new) function:'tzset' variable:'HAVE_TZSET');
		addLast:((CMakeCheckVariableExists new) var:'timezone' variable:'HAVE_TIMEZONE');
		addLast:((CMakeCheckStructHasMember new)struct: '"struct tm"' member: 'tm_gmtoff' header: 'time.h' variable: 'HAVE_TM_GMTOFF');
		addLast:((CMakeConfigDefine new) variable:'IMAGE_DUMP').
	^ templates
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configTemplates [
	|templates|
	self flag:'tty'. "fix this version stuff. get ostype from elsewhere.  does the without-gl flag need to be here?"
	templates:= OrderedCollection new.
	templates 
		addAllLast: self configUnDefineAll;
		addAllLast: self configExplicitImageWidth;
		addAllLast: self configPackageOptions;
		addLast:((CMakeMessage new) message:'/* libraries */');
		addLast:((CMakeMessage new) message:'/* header files */');
		addLast:((CMakeMessage new) message:'/* system calls/library functions */');
		addLast:((CMakeMessage new) message:'/* widths of primitive types */');
		addLast:((CMakeMessage new) message:'/* typedefs */');
		addLast:((CMakeMessage new) message:'/* architecture */');
		addLast:((CMakeMessage new) message:'/* damage containment */');
		addLast:((CMakeMessage new) message:'/* avoid dependencies on glibc2.3 */').
	^ templates
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configUnDefineAll [
	|templates|
	self flag: 'tty'. "I don't think this is needed, but I am playing it safe. It may become useful in automated builds. or unicorns may fly"
	templates:= OrderedCollection new.
	templates 
		addLast:((CMakeMessage new) message:'# undef explicit image width');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_INTERP_H');
		addLast:((CMakeMessage new) message:'# undef package options');
		addLast: ((CMakeConfigUnDefine new) variable: 'USE_X11');
		addLast: ((CMakeConfigUnDefine new) variable: 'USE_X11_GLX');
		addLast: ((CMakeConfigUnDefine new) variable: 'USE_QUARTZ');
		addLast: ((CMakeConfigUnDefine new) variable: 'USE_QUARTZ_CGL');
		addLast: ((CMakeConfigUnDefine new) variable: 'USE_RFB');

		addLast:((CMakeMessage new) message:'# undef libraries');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_LIBX11');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_LIBXEXT');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_LIBDL');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_DYLD');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_LIBFFI');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_ICONV');
		addLast: ((CMakeConfigUnDefine new) variable: 'USE_AUDIO_NONE');
		addLast: ((CMakeConfigUnDefine new) variable: 'USE_AUDIO_SUN');
		addLast: ((CMakeConfigUnDefine new) variable: 'USE_AUDIO_NAS');
		addLast: ((CMakeConfigUnDefine new) variable: 'USE_AUDIO_OSS');
		addLast: ((CMakeConfigUnDefine new) variable: 'USE_AUDIO_MACOSX');
		addLast: ((CMakeConfigUnDefine new) variable: 'OSS_DEVICE');

		addLast:((CMakeMessage new) message:'# undef header files');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_UNISTD_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'NEED_GETHOSTNAME_P');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_DIRENT_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_SYS_NDIR_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_SYS_DIR_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_NDIR_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_DLFCN_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_ICONV_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_SYS_TIME_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'TIME_WITH_SYS_TIME');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_SYS_FILIO_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_SYS_AUDIOIO_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_SUN_AUDIOIO_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_PTY_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_UTIL_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_LIBUTIL_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_STROPTS_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_GL_GL_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_OPENGL_GL_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'NEED_SUNOS_H');

		addLast:((CMakeMessage new) message:'# undef system calls/library functions ');
		addLast: ((CMakeConfigUnDefine new) variable: 'AT_EXIT');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_TZSET');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_OPENPTY');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_UNIX98_PTYS');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_SNPRINTF');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE___SNPRINTF');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_MMAP');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_DYLD');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_LANGINFO_CODESET');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_ALLOCA');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_ALLOCA_H');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_UNSETENV');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_NANOSLEEP');

		addLast:((CMakeMessage new) message:'# undef widths of primitive types');
		addLast: ((CMakeConfigUnDefine new) variable: 'SIZEOF_INT');
		addLast: ((CMakeConfigUnDefine new) variable: 'SIZEOF_LONG');
		addLast: ((CMakeConfigUnDefine new) variable: 'SIZEOF_LONG_LONG');
		addLast: ((CMakeConfigUnDefine new) variable: 'SIZEOF_VOID_P');

		addLast:((CMakeMessage new) message:'# undef structures');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_TM_GMTOFF');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_TIMEZONE');

		addLast:((CMakeMessage new) message:'# undef typedefs');
		addLast: ((CMakeConfigUnDefine new) variable: 'size_t');
		addLast: ((CMakeConfigUnDefine new) variable: 'socklen_t');
		addLast: ((CMakeConfigUnDefine new) variable: 'squeakInt64');

		addLast:((CMakeMessage new) message:'# undef architecture');
		addLast: ((CMakeConfigUnDefine new) variable: 'OS_TYPE');
		addLast: ((CMakeConfigUnDefine new) variable: 'VM_HOST');
		addLast: ((CMakeConfigUnDefine new) variable: 'VM_HOST_CPU');
		addLast: ((CMakeConfigUnDefine new) variable: 'VM_HOST_VENDOR');
		addLast: ((CMakeConfigUnDefine new) variable: 'VM_HOST_OS');
		addLast: ((CMakeConfigUnDefine new) variable: 'VM_BUILD_STRING');
		addLast: ((CMakeConfigUnDefine new) variable: 'WORDS_BIGENDIAN');
		addLast: ((CMakeConfigUnDefine new) variable: 'DOUBLE_WORD_ALIGNMENT');

		addLast:((CMakeMessage new) message:'# undef damage containment');
		addLast: ((CMakeConfigUnDefine new) variable: 'DARWIN');

		addLast:((CMakeMessage new) message:'# undef other configured variables');
		addLast: ((CMakeConfigUnDefine new) variable: 'SQ_VERSION');
		addLast: ((CMakeConfigUnDefine new) variable: 'VM_VERSION');
		addLast: ((CMakeConfigUnDefine new) variable: 'VM_MODULE_PREFIX');
		addLast: ((CMakeConfigUnDefine new) variable: 'VM_DLSYM_PREFIX');
		addLast: ((CMakeConfigUnDefine new) variable: 'VM_X11DIR');

		addLast:((CMakeMessage new) message:'# undef avoid dependencies on glibc2.3');
		addLast: ((CMakeConfigUnDefine new) variable: 'HAVE_FEATURES_H').
	^ templates
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configsqUnixCharConv [
	"holdover from Ian's work"
	|templates|
	templates:= OrderedCollection new.
	templates 
		addLast:((CMakeMessage new) message:'#sqUnixCharConv.c');
		addLast: ((CMakeCheckIncludeFile new) include:'iconv.h' variable:'HAVE_ICONV_H' );		
		addLast: ((CMakeCheckIncludeFile new) include:'langinfo.h' variable:'HAVE_LANGINFO_H' );		
		addLast:(CMakeCheckTryCompileHaveLangInfoCodesetTemplate new);
		addLast:((CMakeCheckLibraryExists new) library:'iconv' function:'libiconv_open' location:'' variable:'HAVE_LIBICONV').
	^ templates
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateAsynchFilePlugin: aMaker [
	aMaker templates addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqUnixAsynchFile.c'))


]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateB3DAcceleratorPlugin: aMaker [
	super configureByTemplateB3DAcceleratorPlugin: aMaker.  
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqUnixOpenGL.c'))

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateDropPlugin: aMaker [

	aMaker templates 
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/FilePlugin'));
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqUnixDragDrop.c'))


]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateFT2Plugin: aMaker [ 
	self flag: 'tty'. "See portability comment below"
	aMaker templates 
		addLast:((CMakeListAppend new) list:'LINKLIBS' elements: (OrderedCollection with: 'freetype'));
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '/usr/include/freetype2')). "<---THIS IS NOT PORTABLE.."

"On a refactoring pass, the 'cmake .' commmand should be able to dig this library up generically and the argument to with: can be a variable"

	
	
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateFileCopyPlugin: aMaker [

	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqUnixFileCopyPlugin.c'))



]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateFilePlugin: aMaker [
	super configureByTemplateFilePlugin: aMaker.
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqUnixFile.c'))

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateInternetConfigPlugin: aMaker [
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqUnixInternetConfiguration.c'))

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateJoystickTabletPlugin: aMaker [ 
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqUnixJoystickTablet.c'))

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateLocalePlugin: aMaker [ 
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqUnixLocale.c'))	

	
]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateMIDIPlugin: aMaker [ 
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqUnixMIDI.c'))

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateSecurityPlugin: aMaker [ 
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqUnixSecurity.c'))

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateSerialPlugin: aMaker [ 
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqUnixSerial.c'))
	

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateSocketPlugin: aMaker [ 
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqUnixSocket.c'))
	

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateSoundPlugin: aMaker [ 

	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqUnixSound.c'));
		addLast:((CMakeListAppend new) list:'LINKLIBS' elements: (OrderedCollection with: 'asound'))

	

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateSqueakSSLPlugin: aMaker [ 
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqUnixOpenSSL.c'));
		addLast:((CMakeListAppend new) list:'LINKLIBS' elements: (OrderedCollection with: 'ssl'))

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateUUIDPlugin: aMaker [ 
	self flag: 'tty'.
	aMaker templates 
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '/usr/include/uuid')); "<---THIS IS NOT PORTABLE.."
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginPlatform}/sqUnixUUID.c'))

"On a refactoring pass, the 'cmake .' commmand should be able to dig this library up generically and the argument to with: can be a variable"

	

]

{ #category : #'plugin extra rules' }
SqueakUnixConfig >> configureByTemplateUnixOSProcessPlugin: aMaker [ 
	super configureByTemplateUnixOSProcessPlugin: aMaker.
	aMaker templates 
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/SocketPlugin'));
		addLast:((CMakeAddDefinitions new) definitions: (OrderedCollection with:  '-DSQAIO_H=\"sqaio.h\"'))

	

]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> configureForBuildType: aSymbol [
	"Set my internal state appropriate for my build type".
	self configureNoBuildType.                "reset all internal flags"
	buildType:= aSymbol.                       "error checking was handled previously"

]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> contentForVmConfigCmake [
"I am a convenience method for developers who are modifying the templates for generateVMConfigCmake method.

Transcript clear.
Transcript show: ((Linux64x86w32BitSqueakCogV3Config new) configureForBuildType: #build) contentForVmConfigCmake
((Linux64x86w32BitSqueakCogV3Config new) configureForBuildType: #build) contentForVmConfigCmake   
"
	|template |
	template:= CMakeSqConfigH new.
	template templates: self configIanPiumartasTemplates.
"	template templates:  self configTemplates."
	^template contentFor: self
]

{ #category : #'source files' }
SqueakUnixConfig >> crossSources [ 
	^#(
			'sqHeapMap.c'
			'sqTicker.c'
			'sqExternalSemaphores.c'
			'sqNamedPrims.c'
			'sqVirtualMachine.c'
		)
]

{ #category : #'initialize-release' }
SqueakUnixConfig >> customizeVMDrivers [
	"
	SystemNavigation default browseMethodsWhoseNamesContain:'customizeVMDrivers'

	force platform level or lower customization of vm-display-X11 vm-sound-ALSA, etc. 
	The configurations can select what subset they want using something like this.

	|subset iwantonly|
	iwantonly :=	 #(#CMakeVMDisplayNull  #CMakeVMDisplayX11  #CMakeVMSoundALSA  #CMakeVMSoundNull ).
	subset := vmdrivers select: [:vmd | 0 < (iwantonly occurrencesOf: (vmd class name) asSymbol)]. 
	vmdrivers := subset.

	self 
		customizeCMakeVMDisplayNull;
		customizeCMakeVMDisplayX11;
		customizeCMakeVMSoundALSA;
		customizeCMakeVMSoundNull


"
	self flag:'tty'. "revisit this design strategy"
	self subclassResponsibility
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
SqueakUnixConfig >> extraVMSettingsBuild: aMaker [
	"add a generated version.c"
	(enabledebugmessages)
		ifTrue:[	templates 
		addLast:((CMakeMessage new) message: (self class name) , 'extraVMSettingsBuild: aMaker')
	] .
	templates
		addLast:((CMakeAddCustomCommandOutput new) 
						output:(OrderedCollection with: 'version.c')
						commandsandargs: (OrderedCollection with: 'COMMAND ${platformsDir}/unix/config/verstamp version.c gcc' )
						comment: 'Generating version.c').




]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> frameworksBuild [
	"leave empty for all platforms but Mac OS"
	^ #()
]

{ #category : #'source generation' }
SqueakUnixConfig >> generateByTemplate [
self flag:'tty: will need this in non-unix platforms'.
	self 
		generatePluginsList;                                        "informative list of plugins for end user"
		generateLicense;                                             "Squeak license"
		generateUtilsCmake;                                       "Ian's useful CMake macros. used extensivelly."
		generatePluginsCmake;                                   "Ian's CMake Plugins Processing"
		generateVmBuildCmake;                                  "Ian's CMake Build script"
		generateVmConfigCmake;                               "Ian's config.cmake file used to generate gnu config.h"
		generateVmConfigIn;                                       "Ian's code, not sure what it does yet"
		generateTestDoubleWordAlignmentC;             "Ian's platform tests used in configuration"
		generateTestDoubleWordOrderC;
		generateTestLanginfoCodesetC.
	^ CMakeVMGeneratorForSqueak generateByTemplate: self 
]

{ #category : #'cmake configuration' }
SqueakUnixConfig >> generateVmConfigCmake [
	|template |
	template:= CMakeSqConfigH new.
      template templates: self configIanPiumartasTemplates.
"	template templates:  self configTemplates."
	template generate: self
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

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> postBuildActionsBuild: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActionsBuild:'"
	(aMaker config enabledebugmessages)
		ifTrue:[	
	aMaker config templates 
		addLast: ((CMakeMessage new) message: (self class name), ' postBuildActionsBuild' )
	].
	aMaker config templates 
		addLast: ((CMakeMessage new) message: 'postBuildActionsBuild: aMaker' );
		addLast:((CMakeCommand new) command:'include' params:'config.cmake');                                                 "cmake --help-command include "
		addLast:((CMakeCommand new) command:'LIST' params:'REMOVE_DUPLICATES config_vars');                      "cmake --help-command LIST"
		addLast:((CMakeCommand new) command:'FILE' params:'WRITE ${CMAKE_BINARY_DIR}/config.h.in ""');          "cmake --help-command FILE"
		addLast:(CMakeAppendConfigHIn new);
		addLast:((CMakeCommand new) command:'CONFIGURE_FILE' params:'${CMAKE_BINARY_DIR}/config.h.in ${CMAKE_BINARY_DIR}/config.h');
		addLast:((CMakeCommand new) command:'GET_CMAKE_PROPERTY' params:'tmp VARIABLES');
		addLast:((CMakeCommand new) command:'LIST' params:'REMOVE_ITEM tmp tmp');
		addLast:((CMakeCommand new) command:'LIST' params:'SORT tmp');
		addLast:((CMakeCommand new) command:'FILE' params:'WRITE ${CMAKE_BINARY_DIR}/config.h.status ""');
		addLast:(CMakeAppendConfigStatus new).


]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> setGlobalOptionsAfterDetermineSystemBuild: aMaker [
	"	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystemBuild'"
	(enabledebugmessages)
		ifTrue:[	
	templates 
	addLast: ((CMakeMessage new) message: (self class name), '  setGlobalOptionsAfterDetermineSystemBuild: aMaker')
	].
	"templates addLast:((CMakeSet new) variable:'CMAKE_C_COMPILER' value: 'gcc')"

	
]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> standardIncludesBuild [
	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: (self class name), ' standardIncludesBuild' )
	].

	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_PATH =  ${CMAKE_INCLUDE_PATH}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_SYSTEM_INCLUDE_PATH =  ${CMAKE_SYSTEM_INCLUDE_PATH}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES = ${CMAKE_C_IMPLICIT_INCLUDE_DIRECTORIES}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES =  ${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_FIND_ROOT_PATH_MODE_INCLUDE =  ${CMAKE_FIND_ROOT_PATH_MODE_INCLUDE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_FIND_ROOT_PATH_MODE_INCLUDE =  ${CMAKE_INCLUDE_CURRENT_DIR}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_CURRENT_DIR_IN_INTERFACE =  ${CMAKE_INCLUDE_CURRENT_DIR_IN_INTERFACE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_DIRECTORIES_BEFORE =  ${CMAKE_INCLUDE_DIRECTORIES_BEFORE}' );
		addLast: ((CMakeMessage new) message: 'CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE =  ${CMAKE_INCLUDE_DIRECTORIES_PROJECT_BEFORE}' )
	].

]

{ #category : #'cmake buildType redirects' }
SqueakUnixConfig >> thirdpartyLibsBuild [
	^ thirdpartyLibs ifNil: [ thirdpartyLibs := OrderedCollection new ].
]

{ #category : #plugins }
SqueakUnixConfig >> vmDrivers [
"SystemNavigation default browseMethodsWhoseNamesContain: 'vmDrivers'
"
	^#(
'vm-display-Quartz' 
'vm-display-X11'  
'vm-display-custom'  
'vm-display-fbdev'  
'vm-display-null'  
'vm-sound-ALSA'  
'vm-sound-MacOSX'  
'vm-sound-NAS'  
'vm-sound-OSS'  
'vm-sound-Sun'  
'vm-sound-custom'
'vm-sound-null'
)

]
