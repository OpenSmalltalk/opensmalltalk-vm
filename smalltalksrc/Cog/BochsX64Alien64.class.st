"
I am a wrapper around the Bochs C++ x86_64 CPU emulator when compiled in 64 bits.  My superclass is the same but for 32 bits.
"
Class {
	#name : #BochsX64Alien64,
	#superclass : #BochsX64Alien,
	#type : #bytes,
	#category : #'Cog-Processors'
}

{ #category : #'instance creation' }
BochsX64Alien64 class >> dataSize [
	^26960
]

{ #category : #accessing }
BochsX64Alien64 >> al [
	^self unsignedByteAt: 481
]

{ #category : #accessing }
BochsX64Alien64 >> al: anUnsignedInteger [
	^self unsignedByteAt: 481 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> bl [
	^self unsignedByteAt: 505
]

{ #category : #accessing }
BochsX64Alien64 >> bl: anUnsignedInteger [
	^self unsignedByteAt: 505 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> bpl [
	^self unsignedByteAt: 521
]

{ #category : #accessing }
BochsX64Alien64 >> bpl: anUnsignedInteger [
	^self unsignedByteAt: 521 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> cl [
	^self unsignedByteAt: 489
]

{ #category : #accessing }
BochsX64Alien64 >> cl: anUnsignedInteger [
	^self unsignedByteAt: 489 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> cr0 [
	^self unsignedLongLongAt: 1281
]

{ #category : #accessing }
BochsX64Alien64 >> cr0: anUnsignedInteger [
	^self unsignedLongLongAt: 1281 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> cr1 [
	^self unsignedLongLongAt: 1285
]

{ #category : #accessing }
BochsX64Alien64 >> cr1: anUnsignedInteger [
	^self unsignedLongLongAt: 1285 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> cr2 [
	^self unsignedLongLongAt: 1289
]

{ #category : #accessing }
BochsX64Alien64 >> cr2: anUnsignedInteger [
	^self unsignedLongLongAt: 1289 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> cr3 [
	^self unsignedLongLongAt: 1297
]

{ #category : #accessing }
BochsX64Alien64 >> cr3: anUnsignedInteger [
	^self unsignedLongLongAt: 1297 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> cr4 [
	^self unsignedLongLongAt: 1309
]

{ #category : #accessing }
BochsX64Alien64 >> cr4: anUnsignedInteger [
	^self unsignedLongLongAt: 1309 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> dil [
	^self unsignedByteAt: 537
]

{ #category : #accessing }
BochsX64Alien64 >> dil: anUnsignedInteger [
	^self unsignedByteAt: 537 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> dl [
	^self unsignedByteAt: 497
]

{ #category : #accessing }
BochsX64Alien64 >> dl: anUnsignedInteger [
	^self unsignedByteAt: 497 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> ipl [
	^self unsignedByteAt: 609
]

{ #category : #accessing }
BochsX64Alien64 >> ipl: anUnsignedInteger [
	^self unsignedByteAt: 609 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> r10 [
	^self unsignedLongLongAt: 561
]

{ #category : #accessing }
BochsX64Alien64 >> r10: anUnsignedInteger [
	^self unsignedLongLongAt: 561 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> r10l [
	^self unsignedByteAt: 561
]

{ #category : #accessing }
BochsX64Alien64 >> r10l: anUnsignedInteger [
	^self unsignedByteAt: 561 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> r11 [
	^self unsignedLongLongAt: 569
]

{ #category : #accessing }
BochsX64Alien64 >> r11: anUnsignedInteger [
	^self unsignedLongLongAt: 569 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> r11l [
	^self unsignedByteAt: 569
]

{ #category : #accessing }
BochsX64Alien64 >> r11l: anUnsignedInteger [
	^self unsignedByteAt: 569 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> r12 [
	^self unsignedLongLongAt: 577
]

{ #category : #accessing }
BochsX64Alien64 >> r12: anUnsignedInteger [
	^self unsignedLongLongAt: 577 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> r12l [
	^self unsignedByteAt: 577
]

{ #category : #accessing }
BochsX64Alien64 >> r12l: anUnsignedInteger [
	^self unsignedByteAt: 577 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> r13 [
	^self unsignedLongLongAt: 585
]

{ #category : #accessing }
BochsX64Alien64 >> r13: anUnsignedInteger [
	^self unsignedLongLongAt: 585 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> r13l [
	^self unsignedByteAt: 585
]

{ #category : #accessing }
BochsX64Alien64 >> r13l: anUnsignedInteger [
	^self unsignedByteAt: 585 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> r14 [
	^self unsignedLongLongAt: 593
]

{ #category : #accessing }
BochsX64Alien64 >> r14: anUnsignedInteger [
	^self unsignedLongLongAt: 593 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> r14l [
	^self unsignedByteAt: 593
]

{ #category : #accessing }
BochsX64Alien64 >> r14l: anUnsignedInteger [
	^self unsignedByteAt: 593 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> r15 [
	^self unsignedLongLongAt: 601
]

{ #category : #accessing }
BochsX64Alien64 >> r15: anUnsignedInteger [
	^self unsignedLongLongAt: 601 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> r15l [
	^self unsignedByteAt: 601
]

{ #category : #accessing }
BochsX64Alien64 >> r15l: anUnsignedInteger [
	^self unsignedByteAt: 601 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> r8 [
	^self unsignedLongLongAt: 545
]

{ #category : #accessing }
BochsX64Alien64 >> r8: anUnsignedInteger [
	^self unsignedLongLongAt: 545 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> r8l [
	^self unsignedByteAt: 545
]

{ #category : #accessing }
BochsX64Alien64 >> r8l: anUnsignedInteger [
	^self unsignedByteAt: 545 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> r9 [
	^self unsignedLongLongAt: 553
]

{ #category : #accessing }
BochsX64Alien64 >> r9: anUnsignedInteger [
	^self unsignedLongLongAt: 553 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> r9l [
	^self unsignedByteAt: 553
]

{ #category : #accessing }
BochsX64Alien64 >> r9l: anUnsignedInteger [
	^self unsignedByteAt: 553 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> rax [
	^self unsignedLongLongAt: 481
]

{ #category : #accessing }
BochsX64Alien64 >> rax: anUnsignedInteger [
	^self unsignedLongLongAt: 481 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> rbp [
	^self unsignedLongLongAt: 521
]

{ #category : #accessing }
BochsX64Alien64 >> rbp: anUnsignedInteger [
	^self unsignedLongLongAt: 521 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> rbx [
	^self unsignedLongLongAt: 505
]

{ #category : #accessing }
BochsX64Alien64 >> rbx: anUnsignedInteger [
	^self unsignedLongLongAt: 505 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> rcx [
	^self unsignedLongLongAt: 489
]

{ #category : #accessing }
BochsX64Alien64 >> rcx: anUnsignedInteger [
	^self unsignedLongLongAt: 489 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> rdi [
	^self unsignedLongLongAt: 537
]

{ #category : #accessing }
BochsX64Alien64 >> rdi: anUnsignedInteger [
	^self unsignedLongLongAt: 537 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> rdx [
	^self unsignedLongLongAt: 497
]

{ #category : #accessing }
BochsX64Alien64 >> rdx: anUnsignedInteger [
	^self unsignedLongLongAt: 497 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> rflags [
	^self unsignedLongLongAt: 633
]

{ #category : #accessing }
BochsX64Alien64 >> rip [
	^self unsignedLongLongAt: 609
]

{ #category : #accessing }
BochsX64Alien64 >> rip: anUnsignedInteger [
	^self unsignedLongLongAt: 609 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> rsi [
	^self unsignedLongLongAt: 529
]

{ #category : #accessing }
BochsX64Alien64 >> rsi: anUnsignedInteger [
	^self unsignedLongLongAt: 529 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> rsp [
	^self unsignedLongLongAt: 513
]

{ #category : #accessing }
BochsX64Alien64 >> rsp: anUnsignedInteger [
	^self unsignedLongLongAt: 513 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> saveEip [
	^self unsignedLongAt: 1985
]

{ #category : #accessing }
BochsX64Alien64 >> saveEip: anUnsignedInteger [
	^self unsignedLongAt: 1985 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> saveEsp [
	^self unsignedLongAt: 1993
]

{ #category : #accessing }
BochsX64Alien64 >> saveEsp: anUnsignedInteger [
	^self unsignedLongAt: 1993 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> sil [
	^self unsignedByteAt: 529
]

{ #category : #accessing }
BochsX64Alien64 >> sil: anUnsignedInteger [
	^self unsignedByteAt: 529 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> spl [
	^self unsignedByteAt: 513
]

{ #category : #accessing }
BochsX64Alien64 >> spl: anUnsignedInteger [
	^self unsignedByteAt: 513 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> stopReason [
	^self unsignedByteAt: 2057
]

{ #category : #accessing }
BochsX64Alien64 >> stopReason: anUnsignedInteger [
	^self unsignedByteAt: 2057 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm0high [
	^self unsignedLongLongAt: 1481
]

{ #category : #accessing }
BochsX64Alien64 >> xmm0high: anUnsignedInteger [
	^self unsignedLongLongAt: 1481 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm0low [
	^self unsignedLongLongAt: 1473
]

{ #category : #accessing }
BochsX64Alien64 >> xmm0low: anUnsignedInteger [
	^self unsignedLongLongAt: 1473 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm10high [
	^self unsignedLongLongAt: 1641
]

{ #category : #accessing }
BochsX64Alien64 >> xmm10high: anUnsignedInteger [
	^self unsignedLongLongAt: 1641 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm10low [
	^self unsignedLongLongAt: 1633
]

{ #category : #accessing }
BochsX64Alien64 >> xmm10low: anUnsignedInteger [
	^self unsignedLongLongAt: 1633 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm11high [
	^self unsignedLongLongAt: 1657
]

{ #category : #accessing }
BochsX64Alien64 >> xmm11high: anUnsignedInteger [
	^self unsignedLongLongAt: 1657 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm11low [
	^self unsignedLongLongAt: 1649
]

{ #category : #accessing }
BochsX64Alien64 >> xmm11low: anUnsignedInteger [
	^self unsignedLongLongAt: 1649 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm12high [
	^self unsignedLongLongAt: 1673
]

{ #category : #accessing }
BochsX64Alien64 >> xmm12high: anUnsignedInteger [
	^self unsignedLongLongAt: 1673 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm12low [
	^self unsignedLongLongAt: 1665
]

{ #category : #accessing }
BochsX64Alien64 >> xmm12low: anUnsignedInteger [
	^self unsignedLongLongAt: 1665 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm13high [
	^self unsignedLongLongAt: 1689
]

{ #category : #accessing }
BochsX64Alien64 >> xmm13high: anUnsignedInteger [
	^self unsignedLongLongAt: 1689 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm13low [
	^self unsignedLongLongAt: 1681
]

{ #category : #accessing }
BochsX64Alien64 >> xmm13low: anUnsignedInteger [
	^self unsignedLongLongAt: 1681 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm14high [
	^self unsignedLongLongAt: 1705
]

{ #category : #accessing }
BochsX64Alien64 >> xmm14high: anUnsignedInteger [
	^self unsignedLongLongAt: 1705 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm14low [
	^self unsignedLongLongAt: 1697
]

{ #category : #accessing }
BochsX64Alien64 >> xmm14low: anUnsignedInteger [
	^self unsignedLongLongAt: 1697 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm15high [
	^self unsignedLongLongAt: 1721
]

{ #category : #accessing }
BochsX64Alien64 >> xmm15high: anUnsignedInteger [
	^self unsignedLongLongAt: 1721 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm15low [
	^self unsignedLongLongAt: 1713
]

{ #category : #accessing }
BochsX64Alien64 >> xmm15low: anUnsignedInteger [
	^self unsignedLongLongAt: 1713 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm1high [
	^self unsignedLongLongAt: 1497
]

{ #category : #accessing }
BochsX64Alien64 >> xmm1high: anUnsignedInteger [
	^self unsignedLongLongAt: 1497 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm1low [
	^self unsignedLongLongAt: 1489
]

{ #category : #accessing }
BochsX64Alien64 >> xmm1low: anUnsignedInteger [
	^self unsignedLongLongAt: 1489 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm2high [
	^self unsignedLongLongAt: 1513
]

{ #category : #accessing }
BochsX64Alien64 >> xmm2high: anUnsignedInteger [
	^self unsignedLongLongAt: 1513 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm2low [
	^self unsignedLongLongAt: 1505
]

{ #category : #accessing }
BochsX64Alien64 >> xmm2low: anUnsignedInteger [
	^self unsignedLongLongAt: 1505 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm3high [
	^self unsignedLongLongAt: 1529
]

{ #category : #accessing }
BochsX64Alien64 >> xmm3high: anUnsignedInteger [
	^self unsignedLongLongAt: 1529 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm3low [
	^self unsignedLongLongAt: 1521
]

{ #category : #accessing }
BochsX64Alien64 >> xmm3low: anUnsignedInteger [
	^self unsignedLongLongAt: 1521 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm4high [
	^self unsignedLongLongAt: 1545
]

{ #category : #accessing }
BochsX64Alien64 >> xmm4high: anUnsignedInteger [
	^self unsignedLongLongAt: 1545 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm4low [
	^self unsignedLongLongAt: 1537
]

{ #category : #accessing }
BochsX64Alien64 >> xmm4low: anUnsignedInteger [
	^self unsignedLongLongAt: 1537 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm5high [
	^self unsignedLongLongAt: 1561
]

{ #category : #accessing }
BochsX64Alien64 >> xmm5high: anUnsignedInteger [
	^self unsignedLongLongAt: 1561 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm5low [
	^self unsignedLongLongAt: 1553
]

{ #category : #accessing }
BochsX64Alien64 >> xmm5low: anUnsignedInteger [
	^self unsignedLongLongAt: 1553 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm6high [
	^self unsignedLongLongAt: 1577
]

{ #category : #accessing }
BochsX64Alien64 >> xmm6high: anUnsignedInteger [
	^self unsignedLongLongAt: 1577 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm6low [
	^self unsignedLongLongAt: 1569
]

{ #category : #accessing }
BochsX64Alien64 >> xmm6low: anUnsignedInteger [
	^self unsignedLongLongAt: 1569 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm7high [
	^self unsignedLongLongAt: 1593
]

{ #category : #accessing }
BochsX64Alien64 >> xmm7high: anUnsignedInteger [
	^self unsignedLongLongAt: 1593 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm7low [
	^self unsignedLongLongAt: 1585
]

{ #category : #accessing }
BochsX64Alien64 >> xmm7low: anUnsignedInteger [
	^self unsignedLongLongAt: 1585 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm8high [
	^self unsignedLongLongAt: 1609
]

{ #category : #accessing }
BochsX64Alien64 >> xmm8high: anUnsignedInteger [
	^self unsignedLongLongAt: 1609 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm8low [
	^self unsignedLongLongAt: 1601
]

{ #category : #accessing }
BochsX64Alien64 >> xmm8low: anUnsignedInteger [
	^self unsignedLongLongAt: 1601 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm9high [
	^self unsignedLongLongAt: 1625
]

{ #category : #accessing }
BochsX64Alien64 >> xmm9high: anUnsignedInteger [
	^self unsignedLongLongAt: 1625 put: anUnsignedInteger
]

{ #category : #accessing }
BochsX64Alien64 >> xmm9low [
	^self unsignedLongLongAt: 1617
]

{ #category : #accessing }
BochsX64Alien64 >> xmm9low: anUnsignedInteger [
	^self unsignedLongLongAt: 1617 put: anUnsignedInteger
]
