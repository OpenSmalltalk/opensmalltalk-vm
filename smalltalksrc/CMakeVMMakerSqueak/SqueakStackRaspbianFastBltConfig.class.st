"
http://www.cmake.org/Wiki/CMake/Assembler

Usage:
SqueakStackRaspbianFastBltConfig generateWithSources
Or:
SqueakStackRaspbianFastBltConfig generate
"
Class {
	#name : #SqueakStackRaspbianFastBltConfig,
	#superclass : #SqueakStackRaspbianConfig,
	#category : #'CMakeVMMakerSqueak-Linux32ARMv6'
}

{ #category : #'as yet unclassified' }
SqueakStackRaspbianFastBltConfig >> commonCompilerFlags [
	^ super commonCompilerFlags, { '-DENABLE_FAST_BLT' }.
]

{ #category : #'as yet unclassified' }
SqueakStackRaspbianFastBltConfig >> configureBitBltSimulation: maker [
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
