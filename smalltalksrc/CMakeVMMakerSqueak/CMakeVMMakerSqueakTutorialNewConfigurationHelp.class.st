"
A CMakeVMMakerSqueakNewConfigurationStepByStepHelp itemizes the steps needed to create a new build configuration.

HelpBrowser openOn: CMakeVMMakerSqueakNewConfigurationStepByStepHelp
"
Class {
	#name : #CMakeVMMakerSqueakTutorialNewConfigurationHelp,
	#superclass : #CMakeVMMakerSqueakTutorialsHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> addVMPlugins [
	^HelpTopic
		title:'addVMPlugins'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

addVMPlugins depends on custom configuration provided in our Configuration; the method depends on three other methods as described below 

VMPlugins are similar to built-in plugins yet are critical for running squeak on particular systems. 

The CMake configuration data needed for building them is encapsulated in sublcasses of CMakeVMPlugin.

CMakeVMPlugin browseHierarchy

You see that they are predominantly display and sound drivers.

The process of customization ''starts'' in the initialze method of CPlatformConfigForSqueak

ToolSet browse: CPlatformConfigForSqueak selector: #initialize

In CPlatformConfigForSqueak>>initializeVMDrivers an OrderedCollection of CMakeVMPlugin subclasses are initialzed and stored. This collection is the universe of possible vm plugins.

In our custom Configuration, we need a subset of that universe.  The CPlatformConfigForSqueak>>customizeVMDrivers forces this with a ''self subclassResponsibility''

In our  new Configuration we have this method already as we copied from an existing Configuration

ToolSet browse: Linux64x86w32BitConfigUsrLib selector: #customizeVMPlugins

We see that the code selects specific vm plugin templates from the universe of available ones and then customizes each one.

Taking Linux64x86w32BitConfigUsrLib>>customizeCMakeVMDisplayNull as an example...

ToolSet browse: Linux64x86w32BitConfigUsrLib selector: #customizeCMakeVMDisplayNull

We see that we set the sources, compiler definitions, flags, external libraries, linker flags and include directories needed to compile the vm plugin here.

So, if we have trouble with a vm plugin, we need to look in its customzeCMakeVMXYZ  method and fix it there.

These configurations are extracted from our Configuration and written out to that vm plugins directory and placed in its CMakeLists.txt file.

Here is an example of the CMakeLists.txt file for the vm-display-null plugin

bash-4.2$ cat oscogvm/cmake.build.linux64x86w32BitCompatibility/squeak.cog.v3/build/vm-display-null/CMakeLists.txt 
# This is automatically generated file using Linux64x86w32BitSqueakCogSpurConfig on 1 May 2016 8:40:02.153261 am
  project (vm-display-null)
  cmake_minimum_required(VERSION 2.8.12)
  include (/home/wm/usr/src/smalltalk/CMake.oscog/cogspurVMMaker/oscogvm/cmake.build.linux64x86w32BitCompatibility/squeak.cog.v3/build/directories.cmake)
  add_definitions(-DNDEBUG -DDEBUGVM=0  -DLSB_FIRST=1 -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64 -DCOGMTVM=0)
  add_definitions(-w -m32 -msse2 -O1)
  add_definitions(-fPIC -DPIC)
  set(sources ${targetPlatform}/vm-display-null/sqUnixDisplayNull)
  add_library(vm-display-null  SHARED   ${sources})
  include_directories(  ${crossDir}/plugins/FilePlugin ${targetPlatform}/plugins/B3DAcceleratorPlugin ${crossDir}/plugins/B3DAcceleratorPlugin)
  set(LIBRARY_OUTPUT_PATH "/home/wm/usr/src/smalltalk/CMake.oscog/cogspurVMMaker/oscogvm/cmake.products/squeak.cog.v3")
  target_link_libraries(vm-display-null  ${LINKLIBS})
  set_target_properties(vm-display-null PROPERTIES PREFIX ""  SUFFIX ""  LINK_FLAGS "-w -m32 -msse2 -O1")


To modify the above output, we modify our Configuration''s customizeCMakeVMXyz methods . 
To add or remove a vm-plugin from our configuration, we edit the customizeVMPlugins method.
To expand the universe of available vm plugins, we modify the CMakeConfigForSqueak >>initializeVMDrivers method.


'
]

