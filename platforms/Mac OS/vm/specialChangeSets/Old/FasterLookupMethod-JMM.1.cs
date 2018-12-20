'From Squeak3.6beta of ''4 July 2003'' [latest update: #5373] on 6 August 2003 at 12:05:30 pm'!
"Change Set:		FasterLookupMethod-JMM
Date:			6 August 2003
Author:			johnmci@smalltalkconsulting.com

Change lookupMethodInDictionary: to force nilObj into a local register for compare, and don't compare the selector to nilObj (the failure case) before comparing to the wanted selector. This usually removes an extra if statement check since the failure case is 1/20 of the found case"!


!Interpreter methodsFor: 'message sending' stamp: 'JMM 8/5/2003 22:14'!
lookupMethodInDictionary: dictionary
	"This method lookup tolerates integers as Dictionary keys to support
	execution of images in which Symbols have been compacted out"
 	| length index mask wrapAround nextSelector methodArray nilOops|
	self inline: true.
	nilOops _ nilObj.
	length _ self fetchWordLengthOf: dictionary.
	mask _ length - SelectorStart - 1.
	(self isIntegerObject: messageSelector)
		ifTrue:
		[index _ (mask bitAnd: (self integerValueOf: messageSelector)) + SelectorStart]
		ifFalse:
		[index _ (mask bitAnd: (self hashBitsOf: messageSelector)) + SelectorStart].
	"It is assumed that there are some nils in this dictionary, and search will
	stop when one is encountered.  However, if there are no nils, then wrapAround
	will be detected the second time the loop gets to the end of the table."
	wrapAround _ false.
	[true] whileTrue:
		[nextSelector _ self fetchPointer: index
					ofObject: dictionary.
		nextSelector=messageSelector ifTrue: [
			methodArray _ self fetchPointer: MethodArrayIndex
							ofObject: dictionary.
			newMethod _ self fetchPointer:  index - SelectorStart
						ofObject: methodArray.
			"Check if newMethod is a CompiledMethod."
			(self formatOf: newMethod) >= 12 ifTrue:[
				primitiveIndex _ self primitiveIndexOf: newMethod.
				primitiveIndex > MaxPrimitiveIndex ifTrue:[
					"If primitiveIndex is out of range, set to zero before putting in cache.
					This is equiv to primFail, and avoids the need to check on every send."
					primitiveIndex _ 0.
				].
			] ifFalse:[
				"indicate that this is no compiled method"
				primitiveIndex := 248.
			].
			^true
		].
		nextSelector=nilOops ifTrue: [^false].
		index _ index + 1.
		index = length
			ifTrue: [wrapAround ifTrue: [^false].
				wrapAround _ true.
				index _ SelectorStart]]! !

