"
This is a concrete class which generates a StackVM for Raspbian (debian on RaspberryPi). But in cross compilation usage.

I configure a VM according to my name's form: [Operating System] [WordSize] [Processor Language][VM MemoryManager][BuildType]Conf

SqueakLinux32ARMv6Builder 
	configureABuildFor: #MY NAME HERE withBuildType: #build;
	generateSources;
	generate.  

HelpBrowser openOn: CMakeVMMakerSqueakEndUserHelp
HelpBrowser openOn: CMakeVMMakerSqueakDeveloperHelp


"
Class {
	#name : #Linux32ARMv6StackV3CrossRaspbianFastBltConfig,
	#superclass : #Linux32ARMv6StackV3CrossRaspbianConfig,
	#category : #'CMakeVMMakerSqueak-Linux32ARMv6'
}

{ #category : #'compiler flags' }
Linux32ARMv6StackV3CrossRaspbianFastBltConfig >> commonCompilerFlags [
	^ super commonCompilerFlags, { '-DENABLE_FAST_BLT' }.
]

{ #category : #'plugin extra rules' }
Linux32ARMv6StackV3CrossRaspbianFastBltConfig >> configureBitBltSimulation: maker [
	"extra rules for BitBltSimulation"

	maker includeDirectories: '${pluginCross}'.
	maker set: 'can_use_assembler' to: 'TRUE'.
	maker cmd: 'enable_language' params: 'ASM'.
	maker set: 'CMAKE_ASM_COMPILE_OBJECT' to: '"asasm -cpu 6 -I ${pluginCross} -o <OBJECT> <SOURCE>"'.
	
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
Linux32ARMv6StackV3CrossRaspbianFastBltConfig >> excludeFromBuild [
	^true

]
