Extension { #name : #Stream }

{ #category : #'*Cog-Benchmarks-Shootout-platform' }
Stream >> nl [
   self nextPut: Character lf
]

{ #category : #'*Cog-Benchmarks-Shootout-platform' }
Stream >> print: number digits: decimalPlaces [
   | precision rounded |
   decimalPlaces <= 0 ifTrue: [^ number rounded printString].
   precision := Utilities floatPrecisionForDecimalPlaces: decimalPlaces.
   rounded := number roundTo: precision.
   self nextPutAll: 
      ((rounded asScaledDecimal: decimalPlaces) printString copyUpTo: $s)
]

{ #category : #'*Cog-Benchmarks-Shootout-platform' }
Stream >> print: number paddedTo: width [
   self nextPutAll: (number printStringLength: width padded: false)
]
