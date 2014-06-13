"
A Linux32x86SqueakCogSpurConfig  configures a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

Usage:
Linux32x86SqueakCogSpurConfig generate
Or:
Linux32x86SqueakCogSpurConfig generateWithSources
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me

"
Class {
	#name : #Linux32x86SqueakCogV3Config,
	#superclass : #Linux32x86Config,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'source generation' }
Linux32x86SqueakCogV3Config >> cogitClass [
	"answer a class for machine code generation or nil"
	
	^ StackToRegisterMappingCogit 
]

{ #category : #'compiler flags' }
Linux32x86SqueakCogV3Config >> commonCompilerFlags [
	^ {
		'-DLSB_FIRST=1'. 
	      '-m32' .
	 } 	
	
]

{ #category : #cmake }
Linux32x86SqueakCogV3Config >> compilerFlagsRelease [
"tty. cut-n-paste from Igor's CogUnixConfig
THIS FLAGS ARE CRASHING COMPILER 
-fschedule-insns2 
-fschedule-insns 

THIS FLAGS ARE CRASHING VM
-ftree-pre  
-fcaller-saves 

THIS FLAGS ARE WORKING 
-O1 -fthread-jumps -falign-functions -falign-jumps -falign-loops -falign-labels -fcrossjumping -fcse-follow-jumps -fcse-skip-blocks -fdelete-null-pointer-checks -fdevirtualize -fexpensive-optimizations -fgcse -fgcse-lm -finline-small-functions -findirect-inlining -fipa-sra -foptimize-sibling-calls -fpeephole2 -fregmove -freorder-blocks -frerun-cse-after-loop -freorder-functions  -fsched-interblock -fsched-spec -fstrict-aliasing -fstrict-overflow  -ftree-switch-conversion -ftree-vrp

THIS IS LIKE: -O2 -fno-tree-pre -fno-caller-saves 

"

	^ {
		'-g0'. 
		'-O2'. 
		'-fno-tree-pre'. 
		'-fno-caller-saves'. 
		'-msse2'. 
		'-D_GNU_SOURCE'. 
		'-DNDEBUG'. 
		'-DITIMER_HEARTBEAT=1'. 
		'-DNO_VM_PROFILE=1'. 
		'-DDEBUGVM=0' }
]

{ #category : #sources }
Linux32x86SqueakCogV3Config >> coreSources [
	"files to include from src/vm dir"
	^ #(
		'cogit.c'
		'cointerp.c'
		)
]

{ #category : #plugins }
Linux32x86SqueakCogV3Config >> defaultExternalPlugins [
	""
	self flag:'tty'. "UUIDPlugin does not build on my linux system. fix this"
	^ (super defaultExternalPlugins copyWithoutAll: #(#UUIDPlugin #UnixOSProcessPlugin))
]

{ #category : #plugins }
Linux32x86SqueakCogV3Config >> defaultInternalPlugins [
	""
	self flag:'tty'. "UUIDPlugin does not build on my linux system. fix this"
	^ (super defaultInternalPlugins copyWithoutAll: #(#VMProfileLinuxSupportPlugin))
]

{ #category : #cmake }
Linux32x86SqueakCogV3Config >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakCogV3
]

{ #category : #cmake }
Linux32x86SqueakCogV3Config >> excludeFromBuild [
	"over-ride to exclude yourself from a build"
	^false
]

{ #category : #accessing }
Linux32x86SqueakCogV3Config >> executableName [
	^ 'CogVM'
]

{ #category : #'source generation' }
Linux32x86SqueakCogV3Config >> interpreterClass [
	^ CoInterpreter
]

{ #category : #'source generation' }
Linux32x86SqueakCogV3Config >> prepareForGeneration [
	^ self prepareForCogGeneration

]

{ #category : #utils }
Linux32x86SqueakCogV3Config >> setExtraTargetProperties: maker [

	maker setTargetProperties: 'LIBS "-lptrhead -luuid"'.
	maker setTargetProperties: 'LDFLAGS "-Wl -z now"'.

	super setExtraTargetProperties: maker.

]
