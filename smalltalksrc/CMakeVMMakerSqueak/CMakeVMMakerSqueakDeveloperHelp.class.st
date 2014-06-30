Class {
	#name : #CMakeVMMakerSqueakDeveloperHelp,
	#superclass : #CMakeVMMakerSqueakHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakDeveloperHelp class >> bookName [ 
	^'Developer Guide'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> buildersAndConfigs [
	^HelpTopic
		title:'Organization'
		contents:
'
The CMakeVMMakerSqueak Builders and Configurations are organized to mirror  Eliot''s GNU build system organization.

The intent is to reduce brain cycles translating from the computer''s directory layout to what you see in CMakeVMMakerSqueak by providing a (nearly) one-to-one correspondence.

Eliot has named build directories in Cog/ svn (oscogvm directory in this system) by the convention
build.[OperatingSystem].[VMWordSize].[Processor Architecture]. For  example: build.macosx32x86 

Under each build.[OperatingSystem].[VMWordSize].[Processor Architecture]  directory are subdirectories for each
[Language][VM][MemoryManager]. example newspeak.sista.spur.

The permutations of [Language][VM][MemoryManager] currently are: 

[newspeak | squeak]. [cog | sista | stack]. [spur | v3] or 2! x 3! x 2!  which is  between 12 and eleventy billion permutations 

Similarly, in CMakeVMMakerSqueak,  Categories containing Configurations are organized by CMakeVMMakerSqueak-[OperatingSystem][VMWordSize][Processor][etc]

Configuration classes within a CMakeVMMakerSqueak-[OperatingSystem][VMWordSize][Processor][etc] are Named:
[[Squeak] | [] ][Language][VM][MemoryManager][etc]Config and correspond with the 12 permutations

When CMakeVMMakerSqueak generates build or products , it prefaces Eliot''s naming convention with a ''cmake.''

for example builds take place in:  cmake.build.linux.32.x66/squeak.cog.spur
and output is placed in cmake.products. for example: oscogvm/cmake.products/squeak.cog.v3.noGL/

Builders manage Configurations and Builds for a particular [Language][VM][MemoryManager]  category.
THERE IS A ONE-TO-ONE CORRESPONEDENCE between aConcreteBuilder>configurationsCategory and the Smalltalk Category name. 
If you change one, you must change the other in order for the Builder to manage that configuration.

example: SqueakMacOSX32x86Builder configurationsCategory



'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> igorStasenkoDesign [
	^HelpTopic
		title:'Design Patterns'
		contents:
'CMakeVMMakerSqueak extends Igor Stasenko''s pharo work in CMMakeVMMaker. 

The system employs the Visitor design pattern in two places.

1. When a CPlatformConfigForSqueak subclass invokes CMakeVMGeneratorForSqueak>>generate passing itself as the visitor.
2. In SqueakCMakeVMMakerAbstractBuilder when Configuration information is cached in a CMakeVMakerConfigurationInfo.

The CPlatformConfigForSqueak makes heavy use of a Template pattern. This pattern is used extensively in the protocol ''cmake buildType redirects''.
This is used to force correct implementation of configurations. It also extends the pharo system to support the build types required for the 

Fairly extensive Tests are written to ensure correct implementation of Configurations.

'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> overview [
	^HelpTopic
		title:'Overview'
		contents:
'
The heart of the package is CMakeGeneratorForSqueak and its two subclasses CMakeVMGeneratorForSqueak and CMakePluginGeneratorForSqueak.


CMakeVMGeneratorForSqueak collects information from subclasses of CPlatformConfigForSqueak, CMThirdpartyLibrary and InterpreterPlugins and writes it out to CMake files and associated directories. 

From there, the user invokes cmake and make using a generated build.sh script.

The programmer directs the flow of the generator by coding a subclass of CPlatformConf, setting it up correctly and asking it to generate itself. 

The configuration then invokes the CMakeGeneratorForSqueak passing itself as an argument. 

The VMGeneratator extracts the information and utilizes VMPluginGenerator to generate plugin stuff, the CPlatformConf to generate other stuff and CMThirdPartyLibrary''s to generate other stuff. 

The end result is a CMake evironment that is set up to correctly build a VM

Concrete implementations of SqueakCMakeVMMakerAbstractBuilder provide an invokation facade and configuration query capabilities.


'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> pages [
	^#(overview prerequisites  terms igorStasenkoDesign  buildersAndConfigs plugins pthreads)
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> plugins [
	^HelpTopic
		title:'Plugins'
		contents:'

TODO explain the design and methodology of the ''plugin extra rules'' protocol in


provide example of mapping from plugins.int to defaultInternalPlugins

|s|
Transcript clear.
s:=SortedCollection new.
InterpreterPlugin allSubclassesDo:[:p|
	p moduleName = ''B2DPlugin''
		ifTrue:[Transcript show:p name].
	s add: (p moduleName)].

Transcript show: s.

SqueakUnixConfig browse
'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> prerequisites [
	^HelpTopic
		title:'Prerequisites'
		contents:
'The CMakeVMMakerSqueak depends on CMakeVMMaker (a pharo implementation)

CMake from  http://www.cmake.org/ is required to process the output of this package.

This package was written using cmake version 2.8.12
'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> pthreads [
	^HelpTopic
		title:'PThreads'
		contents:'

http://www.mirandabanda.org/files/Cog/VM/VM.r3006/README.3006

N.B. For Squeak/Pharo/Croquet please use the archives whose names begin with
     Cog or cog.  The archives whose names begin with nsvm or Newspeak are
     for Newspeak and are missing plugins required by Squeak/Pharo/Croquet.
     VMs with "mt" or "MT" in the name are multi-threaded VMs which support
     non-blocking FFI calls.  The archives containing "Spur" or "spur" are
     VMs using the new Spur object representation and garbage collector and
     should be used with Spur-format Squeak/Pharo/Croquet or Newspeak images.

     There are two variants of the Linux VMs; those ending in "ht" have a
     heartbeat thread, while those that don''t, use an interval timer for the
     heartbeat (the Windows and Mac VMs have a threaded heartbeat).  The
     threaded heartbeat is better (for example, signals from the interval timer
     interfere with system calls, etc), but to use it one must have a kernel
     later than 2.6.12 and configure linux to allow the VM to use multiple
     thread priorities.  To do so, create a file called VM.conf where VM is
     the name of the vm executable ("squeak" for the Squeak vm, "nsvm" for
     the Newspeak vm) in /etc/security/limits.d/ with contents:
*       hard    rtprio  2
*       soft    rtprio  2

     e.g.
sudo cat >/etc/security/limits.d/squeak.conf <<END
*       hard    rtprio  2
*       soft    rtprio  2
END
sudo cp /etc/security/limits.d/squeak.conf /etc/security/limits.d/nsvm.conf
     Then log out and log back in for the limits to take effect.


On Slackware linux 14.0  
bash$ man limits

From the man page, the O (oh) option is:   O: max real time priority

create a file /etc/limits file and add an entry

tty O100

where tty is the login name, and the O option is set to 100.

Logout and re-login.


'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> terms [
	^HelpTopic
		title:'Terms'
		contents:
'
AbstractBaseClass:   
	Typically the topmost class in a [OS][VMWordSize][Processor][ETC]  class category. Example: CPlatformConfigForSqueak. Most of the configuration action happens at this level and lower.

Builder:                      
	A concrete subclass of SqueakCMakeVMMakerAbstractBuilder. Builders act as a facade for invoking the configurations.They also provide query tools for the configurations that a builder manages. There is a one-to-one correspondence between a Builder''s configurationsCategory and the configurations it manages. example:    SqueakBSDx86Builder configurationsCategory

buildType:
	One of SqueakCMakeVMMakerAbstractBuilder  allBuildTypes 
                                 

CMakeLists.txt:
	The instructions that CMake uses to build build systems.  One output of a configuration

Configuration:            
	CPlatformConfigForSqueak  and its subclasses. These maintain the definitions that are rendered into CMakeLists.txt files


Generator:                 
	CMakeGeneratorForSqueak and its subclasses


Redirect Methods:      
	Given a method X, it is a redirect method if a call to it redirects to xBuildType based on the state of the configurations buildType  buildType variable.  See CPlatformConfigForSqueak protocol ''cmake buildType redirects''




'
]
