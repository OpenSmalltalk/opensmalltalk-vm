"
These tests require VMMaker and should be considered part of it.
"
Class {
	#name : #BitBltSimulationTest,
	#superclass : #TestCase,
	#category : #'VMMaker-OriginalTests'
}

{ #category : #running }
BitBltSimulationTest >> setUp [
	(self respondsTo: #timeout: )
		ifTrue: [self perform: #timeout: with: 10]

]

{ #category : #tests }
BitBltSimulationTest >> testAlphaCompositing2Simulated [
	"self run: #testAlphaCompositing2Simulated"

	| bb f1 f2 mixColor result eps |
	f1 := Form extent: 1@1 depth: 32.
	f2 := Form extent: 1@1 depth: 32.
	eps := 0.5 / 255.
	0 to: 255 do:[:i|
		f1 colorAt: 0@0 put: Color transparent.
		mixColor := Color red alpha: i / 255.0.
		f2 colorAt: 0@0 put: mixColor.
		mixColor := f2 colorAt: 0@0.
		bb := BitBlt toForm: f1.
		bb sourceForm: f2.
		bb combinationRule: Form blend.
		bb copyBitsSimulated.
		result := f1 colorAt: 0@0.
		self assert: (result red - mixColor alpha) abs < eps.
		self assert: result alpha = mixColor alpha.
	]
]

{ #category : #tests }
BitBltSimulationTest >> testAlphaCompositingSimulated [
	"self run: #testAlphaCompositingSimulated"
	
	| bb f1 f2 mixColor result eps |

	f1 := Form extent: 1@1 depth: 32.
	f2 := Form extent: 1@1 depth: 32.
	eps := 0.5 / 255.
	0 to: 255 do:[:i|
		f1 colorAt: 0@0 put: Color blue.
		mixColor := Color red alpha: i / 255.0.
		f2 colorAt: 0@0 put: mixColor.
		mixColor := f2 colorAt: 0@0.
		bb := BitBlt toForm: f1.
		bb sourceForm: f2.
		bb combinationRule: Form blend.
		bb copyBitsSimulated.
		result := f1 colorAt: 0@0.
		self assert: (result red - mixColor alpha) abs < eps.
		self assert: (result blue - (1.0 - mixColor alpha)) abs < eps.
		self assert: result alpha = 1.0.
	]
]

{ #category : #tests }
BitBltSimulationTest >> testDisplayStringSimulated [
	"self run: #testAlphaCompositingSimulated"
	
	| bb f1 font |
	f1 := Form extent: 1@1 depth: 32.
	bb := BitBlt toForm: f1.
	bb combinationRule: 15.
	bb destX: 1.
	bb destY: 1.
	bb sourceX: 100.
	bb width: 100.
	font := TextStyle default fontOfSize: 21.
	bb simulatePrimitive: 'primitiveDisplayString' args: {'hello'. 1. 4. font characterToGlyphMap. font xTable. 1}.

]
