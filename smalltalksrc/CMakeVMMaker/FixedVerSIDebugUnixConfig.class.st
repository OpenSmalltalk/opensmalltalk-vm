"
This is done specifically to track down the instability issues of Cog VM on UNIX


"
Class {
	#name : #FixedVerSIDebugUnixConfig,
	#superclass : #StackInterpreterDebugUnixConfig,
	#category : #'CMakeVMMaker-Unix-Cog'
}

{ #category : #'as yet unclassified' }
FixedVerSIDebugUnixConfig >> compilerFlagsDebug [

	^ '-g3 -O1 -msse2 -save-temps -D_GNU_SOURCE -DDEBUG=1 -DITIMER_HEARTBEAT=1 -DNO_VM_PROFILE=1 -DCOGMTVM=0 -DDEBUGVM=1'


]

{ #category : #'as yet unclassified' }
FixedVerSIDebugUnixConfig >> extraVMSettings: maker [
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
