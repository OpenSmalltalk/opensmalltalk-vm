Class {
	#name : #SqueakMacintoshConfig,
	#superclass : #CPlatformConfigForSqueak,
	#instVars : [
		'resourcesDir'
	],
	#category : #CMakeVMMakerSqueak
}

{ #category : #'compiler flags' }
SqueakMacintoshConfig >> commonCompilerFlags [
	"Macintosh Common compiler flags"
	self flag:'tty'. "cut-n-paste from representative pharo macOS configs"
	^ { 
		'-fmessage-length=0'. 
		'-Wno-trigraphs'. 
		'-fpascal-strings'. 
		'-fasm-blocks'. 
		'-DCOGMTVM=0'. 
		'-DUSE_GLOBAL_STRUCT=0'. 
		'-DTARGET_API_MAC_CARBON'. 
		'-DBUILD_FOR_OSX'. 
		'-DHAVE_SYS_TIME_H'. 
		'-mmacosx-version-min=10.5' }	

]

{ #category : #'compiler flags' }
SqueakMacintoshConfig >> compilerFlags [
	self subclassResponsibility
]

{ #category : #'compiler flags' }
SqueakMacintoshConfig >> compilerFlagsDebug [

	^ {
		'-g3'. 
		'-O0'. 
		'-Wmissing-prototypes'. 
		'-Wmissing-braces'. 
		'-Wparentheses'. 
		'-Wunused-function'. 
		'-Wunused-label'. 
		'-Wunused-parameter'. 
		'-Wunused-variable'. 
		'-Wunused-value'. 
		'-Wsign-compare'. 
		'-DDEBUGVM=1'. 
		'-DEXTERNALPRIMSDEBUG=1'. 
		'-gdwarf-2' }
]

{ #category : #'compiler flags' }
SqueakMacintoshConfig >> compilerFlagsRelease [
" -mdynamic-no-pic "
	^ {
		'-gdwarf-2'. 
		'-O3'. 
		'-funroll-loops'. 
		'-ftree-vectorize'. 
		'-msse3'. 
		'-DDEBUGVM=0'. 
		'-DNDEBUG'. 
		'-Wunused-value'. 
		'-Wuninitialized'. 
		'-falign-functions=16'. 
		'-fno-gcse'. 
		'-mtune=prescott'. 
		'-march=pentium-m'. 
		'-mfpmath=sse'. 
		'-finline-functions'. 
		'-Wall'. 
		'-DUSE_INLINE_MEMORY_ACCESSORS' }
]

{ #category : #accessing }
SqueakMacintoshConfig >> defaultDirectoriesFromGitDir: gitRepository [
	"Set the default values for all necessary directories taking into account the Git repostiory. An example to use this method is:
	MTCocoaIOSCogJitDebugConfig new
	defaultDirectoriesFromGitDir: '/Users/mariano/Pharo/vm/git/cogVM/blessed';
	generateSources; 
	generate.
	"
	| gitRepositoryString |
	self flag:'tty'. "Squeak don't git"
	gitRepositoryString :=  gitRepository, '/'.
	self srcDir: gitRepositoryString, self srcDirName.
    	self platformsDir: gitRepositoryString, self platformsDirName.
    	self buildDir: gitRepositoryString, self buildDirName.
	self resourcesDir: gitRepositoryString, self resourcesDirName.
	self outputDir: gitRepositoryString, self outputDirName.
	
	
	
]

{ #category : #accessing }
SqueakMacintoshConfig >> executableType [
	^ 'MACOSX_BUNDLE'
]

{ #category : #accessing }
SqueakMacintoshConfig >> externalModulesDir [
	"answer the location in VM bundle, where plugins and rest of dynamic libs will be copied,
	by default, it is Framerowks subdir. i.e: 
	
		Cog.app/Contents/Frameworks
		
	"
	
	^ '${outputDir}/', self executableName, '.app/Contents/MacOS/Plugins'
]

{ #category : #'source files' }
SqueakMacintoshConfig >> extraSources [
	self subclassResponsibility
]

{ #category : #accessing }
SqueakMacintoshConfig >> platformName [
	^self macOSPlatformName
]

{ #category : #'source files' }
SqueakMacintoshConfig >> platformSources [
	"files added from platform/Mac OS/vm dir "
	^ #(
	'NSCursorWrappers.m'
	'nsPoolManagement.m'
	'osExports.c'
	'sqMacEncoding.c'
	'sqMacImageIO.c'
	'sqMacMain.c'
	'sqMacMemory.c'
	'sqMacNSPluginUILogic2.c'
	'sqMacTime.c'
	'sqMacUIAppleEvents.c'
	'sqMacUIClipBoard.c'
	'sqMacUIEventsUniversal.c'  " instead of: sqMacUIEvents.c "
	'sqMacUIMenuBarUniversal.c'
	'sqMacUnixCommandLineInterface.c'
	'sqMacUnixExternalPrims.c'
	'sqMacWindowUniversal.c'
	'version.c'	
	)
]

{ #category : #accessing }
SqueakMacintoshConfig >> resourcesDir [ 
	"Answer the value of resourcesDir"
	self flag:'tty'. "I modified resourcesDir to 'assureExistence' from 'fullname'. if this causes problems, look into that"
	^ resourcesDir ifNil: [ resourcesDir := (self topDir / self resourcesDirName) assureExistence ]
	
]

{ #category : #accessing }
SqueakMacintoshConfig >> resourcesDir: anObject [
	"Set the value of platformsDir"

	resourcesDir := anObject
]

{ #category : #accessing }
SqueakMacintoshConfig >> resourcesDirName [
	^self dirBuild, FileDirectory slash,'resources'.
"	^ 'macbuild/resources'"
]
