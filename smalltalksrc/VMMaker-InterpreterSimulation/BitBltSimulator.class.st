"
Provide bitblt support for the vm simulator
"
Class {
	#name : #BitBltSimulator,
	#superclass : #BitBltSimulation,
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #'instance creation' }
BitBltSimulator class >> new [
	^super new
]

{ #category : #translation }
BitBltSimulator class >> shouldBeTranslated [
"This class should not be translated "
	^false
]

{ #category : #'debug support' }
BitBltSimulator >> dstLongAt: dstIndex [
	interpreterProxy isInterpreterProxy
		ifTrue:[^dstIndex longAt: 0].
	((dstIndex anyMask: 3) or:[dstIndex + 4 < destBits or:[
		dstIndex > (destBits + (destPitch * destHeight))]])
			ifTrue:[self error:'Out of bounds'].
	^interpreterProxy longAt: dstIndex
]

{ #category : #'debug support' }
BitBltSimulator >> dstLongAt: dstIndex put: value [
	interpreterProxy isInterpreterProxy
		ifTrue:[^dstIndex longAt: 0 put: value].
	((dstIndex anyMask: 3) or:[dstIndex < destBits or:[
		dstIndex >= (destBits + (destPitch * destHeight))]])
			ifTrue:[self error:'Out of bounds'].
	^interpreterProxy longAt: dstIndex put: value
]

{ #category : #'as yet unclassified' }
BitBltSimulator >> initBBOpTable [
	opTable _ OpTable.
	maskTable _ Array new: 32.
	#(1 2 4 5 8 16 32) do:[:i| maskTable at: i put: (1 << i)-1].
	self initializeDitherTables.
	warpBitShiftTable _ CArrayAccessor on: (Array new: 32).
]

{ #category : #'as yet unclassified' }
BitBltSimulator >> initializeDitherTables [
	ditherMatrix4x4 _ CArrayAccessor on:
		#(	0	8	2	10
			12	4	14	6
			3	11	1	9
			15	7	13	5).
	ditherThresholds16 _ CArrayAccessor on:#(0 2 4 6 8 10 12 14 16).
	ditherValues16 _ CArrayAccessor on: 
		#(0 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14
		15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30).
	dither8Lookup _ CArrayAccessor on: (Array new: 4096).
	self initDither8Lookup.
]

{ #category : #'as yet unclassified' }
BitBltSimulator >> mergeFn: arg1 with: arg2 [
	^ self perform: (opTable at: combinationRule+1) with: arg1 with: arg2
]

{ #category : #'debug support' }
BitBltSimulator >> srcLongAt: srcIndex [
	interpreterProxy isInterpreterProxy
		ifTrue:[^srcIndex longAt: 0].
	((srcIndex anyMask: 3) or:[srcIndex + 4 < sourceBits or:[
		srcIndex > (sourceBits + (sourcePitch * sourceHeight))]])
			ifTrue:[self error:'Out of bounds'].
	^interpreterProxy longAt: srcIndex
]

{ #category : #'as yet unclassified' }
BitBltSimulator >> tableLookup: table at: index [

	^ interpreterProxy longAt: (table + (index * 4))
]
