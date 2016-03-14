"
This plugin implements the functionality of
	CRStrokeFeature>>sameClassAbsoluteStrokeDistance: aCRFeature forReference: aBoolean
. This means that changes there should be mirrored here!

GeniePlugin>>majorNO should be in sync with version number of Genie.

"
Class {
	#name : #GeniePlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #'check installed plugin' }
GeniePlugin class >> majorNO [
	| no |
	^ (no := self versionNO) ifNotNil: [no // 1000]

]

{ #category : #'check installed plugin' }
GeniePlugin class >> minorNO [
	| no |
	^ (no := self versionNO) ifNotNil: [no \\ 1000]

]

{ #category : #translation }
GeniePlugin class >> moduleNameAndVersion [
	"Answer the receiver's module name and version info that is used for the plugin's C code. The default is to append the code generation date, but any useful text is ok (keep it short)"

	^ self moduleName, Character space asString, self version, Character space asString, Date today asString
]

{ #category : #translation }
GeniePlugin class >> version [
	"Answer the receiver's version info as String."
	"Somewhat a hack, but calling class methods from inst methods doesn't result in usable C-code..."

	| inst |
	inst := self new.
	^ 'v', inst majorNO asString, '.', inst minorNO asString
]

{ #category : #'check installed plugin' }
GeniePlugin class >> versionNO [
	<primitive: 'primVersionNO' module: 'GeniePlugin'>
	^ nil

]

{ #category : #'check installed plugin' }
GeniePlugin class >> versionString [
	^ 'v', (self versionNO / 1000 asFloat) asString
]

{ #category : #computation }
GeniePlugin >> cSquaredDistanceFrom: aPoint to: bPoint [
	"arguments are pointer to ints paired as x,y coordinates of points"
	| aPointX aPointY bPointX bPointY xDiff yDiff |
	<var: #aPoint type: #'int *'>
	<var: #bPoint type: #'int *'>
	aPointX := aPoint at: 0.
	aPointY := aPoint at: 1.
	bPointX := bPoint at: 0.
	bPointY := bPoint at: 1.

	xDiff := bPointX - aPointX.
	yDiff := bPointY - aPointY.
	^ xDiff * xDiff + (yDiff * yDiff)
]

{ #category : #computation }
GeniePlugin >> cSubstAngleFactorFrom: startDegreeNumber to: endDegreeNumber [ 
	| absDiff |
	absDiff := (endDegreeNumber - startDegreeNumber) abs.
	absDiff > 180 ifTrue: [absDiff := 360 - absDiff].
	^ absDiff * absDiff bitShift: -6
]

{ #category : #version }
GeniePlugin >> majorNO [
	^ 2
]

{ #category : #version }
GeniePlugin >> minorNO [
	^ 0
]

{ #category : #computation }
GeniePlugin >> primSameClassAbsoluteStrokeDistanceMyPoints: myPointsOop otherPoints: otherPointsOop myVectors: myVectorsOop otherVectors: otherVectorsOop mySquaredLengths: mySquaredLengthsOop otherSquaredLengths: otherSquaredLengthsOop myAngles: myAnglesOop otherAngles: otherAnglesOop maxSizeAndReferenceFlag: maxSizeAndRefFlag rowBase: rowBaseOop rowInsertRemove: rowInsertRemoveOop rowInsertRemoveCount: rowInsertRemoveCountOop [
	| base insertRemove jLimiT substBase insert remove subst removeBase insertBase insertRemoveCount additionalMultiInsertRemoveCost myPoints otherPoints myVectors otherVectors rowInsertRemoveCount mySquaredLengths otherSquaredLengths myAngles otherAngles rowBase rowInsertRemove otherPointsSize myVectorsSize otherVectorsSize otherSquaredLengthsSize rowBaseSize maxDist maxSize forReference jM1 iM1 iM1T2 jM1T2 |
	<var: #myPoints type: #'int *'>
	<var: #otherPoints type: #'int *'>
	<var: #myVectors type: #'int *'>
	<var: #otherVectors type: #'int *'>
	<var: #mySquaredLengths type: #'int *'>
	<var: #otherSquaredLengths type: #'int *'>
	<var: #myAngles type: #'int *'>
	<var: #otherAngles type: #'int *'>
	<var: #rowBase type: #'int *'>
	<var: #rowInsertRemove type: #'int *'>
	<var: #rowInsertRemoveCount type: #'int *'>
	self
		primitive: 'primSameClassAbsoluteStrokeDistanceMyPoints_otherPoints_myVectors_otherVectors_mySquaredLengths_otherSquaredLengths_myAngles_otherAngles_maxSizeAndReferenceFlag_rowBase_rowInsertRemove_rowInsertRemoveCount'
		parameters: #(#Oop #Oop #Oop #Oop #Oop #Oop #Oop #Oop #SmallInteger #Oop #Oop #Oop)
		receiver: #Oop.
	interpreterProxy failed
		ifTrue: [self msg: 'failed 1'.
			^ nil].

	interpreterProxy success: (interpreterProxy isWords: myPointsOop)
			& (interpreterProxy isWords: otherPointsOop)
			& (interpreterProxy isWords: myVectorsOop)
			& (interpreterProxy isWords: otherVectorsOop)
			& (interpreterProxy isWords: mySquaredLengthsOop)
			& (interpreterProxy isWords: otherSquaredLengthsOop)
			& (interpreterProxy isWords: myAnglesOop)
			& (interpreterProxy isWords: otherAnglesOop)
			& (interpreterProxy isWords: rowBaseOop)
			& (interpreterProxy isWords: rowInsertRemoveOop)
			& (interpreterProxy isWords: rowInsertRemoveCountOop).
	interpreterProxy failed
		ifTrue: [self msg: 'failed 2'.
			^ nil].
	interpreterProxy success: (interpreterProxy is: myPointsOop MemberOf: 'PointArray')
			& (interpreterProxy is: otherPointsOop MemberOf: 'PointArray').
	interpreterProxy failed
		ifTrue: [self msg: 'failed 3'.
			^ nil].
	myPoints := interpreterProxy firstIndexableField: myPointsOop.
	otherPoints := interpreterProxy firstIndexableField: otherPointsOop.
	myVectors := interpreterProxy firstIndexableField: myVectorsOop.
	otherVectors := interpreterProxy firstIndexableField: otherVectorsOop.
	mySquaredLengths := interpreterProxy firstIndexableField: mySquaredLengthsOop.
	otherSquaredLengths := interpreterProxy firstIndexableField: otherSquaredLengthsOop.
	myAngles := interpreterProxy firstIndexableField: myAnglesOop.
	otherAngles := interpreterProxy firstIndexableField: otherAnglesOop.
	rowBase := interpreterProxy firstIndexableField: rowBaseOop.
	rowInsertRemove := interpreterProxy firstIndexableField: rowInsertRemoveOop.
	rowInsertRemoveCount := interpreterProxy firstIndexableField: rowInsertRemoveCountOop.
	"Note: myPointsSize and mySquaredLengthsSize variables eliminated to reduce
	method temporary variable count for closure-enabled images"
	"PointArrays"
	"myPointsSize := (interpreterProxy stSizeOf: myPointsOop) bitShift: -1."
	otherPointsSize := (interpreterProxy stSizeOf: otherPointsOop) bitShift: -1.
	myVectorsSize := (interpreterProxy stSizeOf: myVectorsOop) bitShift: -1.
	otherVectorsSize := (interpreterProxy stSizeOf: otherVectorsOop) bitShift: -1.
	"IntegerArrays"
	"mySquaredLengthsSize := interpreterProxy stSizeOf: mySquaredLengthsOop."
	otherSquaredLengthsSize := interpreterProxy stSizeOf: otherSquaredLengthsOop.
	rowBaseSize := interpreterProxy stSizeOf: rowBaseOop.

	interpreterProxy success: rowBaseSize
			= (interpreterProxy stSizeOf: rowInsertRemoveOop) & (rowBaseSize
				= (interpreterProxy stSizeOf: rowInsertRemoveCountOop)) & (rowBaseSize > otherVectorsSize).
	interpreterProxy failed
		ifTrue: [self msg: 'failed 4'.
			^ nil].
	interpreterProxy success: (interpreterProxy stSizeOf: mySquaredLengthsOop) >= (myVectorsSize - 1)
				& (((interpreterProxy stSizeOf: myPointsOop) bitShift: -1) >= myVectorsSize)
				& (otherSquaredLengthsSize >= (otherVectorsSize - 1))
				& (otherPointsSize >= otherVectorsSize) & ((interpreterProxy stSizeOf: myAnglesOop)
				>= (myVectorsSize - 1)) & ((interpreterProxy stSizeOf: otherAnglesOop)
				>= (otherVectorsSize - 1)).
	interpreterProxy failed
		ifTrue: [self msg: 'failed 5'.
			^ nil].

	"maxSizeAndRefFlag contains the maxium feature size (pixel) and also indicates whether
	the reference flag (boolean) is set. Therefore the maximum size is moved to the left 
	and the reference flag is stored in the LSB.
	Note: This is necessary to avoid more than 12 primitive parameters"
	forReference := maxSizeAndRefFlag bitAnd: 1.
	maxSize := maxSizeAndRefFlag bitShift: -1.
	maxDist := 1 bitShift: 29.
	forReference
		ifTrue: [additionalMultiInsertRemoveCost := 0]
		ifFalse: [additionalMultiInsertRemoveCost := maxSize * maxSize bitShift: -10].
	"C indices!!"
	rowBase
		at: 0
		put: 0.
	rowInsertRemove
		at: 0
		put: 0.
	rowInsertRemoveCount
		at: 0
		put: 2.
	insertRemove := 0 - additionalMultiInsertRemoveCost.
	jLimiT := otherVectorsSize.
	otherPointsSize >= (jLimiT - 1) & (otherSquaredLengthsSize >= (jLimiT - 1))
		ifFalse: [^ interpreterProxy primitiveFail].
	1
		to: jLimiT
		do: [:j |
			jM1 := j - 1.
			insertRemove := insertRemove + ((otherSquaredLengths at: jM1)
							+ (self
									cSquaredDistanceFrom: (otherPoints + (jM1 bitShift: 1))
									to: myPoints) bitShift: -7) + additionalMultiInsertRemoveCost.
			rowInsertRemove
				at: j
				put: insertRemove.
			rowBase
				at: j
				put: insertRemove * j.
			rowInsertRemoveCount
				at: j
				put: j + 1].
	insertRemove := (rowInsertRemove at: 0)
				- additionalMultiInsertRemoveCost.
	1
		to: myVectorsSize
		do: [:i |
			iM1 := i - 1.
			iM1T2 := iM1 bitShift: 1.
			substBase := rowBase at: 0.
			insertRemove := insertRemove + ((mySquaredLengths at: iM1)
							+ (self
									cSquaredDistanceFrom: (myPoints + iM1T2)
									to: otherPoints) bitShift: -7) + additionalMultiInsertRemoveCost.
			rowInsertRemove
				at: 0
				put: insertRemove.
			rowBase
				at: 0
				put: insertRemove * i.
			rowInsertRemoveCount
				at: 0
				put: i + 1.
			jLimiT := otherVectorsSize.
			1
				to: jLimiT
				do: [:j |
					jM1 := j - 1.
					jM1T2 := jM1 bitShift: 1.
					removeBase := rowBase at: j.
					insertBase := rowBase at: jM1.
					remove := (mySquaredLengths at: iM1)
								+ (self
										cSquaredDistanceFrom: (myPoints + iM1T2)
										to: (otherPoints + (j bitShift: 1))) bitShift: -7.
					(insertRemove := rowInsertRemove at: j) = 0
						ifTrue: [removeBase := removeBase + remove]
						ifFalse: [removeBase := removeBase + insertRemove + (remove
											* (rowInsertRemoveCount at: j)).
							remove := remove + insertRemove].
					insert := (otherSquaredLengths at: jM1)
								+ (self
										cSquaredDistanceFrom: (otherPoints + jM1T2)
										to: (myPoints + (i bitShift: 1))) bitShift: -7.
					(insertRemove := rowInsertRemove at: jM1) = 0
						ifTrue: [insertBase := insertBase + insert]
						ifFalse: [insertBase := insertBase + insertRemove + (insert
											* (rowInsertRemoveCount at: jM1)).
							insert := insert + insertRemove].
					forReference
						ifTrue: [substBase := maxDist]
						ifFalse: [subst := (self
										cSquaredDistanceFrom: (otherVectors + jM1T2)
										to: (myVectors + iM1T2))
										+ (self
												cSquaredDistanceFrom: (otherPoints + jM1T2)
												to: (myPoints + iM1T2)) * (16
											+ (self
													cSubstAngleFactorFrom: (otherAngles at: jM1)
													to: (myAngles at: iM1))) bitShift: -11.
							substBase := substBase + subst].
					(substBase <= removeBase
							and: [substBase <= insertBase])
						ifTrue: [base := substBase.
							insertRemove := 0.
							insertRemoveCount := 1]
						ifFalse: [removeBase <= insertBase
								ifTrue: [base := removeBase.
									insertRemove := remove + additionalMultiInsertRemoveCost.
									insertRemoveCount := (rowInsertRemoveCount at: j)
												+ 1]
								ifFalse: [base := insertBase.
									insertRemove := insert + additionalMultiInsertRemoveCost.
									insertRemoveCount := (rowInsertRemoveCount at: jM1)
												+ 1]].
					substBase := rowBase at: j.
					rowBase
						at: j
						put: (base min: maxDist).
					rowInsertRemove
						at: j
						put: (insertRemove min: maxDist).
					rowInsertRemoveCount
						at: j
						put: insertRemoveCount].
			insertRemove := rowInsertRemove at: 0].
	^ base asOop: SmallInteger

]

{ #category : #version }
GeniePlugin >> primVersionNO [
	"majorNO * 1000 + minorNO"
	self
		primitive: 'primVersionNO'
		parameters: #()
		receiver: #Oop.
	^ (self majorNO * 1000 + self minorNO) asOop: SmallInteger
]
