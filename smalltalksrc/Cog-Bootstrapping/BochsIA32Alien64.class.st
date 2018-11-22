"
I am a wrapper around the Bochs C++ IA32 CPU emulator when compiled in 64 bits.  My superclass is the same but for 32 bits.
"
Class {
	#name : #BochsIA32Alien64,
	#superclass : #BochsIA32Alien,
	#type : #bytes,
	#category : #'Cog-Processors'
}

{ #category : #'instance creation' }
BochsIA32Alien64 class >> dataSize [
	^26384
]

{ #category : #accessing }
BochsIA32Alien64 >> al [
	^self unsignedByteAt: 477
]

{ #category : #accessing }
BochsIA32Alien64 >> al: anUnsignedInteger [
	^self unsignedByteAt: 477 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> bl [
	^self unsignedByteAt: 489
]

{ #category : #accessing }
BochsIA32Alien64 >> bl: anUnsignedInteger [
	^self unsignedByteAt: 489 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> bpl [
	^self unsignedByteAt: 497
]

{ #category : #accessing }
BochsIA32Alien64 >> bpl: anUnsignedInteger [
	^self unsignedByteAt: 497 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> cl [
	^self unsignedByteAt: 481
]

{ #category : #accessing }
BochsIA32Alien64 >> cl: anUnsignedInteger [
	^self unsignedByteAt: 481 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> cr0 [
	^self unsignedLongLongAt: 1017
]

{ #category : #accessing }
BochsIA32Alien64 >> cr0: anUnsignedInteger [
	^self unsignedLongLongAt: 1017 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> cr1 [
	^self unsignedLongLongAt: 1021
]

{ #category : #accessing }
BochsIA32Alien64 >> cr1: anUnsignedInteger [
	^self unsignedLongLongAt: 1021 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> cr2 [
	^self unsignedLongLongAt: 1025
]

{ #category : #accessing }
BochsIA32Alien64 >> cr2: anUnsignedInteger [
	^self unsignedLongLongAt: 1025 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> cr3 [
	^self unsignedLongLongAt: 1029
]

{ #category : #accessing }
BochsIA32Alien64 >> cr3: anUnsignedInteger [
	^self unsignedLongLongAt: 1029 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> cr4 [
	^self unsignedLongLongAt: 1037
]

{ #category : #accessing }
BochsIA32Alien64 >> cr4: anUnsignedInteger [
	^self unsignedLongLongAt: 1037 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> dil [
	^self unsignedByteAt: 505
]

{ #category : #accessing }
BochsIA32Alien64 >> dil: anUnsignedInteger [
	^self unsignedByteAt: 505 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> dl [
	^self unsignedByteAt: 485
]

{ #category : #accessing }
BochsIA32Alien64 >> dl: anUnsignedInteger [
	^self unsignedByteAt: 485 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> eax [
	^self unsignedLongAt: 477
]

{ #category : #accessing }
BochsIA32Alien64 >> eax: anUnsignedInteger [
	^self unsignedLongAt: 477 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> ebp [
	^self unsignedLongAt: 497
]

{ #category : #accessing }
BochsIA32Alien64 >> ebp: anUnsignedInteger [
	^self unsignedLongAt: 497 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> ebx [
	^self unsignedLongAt: 489
]

{ #category : #accessing }
BochsIA32Alien64 >> ebx: anUnsignedInteger [
	^self unsignedLongAt: 489 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> ecx [
	^self unsignedLongAt: 481
]

{ #category : #accessing }
BochsIA32Alien64 >> ecx: anUnsignedInteger [
	^self unsignedLongAt: 481 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> edi [
	^self unsignedLongAt: 505
]

{ #category : #accessing }
BochsIA32Alien64 >> edi: anUnsignedInteger [
	^self unsignedLongAt: 505 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> edx [
	^self unsignedLongAt: 485
]

{ #category : #accessing }
BochsIA32Alien64 >> edx: anUnsignedInteger [
	^self unsignedLongAt: 485 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> eflags [
	^self unsignedLongAt: 521
]

{ #category : #accessing }
BochsIA32Alien64 >> eip [
	^self unsignedLongAt: 509
]

{ #category : #accessing }
BochsIA32Alien64 >> eip: anUnsignedInteger [
	^self unsignedLongAt: 509 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> esi [
	^self unsignedLongAt: 501
]

{ #category : #accessing }
BochsIA32Alien64 >> esi: anUnsignedInteger [
	^self unsignedLongAt: 501 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> esp [
	^self unsignedLongAt: 493
]

{ #category : #accessing }
BochsIA32Alien64 >> esp: anUnsignedInteger [
	^self unsignedLongAt: 493 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> ipl [
	^self unsignedByteAt: 509
]

{ #category : #accessing }
BochsIA32Alien64 >> ipl: anUnsignedInteger [
	^self unsignedByteAt: 509 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> saveEip [
	^self unsignedLongAt: 1541
]

{ #category : #accessing }
BochsIA32Alien64 >> saveEip: anUnsignedInteger [
	^self unsignedLongAt: 1541 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> saveEsp [
	^self unsignedLongAt: 1545
]

{ #category : #accessing }
BochsIA32Alien64 >> saveEsp: anUnsignedInteger [
	^self unsignedLongAt: 1545 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> sil [
	^self unsignedByteAt: 501
]

{ #category : #accessing }
BochsIA32Alien64 >> sil: anUnsignedInteger [
	^self unsignedByteAt: 501 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> spl [
	^self unsignedByteAt: 493
]

{ #category : #accessing }
BochsIA32Alien64 >> spl: anUnsignedInteger [
	^self unsignedByteAt: 493 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> stopReason [
	^self unsignedByteAt: 1593
]

{ #category : #accessing }
BochsIA32Alien64 >> stopReason: anUnsignedInteger [
	^self unsignedByteAt: 1593 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm0high [
	^self unsignedLongLongAt: 1193
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm0high: anUnsignedInteger [
	^self unsignedLongLongAt: 1193 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm0low [
	^self unsignedLongLongAt: 1185
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm0low: anUnsignedInteger [
	^self unsignedLongLongAt: 1185 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm1high [
	^self unsignedLongLongAt: 1209
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm1high: anUnsignedInteger [
	^self unsignedLongLongAt: 1209 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm1low [
	^self unsignedLongLongAt: 1201
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm1low: anUnsignedInteger [
	^self unsignedLongLongAt: 1201 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm2high [
	^self unsignedLongLongAt: 1225
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm2high: anUnsignedInteger [
	^self unsignedLongLongAt: 1225 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm2low [
	^self unsignedLongLongAt: 1217
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm2low: anUnsignedInteger [
	^self unsignedLongLongAt: 1217 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm3high [
	^self unsignedLongLongAt: 1241
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm3high: anUnsignedInteger [
	^self unsignedLongLongAt: 1241 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm3low [
	^self unsignedLongLongAt: 1233
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm3low: anUnsignedInteger [
	^self unsignedLongLongAt: 1233 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm4high [
	^self unsignedLongLongAt: 1257
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm4high: anUnsignedInteger [
	^self unsignedLongLongAt: 1257 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm4low [
	^self unsignedLongLongAt: 1249
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm4low: anUnsignedInteger [
	^self unsignedLongLongAt: 1249 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm5high [
	^self unsignedLongLongAt: 1273
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm5high: anUnsignedInteger [
	^self unsignedLongLongAt: 1273 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm5low [
	^self unsignedLongLongAt: 1265
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm5low: anUnsignedInteger [
	^self unsignedLongLongAt: 1265 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm6high [
	^self unsignedLongLongAt: 1289
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm6high: anUnsignedInteger [
	^self unsignedLongLongAt: 1289 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm6low [
	^self unsignedLongLongAt: 1281
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm6low: anUnsignedInteger [
	^self unsignedLongLongAt: 1281 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm7high [
	^self unsignedLongLongAt: 1305
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm7high: anUnsignedInteger [
	^self unsignedLongLongAt: 1305 put: anUnsignedInteger
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm7low [
	^self unsignedLongLongAt: 1297
]

{ #category : #accessing }
BochsIA32Alien64 >> xmm7low: anUnsignedInteger [
	^self unsignedLongLongAt: 1297 put: anUnsignedInteger
]
