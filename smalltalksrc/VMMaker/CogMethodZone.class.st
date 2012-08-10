"
I am a simple allocator/deallocator for the native code zone.  I also manage the youngReferers list, which contains methods that may refer to one or more young objects, and the openPICList which is a linked list of all open PICs in the zone.
"
Class {
	#name : #CogMethodZone,
	#superclass : #CogClass,
	#instVars : [
		'youngReferrers',
		'openPICList',
		'mzFreeStart',
		'baseAddress',
		'limitAddress',
		'methodBytesFreedSinceLastCompaction',
		'coInterpreter',
		'objectRepresentation',
		'cogit',
		'objectMemory'
	],
	#pools : [
		'CogMethodConstants',
		'VMBasicConstants'
	],
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
CogMethodZone class >> declareCVarsIn: aCCodeGenerator [
	aCCodeGenerator
		removeVariable: 'coInterpreter';
		removeVariable: 'objectRepresentation'.
	
	self declareC: #(youngReferrers mzFreeStart baseAddress limitAddress)
			as: #usqInt
				in: aCCodeGenerator
]

{ #category : #translation }
CogMethodZone class >> implicitReturnTypeFor: aSelector [
	"Answer the return type for methods that don't have an explicit return."
	^#void
]

{ #category : #translation }
CogMethodZone class >> isNonArgumentImplicitReceiverVariableName: aString [
	^#('self' 'coInterpreter' 'objectRepresentation') includes: aString
]

{ #category : #translation }
CogMethodZone class >> typeForSelf [
	^#implicit
]

{ #category : #accessing }
CogMethodZone >> addToOpenPICList: anOpenPIC [
	<var: #anOpenPIC type: #'CogMethod *'>
	self assert: anOpenPIC cmType = CMOpenPIC.
	self assert: (openPICList == nil
				or: [openPICList cmType = CMOpenPIC]).
	anOpenPIC nextOpenPIC: openPICList asUnsignedInteger.
	openPICList := anOpenPIC
]

{ #category : #'young referers' }
CogMethodZone >> addToYoungReferrers: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	self assert: youngReferrers <= limitAddress.
	self assert: (self occurrencesInYoungReferrers: cogMethod) = 0.
	self assert: cogMethod cmRefersToYoung.
	(self asserta: self roomOnYoungReferrersList) ifFalse:
		[self error: 'no room on youngReferrers list'].
	youngReferrers := youngReferrers - BytesPerWord.
	objectMemory longAt: youngReferrers put: cogMethod asUnsignedInteger
]

{ #category : #allocating }
CogMethodZone >> allocate: numBytes [
	| roundedBytes allocation |
	roundedBytes := numBytes + 7 bitAnd: -8.
	mzFreeStart + roundedBytes > (youngReferrers - BytesPerWord) ifTrue:
		[^0].
	allocation := mzFreeStart.
	mzFreeStart := mzFreeStart + roundedBytes.
	self cCode: '' inSmalltalk:
		[(cogit breakPC isInteger
		   and: [cogit breakPC between: allocation and: mzFreeStart]) ifTrue:
			[cogit singleStep: true]].
	^allocation
]

{ #category : #'jit - api' }
CogMethodZone >> clearCogCompiledCode [
	"Free all methods"
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	 cogMethod := coInterpreter cCoerceSimple: baseAddress to: #'CogMethod *'.
	 [cogMethod asUnsignedInteger < mzFreeStart] whileTrue:
		[cogMethod cmType = CMMethod ifTrue:
			[self freeMethod: cogMethod].
		 cogMethod := self methodAfter: cogMethod].
	mzFreeStart := baseAddress.
	youngReferrers := limitAddress.
	openPICList := nil.
	methodBytesFreedSinceLastCompaction := 0
]

{ #category : #printing }
CogMethodZone >> cogMethodsSelect: aBlock [
	<doNotGenerate>
	| cogMethod cogMethods |
	cogMethods := OrderedCollection new: 256.
	cogMethod := coInterpreter cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod < self limitZony] whileTrue:
		[(aBlock value: cogMethod) ifTrue:
			[cogMethods addLast: cogMethod].
		 cogMethod := self methodAfter: cogMethod].
	^cogMethods
]

{ #category : #compaction }
CogMethodZone >> compactCompiledCode: objectHeaderValue [
	| source dest bytes |
	<var: #source type: #'CogMethod *'>
	<var: #dest type: #'CogMethod *'>
	source := coInterpreter cCoerceSimple: baseAddress to: #'CogMethod *'.
	openPICList := nil.
	[source < self limitZony
	 and: [source cmType ~= CMFree]] whileTrue:
		[self assert: (cogit cogMethodDoesntLookKosher: source) = 0.
		 source objectHeader: objectHeaderValue.
		 source cmUsageCount > 0 ifTrue:
			[source cmUsageCount: source cmUsageCount // 2].
		 source cmType = CMOpenPIC ifTrue:
			[source nextOpenPIC: openPICList asUnsignedInteger.
			 openPICList := source].
		 source := self methodAfter: source].
	source >= self limitZony ifTrue:
		[^self halt: 'no free methods; cannot compact.'].
	dest := source.
	[source < self limitZony] whileTrue:
		[self assert: (cogit maybeFreeCogMethodDoesntLookKosher: source) = 0.
		 bytes := source blockSize.
		 source cmType ~= CMFree ifTrue:
			[self mem: dest mo: source ve: bytes.
			 dest objectHeader: objectHeaderValue.
			 dest cmType = CMMethod
				ifTrue:
					["For non-Newspeak there should ne a one-to-one mapping metween bytecoded and
					  cog methods. For Newspeak not necessarily, but only for anonymous accessors."
					 self assert: ((coInterpreter rawHeaderOf: dest methodObject) asInteger = source asInteger
								or: [(cogit noAssertMethodClassAssociationOf: dest methodObject) = objectMemory nilObject]).
					"Only update the original method's header if it is referring to this CogMethod."
					 (coInterpreter rawHeaderOf: dest methodObject) asInteger = source asInteger ifTrue:
						[coInterpreter rawHeaderOf: dest methodObject put: dest asInteger]]
				ifFalse:
					[dest cmType = CMOpenPIC ifTrue:
						[dest nextOpenPIC: openPICList asUnsignedInteger.
						 openPICList := dest]].
			 dest cmUsageCount > 0 ifTrue:
				[dest cmUsageCount: dest cmUsageCount // 2].
			 dest := coInterpreter
								cCoerceSimple: dest asInteger + bytes
								to: #'CogMethod *'].
		 source := coInterpreter
							cCoerceSimple: source asInteger + bytes
							to: #'CogMethod *'].
	mzFreeStart := dest asInteger.
	methodBytesFreedSinceLastCompaction := 0
]

{ #category : #accessing }
CogMethodZone >> findPreviouslyCompiledVersionOf: aMethodObj with: aSelectorOop [
	<returnTypeC: #'CogMethod *'>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	((coInterpreter methodHasCogMethod: aMethodObj)
	and: [(coInterpreter methodClassAssociationOf: aMethodObj) = objectMemory nilObject]) ifTrue:
		[cogMethod := cogit cCoerceSimple: baseAddress to: #'CogMethod *'.
		[cogMethod < self limitZony] whileTrue:
			[(cogMethod cmType = CMMethod
			  and: [cogMethod selector = aSelectorOop
			  and: [cogMethod methodObject = aMethodObj]]) ifTrue:
				[^cogMethod].
			 cogMethod := self methodAfter: cogMethod]].
	^nil
]

{ #category : #compaction }
CogMethodZone >> freeMethod: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	<inline: false>
	self assert: cogMethod cmType ~= CMFree.
	self assert: (cogit cogMethodDoesntLookKosher: cogMethod) = 0.
	cogMethod cmType = CMMethod ifTrue:
		["For non-Newspeak there should ne a one-to-one mapping between bytecoded and
		  cog methods. For Newspeak not necessarily, but only for anonymous accessors."
		 self assert: ((coInterpreter rawHeaderOf: cogMethod methodObject) asInteger = cogMethod asInteger
					or: [(cogit noAssertMethodClassAssociationOf: cogMethod methodObject) = objectMemory nilObject]).
		"Only reset the original method's header if it is referring to this CogMethod."
		 (coInterpreter rawHeaderOf: cogMethod methodObject) asInteger = cogMethod asInteger ifTrue:
			[coInterpreter
				rawHeaderOf: cogMethod methodObject
				put: cogMethod methodHeader].
		 cogMethod cmRefersToYoung: false].
	cogMethod cmType = CMOpenPIC ifTrue:
		[self removeFromOpenPICList: cogMethod.
		 cogMethod cmRefersToYoung: false].
	cogMethod cmType: CMFree.
	methodBytesFreedSinceLastCompaction := methodBytesFreedSinceLastCompaction
											+ cogMethod blockSize
]

{ #category : #compaction }
CogMethodZone >> freeOlderMethodsForCompaction [
	"Free methods, preferring older methods for compaction, up to some fraction."
	| zoneSize amountToFree initialFreeSpace freedSoFar freeableUsage cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	zoneSize := limitAddress - baseAddress.
	initialFreeSpace := limitAddress - mzFreeStart + methodBytesFreedSinceLastCompaction.
	freedSoFar := initialFreeSpace.
	amountToFree := zoneSize // 4. "4 needs to be e.g. a start-up parameter"
	freeableUsage := 0.
	[self cCode: ''
		inSmalltalk: [coInterpreter transcript nextPutAll: 'freeing methods with usage '; print: freeableUsage; cr; flush].
	 cogMethod := coInterpreter cCoerceSimple: baseAddress to: #'CogMethod *'.
	 [cogMethod asUnsignedInteger < mzFreeStart
	  and: [freedSoFar < amountToFree]] whileTrue:
		[(cogMethod cmType ~= CMFree
		  and: [cogMethod cmUsageCount <= freeableUsage]) ifTrue:
			[self freeMethod: cogMethod.
			 freedSoFar := freedSoFar + cogMethod blockSize].
		 cogMethod := self methodAfter: cogMethod].
	 freedSoFar < amountToFree
	 and: [(freeableUsage := freeableUsage + 1) < CMMaxUsageCount]] whileTrue.
	self cCode: ''
		inSmalltalk: [coInterpreter transcript
						nextPutAll: 'Compaction freeing '; print: freedSoFar;
						nextPutAll: ' of '; print: zoneSize;
						nextPutAll: ' (target: '; print: amountToFree;
						nextPutAll: ' (newly freed: '; print: freedSoFar - initialFreeSpace;
						cr; flush]
]

{ #category : #'young referers' }
CogMethodZone >> kosherYoungReferrers [
	"Answer that all entries in youngReferrers are in-use and have the cmRefersToYoung flag set.
	 Used to check that the youngreferrers pruning routines work correctly."
	| pointer cogMethod |
	<var: #pointer type: #usqInt>
	<var: #cogMethod type: #'CogMethod *'>
	(youngReferrers > limitAddress
	 or: [youngReferrers < mzFreeStart]) ifTrue:
		[^false].
	pointer := youngReferrers.
	[pointer < limitAddress] whileTrue:
		[cogMethod := coInterpreter cCoerceSimple: (objectMemory longAt: pointer) to: #'CogMethod *'.
		 (cogMethod cmType ~= CMFree and: [cogMethod cmRefersToYoung]) ifFalse:
			[^false].
		 pointer := pointer + BytesPerWord].
	^true
]

{ #category : #accessing }
CogMethodZone >> limitZony [ "Let us salute Andrei Tarkovski and his movie Stalker"
	<cmacro: '() ((CogMethod *)mzFreeStart)'>
	^mzFreeStart
]

{ #category : #initialization }
CogMethodZone >> manageFrom: theStartAddress to: theLimitAddress [
	<returnTypeC: #void>
	mzFreeStart := baseAddress := theStartAddress.
	youngReferrers := limitAddress := theLimitAddress.
	openPICList := nil.
	methodBytesFreedSinceLastCompaction := 0
]

{ #category : #compaction }
CogMethodZone >> mem: destAddress mo: sourceAddress ve: bytes [
	<doNotGenerate>
	| dst src  |
	dst := destAddress asInteger.
	src := sourceAddress asInteger.
	"Emulate the c library memmove function"
	self assert: bytes \\ 4 = 0.
	0 to: bytes - 4 by: 4 do:
		[:i|
		objectMemory longAt: dst + i put: (objectMemory longAt: src + i)]
]

{ #category : #accessing }
CogMethodZone >> methodAfter: cogMethod [
	<returnTypeC: #'CogMethod *'>
	<var: #cogMethod type: #'CogMethod *'>
	^coInterpreter
		cCoerceSimple: (self roundUpLength: cogMethod asInteger + cogMethod blockSize)
		to: #'CogMethod *'
]

{ #category : #accessing }
CogMethodZone >> methodBytesFreedSinceLastCompaction [
	<cmacro: '() methodBytesFreedSinceLastCompaction'> "we all get a tad fatigued now and again..."
	^methodBytesFreedSinceLastCompaction
]

{ #category : #'jit - api' }
CogMethodZone >> methodFor: address [
	<api>
	<returnTypeC: #'CogMethod *'>
	<var: #address type: #'void *'>
	| cogMethod nextMethod |
	<var: #cogMethod type: #'CogMethod *'>
	<var: #nextMethod type: #'CogMethod *'>
	cogMethod := coInterpreter cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod < self limitZony
	 and: [(self cCoerceSimple: cogMethod to: #'void *') <= address]] whileTrue:
		[nextMethod := self methodAfter: cogMethod.
		 nextMethod = cogMethod ifTrue:
			[^0].
		 (address >= (self cCoerceSimple: cogMethod to: #'void *')
		  and: [address < (self cCoerceSimple: nextMethod to: #'void *')]) ifTrue:
			[^cogMethod].
		 cogMethod := nextMethod].
	^0
]

{ #category : #'simulation only' }
CogMethodZone >> methods [
	<doNotGenerate>
	| methods |
	methods := OrderedCollection new.
	self methodsDo:
		[:m| methods addLast: m].
	^methods
]

{ #category : #'simulation only' }
CogMethodZone >> methodsDo: aBlock [
	<doNotGenerate>
	| cogMethod |
	cogMethod := cogit cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod < self limitZony] whileTrue:
		[cogMethod cmType ~= CMFree ifTrue:
			[aBlock value: cogMethod].
		 cogMethod := self methodAfter: cogMethod]
	"<api>
	<returnTypeC: #void>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := cogit cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod < self limitZony] whileTrue:
		[cogMethod cmType ~= CMFree ifTrue:
			[aBlock value: cogMethod].
		 cogMethod := self methodAfter: cogMethod]"
]

{ #category : #'jit - api' }
CogMethodZone >> numMethodsOfType: cogMethodType [
	<api>
	| n cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	n := 0.
	cogMethod := cogit cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod < self limitZony] whileTrue:
		[cogMethod cmType = cogMethodType ifTrue:
			[n := n + 1].
		 cogMethod := self methodAfter: cogMethod].
	^n
]

{ #category : #'young referers' }
CogMethodZone >> occurrencesInYoungReferrers: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	| count pointer |
	<var: #pointer type: #usqInt>
	self assert: youngReferrers <= limitAddress.
	count := 0.
	pointer := youngReferrers.
	[pointer < limitAddress] whileTrue:
		[cogMethod asInteger = (objectMemory longAt: pointer) ifTrue:
			[count := count + 1].
		 pointer := pointer + BytesPerWord].
	^count
]

{ #category : #accessing }
CogMethodZone >> openPICWithSelector: aSelector [
	| openPIC |
	<var: #openPIC type: #'CogMethod *'>
	<returnTypeC: #'CogMethod *'>
	openPIC := openPICList.
	[(openPIC == nil
	  or: [openPIC selector = aSelector]) ifTrue:
		[^openPIC].
	 "N.B. Use self rather than coInterpreter to avoid attempting to cast nil.
	  Conversion to CogMethod done in the nextOpenPIC accessor."
	 openPIC := self cCoerceSimple: openPIC nextOpenPIC to: #'CogMethod *'.
	 true] whileTrue
]

{ #category : #compaction }
CogMethodZone >> planCompaction [
	"Some metods have been freed.  Compute how much each survivor needs to
	 move during the ensuing compaction and record it in the objectHeader field."
	| delta cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	delta := 0.
	cogMethod := coInterpreter cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod asUnsignedInteger < mzFreeStart] whileTrue:
		[cogMethod cmType = CMFree
			ifTrue: [delta := delta - cogMethod blockSize]
			ifFalse:
				[self assert: (cogit cogMethodDoesntLookKosher: cogMethod) = 0.
				 cogMethod objectHeader: delta signedIntToLong].
		 cogMethod := self methodAfter: cogMethod]
]

{ #category : #printing }
CogMethodZone >> printCogMethods [
	<api>
	<returnTypeC: #void>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := coInterpreter cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod < self limitZony] whileTrue:
		[coInterpreter printCogMethod: cogMethod.
		 cogMethod := self methodAfter: cogMethod]
]

{ #category : #printing }
CogMethodZone >> printCogMethodsOfType: cmType [
	<api>
	<returnTypeC: #void>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := coInterpreter cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod < self limitZony] whileTrue:
		[cogMethod cmType = cmType ifTrue:
			[coInterpreter printCogMethod: cogMethod].
		 cogMethod := self methodAfter: cogMethod]
]

{ #category : #printing }
CogMethodZone >> printCogMethodsWithMethod: methodOop [
	<api>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := coInterpreter cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod < self limitZony] whileTrue:
		[(cogMethod cmType ~= CMFree
		  and: [cogMethod methodObject = methodOop]) ifTrue:
			[coInterpreter printCogMethod: cogMethod].
		 cogMethod := self methodAfter: cogMethod]
]

{ #category : #printing }
CogMethodZone >> printCogMethodsWithSelector: selectorOop [
	<api>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := coInterpreter cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod < self limitZony] whileTrue:
		[(cogMethod cmType ~= CMFree
		  and: [cogMethod selector = selectorOop]) ifTrue:
			[coInterpreter printCogMethod: cogMethod].
		 cogMethod := self methodAfter: cogMethod]
]

{ #category : #'young referers' }
CogMethodZone >> pruneYoungReferrers [
	| source dest next |
	<var: #source type: #usqInt>
	<var: #dest type: #usqInt>
	<var: #next type: #usqInt>
	<inline: false>

	self assert: youngReferrers <= limitAddress.
	youngReferrers = limitAddress ifTrue:
		[^nil].
	dest := limitAddress.
	[next := dest - BytesPerWord.
	 next >= youngReferrers
	 and: [(coInterpreter cCoerceSimple: (objectMemory longAt: next) to: #'CogMethod *') cmRefersToYoung]] whileTrue:
		[dest := next].
	self assert: dest >= youngReferrers.
	source := dest - BytesPerWord.
	[source >= youngReferrers] whileTrue:
		[(coInterpreter cCoerceSimple: (objectMemory longAt: source) to: #'CogMethod *') cmRefersToYoung ifTrue:
			[self assert: source < (dest - BytesPerWord).
			 objectMemory longAt: (dest := dest - BytesPerWord) put: (objectMemory longAt: source)].
		 source := source - BytesPerWord].
	youngReferrers := dest.
	self assert: self kosherYoungReferrers
]

{ #category : #'jit - api' }
CogMethodZone >> quickClearCogCompiledCode [
	"Quick, for in-image testing"
	<doNotGenerate>
	mzFreeStart := baseAddress.
	self clearCogCompiledCode
]

{ #category : #'young referers' }
CogMethodZone >> relocateAndPruneYoungReferrers [
	| source dest next cogMethod |
	<var: #source type: #usqInt>
	<var: #dest type: #usqInt>
	<var: #next type: #usqInt>
	<var: #cogMethod type: #'CogMethod *'>
	<inline: false>

	self assert: youngReferrers <= limitAddress.
	youngReferrers = limitAddress ifTrue:
		[^nil].
	dest := limitAddress.
	[next := dest - BytesPerWord.
	 next >= youngReferrers
	 and: [(cogMethod := coInterpreter cCoerceSimple: (objectMemory longAt: next) to: #'CogMethod *') cmType ~= CMFree
	 and: [cogMethod cmRefersToYoung]]] whileTrue:
		[cogMethod objectHeader ~= 0 ifTrue:
			[coInterpreter longAt: next put: cogMethod asInteger + cogMethod objectHeader signedIntFromLong].
		 dest := next].
	self assert: dest >= youngReferrers.
	source := dest - BytesPerWord.
	[source >= youngReferrers] whileTrue:
		[cogMethod := coInterpreter cCoerceSimple: (objectMemory longAt: source) to: #'CogMethod *'.
		 (cogMethod cmType ~= CMFree
		  and: [cogMethod cmRefersToYoung]) ifTrue:
			[self assert: source < (dest - BytesPerWord).
			 cogMethod objectHeader ~= 0 ifTrue:
				[cogMethod := coInterpreter cCoerceSimple: cogMethod asInteger + cogMethod objectHeader signedIntFromLong
									to: #'CogMethod *'].
			 objectMemory longAt: (dest := dest - BytesPerWord) put: cogMethod asInteger].
		 source := source - BytesPerWord].
	youngReferrers := dest.
	"this assert must be deferred until after compaction.  See the end of compactCogCompiledCode"
	"self assert: self kosherYoungReferrers"
]

{ #category : #accessing }
CogMethodZone >> removeFromOpenPICList: anOpenPIC [
	<var: #anOpenPIC type: #'CogMethod *'>
	| prevPIC |
	<var: #prevPIC type: #'CogMethod *'>
	self assert: anOpenPIC cmType = CMOpenPIC.
	anOpenPIC = openPICList ifTrue:
		["N.B. Use self rather than coInterpreter to avoid attempting to cast nil.
		  Conversion to CogMethod done in the nextOpenPIC accessor."
		 openPICList := self cCoerceSimple: anOpenPIC nextOpenPIC to: #'CogMethod *'.
		 ^nil].
	prevPIC := openPICList.
	[self assert: (prevPIC ~~ nil
				and: [prevPIC cmType = CMOpenPIC]).
	 prevPIC nextOpenPIC = anOpenPIC asInteger ifTrue:
		[prevPIC nextOpenPIC: anOpenPIC nextOpenPIC.
		 ^nil].
	  prevPIC := self cCoerceSimple: prevPIC nextOpenPIC to: #'CogMethod *'.
	  true] whileTrue
]

{ #category : #'young referers' }
CogMethodZone >> roomOnYoungReferrersList [
	^youngReferrers - BytesPerWord >= mzFreeStart
]

{ #category : #accessing }
CogMethodZone >> roundUpAddress: address [
	<returnTypeC: #'void *'>
	<var: #address type: #'void *'>
	^self cCoerce: ((self cCoerce: address to: 'unsigned long') + 7 bitAnd: -8) to: #'void *'
]

{ #category : #accessing }
CogMethodZone >> roundUpLength: numBytes [
	^numBytes + 7 bitAnd: -8
]

{ #category : #initialization }
CogMethodZone >> setInterpreter: aCoInterpreter objectRepresentation: anObjectRepresentation cogit: aCogit [
	<doNotGenerate>
	coInterpreter := aCoInterpreter.
	objectRepresentation := anObjectRepresentation.
	cogit := aCogit.
	objectMemory := aCoInterpreter objectMemory
]

{ #category : #'jit - api' }
CogMethodZone >> voidYoungReferrersPostTenureAll [
	<var: #cogMethod type: #'CogMethod *'>
	| pointer cogMethod |
	<var: #pointer type: #usqInt>
	<var: #cogMethod type: #'CogMethod *'>
	self assert: youngReferrers <= limitAddress.
	pointer := youngReferrers.
	[pointer < limitAddress] whileTrue:
		[cogMethod := coInterpreter cCoerceSimple: (objectMemory longAt: pointer) to: #'CogMethod *'.
		 cogMethod cmType ~= CMFree ifTrue:
			[cogMethod cmRefersToYoung: false].
		 pointer := pointer + BytesPerWord].
	youngReferrers := limitAddress
]

{ #category : #'young referers' }
CogMethodZone >> youngReferrers [
	<cmacro: '() youngReferrers'>
	^youngReferrers
]

{ #category : #accessing }
CogMethodZone >> zoneEnd [
	^limitAddress
]

{ #category : #accessing }
CogMethodZone >> zoneLimit [
	<returnTypeC: #usqInt>
	^mzFreeStart
]

{ #category : #accessing }
CogMethodZone >> zoneLimit: zoneLimit [
	<doNotGenerate>
	^mzFreeStart := zoneLimit
]
