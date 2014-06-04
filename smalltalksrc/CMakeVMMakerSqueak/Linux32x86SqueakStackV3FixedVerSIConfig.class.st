"
This is done specifically to track down the instability issues of Cog VM on UNIX


Usage:
SqueakStackUnixDebugFixedVerSIConfig generateWithSources
or:
SqueakStackUnixDebugFixedVerSIConfig generate

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #Linux32x86SqueakStackV3FixedVerSIConfig,
	#superclass : #Linux32x86SqueakStackV3DebugConfig,
	#category : #'CMakeVMMakerSqueak-Linux32x86'
}

{ #category : #'as yet unclassified' }
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

{ #category : #'as yet unclassified' }
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
