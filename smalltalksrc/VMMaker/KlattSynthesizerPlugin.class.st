"
This is a pluggable primitive implementation of the KlattSynthesizer.
"
Class {
	#name : #KlattSynthesizerPlugin,
	#superclass : #InterpreterPlugin,
	#instVars : [
		'resonators',
		'frame',
		'pitch',
		't0',
		'nper',
		'nopen',
		'nmod',
		'a1',
		'a2',
		'x1',
		'x2',
		'b1',
		'c1',
		'glast',
		'vlast',
		'nlast',
		'periodCount',
		'samplesCount',
		'seed',
		'cascade',
		'samplesPerFrame',
		'samplingRate'
	],
	#classVars : [
		'Bypass',
		'B3f',
		'Db1',
		'B2',
		'F2',
		'A4f',
		'Epsilon',
		'Df1',
		'Ftp',
		'Voicing',
		'Flutter',
		'B5',
		'Btp',
		'A3v',
		'F5',
		'Atv',
		'Ftz',
		'Diplophonia',
		'PI',
		'Aspiration',
		'Btz',
		'B4f',
		'B1',
		'A5f',
		'F1',
		'B4',
		'Jitter',
		'A4v',
		'F4',
		'Fnp',
		'A2f',
		'B5f',
		'A6f',
		'Bnp',
		'Anv',
		'Shimmer',
		'F0',
		'Fnz',
		'A1v',
		'Ra',
		'Bnz',
		'Ro',
		'B3',
		'B2f',
		'F3',
		'Rk',
		'B6f',
		'A3f',
		'B6',
		'Turbulence',
		'F6',
		'Gain',
		'A2v',
		'Friction'
	],
	#pools : [
		'KlattResonatorIndices'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
KlattSynthesizerPlugin class >> declareCVarsIn: cg [ 
	cg var: #resonators type: #'float*'.
	cg var: #frame type: #'float*'.
	cg var: #pitch type: #float.
	cg var: #a1 type: #float.
	cg var: #a2 type: #float.
	cg var: #x1 type: #float.
	cg var: #x2 type: #float.
	cg var: #b1 type: #float.
	cg var: #c1 type: #float.
	cg var: #glast type: #float.
	cg var: #vlast type: #float.
	cg var: #nlast type: #float
]

