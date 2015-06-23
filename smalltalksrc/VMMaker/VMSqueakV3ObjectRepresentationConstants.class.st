"
I am a shared pool for the constants that define the Squeak V3 object representation shared between the object memories (e.g. ObjectMemory, NewObjectMemory), the interpreters (e.g. StackInterpreter, CoInterpreter) and the object representations (e.g. ObjectRepresentationForSqueakV3).

self ensureClassPool
self classPool declare: #AllButTypeMask from: VMObjectOffsets classPool
(ObjectMemory classPool keys select: [:k| k includesSubString: 'Compact']) do:
	[:k| self classPool declare: k from: ObjectMemory classPool]
"
Class {
	#name : #VMSqueakV3ObjectRepresentationConstants,
	#superclass : #VMBasicConstants,
	#classVars : [
		'AllButTypeMask',
		'CompactClassMask',
		'HashBitsOffset',
		'HashMaskUnshifted',
		'HeaderTypeShort',
		'HeaderTypeSizeAndClass',
		'ImmutabilityBit',
		'LongSizeMask',
		'MarkBit',
		'RootBit',
		'Size4Bit',
		'SizeMask',
		'TypeMask'
	],
	#category : #'VMMaker-Interpreter'
}
