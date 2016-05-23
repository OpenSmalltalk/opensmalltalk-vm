"
SpurBootstrap bootstraps an image in SpurMemoryManager format from a Squeak V3 + closures format.

e.g.
	(SpurBootstrap32 new on: '/Users/eliot/Cog/startreader.image')
		transform;
		launch

Bootstrap issues:
- should it implement a deterministic Symbol identityHash? This means set a Symbol's identityHash at instance creation time
  based on its string hash so that e.g. MethodDIctionary instances have a deterministic order and don't need to be rehashed on load.
- should it collapse ContextPart and MethodContext down onto Context (and perhaps eliminate BlockContext)?

Instance Variables
	classToIndex:			<Dictionary>
	lastClassTablePage:	<Integer>
	map:					<Dictionary>
	methodClasses:		<Set>
	newHeap:				<SpurMemoryManager>
	oldHeap:				<NewObjectMemory>
	oldInterpreter:			<StackInterpreterSimulator>
	reverseMap:			<Dictionary>
	symbolMap:				<Dictionary>

classToIndex
	- oldClass to new classIndex map

lastClassTablePage
	- oop in newHeap of last classTable page.  U<sed in validation to filter-out class table.

methodClasses
	- cache of methodClassAssociations for classes in which modified methods are installed

map
	- oldObject to newObject map

newHeap
	- the output, bootstrapped image

oldHeap
	- the input, image

oldInterpreter
	- the interpreter associated with oldHeap, needed for a hack to grab WeakArray

reverseMap
	- newObject to oldObject map

symbolMap
	- symbol toi symbol oop in oldHeap, used to map prototype methdos to methods in oldHeap
"
Class {
	#name : #SpurBootstrap,
	#superclass : #SimulatorHarness,
	#instVars : [
		'oldHeap',
		'newHeap',
		'oldHeapSize',
		'newHeapSize',
		'oldHeapNumObjs',
		'newHeapNumObjs',
		'map',
		'reverseMap',
		'classToIndex',
		'oldInterpreter',
		'lastClassTablePage',
		'literalMap',
		'methodClasses',
		'installedPrototypes',
		'installedMethodOops',
		'classMetaclass',
		'imageTypes',
		'classMethodContextIndex',
		'classBlockClosureIndex',
		'toBeInitialized'
	],
	#classVars : [
		'ImageHeaderFlags',
		'ImageName',
		'ImageScreenSize',
		'TransformedImage'
	],
	#pools : [
		'VMObjectIndices'
	],
	#category : 'Cog-Bootstrapping'
}

