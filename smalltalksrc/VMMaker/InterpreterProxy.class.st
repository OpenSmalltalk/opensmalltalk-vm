"
This class should provide the definition of what interpreter support plugins need and can have access to. Note that the proxy related files platforms - Cross - vm - sqVirtualMachine.[ch] are kept under the Sourceforge tree.
The main use of the class is to support the vm simulator
"
Class {
	#name : #InterpreterProxy,
	#superclass : #Object,
	#instVars : [
		'successFlag',
		'remapBuffer',
		'stack',
		'method',
		'argumentCount',
		'bb'
	],
	#category : #'VMMaker-InterpreterSimulation'
}

{ #category : #private }
InterpreterProxy class >> validateProxyImplementation: anInterpreter [ 
	"InterpreterProxy validateProxyImplementation: Interpreter"
	"InterpreterProxy validateProxyImplementation: DynamicInterpreter"

	| proxyClass catList |
	proxyClass _ InterpreterProxy.
	catList _ proxyClass organization categories copy asOrderedCollection.
	catList remove: 'initialize' ifAbsent:[].
	catList remove: 'private' ifAbsent:[].
	catList do:[:categ|
		(proxyClass organization listAtCategoryNamed: categ) do:[:selector|
			(anInterpreter canUnderstand: selector) 
				ifFalse:
					[self notifyWithLabel: selector, ' is not implemented in ', anInterpreter name]]]
]

{ #category : #'object access' }
InterpreterProxy >> argumentCountOf: methodPointer [
	^methodPointer numArgs
]

{ #category : #'object access' }
InterpreterProxy >> arrayValueOf: oop [
	self returnTypeC: 'void *'.
	self success: (self isWordsOrBytes: oop).
	^CArrayAccessor on: oop.
]

{ #category : #other }
InterpreterProxy >> become: array1 with: array2 [
	array1 elementsExchangeIdentityWith: array2
]

{ #category : #converting }
InterpreterProxy >> booleanValueOf: obj [
	obj == true ifTrue:[^true].
	obj == false ifTrue:[^false].
	self primitiveFail.
	^nil
]

{ #category : #private }
InterpreterProxy >> byteAt: accessor [
	^accessor byteAt: 0
]

{ #category : #private }
InterpreterProxy >> byteAt: accessor put: value [
	^accessor byteAt: 0 put: value
]

{ #category : #'object access' }
InterpreterProxy >> byteSizeOf: oop [
	"Return the size of the receiver in bytes"
	^oop class isBytes
		ifTrue:[(self slotSizeOf: oop)]
		ifFalse:[(self slotSizeOf: oop) * 4]
]

{ #category : #other }
InterpreterProxy >> byteSwapped: w [
	"Return the given integer with its bytes in the reverse order."

	^ ((w bitShift: -24) bitAnd: 16rFF) +
	  ((w bitShift: -8) bitAnd: 16rFF00) +
	  ((w bitShift: 8) bitAnd: 16rFF0000) +
	  ((w bitShift: 24) bitAnd: 16rFF000000)

]

{ #category : #'special objects' }
InterpreterProxy >> characterTable [
	^Character characterTable
]

{ #category : #converting }
InterpreterProxy >> checkedIntegerValueOf: intOop [
	(self isIntegerObject: intOop)
		ifTrue:[^self integerValueOf: intOop]
		ifFalse:[self primitiveFail. ^0].
]

{ #category : #'special classes' }
InterpreterProxy >> classArray [
	^Array
]

{ #category : #'special classes' }
InterpreterProxy >> classBitmap [
	^Bitmap
]

{ #category : #'special classes' }
InterpreterProxy >> classByteArray [
	^ByteArray
]

{ #category : #'special classes' }
InterpreterProxy >> classCharacter [
	^Character
]

{ #category : #'FFI support' }
InterpreterProxy >> classExternalAddress [
	^Smalltalk at: #ExternalAddress ifAbsent:[nil]
]

{ #category : #'FFI support' }
InterpreterProxy >> classExternalData [
	^Smalltalk at: #ExternalData ifAbsent:[nil]
]

{ #category : #'FFI support' }
InterpreterProxy >> classExternalFunction [
	^Smalltalk at: #ExternalFunction ifAbsent:[nil]
]

{ #category : #'FFI support' }
InterpreterProxy >> classExternalLibrary [
	^Smalltalk at: #ExternalLibrary ifAbsent:[nil]
]

{ #category : #'FFI support' }
InterpreterProxy >> classExternalStructure [
	^Smalltalk at: #ExternalStructure ifAbsent:[nil]
]

{ #category : #'special classes' }
InterpreterProxy >> classFloat [
	^Float
]

{ #category : #'special classes' }
InterpreterProxy >> classLargeNegativeInteger [
	^LargeNegativeInteger
]

{ #category : #'special classes' }
InterpreterProxy >> classLargePositiveInteger [
	^LargePositiveInteger
]

{ #category : #'special classes' }
InterpreterProxy >> classPoint [
	^Point
]

{ #category : #'special classes' }
InterpreterProxy >> classSemaphore [
	^Semaphore
]

{ #category : #'special classes' }
InterpreterProxy >> classSmallInteger [
	^SmallInteger
]

{ #category : #'special classes' }
InterpreterProxy >> classString [
	^String
]

{ #category : #'instance creation' }
InterpreterProxy >> clone: oop [
	^oop clone
]

{ #category : #'BitBlt support' }
InterpreterProxy >> copyBits [
	bb copyBits.
]

{ #category : #'BitBlt support' }
InterpreterProxy >> copyBitsFrom: leftX to: rightX at: yValue [
	bb copyBitsFrom: leftX to: rightX at: yValue.
]

{ #category : #'special objects' }
InterpreterProxy >> displayObject [
	^Display
]

{ #category : #other }
InterpreterProxy >> failed [
	^successFlag not
]

{ #category : #'special objects' }
InterpreterProxy >> falseObject [
	^false
]

{ #category : #'object access' }
InterpreterProxy >> fetchArray: fieldIndex ofObject: objectPointer [
	"Fetch the instance variable at the given index of the given object. Return the address of first indexable field of resulting array object, or fail if the instance variable does not contain an indexable bytes or words object."
	"Note: May be called by translated primitive code."

	| arrayOop |
	self returnTypeC: 'void *'.
	arrayOop _ self fetchPointer: fieldIndex ofObject: objectPointer.
	^ self arrayValueOf: arrayOop

]

{ #category : #'object access' }
InterpreterProxy >> fetchClassOf: oop [
	^oop class
]

{ #category : #'object access' }
InterpreterProxy >> fetchFloat: fieldIndex ofObject: objectPointer [
	"Fetch the instance variable at the given index of the given object. Return the C double precision floating point value of that instance variable, or fail if it is not a Float."
	"Note: May be called by translated primitive code."

	| floatOop |
	self returnTypeC: 'double'.
	floatOop _ self fetchPointer: fieldIndex ofObject: objectPointer.
	^ self floatValueOf: floatOop
]

{ #category : #'object access' }
InterpreterProxy >> fetchInteger: fieldIndex ofObject: objectPointer [
	"Note: May be called by translated primitive code."

	| intOop |
	self inline: false.
	intOop _ self fetchPointer: fieldIndex ofObject: objectPointer.
	^self checkedIntegerValueOf: intOop
]

{ #category : #private }
InterpreterProxy >> fetchIntegerOrTruncFloat: fieldIndex ofObject: objectPointer [
	"Support for BitBlt simulation only"
	| intOrFloat |
	intOrFloat _ self fetchPointer: fieldIndex ofObject: objectPointer.
	(self isIntegerObject: intOrFloat) ifTrue: [^ self integerValueOf: intOrFloat].
	intOrFloat isFloat ifTrue:[^intOrFloat truncated].
	^self primitiveFail.
]

{ #category : #'object access' }
InterpreterProxy >> fetchPointer: index ofObject: oop [
	^oop instVarAt: index+1
]

{ #category : #'object access' }
InterpreterProxy >> fetchWord: fieldIndex ofObject: oop [
	^oop instVarAt: fieldIndex+1
]

{ #category : #'object access' }
InterpreterProxy >> firstFixedField: oop [
	self returnTypeC:'void *'.
	^CObjectAccessor on: oop
]

{ #category : #'object access' }
InterpreterProxy >> firstIndexableField: oop [
	self returnTypeC:'void *'.
	^CArrayAccessor on: oop
]

{ #category : #converting }
InterpreterProxy >> floatObjectOf: aFloat [
	self var: #aFloat declareC: 'double aFloat'.
	aFloat class == Float ifFalse:[self error:'Not a float object'].
	^aFloat
]

{ #category : #converting }
InterpreterProxy >> floatValueOf: oop [
	self returnTypeC:'double'.
	oop class == Float
		ifTrue:[^oop]
		ifFalse:[self primitiveFail. ^0.0].
]

{ #category : #other }
InterpreterProxy >> fullDisplayUpdate [
	Display display
]

{ #category : #other }
InterpreterProxy >> fullGC [
	Smalltalk garbageCollect.
]

{ #category : #testing }
InterpreterProxy >> includesBehavior: aClass ThatOf: aSuperclass [
	^aClass includesBehavior: aSuperclass
]

{ #category : #other }
InterpreterProxy >> incrementalGC [
	Smalltalk garbageCollectMost.
]

{ #category : #initialize }
InterpreterProxy >> initialize [
	successFlag _ true.
	remapBuffer _ OrderedCollection new.
	stack _ OrderedCollection new.
]

{ #category : #'instance creation' }
InterpreterProxy >> instantiateClass: classPointer indexableSize: size [
	^size = 0 
		ifTrue:[classPointer basicNew]
		ifFalse:[classPointer basicNew: size]
]

{ #category : #converting }
InterpreterProxy >> integerObjectOf: value [
	value class == SmallInteger ifFalse:[self error:'Not a SmallInteger object'].
	^value
]

{ #category : #converting }
InterpreterProxy >> integerValueOf: oop [
	oop class == SmallInteger ifFalse:[self error:'Not a SmallInteger'].
	^oop
]

{ #category : #'FFI support' }
InterpreterProxy >> ioLoadFunction: functionName From: moduleName [
	"Dummy - provided by support code"
	^0
]

{ #category : #'FFI support' }
InterpreterProxy >> ioLoadModule: moduleNameIndex OfLength: moduleLength [
	"Dummy - provided by support code"
	^0
]

{ #category : #'FFI support' }
InterpreterProxy >> ioLoadSymbol: functionNameIndex OfLength: functionLength FromModule: moduleHandle [
	"Dummy - provided by support code"
	^0
]

{ #category : #other }
InterpreterProxy >> ioMicroMSecs [
	^Time millisecondClockValue
]

{ #category : #testing }
InterpreterProxy >> is: oop KindOf: aString [
	"InterpreterProxy new is: 42 KindOf: 'Number'"
	| theClass |
	self var: #aString declareC:'char *aString'.
	theClass _ Smalltalk at: aString asSymbol ifAbsent:[nil].
	^theClass isNil
		ifTrue:[false]
		ifFalse:[^oop isKindOf: theClass]
]

{ #category : #testing }
InterpreterProxy >> is: oop MemberOf: aString [
	"InterpreterProxy new is: 42 MemberOf:'SmallInteger'"
	| theClass |
	self var: #aString declareC:'char *aString'.
	theClass _ Smalltalk at: aString asSymbol ifAbsent:[nil].
	^theClass isNil
		ifTrue:[false]
		ifFalse:[^oop isMemberOf: theClass]
]

{ #category : #testing }
InterpreterProxy >> isArray: oop [
	^(self isIntegerObject: oop) not and:[(oop class format bitAnd: 15) = 2]

]

{ #category : #testing }
InterpreterProxy >> isBytes: oop [
	^oop class isBytes
]

{ #category : #testing }
InterpreterProxy >> isFloatObject: oop [
	^oop class == Float
]

{ #category : #'FFI support' }
InterpreterProxy >> isInMemory: address [
	"Return true if the given address is in ST object memory"
	^true
]

{ #category : #testing }
InterpreterProxy >> isIndexable: oop [
	^oop class isVariable
]

{ #category : #testing }
InterpreterProxy >> isIntegerObject: objectPointer [
	^objectPointer class == SmallInteger
]

{ #category : #testing }
InterpreterProxy >> isIntegerValue: intValue [
	^intValue class == SmallInteger
]

{ #category : #private }
InterpreterProxy >> isInterpreterProxy [
	"Return true since I am not a real Interpreter simulation"
	^true
]

{ #category : #testing }
InterpreterProxy >> isPointers: oop [
	^oop class isPointers
]

{ #category : #testing }
InterpreterProxy >> isWeak: oop [
	^oop class isWeak
]

{ #category : #testing }
InterpreterProxy >> isWords: oop [
	^oop class isPointers not and:[oop class isBytes not]
]

{ #category : #testing }
InterpreterProxy >> isWordsOrBytes: oop [
	^(self isBytes: oop) or:[self isWords: oop]
]

{ #category : #'object access' }
InterpreterProxy >> literal: offset ofMethod: methodPointer [
	^methodPointer literals at: offset+1
]

{ #category : #'object access' }
InterpreterProxy >> literalCountOf: methodPointer [
	^methodPointer numLiterals
]

{ #category : #'BitBlt support' }
InterpreterProxy >> loadBitBltFrom: bbOop [
	bb _ bbOop.
]

{ #category : #initialize }
InterpreterProxy >> loadStackFrom: aContext [
	self push: aContext receiver.
	method _ aContext method.
	argumentCount _ method numArgs.
	1 to: argumentCount do:[:i| self push: (aContext at: i) ].
]

{ #category : #private }
InterpreterProxy >> longAt: accessor [
	^accessor longAt: 0
]

{ #category : #private }
InterpreterProxy >> longAt: accessor put: value [
	^accessor longAt: 0 put: value
]

{ #category : #'instance creation' }
InterpreterProxy >> makePointwithxValue: xValue yValue: yValue [
	(xValue class == SmallInteger and:[yValue class == SmallInteger]) 
		ifFalse:[self error:'Not SmallInteger objects'].
	^xValue@yValue
]

{ #category : #'object access' }
InterpreterProxy >> methodArgumentCount [
	^argumentCount
]

{ #category : #'object access' }
InterpreterProxy >> methodPrimitiveIndex [
	^method primitive
]

{ #category : #'special objects' }
InterpreterProxy >> nilObject [
	^nil
]

{ #category : #'stack access' }
InterpreterProxy >> pop: nItems [
	1 to: nItems do:[:i| stack removeLast].
]

{ #category : #'stack access' }
InterpreterProxy >> pop: nItems thenPush: oop [
	self pop: nItems.
	self push: oop.
]

{ #category : #'instance creation' }
InterpreterProxy >> popRemappableOop [
	^remapBuffer removeLast
]

{ #category : #converting }
InterpreterProxy >> positive32BitIntegerFor: integerValue [
	integerValue isInteger ifFalse:[self error:'Not an Integer object'].
	^integerValue > 0
		ifTrue:[integerValue]
		ifFalse:[ (1 bitShift: 32) + integerValue]
]

{ #category : #converting }
InterpreterProxy >> positive32BitValueOf: oop [
	oop isInteger ifFalse:[self error:'Not an integer object'].
	oop < 0 
		ifTrue:[self primitiveFail. ^0]
		ifFalse:[^oop]
]

{ #category : #converting }
InterpreterProxy >> positive64BitIntegerFor: integerValue [
	integerValue isInteger ifFalse:[self error:'Not an Integer object'].
	^integerValue > 0
		ifTrue:[integerValue]
		ifFalse:[ (1 bitShift: 64) + integerValue]
]

{ #category : #converting }
InterpreterProxy >> positive64BitValueOf: oop [
	oop isInteger ifFalse:[self error:'Not an integer object'].
	oop < 0 
		ifTrue:[self primitiveFail. ^0]
		ifFalse:[^oop]
]

{ #category : #other }
InterpreterProxy >> primitiveFail [
	(self confirm:'A primitive is failing -- Stop simulation?') ifTrue:[self halt].
	successFlag _ false.
]

{ #category : #'object access' }
InterpreterProxy >> primitiveIndexOf: methodPointer [
	^methodPointer primitive
]

{ #category : #'object access' }
InterpreterProxy >> primitiveMethod [
	"Return the method an external primitive was defined in"
	^method
]

{ #category : #'stack access' }
InterpreterProxy >> push: object [
	stack addLast: object
]

{ #category : #'stack access' }
InterpreterProxy >> pushBool: trueOrFalse [
	(trueOrFalse == true or:[trueOrFalse == false]) ifFalse:[self error:'Not a Boolean'].
	self push: trueOrFalse
]

{ #category : #'stack access' }
InterpreterProxy >> pushFloat: f [
	self var: #f declareC: 'double f'.
	f class == Float ifFalse:[^self error:'Not a Float'].
	self push: f.
]

{ #category : #'stack access' }
InterpreterProxy >> pushInteger: integerValue [
	self push: (self integerObjectOf: integerValue).
]

{ #category : #'instance creation' }
InterpreterProxy >> pushRemappableOop: oop [
	remapBuffer addLast: oop
]

{ #category : #other }
InterpreterProxy >> showDisplayBits: aForm Left: l Top: t Right: r Bottom: b [
	aForm == Display ifTrue:[
		Display forceToScreen: (Rectangle left: l right: r top: t bottom: b)].
]

{ #category : #other }
InterpreterProxy >> signalSemaphoreWithIndex: semaIndex [
	((Smalltalk externalObjects) at: semaIndex) signal
]

{ #category : #converting }
InterpreterProxy >> signed32BitIntegerFor: integerValue [
	integerValue isInteger ifFalse:[self error:'Not an Integer object'].
	^integerValue
]

{ #category : #converting }
InterpreterProxy >> signed32BitValueOf: oop [
	oop isInteger ifFalse:[self error:'Not an integer object'].
	^oop
]

{ #category : #converting }
InterpreterProxy >> signed64BitIntegerFor: integerValue [
	integerValue isInteger ifFalse:[self error:'Not an Integer object'].
	^integerValue
]

{ #category : #converting }
InterpreterProxy >> signed64BitValueOf: oop [
	oop isInteger ifFalse:[self error:'Not an integer object'].
	^oop
]

{ #category : #'object access' }
InterpreterProxy >> sizeOfSTArrayFromCPrimitive: cPtr [
	"Note: Only called by translated primitive code."
	self var: #cPtr declareC: 'void *cPtr'.
	^self shouldNotImplement
]

{ #category : #'object access' }
InterpreterProxy >> slotSizeOf: oop [
	"Returns the number of slots in the receiver.
	If the receiver is a byte object, return the number of bytes.
	Otherwise return the number of words."
	^(oop basicSize) + (oop class instSize)
]

{ #category : #'object access' }
InterpreterProxy >> stObject: array at: index [
	^array at: index
]

{ #category : #'object access' }
InterpreterProxy >> stObject: array at: index put: value [
	^array at: index put: value
]

{ #category : #'object access' }
InterpreterProxy >> stSizeOf: oop [
	"Return the number of indexable fields in the receiver"
	^oop basicSize
]

{ #category : #'stack access' }
InterpreterProxy >> stackFloatValue: offset [
	| oop |
	self returnTypeC: 'double'.
	oop _ self stackValue: offset.
	(self isFloatObject: oop) ifFalse: [self primitiveFail. ^0.0].
	^oop
]

{ #category : #'stack access' }
InterpreterProxy >> stackIntegerValue: offset [
	| oop |
	oop _ self stackValue: offset.
	(self isIntegerObject: oop) ifFalse: [self primitiveFail. ^0].
	^oop
]

{ #category : #'stack access' }
InterpreterProxy >> stackObjectValue: offset [
	| oop |
	oop _ self stackValue: offset.
	(self isIntegerObject: oop) ifTrue: [self primitiveFail. ^ nil].
	^oop
]

{ #category : #'stack access' }
InterpreterProxy >> stackValue: offset [
	^stack at: stack size - offset.
]

{ #category : #'object access' }
InterpreterProxy >> storeInteger: index ofObject: oop withValue: integer [
	(self isIntegerValue: integer) 
		ifTrue:[^self storePointer: index ofObject: oop withValue: integer]
		ifFalse:[^self primitiveFail]
]

{ #category : #'object access' }
InterpreterProxy >> storePointer: index ofObject: oop withValue: valuePointer [
	^oop instVarAt: index+1 put: valuePointer
]

{ #category : #other }
InterpreterProxy >> success: aBoolean [
	successFlag not ifTrue:[^self].
	successFlag _ successFlag and:[aBoolean].
	successFlag not ifTrue:[
		(self confirm:'A primitive is failing -- Stop simulation?') ifTrue:[self halt]].
]

{ #category : #other }
InterpreterProxy >> superclassOf: classPointer [
	^classPointer superclass
]

{ #category : #'special objects' }
InterpreterProxy >> trueObject [
	^true
]
