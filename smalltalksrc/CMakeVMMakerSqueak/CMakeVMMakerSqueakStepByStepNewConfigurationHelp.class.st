"
A CMakeVMMakerSqueakNewConfigurationStepByStepHelp itemizes the steps needed to create a new build configuration.

HelpBrowser openOn: CMakeVMMakerSqueakNewConfigurationStepByStepHelp
"
Class {
	#name : #CMakeVMMakerSqueakStepByStepNewConfigurationHelp,
	#superclass : #CMakeVMMakerSqueakConfigurationsHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> aNoteOnFoo [
	^HelpTopic
		title:'A Note On FOO'
		contents:
'Since we have customized plugins, now is a good time to introduce the FOO in [PLATFORM][Language][VM][Memory Manager][BuildType][foo] 

The purpose of FOO is to accomadate personal plugins that ''just work'' for an odd-ball platform or odd set of plugins or some obscure operating system..

Some examples will suffice to convey the purpose of FOO. (below I encase [FOO] for clarity)

Linux64x86w32BitSqueakCogV3[WithoutGL]Config

SqueakBSD32x86[TTYsConfigurationFromHell]Config

Linux32x86SqueakCogV3[BillyBobVeryOwn]Config

Linux32x86SqueakCogV3[withoutIA32BOCHSPLugin]Config

you get the idea. 


'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> addVMPlugins [
	^HelpTopic
		title:'addVMPlugins'
		contents:
'
'
]

