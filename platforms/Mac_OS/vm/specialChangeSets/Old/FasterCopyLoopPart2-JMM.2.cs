'From Squeak3.6beta of ''4 July 2003'' [latest update: #5331] on 29 July 2003 at 2:36:26 pm'!

!BitBltSimulation methodsFor: 'inner loop' stamp: 'jmm 7/15/2003 20:44'!
copyLoopNoSource
	"Faster copyLoop when source not used. hDir and vDir are both  
	positive, and perload and skew are unused"
	| halftoneWord mergeWord mergeFnwith destWord destIndexLocal nWordsMinusOne |
	self inline: false.
	self var: #mergeFnwith declareC: 'int (*mergeFnwith)(int, int)'.
	mergeFnwith _ self
				cCoerce: (opTable at: combinationRule + 1)
				to: 'int (*)(int, int)'.
	mergeFnwith.
	"null ref for compiler"
	destIndexLocal _ destIndex.
	nWordsMinusOne _ nWords - 1.
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
						to: nWordsMinusOne
						do: [:word | 
							self dstLongAt: destIndexLocal put: destWord.
							destIndexLocal _ destIndexLocal + 4]]
				ifFalse: ["Normal inner loop does merge"
					2
						to: nWordsMinusOne
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

