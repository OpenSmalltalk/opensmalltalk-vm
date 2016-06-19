Class {
	#name : #Linux64x64SqueakCogSpurConfig,
	#superclass : #Linux64x64Config,
	#category : #'CMakeVMMakerSqueak-Linux64x64'
}

{ #category : #accessing }
Linux64x64SqueakCogSpurConfig class >> isAbstractBaseClass [
	^false

]

{ #category : #cmake }
Linux64x64SqueakCogSpurConfig >> availableBuildTypes [ 
"2.14.12.09 only buildType implemented is #build so I remove #build from the below OrderedCollection."
	^SqueakCMakeVMMakerAbstractBuilder  default  allBuildTypes copyWithoutAll: #( #buildAssert #buildAssertITimerHeartbeat #buildDebug #buildDebugITimerHeartbeat #buildITimerHeartbeat #buildMultiThreaded #buildMultiThreadedAssert #buildMultiThreadedDebug #buildNone)
]

{ #category : #'source generation' }
Linux64x64SqueakCogSpurConfig >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #'source generation' }
Linux64x64SqueakCogSpurConfig >> compilerDefinitionsBuild [
	"cat oscogvm/build.linux64x64/squeak.cog.spur/build/mvm and get values from there"
	^#(
	 '-DNDEBUG'          
 	 '-DDEBUGVM=0'
	 ' -DLSB_FIRST=1'
	 '-D_GNU_SOURCE'
 	 '-DCOGMTVM=0') .

]

{ #category : #'source generation' }
Linux64x64SqueakCogSpurConfig >> compilerFlagsBuild [
	"cat oscogvm/build.linux64x64/squeak.cog.spur/build/mvm and get values from there"
	self flag:'tty: O1 or O2 depends on gcc version.  How can CMake set this for us?'.
	^#('-g'
	     '-O1'
		'-msse2'
            '-fwrapv'
 	      '-m64') 


"	^#('-g'
	     '-O2'
 	      '-m64') "

]

{ #category : #cmake }
Linux64x64SqueakCogSpurConfig >> dirBuildLanguageVMMM [
	^self squeakCogSpur
]

{ #category : #'cmake directory objects' }
Linux64x64SqueakCogSpurConfig >> dirSource [
	^self spursrc
]

{ #category : #cmake }
Linux64x64SqueakCogSpurConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^false
]

{ #category : #'cmake buildType redirects' }
Linux64x64SqueakCogSpurConfig >> externalLibsBuild [
	^self externalLibraries asOrderedCollection.

]

{ #category : #'source generation' }
Linux64x64SqueakCogSpurConfig >> interpreterClass [
	^ CoInterpreter
]

{ #category : #'cmake buildType redirects' }
Linux64x64SqueakCogSpurConfig >> setPlatformSourcesBuild:aMaker [
	|mysubset iwantonly|

	"trim the platformSources collection .c files I want.  for  this OS/platform"
	self flag:'tty. go through the Cog svn tree and see exactly what files should be included here. debug.c feels wrong'.
	iwantonly := #(		
	'aio.c'
	'debug.c'	
	'osExports.c'
	'sqUnixCharConv.c'
	'sqUnixExternalPrims.c'
	'sqUnixHeartbeat.c'
	'sqUnixMain.c'
	'sqUnixMemory.c'
	'sqUnixSpurMemory.c'	
	'sqUnixThreads.c'
	'sqUnixVMProfile.c'
	).		
	mysubset := platformSources select: [:c | 0 < (iwantonly occurrencesOf: c)]. 
	platformSources := mysubset.
	super setPlatformSourcesBuild:aMaker
]