{ #category : #'class initialization' }
KlattSynthesizerPlugin class >> initialize [
	"
	KlattSynthesizerPlugin initialize
	"
	KlattFrame parameterNames
		doWithIndex: [ :each :i | self classPool at: each capitalized asSymbol put: i-1].
	PI _ Float pi	.
	Epsilon _ 1.0e-04
]

{ #category : #translation }
KlattSynthesizerPlugin class >> moduleName [
	"
	KlattSynthesizerPlugin translateDoInlining: true
	"
	^ 'Klatt'
]

{ #category : #'processing-voice' }
KlattSynthesizerPlugin >> addAmplitudeDiplophonia [
	"Add diplophonia (bicyclic voice). Change voicing amplitude."
	self returnTypeC: 'void'.
	periodCount \\ 2 = 0
		ifFalse: [x1 _ x1 * (1.0 - (frame at: Diplophonia)).
				"x1 must be <= 0"
				x1 > 0 ifTrue: [x1 _ 0]]
]

{ #category : #'processing-voice' }
KlattSynthesizerPlugin >> addFlutter [
	"Add F0 flutter, as specified in:
		'Analysis, synthesis and perception of voice quality variations among
		female and male talkers' D.H. Klatt and L.C. Klatt JASA 87(2) February 1990.
	Flutter is added by applying a quasi-random element constructed from three
	slowly varying sine waves."
	| timeCount asin bsin csin deltaF0 |
	self returnTypeC: 'void'.
	self var: 'timeCount' declareC: 'float timeCount'.
	self var: 'asin' declareC: 'float asin'.
	self var: 'bsin' declareC: 'float bsin'.
	self var: 'csin' declareC: 'float csin'.
	self var: 'deltaF0' declareC: 'double deltaF0'.
	timeCount _ (self cCoerce: samplesCount to: 'float') / (self cCoerce: samplingRate to: 'float').
	asin _ (2.0 * PI * 12.7 * timeCount) sin.
	bsin _ (2.0 * PI * 7.1 * timeCount) sin.
	csin _ (2.0 * PI * 4.7 * timeCount) sin.
	deltaF0 _ (frame at: Flutter) * 2.0 * (frame at: F0) / 100.0 * (asin + bsin + csin).
	pitch _ pitch + deltaF0
]

{ #category : #'processing-voice' }
KlattSynthesizerPlugin >> addFrequencyDiplophonia [
	"Add diplophonia (bicyclic voice). Change F0."
	self returnTypeC: 'void'.
	periodCount \\ 2 = 0
		ifTrue: [pitch _ pitch + ((frame at: Diplophonia) * (frame at: F0) * (1.0 - (frame at: Ro)))]
		ifFalse: [pitch _ pitch - ((frame at: Diplophonia) * (frame at: F0) * (1.0 - (frame at: Ro)))]
]

{ #category : #'processing-voice' }
KlattSynthesizerPlugin >> addJitter [
	"Add jitter (random F0 perturbation)."
	self returnTypeC: 'void'.
	pitch _ pitch + (self nextRandom - 32767 * (frame at: Jitter) / 32768.0 * (frame at: F0))
]

{ #category : #'processing-voice' }
KlattSynthesizerPlugin >> addShimmer [
	"Add shimmer (random voicing amplitude perturbation)."
	self returnTypeC: 'void'.
	x1 _ x1 + (self nextRandom - 32767 * (frame at: Shimmer) / 32768.0 * x1).
	"x1 must be <= 0"
	x1 > 0 ifTrue: [x1 _ 0]
]

{ #category : #resonators }
KlattSynthesizerPlugin >> antiResonator: index frequency: freq bandwidth: bw [
	"Set up an anti-resonator"
	| arg r a b c |
	self returnTypeC: 'void'.
	self var: 'freq' declareC: 'float freq'.
	self var: 'bw' declareC: 'float bw'.
	self var: 'arg' declareC: 'double arg'.
	self var: 'a' declareC: 'float a'.
	self var: 'b' declareC: 'float b'.
	self var: 'c' declareC: 'float c'.
	self var: 'r' declareC: 'float r'.
	arg _ 0.0 - PI / samplingRate * bw.
	r _ arg exp.
	c _ 0.0 - (r * r).
	arg _ PI * 2.0 / samplingRate * freq.
	b _ r * arg cos * 2.0.
	a _ 1.0 - b - c.
	a _ 1.0 / a.
	b _ 0.0 - b * a.
	c _ 0.0 - c * a.
	self resonatorA: index put: a.
	self resonatorB: index put: b.
	self resonatorC: index put: c
]

{ #category : #resonators }
KlattSynthesizerPlugin >> antiResonator: index value: aFloat [
	| answer p1 |
	self inline: true.
	self returnTypeC: 'float'.
	self var: 'aFloat' declareC: 'double aFloat'.
	self var: 'answer' declareC: 'double answer'.
	self var: 'p1' declareC: 'double p1'.
	answer _ (self resonatorA: index) * aFloat
			+ ((self resonatorB: index) * (p1 _ self resonatorP1: index))
			+ ((self resonatorC: index) * (self resonatorP2: index)).
	self resonatorP2: index put: p1.
	self resonatorP1: index put: aFloat.
	^ answer
]

{ #category : #processing }
KlattSynthesizerPlugin >> cascadeBranch: source [
	"Cascade vocal tract, excited by laryngeal sources.
	Nasal antiresonator, nasal resonator, tracheal antirresonator,
	tracheal resonator, then formants F8, F7, F6, F5, F4, F3, F2, F1."
	| out |
	self inline: true.
	self returnTypeC: 'float'.
	self var: 'source' declareC: 'float source'.
	self var: 'out' declareC: 'float out'.
	cascade > 0 ifFalse: [^ 0.0].
	out _ self antiResonator: Rnz value: source.
	out _ self resonator: Rnpc value: out.
	out _ self antiResonator: Rtz value: out.
	out _ self resonator: Rtpc value: out.
	"Do not use unless sample rate >= 16000"
	cascade >= 8 ifTrue: [out _ self resonator: R8c value: out].
	"Do not use unless sample rate >= 16000"
	cascade >= 7 ifTrue: [out _ self resonator: R7c value: out].
	"Do not use unless long vocal tract or sample rate increased"
	cascade >= 6 ifTrue: [out _ self resonator: R6c value: out].
	cascade >= 5 ifTrue: [out _ self resonator: R5c value: out].
	cascade >= 4 ifTrue: [out _ self resonator: R4c value: out].
	cascade >= 3 ifTrue: [out _ self resonator: R3c value: out].
	cascade >= 2 ifTrue: [out _ self resonator: R2c value: out].
	cascade >= 1 ifTrue: [out _ self resonator: R1c value: out].
	^ out
]

{ #category : #private }
KlattSynthesizerPlugin >> checkedFloatPtrOf: oop [
	"Return the first indexable word of oop which is assumed to be variableWordSubclass"
	self returnTypeC:'float *'.
	interpreterProxy success: (interpreterProxy isWords: oop).
	interpreterProxy failed ifTrue:[^0].
	^self cCoerce: (interpreterProxy firstIndexableField: oop) to:'float *'
]

{ #category : #private }
KlattSynthesizerPlugin >> checkedShortPtrOf: oop [
	"Return the first indexable word of oop which is assumed to be variableWordSubclass"
	self returnTypeC:'short *'.
	interpreterProxy success: (interpreterProxy isWords: oop).
	interpreterProxy failed ifTrue:[^0].
	^self cCoerce: (interpreterProxy firstIndexableField: oop) to:'short *'
]

{ #category : #'processing-LF' }
KlattSynthesizerPlugin >> glottalSource [
	| x0 |
	self inline: true.
	self returnTypeC: 'float'.
	self var: 'x0' declareC: 'float x0'.
	t0 = 0 ifTrue: [^ 0].
	nper < nopen
		ifTrue: [x0 _ a1 * x1 + (a2 * x2).
				x2 _ x1.
				x1 _ x0]
		ifFalse: [x0 _ b1 * x1 - c1.
				x1 _ x0].
	"Reset period when 'nper' reaches t0."
	nper >= t0 ifTrue: [nper _ 0. self pitchSynchronousReset].
	nper _ nper + 1.
	^ x0
]

{ #category : #processing }
KlattSynthesizerPlugin >> linearFromdB: aNumber [
	self inline: true.
	self returnTypeC: 'float'.
	self var: 'aNumber' declareC: 'double aNumber'.
	^ (2.0 raisedTo: (aNumber-87.0/6.0)) * 32.767
]

{ #category : #private }
KlattSynthesizerPlugin >> loadFrom: klattOop [
	| oop |
	interpreterProxy success: (interpreterProxy slotSizeOf: klattOop) = 22.
	interpreterProxy failed ifTrue:[^ false].

	oop _ interpreterProxy fetchPointer: 0 ofObject: klattOop.
	resonators _ self checkedFloatPtrOf: oop.

	pitch _ interpreterProxy fetchFloat: 2 ofObject: klattOop.
	t0 _ interpreterProxy fetchInteger: 3 ofObject: klattOop.
	nper _ interpreterProxy fetchInteger: 4 ofObject: klattOop.
	nopen _ interpreterProxy fetchInteger: 5 ofObject: klattOop.
	nmod _ interpreterProxy fetchInteger: 6 ofObject: klattOop.
	a1 _ interpreterProxy fetchFloat: 7 ofObject: klattOop.
	a2 _ interpreterProxy fetchFloat: 8 ofObject: klattOop.
	x1 _ interpreterProxy fetchFloat: 9 ofObject: klattOop.
	x2 _ interpreterProxy fetchFloat: 10 ofObject: klattOop.
	b1 _ interpreterProxy fetchFloat: 11 ofObject: klattOop.
	c1 _ interpreterProxy fetchFloat: 12 ofObject: klattOop.
	glast _ interpreterProxy fetchFloat: 13 ofObject: klattOop.
	vlast _ interpreterProxy fetchFloat: 14 ofObject: klattOop.
	nlast _ interpreterProxy fetchFloat: 15 ofObject: klattOop.
	periodCount _ interpreterProxy fetchInteger: 16 ofObject: klattOop.
	samplesCount _ interpreterProxy fetchInteger: 17 ofObject: klattOop.
	seed _ interpreterProxy fetchInteger: 18 ofObject: klattOop.
	cascade _ interpreterProxy fetchInteger: 19 ofObject: klattOop.
	samplesPerFrame _ interpreterProxy fetchInteger: 20 ofObject: klattOop.
	samplingRate _ interpreterProxy fetchInteger: 21 ofObject: klattOop.

	^ interpreterProxy failed == false
]

{ #category : #processing }
KlattSynthesizerPlugin >> nextRandom [
	"Answer a random number between 0 and 65535."
	self inline: true.
	seed _ (seed * 1309) + 13849 bitAnd: 65535.
	^ seed
]

{ #category : #'processing-LF' }
KlattSynthesizerPlugin >> normalizeGlottalPulse [
	| s1 s2 s0 |
	self inline: true.
	self returnTypeC: 'void'.
	self var: 's0' declareC: 'float s0'.
	self var: 's1' declareC: 'float s1'.
	self var: 's2' declareC: 'float s2'.
	s0 _ 0.0.
	s1 _ x1.
	s2 _ x2.
	1 to: nopen do: [ :ingore |
		s0 _ a1 * s1 + (a2 * s2).
		s2 _ s1.
		s1 _ s0].
	s0 = 0.0 ifFalse: [x1 _ x1 / s0 * 10000.0]
]

{ #category : #processing }
KlattSynthesizerPlugin >> parallelFrictionBranch: source [
	"Friction-excited parallel vocal tract formants F6, F5, F4, F3, F2,
	outputs added with alternating sign. Sound source for other
	parallel resonators is friction plus first difference of
	voicing waveform."
	self inline: true.
	self returnTypeC: 'float'.
	self var: 'source' declareC: 'float source'.
	^ (self resonator: R2fp value: source) - (self resonator: R3fp value: source) + (self resonator: R4fp value: source) - (self resonator: R5fp value: source) + (self resonator: R6fp value: source)
]

{ #category : #processing }
KlattSynthesizerPlugin >> parallelVoicedBranch: source [
	"Voice-excited parallel vocal tract F1, F2, F3, F4, FNP and FTP."
	self inline: true.
	self returnTypeC: 'float'.
	self var: 'source' declareC: 'float source'.
	^ (self resonator: R1vp value: source) + (self resonator: R2vp value: source) + (self resonator: R3vp value: source) + (self resonator: R4vp value: source) + (self resonator: Rnpp value: source) + (self resonator: Rtpp value: source)
]

{ #category : #'processing-voice' }
KlattSynthesizerPlugin >> pitchSynchronousReset [
	self returnTypeC: 'void'.
	(frame at: F0) > 0
		ifTrue: [self voicedPitchSynchronousReset.
				periodCount _ periodCount + 1 \\ 65535]
		ifFalse: [t0 _ 1.
				nmod _ t0]
]

{ #category : #primitives }
KlattSynthesizerPlugin >> primitiveSynthesizeFrameIntoStartingAt [
	| aKlattFrame buffer startIndex rcvr bufferOop |
	self export: true.
	self var: 'aKlattFrame' declareC: 'float *aKlattFrame'.
	self var: 'buffer' declareC: 'short *buffer'.
	aKlattFrame _ self checkedFloatPtrOf: (interpreterProxy stackValue: 2).
	buffer _ self checkedShortPtrOf: (bufferOop _ interpreterProxy stackValue: 1).
	startIndex _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue: [^nil].
	rcvr _ interpreterProxy stackObjectValue: 3.
	(self loadFrom: rcvr) ifFalse:[^nil].
	interpreterProxy success: (interpreterProxy stSizeOf: bufferOop) * 2 >= samplesPerFrame.
	interpreterProxy failed ifTrue: [^nil].
	self synthesizeFrame: aKlattFrame into: buffer startingAt: startIndex.
	(self saveTo: rcvr) ifFalse: [^nil].
	interpreterProxy pop: 3
]

{ #category : #'processing-LF' }
KlattSynthesizerPlugin >> qu: u phi: phi cosphi: cosphi sinphi: sinphi rphid: rphid [
	| expuphi |
	self returnTypeC: 'float'.
	self var: 'u' declareC: 'float u'.
	self var: 'phi' declareC: 'float phi'.
	self var: 'cosphi' declareC: 'float cosphi'.
	self var: 'sinphi' declareC: 'float sinphi'.
	self var: 'rphid' declareC: 'float rphid'.
	self var: 'expuphi' declareC: 'float expuphi'.
	expuphi _ (u * phi) exp.
	^ expuphi * ((rphid * (u*u + 1.0) + u) * sinphi - cosphi) + 1.0
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonator: index frequency: freq bandwidth: bw [
	"Convert formant frequencies and bandwidth into
	resonator difference equation coefficients."
	| arg r a b c |
	self returnTypeC: 'void'.
	self var: 'freq' declareC: 'float freq'.
	self var: 'bw' declareC: 'float bw'.
	self var: 'arg' declareC: 'double arg'.
	self var: 'a' declareC: 'float a'.
	self var: 'b' declareC: 'float b'.
	self var: 'c' declareC: 'float c'.
	self var: 'r' declareC: 'float r'.
	arg _ 0.0 - PI / samplingRate * bw.
	r _ arg exp.
	c _ 0.0 - (r * r).
	arg _ PI * 2.0 / samplingRate * freq.
	b _ r * arg cos * 2.0.
	a _ 1.0 - b - c.
	self resonatorA: index put: a.
	self resonatorB: index put: b.
	self resonatorC: index put: c
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonator: index frequency: freq bandwidth: bw gain: gain [
	"Convert formant frequencies and bandwidth into
	resonator difference equation coefficients."
	self returnTypeC: 'void'.
	self var: 'freq' declareC: 'float freq'.
	self var: 'bw' declareC: 'float bw'.
	self var: 'gain' declareC: 'float gain'.
	self resonator: index frequency: freq bandwidth: bw.
	self resonatorA: index put: (self resonatorA: index) * gain
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonator: index value: aFloat [
	| answer p1 |
	self inline: true.
	self returnTypeC: 'float'.
	self var: 'aFloat' declareC: 'float aFloat'.
	self var: 'answer' declareC: 'float answer'.
	self var: 'p1' declareC: 'float p1'.
	answer _ (self resonatorA: index) * aFloat
			+ ((self resonatorB: index) * (p1 _ self resonatorP1: index))
			+ ((self resonatorC: index) * (self resonatorP2: index)).
	"(p1 between: -100000 and: 100000) ifFalse: [self halt].
	(answer between: -100000 and: 100000) ifFalse: [self halt]."
	self resonatorP2: index put: p1.
	self resonatorP1: index put: answer.
	^ answer
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorA: index [
	self inline: true.
	self returnTypeC: 'float'.
	^resonators at: index*5-5
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorA: index put: aFloat [
	self inline: true.
	self returnTypeC: 'void'.
	self var: 'aFloat' declareC: 'float aFloat'.
	resonators at: index*5-5 put: aFloat
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorB: index [
	self inline: true.
	self returnTypeC: 'float'.
	^resonators at: index*5-4
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorB: index put: aFloat [
	self inline: true.
	self returnTypeC: 'void'.
	self var: 'aFloat' declareC: 'float aFloat'.
	resonators at: index*5-4 put: aFloat
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorC: index [
	self inline: true.
	self returnTypeC: 'float'.
	^resonators at: index*5-3
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorC: index put: aFloat [
	self inline: true.
	self returnTypeC: 'void'.
	self var: 'aFloat' declareC: 'float aFloat'.
	resonators at: index*5-3 put: aFloat
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorP1: index [
	self inline: true.
	self returnTypeC: 'float'.
	^resonators at: index*5-2
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorP1: index put: aFloat [
	self inline: true.
	self returnTypeC: 'void'.
	self var: 'aFloat' declareC: 'float aFloat'.
	resonators at: index*5-2 put: aFloat
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorP2: index [
	self inline: true.
	self returnTypeC: 'float'.
	^resonators at: index*5-1
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorP2: index put: aFloat [
	self inline: true.
	self returnTypeC: 'void'.
	self var: 'aFloat' declareC: 'float aFloat'.
	resonators at: index*5-1 put: aFloat
]

{ #category : #'processing-LF' }
KlattSynthesizerPlugin >> ro: roNumber ra: raNumber rk: rkNumber [
	| r d phi cosphi sinphi rphid u theta rho gamma gammapwr te ro ra rk |

	self returnTypeC: 'void'.
	self var: 'roNumber' declareC: 'float roNumber'.
	self var: 'raNumber' declareC: 'float raNumber'.
	self var: 'rkNumber' declareC: 'float rkNumber'.
	self var: 'r' declareC: 'float r'.
	self var: 'd' declareC: 'float d'.
	self var: 'phi' declareC: 'float phi'.
	self var: 'cosphi' declareC: 'float cosphi'.
	self var: 'sinphi' declareC: 'float sinphi'.
	self var: 'rphid' declareC: 'float rphid'.
	self var: 'u' declareC: 'float u'.
	self var: 'theta' declareC: 'float theta'.
	self var: 'rho' declareC: 'float rho'.
	self var: 'gamma' declareC: 'float gamma'.
	self var: 'gammapwr' declareC: 'float gammapwr'.
	self var: 'ro' declareC: 'float ro'.
	self var: 'ra' declareC: 'float ra'.
	self var: 'rk' declareC: 'float rk'.

	te _ (t0 * roNumber) asInteger.
	ro _ te asFloat / t0 asFloat.
	rk _ rkNumber.
	ra _ raNumber.

	ra <= 0.0
		ifTrue: [d _ 1.0]
		ifFalse: [r _ 1.0 - ro / ra.
				d _ 1.0 - (r / (r exp - 1.0))].

	phi _ PI * (rk + 1.0).
	cosphi _ phi cos.
	sinphi _ phi sin.
	rphid _ ra / ro * phi * d.

	u _ self zeroQphi: phi cosphi: cosphi sinphi: sinphi rphid: rphid.
	theta _ phi / te.
	rho _ (u * theta) exp.
	a1 _ 2.0 * theta cos * rho.
	a2 _ 0.0 - (rho * rho).
	x2 _ 0.0.
	x1 _ rho * theta sin.

	gamma _ (-1.0 / (ra * t0)) exp.
	gammapwr _ gamma raisedTo: t0 - te.

	b1 _ gamma.
	c1 _ (1.0 - gamma) * gammapwr / (1.0 - gammapwr).

	self normalizeGlottalPulse
]

{ #category : #private }
KlattSynthesizerPlugin >> saveTo: origKlattOop [
	| pitchOop a1Oop a2Oop x1Oop x2Oop b1Oop c1Oop glastOop vlastOop nlastOop klattOop |
	interpreterProxy pushRemappableOop: origKlattOop.
	interpreterProxy pushRemappableOop: (interpreterProxy floatObjectOf: pitch).
	interpreterProxy pushRemappableOop: (interpreterProxy floatObjectOf: a1).
	interpreterProxy pushRemappableOop: (interpreterProxy floatObjectOf: a2).
	interpreterProxy pushRemappableOop: (interpreterProxy floatObjectOf: x1).
	interpreterProxy pushRemappableOop: (interpreterProxy floatObjectOf: x2).
	interpreterProxy pushRemappableOop: (interpreterProxy floatObjectOf: b1).
	interpreterProxy pushRemappableOop: (interpreterProxy floatObjectOf: c1).
	interpreterProxy pushRemappableOop: (interpreterProxy floatObjectOf: glast).
	interpreterProxy pushRemappableOop: (interpreterProxy floatObjectOf: vlast).
	nlastOop _ interpreterProxy floatObjectOf: nlast.
	vlastOop _ interpreterProxy popRemappableOop.
	glastOop _ interpreterProxy popRemappableOop.
	c1Oop _ interpreterProxy popRemappableOop.
	b1Oop _ interpreterProxy popRemappableOop.
	x2Oop _ interpreterProxy popRemappableOop.
	x1Oop _ interpreterProxy popRemappableOop.
	a2Oop _ interpreterProxy popRemappableOop.
	a1Oop _ interpreterProxy popRemappableOop.
	pitchOop _ interpreterProxy popRemappableOop.
	klattOop _ interpreterProxy popRemappableOop.
	interpreterProxy failed ifTrue:[^ false].

	interpreterProxy storePointer: 2 ofObject: klattOop withValue: pitchOop.
	interpreterProxy storeInteger: 3 ofObject: klattOop withValue: t0.
	interpreterProxy storeInteger: 4 ofObject: klattOop withValue: nper.
	interpreterProxy storeInteger: 5 ofObject: klattOop withValue: nopen.
	interpreterProxy storeInteger: 6 ofObject: klattOop withValue: nmod.
	interpreterProxy storePointer: 7 ofObject: klattOop withValue: a1Oop.
	interpreterProxy storePointer: 8 ofObject: klattOop withValue: a2Oop.
	interpreterProxy storePointer: 9 ofObject: klattOop withValue: x1Oop.
	interpreterProxy storePointer: 10 ofObject: klattOop withValue: x2Oop.
	interpreterProxy storePointer: 11 ofObject: klattOop withValue: b1Oop.
	interpreterProxy storePointer: 12 ofObject: klattOop withValue: c1Oop.
	interpreterProxy storePointer: 13 ofObject: klattOop withValue: glastOop.
	interpreterProxy storePointer: 14 ofObject: klattOop withValue: vlastOop.
	interpreterProxy storePointer: 15 ofObject: klattOop withValue: nlastOop.
	interpreterProxy storeInteger: 16 ofObject: klattOop withValue: periodCount.
	interpreterProxy storeInteger: 17 ofObject: klattOop withValue: samplesCount.
	interpreterProxy storeInteger: 18 ofObject: klattOop withValue: seed.

	^ interpreterProxy failed == false
]

{ #category : #processing }
KlattSynthesizerPlugin >> setCurrentFrame: aKlattFrame [
	| ampFNV ampFTV ampF1V ampF2V ampF3V ampF4V ampF2F ampF3F ampF4F ampF5F ampF6F |
	self returnTypeC: 'void'.
	self var: 'aKlattFrame' declareC: 'float *aKlattFrame'.
	self var: 'ampFNV' declareC: 'float ampFNV'.
	self var: 'ampFTV' declareC: 'float ampFTV'.
	self var: 'ampF1V' declareC: 'float ampF1V'.
	self var: 'ampF2V' declareC: 'float ampF2V'.
	self var: 'ampF3V' declareC: 'float ampF3V'.
	self var: 'ampF4V' declareC: 'float ampF4V'.
	self var: 'ampF2F' declareC: 'float ampF2F'.
	self var: 'ampF3F' declareC: 'float ampF3F'.
	self var: 'ampF4F' declareC: 'float ampF4F'.
	self var: 'ampF5F' declareC: 'float ampF5F'.
	self var: 'ampF6F' declareC: 'float ampF6F'.

	frame _ aKlattFrame.

	"Fudge factors..."
	ampFNV _ (self linearFromdB: (frame at: Anv)) * 0.6.	"-4.44 dB"
	ampFTV _ (self linearFromdB: (frame at: Atv)) * 0.6.		"-4.44 dB"
	ampF1V _ (self linearFromdB: (frame at: A1v)) * 0.4.		"-7.96 dB"
	ampF2V _ (self linearFromdB: (frame at: A2v)) * 0.15.	"-16.5 dB"
	ampF3V _ (self linearFromdB: (frame at: A3v)) * 0.06.	"-24.4 dB"
	ampF4V _ (self linearFromdB: (frame at: A4v)) * 0.04.	"-28.0 dB"
	ampF2F _ (self linearFromdB: (frame at: A2f)) * 0.15.		"-16.5 dB"
	ampF3F _ (self linearFromdB: (frame at: A3f)) * 0.06.	"-24.4 dB"
	ampF4F _ (self linearFromdB: (frame at: A4f)) * 0.04.	"-28.0 dB"
	ampF5F _ (self linearFromdB: (frame at: A5f)) * 0.022.	"-33.2 dB"
	ampF6F _ (self linearFromdB: (frame at: A6f)) * 0.03.	"-30.5 dB"

	"Set coefficients of variable cascade resonators"
	cascade >= 8
		ifTrue: [samplingRate >= 16000	"Inside Nyquist rate?"
					ifTrue: [self resonator: R8c frequency: 7500 bandwidth: 600]
					ifFalse: [cascade _ 6]].
	cascade >= 7
		ifTrue: [samplingRate >= 16000	"Inside Nyquist rate?"
					ifTrue: [self resonator: R7c frequency: 6500 bandwidth: 500]
					ifFalse: [cascade _ 6]].
	cascade >= 6 ifTrue: [self resonator: R6c frequency: (frame at: F6) bandwidth: (frame at: B6)].
	cascade >= 5 ifTrue: [self resonator: R5c frequency: (frame at: F5) bandwidth: (frame at: B5)].
	self resonator: R4c frequency: (frame at: F4) bandwidth: (frame at: B4).
	self resonator: R3c frequency: (frame at: F3) bandwidth: (frame at: B3).
	self resonator: R2c frequency: (frame at: F2) bandwidth: (frame at: B2).
	self resonator: R1c frequency: (frame at: F1) bandwidth: (frame at: B1).

	"Set coefficients of nasal and tracheal resonators and antiresonators"
	self resonator: Rnpc frequency: (frame at: Fnp) bandwidth: (frame at: Bnp).
	self resonator: Rtpc frequency: (frame at: Ftp) bandwidth: (frame at: Btp).
	self antiResonator: Rnz frequency: (frame at: Fnz) bandwidth: (frame at: Bnz).
	self antiResonator: Rtz frequency: (frame at: Ftz) bandwidth: (frame at: Btz).

	"Set coefficients of parallel resonators, and amplitude of outputs"
	self resonator: Rnpp frequency: (frame at: Fnp) bandwidth: (frame at: Bnp) gain: ampFNV.
	self resonator: Rtpp frequency: (frame at: Ftp) bandwidth: (frame at: Btp) gain: ampFTV.
	self resonator: R1vp frequency: (frame at: F1) bandwidth: (frame at: B1) gain: ampF1V.
	self resonator: R2vp frequency: (frame at: F2) bandwidth: (frame at: B2) gain: ampF2V.
	self resonator: R3vp frequency: (frame at: F3) bandwidth: (frame at: B3) gain: ampF3V.
	self resonator: R4vp frequency: (frame at: F4) bandwidth: (frame at: B4) gain: ampF4V.
	self resonator: R2fp frequency: (frame at: F2) bandwidth: (frame at: B2f) gain: ampF2F.
	self resonator: R3fp frequency: (frame at: F3) bandwidth: (frame at: B3f) gain: ampF3F.
	self resonator: R4fp frequency: (frame at: F4) bandwidth: (frame at: B4f) gain: ampF4F.
	self resonator: R5fp frequency: (frame at: F5) bandwidth: (frame at: B5f) gain: ampF5F.
	self resonator: R6fp frequency: (frame at: F6) bandwidth: (frame at: B6f) gain: ampF6F
]

{ #category : #processing }
KlattSynthesizerPlugin >> synthesizeFrame: aKlattFrame into: buffer startingAt: startIndex [
	| noise voice frictionNoise aspirationNoise glotout
	parGlotout source temp out
	index top
	voicing parVoicing turbulence friction aspiration bypass
	gain ampGain |

	self returnTypeC: 'void'.
	self var: 'aKlattFrame' declareC: 'float *aKlattFrame'.
	self var: 'buffer' declareC: 'short *buffer'.
	self var: 'noise' declareC: 'float noise'.
	self var: 'voice' declareC: 'float voice'.
	self var: 'frictionNoise' declareC: 'float frictionNoise'.
	self var: 'aspirationNoise' declareC: 'float aspirationNoise'.
	self var: 'voicing' declareC: 'float voicing'.
	self var: 'parVoicing' declareC: 'float parVoicing'.
	self var: 'turbulence' declareC: 'float turbulence'.
	self var: 'friction' declareC: 'float friction'.
	self var: 'aspiration' declareC: 'float aspiration'.
	self var: 'bypass' declareC: 'float bypass'.
	self var: 'glotout' declareC: 'float glotout'.
	self var: 'parGlotout' declareC: 'float parGlotout'.
	self var: 'source' declareC: 'float source'.
	self var: 'gain' declareC: 'float gain'.
	self var: 'ampGain' declareC: 'float ampGain'.
	self var: 'out' declareC: 'float out'.

	self setCurrentFrame: aKlattFrame.

	pitch > 0
		ifTrue: [voicing _ self linearFromdB: (frame at: Voicing) - 7.
				parVoicing _ self linearFromdB: (frame at: Voicing).
				turbulence _ (self linearFromdB: (frame at: Turbulence)) * 0.1]
		ifFalse: [voicing _ parVoicing _ turbulence _ 0.0].

	friction _ (self linearFromdB: (frame at: Friction)) * 0.25.
	aspiration _ (self linearFromdB: (frame at: Aspiration)) * 0.05.
	bypass _ (self linearFromdB: (frame at: Bypass)) * 0.05.		"-26.0 dB"

	"Flod overall gain into output resonator (low-pass filter)"
	gain _ (frame at: Gain) - 3.
	gain <= 0 ifTrue: [gain _ 57].
	ampGain _ self linearFromdB: gain.
	self resonator: Rout frequency: 0 bandwidth: samplingRate gain: ampGain.

	noise _ nlast.
	index _ startIndex.
	top _ samplesPerFrame + startIndex - 1.
	[index <= top] whileTrue: [
		"Get low-passed random number for aspiration and friction noise"
		noise _ (self nextRandom - 32768) asFloat / 4.0. "radom number between -8196.0 and 8196.0"

		"Tilt down noise spectrum by soft low-pass filter having
		 a pole near the origin in the z-plane."
		noise _ noise + (0.75 * nlast).
		nlast _ noise.

		"Amplitude modulate noise (reduce noise amplitude during second
		 half of glottal period) if voicing  simultaneously present."
		nper > nmod ifTrue: [noise _ noise * 0.5].

		"Compute frictation noise"
		frictionNoise _ friction * noise.

		"Compute voicing waveform."
		voice _ self glottalSource.
		vlast _ voice.

		"Add turbulence during glottal open phase.
		 Use random rather than noise because noise is low-passed."
		nper < nopen ifTrue: [voice _ voice + (turbulence * (self nextRandom - 32768) asFloat / 4.0)].

		"Set amplitude of voicing."
		glotout _ voicing * voice.
		parGlotout _ parVoicing * voice.

		"Compute aspiration amplitude and add to voicing source."
		aspirationNoise _ aspiration * noise.
		glotout _ glotout + aspirationNoise.
		parGlotout _ parGlotout + aspirationNoise.

		"Cascade vocal tract, excited by laryngeal sources.
		 Nasal antiresonator, nasal resonator, trachearl antirresonator,
		 tracheal resonator, then formants F8, F7, F6, F5, F4, F3, F2, F1."
		out _ self cascadeBranch: glotout.

		"Voice-excited parallel vocal tract F1, F2, F3, F4, FNP and FTP."
		source _ parGlotout.	"Source is voicing plus aspiration."
		out _ out + (self parallelVoicedBranch: source).

		"Friction-excited parallel vocal tract formants F6, F5, F4, F3, F2,
		 outputs added with alternating sign. Sound source for other
		 parallel resonators is friction plus first difference of
		 voicing waveform."
		source _ frictionNoise + parGlotout - glast.
		glast _ parGlotout.
		out _ (self parallelFrictionBranch: source) - out.

		"Apply bypas and output low-pass filter"
		out _ bypass * source - out.
		out _ self resonator: Rout value: out.
		temp _ (out * ampGain) asInteger.
		temp < -32768 ifTrue: [temp _ -32768].
		temp > 32767 ifTrue: [temp _ 32767].
		buffer at: index - 1 put: temp.
		index _ index + 1.
		samplesCount _ samplesCount + 1]
]

{ #category : #'processing-voice' }
KlattSynthesizerPlugin >> voicedPitchSynchronousReset [
	self returnTypeC: 'void'.

	"Set the pitch."
	pitch _ frame at: F0.

	"Add flutter and jitter (F0 perturbations)."
	self addFlutter.
	self addJitter.
	self addFrequencyDiplophonia.
	pitch < 0 ifTrue: [pitch _ 0].

	"Recompute t0 (it is the number of samples in one pitch period)."
	t0 _ (samplingRate / pitch) asInteger.

	"Duration of period before amplitude modulation."
	nmod _ t0.
	(frame at: Voicing) > 0 ifTrue: [nmod _ nmod // 2].

	"Set open phase of glottal period."
	nopen _ (t0 * (frame at: Ro)) asInteger.

	"Set the LF glottal pulse model parameters."
	self ro: (frame at: Ro) ra: (frame at: Ra) rk: (frame at: Rk).

	"Add shimmer and diplophonia amplitude pertirbations.
	(This must be done AFTER the actual computation of the LF parameters.)"
	self addShimmer.
	self addAmplitudeDiplophonia
]

{ #category : #'processing-LF' }
KlattSynthesizerPlugin >> zeroQphi: phi cosphi: cosphi sinphi: sinphi rphid: rphid [
	| qzero ua ub qa qb uc qc |
	self returnTypeC: 'float'.
	self var: 'qzero' declareC: 'float qzero'.
	self var: 'ua' declareC: 'float ua'.
	self var: 'ub' declareC: 'float ub'.
	self var: 'qa' declareC: 'float qa'.
	self var: 'qb' declareC: 'float qb'.
	self var: 'uc' declareC: 'float uc'.
	self var: 'qc' declareC: 'float qc'.
	self var: 'phi' declareC: 'float phi'.
	self var: 'cosphi' declareC: 'float cosphi'.
	self var: 'sinphi' declareC: 'float sinphi'.
	self var: 'rphid' declareC: 'float rphid'.

	qzero _ self qu: 0 phi: phi cosphi: cosphi sinphi: sinphi rphid: rphid.

	qzero > 0
		ifTrue: [ua _ 0. ub _ 1.
				qa _ qzero. qb _ self qu: ub phi: phi cosphi: cosphi sinphi: sinphi rphid: rphid.
				[qb > 0]
					whileTrue: [ua _ ub. qa _ qb.
								ub _ ub * 2. qb _ self qu: ub phi: phi cosphi: cosphi sinphi: sinphi rphid: rphid]]
		ifFalse: [ua _ -1. ub _ 0.
				qa _ self qu: ua phi: phi cosphi: cosphi sinphi: sinphi rphid: rphid. qb _ qzero.
				[qa < 0]
					whileTrue: [ub _ ua. qb _ qa.
								ua _ ua * 2. qa _ self qu: ua phi: phi cosphi: cosphi sinphi: sinphi rphid: rphid]].
	[ub - ua > Epsilon]
		whileTrue: [uc _ ub + ua / 2.0. qc _ self qu: uc phi: phi cosphi: cosphi sinphi: sinphi rphid: rphid.
					qc > 0 ifTrue: [ua _ uc. qa _ qc] ifFalse: [ub _ uc. qb _ qc]].
	^ ub + ua / 2.0
]
