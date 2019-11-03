'From Squeak3.5 of ''11 April 2003'' [latest update: #5180] on 29 June 2003 at 11:03:57 pm'!
"Change Set:		FasterCopyLoop-JMM
Date:			29 June 2003
Author:			johnmci@smalltalkconsulting.com

Make some of the variables in the inner loop of copyLoop, copyLoopNoSource, and copyLoopPixMap locals versus instance variables to improve performance on the powerpc"!


!BitBltSimulation methodsFor: 'inner loop' stamp: 'JMM 6/29/2003 23:01'!
copyLoop
	"This version of the inner loop assumes noSource = false."
	| prevWord thisWord skewWord halftoneWord mergeWord hInc y unskew skewMask notSkewMask mergeFnwith destWord skewLocal sourceIndexLocal destIndexLocal vDirLocal hDirLocal nWordsMinusOne |
	self inline: false.
	self var: #mergeFnwith declareC: 'int (*mergeFnwith)(int, int)'.
	mergeFnwith _ self
				cCoerce: (opTable at: combinationRule + 1)
				to: 'int (*)(int, int)'.
	mergeFnwith.
	"null ref for compiler"
	hInc _ hDir * 4.
	skewLocal _ skew.
	sourceIndexLocal _ sourceIndex.
	destIndexLocal _ destIndex.
	vDirLocal _ vDir.
	hDirLocal _ hDir.
	nWordsMinusOne _ nWords - 1.
	"Byte delta"
	"degenerate skew fixed for Sparc. 10/20/96 ikp"
	skewLocal == -32
		ifTrue: [skewLocal _ unskew _ skewMask _ 0]
		ifFalse: [skewLocal < 0
				ifTrue: [unskew _ skewLocal + 32.
					skewMask _ AllOnes << (0 - skewLocal)]
				ifFalse: [skewLocal = 0
						ifTrue: [unskew _ 0.
							skewMask _ AllOnes]
						ifFalse: [unskew _ skewLocal - 32.
							skewMask _ AllOnes >> skewLocal]]].
	notSkewMask _ skewMask bitInvert32.
	noHalftone
		ifTrue: [halftoneWord _ AllOnes.
			halftoneHeight _ 0]
		ifFalse: [halftoneWord _ self halftoneAt: 0].
	y _ dy.
	1
		to: bbH
		do: [:i | 
			"here is the vertical loop"
			halftoneHeight > 1
				ifTrue: ["Otherwise, its always the same"
					halftoneWord _ self halftoneAt: y.
					y _ y + vDirLocal].
			preload
				ifTrue: ["load the 64-bit shifter"
					prevWord _ self srcLongAt: sourceIndexLocal.
					sourceIndexLocal _ sourceIndexLocal + hInc]
				ifFalse: [prevWord _ 0].
			"Note: the horizontal loop has been expanded into three parts for 
			speed:"
			"This first section requires masking of the destination store..."
			destMask _ mask1.
			thisWord _ self srcLongAt: sourceIndexLocal.
			"pick up next word"
			sourceIndexLocal _ sourceIndexLocal + hInc.
			skewWord _ ((prevWord bitAnd: notSkewMask)
						bitShift: unskew)
						bitOr: ((thisWord bitAnd: skewMask)
								bitShift: skewLocal).
			"32-bit rotate"
			prevWord _ thisWord.
			destWord _ self dstLongAt: destIndexLocal.
			mergeWord _ self
						mergeFn: (skewWord bitAnd: halftoneWord)
						with: destWord.
			destWord _ (destMask bitAnd: mergeWord)
						bitOr: (destWord bitAnd: destMask bitInvert32).
			self dstLongAt: destIndexLocal put: destWord.
			destIndexLocal _ destIndexLocal + hInc.
			"This central horizontal loop requires no store masking"
			destMask _ AllOnes.
			combinationRule = 3
				ifTrue: [skewLocal = 0 & (halftoneWord = AllOnes)
						ifTrue: ["Very special inner loop for STORE mode with no 
							skew -- just move words"
							hDirLocal = -1
								ifTrue: ["Woeful patch: revert to older code for  
									hDir = -1"
									2
										to: nWordsMinusOne
										do: [:word | 
											thisWord _ self srcLongAt: sourceIndexLocal.
											sourceIndexLocal _ sourceIndexLocal + hInc.
											self dstLongAt: destIndexLocal put: thisWord.
											destIndexLocal _ destIndexLocal + hInc]]
								ifFalse: [2
										to: nWordsMinusOne
										do: [:word | 
											"Note loop starts with prevWord  
											loaded (due to preload)"
											self dstLongAt: destIndexLocal put: prevWord.
											destIndexLocal _ destIndexLocal + hInc.
											prevWord _ self srcLongAt: sourceIndexLocal.
											sourceIndexLocal _ sourceIndexLocal + hInc]]]
						ifFalse: ["Special inner loop for STORE mode -- no need to 
							call merge"
							2
								to: nWordsMinusOne
								do: [:word | 
									thisWord _ self srcLongAt: sourceIndexLocal.
									sourceIndexLocal _ sourceIndexLocal + hInc.
									skewWord _ ((prevWord bitAnd: notSkewMask)
												bitShift: unskew)
												bitOr: ((thisWord bitAnd: skewMask)
														bitShift: skewLocal).
									"32-bit rotate"
									prevWord _ thisWord.
									self
										dstLongAt: destIndexLocal
										put: (skewWord bitAnd: halftoneWord).
									destIndexLocal _ destIndexLocal + hInc]]]
				ifFalse: [2
						to: nWordsMinusOne
						do: [:word | 
							"Normal inner loop does merge:"
							thisWord _ self srcLongAt: sourceIndexLocal.
							"pick up next word"
							sourceIndexLocal _ sourceIndexLocal + hInc.
							skewWord _ ((prevWord bitAnd: notSkewMask)
										bitShift: unskew)
										bitOr: ((thisWord bitAnd: skewMask)
												bitShift: skewLocal).
							"32-bit rotate"
							prevWord _ thisWord.
							mergeWord _ self
										mergeFn: (skewWord bitAnd: halftoneWord)
										with: (self dstLongAt: destIndexLocal).
							self dstLongAt: destIndexLocal put: mergeWord.
							destIndexLocal _ destIndexLocal + hInc]].
			"This last section, if used, requires masking of the destination  
			store..."
			nWords > 1
				ifTrue: [destMask _ mask2.
					thisWord _ self srcLongAt: sourceIndexLocal.
					"pick up next word"
					sourceIndexLocal _ sourceIndexLocal + hInc.
					skewWord _ ((prevWord bitAnd: notSkewMask)
								bitShift: unskew)
								bitOr: ((thisWord bitAnd: skewMask)
										bitShift: skewLocal).
					"32-bit rotate"
					destWord _ self dstLongAt: destIndexLocal.
					mergeWord _ self
								mergeFn: (skewWord bitAnd: halftoneWord)
								with: destWord.
					destWord _ (destMask bitAnd: mergeWord)
								bitOr: (destWord bitAnd: destMask bitInvert32).
					self dstLongAt: destIndexLocal put: destWord.
					destIndexLocal _ destIndexLocal + hInc].
			sourceIndexLocal _ sourceIndexLocal + sourceDelta.
			destIndexLocal _ destIndexLocal + destDelta]! !

