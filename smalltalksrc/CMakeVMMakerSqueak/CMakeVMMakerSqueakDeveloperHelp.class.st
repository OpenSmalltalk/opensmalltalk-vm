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
CMakeVMMakerSqueakDeveloperHelp class >> configDotCmake [
	^HelpTopic
		title:'config.cmake'
		contents:
'The config.cmake file is included in CMakeLists.txt. 

It contains CMake code to generate a config.h file on unix systems.

You can view a Configurations config.cmake with this code:

Transcript clear.
Transcript show: ((Linux64x86w32BitSqueakCogV3Config new) configureForBuildType: #build) contentForVmConfigCmake

or print it in place with:

((Linux64x86w32BitSqueakCogV3Config new) configureForBuildType: #build) contentForVmConfigCmake   

The config.cmake file is generated with the usual Builder expressions.

SqueakLinux64x86w32CompatBuilder
	configureA: #Linux64x86w32BitSqueakCogV3Config forBuildType:#build;
	generate.


A config.cmake is created from CMake Templates (wrappers) in the CmakeVMMakerSqueak-CMakeTemplates  and CmakeVMMakerSqueak-CMakeCustomTemplates categories.


'
]

{ #category : #accessing }
CMakeVMMakerSqueakDeveloperHelp class >> key [
	^'CMakeVMMakerSqueakDeveloperHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> looseEnds [
	^HelpTopic
		title:'Loose Ends'
		contents:
'As of 2014.12.09 there are the inevitable loose ends. Some are:

CMake provides a Packaging infrastructure that should be imported here.

Importing and compiling 3''rd party libraries has not been ported or tested.

The Builder facades lacks some query functionality.

The Builder facades may prove to be useless--we may want to throw them away.

Tests needed for testing Plugins

Templates should probably be organized by 
cmake --help-command-list
cmake --help-module-list
cmake --help-property-list
cmake --help-variable-list  etc.

'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> pages [
	^#( CMakeVMMakerSqueakOverviewHelp  CMakeVMMakerSqueakBuildersHelp   CMakeVMMakerSqueakConfigurationsHelp    CMakeVMMakerSqueakGeneratorsHelp CMakeVMMakerSqueakTemplatesHelp CMakeVMMakerSqueakDesignPatternsHelp CMakeVMMakerSqueakHistoryHelp )
	

]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> plugins [
	^HelpTopic
		title:'Plugins'
		contents:'

TODO explain the design and methodology of the ''plugin extra rules'' protocol in

Explain CMakePluginGeneratorSqueak containing the config.cmake files


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

{ #category : #accessing }
CMakeVMMakerSqueakDeveloperHelp class >> priority [

	^ 2
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
CMakeVMMakerSqueakDeveloperHelp class >> templates [
	^HelpTopic
		title:'CPlatformConfigForSqueak class templates'
		contents:
'CMakeVMMakerSqueak utilizes wrapper classes on CMake commands to generate CMake output files like CMakeLists.txt.

Currently the 3 class categories produce output as such:

1. CMakeVMMakerSqueak-CMakeCompositeTemplates output large CMake structures. The essentially wrap both custom and standard CMake templates.

2. CMakeVMMakerSqueak-CMakeCustomTemplates typically wrap CMake logic constructs like IF(DEFINED foo;

3. CMakeVMMakerSqueak-CMakeTemplates are wrappers for specific CMake Commands, properties and variables.
cmake --help 
cmake --help-command-list
cmake --help-property-list
cmake --help-variable-list

will give you an idea of what is wrapped. As new templates are introduced, they can be re-used easily, minimizing errors.

'
]

{ #category : #pages }
CMakeVMMakerSqueakDeveloperHelp class >> tests [
	^HelpTopic
		title:'Tests'
		contents:
'
When all tests pass. This does not mean the classes are configured correctly for source,output and build directories.

It does mean nothing structural is preventing that from being implemented.

'
]
