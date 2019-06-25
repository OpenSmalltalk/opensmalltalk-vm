Class {
	#name : #CMakeVMMakerSqueakDesignPatternsHelp,
	#superclass : #CMakeVMMakerSqueakDeveloperHelp,
	#category : #'CMakeVMMakerSqueak-Help'
}

{ #category : #accessing }
CMakeVMMakerSqueakDesignPatternsHelp class >> bookName [ 
	^'Design Patterns'
]

{ #category : #accessing }
CMakeVMMakerSqueakDesignPatternsHelp class >> key [
	^'CMakeVMMakerSqueakDesignPatternsHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakDesignPatternsHelp class >> overview [
	^HelpTopic
		title: 'Overview'
		contents:
'CMakeVMMakerSqueak makes heavy use of several design patterns.

They include:

Method Redirect Pattern*.
Visitor Pattern.


*N.B. tty. It might have a different name, I just named it that for reasons that will be apparent.

'
]

{ #category : #pages }
CMakeVMMakerSqueakDesignPatternsHelp class >> pages [
	^#( overview 
visitorPattern 
redirectPattern 
redirectPatternMotivation
redirectPatternInvocation 
redirectPatternImplementation 
redirectPatternHeirarchy
redirectPatternSummary)
]

{ #category : #accessing }
CMakeVMMakerSqueakDesignPatternsHelp class >> priority [

	^ 8
]

{ #category : #pages }
CMakeVMMakerSqueakDesignPatternsHelp class >> redirectPattern [
	^HelpTopic
		title: 'Method Redirect Pattern'
		contents:
'What I call The Method Redirect Pattern* is used extensivelly in CPlatformConfigForSqueak.

Its use is very consistent and intuitive once the reasoning behind it is grasped and its structure understood.

I discuss this in five parts:

Motivation
Invocation
Implementation
Heirarchy
Summary


*N.B. tty. It might have a different name, I just named it that for reasons that will be apparent.
'
]

{ #category : #pages }
CMakeVMMakerSqueakDesignPatternsHelp class >> redirectPatternHeirarchy [
	^HelpTopic
		title: 'Method Redirect Heirarchy'
		contents:
'To get a sense of the hierarchy and this pattern browse 

ToolSet browseMessageCategory: ''cmake buildType redirects''  inClass:CPlatformConfigForSqueak

Under the ''cmake buildType redirects'' protocol we see coreSourcesBuld and coreSourcesBuilMultiThreaded.

Under 
coreSourcesBuild
	"files to include from src/vm dir"
	^ #(
		''cogit.c''
		''gcc3x-cointerp.c''                    <--single threaded version
		)

We see single c files for a single-threaded interpreter, while under

coreSourcesBuildMultiThreaded
	"files to include from src/vm dir"
	^ #(
		''cogit.c''
		''cointerpmt.c''                         <--multi threaded version
		)

We get the multi-threaded version.

Continuing down the heirarchy to Linux64x86w32BitSqueakCogV3Config we see the real power of this in its redirect methods:

Here we can set compiler flags, linker flags, libraries, and pre-processor flags that are customized for each build type.

To put this in terms of Eliot''s Autotools directory hierarchy these methods map directly to the .mvm files in his various build directories.


'
]

{ #category : #pages }
CMakeVMMakerSqueakDesignPatternsHelp class >> redirectPatternImplementation [
	^HelpTopic
		title: 'Method Redirect Implementation'
		contents:
'Implementation is very straight forward.

Pictorially it looks like this:
#buildITimerHeartbeat #buildMultiThreaded  
                                       --are redirected to---> #build 

And this: 
#buildAssert #buildAssertITimerHeartbeat #buildDebugITimerHeartbeat#buildMultiThreadedAssert #buildMultiThreadedDebug 
                                                                                                                                                                     -- are redirected to---> #buldDebug 


In code:

setGlobalOptionsBuildMultiThreaded: aMaker
	^self setGlobalOptionsBuild: aMaker                   <----redirect to #build


setGlobalOptionsBuildAssertITimerHeartbeat: aMaker
	^self setGlobalOptionsBuildDebug: aMaker               <----redirect to #buildDebug


Any Configuration in the CPlatformConfigForSqueak heirarchy can override any of these Redirect Methods to provide custom results for any build type at any step in the generate process.


The Implementation is a bit of over-kill in many instances. However, I find the idea of boiler-plate consistency is easier to code and comprehend for newbie coders.
Getting newbie-coders comfortable writing configurations is a goal of this project.

'
]

{ #category : #pages }
CMakeVMMakerSqueakDesignPatternsHelp class >> redirectPatternInvocation [
	^HelpTopic
		title: 'Method Redirect Invocation'
		contents:
'Invocation of the Method Redirect Pattern occurs in CMakeVMGenratorSqueak (and possibly in Plugins, but I forget)

To provide context, browse CMakeVMGeneratorForSqueak  >> generateByTemplate and look at the cascade that starts with

	config 
		setGlobalOptions: self;    
		cmakePrefixPath;
		cmakeIncludePath;
            ....
By the time the Configuration gets to this point the Configuration has configured itself for a particular build type out of the universe of buildTypes provided by
SqueakCMakeVMMakerAbstractBuilder allBuildTypes 

The Configuration then "visits" the CMakeVMGeneratorSqueak and the generator starts sending it the messages in the above cascade.

Lets look at  CPlatformConfigForSqueak >> setGlobalOptions: self 
since it is first in the cascade.

CPlatformConfigForSqueak >>
setGlobalOptions: aMaker
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

Here, a copy of an existing Dictionary (used for other purposes elsewhere) is modified to containing blocks to be executed for a particular buildType.

When the Dictionary is populated with these blocks, the block is executed that corresponds to the configurations current buildType.

The 	^(d at: buildType) value evaluates that block and returns its result.

So, when I evaluate:

SqueakLinux64x86w32CompatBuilder
	configureA: #Linux64x86w32BitSqueakCogV3Config forBuildType:#buildMultiThreadedDebug; 
	generateByTemplate.

The Linux64x86w32BitSqueakCogV3Config sets its buildType to #buildMultiThreadedDebug.
When the CMakeVMGeneratorForSqueak send the message ...

	config 
		setGlobalOptions: self;   
            ...

The configuration method that actually gets executed is 
	self setGlobalOptionsBuildMultiThreadedDebug: aMaker 


Ok, that''s how the invocation works. '
]

{ #category : #pages }
CMakeVMMakerSqueakDesignPatternsHelp class >> redirectPatternMotivation [
	^HelpTopic
		title: 'Method Redirect Pattern Motivation'
		contents:
'The motivation for the Redirect Pattern is to reduce the number of concrete configurations by encapsulating every possible build type in one concrete configuration

If you look at the pharo CMakeVMMaker package,  under the CMakeVMMaker-Unix class category, note the existence of StackUnixConfig and its child class StackUnixDebugConfig.   It is the "Debug" that is the problem.  The pharo team supports two build types: Release and Debug, while the Squeak team supports (currently) 10 build types. By adopting the pharo strategy of creating a new sub-class for each buildType the number of Concrete Configurations becomes--in my view--too many.

Here is the math: 

A configurations [PLATFORM]x[Language]x[VM]x[Memory Manager]x[buildType] form expands to:
 [BSD32x64. | .....| SunOS32x86] x [Newspeak | Squeak ]. [Cog | Stack  ] [V3 | Spur]   [#build | #build.debug| ...| #buildMultiThreadedDebug]

which in combination yeilds (as of today)

[10 platforms] x [2 languages] x [2 VM''s] x [2 Memory Managers] x [10 buildTypes] = 600 concrete configurations. 

By implementing the redirect pattern, the buildType is handled within a single concrete implementation. and math becomes a much more manageable

[10 platforms] x [2 languages] x [2 VM''s] x [2 Memory Managers] = 60 concrete configurations.

It is for this reason that I implemented this design pattern.

An explanation of the naming convention is available by evaluating
HelpBrowser openOn: CMakeVMMakerSqueakOverviewHelp'
]

{ #category : #pages }
CMakeVMMakerSqueakDesignPatternsHelp class >> redirectPatternSummary [
	^HelpTopic
		title: 'Method Redirect Summary'
		contents:
'The motivation for the Redirect Pattern is to reduce the number of concrete configurations by encapsulating every possible build type in one concrete configuration. This is accomplished by redirecting sends to a single method to a method appropriate for that build type.


A fair critique is to ask "Why the overkill with all the methods when you only use a subset and it is doubtful that a particular one will need to be over-ridden?"

The answer is that I find it easier to understand--and I believe easier for newbies to understand--the source code when it is consistently applied. 

Secondly, adding new redirect methods is straighforward boilerplate--just a matter of copy-n-paste-rename. 

Thirdly it reduces brain-cycles when debugging.
'

]

{ #category : #pages }
CMakeVMMakerSqueakDesignPatternsHelp class >> visitorPattern [
	^HelpTopic
		title: 'Visitor Pattern'
		contents:
'The Visitor Pattern is used in several places in the CMakeVMMakerSqueak system.

SqueakCMakeVMMakerAbstractBuilder invokes the Visitor pattern on the CMakeVMakerConfigurationInfo by passing Concrete Builders to its visit: method.  In this pattern, Instances of CMakeVMMakerConfigurationInfo are just data buckets used to make coding a bit easier.

In CMakeVMGeneratorForSqueak and CMakePluginGeneratorForSqueak, the generateByTemplate method''s are a modified version of the Visitor pattern.




'
]
