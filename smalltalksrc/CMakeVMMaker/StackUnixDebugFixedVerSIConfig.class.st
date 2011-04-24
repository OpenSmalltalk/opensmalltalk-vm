"
This is done specifically to track down the instability issues of Cog VM on UNIX


Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #StackUnixDebugFixedVerSIConfig,
	#superclass : #StackUnixDebugConfig,
	#category : #'CMakeVMMaker-Unix'
}

{ #category : #'as yet unclassified' }
StackUnixDebugFixedVerSIConfig >> compilerFlagsDebug [

	^ '-g3 -O0 -msse2 -save-temps -D_GNU_SOURCE -DDEBUG=1 -DITIMER_HEARTBEAT=1 -DNO_VM_PROFILE=1 -DCOGMTVM=0 -DDEBUGVM=1'


]

{ #category : #'as yet unclassified' }
StackUnixDebugFixedVerSIConfig >> extraVMSettings: maker [
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
