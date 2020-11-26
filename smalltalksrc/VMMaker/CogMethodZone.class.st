"
I am a simple allocator/deallocator for the native code zone.  I also manage the youngReferers list, which contains methods that may refer to one or more young objects, and the openPICList which is a linked list of all open PICs in the zone.

Instance Variables
	baseAddress:								<Integer address>
	coInterpreter:								<CoInterpreter>
	cogit:										<Cogit>
	limitAddress:								<Integer address>
	methodBytesFreedSinceLastCompaction:	<Integer>
	methodCount:								<Integer>
	mzFreeStart:								<Integer address>
	objectMemory:								<NewCoObjectMemory|SpurCoMemoryManager>
	objectRepresentation:						<CogObjectRepresentation:>
	openPICList:								<CogMethod *|nil>
	unpairedMethodList:						<CogMethod *|nil>
	youngReferrers:							<Integer address>

baseAddress
	- the lowest address in the native method zone

coInterpreter
	- simulation-only

cogit
	- simulation-only

limitAddress
	- the address immediately following the native method zone

methodBytesFreedSinceLastCompaction
	- a count of the bytes in methods freed since the last compaction of the native method zone, used to answer the used bytes in the zone

methodCount
	- a count of the number of methods in the native method zone

mzFreeStart
	- the start of free space in the zone

objectMemory
	- simulation-only

objectRepresentation
	- simulation-only

openPICList
	- the head of the list of open PICs

unpairedMethodList
	- the head of the list of Cog methods with no associated CompiledMethod object (Newspeak only)

youngReferrers
	- the pointer to the start of an array of pointers to CogMethods that refer to young objects.  May contain false positives.  Occupies the top of the zone from youngReferrers up to limitAddress

