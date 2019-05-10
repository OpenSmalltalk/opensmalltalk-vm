"
Verify and document the values of ImageFormat. The image format is an integer value that identifies the format of an image snapshot and the capabilities that the image expects of the virtual machine.
"
Class {
	#name : #ImageFormatTest,
	#superclass : #TestCase,
	#category : #'ImageFormat-Tests'
}

{ #category : #testing }
ImageFormatTest >> testAsInteger [

	self assert: (ImageFormat fromInteger: 6502) asInteger = 6502.
	self assert: (ImageFormat fromInteger: 6504) asInteger = 6504.
	self assert: (ImageFormat fromInteger: 68000) asInteger = 68000.
	self assert: (ImageFormat fromInteger: 68002) asInteger = 68002.
	self assert: (ImageFormat fromInteger: 6521) asInteger = 6521.
	self assert: (ImageFormat fromInteger: 68019) asInteger = 68019.
	self assert: (ImageFormat fromInteger: 68021) asInteger = 68021.
	
]

{ #category : #testing }
ImageFormatTest >> testBaseVersionBits [

	self assert: ImageFormat baseVersionMask = 16r119EE.
	self assert: (ImageFormat wordSize: 4) baseVersionBits = 6502.
	self assert: (ImageFormat new fromInteger: 6504) baseVersionBits = 6504.
	self assert: (ImageFormat wordSize: 8) baseVersionBits = 68000.
	self assert: (ImageFormat new fromInteger: 68002) baseVersionBits = 68002.

]

{ #category : #testing }
ImageFormatTest >> testBit17AsTestFor64BitImages [
	"If bit 17 of the version number is 1, then the image is a 64-bit image."

	ImageFormat knownVersionNumbers do: [ :versionNumber | | is64 bit17 |
		is64 := (ImageFormat fromInteger: versionNumber) is64Bit.
		bit17 := versionNumber bitAt: 17.
		self assert: bit17 = 1 equals:is64
	].

]

{ #category : #testing }
ImageFormatTest >> testBitsInUse [
	"Ensure that the list of known version numbers is kept up to date with the bit allocation"

	| allocatedBitsInUse calculatedBitsInUse |
	calculatedBitsInUse := ImageFormat knownVersionNumbers
		inject: 0
		into: [ :e :a | a bitOr: e] .
	allocatedBitsInUse := ImageFormat baseVersionMask bitOr: ImageFormat capabilitiesBitsMask.
	self assert: calculatedBitsInUse = allocatedBitsInUse

]

{ #category : #testing }
ImageFormatTest >> testDefaultImageFormats [
	"Original 32-bit image format, and the original 64-bit image format, prior to
	introduction of block closure support."

	self assert: (6502 = (ImageFormat wordSize: 4) asInteger).
	self assert: (68000 = (ImageFormat wordSize: 8) asInteger).
	self should: [ImageFormat wordSize: 0] raise: Error.
	self should: [ImageFormat wordSize: 12] raise: Error
]

{ #category : #testing }
ImageFormatTest >> testFormat6502 [

	self assert: ImageFormat default asInteger = 6502.
	self assert: (ImageFormat wordSize: 4) asInteger = 6502.
	self assert: (ImageFormat wordSize: 4 closures: false) asInteger = 6502.
	self assert: (ImageFormat fromInteger: 6502) asInteger = 6502.
	self assert: ImageFormat default wordSize = 4.
	self deny: ImageFormat default requiresClosureSupport.
	self deny: ImageFormat default requiresNativeFloatWordOrder.
	self assert: ImageFormat default is32Bit.
	self deny: ImageFormat default is64Bit.
	self assert: (ImageFormat fromInteger: 6502) asInteger = 6502

]

{ #category : #testing }
ImageFormatTest >> testFormat6504 [

	| defaultWithClosures |
	defaultWithClosures := ImageFormat default setClosureSupportRequirement: true.
	self assert: defaultWithClosures asInteger = 6504.
	self assert: (ImageFormat wordSize: 4 closures: true) asInteger = 6504.
	self assert: (ImageFormat fromInteger: 6504) asInteger = 6504.
	self assert: defaultWithClosures wordSize = 4.
	self assert: defaultWithClosures requiresClosureSupport.
	self deny: defaultWithClosures requiresNativeFloatWordOrder.
	self assert: defaultWithClosures is32Bit.
	self deny: defaultWithClosures is64Bit.
	self assert: (ImageFormat fromInteger: 6504) asInteger = 6504

]

{ #category : #testing }
ImageFormatTest >> testFormat6505 [

	| cog32 |
	cog32 := ImageFormat default
				setCogSupportRequirement: true;
				setClosureSupportRequirement: true.
	self assert: cog32 asInteger = 6505.
	self assert: (ImageFormat wordSize: 4 cog: true) asInteger = 6505.
	self assert: (ImageFormat fromInteger: 6505) asInteger = 6505.
	self assert: cog32 wordSize = 4.
	self assert: cog32 requiresClosureSupport.
	self assert: cog32 requiresNativeFloatWordOrder.
	self assert: cog32 is32Bit.
	self deny: cog32 is64Bit.
	self assert: (ImageFormat fromInteger: 6505) asInteger = 6505
]

{ #category : #testing }
ImageFormatTest >> testFormat6521 [

	| spur |
	spur := ImageFormat fromInteger: 6521.
	self assert: spur asInteger = 6521.
	self assert: (ImageFormat wordSize: 4 spur: true) asInteger = 6521.
	self assert: (ImageFormat fromInteger: 6521) asInteger = 6521.
	self assert: spur wordSize = 4.
	self assert: spur requiresClosureSupport.
	self assert: spur requiresNativeFloatWordOrder.
	self assert: spur is32Bit.
	self deny: spur is64Bit.
	self assert: spur requiresSpurSupport.
	self assert: (ImageFormat fromInteger: 6521) asInteger = 6521
]

{ #category : #testing }
ImageFormatTest >> testFormat68000 [

	| closures64 |
	closures64 := ImageFormat wordSize: 8.
	self assert: closures64 asInteger = 68000.
	self assert: (ImageFormat wordSize: 8 closures: false) asInteger = 68000.
	self assert: (ImageFormat fromInteger: 68000) asInteger = 68000.
	self assert: closures64 wordSize = 8.
	self deny: closures64 requiresClosureSupport.
	self deny: closures64 requiresNativeFloatWordOrder.
	self deny: closures64 is32Bit.
	self assert: closures64 is64Bit.
	self assert: (ImageFormat fromInteger: 68000) asInteger = 68000

]

{ #category : #testing }
ImageFormatTest >> testFormat68002 [

	| closures64 |
	closures64 := (ImageFormat wordSize: 8) setClosureSupportRequirement: true.
	self assert: closures64 asInteger = 68002.
	self assert: (ImageFormat wordSize: 8 closures: true) asInteger = 68002.
	self assert: (ImageFormat fromInteger: 68002) asInteger = 68002.
	self assert: closures64 wordSize = 8.
	self assert: closures64 requiresClosureSupport.
	self deny: closures64 requiresNativeFloatWordOrder.
	self deny: closures64 is32Bit.
	self assert: closures64 is64Bit.
	self assert: (ImageFormat fromInteger: 68002) asInteger = 68002
]

{ #category : #testing }
ImageFormatTest >> testFormat68003 [

	| cog64 |
	cog64 := (ImageFormat wordSize: 8) setCogSupportRequirement: true.
	self assert: cog64 asInteger = 68003.
	self assert: (ImageFormat wordSize: 8 cog: true) asInteger = 68003.
	self assert: (ImageFormat fromInteger: 68003) asInteger = 68003.
	self assert: cog64 wordSize = 8.
	self assert: cog64 requiresClosureSupport.
	self assert: cog64 requiresNativeFloatWordOrder.
	self deny: cog64 is32Bit.
	self assert: cog64 is64Bit.
	self assert: (ImageFormat fromInteger: 68003) asInteger = 68003
]

{ #category : #testing }
ImageFormatTest >> testFormat68019 [

	| spur |
	spur := ImageFormat fromInteger: 68019.
	self assert: spur asInteger = 68019.
	self assert: (ImageFormat wordSize: 8 spur: true requiresNewSpur64TagAssignment: false) asInteger = 68019.
	self assert: (ImageFormat fromInteger: 68019) asInteger = 68019.
	self assert: spur wordSize = 8.
	self assert: spur requiresClosureSupport.
	self assert: spur requiresNativeFloatWordOrder.
	self deny: spur is32Bit.
	self assert: spur is64Bit.
	self assert: spur requiresSpurSupport.
	self assert: (ImageFormat fromInteger: 68019) asInteger = 68019
]

{ #category : #testing }
ImageFormatTest >> testFormat68021 [

	| spur |
	spur := ImageFormat fromInteger: 68021.
	self assert: spur asInteger = 68021.
	self assert: (ImageFormat wordSize: 8 spur: true) asInteger = 68021.
	self assert: (ImageFormat fromInteger: 68021) asInteger = 68021.
	self assert: spur wordSize = 8.
	self assert: spur requiresClosureSupport.
	self assert: spur requiresNativeFloatWordOrder.
	self deny: spur is32Bit.
	self assert: spur is64Bit.
	self assert: spur requiresSpurSupport.
	self assert: (ImageFormat fromInteger: 68021) asInteger = 68021
]

{ #category : #testing }
ImageFormatTest >> testIs32Bit [

	self assert: (ImageFormat wordSize: 4) is32Bit.
	self assert: (ImageFormat new fromInteger: 6504) is32Bit.
	self deny: (ImageFormat wordSize: 8) is32Bit.
	self deny: (ImageFormat new fromInteger: 68002) is32Bit.
	self deny: (ImageFormat fromInteger: 6521) is64Bit.
	self assert: (ImageFormat new fromInteger: 68019) is64Bit.
	self assert: (ImageFormat new fromInteger: 68021) is64Bit.

]

{ #category : #testing }
ImageFormatTest >> testIs64Bit [

	self deny: (ImageFormat wordSize: 4) is64Bit.
	self deny: (ImageFormat new fromInteger: 6504) is64Bit.
	self assert: (ImageFormat wordSize: 8) is64Bit.
	self assert: (ImageFormat new fromInteger: 68002) is64Bit.
	self deny: (ImageFormat fromInteger: 6521) is64Bit.
	self assert: (ImageFormat new fromInteger: 68019) is64Bit.
	self assert: (ImageFormat new fromInteger: 68021) is64Bit.

]

{ #category : #testing }
ImageFormatTest >> testIsValidVersionNumber [

	self should: [ImageFormat fromInteger: 0] raise: Error.
	self should: [ImageFormat fromInteger: (6502 bitAnd: 16r80000000)] raise: Error.
	self should: [ImageFormat fromInteger: (6502 bitAt: 31 put: 1)] raise: Error.
	self should: [ImageFormat fromInteger: 6500] raise: Error.
	self should: [ImageFormat fromInteger: 6501] raise: Error.
	self should: [ImageFormat fromInteger: 6503] raise: Error. "Cog requires both capabilities"
	self should: [ImageFormat fromInteger: 68001] raise: Error. "Cog requires both capabilities"

	self assert: ImageFormat default isValidVersionNumber.
	self assert: (ImageFormat wordSize: 4 closures: false) isValidVersionNumber.
	self assert: (ImageFormat wordSize: 4 closures: true) isValidVersionNumber.
	self assert: (ImageFormat wordSize: 8 closures: false) isValidVersionNumber.
	self assert: (ImageFormat wordSize: 8 closures: true) isValidVersionNumber.
	self assert: (ImageFormat fromInteger: 6502) isValidVersionNumber.
	self assert: (ImageFormat fromInteger: (6502 bitAt: 31 put: 0)) isValidVersionNumber.
	self assert: (ImageFormat fromInteger: 6521) isValidVersionNumber.
	self assert: (ImageFormat fromInteger:68000) isValidVersionNumber.
	self assert: (ImageFormat fromInteger:68002) isValidVersionNumber.
	self assert: (ImageFormat fromInteger:68004) isValidVersionNumber.
	self assert: (ImageFormat fromInteger:68003) isValidVersionNumber. "valid but unused, as with 68019"
	self assert: (ImageFormat fromInteger: 68019) isValidVersionNumber.
	self assert: (ImageFormat fromInteger: 68021) isValidVersionNumber.


]

{ #category : #testing }
ImageFormatTest >> testRequiresClosureSupport [

	| v |
	v := ImageFormat wordSize: 4.
	self deny: v requiresClosureSupport.
	v setClosureSupportRequirement: false.
	self assert: v asInteger = 6502.
	self deny: v requiresClosureSupport.
	v setClosureSupportRequirement: true.
	self assert: v asInteger = 6504.
	self assert: v requiresClosureSupport.

	v := ImageFormat wordSize: 8.
	self deny: v requiresClosureSupport.
	v setClosureSupportRequirement: false.
	self assert: v asInteger = 68000.
	self deny: v requiresClosureSupport.
	v setClosureSupportRequirement: true.
	self assert: v asInteger = 68002.
	self assert: v requiresClosureSupport.
	
	self deny: (ImageFormat wordSize: 4 closures: false) requiresClosureSupport.
	self assert: (ImageFormat wordSize: 4 closures: true) requiresClosureSupport.
	self deny: (ImageFormat wordSize: 8 closures: false) requiresClosureSupport.
	self assert: (ImageFormat wordSize: 8 closures: true) requiresClosureSupport.

]

{ #category : #testing }
ImageFormatTest >> testRequiresNativeFloatWordOrder [
	"Required for Cog and StackInterpreter"

	| v |
	v := ImageFormat wordSize: 4.
	self deny: v requiresNativeFloatWordOrder.
	v setCogSupportRequirement: false.
	self assert: v asInteger = 6502.
	self deny: v requiresNativeFloatWordOrder.
	v setCogSupportRequirement: true.
	self assert: v asInteger = 6505.
	self assert: v requiresNativeFloatWordOrder.
	v setSpurSupportRequirement: true.
	self assert: v asInteger = 6521.

	v := ImageFormat wordSize: 8.
	self deny: v requiresNativeFloatWordOrder.
	v setCogSupportRequirement: false.
	self assert: v asInteger = 68000.
	self deny: v requiresNativeFloatWordOrder.
	v setCogSupportRequirement: true.
	self assert: v asInteger = 68003.
	self assert: v requiresNativeFloatWordOrder.
	v setSpurSupportRequirement: true.
	self assert: v asInteger = 68019.
	
	self deny: (ImageFormat wordSize: 4 cog: false) requiresNativeFloatWordOrder.
	self deny: (ImageFormat wordSize: 4 cog: false) requiresClosureSupport.
	self deny: (ImageFormat wordSize: 8 cog: false) requiresNativeFloatWordOrder.
	self deny: (ImageFormat wordSize: 8 cog: false) requiresClosureSupport.
	self assert: (ImageFormat wordSize: 4 cog: true) requiresNativeFloatWordOrder.
	self assert: (ImageFormat wordSize: 4 cog: true) requiresClosureSupport.
	self assert: (ImageFormat wordSize: 8 cog: true) requiresNativeFloatWordOrder.
	self assert: (ImageFormat wordSize: 8 cog: true) requiresClosureSupport.
	self assert: (ImageFormat fromInteger: 6521) requiresNativeFloatWordOrder.
	self assert: (ImageFormat fromInteger: 6521) requiresClosureSupport.
	self assert: (ImageFormat fromInteger: 68019) requiresNativeFloatWordOrder.
	self assert: (ImageFormat fromInteger: 68019) requiresClosureSupport.
	self assert: (ImageFormat fromInteger: 68021) requiresNativeFloatWordOrder.
	self assert: (ImageFormat fromInteger: 68021) requiresClosureSupport.


]
