"
A CPlatformConfigForSqueak acts as a compatability layer for Squeak and an Abstract Base Class for extended functionality required for the Squeak CMakeVMMaker use-case.

I make (very) heavy use of a specific design pattern for configuring myself and remaining compatible with pharo's CMakeVMMaker.
The entry point for that pattern is my method 'configureForBuildType: aSymbol' . Each method send in there detects my buildType and routes the send
to the approriate method for that buildType.

Subclasses of me 'must' configure themselves for each build type per that pattern. 
However this can be very easy by just returning the base configuration.

Tests are written to verify that this support infrastructure is in place.

I have two important methods.

excludeFromBuild and isAbstractBaseClass.

excludeFromBuild 
		is used to exclude a configuration from being built by a Builder.
		is used to exclude a configuration from Testing.

isAbstractBaseClass 
		is used by configurations that exclude themselves from being built by a Builder BUT need to be included in 		Testing.

										
excludeFromBuild  | isAbstractBaseClass  | should build  | should test
	T					    T                            NO                  YES
      T					    F                             NO                   NO
      F					    T                            YES                  YES
      F                                 F                            YES                  YES


The use-case is as follows.

An abstract base class contains a lot of functionality that must be implemented and tested for the system to work, but it is not meant to be compiled.

concrete classes of that AbstractBase class can exclude themselves from being built by builders and by doing so are not tested.
However, once a concrete configuration is enabled to be built, it must pass all tests.

Linux32x86Config is an example of an AbstractBase class that must pass all testing, but is not buildable.
Its subclass Linux32x86SqueakCogV3Config needs testing, but a developer can toggle 'exclude from build' to hide it from Builders or make it available to them.

Tests make the decision on what configurations to test. Here are some examples.
	(o excludeFromBuild not) & (configuration isAbstractBaseClass not)  this is a concrete [Lang][VM][MemoryManager][etc] configuration that will be built. No platform classes considered
	(o excludeFromBuild) & (configuration isAbstractBaseClass not)         This is a concrete [Lang][VM][MemoryManager][etc] configuration that will be NOT built.
	(o excludeFromBuild not) | (configuration isAbstractBaseClass)          concrete implementation may depend on its [OS][VMWordSize][Processor] AbstractBaseClass for platform level methods. 
																		   example: Linux32x86Config ccBuild has the '-m32' compiler flag that is common to all builds on that platform
	(o excludeFromBuild not) & (configuration isAbstractBaseClass)       Not allowed. [OS][VMWordSize][Processor] AbstractBaseClasses should not be built. This is a useful test in its own right.
	(o excludeFromBuild) & (configuration isAbstractBaseClass)             These are the AbstractBaseClasses. An AbstractBaseClass should always be excluded from a build


HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp
tty.
"
Class {
	#name : #CPlatformConfigForSqueak,
	#superclass : #CPlatformConfig,
	#instVars : [
		'buildType',
		'generateBuild',
		'generateBuildAssert',
		'generateBuildAssertITimerHeartbeat',
		'generateBuildDebug',
		'generateBuildDebugITimerHeartbeat',
		'generateBuildDebugMultiThreaded',
		'generateBuildIHeartbeatTimer',
		'generateBuildMultiThreaded',
		'generateBuildMultiThreadedAssert',
		'generateBuildMultiThreadedDebug',
		'templates',
		'enabledebugmessages',
		'vmplugins'
	],
	#classInstVars : [
		'isAbstractBaseClass'
	],
	#category : #CMakeVMMakerSqueak
}

