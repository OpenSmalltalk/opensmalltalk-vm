"
I a wrapper around the ARMulator ARMv6 CPU emulator when compiled in 64 bits.  My superclass is the same but for 32 bits.
"
Class {
	#name : #GdbARMAlien64,
	#superclass : #GdbARMAlien,
	#type : #bytes,
	#category : #'Cog-Processors'
}

{ #category : #'instance creation' }
GdbARMAlien64 class >> dataSize [
	^2576
]

{ #category : #accessing }
GdbARMAlien64 >> cflag [
	^self unsignedLongAt: 577
]

{ #category : #accessing }
GdbARMAlien64 >> cflag: anUnsignedInteger [
	^self unsignedLongAt: 577 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d0 [
	^self unsignedLongLongAt: 2313
]

{ #category : #accessing }
GdbARMAlien64 >> d0: anUnsignedInteger [
	^self unsignedLongLongAt: 2313 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d1 [
	^self unsignedLongLongAt: 2321
]

{ #category : #accessing }
GdbARMAlien64 >> d10 [
	^self unsignedLongLongAt: 2393
]

{ #category : #accessing }
GdbARMAlien64 >> d10: anUnsignedInteger [
	^self unsignedLongLongAt: 2393 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d11 [
	^self unsignedLongLongAt: 2401
]

{ #category : #accessing }
GdbARMAlien64 >> d11: anUnsignedInteger [
	^self unsignedLongLongAt: 2401 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d12 [
	^self unsignedLongLongAt: 2409
]

{ #category : #accessing }
GdbARMAlien64 >> d12: anUnsignedInteger [
	^self unsignedLongLongAt: 2409 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d13 [
	^self unsignedLongLongAt: 2417
]

{ #category : #accessing }
GdbARMAlien64 >> d13: anUnsignedInteger [
	^self unsignedLongLongAt: 2417 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d14 [
	^self unsignedLongLongAt: 2425
]

{ #category : #accessing }
GdbARMAlien64 >> d14: anUnsignedInteger [
	^self unsignedLongLongAt: 2425 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d15 [
	^self unsignedLongLongAt: 2433
]

{ #category : #accessing }
GdbARMAlien64 >> d15: anUnsignedInteger [
	^self unsignedLongLongAt: 2433 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d16 [
	^self unsignedLongLongAt: 2441
]

{ #category : #accessing }
GdbARMAlien64 >> d16: anUnsignedInteger [
	^self unsignedLongLongAt: 2441 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d17 [
	^self unsignedLongLongAt: 2449
]

{ #category : #accessing }
GdbARMAlien64 >> d17: anUnsignedInteger [
	^self unsignedLongLongAt: 2449 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d18 [
	^self unsignedLongLongAt: 2457
]

{ #category : #accessing }
GdbARMAlien64 >> d18: anUnsignedInteger [
	^self unsignedLongLongAt: 2457 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d19 [
	^self unsignedLongLongAt: 2465
]

{ #category : #accessing }
GdbARMAlien64 >> d19: anUnsignedInteger [
	^self unsignedLongLongAt: 2465 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d1: anUnsignedInteger [
	^self unsignedLongLongAt: 2321 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d2 [
	^self unsignedLongLongAt: 2329
]

{ #category : #accessing }
GdbARMAlien64 >> d20 [
	^self unsignedLongLongAt: 2473
]

{ #category : #accessing }
GdbARMAlien64 >> d20: anUnsignedInteger [
	^self unsignedLongLongAt: 2473 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d21 [
	^self unsignedLongLongAt: 2481
]

{ #category : #accessing }
GdbARMAlien64 >> d21: anUnsignedInteger [
	^self unsignedLongLongAt: 2481 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d22 [
	^self unsignedLongLongAt: 2489
]

{ #category : #accessing }
GdbARMAlien64 >> d22: anUnsignedInteger [
	^self unsignedLongLongAt: 2489 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d23 [
	^self unsignedLongLongAt: 2497
]

{ #category : #accessing }
GdbARMAlien64 >> d23: anUnsignedInteger [
	^self unsignedLongLongAt: 2497 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d24 [
	^self unsignedLongLongAt: 2505
]

{ #category : #accessing }
GdbARMAlien64 >> d24: anUnsignedInteger [
	^self unsignedLongLongAt: 2505 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d25 [
	^self unsignedLongLongAt: 2513
]

{ #category : #accessing }
GdbARMAlien64 >> d25: anUnsignedInteger [
	^self unsignedLongLongAt: 2513 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d26 [
	^self unsignedLongLongAt: 2521
]

{ #category : #accessing }
GdbARMAlien64 >> d26: anUnsignedInteger [
	^self unsignedLongLongAt: 2521 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d27 [
	^self unsignedLongLongAt: 2529
]

{ #category : #accessing }
GdbARMAlien64 >> d27: anUnsignedInteger [
	^self unsignedLongLongAt: 2529 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d28 [
	^self unsignedLongLongAt: 2537
]

{ #category : #accessing }
GdbARMAlien64 >> d28: anUnsignedInteger [
	^self unsignedLongLongAt: 2537 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d29 [
	^self unsignedLongLongAt: 2545
]

{ #category : #accessing }
GdbARMAlien64 >> d29: anUnsignedInteger [
	^self unsignedLongLongAt: 2545 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d2: anUnsignedInteger [
	^self unsignedLongLongAt: 2329 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d3 [
	^self unsignedLongLongAt: 2337
]

{ #category : #accessing }
GdbARMAlien64 >> d30 [
	^self unsignedLongLongAt: 2553
]

{ #category : #accessing }
GdbARMAlien64 >> d30: anUnsignedInteger [
	^self unsignedLongLongAt: 2553 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d31 [
	^self unsignedLongLongAt: 2561
]

{ #category : #accessing }
GdbARMAlien64 >> d31: anUnsignedInteger [
	^self unsignedLongLongAt: 2561 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d3: anUnsignedInteger [
	^self unsignedLongLongAt: 2337 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d4 [
	^self unsignedLongLongAt: 2345
]

{ #category : #accessing }
GdbARMAlien64 >> d4: anUnsignedInteger [
	^self unsignedLongLongAt: 2345 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d5 [
	^self unsignedLongLongAt: 2353
]

{ #category : #accessing }
GdbARMAlien64 >> d5: anUnsignedInteger [
	^self unsignedLongLongAt: 2353 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d6 [
	^self unsignedLongLongAt: 2361
]

{ #category : #accessing }
GdbARMAlien64 >> d6: anUnsignedInteger [
	^self unsignedLongLongAt: 2361 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d7 [
	^self unsignedLongLongAt: 2369
]

{ #category : #accessing }
GdbARMAlien64 >> d7: anUnsignedInteger [
	^self unsignedLongLongAt: 2369 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d8 [
	^self unsignedLongLongAt: 2377
]

{ #category : #accessing }
GdbARMAlien64 >> d8: anUnsignedInteger [
	^self unsignedLongLongAt: 2377 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> d9 [
	^self unsignedLongLongAt: 2385
]

{ #category : #accessing }
GdbARMAlien64 >> d9: anUnsignedInteger [
	^self unsignedLongLongAt: 2385 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> fpCPSR [
"The VFP cpsr flags are kept as a single word in the Alien structure. Return just the top 4 bits, the actual flags"
	^(self unsignedLongAt: 2569) >>28
]

{ #category : #accessing }
GdbARMAlien64 >> ifflags [
	^self unsignedLongAt: 585
]

{ #category : #accessing }
GdbARMAlien64 >> ifflags: anUnsignedInteger [
	^self unsignedLongAt: 585 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> nflag [
	^self unsignedLongAt: 569
]

{ #category : #accessing }
GdbARMAlien64 >> nflag: anUnsignedInteger [
	^self unsignedLongAt: 569 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> priorPc [
	^self unsignedLongAt: 613
]

{ #category : #accessing }
GdbARMAlien64 >> priorPc: anUnsignedInteger [
	^self unsignedLongAt: 613 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> rawCPSR [
	^self unsignedLongAt: 537
]

{ #category : #accessing }
GdbARMAlien64 >> sflag [
	^self unsignedLongAt: 589
]

{ #category : #accessing }
GdbARMAlien64 >> sflag: anUnsignedInteger [
	^self unsignedLongAt: 589 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> tflag [
	^self unsignedLongAt: 593
]

{ #category : #accessing }
GdbARMAlien64 >> tflag: anUnsignedInteger [
	^self unsignedLongAt: 593 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> vflag [
	^self unsignedLongAt: 581
]

{ #category : #accessing }
GdbARMAlien64 >> vflag: anUnsignedInteger [
	^self unsignedLongAt: 581 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> zflag [
	^self unsignedLongAt: 573
]

{ #category : #accessing }
GdbARMAlien64 >> zflag: anUnsignedInteger [
	^self unsignedLongAt: 573 put: anUnsignedInteger
]