{ #category : #accessing }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> bookName [ 
	^'Tutorial: New Configuration'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> builderConfigurationInteraction [
	^HelpTopic
		title:'Builder Configuration Interaction'
		contents:
'Within the broad terms of this tutorial, you are here: 
4. Interaction of the Builder and your Configuration

I can query  the Builder for  information about its Configurations:

SqueakLinux64x86w32CompatBuilder  availableBuildConfigurations
  a SortedCollection(#Linux64x86w32BitSqueakCogV3Config)   <--A Cog V3 configuration exists. 

SqueakLinux64x86w32CompatBuilder  unAvailableBuildConfigurations 
--> a SortedCollection(#Linux64x86w32BitConfigUsrLib #Linux64x86w32BitConfigUsrLib32)
These two Configurations are platform specific Abstract Base Classes. Abstract Base Classes cannot be built, hence they are unavailable.

The Bulder can query Configurations about input and output directory paths it uses and/or creates:

SqueakLinux64x86w32CompatBuilder  buildDirectory 
-->''cmake.build.linux64x86w32BitCompatibility''                     <--this matches my platform

'


]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> cPlatformConfigForSqueak [
	"This method was automatically generated. Edit it using:"
	"a HelpBrowser edit: #cPlatformConfigForSqueak"
	^HelpTopic
		title: 'CPlatformConfigForSqueak'
		contents: 
'Within the broad outline of this tutorial, you are here: 
7. Some high level classes and concepts
	7.a  CPlatformConfigForSqueak

CPlatformConfForSqueak encapsulates CMake constructs.
CPlatformConfForSqueak encapsulates CMake constructs that are common to all computer platforms. 

Its child classes progressively specialized CMake constructs.


CPlatformConfigForSqueak browseHierarchy

The immediate children of CPlatformConfigForSqueak

SqueakMacintoshConfig 
SqueakUnixConfig
SqueakWindowsConfig

begin the specialization required for the Macintiosh , Unix and Windows machines. Adding a new platform, say VAX, is as easy as
CPlatformConfigForSqueak subclass:#SqueakVAXConfig and configure its relevant data/methods for that platform.

An example of Configuration customization at the platform level is in the executableType method.

SystemNavigation default browseMethodsWhoseNamesContain: ''executableType''

Here, we see that CPlatformConfForSqueak requires that a subclass implement it. The other subclasses may impliment it with an appropriate return value.

Configurations are further refined as we proceed down the heirarchy. 

SqueakMacOSX32x86Config browseHierarchy

Here we see a (stub) configuration for Mac OSX32 on the x86 processor. 

Our new Linux64x86w32BitSqueakCogSpurConfig configuration fits into its expected place under the Unix hierarchy.

Linux64x86w32BitSqueakCogSpurConfig browseHierarchy

The key and art of customizing our Linux64x86w32BitSqueakCogSpurConfig is to customize our Configuration at the appropriate level. 
Higher levels should provide existing, appropriate configuration. Our job is to then implement and customize at the finest level of customization.

To understand the how and why of customizing a Configuration, we turn to the heavily implemented design pattern I call the "Method Redirect Pattern".

We cover that next.


N.B. The ''Squeak'' prefix is unfortunate as it violates the naming convention. It is a holdover from initial attempts with the Pharo CMakeVMMaker code base.
I will attempt to remember to rename these after the Pharo dependency is removed.



CPlatformConfigForSqueak is a child of CPlatformConfig, the root Configuration in Pharo''''s CMakeVMMaker. 

This is temporary as I have decided to de-couple CMakeVMMakerSqueak from CMakeVMMaker.

ToolSet browseMessageCategory:''cmake'' inClass: CPlatformConfigForSqueak!' readStream nextChunkText
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> cPlatformConfigForSqueakInitialize [
	^HelpTopic
		title: 'Configuration Initialization'
		contents: 
'Within the broad outline of this tutorial, you are here: 
	8. Customizing your Configuration.


	ToolSet browse: CPlatformConfigForSqueak selector: #initialize
	
The relevant section is..

	self 
		initializePlatformSources;
		initializeVMPlugins;
		customizeVMPlugins.
			
We will take each in turn.	
'



]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> cmakeAddDefinitions [
	^HelpTopic
		title:'cmakeAddDefinitions'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.


SystemNavigation browseAllImplementorsOf: #cmakeAddDefinitions

We see that the CPlatformConfigForSqueak routes the method based on the buildType #build via the Method Redirect pattern to cmakeAddDefinitionsBuild

SystemNavigation browseAllImplementorsOf: #cmakeAddDefinitionsBuild

We see that our Linux64x86w32BitSqueakCogSpurConfig already implements it due to our copying of an existing configuration.

We need to modify this for our Configuration. The current method (minus commented out elements) reads as:

	definitions:=#(
	 ''-DNDEBUG''          
 	 ''-DDEBUGVM=0''
	 '' -DLSB_FIRST=1''
	 ''-D_GNU_SOURCE''
 	 ''-D_FILE_OFFSET_BITS=64''
 	 ''-DCOGMTVM=0'') . 

Like the cmakeCFlags method, we look at the mvm file 

cat ~/.../Cog/build.linux32x86/squeak.cog.spur/build/mvm

And see the 
3.4.*)  OPT=''-g -O1 -fwrapv -DNDEBUG -DDEBUGVM=o'';;
*)              OPT=''-g -O2 -DNDEBUG -DDEBUGVM=0'';;

lines and the 

CFLAGS=''$OPT -msse2 -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64 -DCOGMTVM=0'' \

Based on these mvm file details, I modify the method to read as such:

	definitions:=#(
	 ''-DNDEBUG''          
 	 ''-DDEBUGVM=0''
	 ''-D_GNU_SOURCE''
 	 ''-D_FILE_OFFSET_BITS=64''
 	 ''-DCOGMTVM=0'') .

To match the directives specified in the mvm file

'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> cmakeAddExecutableNameOptionSource [
	^HelpTopic
		title:'cmakeAddExecutableNameOptionSource:'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

SystemNavigation browseAllImplementorsOf: #cmakeAddExecutableNameOptionSource:

We see this is a top-level method implemented only by CPlatformConfigForSqueak

The method creates a new CMakeAddExecutableNameOptionSource template 

CMakeAddExecutableNameOptionSource browse

and the class comment says it "Add an executable to the project using the specified source files."

To get a sense of the CMake output print the following:

((CMakeAddExecutableNameOptionSource new)
			executableName: ''cog''
			optionalproperty: ''''
			sources: (OrderedCollection with: ''${coreSources} ${crossVMSources} ${platformVMSources} ${extraSources}'')) content

In looking at this, the exectuableName worries me.  I am not sure that ''cog'' is what we want.

Looking at it...
SystemNavigation browseAllImplementorsOf: #executableName

it is something we can customize or code if we need.

'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> cmakeCFlags [
	^HelpTopic
		title:'cmakeCFlags'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.


SystemNavigation browseAllImplementorsOf: #cmakeCFlags

We see that  CPlatformConfigForSqueak implements it

The method comment reads in part:

''self deprecated: this catchall method has been split into dedicated methods: cmakePrefixPath cmakeIncludePath 	cmakeLibraryPath	cmakeIncludeModules;    cmakeCFlags;      ...''


And that this method will be refactored out of existence ''soon''.

Looking at it, we see that the method  implements the Method Redirect pattern 

Since we have configured for buildType: #build, the Method Redirect Pattern will invoke the  cmakeCFlagsBuild method.

So we look at the implementors of it..

SystemNavigation browseAllImplementorsOf: #cmakeCFlagsBuild

Here we see that our new Linux64x86w32BitSqueakCogSpurConfig configuration implements it (since we copied an existing Configuration that implemented it)

We now have something to customize.

We look at the line: cflags:= String streamContents: [:stream | (self compilerFlags) asStringOn: stream delimiter: '' '' ]. 

and see that our ''self compilerFlags'' method is used.

SystemNavigation browseAllImplementorsOf: #compilerFlags

These are flags to pass to the compiler. Take a look at the mwm file in the GNU config

cat ~/.../Cog/build.linux32x86/squeak.cog.spur/build/mvm

We see an OPT variable being populated...


	OPT=''-g -O1 -fwrapv -DNDEBUG -DDEBUGVM=0'';;
	OPT=''-g -O2 -DNDEBUG -DDEBUGVM=0'';;
esac

And later in the file we see the CFLAGS variable being populated with the $OPT variable and some other flags.

	CC=''gcc -m32'' \
	CXX=''g++ -m32'' \
	CFLAGS=''$OPT -msse2 -D_GNU_SOURCE -D_FILE_OFFSET_BITS=64 -DCOGMTVM=0'' \
	LIBS=''-lpthread -luuid'' \
	LDFLAGS=-Wl,-z,now

That CFLAGS variable is what we are mimicing here. with some caveats...

The pharo code just dumped all that stuff into one method, whereas I split them up.

We are ommitting the Compiler defines like -D_GNU_SOURCE  as we will be setting those in cmakeAddDefinitions.

My current compilerFlags (minus commented out elements) method reads like this:

compilerFlags
	^#(	''-w''
		''-m32''
		''-msse2''
		''-O1'') 


checking my compiler version 
bash-4.2$ gcc --version
gcc (GCC) 4.8.2
Copyright (C) 2013 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

I see I need some options from the    OPT=''-g -O1 -fwrapv -DNDEBUG -DDEBUGVM=0'' line
 line 


Mimicing the mvm file, I modify it to read as such:

compilerFlags
	^#(''-g''
	     ''-O1''
	     ''-fwrapv''
	     ''-m32''
	     ''-msse2''
	) 

In doing this, I am congizant that I may have to return to this method as I fiddle around getting this configuration correct.

'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> cmakeIncludeDirectories [
	^HelpTopic
		title:'cmakeIncludeDirectories'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.


SystemNavigation browseAllImplementorsOf: #cmakeIncludeDirectories:

We see that the sole implementor of the method is the top level configuration CPlatformConfigForSqueak

The method creates an instance of the CMakeTemplate CMakeIncludeDirectories

CMakeIncludeDirectories browse

where the class comment tells us that it tells CMake to add extra ''include'' directories to the build.

Currently a variable placeholder is hard-coded in CMakeVMGeneratorForSqueak>>includeDirs
You can print the following to see them:
(CMakeVMGeneratorForSqueak new) includeDirs

And the generated CMake by printing the following:

((CMakeIncludeDirectories new) dirs: (OrderedCollection with: (CMakeVMGeneratorForSqueak new) includeDirs)) content 

What you see when you print it are variable placeholders that CMake will populate with the value of CMake variables  ${crossDir}
, ${srcVMDir} and ${targetPlatform} that we will be defining or have already been defined in our configuration.

This is truly a global method and would only change if Eliot changed the layout of the underlying build structure.
'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> cmakeIncludeModules [
	^HelpTopic
		title:'cmakeIncludeModules'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.


CMake allows the user to include custom CMake library files (modules).  
This construct allows the developer to include those modules.

cmakeIncludeModules implements the Method Redirect pattern.

ToolSet browse: CPlatformConfigForSqueak selector: #cmakeIncludeModules

Since the configuration is configured for buildType: #build the method redirect pattern will redirect to

SystemNavigation browseAllImplementorsOf: #cmakeIncludeModulesBuild.

We see in CPlatformConfigForSqueak that a sublcass must implement it via ''self subclassResponsibility''.

We see that (as of this writing) the SqueakUnixConfig handles the method by including some custom modules
Utils.cmake
Plugins.cmake
TestBigEndian
CheckIncludeFile
CheckLibraryExists
CheckTypeSize
CheckFunctionExists
CheckVariableExists
CheckStructHasMember
FindPkgConfig

These Module wrap CMake constructs and can be thought of as CMake ''include files''. and they are implemented high in the Configuration platform hierarchy.

Our new Configuration need not override anything here.

Let''s move on...'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> cmakeIncludePath [
	^HelpTopic
		title:'cmakeIncludePath'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.


cmakeIncludePath implements the Method Redirect pattern.

ToolSet browse: CPlatformConfigForSqueak selector: #cmakeIncludePath

Since the configuration is configured for buildType: #build the method redirect pattern will redirect to

SystemNavigation browseAllImplementorsOf: #cmakeIncludePathBuild

We see in CPlatformConfigForSqueak that a sublcass must implement it via ''self subclassResponsibility''.

We see that (as of this writing) the SqueakUnixConfig handles the method, but only for debug messages.

There is a possibility a  sub-platform will have include files in a non-standard directories and a specific Configuration
will have to implement this to generate appropriate CMake output. 

At this moment, we conclude we don''t need to. 

Since I am writing this help in tandem with generating a new Configuration, there is the possibility I am wrong and that I will need this.

Since I don''t know for a fact that it is, I leave it alone for now.'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> cmakeLibraryPath [
	^HelpTopic
		title:'cmakeLibraryPath'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

cmakeLibraryPath implements the Method Redirect pattern.

ToolSet browse: CPlatformConfigForSqueak selector: #cmakeLibraryPath

Since the configuration is configured for buildType: #build the method redirect pattern will redirect to

SystemNavigation browseAllImplementorsOf: #cmakeLibraryPathBuild.

We see in CPlatformConfigForSqueak that a sublcass must implement it via ''self subclassResponsibility''.

We see that (as of this writing) the SqueakUnixConfig handles the method, but only for debug messages.

There is a possibility a  sub-platform will have libraries in a non-standard directories and a specific Configuration
will have to implement this to generate appropriate CMake output. 

At this moment, we conclude we don''t need to. 

Since I am writing this help in tandem with generating a new Configuration, there is the possibility I am wrong and that I will need this.

Since I don''t know for a fact that it is, I leave it alone for now.
'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> cmakeListAppend:LINKLIBSelements [
	^HelpTopic
		title:'cmakeListAppend:LINKLIBSelements'
		contents:
'
'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> cmakeListAppendLINKLIBSelements [
	^HelpTopic
		title:'cmakeListAppendLINKLIBSelements'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

SystemNavigation browseAllImplementorsOf: #cmakeListAppend:elements:

We see this is a top-level method.

The method creates a new CMakeListAppend which according to the class comment ''I handle the APPEND functionality for the cmake list commmand.''.

Here we are appending libraries to link to the list LINKLIBS.

You can get a sense of the CMake output by evaluating.

((CMakeListAppend new) list:''LINKLIBS'' elements:#((''-L/usr/lib'' ''-L/usr/lib/X11'' ''uuid'' ''ssl'' ''crypto'' ''m'' ''dl'' ''pthread'' ''SM'' ''ICE'' ''GL'' ''X11'' ''nsl''))) content

The list of libraries is available via the configurations ''externalLibs'' method. 

SystemNavigation browseAllImplementorsOf: #externalLibs

Which we see implements the Method Redirect pattern.

Since this is a #build buildType we look in 

SystemNavigation browseAllImplementorsOf: #externalLibsBuild 

And we see the CPlatformConfigForSqueak subclasses responsibility and that our new Linux64x86w32BitSqueakCogSpurConfig implements it as

externalLibsBuild
	^self externalLibraries asOrderedCollection.

which is contained in its parent as

externalLibraries
	^#(
		     ''-L/usr/lib''
		     ''-L/usr/lib/X11''
		......
		etc...
	)
		
		
So, we see the ability to specify what libraries we want to link against in our configuration.

Where to do this in the Configuration heirarchy is a matter of judgement.

We will leave this one alone, bearing in mind that if we have a library linking problem, we have an idea where to look for it.		
	'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> cmakePrefixPath [
	^HelpTopic
		title:'cmakePrefixPath'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

ToolSet browse: CPlatformConfigForSqueak selector: #cmakePrefixPath

cmakePrefixPath implements the Method Redirect pattern.

Since the configuration is configured for buildType: #build the method redirect pattern will redirect to

SystemNavigation browseAllImplementorsOf: #cmakePrefixPathBuild

We see in CPlatformConfigForSqueak that a sublcass must implement it via ''self subclassResponsibility''.

We see that (as of this writing) the SqueakUnixConfig handles the method.

We reason that this method generates  platform specific CMake output and our lower-level Configuration need not override it.
'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> cmakeSetSourceFilesProperties [
	^HelpTopic
		title:'cmakeSetSourceFilesProperties'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

This is a legacy method from the pharo system. I expect it to be refactored.

SystemNavigation browseAllImplementorsOf: #cmakeSetSourceFilesProperties

Here we see the Method Redirect Pattern

SystemNavigation browseAllImplementorsOf: #cmakeSetSourceFilesPropertiesBuild

We see that the CPlatformConfigForSqueak subclasses responsibility (scroll down past the method comment)

We also see that our new Linux64x86w32BitSqueakCogSpurConfig Configuration implements it.

I suspect this method will be refactored upwards. It appears to be passing distinct compiler flags to the cogit.c and sqUnixHeartbeat.c.

Let''s leave this one alone.
'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> cmakeWriteDirectoriesDotCmake [
	^HelpTopic
		title:'cmakeWriteDirectoriesDotCmake'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.


SystemNavigation browseAllImplementorsOf: #cmakeWriteDirectoriesDotCmake:

Here we see that the CPlatformConfigForSqueak forces subclasses to implement this .

This method sets some CMake variables to platform specific values and writes them to a file named ''directories.cmake''

Here is the directories.cmake file contents on my platform

bash-4.2$ cat directories.cmake 
  set(topDir "/home/tty/usr/src/smalltalk/CMake.oscog/cogspurVMMaker/oscogvm")
  set(buildDir "/home/tty/usr/src/smalltalk/CMake.oscog/cogspurVMMaker/oscogvm/cmake.build.linux64x86w32BitCompatibility/squeak.cog.v3/build")
  set(thirdpartyDir "${buildDir}/thirdParty")
  set(platformsDir "/home/tty/usr/src/smalltalk/CMake.oscog/cogspurVMMaker/oscogvm/platforms")
  set(srcDir "/home/tty/usr/src/smalltalk/CMake.oscog/cogspurVMMaker/oscogvm/src")
  set(srcPluginsDir "${srcDir}/plugins")
  set(srcVMDir "${srcDir}/vm")
  set(platformName "unix")
  set(targetPlatform "${platformsDir}/${platformName}")
  set(crossDir "${platformsDir}/Cross")
  set(platformVMDir "${targetPlatform}/vm}")
  set(outputDir "/home/tty/usr/src/smalltalk/CMake.oscog/cogspurVMMaker/oscogvm/cmake.products/squeak.cog.v3")
  set(externalModulesDir "${outputDir}")

EOF

The file contains CMake ''set'' commands that bind a variable to a value. 

In this application, CMake commands are encapsulated as objects and the CMake Set command is no exception:

CMakeSet browse

Taking the set(platformName,"unix") command as an example, we see the rationale for sublcassing this construct to the platform specific subclasses.


There is nothing for us to do here, HOWEVER, we will be customizing some variables that compose this. For example:
set(srcDir "some path to a source directory") can take any of the below directory names:

nsspur64src
nsspursrc
nsspurstack64src
nsspurstacksrc
nssrc
spur64src
spursistasrc
spursrc
spurstack64src
spurstacksrc
src
stacksrc









'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> compilingLinkingSetup [
	^HelpTopic
		title:'Compiling and Linking Setup'
		contents:
'In your concrete configuration''s ''compiling'' protocol contains the methods that you must customize for your Configuration

cmakeAddDefinitionsBuild
cmakeCFlagsBuild
externalLibsBuild
linkerFlags


'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> configGenerateByTemplate [
	^HelpTopic
		title:'Config Generate By Template'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

A Configuration starts generating CMakeOutput when a Builder sends it the #generateByTemplate message.

ToolSet browse: SqueakCMakeVMMakerAbstractBuilder selector:#generateByTemplate
 see the ''ifFalse:[config genrateByTemplate]] '' line.