{ #category : #'as yet unclassified' }
CPlatformConfigForSqueak class >> isAbstractBaseClass [
	^true

]

{ #category : #'as yet unclassified' }
CPlatformConfigForSqueak class >> licenseTemplate [
	^'Squeak {1} license information
==============================

About Squeak
-----------
Squeak is a modern, open source, full-featured implementation of the powerful Smalltalk programming language and environment. Squeak is highly-portable, running on almost any platform you could name and you can really truly write once run anywhere.  Squeak is the vehicle for a wide range of projects from multimedia applications and educational platforms to commercial web application development.

LIcense
Note: The current release of Squeak is a combination of source code originating from it''s origins at Apple which Apple agreed to license under the Apache license and more recent contributions licensed under the MIT license. The vast majority of the code is under the MIT license.
MIT License

Copyright (c) The individual, corporate, and institutional contributors who have collectively contributed elements to this software ("The Squeak Community"), 1996-2010 All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
Portions of Squeak are covered by the following license:
Apache License, Version 2.0

Copyright (c) Xerox Corp. 1981, 1982 All rights reserved. Copyright (c) Apple Computer, Inc. 1985-1996 All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.


About Cog
---------

Cog is a virtual machine designed for Smalltalk and other similar dynamic languages.  Cog builds on the
Squeak virtual machine adding a stack-to-register-mapping just-in-time compiler, aggressive in-line message
cacheing and effective optimization of Smalltalk?s first-class activation records.  Cog is the virtual machine
underlying Teleplace''s Croquet-based enterprise virtual collaboration spaces software, the fastest virtual
machine for Squeak, and for Gilad Bracha''s Newspeak modular language inspired by Beta and Smalltalk.  
Like the original Squeak VM, Cog is implemented and developed in Smalltalk, and translated into a lower-level
language to produce the production VM.  Being a Smalltalk program it is a delight to develop.  Cog is
available under the MIT open source license and is unencumbered for commercial deployment.

Cog''s performance relative to the existing Squeak interpreter varies, depending on the benchmark chosen.
As of early-2011, the Cog JIT uses strong inline cacheing techniques and stack-to-register mapping that
results in a register-based calling convention for low-arity methods.  Due to the complexity of the Squeak
object representation it has a limited set of primitives implemented in machine code that, for example,
exclude object allocation.  Performance of the early-2011 JIT for the nbody, binarytrees and chameneos
redux benchmarks from the computer language shootout is in the range of 4 to 6 times faster than the
interpreter.
'
]

{ #category : #'as yet unclassified' }
CPlatformConfigForSqueak class >> pluginsCMake [
	^'# Figure out which plugins to build and create a configuration for each.
# 
# Last edited: 2013-11-18 15:12:57 by piumarta on emilia
#
# Modified by tty to only include the macros. Hopefully, I can transform this to create the config.h for all the plugins on unix
#
#IF (EXISTS ${bld}/plugins.int)
#  FILE (STRINGS ${bld}/plugins.int plugins_int)
#ELSEIF (EXISTS ${config}/plugins.int)
#  FILE (STRINGS ${config}/plugins.int plugins_int)
#ELSEIF (EXISTS ${src}/plugins.int)
#  FILE (STRINGS ${src}/plugins.int plugins_int)
#ELSE (EXISTS ${src}/plugins.int)
#  MESSAGE (FATAL_ERROR "Cannot find plugins.int in ${bld}, ${config} or ${src}")
#ENDIF (EXISTS ${bld}/plugins.int)
#
#STRING (REGEX REPLACE ".*= *(.*)" "\\1" plugins_int ${plugins_int})
#STRING (REPLACE " " ";" plugins_int "${plugins_int}")
#
#IF (EXISTS ${bld}/plugins.ext)
#  FILE (STRINGS ${bld}/plugins.ext plugins_ext)
#ELSEIF (EXISTS ${config}/plugins.ext)
#  FILE (STRINGS ${config}/plugins.ext plugins_ext)
#ELSEIF (EXISTS ${src}/plugins.ext)
#  FILE (STRINGS ${src}/plugins.ext plugins_ext)
#ELSE (EXISTS ${src}/plugins.ext)
#  MESSAGE (FATAL_ERROR "Cannot find plugins.ext in ${bld}, ${config} or ${src}")
#ENDIF (EXISTS ${bld}/plugins.ext)
#
#STRING (REGEX REPLACE ".*= *(.*)" "\\1" plugins_ext ${plugins_ext})
#STRING (REPLACE " " ";" plugins_ext "${plugins_ext}")
#
#IF (EXISTS ${bld}/plugins.exc)
#  FILE (STRINGS ${bld}/plugins.exc plugins_exc)
#ELSEIF (EXISTS ${config}/plugins.exc)
#  FILE (STRINGS ${config}/plugins.exc plugins_exc)
#ELSEIF (EXISTS ${src}/plugins.exc)
#  FILE (STRINGS ${src}/plugins.exc plugins_exc)
#ENDIF (EXISTS ${bld}/plugins.exc)
#
#IF (DEFINED plugins_exc)
#  STRING (REGEX REPLACE ".*= *(.*)" "\\1" plugins_exc ${plugins_exc})
#  STRING (REPLACE " " ";" plugins_exc "${plugins_exc}")
#  FOREACH (plugin ${plugins_exc})
#    MESSAGE ("!! excluding plugin ${plugin}")
#    LIST (REMOVE_ITEM plugins_int ${plugin})
#    LIST (REMOVE_ITEM plugins_ext ${plugin})
#  ENDFOREACH (plugin)
#ENDIF (DEFINED plugins_exc)
#
#FILE (GLOB plugins_vm RELATIVE ${unix} ${unix}/vm-*)
#
## copy generated headers to ${bld} to eliminate ${src} from the include search path
#
#FILE_COPY (${bld}/interp.h ${src}/vm/interp.h)

MACRO (INTERNAL_PLUGIN plugin)
  SET (plugin_sources "")
  IF (DEFINED ${plugin}_sources)
    SET (plugin_sources ${${plugin}_sources})
  ELSE (DEFINED ${plugin}_sources)
    FOREACH (dir ${src}/plugins ${cross}/plugins ${unix}/plugins)
      SET (tmp "")
      AUX_SOURCE_DIRECTORY (${dir}/${plugin} tmp)
      STRING_APPEND (plugin_sources "${tmp}")
    ENDFOREACH (dir)
  ENDIF (DEFINED ${plugin}_sources)
  IF (DEFINED ${plugin}_extra_sources)
    STRING_APPEND (plugin_sources "${${plugin}_extra_sources}")
  ENDIF (DEFINED ${plugin}_extra_sources)
  FILE (WRITE ${bld}/${plugin}/CMakeLists.in "")
  FOREACH (dir ${unix}/plugins ${unix})
    FILE_APPEND (${bld}/${plugin}/CMakeLists.in ${dir}/${plugin}/build.cmake)
  ENDFOREACH (dir)
  FILE_APPEND (${bld}/${plugin}/CMakeLists.in ${config}/PluginInternal.cmake)
  CONFIGURE_FILE (${bld}/${plugin}/CMakeLists.in ${bld}/${plugin}/CMakeLists.txt @ONLY)
  ADD_SUBDIRECTORY (${bld}/${plugin} ${bld}/${plugin})
ENDMACRO (INTERNAL_PLUGIN)

MACRO (EXTERNAL_PLUGIN plugin)
  SET (plugin_sources)
  IF (DEFINED ${plugin}_sources)
    SET (plugin_sources ${${plugin}_sources})
  ELSE (DEFINED ${plugin}_sources)
    FOREACH (dir ${src}/plugins ${cross}/plugins ${unix}/plugins ${unix})
      SET (tmp "")
      AUX_SOURCE_DIRECTORY (${dir}/${plugin} tmp)
      STRING_APPEND (plugin_sources "${tmp}")
    ENDFOREACH (dir)
  ENDIF (DEFINED ${plugin}_sources)
  IF (DEFINED ${plugin}_extra_sources)
    STRING_APPEND (plugin_sources "${${plugin}_extra_sources}")
  ENDIF (DEFINED ${plugin}_extra_sources)
  FILE (WRITE ${bld}/${plugin}/CMakeLists.in "")
  FOREACH (dir ${unix}/plugins ${unix})
    FILE_APPEND (${bld}/${plugin}/CMakeLists.in ${dir}/${plugin}/build.cmake)
  ENDFOREACH (dir)
  FILE_APPEND (${bld}/${plugin}/CMakeLists.in ${config}/PluginExternal.cmake)
  CONFIGURE_FILE (${bld}/${plugin}/CMakeLists.in ${bld}/${plugin}/CMakeLists.txt @ONLY)
  ADD_SUBDIRECTORY (${bld}/${plugin} ${bld}/${plugin})
ENDMACRO (EXTERNAL_PLUGIN)

MACRO (PLUGIN_DISABLE)
  SET (plugin_disabled 1)
ENDMACRO (PLUGIN_DISABLE)

MACRO (PLUGIN_SOURCES)
  SET (${plugin}_sources ${ARGV})
ENDMACRO (PLUGIN_SOURCES)

MACRO (PLUGIN_DEFINITIONS)
  LIST_APPEND (${plugin}_definitions ${ARGV})
ENDMACRO (PLUGIN_DEFINITIONS)

MACRO (PLUGIN_INCLUDE_DIRECTORIES)
  LIST_APPEND (${plugin}_include_directories ${ARGV})
ENDMACRO (PLUGIN_INCLUDE_DIRECTORIES)

MACRO (PLUGIN_LINK_DIRECTORIES)
  LIST_APPEND (${plugin_target}_link_directories ${ARGV})
ENDMACRO (PLUGIN_LINK_DIRECTORIES)

MACRO (PLUGIN_LINK_LIBRARIES)
  LIST_APPEND (${plugin_target}_link_libraries ${ARGV})
ENDMACRO (PLUGIN_LINK_LIBRARIES)

MACRO (CONFIGURE_PLUGIN_LIST plugins_list)
  SET (plugins ${${plugins_list}})
  FOREACH (plugin ${plugins})
    FILE (MAKE_DIRECTORY ${bld}/${plugin})
    FILE (WRITE ${bld}/${plugin}/config.cmake "")
    FOREACH (dir ${unix}/plugins ${unix})
      FILE_APPEND (${bld}/${plugin}/config.cmake ${dir}/${plugin}/config.cmake)
    ENDFOREACH (dir)
    #MESSAGE ("-- plugin ${plugin}")
    IF (${plugins_list} STREQUAL "plugins_int")
      SET (plugin_target "vm")
      SET (${plugin}_source_dir "${src}/plugins/${plugin}")
    ELSE ()
      SET (plugin_target "${plugin}")
      SET (${plugin}_source_dir "${src}/plugins/${plugin}")
    ENDIF (${plugins_list} STREQUAL "plugins_int")
    SET (plugin_disabled)
    INCLUDE (${bld}/${plugin}/config.cmake)
    IF (without-${plugin})
      SET (plugin_disabled 1)
    ENDIF ()
    IF (DEFINED plugin_disabled)
      LIST (REMOVE_ITEM ${plugins_list} ${plugin})
      MESSAGE ("!! ${plugin} disabled")
      SET (${plugin}_disabled 1)
    ELSE (DEFINED plugin_disabled)
      IF (${plugins_list} STREQUAL "plugins_int")
        USE_LIBRARY (${plugin})
      ENDIF (${plugins_list} STREQUAL "plugins_int")
      SET (${plugin}_disabled)
    ENDIF (DEFINED plugin_disabled)
  ENDFOREACH (plugin)
ENDMACRO (CONFIGURE_PLUGIN_LIST)

MACRO (CONFIGURE_PLUGINS)
  CONFIGURE_PLUGIN_LIST (plugins_int)
  CONFIGURE_PLUGIN_LIST (plugins_ext)
  CONFIGURE_PLUGIN_LIST (plugins_vm)
ENDMACRO (CONFIGURE_PLUGINS)

MACRO (BUILD_PLUGINS)
  FOREACH (plugin ${plugins_int})
    INTERNAL_PLUGIN (${plugin})
  ENDFOREACH (plugin)
  FOREACH (plugin ${plugins_ext})
    EXTERNAL_PLUGIN (${plugin})
  ENDFOREACH (plugin)
  FOREACH (plugin ${plugins_vm})
    EXTERNAL_PLUGIN (${plugin})
  ENDFOREACH (plugin)
  # create sqNamedPrims.h containing a list of exports for all configured internal plugins
  SET (exports_h "${bld}/sqNamedPrims.h")
  FILE (WRITE ${exports_h} "/* Automatically generated by Plugins.cmake from plugins.int */\n")
  FILE (APPEND ${exports_h} "extern sqExport vm_exports[];\n")
  FILE (APPEND ${exports_h} "extern sqExport os_exports[];\n")
  FOREACH (plugin ${plugins_int})
    FILE (APPEND ${exports_h} "extern sqExport ")
    FILE (APPEND ${exports_h} ${plugin})
    FILE (APPEND ${exports_h} "_exports[];\n")
  ENDFOREACH (plugin)
  FILE (APPEND ${exports_h} "\n")
  FILE (APPEND ${exports_h} "sqExport *pluginExports[] = {\n")
  FILE (APPEND ${exports_h} "\tvm_exports,\n")
  FILE (APPEND ${exports_h} "\tos_exports,\n")
  FOREACH (plugin ${plugins_int})
    FILE (APPEND ${exports_h} "\t")
    FILE (APPEND ${exports_h} ${plugin})
    FILE (APPEND ${exports_h} "_exports,\n")
  ENDFOREACH (plugin)
  FILE (APPEND ${exports_h} "\tNULL\n")
  FILE (APPEND ${exports_h} "};\n")
ENDMACRO (BUILD_PLUGINS)

MACRO (PLUGIN_MESSAGE msg)
  MESSAGE (STATUS "${plugin}: ${msg}")
ENDMACRO (PLUGIN_MESSAGE)

MACRO (PLUGIN_FIND_INCLUDE VAR NAME)
  FIND_PATH (${VAR}_H ${NAME} ${${plugin_target}_include_directories} ${ARGN})
  IF (${VAR}_H)
    PLUGIN_MESSAGE ("${${VAR}_H}/${NAME}")
    SET (HAVE_${VAR}_H 1)
    PLUGIN_INCLUDE_DIRECTORIES (${${VAR}_H})
  ELSE ()
    PLUGIN_MESSAGE ("${NAME} not found")
  ENDIF ()
ENDMACRO ()

MACRO (PLUGIN_REQUIRE_INCLUDE VAR NAME)
  PLUGIN_FIND_INCLUDE(${VAR} ${NAME} ${ARGN})
  IF (NOT ${VAR}_H)
    PLUGIN_DISABLE ()
  ENDIF ()
ENDMACRO ()

MACRO (PLUGIN_FIND_LIBRARY VAR NAME)
  FIND_LIBRARY (LIB${VAR} ${NAME})
  IF (LIB${VAR})
    PLUGIN_MESSAGE ("${LIB${VAR}}")
    SET (HAVE_LIB${VAR} 1)
    PLUGIN_LINK_LIBRARIES (${LIB${VAR}})
  ELSE ()
    PLUGIN_MESSAGE ("lib${NAME} not found")
  ENDIF ()
ENDMACRO ()

MACRO (PLUGIN_REQUIRE_LIBRARY VAR NAME)
  PLUGIN_FIND_LIBRARY(${VAR} ${NAME})
  if (NOT LIB${VAR})
    PLUGIN_DISABLE ()
  ENDIF ()
ENDMACRO ()

MACRO (PLUGIN_FIND_PACKAGE VAR NAME)
  IF (PKG_CONFIG_FOUND)
    PKG_CHECK_MODULES (${VAR} ${NAME})
    IF (${VAR}_FOUND)
      PLUGIN_MESSAGE ("${NAME} found")
      SET (HAVE_${VAR} 1)
      PLUGIN_INCLUDE_DIRECTORIES (${${VAR}_INCLUDE_DIRS})
      PLUGIN_LINK_DIRECTORIES (${${VAR}_LIBRARY_DIRS})
      PLUGIN_LINK_LIBRARIES (${${VAR}_LIBRARIES})
    ENDIF ()
  ENDIF ()
ENDMACRO ()

MACRO (PLUGIN_REQUIRE_PACKAGE VAR NAME)
  PLUGIN_FIND_PACKAGE(${VAR} ${NAME})
  IF (NOT ${VAR}_FOUND)
    PLUGIN_DISABLE ()
  ENDIF ()
ENDMACRO ()

MACRO (EXPECT_UNDEFINED_SYMBOLS)
  IF (APPLE)
    SET (CMAKE_SHARED_MODULE_CREATE_C_FLAGS "${CMAKE_SHARED_MODULE_CREATE_C_FLAGS} -flat_namespace -undefined suppress")
    SET (CMAKE_SHARED_MODULE_CREATE_CXX_FLAGS "${CMAKE_SHARED_MODULE_CREATE_CXX_FLAGS} -flat_namespace -undefined suppress")
  ENDIF (APPLE)
ENDMACRO (EXPECT_UNDEFINED_SYMBOLS)
'
]

{ #category : #'as yet unclassified' }
CPlatformConfigForSqueak class >> pluginsTemplate [
	^'{4} {1} ships with this plugins already built:
		
Internal: 
=========
{2}

External: 
=========
{3}

'
]

{ #category : #'as yet unclassified' }
CPlatformConfigForSqueak class >> testDoubleWordAlignmentC [
	"used in config.cmake"
	^' 
int f(void *i)
{
  *(double *)i= *(double *)(i + 4);
  return *(char *)i;
}

int main()
{
  char b[12];
  b[0]=1; b[1]=2; b[2]=3; b[3]=4; b[4]=0; b[5]=0; b[6]=0; b[7]=0; b[8]=0; b[9]=0; b[10]=0; b[11]=0;
  return f(b);
}
'


]

{ #category : #'as yet unclassified' }
CPlatformConfigForSqueak class >> testDoubleWordOrderC [ 
	"used by config.cmake"
	^'
union { double d; int i[2]; } d;

int main(void)
{
  d.d= 1.0;
  return d.i[0] == 0;
}
'
]

{ #category : #'as yet unclassified' }
CPlatformConfigForSqueak class >> testLanginfoCodesetC [
	^'
#include <langinfo.h>

int main(int argc, char **argv)
{
  char *cs= nl_langinfo(CODESET);
  return 0;
}
'
]

{ #category : #'as yet unclassified' }
CPlatformConfigForSqueak class >> utilsCMake [
	^'
# Some random useful things to avoid repetition
# 
# Last edited: 2009-08-26 10:41:32 by piumarta on ubuntu.piumarta.com

MACRO (STRING_APPEND var str)
  IF (DEFINED ${var})
    SET (${var} "${${var}} ${str}")
  ELSE (DEFINED ${var})
    SET (${var} "${str}")
  ENDIF (DEFINED ${var})
ENDMACRO (STRING_APPEND)

MACRO (LIST_APPEND list)
  LIST (APPEND ${list} "${ARGN}")
  LIST (REMOVE_DUPLICATES ${list})
ENDMACRO (LIST_APPEND)

MACRO (FILE_APPEND to from)
  IF (EXISTS ${from})
    FILE (READ ${from} tmp)
    FILE (APPEND ${to} "${tmp}")
  ENDIF (EXISTS ${from})
ENDMACRO (FILE_APPEND)

MACRO (FILE_COPY to from)
  IF (EXISTS ${from})
    FILE (READ ${from} tmp)
    FILE (WRITE ${to} "${tmp}")
  ENDIF (EXISTS ${from})
ENDMACRO (FILE_COPY)


##added by tty. cut-n-paste from ian CMakeLists.txt
MACRO (USE_LIBRARY lib)
  LIST (APPEND squeak_libs "${lib}")
ENDMACRO (USE_LIBRARY)

MACRO (USE_FRAMEWORK fwk)
  USE_LIBRARY ("-framework ${fwk}")
ENDMACRO (USE_FRAMEWORK)

MACRO (CONFIG_DEFINE var)
  LIST (APPEND config_vars "${var}")
ENDMACRO (CONFIG_DEFINE var)

MACRO (CONFIG_UNDEFINE var)
  LIST (REMOVE_ITEM config_vars "${var}")
ENDMACRO (CONFIG_UNDEFINE var)



##End tty additions


'
]

{ #category : #'as yet unclassified' }
CPlatformConfigForSqueak class >> vmBuildCmake [
	self flag: 'tty'. "I probably do not want this as this is what we currently do in Squeak. Ian appears to have farmed it out to its own file"
	^'
LINK_DIRECTORIES (${vm_link_directories})

ADD_EXECUTABLE (squeakvm${scriptsuffix}
  ${bld}/${interp}.c
  ${unix}/vm/aio.c
  ${unix}/vm/debug.c
  ${unix}/vm/osExports.c
  ${unix}/vm/sqUnixCharConv.c
  ${unix}/vm/sqUnixExternalPrims.c
  ${unix}/vm/sqUnixMain.c
  ${unix}/vm/sqUnixMemory.c
  ${cross}/vm/sqNamedPrims.c
  ${cross}/vm/sqVirtualMachine.c
  ${bld}/version.c
)

ADD_CUSTOM_COMMAND (
  OUTPUT  version.c
  COMMAND ${config}/verstamp ${bld}/version.c ${CMAKE_C_COMPILER}
)

ADD_CUSTOM_COMMAND (
  DEPENDS ${src}/vm/interp.c
  OUTPUT  ${bld}/interp.c
  COMMAND tr ''\\015'' ''\\012'' < ${src}/vm/interp.c > ${bld}/interp.c
)

ADD_CUSTOM_COMMAND (
  DEPENDS ${bld}/interp.c
  OUTPUT  ${bld}/gnu-interp.c
  COMMAND ${config}/gnuify ${config}/gnuify.awk ${bld}/interp.c ${bld}/gnu-interp.c
)

INCLUDE_DIRECTORIES (
  ${bld}
# ${src}/vm # files are now copied/generated in ${bld}
  ${unix}/vm
  ${cross}/vm
  ${unix}/plugins/B3DAcceleratorPlugin	# for sqUnixOpenGL.h
  ${X11_INCLUDE_DIR}
  ${OPENGL_INCLUDE_DIR}
  ${vm_include_directories}
)

SET_TARGET_PROPERTIES (squeakvm${scriptsuffix} PROPERTIES LINK_FLAGS "${CMAKE_EXE_EXPORTS_C_FLAG}")

TARGET_LINK_LIBRARIES (squeakvm${scriptsuffix} m ${squeak_libs} ${vm_link_libraries})

INSTALL (PROGRAMS ${bld}/squeakvm${scriptsuffix} DESTINATION ${plgdir})

IF (vm-sound-OSS_disabled)
  SET (useoss "false")
ELSE ()
  SET (useoss "true")
ENDIF ()

CONFIGURE_FILE (${config}/config.in ${bld}/config @ONLY)

# launcher scripts

ADD_CUSTOM_TARGET (squeak
  DEPENDS ${config}/squeak.in
  COMMAND sh ${bld}/config ${config}/squeak.in ${bld}/squeak
  COMMAND chmod +x ${bld}/squeak
)

INSTALL (PROGRAMS ${bld}/squeak DESTINATION bin)

ADD_CUSTOM_TARGET (squeak.sh
  DEPENDS ${config}/squeak.sh.in
  COMMAND sh ${bld}/config ${config}/squeak.sh.in ${bld}/squeak.sh
  COMMAND chmod +x ${bld}/squeak.sh
)

INSTALL (PROGRAMS ${bld}/squeak.sh DESTINATION bin)

ADD_EXECUTABLE (ckformat
  ${src}/ckformat.c
)

INSTALL (PROGRAMS ${bld}/ckformat DESTINATION ${plgdir})

ADD_DEPENDENCIES (squeakvm${scriptsuffix} squeak squeak.sh ckformat)

# manual page

ADD_CUSTOM_TARGET (squeak.1
  DEPENDS ${unix}/doc/squeak.1
  COMMAND sh ${bld}/config ${unix}/doc/squeak.1 ${bld}/squeak.1
)
ADD_DEPENDENCIES (squeakvm${scriptsuffix} squeak.1)
INSTALL (FILES ${bld}/squeak.1 DESTINATION share/man/man1)
'
]

{ #category : #'as yet unclassified' }
CPlatformConfigForSqueak class >> vmConfigCmake [
	"see svn co http://squeakvm.org/svn/squeak/trunk/platforms/unix/vm/config.cmake for original.
	my subclasses have custom version of that script.
	 "
	self subclassResponsibility.

]

{ #category : #'as yet unclassified' }
CPlatformConfigForSqueak class >> vmConfigIn [
	"used in build.cmake"
	^'#!/bin/sh

# echo "Configuring `basename $1` -> `basename $2`" >&2

sed "
s%\[version\]%@version@%g
s%\[major\]%@major@%g
s%\[minor\]%@minor@%g
s%\[patch\]%@patch@%g
s%\[bindir\]%@prefix@/@bindir@%g
s%\[imgdir\]%@prefix@/@imgdir@%g
s%\[plgdir\]%@prefix@/@plgdir@%g
s%\[mandir\]%@prefix@/@mandir@%g
s%\[docdir\]%@prefix@/@docdir@%g
s%\[useoss\]%@useoss@%g
" < $1 > $2'
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> addDriver: name sources: aSources generator: cmakeGen externalLibs: extLibs [

	| cfg srcs |
	
	srcs := aSources inject: '' into: [:res :each | res , ' "', each, '"' ].
	cfg := cmakeGen
		captureOutputDuring: [
			cmakeGen printHeader;
			project: name;
			include: '../directories.cmake';
		
			message: 'Adding module: ', name;
			
			addDefinitions:  self compilerFlags;
			addDefinitions: '-fPIC -DPIC';
			set: #sources to: srcs;
			cmd: 'add_library' params: name, ' SHARED ${sources}'; 
			includeDirectories: '${crossDir}/plugins/FilePlugin';
			includeDirectories: '${targetPlatform}/plugins/B3DAcceleratorPlugin';
			includeDirectories: '${crossDir}/plugins/B3DAcceleratorPlugin';
			set: 'LIBRARY_OUTPUT_PATH' toString: self outputDir fullName;
			addExternalLibraries: extLibs;
			cmd: 'target_link_libraries' params: name , ' ${LINKLIBS}';
			cmd: 'set_target_properties' params: name , ' PROPERTIES PREFIX "" SUFFIX "" 
			LINK_FLAGS -m32' 
	].
	
	(self buildDir / name) assureExistence.
	self write: cfg toFile: name , '/', cmakeGen outputFileName.
	cmakeGen addSubdirectory:  name.
	
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMDrivers: aMaker [
	"CMakeVMMaker compat"
	self deprecated:'CMakeVMMaker holdover from pharo. use addVMPlugins: aMaker'.
	^self addVMPlugins: aMaker

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMPlugins: aMaker [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self addVMPluginsBuild: aMaker];
		at: #buildAssert  put: [self addVMPluginsBuildAssert: aMaker];
		at: #buildAssertITimerHeartbeat  put: [self addVMPluginsBuildAssertITimerHeartbeat: aMaker];
            at:#buildDebug  put: [self addVMPluginsBuildDebug: aMaker];   
		at: #buildDebugITimerHeartbeat  put: [self addVMPluginsBuildDebugITimerHeartbeat: aMaker ];
		at: #buildITimerHeartbeat  put: [self addVMPluginsBuildITimerHeartbeat: aMaker];
		at: #buildMultiThreaded  put: [self addVMPluginsBuildMultiThreaded: aMaker ];
		at: #buildMultiThreadedAssert  put: [self addVMPluginsBuildMultiThreadedAssert: aMaker];
		at: #buildMultiThreadedDebug   put: [self addVMPluginsBuildMultiThreadedDebug: aMaker ];
		at: #buildNone put:[self addVMPluginsNoBuildType:  aMaker].
	^(d at: buildType) value

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMPluginsBuild: aMaker [
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMPluginsBuildAssert: aMaker [
	"override if you need custom vm-plugins for this build type"
	^self addVMPluginsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMPluginsBuildAssertITimerHeartbeat: aMaker [
	"override if you need custom vm-plugins for this build type"
	^self addVMPluginsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMPluginsBuildDebug: aMaker [
	"override if you need custom vm-plugins for this build type"
	^self addVMPluginsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMPluginsBuildDebugITimerHeartbeat: aMaker [
	"override if you need custom vm-plugins for this build type"
	^self addVMPluginsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMPluginsBuildITimerHeartbeat: aMaker [
	"override if you need custom vm-plugins for this build type"
	^self addVMPluginsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMPluginsBuildMultiThreaded: aMaker [
	"override if you need custom vm-plugins for this build type"
	^self addVMPluginsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMPluginsBuildMultiThreadedAssert: aMaker [
	"override if you need custom vm-plugins for this build type"
	^self addVMPluginsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMPluginsBuildMultiThreadedDebug: aMaker [
	"override if you need custom vm-plugins for this build type"
	^self addVMPluginsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> addVMPluginsNoBuildType: aMaker [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> androidPlatformName [
	^'android'
]

{ #category : #cmake }
CPlatformConfigForSqueak >> availableBuildTypes [
	self subclassResponsibility.

	" ^SqueakCMakeVMMakerAbstractBuilder  default  noBuildTypes
	  ^(SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes
			copyWithoutAll: #( #assertWithHeartbeatTimer #debugWithHeartbeatTimer debugMultiThreadedFFI.....etc))   
	"
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> buildDir [
	^ buildDir ifNil: [ buildDir := ( self topDir / self buildDirName) assureExistence].
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> buildDirName [
	buildType isNil
		ifTrue:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, 'build']
		ifFalse:[^self dirBuildPlatform, FileDirectory slash, self dirBuildLanguageVMMM, FileDirectory slash, buildType asString]
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> buildScript [
	"see standardVM/platforms/unix/cmake/configure"
	^ '#!/usr/bin/env bash
export CC=gcc
export CXX=g++
cmake .
make'

"  cmake '${unix}'' -DVM_HOST=''${host}'' -DVM_VERSION=''${VM_VERSION}'' -DPLATFORM_SOURCE_VERSION=''${PLATFORM_SOURCE_VERSION}'' -DSRC=''${src}'' -DOPT--CMAKE_C_FLAGS=''${cflags}'' ${args}
"
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> buildType: aSymbol [
	buildType:= aSymbol
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeAddDefinitions [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self cmakeAddDefinitionsBuild];
		at: #buildAssert  put: [self cmakeAddDefinitionsBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self cmakeAddDefinitionsBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self cmakeAddDefinitionsBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self cmakeAddDefinitionsBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self cmakeAddDefinitionsBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self cmakeAddDefinitionsBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self cmakeAddDefinitionsBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self cmakeAddDefinitionsBuildMultiThreadedDebug ];
		at: #buildNone put:[self cmakeAddDefinitionsNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeAddDefinitionsBuild [
	 ""
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeAddDefinitionsBuildAssert [
	 "override default for custom buildType. "
	^self cmakeAddDefinitionsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeAddDefinitionsBuildAssertITimerHeartbeat [
	 "override default for custom buildType. "
	^self cmakeAddDefinitionsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeAddDefinitionsBuildDebug [
	 "override default for custom buildType. "
	^self cmakeAddDefinitionsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeAddDefinitionsBuildDebugITimerHeartbeat [
	 "override default for custom buildType. "
	^self cmakeAddDefinitionsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeAddDefinitionsBuildITimerHeartbeat [
	 "override default for custom buildType. "
	^self cmakeAddDefinitionsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeAddDefinitionsBuildMultiThreaded [
	 "override default for custom buildType. "
	^self cmakeAddDefinitionsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeAddDefinitionsBuildMultiThreadedAssert [
	 "override default for custom buildType. "
	^self cmakeAddDefinitionsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeAddDefinitionsBuildMultiThreadedDebug [
	 "override default for custom buildType. "
	^self cmakeAddDefinitionsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeAddDefinitionsNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #cmake }
CPlatformConfigForSqueak >> cmakeAddExecutableNameOptionSource: aMaker [
	(enabledebugmessages)
		ifTrue:[	templates 
		addLast:((CMakeMessage new) message: (self class name) , 'cmakeAddExecutableNameOptionSource: aMaker')
	].
	templates
		addLast:((CMakeAddExecutableNameOptionSource new)
			executableName: (self executableName)
			optionalproperty: (self executableType)
			sources: (OrderedCollection with: aMaker sources)).

	
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeCFlags [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self cmakeCFlagsBuild];
		at: #buildAssert  put: [self cmakeCFlagsBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self cmakeCFlagsBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self cmakeCFlagsPathBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self cmakeCFlagsBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self cmakeCFlagsBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self cmakeCFlagsBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self cmakeCFlagsBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self cmakeCFlagsBuildMultiThreadedDebug ];
		at: #buildNone put:[self cmakeCFlagsNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeCFlagsBuild [
"
convenience method for customizing CMAKE_C_FLAGS CMAKE_C_FLAGS_RELEASE CMAKE_C_FLAGS_DEBUG  variables based on #buildType.
 
cmake --help-variable   CMAKE_C_FLAGS  
cmake --help-variable   CMAKE_C_FLAGS_DEBUG 
cmake --help-variable   CMAKE_C_FLAGS_RELEASE

cmake --help-variable   CMAKE_CXX_FLAGS  
cmake --help-variable   CMAKE_CXX_FLAGS_DEBUG 
cmake --help-variable   CMAKE_CXX_FLAGS_RELEASE

NOTE: be careful not to clobber existing flags unless you intend to.
You can avoid that with this form:  set(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS}  -Wall -m32) which is created via cmake templates with
	templates
		addLast:((CMakeSet new) variable:'CMAKE_CXX_FLAGS' value: '${CMAKE_CXX_FLAGS}  -Wall -m32');




SystemNavigation default browseMethodsWhoseNamesContain: 'cmakeCFlagsBuild'
"
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeCFlagsBuildAssert [
	"convenience method for customizing CMAKE_C_FLAGS CMAKE_C_FLAGS_RELEASE CMAKE_C_FLAGS_DEBUG  variables based on #buildType."
	^self cmakeCFlagsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeCFlagsBuildAssertITimerHeartbeat [
	"convenience method for customizing CMAKE_C_FLAGS CMAKE_C_FLAGS_RELEASE CMAKE_C_FLAGS_DEBUG  variables based on #buildType."
	^self cmakeCFlagsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeCFlagsBuildDebugITimerHeartbeat [
	"convenience method for customizing CMAKE_C_FLAGS CMAKE_C_FLAGS_RELEASE CMAKE_C_FLAGS_DEBUG  variables based on #buildType."
	^self cmakeCFlagsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeCFlagsBuildITimerHeartbeat [
	"convenience method for customizing CMAKE_C_FLAGS CMAKE_C_FLAGS_RELEASE CMAKE_C_FLAGS_DEBUG  variables based on #buildType."
	^self cmakeCFlagsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeCFlagsBuildMultiThreaded [
	"convenience method for customizing CMAKE_C_FLAGS CMAKE_C_FLAGS_RELEASE CMAKE_C_FLAGS_DEBUG  variables based on #buildType."
	^self cmakeCFlagsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeCFlagsBuildMultiThreadedAssert [
	"convenience method for customizing CMAKE_C_FLAGS CMAKE_C_FLAGS_RELEASE CMAKE_C_FLAGS_DEBUG  variables based on #buildType."
	^self cmakeCFlagsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeCFlagsBuildMultiThreadedDebug [
	"convenience method for customizing CMAKE_C_FLAGS CMAKE_C_FLAGS_RELEASE CMAKE_C_FLAGS_DEBUG  variables based on #buildType."
	^self cmakeCFlagsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeCFlagsNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeCFlagsPathBuildDebug [
	"convenience method for customizing CMAKE_C_FLAGS CMAKE_C_FLAGS_RELEASE CMAKE_C_FLAGS_DEBUG  variables based on #buildType."
	^self cmakeCFlagsBuild
]

{ #category : #cmake }
CPlatformConfigForSqueak >> cmakeIncludeDirectories: aMaker [
	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: (self class name), ' includeDirs: aMaker' )
	].
	templates
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: (aMaker includeDirs))).

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludeModules [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self cmakeIncludeModulesBuild];
		at: #buildAssert  put: [self cmakeIncludeModulesBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self cmakeIncludeModulesBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self cmakeIncludeModulesBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self cmakeIncludeModulesBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self cmakeIncludeModulesBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self cmakeIncludeModulesMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self cmakeIncludeModulesBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self cmakeIncludeModulesBuildMultiThreadedDebug ];
		at: #buildNone put:[self cmakeIncludeModulesNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludeModulesBuild [
"cmake Modules to include"
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludeModulesBuildAssert [
	"convenience method for including different CMake Modules for different buildType default #build "
	^self cmakeIncludeModulesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludeModulesBuildAssertITimerHeartbeat [
	"convenience method for including different CMake Modules for different buildType default #build "
	^self cmakeIncludeModulesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludeModulesBuildDebug [
	"convenience method for including different CMake Modules for different buildType default #build "
	^self cmakeIncludeModulesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludeModulesBuildDebugITimerHeartbeat [
	"convenience method for including different CMake Modules for different buildType default #build "
	^self cmakeIncludeModulesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludeModulesBuildITimerHeartbeat [
	"convenience method for including different CMake Modules for different buildType default #build "
	^self cmakeIncludeModulesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludeModulesBuildMultiThreadedAssert [
	"convenience method for including different CMake Modules for different buildType default #build "
	^self cmakeIncludeModulesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludeModulesBuildMultiThreadedDebug [
	"convenience method for including different CMake Modules for different buildType default #build "
	^self cmakeIncludeModulesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludeModulesMultiThreaded [
	"convenience method for including different CMake Modules for different buildType default #build "
	^self cmakeIncludeModulesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludeModulesNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludePath [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self cmakeIncludePathBuild];
		at: #buildAssert  put: [self cmakeIncludePathBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self cmakeIncludePathBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self cmakeIncludePathBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self cmakeIncludePathBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self cmakeIncludePathBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self cmakeIncludePathBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self cmakeIncludePathBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self cmakeIncludePathBuildMultiThreadedDebug ];
		at: #buildNone put:[self cmakeIncludePathNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludePathBuild [
	"
cmake --help-variable  CMAKE_INCLUDE_PATH 
 This is used when searching for include files e.g. using the FIND_PATH() command. If you have headers in non-standard locations, it may be useful to set this variable to this directory (e.g. /sw/include on Mac OS X). If you need several directories, separate them by the platform specific separators (e.g. ':' on UNIX) "
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludePathBuildAssert [
	"convenience method for cusomizing CMAKE_INCLUDE_PATH for different buildType "
	^self cmakeIncludePathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludePathBuildAssertITimerHeartbeat [
	"convenience method for cusomizing CMAKE_INCLUDE_PATH for different buildType "
	^self cmakeIncludePathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludePathBuildDebug [
	"convenience method for cusomizing CMAKE_INCLUDE_PATH for different buildType "
	^self cmakeIncludePathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludePathBuildDebugITimerHeartbeat [
	"convenience method for cusomizing CMAKE_INCLUDE_PATH for different buildType "
	^self cmakeIncludePathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludePathBuildITimerHeartbeat [
	"convenience method for cusomizing CMAKE_INCLUDE_PATH for different buildType "
	^self cmakeIncludePathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludePathBuildMultiThreaded [
	"convenience method for cusomizing CMAKE_INCLUDE_PATH for different buildType "
	^self cmakeIncludePathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludePathBuildMultiThreadedAssert [
	"convenience method for cusomizing CMAKE_INCLUDE_PATH for different buildType "
	^self cmakeIncludePathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludePathBuildMultiThreadedDebug [
	"convenience method for cusomizing CMAKE_INCLUDE_PATH for different buildType "
	^self cmakeIncludePathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeIncludePathNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeLibraryPath [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self cmakeLibraryPathBuild];
		at: #buildAssert  put: [self cmakeLibraryPathBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self cmakeLibraryPathBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self cmakeLibraryPathBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self cmakeLibraryPathBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self cmakeLibraryPathBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self cmakeLibraryPathBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self cmakeLibraryPathBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self cmakeLibraryPathBuildMultiThreadedDebug ];
		at: #buildNone put:[self cmakeLibraryPathNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeLibraryPathBuild [
	"
cmake --help-variable   CMAKE_LIBRARY_PATH 
 This is used when searching for libraries e.g. using the FIND_LIBRARY() command. If you have libraries in non-standard locations, it may be useful to set this variable to this directory (e.g. /sw/lib on Mac OS X). If you need several directories, separate them by the platform specific separators (e.g. '':'' on UNIX)  "
	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeLibraryPathBuildAssert [
	"convenience method for cusomizing CMAKE_LIBRARY_PATH for different buildType "
	^self cmakeLibraryPathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeLibraryPathBuildAssertITimerHeartbeat [
	"convenience method for cusomizing CMAKE_LIBRARY_PATH for different buildType "
	^self cmakeLibraryPathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeLibraryPathBuildDebug [
	"convenience method for cusomizing CMAKE_LIBRARY_PATH for different buildType "
	^self cmakeLibraryPathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeLibraryPathBuildDebugITimerHeartbeat [
	"convenience method for cusomizing CMAKE_LIBRARY_PATH for different buildType "
	^self cmakeLibraryPathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeLibraryPathBuildITimerHeartbeat [
	"convenience method for cusomizing CMAKE_LIBRARY_PATH for different buildType "
	^self cmakeLibraryPathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeLibraryPathBuildMultiThreaded [
	"convenience method for cusomizing CMAKE_LIBRARY_PATH for different buildType "
	^self cmakeLibraryPathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeLibraryPathBuildMultiThreadedAssert [
	"convenience method for cusomizing CMAKE_LIBRARY_PATH for different buildType "
	^self cmakeLibraryPathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeLibraryPathBuildMultiThreadedDebug [
	"convenience method for cusomizing CMAKE_LIBRARY_PATH for different buildType "
	^self cmakeLibraryPathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeLibraryPathNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #cmake }
CPlatformConfigForSqueak >> cmakeListAppend: listString elements: anOrderedCollection [
	(enabledebugmessages)
		ifTrue:[	
	templates 
		addLast: ((CMakeMessage new) message: (self class name), ' cmakeListAppend: listString elements: eString' )
	].
	templates
		addLast: ((CMakeListAppend new) list: listString elements: anOrderedCollection).


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakePrefixPath [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self cmakePrefixPathBuild];
		at: #buildAssert  put: [self cmakePrefixPathBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self cmakePrefixPathBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self cmakePrefixPathBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self cmakePrefixPathBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self cmakePrefixPathBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self cmakePrefixPathBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self cmakePrefixPathBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self cmakePrefixPathBuildMultiThreadedDebug ];
		at: #buildNone put:[self cmakePrefixPathNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakePrefixPathBuild [
"
cmake --help-variable   CMAKE_PREFIX_PATH 
 (since CMake 2.6.0) This is used when searching for include files, binaries, or libraries using either the FIND_PACKAGE(), FIND_PATH(), FIND_PROGRAM(), or FIND_LIBRARY() commands. For each path in the CMAKE_PREFIX_PATH list, CMake will check ''PATH/include'' and ''PATH'' when FIND_PATH() is called, ''PATH/bin'' and ''PATH'' when FIND_PROGRAM() is called, and ''PATH/lib'' and ''PATH'' when FIND_LIBRARY() is called. See the documentation for FIND_PACKAGE(), FIND_LIBRARY(), FIND_PATH(), and FIND_PROGRAM() for more details."

	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakePrefixPathBuildAssert [
	"convenience method for cusomizing CMAKE_PREFIX_PATH for different buildType "
	^self cmakePrefixPathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakePrefixPathBuildAssertITimerHeartbeat [
	"convenience method for cusomizing CMAKE_PREFIX_PATH for different buildType "
	^self cmakePrefixPathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakePrefixPathBuildDebug [
	"convenience method for cusomizing CMAKE_PREFIX_PATH for different buildType "
	^self cmakePrefixPathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakePrefixPathBuildDebugITimerHeartbeat [
	"convenience method for cusomizing CMAKE_PREFIX_PATH for different buildType "
	^self cmakePrefixPathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakePrefixPathBuildITimerHeartbeat [
	"convenience method for cusomizing CMAKE_PREFIX_PATH for different buildType "
	^self cmakePrefixPathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakePrefixPathBuildMultiThreaded [
	"convenience method for cusomizing CMAKE_PREFIX_PATH for different buildType "
	^self cmakePrefixPathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakePrefixPathBuildMultiThreadedAssert [
	"convenience method for cusomizing CMAKE_PREFIX_PATH for different buildType "
	^self cmakePrefixPathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakePrefixPathBuildMultiThreadedDebug [
	"convenience method for cusomizing CMAKE_PREFIX_PATH for different buildType "
	^self cmakePrefixPathBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakePrefixPathNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeSetSourceFilesProperties [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self cmakeSetSourceFilesPropertiesBuild];
		at: #buildAssert  put: [self cmakeSetSourceFilesPropertiesBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self cmakeSetSourceFilesPropertiesBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self cmakeSetSourceFilesPropertiesBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self cmakeSetSourceFilesPropertiesBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self cmakeSetSourceFilesPropertiesBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self cmakeSetSourceFilesPropertiesBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self cmakeSetSourceFilesPropertiesBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self cmakeSetSourceFilesPropertiesBuildMultiThreadedDebug ];
		at: #buildNone put:[self cmakeSetSourceFilesPropertiesNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeSetSourceFilesPropertiesBuild [
"
 cmake --help-command set_source_files_properties
set_source_files_properties
---------------------------

Source files can have properties that affect how they are built.

::

 set_source_files_properties([file1 [file2 [...]]]
                             PROPERTIES prop1 value1
                             [prop2 value2 [...]])

Set properties associated with source files using a key/value paired
list.  See properties documentation for those known to CMake.
Unrecognized properties are ignored.  Source file properties are
visible only to targets added in the same directory (CMakeLists.txt).

."

	self subclassResponsibility.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeSetSourceFilesPropertiesBuildAssert [
	"convenience method for cusomizing  for different buildType "
	^self cmakeSetSourceFilesPropertiesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeSetSourceFilesPropertiesBuildAssertITimerHeartbeat [
	"convenience method for cusomizing  for different buildType "
	^self cmakeSetSourceFilesPropertiesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeSetSourceFilesPropertiesBuildDebug [
	"convenience method for cusomizing  for different buildType "
	^self cmakeSetSourceFilesPropertiesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeSetSourceFilesPropertiesBuildDebugITimerHeartbeat [
	"convenience method for cusomizing  for different buildType "
	^self cmakeSetSourceFilesPropertiesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeSetSourceFilesPropertiesBuildITimerHeartbeat [
	"convenience method for cusomizing  for different buildType "
	^self cmakeSetSourceFilesPropertiesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeSetSourceFilesPropertiesBuildMultiThreaded [
	"convenience method for cusomizing  for different buildType "
	^self cmakeSetSourceFilesPropertiesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeSetSourceFilesPropertiesBuildMultiThreadedAssert [
	"convenience method for cusomizing  for different buildType "
	^self cmakeSetSourceFilesPropertiesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeSetSourceFilesPropertiesBuildMultiThreadedDebug [
	"convenience method for cusomizing  for different buildType "
	^self cmakeSetSourceFilesPropertiesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> cmakeSetSourceFilesPropertiesNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #cmake }
CPlatformConfigForSqueak >> cmakeWriteDirectoriesDotCmake: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'setupDirectories:'"
	self subclassResponsibility
]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> cogitClass [
	self subclassResponsibility

	"
	^SimpleStackBasedCogit
	^ StackToRegisterMappingCogit 
	^SistaStackToRegisterMappingCogit

	Which one?

	ClassCommentVersionsBrowser browseCommentOf: Cogit 

	"

]

{ #category : #compiling }
CPlatformConfigForSqueak >> compilerDefinitions [
	"-DNDEBUG -DGNU_SOURCE...etc . cmakeAddDefinitions(buildType) replaces this"
	self deprecated: 'Legacy method from pharo approach. We need different definitions for each buildType'.
	self	subclassResponsibility
]

{ #category : #compiling }
CPlatformConfigForSqueak >> compilerFlags [
	self flag:'tty'. "This goes away if we agree to fork the  project. "
	self deprecated:' this catchall method has been split into dedicated methods: cmakePrefixPath cmakeIncludePath 	cmakeLibraryPath	cmakeIncludeModules;    cmakeCFlags;       '. "see method ''generate'' in CMakeVMGeneratorForSqueak browse      for old call.  "
	self	 cmakeCFlags.


"The old CMakeVMMaker loaded all kinds of stuff in compilerflags that where really pre-processor definitions etc. 
I have factored them out in the interest of clarity and simplicity.
"
]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateB3DAcceleratorPlugin: aMaker [

	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '$(pluginCross)/sqOpenGLRenderer.c'))

]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateBitBltSimulation: aMaker [
	aMaker templates 
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${pluginCross}'));
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginCross}/BitBltGeneric.c'));
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginCross}/BitBltDispatch.c'))


]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateBochsIA32Plugin: aMaker [

	"this stuff is not ready for use yet" 
	
" 	maker addCrossSources:
		#( 'sqBochsIA32Plugin.cpp'  )

"
	aMaker doNotGenerate:true

]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateCroquetPlugin: aMaker [ 
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginCross}/TriBoxStub.c'))

]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateFFIPlugin: aMaker [
	self flag:'tty'. "comment below is from pharo code. I have no idea at the moment."
	" it is incomplete right now, because in Cog this plugin are not used anymore"
	aMaker doNotGenerate: true.
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '$(pluginCross)/sqFFIPlugin.c')).

]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateFilePlugin: aMaker [
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginCross}/sqFilePluginBasicPrims.c'))




]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateFloatMathPlugin: aMaker [
      |cfiles pfiles|
	cfiles:= #(
		'acos.c' 'acosh.c' 'asin.c' 'asinh.c' 'atan.c' 'atan2.c' 'atanh.c'
		'copysign.c' 'cos.c' 'cosh.c' 'exp.c' 'expm1.c' 'finite.c' 'fmod.c'
		'hypot.c' 'isnan.c' 'k_cos.c' 'k_rem_pio2.c' 'k_sin.c' 'k_tan.c' 'ldexp.c'
		'log.c' 'log10.c' 'log1p.c' 'modf.c' 'pow.c' 'rem_pio2.c' 'rint.c'
		'scalb.c' 'scalbn.c' 'sin.c' 'sinh.c' 'sqrt.c' 'tan.c' 'tanh.c' ).
	pfiles:=OrderedCollection new.  "Anybody who knows how to do this elegantly, please change this"
	cfiles do:[:each | pfiles addLast:('${pluginCross}/', each)].
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: pfiles);
		addLast:((CMakeAddDefinitions new) definitions: (OrderedCollection with: '-O0')).  "See Note 1."
	self isLittleEndian 
		ifTrue: [
			aMaker templates 
				addLast:((CMakeAddDefinitions new) definitions: (OrderedCollection with:'-D__LITTLE_ENDIAN=1' ))].  "See Note 2."

	aMaker templates "See Note 3."
		addLast:((CMakeIfAddDefinitionsElseAddDefinitions new) 
					condition:'${WIN32}' 
					ifdefinitions:'-Werror-implicit-function-declaration'
					elsedefinitions:'-DNO_ISNAN')

"
Note 1. according to http://www.netlib.org/fdlibm/readme	it should be compiled with no optimizations

Note 2. compile with -D__LITTLE_ENDIAN	This macro is set automatically in fdlibm.h when compiled ith -m32 but
		not when compiled with -m64 (Nicolas Cellier)

Note 3. 	It may be better to push these down to SqueakMacintoshConfig, SqueakUnixConfig, SqueakWindowsConfig.
I think it is clearer here.

In the mean time this template outputs the following:

if (${WIN32})
	add_definitions(-Werror-implicit-function-declaration)	<---push down to SqueakWindowsConfig
else(${WIN32})
	add_definitions(-DNO_ISNAN)                                        <---push down to SqueakUnix/MacConfigs
endif (${WIN32})'.

"
]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateIA32ABIPlugin: aMaker [
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '$(pluginCross)/ia32abicc.c')).


]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateJPEGReadWriter2Plugin: aMaker [ 
      |cfiles pfiles|
	cfiles:=  #('Error.c' 'jcapimin.c' 'jcapistd.c' 'jccoefct.c' 'jccolor.c' 'jcdctmgr.c' 
                       'jchuff.c' 'jcinit.c' 'jcmainct.c' 'jcmarker.c' 'jcmaster.c' 'jcomapi.c'  'jcparam.c' 
                       'jcphuff.c' 'jcprepct.c' 'jcsample.c' 'jctrans.c' 'jdapimin.c' 'jdapistd.c'
                       'jdatadst.c' 'jdatasrc.c' 'jdcoefct.c' 'jdcolor.c' 'jddctmgr.c' 'jdhuff.c'
                       'jdinput.c' 'jdmainct.c' 'jdmarker.c' 'jdmaster.c' 'jdmerge.c' 'jdphuff.c' 'jdpostct.c'
                       'jdsample.c' 'jdtrans.c' 'jerror.c' 'jfdctflt.c' 'jfdctfst.c' 'jfdctint.c'
                       'jidctflt.c' 'jidctfst.c' 'jidctint.c' 'jidctred.c' 'jmemdatadst.c' 'jmemdatasrc.c'
                       'jmemmgr.c' 'jmemnobs.c' 'jquant1.c' 'jquant2.c' 'jutils.c' ) .
	pfiles:=OrderedCollection new.  "Anybody who knows how to do this elegantly, please change this"
	cfiles do:[:each | pfiles addLast:('$(pluginCross)/', each)].
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: pfiles).



]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateMpeg3Plugin: aMaker [
      |cfiles pfiles|
	cfiles:=#( 'libmpeg/bitstream.c' 'libmpeg/changesForSqueak.c'	'libmpeg/audio/dct.c' 
     'libmpeg/video/getpicture.c' 'libmpeg/audio/header.c' 'libmpeg/video/headers.c' 
     'libmpeg/video/idct.c' 'libmpeg/audio/layer1.c' 'libmpeg/audio/layer2.c' 
     'libmpeg/audio/layer3.c' 'libmpeg/libmpeg3.c' 'libmpeg/video/macroblocks.c' 
     'libmpeg/video/mmxtest.c' 'libmpeg/video/motion.c' 'libmpeg/mpeg3atrack.c' 
     'libmpeg/audio/mpeg3audio.c' 'libmpeg/mpeg3demux.c' 'libmpeg/mpeg3io.c'
     'libmpeg/mpeg3title.c' 'libmpeg/video/mpeg3video.c' 'libmpeg/mpeg3vtrack.c'
     'libmpeg/video/output.c' 'libmpeg/audio/pcm.c' 'libmpeg/video/reconstruct.c'
     'libmpeg/video/seek.c' 'libmpeg/video/slice.c' 'libmpeg/audio/synthesizers.c'
     'libmpeg/audio/tables.c' 'libmpeg/video/vlc.c' ).
	pfiles:=OrderedCollection new.  "Anybody who knows how to do this elegantly, please change this"
	cfiles do:[:each | pfiles addLast:('${pluginCross}/', each)].
	aMaker templates 
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${pluginCross}/libmpeg ${pluginCross}/libmpeg/audio ${pluginCross}/libmpeg/video'));
		addLast:((CMakeListAppend new) list:'sources' elements: pfiles).

	
	

]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> configureByTemplatePlugin: aPlugin with: generator [

	^ self perform: ( 'configureByTemplate' , aPlugin name , ':' ) asSymbol with: generator.
	
]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateRePlugin: aMaker [ 
	aMaker templates 
		addLast:((CMakeListAppend new) 
			list:'sources' 
			elements: (OrderedCollection 
						with: '$(pluginCross)/pcre.c'
						with: '$(pluginCross)/study.c'
						with: '$(pluginCross)/get.c'
						with: '$(pluginCross)/chartables.c'))


]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateReentrantIA32FFIPlugin: aMaker [
	aMaker templates 
		addLast:((CMakeListAppend new) 
			list:'sources' 
			elements: (OrderedCollection 
						with: '$(pluginCross)/sqFFIPlugin.c'
						with: '$(pluginCross)/sqFFITestFuncs.c'
						with: '$(pluginCross)/sqManualSurface.c')).


]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateSoundCodecPlugin: aMaker [
	aMaker templates 
		addLast:((CMakeListAppend new) 
			list:'sources' 
			elements: (OrderedCollection 	with: '${pluginCross}/sqSoundCodecPluginBasicPrims.c')).


]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateSoundGenerationPlugin: aMaker [ 
	aMaker doNotGenerate: true. 
	"From Pharo comment:  The sources in platforms/Cross/plugins/SoundGenerationPlugin/sqOldSoundPrims.c 
	are out of date and need to be fixed before it can be built 
	
	aMaker templates 
		addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '$(pluginCross)/sqOldSoundPrims.c'));
	"
]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateSurfacePlugin: aMaker [ 
	aMaker templates
			addLast:((CMakeSet new) variable: #sources value: '');"remove default source file"
			addLast:((CMakeListAppend new) list:'sources' elements: (OrderedCollection with: '${pluginCross}/SurfacePlugin.c')).


]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateThreadedIA32FFIPlugin: aMaker [
	aMaker templates 
		addLast:((CMakeListAppend new) 
			list:'sources' 
			elements: (OrderedCollection 
						with: '$(pluginCross)/sqFFIPlugin.c'
						with: '$(pluginCross)/sqFFITestFuncs.c'
						with: '$(pluginCross)/sqManualSurface.c')).


]

{ #category : #'plugin extra rules' }
CPlatformConfigForSqueak >> configureByTemplateUnixOSProcessPlugin: aMaker [
	aMaker templates 
		addLast: ((CMakeIncludeDirectories new) dirs: (OrderedCollection with: '${crossDir}/plugins/FilePlugin'));
		addLast:((CMakeSet new) variable: #linkFlags value: '-undefined dynamic_lookup').  	"THIS IS UGLY AND LAME!!! (comment from Pharo code)"


]

{ #category : #cmake }
CPlatformConfigForSqueak >> configureForBuildType: aSymbol [
	"Set my internal state appropriate for my build type".
	self subclassResponsibility.

]

{ #category : #cmake }
CPlatformConfigForSqueak >> configureNoBuildType [
		generateBuild:=generateBuildAssert:=generateBuildAssertITimerHeartbeat:=generateBuildDebug:=generateBuildDebugITimerHeartbeat:= generateBuildDebugMultiThreaded:= generateBuildIHeartbeatTimer:= generateBuildMultiThreaded:= generateBuildMultiThreadedAssert:= generateBuildMultiThreadedDebug:=false.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSources [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self coreSourcesBuild];
		at: #buildAssert  put: [self coreSourcesBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self coreSourcesBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self coreSourcesBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self coreSourcesBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self coreSourcesBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self coreSourcesBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self coreSourcesBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self coreSourcesBuildMultiThreadedDebug ];
		at: #buildNone put:[self coreSourcesNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuild [
	^self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuildAssert [
	"override if your configuration's core sources change based on build type. (doubtful)"
	^self coreSourcesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuildAssertITimerHeartbeat [
	"override if your configuration's core sources change based on build type. (doubtful)"
	^self coreSourcesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuildDebug [
	"override if your configuration's core sources change based on build type. (doubtful)"
	^self coreSourcesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuildDebugITimerHeartbeat [
	"override if your configuration's core sources change based on build type. (doubtful)"
	^self coreSourcesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuildITimerHeartbeat [
	"override if your configuration's core sources change based on build type. (doubtful)"
	^self coreSourcesBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuildMultiThreaded [
	^self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuildMultiThreadedAssert [
	"override if your configuration's core sources change based on build type. (doubtful)"
	^self coreSourcesBuildMultiThreaded
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesBuildMultiThreadedDebug [
	"override if your configuration's core sources change based on build type. (doubtful)"
	^self coreSourcesBuildMultiThreaded
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> coreSourcesNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'source files' }
CPlatformConfigForSqueak >> crossSources [ 
"	
	SystemNavigation default browseMethodsWhoseNamesContain: 'crossSources'

^#(
			'sqHeapMap.c'
			'sqTicker.c'
			'sqExternalSemaphores.c'
			'sqNamedPrims.c'
			'sqVirtualMachine.c'
		)
"
self subclassResponsibility
]

{ #category : #plugins }
CPlatformConfigForSqueak >> customizeVMPlugins [
	self flag:'tty'. "is this needed on all platforms? consider moving down"
	self subclassResponsibility
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirARMv6 [
	^'cmake.build.arm.v6'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirAndroid [
	^'Do Not Build. See Class Comment'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirBSD32x86 [
	^'cmake.build.bsd32x86'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirBuild [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #build
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirBuildAssert [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildAssert
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirBuildAssertITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildAssertITimerHeartbeat
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirBuildDebug [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debug
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirBuildDebugITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debugITimerHeartbeat
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirBuildDebugMultiThreaded [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #debugMultiThreaded
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirBuildITimerHeartbeat [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildITimerHeartbeat
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	self subclassResponsibility
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirBuildMultiThreaded [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreaded
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirBuildMultiThreadedAssert [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreadedAssert
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirBuildMultiThreadedDebug [
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #buildMultiThreadedDebug
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirBuildPlatform [
	"the directory for the platform. example: build.linux32x86"
	self subclassResponsibility
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> dirFrom: aStringOrDir [
	^ aStringOrDir isString
		ifTrue: [ FileDirectory forFileName: aStringOrDir  ]
		ifFalse: [ aStringOrDir ]
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirIA32Bochs [
	^'cmake.build.ia32bochs'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirIOS [
	^'cmake.build.ios'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirInstall [
	"the directory of the finished product.. the place where 'make install' puts stuff.
	SystemNavigation default browseMethodsWhoseNamesContain: 'outputDir'
      "
	self subclassResponsibility

]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirLinux32Armv6 [
	^'cmake.build.linux32armv6'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirLinux32x86 [
	^'cmake.build.linux32x86'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirLinux64x64 [
	^'cmake.build.linux64x64'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirLinux64x86w32BitCompatibility [
	^'cmake.build.linux64x86w32BitCompatibility'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirMacOS [
	^'cmake.build.macos'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirMacOSPowerPC [
	^'cmake.build.macospowerpc'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirMacOSX32x86 [
	^'cmake.build.macosx32x86'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirOutput [
	^'cmake.products'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirSource [
	^'src'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirSunOS32x86 [
	^'cmake.build.sunos32x86'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> dirWin32x86 [
	^'cmake.build.win32x86'
]

{ #category : #accessing }
CPlatformConfigForSqueak >> enabledebugmessages [
	^enabledebugmessages
]

{ #category : #accessing }
CPlatformConfigForSqueak >> enabledebugmessages: aBoolean [
	enabledebugmessages := aBoolean
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> eventStackV3 [

	^'do not build'
]

{ #category : #cmake }
CPlatformConfigForSqueak >> excludeFromBuild [
"	^false"   "build this configuration"
"	^true"   "do not build this configuration"
	self subclassResponsibility

]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> executableName [
	self subclassResponsibility
"
executableName
	^ self vmCogExecutableName
	^ self vmSistaExecutableName
	^ self vmStackExectuableName
"

]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> executableType [
	self subclassResponsibility.

"
SystemNavigation default browseMethodsWhoseNamesContain: ''executableType''
	^ 'MACOSX_BUNDLE'
	^ 'WIN32'\
	^ ''
"
]

{ #category : #compiling }
CPlatformConfigForSqueak >> externalLibraries [
	"-lX11 -luuid -lssl -lcrypto  define these in your concrete CPlatformConfigForSqueak and feed them to cmakeListAppendLinkLibs"
	self	subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalLibs [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self externalLibsBuild];
		at: #buildAssert  put: [self externalLibsBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self externalLibsBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self externalLibsBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self externalLibsBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self externalLibsBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self externalLibsBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self externalLibsBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self externalLibsBuildMultiThreadedDebug ];
		at: #buildNone put:[self externalLibsNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalLibsBuild [
	 ""
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalLibsBuildAssert [
	 "override this if you need to customize for this build type"
	^self externalLibsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalLibsBuildAssertITimerHeartbeat [
	 "override this if you need to customize for this build type"
	^self externalLibsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalLibsBuildDebug [
	 "override this if you need to customize for this build type"
	^self externalLibsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalLibsBuildDebugITimerHeartbeat [
	 "override this if you need to customize for this build type"
	^self externalLibsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalLibsBuildITimerHeartbeat [
	 "override this if you need to customize for this build type"
	^self externalLibsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalLibsBuildMultiThreaded [
	 "override this if you need to customize for this build type"
	^self externalLibsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalLibsBuildMultiThreadedAssert [
	 "override this if you need to customize for this build type"
	^self externalLibsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalLibsBuildMultiThreadedDebug [
	 "override this if you need to customize for this build type"
	^self externalLibsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalLibsNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> externalModulesDir [
	"answer the location in VM bundle, where plugins and rest of dynamic libs will be copied,
	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPlugins [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self externalPluginsBuild];
		at: #buildAssert  put: [self externalPluginsBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self externalPluginsBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self externalPluginsBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self externalPluginsBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self externalPluginsBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self externalPluginsBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self externalPluginsBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self externalPluginsBuildMultiThreadedDebug ];
		at: #buildNone put:[self externalPluginsNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuild [ 
	"convenience method to customize plugins for this build. 
	^self externalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuildAssert [ 
	"convenience method to customize plugins for this build. "
	^self externalPluginsBuild


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuildAssertITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPluginsBuild


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuildDebug [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuildDebugITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuildITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuildMultiThreaded [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuildMultiThreadedAssert [
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPluginsBuild

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsBuildMultiThreadedDebug [ 
	"convenience method to customize plugins for this build.  default is self  externalPluins"
	^self externalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> externalPluginsNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettings: aMaker [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self extraPluginSettingsBuild: aMaker];
		at: #buildAssert  put: [self extraPluginSettingsBuildAssert: aMaker];
		at: #buildAssertITimerHeartbeat  put: [self extraPluginSettingsBuildAssertITimerHeartbeat: aMaker];
            at:#buildDebug  put: [self extraPluginSettingsBuildDebug: aMaker];   
		at: #buildDebugITimerHeartbeat  put: [self extraPluginSettingsBuildDebugITimerHeartbeat: aMaker ];
		at: #buildITimerHeartbeat  put: [self extraPluginSettingsBuildITimerHeartbeat: aMaker];
		at: #buildMultiThreaded  put: [self extraPluginSettingsBuildMultiThreaded: aMaker];
		at: #buildMultiThreadedAssert  put: [self extraPluginSettingsBuildMultiThreadedAssert: aMaker];
		at: #buildMultiThreadedDebug   put: [self extraPluginSettingsBuildMultiThreadedDebug: aMaker ];
		at: #buildNone put:[self extraPluginSettingsNoBuildType: aMaker].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuild: maker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraPluginSettings'
	"
	self subclassResponsibility


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildAssert: aMaker [
	"convenience method for customizing per build type. Overrride if you need it"
	^self extraPluginSettingsBuild: aMaker



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildAssertITimerHeartbeat: aMaker [
	"convenience method for customizing per build type. Overrride if you need it"
	^self extraPluginSettingsBuild: aMaker


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildDebug: aMaker [
	"convenience method for customizing per build type. Overrride if you need it"
	^self extraPluginSettingsBuild: aMaker



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildDebugITimerHeartbeat: aMaker [
	"convenience method for customizing per build type. Overrride if you need it"
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildITimerHeartbeat: aMaker [
	"convenience method for customizing per build type. Overrride if you need it"
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildMultiThreaded: aMaker [
	"convenience method for customizing per build type. Overrride if you need it"
	^self extraPluginSettingsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildMultiThreadedAssert: aMaker [
	"convenience method for customizing per build type. Overrride if you need it"
	^self extraPluginSettingsBuild: aMaker



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsBuildMultiThreadedDebug: aMaker [
	"convenience method for customizing per build type. Overrride if you need it"
	^self extraPluginSettingsBuild: aMaker


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraPluginSettingsNoBuildType: aMaker [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'source files' }
CPlatformConfigForSqueak >> extraSources [
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettings: aMaker [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self extraVMSettingsBuild: aMaker];
		at: #buildAssert  put: [self extraVMSettingsBuildAssert: aMaker];
		at: #buildAssertITimerHeartbeat  put: [self extraVMSettingsBuildAssertITimerHeartbeat: aMaker];
            at:#buildDebug  put: [self extraVMSettingsBuildDebug: aMaker];   
		at: #buildDebugITimerHeartbeat  put: [self extraVMSettingsBuildDebugITimerHeartbeat: aMaker ];
		at: #buildITimerHeartbeat  put: [self extraVMSettingsBuildITimerHeartbeat: aMaker];
		at: #buildMultiThreaded  put: [self extraVMSettingsBuildMultiThreaded: aMaker ];
		at: #buildMultiThreadedAssert  put: [self extraVMSettingsBuildMultiThreadedAssert: aMaker];
		at: #buildMultiThreadedDebug   put: [self extraVMSettingsBuildMultiThreadedDebug: aMaker ];
		at: #buildNone put:[self extraVMSettingsNoBuildType:  aMaker].
	^(d at: buildType) value

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuild: maker [
	"convenience method to customize plugin settings for this buildType. 
	on unix writes out version.c custom command.
	on mac/windows, I don't know.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"

	^self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuildAssert: aMaker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"

	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuildAssertITimerHeartbeat: aMaker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuildDebug: aMaker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuildDebugITimerHeartbeat: aMaker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuildITimerHeartbeat: aMaker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuildMultiThreaded: aMaker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuildMultiThreadedAssert: aMaker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsBuildMultiThreadedDebug: aMaker [
	"convenience method to customize plugin settings for this buildType. 
	Most configurations do nothing.
	SystemNavigation default browseMethodsWhoseNamesContain: 'extraVMSettings'
	"
	^self extraVMSettingsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> extraVMSettingsNoBuildType: maker [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> fixLineEndsOf: string [
	self flag:'tty'. "does FileStream handle this cleanly?"
	^ string copyReplaceAll: String cr with: String crlf
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworks [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self frameworksBuild];
		at: #buildAssert  put: [self frameworksBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self frameworksBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self frameworksBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self frameworksBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self frameworksBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self frameworksBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self frameworksBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self frameworksBuildMultiThreadedDebug ];
		at: #buildNone put:[self frameworksNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuild [
	"^#()"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuildAssert [ 
	"convenience method to customize plugins for this build default to internalPluins"
	^self frameworksBuild


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuildAssertITimerHeartbeat [ 
	"convenience method to customize plugins for this build default to internalPluins"
	^self frameworksBuild

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuildDebug [ 
	"convenience method to customize plugins for this build default to internalPluins"
	^self frameworksBuild

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuildDebugITimerHeartbeat [ 
	"convenience method to customize plugins for this build default to internalPluins"
	^self frameworksBuild


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuildITimerHeartbeat [ 
	"convenience method to customize plugins for this build default to internalPluins"
	^self frameworksBuild

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuildMultiThreaded [ 
	"convenience method to customize plugins for this build default to internalPluins"
	^self frameworksBuild


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuildMultiThreadedAssert [
	"convenience method to customize plugins for this build default to internalPluins"
	^self frameworksBuild

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> frameworksBuildMultiThreadedDebug [ 
	"convenience method to customize plugins for this build default to internalPluins"
	^self frameworksBuild


]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> generateByTemplate [
	self subclassResponsibility

]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> generateLicense [ 
	self 
		write:  (self class licenseTemplate 
			format: { self version })
		toFile: 'LICENSE.txt'
	
]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> generatePluginsCmake [
	self 
		write:  (self class pluginsCMake)
		toFile: 'Plugins.cmake'
	
]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> generatePluginsList [ 
	self 
		write:  (self class pluginsTemplate 
			format: {
				self version. 
				String streamContents: [ :stream | self internalPlugins asStringOn: stream delimiter: String cr ].
				String streamContents: [ :stream | self externalPlugins asStringOn: stream delimiter: String cr ].
				self executableName })
		toFile: 'PLUGINS.txt'
	
]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> generateTestDoubleWordAlignmentC [
	self 
		write:  (self class testDoubleWordAlignmentC)
		toFile: 'testDoubleWordAlignment.c'
	
]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> generateTestDoubleWordOrderC [
	self 
		write:  (self class testDoubleWordOrderC)
		toFile: 'testDoubleWordOrder.c'
	
]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> generateTestLanginfoCodesetC [
	self 
		write:  (self class testLanginfoCodesetC)
		toFile: 'testLanginfoCodeset.c'
	
]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> generateUtilsCmake [
	self 
		write:  (self class utilsCMake)
		toFile: 'Utils.cmake'
	
]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> generateVmBuildCmake [
	self 
		write:  (self class vmBuildCmake)
		toFile: 'build.cmake'
	
]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> generateVmConfigCmake [
	self subclassResponsibility
]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> generateVmConfigIn [
	self 
		write:  (self class vmConfigIn)
		toFile: 'config.in'
	
]

{ #category : #'initialize-release' }
CPlatformConfigForSqueak >> initialize [
	enabledebugmessages := false.
	self initializeVMDrivers.
	self customizeVMPlugins
]

{ #category : #'initialize-release' }
CPlatformConfigForSqueak >> initializeVMDrivers [
	vmplugins := OrderedCollection new.
	vmplugins 
		addLast:(CMakeVMDisplayCustom new);
		addLast:(CMakeVMDisplayFbdev new);
		addLast:(CMakeVMDisplayNull new);
		addLast:(CMakeVMDisplayQuartz new);
		addLast:(CMakeVMDisplayX11 new);
		addLast:(CMakeVMSoundALSA new);
		addLast:(CMakeVMSoundCustom new);
		addLast:(CMakeVMSoundMacOSX new);
		addLast:(CMakeVMSoundNAS new);
		addLast:(CMakeVMSoundNull new);
		addLast:(CMakeVMSoundOSS new);
		addLast:(CMakeVMSoundSun new).

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPlugins [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self internalPluginsBuild];
		at: #buildAssert  put: [self internalPluginsBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self internalPluginsBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self internalPluginsBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self internalPluginsBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self internalPluginsBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self internalPluginsBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self internalPluginsBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self internalPluginsBuildMultiThreadedDebug ];
		at: #buildNone put:[self internalPluginsNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuild [ 
	"convenience method to customize plugins for this build default to internalPluins
	^self internalPlugins"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuildAssert [ 
	"convenience method to customize plugins for this build default to internalPluins
	^self internalPlugins"
	^self internalPluginsBuild

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuildAssertITimerHeartbeat [ 
	"convenience method to customize plugins for this build default to internalPluins
	^self internalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuildDebug [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	^self internalPluginsBuild

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuildDebugITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	^self internalPluginsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuildITimerHeartbeat [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	^self internalPluginsBuild

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuildMultiThreaded [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	^self internalPluginsBuild

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuildMultiThreadedAssert [
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	^self internalPluginsBuild

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsBuildMultiThreadedDebug [ 
	"convenience method to customize plugins for this build.  default is self  internalPluins
	^self internalPlugins"
	^self internalPluginsBuild

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> internalPluginsNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> interpreterClass [
	"answer an interpreter class for VM source code generation"
	self subclassResponsibility 


"
	^ CoInterpreter
	^ CoInterpreterMT
	^ CoInterpreterMT
	^ StackInterpreter
	^ StackEvtAndroidInterpreter
	??other
"
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuild [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuildAssert [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuildAssertITimerHeartbeat [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuildDebug [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuildDebugITImerHeartbeat [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuildITimerHeartbeat [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClass



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuildITimerMultiThreaded [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^CoInterpreterMT



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuildITimerMultiThreadedAssert [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClassBuildITimerMultiThreaded



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassBuildITimerMultiThreadedDebug [
	"interpreter class can change to MultiThreaded for certain build types. For consistency sake, we maintain the pattern of other confiuration methods"
	^self interpreterClassBuildITimerMultiThreaded



]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> interpreterClassNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.



]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> iosPlatformName [
	^'iOS'
]

{ #category : #compiling }
CPlatformConfigForSqueak >> linkerFlags [
	self flag:'tty'. "Does this need to be ported to the redirect design pattern with linkerFlagsBuild, linkerFlagsDebug etc?"
"
linkerFlags
	^#(	'-Wl'
            '-z'
            'now'
	   ) 
"


	self	subclassResponsibility
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> macOSPlatformName [
	^'Mac OS'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> newspeakCogSpur [
	^'newspeak.cog.spur'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> newspeakCogV3 [
	^'newspeak.cog.v3'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> newspeakSistaSpur [
	^'newspeak.sista.Spur'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> newspeakSistaV3 [
	^'newspeak.sista.v3'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> newspeakStackSpur [
	^'newspeak.stack.spur'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> newspeakStackV3 [
	^'newspeak.stack.v3'
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> nilPlatformName [
	^nil
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> oscogvm [
	^'oscogvm'
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> outputDir [

	"the directory where built binaries will be stored"
	^ outputDir ifNil: [ outputDir := (self topDir / self dirOutput /  self dirInstall) ]	


]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> outputDirName [
	^ 'products'
]

{ #category : #'source files' }
CPlatformConfigForSqueak >> platformSources [

"	
	SystemNavigation default browseMethodsWhoseNamesContain: 'platformSources'

^#( platform specific array)
"

	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActions: aMaker [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self postBuildActionsBuild: aMaker];
		at: #buildAssert  put: [self postBuildActionsBuildAssert: aMaker];
		at: #buildAssertITimerHeartbeat  put: [self postBuildActionsBuildAssertITimerHeartbeat: aMaker];
            at:#buildDebug  put: [self postBuildActionsBuildDebug: aMaker];   
		at: #buildDebugITimerHeartbeat  put: [self postBuildActionsBuildDebugITimerHeartbeat: aMaker ];
		at: #buildITimerHeartbeat  put: [self postBuildActionsBuildITimerHeartbeat: aMaker];
		at: #buildMultiThreaded  put: [self postBuildActionsBuildMultiThreaded: aMaker ];
		at: #buildMultiThreadedAssert  put: [self postBuildActionsBuildMultiThreadedAssert: aMaker];
		at: #buildMultiThreadedDebug   put: [self postBuildActionsBuildMultiThreadedDebug: aMaker ];
		at: #buildNone put:[self postBuildActionsNoBuildType:  aMaker].
	^(d at: buildType) value

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuild: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'

	"
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuildAssert: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'"

	self postBuildActionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuildAssertITimerHeartbeat: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'"

	self postBuildActionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuildDebug: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'"

	self postBuildActionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuildDebugITimerHeartbeat: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'"

	self postBuildActionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuildITimerHeartbeat: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'"

	self postBuildActionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuildMultiThreaded: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'"

	self postBuildActionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuildMultiThreadedAssert: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'"

	self postBuildActionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsBuildMultiThreadedDebug: aMaker [
	"
	SystemNavigation default browseMethodsWhoseNamesContain: 'postBuildActions'"

	self postBuildActionsBuild: aMaker

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> postBuildActionsNoBuildType: aMaker [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludes [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self preferredIncludesBuild];
		at: #buildAssert  put: [self preferredIncludesBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self preferredIncludesBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self preferredIncludesBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self preferredIncludesBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self preferredIncludesBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self preferredIncludesBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self preferredIncludesBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self preferredIncludesBuildMultiThreadedDebug ];
		at: #buildNone put:[self preferredIncludesNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuild [	
	"convencience method to customize for this build.
	SystemNavigation default browseMethodsWhoseNamesContain: 'preferredIncludes'"

	self subclassResponsibility


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuildAssert [
	^ self preferredIncludesBuild.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuildAssertITimerHeartbeat [
	^ self preferredIncludesBuild.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuildDebug [
	^ self preferredIncludesBuild.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuildDebugITimerHeartbeat [
	^ self preferredIncludesBuild.

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuildITimerHeartbeat [
	^ self preferredIncludesBuild.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuildMultiThreaded [
	^ self preferredIncludesBuild.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuildMultiThreadedAssert [
	^ self preferredIncludesBuild.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesBuildMultiThreadedDebug [
	^ self preferredIncludesBuild.

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> preferredIncludesNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'source generation' }
CPlatformConfigForSqueak >> prepareForGeneration [
	"feel free to override me"
	|i|
	self flag:'tty'. 
	i:= self interpreterClass.
	((i == CoInterpreter) | (i == CoInterpreterMT ))
		ifTrue:[self prepareForCogGeneration].   "what is more efficient? self or super?  tty."
	(i == StackInterpreter) 
		ifTrue:[self prepareForStackVMGeneration].


]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> prepareVMMaker [
	
	| maker allPlugins |
	
	"In CogVMs (in contrast to Interpreter VM) the generated sources are platform independent, therefore Cross is ok"
	maker := VMMaker forPlatform: 'Cross'.
	
	maker sourceDirectoryName: self srcDir pathName.
	maker platformRootDirectoryName: self platformsDir.
	
	
	allPlugins := self internalPlugins , self externalPlugins.
	
	"touch plugins to force their source generation unconditionally"
	allPlugins do: [:name | (Smalltalk globals at: name) touch ].
	
	" Why we put all plugins as external?   Because the generated sources are not different whether the plugins were defined as internal or external. VMMaker used to need this to to generate plugins.int and plugins.ext files. But since this is achieved in another way with CMakeVMMaker, there is no different at all to put all plugins as internal or as external."
	maker externalModules addAll:  allPlugins.
	
	^ maker
]

{ #category : #cmake }
CPlatformConfigForSqueak >> setCoreSources: aMaker [
	|core |
	(enabledebugmessages)
		ifTrue:[	templates 
		addLast:((CMakeMessage new) message: (self class name) , 'setCoreSources: aMaker')
	].
	core := aMaker append: '${srcVMDir}/' toAll: (self coreSources).
	templates
		addLast:((CMakeSet new) variable:'coreSources' value: core).

	
]

{ #category : #cmake }
CPlatformConfigForSqueak >> setCrossSources: aMaker [
	|cross |
	(enabledebugmessages)
		ifTrue:[	templates 
		addLast:((CMakeMessage new) message: (self class name) , 'setCrossSources: aMaker')
	].
	cross := aMaker append: '${crossDir}/vm/' toAll: (self crossSources).
	templates
		addLast:((CMakeSet new) variable:'crossVMSources' value: cross)

	
]

{ #category : #cmake }
CPlatformConfigForSqueak >> setDirectories: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'setupDirectories:'"
	self subclassResponsibility
]

{ #category : #cmake }
CPlatformConfigForSqueak >> setExecutableOutputPath [
	(enabledebugmessages)
		ifTrue:[	templates 
		addLast:((CMakeMessage new) message: (self class name) , 'setExecutableOutputPath: aMaker')
	].
	templates
		addLast:((CMakeSet new) variable:'EXECUTABLE_OUTPUT_PATH' quotedValue: (self outputDir fullName)).

	
]

{ #category : #cmake }
CPlatformConfigForSqueak >> setExtraSources [
	(enabledebugmessages)
		ifTrue:[	templates 
		addLast:((CMakeMessage new) message: (self class name) , 'setExtraSources')
	].
	templates
		addLast:((CMakeSet new) variable:'extraSources' value: (self extraSources))

	
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptions: aMaker [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self setGlobalOptionsBuild: aMaker];
		at: #buildAssert  put: [self setGlobalOptionsBuildAssert: aMaker];
		at: #buildAssertITimerHeartbeat  put: [self setGlobalOptionsBuildAssertITimerHeartbeat: aMaker];
            at:#buildDebug  put: [self setGlobalOptionsBuildDebug: aMaker];   
		at: #buildDebugITimerHeartbeat  put: [self setGlobalOptionsBuildDebugITimerHeartbeat: aMaker ];
		at: #buildITimerHeartbeat  put: [self setGlobalOptionsBuildITimerHeartbeat: aMaker];
		at: #buildMultiThreaded  put: [self setGlobalOptionsBuildMultiThreaded: aMaker ];
		at: #buildMultiThreadedAssert  put: [self setGlobalOptionsBuildMultiThreadedAssert: aMaker];
		at: #buildMultiThreadedDebug   put: [self setGlobalOptionsBuildMultiThreadedDebug: aMaker ];
		at: #buildNone put:[self setGlobalOptionsNoBuildType: aMaker].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystem: aMaker [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self setGlobalOptionsAfterDetermineSystemBuild: aMaker];
		at: #buildAssert  put: [self setGlobalOptionsAfterDetermineSystemBuildAssert: aMaker];
		at: #buildAssertITimerHeartbeat  put: [self setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat: aMaker];
            at:#buildDebug  put: [self setGlobalOptionsAfterDetermineSystemBuildDebug: aMaker];   
		at: #buildDebugITimerHeartbeat  put: [self setGlobalOptionsAfterDetermineSystemBuildDebugITimerHeartbeat: aMaker ];
		at: #buildITimerHeartbeat  put: [self setGlobalOptionsAfterDetermineSystemBuildITimerHeartbeat: aMaker];
		at: #buildMultiThreaded  put: [self setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker ];
		at: #buildMultiThreadedAssert  put: [self setGlobalOptionsAfterDetermineSystemBuildMultiThreadedAssert: aMaker];
		at: #buildMultiThreadedDebug   put: [self setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug: aMaker ];
		at: #buildNone put:[self setGlobalOptionsAfterDetermineSystemNoBuildType: aMaker].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuild: aMaker [
	"If you need some extra CMake Commands generated for your platform, put them here.

	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptionsAfterDetermineSystemBuild'

"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildAssert: aMaker [
	"convenience method to customize for this build type. "
		^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildAssertITimerHeartbeat: aMaker [
	"convenience method to customize for this build type. "
		^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildDebug: aMaker [
	"convenience method to customize for this build type. "
		^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildDebugITimerHeartbeat: aMaker [
	"convenience method to customize for this build type. "
		^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildITimerHeartbeat: aMaker [
	"convenience method to customize for this build type. "
		^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildMultiThreaded: aMaker [
	"convenience method to customize for this build type. "
		^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedAssert: aMaker [
	"convenience method to customize for this build type. "
		^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemBuildMultiThreadedDebug: aMaker [
	"convenience method to customize for this build type. "
		^self setGlobalOptionsAfterDetermineSystemBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsAfterDetermineSystemNoBuildType: aMaker [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuild: aMaker [
	"These are CMakeLists.txt commands that span all platforms. Extend me as needed.
	SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'"
	(enabledebugmessages)
		ifTrue:[	templates 
			addLast: ((CMakeMessage new) message: (self class name), '  setGlobalOptionsBuild: aMaker')
	].
	templates 
		addLast: ((CMakeHeader new)  configurationName:  self class name );
		addLast: ((CMakeProject new)variable: self executableName  );
		addLast: ((CMakeMinimumRequired new) version: '2.8.12');
		addLast: ((CMakeSet new) variable: 'CMAKE_CONFIGURATION_TYPES' value: 'Release').

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildAssert: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'"

	^self setGlobalOptionsBuildDebug: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildAssertITimerHeartbeat: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'"

	^self setGlobalOptionsBuildDebug: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildDebug: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'"
	self flag: 'tty'. "study up on CMAKE_CONFIGURATION TYPES"
	templates 
		addLast: ((CMakeMessage new) message: (self class name), '  setGlobalOptionsBuild: aMaker');
		addLast: ((CMakeHeader new)  configurationName:  self class name );
		addLast: ((CMakeProject new)variable: self executableName  );
		addLast: ((CMakeMinimumRequired new) version: '2.8.12');
		addLast: ((CMakeMessage new) message: 'CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}');
		addLast: ((CMakeSet new) variable: 'CMAKE_CONFIGURATION_TYPES' value: 'Debug').

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildDebugITimerHeartbeat: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'"

	^self setGlobalOptionsBuildDebug: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildITimerHeartbeat: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'"

	^self setGlobalOptionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildMultiThreaded: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'"

	^self setGlobalOptionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildMultiThreadedAssert: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'"

	^self setGlobalOptionsBuild: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsBuildMultiThreadedDebug: aMaker [
	"SystemNavigation default browseMethodsWhoseNamesContain: 'setGlobalOptions'"

	^self setGlobalOptionsBuildDebug: aMaker
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setGlobalOptionsNoBuildType: aMaker [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.
]

{ #category : #cmake }
CPlatformConfigForSqueak >> setPlatformSources: aMaker [
	|platform |
	(enabledebugmessages)
		ifTrue:[	templates 
		addLast:((CMakeMessage new) message: (self class name) , 'setPlatformSources: aMaker')
	].
	platform := aMaker append: '${targetPlatform}/vm/' toAll: (self platformSources).
	templates
		addLast:((CMakeSet new) variable:'platformVMSources' value: platform)

	
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> setResourceProperties: maker [
	"only on mac? tty"
	self subclassResponsibility
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> squeakCogSpur [
	^'squeak.cog.spur'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> squeakCogV3 [
	^'squeak.cog.v3'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> squeakSistaSpur [
	^'squeak.sista.Spur'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> squeakSistaV3 [
	^'squeak.sista.v3'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> squeakStackSpur [
	^'squeak.stack.spur'
]

{ #category : #'cmake directory' }
CPlatformConfigForSqueak >> squeakStackV3 [
	^'squeak.stack.v3'
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> srcDir [
		^ srcDir ifNil: [ srcDir := (self topDir directoryNamed: 'src' )]
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludes [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self standardIncludesBuild];
		at: #buildAssert  put: [self standardIncludesBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self standardIncludesBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self standardIncludesBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self standardIncludesBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self standardIncludesBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self standardIncludesBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self standardIncludesBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self standardIncludesBuildMultiThreadedDebug ];
		at: #buildNone put:[self standardIncludesNoBuildType].
	^(d at: buildType) value
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuild [ 
	self subclassResponsibility
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuildAssert [ 
	^self  standardIncludesBuild.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuildAssertITimerHeartbeat [ 
	^self  standardIncludesBuild.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuildDebug [ 
	^self  standardIncludesBuild.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuildDebugITimerHeartbeat [ 
	^self  standardIncludesBuild.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuildITimerHeartbeat [ 
	^self  standardIncludesBuild.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuildMultiThreaded [ 
	^self  standardIncludesBuild.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuildMultiThreadedAssert [ 
	^self  standardIncludesBuild.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesBuildMultiThreadedDebug [ 
	^self  standardIncludesBuild.
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> standardIncludesNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #accessing }
CPlatformConfigForSqueak >> templates [
	^ templates
]

{ #category : #accessing }
CPlatformConfigForSqueak >> templates: anObject [
	templates := anObject
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibs [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self thirdpartyLibsBuild];
		at: #buildAssert  put: [self thirdpartyLibsBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self thirdpartyLibsBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self thirdpartyLibsBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self thirdpartyLibsBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self thirdpartyLibsBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self thirdpartyLibsBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self thirdpartyLibsBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self thirdpartyLibsBuildMultiThreadedDebug ];
		at: #buildNone put:[self thirdpartyLibsBuildNone].
	^(d at: buildType) value

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuild [ 
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'

	do nothing is an option
	"
	self subclassResponsibility

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildAssert [ 
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'
"
	^ self thirdpartyLibsBuild

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildAssertITimerHeartbeat [ 
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'
"
	^ self thirdpartyLibsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildDebug [ 
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'
"
	^ self thirdpartyLibsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildDebugITimerHeartbeat [ 
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'
"
	^ self thirdpartyLibsBuild

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildITimerHeartbeat [ 
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'
"
	^ self thirdpartyLibsBuild

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildMultiThreaded [ 
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'
"
	^ self thirdpartyLibsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildMultiThreadedAssert [
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'
"
	^ self thirdpartyLibsBuild

]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildMultiThreadedDebug [ 
	"convenience method to customize third party libs for this buildType.  

	SystemNavigation default browseMethodsWhoseNamesContain: 'addThirdpartyLibrary:'

	SystemNavigation default browseMethodsWhoseNamesContain: 'processThirdpartyLibraries'	

	SystemNavigation default browseMethodsWhoseNamesContain: 'thirdpartyLibs'
"
	^ self thirdpartyLibsBuild
]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> thirdpartyLibsBuildNoBuildType [
	"SHOULD NOT GET HERE"
	self shouldNotImplement.

]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> topDir [
	^ topDir ifNil: [ topDir := FileDirectory default directoryNamed: self oscogvm ]
	
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> unixPlatformName [

	^'unix'
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> validateSourcesPresent [
	| sources |
	sources := Smalltalk sourcesName.
	
	(sources == nil)
		ifTrue: [	self error: 'VM source code cannot be generated without .sources file'.]		
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> version [
	^ ''
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> vmCogExecutableName [

	^'cog'
]

{ #category : #plugins }
CPlatformConfigForSqueak >> vmDrivers [
"SystemNavigation default browseMethodsWhoseNamesContain: 'vmDrivers'
"
	self subclassResponsibility
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> vmIShouldNotBeHereExecutableName [

	^'IShouldNotBeHere'
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> vmSistaExecutableName [

	^'sista'
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> vmStackExecutableName [

	^'squeak'
]

{ #category : #accessing }
CPlatformConfigForSqueak >> vmplugins [
	^vmplugins
]

{ #category : #'cmake executable names' }
CPlatformConfigForSqueak >> win32PlatformName [
	^'win32'
]

{ #category : #'squeak compatability' }
CPlatformConfigForSqueak >> write: aContents toFile: aFileName [
	"write a file to current output directory (buildDir).
	use line end convention appropriate for config platform"
	| bldDir |
	bldDir := self buildDir.
	bldDir isString
		ifTrue: [ bldDir := FileDirectory directoryEntryFor: bldDir ].
	bldDir assureExistence.
	bldDir
		forceNewFileNamed: aFileName
		do: [:s | s
				nextPutAll: (self fixLineEndsOf: aContents)]


]

{ #category : #'cmake buildType redirects' }
CPlatformConfigForSqueak >> x [
	"Route this message send to the message appropriate for my buildType "
	|d |
	d:= SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo copy.
	d 
		at: #build put: [self xBuild];
		at: #buildAssert  put: [self xBuildAssert];
		at: #buildAssertITimerHeartbeat  put: [self xBuildAssertITimerHeartbeat];
            at:#buildDebug  put: [self xBuildDebug];   
		at: #buildDebugITimerHeartbeat  put: [self xBuildDebugITimerHeartbeat ];
		at: #buildITimerHeartbeat  put: [self xBuildITimerHeartbeat];
		at: #buildMultiThreaded  put: [self xBuildMultiThreaded];
		at: #buildMultiThreadedAssert  put: [self xBuildMultiThreadedAssert];
		at: #buildMultiThreadedDebug   put: [self xBuildMultiThreadedDebug ];
		at: #buildNone put:[self xNoBuildType].
	^(d at: buildType) value
]
