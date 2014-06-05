"
http://www.cmake.org/Wiki/CMake/Assembler

Usage:
SqueakStackRaspbianFastBltConfig generateWithSources
Or:
SqueakStackRaspbianFastBltConfig generate
"
Class {
	#name : #Linux32ARMv6StackV3RaspbianFastBltConfig,
	#superclass : #Linux32ARMv6StackV3RaspbianConfig,
	#category : #'CMakeVMMakerSqueak-Linux32ARMv6'
}

{ #category : #'as yet unclassified' }
Linux32ARMv6StackV3RaspbianFastBltConfig >> commonCompilerFlags [
	^ super commonCompilerFlags, { '-DENABLE_FAST_BLT' }.
]

{ #category : #'as yet unclassified' }
Linux32ARMv6StackV3RaspbianFastBltConfig >> configureBitBltSimulation: maker [
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
