'From TeaSqueak3.2 of 19 September 2002 [latest update: #292] on 25 October 2002 at 12:17:06 am'!
InterpreterPlugin subclass: #FontPlugin
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Squeak-Plugins'!

!FontPlugin commentStamp: '<historical>' prior: 0!
FontPlugin translate.!


!FontPlugin methodsFor: 'initialize' stamp: 'ar 6/4/2000 19:18'!
initialiseModule
	"Initialise the module"
	self export: true.
	^self cCode: 'ioFontInit()' inSmalltalk:[true]! !

!FontPlugin methodsFor: 'initialize' stamp: 'ar 6/4/2000 19:18'!
shutdownModule
	"Initialise the module"
	self export: true.
	^self cCode: 'ioFontShutdown()' inSmalltalk:[true]! !

!FontPlugin methodsFor: 'primitives' stamp: 'ar 6/4/2000 23:11'!
primitiveCreateFont
	| fontName fontFlags fontSize fontNameLength fontNameIndex fontID |
	self export: true.
	interpreterProxy methodArgumentCount = 3
		ifFalse:[^interpreterProxy primitiveFail].
	fontFlags _ interpreterProxy stackIntegerValue: 0.
	fontSize _ interpreterProxy stackIntegerValue: 1.
	fontName _ interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isBytes: fontName)
		ifFalse:[^interpreterProxy primitiveFail].
	fontNameLength _ interpreterProxy byteSizeOf: fontName.
	fontNameIndex _ self cCoerce: (interpreterProxy firstIndexableField: fontName) to:'int'.
	fontID _ self cCode:'ioCreateFont(fontNameIndex, fontNameLength, fontSize, fontFlags)' inSmalltalk:[-1].
	fontID < 0 ifTrue:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 4.
	interpreterProxy pushInteger: fontID.! !

!FontPlugin methodsFor: 'primitives' stamp: 'ar 6/4/2000 20:57'!
primitiveDestroyFont
	| fontIndex |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	fontIndex _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	(self ioDestroyFont: fontIndex)
		ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 1! !

!FontPlugin methodsFor: 'primitives' stamp: 'ar 6/4/2000 22:24'!
primitiveFontAscent
	| fontIndex ascent |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	fontIndex _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	ascent _ self ioFontAscent: fontIndex.
	ascent >= 0
		ifFalse:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 2.
	^interpreterProxy pushInteger: ascent.! !

!FontPlugin methodsFor: 'primitives' stamp: 'ar 2/18/2001 19:33'!
primitiveFontDataSize
	| fontIndex size |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	fontIndex _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	size _ self ioGetFontDataSize: fontIndex.
	interpreterProxy pop: 2.
	^interpreterProxy pushInteger: size.! !

!FontPlugin methodsFor: 'primitives' stamp: 'ar 6/4/2000 22:25'!
primitiveFontDescent
	| fontIndex descent |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	fontIndex _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	descent _ self ioFontDescent: fontIndex.
	descent >= 0
		ifFalse:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 2.
	^interpreterProxy pushInteger: descent.! !

!FontPlugin methodsFor: 'primitives' stamp: 'ar 2/18/2001 19:57'!
primitiveFontEmbeddingFlags
	| fontIndex flags |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	fontIndex _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	flags _ self ioFontEmbeddingFlags: fontIndex.
	interpreterProxy pop: 2.
	^interpreterProxy pushInteger: flags! !

!FontPlugin methodsFor: 'primitives' stamp: 'ar 6/4/2000 21:08'!
primitiveFontEncoding
	| fontIndex encoding |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	fontIndex _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	encoding _ self ioFontEncoding: fontIndex.
	encoding >= 0
		ifFalse:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 2.
	^interpreterProxy pushInteger: encoding.! !

!FontPlugin methodsFor: 'primitives' stamp: 'ar 8/28/2000 17:31'!
primitiveFontFullWidthOfChar
	| fontIndex charIndex array fullWidth |
	self var: #fullWidth declareC:'int fullWidth[3]'.
	self export: true.
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	charIndex _ interpreterProxy stackIntegerValue: 0.
	fontIndex _ interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	(self cCode: 'ioFontFullWidthOfChar(fontIndex, charIndex, fullWidth)' inSmalltalk:[false])
		ifFalse:[^interpreterProxy primitiveFail].
	array _ interpreterProxy 
					instantiateClass: interpreterProxy classArray 
					indexableSize: 3.
	0 to: 2 do:[:i|
		interpreterProxy storeInteger: i ofObject: array withValue: (fullWidth at: i).
	].
	interpreterProxy pop: 3.
	^interpreterProxy push: array! !

!FontPlugin methodsFor: 'primitives' stamp: 'ar 8/28/2000 17:31'!
primitiveFontGetKernPair
	| fontIndex kernIndex array kernPair |
	self var: #kernPair declareC:'int kernPair[3]'.
	self export: true.
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	kernIndex _ interpreterProxy stackIntegerValue: 0.
	fontIndex _ interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	(self cCode: 'ioFontGetKernPair(fontIndex, kernIndex, kernPair)' inSmalltalk:[false])
		ifFalse:[^interpreterProxy primitiveFail].
	array _ interpreterProxy 
					instantiateClass: interpreterProxy classArray 
					indexableSize: 3.
	0 to: 2 do:[:i|
		interpreterProxy storeInteger: i ofObject: array withValue: (kernPair at: i).
	].
	interpreterProxy pop: 3.
	^interpreterProxy push: array! !

