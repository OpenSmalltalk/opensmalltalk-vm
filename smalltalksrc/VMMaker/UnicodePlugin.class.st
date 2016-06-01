"
This plugin measures and renders Unicode (UTF8) strings.

"
Class {
	#name : #UnicodePlugin,
	#superclass : #InterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
UnicodePlugin class >> hasHeaderFile [

	^true
]

{ #category : #utility }
UnicodePlugin >> asCString: stringOop [
	"Return a C char * pointer into the given Squeak string object."
	"Warning: A Squeak string is not necessarily null-terminated."
	"Warning: the resulting pointer may become invalid after the next garbage collection and should only be using during the current primitive call."

	<returnTypeC: #'char *'>

	interpreterProxy success: (interpreterProxy isBytes: stringOop).

	^interpreterProxy failed
		ifTrue: [0]
		ifFalse: [self cCoerce: (interpreterProxy firstIndexableField: stringOop) to: #'char *']
]

{ #category : #utility }
UnicodePlugin >> cWordsPtr: oop minSize: minSize [
	"Return a C pointer to the first indexable field of oop, which must be a words object of at least the given size."
	"Warning: the resulting pointer may become invalid after the next garbage collection and should only be using during the current primitive call."

	<returnTypeC: #'void *'>

	interpreterProxy success:
		((interpreterProxy isWords: oop)
		 and: [(interpreterProxy stSizeOf: oop) >= minSize]).
	^interpreterProxy failed
		ifTrue: [0]
		ifFalse: [self cCoerce: (interpreterProxy firstIndexableField: oop) to: #'void *']
]

{ #category : #utility }
UnicodePlugin >> copyString: stringOop into: stringPtr max: maxChars [
	"Copy the Squeak string into a temporary buffer and add a terminating null byte. Fail if there is not sufficent space in the buffer."

	| srcPtr count |
	<inline: false>
	<var: 'stringPtr' type: #'char *'>
	<var: 'srcPtr' type: #'char *'>

	((interpreterProxy isBytes: stringOop)
	and: [(count := interpreterProxy stSizeOf: stringOop) < maxChars]) ifFalse:
		[interpreterProxy success: false.
		^ 0].

	srcPtr := self cCoerce: (interpreterProxy firstIndexableField: stringOop) to: #'char *'.
	1 to: count do: [:i | self cCode: '*stringPtr++ = *srcPtr++'].
	self cCode: '*stringPtr = 0'.
	^ 0
]

{ #category : #primitives }
UnicodePlugin >> primitiveClipboardGet [
	"Read the clipboard into the given UTF16 string.."

	| utf16Oop utf16 utf16Length count |
	<export: true>
	<var: 'utf16' type: #'unsigned short *'>

	utf16Oop := interpreterProxy stackValue: 0.

	interpreterProxy success: (interpreterProxy isWords: utf16Oop).

	interpreterProxy failed ifTrue: [^ 0].

	utf16 := self cCoerce: (interpreterProxy firstIndexableField: utf16Oop) to: #'unsigned short *'.
	utf16Length := 2 * (interpreterProxy stSizeOf: utf16Oop).

	count := self unicodeClipboard: utf16 Get: utf16Length.

	interpreterProxy pop: 2
		thenPush: (interpreterProxy integerObjectOf: count).

	^ 0
]

{ #category : #primitives }
UnicodePlugin >> primitiveClipboardPut [
	"Set the clipboard to a UTF16 string.."

	| strOop count utf16 utf16Length |
	<export: true>
	<var: 'utf16' type: #'unsigned short *'>

	strOop := interpreterProxy stackValue: 1.
	count := interpreterProxy stackIntegerValue: 0.

	interpreterProxy success: (interpreterProxy isWords: strOop).

	interpreterProxy failed ifTrue: [^ 0].

	utf16 := self cCoerce: (interpreterProxy firstIndexableField: strOop) to: #'unsigned short *'.
	utf16Length := 2 * (interpreterProxy stSizeOf: strOop).
	((count >= 0) & (count < utf16Length)) ifTrue: [utf16Length := count].

	self unicodeClipboard: utf16 Put: utf16Length.

	interpreterProxy pop: 2.  "pop args, leave rcvr on stack"
	^ 0
]

{ #category : #primitives }
UnicodePlugin >> primitiveClipboardSize [

	| count |
	<export: true>

	count := self cCode: 'unicodeClipboardSize()'.

	interpreterProxy pop: 1
		thenPush: (interpreterProxy integerObjectOf: count).
	^ 0

]

{ #category : #primitives }
UnicodePlugin >> primitiveDrawString [

	| utf8Oop utf8 w h bitmapOop bitmapPtr utf8Length result |
	<export: true>
	<var: 'utf8' declareC: 'char *utf8'>
	<var: 'bitmapPtr' declareC: 'void *bitmapPtr'>

	utf8Oop := interpreterProxy stackValue: 3.
	utf8 := self asCString: utf8Oop.
	w := interpreterProxy stackIntegerValue: 2.
	h := interpreterProxy stackIntegerValue: 1.
	bitmapOop := interpreterProxy stackValue: 0.
	bitmapPtr := self cWordsPtr: bitmapOop minSize: w * h.
	interpreterProxy failed ifTrue: [^ nil].

	utf8Length := interpreterProxy stSizeOf: utf8Oop.
	self cCode: 'unicodeDrawString(utf8, utf8Length, &w, &h, bitmapPtr)'.

	result := interpreterProxy makePointwithxValue: w yValue: h.
	interpreterProxy pop: 5 thenPush: result.
	^ 0

]

{ #category : #primitives }
UnicodePlugin >> primitiveGetFontList [


	| strOop str strLength count |
	<export: true>
	<var: 'str' declareC: 'char *str'>

	strOop := interpreterProxy stackValue: 0.
	str := self asCString: strOop.
	interpreterProxy failed ifTrue: [^ nil].

	strLength := interpreterProxy stSizeOf: strOop.
	count := self cCode: 'unicodeGetFontList(str, strLength)'.

	interpreterProxy pop: 2
		thenPush: (interpreterProxy integerObjectOf: count).
	^ 0

]

{ #category : #primitives }
UnicodePlugin >> primitiveGetXRanges [

	| utf8Oop utf8 resultOop resultPtr utf8Length count resultLength |
	<export: true>
	<var: 'utf8' declareC: 'char *utf8'>
	<var: 'resultPtr' declareC: 'int *resultPtr'>

	utf8Oop := interpreterProxy stackValue: 1.
	utf8 := self asCString: utf8Oop.

	resultOop := interpreterProxy stackValue: 0.
	resultPtr := self cWordsPtr: resultOop minSize: 0.
	interpreterProxy failed ifTrue: [^ nil].

	utf8Length := interpreterProxy stSizeOf: utf8Oop.
	resultLength := interpreterProxy stSizeOf: resultOop.
	count := self cCode: 'unicodeGetXRanges(utf8, utf8Length, resultPtr, resultLength)'.

	interpreterProxy pop: 3 thenPush: (interpreterProxy integerObjectOf: count).
	^ 0

]

{ #category : #primitives }
UnicodePlugin >> primitiveMeasureString [

	| utf8Oop utf8 utf8Length w h result |
	<export: true>
	<var: 'utf8' declareC: 'char *utf8'>

	utf8Oop := interpreterProxy stackValue: 0.
	utf8 := self asCString: utf8Oop.
	interpreterProxy failed ifTrue: [^ nil].

	w := h := 0.
	utf8Length := interpreterProxy stSizeOf: utf8Oop.
	self cCode: 'unicodeMeasureString(utf8, utf8Length, &w, &h)'.

	result := interpreterProxy makePointwithxValue: w yValue: h.
	interpreterProxy pop: 2 thenPush: result.
	^ 0

]

{ #category : #primitives }
UnicodePlugin >> primitiveSetColors [

	| fgRed fgGreen fgBlue bgRed bgGreen bgBlue mapBGToTransparent |
	<export: true>

	fgRed := interpreterProxy stackIntegerValue: 6.
	fgGreen := interpreterProxy stackIntegerValue: 5.
	fgBlue := interpreterProxy stackIntegerValue: 4.
	bgRed := interpreterProxy stackIntegerValue: 3.
	bgGreen := interpreterProxy stackIntegerValue: 2.
	bgBlue := interpreterProxy stackIntegerValue: 1.
	mapBGToTransparent := interpreterProxy booleanValueOf: (interpreterProxy stackValue: 0).
	interpreterProxy failed ifTrue: [^ nil].

	self cCode: 'unicodeSetColors(fgRed, fgGreen, fgBlue, bgRed, bgGreen, bgBlue, mapBGToTransparent)'.

	interpreterProxy pop: 7.
	^ 0

]

{ #category : #primitives }
UnicodePlugin >> primitiveSetFont [

	| fontName fontSize boldFlag italicFlag antiAliasFlag |
	<export: true>
	<var: 'fontName' declareC: 'char fontName[200]'>

	self copyString: (interpreterProxy stackValue: 4) into: fontName max: 200.
	fontSize := interpreterProxy stackIntegerValue: 3.
	boldFlag := interpreterProxy booleanValueOf: (interpreterProxy stackValue: 2).
	italicFlag := interpreterProxy booleanValueOf: (interpreterProxy stackValue: 1).
	antiAliasFlag := interpreterProxy booleanValueOf: (interpreterProxy stackValue: 0).
	interpreterProxy failed ifTrue: [^ nil].

	self cCode: 'unicodeSetFont(fontName, fontSize, boldFlag, italicFlag, antiAliasFlag)'.

	interpreterProxy pop: 5.
	^ 0

]
