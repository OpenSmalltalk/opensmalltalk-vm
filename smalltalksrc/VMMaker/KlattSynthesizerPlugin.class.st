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
		'A1v',
		'A2f',
		'A2v',
		'A3f',
		'A3v',
		'A4f',
		'A4v',
		'A5f',
		'A6f',
		'Anv',
		'Aspiration',
		'Atv',
		'B1',
		'B2',
		'B2f',
		'B3',
		'B3f',
		'B4',
		'B4f',
		'B5',
		'B5f',
		'B6',
		'B6f',
		'Bnp',
		'Bnz',
		'Btp',
		'Btz',
		'Bypass',
		'Db1',
		'Df1',
		'Diplophonia',
		'Epsilon',
		'F0',
		'F1',
		'F2',
		'F3',
		'F4',
		'F5',
		'F6',
		'Flutter',
		'Fnp',
		'Fnz',
		'Friction',
		'Ftp',
		'Ftz',
		'Gain',
		'Jitter',
		'PI',
		'Ra',
		'Rk',
		'Ro',
		'Shimmer',
		'Turbulence',
		'Voicing'
	],
	#pools : [
		'KlattResonatorIndices'
	],
	#category : 'VMMaker-Plugins'
}

{ #category : #translation }
KlattSynthesizerPlugin class >> declareCVarsIn: cg [ 
	cg var: #resonators type: #'float *'.
	cg var: #frame type: #'float *'.
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
	| parameterClass |
	parameterClass := (Smalltalk hasClassNamed: #KlattFrame)
		ifTrue: [Smalltalk at: #KlattFrame "original package structure"]
		ifFalse: [Smalltalk at: #KlattResonatorIndices "repackaged to separate plugin from Speech dependency"].
	
	parameterClass parameterNames
		doWithIndex: [ :each :i | self classPool at: each capitalized asSymbol put: i-1].
	PI := Float pi	.
	Epsilon := 1.0e-04
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
	<returnTypeC: 'void'>
	periodCount \\ 2 = 0
		ifFalse: [x1 := x1 * (1.0 - (frame at: Diplophonia)).
				"x1 must be <= 0"
				x1 > 0 ifTrue: [x1 := 0]]
]

{ #category : #'processing-voice' }
KlattSynthesizerPlugin >> addFlutter [
	"Add F0 flutter, as specified in:
		'Analysis, synthesis and perception of voice quality variations among
		female and male talkers' D.H. Klatt and L.C. Klatt JASA 87(2) February 1990.
	Flutter is added by applying a quasi-random element constructed from three
	slowly varying sine waves."
	| timeCount asin bsin csin deltaF0 |
	<returnTypeC: 'void'>
	<var: 'timeCount' type: 'float '>
	<var: 'asin' type: 'float '>
	<var: 'bsin' type: 'float '>
	<var: 'csin' type: 'float '>
	<var: 'deltaF0' type: 'double '>
	timeCount := (self cCoerce: samplesCount to: 'float') / (self cCoerce: samplingRate to: 'float').
	asin := (2.0 * PI * 12.7 * timeCount) sin.
	bsin := (2.0 * PI * 7.1 * timeCount) sin.
	csin := (2.0 * PI * 4.7 * timeCount) sin.
	deltaF0 := (frame at: Flutter) * 2.0 * (frame at: F0) / 100.0 * (asin + bsin + csin).
	pitch := pitch + deltaF0
]

{ #category : #'processing-voice' }
KlattSynthesizerPlugin >> addFrequencyDiplophonia [
	"Add diplophonia (bicyclic voice). Change F0."
	<returnTypeC: 'void'>
	periodCount \\ 2 = 0
		ifTrue: [pitch := pitch + ((frame at: Diplophonia) * (frame at: F0) * (1.0 - (frame at: Ro)))]
		ifFalse: [pitch := pitch - ((frame at: Diplophonia) * (frame at: F0) * (1.0 - (frame at: Ro)))]
]

{ #category : #'processing-voice' }
KlattSynthesizerPlugin >> addJitter [
	"Add jitter (random F0 perturbation)."
	<returnTypeC: 'void'>
	pitch := pitch + (self nextRandom - 32767 * (frame at: Jitter) / 32768.0 * (frame at: F0))
]

{ #category : #'processing-voice' }
KlattSynthesizerPlugin >> addShimmer [
	"Add shimmer (random voicing amplitude perturbation)."
	<returnTypeC: 'void'>
	x1 := x1 + (self nextRandom - 32767 * (frame at: Shimmer) / 32768.0 * x1).
	"x1 must be <= 0"
	x1 > 0 ifTrue: [x1 := 0]
]

{ #category : #resonators }
KlattSynthesizerPlugin >> antiResonator: index frequency: freq bandwidth: bw [
	"Set up an anti-resonator"
	| arg r a b c |
	<returnTypeC: 'void'>
	<var: 'freq' type: 'float '>
	<var: 'bw' type: 'float '>
	<var: 'arg' type: 'double '>
	<var: 'a' type: 'float '>
	<var: 'b' type: 'float '>
	<var: 'c' type: 'float '>
	<var: 'r' type: 'float '>
	arg := 0.0 - PI / samplingRate * bw.
	r := arg exp.
	c := 0.0 - (r * r).
	arg := PI * 2.0 / samplingRate * freq.
	b := r * arg cos * 2.0.
	a := 1.0 - b - c.
	a := 1.0 / a.
	b := 0.0 - b * a.
	c := 0.0 - c * a.
	self resonatorA: index put: a.
	self resonatorB: index put: b.
	self resonatorC: index put: c
]

{ #category : #resonators }
KlattSynthesizerPlugin >> antiResonator: index value: aFloat [
	| answer p1 |
	<inline: true>
	<returnTypeC: 'float'>
	<var: 'aFloat' type: 'double '>
	<var: 'answer' type: 'double '>
	<var: 'p1' type: 'double '>
	answer := (self resonatorA: index) * aFloat
			+ ((self resonatorB: index) * (p1 := self resonatorP1: index))
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
	<inline: true>
	<returnTypeC: 'float'>
	<var: 'source' type: 'float '>
	<var: 'out' type: 'float '>
	cascade > 0 ifFalse: [^ 0.0].
	out := self antiResonator: Rnz value: source.
	out := self resonator: Rnpc value: out.
	out := self antiResonator: Rtz value: out.
	out := self resonator: Rtpc value: out.
	"Do not use unless sample rate >= 16000"
	cascade >= 8 ifTrue: [out := self resonator: R8c value: out].
	"Do not use unless sample rate >= 16000"
	cascade >= 7 ifTrue: [out := self resonator: R7c value: out].
	"Do not use unless long vocal tract or sample rate increased"
	cascade >= 6 ifTrue: [out := self resonator: R6c value: out].
	cascade >= 5 ifTrue: [out := self resonator: R5c value: out].
	cascade >= 4 ifTrue: [out := self resonator: R4c value: out].
	cascade >= 3 ifTrue: [out := self resonator: R3c value: out].
	cascade >= 2 ifTrue: [out := self resonator: R2c value: out].
	cascade >= 1 ifTrue: [out := self resonator: R1c value: out].
	^ out
]

{ #category : #private }
KlattSynthesizerPlugin >> checkedFloatPtrOf: oop [
	"Return the first indexable word of oop which is assumed to be variableWordSubclass"
	<returnTypeC: 'float *'>
	interpreterProxy success: (interpreterProxy isWords: oop).
	interpreterProxy failed ifTrue:[^0].
	^self cCoerce: (interpreterProxy firstIndexableField: oop) to:'float *'
]

{ #category : #private }
KlattSynthesizerPlugin >> checkedShortPtrOf: oop [
	"Return the first indexable word of oop which is assumed to be variableWordSubclass"
	<returnTypeC: 'short *'>
	interpreterProxy success: (interpreterProxy isWords: oop).
	interpreterProxy failed ifTrue:[^0].
	^self cCoerce: (interpreterProxy firstIndexableField: oop) to:'short *'
]

{ #category : #'processing-LF' }
KlattSynthesizerPlugin >> glottalSource [
	| x0 |
	<inline: true>
	<returnTypeC: 'float'>
	<var: 'x0' type: 'float '>
	t0 = 0 ifTrue: [^ 0].
	nper < nopen
		ifTrue: [x0 := a1 * x1 + (a2 * x2).
				x2 := x1.
				x1 := x0]
		ifFalse: [x0 := b1 * x1 - c1.
				x1 := x0].
	"Reset period when 'nper' reaches t0."
	nper >= t0 ifTrue: [nper := 0. self pitchSynchronousReset].
	nper := nper + 1.
	^ x0
]

{ #category : #processing }
KlattSynthesizerPlugin >> linearFromdB: aNumber [
	<inline: true>
	<returnTypeC: 'float'>
	<var: 'aNumber' type: 'double '>
	^ (2.0 raisedTo: (aNumber-87.0/6.0)) * 32.767
]

{ #category : #private }
KlattSynthesizerPlugin >> loadFrom: klattOop [
	| oop |
	interpreterProxy success: (interpreterProxy slotSizeOf: klattOop) = 22.
	interpreterProxy failed ifTrue:[^ false].

	oop := interpreterProxy fetchPointer: 0 ofObject: klattOop.
	resonators := self checkedFloatPtrOf: oop.

	pitch := interpreterProxy fetchFloat: 2 ofObject: klattOop.
	t0 := interpreterProxy fetchInteger: 3 ofObject: klattOop.
	nper := interpreterProxy fetchInteger: 4 ofObject: klattOop.
	nopen := interpreterProxy fetchInteger: 5 ofObject: klattOop.
	nmod := interpreterProxy fetchInteger: 6 ofObject: klattOop.
	a1 := interpreterProxy fetchFloat: 7 ofObject: klattOop.
	a2 := interpreterProxy fetchFloat: 8 ofObject: klattOop.
	x1 := interpreterProxy fetchFloat: 9 ofObject: klattOop.
	x2 := interpreterProxy fetchFloat: 10 ofObject: klattOop.
	b1 := interpreterProxy fetchFloat: 11 ofObject: klattOop.
	c1 := interpreterProxy fetchFloat: 12 ofObject: klattOop.
	glast := interpreterProxy fetchFloat: 13 ofObject: klattOop.
	vlast := interpreterProxy fetchFloat: 14 ofObject: klattOop.
	nlast := interpreterProxy fetchFloat: 15 ofObject: klattOop.
	periodCount := interpreterProxy fetchInteger: 16 ofObject: klattOop.
	samplesCount := interpreterProxy fetchInteger: 17 ofObject: klattOop.
	seed := interpreterProxy fetchInteger: 18 ofObject: klattOop.
	cascade := interpreterProxy fetchInteger: 19 ofObject: klattOop.
	samplesPerFrame := interpreterProxy fetchInteger: 20 ofObject: klattOop.
	samplingRate := interpreterProxy fetchInteger: 21 ofObject: klattOop.

	^ interpreterProxy failed == false
]

{ #category : #processing }
KlattSynthesizerPlugin >> nextRandom [
	"Answer a random number between 0 and 65535."
	<inline: true>
	seed := (seed * 1309) + 13849 bitAnd: 65535.
	^ seed
]

{ #category : #'processing-LF' }
KlattSynthesizerPlugin >> normalizeGlottalPulse [
	| s1 s2 s0 |
	<inline: true>
	<returnTypeC: 'void'>
	<var: 's0' type: 'float '>
	<var: 's1' type: 'float '>
	<var: 's2' type: 'float '>
	s0 := 0.0.
	s1 := x1.
	s2 := x2.
	1 to: nopen do: [ :ingore |
		s0 := a1 * s1 + (a2 * s2).
		s2 := s1.
		s1 := s0].
	s0 = 0.0 ifFalse: [x1 := x1 / s0 * 10000.0]
]

{ #category : #processing }
KlattSynthesizerPlugin >> parallelFrictionBranch: source [
	"Friction-excited parallel vocal tract formants F6, F5, F4, F3, F2,
	outputs added with alternating sign. Sound source for other
	parallel resonators is friction plus first difference of
	voicing waveform."
	<inline: true>
	<returnTypeC: 'float'>
	<var: 'source' type: 'float '>
	^ (self resonator: R2fp value: source) - (self resonator: R3fp value: source) + (self resonator: R4fp value: source) - (self resonator: R5fp value: source) + (self resonator: R6fp value: source)
]

{ #category : #processing }
KlattSynthesizerPlugin >> parallelVoicedBranch: source [
	"Voice-excited parallel vocal tract F1, F2, F3, F4, FNP and FTP."
	<inline: true>
	<returnTypeC: 'float'>
	<var: 'source' type: 'float '>
	^ (self resonator: R1vp value: source) + (self resonator: R2vp value: source) + (self resonator: R3vp value: source) + (self resonator: R4vp value: source) + (self resonator: Rnpp value: source) + (self resonator: Rtpp value: source)
]

{ #category : #'processing-voice' }
KlattSynthesizerPlugin >> pitchSynchronousReset [
	<returnTypeC: 'void'>
	(frame at: F0) > 0
		ifTrue: [self voicedPitchSynchronousReset.
				periodCount := periodCount + 1 \\ 65535]
		ifFalse: [t0 := 1.
				nmod := t0]
]

{ #category : #primitives }
KlattSynthesizerPlugin >> primitiveSynthesizeFrameIntoStartingAt [
	| aKlattFrame buffer startIndex rcvr bufferOop |
	<export: true>
	<var: 'aKlattFrame' type: 'float *'>
	<var: 'buffer' type: 'short *'>
	aKlattFrame := self checkedFloatPtrOf: (interpreterProxy stackValue: 2).
	buffer := self checkedShortPtrOf: (bufferOop := interpreterProxy stackValue: 1).
	startIndex := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue: [^nil].
	rcvr := interpreterProxy stackObjectValue: 3.
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
	<returnTypeC: 'float'>
	<var: 'u' type: 'float '>
	<var: 'phi' type: 'float '>
	<var: 'cosphi' type: 'float '>
	<var: 'sinphi' type: 'float '>
	<var: 'rphid' type: 'float '>
	<var: 'expuphi' type: 'float '>
	expuphi := (u * phi) exp.
	^ expuphi * ((rphid * (u*u + 1.0) + u) * sinphi - cosphi) + 1.0
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonator: index frequency: freq bandwidth: bw [
	"Convert formant frequencies and bandwidth into
	resonator difference equation coefficients."
	| arg r a b c |
	<returnTypeC: 'void'>
	<var: 'freq' type: 'float '>
	<var: 'bw' type: 'float '>
	<var: 'arg' type: 'double '>
	<var: 'a' type: 'float '>
	<var: 'b' type: 'float '>
	<var: 'c' type: 'float '>
	<var: 'r' type: 'float '>
	arg := 0.0 - PI / samplingRate * bw.
	r := arg exp.
	c := 0.0 - (r * r).
	arg := PI * 2.0 / samplingRate * freq.
	b := r * arg cos * 2.0.
	a := 1.0 - b - c.
	self resonatorA: index put: a.
	self resonatorB: index put: b.
	self resonatorC: index put: c
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonator: index frequency: freq bandwidth: bw gain: gain [
	"Convert formant frequencies and bandwidth into
	resonator difference equation coefficients."
	<returnTypeC: 'void'>
	<var: 'freq' type: 'float '>
	<var: 'bw' type: 'float '>
	<var: 'gain' type: 'float '>
	self resonator: index frequency: freq bandwidth: bw.
	self resonatorA: index put: (self resonatorA: index) * gain
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonator: index value: aFloat [
	| answer p1 |
	<inline: true>
	<returnTypeC: 'float'>
	<var: 'aFloat' type: 'float '>
	<var: 'answer' type: 'float '>
	<var: 'p1' type: 'float '>
	answer := (self resonatorA: index) * aFloat
			+ ((self resonatorB: index) * (p1 := self resonatorP1: index))
			+ ((self resonatorC: index) * (self resonatorP2: index)).
	"(p1 between: -100000 and: 100000) ifFalse: [self halt].
	(answer between: -100000 and: 100000) ifFalse: [self halt]."
	self resonatorP2: index put: p1.
	self resonatorP1: index put: answer.
	^ answer
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorA: index [
	<inline: true>
	<returnTypeC: 'float'>
	^resonators at: index*5-5
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorA: index put: aFloat [
	<inline: true>
	<returnTypeC: 'void'>
	<var: 'aFloat' type: 'float '>
	resonators at: index*5-5 put: aFloat
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorB: index [
	<inline: true>
	<returnTypeC: 'float'>
	^resonators at: index*5-4
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorB: index put: aFloat [
	<inline: true>
	<returnTypeC: 'void'>
	<var: 'aFloat' type: 'float '>
	resonators at: index*5-4 put: aFloat
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorC: index [
	<inline: true>
	<returnTypeC: 'float'>
	^resonators at: index*5-3
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorC: index put: aFloat [
	<inline: true>
	<returnTypeC: 'void'>
	<var: 'aFloat' type: 'float '>
	resonators at: index*5-3 put: aFloat
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorP1: index [
	<inline: true>
	<returnTypeC: 'float'>
	^resonators at: index*5-2
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorP1: index put: aFloat [
	<inline: true>
	<returnTypeC: 'void'>
	<var: 'aFloat' type: 'float '>
	resonators at: index*5-2 put: aFloat
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorP2: index [
	<inline: true>
	<returnTypeC: 'float'>
	^resonators at: index*5-1
]

{ #category : #resonators }
KlattSynthesizerPlugin >> resonatorP2: index put: aFloat [
	<inline: true>
	<returnTypeC: 'void'>
	<var: 'aFloat' type: 'float '>
	resonators at: index*5-1 put: aFloat
]

{ #category : #'processing-LF' }
KlattSynthesizerPlugin >> ro: roNumber ra: raNumber rk: rkNumber [
	| r d phi cosphi sinphi rphid u theta rho gamma gammapwr te ro ra rk |

	<returnTypeC: 'void'>
	<var: 'roNumber' type: 'float '>
	<var: 'raNumber' type: 'float '>
	<var: 'rkNumber' type: 'float '>
	<var: 'r' type: 'float '>
	<var: 'd' type: 'float '>
	<var: 'phi' type: 'float '>
	<var: 'cosphi' type: 'float '>
	<var: 'sinphi' type: 'float '>
	<var: 'rphid' type: 'float '>
	<var: 'u' type: 'float '>
	<var: 'theta' type: 'float '>
	<var: 'rho' type: 'float '>
	<var: 'gamma' type: 'float '>
	<var: 'gammapwr' type: 'float '>
	<var: 'ro' type: 'float '>
	<var: 'ra' type: 'float '>
	<var: 'rk' type: 'float '>

	te := (t0 * roNumber) asInteger.
	ro := te asFloat / t0 asFloat.
	rk := rkNumber.
	ra := raNumber.

	ra <= 0.0
		ifTrue: [d := 1.0]
		ifFalse: [r := 1.0 - ro / ra.
				d := 1.0 - (r / (r exp - 1.0))].

	phi := PI * (rk + 1.0).
	cosphi := phi cos.
	sinphi := phi sin.
	rphid := ra / ro * phi * d.

	u := self zeroQphi: phi cosphi: cosphi sinphi: sinphi rphid: rphid.
	theta := phi / te.
	rho := (u * theta) exp.
	a1 := 2.0 * theta cos * rho.
	a2 := 0.0 - (rho * rho).
	x2 := 0.0.
	x1 := rho * theta sin.

	gamma := (-1.0 / (ra * t0)) exp.
	gammapwr := gamma raisedTo: t0 - te.

	b1 := gamma.
	c1 := (1.0 - gamma) * gammapwr / (1.0 - gammapwr).

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
	nlastOop := interpreterProxy floatObjectOf: nlast.
	vlastOop := interpreterProxy popRemappableOop.
	glastOop := interpreterProxy popRemappableOop.
	c1Oop := interpreterProxy popRemappableOop.
	b1Oop := interpreterProxy popRemappableOop.
	x2Oop := interpreterProxy popRemappableOop.
	x1Oop := interpreterProxy popRemappableOop.
	a2Oop := interpreterProxy popRemappableOop.
	a1Oop := interpreterProxy popRemappableOop.
	pitchOop := interpreterProxy popRemappableOop.
	klattOop := interpreterProxy popRemappableOop.
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
	<returnTypeC: 'void'>
	<var: 'aKlattFrame' type: 'float *'>
	<var: 'ampFNV' type: 'float '>
	<var: 'ampFTV' type: 'float '>
	<var: 'ampF1V' type: 'float '>
	<var: 'ampF2V' type: 'float '>
	<var: 'ampF3V' type: 'float '>
	<var: 'ampF4V' type: 'float '>
	<var: 'ampF2F' type: 'float '>
	<var: 'ampF3F' type: 'float '>
	<var: 'ampF4F' type: 'float '>
	<var: 'ampF5F' type: 'float '>
	<var: 'ampF6F' type: 'float '>

	frame := aKlattFrame.

	"Fudge factors..."
	ampFNV := (self linearFromdB: (frame at: Anv)) * 0.6.	"-4.44 dB"
	ampFTV := (self linearFromdB: (frame at: Atv)) * 0.6.		"-4.44 dB"
	ampF1V := (self linearFromdB: (frame at: A1v)) * 0.4.		"-7.96 dB"
	ampF2V := (self linearFromdB: (frame at: A2v)) * 0.15.	"-16.5 dB"
	ampF3V := (self linearFromdB: (frame at: A3v)) * 0.06.	"-24.4 dB"
	ampF4V := (self linearFromdB: (frame at: A4v)) * 0.04.	"-28.0 dB"
	ampF2F := (self linearFromdB: (frame at: A2f)) * 0.15.		"-16.5 dB"
	ampF3F := (self linearFromdB: (frame at: A3f)) * 0.06.	"-24.4 dB"
	ampF4F := (self linearFromdB: (frame at: A4f)) * 0.04.	"-28.0 dB"
	ampF5F := (self linearFromdB: (frame at: A5f)) * 0.022.	"-33.2 dB"
	ampF6F := (self linearFromdB: (frame at: A6f)) * 0.03.	"-30.5 dB"

	"Set coefficients of variable cascade resonators"
	cascade >= 8
		ifTrue: [samplingRate >= 16000	"Inside Nyquist rate?"
					ifTrue: [self resonator: R8c frequency: 7500 bandwidth: 600]
					ifFalse: [cascade := 6]].
	cascade >= 7
		ifTrue: [samplingRate >= 16000	"Inside Nyquist rate?"
					ifTrue: [self resonator: R7c frequency: 6500 bandwidth: 500]
					ifFalse: [cascade := 6]].
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

	<returnTypeC: 'void'>
	<var: 'aKlattFrame' type: 'float *'>
	<var: 'buffer' type: 'short *'>
	<var: 'noise' type: 'float '>
	<var: 'voice' type: 'float '>
	<var: 'frictionNoise' type: 'float '>
	<var: 'aspirationNoise' type: 'float '>
	<var: 'voicing' type: 'float '>
	<var: 'parVoicing' type: 'float '>
	<var: 'turbulence' type: 'float '>
	<var: 'friction' type: 'float '>
	<var: 'aspiration' type: 'float '>
	<var: 'bypass' type: 'float '>
	<var: 'glotout' type: 'float '>
	<var: 'parGlotout' type: 'float '>
	<var: 'source' type: 'float '>
	<var: 'gain' type: 'float '>
	<var: 'ampGain' type: 'float '>
	<var: 'out' type: 'float '>

	self setCurrentFrame: aKlattFrame.

	pitch > 0
		ifTrue: [voicing := self linearFromdB: (frame at: Voicing) - 7.
				parVoicing := self linearFromdB: (frame at: Voicing).
				turbulence := (self linearFromdB: (frame at: Turbulence)) * 0.1]
		ifFalse: [voicing := parVoicing := turbulence := 0.0].

	friction := (self linearFromdB: (frame at: Friction)) * 0.25.
	aspiration := (self linearFromdB: (frame at: Aspiration)) * 0.05.
	bypass := (self linearFromdB: (frame at: Bypass)) * 0.05.		"-26.0 dB"

	"Flod overall gain into output resonator (low-pass filter)"
	gain := (frame at: Gain) - 3.
	gain <= 0 ifTrue: [gain := 57].
	ampGain := self linearFromdB: gain.
	self resonator: Rout frequency: 0 bandwidth: samplingRate gain: ampGain.

	noise := nlast.
	index := startIndex.
	top := samplesPerFrame + startIndex - 1.
	[index <= top] whileTrue: [
		"Get low-passed random number for aspiration and friction noise"
		noise := (self nextRandom - 32768) asFloat / 4.0. "radom number between -8196.0 and 8196.0"

		"Tilt down noise spectrum by soft low-pass filter having
		 a pole near the origin in the z-plane."
		noise := noise + (0.75 * nlast).
		nlast := noise.

		"Amplitude modulate noise (reduce noise amplitude during second
		 half of glottal period) if voicing  simultaneously present."
		nper > nmod ifTrue: [noise := noise * 0.5].

		"Compute frictation noise"
		frictionNoise := friction * noise.

		"Compute voicing waveform."
		voice := self glottalSource.
		vlast := voice.

		"Add turbulence during glottal open phase.
		 Use random rather than noise because noise is low-passed."
		nper < nopen ifTrue: [voice := voice + (turbulence * (self nextRandom - 32768) asFloat / 4.0)].

		"Set amplitude of voicing."
		glotout := voicing * voice.
		parGlotout := parVoicing * voice.

		"Compute aspiration amplitude and add to voicing source."
		aspirationNoise := aspiration * noise.
		glotout := glotout + aspirationNoise.
		parGlotout := parGlotout + aspirationNoise.

		"Cascade vocal tract, excited by laryngeal sources.
		 Nasal antiresonator, nasal resonator, trachearl antirresonator,
		 tracheal resonator, then formants F8, F7, F6, F5, F4, F3, F2, F1."
		out := self cascadeBranch: glotout.

		"Voice-excited parallel vocal tract F1, F2, F3, F4, FNP and FTP."
		source := parGlotout.	"Source is voicing plus aspiration."
		out := out + (self parallelVoicedBranch: source).

		"Friction-excited parallel vocal tract formants F6, F5, F4, F3, F2,
		 outputs added with alternating sign. Sound source for other
		 parallel resonators is friction plus first difference of
		 voicing waveform."
		source := frictionNoise + parGlotout - glast.
		glast := parGlotout.
		out := (self parallelFrictionBranch: source) - out.

		"Apply bypas and output low-pass filter"
		out := bypass * source - out.
		out := self resonator: Rout value: out.
		temp := (out * ampGain) asInteger.
		temp < -32768 ifTrue: [temp := -32768].
		temp > 32767 ifTrue: [temp := 32767].
		buffer at: index - 1 put: temp.
		index := index + 1.
		samplesCount := samplesCount + 1]
]

{ #category : #'processing-voice' }
KlattSynthesizerPlugin >> voicedPitchSynchronousReset [
	<returnTypeC: 'void'>

	"Set the pitch."
	pitch := frame at: F0.

	"Add flutter and jitter (F0 perturbations)."
	self addFlutter.
	self addJitter.
	self addFrequencyDiplophonia.
	pitch < 0 ifTrue: [pitch := 0].

	"Recompute t0 (it is the number of samples in one pitch period)."
	t0 := (samplingRate / pitch) asInteger.

	"Duration of period before amplitude modulation."
	nmod := t0.
	(frame at: Voicing) > 0 ifTrue: [nmod := nmod // 2].

	"Set open phase of glottal period."
	nopen := (t0 * (frame at: Ro)) asInteger.

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
	<returnTypeC: 'float'>
	<var: 'qzero' type: 'float '>
	<var: 'ua' type: 'float '>
	<var: 'ub' type: 'float '>
	<var: 'qa' type: 'float '>
	<var: 'qb' type: 'float '>
	<var: 'uc' type: 'float '>
	<var: 'qc' type: 'float '>
	<var: 'phi' type: 'float '>
	<var: 'cosphi' type: 'float '>
	<var: 'sinphi' type: 'float '>
	<var: 'rphid' type: 'float '>

	qzero := self qu: 0 phi: phi cosphi: cosphi sinphi: sinphi rphid: rphid.

	qzero > 0
		ifTrue: [ua := 0. ub := 1.
				qa := qzero. qb := self qu: ub phi: phi cosphi: cosphi sinphi: sinphi rphid: rphid.
				[qb > 0]
					whileTrue: [ua := ub. qa := qb.
								ub := ub * 2. qb := self qu: ub phi: phi cosphi: cosphi sinphi: sinphi rphid: rphid]]
		ifFalse: [ua := -1. ub := 0.
				qa := self qu: ua phi: phi cosphi: cosphi sinphi: sinphi rphid: rphid. qb := qzero.
				[qa < 0]
					whileTrue: [ub := ua. qb := qa.
								ua := ua * 2. qa := self qu: ua phi: phi cosphi: cosphi sinphi: sinphi rphid: rphid]].
	[ub - ua > Epsilon]
		whileTrue: [uc := ub + ua / 2.0. qc := self qu: uc phi: phi cosphi: cosphi sinphi: sinphi rphid: rphid.
					qc > 0 ifTrue: [ua := uc. qa := qc] ifFalse: [ub := uc. qb := qc]].
	^ ub + ua / 2.0
]
