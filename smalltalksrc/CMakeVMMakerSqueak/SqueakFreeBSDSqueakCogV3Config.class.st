"
I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakBSDx86Builder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp


"
Class {
	#name : #SqueakFreeBSDSqueakCogV3Config,
	#superclass : #SqueakBSDConfig,
	#category : #'CMakeVMMakerSqueak-BSD32x86'
}

{ #category : #'source generation' }
SqueakFreeBSDSqueakCogV3Config >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #'compiler flags' }
SqueakFreeBSDSqueakCogV3Config >> compilerFlagsAssert [

	^ {
		'-g3'. 
		'-O0'. 
		'-msse2'. 
		'-D_GNU_SOURCE'. 
		'-DITIMER_HEARTBEAT=1'. 
		'-DNO_VM_PROFILE=1'. 
		'-DDEBUGVM=1' }
]

{ #category : #'compiler flags' }
SqueakFreeBSDSqueakCogV3Config >> compilerFlagsBuild [
	"copied from Cog svn in build.linux32x86/build/mvm"

	^ {'-msse2' . 
           '-D_GNU_SOURCE' .
           '-D_FILE_OFFSET_BITS=64' . 
            '-DCOGMTVM=0'
		}

]

{ #category : #cmake }
SqueakFreeBSDSqueakCogV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogV3
]

{ #category : #cmake }
SqueakFreeBSDSqueakCogV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #cmake }
SqueakFreeBSDSqueakCogV3Config >> executableName [
	^ self vmCogExecutableName
]

{ #category : #'source generation' }
SqueakFreeBSDSqueakCogV3Config >> interpreterClass [
	^ CoInterpreter

]
