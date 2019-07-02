Class {
	#name : #SmartSyntaxPluginValidationCodeGenerator,
	#superclass : #SmartSyntaxPluginPrologCodeGenerator,
	#category : #'VMMaker-SmartSyntaxPlugins'
}

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asBooleanValueFrom: stackIndex [
	^self loadAs: #isBooleanObject: from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asCharPtrFrom: stackIndex [
	^self loadAs: #isWordsOrBytes: from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asCharPtrFrom: stackIndex andThen: validationString [
	^validationString, (self stackAccessorFor: stackIndex)
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asFloatValueFrom: stackIndex [
	^self loadAs: #isFloatObject: from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asIntPtrFrom: stackIndex [
	^self loadAs: #isWordsOrBytes: from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asIntPtrFrom: stackIndex andThen: validationString [
	^validationString, (self stackAccessorFor: stackIndex)
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asIntegerValueFrom: stackIndex [
	^self loadAs: #isIntegerObject: from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asKindOf: aClass from: stackIndex [
	^self loadAs: #is:KindOf: class: aClass from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asKindOfIntegerFrom: stackIndex [
	^self loadAs: #isKindOfInteger: from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asMemberOf: aClass from: stackIndex [
	^self loadAs: #is:MemberOf: class: aClass from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asMemberOfLargeNegativeIntegerFrom: stackIndex [
	^self loadAs: #isLargeNegativeIntegerObject: from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asMemberOfLargePositiveIntegerFrom: stackIndex [
	^self loadAs: #isLargePositiveIntegerObject: from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asNonIntegerValueFrom: stackIndex [
	^self loadAs: #isNonImmediate: from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asOopPtrFrom: stackIndex [
	^self loadAs: #isNonImmediate: from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asOopPtrFrom: stackIndex andThen: validationString [
	^String streamContents:
		[:s|
		 s	nextPut: $(;
			nextPutAll: (self loadAs: #isPointers: from: stackIndex);
			nextPutAll: ') and: [';
			nextPutAll: validationString;
			nextPutAll: (self stackAccessorFor: stackIndex);
			nextPut: $]]
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asRawOopFrom: anInteger [
	^nil
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asUnsignedPtrFrom: stackIndex andThen: validationString [
	^validationString, (self stackAccessorFor: stackIndex)
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asUnsignedValueFrom: 	stackIndex [
	^self loadAs: #isPositiveMachineIntegerObject: from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asWBCharPtrFrom: stackIndex [
	^self loadAs: #isWordsOrBytes: from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asWBFloatPtrFrom: stackIndex [
	^self loadAs: #isWordsOrBytes: from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginValidationCodeGenerator >> ccgLoad: aBlock expr: aString asWBIntPtrFrom: stackIndex [
	^self loadAs: #isWordsOrBytes: from: stackIndex
]

{ #category : #'coercing support' }
SmartSyntaxPluginValidationCodeGenerator >> ccgValBlock: aString [
	^'interpreterProxy ', (aString, ': ')
]

{ #category : #'coercing support' }
SmartSyntaxPluginValidationCodeGenerator >> loadAs: classMembershipSelector class: aClass from: stackIndex [

	^String streamContents:
		[:aStream | | keywords |
		 keywords := classMembershipSelector keywords.
		 aStream
			nextPutAll: 'interpreterProxy ';
			nextPutAll: keywords first;
			nextPutAll: (self stackAccessorFor: stackIndex);
			space;
			nextPutAll: keywords last;
			nextPutAll:	' ''';
			nextPutAll:	aClass asString;
			nextPutAll: '''']
]

{ #category : #'coercing support' }
SmartSyntaxPluginValidationCodeGenerator >> loadAs: classMembershipSelector from: stackIndex [

	^String streamContents:
		[:aStream |
		 aStream
			nextPutAll: 'interpreterProxy ';
			nextPutAll: classMembershipSelector;
			nextPutAll: (self stackAccessorFor: stackIndex)]
]
