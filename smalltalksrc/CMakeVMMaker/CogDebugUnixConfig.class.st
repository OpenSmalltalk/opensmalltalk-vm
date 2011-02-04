Class {
	#name : #CogDebugUnixConfig,
	#superclass : #CogUnixConfig,
	#category : #CMakeVMMaker
}

{ #category : #'as yet unclassified' }
CogDebugUnixConfig >> compilerFlags [

	^ '-g3 -O1 -msse2 -D_GNU_SOURCE -DDEBUG -DITIMER_HEARTBEAT=1 
	-DNO_VM_PROFILE=1 -DCOGMTVM=0 -DDEBUGVM=1'


]