!FontPlugin methodsFor: 'primitives' stamp: 'ar 6/4/2000 21:11'!
primitiveFontGlyphOfChar
	| fontIndex charIndex formOop formBits formWidth formHeight formDepth ppw pitch |
	self export: true.
	interpreterProxy methodArgumentCount = 3
		ifFalse:[^interpreterProxy primitiveFail].
	formOop _ interpreterProxy stackObjectValue: 0.
	charIndex _ interpreterProxy stackIntegerValue: 1.
	fontIndex _ interpreterProxy stackIntegerValue: 2.
	interpreterProxy failed ifTrue:[^nil].
	((interpreterProxy isPointers: formOop) and:[
		(interpreterProxy slotSizeOf: formOop) >= 4])
			ifFalse:[^interpreterProxy primitiveFail].
	formBits _ interpreterProxy fetchPointer: 0 ofObject: formOop.
	formWidth _ interpreterProxy fetchInteger: 1 ofObject: formOop.
	formHeight _ interpreterProxy fetchInteger: 2 ofObject: formOop.
	formDepth _ interpreterProxy fetchInteger: 3 ofObject: formOop.
	(formWidth > 0 and:[formHeight > 0 and:[formDepth > 0]])
		ifFalse:[^interpreterProxy primitiveFail].
	ppw _ 32 // formDepth.
	pitch _ formWidth + (ppw-1) // ppw * 4.
	((interpreterProxy fetchClassOf: formBits) == interpreterProxy classBitmap
		and:[(interpreterProxy byteSizeOf: formBits) = (pitch * formHeight)])
			ifFalse:[^interpreterProxy primitiveFail].
	formBits _ self cCoerce: (interpreterProxy firstIndexableField: formBits) to: 'int'.
	(self cCode:'ioFontGlyphOfChar(fontIndex, charIndex, formBits, formWidth, formHeight, formDepth)' inSmalltalk:[false])
		ifFalse:[^interpreterProxy primitiveFail].
	^interpreterProxy pop: 3.! !

!FontPlugin methodsFor: 'primitives' stamp: 'ar 8/28/2000 16:06'!
primitiveFontNumKernPairs
	| fontIndex nKernPairs |
	self export: true.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	fontIndex _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	nKernPairs _ self ioFontNumKernPairs: fontIndex.
	nKernPairs >= 0
		ifFalse:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 2.
	^interpreterProxy pushInteger: nKernPairs.! !

!FontPlugin methodsFor: 'primitives' stamp: 'ar 6/4/2000 21:08'!
primitiveFontWidthOfChar
	| fontIndex charIndex charWidth |
	self export: true.
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	charIndex _ interpreterProxy stackIntegerValue: 0.
	fontIndex _ interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	charWidth _ self ioFont: fontIndex WidthOfChar: charIndex.
	(charWidth >= 0)
		ifFalse:[^interpreterProxy primitiveFail].
	interpreterProxy pop: 3.
	^interpreterProxy pushInteger: charWidth! !

!FontPlugin methodsFor: 'primitives' stamp: 'ar 2/18/2001 19:39'!
primitiveGetFontData
	| fontIndex buffer bufSize bufPtr result |
	self export: true.
	self var: #bufPtr type:'char *'.
	interpreterProxy methodArgumentCount = 2
		ifFalse:[^interpreterProxy primitiveFail].
	buffer _ interpreterProxy stackObjectValue: 0.
	fontIndex _ interpreterProxy stackIntegerValue: 1.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy isBytes: buffer) 
		ifFalse:[^interpreterProxy primitiveFail].
	bufSize _ interpreterProxy byteSizeOf: buffer.
	bufPtr _ interpreterProxy firstIndexableField: buffer.
	result _ self cCode: 'ioGetFontData(fontIndex, bufPtr, bufSize)'.
	interpreterProxy pop: 3.
	^interpreterProxy pushInteger: result.! !

!FontPlugin methodsFor: 'primitives' stamp: 'ar 6/4/2000 19:23'!
primitiveListFont
	| fontIndex fontName fontNameLen fontOop fontPtr |
	self export: true.
	self var: #fontName type:'char *'.
	self var: #fontPtr type:'char *'.
	interpreterProxy methodArgumentCount = 1
		ifFalse:[^interpreterProxy primitiveFail].
	fontIndex _ interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	fontName _ self ioListFont: fontIndex.
	fontName == nil ifTrue:[
		interpreterProxy pop: 2.
		^interpreterProxy push: interpreterProxy nilObject].
	fontNameLen _ fontName strlen.
	fontOop _ interpreterProxy 
					instantiateClass: interpreterProxy classString 
					indexableSize: fontNameLen.
	fontPtr _ interpreterProxy firstIndexableField: fontOop.
	0 to: fontNameLen-1 do:[:i| fontPtr at: i put: (fontName at: i)].
	interpreterProxy pop: 2.
	interpreterProxy push: fontOop.! !


!FontPlugin class methodsFor: 'translation' stamp: 'ar 2/18/2001 19:58'!
headerFile
^'/* FontPlugin header file */

char *ioListFont(int fontIndex);
int ioCreateFont(int fontNameIndex, int fontNameLength, int pixelSize, int flags);
int ioDestroyFont(int fontIndex);
int ioFontWidthOfChar(int fontIndex, int characterIndex);
int ioFontFullWidthOfChar(int fontIndex, int characterIndex, int width[3]);
int ioFontNumKernPairs(int fontIndex);
int ioFontGetKernPair(int fontIndex, int kernIndex, int kernPair[3]);

int ioFontGlyphOfChar(int fontIndex, int characterIndex, 
					  int formBitsIndex, int formWidth, int formHeight, int formDepth);
int ioFontEncoding(int fontIndex);
int ioFontAscent(int fontIndex);
int ioFontDescent(int fontIndex);

int ioFontEmbeddingFlags(int fontIndex);
int ioGetFontDataSize(int fontIndex);
int ioGetFontData(int fontIndex, char *buffer, int bufSize);

'! !