SystemNavigation browseAllImplementorsOf: #generateByTemplate

Looking at the SqueakUnixConfig>>generateByTemplate we see the Configuration writes some CMake supporting files via some method calls

		generatePluginsList;                                      
		generateLicense;                                          
		generateUtilsCmake;                                       
		generatePluginsCmake;                                   
		generateVmBuildCmake;                                  
		generateVmConfigCmake;                               
		generateVmConfigIn;                                  
		generateTestDoubleWordAlignmentC;             
		generateTestDoubleWordOrderC;
		generateTestLanginfoCodesetC.

Each of the above writes a file to the build directory.  The contents of which are hard-coded on the class side of the CPlatformConfigForSqueak

For example the class method CPlatformConfigForSqueak>utilsCMake has some CMake Macros Ian wrote.

ToolSet browse: (CPlatformConfigForSqueak class) selector: #utilsCMake

This is high level stuff. It will probably be refactored once the CMake system matures.

For now, its enough to know it exists.

Looking at the SqueakWindowsConfig and SqueakMacintoshConfig in their generateByTemplate method, these calls do not (presently) exist.

ToolSet browse: SqueakWindowsConfig  selector: #generateByTemplate
ToolSet browse: SqueakMacintoshConfig  selector: #generateByTemplate

While you probably will not be modifying this, this IS part of customizating a Configuration should you need these things

