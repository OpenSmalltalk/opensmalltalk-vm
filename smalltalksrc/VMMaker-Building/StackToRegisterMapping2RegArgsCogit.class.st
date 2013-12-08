Class {
	#name : #StackToRegisterMapping2RegArgsCogit,
	#superclass : #StackToRegisterMappingCogit,
	#category : #'VMMaker-JIT'
}

{ #category : #'calling convention' }
StackToRegisterMapping2RegArgsCogit >> numRegArgs [
	<api>
	"Use of the macro allows the compiler to avoid the call and test in cointerpreter.c"
	<cmacro: '() 2'>
	^2
]
