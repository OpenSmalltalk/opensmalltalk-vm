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
GdbARMAlien64 >> lr [
	^self unsignedLongAt: 69
]

{ #category : #accessing }
GdbARMAlien64 >> lr: anUnsignedInteger [
	^self unsignedLongAt: 69 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> pc [
	^self unsignedLongAt: 73
]

{ #category : #accessing }
GdbARMAlien64 >> pc: anUnsignedInteger [
	^self unsignedLongAt: 73 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> r0 [
	^self unsignedLongAt: 13
]

{ #category : #accessing }
GdbARMAlien64 >> r0: anUnsignedInteger [
	^self unsignedLongAt: 13 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> r1 [
	^self unsignedLongAt: 17
]

{ #category : #accessing }
GdbARMAlien64 >> r10 [
	^self unsignedLongAt: 53
]

{ #category : #accessing }
GdbARMAlien64 >> r10: anUnsignedInteger [
	^self unsignedLongAt: 53 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> r11 [
	^self unsignedLongAt: 57
]

{ #category : #accessing }
GdbARMAlien64 >> r11: anUnsignedInteger [
	^self unsignedLongAt: 57 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> r12 [
	^self unsignedLongAt: 61
]

{ #category : #accessing }
GdbARMAlien64 >> r12: anUnsignedInteger [
	^self unsignedLongAt: 61 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> r1: anUnsignedInteger [
	^self unsignedLongAt: 17 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> r2 [
	^self unsignedLongAt: 21
]

{ #category : #accessing }
GdbARMAlien64 >> r2: anUnsignedInteger [
	^self unsignedLongAt: 21 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> r3 [
	^self unsignedLongAt: 25
]

{ #category : #accessing }
GdbARMAlien64 >> r3: anUnsignedInteger [
	^self unsignedLongAt: 25 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> r4 [
	^self unsignedLongAt: 29
]

{ #category : #accessing }
GdbARMAlien64 >> r4: anUnsignedInteger [
	^self unsignedLongAt: 29 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> r5 [
	^self unsignedLongAt: 33
]

{ #category : #accessing }
GdbARMAlien64 >> r5: anUnsignedInteger [
	^self unsignedLongAt: 33 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> r6 [
	^self unsignedLongAt: 37
]

{ #category : #accessing }
GdbARMAlien64 >> r6: anUnsignedInteger [
	^self unsignedLongAt: 37 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> r7 [
	^self unsignedLongAt: 41
]

{ #category : #accessing }
GdbARMAlien64 >> r7: anUnsignedInteger [
	^self unsignedLongAt: 41 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> r8 [
	^self unsignedLongAt: 45
]

{ #category : #accessing }
GdbARMAlien64 >> r8: anUnsignedInteger [
	^self unsignedLongAt: 45 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> r9 [
	^self unsignedLongAt: 49
]

{ #category : #accessing }
GdbARMAlien64 >> r9: anUnsignedInteger [
	^self unsignedLongAt: 49 put: anUnsignedInteger
]

{ #category : #accessing }
GdbARMAlien64 >> sp [
	^self unsignedLongAt: 65
]

{ #category : #accessing }
GdbARMAlien64 >> sp: anUnsignedInteger [
	^self unsignedLongAt: 65 put: anUnsignedInteger
]