'

]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> configureAbstractBaseClass [
	^HelpTopic
		title:'Configure Abstract Base Class'
		contents:
'Abstract Base Classes contain configuration information for a specific platform.

Let''s start from the top and work are way down. evaluate:

CPlatformConfigForSqueak browseHierarchy

CPlatformConfigForSqueak is a fairly involved class, but focusing on the protocol ''cmake directory'' for now, we see a bunch of dirFOO methods.

selectinng: 

CPlatformConfigForSqueak >>dirLinux32x86
	^''cmake.build.linux32x86'' 

We see the top-level directory for our new platform specific build. 

The next level down in our hierarchy is SqueakUnixConfig which contains configuration info specific to Unix platforms. An example being: 

SqueakUnixConfig>>platformName
	^self unixPlatformName


The next level down is our Abstract Base Class for our specific variant of Unix--specifically Linux32x86Config.

The methods in this class contain system wide configuratin information for this Platform. On a mature platform tree, this class''s configuration should be rock-solid. However, as of 2014.12.09, the Abstract Base Class has not been configured correctly and I must set it up here. 

Setting it up is not difficult and an existing Abstract Base Class can provide a good starting point. However, a familiarity with the design patterns of the Configurations is helpful (particularly the Redirect Method pattern)

HelpBrowser openOn: CMakeVMMakerSqueakDesignPatternsHelp




'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> createTheConfiguration [
	^HelpTopic
		title:'Create the Configuration'
		contents:
'Within the broad outline of this tutorial, you are here: 
4. Create your Configuration

Our new Concrete Configuration must be created as a subclass of our Platform''s Abstract Base Class.

SInce I am creating a Squeak Cog Spur config for the CMakeVMMakerSqueak-Linux64X86-32BitCompatibility Platform I choose the name*:

Linux64x86w32BitSqueakCogSpurConfig.


To create it, I must subclass the Abstract Base Class for my Platform like so:

Linux64x86w32BitConfigUsrLib subclass: #Linux64x86w32BitSqueakCogSpurConfig
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: ''CMakeVMMakerSqueak-Linux64X86-32BitCompatibility''

However, being lazy, I am going to copy an existing Configuration that is similar to what I want. 

Today I choose Linux64x86w32BitSqueakCogV3Config from the  CMakeVMMakerSqueak-Linux64X86-32BitCompatibility Platform category

I copy the class and then change its name, parent and class category to get:

Linux64x86w32BitConfigUsrLib subclass: #Linux64x86w32BitSqueakCogSpurConfig
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: ''CMakeVMMakerSqueak-Linux64X86-32BitCompatibility''


I then query by Builder to see if it sees the new Configuration in the platform:

SqueakLinux64x86w32CompatBuilder configurationsCategory
-->  ''CMakeVMMakerSqueak-Linux64X86-32BitCompatibility''

SqueakLinux64x86w32CompatBuilder  availableBuildConfigurations  
-->  a SortedCollection(#Linux64x86w32BitSqueakCogSpurConfig #Linux64x86w32BitSqueakCogV3Config)
   "Here we see our new Configuration is visible to the Builder"

SqueakLinux64x86w32CompatBuilder  unAvailableBuildConfigurations
-->  a SortedCollection(#Linux64x86w32BitConfigUsrLib #Linux64x86w32BitConfigUsrLib32)  "Our Abstract Base Classes are not available to be built"

SqueakLinux64x86w32CompatBuilder availableBuildTypesFor: #Linux64x86w32BitSqueakCogSpurConfig
--> an OrderedCollection(#build #buildAssert) "The Configuration I copied has two Build Types coded and available."


SqueakLinux64x86w32CompatBuilder  sourceDirectoryFor:#Linux64x86w32BitSqueakCogSpurConfig
-->  "src"                                                        "Where the vm source code is located (we will be changing this)"

My new configuration is correctly named and in the correct place. 

At this point I re-run all my Tests.
TestRunner open
 For me, all tests pass.

In the next topic we cover how to hide our new Configuration from a builder. 

*For a discussion on naming conventions evaluate:
HelpBrowser openOn: CMakeVMMakerSqueakOverviewHelp


'

]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> customizePlatformSources [
	"This method was automatically generated. Edit it using:"
	"a HelpBrowser edit: #customizePlatformSources"
	^HelpTopic
		title: 'Customize Platform Sources'
		contents: 
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

In the previous topic we saw where the universe of possible platform sources was populated in the initializePlatformSources method of our platform level Configuration.

What we need to do now is have our custom Configuration return a subset of that that universe.

This is done in the setPlatformSources method.

ToolSet browse: CPlatformConfigForSqueak selector: #setPlatformSources:

Here we see the Method Redirect Pattern. Since I am building my Configuration for the buildType build, I must override that method

SystemNavigation browseAllImplementorsOf: #setPlatformSourcesBuild:

Here we see that the Linux64x86w32BitSqueakCogV3Config selects a subset of the available platform sources that it needs to build itself.
The super call at the end of the method invokes Linux64x86w32BitSqueakCogV3Config>>setPlatformSourcesBuild:aMaker which writes the actual CMake output.

If you compare the 

Linux64x86w32BitSqueakCogV3Config>>setPlatformSourcesBuild: aMaker method

 to

the Linux64x86w32BitSqueakCogSpurConfig>>setPlatformSourcesBuild: aMaker 

you will see that the latter has an additional source file 	''sqUnixSpurMemory.c'' . 
	
That difference is a good example of what customizing platform sources means. 

!' readStream nextChunkText
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> customizePlugins [
	^HelpTopic
		title:'customize Plugins'
		contents:
'We can customize which plugins we want on our configuration by overriding our platform''s defaultExternalPlugins and defaultInternalPlugins methods.

The default set can be further customized according to buildType if desired via the externalPlugins[BuildType] and internalPlugins[BuildType] redirect pattern


'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> customizeVMPlugins [
	^HelpTopic
		title:'Customize VM Plugins'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

As we saw in the previous page the CPlatformConfigForSqueak maintains a list of the available VM plugins in the form of ''data-bucket'' objects.

Since every configuration does not use every VM plugin, our configuration can  customize that master list.

It can do this in one of two ways.

First,  We can do this by overloading the SqueakUnixConfig>>customizeVMPlugins method.. 
SystemNavigation browseAllImplementorsOf: #customizeVMPlugins
This customization occures before the buildType has been set in the Configuration. 
So this selection will be used regardless of buildType  unless.......



Second, we override the addVMPlugins[buildType] : aMaker method in our Configuration and set our vmplugins variable there similar to how we do it in this method.
SystemNavigation browseAllImplementorsOf: #addVMPluginsBuild:


It is my opinion that the selecting vm plugins based on buildType will not happen and that that those selected at the initialization change will be the default.




'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> dirBuildLanguageVMMM [
	^HelpTopic
		title:'Specify dirBuildLanguageVMMM'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

SystemNavigation new browseAllImplementorsOf: #dirBuildLanguageVMMM localTo:CPlatformConfigForSqueak.

We scroll down to our Linux64x86w32BitSqueakCogSpurConfig which we copied from the existing Linux64x86w32BitSqueakCogV3Config.

Looking at the dirBuildLanguageVMMM it initially reads (due to the copying of the existing class)

dirBuildLanguageVMMM
	^self squeakCogV3

Since this is a configuration for Squeak Cog Spur, I modify the method to return

dirBuildLanguageVMMM
	^self squeakCogSpur


As a sanity check, I verify that the method squeakCogSpur exists...

SystemNavigation new browseAllImplementorsOf: #squeakCogSpur

And we see the method exists and will return the string ''squeak.cog.spur''.

(CPlatformConfigForSqueak basicNew) squeakCogSpur


The result will be used in two places--in the build directory and the output directory relative to the directories we have specified.

The build directory at the platform level now looks like:  "oscogvm/cmake.build.linux64x86w32BitCompatibility/squeak.cog.spur/

The output directory at the platform level now looks like: "oscogvm/cmake.products/cmake.build.linux64x86w32BitCompatibility/squeak.cog.spur/




'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> dirSource [
	^HelpTopic
		title:'Specify Source Directory'
		contents:
'
Eliot''s VMMaker.oscog package outputs c-source code to varios directories depending ont he vm type.

SystemNavigation new browseAllImplementorsOf: #dirSource localTo:CPlatformConfigForSqueak.

Evaluating the above, we see that the CPlatformConfigForSqueak lists the available source directories.

The string values for these things are hard-coded in CPlatformConfigForSqueak in the ''cmake source names'' category.

ToolSet browse: CPlatformConfigForSqueak category: ''cmake source names''

For our Linux64x86w32BitSqueakCogSpurConfig we choose ''spursrc'' as our dirSource return value

dirSource
	^self spursrc

which you can test here.

(Linux64x86w32BitSqueakCogSpurConfig basicNew) dirSource

'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> excludingConfigFromBuilds [
	^HelpTopic
		title:'Excluding a Config From Builds'
		contents:
'Within the broad outline of this tutorial, you are here: 
5. Interaction of the Builder and your Configuration

Configurations can hide themselves from , or make themselves visible to Builders via their ''excludeFromBuild'' method.

excludeFromBuild
	^false   "build this configuration"
"	^true     do not build this configuration"   

In our case, the Builder shows us that Linux32x86SqueakCogSpurConfig is capable of being built (I had copied an existing, working Configuration):

SqueakLinux64x86w32CompatBuilder availableBuildConfigurations
--> a SortedCollection(#Linux64x86w32BitSqueakCogSpurConfig #Linux64x86w32BitSqueakCogV3Config)


To exclude it, override (or alter) the Configurations ''excludeFromBuild'' method

Linux64x86w32BitSqueakCogSpurConfig >>excludeFromBuild
	"over-ride to exclude yourself from a build"
	^true

And the Configuration is hidden from the Builder...

SqueakLinux64x86w32CompatBuilder availableBuildConfigurations
-->  a SortedCollection(#Linux64x86w32BitSqueakCogV3Config)


However, since I am developing locally, I need it to be visible to the Builder , so I set it as so:

Linux64x86w32BitSqueakCogSpurConfig >>excludeFromBuild
	"over-ride to exclude yourself from a build"
	^false

And my Builder can see it again...

SqueakLinux64x86w32CompatBuilder availableBuildConfigurations  
-->  a SortedCollection(#Linux64x86w32BitSqueakCogSpurConfig #Linux64x86w32BitSqueakCogV3Config)


N.B. tty. My opinion is that this is a weak way of doing this, but I have not thought through how to do this elegantly. 
This functionality is included with an eye towards easing automated builds for all platforms and configurations.'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> extraVMSettings [
	^HelpTopic
		title:'extraVMSettings'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

SystemNavigation browseAllImplementorsOf: #extraVMSettings:


In the CPlatformConfigForSqueak>>extraVMSettings: aMaker, we see the Method Redirect Pattern employed. Since this is for buildType #build, the method will re-route to self extraVMSettingsBuild:

SystemNavigation browseAllImplementorsOf: #extraVMSettingsBuild:

We see the CPLatformConfigForSqueak forces a subclass to implement it and the SqueakUnixConfig implements it.

In SqueakUnixConfig a CMakeAddCustomCommandOutput is created and initialized. 

CMakeAddCustomCommandOutput browse

The class comment says that: ''Add a custom build rule to the generated build system.''


If you  look in the file  Cog/platforms/unix/config/verstamp you see that this is (looks like) the definition/implemenation of the command CMake 
will invoke.


Currently this is a platform level method. Honestly, I have no idea why it is there. (:

For our purposes, there is nothing we need to do.
'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> fin [
	^HelpTopic
		title:'fin'
		contents:
'Within the broad outline of this tutorial, you are here: 

done!

To recap you have covered:

1. Tests
2. Where to place your new Configuration
3. What Builder to use
4. Create your Configuration
5. Interaction of the Builder and your Configuration
6. Generating a proof-of-concept CMake build tree.
7. Some high level classes and concepts
  7.a  CPlatformConfigForSqueak
  7b. The Method Redirect Pattern (a broadly used design pattern in the system)
  7c. The CMakeVMGeneratorForSqueak 
8. Customizing your Configuration.




'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> firstCMakeGeneration [
	"This method was automatically generated. Edit it using:"
	"a HelpBrowser edit: #firstCMakeGeneration"
	^HelpTopic
		title: 'First CMake Generation'
		contents: 
'Within the broad outline of this tutorial, you are here: 
6. Generating a proof-of-concept CMake build tree.

For didactic purposes I am going to do a sanity check and generate CMake code from the configuration for the first time. 

If you are not familiar with the CMakeVMMakerSqueak naming conventions, please evaluate:
HelpBrowser openOn: CMakeVMMakerSqueakOverviewHelp

On my system a copy of the Cog svn tree is located under my current working Squeak directory in the folder ''oscogvm".

It looks like this:

bash-4.2$ ls --width=1 ~/usr/src/smalltalk/CMake.oscog/cogspurVMMaker/oscogvm/
README
build
build.linux32ARM
build.linux32x86
build.linux64x64
build.macos32x86
build.macos64x64
build.win32x86
history
mkNamedPrims.sh
nsspur64src
nsspursrc
nsspurstack64src
nsspurstacksrc
nssrc
platforms
processors
products
scripts
sources
spur64src
spursistasrc
spursrc
spurstack64src
spurstacksrc
src
stacksrc

What I want to do is see if my configuration will write its output to an appropriate CMake subfolder.

To do this,  I ask the Builder to configure my new configuration for a buildType and output its contents. I do so by evaluating:

 SqueakLinux64x86w32CompatBuilder 
	configureA: #Linux32x86SqueakCogSpurConfig forBuildType:#build; 
	enableMessageTracking: true;
	generateByTemplate.


and look again 
bash-4.2$ ls --width=1 usr/src/smalltalk/CMake.oscog/cogspurVMMaker/oscogvm/
CHANGES
LICENSE
README
build
build.linux32ARM
build.linux32x86
build.linux64x64
build.macos32x86
build.macos64x64
build.win32x86
cmake.build.linux64x86w32BitCompatibility  <--Here is the directory created by my configuration. 
history
....

Above we see that a new cmake.build.linux64x86w32BitCompatibility   directory has been created. Let''s look at its contents

 tree -d  ~/usr/src/smalltalk/CMake.oscog/cogspurVMMaker/oscogvm/cmake.build.linux64x86w32BitCompatibility/
`-- squeak.cog.v3                                               <--We will be changing this later as we want a squeak.cog.spur directory, not a V3 directory
    `-- build                                                         <--our build type is #build
        |-- ADPCMCodecPlugin
        |-- AsynchFilePlugin
        |-- B2DPlugin
        |-- BMPReadWriterPlugin
        |-- BitBltPlugin
        |-- CroquetPlugin
        |-- DSAPrims
        |-- DropPlugin
        |-- FFTPlugin
        |-- FileCopyPlugin
        |-- FilePlugin
        |-- FloatArrayPlugin
        |-- FloatMathPlugin
        |-- JoystickTabletPlugin
        |-- Klatt
        |-- LargeIntegers
        |-- LocalePlugin
        |-- MIDIPlugin
        |-- Matrix2x3Plugin
        |-- MiscPrimitivePlugin
        |-- Mpeg3Plugin
        |-- SecurityPlugin
        |-- SerialPlugin
        |-- SocketPlugin
        |-- SoundCodecPrims
        |-- SoundGenerationPlugin
        |-- SoundPlugin
        |-- StarSqueakPlugin
        |-- SurfacePlugin
        |-- ZipPlugin
        |-- vm-display-X11
        |-- vm-display-null
        |-- vm-sound-ALSA
        `-- vm-sound-null

...etc
We see that the configuration has output a CMake build tree and we have done a sanity check. 

Next we take stock of what we have accomplished and preview the remaining tasks.

!' readStream nextChunkText
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> generateBuildScript [
	^HelpTopic
		title:'Generate Build Script'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

ToolSet browse: CPlatformConfigForSqueak selector: buildScript

This generates a bash shell script that can be used in place of manuallinvoking cmake and make.



'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> generatePluginConfigs [
	^HelpTopic
		title:'generatePluginConfigs'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

This method iterates over a collection of InterpreterPlugin subclasses and asks each class to populate itself with some basic information and write out its own CMakeLists.txt in a directory named after the plugin name.

The processing is a bit complicated, but the setup is easy.

The collections of  plugin classes are stored in our Configuration. We cover that next in Specifying Plugins'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> identifyBuilder [
	^HelpTopic
		title:'Identify Builder'
		contents:
'Within the broad outline of this tutorial, you are here: 
3. What Builder to use

My new Configuration will be managed by a Builder.

Builders are located in the CMakeVMMakerSqueak-Builder class category.

Builders are subclasses of SqueakCMakeVMMakerAbstractBuilder.
SqueakCMakeVMMakerAbstractBuilder browseHierarchy

Builders are named* according to the Platform they manage.

Builders manage configurations for one Platform in one  class category.

My platform is Linux Linux64x86 with 32 bit compatability libs stored in /usr/lib (other linux use /usr/lib32 for this.)

I suspect that the  SqueakLinux64x86w32CompatBuilder as the Builder that will manage my new configuration.

I confirm this by sending it the ''configurationsCategory'' message as shown below:

SqueakLinux64x86w32CompatBuilder configurationsCategory 
-->''CMakeVMMakerSqueak-Linux64X86-32BitCompatibility''                    <---this is the correct class category for my Platform.

This is correct Builder for my new Configuration. 

I can query  the Builder for some more information:

SqueakLinux64x86w32CompatBuilder  availableBuildConfigurations
  a SortedCollection(#Linux64x86w32BitSqueakCogV3Config)   <--A Cog V3 configuration exists. 

SqueakLinux64x86w32CompatBuilder  unAvailableBuildConfigurations 
--> a SortedCollection(#Linux64x86w32BitConfigUsrLib #Linux64x86w32BitConfigUsrLib32)
 <--these are platform specific Abstract Base Classes. Abstract Base Classes cannot be built, hence they are unavailable.



We will be using the SqueakLinux64x86w32CompatBuilder in tandem with Tests during Configuration development.

*For a discussion on naming conventions evaluate:
HelpBrowser openOn: CMakeVMMakerSqueakOverviewHelp

'


]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> identifyPlatform [
	^HelpTopic
		title:'Identify Platform'
		contents:
' Within the broad outline of this tutorial, you are here: 
2. Where to place your new Configuration

My target platform is 64 bit Linux on X86 with 32 bit compatibility libraries stored in /usr/lib.

I identify my Platform in the existing CMakeVMMakerSqueak-xyz class categories.  

As of 2016.06.19 the class categories that correspond to target platforms are:

CMakeVMMakerSqueak-IA32-Bochs
CMakeVMMakerSqueak-IOS
CMakeVMMakerSqueak-Linux32ARMv6
CMakeVMMakerSqueak-Linux32x86
CMakeVMMakerSqueak-Linux64X86-32BitCompatibility
CMakeVMMakerSqueak-Linux64x64
CMakeVMMakerSqueak-MacOSPowerPC
CMakeVMMakerSqueak-MacOSX32x86
CMakeVMMakerSqueak-SunOS32x86
CMakeVMMakerSqueak-Win32x86



If I wanted a configuration for MacOSX32x86, I would place my configuration in CMakeVMMakerSqueak-MacOSX32x86.
If SunOSx3x86 then CMakeVMMakerSqueak-SunOS32x86.
etc.

Sincy my target platform is 64 bit Linux on X86 with 32 bit compatibility libraries stored in /usr/lib. I choose
the class category CMakeVMMakerSqueak-Linux64X86-32BitCompatibility to contain my new configurartion

For a discussion on naming conventions evaluate:
HelpBrowser openOn: CMakeVMMakerSqueakOverviewHelp
'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> identifyPlatformAbstractBaseClass [
	^HelpTopic
		title:'Identify Abstract Base Class '
		contents:
'Within the broad outline of this tutorial, you are here: 
2. Where to place your new Configuration

My new configuration must be a subclass of my Platform''s Abstract Base Class. 

A Platform Abstract Base Class encapsulates common platform information. 

In CMakeVMMakerSqueak-Linux64X86-32BitCompatibility class category I see two Abstract Base Classes (typically there is only one). They are:

Linux64x86w32BitConfigUsrLib 
Linux64x86w32BitConfigUsrLib32

The Suffixes ''UsrLib'' and ''UsrLib32'' refer to the location of the 32 bit compatablity libs. 
Some systems (Ubuntu?) place their 32 bit compatability libs in /usr/lib32. 
On my system (Slackware) they are in /usr/lib,  so I choose  Linux64x86w32BitConfigUsrLib as my Abstract Base Class

Examples of Abstract Base Classes in other class categories  include:

CMakeVMMakerSqueak-BSD32x86                                -> SqueakBSD32x86Config
CMakeVMMakerSqueak-IA32-Bochs                               -> SqueakIA32BochsConfig
CMakeVMMakerSqueak-IOS                                           -> SqueakIOSConfig
CMakeVMMakerSqueak-IOS                                           -> SqueakIOSConfig
CMakeVMMakerSqueak-Linux32ARMv6                          -> Linux32ARMv6Config
CMakeVMMakerSqueak-Linux64x64                              -> Linux64x64Config
CMakeVMMakerSqueak-MacOSPowerPC                        -> SqueakMacOSXPowerPCConfig
CMakeVMMakerSqueak-MacOSX32x86                          -> SqueakMacOSX32x86Config
CMakeVMMakerSqueak-SunOS32x86                            -> SqueakSunOS32x86Config
CMakeVMMakerSqueak-Win32x86                                 -> SqueakWin32x86Config

I can identify the Abstract Base Class in several ways

1. It is a  topmost class in the class heirarchy for that platform/class category
2. It is named after its platform
3. It answers #true to the message isAbstractBaseClass
Linux64x86w32BitConfigUsrLib  isAbstractBaseClass 
--> true

In this workflow example I ideduce that the  AbstractBaseClass for my Platform is Linux64x86w32BitConfigUsrLib'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> initializePlatformSources [
	^HelpTopic
		title:'Initialize Platform Sources'
		contents:
'Within the broad outline of this tutorial, you are here: 
  8. Customizing your Configuration.

Platform Sources are platform dependent source files in the Cog development tree..
To build the VM, CMake needs to know their names. 

They reside in subdirectories of Cog/platforms

bash-4.2$ ls -1 Cog/platforms/
Cross
Mac OS
Plan9
RiscOS
iOS
unix
win32

On the unix platform the VM depends on some platform sources they are stored in the platforms/unix/vm directory..

bash-4.2$ ls -1 Cog/platforms/unix/vm/*.[ch]
Cog/platforms/unix/vm/SqDisplay.h
Cog/platforms/unix/vm/SqModule.h
Cog/platforms/unix/vm/SqSound.h
Cog/platforms/unix/vm/aio.c
Cog/platforms/unix/vm/debug.c
Cog/platforms/unix/vm/debug.h
Cog/platforms/unix/vm/dlfcn-dyld.c
Cog/platforms/unix/vm/feedback.h
Cog/platforms/unix/vm/glibc.h
Cog/platforms/unix/vm/mac-alias.c
Cog/platforms/unix/vm/osExports.c
Cog/platforms/unix/vm/sqConfig.h
Cog/platforms/unix/vm/sqGnu.h
Cog/platforms/unix/vm/sqPlatformSpecific.h
Cog/platforms/unix/vm/sqUnixCharConv.c
Cog/platforms/unix/vm/sqUnixCharConv.h
Cog/platforms/unix/vm/sqUnixEvent.c
Cog/platforms/unix/vm/sqUnixExternalPrims.c
Cog/platforms/unix/vm/sqUnixGL.h
Cog/platforms/unix/vm/sqUnixGlobals.h
Cog/platforms/unix/vm/sqUnixHeartbeat.c
Cog/platforms/unix/vm/sqUnixITimerHeartbeat.c
Cog/platforms/unix/vm/sqUnixITimerTickerHeartbeat.c
Cog/platforms/unix/vm/sqUnixMain.c
Cog/platforms/unix/vm/sqUnixMain.h
Cog/platforms/unix/vm/sqUnixMemory.c
Cog/platforms/unix/vm/sqUnixSpurMemory.c
Cog/platforms/unix/vm/sqUnixThreads.c
Cog/platforms/unix/vm/sqUnixVMProfile.c
Cog/platforms/unix/vm/sqUnixWindow.h
Cog/platforms/unix/vm/sqaio.h
Cog/platforms/unix/vm/sunos.h

A subset of these must be customized in our Configuration. 
In the initializePlatformSources step, the universe of possible sources is hard coded by hand*

If you look at the system level configurations you can see the files listed 
SystemNavigation  browseAllImplementorsOf: #initializePlatformSources  


There are different sources for the Windows and Mac platforms which I do not cover here. As of 20160530 the Dos and Mac code has not been developed beyond what I inherited from the Pharo code..

*This has already bitten me. The sqUnixSpurMemory was added as I was developing this system and was not originally in my list of initialized files. I had to debug the problem and then add it by hand.



'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> initializeVMPlugins [
	"This method was automatically generated. Edit it using:"
	"a HelpBrowser edit: #initializeVMPlugins"
	^HelpTopic
		title: 'Initialize VM Plugins'
		contents: 
'Within the broad outline of this tutorial, you are here: 
  8. Customizing your Configuration.

VM Pluings are a type of plugin that is unique to Unix.  Their directories exist in the Cog/Platforms/unix directory
Shown here:

bash-4.2$ ls  -1d  Cog/platforms/unix/vm-*
Cog/platforms/unix/vm-display-Quartz
Cog/platforms/unix/vm-display-X11
Cog/platforms/unix/vm-display-custom
Cog/platforms/unix/vm-display-fbdev
Cog/platforms/unix/vm-display-null
Cog/platforms/unix/vm-sound-ALSA
Cog/platforms/unix/vm-sound-MacOSX
Cog/platforms/unix/vm-sound-NAS
Cog/platforms/unix/vm-sound-OSS
Cog/platforms/unix/vm-sound-Sun
Cog/platforms/unix/vm-sound-custom
Cog/platforms/unix/vm-sound-null
Cog/platforms/unix/vm-sound-pulse



ToolSet browse: CPlatformConfigForSqueak selector: #initializeVMPlugins

is a hard-coded list of these VM Plugins but expressed as a list of encapsulating objects.
These objects are just data buckets for carrying information that will be used to build them.

CMakeVMPlugin browseHierarchy

On initialization, the CPlatformConfigForSqueak stores them in its vmplugins instance variable where we will customize them later.
!' readStream nextChunkText
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> isAbstractBaseClass [
	^HelpTopic
		title:'Is Abstract Base Class'
		contents:
'Within the broad outline of this tutorial, you are here: 
5. Interaction of the Builder and your Configuration

Configurations  must identify themselves as NOT being an Abstract Base Class

The default, inhereted from CPlatformConfigForSqueak is that a Configuration IS an Abstract Base Class.

CPlatformConfigForSqueak class browse

isAbstractBaseClass
	^true
	
If we look at our new configuration that we just copied from an existing, we see	
Linux64x86w32BitSqueakCogSpurConfig class browse	
	
isAbstractBaseClass
	^false
	
	
	



	^false   "build this configuration"
"	^true     do not build this configuration"   

In our case, the Builder shows us that Linux32x86SqueakCogSpurConfig is capable of being built (I had copied an existing, working Configuration):

SqueakLinux64x86w32CompatBuilder availableBuildConfigurations
--> a SortedCollection(#Linux64x86w32BitSqueakCogSpurConfig #Linux64x86w32BitSqueakCogV3Config)


To exclude it, override (or alter) the Configurations ''excludeFromBuild'' method

Linux64x86w32BitSqueakCogSpurConfig >>excludeFromBuild
	"over-ride to exclude yourself from a build"
	^true

And the Configuration is hidden from the Builder...

SqueakLinux64x86w32CompatBuilder availableBuildConfigurations
-->  a SortedCollection(#Linux64x86w32BitSqueakCogV3Config)


However, since I am developing locally, I need it to be visible to the Builder , so I set it as so:

Linux64x86w32BitSqueakCogSpurConfig >>excludeFromBuild
	"over-ride to exclude yourself from a build"
	^false

And my Builder can see it again...

SqueakLinux64x86w32CompatBuilder availableBuildConfigurations  
-->  a SortedCollection(#Linux64x86w32BitSqueakCogSpurConfig #Linux64x86w32BitSqueakCogV3Config)


N.B. tty. My opinion is that this is a weak way of doing this, but I have not thought through how to do this elegantly. 
This functionality is included with an eye towards easing automated builds for all platforms and configurations.'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> isAbstractBaseClassAndExcludeFromBuild [
	^HelpTopic
		title:'ExcludeFrom Build and Abstract Base Class'
		contents:
'Within the broad outline of this tutorial, you are here: 
5. Interaction of the Builder and your Configuration


A bit of explanation about excludeFromBuild and isAbstractBaseClass is in order.

Both Builders and Tests use the truth values of these methods to determine if a Configuration should be tested or built or queried

The Class comment for CPlatformConfigForSqueak explains the interaction in full.

ClassCommentVersionsBrowser browseCommentOf:CPlatformConfigForSqueak

'
]

{ #category : #accessing }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> key [
	^'CMakeVMMakerSqueakStepByStepNewConfigurationHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> methodRedirectPattern [
	^HelpTopic
		title:'Review of Method Redirect Pattern'
		contents:
'Within the broad outline of this tutorial, you are here: 
7. Some high level classes and concepts
	7b. The Method Redirect Pattern (a broadly used design pattern in the system)

The CPlatformConfigForSqueak provides methods that must be implemented at some level in the CPlatformConfigForSqueak hierarchy. 
The design pattern is heavily used and you can get a sense of its scope by evaluating:

ToolSet browseMessageCategory: ''cmake buildType redirects''  inClass:CPlatformConfigForSqueak

The naming of the redirect methods follows a consistent pattern.

fooBuild;
fooBuildAssert
fooBuildAssertITimerHeartbeat
fooBuildDebug
fooBuildDebugITimerHeartbeat
fooBuildITimerHeartbeat
fooBuildMultiThreaded
fooBuildMultiThreadedAssert
fooBuildMultiThreadedDebug
fooNoBuildType

Where the suffix to ''foo'' denotes a specific buildType out of the available pool specified here:

SqueakCMakeVMMakerAbstractBuilder allBuildTypes


The CPlatformConfigForSqueak either (rarely) implements or  requires that at least one of these methods are implemented as such:

fooBuild
	 self subclassResponsibility


At the same time, it does not require that all of them be implemented. It accomplishes this by defaulting to  the ''fooBuild'' method:

fooBuildAssertITimerHeartbeat
  ^ self fooBuild

You can see the ''foo'' pattern here in the ''cmakeAddDefinitions'' method

SystemNavigation new browseAllImplementorsOf: #cmakeAddDefinitionsBuildMultiThreadedAssert localTo: CPlatformConfigForSqueak.

Most buildTypes are redirected to a default implementation. This default implementation is implemented at an appropriate level in the CPlatformConfigHeirarchy 

There are some redirect methods that are appropriate to CPlatformConfigForSqueak; for example:

SystemNavigation new browseAllImplementorsOf: #setGlobalOptionsBuild: localTo: CPlatformConfigForSqueak.   

Most methods are implemented lower in the hierarchy.

When we implement a Configuration, we are implementing and or overriding methods in CMakePlatformConfigForSqueak that are appropriate for our buildType. 

The Method Redirect Pattern is covered in detail in an existing Help topic.

HelpBrowser openOn: CMakeVMMakerSqueakDesignPatternsHelp

Invocation of the Method Redirect Pattern occurs in the VMGenerator. We cover that next.

'


]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> overview [
	"This method was automatically generated. Edit it using:"
	"a HelpBrowser edit: #overview"
	^HelpTopic
		title: 'Overview'
		contents: 
'This Help Topic presents the workflow the author used in creating the  Squeak, Cog, Spur CMake configuration for a 64 bit Slackware 14.1 system.with 32 bit compatability libs in /usr/lib

The broad outline of this tutorial covers

1. Tests
2. Where to place your new Configuration
3. What Builder to use
4. Create your Configuration
5. Interaction of the Builder and your Configuration
6. Generating a proof-of-concept CMake build tree.
7. Some high level classes and concepts
  7.a  CPlatformConfigForSqueak
  7b. The Method Redirect Pattern (a broadly used design pattern in the system)
  7c. The CMakeVMGeneratorForSqueak 
8. Customizing your Configuration.


Although some details will be different, the steps involved should be the same for any platform.





!' readStream nextChunkText
]

{ #category : #accessing }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> pages [

"platformSources...cogitClass...src vs vmsrc"
	^#(
overview 
tests 
identifyPlatform 
identifyPlatformAbstractBaseClass
identifyBuilder
createTheConfiguration
excludingConfigFromBuilds
isAbstractBaseClass
isAbstractBaseClassAndExcludeFromBuild

setAvailableBuildTypes
firstCMakeGeneration
tackingStockOne
cPlatformConfigForSqueak
methodRedirectPattern
theVMGenerator
tackingStockTwo
cPlatformConfigForSqueakInitialize
initializePlatformSources
customizePlatformSources
initializeVMPlugins
customizeVMPlugins
configGenerateByTemplate
specifyCogitClass


specifyDirectories
specifyTopDir
specifyDirOutput
specifyDirBuildPlatform
dirBuildLanguageVMMM
setGlobalOptions
cmakePrefixPath
cmakeIncludePath
cmakeLibraryPath
cmakeIncludeModules
cmakeCFlags
cmakeAddDefinitions
cmakeWriteDirectoriesDotCmake
cmakeIncludeDirectories
preferredIncludes
standardIncludes
setGlobalOptionsAfterDetermineSystem
extraVMSettings
setCoreSources
setPlatformSources
setCrossSources
setExtraSources
cmakeSetSourceFilesProperties
cmakeListAppendLINKLIBSelements
cmakeAddExecutableNameOptionSource
setExecutableOutputPath
addVMPlugins
generatePluginConfigs
specifyPlugins
processPlugins
postBuildActions
generateBuildScript
fin
)


]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> postBuildActions [
	^HelpTopic
		title:'postBuildActions:'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

postBuildActions: implements the Method Redirect pattern.

ToolSet browse: CPlatformConfigForSqueak selector: #postBuildActions:

Since the configuration is configured for buildType: #build the method redirect pattern will redirect to

SystemNavigation browseAllImplementorsOf: #postBuildActionsBuild:

We see in CPlatformConfigForSqueak that a sublcass must implement it via ''self subclassResponsibility''.

The platform Config SqueakUnixConfig implements this. It can be over-ridden or extended as needed.

We have nothing new to do here.
'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> preferredIncludes [
	^HelpTopic
		title:'preferredIncludes'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

SystemNavigation browseAllImplementorsOf: #preferredIncludes

CPlatformConfig browseHierarchy

As of CMakeVMMakerSqueak-tty.114 the method is a legacy method from the pharo CPlatformConfig. It is expect it (and this help page!) will go away on a refactoring pass when the dependency on the pharo package is removed.


In the CPlatformConfigForSqueak>>preferredIncludes, we see the Method Redirect Pattern employed. Since this is for buildType #build, the method will re-route to self preferredIncludesBuild.

SystemNavigation browseAllImplementorsOf: #preferredIncludesBuild

We see that #preferredIncludesBuild  is subclassed and implemented below the the platform level and down at the architecture/library location, one level above our new configuration.

Linux64x86w32BitConfigUsrLib browseHierarchy

The method itself creates a CMakeIncludeDirectories CMake template 

CMakeIncludeDirectories browse

The class comment tells us that we can add custom include directories for CMake to use.

The CMake template class initializes itself with some default data, which you can print out here:

(CMakeIncludeDirectories new) content

Since this is handled for us one level above our new configuration, we will leave this one untouched.  If it turns out that we need to include some other directories, we can override the method.'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> processPlugins [
^HelpTopic
		title:'Process Plugins'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

SystemNavigation browseAllImplementorsOf: #processPlugins:

This method is inhereted from the pharo code. I do not fully understand the reasoning behind it. I expect it will be refactored or rewritten.
See the method comment in 

SystemNavigation browseAllImplementorsOf: #initializeConfigDotCmakeFiles

Presently it does (at least) three things.

First, it adds plugin information to the master CMakeLists.txt file typically the add_subdirectory(''PluginName'') cmake command.

Second, it adds plugin information to the master CMakeLists.txt file from the CMakePluginGeneratorForSqueak>>configDotSomePluginName group of methods


SystemNavigation browseAllImplementorsOf: #configDotFilePlugin


Third it generates the sqNamedPrims.h file reproduced below.

bash-4.2$ cat sqNamedPrims.h 
/* This is automatically generated file using CVMMaker on 9 May 2016 2:26:20.906098 pm */
extern sqExport vm_exports[];
extern sqExport os_exports[];
extern sqExport ADPCMCodecPlugin_exports [];
extern sqExport AsynchFilePlugin_exports [];
extern sqExport B2DPlugin_exports [];
extern sqExport BitBltPlugin_exports [];
extern sqExport BMPReadWriterPlugin_exports [];
extern sqExport CroquetPlugin_exports [];
extern sqExport ZipPlugin_exports [];
extern sqExport DropPlugin_exports [];
extern sqExport DSAPrims_exports [];
extern sqExport FFTPlugin_exports [];
extern sqExport FileCopyPlugin_exports [];
extern sqExport FilePlugin_exports [];
extern sqExport FloatArrayPlugin_exports [];
extern sqExport FloatMathPlugin_exports [];
extern sqExport JoystickTabletPlugin_exports [];
extern sqExport Klatt_exports [];
extern sqExport LargeIntegers_exports [];
extern sqExport Matrix2x3Plugin_exports [];
extern sqExport MIDIPlugin_exports [];
extern sqExport MiscPrimitivePlugin_exports [];
extern sqExport Mpeg3Plugin_exports [];
extern sqExport SecurityPlugin_exports [];
extern sqExport SerialPlugin_exports [];
extern sqExport SocketPlugin_exports [];
extern sqExport SoundCodecPrims_exports [];
extern sqExport SoundPlugin_exports [];
extern sqExport StarSqueakPlugin_exports [];
extern sqExport SurfacePlugin_exports [];
extern sqExport LocalePlugin_exports [];

sqExport *pluginExports[] = {
        vm_exports,
        os_exports,
ADPCMCodecPlugin_exports,
AsynchFilePlugin_exports,
B2DPlugin_exports,
BitBltPlugin_exports,
BMPReadWriterPlugin_exports,
CroquetPlugin_exports,
ZipPlugin_exports,
DropPlugin_exports,
DSAPrims_exports,
FFTPlugin_exports,
FileCopyPlugin_exports,
FilePlugin_exports,
FloatArrayPlugin_exports,
FloatMathPlugin_exports,
JoystickTabletPlugin_exports,
Klatt_exports,
LargeIntegers_exports,
Matrix2x3Plugin_exports,
MIDIPlugin_exports,
MiscPrimitivePlugin_exports,
Mpeg3Plugin_exports,
SecurityPlugin_exports,
SerialPlugin_exports,
SocketPlugin_exports,
SoundCodecPrims_exports,
SoundPlugin_exports,
StarSqueakPlugin_exports,
SurfacePlugin_exports,
LocalePlugin_exports,
NULL




'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> setAvailableBuildTypes [
	^HelpTopic
		title:'Setting Available Build Types'
		contents:
'Within the broad outline of this tutorial, you are here: 
5. Interaction of the Builder and your Configuration

Configurations  inform Builders what BuildTypes they support. via the availableBuildTypes method

Here is my Builder asking my new Configuration what build types it supports (remember, this Configuration was copied, so it has been configured already)

SqueakLinux64x86w32CompatBuilder availableBuildTypesFor: #Linux64x86w32BitSqueakCogSpurConfig
-->  an OrderedCollection(#build #buildAssert)


In our Abstract Base Class (Which, you recall cannot be built )for our Platform, we default to no build types.

Linux64x86w32BitConfigUsrLib>>availableBuildTypes
 	 ^SqueakCMakeVMMakerAbstractBuilder  default  noBuildTypes


To get an idea of what buildTypes are available system wide evaluate
SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes 
-->an OrderedCollection(#build #buildAssert #buildAssertITimerHeartbeat #buildDebug #buildDebugITimerHeartbeat #buildITimerHeartbeat #buildMultiThreaded #buildMultiThreadedAssert #buildMultiThreadedDebug #buildNone)


To set the available build types for a Concrete Configurations we override the AbstactBaseClass''s method and SUBTRACT OUT what we do not want. Like so:

Since I am starting simple, I want my configuration to build a vanilla build. To do this I remove all but #build buildType like so

Linux64x86w32BitSqueakCogSpurConfig >> availableBuildTypes 
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes copyWithoutAll: #( #buildAssert #buildAssertITimerHeartbeat #buildDebug #buildDebugITimerHeartbeat #buildITimerHeartbeat #buildMultiThreaded #buildMultiThreadedAssert #buildMultiThreadedDebug #buildNone)


As I code more build types in my configuration, I subtract out 

Linux32x86SqueakCogV3Config >> availableBuildTypes 
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes copyWithoutAll: #(  #buildMultiThreadedDebug #buildNone)

With the result that my Builder shows the removed items as Available Build Types:

SqueakLinux32x86Builder availableBuildTypesFor: #Linux32x86SqueakCogV3Config 
--> an OrderedCollection(#build #buildAssert #buildAssertITimerHeartbeat #buildDebug #buildDebugITimerHeartbeat #buildITimerHeartbeat #buildMultiThreaded #buildMultiThreadedAssert)

Since I will only be developing the #build buildType for now, I put it as so:

Linux32x86SqueakCogV3Config>>availableBuildTypes 
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes copyWithoutAll: #( #buildAssert #buildAssertITimerHeartbeat #buildDebug #buildDebugITimerHeartbeat #buildITimerHeartbeat #buildMultiThreaded #buildMultiThreadedAssert #buildMultiThreadedDebug #buildNone)


and verify it is correct:

SqueakLinux32x86Builder availableBuildTypesFor: #Linux32x86SqueakCogV3Config 
-->an OrderedCollection(#build)


*N.B. tty. In my opinion, this is a weak design on my part. as it relies on the developer to set it up. If there is an elegant way to do this , I am for it.
'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> setConfigurationDirectory [
	^HelpTopic
		title:'Set Configuration Directory'
		contents:
'
Need the squeak.cog.spur directory here.


'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> setCoreSources [
	^HelpTopic
		title:'setCoreSources'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

SystemNavigation browseAllImplementorsOf: #setCoreSources:

The ''self coreSources'' message is a Method Redirect Pattern. 

ToolSet browse: CPlatformConfigForSqueak selector:#coreSources

SystemNavigation browseAllImplementorsOf: #coreSourcesBuild

Here we see a hard-coded list returned (this will probably be refactored on a refactoring pass)

The  ''${srcVMDir}'' is a variable placeholder in CMake. It contains a path name that resolves to where those files listed above exist.

We set that in (FIX ME AND IDENTIFY PRECISIELY WHERE srcVMDir gets its value)

'



]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> setCrossSources [
	^HelpTopic
		title:'setCrossSources'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

SystemNavigation browseAllImplementorsOf: #setCrossSources:

We see that this is a top-level Configuration method that writes a CMake Set(foo, bar) construct.

crossSources is another hard-coded list of source files

ToolSet browse: SqueakUnixConfig selector: #crossSources

This list of sources is in the Cog subversion build tree under:

bash-4.2$ ls -1 Cog/platforms/Cross/vm/*.c
oscogvm/platforms/Cross/vm/sqExternalSemaphores.c
oscogvm/platforms/Cross/vm/sqHeapMap.c
oscogvm/platforms/Cross/vm/sqNamedPrims.c
oscogvm/platforms/Cross/vm/sqTicker.c
oscogvm/platforms/Cross/vm/sqVirtualMachine.c

The ''${crossDir}'' is a variable placeholder that CMake will populate. The variable value is held in our configuration 
It will resolve to "oscogvm/platforms/Cross/vm''

What this is doing is creating a list of paths to files.

If any Cross platform files are ever added, we will have to modify the #crossSources return value.



'

]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> setExecutableOutputPath [
	"This method was automatically generated. Edit it using:"
	"a HelpBrowser edit: #setExecutableOutputPath"
	^HelpTopic
		title: 'setExecutableOutputPath'
		contents: 
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

SystemNavigation browseAllImplementorsOf: #setExecutableOutputPath

 We see that this is implemtented in CPlatformConfigForSqueak.

It creates a CMakeSet object and sets the ''EXECUTABLE_OUTPUT_PATH'' variable to self outputDir

SystemNavigation browseAllImplementorsOf: #outputDir

Which redirects to 

(CPlatformConfigForSqueak basicNew) outputDirName

The #outputDir method is a legacy method from the pharo code. It should be factored out after the dependency on the pharo code is removed.!' readStream nextChunkText
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> setExtraSources [
	^HelpTopic
		title:'setExtraSources'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

SystemNavigation browseAllImplementorsOf: #setExtraSources

We see that this is a top-level Configuration method that writes a CMake Set(foo, bar) construct.

You can see the CMake generated by evaluating

((CMakeSet new) variable:''extraSources'' value:((SqueakUnixConfig basicNew) extraSources)) content

The #extraSources method contains some hard coded values (expect refactoring)

SystemNavigation browseAllImplementorsOf: #extraSources

ToolSet browse: SqueakUnixConfig selector: #extraSources

If we needed to we could add or remove these in our Configuration.

For us, there is nothing to do here.

'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> setGlobalOptions [
	^HelpTopic
		title:'setGlobalOptions: self'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

For this method there is nothing to do. Here is why.

Let''s start by seeing what classes implement the method

SystemNavigation browseAllImplementorsOf: #setGlobalOptions:

We see that  CPlatformConfigForSqueak implements it (The other classes are from the pharo package. These will go way after the dependency on the pharo code is factored out).

Looking at it, we see that the method  implements the Method Redirect pattern 

Since we have configured for buildType: #build, the Method Redirect Pattern will invoke the  setGlobalOptionsBuild: aMaker method.

So we look at the implementors of it..

SystemNavigation browseAllImplementorsOf: #setGlobalOptionsBuild:

We see only CPlatformConfigForSqueak implements the method. Reading the method comments, we see that it generates CMakeLists.txt commands that span all platforms. 

No subclasses of CPlatformConfigForSqueak override it.

There is nothing for us to override here. Let''s move on.

'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> setGlobalOptionsAfterDetermineSystem [
	^HelpTopic
		title:'setGlobalOptionsAfterDetermineSystem'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

SystemNavigation browseAllImplementorsOf: #setGlobalOptionsAfterDetermineSystem:


In the CPlatformConfigForSqueak>>setGlobalOptionsAfterDetermineSystem: aMaker, we see the Method Redirect Pattern employed. Since this is for buildType #build, the method will re-route to self setGlobalOptionsAfterDetermineSystemBuild

SystemNavigation browseAllImplementorsOf: #setGlobalOptionsAfterDetermineSystemBuild:

We see the CPLatformConfigForSqueak forces a subclass to implement it and the SqueakUnixConfig implements it.

In SqueakUnixConfig a CMakeSet is created and initialized. You can see the resultant output by printing the below expression:

((CMakeSet new) variable:''CMAKE_C_COMPILER'' value:''gcc'') content

Currently this is a platform level method, however, we can envision it being set lower when ''gcc'' is not the default compiler.

For our purposes, there is nothing we need to do.

'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> setPlatformSources [
	^HelpTopic
		title:'setPlatformSources'
		contents:'
Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

SystemNavigation browseAllImplementorsOf: #setPlatformSources:

We see the Method Redirect Pattern.

SystemNavigation browseAllImplementorsOf: #setPlatformSourcesBuild:

Looking at Linux64x86w32BitSqueakCogSpurConfig>>setPlatformSourceBuild: aMaker 

we see work we did earlier in this tutorial. 

If you recall, on Configuration initialization the platformSources variable was populated with the names of source files in Cog/platforms/unix/vm

Here we must return a subset of that data.

.'

]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> specifyCogitClass [
	^HelpTopic
		title:'Specify Cogit Class'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

Depending on the type of vm we are building, we must specify the cogit class	

ToolSet browse: CPlatformConfigForSqueak selector: #cogitClass

The types we can return are

	^SimpleStackBasedCogit
	^ StackToRegisterMappingCogit 
	^SistaStackToRegisterMappingCogit

These are subclasses of Cogit.
Cogit browseHierarchy

Since we are building a Cog VM we need the StackToRegisterMappingCogit.

(I need to get with Eliot to specify this exactly)

For our purposes in this tutorial, we have our Linux64x86w32BitSqueakCogSpurConfig>>cogitClass return StackToRegisterMappingCogit.

ToolSet browse: Linux64x86w32BitSqueakCogSpurConfig selector: #cogitClass



'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> specifyDirBuildPlatform [
	^HelpTopic
		title: 'Specify dirBuildPlatform'
		contents: 
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.


Please evaluate:
SystemNavigation new browseAllImplementorsOf: #dirBuildPlatform

Notice that the CPlatformForSqueak forces subclasses to implement his.

Looking at the classes that do implement it, notice that they are all at the platform level; i.e. they correspond to the OperatingSystem/Processor the user is compiling for.

Taking the Linux64x86w32BitConfigUsrLib Confiiguration, we see its implementation of "dirBuildPlatform" returns 
^self dirLinux64x86w32BitCompatibility

SystemNavigation new browseAllImplementorsOf: #dirLinux64x86w32BitCompatibility

Notice that return value is a "cmake directory string" method in CPlatformConfigForSqueak.


The result will be used in two places--in the build directory and the output directory relative to the directories we have specified.

The build directory at the platform level now looks like:  "oscogvm/cmake.build.linux64x86w32BitCompatibility

The output directory at the platform level now looks like: "oscogvm/cmake.products/cmake.build.linux64x86w32BitCompatibility

!'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> specifyDirOutput [
	^HelpTopic
		title: 'Specify dirOutput'
		contents: 
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

SystemNavigation new browseAllImplementorsOf: #dirOutput

Here, we see a  "cmake directory string" returned. 

The system will use this to create the "oscogvm/cmake.products" directory which will store the compiled VM for your configuration.

This will rarely, if ever, need customization.

!'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> specifyDirectories [
	"This method was automatically generated. Edit it using:"
	"a HelpBrowser edit: #specifyDirectories"
	^HelpTopic
		title: 'Specify Directories Overview'
		contents: 
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

Our new Configuration must correctly name two directory trees.

The first is  the cmake.build.* directory tree where the generated CMake output is placed.
The second is the cmake.products/* directory tree where the compiled vm is placed.


Correctly naming these is a courtesy you should extend as the system grows*.


For this particular Configuration, we want a cmake.build.* directory that looks like this:

oscogvm/cmake.products/cmake.build.linux64x86w32BitCompatibility/squeak.cog.spur


and we want a cmake.products/* directory that looks like this:

oscogvm/cmake.products/cmake.build.linux64x86w32BitCompatibility/squeak.cog.spur/build


Each directory in those trees is accessible via the the CPlatformConfigForSqueak method categories: ''cmake directory strings'' and "cmake directory objects"

ToolSet browseClass: CPlatformConfigForSqueak category: ''cmake directory strings''.
ToolSet browseClass: CPlatformConfigForSqueak category: ''cmake directory objects''.


Methods in "cmake directory strings" return strings.
Methods in "cmake directory objects" return FileDirectory objects.


In "cmake directory strings" there are two method variants.

The first variant in "cmake directory strings" is hardcoded in the method itself. For example the platform directories are stored as...

dirLinux32Armv6
	^''cmake.build.linux32armv6''

or, for our configuration

dirLinux64x86w32BitCompatibility
	^''cmake.build.linux64x86w32BitCompatibility''
	
The second variant  in "cmake directory strings" accesses the  name of a buildType directory via the SqueakCMakeVMMakerAbstractBuilder (do a printIt or doIt).

dirBuild
	^SqueakCMakeVMMakerAbstractBuilder default buildTypeAndDirectoryInfo at: #build	

Each part of the directory tree is contained/accessible via these methods. It is our job to select the corect ones for our purposes.

Here is an example of mapping this output directory path
''oscogvm/cmake.products/cmake.build.linux64x86w32BitCompatibility/squeak.cog.spur/build''

to the methods that output each part.

|c|
c:=(CPlatformConfigForSqueak basicNew). 
(c oscogvm), ''/'', (c dirOutput), ''/'', (c dirLinux64x86w32BitCompatibility), ''/'', (c squeakCogSpur), ''/'', (c dirBuild)


The methods corresponding to each of the above directory names are:

topDir
dirOutput
dirBuildPlatform
dirBuildLanguageVMMM
buildType (not a method,this is a private instance variable in the configuration)

The first two, topDir and dirOutput are contained in CPlatformConfigForSqueak
dirBuildPlatform is contained at the platform level

SystemNavigation new browseAllImplementorsOf: #dirBuildPlatform localTo:CPlatformConfigForSqueak.

dirBuildLangaugeVMMM is at the specific Configuration level
SystemNavigation new browseAllImplementorsOf: #dirBuildLanguageVMMM localTo:CPlatformConfigForSqueak.

buildType is set when we configure the Configuration for a particular buildType and is stored in the SqueakCMakeVMMakerAbstractBuilder at its initialization.

SystemNavigation new browseAllImplementorsOf: #initializeBuildTypeAndDirectoryInfo

It is this values that the CPlatformConfigForSqueak access via dirBuild, dirBuildAssert etc...
SystemNavigation new browseAllImplementorsOf: #dirBuild


Similarly, the build directory tree 
''oscogvm/cmake.build.linux64x86w32BitCompatibility/squeak.cog.spur/build/''

has methods corresponding to each of the above directory names. they are:

topDir
dirBuildPlatform
dirBuildLanguageVMMM
buildType (not a method,this is a private instance variable in the configuration)

It follows then, that for our Configuration we need to make the method dirBuildLanguageVMMM return ''squeak.cog.spur''.

We cover that  in the next Help page.


*The naming convention is straightforward and convered in the ''Naming Convetions'' page of the Developer Guide Overview Help.

HelpBrowser openOn: CMakeVMMakerSqueakOverviewHelp) model showTopicThat: [:topic | topic key = #namingConventions].


!'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> specifyPlugins [
	^HelpTopic
		title:'Specify Plugins'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

We can specify which plugins we want on our configuration by overriding our platform''s defaultExternalPlugins and defaultInternalPlugins methods.

The default set can be further customized according to buildType if desired via the externalPlugins[BuildType] and internalPlugins[BuildType] redirect pattern

We will cover only the internalPlugins scenario here. The methodology is exactly the same for externalPlugins.

Let''s look first at the defaultInternalPlugins

SystemNavigation browseAllImplementorsOf: #defaultInternalPlugins

Looking at the Linux64x86w32BitConfigUsrLib we see that it just returns a default collection of class names. 

The defaultInternalPlugins message is  typically sent from the internalPlugins[buildType] method.

SystemNavigation browseAllImplementorsOf: #internalPlugins

Here we see that CPlatformConfigForSqueak implements the message redirect pattern.

SystemNavigation browseAllImplementorsOf: #internalPluginsBuild

In CPlatformConfigForSqueak >> internalPluginsBuild forces subclasses to implement the method.

Looking at 

SystemNavigation browseAllImplementorsOf: #internalPluginsBuildMultiThreadedDebug
we see the default is to return the default list provided in internalPluginsBuild.

This enables configurations to customize their plugins with a good degree of granularity should we want to change the plugins we use based on buildType while keeping things simple in the default case.

To summarize, a Configuration specifies what plugins it wants to build (either internal or external) by modifying or overriding the list of Plugin class names stored in defaultInternalPlugins or defaultExternalPlugins by overriding the internalPlugins[buildType] method or externalPlugins[buildType] method





















'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> specifyTopDir [
	^HelpTopic
		title: 'Specify TopDir'
		contents: 
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.

topDir is the root at the top of the build tree and it is fitting it is in the top Configuration.

SystemNavigation new browseAllImplementorsOf: #topDir
SystemNavigation new browseAllImplementorsOf: #oscogvm

Here, we see a "cmake directory object" and "cmake directory string" used to create a FileDirectory object named ''oscogvm"

This will rarely, if ever, need customization.

!'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> standardIncludes [
	^HelpTopic
		title:'standardIncludes'
		contents:
'Within the broad outline of this tutorial, you are here: 
8. Customizing your Configuration.


As of CMakeVMMakerSqueak-tty.114 the method is a legacy method from the pharo CPlatformConfig. It is expect it (and this help page!) will go away on a refactoring pass when the dependency on the pharo package is removed.


SystemNavigation browseAllImplementorsOf: #standardIncludes

CPlatformConfig browseHierarchy

In the CPlatformConfigForSqueak>>standardIncludes, we see the Method Redirect Pattern employed. Since this is for buildType #build, the method will re-route to self standardIncludesBuild.

SystemNavigation browseAllImplementorsOf: #standardIncludesBuild

The SqueakUnixConfig just writes some debug messages. 

There is nothing for us to do here.'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> tackingStockOne [
	^HelpTopic
		title:'Taking Stock'
		contents:
'Let''s take stock of where we are.

At this point, we have 
1. Created a Configuration for a specific platform, language, VM and memory model .
2. Invoked the appropriate  Builder for that Configuration asking it to ...
	2.a configure itself for a specific BuildType and 
	2.b asked it to ouput its content to a specific directory.
3. Confirmed that the Configuration outputs its data.

Within the broad outline of this tutorial, you have covered the following
1. Tests
2. Where to place your new Configuration
3. What Builder to use
4. Create your Configuration
5. Interaction of the Builder and your Configuration
6. Generating a proof-of-concept CMake build tree.


The remainder of our task is customizing our Configuration so that the generated data correctly builds as the intention revealing name of the Configuration implies. I.e. we expect a Linux64x86w32BitSqueakCogSpurConfig, when configured for the buildType  #build to generate CMake (and other) files that in fact, creates a release version of a squeak.cog.spur vm that runs on Linux64 with 32 bit compat libs stored in /usr/lib.

Before we dive into customizing our new Configuration,  we step back to gain some perspective so that if there are problems, you know where to look. 

We will start by a quick summary of..

1. The root Configuration class CPlatformConfigForSqueak
2. The ''method redirect''  design pattern.
3. The CMakeVMGeneratorForSqueak class


After that, we will take stock again and proceed with the customization of our example Linux64x86w32BitSqueakCogSpurConfig 
'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> tackingStockTwo [
	^HelpTopic
		title:'Taking Stock II'
		contents:
'Within the broad outline of this tutorial, you have covered the following: 
1. Tests
2. Where to place your new Configuration
3. What Builder to use
4. Create your Configuration
5. Interaction of the Builder and your Configuration
6. Generating a proof-of-concept CMake build tree.
7. Some high level classes and concepts
  7.a  CPlatformConfigForSqueak
  7b. The Method Redirect Pattern (a broadly used design pattern in the system)
  7c. The CMakeVMGeneratorForSqueak 


The remainder of this Example Workflow will be the customization of the Linux64x86w32BitSqueakCogSpurConfig and generating a working build.

To do this by 

Examining the CPlatformConfigForSqueak>>initialize process
Working through each statement in the CMakeVMGeneratorForSqueak>>generateByTemplate cascade in turn.
'
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> tests [
	"This method was automatically generated. Edit it using:"
	"a HelpBrowser edit: #tests"
	^HelpTopic
		title: 'Tests'
		contents: 
'Within the broad outline of this tutorial, you are here: 
1. Tests.

The Tests are in class category CMakeVMMakerSqueak-Tests.

They are:

CMakeVMMakerSqueakBuildersTest
CMakeVMMakerSqueakCommonConfigTest
CMakeVMMakerSqueakMacintoshConfigTest
CMakeVMMakerSqueakRedirectMethodsTest
CMakeVMMakerSqueakRedirectMethodsWithArgTest
CMakeVMMakerSqueakUnixConfigTest
CMakeVMMakerSqueakWindowsConfigTest

As of 2014.12.09 all tests pass. 

As we create the Configuration these tests will be an important check on our work and we will return to them often.!' readStream nextChunkText
]

{ #category : #pages }
CMakeVMMakerSqueakTutorialNewConfigurationHelp class >> theVMGenerator [
	^HelpTopic
		title:'The CMakeVMGeneratorForSqueak class'
		contents:
'Within the broad outline of this tutorial, you are here: 
7. Some high level classes and concepts
	7c. The CMakeVMGeneratorForSqueak 

Before we move onto setting the most common directives and flags in the Concrete Configuration, lets take a quick look at the class and  method that actually generates the CMake files for us. 

CMakeVMGeneratorForSqueak browseHierarchy

CMakeVMGeneratorForSqueak implements the Visitor Design pattern. It takes as input a Configuration and it operates on that Configuration in a methodical manner.

The CMakeVMGeneratorForSqueak has in instance variable named ''config''. This variable is our Configuration.

The methodical operation and generation of CMake output occurs in two places.

1. In the Configuration>>initialize method
	ToolSet browse: CPlatformConfigForSqueak selector: #initialize
2. In the  CMakeVMGeneratorForSqueak>>generateByTemplate method.
	ToolSet browse: CMakeVMGeneratorForSqueak selector: #generateByTemplate

The long cascade that starts with :

	config 
		setGlobalOptions: self;    
		cmakePrefixPath;
		cmakeIncludePath;.....

is the bulk of the CMake generation.

Here you see the CMakeVMGeneratorForSqueak iterating over the CPlatformConfigForSqueak Method Redirect methods.

Taking the ''cmakeIncludePath'' method for example...
SystemNavigation new browseAllImplementorsOf: #cmakeIncludePath localTo: CPlatformConfigForSqueak.

you see that based on the Configurations buildType, the appropriate Redirect Method out of :

cmakeIncludePathBuild
cmakeIncludePathBuildAssert
cmakeIncludePathBuildAssertITimerHeartbeat
cmakeIncludePathBuildDebug
cmakeIncludePathBuildDebugITimerHeartbeat
cmakeIncludePathBuildITimerHeartbeat
cmakeIncludePathBuildMultiThreaded
cmakeIncludePathBuildMultiThreadedAssert
cmakeIncludePathBuildMultiThreadedDebug
cmakeIncludePathNoBuildType

will be executed based on the Configurations buildType (which you set with your Builder earlier)


For debugging and troubleshooting you new Configuration, CMakeVMGeneratorForSqueak>>generateByTemplate enables you to step through CMake generation in an entirely predictable way.

Let''s recap next.
'


]