"
Class {
	#name : #CogMethodZone,
	#superclass : #CogClass,
	#instVars : [
		'youngReferrers',
		'unpairedMethodList',
		'methodCount',
		'openPICList',
		'mzFreeStart',
		'baseAddress',
		'limitAddress',
		'methodBytesFreedSinceLastCompaction',
		'compactionInProgress',
		'coInterpreter',
		'objectRepresentation',
		'cogit',
		'objectMemory',
		'percentageToEnsureRelease'
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
	
	self declareC: #(youngReferrers mzFreeStart baseAddress limitAddress unpairedMethodList)
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

{ #category : #'young referers' }
CogMethodZone >> addAllToYoungReferrers [
	<api>
	<returnTypeC: #void>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := coInterpreter cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod < self limitZony] whileTrue:
		[(cogMethod cmType = CMMethod
		  or: [cogMethod cmType = CMOpenPIC]) ifTrue:
			[self ensureInYoungReferrers: cogMethod].
		 cogMethod := self methodAfter: cogMethod]
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
	self assert: (youngReferrers <= limitAddress
				and: [youngReferrers >= (limitAddress - (methodCount * objectMemory wordSize))]).
	(self asserta: limitAddress - (methodCount * objectMemory wordSize) >= mzFreeStart) ifFalse:
		[self error: 'no room on youngReferrers list'].
	youngReferrers := youngReferrers - objectMemory wordSize.
	objectMemory longAt: youngReferrers put: cogMethod asUnsignedInteger
]

{ #category : #allocating }
CogMethodZone >> allocate: numBytes [
	| roundedBytes allocation |
	roundedBytes := numBytes + 7 bitAnd: -8.
	mzFreeStart + roundedBytes >= self allocationLimit ifTrue:
		[^0].
	allocation := mzFreeStart.
	mzFreeStart := mzFreeStart + roundedBytes.
	methodCount := methodCount + 1.
	self cCode: '' inSmalltalk:
		[(cogit breakPC isInteger
		   and: [cogit breakPC between: allocation and: mzFreeStart]) ifTrue:
			[cogit singleStep: true]].
	^allocation
]

{ #category : #allocating }
CogMethodZone >> allocationLimit [
	<inline: true>
	^limitAddress - (methodCount * objectMemory wordSize)
]

{ #category : #'as yet unclassified' }
CogMethodZone >> baseAddress: anInteger [ 

	<doNotGenerate>
	baseAddress := anInteger
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
	self manageFrom: baseAddress to: limitAddress
]

{ #category : #compaction }
CogMethodZone >> clearSavedPICUsageCount: cogMethod [
	"For Sista, where we want PICs to last so they can be observed, we need to keep PICs unless
	 they are definitely unused.  So we need to identify unused PICs.  So in planCompact, zero the
	 usage counts of all PICs, saving the actual usage count in blockEntryOffset.  Then in
	 relocateMethodsPreCompaction (actually in relocateIfCallOrMethodReference:mcpc:delta:)
	 restore the usage counts of used PICs.  Finally in compactCompiledCode, clear the blockEntryOffset
	 of the unused PICs; they will then have a zero count and be reclaimed in the next code compaction."
	<var: #cogMethod type: #'CogMethod *'>
	<option: #SistaVM>
	cogMethod cmType = CMClosedPIC ifTrue:
		[cogMethod blockEntryOffset: 0]
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

{ #category : #'simulation only' }
CogMethodZone >> cogit [
	"This is for the sizeof: CogMethod hook that allows different cogit classes to use differet CogMethod variants."
	<doNotGenerate>
	^cogit
]

{ #category : #compaction }
CogMethodZone >> compactCompiledCode [
	| objectHeaderValue source dest bytes |
	<var: #source type: #'CogMethod *'>
	<var: #dest type: #'CogMethod *'>
	compactionInProgress := true.
	objectHeaderValue := objectMemory nullHeaderForMachineCodeMethod.
	source := coInterpreter cCoerceSimple: baseAddress to: #'CogMethod *'.
	self voidOpenPICList. "The list will be rebuilt with the current live set"
	methodCount := 0.
	[source < self limitZony
	 and: [source cmType ~= CMFree]] whileTrue:
		[self assert: (cogit cogMethodDoesntLookKosher: source) = 0.
		 source objectHeader: objectHeaderValue.
		 source cmUsageCount > 0 ifTrue:
			[source cmUsageCount: source cmUsageCount // 2].
		 SistaVM ifTrue:
			[self clearSavedPICUsageCount: source].
		 source cmType = CMOpenPIC ifTrue:
			[self addToOpenPICList: source].
		 methodCount := methodCount + 1.
		 source := self methodAfter: source].
	source >= self limitZony ifTrue:
		[^self halt: 'no free methods; cannot compact.'].
	dest := source.
	[source < self limitZony] whileTrue:
		[self assert: (cogit maybeFreeCogMethodDoesntLookKosher: source) = 0.
		 bytes := source blockSize.
		 source cmType ~= CMFree ifTrue:
			[methodCount := methodCount + 1.
			 objectMemory memmove: dest _: source _: bytes.
			 dest objectHeader: objectHeaderValue.
			 dest cmType = CMMethod
				ifTrue:
					["There should be a one-to-one mapping between bytecoded and cog methods."
					"Only update the original method's header if it is referring to this CogMethod."
					 (coInterpreter rawHeaderOf: dest methodObject) asInteger = source asInteger
						ifTrue:
							[coInterpreter rawHeaderOf: dest methodObject put: dest asInteger]
						ifFalse:
							[self assert: (cogit noAssertMethodClassAssociationOf: dest methodObject) = objectMemory nilObject]]
				ifFalse:
					[SistaVM ifTrue:
						[self clearSavedPICUsageCount: dest].
					 dest cmType = CMOpenPIC ifTrue:
						[self addToOpenPICList: dest]].
			 dest cmUsageCount > 0 ifTrue:
				[dest cmUsageCount: dest cmUsageCount // 2].
			 dest := coInterpreter
								cCoerceSimple: dest asUnsignedInteger + bytes
								to: #'CogMethod *'].
		 source := coInterpreter
							cCoerceSimple: source asUnsignedInteger + bytes
							to: #'CogMethod *'].
	mzFreeStart := dest asUnsignedInteger.
	methodBytesFreedSinceLastCompaction := 0.
	compactionInProgress := false
]

{ #category : #accessing }
CogMethodZone >> compactionInProgress [
	^compactionInProgress
]

{ #category : #allocating }
CogMethodZone >> effectiveLimit [
	<inline: true>
	^limitAddress
]

{ #category : #'young referers' }
CogMethodZone >> ensureInYoungReferrers: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod cmRefersToYoung ifFalse:
		[self assert: (self occurrencesInYoungReferrers: cogMethod) = 0.
		 cogMethod cmRefersToYoung: true.
		 self addToYoungReferrers: cogMethod]
]

{ #category : #'jit - api' }
CogMethodZone >> followForwardedLiteralsInOpenPICList [
	<option: #SpurObjectMemory>
	| openPIC |
	<var: #openPIC type: #'CogMethod *'>
	openPIC := openPICList.
	[openPIC notNil] whileTrue:
		[cogit followForwardedLiteralsIn: openPIC.
		 openPIC := self cCoerceSimple: openPIC nextOpenPIC to: #'CogMethod *'.]
]

{ #category : #compaction }
CogMethodZone >> freeMethod: cogMethod [
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	<inline: false>
	self assert: cogMethod cmType ~= CMFree.
	self assert: (cogit cogMethodDoesntLookKosher: cogMethod) = 0.
	cogMethod cmType = CMMethod ifTrue:
		["There should be a one-to-one mapping between bytecoded and cog methods."
		"Only reset the original method's header if it is referring to this CogMethod."
		 (coInterpreter rawHeaderOf: cogMethod methodObject) asInteger = cogMethod asInteger
			ifTrue:
				[ coInterpreter rawHeaderOf: cogMethod methodObject put: cogMethod methodHeader ]
			ifFalse:
				[self cCode: [self assert: (cogit noAssertMethodClassAssociationOf: cogMethod methodObject) = objectMemory nilObject]
					inSmalltalk: [self assert: ((cogit noAssertMethodClassAssociationOf: cogMethod methodObject) = objectMemory nilObject
											or: [coInterpreter isKindOf: CurrentImageCoInterpreterFacade])] ].
		 cogit maybeFreeCountersOf: cogMethod].
	cogMethod cmType = CMOpenPIC ifTrue:
		[self removeFromOpenPICList: cogMethod].
	cogMethod cmRefersToYoung: false.
	cogMethod cmType: CMFree.
	methodBytesFreedSinceLastCompaction := methodBytesFreedSinceLastCompaction
												+ cogMethod blockSize
]

{ #category : #compaction }
CogMethodZone >> freeOlderMethodsForCompaction [
	"Free methods, preferring older methods for compaction, up to some fraction, currently a quarter."
	| zoneSize amountToFree initialFreeSpace freedSoFar freeableUsage cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	zoneSize := self effectiveLimit - baseAddress.
	initialFreeSpace := self effectiveLimit - mzFreeStart + methodBytesFreedSinceLastCompaction.
	freedSoFar := initialFreeSpace.
	amountToFree := zoneSize // 4. "4 needs to be e.g. a start-up parameter"
	freeableUsage := 0.
	[self cCode: ''
		inSmalltalk: [coInterpreter transcript nextPutAll: 'freeing methods with usage '; print: freeableUsage; cr; flush].
	 cogMethod := cogit cCoerceSimple: baseAddress to: #'CogMethod *'.
	 [cogMethod asUnsignedInteger < mzFreeStart
	  and: [freedSoFar < amountToFree]] whileTrue:
		[(self shouldFreeMethod: cogMethod given: freeableUsage) ifTrue:
			[self freeMethod: cogMethod.
			 freedSoFar := freedSoFar + cogMethod blockSize].
		 cogMethod := self methodAfter: cogMethod].
	 freedSoFar < amountToFree
	 and: [(freeableUsage := freeableUsage + 1) < CMMaxUsageCount]] whileTrue.
	self cCode: ''
		inSmalltalk: [coInterpreter transcript
						nextPutAll: 'Code Compaction freeing '; print: freedSoFar;
						nextPutAll: ' of '; print: zoneSize;
						nextPutAll: ' (target: '; print: amountToFree;
						nextPutAll: ' (newly freed: '; print: freedSoFar - initialFreeSpace;
						cr; flush]
]

{ #category : #accessing }
CogMethodZone >> freeStart [
	"declared as a macro so as not to conflict with the memory manager's freeStart."
	<cmacro: '() mzFreeStart'>
	^mzFreeStart
]

{ #category : #accessing }
CogMethodZone >> freeStart: zoneLimit [
	<doNotGenerate>
	^baseAddress := mzFreeStart := zoneLimit
]

{ #category : #initialization }
CogMethodZone >> initialize [
	"Make youngReferrers arithmetic for addressIsInCodeZone:"
	youngReferrers := methodCount := methodBytesFreedSinceLastCompaction := 0.
	compactionInProgress := false
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
		 pointer := pointer + objectMemory wordSize].
	^true
]

{ #category : #accessing }
CogMethodZone >> limitZony [ "Let us salute Andrei Tarkovsky and his movie Stalker"
	<cmacro: '() ((CogMethod *)mzFreeStart)'>
	^mzFreeStart
]

{ #category : #initialization }
CogMethodZone >> manageFrom: theStartAddress to: theLimitAddress [
	<returnTypeC: #void>
	mzFreeStart := baseAddress := theStartAddress.
	youngReferrers := limitAddress := theLimitAddress.
	openPICList := nil.
	methodBytesFreedSinceLastCompaction := 0.
	methodCount := 0
]

{ #category : #accessing }
CogMethodZone >> methodAfter: cogMethod [
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	^coInterpreter
		cCoerceSimple: (self roundUpLength: cogMethod asInteger + cogMethod blockSize)
		to: #'CogMethod *'
]

{ #category : #accessing }
CogMethodZone >> methodBytesFreedSinceLastCompaction [
	<cmacro: '() methodBytesFreedSinceLastCompaction'>
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
	 and: [cogMethod asUnsignedInteger <= address asUnsignedInteger]] whileTrue:
		[nextMethod := self methodAfter: cogMethod.
		 nextMethod = cogMethod ifTrue:
			[^0].
		 (address asUnsignedInteger >= cogMethod asUnsignedInteger
		  and: [address asUnsignedInteger < nextMethod asUnsignedInteger]) ifTrue:
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

{ #category : #'method zone introspection' }
CogMethodZone >> methodsCompiledToMachineCodeInto: arrayObj [ 
	<api>
	<var: #cogMethod type: #'CogMethod *'>
	| cogMethod methodIndex |
	methodIndex := 0.
	cogMethod := cogit cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod < self limitZony] whileTrue:
		[cogMethod cmType = CMMethod ifTrue:
			[objectMemory 
				storePointerUnchecked: methodIndex 
				ofObject: arrayObj 
				withValue: cogMethod methodObject.
			 methodIndex := methodIndex + 1].
		 cogMethod := self methodAfter: cogMethod].
	^ methodIndex
	
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

{ #category : #accessing }
CogMethodZone >> numMethods [
	<api>
	^methodCount
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
		 pointer := pointer + objectMemory wordSize].
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
	"Some methods have been freed.  Compute how much each survivor needs to
	 move during the ensuing compaction and record it in the objectHeader field.

	 For Sista, where we want PICs to last so they can be observed, we need to keep PICs unless
	 they are definitely unused.  So we need to identify unused PICs.  So in planCompact, zero the
	 usage counts of all PICs, saving the actual usage count in blockEntryOffset.  Then in
	 relocateMethodsPreCompaction (actually in relocateIfCallOrMethodReference:mcpc:delta:)
	 restore the usage counts of used PICs.  Finally in compactCompiledCode, clear the blockEntryOffset
	 of the unused PICs; they will then have a zero count and be reclaimed in the next code compaction."
	| delta cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	delta := 0.
	cogMethod := cogit cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod asUnsignedInteger < mzFreeStart] whileTrue:
		[cogMethod cmType = CMFree
			ifTrue: [delta := delta - cogMethod blockSize]
			ifFalse:
				[self assert: (cogit cogMethodDoesntLookKosher: cogMethod) = 0.
				 cogMethod objectHeader: delta.
				 SistaVM ifTrue:
					[self savePICUsageCount: cogMethod]].
		 cogMethod := self methodAfter: cogMethod]
]

{ #category : #printing }
CogMethodZone >> printCogMethods [
	<api>
	<returnTypeC: #void>
	| cogMethod nm nc no nf nu |
	<var: #cogMethod type: #'CogMethod *'>
	nm := nc := no := nf := nu := 0.
	cogMethod := coInterpreter cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod < self limitZony] whileTrue:
		[coInterpreter printCogMethod: cogMethod.
		 cogMethod cmType
			caseOf: {
			[CMFree]		->	[nf := nf + 1].
			[CMMethod]	->	[nm := nm + 1].
			[CMClosedPIC]	->	[nc := nc + 1].
			[CMOpenPIC]	->	[no:= no+ 1] }
			otherwise: [nu := nu + 1].
		 cogMethod := self methodAfter: cogMethod].
	coInterpreter print: 'CMMethod '; printNum: nm;  print: ' CMClosedPIC '; printNum: nc;  print: ' CMOpenPIC '; printNum: no;  print: ' CMFree '; printNum: nf.
	nu > 0 ifTrue:
		[coInterpreter print: ' UNKNOWN '; printNum: nu].
	coInterpreter print: ' total '; printNum: nm+nc+no+nf+nu; cr
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
CogMethodZone >> printCogMethodsWithPrimitive: primIdx [
	<api>
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := coInterpreter cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod < self limitZony] whileTrue:
		[(cogMethod cmType = CMMethod
		  and: [primIdx = (coInterpreter primitiveIndexOfMethod: cogMethod methodObject
							header: cogMethod methodHeader)]) ifTrue:
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

{ #category : #printing }
CogMethodZone >> printCogYoungReferrers [
	<api>
	<returnTypeC: #void>
	| pointer cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	pointer := youngReferrers.
	[pointer < limitAddress] whileTrue:
		[cogMethod := coInterpreter cCoerceSimple: (objectMemory longAt: pointer) to: #'CogMethod *'.
		 cogMethod cmRefersToYoung ifFalse:
			[coInterpreter print: '*'].
		 cogMethod cmType = CMFree ifTrue:
			[coInterpreter print: '!'].
		 (cogMethod cmRefersToYoung and: [cogMethod cmType ~= CMFree]) ifFalse:
			[coInterpreter print: ' '].
		 coInterpreter printCogMethod: cogMethod.
		 pointer := pointer + objectMemory wordSize]
]

{ #category : #accessing }
CogMethodZone >> printOpenPICList [
	<api>
	| n openPIC |
	<var: #openPIC type: #'CogMethod *'>
	n := 0.
	openPIC := openPICList.
	[openPIC == nil] whileFalse:
		[n := n + 1.
		 coInterpreter printCogMethod: openPIC.
		 openPIC := self cCoerceSimple: openPIC nextOpenPIC to: #'CogMethod *'].
	^n
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
	[next := dest - objectMemory wordSize.
	 next >= youngReferrers
	 and: [(coInterpreter cCoerceSimple: (objectMemory longAt: next) to: #'CogMethod *') cmRefersToYoung]] whileTrue:
		[dest := next].
	self assert: dest >= youngReferrers.
	source := dest - objectMemory wordSize.
	[source >= youngReferrers] whileTrue:
		[(coInterpreter cCoerceSimple: (objectMemory longAt: source) to: #'CogMethod *') cmRefersToYoung ifTrue:
			[self assert: source < (dest - objectMemory wordSize).
			 objectMemory longAt: (dest := dest - objectMemory wordSize) put: (objectMemory longAt: source)].
		 source := source - objectMemory wordSize].
	youngReferrers := dest.
	self assert: self kosherYoungReferrers
]

{ #category : #'jit - api' }
CogMethodZone >> quickClearCogCompiledCode [
	"Quick, for in-image testing"
	<doNotGenerate>
	mzFreeStart := baseAddress.
	self clearCogCompiledCode.
	cogit backEnd stopsFrom: mzFreeStart to: limitAddress - 1
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
	[next := dest - objectMemory wordSize.
	 next >= youngReferrers
	 and: [(cogMethod := coInterpreter cCoerceSimple: (objectMemory longAt: next) to: #'CogMethod *') cmType ~= CMFree
	 and: [cogMethod cmRefersToYoung]]] whileTrue:
		[cogMethod objectHeader ~= 0 ifTrue:
			[coInterpreter longAt: next put: cogMethod asInteger + cogMethod objectHeader].
		 dest := next].
	self assert: dest >= youngReferrers.
	source := dest - objectMemory wordSize.
	[source >= youngReferrers] whileTrue:
		[cogMethod := coInterpreter cCoerceSimple: (objectMemory longAt: source) to: #'CogMethod *'.
		 (cogMethod cmType ~= CMFree
		  and: [cogMethod cmRefersToYoung]) ifTrue:
			[self assert: source < (dest - objectMemory wordSize).
			 cogMethod objectHeader ~= 0 ifTrue:
				[cogMethod := coInterpreter
									cCoerceSimple: cogMethod asInteger + cogMethod objectHeader asInteger
									to: #'CogMethod *'].
			 objectMemory longAt: (dest := dest - objectMemory wordSize) put: cogMethod asInteger].
		 source := source - objectMemory wordSize].
	youngReferrers := dest.
	"this assert must be deferred until after compaction.  See the end of compactCogCompiledCode"
	"self assert: self kosherYoungReferrers"
]

{ #category : #compaction }
CogMethodZone >> relocateMethodsPreCompaction [
	"All surviving methods have had the amount they are going to relocate by
	 stored in their objectHeader fields.  Relocate all relative calls so that after
	 the compaction of both the method containing each call and the call target
	 the calls invoke the same target."
	| cogMethod |
	<var: #cogMethod type: #'CogMethod *'>
	cogMethod := cogit cCoerceSimple: baseAddress to: #'CogMethod *'.
	[cogMethod asUnsignedInteger < mzFreeStart] whileTrue:
		[cogMethod cmType ~= CMFree ifTrue:
			[cogMethod cmType = CMClosedPIC
				ifTrue: [cogit relocateCallsInClosedPIC: cogMethod]
				ifFalse: [cogit relocateCallsAndSelfReferencesInMethod: cogMethod]].
		 cogMethod := self methodAfter: cogMethod].
	self relocateAndPruneYoungReferrers.
	^true
]

{ #category : #accessing }
CogMethodZone >> removeFromOpenPICList: anOpenPIC [
	<var: #anOpenPIC type: #'CogMethod *'>
	| prevPIC |
	<var: #prevPIC type: #'CogMethod *'>
	self assert: anOpenPIC cmType = CMOpenPIC.
	openPICList ifNil: [^nil]. "As it is when compacting or unlinking all sends"
	self assert: (openPICList cmType = CMOpenPIC
				and: [openPICList nextOpenPIC isNil
					or: [(self cCoerceSimple: openPICList nextOpenPIC to: #'CogMethod *') cmType = CMOpenPIC]]).
	anOpenPIC = openPICList ifTrue:
		["N.B. Use self rather than coInterpreter to avoid attempting to cast nil.
		  Conversion to CogMethod done in the nextOpenPIC accessor."
		 openPICList := self cCoerceSimple: anOpenPIC nextOpenPIC to: #'CogMethod *'.
		 ^nil].
	prevPIC := openPICList.
	[self assert: (prevPIC ~~ nil
				and: [prevPIC cmType = CMOpenPIC]).
	 prevPIC nextOpenPIC = anOpenPIC asUnsignedInteger ifTrue:
		[prevPIC nextOpenPIC: anOpenPIC nextOpenPIC.
		 ^nil].
	  prevPIC := self cCoerceSimple: prevPIC nextOpenPIC to: #'CogMethod *'.
	  true] whileTrue
]

{ #category : #compaction }
CogMethodZone >> restorePICUsageCount: cogMethod [
	"For Sista, where we want PICs to last so they can be observed, we need to keep PICs unless
	 they are definitely unused.  So we need to identify unused PICs.  So in planCompact, zero the
	 usage counts of all PICs, saving the actual usage count in blockEntryOffset.  Then in
	 relocateMethodsPreCompaction (actually in relocateIfCallOrMethodReference:mcpc:delta:)
	 restore the usage counts of used PICs.  Finally in compactCompiledCode, clear the blockEntryOffset
	 of the unused PICs; they will then have a zero count and be reclaimed in the next code compaction."
	<var: #cogMethod type: #'CogMethod *'>
	<option: #SistaVM>
	(cogMethod cmType = CMClosedPIC
	 and: [cogMethod blockEntryOffset ~= 0]) ifTrue:
		[cogMethod
			cmUsageCount: cogMethod blockEntryOffset;
			blockEntryOffset: 0]
]

{ #category : #accessing }
CogMethodZone >> roundUpAddress: address [
	<returnTypeC: #'void *'>
	<var: #address type: #'void *'>
	^self cCoerce: ((self cCoerce: address to: #'usqIntptr_t') + 7 bitAnd: -8) to: #'void *'
]

{ #category : #accessing }
CogMethodZone >> roundUpLength: numBytes [
	<cmacro: '(numBytes) ((numBytes) + 7 & -8)'>
	^numBytes + 7 bitAnd: -8
]

{ #category : #compaction }
CogMethodZone >> savePICUsageCount: cogMethod [
	"For Sista, where we want PICs to last so they can be observed, we need to keep PICs unless
	 they are definitely unused.  So we need to identify unused PICs.  So in planCompact, zero the
	 usage counts of all PICs, saving the actual usage count in blockEntryOffset.  Then in
	 relocateMethodsPreCompaction (actually in relocateIfCallOrMethodReference:mcpc:delta:)
	 restore the usage counts of used PICs.  Finally in compactCompiledCode, clear the blockEntryOffset
	 of the unused PICs; they will then have a zero count and be reclaimed in the next code compaction."
	<var: #cogMethod type: #'CogMethod *'>
	<option: #SistaVM>
	cogMethod cmType = CMClosedPIC ifTrue:
		[cogMethod
			blockEntryOffset: cogMethod cmUsageCount;
			cmUsageCount: 0]
]

{ #category : #initialization }
CogMethodZone >> setInterpreter: aCoInterpreter objectRepresentation: anObjectRepresentation cogit: aCogit [
	<doNotGenerate>
	coInterpreter := aCoInterpreter.
	objectRepresentation := anObjectRepresentation.
	cogit := aCogit.
	objectMemory := aCoInterpreter objectMemory
]

{ #category : #compaction }
CogMethodZone >> shouldFreeMethod: cogMethod given: freeableUsage [
	"Answer if cogMethod should be freed in the current pass of freeOlderMethodsForCompaction.

	 For Sista, where we want PICs to last so they can be observed, we need to keep PICs unless
	 they are definitely unused.  So we need to identify unused PICs.  So in planCompact, zero the
	 usage counts of all PICs, saving the actual usage count in blockEntryOffset.  Then in
	 relocateMethodsPreCompaction (actually in relocateIfCallOrMethodReference:mcpc:delta:)
	 restore the usage counts of used PICs.  Finally in compactCompiledCode, clear the blockEntryOffset
	 of the unused PICs; they will then have a zero count and be reclaimed in the next code compaction."
	<var: #cogMethod type: #'CogMethod *'>
	<inline: true>
	^SistaVM
		ifTrue:
			[cogMethod cmType = CMMethod
			 	ifTrue: [cogMethod cmUsageCount <= freeableUsage]
				ifFalse: [cogMethod cmType ~= CMFree
						  and: [cogMethod cmUsageCount = 0]]]
		ifFalse:
			[cogMethod cmType ~= CMFree
			  and: [cogMethod cmUsageCount <= freeableUsage]]
]

{ #category : #accessing }
CogMethodZone >> voidOpenPICList [
	openPICList := nil
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
		 pointer := pointer + objectMemory wordSize].
	youngReferrers := limitAddress
]

{ #category : #'debug printing' }
CogMethodZone >> whereIsMaybeCodeThing: anOop [
	<api>
	<returnTypeC: 'char *'>
	(self oop: anOop isGreaterThanOrEqualTo: cogit cogCodeBase andLessThan: limitAddress) ifTrue:
		[(self oop: anOop isLessThan: cogit minCogMethodAddress) ifTrue:
			[^' is in generated runtime'].
		 (self oop: anOop isLessThan: mzFreeStart) ifTrue:
			[^' is in generated methods'].
		 (self oop: anOop isLessThan: youngReferrers) ifTrue:
			[^' is in code zone'].
		 ^' is in young referrers'].
	^nil
]

{ #category : #'young referers' }
CogMethodZone >> youngReferrers [
	<cmacro: '() youngReferrers'>
	^youngReferrers
]

{ #category : #accessing }
CogMethodZone >> zoneAlignment [
	^8
]

{ #category : #accessing }
CogMethodZone >> zoneEnd [
	^limitAddress
]

{ #category : #'simulation only' }
CogMethodZone >> zoneEnd: zoneEnd [
	<doNotGenerate> 
	limitAddress := zoneEnd
]

{ #category : #accessing }
CogMethodZone >> zoneFree [
	^mzFreeStart
]