!BitBltSimulation methodsFor: 'inner loop' stamp: 'JMM 6/29/2003 23:01'!
copyLoopNoSource
	"Faster copyLoop when source not used. hDir and vDir are both  
	positive, and perload and skew are unused"
	| halftoneWord mergeWord mergeFnwith destWord destIndexLocal |
	self inline: false.
	self var: #mergeFnwith declareC: 'int (*mergeFnwith)(int, int)'.
	mergeFnwith _ self
				cCoerce: (opTable at: combinationRule + 1)
				to: 'int (*)(int, int)'.
	mergeFnwith.
	"null ref for compiler"
	destIndexLocal _ destIndex.
	1
		to: bbH
		do: [:i | 
			"here is the vertical loop"
			noHalftone
				ifTrue: [halftoneWord _ AllOnes]
				ifFalse: [halftoneWord _ self halftoneAt: dy + i - 1].
			"Note: the horizontal loop has been expanded into three parts for 
			speed:"
			"This first section requires masking of the destination store..."
			destMask _ mask1.
			destWord _ self dstLongAt: destIndexLocal.
			mergeWord _ self mergeFn: halftoneWord with: destWord.
			destWord _ (destMask bitAnd: mergeWord)
						bitOr: (destWord bitAnd: destMask bitInvert32).
			self dstLongAt: destIndexLocal put: destWord.
			destIndexLocal _ destIndexLocal + 4.
			"This central horizontal loop requires no store masking"
			destMask _ AllOnes.
			combinationRule = 3
				ifTrue: ["Special inner loop for STORE"
					destWord _ halftoneWord.
					2
						to: nWords - 1
						do: [:word | 
							self dstLongAt: destIndexLocal put: destWord.
							destIndexLocal _ destIndexLocal + 4]]
				ifFalse: ["Normal inner loop does merge"
					2
						to: nWords - 1
						do: [:word | 
							"Normal inner loop does merge"
							destWord _ self dstLongAt: destIndexLocal.
							mergeWord _ self mergeFn: halftoneWord with: destWord.
							self dstLongAt: destIndexLocal put: mergeWord.
							destIndexLocal _ destIndexLocal + 4]].
			"This last section, if used, requires masking of the destination  
			store..."
			nWords > 1
				ifTrue: [destMask _ mask2.
					destWord _ self dstLongAt: destIndexLocal.
					mergeWord _ self mergeFn: halftoneWord with: destWord.
					destWord _ (destMask bitAnd: mergeWord)
								bitOr: (destWord bitAnd: destMask bitInvert32).
					self dstLongAt: destIndexLocal put: destWord.
					destIndexLocal _ destIndexLocal + 4].
			destIndexLocal _ destIndexLocal + destDelta]! !

