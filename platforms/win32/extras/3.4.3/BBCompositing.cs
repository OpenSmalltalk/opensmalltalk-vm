'From Squeak3.4 of 1 March 2003 [latest update: #5170] on 6 April 2003 at 7:05:25 pm'!

!BitBltSimulation methodsFor: 'combination rules' stamp: 'ar 4/6/2003 18:52'!
alphaBlend: sourceWord with: destinationWord
	"Blend sourceWord with destinationWord, assuming both are 32-bit pixels.
	The source is assumed to have 255*alpha in the high 8 bits of each pixel,
	while the high 8 bits of the destinationWord will be ignored.
	The blend produced is alpha*source + (1-alpha)*dest, with
	the computation being performed independently on each color
	component.  The high byte of the result will be 0."
	| alpha unAlpha colorMask result blend shift |
	self inline: false.
	alpha _ sourceWord >> 24.  "High 8 bits of source pixel"
	alpha = 0 ifTrue: [ ^ destinationWord ].
	alpha = 255 ifTrue: [ ^ sourceWord ].
	unAlpha _ 255 - alpha.
	colorMask _ 16rFF.
	result _ 0.

	"red"
	shift := 0.
	blend := ((sourceWord >> shift bitAnd: colorMask) * alpha) +
				((destinationWord>>shift bitAnd: colorMask) * unAlpha)
			 	+ 254 // 255 bitAnd: colorMask.
	result _ result bitOr: blend << shift.
	"green"
	shift := 8.
	blend := ((sourceWord >> shift bitAnd: colorMask) * alpha) +
				((destinationWord>>shift bitAnd: colorMask) * unAlpha)
			 	+ 254 // 255 bitAnd: colorMask.
	result _ result bitOr: blend << shift.
	"blue"
	shift := 16.
	blend := ((sourceWord >> shift bitAnd: colorMask) * alpha) +
				((destinationWord>>shift bitAnd: colorMask) * unAlpha)
			 	+ 254 // 255 bitAnd: colorMask.
	result _ result bitOr: blend << shift.
	"alpha (pre-multiplied)"
	shift := 24.
	blend := (alpha * 255) +
				((destinationWord>>shift bitAnd: colorMask) * unAlpha)
			 	+ 254 // 255 bitAnd: colorMask.
	result _ result bitOr: blend << shift.
	^ result
! !

