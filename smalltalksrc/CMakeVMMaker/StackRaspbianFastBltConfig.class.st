"
http://www.cmake.org/Wiki/CMake/Assembler
"
Class {
	#name : #StackRaspbianFastBltConfig,
	#superclass : #StackRaspbianConfig,
	#category : #'CMakeVMMaker-Unix'
}

{ #category : #'as yet unclassified' }
StackRaspbianFastBltConfig >> commonCompilerFlags [
	^ super commonCompilerFlags, { '-DENABLE_FAST_BLT' }.
]

{ #category : #'as yet unclassified' }
StackRaspbianFastBltConfig >> configureBitBltSimulation: maker [
	"extra rules for BitBltSimulation"

	maker includeDirectories: '${pluginCross}'.
	
	maker set: 'can_use_assembler' to: 'TRUE'.
	
	maker addCrossSources: #(
		'BitBltArm.c'
		'BitBltArmSimd.c'
		'BitBltDispatch.c'
		'BitBltGeneric.c'
		'BitBltArmLinux.c'
		'BitBltArmSimdAlphaBlend.s'
		'BitBltArmSimdBitLogical.s'
		'BitBltArmSimdPixPaint.s'
		'BitBltArmSimdSourceWord.s'
	).
	
]