!BitBltSimulation methodsFor: 'inner loop' stamp: 'JMM 6/29/2003 23:01'!
copyLoopPixMap
	"This version of the inner loop maps source pixels  
	to a destination form with different depth. Because it is already  
	unweildy, the loop is not unrolled as in the other versions.  
	Preload, skew and skewMask are all overlooked, since pickSourcePixels  
	delivers its destination word already properly aligned.  
	Note that pickSourcePixels could be copied in-line at the top of  
	the horizontal loop, and some of its inits moved out of the loop."
	"ar 12/7/1999:  
	The loop has been rewritten to use only one pickSourcePixels call.  
	The idea is that the call itself could be inlined. If we decide not  
	to inline pickSourcePixels we could optimize the loop instead."
	| skewWord halftoneWord mergeWord scrStartBits nSourceIncs startBits endBits sourcePixMask destPixMask mergeFnwith nPix srcShift dstShift destWord words srcShiftInc dstShiftInc dstShiftLeft mapperFlags destIndexLocal |
	self inline: false.
	self var: #mergeFnwith declareC: 'int (*mergeFnwith)(int, int)'.
	mergeFnwith _ self
				cCoerce: (opTable at: combinationRule + 1)
				to: 'int (*)(int, int)'.
	mergeFnwith.
	"null ref for compiler"
	destIndexLocal _ destIndex.
	"Additional inits peculiar to unequal source and dest pix size..."
	sourcePPW _ 32 // sourceDepth.
	sourcePixMask _ maskTable at: sourceDepth.
	destPixMask _ maskTable at: destDepth.
	mapperFlags _ cmFlags bitAnd: ColorMapNewStyle bitInvert32.
	sourceIndex _ sourceBits + (sy * sourcePitch) + (sx // sourcePPW * 4).
	scrStartBits _ sourcePPW
				- (sx bitAnd: sourcePPW - 1).
	bbW < scrStartBits
		ifTrue: [nSourceIncs _ 0]
		ifFalse: [nSourceIncs _ bbW - scrStartBits // sourcePPW + 1].
	sourceDelta _ sourcePitch - (nSourceIncs * 4).
	"Note following two items were already calculated in destmask setup!!"
	startBits _ destPPW
				- (dx bitAnd: destPPW - 1).
	endBits _ (dx + bbW - 1 bitAnd: destPPW - 1)
				+ 1.
	bbW < startBits
		ifTrue: [startBits _ bbW].
	"Precomputed shifts for pickSourcePixels"
	srcShift _ (sx bitAnd: sourcePPW - 1)
				* sourceDepth.
	dstShift _ (dx bitAnd: destPPW - 1)
				* destDepth.
	srcShiftInc _ sourceDepth.
	dstShiftInc _ destDepth.
	dstShiftLeft _ 0.
	sourceMSB
		ifTrue: [srcShift _ 32 - sourceDepth - srcShift.
			srcShiftInc _ 0 - srcShiftInc].
	destMSB
		ifTrue: [dstShift _ 32 - destDepth - dstShift.
			dstShiftInc _ 0 - dstShiftInc.
			dstShiftLeft _ 32 - destDepth].
	1
		to: bbH
		do: [:i | 
			"here is the vertical loop"
			"*** is it possible at all that noHalftone == false? ***"
			noHalftone
				ifTrue: [halftoneWord _ AllOnes]
				ifFalse: [halftoneWord _ self halftoneAt: dy + i - 1].
			"setup first load"
			srcBitShift _ srcShift.
			dstBitShift _ dstShift.
			destMask _ mask1.
			nPix _ startBits.
			"Here is the horizontal loop..."
			words _ nWords.
			["pick up the word"
			skewWord _ self
						pickSourcePixels: nPix
						flags: mapperFlags
						srcMask: sourcePixMask
						destMask: destPixMask
						srcShiftInc: srcShiftInc
						dstShiftInc: dstShiftInc.
			"align next word to leftmost pixel"
			dstBitShift _ dstShiftLeft.
			destMask = AllOnes
				ifTrue: ["avoid read-modify-write"
					mergeWord _ self
								mergeFn: (skewWord bitAnd: halftoneWord)
								with: (self dstLongAt: destIndexLocal).
					self
						dstLongAt: destIndexLocal
						put: (destMask bitAnd: mergeWord)]
				ifFalse: ["General version using dest masking"
					destWord _ self dstLongAt: destIndexLocal.
					mergeWord _ self
								mergeFn: (skewWord bitAnd: halftoneWord)
								with: (destWord bitAnd: destMask).
					destWord _ (destMask bitAnd: mergeWord)
								bitOr: (destWord bitAnd: destMask bitInvert32).
					self dstLongAt: destIndexLocal put: destWord].
			destIndexLocal _ destIndexLocal + 4.
			words = 2
				ifTrue: ["e.g., is the next word the last word?"
					"set mask for last word in this row"
					destMask _ mask2.
					nPix _ endBits]
				ifFalse: ["use fullword mask for inner loop"
					destMask _ AllOnes.
					nPix _ destPPW].
			(words _ words - 1) = 0] whileFalse.
			"--- end of inner loop ---"
			sourceIndex _ sourceIndex + sourceDelta.
			destIndexLocal _ destIndexLocal + destDelta]! !

