"
This is done specifically to track down the instability issues of Cog VM on UNIX


Usage:
Linux32x86SqueakStackV3FixedVerSIConfig generateWithSources
or:
Linux32x86SqueakStackV3FixedVerSIConfig generate
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me

"
Class {
	#name : #Linux32x86SqueakStackV3FixedVerSIConfig,
	#superclass : #Linux32x86SqueakStackV3DebugConfigz,
	#category : #'CMakeVMMakerSqueak-IslandOfMisfitToys'
}

{ #category : #'source generation' }
Linux32x86SqueakStackV3FixedVerSIConfig >> cogitClass [
	^ StackToRegisterMappingCogit 

]

{ #category : #'compiler flags' }
Linux32x86SqueakStackV3FixedVerSIConfig >> compilerFlagsDebug [

	^ {
		'-g3'. 
		'-O0'. 
		'-msse2'. 
		'-save-temps'. 
		'-D_GNU_SOURCE'. 
		'-DITIMER_HEARTBEAT=1'. 
		'-DNO_VM_PROFILE=1'. 
		'-DCOGMTVM=0'. 
		'-DDEBUGVM=1' }
]

{ #category : #cmake }
Linux32x86SqueakStackV3FixedVerSIConfig >> excludeFromBuild [
	"over-ride to exclude yourself from a build or not"
	^true
]

{ #category : #settings }
Linux32x86SqueakStackV3FixedVerSIConfig >> extraVMSettings: maker [
	| versionC |
	self generateConfigH.
	
	
	"output a fake version.c file"
	
	self write:
'int vm_serial= 1;
char *vm_date= "<HERE IS SUPPOSED TO BE THE DATE>";
char *cc_version= "<HERE IS SUPPOSED TO BE gcc VERSION>";
char *ux_version= "<FAKE FROZEN VERSION FOR DEBUGGING PURPOSES>";
'
	toFile: 'version.c'.

]

{ #category : #'source generation' }
Linux32x86SqueakStackV3FixedVerSIConfig >> interpreterClass [
	^ StackInterpreter
]
