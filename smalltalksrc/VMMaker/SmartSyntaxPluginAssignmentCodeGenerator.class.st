Class {
	#name : #SmartSyntaxPluginAssignmentCodeGenerator,
	#superclass : #SmartSyntaxPluginPrologCodeGenerator,
	#category : #'VMMaker-SmartSyntaxPlugins'
}

{ #category : #'coercing support' }
SmartSyntaxPluginAssignmentCodeGenerator >> assign: variableName coerceTo: cType from: stackIndex [
	^String streamContents:
		[:aStream |
		 aStream
			nextPutAll: variableName;
			nextPutAll: ' := self cCoerce: (interpreterProxy firstIndexableField:';
			nextPutAll: (self stackAccessorFor: stackIndex);
			nextPutAll: ') to: ';
			store: cType]
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asBooleanValueFrom: stackIndex [
	^(aString, ' := '), (self loadAs: #booleanValueOf: from: stackIndex)
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asCharPtrFrom: stackIndex [
	^self assign: aString coerceTo: #'char *' from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asCharPtrFrom: stackIndex andThen: valBlock [
	^self assign: aString coerceTo: #'char *' from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asFloatValueFrom: anInteger [
	^String streamContents:
		[:aStream |
		aStream
			nextPutAll: aString;
			nextPutAll: ' := interpreterProxy stackFloatValue: ';
			print: anInteger]
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asIntPtrFrom: stackIndex [
	^self assign: aString coerceTo: #'int *' from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asIntPtrFrom: stackIndex andThen: valBlock [
	^self assign: aString coerceTo: #'int *' from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asIntegerValueFrom: anInteger [
	^String streamContents:
		[:aStream |
		aStream
			nextPutAll: aString;
			nextPutAll: ' := interpreterProxy stackIntegerValue: ';
			print: anInteger]
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asKindOf: aClass from: stackIndex [
	^self ccgLoad: aBlock expr: aString asRawOopFrom: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asKindOfIntegerFrom: stackIndex [
	^self ccgLoad: aBlock expr: aString asRawOopFrom: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asMemberOf: aClass from: stackIndex [
	^self ccgLoad: aBlock expr: aString asRawOopFrom: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asMemberOfLargeNegativeIntegerFrom: stackIndex [
	^self ccgLoad: aBlock expr: aString asRawOopFrom: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asMemberOfLargePositiveIntegerFrom: stackIndex [
	^self ccgLoad: aBlock expr: aString asRawOopFrom: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asNonIntegerValueFrom: stackIndex [
	^self ccgLoad: aBlock expr: aString asRawOopFrom: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asOopPtrFrom: stackIndex [
	^self assign: aString coerceTo: 'sqInt *' from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asOopPtrFrom: stackIndex andThen: valBlock [
	^self assign: aString coerceTo: 'sqInt *' from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asRawOopFrom: stackIndex [
	^aString, ' := ', (self stackAccessorFor: stackIndex)
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asUnsignedPtrFrom: stackIndex andThen: valBlock [
	^self assign: aString coerceTo: 'unsigned *' from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asUnsignedValueFrom: stackIndex [
	^String streamContents:
		[:aStream |
		aStream
			nextPutAll: aString;
			nextPutAll: ' := (interpreterProxy bytesPerOop = 4';
			crtab: 2;
			nextPutAll: 'ifTrue: [interpreterProxy positive32BitValueOf:';
			nextPutAll: (self stackAccessorFor: stackIndex);
			nextPutAll: '] ifFalse: [interpreterProxy positive64BitValueOf:';
			nextPutAll: (self stackAccessorFor: stackIndex);
			nextPutAll: '])']
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asWBCharPtrFrom: stackIndex [
	^self assign: aString coerceTo: #'char *' from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asWBFloatPtrFrom: stackIndex [
	^self assign: aString coerceTo: #'float *' from: stackIndex
]

{ #category : #coercing }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgLoad: aBlock expr: aString asWBIntPtrFrom: stackIndex [
	^self assign: aString coerceTo: #'int *' from: stackIndex
]

{ #category : #'coercing support' }
SmartSyntaxPluginAssignmentCodeGenerator >> ccgValBlock: aString [
	"ignore"
]

{ #category : #'coercing support' }
SmartSyntaxPluginAssignmentCodeGenerator >> loadAs: coercionSelector from: stackIndex [

	^String streamContents:
		[:aStream |
		 aStream
			nextPutAll: 'interpreterProxy ';
			nextPutAll: coercionSelector;
			nextPutAll: (self stackAccessorFor: stackIndex)]
]
