"
I am a shared pool for the constants that define object layout shared between the object memories (e.g. ObjectMemory, NewObjectMemory), the interpreters (e.g. StackInterpreter, CoInterpreter) and the object representations (e.g. ObjectRepresentationForSqueakV3).

self classPool declare: #Foo from: StackInterpreter classPool
"
Class {
	#name : #VMObjectOffsets,
	#superclass : #SharedPool,
	#classVars : [
		'ClosureFirstCopiedValueIndex',
		'ClosureNumArgsIndex',
		'ClosureOuterContextIndex',
		'ClosureStartPCIndex',
		'HeaderIndex',
		'InstanceSpecificationIndex',
		'InstructionPointerIndex',
		'MethodIndex',
		'ReceiverIndex',
		'SenderIndex',
		'StackPointerIndex',
		'ValueIndex'
	],
	#category : #'VMMaker-Interpreter'
}
