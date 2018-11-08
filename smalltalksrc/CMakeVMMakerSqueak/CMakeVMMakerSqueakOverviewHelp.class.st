Class {
	#name : #CMakeVMMakerSqueakOverviewHelp,
	#superclass : #CMakeVMMakerSqueakDeveloperHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakOverviewHelp class >> bookName [ 
	^'Overview'
]

{ #category : #accessing }
CMakeVMMakerSqueakOverviewHelp class >> key [
	^'CMakeVMMakerSqueakOverviewHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakOverviewHelp class >> namingConventions [
	"This method was automatically generated. Edit it using:"
	"a HelpBrowser edit: #namingConventions"
	^HelpTopic
		title: 'Naming Conventions'
		contents: 
'[PLATFORM][Language][VM][Memory Manager][BuildType][foo]  IS the naming convention for CMakeVMMakerSqueak

The convention is a bottom-up design starting with Eliot Miranda''s Cog layout at 
http://www.squeakvm.org/svn/squeak/branches/Cog/ 

In the Cog directory tree are build directories. Taking the build.linux32x86 directory as an example, we have a directory tree that looks like this:

build.linux32x86/
|-- newspeak.cog.spur
|   |-- build
|   |-- build.assert
|   |-- build.assert.itimerheartbeat
|   |-- build.debug
|   |-- build.debug.itimerheartbeat
|   `-- build.itimerheartbeat
|-- newspeak.cog.v3
|   |-- build
......etc... .

The FORM of this layout is  :

build.[PLATFORM]/
|-- [Language].[VM].[Memory Manager]/
|   |-- [BuildType]

It is this form that drives a parallel naming convention and directory structure in CMakeVMMakerSqueak. 

The parallel directory structure simply prefixes a ''cmake." to the directory name.

cmake.build.[PLATFORM]/
|-- [Language].[VM].[Memory Manager]  
|   |-- [BuildType]


Builders have the form: Squeak[Platform]Builder. 
Example: SqueakBSD32x86Builder

AbstractBaseClass Configurations have the form: [Optional Prefix][Platform]Config.
Example: Linux32x86Config

Concrete Configurations have the form: [Optional Prefix]][Platform] [Language] [VM] [MemoryManager] [Optional Suffix] Config
Linux32x86SqueakCogV3Config

When the Linux32x86SqueakCogV3Config is  configured for the buildType #build.debug it will map its output to cmake.build.linux32x86/squeak.cog.v3/build.debug/

The naming convention for Configurations takes the following form:
[Optional Prefix]][Platform] [Language] [VM] [MemoryManager] [Optional Suffix] Config.

As of 2014.12.09 the possible combinatons are:

[Prefix][Platform][Newspeak | Squeak][Cog | Sista | Stack][V3 | Spur][Foo]Config.


!' readStream nextChunkText
]

{ #category : #pages }
CMakeVMMakerSqueakOverviewHelp class >> overview [
	^HelpTopic
		title:'Overview'
		contents:
'"CMake drives development."

Keeping the above statement in mind is the key to this package. 

What we are looking for is a CMake system that correctly builds a virtual machine on a given platform. 
We then encapsulate that CMake system state in CMakeVMMakerSqueak Configurations. The end user can then reproduce that CMake system on their platform.

Hopefully this package makes the above process predictable and somewhat sane.

Towards that end, this system does the following :

Stores CMake configuration in concrete subclasses of CPlatformConfigForSqueak in a predicatable manner.
Provides methods for extracting the CMake configuration from those classes.
Provides a (hopefully) newbie friendly Facade for extracting the CMake configuration via Builders (Concrete subclasses of SqueakCMakeVMMakerAbstractBuilder)
Provides (for the configuration developer) CMake command wrapper code in subclasses of CMakeTemplate.
Proves to be scriptable such that generating the CMake output can be automated (or extracted from a Seaside website).

As the SqueakVM community gains experience with CMake, I expect the quality of the generated CMake output to improve considerably. CMake is a BIG system with LOTS of stuff in it. Storing the knowledge we gain in our Squeak classes should make things a lot easier on us.

The heart of the package is CMakeGeneratorForSqueak and its two subclasses CMakeVMGeneratorForSqueak and CMakePluginGeneratorForSqueak.

CMakeVMGeneratorForSqueak collects information from subclasses of CPlatformConfigForSqueak, CMThirdpartyLibrary and InterpreterPlugins and writes it out to CMake files and associated directories. 

From there, the user invokes cmake and make using a generated build.sh script.

The programmer directs the flow of the generator by coding a subclass of CPlatformConf, setting it up correctly and asking it to generate itself. 

The configuration then invokes the CMakeGeneratorForSqueak passing itself as an argument. 

The VMGeneratator extracts the information and utilizes VMPluginGenerator to generate plugin stuff, the CPlatformConf to generate other stuff and CMThirdPartyLibrary''s to generate other stuff. (TODO: tighten up this language)

The end result is a CMake evironment that is set up to correctly build a VM

Concrete implementations of SqueakCMakeVMMakerAbstractBuilder provide an invokation facade and configuration query capabilities.
'
]

{ #category : #pages }
CMakeVMMakerSqueakOverviewHelp class >> pages [
	^#(overview  prerequisites  namingConventions  )
]

{ #category : #pages }
CMakeVMMakerSqueakOverviewHelp class >> prerequisites [
	^HelpTopic
		title:'Prerequisites'
		contents:
'As of 2016.02.06 CMakeVMMakerSqueak depends on CMakeVMMaker (a pharo implementation). This dependency will be broken in due course.
TODO: Break this dependency TTY

CMake from  http://www.cmake.org/ is required to process the output of this package.

This package was written using cmake version 2.8.12
'
]
