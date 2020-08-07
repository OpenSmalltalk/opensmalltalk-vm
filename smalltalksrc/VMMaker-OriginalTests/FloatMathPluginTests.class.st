"
FloatMathPluginTests buildSuite run.
"
Class {
	#name : #FloatMathPluginTests,
	#superclass : #TestCase,
	#instVars : [
		'seed'
	],
	#category : #'VMMaker-OriginalTests'
}

{ #category : #math }
FloatMathPluginTests >> arcCos: f [
	<primitive: 'primitiveArcCos' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #math }
FloatMathPluginTests >> arcCosH: f [
	<primitive: 'primitiveArcCosH' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #math }
FloatMathPluginTests >> arcSin: f [
	<primitive: 'primitiveArcSin' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #math }
FloatMathPluginTests >> arcSinH: f [
	<primitive: 'primitiveArcSinH' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #math }
FloatMathPluginTests >> arcTan2: value with: arg [
	<primitive: 'primitiveArcTan2' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #math }
FloatMathPluginTests >> arcTan: value [
	<primitive: 'primitiveArcTan' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #math }
FloatMathPluginTests >> arcTanH: value [
	<primitive: 'primitiveArcTanH' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #math }
FloatMathPluginTests >> cos: value [
	<primitive: 'primitiveCos' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #math }
FloatMathPluginTests >> cosH: value [
	<primitive: 'primitiveCosH' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #math }
FloatMathPluginTests >> exp: value [
	<primitive: 'primitiveExp' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #math }
FloatMathPluginTests >> fractionPart: value [
	<primitive: 'primitiveFractionalPart' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #math }
FloatMathPluginTests >> hypot: x with: y [
	<primitive: 'primitiveHypot' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #math }
FloatMathPluginTests >> ln: value [
	<primitive: 'primitiveLogN' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #math }
FloatMathPluginTests >> log10: value [
	<primitive: 'primitiveLog10' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #running }
FloatMathPluginTests >> makeLargeTestData [
	"self basicNew makeLargeTestData"
	self makeTestData: 'sin-large.dat' using:[:f| self sin: f] seed: 432567 rounds: 1000000.
	self makeTestData: 'log-large.dat' using:[:f| self ln: f abs] seed: 432567 rounds: 1000000.
	self makeTestData: 'sqrt-large.dat' using:[:f| self sqrt: f abs] seed: 432567 rounds: 1000000.
	self makeTestData: 'atan-large.dat' using:[:f| self arcTan: f] seed: 432567 rounds: 1000000.
	self makeTestData: 'exp-large.dat' using:[:f| self exp: f] seed: 432567 rounds: 1000000.

]

{ #category : #running }
FloatMathPluginTests >> makeSmallTestData [
	"self basicNew makeSmallTestData"
	self makeTestData: 'sin-small.dat' using:[:f| self sin: f] seed: 321567 rounds: 10000.
	self makeTestData: 'log-small.dat' using:[:f| self ln: f abs] seed: 321567 rounds: 10000.
	self makeTestData: 'sqrt-small.dat' using:[:f| self sqrt: f abs] seed: 321567 rounds: 10000.
	self makeTestData: 'atan-small.dat' using:[:f| self arcTan: f] seed: 321567 rounds: 10000.
	self makeTestData: 'exp-small.dat' using:[:f| self exp: f] seed: 321567 rounds: 10000.

]

{ #category : #running }
FloatMathPluginTests >> makeTestData: fileName using: aBlock seed: seed rounds: rounds [
	| bytes out float result |
	bytes := ByteArray new: 8.
	out := FileStream newFileNamed: fileName.
	[
		out binary. 
		out nextNumber: 4 put: rounds.
		out nextNumber: 4 put: seed.
		self seed: seed.
		float := Float basicNew: 2.
		'Creating test data for: ', fileName 
			displayProgressAt: Sensor cursorPoint 
			from: 1 to: rounds during:[:bar|
				1 to: rounds do:[:i|
					i \\ 10000 = 0 ifTrue:[bar value: i].
					[1 to: 8 do:[:j| bytes at: j put: (self nextInt: 256)-1].
					float basicAt: 1 put: (bytes unsignedLongAt: 1 bigEndian: true).
					float basicAt: 2 put: (bytes unsignedLongAt: 5 bigEndian: true).
					float isNaN] whileTrue.
					result := aBlock value: float.
					out nextNumber: 4 put: (result basicAt: 1).
					out nextNumber: 4 put: (result basicAt: 2).
				].
			].
	] ensure:[out close].

]

{ #category : #md5 }
FloatMathPluginTests >> md5HashMessage: aStringOrByteArray [
	^ self md5HashStream: (ReadStream on: aStringOrByteArray asByteArray)

]

{ #category : #md5 }
FloatMathPluginTests >> md5HashStream: aStream [
	| start buffer bytes sz n words hash large |
	hash := WordArray with: 16r67452301 with: 16rEFCDAB89 with: 16r98BADCFE with: 16r10325476.
	words := WordArray new: 16.
	buffer := ByteArray new: 64.
	start := aStream position.
	[aStream atEnd] whileFalse: [
		bytes := aStream nextInto: buffer.
		(bytes size < 64 or:[aStream atEnd]) ifTrue:[
			sz := bytes size.
			buffer replaceFrom: 1 to: sz with: bytes startingAt: 1.
			buffer from: sz+1 to: buffer size put: 0.
			sz < 56 ifTrue:[
				buffer at: sz + 1 put: 128. "trailing bit"
			] ifFalse:[
				"not enough room for the length, so just pad this one, then..."
				sz < 64 ifTrue:[buffer at: sz + 1 put: 128].
				1 to: 16 do:[:i| words at: i put: (buffer unsignedLongAt: i*4-3 bigEndian: false)].
				self md5Transform: words hash: hash.
				"process one additional block of padding ending with the length"
				buffer atAllPut: 0.
				sz = 64 ifTrue: [buffer at: 1 put: 128].
			].
			"Fill in the final 8 bytes with the 64-bit length in bits."
			n := (aStream position - start) * 8.
			7 to: 0 by: -1 do:[:i| buffer at: (buffer size - i) put: ((n bitShift: 7 - i * -8) bitAnd: 255)].
		].
		1 to: 16 do:[:i| words at: i put: (buffer unsignedLongAt: i*4-3 bigEndian: false)].
		self md5Transform: words hash: hash.
	].
	bytes := ByteArray new: 16.
	bytes unsignedLongAt: 1 put: (hash at: 4) bigEndian: true.
	bytes unsignedLongAt: 5 put: (hash at: 3) bigEndian: true.
	bytes unsignedLongAt: 9 put: (hash at: 2) bigEndian: true.
	bytes unsignedLongAt: 13 put: (hash at: 1) bigEndian: true.
	large := LargePositiveInteger new: 16.
	1 to: 16 do:[:i| large digitAt: i put: (bytes at: i)].
	^large normalize
]

{ #category : #md5 }
FloatMathPluginTests >> md5Transform: in hash: hash [
	"This adds the incoming words to the existing hash"
	| a b c d |
	<primitive: 'primitiveMD5Transform' module: 'CroquetPlugin'>
	a := hash at: 1.
	b := hash at: 2.
	c := hash at: 3.
	d := hash at: 4.

	a := self step1: a x: b y: c z: d data: (in at:  1) add: 16rD76AA478 shift: 7.
	d := self step1: d x: a y: b z: c data: (in at:  2) add: 16rE8C7B756 shift: 12.
	c := self step1: c x: d y: a z: b data: (in at:  3) add: 16r242070DB shift: 17.
	b := self step1: b x: c y: d z: a data: (in at:  4) add: 16rC1BDCEEE shift: 22.
	a := self step1: a x: b y: c z: d data: (in at:  5) add: 16rF57C0FAF shift:  7.
	d := self step1: d x: a y: b z: c data: (in at:  6) add: 16r4787C62A shift: 12.
	c := self step1: c x: d y: a z: b data: (in at:  7) add: 16rA8304613 shift: 17.
	b := self step1: b x: c y: d z: a data: (in at:  8) add: 16rFD469501 shift: 22.
	a := self step1: a x: b y: c z: d data: (in at:  9) add: 16r698098D8 shift:  7.
	d := self step1: d x: a y: b z: c data: (in at: 10) add: 16r8B44F7AF shift: 12.
	c := self step1: c x: d y: a z: b data: (in at: 11) add: 16rFFFF5BB1 shift: 17.
	b := self step1: b x: c y: d z: a data: (in at: 12) add: 16r895CD7BE shift: 22.
	a := self step1: a x: b y: c z: d data: (in at: 13) add: 16r6B901122 shift:  7.
	d := self step1: d x: a y: b z: c data: (in at: 14) add: 16rFD987193 shift: 12.
	c := self step1: c x: d y: a z: b data: (in at: 15) add: 16rA679438E shift: 17.
	b := self step1: b x: c y: d z: a data: (in at: 16) add: 16r49B40821 shift: 22.

	a := self step2: a x: b y: c z: d data: (in at:  2) add: 16rF61E2562 shift:  5.
	d := self step2: d x: a y: b z: c data: (in at:  7) add: 16rC040B340 shift:  9.
	c := self step2: c x: d y: a z: b data: (in at: 12) add: 16r265E5A51 shift: 14.
	b := self step2: b x: c y: d z: a data: (in at:  1) add: 16rE9B6C7AA shift: 20.
	a := self step2: a x: b y: c z: d data: (in at:  6) add: 16rD62F105D shift:  5.
	d := self step2: d x: a y: b z: c data: (in at: 11) add: 16r02441453 shift:  9.
	c := self step2: c x: d y: a z: b data: (in at: 16) add: 16rD8A1E681 shift: 14.
	b := self step2: b x: c y: d z: a data: (in at:  5) add: 16rE7D3FBC8 shift: 20.
	a := self step2: a x: b y: c z: d data: (in at: 10) add: 16r21E1CDE6 shift:  5.
	d := self step2: d x: a y: b z: c data: (in at: 15) add: 16rC33707D6 shift:  9.
	c := self step2: c x: d y: a z: b data: (in at:  4) add: 16rF4D50D87 shift: 14.
	b := self step2: b x: c y: d z: a data: (in at:  9) add: 16r455A14ED shift: 20.
	a := self step2: a x: b y: c z: d data: (in at: 14) add: 16rA9E3E905 shift:  5.
	d := self step2: d x: a y: b z: c data: (in at:  3) add: 16rFCEFA3F8 shift:  9.
	c := self step2: c x: d y: a z: b data: (in at:  8) add: 16r676F02D9 shift: 14.
	b := self step2: b x: c y: d z: a data: (in at: 13) add: 16r8D2A4C8A shift: 20.

	a := self step3: a x: b y: c z: d data: (in at:  6) add: 16rFFFA3942 shift:  4.
	d := self step3: d x: a y: b z: c data: (in at:  9) add: 16r8771F681 shift: 11.
	c := self step3: c x: d y: a z: b data: (in at: 12) add: 16r6D9D6122 shift: 16.
	b := self step3: b x: c y: d z: a data: (in at: 15) add: 16rFDE5380C shift: 23.
	a := self step3: a x: b y: c z: d data: (in at:  2) add: 16rA4BEEA44 shift:  4.
	d := self step3: d x: a y: b z: c data: (in at:  5) add: 16r4BDECFA9 shift: 11.
	c := self step3: c x: d y: a z: b data: (in at:  8) add: 16rF6BB4B60 shift: 16.
	b := self step3: b x: c y: d z: a data: (in at: 11) add: 16rBEBFBC70 shift: 23.
	a := self step3: a x: b y: c z: d data: (in at: 14) add: 16r289B7EC6 shift:  4.
	d := self step3: d x: a y: b z: c data: (in at:  1) add: 16rEAA127FA shift: 11.
	c := self step3: c x: d y: a z: b data: (in at:  4) add: 16rD4EF3085 shift: 16.
	b := self step3: b x: c y: d z: a data: (in at:  7) add: 16r04881D05 shift: 23.
	a := self step3: a x: b y: c z: d data: (in at: 10) add: 16rD9D4D039 shift:  4.
	d := self step3: d x: a y: b z: c data: (in at: 13) add: 16rE6DB99E5 shift: 11.
	c := self step3: c x: d y: a z: b data: (in at: 16) add: 16r1FA27CF8 shift: 16.
	b := self step3: b x: c y: d z: a data: (in at:  3) add: 16rC4AC5665 shift: 23.

	a := self step4: a x: b y: c z: d data: (in at:  1) add: 16rF4292244 shift:  6.
	d := self step4: d x: a y: b z: c data: (in at:  8) add: 16r432AFF97 shift: 10.
	c := self step4: c x: d y: a z: b data: (in at: 15) add: 16rAB9423A7 shift: 15.
	b := self step4: b x: c y: d z: a data: (in at:  6) add: 16rFC93A039 shift: 21.
	a := self step4: a x: b y: c z: d data: (in at: 13) add: 16r655B59C3 shift:  6.
	d := self step4: d x: a y: b z: c data: (in at:  4) add: 16r8F0CCC92 shift: 10.
	c := self step4: c x: d y: a z: b data: (in at: 11) add: 16rFFEFF47D shift: 15.
	b := self step4: b x: c y: d z: a data: (in at:  2) add: 16r85845DD1 shift: 21.
	a := self step4: a x: b y: c z: d data: (in at:  9) add: 16r6FA87E4F shift:  6.
	d := self step4: d x: a y: b z: c data: (in at: 16) add: 16rFE2CE6E0 shift: 10.
	c := self step4: c x: d y: a z: b data: (in at:  7) add: 16rA3014314 shift: 15.
	b := self step4: b x: c y: d z: a data: (in at: 14) add: 16r4E0811A1 shift: 21.
	a := self step4: a x: b y: c z: d data: (in at:  5) add: 16rF7537E82 shift:  6.
	d := self step4: d x: a y: b z: c data: (in at: 12) add: 16rBD3AF235 shift: 10.
	c := self step4: c x: d y: a z: b data: (in at:  3) add: 16r2AD7D2BB shift: 15.
	b := self step4: b x: c y: d z: a data: (in at: 10) add: 16rEB86D391 shift: 21.

	a := (a + (hash at: 1)) bitAnd: 16rFFFFFFFF. hash at: 1 put: a.
	b := (b + (hash at: 2)) bitAnd: 16rFFFFFFFF. hash at: 2 put: b.
	c := (c + (hash at: 3)) bitAnd: 16rFFFFFFFF. hash at: 3 put: c.
	d := (d + (hash at: 4)) bitAnd: 16rFFFFFFFF. hash at: 4 put: d.

	^hash
]

{ #category : #rand }
FloatMathPluginTests >> nextInt: anInteger [
	"Answer a random integer in the interval [1, anInteger]."

	| a m q r lo hi aLoRHi |
	a := 16r000041A7 asFloat.    " magic constant =      16807 "
	m := 16r7FFFFFFF asFloat.    " magic constant = 2147483647 "
	q := (m quo: a) asFloat.
	r  := (m \\ a) asFloat.
	hi := (seed quo: q) asFloat.
	lo := seed - (hi * q).  " = seed rem: q"  
	aLoRHi := (a * lo) - (r * hi).
	seed := (aLoRHi > 0.0)
		ifTrue:  [aLoRHi]
		ifFalse: [aLoRHi + m].
	^ (seed / m * anInteger) truncated + 1
]

{ #category : #md5 }
FloatMathPluginTests >> rotate: value by: amount [
	"Rotate value left by amount"
	| lowMask highMask |
	lowMask := (1 bitShift: 32-amount) - 1.
	highMask := 16rFFFFFFFF - lowMask.
	^((value bitAnd: lowMask) bitShift: amount) + 
		((value bitAnd: highMask) bitShift: amount-32)
]

{ #category : #running }
FloatMathPluginTests >> runTest: aBlock [
	| bytes out float result |
	bytes := ByteArray new: 8.
	out := WriteStream on: ByteArray new.
	float := Float basicNew: 2.
	1 to: 10000 do:[:i|
		[1 to: 8 do:[:j| bytes at: j put: (self nextInt: 256)-1].
		float basicAt: 1 put: (bytes unsignedLongAt: 1 bigEndian: true).
		float basicAt: 2 put: (bytes unsignedLongAt: 5 bigEndian: true).
		float isNaN] whileTrue.
		result := [aBlock value: float] on: Error do:[:ex|
			"we convert all errors into NaNs to have a value for testing"
			ex return: Float nan.
		].
		out nextNumber: 4 put: (result basicAt: 1).
		out nextNumber: 4 put: (result basicAt: 2).
	].
	^self md5HashMessage: out contents.
]

{ #category : #rand }
FloatMathPluginTests >> seed: anInteger [
	seed := anInteger
]

{ #category : #running }
FloatMathPluginTests >> setUp [
	self seed: 253213.
]

{ #category : #math }
FloatMathPluginTests >> sin: value [
	<primitive: 'primitiveSin' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #math }
FloatMathPluginTests >> sinH: value [
	<primitive: 'primitiveSinH' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #math }
FloatMathPluginTests >> sqrt: value [
	<primitive: 'primitiveSqrt' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #md5 }
FloatMathPluginTests >> step1: w x: x y: y z: z data: data add: add shift: s [
	"First step in MD5 transformation"
	| f result |
	f := z bitXor: (x bitAnd: (y bitXor: z)).
	result := w + f + data + add.
	result := self rotate: result by: s.
	^result + x bitAnd: 16rFFFFFFFF
]

{ #category : #md5 }
FloatMathPluginTests >> step2: w x: x y: y z: z data: data add: add shift: s [
	"First step in MD5 transformation"
	| f result |
	f := y bitXor: (z bitAnd: (x bitXor: y)).
	result := w + f + data + add.
	result := self rotate: result by: s.
	^result + x bitAnd: 16rFFFFFFFF
]

{ #category : #md5 }
FloatMathPluginTests >> step3: w x: x y: y z: z data: data add: add shift: s [
	"First step in MD5 transformation"
	| f result |
	f := (x bitXor: y) bitXor: z.
	result := w + f + data + add.
	result := self rotate: result by: s.
	^result + x bitAnd: 16rFFFFFFFF
]

{ #category : #md5 }
FloatMathPluginTests >> step4: w x: x y: y z: z data: data add: add shift: s [
	"First step in MD5 transformation"
	| f result |
	f := y bitXor: (x bitOr: (z  bitXor: 16rFFFFFFFF)).
	result := w + f + data + add.
	result := self rotate: result by: s.
	^result + x bitAnd: 16rFFFFFFFF
]

{ #category : #math }
FloatMathPluginTests >> tan: value [
	<primitive: 'primitiveTan' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #math }
FloatMathPluginTests >> tanH: value [
	<primitive: 'primitiveTanH' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #tests }
FloatMathPluginTests >> testArcCos [
	| hash |
	hash := self runTest:[:f| self arcCos: f].
	self assert: hash = 320603091210691421897131240956682310429
]

{ #category : #tests }
FloatMathPluginTests >> testArcCosH [
	| hash |
	hash := self runTest:[:f| self arcCosH: f].
	self assert: hash = 6724426144112251941037505276242428134
]

{ #category : #tests }
FloatMathPluginTests >> testArcSin [
	| hash |
	hash := self runTest:[:f| self arcSin: f].
	self assert: hash = 27372132577303862731837100895783885417
]

{ #category : #tests }
FloatMathPluginTests >> testArcSinH [
	| hash |
	hash := self runTest:[:f| self arcSinH: f].
	self assert: hash = 255911863578190171815115260235896145802
]

{ #category : #tests }
FloatMathPluginTests >> testArcTan [
	| hash |
	hash := self runTest:[:f| self arcTan: f].
	self assert: hash = 17311773710959114634056077345168823659
]

{ #category : #tests }
FloatMathPluginTests >> testArcTan2 [
	| hash |
	hash := self runTest:[:f| self arcTan2: f with: f].
	self assert: hash = 287068347279655848752274030373495709564
]

{ #category : #tests }
FloatMathPluginTests >> testArcTanH [
	| hash |
	hash := self runTest:[:f| self arcTanH: f].
	self assert: hash = 295711907369004359459882231908879164929
]

{ #category : #data }
FloatMathPluginTests >> testAtanData [
	self verifyTestData: 'atan-small.dat' using:[:f| self arcTan: f].
	self verifyTestData: 'atan-large.dat' using:[:f| self arcTan: f].

]

{ #category : #tests }
FloatMathPluginTests >> testCos [
	| hash |
	hash := self runTest:[:f| self cos: f].
	self assert: hash = 110207739557966732640546618158077332978
]

{ #category : #tests }
FloatMathPluginTests >> testCosH [
	| hash |
	hash := self runTest:[:f| self cosH: f].
	self assert: hash = 139309299067563830037108641802292492276
]

{ #category : #tests }
FloatMathPluginTests >> testExp [
	| hash |
	hash := self runTest:[:f| self exp: f].
	self assert: hash = 264681209343177480335132131244505189510
]

{ #category : #data }
FloatMathPluginTests >> testExpData [
	self verifyTestData: 'exp-small.dat' using:[:f| self exp: f].
	self verifyTestData: 'exp-large.dat' using:[:f| self exp: f].

]

{ #category : #tests }
FloatMathPluginTests >> testFloatAt [
	| hash flt |
	flt := FloatArray new: 1.
	hash := self runTest:[:f| flt at: 1 put: f. flt at: 1].
	self assert: hash = 80498428122197125691266588764018905399
]

{ #category : #tests }
FloatMathPluginTests >> testFraction [
	| hash |
	hash := self runTest:[:f| self fractionPart: f].
	self assert: hash = 320444785026869345695277323179170692004
]

{ #category : #tests }
FloatMathPluginTests >> testHypot [
	| hash |
	hash := self runTest:[:f| self hypot: f with: f+1].
	self assert: hash = 217113721886532765853628735806816720346
]

{ #category : #tests }
FloatMathPluginTests >> testLog [
	| hash |
	hash := self runTest:[:f| self ln: f abs].
	self assert: hash = 24389651894375564945708989023746058645
]

{ #category : #tests }
FloatMathPluginTests >> testLog10 [
	| hash |
	hash := self runTest:[:f| self log10: f abs].
	self assert: hash = 135564553959509933253581837789050718785
]

{ #category : #data }
FloatMathPluginTests >> testLogData [
	self verifyTestData: 'log-small.dat' using:[:f| self ln: f abs].
	self verifyTestData: 'log-large.dat' using:[:f| self ln: f abs].

]

{ #category : #md5 }
FloatMathPluginTests >> testMD5 [
	self assert: (self md5HashMessage: 'a') = 16r0CC175B9C0F1B6A831C399E269772661.
	self assert: (self md5HashMessage: 'abc') = 16r900150983CD24FB0D6963F7D28E17F72.
	self assert: (self md5HashMessage: 'message digest') = 16rF96B697D7CB7938D525A2F31AAF161D0.
	self assert: (self md5HashMessage:
		'abcdefghijklmnopqrstuvwxyz') = 16rC3FCD3D76192E4007DFB496CCA67E13B.
	self assert: (self md5HashMessage:
		'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789') =
		16rD174AB98D277D9F5A5611C2C9F419D9F.
	self assert: (self md5HashMessage:
		'12345678901234567890123456789012345678901234567890123456789012345678901234567890') =
 		16r57EDF4A22BE3C955AC49DA2E2107B67A.
]

{ #category : #tests }
FloatMathPluginTests >> testSin [
	| hash |
	hash := self runTest:[:f| self sin: f].
	self assert: hash = 290162321010315440569513182938961037473
]

{ #category : #data }
FloatMathPluginTests >> testSinData [
	self verifyTestData: 'sin-small.dat' using:[:f| self sin: f].
	self verifyTestData: 'sin-large.dat' using:[:f| self sin: f].

]

{ #category : #tests }
FloatMathPluginTests >> testSinH [
	| hash |
	hash := self runTest:[:f| self sinH: f].
	self assert: hash = 146029709156303766079448006055284064911
]

{ #category : #tests }
FloatMathPluginTests >> testSqrt [
	| hash |
	hash := self runTest:[:f| self sqrt: f abs].
	self assert: hash = 112236588358122834093969606123302196127
]

{ #category : #data }
FloatMathPluginTests >> testSqrtData [
	self verifyTestData: 'sqrt-small.dat' using:[:f| self sqrt: f abs].
	self verifyTestData: 'sqrt-large.dat' using:[:f| self sqrt: f abs].
]

{ #category : #tests }
FloatMathPluginTests >> testTan [
	| hash |
	hash := self runTest:[:f| self tan: f].
	self assert: hash = 207143885112027702205238433494882679660
]

{ #category : #tests }
FloatMathPluginTests >> testTanH [
	| hash |
	hash := self runTest:[:f| self tanH: f].
	self assert: hash = 15738508136206638425252880299326548123
]

{ #category : #tests }
FloatMathPluginTests >> testTimesTwoPower [
	| hash |
	hash := self runTest:[:f| self timesTwoPower: f with: (self nextInt: 200) - 100].
	self assert: hash = 278837335583284459890979576373223649870.
]

{ #category : #math }
FloatMathPluginTests >> timesTwoPower: f with: arg [
	<primitive: 'primitiveTimesTwoPower' module: 'FloatMathPlugin'>
	^self primitiveFailed
]

{ #category : #running }
FloatMathPluginTests >> verifyTestData: fileName using: aBlock [
	| rounds seed bytes float result in expected count bits |
	in := [FileStream readOnlyFileNamed: fileName] 
			on: FileDoesNotExistException 
			do:[:ex| ex return: nil].
	in ifNil:[^nil].
	count := bits := 0.
	bytes := ByteArray new: 8.
	[
		in binary.
		rounds := in nextNumber: 4.
		seed := in nextNumber: 4.
		self seed: seed.
		float := Float basicNew: 2.
		expected := Float basicNew: 2.
		'Verifying test data from: ', fileName 
			displayProgressAt: Sensor cursorPoint 
			from: 1 to: rounds during:[:bar|
				1 to: rounds do:[:i|
					i \\ 10000 = 0 ifTrue:[bar value: i].
					[1 to: 8 do:[:j| bytes at: j put: (self nextInt: 256)-1].
					float basicAt: 1 put: (bytes unsignedLongAt: 1 bigEndian: true).
					float basicAt: 2 put: (bytes unsignedLongAt: 5 bigEndian: true).
					float isNaN] whileTrue.
					result := aBlock value: float.
					expected basicAt: 1 put: (in nextNumber: 4).
					expected basicAt: 2 put: (in nextNumber: 4).
					((expected isNaN and:[result isNaN]) or:[expected = result]) ifFalse:[
						(expected basicAt: 1) = (result basicAt: 1)
							ifFalse:[self error: 'Verification failure'].
						count := count + 1.
						bits := bits + ((expected basicAt: 2) - (result basicAt: 2)) abs.
					].
				].
			].
	] ensure:[in close].
	self assert: count = 0. "all the same"
]
