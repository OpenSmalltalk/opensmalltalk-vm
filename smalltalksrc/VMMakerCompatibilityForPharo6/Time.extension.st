Extension { #name : #Time }

{ #category : #'*VMMakerCompatibilityForPharo6' }
Time class >> dateAndTimeNow [
	
	| now |
	now := DateAndTime now.
	^ { now asDate . now asTime }
]