{ #category : #utilities }
SpurBootstrap class >> bootstrapCuisImage: imageFileBaseName [
	self bootstrapImage: imageFileBaseName type: #('squeak' 'cuis')
]

{ #category : #utilities }
SpurBootstrap class >> bootstrapImage: imageFileNameOrBaseName type: typeName [
	"SpurBootstrap bootstrapImage: '/Users/eliot/Squeak/Squeak4.5/Squeak4.5-13680'"
	| imageFileBaseName imageFormat |
	imageFileBaseName := (imageFileNameOrBaseName endsWith: '.image')
								ifTrue: [imageFileNameOrBaseName allButLast: 6]
								ifFalse: [imageFileNameOrBaseName].
	imageFormat := ImageFormat fromFile: imageFileBaseName, '.image'.
	imageFormat requiresClosureSupport ifFalse:
		[self error: 'Can''t bootstrap this image since Spur assumes closure support.'].
	imageFormat requiresSpurSupport ifTrue:
		[self error: 'This image is already in Spur format.'].
	imageFormat is32Bit ifTrue:
		[^SpurBootstrap32 new bootstrapImage: imageFileBaseName type: typeName].
	self error: '64-bit support and 64-bit generation as-yet-unimplemented'
]

{ #category : #utilities }
SpurBootstrap class >> bootstrapOldSqueakImage: imageFileBaseName [
	"Try asnd bootstrap a pre-CompiledMethodTrailer Squeak image."
	self bootstrapImage: imageFileBaseName type: #('squeak' 'old squeak')
]

{ #category : #utilities }
SpurBootstrap class >> bootstrapPharoImage: imageFileBaseName [
	| oldCompilerClass oldBytecodeBackend |
	
	oldCompilerClass := SmalltalkImage compilerClass.
	oldBytecodeBackend := CompilationContext bytecodeBackend. 
	[ 
		SmalltalkImage compilerClass: Compiler. 
		CompilationContext bytecodeBackend: IRSpurSqueakV3PlusClosuresBytecodeGenerator.
		self bootstrapImage: imageFileBaseName type: 'pharo' ]
	ensure: [ 
		SmalltalkImage compilerClass: oldCompilerClass.
		CompilationContext bytecodeBackend: oldBytecodeBackend ]
]

{ #category : #utilities }
SpurBootstrap class >> bootstrapSqueakImage: imageFileBaseName [
	self bootstrapImage: imageFileBaseName type: 'squeak'
]

{ #category : #'method prototype categorization' }
SpurBootstrap class >> categoryForClass: className meta: isMeta selector: selector [ 
	^(isMeta
			ifTrue: [{ className. #class. selector }]
			ifFalse: [{ className. selector }])
		caseOf: {
			[#(Behavior allInstancesOrNil)]					-> [#enumerating].
			[#(Behavior byteSizeOfInstance)]				-> [#'accessing instances and variables'].
			[#(Behavior byteSizeOfInstanceOfSize:)]		-> [#'accessing instances and variables'].
			[#(Behavior elementSize)]						-> [#'accessing instances and variables'].
			[#(Behavior handleFailingBasicNew)]			-> [#private].
			[#(Behavior handleFailingBasicNew:)]			-> [#private].
			[#(Behavior handleFailingFailingBasicNew)]		-> [#private].
			[#(Behavior handleFailingFailingBasicNew:)]		-> [#private].
			[#(Behavior identityHash)]						-> [#comparing].
			[#(Behavior isCompiledMethodClass)]			-> [#testing].
			[#(Behavior isEphemeronClass)]				-> [#testing].
			[#(Behavior isImmediateClass)]					-> [#testing].
			[#(BoxedFloat64 class basicNew)]				-> [#'instance creation'].
			[#(BoxedFloat64 class basicNew:)]				-> [#'instance creation'].
			[#(Character identityHash)]						-> [#comparing].
			[#(Character setValue:)]						-> [#accessing].
			[#(Class immediateSubclass:instanceVariableNames:classVariableNames:poolDictionaries:category:)]
															-> [#'subclass creation'].
			[#(ClassBuilder superclass:immediateSubclass:instanceVariableNames:classVariableNames:poolDictionaries:category:)]
															-> [#public].
			[#(CompiledMethod bytecodeSetName)]		-> [#accessing].
			[#(CompiledMethod class handleFailingFailingNewMethod:header:)]
															-> [#private].
			[#(CompiledMethod class handleFailingNewMethod:header:)]
															-> [#private].
			[#(CompiledMethod class headerFlagForEncoder:)]
															-> [#'method encoding'].
			[#(CompiledMethod class installPrimaryBytecodeSet:)]
															-> [#'class initialization'].
			[#(CompiledMethod class installSecondaryBytecodeSet:)]
															-> [#'class initialization'].
			[#(Context class allInstances)]					-> [#enumerating].
			[#(Context class allInstancesDo:)]				-> [#enumerating].
			[#(Context failPrimitiveWith:)]					-> [#'system simulation'].
			[#(Context isPrimFailToken:)]					-> [#private].
			[#(Context send:to:with:lookupIn:)]				-> [#controlling].
			[#(ContextPart isPrimFailToken:)]				-> [#private].
			[#(ContextPart send:to:with:lookupIn:)]			-> [#controlling].
			[#(EncoderForV3 computeMethodHeaderForNumArgs:numTemps:numLits:primitive:)]
															-> [#'method encoding'].
			[#(EncoderForV3PlusClosures genCallPrimitive:)]
															-> [#'bytecode generation'].
			[#(EncoderForV3PlusClosures class callPrimitiveCode)]
															-> [#'bytecode decoding'].
			[#(InstructionClient callPrimitive:)]				-> [#'instruction decoding'].
			[#(MethodContext failPrimitiveWith:)]			-> [#'system simulation'].
			[#(MethodContext class allInstances)]			-> [#enumerating].
			[#(MethodContext class allInstancesDo:)]		-> [#enumerating].
			[#(Object isPinned)]							-> [#'system primitives'].
			[#(Object pin)]									-> [#'system primitives'].
			[#(Object setPinned:)]							-> [#'system primitives'].
			[#(Object unpin)]								-> [#'system primitives'].
			[#(SmallFloat64 class basicNew)]				-> [#'instance creation'].
			[#(SmallFloat64 class basicNew:)]				-> [#'instance creation'].
			[#(SmallFloat64 clone)]							-> [#copying].
			[#(SmallFloat64 copy)]							-> [#copying].
			[#(SmallFloat64 deepCopy)]					-> [#copying].
			[#(SmallFloat64 identityHash)]					-> [#comparing].
			[#(SmallFloat64 shallowCopy)]					-> [#copying].
			[#(SmallFloat64 veryDeepCopyWith:)]			-> [#copying].
			[#(SmallInteger asCharacter)]					-> [#converting].
			[#(SmalltalkImage growMemoryByAtLeast:)]	-> [#'memory space'].
			[#(SmalltalkImage maxIdentityHash)]			-> [#'system attributes'].
			[#(SystemDictionary growMemoryByAtLeast:)]	-> [#'memory space'].
			[#(SystemDictionary maxIdentityHash)]			-> [#'system attributes'].
			[#(SystemDictionary setGCParameters)]		-> [#'snapshot and quit'].
			[#(SystemNavigation allObjects)]				-> [#query].
			[#(SystemNavigation allObjectsOrNil)]			-> [#query].
			 }
		otherwise:
			[Transcript nextPutAll: className.
			 isMeta ifTrue: [Transcript nextPutAll: ' class'].
			 Transcript nextPutAll: '>>'; store: selector; nextPutAll: ' is unclassified'; cr; flush.
			 ^Categorizer default]
]

{ #category : #debugger }
SpurBootstrap class >> defaultIntegerBaseInDebugger [
	^16
]

{ #category : #utilities }
SpurBootstrap class >> isolatedPrototypes [
	"SpurBootstrap isolatedPrototypes"
	| prototypes |
	prototypes := (self systemNavigation allMethodsSelect:
						[:m| m selector includesSubString: 'PROTOTYPE'])
							collect: [:mr| mr compiledMethod].
	^prototypes select:
		[:m|
		(m methodClass includesBehavior: SpurBootstrapPrototypes)
			ifTrue:
				[(m pragmaAt: #indirect) notNil
				  and: [prototypes noneSatisfy:
						[:p|
						p selector == m selector
						and: [p methodClass ~~ m methodClass]]]]
			ifFalse:
				[prototypes noneSatisfy:
					[:p|
					p selector == m selector
					and: [(p methodClass includesBehavior: SpurBootstrapPrototypes)
					and: [(p pragmaAt: #indirect) notNil]]]]]
]

{ #category : #tests }
SpurBootstrap class >> testComputeFormat [
	"self testComputeFormat"
	#(	(normal 0)
		(bytes 16)
		(words 12)
		(variable 2)
		(weak 4)
		(ephemeron 5)
		(immediate 7)
		(compiledMethod 24)) do:
		[:tuple|
		 [:type :instSpec| | fmt |
		   fmt := [self ClassBuilderPROTOTYPEcomputeFormat: type instSize: 0 forSuper: Object ccIndex: 0]
					on: MessageNotUnderstood
					do: [:ex|
						ex message selector ~~ #format:variable:words:pointers:weak: ifTrue:
							[ex pass].
						self perform: #ClassBuilderPROTOTYPEformat:variable:words:pointers:weak:
							withArguments: ex message arguments].
		   self assert: (fmt >> 16 = instSpec
						or: [type = #compiledMethod and: [fmt = CompiledMethod format]]).
		 ] valueWithArguments: tuple]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> addMissingClassVars: classVars [
	"Add any missing class vars given classVars, a Dictionary from nonMetaClass to binding.
	 Initialize any classes that get inst vars added."
	| addClassVarNameSym bindingOfSym |
	classVars isEmpty ifTrue:
		[^self].
	addClassVarNameSym := self findSymbol: #addClassVarName:.
	addClassVarNameSym ifNil: 
		[addClassVarNameSym := self findSymbol: #addClassVarNamed:].
	bindingOfSym := self findSymbol: #bindingOf:.
	classVars keysAndValuesDo:
		[:binding :class| 
		Transcript cr;  nextPutAll: 'ADDING CLASS VAR '; store: binding key; nextPutAll: ' TO '; print: class; flush.
		self interpreter: oldInterpreter
			object: (self oldClassOopFor: class)
			perform: addClassVarNameSym
			withArguments: {oldHeap stringForCString: binding key}.
		literalMap
			at: binding
			put: (self interpreter: oldInterpreter
					object: (self oldClassOopFor: class)
					perform: bindingOfSym
					withArguments: {self findSymbol: binding key})].
	toBeInitialized := classVars asSet
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> addNewMethods [
	"Get the simulator to add any and all missing methods immediately."
	| cmaiaSym basSym |
	cmaiaSym := self findSymbol: #compiledMethodAt:ifAbsent:.
	basSym := self findSymbol: #basicAddSelector:withMethod:.
	basSym ifNil:
		[basSym := self findSymbol: #addSelectorSilently:withMethod:].
	self allPrototypeClassNamesDo:
		[:sym :symIsMeta|
		(self findClassNamed: (literalMap at: sym))
			ifNil: [Transcript
					cr;
					nextPutAll: 'not installing any methods for ';
					nextPutAll: sym;
					nextPutAll: '; class not found in image';
					flush.]
			ifNotNil:
				[:theClass| | class |
				class := symIsMeta ifTrue: [oldHeap fetchClassOfNonImm: theClass] ifFalse: [theClass].
				self prototypeClassNameMetaSelectorMethodDo:
					[:className :isMeta :selector :method| | methodOrNil |
					(className = sym
					 and: [symIsMeta = isMeta
					 and: [(method pragmaAt: #remove) isNil]]) ifTrue:
						["probe method dictionary of the class for each method, installing a dummy if not found."
						 "Transcript cr; nextPutAll: 'checking for '; nextPutAll: selector; flush."
						 methodOrNil := self interpreter: oldInterpreter
											object: class
											perform: cmaiaSym
											withArguments: {literalMap at: selector. oldHeap nilObject}.
						 methodOrNil = oldHeap nilObject
							ifTrue: "no method.  install the real thing now"
								[Transcript
									cr;
									nextPutAll: 'installing ';
									nextPutAll: className;
									nextPutAll: (isMeta ifTrue: [' class>>'] ifFalse: ['>>']);
									store: selector;
									flush.
								 self interpreter: oldInterpreter
									object: class
									perform: basSym
									withArguments: { literalMap at: selector.
													   self installableMethodFor: method
														selector: selector
														className: className
														isMeta: isMeta}.
								installedPrototypes add: method selector]
							ifFalse: "existing method; collect the methodClassAssociation; its needed later"
								[methodClasses add: (oldInterpreter methodClassAssociationOf: methodOrNil)]]]]]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> allInstancesOf: classOop [
	| instances |
	instances := OrderedCollection new.
	oldHeap allObjectsDo:
		[:o|
		((oldHeap isPointersNonImm: o)
		 and: [(oldHeap fetchClassOf: o) = classOop]) ifTrue:
			[instances addLast: o]].
	^instances
]

{ #category : #'method prototypes' }
SpurBootstrap >> allMethodPrototypes [
	"Answer all prototype selectors, including those marked <remove>"
	^(imageTypes 
		inject: (IdentitySet withAll: SpurBootstrapPrototypes allMethodPrototypes)
		into: [:allPrototypes :type | | prototypes |
			prototypes := (SpurBootstrapPrototypes prototypeClassFor: type) allMethodPrototypes.
			allPrototypes
				removeAllSuchThat: [:existing| prototypes anySatisfy: [:new| existing selector == new selector]];
				addAll: (prototypes reject: [:prototype| (prototype pragmaAt: #ignore) notNil]);
				yourself])
		asArray sort: [:ma :mb| ma selector <= mb selector]
]

{ #category : #'method prototypes' }
SpurBootstrap >> allPrototypeClassNamesDo: aBlock [
	"self basicNew allPrototypeClassNames"
	| pairs |
	pairs := Set new.
	self prototypeClassNameMetaSelectorMethodDo:
		[:className :isMeta :selector :method |
		pairs add: {className. isMeta}].
	pairs do: [:pair| aBlock value: pair first value: pair last]
]

{ #category : #'method prototypes' }
SpurBootstrap >> allPrototypeMethodSymbols [
	"self basicNew allPrototypeMethodSymbols"
	| symbols |
	self assert: SpurBootstrap isolatedPrototypes isEmpty.
	symbols := Set new.
	self prototypeClassNameMetaSelectorMethodDo:
		[:className :isMeta :selector :method | | adder |
		symbols
			add: className;
			add: selector.	
		adder := [:lit|
				   (lit isSymbol and: [lit ~~ method selector]) ifTrue: [symbols add: lit].
				   lit isArray ifTrue: [lit do: adder]].
		method literals do: adder].
	^symbols
]

{ #category : #'bootstrap image' }
SpurBootstrap >> allocateClassTable [
	"Allocate the root of the classTable plus enough pages to accomodate all classes in
	 the classToIndex map.  Don't fill in the entries yet; the classes have yet to be cloned."
	| tableRoot page maxSize numPages |
	tableRoot := newHeap
					allocateSlots: newHeap classTableRootSlots + newHeap hiddenRootSlots
					format: newHeap arrayFormat
					classIndex: newHeap arrayClassIndexPun.
	self assert: (newHeap numSlotsOf: tableRoot) = (newHeap classTableRootSlots + newHeap hiddenRootSlots).
	self assert: (newHeap formatOf: tableRoot) = newHeap arrayFormat.
	self assert: (newHeap classIndexOf: tableRoot) = newHeap arrayClassIndexPun.
	newHeap nilFieldsOf: tableRoot.
	"first page is strong"
	page := newHeap
					allocateSlots: newHeap classTablePageSize
					format: newHeap arrayFormat
					classIndex: newHeap arrayClassIndexPun.
	self assert: (newHeap numSlotsOf: page) = newHeap classTablePageSize.
	self assert: (newHeap formatOf: tableRoot) = newHeap arrayFormat.
	self assert: (newHeap classIndexOf: tableRoot) = newHeap arrayClassIndexPun.
	self assert: (newHeap objectAfter: tableRoot limit: newHeap freeStart) = page.
	lastClassTablePage := page.
	newHeap nilFieldsOf: page.
	newHeap storePointer: 0 ofObject: tableRoot withValue: page.
	newHeap setHiddenRootsObj: tableRoot.
	maxSize := classToIndex inject: 0 into: [:a :b| a max: b].
	numPages := (maxSize + newHeap classTableMinorIndexMask / newHeap classTablePageSize) truncated.
	2 to: numPages do:
		[:i|
		page := newHeap
					allocateSlots: newHeap classTablePageSize
					format: newHeap arrayFormat
					classIndex: newHeap arrayClassIndexPun.
		self assert: (newHeap numSlotsOf: page) = newHeap classTablePageSize.
		self assert: (newHeap formatOf: page) = newHeap arrayFormat.
		self assert: (newHeap classIndexOf: page) = newHeap arrayClassIndexPun.
		newHeap fillObj: page numSlots: newHeap classTablePageSize with: newHeap nilObject.
		newHeap storePointer: i - 1 ofObject: tableRoot withValue: page.
		self assert: (newHeap objectAfter: (newHeap fetchPointer: i - 2 ofObject: tableRoot)  limit: newHeap freeStart) = page.
		lastClassTablePage := page].
	"and once again to recompute numClassTablePages post building the class table."
	newHeap instVarNamed: 'numClassTablePages' put: nil.
	newHeap setHiddenRootsObj: tableRoot
]

{ #category : #'bootstrap image' }
SpurBootstrap >> allocateFreeLists [
	"Allocate the freeLists array."
	| freeListsOop |
	freeListsOop := newHeap
						allocateSlots: newHeap numFreeLists
						format: newHeap wordIndexableFormat
						classIndex: newHeap wordSizeClassIndexPun.
	self assert: (newHeap objectAfter: newHeap trueObject) = freeListsOop.
	0 to: newHeap numFreeLists - 1 do:
		[:i|
		newHeap
			storePointerUnchecked: i
			ofObject: freeListsOop
			withValue: 0]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> bootstrapImage [
	oldHeap fullGC.
	self measureOldHeapPostGC.
	self initMaps.
	Transcript cr; nextPutAll: 'transforming image...'; flush.
	self cloneNilTrueAndFalse.
	self allocateFreeLists.
	self buildClassMap.
	self allocateClassTable.
	self cloneObjects.
	self fillInObjects.
	self fillInClassTable.
	newHeapSize := newHeap freeStart.
	newHeap initializePostBootstrap.
	self measureNewHeapPostInitPostBootstrap
]

{ #category : #'public access' }
SpurBootstrap >> bootstrapImage: imageName [
	(Smalltalk classNamed: #FileReference) ifNotNil:
		[^self bootstrapImageUsingFileReference: imageName].
	(Smalltalk classNamed: #FileDirectory) ifNotNil:
		[^self bootstrapImageUsingFileDirectory: imageName].
	self error: 'at a loss as to what file system support to use'
]

{ #category : #'public access' }
SpurBootstrap >> bootstrapImage: imageName type: typeNameOrArrayOfTypeNames [
	"type can be:
		- 'squeak'
		- {'old squeak' 'squeak' }
		- { 'cuis' 'squeak' }
		- 'pharo'
		- it might be 'newspeak', if needed (but is not implemented)"
	imageTypes := typeNameOrArrayOfTypeNames isArray
						ifTrue: [typeNameOrArrayOfTypeNames]
						ifFalse: [{typeNameOrArrayOfTypeNames}].
	self bootstrapImage: imageName
	
]

{ #category : #'public access' }
SpurBootstrap >> bootstrapImageUsingFileDirectory: imageName [
	| dirName baseName dir |
	dirName := FileDirectory dirPathFor: imageName.
	baseName := (imageName endsWith: '.image')
					ifTrue: [FileDirectory baseNameFor: imageName]
					ifFalse: [FileDirectory localNameFor: imageName].
	dir := dirName isEmpty ifTrue: [FileDirectory default] ifFalse: [FileDirectory default on: dirName].
	self on: (dir fullNameFor: baseName, '.image').
	[self transform]
		on: Halt
		do: [:ex|
			"suppress halts from the usual suspects (development time halts)"
			(#(fullGC compactImage) includes: ex signalerContext sender selector)
				ifTrue: [ex resume]
				ifFalse: [ex pass]].
	self writeSnapshot: (dir fullNameFor: baseName, '-spur.image')
		ofTransformedImage: newHeap
		headerFlags: oldInterpreter getImageHeaderFlags
		screenSize: oldInterpreter savedWindowSize.
	dir deleteFileNamed: baseName, '-spur.changes';
		copyFileNamed: baseName, '.changes' toFileNamed: baseName, '-spur.changes'
]

{ #category : #'public access' }
SpurBootstrap >> bootstrapImageUsingFileReference: imageName [
	| dirName baseName dir |
	dirName := imageName asFileReference parent fullName.
	baseName := (imageName endsWith: '.image')
		ifTrue: [ imageName asFileReference base ]
		ifFalse: [ (imageName, '.image') asFileReference base ].
	dir := dirName asFileReference.
	self on: (dir / (baseName, '.image')) fullName.
	[self transform]
		on: Halt
		do: [:ex|
			"suppress halts from the usual suspects (development time halts)"
			(#(fullGC compactImage) includes: ex signalerContext sender selector)
				ifTrue: [ex resume]
				ifFalse: [ex pass]].
	self writeSnapshot: (dir / (baseName, '-spur.image')) fullName
		ofTransformedImage: newHeap
		headerFlags: oldInterpreter getImageHeaderFlags
		screenSize: oldInterpreter savedWindowSize.
	(dir / (baseName, '.changes')) copyTo: (dir / (baseName, '-spur.changes'))
]

{ #category : #'bootstrap image' }
SpurBootstrap >> buildClassMap [
	"enumerate all objects asking isBehavior:?  (class == Metaclass or class class == Metaclass) doesn't work for Newspeak"
	"Build a map from all classes in oldHeap to a class index.
	 ONLY DEALS WITH CLASSES THAT HAVE INSTANCES!! (can walk superclass chain?  Can walk subclasses set? Can ask class == Metaclass or class class == Metaclass class?)"
	| classes classTableIndex |
	self defineKnownClassIndices.
	classes := classToIndex keys asSet.
	classTableIndex := classToIndex inject: 0 into: [:a :b| a max: b].
	oldHeap allObjectsDo:
		[:oldObj| | oldClass |
		 oldClass := oldHeap fetchClassOfNonImm: oldObj.
		 self assert: (oldHeap isPointersNonImm: oldClass).
		 (classes includes: oldClass) ifFalse:
			[classes add: oldClass.
			 classToIndex at: oldClass put: (classTableIndex := classTableIndex + 1)]]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> checkReshapeOf: ourMethodClasses [
	"Check the shape of all our method classes match the shape of those in the image to be bootstrapped.
	 Use the simulator to redefine any that need it.  Does /not/ reshape metaclasses; these we assume are ok."
	| toReshape |
	toReshape := Set new.
	ourMethodClasses do:
		[:mc|
		(literalMap at: mc binding ifAbsent: []) ifNotNil:
			[:binding|
			(mc ~~ Character "Character will reshape anyway"
			 and: [mc instSize ~= (oldHeap instanceSizeOf: (oldHeap fetchPointer: ValueIndex ofObject: binding))]) ifTrue:
				[toReshape add: mc]]].
	toReshape isEmpty ifTrue:
		[^self].
	self interpreter: oldInterpreter
			object: (self oldClassOopFor: ClassBuilder)
			perform: (self findSymbol: #beSilent:)
			withArguments: {oldHeap trueObject}.
	"Assume only one class in any subtree needs reshaping.  Fast and loose but gets us there for now."
	toReshape copy do:
		[:class|
		toReshape removeAll: (toReshape select: [:ea| ea inheritsFrom: class])].
	toReshape do:
		[:class|
		Transcript cr;  nextPutAll: 'RESHAPING '; print: class; flush.
		self interpreter: oldInterpreter
			object: (self oldClassOopFor: Compiler)
			perform: (self findSymbol: #evaluate:)
			withArguments: {oldHeap stringForCString: class definition}]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> classMetaclass [
	^classMetaclass ifNil:
		[classMetaclass := oldHeap fetchClassOfNonImm: (oldHeap fetchClassOfNonImm: oldHeap classArray)]
]

{ #category : #'method prototypes' }
SpurBootstrap >> classNameForPrototypeMethod: protoMethod [
	| protoSelector |
	protoSelector := protoMethod selector.
	#('OLDSQUEAKPROTOTYPE' 'SQUEAKPROTOTYPE' 'PHAROPROTOTYPE' 'PROTOTYPE') do:
		[:prototype| | index |
		(index := protoSelector indexOfSubCollection: prototype) ~= 0 ifTrue:
			[^(protoSelector first: index - 1) asSymbol]].
	self error: 'really??'
]

{ #category : #'class indices' }
SpurBootstrap >> classTableSize [
	^newHeap classIndexMask + 1
]

{ #category : #'bootstrap image' }
SpurBootstrap >> clone: oldObj classIndex: classIndex [
	| newObj format numBytes |
	((format := oldHeap formatOf: oldObj) >= oldHeap firstLongFormat
	 and: [numBytes := oldHeap numBytesOf: oldObj.
		format >= oldHeap firstCompiledMethodFormat
		and: [(oldInterpreter primitiveIndexOf: oldObj) > 0]]) ifTrue:
			[numBytes := numBytes + 3].
	newObj := newHeap
				allocateSlots: (format >= oldHeap firstLongFormat
								ifTrue: [newHeap numSlotsForBytes: numBytes]
								ifFalse: [oldHeap numSlotsOf: oldObj])
				format: (self newFormatFor: oldObj numBytes: numBytes)
				classIndex: classIndex.
	reverseMap at: newObj put: oldObj.
	^map at: oldObj put: newObj
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> cloneArrayLiteral: anArray [
	"Currently serves only to clone the #(0 0) literal in SpaceTallyPROTOTYPEspaceForInstancesOf:"
	| array |
	array := oldHeap instantiateClass: (oldHeap splObj: ClassArray) indexableSize: anArray size.
	1 to: anArray size do:
		[:i| | lit |
		lit := anArray at: i.
		lit class caseOf: {
			[SmallInteger] -> [oldHeap
									storePointerUnchecked: i - 1
									ofObject: array
									withValue: (oldHeap integerObjectOf: lit)].
			[ByteSymbol] -> [oldHeap
									storePointer: i - 1
									ofObject: array
									withValue: (self findSymbol: lit)].
			[UndefinedObject] -> [oldHeap
									storePointerUnchecked: i - 1
									ofObject: array
									withValue: oldHeap nilObject] }].
	^array

]

{ #category : #'bootstrap methods' }
SpurBootstrap >> cloneMethodProxy: proxy [ "<VMCompiledMethodProxy>"
	| bytes newMethod delta |
	bytes := proxy size - proxy initialPC + 1.
	delta := proxy primitive > 0
				ifTrue: [3]
				ifFalse: [0].
	newMethod := CompiledMethod
						newMethod: bytes + delta
						header: (self headerForOldMethodHeader: (oldHeap integerObjectOf: proxy header)).
	1 to: proxy numLiterals - 1 do:
		[:i| newMethod literalAt: i put: (proxy literalAt: i)].
	newMethod
		literalAt: proxy numLiterals
		put: (Smalltalk bindingOf: #Character).
	delta > 0 ifTrue:
		[newMethod
			at: newMethod initialPC + 0 put: 139;
			at: newMethod initialPC + 1 put: (proxy primitive bitAnd: 16rFF);
			at: newMethod initialPC + 2 put: (proxy primitive bitShift: -8)].
	proxy initialPC to: proxy size do:
		[:i| newMethod at: i + delta put: (proxy at: i)].
	^newMethod
]

{ #category : #'bootstrap image' }
SpurBootstrap >> cloneNilTrueAndFalse [
	{	oldHeap nilObject.
		oldHeap falseObject.
		oldHeap trueObject. }
		with: (self firstOrdinaryClassIndex to: self firstOrdinaryClassIndex + 2)
		do: [:obj :classIndex|
			classToIndex at: (oldHeap fetchClassOfNonImm: obj) put: classIndex.
			self clone: obj classIndex: classIndex].
	newHeap
		nilObject: (map at: oldHeap nilObject); "needed for nilling objects etc"
		falseObject: (map at: oldHeap falseObject);
		trueObject: (map at: oldHeap trueObject)
]

{ #category : #'bootstrap image' }
SpurBootstrap >> cloneObjects [
	| specialObjectsArray characterClass characterTable compactClasses oldObj oldClass |
	specialObjectsArray := oldHeap specialObjectsOop.
	characterClass := oldHeap classCharacter.
	characterTable := oldHeap characterTable.
	compactClasses := oldHeap splObj: CompactClasses.
	self clone: specialObjectsArray
		classIndex: (classToIndex at: (oldHeap fetchClassOfNonImm: specialObjectsArray)).
	oldObj := oldHeap objectAfter: oldHeap trueObject.
	[oldObj < oldHeap freeStart] whileTrue:
		[oldClass := oldHeap fetchClassOfNonImm: oldObj.
		 (oldObj ~= characterTable
		 and: [oldObj ~= specialObjectsArray
		 and: [oldObj ~= compactClasses
		 and: [oldClass ~= characterClass]]]) ifTrue:
			[self clone: oldObj classIndex: (classToIndex at: oldClass)].
		 oldObj := oldHeap objectAfter: oldObj].
	newHeap
		specialObjectsOop: (map at: oldHeap specialObjectsOop);
		lastHash: oldHeap lastHash
]

{ #category : #testing }
SpurBootstrap >> coHeapFrom: aSpur32BitMMLESimulator [
	| coHeap |
	coHeap := Spur32BitMMLECoSimulator new.
	aSpur32BitMMLESimulator class allInstVarNames do:
		[:ivn|
		coHeap instVarNamed: ivn put: (aSpur32BitMMLESimulator instVarNamed: ivn)].
	coHeap scavenger instVarNamed: 'manager' put: coHeap.
	^coHeap
]

{ #category : #'bootstrap image' }
SpurBootstrap >> compactImage [
	| firstFree lastUsed |
	newHeap allHeapEntitiesDo:
		[:o|
		(newHeap isFreeObject: o)
			ifTrue: [firstFree ifNil: [firstFree := o]]
			ifFalse: [lastUsed := o]].
	lastUsed < firstFree ifTrue: "nothing to do"
		[^self].
	self halt
]

{ #category : #'bootstrap image' }
SpurBootstrap >> convertOldMethodHeader: methodHeader [
	^((oldInterpreter argumentCountOfMethodHeader: methodHeader) << 24)
	 + ((oldInterpreter temporaryCountOfMethodHeader: methodHeader) << 18)
	 + ((oldInterpreter methodHeaderIndicatesLargeFrame: methodHeader) ifTrue: [1 << 17] ifFalse: [0])
	 + ((oldInterpreter methodHeaderHasPrimitive: methodHeader) ifTrue: [1 << 16] ifFalse: [0])
	 + (oldHeap literalCountOfMethodHeader: methodHeader)
]

{ #category : #'class indices' }
SpurBootstrap >> defineKnownClassIndices [
	"The classTable is laid out
		- to make it easy to map immediates to classes; the tag pattern of an immediate is its class index.
		  hence there are two entries for SmallInteger
		- to assign small indices to well-known classes such as Array, Message et al
		- to leave plenty of room for new known classes; hence the first page contains only well-known classes
		- to enable overlaps and avoid conflicts with indices in the specialObjectsArray (?really? eem)
		- to provide a WeakArray pun for the pages of the table itself so that these do not show up as instances of WeakArray"
	| classMethodContext classBlockClosure classMessage "no api method for these" |
	classMessage := oldHeap splObj: (VMObjectIndices bindingOf: #ClassMessage) value.
	classMethodContext := oldHeap splObj: (VMObjectIndices bindingOf: #ClassMethodContext) value.
	classBlockClosure := oldHeap splObj: (VMObjectIndices bindingOf: #ClassBlockClosure) value.
	"c.f. SpurMemoryManager class>>intializeCompactClassIndices".
	classToIndex keysDo:
		[:oldClass|
		self assert: (oldInterpreter addressCouldBeClassObj: oldClass)].
	classToIndex
		at: oldHeap classSmallInteger put: 1; "N.B. must fill-in index 3 manually"
		at: oldHeap classCharacter put: 2;
		"at: oldHeap classSmallInteger put: 3" "N.B. must fill-in index 3 manually"
		"leave room for up to 15 tagged classes"
		"leave room for up to 16 puns"
		at: oldHeap classLargeNegativeInteger put: 32;
		at: oldHeap classLargePositiveInteger put: 33;
		at: oldHeap classFloat put: 34;

		at: "oldHeap" classMessage put: 35;
		at: "oldHeap" classMethodContext put: (classMethodContextIndex := 36);
		at: "oldHeap" classBlockClosure put: (classBlockClosureIndex := 37);

		at: oldHeap classSemaphore put: 48;
		"at: oldHeap classMutex put: 49; see below"

		at: oldHeap classByteArray put: 50;
		at: oldHeap classArray put: 51;
		at: oldHeap classString put: 52;
		at: oldHeap classBitmap put: 53;
		at: oldHeap classPoint put: 54.

	{{oldHeap classMutex. 49}.
	 {oldHeap classExternalAddress. 128}.
	 {oldHeap classExternalData. 129}.
	 {oldHeap classExternalFunction. 130}.
	 {oldHeap classExternalLibrary. 131}.
	 {oldHeap classExternalStructure. 132}.
	 {oldHeap classAlien. 133}.
	 {oldHeap classUnsafeAlien. 134}}
		do: [:pair|
			[:oop :index|
			oop ~= oldHeap nilObject ifTrue:
				[classToIndex at: oop put: index]] valueWithArguments: pair].

	classToIndex keysDo:
		[:oldClass|
		self assert: (oldInterpreter addressCouldBeClassObj: oldClass)]
]

{ #category : #'public access' }
SpurBootstrap >> fileOutPrototypesFor: imageTypeOrArrayOfTypes [
	"SpurBootstrap new fileOutPrototypesFor: 'squeak'"
	| internalStream |
	imageTypes := imageTypeOrArrayOfTypes isString
						ifTrue: [{imageTypeOrArrayOfTypes}]
						ifFalse: [imageTypeOrArrayOfTypes asArray].
	internalStream := WriteStream on: (String new: 1000).
	internalStream header; timeStamp.
	self prototypeClassNameMetaSelectorMethodDo:
		[:className :isMeta :selector :method| | classNameString class category preamble source |
		class := Smalltalk classNamed: className.
		isMeta
			ifTrue: [class := class class. classNameString := className, ' class']
			ifFalse: [classNameString := className].
		(method pragmaAt: #remove)
			ifNil:
				[category := class ifNotNil: [class organization categoryOfElement: selector].
				 (category notNil and: [category first = $*]) ifTrue:
					[category := nil].
				 category ifNil:
					[category := self class categoryForClass: className meta: isMeta selector: selector].
				preamble := classNameString, ' methodsFor: ' , category asString printString, ' stamp: ''', method timeStamp, ''''.
				internalStream nextPut: $!; nextChunkPut: preamble; cr.
				source := method getSourceFromFile asString.
				source := source copyFrom: (source indexOfSubCollection: 'PROTOTYPE') + 9 to: source size.
				(self selectorForPrototypeMethod: method) isBinary ifTrue:
					[source := (self selectorForPrototypeMethod: method), (source copyFrom: (source indexOf: Character space) to: source size)].
				internalStream nextChunkPut: source; space; nextPut: $!; cr; cr]
			ifNotNil:
				[source := classNameString, ' removeSelector: ', selector storeString.
				 internalStream nextChunkPut: source; cr; cr]].
	internalStream trailer.

	FileStream
		writeSourceCodeFrom: internalStream
		baseName: ('SpurBootstrapPrototypes-', (imageTypes fold: [:a :b| a, '-', b]) replaceAll: Character space with: $_)
		isSt: true
		useHtml: false
]

{ #category : #'bootstrap image' }
SpurBootstrap >> fillInClassTable [
	| firstPage maxIndex |
	maxIndex := 0.
	classToIndex keysAndValuesDo:
		[:oldClass :index| | newClass page |
		maxIndex := maxIndex max: index.
		newClass := map at: oldClass.
		self assert: (newHeap isPointersNonImm: newClass).
		newHeap setHashBitsOf: newClass to: index.
		page := newHeap
					fetchPointer: index >> newHeap classTableMajorIndexShift
					ofObject: newHeap classTableRootObj.
		newHeap
			storePointer: (index bitAnd: newHeap classTableMinorIndexMask)
			ofObject: page
			withValue: newClass.
		self assert: (newHeap classAtIndex: index) = newClass].
	firstPage := newHeap
					fetchPointer: 0
					ofObject: newHeap classTableRootObj.
	newHeap
		storePointer: 1
			ofObject: firstPage
				withValue: (map at: oldHeap classSmallInteger);
		storePointer: 2
			ofObject: firstPage
				withValue: (map at: oldHeap classCharacter);
		storePointer: 3
			ofObject: firstPage
				withValue: (map at: oldHeap classSmallInteger);
		storePointer: newHeap arrayClassIndexPun
			ofObject: firstPage
				withValue: (map at: oldHeap classArray);
		storePointer: newHeap arrayClassIndexPun
			ofObject: firstPage
				withValue: (map at: oldHeap classArray).

	newHeap classTableIndex: maxIndex
]

{ #category : #'bootstrap image' }
SpurBootstrap >> fillInCompiledMethod: newObj from: oldObj [
	| firstByteIndex primIndex |
	self fillInPointerObject: newObj from: oldObj.
	"Now convert the CompiledMethod's format.  First write the header in the new format"
	newHeap
		storePointerUnchecked: 0
		ofObject: newObj
		withValue: (newHeap integerObjectOf: (self convertOldMethodHeader: (oldHeap fetchPointer: 0 ofObject: oldObj))).
	"Then if necessary prepend the callPrimitive: bytecode"
	(primIndex := oldInterpreter primitiveIndexOf: oldObj) > 0
		ifTrue:
			[firstByteIndex := oldHeap lastPointerOf: oldObj.
			 newHeap
				storeByte: firstByteIndex + 0 ofObject: newObj withValue: 139;
				storeByte: firstByteIndex + 1 ofObject: newObj withValue: (primIndex bitAnd: 255);
				storeByte: firstByteIndex + 2 ofObject: newObj withValue: (primIndex bitShift: -8).
			 firstByteIndex to: (oldHeap numBytesOfBytes: oldObj) - 1 do:
				[:i|
				newHeap storeByte: i + 3 ofObject: newObj withValue: (oldHeap fetchByte: i ofObject: oldObj)]]
		ifFalse:
			[(oldHeap lastPointerOf: oldObj) / oldHeap wordSize to: (oldHeap numSlotsOf: oldObj) - 1 do:
				[:i|
				newHeap storeLong32: i ofObject: newObj withValue: (oldHeap fetchLong32: i ofObject: oldObj)]]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> fillInObjects [
	oldHeap allObjectsDo:
		[:oldObj|
		(map at: oldObj ifAbsent: nil) ifNotNil:
			[:newObj| | format classIndex |
			format := newHeap formatOf: newObj.
			(newHeap isPointersFormat: format)
				ifTrue:
					[((newHeap isIndexableFormat: format)
						and: [(classIndex := newHeap classIndexOf: newObj) <= classBlockClosureIndex
						and: [classIndex >= classMethodContextIndex]])
						ifTrue: [self fillInPointerObjectWithPC: newObj from: oldObj]
						ifFalse: [self fillInPointerObject: newObj from: oldObj]]
				ifFalse:
					[(newHeap isCompiledMethodFormat: format)
						ifTrue: [self fillInCompiledMethod: newObj from: oldObj]
						ifFalse: [self fillInBitsObject: newObj from: oldObj]]]]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> fillInPointerObject: newObj from: oldObj [
	"Fill-in a newObj with appropriately mapped contents from oldObj.
	 Filter-out the character table and the compact classes array.
	 Map character objects to immediate characters."
	0 to: (oldHeap lastPointerOf: oldObj) / oldHeap wordSize - 1 do:
		[:i| | oldValue newValue |
		oldValue := oldHeap fetchPointer: i ofObject: oldObj.
		newValue := (oldHeap isIntegerObject: oldValue)
						ifTrue: [oldValue]
						ifFalse:
							[map at: oldValue ifAbsent:
								[(oldValue = oldHeap characterTable
								  or: [oldValue = (oldHeap splObj: CompactClasses)])
									ifTrue: [newHeap nilObject]
									ifFalse:
										[self assert: (oldHeap fetchClassOfNonImm: oldValue) = oldHeap classCharacter.
										 newHeap characterObjectOf:
											(oldHeap integerValueOf:
												(oldHeap fetchPointer: CharacterValueIndex ofObject: oldValue))]]].
		newHeap
			storePointerUnchecked: i
			ofObject: newObj
			withValue: newValue].
	(self isOldObjABehavior: oldObj) ifTrue:
		[self mapOldBehavior: oldObj toNewBehavior: newObj]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> fillInPointerObjectWithPC: newObj from: oldObj [
	"Fill-in a newObj with appropriately mapped contents from oldObj.
	 If the object has a pc and its method has a primitive, increment the
	 pc by the size of the callPrimitive: bytecode."
	| method |
	self fillInPointerObject: newObj from: oldObj.
	(newHeap classIndexOf: newObj) = classBlockClosureIndex ifTrue:
		[method := oldHeap
						fetchPointer: MethodIndex
						ofObject: (oldHeap
									fetchPointer: ClosureOuterContextIndex
									ofObject: oldObj).
		 (oldInterpreter primitiveIndexOf: method) > 0 ifTrue:
			[self incrementPCField: ClosureStartPCIndex ofObject: newObj by: 3]].
	(newHeap classIndexOf: newObj) = classMethodContextIndex ifTrue:
		[method := oldHeap
						fetchPointer: MethodIndex
						ofObject: oldObj.
		 (method ~= oldHeap nilObject
		  and: [(oldInterpreter primitiveIndexOf: method) > 0]) ifTrue:
			[self incrementPCField: InstructionPointerIndex ofObject: newObj by: 3]].
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> findClassNamed: symbolOop [ 
	oldHeap allObjectsDo:
		[:o|
		((oldHeap isPointersNonImm: o)
		 and: [(oldInterpreter addressCouldBeClassObj: o)
		 and: [(oldHeap fetchPointer: oldInterpreter classNameIndex ofObject: o) = symbolOop]]) ifTrue:
			[^o]].
	^nil
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> findLiteral: aLiteral inClass: classOop [
	| bindingOrNil |
	aLiteral isString ifTrue:
		[^self stringFor: aLiteral].
	aLiteral isFloat ifTrue:
		[^oldHeap floatObjectOf: aLiteral].
	aLiteral isArray ifTrue:
		[^self cloneArrayLiteral: aLiteral].
	aLiteral isCharacter ifTrue:
		[^oldHeap characterObjectOf: aLiteral asciiValue].
	self assert: aLiteral isVariableBinding.
	bindingOrNil := self interpreter: oldInterpreter
						object: classOop
						perform: (self findSymbol: #bindingOf:)
						withArguments: {self findSymbol: aLiteral key}.
	bindingOrNil ~= oldHeap nilObject ifTrue:
		[^bindingOrNil].
	self error: 'couldn''t find literal ', aLiteral printString
]

{ #category : #'bootstrap image' }
SpurBootstrap >> findRequiredGlobals [
	"Look for the necessary gobal bindings in the prototype methods in the old image.
	 This has to be done early by sending bindingOf: to Smalltalk.  Collect the class
	 hierarchy of all prototypes that access inst vars (non-local prototypes) to check
	 their shapes.  Also find out Metaclass, needed for identifying classes."
	| globals ourMethodClasses classVars bindingOfSym |
	globals := Set new.
	ourMethodClasses := Set new.
	classVars := Dictionary new.
	self prototypeClassNameMetaSelectorMethodDo:
		[:c :m :s :method| | allNonMetaSupers |
		(Smalltalk classNamed: c) ifNotNil:
			[:nonMetaClass|
			allNonMetaSupers := nonMetaClass withAllSuperclasses.
			(method methodClass includesBehavior: SpurBootstrapPrototypes) ifFalse:
				[ourMethodClasses addAll: allNonMetaSupers.
				 globals addAll: (allNonMetaSupers collect: [:sc| sc binding])].
			method literals do:
				[:l|
				(l isVariableBinding
				 and: [l key isSymbol
				 and: [SpurBootstrapPrototypes withAllSubclasses noneSatisfy: [:sbpc| sbpc name == l key]]]) ifTrue:
					[((Smalltalk bindingOf: l key) == l
					  or: [(Undeclared bindingOf: l key) == l])
						ifTrue: [globals add: l]
						ifFalse:
							[self assert: (nonMetaClass bindingOf: l key) == l.
							classVars at: l put: nonMetaClass]]]]].
	globals add: Compiler binding. "For potential reshaping in checkReshapeOf:"
	bindingOfSym := self findSymbol: #bindingOf:.
	self withExecutableInterpreter: oldInterpreter
		do:	[| toBeAdded |
			globals do:
				[:global| | bindingOop |
				(self findSymbol: global key) ifNotNil:
					[:symbolOop|
					bindingOop := self interpreter: oldInterpreter
										object: (oldHeap splObj: 8) "Smalltalk"
										perform: bindingOfSym
										withArguments: {self findSymbol: global key}.
					bindingOop ~= oldHeap nilObject ifTrue:
						[literalMap at: global put: bindingOop]]].
			 toBeAdded := Dictionary new.
			 classVars keysAndValuesDo:
				[:var :class| | val |
				(self findSymbol: var key) "New class inst vars may not yet be interned."
					ifNil: [toBeAdded at: var put: class]
					ifNotNil:
						[:varName|
						val := self interpreter: oldInterpreter
									object: (self oldClassOopFor: class)
									perform: bindingOfSym
									withArguments: {varName}.
						val ~= oldHeap nilObject
							ifTrue: [literalMap at: var put: val]
							ifFalse: [toBeAdded at: var put: class]]].
			"May have to redefine to add missing inst vars and/or add any missing class vars."
			self checkReshapeOf: ourMethodClasses.
			self addMissingClassVars: toBeAdded]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> findSymbol: aString [
	"Find the Symbol equal to aString in oldHeap."
	| symbolClass |
	(literalMap at: aString ifAbsent: nil) ifNotNil:
		[:oop| ^oop].
	symbolClass := self symbolClass.
	oldHeap allObjectsDo:
		[:obj|
		(symbolClass = (oldHeap fetchClassOfNonImm: obj)
		 and: [(oldHeap numBytesOf: obj) = aString size
		 and: [aString = (oldHeap stringOf: obj)]]) ifTrue:
			[aString isSymbol ifTrue:
				[literalMap at: aString asSymbol put: obj].
			 ^obj]].
	Transcript cr; nextPutAll: 'Warning, could not find '; store: aString; flush.
	^nil
]

{ #category : #'class indices' }
SpurBootstrap >> firstOrdinaryClassIndex [
	^newHeap classTablePageSize
]

{ #category : #'bootstrap image' }
SpurBootstrap >> followForwardingPointers [
	newHeap allObjectsDo:
		[:o|
		(newHeap isForwarded: o) ifFalse:
			[0 to: (newHeap numPointerSlotsOf: o) - 1 do:
				[:i| | field |
				field := newHeap fetchPointer: i ofObject: o.
				(newHeap isOopForwarded: field) ifTrue:
					[newHeap
						storePointer: i
						ofObject: o
						withValue: (newHeap followForwarded: field)]]]]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> freeForwarders [
	"Check that all forwarders have been followed.  Then free them."
	| numForwarders numFreed |
	numForwarders := numFreed := 0.
	newHeap allObjectsDo:
		[:o|
		(newHeap isForwarded: o)
			ifTrue: [numForwarders := numForwarders + 1]
			ifFalse:
				[0 to: (newHeap numPointerSlotsOf: o) - 1 do:
					[:i|
					self assert: (newHeap isOopForwarded: (newHeap fetchPointer: i ofObject: o)) not]]].
	Transcript ensureCr;  nextPutAll: 'freeing '; print: numForwarders; nextPutAll: ' forwarders'; cr; flush.
	newHeap allObjectsDo:
		[:o|
		(newHeap isForwarded: o) ifTrue:
			[numFreed := numFreed + 1.
			 newHeap freeObject: o]].
	self assert: numFreed = numForwarders
]

{ #category : #'bootstrap image' }
SpurBootstrap >> headerForOldMethodHeader: methodHeaderOop [
	^self isOnSpur
		ifTrue: [self convertOldMethodHeader: methodHeaderOop]
		ifFalse: [oldHeap integerValueOf: methodHeaderOop]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> imageTypes: anArray [
	imageTypes := anArray
]

{ #category : #'bootstrap image' }
SpurBootstrap >> incrementPCField: fieldIndex ofObject: newObj by: n [
	| value |
	value := newHeap fetchPointer: fieldIndex ofObject: newObj.
	(newHeap isIntegerObject: value)
		ifTrue:
			[newHeap
				storePointerUnchecked: fieldIndex
				ofObject: newObj
				withValue: (newHeap integerObjectOf: n + (newHeap integerValueOf: value))]
		ifFalse:
			[self assert: value = newHeap nilObject]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> indexOfSelector: selectorOop in: methodDict [
	SelectorStart to: (oldHeap numSlotsOf: methodDict) - 1 do:
		[:i|
		(oldHeap fetchPointer: i ofObject: methodDict) = selectorOop ifTrue:
			[^i]].
	self error: 'could not find selector in method dict'
]

{ #category : #'initialize-release' }
SpurBootstrap >> initMaps [
	map := Dictionary new: oldHeap memory size // 4.
	reverseMap := Dictionary new: oldHeap memory size // 4.
	classToIndex := Dictionary new: 1024.
	literalMap := IdentityDictionary new.
	methodClasses := Set new.
	installedPrototypes := Set new.
	installedMethodOops := Set new.
	classMetaclass := nil
]

{ #category : #'initialize-release' }
SpurBootstrap >> initialize [
	super initialize.
	imageTypes := {'squeak'}. "By default, image is Squeak (so Eliot does not kick me :P)"
]

{ #category : #'bootstrap image' }
SpurBootstrap >> initializeClasses [
	toBeInitialized ifNil: [^self].
	self withExecutableInterpreter: oldInterpreter
		do: [toBeInitialized do:
				[:class|
				self interpreter: oldInterpreter
					object: (self oldClassOopFor: class)
					perform: (self findSymbol: #initialize)
					withArguments: #()]]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> installModifiedMethods [
	"Install all the methods in the class-side method prototypes protocol in the relevant classes
	 in the new image.  First use the simulator to get the image to intern all symbols and add
	 dummy methods under new selectors.  With that done we can manually replace the relevant
	 methods with the prototypes, mapping selectors and global variables as required."
	self withExecutableInterpreter: oldInterpreter
		do: [self internAllSymbols.
			 self addNewMethods.
			 self removeMethods.
			 self replaceMethods.
			 self modifyCharacterMethods]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> installableMethodFor: aCompiledMethod selector: selector className: className isMeta: isMeta [
	"Create a sourceless method to install in the bootstrapped image.  It will allow the
	 bootstrap to limp along until the relevant transformed Monticello package is loaded."
	| compiledMethodClass methodClassBinding methodClass sourcelessMethod bytes newMethod delta initialPC |
	compiledMethodClass := self findClassNamed: (self findSymbol: #CompiledMethod).
	methodClassBinding := self methodClassBindingForClassName: className isMeta: isMeta.
	methodClass := oldHeap fetchPointer: ValueIndex ofObject: methodClassBinding.
	"the prototypes have source pointers.  the Character methods to be replaced don't."
	sourcelessMethod := aCompiledMethod trailer hasSourcePointer
							ifTrue: [aCompiledMethod copyWithTempsFromMethodNode: aCompiledMethod methodNode]
							ifFalse: [aCompiledMethod].
	initialPC := sourcelessMethod initialPC.
	bytes := sourcelessMethod size - initialPC + 1.
	"Ugh, this is complicated.  We could be running on Spur with the new method format
	 or on non-Spur with the old format.  Make both work."
	delta := (sourcelessMethod primitive > 0
			 and: [(sourcelessMethod at: initialPC) = sourcelessMethod encoderClass callPrimitiveCode])
				ifTrue: [3]
				ifFalse: [0].
	newMethod := self
					interpreter: oldInterpreter
					object: compiledMethodClass
					perform: (self findSymbol: #newMethod:header:)
					withArguments: { oldHeap integerObjectOf: bytes - delta.
									   oldHeap integerObjectOf: (self oldFormatHeaderFor: sourcelessMethod) }.
	1 to: sourcelessMethod numLiterals - 2 do:
		[:i| | literal oop |
		literal := sourcelessMethod literalAt: i.
		oop := (literal isLiteral or: [literal isVariableBinding])
					ifTrue:
						[literal isInteger
							ifTrue: [oldInterpreter signed64BitIntegerFor: literal]
							ifFalse: [literalMap
										at: literal
										ifAbsent: [self findLiteral: literal
														inClass: methodClass]]]
					ifFalse: "should be a VMObjectProxy"
						[literal oop].
		oldHeap storePointer: i ofObject: newMethod withValue: oop].
	oldHeap
		storePointer: sourcelessMethod numLiterals - 1
		ofObject: newMethod
		withValue: (selector isSymbol
						ifTrue: [self findSymbol: selector]
						ifFalse: [selector oop]);
		storePointer: sourcelessMethod numLiterals
		ofObject: newMethod
		withValue: methodClassBinding.
	initialPC to: sourcelessMethod size - delta do:
		[:i|
		oldHeap storeByte: i - 1 ofObject: newMethod withValue: (sourcelessMethod byteAt: i + delta)].
	installedMethodOops add: newMethod.
	^newMethod
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> internAllSymbols [
	"Ensure that all symbols in the method prototypes are interned so that later we can install them.
	 Enter them into the map, this system's symbol -> oldHeap's version.
	 Do this by interpreting Symbol intern: 'aSymbol' for each symbol."
	| internSym all symbolClass |
	internSym := self findSymbol: #intern:.
	symbolClass := self symbolClass.
	all := self allPrototypeMethodSymbols.
	oldHeap allObjectsDo:
		[:objOop| | sz |
		symbolClass = (oldHeap fetchClassOfNonImm: objOop) ifTrue:
			[sz := oldHeap numBytesOf: objOop.
			 (all detect: [:sym| sym size = sz and: [sym = (oldHeap stringOf: objOop)]]
				ifNone: nil) ifNotNil:
					[:sym|
					literalMap at: sym put: objOop.
					all remove: sym]]].
	all do: [:sym|
		(self findSymbol: sym)
			ifNotNil: [:imageSym| literalMap at: sym put: imageSym]
			ifNil:[Transcript cr; nextPutAll: 'interning '; nextPutAll: sym; flush.
				"Interpret Symbol intern: sym to ... intern it :-)"
				literalMap
					at: sym
					put: (self interpreter: oldInterpreter
							object: self symbolClass
							perform: internSym
							withArguments: {self stringFor: sym})]].
	literalMap keysAndValuesDo:
		[:symOrGlobal :imageSymOrGlobal|
		symOrGlobal isSymbol ifTrue:
			[self assert: symOrGlobal = (oldHeap stringOf: imageSymOrGlobal)]]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> isOldObjABehavior: oldObj [
	| oldObjClass |
	^(classToIndex includesKey: oldObj)
	or: [(oldObjClass := oldHeap fetchClassOfNonImm: oldObj) = self classMetaclass
	or: [(oldHeap fetchClassOfNonImm: oldObjClass) = classMetaclass]]
]

{ #category : #testing }
SpurBootstrap >> isOnSpur [
	^$c class instSize = 0
]

{ #category : #testing }
SpurBootstrap >> launch [
	self launch: newHeap
		simulatorClass: StackInterpreterSimulator
		headerFlags: oldInterpreter getImageHeaderFlags
]

{ #category : #testing }
SpurBootstrap >> launch: heap simulatorClass: simulatorClass headerFlags: headerFlags [
	| sim methodCacheSize |
	sim := simulatorClass onObjectMemory: heap.
	heap coInterpreter: sim.
	(sim class allInstVarNames includes: 'cogCodeSize')
		ifTrue:
			[sim initializeInterpreter: 0.
			 methodCacheSize := sim methodCache size * heap wordSize.
			 sim instVarNamed: 'heapBase' put: heap startOfMemory;
				instVarNamed: 'numStackPages' put: 8;
				instVarNamed: 'cogCodeSize' put: 1024*1024;
				moveMethodCacheToMemoryAt: sim cogCodeSize + sim computeStackZoneSize;
				movePrimTraceLogToMemoryAt: sim cogCodeSize + sim computeStackZoneSize + methodCacheSize;
				"sendTrace: 1+ 2 + 8 + 16;"
			 	initializeCodeGenerator]
		ifFalse:
			[sim initializeInterpreter: 0].
	heap
		initializeNewSpaceVariables;
		bootstrapping: false;
		assimilateNewSegment: (heap segmentManager segments at: 0).
	sim
		setImageHeaderFlagsFrom: headerFlags;
		imageName: ImageName;
		flushExternalPrimitives;
		openAsMorph;
		transcript: Transcript. "deep copy copies this"
	"sim
		instVarNamed: 'printSends' put: true;
		instVarNamed: 'printReturns' put: true;
		instVarNamed: 'methodDictLinearSearchLimit' put: SmallInteger maxVal." "for now"
	heap
		setCheckForLeaks: 0;
		runLeakCheckerForFullGC.

	sim halt; run
]

{ #category : #testing }
SpurBootstrap >> launchSaved [
	self launch: TransformedImage veryDeepCopy
		simulatorClass: StackInterpreterSimulator
		headerFlags: ImageHeaderFlags
]

{ #category : #testing }
SpurBootstrap >> launchSavedWithJIT [
	self launch: (self coHeapFrom: TransformedImage veryDeepCopy)
		simulatorClass: CogVMSimulator
		headerFlags: ImageHeaderFlags
]

{ #category : #'bootstrap image' }
SpurBootstrap >> mapOldBehavior: oldObj toNewBehavior: newObj [
	"Map the old format inst var's value to the new value.
	 In addition, for Character, make it immediate and remove its instance variable."
	newHeap
		storePointerUnchecked: InstanceSpecificationIndex
		ofObject: newObj
		withValue: (self newClassFormatFor: oldObj).
	oldObj = oldHeap classCharacter ifTrue:
		[InstanceSpecificationIndex + 1 to: (oldHeap numSlotsOf: oldObj) do:
			[:i| | var field |
			var := oldHeap fetchPointer: i ofObject: oldObj.
			((oldHeap fetchClassOf: var) = oldHeap classArray
			 and: [(oldHeap numSlotsOf: var) = 1
			 and: [field := oldHeap fetchPointer: 0 ofObject: var.
				(oldHeap fetchClassOf: field) = oldHeap classString
			 and: [(oldHeap lengthOf: field) = 5
			 and: [(oldHeap str: 'value'  n: (oldHeap firstIndexableField: field) cmp: 5) = 0]]]]) ifTrue:
				[newHeap
					storePointerUnchecked: i
					ofObject: newObj
					withValue: newHeap nilObject.
				 ^self]]]
]

{ #category : #stats }
SpurBootstrap >> measureNewHeapPostInitPostBootstrap [
	| savedEndOfMemory |
	"need to hack around the fact that newHeap isn't all there yet.
	 In particular, it has no freeList so can't free space from
	 freeOldSpaceStart to endOfMemory to make oldSpace enumerable."
	newHeapNumObjs := 0.
	savedEndOfMemory := newHeap endOfMemory.
	newHeap setEndOfMemory: newHeap freeOldSpaceStart.
	newHeap allObjectsDo: [:o| newHeapNumObjs := newHeapNumObjs + 1].
	newHeap setEndOfMemory: savedEndOfMemory
]

{ #category : #stats }
SpurBootstrap >> measureOldHeapPostGC [
	oldHeapSize := oldHeap freeStart.
	oldHeapNumObjs := 0.
	oldHeap allObjectsDo: [:o| oldHeapNumObjs := oldHeapNumObjs + 1]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> methodClassBindingForClassName: classNameSymbol isMeta: isMeta [ 
	| class |
	class := self findClassNamed: (literalMap at: classNameSymbol).
	isMeta ifTrue: [class := oldHeap fetchClassOfNonImm: class].
	^self interpreter: oldInterpreter
		object: class
		perform: (self findSymbol: #binding)
		withArguments: #()
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> modifyCharacterMethods [
	| cc md mda |
	cc := oldHeap classCharacter.
	md := oldHeap fetchPointer: MethodDictionaryIndex ofObject: cc.
	mda := oldHeap fetchPointer: MethodArrayIndex ofObject: md..
	0 to: (oldHeap numSlotsOf: mda) - 1 do:
		[:i| | method |
		method := oldHeap fetchPointer: i ofObject: mda.
		method ~= oldHeap nilObject ifTrue:
			[(self replacementForCharacterMethod: method) ifNotNil:
				[:replacement|
				Transcript
					cr;
					nextPutAll: 'replacing Character>>#';
					nextPutAll: (oldHeap stringOf: (oldHeap fetchPointer: i + SelectorStart ofObject: md));
					flush. 
				oldHeap
					storePointer: i
					ofObject: mda
					withValue: replacement]]]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> newClassFormatFor: oldClassObj [
	"OLD: 		<2 bits=instSize//64><5 bits=cClass><4 bits=instSpec><6 bits=instSize\\64><1 bit=0>
	 NEW: 		<5 bits inst spec><16 bits inst size>"
	| oldFormat instSize newInstSpec |
	((oldInterpreter classNameOf: oldClassObj Is: 'SmallInteger')
	 or: [(oldInterpreter classNameOf: oldClassObj Is: 'Character')
	 or: [oldInterpreter classNameOf: oldClassObj Is: 'SmallFloat64']]) ifTrue:
		[^newHeap integerObjectOf: newHeap instSpecForImmediateClasses << 16].
	oldFormat := oldHeap formatOfClass: oldClassObj. "N.B. SmallInteger with tag bit cleared"
	oldFormat := oldFormat >> 1.
	instSize := ((oldFormat bitShift: -10) bitAnd: 16rC0) + ((oldFormat bitShift: -1) bitAnd: 16r3F) - 1.
	newInstSpec := #(0 1 2 3 4 nil 10 9 16 16 16 16 24 24 24 24) at: ((oldFormat bitShift: -7) bitAnd: 16rF) + 1.
	^newHeap integerObjectOf: newInstSpec << 16 + instSize
]

{ #category : #'bootstrap image' }
SpurBootstrap >> newFormatFor: oldObj numBytes: numBytesIfBits [
	"OLD:
	 0	no fields
	 1	fixed fields only (all containing pointers)
	 2	indexable fields only (all containing pointers)
	 3	both fixed and indexable fields (all containing pointers)
	 4	both fixed and indexable weak fields (all containing pointers).

	 5	unused
	 6	indexable word fields only (no pointers)
	 7	indexable long (64-bit) fields (only in 64-bit images)
 
	 8-11	indexable byte fields only (no pointers) (low 2 bits are low 2 bits of size)
	 12-15	compiled methods:
	 	    # of literal oops specified in method header,
	 	    followed by indexable bytes (same interpretation of low 2 bits as above)"

	"NEW:
	 0 = 0 sized objects (UndefinedObject True False et al)
	 1 = non-indexable objects with inst vars (Point et al)
	 2 = indexable objects with no inst vars (Array et al)
	 3 = indexable objects with inst vars (MethodContext AdditionalMethodState et al)
	 4 = weak indexable objects with inst vars (WeakArray et al)
	 5 = weak non-indexable objects with inst vars (ephemerons) (Ephemeron)
	 6 = reserved
	 7 = forwarder format (also immediate class format)
	 9          64-bit indexable
	 10 - 11 32-bit indexable
	 12 - 15 16-bit indexable
	 16 - 23 byte indexable
	 24 - 31 compiled method"
	| oldFormat |
	oldFormat := oldHeap formatOf: oldObj.
	oldFormat <= 4 ifTrue:
		[^oldFormat].
	oldFormat >= 12 ifTrue: "CompiledMethod"
		[^24 + (self wordSize - numBytesIfBits bitAnd: self wordSizeMask)].
	oldFormat >= 8 ifTrue: "ByteArray et al"
		[^16 + (self wordSize - numBytesIfBits bitAnd: self wordSizeMask)].
	oldFormat = 6 ifTrue: "32-bit indexable"
		[^10 + (numBytesIfBits bitAnd: self wordSizeMask) sign].
	oldFormat = 7 ifTrue: "64-bit indexable"
		[^9].
	self error: 'illegal old format'
]

{ #category : #'bootstrap image' }
SpurBootstrap >> oldClassOopFor: aClass [
	^oldHeap fetchPointer: ValueIndex ofObject: (literalMap at: aClass binding).
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> oldFormatHeaderFor: method [
	| primBits primitive |
	primitive := method primitive.
	primBits := primitive <= 16r1FF
					ifTrue: [primitive]
					ifFalse: [(primitive bitAnd: 16r1FF) + ((primitive bitAnd: 16r200) bitShift: 19)].
	^(method numArgs bitShift: 24)
	+ (method numTemps bitShift: 18)
	+ (method frameSize > method class smallFrameSize ifTrue: [1 << 17] ifFalse: [0])
	+ (method numLiterals bitShift: 9)
	+ primBits
]

{ #category : #'initialize-release' }
SpurBootstrap >> on: imageName [
	StackInterpreter initializeWithOptions: Dictionary new.
	(oldInterpreter := StackInterpreterSimulator new)
		openOn: imageName extraMemory: 0;
		assertValidExecutionPointersAtEachStep: false.
	oldHeap := oldInterpreter objectMemory.
	newHeap := Spur32BitMMLESimulator new.
	newHeap
		allocateMemoryOfSize: (oldHeap youngStart * 3 / 2 roundUpTo: 1024 * 1024)
		newSpaceSize: 4 * 1024 * 1024
		stackSize: 16 * 1024
		codeSize: 0.
	newHeap setCheckForLeaks: 15 - 6. "don't check become; or newSpace; soooo many rehashes in bootstrap"
	newHeap bootstrapping: true.
	self initMaps
]

{ #category : #'method prototypes' }
SpurBootstrap >> prototypeClassNameMetaSelectorMethodDo: quaternaryBlock [
	"Evaluate aBlock with class name, class is meta, method and selector.
	 For now find methods in class-side category #'method prototypes'.
	 Scheme could be extended to have different protocols for different
	 Squeak/Pharo versions."
	self allMethodPrototypes do:
		[:methodArg| | method className isMeta |
		className := self classNameForPrototypeMethod: (method := methodArg).
		(isMeta := className endsWith: 'class') ifTrue:
			[className := (className allButLast: 5) asSymbol].
		(method pragmaAt: #indirect) ifNotNil:
			[method := (isMeta
							ifTrue: [(Smalltalk classNamed: className) class]
							ifFalse: [Smalltalk classNamed: className]) >> method selector].
		quaternaryBlock
			value: className
			value: isMeta
			value: (self selectorForPrototypeMethod: method)
			value: method]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> recreateSpecialObjectsArray [
	"This is tricky.  We want to recreate the specialObjectsArray according to
	 the class side SmalltalkImagePROTOTYPErecreateSpecialObjectsArray.
	 But that version destroys the CompactClassesArray upon which the V3
	 image depends.  The bootstrap will get rid of it later.  So save it before
	 the recreation and restore it."
	self withExecutableInterpreter: oldInterpreter
		do: [| compactClassesArray |
			compactClassesArray := oldHeap splObj: CompactClasses.
			self
				interpreter: oldInterpreter
				object: (oldHeap splObj: 8)
				perform: (self findSymbol: #recreateSpecialObjectsArray)
				withArguments: #().
			oldHeap splObj: CompactClasses put: compactClassesArray]
]

{ #category : #'bootstrap image' }
SpurBootstrap >> rehashImage [
	"Rehash all collections in newHeap.
	 Find out which classes implement rehash, entering a 1 against their classIndex in rehashFlags.
	 Enumerate all objects, rehashing those whose class has a bit set in rehashFlags."
	| n sim rehashFlags dotDate rehashSym sizeSym |
	rehashSym := map at: (self findSymbol: #rehash).
	sizeSym := map at: (self findSymbol: #size).
	sim := StackInterpreterSimulator 
				onObjectMemory: newHeap 
				options: #(ObjectMemory #Spur32BitMemoryManager).
	sim 
		setImageHeaderFlagsFrom: oldInterpreter getImageHeaderFlags;
		imageName: 'spur image';
		assertValidExecutionPointersAtEachStep: false..
	newHeap coInterpreter: sim.
	sim bootstrapping: true.
	sim initializeInterpreter: 0.
	sim instVarNamed: 'methodDictLinearSearchLimit' put: SmallInteger maxVal.
	(imageTypes includes: 'cuis') ifTrue:
		[newHeap scavenger growRememberedSet]. "Rehashing a 4.2 Cuis image overflows the 768 element high tide."
	
	sim redirectTranscriptToHost.

	newHeap
		setHashBitsOf: newHeap nilObject to: 1;
		setHashBitsOf: newHeap falseObject to: 2;
		setHashBitsOf: newHeap trueObject to: 3.

	rehashFlags := ByteArray new: newHeap numClassTablePages * newHeap classTablePageSize.
	n := 0.
	newHeap classTableObjectsDo:
		[:class| | classIndex |
		sim messageSelector: rehashSym.
		"Lookup rehash but don't be fooled by ProtoObject>>rehash, which is just ^self."
		((sim lookupOrdinaryNoMNUEtcInClass: class) = 0
		 and: [(sim isQuickPrimitiveIndex: (sim primitiveIndexOf: (sim instVarNamed: 'newMethod'))) not]) ifTrue:
			[n := n + 1.
			 classIndex := newHeap rawHashBitsOf: class.
			 rehashFlags
				at: classIndex >> 3 + 1
				put: ((rehashFlags at: classIndex >> 3 + 1)
						bitOr: (1 << (classIndex bitAnd: 7)))]].
	Transcript cr; print: n; nextPutAll: ' classes understand rehash. rehashing instances...'; flush.
	dotDate := Time now asSeconds.
	n := 0.
	self withExecutableInterpreter: sim
		do: [sim setBreakSelector: 'error:'.
			 "don't rehash twice (actually without limit), so don't rehash any new objects created."
			 newHeap allExistingOldSpaceObjectsDo:
				[:o| | classIndex |
				classIndex := newHeap classIndexOf: o.
				((rehashFlags at: classIndex >> 3 + 1) anyMask: 1 << (classIndex bitAnd: 7)) ifTrue:
					[Time now asSeconds > dotDate ifTrue:
					 	[Transcript nextPut: $.; flush.
						 dotDate := Time now asSeconds].
					 "2845 = n ifTrue: [self halt]."
					 "Rehash an object if its size is > 0.
					  Symbol implements rehash, but let's not waste time rehashing it; in Squeak
					  up to 2013 symbols are kept in a set which will get reashed anyway..
					  Don't rehash empty collections; they may be large for a reason and rehashing will shrink them."
					 ((sim addressCouldBeClassObj: o)
					   or: [(self interpreter: sim
							object: o
							perform: sizeSym
							withArguments: #()) = (newHeap integerObjectOf: 0)]) ifFalse:
						[self interpreter: sim
							object: o
							perform: rehashSym
							withArguments: #()]]]]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> removeMethods [
	"Get the simulator to remove any methods marked with <remove>."
	| removeSym |
	removeSym := self findSymbol: #removeSelectorSilently:.
	removeSym ifNil:
		[removeSym := self findSymbol: #removeSelector:].
	self prototypeClassNameMetaSelectorMethodDo:
		[:className :isMeta :selector :method| | class |
		(method pragmaAt: #remove) ifNotNil:
			[(self findClassNamed: (literalMap at: className)) ifNotNil:
				[:theClass|
				 class := isMeta ifTrue: [oldHeap fetchClassOfNonImm: theClass] ifFalse: [theClass].
				 Transcript
					cr;
					nextPutAll: 'removing ';
					nextPutAll: className;
					nextPutAll: (isMeta ifTrue: [' class>>'] ifFalse: ['>>']);
					store: selector;
					flush.
				 self interpreter: oldInterpreter
					object: class
					perform: removeSym
					withArguments: {literalMap at: selector}]]]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> replaceMethods [
	"Replace all the modified method prototypes."
	self allPrototypeClassNamesDo:
		[:sym :symIsMeta|
		(self findClassNamed: (literalMap at: sym))
			ifNil: [Transcript
					cr;
					nextPutAll: 'not replacing any methods for ';
					nextPutAll: sym;
					nextPutAll: '; class not found in image';
					flush.]
			ifNotNil:
				[:theClass| | class |
				class := symIsMeta ifTrue: [oldHeap fetchClassOfNonImm: theClass] ifFalse: [theClass].
				self prototypeClassNameMetaSelectorMethodDo:
					[:className :isMeta :selector :method| | replacement methodDict index |
					(className = sym
					 and: [symIsMeta = isMeta
					 and: [(method pragmaAt: #remove) isNil]]) ifTrue:
						[(installedPrototypes includes: method selector) ifFalse:
							["probe method dictionary of the class for each method, installing a dummy if not found."
							Transcript
								cr;
								nextPutAll: 'replacing ';
								nextPutAll: className;
								nextPutAll: (isMeta ifTrue: [' class>>'] ifFalse: ['>>']);
								store: selector;
								flush.
							replacement := self installableMethodFor: method
												selector: selector
												className: className
												isMeta: isMeta.
							methodDict := oldHeap fetchPointer: MethodDictionaryIndex ofObject: class.
							index := self indexOfSelector: (literalMap at: selector) in: methodDict.
							oldHeap
								storePointer: index - SelectorStart
								ofObject: (oldHeap fetchPointer: MethodArrayIndex ofObject: methodDict)
								withValue: replacement.
							installedPrototypes add: method selector]]]]]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> replacementForCharacterMethod: characterMethodOop [
	"Answer a replacement method for the argument if it refers
	 to Character's old inst var value.  Otherwise answer nil."
	| proxy asIntegerProxy clone assembly newInsts newMethod |
	"(oldHeap stringOf: (oldHeap longAt: characterMethodOop + (oldHeap lastPointerOf: characterMethodOop) - 4)) = 'isOctetCharacter' ifTrue:
		[self halt]."
	"Don't replace something already installed."
	(installedMethodOops includes: characterMethodOop) ifTrue:
		[^nil].
	proxy := VMCompiledMethodProxy new
				for: characterMethodOop
				coInterpreter: oldInterpreter
				objectMemory: oldHeap.
	self assert: (oldHeap literalCountOf: characterMethodOop) = proxy numLiterals.
	clone := self cloneMethodProxy: proxy.
	self assert: proxy numLiterals = clone numLiterals.
	clone isReturnSpecial ifTrue:
		[^nil].
	"Quick methods accessing value should have been replaced.  The halt will fire if there
	 is a missing prototype for such a method on the class side of SpurBootstrap.  The
	 relevant Character prototypes there so far are Character>>asInteger, Character>>
	 asciiValue, Character>>hash & Character>>identityHash.  Conceivably the bootstrap
	 could be applied to an image that has others; hence the halt."
	clone isReturnField ifTrue: [self halt].
	clone hasInstVarRef ifFalse:
		[^nil].
	clone setSourcePointer: 0.
	asIntegerProxy := VMObjectProxy new
							for: (literalMap at: #asInteger)
							coInterpreter: oldInterpreter
							objectMemory: oldHeap.
	assembly := BytecodeDisassembler new disassemble: clone.
	assembly literals: (assembly literals allButLast: 2), {asIntegerProxy}, (assembly literals last: 2).
		"Do this by looking for index of pushReceiverVariable: and replacing it by pushSelf, send asInteger"
	newInsts := (assembly instructions piecesCutWhere:
					[:msgOrLabelAssoc :nextInst|
					 msgOrLabelAssoc isVariableBinding not
					 and: [msgOrLabelAssoc selector == #pushReceiverVariable:]]) fold:
				[:a :b|
				 a allButLast,
				 {	Message selector: #pushReceiver.
					Message
						selector: #send:super:numArgs:
						arguments: {asIntegerProxy. false. 0}},
				 b].
	assembly instructions: newInsts.
	newMethod := assembly assemble.
	self assert: clone numLiterals + 1 = newMethod numLiterals.
	^self
		installableMethodFor: newMethod
		selector: clone selector
		className: #Character
		isMeta: false
]

{ #category : #'bootstrap image' }
SpurBootstrap >> reportSizes [
	| change oldAvgBytes newAvgBytes |
	change := newHeapSize - oldHeapSize / oldHeapSize.
	oldAvgBytes := oldHeapSize asFloat / oldHeapNumObjs.
	Transcript
		nextPutAll: 'done.'; cr;
		nextPutAll: 'old heap size: '; nextPutAll: oldHeapSize asStringWithCommas; tab;
		nextPutAll: ' (avg obj bytes '; print: oldAvgBytes maxDecimalPlaces: 2; nextPutAll: ' words '; print: oldAvgBytes / self wordSize maxDecimalPlaces: 2; nextPut: $); cr;
		nextPutAll: 'initial new heap size: '; nextPutAll: newHeapSize asStringWithCommas; cr;
		nextPutAll: 'change: '; print: change * 100.0 maxDecimalPlaces: 2; nextPut: $%; cr;
		flush.
	newHeapSize := newHeap endOfMemory
					- newHeap scavenger eden limit
					- newHeap totalFreeListBytes.
	change := newHeapSize - oldHeapSize / oldHeapSize.
	newAvgBytes := newHeapSize asFloat / newHeapNumObjs.
	Transcript
		nextPutAll: 'final new heap size: '; nextPutAll: newHeapSize asStringWithCommas; tab;
		nextPutAll: ' (avg obj bytes '; print: newAvgBytes maxDecimalPlaces: 2; nextPutAll: ' words '; print: newAvgBytes / self wordSize maxDecimalPlaces: 2; nextPut: $); cr;
		nextPutAll: 'change: '; print: change * 100.0 maxDecimalPlaces: 2; nextPut: $%; cr;
		flush
]

{ #category : #'development support' }
SpurBootstrap >> saveTransformedImage [
	ImageHeaderFlags := oldInterpreter getImageHeaderFlags.
	ImageScreenSize := oldInterpreter savedWindowSize.
	ImageName := oldInterpreter imageName.
	newHeap coInterpreter: nil.
	(newHeap class allInstVarNames select: [:ivn| ivn beginsWith: 'stat']) do:
		[:ivn| newHeap instVarNamed: ivn put: 0].
	TransformedImage := newHeap veryDeepCopy
]

{ #category : #'bootstrap image' }
SpurBootstrap >> scavengeImage [
	"Scavenge the image to get it into a simpler state."
	newHeap coInterpreter voidVMStateForSnapshotFlushingExternalPrimitivesIf: false.
	newHeap flushNewSpace
]

{ #category : #'method prototypes' }
SpurBootstrap >> selectorForPrototypeMethod: protoMethod [
	| protoSelector |
	protoSelector := protoMethod selector.
	protoSelector := protoSelector last: protoSelector size
						- (protoSelector indexOfSubCollection: 'PROTOTYPE')
						- 'PROTOTYPE' size
						+ 1.
	(protoSelector beginsWith: 'Dollar') ifTrue:
		[protoSelector := (Dictionary newFromPairs: #('DollarEquals:' #=))
							at: protoSelector].
	^protoSelector asSymbol
]

{ #category : #'bootstrap image' }
SpurBootstrap >> silenceImage [
	"Turn off change notifications via SystemChangeNotifier"
	(self allInstancesOf: (self findClassNamed: (self findSymbol: #SystemChangeNotifier))) do:
		[:obj | oldHeap storePointer: 1 ofObject: obj withValue: (oldHeap integerObjectOf: 1)]
]

{ #category : #'bootstrap methods' }
SpurBootstrap >> stringFor: aString [
	| string |
	string := oldHeap instantiateClass: (oldHeap splObj: ClassByteString) indexableSize: aString size.
	1 to: aString size do:
		[:i| oldHeap storeByte: i - 1 ofObject: string withValue: (aString at: i) asInteger].
	^string

]

{ #category : #'bootstrap methods' }
SpurBootstrap >> symbolClass [
	^oldHeap fetchClassOfNonImm: (oldHeap splObj: SelectorDoesNotUnderstand)
]

{ #category : #'bootstrap image' }
SpurBootstrap >> transform [
      self silenceImage.
	self findRequiredGlobals.
	self installModifiedMethods.
	self recreateSpecialObjectsArray.
	self initializeClasses.
	self bootstrapImage.
	self validate.
	self rehashImage.
	self followForwardingPointers.
	self scavengeImage.
	self freeForwarders.
	self compactImage.
	self reportSizes
]

{ #category : #'bootstrap image' }
SpurBootstrap >> validate [
	| p n duplicates maxClassIndex savedEndOfMemory |
	self assert: (reverseMap at: newHeap specialObjectsOop) = oldHeap specialObjectsOop.
	self assert: (map at: oldHeap specialObjectsOop) = newHeap specialObjectsOop.
	self assert: (reverseMap at: newHeap classTableRootObj ifAbsent: []) isNil.

	duplicates := { 3. newHeap arrayClassIndexPun. newHeap weakArrayClassIndexPun }.
	maxClassIndex := classToIndex inject: 0 into: [:a :b| a max: b].
	self assert: ((newHeap arrayClassIndexPun to: maxClassIndex) select:
					[:idx| | classObj |
					(classObj := newHeap classOrNilAtIndex: idx) ~= newHeap nilObject
					and: [(newHeap classIndexOf: classObj) = (newHeap rawHashBitsOf: classObj)]]) isEmpty.
	0 to: maxClassIndex do:
		[:index| | classObj |
		(index <= newHeap tagMask
		 and: [index > newHeap isForwardedObjectClassIndexPun]) ifTrue:
			[(classObj := newHeap classOrNilAtIndex: index) = newHeap nilObject
				ifTrue:
					[self assert: (classToIndex keyAtValue: index ifAbsent: []) isNil]
				ifFalse:
					[self assert: (newHeap classIndexOf: classObj) ~= (newHeap rawHashBitsOf: classObj).
					(duplicates includes: index) ifFalse:
						[self assert: (newHeap rawHashBitsOf: classObj) = index]]]].
	classToIndex keysAndValuesDo:
		[:oldClass :idx|
		self assert: (newHeap rawHashBitsOf: (map at: oldClass)) = idx. 
		self assert: oldClass = (reverseMap at: (newHeap classAtIndex: idx))].
	n := 0.
	savedEndOfMemory := newHeap endOfMemory.
	newHeap setEndOfMemory: newHeap freeOldSpaceStart.
	newHeap allObjectsDo:
		[:o|
		(o <= newHeap trueObject
		 or: [o > lastClassTablePage]) ifTrue:
			[self assert: (reverseMap includesKey: o).
			 self assert: (newHeap fetchClassOfNonImm: o) = (map at: (oldHeap fetchClassOfNonImm: (reverseMap at: o)))].
		n := n + 1.
		p := o].
	newHeap setEndOfMemory: savedEndOfMemory.
	self touch: p.
	self assert: (n between: map size and: map size + ((imageTypes includes: 'squeak')
														ifTrue: [6]
														ifFalse: [10])). "+ 6 or 10 is room for freelists & classTable"

	"check some class properties to ensure the format changes are correct"
	self assert: (newHeap fixedFieldsOfClassFormat: (newHeap formatOfClass: newHeap classArray)) = 0.
	self assert: (newHeap instSpecOfClassFormat: (newHeap formatOfClass: newHeap classArray)) = newHeap arrayFormat
]

{ #category : #'word size' }
SpurBootstrap >> wordSize [
	^self subclassResponsibility
]

{ #category : #'word size' }
SpurBootstrap >> wordSizeMask [
	^self subclassResponsibility
]

{ #category : #testing }
SpurBootstrap >> writeSnapshot: imageFileName ofTransformedImage: spurHeap headerFlags: headerFlags screenSize: screenSizeInteger [
	"The bootstrapped image typically contains a few big free chunks and one huge free chunk.
	 Test snapshot writing and loading by turning the largest non-huge chunks into segment bridges
	 and saving."
	| penultimate ultimate sim |
	sim := StackInterpreterSimulator onObjectMemory: spurHeap.
	sim bootstrapping: true.
	spurHeap
		coInterpreter: sim;
		setEndOfMemory: spurHeap endOfMemory + spurHeap bridgeSize. "hack; initializeInterpreter: cuts it back by bridgeSize"
	sim initializeInterpreter: 0;
		setImageHeaderFlagsFrom: headerFlags;
		setSavedWindowSize: screenSizeInteger;
		setDisplayForm: nil.
	spurHeap allOldSpaceEntitiesDo: [:e| penultimate := ultimate. ultimate := e].
	"Check that we've left behind the old, pre-pigCompact segmented save"
	self assert: (spurHeap isFreeObject: penultimate) not.
	spurHeap checkFreeSpace.
	spurHeap runLeakCheckerForFullGC.
	sim bereaveAllMarriedContextsForSnapshotFlushingExternalPrimitivesIf: true.
	sim imageName: imageFileName.
	sim writeImageFileIO.
	Transcript cr; show: 'Done!'
]
