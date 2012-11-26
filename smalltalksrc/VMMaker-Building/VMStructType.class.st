"
I am an absract superclass for classes which map to simple structs in C,  Right now I merely serve to organize all the struct types.  I would like to arrange that generated assignment accessors answer their argument to correspond with field assignment in C, but createInstVarAccessors is implemented by the browser not by ClassDescription.
"
Class {
	#name : #VMStructType,
	#superclass : #VMClass,
	#classVars : [
		'StructTypeNameCache'
	],
	#category : #'VMMaker-Support'
}

{ #category : #'accessing class hierarchy' }
VMStructType class >> addSubclass: aSubclass [
	self voidStructTypeCache.
	^super addSubclass: aSubclass
]

{ #category : #'code generation' }
VMStructType class >> checkGenerateFieldAccessors: fieldSpecs bitPosition: firstBitPosition in: surrogateClass [
	| bitPosition alignedByteSize |
	bitPosition := firstBitPosition.
	fieldSpecs do:
		[:spec| | code |
		"If the accessor is already defined in a superclass don't redefine it in the subclass.
		 We assume it is correctly defined in the superclass."
		(spec first ~= #unused
		 and: [(surrogateClass whichClassIncludesSelector: spec first asSymbol)
				ifNil: [true]
				ifNotNil: [:implementingClass|
						self assert: (implementingClass inheritsFrom: Object).
						implementingClass == surrogateClass]]) ifTrue:
			[code := self getter: spec first
						 bitPosition: bitPosition
						 bitWidth: spec second
						 bool: (spec at: 3 ifAbsent: []) = #Boolean.
			 code ~= (surrogateClass sourceCodeAt: spec first asSymbol ifAbsent: ['']) asString ifTrue:
				[surrogateClass compile: code classified: #accessing].
			 code := self setter: spec first
						 bitPosition: bitPosition
						 bitWidth: spec second
						 bool: (spec at: 3 ifAbsent: []) = #Boolean.
			 code ~= (surrogateClass sourceCodeAt: (spec first, ':') asSymbol ifAbsent: ['']) asString ifTrue:
				[surrogateClass compile: code classified: #accessing]].
		bitPosition := bitPosition + spec second].
	alignedByteSize := bitPosition / 8.
	self assert: alignedByteSize isInteger.
	alignedByteSize ~= surrogateClass alignedByteSize ifTrue:
		[surrogateClass class
			compile: 'alignedByteSize'
					, (String with: Character cr with: Character tab with: $^)
					, alignedByteSize printString
			classified: #accessing]
]

{ #category : #'code generation' }
VMStructType class >> checkGenerateSurrogate: class bytesPerWord: bytesPerWord [
	self checkGenerateFieldAccessors: (self fieldAccessorsForBytesPerWord: bytesPerWord)
		bitPosition: 0
		in: class

	"CogBlockMethod checkGenerateSurrogate: CogBlockMethodSurrogate32 bytesPerWord: 4.
	 CogMethod checkGenerateSurrogate: CogMethodSurrogate32 bytesPerWord: 4"
]

{ #category : #'code generation' }
VMStructType class >> fieldAccessorsForBytesPerWord: bytesPerWord [
	| fieldSpecs |
	fieldSpecs := OrderedCollection new.
	self instVarNamesAndTypesForTranslationDo:
		[:ivn :typeTuple| | index replacement |
		(index := typeTuple indexOf: #BytesPerWord ifAbsent: 0) > 0
			ifTrue:
				[(typeTuple at: index + 1) = bytesPerWord ifTrue:
					[replacement := typeTuple copyReplaceFrom: index to: index + 1 with: #().
					 replacement size = 1 ifTrue:
						[replacement := replacement first].
					fieldSpecs add: { ivn. replacement }]]
			ifFalse:
				[fieldSpecs add: { ivn. typeTuple }]].
	^fieldSpecs collect:
		[:tuple|
			[:ivn :typeTuple|
			{ ('*unused*' match: ivn) ifTrue: [#unused] ifFalse: [ivn].
			  (typeTuple isArray and: ['unsigned' = typeTuple first])
				ifTrue:
					[Integer readFrom: (typeTuple last readStream skipTo: $:; skipSeparators)]
				ifFalse:
					[typeTuple caseOf: {
								['unsigned char']	->	[8].
								['unsigned short']	->	[16].
								['unsigned int']		->	[32].
								['unsigned long']	->	[bytesPerWord * 8].
								['sqInt']				->	[bytesPerWord * 8].
								['usqInt']			->	[bytesPerWord * 8] }].
			(typeTuple isArray and: [typeTuple size >= 3 and: [typeTuple second = #Boolean]]) ifTrue:
				[#Boolean] }] valueWithArguments: tuple]

	"#(4 8) collect: [:bpw| (CogBlockMethod fieldAccessorsForBytesPerWord: bpw) asArray]"
	"#(4 8) collect: [:bpw| (CogMethod fieldAccessorsForBytesPerWord: bpw) asArray]"
]

{ #category : #translation }
VMStructType class >> filteredInstVarNames [
	"Eliminate the obvious simulation-only inst vars"
	^self allInstVarNames reject:
		[:n|
		Cogit isNonArgumentImplicitReceiverVariableName: n]
]

{ #category : #'code generation' }
VMStructType class >> getter: getter bitPosition: bitPosition bitWidth: bitWidth bool: isBool [
	^String streamContents:
		[:s| | startByte endByte alignedPowerOf2 shift bool |
		startByte := bitPosition // 8.
		endByte := bitPosition + bitWidth - 1 // 8.
		shift := bitPosition \\ 8.
		alignedPowerOf2 := (#(8 16 32 64) includes: bitWidth) and: [shift = 0].
		s nextPutAll: getter; crtab: 1; nextPut: $^.
		isBool ifTrue:
			[s nextPut: $(].
		alignedPowerOf2 ifFalse:
			[s nextPut: $(].
		shift ~= 0 ifTrue:
			[s nextPut: $(].
		s nextPutAll: 'memory unsigned';
		   nextPutAll: (#('Byte' 'Short' 'Long' 'Long')
							at: endByte - startByte + 1
							ifAbsent: ['LongLong']);
		  nextPutAll: 'At: address + '; print: startByte + 1.
		shift ~= 0 ifTrue:
			[s nextPutAll: ') bitShift: -'; print: shift].
		alignedPowerOf2 ifFalse:
			[s nextPutAll: ') bitAnd: '; nextPutAll: ((1 << bitWidth) - 1) hex].
		isBool ifTrue:
			[s nextPutAll: ') ~= 0']]
]

{ #category : #translation }
VMStructType class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #translation }
VMStructType class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a struct of this type."

	self subclassResponsibility
]

{ #category : #'accessing class hierarchy' }
VMStructType class >> isAbstract [
	^self == VMStructType
]

{ #category : #translation }
VMStructType class >> isAccessor: aSelector [
	"Answer if aSelector is simply an accessor method for one of our fields."
	^(self instVarIndexFor: (aSelector copyWithout: $:) ifAbsent: [0]) > 0
]

{ #category : #translation }
VMStructType class >> isNonArgumentImplicitReceiverVariableName: aString [
	^Cogit isNonArgumentImplicitReceiverVariableName: aString
]

{ #category : #translation }
VMStructType class >> isStructClass [
	^true
]

{ #category : #translation }
VMStructType class >> isTypePointerToStruct: type [
	| index |
	StructTypeNameCache ifNil:
		[StructTypeNameCache := Set new.
		 self allSubclassesDo:
			[:sc| StructTypeNameCache add: sc name; add: sc structTypeName ]].
	^type notNil
	  and: [(index := type indexOf: $*) > 0
	  and: [StructTypeNameCache anySatisfy:
			[:structType|
			(type beginsWith: structType)
			and: [index > structType size]]]]
]

{ #category : #translation }
VMStructType class >> needsTypeTag [
	self instVarNamesAndTypesForTranslationDo:
		[:ivn :type|
		((type isArray ifTrue: [type] ifFalse: [{type}]) anySatisfy:
			[:str|
			str isString
			and: [str includesSubString: self structTagName]]) ifTrue:
				[^true]].
	^false

	"VMStructType allSubclasses select: [:sc| sc needsTypeTag]"
]

{ #category : #translation }
VMStructType class >> prepareToBeAddedToCodeGenerator: aCodeGen [
	aCodeGen
		removeVariable: 'coInterpreter';
		removeVariable: 'cogit';
		removeVariable: 'objectMemory';
		removeVariable: 'objectRepresentation' ifAbsent: []
]

{ #category : #translation }
VMStructType class >> printTypedefOn: aStream [
	aStream nextPutAll: 'typedef struct '.
	self needsTypeTag ifTrue:
		[aStream nextPutAll: self structTagName; space].
	aStream nextPut: ${; cr.
	self instVarNamesAndTypesForTranslationDo:
		[:ivn :typeArg| | type index |
		type := typeArg.
		(index := type indexOf: #BytesPerWord ifAbsent: 0) > 0 ifTrue:
			[type := (type at: index + 1) = BytesPerWord ifTrue:
						[type := type copyReplaceFrom: index to: index + 1 with: #().
						 type size = 1 ifTrue: [type first] ifFalse: [type]]].
		type ifNotNil:
			[type isArray
				ifTrue:
					[aStream tab: 1.
					aStream nextPutAll: type first.
					(type first last isSeparator or: [type first last = $*]) ifFalse:
						[aStream tab: 2].
					aStream nextPutAll: ivn.
					 type last first = $: ifTrue:
						[aStream space].
					 aStream
						nextPutAll: type last;
						nextPut: $;;
						cr]
				ifFalse:
					[aStream tab: 1.
					aStream nextPutAll: type.
					(type last isSeparator or: [type last = $*]) ifFalse:
						[aStream tab: 1].
					 aStream
						nextPutAll: ivn;
						nextPut: $;;
						cr]]].
	aStream
		nextPutAll: ' } ';
		nextPutAll: self structTypeName;
		nextPut: $;;
		cr.
	self name ~= self structTypeName ifTrue:
		[aStream cr; nextPutAll: '#define '; nextPutAll: self name; space; nextPutAll: self structTypeName; cr].
	aStream flush
]

{ #category : #'accessing class hierarchy' }
VMStructType class >> removeSubclass: aSubclass [
	self voidStructTypeCache.
	^super removeSubclass: aSubclass
]

{ #category : #'class name' }
VMStructType class >> rename: aString [
	self voidStructTypeCache.
	^super rename: aString
]

{ #category : #translation }
VMStructType class >> returnTypeForAccessor: aSelector [
	| varName deStructTag |
	varName := aSelector copyWithout: $:.
	deStructTag := [:decl| decl copyReplaceAll: 'struct ', self structTagName with: self structTypeName].
	self instVarNamesAndTypesForTranslationDo:
		[:var :typeSpec|
		var = varName ifTrue:
			[^typeSpec isArray
				ifTrue: [(deStructTag value: typeSpec first), ' ', typeSpec last]
				ifFalse: [deStructTag value: typeSpec]]].
	^nil


	"InterpreterStackPage returnTypeForAccessor: #nextPage:"
]

{ #category : #'code generation' }
VMStructType class >> setter: getter bitPosition: bitPosition bitWidth: bitWidth bool: isBool [
	^String streamContents:
		[:s| | startByte endByte shift alignedPowerOf2 accessor mask expr |
		startByte := bitPosition // 8.
		endByte := bitPosition + bitWidth - 1 // 8.
		shift := bitPosition \\ 8.
		alignedPowerOf2 := (#(8 16 32 64) includes: bitWidth) and: [shift = 0].
		accessor := 'unsigned'
					, (#('Byte' 'Short' 'Long' 'Long')
							at: endByte - startByte + 1
							ifAbsent: ['LongLong'])
					, 'At: address + '.
		mask := #(16rFF 16rFFFF 16rFFFFFFFF 16rFFFFFFFF)
						at: endByte - startByte + 1
						ifAbsent: [(2 raisedTo: 64) - 1].
		s nextPutAll: getter; nextPutAll: ': aValue'.
		(isBool or: [alignedPowerOf2]) ifFalse:
			[s crtab: 1; nextPutAll: 'self assert: (aValue between: 0 and: '; nextPutAll:  ((1 << bitWidth) - 1) hex; nextPutAll: ').'].
		s crtab: 1.
		alignedPowerOf2 ifTrue:
			[s nextPut: $^].
		s nextPutAll: 'memory';
		  crtab: 2; nextPutAll: accessor; print: startByte + 1;
		  crtab: 2; nextPutAll: 'put: '.
		isBool ifTrue:
			[s nextPut: $(].
		alignedPowerOf2 ifFalse:
			[s nextPutAll: '((memory '; nextPutAll: accessor; print: startByte + 1;
			    nextPutAll: ') bitAnd: '; nextPutAll: (mask - ((1 << bitWidth - 1) << shift)) hex;
			    nextPutAll: ') + '].
		expr := isBool ifTrue: ['(aValue ifTrue: [1] ifFalse: [0])'] ifFalse: ['aValue'].
		shift = 0
			ifTrue:
				[s nextPutAll: expr]
			ifFalse:
				[s nextPut: $(; nextPutAll: expr; nextPutAll: ' bitShift: '; print: shift; nextPut: $)].
		isBool ifTrue:
			[s nextPut: $)].
		alignedPowerOf2 ifFalse:
			[s nextPut: $.; crtab: 1; nextPutAll: '^aValue']]
]

{ #category : #accessors }
VMStructType class >> settersReturnValue [
	"Override to get the browser to generate setters that return the
	 value set, which matches C semantics for field assignments."
	^true
]

{ #category : #translation }
VMStructType class >> structTagName [
	^'_', self structTypeName
]

{ #category : #translation }
VMStructType class >> structTargetKindForDeclaration: decl [
	StructTypeNameCache ifNil:
		[StructTypeNameCache := Set new.
		 self allSubclassesDo:
			[:sc| StructTypeNameCache add: sc name; add: sc structTypeName ]].
	^(decl notNil
	   and: [(StructTypeNameCache includes: decl)
			or: [StructTypeNameCache anySatisfy:
					[:structType|
					(decl beginsWith: structType)
					and: [(decl indexOf: $* ifAbsent: [decl indexOf: Character space]) > structType size]]]]) ifTrue:
		[(decl indexOf: $*) > 0
			ifTrue: [#pointer]
			ifFalse: [#struct]]
]

{ #category : #translation }
VMStructType class >> structTargetKindForType: type [
	| index |
	StructTypeNameCache ifNil:
		[StructTypeNameCache := Set new.
		 self allSubclassesDo:
			[:sc| StructTypeNameCache add: sc name; add: sc structTypeName ]].
	^(type notNil
	   and: [StructTypeNameCache anySatisfy:
			[:structType|
			(type beginsWith: structType)
			and: [index > structType size]]]) ifTrue:
		[(index := type indexOf: $*) > 0
			ifTrue: [#pointer]
			ifFalse: [#struct]]
]

{ #category : #translation }
VMStructType class >> structTypeName [
	"Provide the typedef name.  Subclases can override."
	^self name
]

{ #category : #translation }
VMStructType class >> typeForSelf [
	"Answer the type to give self if appropriate, or nil if not."
	^self structTypeName, ' *'
]

{ #category : #translation }
VMStructType class >> typedef [
	^String streamContents: [:s| self printTypedefOn: s]
]

{ #category : #translation }
VMStructType class >> voidStructTypeCache [
	StructTypeNameCache := nil
]

{ #category : #printing }
VMStructType >> printOn: aStream [
	"A hook to allow subclasses to print their state if useful."
	<doNotGenerate>
	super printOn: aStream.
	self printStateOn: aStream
]

{ #category : #printing }
VMStructType >> printStateOn: aStream [
	"A hook to allow subclasses to print their state if useful."
	<doNotGenerate>
	^self
]
