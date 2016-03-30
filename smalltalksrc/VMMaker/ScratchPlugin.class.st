"
This plugin combines a number of primitives needed by Scratch including:

  a. primitives that manipulate 24-bit color images (i.e. 32-bit deep Forms but alpha is ignored)
  b. primitive to open browsers, find the user's documents folder, set the window title and other host OS functions

This plugin includes new serial port primitives, including support for named serial ports. The underlying plugin code can support up to 32 simultaenously open ports.

Port options for Set/GetOption primitives:
  1. baud rate
  2. data bits
  3. stop bits
  4. parity type
  5. input flow control type
  6. output flow control type

Handshake lines (options 20-25 for Set/GetOption primitives):
  20. DTR	(output line)
  21. RTS	(output line)
  22. CTS	(input line)
  23. DSR	(input line)
  24. CD		(input line)
  25. RI		(input line)


"
Class {
	#name : #ScratchPlugin,
	#superclass : #InterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
ScratchPlugin class >> hasHeaderFile [

	^true
]

{ #category : #private }
ScratchPlugin >> bitmap: bitmap at: i putH: hue s: saturation v: brightness [

	| hI hF p q t v outPix |
	<inline: true>
	<var: 'bitmap' declareC: 'unsigned int *bitmap'>

	hI := hue // 60.  "integer part of hue (0..5)"
	hF := hue \\ 60.  "fractional part ofhue"
	p := (1000 - saturation) * brightness.
	q := (1000 - ((saturation * hF) // 60)) * brightness.
	t := (1000 - ((saturation * (60 - hF)) // 60)) * brightness.

	v := (brightness * 1000) // 3922.
	p := p // 3922.
	q := q // 3922.
	t := t // 3922.

	0 = hI ifTrue: [outPix := ((v bitShift: 16) + (t bitShift: 8) + p)].
	1 = hI ifTrue: [outPix := ((q bitShift: 16) + (v bitShift: 8) + p)].
	2 = hI ifTrue: [outPix := ((p bitShift: 16) + (v bitShift: 8) + t)].
	3 = hI ifTrue: [outPix := ((p bitShift: 16) + (q bitShift: 8) + v)].
	4 = hI ifTrue: [outPix := ((t bitShift: 16) + (p bitShift: 8) + v)].
	5 = hI ifTrue: [outPix := ((v bitShift: 16) + (p bitShift: 8) + q)].

	outPix = 0 ifTrue: [outPix := 1].  "convert transparent to 1"
	bitmap at: i put: outPix.
	^ 0

]

{ #category : #private }
ScratchPlugin >> checkedFloatPtrOf: oop [
	"Return an unsigned int pointer to the first indexable word of oop, which must be a words object."

	<inline: true>
	<returnTypeC: 'double *'>

	interpreterProxy success: (interpreterProxy isWordsOrBytes: oop).
	interpreterProxy failed ifTrue: [^ 0].
	^ self cCoerce: (interpreterProxy firstIndexableField: oop) to: 'double *'

]

{ #category : #private }
ScratchPlugin >> checkedUnsignedIntPtrOf: oop [
	"Return an unsigned int pointer to the first indexable word of oop, which must be a words object."

	<inline: true>
	<returnTypeC: 'unsigned int *'>

	interpreterProxy success: (interpreterProxy isWords: oop).
	interpreterProxy failed ifTrue: [^ 0].
	^ self cCoerce: (interpreterProxy firstIndexableField: oop) to: 'unsigned int *'

]

{ #category : #private }
ScratchPlugin >> hueFromR: r G: g B: b min: min max: max [
	"Answer the hue, an angle between 0 and 360."

	| span result |
	<inline: true>

	span := max - min.
	span = 0 ifTrue: [^ 0].

	r = max
		ifTrue: [result := ((60 * (g - b)) // span)]
		ifFalse: [
			g = max
				ifTrue: [result := 120 + ((60 * (b - r)) // span)]
				ifFalse: [result := 240 + ((60 * (r - g)) // span)]].

	result < 0 ifTrue: [^ result + 360].
	^ result

]

{ #category : #private }
ScratchPlugin >> interpolate: pix1 and: pix2 frac: frac2 [
	"Answer the interpolated pixel value between the given two pixel values. If either pixel is zero (transparent) answer the other pixel. If both pixels are  transparent, answer transparent. The fraction is between 0 and 1023, out of a total range of 1024."

	| frac1 r g b result |
	<inline: true>

	pix1 = 0 ifTrue: [^ pix2].  "pix1 is transparent"
	pix2 = 0 ifTrue: [^ pix1].  "pix2 is transparent"

	frac1 := 1024 - frac2.
	r := ((frac1 * ((pix1 bitShift: -16) bitAnd: 16rFF)) + (frac2 * ((pix2 bitShift: -16) bitAnd: 16rFF))) // 1024.
	g := ((frac1 * ((pix1 bitShift: -8) bitAnd: 16rFF)) + (frac2 * ((pix2 bitShift: -8) bitAnd: 16rFF))) // 1024.
	b := ((frac1 * (pix1 bitAnd: 16rFF)) + (frac2 * (pix2 bitAnd: 16rFF))) // 1024.
	result := (r bitShift: 16) + (g bitShift: 8) + b.
	result = 0 ifTrue: [result := 1].
	^ result

]

{ #category : #private }
ScratchPlugin >> interpolatedFrom: bitmap x: xFixed y: yFixed width: w height: h [
	"Answer the interpolated pixel value from the given bitmap at the given point. The x and y coordinates are fixed-point integers with 10 bits of fraction (i.e. they were multiplied by 1024, then truncated). If the given point is right on an edge, answer the nearest edge pixel value. If it is entirely outside of the image, answer 0 (transparent)."

	| x y xFrac yFrac index topPix bottomPix |
	<inline: true>
	<var: 'bitmap' declareC: 'unsigned int *bitmap'>

	x := xFixed bitShift: -10.
	(x < -1 or: [x >= w]) ifTrue: [^ 0].
	y := yFixed bitShift: -10.
	(y < -1 or: [y >= h]) ifTrue: [^ 0].

	xFrac := xFixed bitAnd: 1023.
	x = -1 ifTrue: [x := 0. xFrac := 0].  "left edge"
	x = (w - 1) ifTrue: [xFrac := 0].  "right edge"

	yFrac := yFixed bitAnd: 1023.
	y = -1 ifTrue: [y := 0. yFrac := 0].  "top edge"
	y = (h - 1) ifTrue: [yFrac := 0].  "bottom edge"

	index := (y * w) + x "for squeak: + 1".
	topPix := (bitmap at: index) bitAnd: 16rFFFFFF.
	xFrac > 0 ifTrue: [
		topPix := self interpolate: topPix and: ((bitmap at: index + 1) bitAnd: 16rFFFFFF) frac: xFrac].

	yFrac = 0 ifTrue: [^ topPix].  "no y fraction, so just use value from top row"

	index := ((y + 1) * w) + x "for squeak: + 1".
	bottomPix := (bitmap at: index) bitAnd: 16rFFFFFF.
	xFrac > 0 ifTrue: [
		bottomPix := self interpolate: bottomPix and: ((bitmap at: index + 1) bitAnd: 16rFFFFFF) frac: xFrac].

	^ self interpolate: topPix and: bottomPix frac: yFrac

]

{ #category : #'serial port' }
ScratchPlugin >> primClose [
	"Close the given serial port."

	| portNum |
	<export: true>
	portNum := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue: [^ nil].

	self cCode: 'SerialPortClose(portNum)'.

	interpreterProxy pop: 1.  "pop arg, leave rcvr on stack"
	^ 0

]

{ #category : #'serial port' }
ScratchPlugin >> primGetOption [
	"Return the given option value for the given serial port."

	| portNum attrNum result |
	<export: true>
	portNum := interpreterProxy stackIntegerValue: 1.
	attrNum := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue: [^ nil].

	result := self cCode: 'SerialPortGetOption(portNum, attrNum)'.
	result = -1 ifTrue: [interpreterProxy success: false. ^ 0].

	interpreterProxy pop: 3.  "pop args and rcvr, push result"
	interpreterProxy pushInteger: result.
	^ 0

]

{ #category : #'serial port' }
ScratchPlugin >> primIsPortOpen [
	"Answer the true if the given port is open."

	| portNum result |
	<export: true>
	portNum := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue: [^ 0].

	result := self cCode: 'SerialPortIsOpen(portNum)'.

	interpreterProxy pop: 2.  "pop arg and rcvr"
	interpreterProxy pushBool: result ~= 0.  "push result"
	^ 0

]

{ #category : #'serial port' }
ScratchPlugin >> primOpenPortNamed [
	"Open the port with the given name and baud rate."

	| nameStr src nameOop baudRate count portNum |
	<export: true>
	<var: 'nameStr' declareC: 'char nameStr[1000]'>
	<var: 'src' type: #'char *'>

	nameOop := interpreterProxy stackValue: 1.
	baudRate := interpreterProxy stackIntegerValue: 0.

	interpreterProxy success: (interpreterProxy isBytes: nameOop).

	interpreterProxy failed ifTrue: [^ 0].

	src := self cCoerce: (interpreterProxy firstIndexableField: nameOop) to: #'char *'.
	count := interpreterProxy stSizeOf: nameOop.
	0 to: count - 1 do: [:i | nameStr at: i put: (src at: i)].
	nameStr at: count put: 0.

	portNum := self SerialPortOpen: nameStr PortNamed: baudRate.
	portNum = -1 ifTrue: [interpreterProxy success: false. ^ 0].

	interpreterProxy	"pop args and rcvr, push result"
		pop: 3
		thenPush: (interpreterProxy integerObjectOf: portNum).

	^ 0

]

{ #category : #'serial port' }
ScratchPlugin >> primPortCount [
	"Answer the number of serial ports."

	| result |
	<export: true>

	result := self cCode: 'SerialPortCount()'.
	result = -1 ifTrue: [interpreterProxy success: false. ^ 0].

	interpreterProxy
		pop: 1 thenPush: (interpreterProxy integerObjectOf: result).  "pop rcvr, push result"
	^ 0

]

{ #category : #'serial port' }
ScratchPlugin >> primPortName [
	"Get the name for the port with the given number. Fail if the port number is greater than the number of available ports. Port numbering starts with 1."

	| portIndex nameStr count resultOop dst |
	<export: true>
	<var: 'nameStr' declareC: 'char nameStr[1000]'>
	<var: 'dst' declareC: 'char* dst'>

	portIndex := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue: [^ 0].

	self cCode: 'SerialPortName(portIndex, nameStr, 1000)'.

	count := self cCode: 'strlen(nameStr)'.
	count = 0 ifTrue: [
		interpreterProxy success: false.
		^ 0].

	resultOop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: count.
	dst := self cCoerce: (interpreterProxy firstIndexableField: resultOop) to: 'char *'.
	0 to: count - 1 do: [:i | dst at: i put: (nameStr at: i)].

	interpreterProxy pop: 2 thenPush: resultOop.  "pop arg and rcvr, push result"
	^ 0

]

{ #category : #'serial port' }
ScratchPlugin >> primRead [
	"Read data from the given serial port into the given buffer (a ByteArray or String). Answer the number of bytes read."

	| portNum bufOop bytesRead |
	<export: true>

	portNum := interpreterProxy stackIntegerValue: 1.
	bufOop := interpreterProxy stackValue: 0.

	interpreterProxy success: (interpreterProxy isBytes: bufOop).
	interpreterProxy failed ifTrue: [^ 0].

	bytesRead := self Serial: portNum
						Port: (self cCoerce: (interpreterProxy firstIndexableField: bufOop) to: 'char *')
						Read: (interpreterProxy stSizeOf: bufOop).

	interpreterProxy pop: 3.  					"pop args and rcvr"
	interpreterProxy pushInteger: bytesRead.	"push result"
	^ 0
]

{ #category : #'serial port' }
ScratchPlugin >> primSetOption [
	"Return the given option value for the given serial port."

	| portNum attrNum attrValue result |
	<export: true>
	portNum := interpreterProxy stackIntegerValue: 2.
	attrNum := interpreterProxy stackIntegerValue: 1.
	attrValue := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue: [^ nil].

	result := self cCode: 'SerialPortSetOption(portNum, attrNum, attrValue)'.
	result = -1 ifTrue: [interpreterProxy success: false. ^ 0].

	interpreterProxy pop: 3.  "pop args; leave rcvr on stack"
	^ 0

]

{ #category : #'serial port' }
ScratchPlugin >> primWrite [
	"Write data to the given serial port from the given buffer (a ByteArray or String). Answer the number of bytes written."

	| portNum bufOop bytesWritten |
	<export: true>

	portNum := interpreterProxy stackIntegerValue: 1.
	bufOop := interpreterProxy stackValue: 0.

	interpreterProxy success: (interpreterProxy isBytes: bufOop).
	interpreterProxy failed ifTrue: [^ 0].

	bytesWritten := self Serial: portNum
						Port: (self cCoerce: (interpreterProxy firstIndexableField: bufOop) to: 'char *')
						Write: (interpreterProxy stSizeOf: bufOop).

	interpreterProxy pop: 3.  						"pop args and rcvr"
	interpreterProxy pushInteger: bytesWritten.	"push result"
	^ 0
]

{ #category : #'other filters' }
ScratchPlugin >> primitiveBlur [

	| inOop outOop width in out sz height n rTotal gTotal bTotal pix outPix |
	<export: true>
	<var: 'in' declareC: 'unsigned int *in'>
	<var: 'out' declareC: 'unsigned int *out'>

	inOop := interpreterProxy stackValue: 2.
	outOop := interpreterProxy stackValue: 1.
	width := interpreterProxy stackIntegerValue: 0.
	in := self checkedUnsignedIntPtrOf: inOop.
	out := self checkedUnsignedIntPtrOf: outOop.
	sz := interpreterProxy stSizeOf: inOop.
	interpreterProxy success: ((interpreterProxy stSizeOf: outOop) = sz).
	interpreterProxy failed ifTrue: [^ nil].

	height := sz // width.
	1 to: height - 2 do: [:y |
		1 to: width - 2 do: [:x |
			n := rTotal := gTotal := bTotal := 0.
			-1 to: 1 do: [:dY |
				-1 to: 1 do: [:dX |
					pix := (in at: ((y + dY) * width) + (x + dX) "add 1 when testing in Squeak") bitAnd: 16rFFFFFF.
					pix = 0 ifFalse: [  "skip transparent pixels"
						rTotal := rTotal + ((pix bitShift: -16) bitAnd: 16rFF).
						gTotal := gTotal + ((pix bitShift: -8) bitAnd: 16rFF).
						bTotal := bTotal + (pix bitAnd: 16rFF).
						n := n + 1]]].
			n = 0
				ifTrue: [outPix :=  0]
				ifFalse: [outPix := ((rTotal // n) bitShift: 16) + ((gTotal // n) bitShift: 8) +  (bTotal // n)].
			out at: ((y * width) + x "add 1 when testing in Squeak") put: outPix]].

	interpreterProxy pop: 3.  "pop args, leave rcvr on stack"
	^ 0

]

{ #category : #'hsv filters' }
ScratchPlugin >> primitiveBrightnessShift [

	| inOop outOop shift in sz out pix r g b max min hue saturation brightness |
	<export: true>
	<var: 'in' declareC: 'unsigned int *in'>
	<var: 'out' declareC: 'unsigned int *out'>

	inOop := interpreterProxy stackValue: 2.
	outOop := interpreterProxy stackValue: 1.
	shift := interpreterProxy stackIntegerValue: 0.
	in := self checkedUnsignedIntPtrOf: inOop.
	sz := interpreterProxy stSizeOf: inOop.
	out := self checkedUnsignedIntPtrOf: outOop.
	interpreterProxy success: ((interpreterProxy stSizeOf: outOop) = sz).
	interpreterProxy failed ifTrue: [^ nil].

	0 to: sz - 1 do: [:i |
		pix := (in at: i) bitAnd: 16rFFFFFF.
		pix = 0 ifFalse: [  "skip pixel values of 0 (transparent)"
			r := (pix bitShift: -16) bitAnd: 16rFF.
			g := (pix bitShift: -8) bitAnd: 16rFF.
			b := pix bitAnd: 16rFF.

			"find min and max color components"
			max := min := r.
			g > max ifTrue: [max := g].
			b > max ifTrue: [max := b].
			g < min ifTrue: [min := g].
			b < min ifTrue: [min := b].

			"find current hue with range 0 to 360"
			hue := self hueFromR: r G: g B: b min: min max: max.

			"find current saturation and brightness with range 0 to 1000"
			max = 0 ifTrue: [saturation := 0] ifFalse: [saturation := ((max - min) * 1000) // max].
			brightness := (max * 1000) // 255.

			"compute new brigthness"
			brightness := brightness + (shift * 10).
			brightness > 1000 ifTrue: [brightness := 1000].
			brightness < 0 ifTrue: [brightness := 0].

			self bitmap: out at: i putH: hue s: saturation v: brightness]].

	interpreterProxy pop: 3.  "pop args, leave rcvr on stack"
	^ 0

]

{ #category : #sound }
ScratchPlugin >> primitiveCondenseSound [

	| srcOop dstOop factor sz src dst count max v |
	<export: true>
	<var: 'src' declareC: 'short *src'>
	<var: 'dst' declareC: 'short *dst'>

	srcOop := interpreterProxy stackValue: 2.
	dstOop := interpreterProxy stackValue: 1.
	factor := interpreterProxy stackIntegerValue: 0.
	interpreterProxy success: (interpreterProxy isWords: srcOop).
	interpreterProxy success: (interpreterProxy isWords: dstOop).

	count := (2 * (interpreterProxy stSizeOf: srcOop)) // factor.
	sz := 2 * (interpreterProxy stSizeOf: dstOop).
	interpreterProxy success: (sz >= count).
	interpreterProxy failed ifTrue: [^ nil].

	src := self cCoerce: (interpreterProxy firstIndexableField: srcOop) to: 'short *'.
	dst := self cCoerce: (interpreterProxy firstIndexableField: dstOop) to: 'short *'.

	1 to: count do: [:i |
		max := 0.
		1 to: factor do: [:j |
			v := self cCode: '*src++'.
			v < 0 ifTrue: [v := 0 - v].
			v > max ifTrue: [max := v]].
		self cCode: '*dst++ = max'].

	interpreterProxy pop: 3.  "pop args, leave rcvr on stack"
	^ 0

]

{ #category : #scaling }
ScratchPlugin >> primitiveDoubleSize [

	| in out inOop outOop inW inH outW outH dstX dstY baseIndex pix i |
	<export: true>
	<var: 'in' declareC: 'int *in'>
	<var: 'out' declareC: 'int *out'>

	inOop := interpreterProxy stackValue: 7.
	inW := interpreterProxy stackIntegerValue: 6.
	inH := interpreterProxy stackIntegerValue: 5.
	outOop := interpreterProxy stackValue: 4.
	outW := interpreterProxy stackIntegerValue: 3.
	outH := interpreterProxy stackIntegerValue: 2.
	dstX := interpreterProxy stackIntegerValue: 1.
	dstY := interpreterProxy stackIntegerValue: 0.

	in := self checkedUnsignedIntPtrOf: inOop.
	out := self checkedUnsignedIntPtrOf: outOop.
	interpreterProxy success: (dstX + (2 * inW)) < outW.
	interpreterProxy success: (dstY + (2 * inH)) < outH.
	interpreterProxy failed ifTrue: [^ nil].

	0 to: inH - 1 do: [:y |
		baseIndex := ((dstY + (2 * y)) * outW) + dstX.
		0 to: inW - 1 do: [:x |
			pix := in at: x + (y * inW).
			i := baseIndex + (2 * x).
			out at: i put: pix.
			out at: i + 1 put: pix.
			out at: i + outW put: pix.
			out at: i + outW + 1 put: pix]].

	interpreterProxy pop: 8.  "pop args, leave rcvr on stack"
	^ 0

]

{ #category : #sound }
ScratchPlugin >> primitiveExtractChannel [

	| srcOop dstOop rightFlag sz src dst |
	<export: true>
	<var: 'src' declareC: 'short *src'>
	<var: 'dst' declareC: 'short *dst'>

	srcOop := interpreterProxy stackValue: 2.
	dstOop := interpreterProxy stackValue: 1.
	rightFlag := interpreterProxy booleanValueOf: (interpreterProxy stackValue: 0).
	interpreterProxy success: (interpreterProxy isWords: srcOop).
	interpreterProxy success: (interpreterProxy isWords: dstOop).

	sz := interpreterProxy stSizeOf: srcOop.
	interpreterProxy success: ((interpreterProxy stSizeOf: dstOop) >= (sz // 2)).
	interpreterProxy failed ifTrue: [^ nil].

	src := self cCoerce: (interpreterProxy firstIndexableField: srcOop) to: 'short *'.
	dst := self cCoerce: (interpreterProxy firstIndexableField: dstOop) to: 'short *'.

	rightFlag ifTrue: [self cCode: 'src++']. 
	1 to: sz do: [:i | self cCode: '*dst++ = *src; src += 2'].

	interpreterProxy pop: 3.  "pop args, leave rcvr on stack"
	^ 0

]

{ #category : #'other filters' }
ScratchPlugin >> primitiveFisheye [

	| inOop outOop width in out sz height centerX centerY dx dy ang pix power r srcX srcY scaledPower |
	<export: true>
	<var: 'in' type: #'unsigned int *'>
	<var: 'out' type: #'unsigned int *'>
	<var: 'dx' type: #double>
	<var: 'dy' type: #double>
	<var: 'ang' type: #double>
	<var: 'r' type: #double>
	<var: 'scaledPower' type: #double>

	inOop := interpreterProxy stackValue: 3.
	outOop := interpreterProxy stackValue: 2.
	width := interpreterProxy stackIntegerValue: 1.
	power := interpreterProxy stackIntegerValue: 0.
	in := self checkedUnsignedIntPtrOf: inOop.
	out := self checkedUnsignedIntPtrOf: outOop.
	sz := interpreterProxy stSizeOf: inOop.
	interpreterProxy success: ((interpreterProxy stSizeOf: outOop) = sz).
	interpreterProxy failed ifTrue: [^ nil].

	"calculate height, center, scales, radius, whirlRadians, and radiusSquared"
	height := sz // width.
	centerX := width // 2.
	centerY := height // 2.

	height := sz // width.
	centerX := width // 2.
	centerY := height // 2.
	scaledPower := power / 100.0.

	0 to: width - 1 do: [:x |
		0 to: height - 1 do: [:y |
			dx := (x - centerX) / centerX asFloat.
			dy := (y - centerY) / centerY asFloat.
			r := ((dx * dx) + (dy * dy)) sqrt raisedTo: scaledPower.
			r <= 1.0
				ifTrue: [
					ang := self cCode: 'atan2(dy,dx)'.
					srcX := (1024 * (centerX + ((r * ang cos) * centerX))) asInteger.
					srcY := (1024 * (centerY + ((r * ang sin) * centerY))) asInteger]
				ifFalse: [
					srcX := 1024 * x.
					srcY := 1024 * y].
			pix := self interpolatedFrom: in
					x: srcX
					y: srcY
					width: width
					height: height.
			out at: ((y * width) + x "+ 1 for Squeak") put: pix]].

	interpreterProxy pop: 4.  "pop args, leave rcvr on stack"
	^ 0

]

{ #category : #'os functions' }
ScratchPlugin >> primitiveGetFolderPath [
	"Get the path for the special folder with given ID. Fail if the folder ID is out of range."

	| nameStr dst folderID count resultOop |
	<export: true>
	<var: 'nameStr' declareC: 'char nameStr[2000]'>
	<var: 'dst' declareC: 'char* dst'>

	folderID := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue: [^ 0].

	self cCode: 'GetFolderPathForID(folderID, nameStr, 2000)'.

	count := self cCode: 'strlen(nameStr)'.
	resultOop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: count.
	dst := self cCoerce: (interpreterProxy firstIndexableField: resultOop) to: 'char *'.
	0 to: count - 1 do: [:i | dst at: i put: (nameStr at: i)].

	interpreterProxy pop: 2 thenPush: resultOop.  "pop arg and rcvr, push result"
	^ 0

]

{ #category : #scaling }
ScratchPlugin >> primitiveHalfSizeAverage [

	| in inW inH out outW outH srcX srcY dstX dstY dstW dstH srcIndex dstIndex pixel r g b |
	<export: true>
	<var: 'in' declareC: 'int *in'>
	<var: 'out' declareC: 'int *out'>

	in := self checkedUnsignedIntPtrOf: (interpreterProxy stackValue: 11).
	inW := interpreterProxy stackIntegerValue: 10.
	inH := interpreterProxy stackIntegerValue: 9.
	out := self checkedUnsignedIntPtrOf: (interpreterProxy stackValue: 8).
	outW := interpreterProxy stackIntegerValue: 7.
	outH := interpreterProxy stackIntegerValue: 6.
	srcX := interpreterProxy stackIntegerValue: 5.
	srcY := interpreterProxy stackIntegerValue: 4.
	dstX := interpreterProxy stackIntegerValue: 3.
	dstY := interpreterProxy stackIntegerValue: 2.
	dstW := interpreterProxy stackIntegerValue: 1.
	dstH := interpreterProxy stackIntegerValue: 0.

	interpreterProxy success: (srcX >= 0) & (srcY >= 0).
	interpreterProxy success: (srcX + (2 * dstW)) <= inW.
	interpreterProxy success: (srcY + (2 * dstH)) <= inH.
	interpreterProxy success: (dstX >= 0) & (dstY >= 0).
	interpreterProxy success: (dstX + dstW) <= outW.
	interpreterProxy success: (dstY + dstH) <= outH.
	interpreterProxy failed ifTrue: [^ nil].

	0 to: dstH - 1 do: [:y |
		srcIndex := (inW * (srcY + (2 * y))) + srcX.
		dstIndex := (outW * (dstY + y)) + dstX.
		0 to: dstW - 1 do: [:x |
			pixel := in at: srcIndex.
			r := pixel bitAnd: 16rFF0000.
			g := pixel bitAnd: 16rFF00.
			b := pixel bitAnd: 16rFF.

			pixel := in at: srcIndex + 1.
			r := r + (pixel bitAnd: 16rFF0000).
			g := g + (pixel bitAnd: 16rFF00).
			b := b + (pixel bitAnd: 16rFF).

			pixel := in at: srcIndex + inW.
			r := r + (pixel bitAnd: 16rFF0000).
			g := g + (pixel bitAnd: 16rFF00).
			b := b + (pixel bitAnd: 16rFF).

			pixel := in at: srcIndex + inW + 1.
			r := r + (pixel bitAnd: 16rFF0000).
			g := g + (pixel bitAnd: 16rFF00).
			b := b + (pixel bitAnd: 16rFF).

			"store combined RGB into target bitmap"
			out at: dstIndex put:
				(((r bitShift: -2) bitAnd: 16rFF0000) bitOr:
				(((g bitShift: -2) bitAnd: 16rFF00) bitOr: (b bitShift: -2))).

			srcIndex := srcIndex + 2.
			dstIndex := dstIndex + 1]].

	interpreterProxy pop: 12.  "pop args, leave rcvr on stack"
	^ 0

]

{ #category : #scaling }
ScratchPlugin >> primitiveHalfSizeDiagonal [

	| in inW inH out outW outH srcX srcY dstX dstY dstW dstH srcIndex dstIndex p1 p2 r g b |
	<export: true>
	<var: 'in' declareC: 'int *in'>
	<var: 'out' declareC: 'int *out'>

	in := self checkedUnsignedIntPtrOf: (interpreterProxy stackValue: 11).
	inW := interpreterProxy stackIntegerValue: 10.
	inH := interpreterProxy stackIntegerValue: 9.
	out := self checkedUnsignedIntPtrOf: (interpreterProxy stackValue: 8).
	outW := interpreterProxy stackIntegerValue: 7.
	outH := interpreterProxy stackIntegerValue: 6.
	srcX := interpreterProxy stackIntegerValue: 5.
	srcY := interpreterProxy stackIntegerValue: 4.
	dstX := interpreterProxy stackIntegerValue: 3.
	dstY := interpreterProxy stackIntegerValue: 2.
	dstW := interpreterProxy stackIntegerValue: 1.
	dstH := interpreterProxy stackIntegerValue: 0.

	interpreterProxy success: (srcX >= 0) & (srcY >= 0).
	interpreterProxy success: (srcX + (2 * dstW)) <= inW.
	interpreterProxy success: (srcY + (2 * dstH)) <= inH.
	interpreterProxy success: (dstX >= 0) & (dstY >= 0).
	interpreterProxy success: (dstX + dstW) <= outW.
	interpreterProxy success: (dstY + dstH) <= outH.
	interpreterProxy failed ifTrue: [^ nil].

	0 to: dstH - 1 do: [:y |
		srcIndex := (inW * (srcY + (2 * y))) + srcX.
		dstIndex := (outW * (dstY + y)) + dstX.
		0 to: dstW - 1 do: [:x |
			p1 := in at: srcIndex.
			p2 := in at: srcIndex + inW + 1.

			r := (((p1 bitAnd: 16rFF0000) + (p2 bitAnd: 16rFF0000)) bitShift: -1) bitAnd: 16rFF0000.
			g := (((p1 bitAnd: 16rFF00) + (p2 bitAnd: 16rFF00)) bitShift: -1) bitAnd: 16rFF00.
			b := ((p1 bitAnd: 16rFF) + (p2 bitAnd: 16rFF)) bitShift: -1.

			"store combined RGB into target bitmap"
			out at: dstIndex put: (r bitOr: (g bitOr: b)).

			srcIndex := srcIndex + 2.
			dstIndex := dstIndex + 1]].

	interpreterProxy pop: 12.  "pop args, leave rcvr on stack"
	^ 0

]

{ #category : #'hsv filters' }
ScratchPlugin >> primitiveHueShift [

	| inOop outOop shift in sz out pix r g b max min brightness saturation hue |
	<export: true>
	<var: 'in' declareC: 'unsigned int *in'>
	<var: 'out' declareC: 'unsigned int *out'>

	inOop := interpreterProxy stackValue: 2.
	outOop := interpreterProxy stackValue: 1.
	shift := interpreterProxy stackIntegerValue: 0.
	in := self checkedUnsignedIntPtrOf: inOop.
	sz := interpreterProxy stSizeOf: inOop.
	out := self checkedUnsignedIntPtrOf: outOop.
	interpreterProxy success: ((interpreterProxy stSizeOf: outOop) = sz).
	interpreterProxy failed ifTrue: [^ nil].

	0 to: sz - 1 do: [:i |
		pix := (in at: i) bitAnd: 16rFFFFFF.
		pix = 0 ifFalse: [  "skip pixel values of 0 (transparent)"
			r := (pix bitShift: -16) bitAnd: 16rFF.
			g := (pix bitShift: -8) bitAnd: 16rFF.
			b := pix bitAnd: 16rFF.

			"find min and max color components"
			max := min := r.
			g > max ifTrue: [max := g].
			b > max ifTrue: [max := b].
			g < min ifTrue: [min := g].
			b < min ifTrue: [min := b].

			"find current brightness (v) and  saturation with range 0 to 1000"
			brightness := (max * 1000) // 255.
			max = 0 ifTrue: [saturation := 0] ifFalse: [saturation := ((max - min) * 1000) // max].

			brightness < 110 ifTrue: [					"force black to a very dark, saturated gray"
				brightness := 110. saturation := 1000].	
			saturation < 90 ifTrue: [saturation := 90].		"force a small color change on grays"
			((brightness = 110) | (saturation = 90))		"tint all blacks and grays the same"
				ifTrue: [hue := 0]
				ifFalse: [hue := self hueFromR: r G: g B: b min: min max: max].

			hue := (hue + shift + 360000000) \\ 360.  "compute new hue"
			self bitmap: out at: i putH: hue s: saturation v: brightness]].

	interpreterProxy pop: 3.  "pop args, leave rcvr on stack"
	^ 0

]

{ #category : #'bilinear interpolation' }
ScratchPlugin >> primitiveInterpolate [

	| inOop xFixed yFixed width in sz result |
	<export: true>
	<var: 'in' declareC: 'unsigned int *in'>

	inOop := interpreterProxy stackValue: 3.
	width := interpreterProxy stackIntegerValue: 2.
	xFixed := interpreterProxy stackIntegerValue: 1.
	yFixed := interpreterProxy stackIntegerValue: 0.
	in := self checkedUnsignedIntPtrOf: inOop.
	sz := interpreterProxy stSizeOf: inOop.
	interpreterProxy failed ifTrue: [^ nil].

	result := self interpolatedFrom: in x: xFixed y: yFixed width: width height: sz // width.

	interpreterProxy pop: 5.  "pop args and rcvr"
	interpreterProxy pushInteger: result.
	^ 0

]

{ #category : #'os functions' }
ScratchPlugin >> primitiveIsHidden [
	"Answer true if the file or folder with the given path should be hidden from the user. On Windows, this is the value of the 'hidden' file property."

	| pathOop src count fullPath result |
	<export: true>
	<var: 'fullPath' declareC: 'char fullPath[1000]'>
	<var: 'src' type: #'char *'>

	pathOop := interpreterProxy stackValue: 0.

	interpreterProxy success: (interpreterProxy isBytes: pathOop).

	interpreterProxy failed ifTrue: [^ 0].

	src := self cCoerce: (interpreterProxy firstIndexableField: pathOop) to: #'char *'.
	count := interpreterProxy stSizeOf: pathOop.
	count >= 1000 ifTrue: [interpreterProxy success: false. ^ 0].
	0 to: count - 1 do: [:i | fullPath at: i put: (src at: i)].
	fullPath at: count put: 0.

	result := self IsFileOrFolderHidden: fullPath.

	interpreterProxy pop: 2.  "pop arg and rcvr"
	interpreterProxy pushBool: result ~= 0.  "push result"
	^ 0
]

{ #category : #'os functions' }
ScratchPlugin >> primitiveOpenURL [
	"Open a web browser on the given URL."

	| urlStr src urlOop count |
	<export: true>
	<var: 'urlStr' declareC: 'char urlStr[2000]'>
	<var: 'src' type: #'char *'>

	urlOop := interpreterProxy stackValue: 0.

	interpreterProxy success: (interpreterProxy isBytes: urlOop).

	interpreterProxy failed ifTrue: [^ 0].

	src := self cCoerce: (interpreterProxy firstIndexableField: urlOop) to: #'char *'.
	count := interpreterProxy stSizeOf: urlOop.
	count >= 2000 ifTrue: [interpreterProxy success: false. ^ 0].
	0 to: count - 1 do: [:i | urlStr at: i put: (src at: i)].
	urlStr at: count put: 0.

	self OpenURL: urlStr.

	interpreterProxy pop: 1.  "pop arg, leave rcvr on stack"
	^ 0
]

{ #category : #'hsv filters' }
ScratchPlugin >> primitiveSaturationShift [

	| inOop outOop shift in sz out pix r g b max min brightness saturation hue |
	<export: true>
	<var: 'in' declareC: 'unsigned int *in'>
	<var: 'out' declareC: 'unsigned int *out'>

	inOop := interpreterProxy stackValue: 2.
	outOop := interpreterProxy stackValue: 1.
	shift := interpreterProxy stackIntegerValue: 0.
	in := self checkedUnsignedIntPtrOf: inOop.
	sz := interpreterProxy stSizeOf: inOop.
	out := self checkedUnsignedIntPtrOf: outOop.
	interpreterProxy success: ((interpreterProxy stSizeOf: outOop) = sz).
	interpreterProxy failed ifTrue: [^ nil].

	0 to: sz - 1 do: [:i |
		pix := (in at: i) bitAnd: 16rFFFFFF.
		pix < 2 ifFalse: [  "skip pixel values of 0 (transparent) and 1 (black)"
			r := (pix bitShift: -16) bitAnd: 16rFF.
			g := (pix bitShift: -8) bitAnd: 16rFF.
			b := pix bitAnd: 16rFF.

			"find min and max color components"
			max := min := r.
			g > max ifTrue: [max := g].
			b > max ifTrue: [max := b].
			g < min ifTrue: [min := g].
			b < min ifTrue: [min := b].

			"find current brightness (v) and  saturation with range 0 to 1000"
			brightness := (max * 1000) // 255.
			max = 0 ifTrue: [saturation := 0] ifFalse: [saturation := ((max - min) * 1000) // max].

			saturation > 0 ifTrue: [  "do nothing if pixel is unsaturated (gray)"
				hue := self hueFromR: r G: g B: b min: min max: max.

				"compute new saturation"
				saturation := saturation + (shift * 10).
				saturation > 1000 ifTrue: [saturation := 1000].
				saturation < 0 ifTrue: [saturation := 0].
				self bitmap: out at: i putH: hue s: saturation v: brightness]]].

	interpreterProxy pop: 3.  "pop args, leave rcvr on stack"
	^ 0

]

{ #category : #scaling }
ScratchPlugin >> primitiveScale [
	"Scale using bilinear interpolation."
	"This version isn't really able to do much with full ARGB based images; the A channel will be ignored and only fully transparent pixels will be treated as transparent. The output pixel will be either fully transparent or fully opaque."

	| inOop inW inH outOop outW outH in out inX inY xIncr yIncr outPix w1 w2 w3 w4 t p1 p2 p3 p4 tWeight |
	<export: true>
	<var: 'in' declareC: 'int *in'>
	<var: 'out' declareC: 'int *out'>

	inOop := interpreterProxy stackValue: 5.
	inW := interpreterProxy stackIntegerValue: 4.
	inH := interpreterProxy stackIntegerValue: 3.
	outOop := interpreterProxy stackValue: 2.
	outW := interpreterProxy stackIntegerValue: 1.
	outH := interpreterProxy stackIntegerValue: 0.

	interpreterProxy success: (interpreterProxy stSizeOf: inOop) = (inW * inH).
	interpreterProxy success: (interpreterProxy stSizeOf: outOop) = (outW * outH).
	in := self checkedUnsignedIntPtrOf: inOop.
	out := self checkedUnsignedIntPtrOf: outOop.
	interpreterProxy failed ifTrue: [^ nil].

	inX := inY := 0.					"source x and y, scaled by 1024"
	xIncr := (inW * 1024) // outW.	"source x increment, scaled by 1024"
	yIncr := (inH * 1024) // outH.		"source y increment, scaled by 1024"

	0 to: (outH - 1) do: [:outY |
		inX := 0.
		0 to: (outW - 1) do: [:outX |
			"compute weights, scaled by 2^20"
			w1 := (1024 - (inX bitAnd: 1023))	* (1024 - (inY bitAnd: 1023)).
			w2 := (inX bitAnd: 1023)			* (1024 - (inY bitAnd: 1023)).
			w3 := (1024 - (inX bitAnd: 1023))	* (inY bitAnd: 1023).
			w4 := (inX bitAnd: 1023)			* (inY bitAnd: 1023).

			"get source pixels"
			t := ((inY >> 10) * inW) + (inX >> 10).
			p1 := in at: t.
			((inX >> 10) < (inW - 1)) ifTrue: [p2 := in at: t + 1] ifFalse: [p2 := p1].
			(inY >> 10) < (inH - 1) ifTrue: [t := t + inW].  "next row"
			p3 := in at: t.
			((inX >> 10) < (inW - 1)) ifTrue: [p4 := in at: t + 1] ifFalse: [p4 := p3].

			"deal with transparent pixels"
			"Note as above - only transparent not translucent"
			tWeight := 0.
			p1 = 0 ifTrue: [p1 := p2. tWeight := tWeight + w1].
			p2 = 0 ifTrue: [p2 := p1. tWeight := tWeight + w2].
			p3 = 0 ifTrue: [p3 := p4. tWeight := tWeight + w3].
			p4 = 0 ifTrue: [p4 := p3. tWeight := tWeight + w4].
			p1 = 0 ifTrue: [p1 := p3. p2 := p4].  "both top pixels were transparent; use bottom row"
			p3 = 0 ifTrue: [p3 := p1. p4 := p2].  "both bottom pixels were transparent; use top row"

			outPix := 0.
			tWeight < 500000 ifTrue: [  "compute an (opaque) output pixel if less than 50% transparent"
				t := (w1 * ((p1 >> 16) bitAnd: 255)) + (w2 * ((p2 >> 16) bitAnd: 255)) + (w3 * ((p3 >> 16) bitAnd: 255)) + (w4 * ((p4 >> 16) bitAnd: 255)).
				outPix := ((t >> 20) bitAnd: 255) << 16.
				t := (w1 * ((p1 >> 8) bitAnd: 255)) + (w2 * ((p2 >> 8) bitAnd: 255)) + (w3 * ((p3 >> 8) bitAnd: 255)) + (w4 * ((p4 >> 8) bitAnd: 255)).
				outPix := outPix bitOr: (((t >> 20) bitAnd: 255) << 8).
				t := (w1 * (p1 bitAnd: 255)) + (w2 * (p2 bitAnd: 255)) + (w3 * (p3 bitAnd: 255)) + (w4 * (p4 bitAnd: 255)).
				outPix := outPix bitOr: ((t >> 20) bitAnd: 255).
				"If the result is black, remember to make it Squeak-standard-fake-black"
				outPix = 0 ifTrue: [outPix := 1].
				"add the A channel to make it really opaque"
				outPix := outPix bitOr: 16rFF000000].

			out at: (outY * outW) + outX put: outPix.
			inX := inX + xIncr].
		inY := inY + yIncr].

	interpreterProxy pop: 6.  "pop args, leave rcvr on stack"
	^ 0

]

{ #category : #'os functions' }
ScratchPlugin >> primitiveSetUnicodePasteBuffer [
	"Set the Mac OS X Unicode paste buffer."

	| utf16 strOop count |
	<export: true>
	<var: 'utf16' declareC: 'short *utf16'>

	strOop := interpreterProxy stackValue: 0.

	interpreterProxy success: (interpreterProxy isBytes: strOop).

	interpreterProxy failed ifTrue: [^ 0].

	utf16 := self cCoerce: (interpreterProxy firstIndexableField: strOop) to: #'short *'.
	count := interpreterProxy stSizeOf: strOop.

	self SetUnicodePaste: utf16 Buffer: count.

	interpreterProxy pop: 1.  "pop arg, leave rcvr on stack"
	^ 0
]

{ #category : #'os functions' }
ScratchPlugin >> primitiveSetWindowTitle [
	"Set the title of the Scratch window."

	| titleStr src titleOop count |
	<export: true>
	<var: 'titleStr' declareC: 'char titleStr[1000]'>
	<var: 'src' type: #'char *'>

	titleOop := interpreterProxy stackValue: 0.

	interpreterProxy success: (interpreterProxy isBytes: titleOop).

	interpreterProxy failed ifTrue: [^ 0].

	src := self cCoerce: (interpreterProxy firstIndexableField: titleOop) to: #'char *'.
	count := interpreterProxy stSizeOf: titleOop.
	count >= 1000 ifTrue: [interpreterProxy success: false. ^ 0].
	0 to: count - 1 do: [:i | titleStr at: i put: (src at: i)].
	titleStr at: count put: 0.

	self SetScratchWindowTitle: titleStr.

	interpreterProxy pop: 1.  "pop arg, leave rcvr on stack"
	^ 0
]

{ #category : #'os functions' }
ScratchPlugin >> primitiveShortToLongPath [
	"On Windows, convert a short file/path name into a long one. Fail on other platforms."

	| shortPath longPath ptr shortPathOop result count resultOop |
	<export: true>
	<var: 'shortPath' declareC: 'char shortPath[1000]'>
	<var: 'longPath' declareC: 'char longPath[1000]'>
	<var: 'ptr' type: #'char *'>

	shortPathOop := interpreterProxy stackValue: 0.

	(interpreterProxy isBytes: shortPathOop) ifFalse:
		[interpreterProxy success: false. ^ 0].

	ptr := self cCoerce: (interpreterProxy firstIndexableField: shortPathOop) to: #'char *'.
	count := interpreterProxy stSizeOf: shortPathOop.
	count >= 1000 ifTrue: [interpreterProxy success: false. ^ 0].
	0 to: count - 1 do: [:i | shortPath at: i put: (ptr at: i)].
	shortPath at: count put: 0.

	result := self cCode: 'WinShortToLongPath(shortPath, longPath, 1000)'.
	result = -1 ifTrue: [interpreterProxy success: false. ^ 0].

	count := self strlen: longPath.
	resultOop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: count.
	ptr := self cCoerce: (interpreterProxy firstIndexableField: resultOop) to: #'char *'.
	0 to: count - 1 do: [:i | ptr at: i put: (longPath at: i)].

	interpreterProxy pop: 2 thenPush: resultOop.  "pop arg and rcvr, push result"
	^ 0
]

{ #category : #'other filters' }
ScratchPlugin >> primitiveWaterRipples1 [
 
	| in out aArray bArray ripply temp pix dx dy dist inOop outOop width allPix aArOop bArOop height t1 blops x y power val val2 dx2 dy2 newLoc |
	<export: true>
	<var: 'in' declareC: 'unsigned int *in'>
	<var: 'out' declareC: 'unsigned int *out'>
	<var: 'aArray' declareC: 'double *aArray'>
	<var: 'bArray' declareC: 'double *bArray'>
	<var: 'ripply' declareC: 'int ripply'>
	<var: 'temp' declareC: 'double temp'>
	<var: 'pix' declareC: 'unsigned int pix'>
	<var: 'dist' declareC: 'double dist'>
	<var: 'dx2' declareC: 'double dx2'>
	<var: 'dy2' declareC: 'double dy2'>

	inOop := interpreterProxy stackValue: 5.
	outOop := interpreterProxy stackValue: 4.
	width := interpreterProxy stackIntegerValue: 3.
	in := self checkedUnsignedIntPtrOf: inOop.
	out := self checkedUnsignedIntPtrOf: outOop.
	allPix := interpreterProxy stSizeOf: inOop.
	ripply := interpreterProxy stackIntegerValue: 2.
	aArOop := interpreterProxy stackValue: 1.
	bArOop := interpreterProxy stackValue: 0.
	aArray := self checkedFloatPtrOf: aArOop.
	bArray := self checkedFloatPtrOf: bArOop.
	interpreterProxy success: ((interpreterProxy stSizeOf: outOop) = allPix).
	interpreterProxy failed ifTrue: [^ nil].

	height := allPix // width.

	t1 := self cCode: 'rand()'.
	blops := t1 \\ ripply -1.
	0 to: blops /2-1 do: [:t |
		t1 := self cCode: 'rand()'.
		x := t1 \\ width.
		t1 := self cCode: 'rand()'.
		y := t1 \\ height.
		t1 := self cCode: 'rand()'.
		power := t1 \\ 8.
		-4 to: 4 do: [:g |
			-4 to: 4 do: [:h |
				dist := ((g*g) + (h*h)) asFloat.
				((dist < 25) and: [dist > 0]) ifTrue: [
						dx := (x + g) asInteger.
						dy := (y + h) asInteger.
						((dx >0) and: [(dy>0) and: [(dy < height) and: [dx < width]]]) ifTrue: [
							aArray at: ((dy)*width + dx) put: (power *(1.0 asFloat -(dist/(25.0 asFloat))) asFloat).
						].
					].
				].
			].
		].
	
		1 to: width -2 do: [:f |
			1 to: height -2 do: [:d |
			val := (d)*width + f.
			aArray at: val put: (((
				(bArray at: (val+1)) + (bArray at: (val-1)) + (bArray at: (val + width)) + (bArray at: (val - width)) +
				((bArray at: (val -1 -width))/2) + ((bArray at: (val-1+width))/2) + ((bArray at: (val+1-width))/2) + ((bArray at: (val+1+width))/2)) /4) - (aArray at: (val))).
			aArray at: (val) put: ((aArray at: (val))*(0.9 asFloat)).
			].
		].
	
		"temp := bArray.
		bArray := aArray.
		aArray := temp."
		0 to: width*height do: [:q |
			temp := bArray at: q.
			bArray at: q put: (aArray at: q).
			aArray at: q put: temp.
		].

		0 to: height-1 do: [:j |
			0 to: width-1 do: [:i |
				((i > 1) and: [(i<(width-1)) and: [(j>1) and: [(j<(height-1))]]]) ifTrue: [
					val2 := (j)*width + i.
					dx2 := ((((aArray at: (val2)) - (aArray at: (val2-1))) + ((aArray at: (val2+1)) - (aArray at: (val2)))) *64) asFloat.
					dy2 := ((((aArray at: (val2)) - (aArray at: (val2-width))) + ((aArray at: (val2+width)) - (aArray at: (val2)))) /64) asFloat.
					(dx2 < -2) ifTrue: [dx2 := -2].
					(dx2 >  2) ifTrue: [dx2 :=  2].
					(dy2 < -2) ifTrue: [dy2 := -2].
					(dy2 >  2) ifTrue: [dy2 :=  2].
					newLoc := ((j+dy2)*width + (i+dx2)) asInteger.
					((newLoc < (width*height)) and: [newLoc >=0]) ifTrue: [
						pix := in at: newLoc]
					ifFalse: [
						pix := in at: (i +(j*width)) ].
				]
				ifFalse: [
					pix := in at: (i +(j*width)) ].
			out at: (i + (j*width)) put: pix.
		]].

	interpreterProxy pop: 6.  "pop args, leave rcvr on stack"
	^ 0

]

{ #category : #'other filters' }
ScratchPlugin >> primitiveWhirl [

	| inOop outOop width degrees in out sz height centerX centerY radius scaleX scaleY whirlRadians radiusSquared dx dy d factor ang sina cosa pix |
	<export: true>
	<var: 'in' declareC: 'unsigned int *in'>
	<var: 'out' declareC: 'unsigned int *out'>
	<var: 'scaleX' declareC: 'double scaleX'>
	<var: 'scaleY' declareC: 'double scaleY'>
	<var: 'whirlRadians' declareC: 'double whirlRadians'>
	<var: 'radiusSquared' declareC: 'double radiusSquared'>
	<var: 'dx' declareC: 'double dx'>
	<var: 'dy' declareC: 'double dy'>
	<var: 'd' declareC: 'double d'>
	<var: 'factor' declareC: 'double factor'>
	<var: 'ang' declareC: 'double ang'>
	<var: 'sina' declareC: 'double sina'>
	<var: 'cosa' declareC: 'double cosa'>

	inOop := interpreterProxy stackValue: 3.
	outOop := interpreterProxy stackValue: 2.
	width := interpreterProxy stackIntegerValue: 1.
	degrees := interpreterProxy stackIntegerValue: 0.
	in := self checkedUnsignedIntPtrOf: inOop.
	out := self checkedUnsignedIntPtrOf: outOop.
	sz := interpreterProxy stSizeOf: inOop.
	interpreterProxy success: ((interpreterProxy stSizeOf: outOop) = sz).
	interpreterProxy failed ifTrue: [^ nil].

	"calculate height, center, scales, radius, whirlRadians, and radiusSquared"
	height := sz // width.
	centerX := width // 2.
	centerY := height // 2.
	centerX < centerY
		ifTrue: [
			radius := centerX.
			scaleX := centerY asFloat / centerX. 
			scaleY := 1.0]
		ifFalse: [
			radius := centerY.
			scaleX := 1.0.
			centerY < centerX
				ifTrue: [scaleY := centerX asFloat / centerY]
				ifFalse: [scaleY := 1.0]].
	whirlRadians := (-3.141592653589793 * degrees) / 180.0.
	radiusSquared := (radius * radius) asFloat.

	0 to: width - 1 do: [:x |
		0 to: height - 1 do: [:y |
			dx := scaleX * (x - centerX) asFloat.
			dy := scaleY * (y - centerY) asFloat.
			d := (dx * dx) + (dy * dy).
			d < radiusSquared ifTrue: [  "inside the whirl circle"
				factor := 1.0 - (d sqrt / radius).
				ang := whirlRadians * (factor * factor).
				sina := ang sin.
				cosa := ang cos.
				pix := self interpolatedFrom: in
					x: (1024.0 * ((((cosa * dx) - (sina * dy)) / scaleX) + centerX)) asInteger
					y: (1024.0 * ((((sina * dx) + (cosa * dy)) / scaleY) + centerY)) asInteger
					width: width
					height: height.
				out at: ((width * y) + x "for Squeak: + 1") put: pix]]].

	interpreterProxy pop: 4.  "pop args, leave rcvr on stack"
	^ 0

]
