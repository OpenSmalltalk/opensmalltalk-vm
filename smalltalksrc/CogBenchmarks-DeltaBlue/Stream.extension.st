Extension { #name : #Stream }

{ #category : #'*CogBenchmarks-Shootout-platform' }
Stream >> nl [
   self nextPut: Character lf
]

{ #category : #'*CogBenchmarks-Shootout-platform' }
Stream >> print: number digits: decimalPlaces [
   | precision rounded |
   decimalPlaces <= 0 ifTrue: [^ number rounded printString].
   precision := Utilities floatPrecisionForDecimalPlaces: decimalPlaces.
   rounded := number roundTo: precision.
   self nextPutAll: 
      ((rounded asScaledDecimal: decimalPlaces) printString copyUpTo: $s)
]

{ #category : #'*CogBenchmarks-Shootout-platform' }
Stream >> print: number paddedTo: width [
   self nextPutAll: (number printStringLength: width padded: false)
]
