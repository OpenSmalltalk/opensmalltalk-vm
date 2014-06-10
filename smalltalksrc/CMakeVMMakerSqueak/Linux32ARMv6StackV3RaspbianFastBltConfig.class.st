"
http://www.cmake.org/Wiki/CMake/Assembler

Usage:
Linux32ARMv6StackV3RaspbianFastBltConfig generateWithSources
Or:
Linux32ARMv6StackV3RaspbianFastBltConfig generate
Or:
find my Builder in CMakeVMMakerSqueak-Builder category and use that to query me or invoke me

"
Class {
	#name : #Linux32ARMv6StackV3RaspbianFastBltConfig,
	#superclass : #Linux32ARMv6StackV3RaspbianConfig,
	#category : #'CMakeVMMakerSqueak-Linux32ARMv6'
}

{ #category : #'compiler flags' }
Linux32ARMv6StackV3RaspbianFastBltConfig >> commonCompilerFlags [
	^ super commonCompilerFlags, { '-DENABLE_FAST_BLT' }.
]

{ #category : #'plugin extra rules' }
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

{ #category : #cmake }
Linux32ARMv6StackV3RaspbianFastBltConfig >> dirBuildLanguageVMMM [
	"the directory under buildPlatformDir  example: newspeak.cog.spur. use squeak.cog.v3 as default"
	^self squeakStackV3
]

{ #category : #cmake }
Linux32ARMv6StackV3RaspbianFastBltConfig >> excludeFromBuild [
	^false

]