{ #category : #accessing }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> bookName [ 
	^'Example Workflow: New Configuration'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> cPlatformConfigForSqueak [
	"This method was automatically generated. Edit it using:"
	"a HelpBrowser edit: #cPlatformConfigForSqueak"
	^HelpTopic
		title: 'CPlatformConfigForSqueak'
		contents: 
'CPlatformConfigForSqueak browse

CPlatformConfForSqueak encapsulates data and methods/behaviors  that span computer platforms. 

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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> cmakeAddDefinitions [
	^HelpTopic
		title:'cmakeAddDefinitions'
		contents:
'SystemNavigation browseAllImplementorsOf: #cmakeAddDefinitions

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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> cmakeAddExecutableNameOptionSource [
	^HelpTopic
		title:'cmakeAddExecutableNameOptionSource:'
		contents:
'SystemNavigation browseAllImplementorsOf: #cmakeAddExecutableNameOptionSource:

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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> cmakeCFlags [
	^HelpTopic
		title:'cmakeCFlags'
		contents:
'SystemNavigation browseAllImplementorsOf: #cmakeCFlags

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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> cmakeIncludeDirectories [
	^HelpTopic
		title:'cmakeIncludeDirectories'
		contents:
'SystemNavigation browseAllImplementorsOf: #cmakeIncludeDirectories:

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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> cmakeIncludeModules [
	^HelpTopic
		title:'cmakeIncludeModules'
		contents:
'CMake allows the user to include custom CMake library files (modules).  
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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> cmakeIncludePath [
	^HelpTopic
		title:'cmakeIncludePath'
		contents:
'cmakeIncludePath implements the Method Redirect pattern.

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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> cmakeLibraryPath [
	^HelpTopic
		title:'cmakeLibraryPath'
		contents:
'cmakeLibraryPath implements the Method Redirect pattern.

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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> cmakeListAppend:LINKLIBSelements [
	^HelpTopic
		title:'cmakeListAppend:LINKLIBSelements'
		contents:
'
'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> cmakeListAppendLINKLIBSelements [
	^HelpTopic
		title:'cmakeListAppendLINKLIBSelements'
		contents:
'SystemNavigation browseAllImplementorsOf: #cmakeListAppend:elements:

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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> cmakePrefixPath [
	^HelpTopic
		title:'cmakePrefixPath'
		contents:
'ToolSet browse: CPlatformConfigForSqueak selector: #cmakePrefixPath

cmakePrefixPath implements the Method Redirect pattern.

Since the configuration is configured for buildType: #build the method redirect pattern will redirect to

SystemNavigation browseAllImplementorsOf: #cmakePrefixPathBuild

We see in CPlatformConfigForSqueak that a sublcass must implement it via ''self subclassResponsibility''.

We see that (as of this writing) the SqueakUnixConfig handles the method.

We reason that this method generates  platform specific CMake output and our lower-level Configuration need not override it.
'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> cmakeSetSourceFilesProperties [
	^HelpTopic
		title:'cmakeSetSourceFilesProperties'
		contents:
'SystemNavigation browseAllImplementorsOf: #cmakeSetSourceFilesProperties

SystemNavigation browseAllImplementorsOf: #cmakeSetSourceFilesPropertiesBuild

We see that the CPlatformConfigForSqueak subclasses responsibility (scroll down past the method comment)

We also see that our new Linux64x86w32BitSqueakCogSpurConfig Configuration implements it.

I suspect this method will be refactored upwards. It appears to be passing distinct compiler flags to the cogit.c and sqUnixHeartbeat.c.


Let''s leave this one alone.
'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> cmakeWriteDirectoriesDotCmake [
	^HelpTopic
		title:'cmakeWriteDirectoriesDotCmake'
		contents:
'SystemNavigation browseAllImplementorsOf: #cmakeWriteDirectoriesDotCmake:

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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> compilingLinkingSetup [
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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> configureAbstractBaseClass [
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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> createTheConfiguration [
	^HelpTopic
		title:'Create the Configuration'
		contents:
'Our new Concrete Configuration must be created as a subclass of our Platform''s Abstract Base Class.

SInce I am creating a Squeak Cog Spur config for the CMakeVMMakerSqueak-Linux64X86-32BitCompatibility Platform I choose the name:

Linux64x86w32BitSqueakCogSpurConfig.

(For a discussion on naming conventions evaluate:
HelpBrowser openOn: CMakeVMMakerSqueakOverviewHelp
)

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

'

]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> customizePlugins [
	^HelpTopic
		title:'customize Plugins'
		contents:
'We can customize which plugins we want on our configuration by overriding our platform''s defaultExternalPlugins and defaultInternalPlugins methods.

The default set can be further customized according to buildType if desired via the externalPlugins[BuildType] and internalPlugins[BuildType] redirect pattern


'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> customizeVMDrivers [
	^HelpTopic
		title:'Specify VM Drivers'
		contents:
'The SqueakUnixConfig contains the unverisal list of VM Drivers for *nix.

In our concrete Configuration, we need to specify which ones we want for out build.

We do this by overloading the SqueakUnixConfig>>customizeVMDrivers method.

'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> excludingConfigFromBuilds [
	^HelpTopic
		title:'Excluding a Config From Builds'
		contents:
'Configurations can hide themselves from , or make themselves visible to Builders via their ''excludeFromBuild'' method.

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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> extraVMSettings [
	^HelpTopic
		title:'extraVMSettings'
		contents:
'SystemNavigation browseAllImplementorsOf: #extraVMSettings:


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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> firstCMakeGeneration [
	"This method was automatically generated. Edit it using:"
	"a HelpBrowser edit: #firstCMakeGeneration"
	^HelpTopic
		title: 'First CMake Generation'
		contents: 
'For didactic purposes I am going to do a sanity check and generate CMake code from the configuration for the first time. 

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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> forTheImpatient [
	^HelpTopic
		title:'For the impatient'
		contents:
'Here is the TL;DR synopsis of the methods I implemented or overrode in creating the Linux64x86w32BitSqueakCogSpurConfig.
For a step-by-step exposition please continue to the next page.

TODO: Fill this in as you go
cmakeCFlags  
cmakeAddDefinitions


'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> identifyBuilder [
	^HelpTopic
		title:'Identify Builder'
		contents:
'My new Configuration will be managed by a Builder.

Builders are located in the CMakeVMMakerSqueak-Builder class category.

Builders are subclasses of SqueakCMakeVMMakerAbstractBuilder.
SqueakCMakeVMMakerAbstractBuilder browseHierarchy

Builders are named according to the Platform they manage.

(For a discussion on naming conventions evaluate:
HelpBrowser openOn: CMakeVMMakerSqueakOverviewHelp
)

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

SqueakLinux64x86w32CompatBuilder  buildDirectory 
-->''cmake.build.linux64x86w32BitCompatibility''                     <--this matches my platform

We will be using the SqueakLinux64x86w32CompatBuilder in tandem with Tests during Configuration development.'


]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> identifyPlatform [
	^HelpTopic
		title:'Identify Platform'
		contents:
'My target platform is 64 bit Linux on X86 with 32 bit compatibility libraries stored in /usr/lib.

I identify my Platform in the existing CMakeVMMakerSqueak-xyz class categories.  


If I wanted a configuration for MacOSX32x86, I would place my configuration in CMakeVMMakerSqueak-MacOSX32x86.
If SunOSx3x86 then CMakeVMMakerSqueak-SunOS32x86.
etc.

For a discussion on naming conventions evaluate:
HelpBrowser openOn: CMakeVMMakerSqueakOverviewHelp
'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> identifyPlatformAbstractBaseClass [
	^HelpTopic
		title:'Identify Abstract Base Class '
		contents:
'My new configuration must be a subclass of my Platform''s Abstract Base Class. 

A Platform Abstract Base Class encapsulates common platform information. 

In CMakeVMMakerSqueak-Linux64X86-32BitCompatibility class category I see two Abstract Base Classes (typically there is only one). They are:

Linux64x86w32BitConfigUsrLib 
Linux64x86w32BitConfigUsrLib32

The Suffixes ''UsrLib'' and ''UsrLib32'' refer to the location of the 32 bit compatablity libs. 
On my system they are in /usr/lib,  so I choose  Linux64x86w32BitConfigUsrLib as my Abstract Base Class

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

{ #category : #accessing }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> key [
	^'CMakeVMMakerSqueakStepByStepNewConfigurationHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> methodRedirectPattern [
	^HelpTopic
		title:'Review of Method Redirect Pattern'
		contents:
'The CPlatformConfigForSqueak provides methods that must be implemented at some level in the CPlatformConfigForSqueak hierarchy. 
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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> overview [
	^HelpTopic
		title:'Overview'
		contents:
'This Help Topic presents the workflow the author used in creating the  Squeak, Cog, Spur CMake configuration for a 64 bit Slackware 14.1 system.with 32 bit compatability libs in /usr/lib

Although some details will be different, the steps involved should be the same for any platform.'
]

{ #category : #accessing }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> pages [
	^#(overview 
tests 
identifyPlatform 
identifyPlatformAbstractBaseClass
identifyBuilder
createTheConfiguration
excludingConfigFromBuilds
setAvailableBuildTypes
firstCMakeGeneration
tackingStockOne
cPlatformConfigForSqueak
methodRedirectPattern
theVMGenerator
tackingStockTwo
forTheImpatient
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

setConfigurationDirectory
setOutputDirectory
settingPlugins
compilingLinkingSetup
customizeVMDrivers
customizePlugins
aNoteOnFoo
)

"	^#(overview 
tests 
identifyPlatform 
identifyPlatformAbstractBaseClass
identifyBuilder
createTheConfiguration
excludingConfigFromBuilds
setAvailableBuildTypes
firstCMakeGeneration
theVMGenerator
reviewMethodRedirectPattern
setOutputDirectory
settingPlugins
compilingLinkingSetup
customizeVMDrivers
customizePlugins
aNoteOnFoo
)"
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> preferredIncludes [
	^HelpTopic
		title:'preferredIncludes'
		contents:
'SystemNavigation browseAllImplementorsOf: #preferredIncludes

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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> setAvailableBuildTypes [
	^HelpTopic
		title:'Setting Available Build Types'
		contents:
'Configurations  inform Builders what BuildTypes they support. via the availableBuildTypes method

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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> setConfigurationDirectory [
	^HelpTopic
		title:'Set Configuration Directory'
		contents:
'
Need the squeak.cog.spur directory here.


'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> setCoreSources [
	^HelpTopic
		title:'setCoreSources'
		contents:
'SystemNavigation browseAllImplementorsOf: #setCoreSources:

We see that this is a top-level Configuration method that writes a CMake Set(foo, bar) construct.

There is nothing for us to do here.'



]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> setCrossSources [
	^HelpTopic
		title:'setCrossSources'
		contents:
'SystemNavigation browseAllImplementorsOf: #setCrossSources:

We see that this is a top-level Configuration method that writes a CMake Set(foo, bar) construct.

There is nothing for us to do here.'

]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> setExecutableOutputPath [
	^HelpTopic
		title:'setExecutableOutputPath'
		contents:
'SystemNavigation browseAllImplementorsOf: #setExecutableOutputPath

 We see that this is implemtented in CPlatformConfigForSqueak.

It creates a CMakeSet object and sets the ''EXECUTABLE_OUTPUT_PATH'' variable to self outputDir

SystemNavigation browseAllImplementorsOf: #outputDir

This look customizable too, but I doubt we need it.

'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> setExtraSources [
	^HelpTopic
		title:'setExtraSources'
		contents:
'SystemNavigation browseAllImplementorsOf: #setExtraSources

We see that this is a top-level Configuration method that writes a CMake Set(foo, bar) construct.

There is nothing for us to do here.
'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> setGlobalOptions [
	^HelpTopic
		title:'setGlobalOptions: self'
		contents:
'For this method there is nothing to do. Here is why.

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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> setGlobalOptionsAfterDetermineSystem [
	^HelpTopic
		title:'setGlobalOptionsAfterDetermineSystem'
		contents:
'SystemNavigation browseAllImplementorsOf: #setGlobalOptionsAfterDetermineSystem:


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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> setOutputDirectory [
	^HelpTopic
		title:'Set Output Directory'
		contents:
'The output directory is where the finished product is placed when the compilation is successful.

Typically this is ''oscogvm/cmake.products/foo/

The topmost configuration CPlatformConfigForSqueak defines the output directory as such:

outputDir
	"the directory where built binaries will be stored"
	^ outputDir ifNil: [ outputDir := (self topDir / self dirOutput /  self dirInstall) ]	

which (on linux) translates to ''oscogvm/cmaike.products/(subclass resposibility))''

Its that (subclass responsibility) we have to customize in our new configuration.

The convention we use is [Language][VM][MemoryModel]

Since I am building a Squeak Cog V3 configuration, my method should return "squeak.cog.v3"

If you look at implementors of dirInstall, you will see that they typically return some pre-defined strings that are defined in the ''cmake directory'' protocol of CPlatformConfigForSqueak.

For my configuration you can see that I return the "^self squeakCogV3" which returns the directory name that matches the [Language][VM][Memory Model] pattern I need.




'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> setPlatformSources [
	^HelpTopic
		title:'setPlatformSources'
		contents:'
SystemNavigation browseAllImplementorsOf: #setPlatformSources:

We see that this is a top-level Configuration method that writes a CMake Set(foo, bar) construct.

There is nothing for us to do here.'

]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> settingPlugins [
	^HelpTopic
		title:'Setting Plugins'
		contents:
'Write Me.'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> standardIncludes [
	^HelpTopic
		title:'standardIncludes'
		contents:
'As of CMakeVMMakerSqueak-tty.114 the method is a legacy method from the pharo CPlatformConfig. It is expect it (and this help page!) will go away on a refactoring pass when the dependency on the pharo package is removed.


SystemNavigation browseAllImplementorsOf: #standardIncludes

CPlatformConfig browseHierarchy

In the CPlatformConfigForSqueak>>standardIncludes, we see the Method Redirect Pattern employed. Since this is for buildType #build, the method will re-route to self standardIncludesBuild.

SystemNavigation browseAllImplementorsOf: #standardIncludesBuild

The SqueakUnixConfig just writes some debug messages. 

There is nothing for us to do here.'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> tackingStockOne [
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
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> tackingStockTwo [
	^HelpTopic
		title:'Taking Stock II'
		contents:
'To recap, at this point, we have 
1. Created a Configuration for a specific platform, language, VM and memory model .
2. Invoked the appropriate  Builder for that Configuration asking it to ...
	2.a configure itself for a specific BuildType and 
	2.b asked it to ouput its content to a specific directory.
3. Confirmed that the Configuration outputs its data.

We know that

Configuration is performed at the highest appropriate Configuration with fine-tuning at the lower Configuration levels.
The Method Redirect Pattern is implemented in CPlatformConfigForSqueak. It is boilerplate code.
A specific Configuration may override a Method Redirect method for a particular build type to provide custom output
The CMakeVMGeneratorForSqueak takes our Configuration as input via the Visitor pattern and  executes the Method Redirect methods in a predictable way based on the Configurations buidType..


The remainder of this Example Workflow will be the customization of the Linux64x86w32BitSqueakCogSpurConfig and generating a working build.

To do this by taking each statement in the CMakeVMGeneratorForSqueak>>generateByTemplate cascade in turn.


'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> tests [
	^HelpTopic
		title:'Tests'
		contents:
'We start with Tests.

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

As we create the Configuration these tests will be an important check on our work and we will return to them often.'
]

{ #category : #pages }
CMakeVMMakerSqueakStepByStepNewConfigurationHelp class >> theVMGenerator [
	^HelpTopic
		title:'The CMakeVMGeneratorForSqueak class'
		contents:
'Before we move onto setting the most common directives and flags in the Concrete Configuration, lets take a quick look at the class and  method that actually generates the CMake files for us. 

CMakeVMGeneratorForSqueak browseHierarchy


CMakeVMGeneratorForSqueak implements the Visitor Design pattern. It takes as input a Configuration and it operates on that Configuration in a methodical manner.

The CMakeVMGeneratorForSqueak has in instance variable named ''config''. This variable is our Configuration.

The methodical operation on the Configuration occur in its generateByTemplate method.

To see this, look at the generateByTemplate method and the long cascade that starts with:

	config 
		setGlobalOptions: self;    
		cmakePrefixPath;
		cmakeIncludePath;.....


Here you see the generator iterating over the CPlatformConfigForSqueak Method Redirect methods.

SystemNavigation new browseAllImplementorsOf: #cmakeIncludePath localTo: CPlatformConfigForSqueak.

Here you see that based on the Configurations buildType, the appropriate Redirect Method out of 
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

is executed.


For debugging and troubleshooting you new Configuration, CMakeVMGeneratorForSqueak>>generateByTemplate enables you to step through CMake generation in an entirely predictable way.

Let''s recap next.
'


]
