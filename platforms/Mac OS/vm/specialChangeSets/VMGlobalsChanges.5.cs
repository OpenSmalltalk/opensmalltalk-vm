'From Squeak3.5alpha of ''7 January 2003'' [latest update: #5169] on 9 April 2003 at 4:33:07 pm'!
"Change Set:		VMGlobalsChanges
Date:			5 April 2003
Author:			tim@sumeru.stanford.edu, johnmci@smalltalkconsulting.com

Seconds pass at combining all the changes needed to add the VM global structure support into a single filein.
This incorporates:-
MoreInterpAccessors-JMM
GlobalStructure-JMM
GlobalsRiscOS-tpr
GCMakeItFaster-JMM
GCCMakeItFasterGStruct-JMM
VMGlobalsCleanups-tpr
VMGLobalsReStructure-JMM
"!

Object subclass: #CCodeGenerator
	instanceVariableNames: 'translationDict inlineList constants variables variableDeclarations methods variablesSetCache headerFiles pluginName extraDefs postProcesses isCPP globalVariableUsage '
	classVariableNames: 'UseRightShiftForDivide '
	poolDictionaries: ''
	category: 'VMConstruction-Translation to C'!
CCodeGenerator subclass: #CCodeGeneratorGlobalStructure
	instanceVariableNames: 'localStructDef '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMConstruction-Translation to C'!
Object subclass: #ObjectMemory
	instanceVariableNames: 'memory youngStart endOfMemory memoryLimit nilObj falseObj trueObj specialObjectsOop rootTable rootTableCount child field parentField freeBlock lastHash allocationCount lowSpaceThreshold signalLowSpace compStart compEnd fwdTableNext fwdTableLast remapBuffer remapBufferCount allocationsBetweenGCs tenuringThreshold statFullGCs statFullGCMSecs statIncrGCs statIncrGCMSecs statTenures statRootTableOverflows freeContexts freeLargeContexts interruptCheckCounter displayBits totalObjectCount shrinkThreshold growHeadroom headerTypeBytes '
	classVariableNames: 'AllButHashBits AllButMarkBit AllButMarkBitAndTypeMask AllButRootBit AllButTypeMask BaseHeaderSize BlockContextProto CharacterTable ClassArray ClassBitmap ClassBlockContext ClassByteArray ClassCharacter ClassCompiledMethod ClassExternalAddress ClassExternalData ClassExternalFunction ClassExternalLibrary ClassExternalStructure ClassFloat ClassInteger ClassLargeNegativeInteger ClassLargePositiveInteger ClassMessage ClassMethodContext ClassPoint ClassProcess ClassPseudoContext ClassSemaphore ClassString ClassTranslatedMethod CompactClassMask CompactClasses ConstMinusOne ConstOne ConstTwo ConstZero CtxtTempFrameStart DoAssertionChecks DoBalanceChecks Done ExternalObjectsArray FalseObject FloatProto GCTopMarker HashBits HashBitsOffset HeaderTypeClass HeaderTypeFree HeaderTypeGC HeaderTypeShort HeaderTypeSizeAndClass LargeContextBit LargeContextSize MarkBit MethodContextProto NilContext NilObject RemapBufferSize RootBit RootTableSize SchedulerAssociation SelectorAboutToReturn SelectorCannotInterpret SelectorCannotReturn SelectorDoesNotUnderstand SelectorMustBeBoolean SizeMask SmallContextSize SpecialSelectors StackStart StartField StartObj TheDisplay TheFinalizationSemaphore TheInputSemaphore TheInterruptSemaphore TheLowSpaceSemaphore TheTimerSemaphore TrueObject TypeMask Upward '
	poolDictionaries: ''
	category: 'VMConstruction-Interpreter'!
ObjectMemory subclass: #Interpreter
	instanceVariableNames: 'activeContext theHomeContext method receiver instructionPointer stackPointer localIP localSP localHomeContext messageSelector argumentCount newMethod currentBytecode successFlag primitiveIndex methodCache atCache lkupClass reclaimableContextCount nextPollTick nextWakeupTick lastTick interruptKeycode interruptPending semaphoresToSignalA semaphoresUseBufferA semaphoresToSignalCountA semaphoresToSignalB semaphoresToSignalCountB savedWindowSize fullScreenFlag deferDisplayUpdates pendingFinalizationSignals compilerInitialized compilerHooks extraVMMemory newNativeMethod methodClass receiverClass interpreterVersion obsoleteIndexedPrimitiveTable obsoleteNamedPrimitiveTable interpreterProxy showSurfaceFn interruptCheckCounterFeedBackReset interruptChecksEveryNms externalPrimitiveTable cntx val '
	classVariableNames: 'ActiveProcessIndex AtCacheEntries AtCacheFixedFields AtCacheFmt AtCacheMask AtCacheOop AtCacheSize AtCacheTotalSize AtPutBase BlockArgumentCountIndex BytecodeTable CacheProbeMax CallerIndex CharacterValueIndex CompilerHooksSize CrossedX DirBadPath DirEntryFound DirNoMoreEntries EndOfRun ExcessSignalsIndex FirstLinkIndex GenerateBrowserPlugin HeaderIndex HomeIndex InitialIPIndex InstanceSpecificationIndex InstructionPointerIndex JitterTable LastLinkIndex LiteralStart MaxExternalPrimitiveTableSize MaxPrimitiveIndex MessageArgumentsIndex MessageDictionaryIndex MessageLookupClassIndex MessageSelectorIndex MethodArrayIndex MethodCacheClass MethodCacheEntries MethodCacheEntrySize MethodCacheMask MethodCacheMethod MethodCacheNative MethodCachePrim MethodCacheSelector MethodCacheSize MethodIndex MillisecondClockMask MyListIndex NextLinkIndex PrimitiveExternalCallIndex PrimitiveTable PriorityIndex ProcessListsIndex ReceiverIndex SelectorStart SemaphoresToSignalSize SenderIndex StackPointerIndex StreamArrayIndex StreamIndexIndex StreamReadLimitIndex StreamWriteLimitIndex SuperclassIndex SuspendedContextIndex TempFrameStart ValueIndex XIndex YIndex '
	poolDictionaries: ''
	category: 'VMConstruction-Interpreter'!
Object subclass: #TMethod
	instanceVariableNames: 'selector returnType args locals declarations primitive parseTree labels possibleSideEffectsCache complete export static comment definingClass globalStructureBuildMethodHasFoo '
	classVariableNames: 'CaseStatements '
	poolDictionaries: ''
	category: 'VMConstruction-Translation to C'!

!CCodeGenerator methodsFor: 'public' stamp: 'tpr 1/10/2003 15:56'!
codeStringForPrimitives: classAndSelectorList 
"TPR - appears to be obsolete now"
	self addMethodsForPrimitives: classAndSelectorList.
	^self generateCodeStringForPrimitives! !

!CCodeGenerator methodsFor: 'public' stamp: 'JMM 12/28/2002 17:30'!
initialize
	translationDict _ Dictionary new.
	inlineList _ Array new.
	constants _ Dictionary new: 100.
	variables _ OrderedCollection new: 100.
	variableDeclarations _ Dictionary new: 100.
	methods _ Dictionary new: 500.
	self initializeCTranslationDictionary.
	headerFiles _ OrderedCollection new.
	isCPP _ false.
	globalVariableUsage _ Dictionary new.
! !

!CCodeGenerator methodsFor: 'public' stamp: 'JMM 11/28/2002 11:52'!
isGlobalStructureBuild
	^false! !

!CCodeGenerator methodsFor: 'inlining' stamp: 'JMM 4/17/2002 12:02'!
pruneUnreachableMethods
	"Remove any methods that are not reachable. Retain methods needed by the BitBlt operation table, primitives, plug-ins, or interpreter support code."
 
	| retain |
	"Build a set of selectors for methods that should be output even though they have no apparent callers. Some of these are stored in tables for indirect lookup, some are called by the C support code or by primitives."
	retain _ BitBltSimulation opTable asSet.
	#(checkedLongAt: fullDisplayUpdate interpret printCallStack printAllStacks
	   readImageFromFile:HeapSize:StartingAt: success:
		"Windows needs the following two for startup and debug"
	   readableFormat: getCurrentBytecode
		"Jitter reuses all of these"
	   allocateChunk: characterForAscii:
	   findClassOfMethod:forReceiver: findSelectorOfMethod:forReceiver:
	   firstAccessibleObject loadInitialContext noteAsRoot:headerLoc:
	   nullCompilerHook
	   primitiveFloatAdd primitiveFloatDivide primitiveFloatMultiply
	   primitiveFloatSubtract primitiveFlushExternalPrimitives
	   setCompilerInitialized: splObj:
		"accessors needed for global structure support"
	   getFullScreenFlag getInterruptCheckCounter getInterruptKeycode getInterruptPending
	   getNextWakeupTick getSavedWindowSize setFullScreenFlag: setInterruptCheckCounter:
	   setInterruptKeycode: setInterruptPending: setNextWakeupTick: setSavedWindowSize:
	)
			do: [:sel | retain add: sel].
	InterpreterProxy organization categories do: [:cat |
		((cat ~= 'initialize') and: [cat ~= 'private']) ifTrue: [
			retain addAll: (InterpreterProxy organization listAtCategoryNamed: cat)]].

	"Remove all the unreachable methods that aren't retained for the reasons above."
	self unreachableMethods do: [:sel |
		(retain includes: sel) ifFalse: [
			methods removeKey: sel ifAbsent: []]].
! !

!CCodeGenerator methodsFor: 'utilities' stamp: 'JMM 3/27/2003 18:26'!
checkForGlobalUsage: vars in: aTMethod 
	| item |
	vars
		do: [:var | 
			"TPR - why the use of globalsAsSet here instead of globalVariables? 
			JMM - globalVariables is not initialized yet, variables is an OrderedCollection, 
				globalsAsSet returns variables as needed set"
			(self globalsAsSet includes: var)
				ifTrue: ["find the set of method names using this global var"
					item _ globalVariableUsage
								at: var
								ifAbsent: [globalVariableUsage at: var put: Set new].
					"add this method name to that set"
					item add: aTMethod selector]].
	aTMethod referencesGlobalStructMakeZero! !

!CCodeGenerator methodsFor: 'utilities' stamp: 'JMM 3/27/2003 16:46'!
localizeGlobalVariables
	| candidates procedure |

	"find all globals used in only one method"
	candidates _ globalVariableUsage select: [:e | e size = 1].
	variables removeAllFoundIn: candidates keys.

	"move any suitable global to be local to the single method using it"
	candidates keysAndValuesDo: [:key :targets | 
		targets do: [:name |
			procedure _ methods at: name.
			procedure locals add: key.
			variableDeclarations at: key ifPresent: [:v | 
				procedure declarations at: key put: v.
				variableDeclarations removeKey: key]]].! !

!CCodeGenerator methodsFor: 'utilities' stamp: 'JMM 4/16/2002 22:39'!
returnPrefixFromVariable: aName
	^aName! !

!CCodeGenerator methodsFor: 'C code generator' stamp: 'tpr 1/10/2003 16:20'!
emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag
	"Emit C code for all methods in the code base onto the given stream. All inlined method calls should already have been expanded."

	| verbose methodList |
	"method preparation"
	verbose _ false.
	self prepareMethods.
	verbose ifTrue: [
		self printUnboundCallWarnings.
		self printUnboundVariableReferenceWarnings.
		Transcript cr.
	].
	assertionFlag ifFalse: [ self removeAssertions ].
	self doInlining: inlineFlag.

	"code generation"

	methodList _ methods asSortedCollection: [ :m1 :m2 | m1 selector < m2 selector ].
	"clean out no longer valid variable names and then handle any global
		variable usage in each method"
	methodList do: [:m | self checkForGlobalUsage: m zapBogusVariableReferences in: m].
	self localizeGlobalVariables.

	self emitCHeaderOn: aStream.
	self emitCVariablesOn: aStream.
	self emitCFunctionPrototypes: methodList on: aStream.
'Writing Translated Code...'
displayProgressAt: Sensor cursorPoint
from: 0 to: methods size
during: [:bar |
	methodList doWithIndex: [ :m :i | bar value: i.
		m emitCCodeOn: aStream generator: self.
]].
	self emitExportsOn: aStream.
! !

!CCodeGenerator methodsFor: 'C code generator' stamp: 'tpr 2/5/2003 15:56'!
emitCVariablesOn: aStream 
	"Store the global variable declarations on the given stream."
	| varString |
	aStream nextPutAll: '/*** Variables ***/';
		 cr.
	variables asSortedCollection
		do: [:var | 
			varString _ var asString.
			self isGeneratingPluginCode
				ifTrue: [varString = 'interpreterProxy'
						ifTrue: ["quite special..."
							aStream cr; nextPutAll: '#ifdef SQUEAK_BUILTIN_PLUGIN'.
							aStream cr; nextPutAll: 'extern'.
							aStream cr; nextPutAll: '#endif'; cr]
						ifFalse: [aStream nextPutAll: 'static ']].
			(variableDeclarations includesKey: varString)
				ifTrue: [aStream nextPutAll: (variableDeclarations at: varString) , ';'; cr]
				ifFalse: ["default variable declaration"
					aStream nextPutAll: 'int ' , varString , ';'; cr]].
	aStream cr! !

!CCodeGenerator methodsFor: 'C code generator' stamp: 'tpr 1/10/2003 16:17'!
emitExportsOn: aStream
	"Store all the exported primitives in a form to be used by the internal named prim system"
	aStream nextPutAll:'

void* vm_exports[][3] = {'.
	self exportedPrimitiveNames do:[:primName|
		aStream cr;
			nextPutAll:'	{"", "'; 
			nextPutAll: primName; 
			nextPutAll:'", (void*)'; 
			nextPutAll: primName;
			nextPutAll:'},'.
	].
	aStream nextPutAll:'
	{NULL, NULL, NULL}
};
'.! !


!CCodeGeneratorGlobalStructure methodsFor: 'C code generator' stamp: 'JMM 3/27/2003 17:09'!
buildSortedVariablesCollection
	"Build sorted vars, end result will be sorted collection based on static usage, 
	perhaps cache lines will like this!!"

	| globalNames sorted |

	globalNames _ Bag new: globalVariableUsage size.
	globalVariableUsage keysAndValuesDo: [:k :v | 
		(variableDeclarations includesKey: k) ifFalse: 
			[globalNames add: k withOccurrences: v size]].	
	variableDeclarations keysDo: 
		[:e | globalNames add: e withOccurrences: 0].
	sorted _ SortedCollection sortBlock: 
		[:a :b | (globalNames occurrencesOf: a) > (globalNames occurrencesOf: b)].
	sorted addAll: variables.
	^sorted! !

!CCodeGeneratorGlobalStructure methodsFor: 'C code generator' stamp: 'tpr 10/29/2002 14:00'!
emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag
	super emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag.

	"if the machine needs the globals structure defined locally in the interp.c file, don't add the folowing function"
	localStructDef ifFalse:[self emitStructureInitFunctionOn: aStream]! !

!CCodeGeneratorGlobalStructure methodsFor: 'C code generator' stamp: 'tpr 10/29/2002 14:02'!
emitCVariablesOn: aStream
	"Store the global variable declarations on the given stream.
	break logic into vars for structure and vars for non-structure"
	| varString structure nonstruct target |

	structure _ WriteStream on: (String new: 32768).
	nonstruct _ WriteStream on: (String new: 32768).
	aStream nextPutAll: '/*** Variables ***/'; cr.
	structure nextPutAll: 'struct foo {'; cr.
	self buildSortedVariablesCollection do: [ :var |
		varString _ var asString.
		target _ (self placeInStructure: var) 
			ifTrue: [structure]
			ifFalse: [nonstruct].
		(self isGeneratingPluginCode) ifTrue:[
			varString = 'interpreterProxy' ifTrue:[
				"quite special..."
				aStream cr; nextPutAll: '#ifdef SQUEAK_BUILTIN_PLUGIN'.
				aStream cr; nextPutAll: 'extern'.
				aStream cr; nextPutAll: '#endif'; cr.
			] ifFalse:[aStream nextPutAll:'static '].
		].
		(variableDeclarations includesKey: varString) ifTrue: [
			target nextPutAll: (variableDeclarations at: varString), ';'; cr.
		] ifFalse: [
			"default variable declaration"
			target nextPutAll: 'int ', varString, ';'; cr.
		].
	].
	structure nextPutAll: ' } fum;';cr.

	"if the machine needs the fum structure defining locally, do it now"
	localStructDef ifTrue:[structure nextPutAll: 'struct foo * foo = &fum;';cr;cr].

	aStream nextPutAll: structure contents.
	aStream nextPutAll: nonstruct contents.
	aStream cr.! !

!CCodeGeneratorGlobalStructure methodsFor: 'C code generator' stamp: 'tpr 10/9/2002 15:40'!
emitStructureInitFunctionOn: aStream 
	"For the VM using a global struct for most of the global vars (useful for ARM and PPC so far), append the initGlobalStructure() function"
	aStream 
		cr;
		nextPutAll: 'void initGlobalStructure(void) {foo = &fum;}';
		cr! !

!CCodeGeneratorGlobalStructure methodsFor: 'C code generator' stamp: 'tpr 10/29/2002 15:01'!
globalStructDefined: aBool
	localStructDef _ aBool! !

!CCodeGeneratorGlobalStructure methodsFor: 'C code generator' stamp: 'tpr 10/29/2002 16:11'!
initialize
	super initialize.
	localStructDef _ false! !

!CCodeGeneratorGlobalStructure methodsFor: 'C code generator' stamp: 'tpr 2/5/2003 15:58'!
placeInStructure: var
	"See if we should put this array into a structure
	This has hard coded vars, should go somewhere else!!
	The variables listed are hardcoded as C in the interpreter thus they don't get resolved via TVariableNode logic
	Also Lets ignore variables that have special definitions that require initialization, 
	and the function def which has problems"

	| check |
	check _ variableDeclarations at: var ifAbsent: [''].
	(check includes: $=) ifTrue: [^false].
	(check includes: $() ifTrue: [^false].
	(check includes: $[) ifTrue: [^false].
	(#( 'showSurfaceFn' 'memory' 'extraVMMemory' 'interpreterProxy') includes: var) ifTrue: [^false].
	^true.
	! !

!CCodeGeneratorGlobalStructure methodsFor: 'C code generator' stamp: 'JMM 3/27/2003 16:59'!
returnPrefixFromVariable: aName
	^((self globalsAsSet includes: aName) and: [self placeInStructure: aName])
		ifTrue: ['foo->',aName]
		ifFalse: [aName]! !

!CCodeGeneratorGlobalStructure methodsFor: 'public'!
isGlobalStructureBuild
	^true! !

!CCodeGeneratorGlobalStructure methodsFor: 'utilities' stamp: 'JMM 3/27/2003 17:54'!
checkForGlobalUsage: vars in: aTMethod 
	"override to handle global struct needs"
	super checkForGlobalUsage: vars in: aTMethod.
	"if localStructDef is false, we  don't ever need to include a reference to it in a function"
	localStructDef ifFalse:[^self].
	vars asSet do: [:var |
		"if any var is global and in the global var struct 
		tell the TMethod it will be refering to the  struct"
			  ((self globalsAsSet includes: var )
					and: [self placeInStructure: var ])
				ifTrue: [aTMethod referencesGlobalStructIncrementBy: (vars occurrencesOf: var)]]! !

!CCodeGeneratorGlobalStructure methodsFor: 'utilities' stamp: 'JMM 3/27/2003 17:10'!
localizeGlobalVariables
"TPR - remove all the global vars destined for the structure that are only used once - not worth the space,
actually what will happen is the folding code will fold these variables into the method"

	super localizeGlobalVariables.
	globalVariableUsage _ globalVariableUsage select: [:e | e size > 1].
! !


!JPEGReadWriter2Plugin methodsFor: 'primitives' stamp: 'JMM 11/24/2002 21:37'!
primJPEGReadHeader: aJPEGDecompressStruct fromByteArray: source errorMgr: aJPEGErrorMgr2Struct

	| pcinfo pjerr sourceSize |
	self export: true.
	self
		primitive: 'primJPEGReadHeaderfromByteArrayerrorMgr'
		parameters: #(ByteArray ByteArray ByteArray).
 	self var: #pcinfo declareC: 'j_decompress_ptr pcinfo'.
 	self var: #pjerr declareC: 'error_ptr2 pjerr'.


		pcinfo _ nil. pjerr _ nil. sourceSize _ nil.
		pcinfo. pjerr. sourceSize.

	"Various parameter checks"
	self cCode: '
		interpreterProxy->success
			((interpreterProxy->stSizeOf(interpreterProxy->stackValue(2))) >= (sizeof(struct jpeg_decompress_struct)));
		interpreterProxy->success
			((interpreterProxy->stSizeOf(interpreterProxy->stackValue(0))) >= (sizeof(struct error_mgr2))); 
		if (interpreterProxy->failed()) return null;
	' inSmalltalk: [].

	self cCode: '
		sourceSize = interpreterProxy->stSizeOf(interpreterProxy->stackValue(1));
		pcinfo = (j_decompress_ptr)aJPEGDecompressStruct;
		pjerr = (error_ptr2)aJPEGErrorMgr2Struct;
		if (sourceSize) {
			pcinfo->err = jpeg_std_error(&pjerr->pub);
			pjerr->pub.error_exit = error_exit;
			if (setjmp(pjerr->setjmp_buffer)) {
				jpeg_destroy_decompress(pcinfo);
				sourceSize = 0;
			}
			if (sourceSize) {
				jpeg_create_decompress(pcinfo);
				jpeg_mem_src(pcinfo, source, sourceSize);
				jpeg_read_header(pcinfo, TRUE);
			}
		}
	' inSmalltalk: [].! !

!JPEGReadWriter2Plugin methodsFor: 'primitives' stamp: 'JMM 11/24/2002 21:38'!
primJPEGReadImage: aJPEGDecompressStruct fromByteArray: source onForm: form doDithering: ditherFlag errorMgr: aJPEGErrorMgr2Struct

	| pcinfo pjerr buffer rowStride formBits formDepth i j formPix ok rOff gOff bOff rOff2 gOff2 bOff2 formWidth formHeight pixPerWord formPitch formBitsSize sourceSize r1 r2 g1 g2 b1 b2 formBitsAsInt dmv1 dmv2 di dmi dmo |
	self export: true.

	self
		primitive: 'primJPEGReadImagefromByteArrayonFormdoDitheringerrorMgr'
		parameters: #(ByteArray ByteArray Form Boolean ByteArray).

 	self var: #pcinfo declareC: 'j_decompress_ptr pcinfo'.
 	self var: #pjerr declareC: 'error_ptr2 pjerr'.
	self var: #buffer declareC: 'JSAMPARRAY buffer'.
	self var: #formBits declareC: 'unsigned * formBits'.

	"Avoid warnings when saving method"
	 pcinfo _ nil. pjerr _ nil. buffer _ nil. rowStride _ nil.
		formDepth _ nil. formBits _ nil. i _ nil. j _ nil. formPix _ nil.
		ok _ nil. rOff _ nil. gOff _ nil. bOff _ nil. rOff2 _ nil. gOff2 _ nil. bOff2 _ nil. sourceSize _ nil.
		r1 _ nil. r2 _ nil. g1 _ nil. g2 _ nil. b1 _ nil. b2 _ nil.
		dmv1 _ nil. dmv2 _ nil. di _ nil. dmi _ nil. dmo _ nil.
		pcinfo. pjerr. buffer. rowStride. formBits. formDepth. i. j. formPix. ok.
		rOff. gOff. bOff. rOff2. gOff2. bOff2. sourceSize.
		r1. r2. g1.g2. b1. b2. dmv1. dmv2. di. dmi. dmo.

	formBits _self cCoerce: (interpreterProxy fetchPointer: 0 ofObject: form)  to: 'unsigned *'.
	formBitsAsInt _ interpreterProxy fetchPointer: 0 ofObject: form.
	formDepth _ interpreterProxy fetchInteger: 3 ofObject: form.

	"Various parameter checks"
	self cCode: '
		interpreterProxy->success
			((interpreterProxy->stSizeOf(interpreterProxy->stackValue(4))) >= (sizeof(struct jpeg_decompress_struct)));
		interpreterProxy->success
			((interpreterProxy->stSizeOf(interpreterProxy->stackValue(0))) >= (sizeof(struct error_mgr2))); 
		if (interpreterProxy->failed()) return null;
	' inSmalltalk: [].
	formWidth _ (self cCode: '((j_decompress_ptr)aJPEGDecompressStruct)->image_width' inSmalltalk: [0]).
	formHeight _ (self cCode: '((j_decompress_ptr)aJPEGDecompressStruct)->image_height' inSmalltalk: [0]).
	pixPerWord _ 32 // formDepth.
	formPitch _ formWidth + (pixPerWord-1) // pixPerWord * 4.
	formBitsSize _ interpreterProxy byteSizeOf: formBitsAsInt.
	interpreterProxy success: 
		((interpreterProxy isWordsOrBytes: formBitsAsInt)
			and: [formBitsSize = (formPitch * formHeight)]).
	interpreterProxy failed ifTrue: [^ nil].

	self cCode: '
		sourceSize = interpreterProxy->stSizeOf(interpreterProxy->stackValue(3));
		if (sourceSize == 0) {
			interpreterProxy->success(false);
			return null;
		}
		pcinfo = (j_decompress_ptr)aJPEGDecompressStruct;
		pjerr = (error_ptr2)aJPEGErrorMgr2Struct;
		pcinfo->err = jpeg_std_error(&pjerr->pub);
		pjerr->pub.error_exit = error_exit;
		ok = 1;
		if (setjmp(pjerr->setjmp_buffer)) {
			jpeg_destroy_decompress(pcinfo);
			ok = 0;
		}
		if (ok) {
			ok = jpeg_mem_src_newLocationOfData(pcinfo, source, sourceSize);
			if (ok) {
				/* Dither Matrix taken from Form>>orderedDither32To16, but rewritten for this method. */
				int ditherMatrix1[] = { 2, 0, 14, 12, 1, 3, 13, 15 };
				int ditherMatrix2[] = { 10, 8, 6, 4, 9, 11, 5, 7 };
 				jpeg_start_decompress(pcinfo);
				rowStride = pcinfo->output_width * pcinfo->output_components;
				if (pcinfo->out_color_components == 3) {
					rOff = 0; gOff = 1; bOff = 2;
					rOff2 = 3; gOff2 = 4; bOff2 = 5;
				} else {
					rOff = 0; gOff = 0; bOff = 0;
					rOff2 = 1; gOff2 = 1; bOff2 = 1;
				}
				/* Make a one-row-high sample array that will go away when done with image */
				buffer = (*(pcinfo->mem)->alloc_sarray)
					((j_common_ptr) pcinfo, JPOOL_IMAGE, rowStride, 1);

				/* Step 6: while (scan lines remain to be read) */
				/*           jpeg_read_scanlines(...); */

				/* Here we use the library state variable cinfo.output_scanline as the
				 * loop counter, so that we dont have to keep track ourselves.
				 */
				while (pcinfo->output_scanline < pcinfo->output_height) {
					/* jpeg_read_scanlines expects an array of pointers to scanlines.
					 * Here the array is only one element long, but you could ask for
					 * more than one scanline at a time if thats more convenient.
					 */
					(void) jpeg_read_scanlines(pcinfo, buffer, 1);

					switch (formDepth) {
						case 32:
							for(i = 0, j = 1; i < rowStride; i +=(pcinfo->out_color_components), j++) {
								formPix = (255 << 24) | (buffer[0][i+rOff] << 16) | (buffer[0][i+gOff] << 8) | buffer[0][i+bOff];
								if (formPix == 0) formPix = 1;
								formBits [ ((pcinfo->output_scanline - 1) * (pcinfo->image_width)) + j ] = formPix;
							}
							break;

						case 16:
							for(i = 0, j = 1; i < rowStride; i +=(pcinfo->out_color_components*2), j++) {
								r1 = buffer[0][i+rOff];
								r2 = buffer[0][i+rOff2];
								g1 = buffer[0][i+gOff];
								g2 = buffer[0][i+gOff2];
								b1 = buffer[0][i+bOff];
								b2 = buffer[0][i+bOff2];

								if (!!ditherFlag) {
									r1 = r1 >> 3;
									r2 = r2 >> 3;
									g1 = g1 >> 3;
									g2 = g2 >> 3;
									b1 = b1 >> 3;
									b2 = b2 >> 3;
								} else {
									/* Do 4x4 ordered dithering. Taken from Form>>orderedDither32To16 */
									dmv1 = ditherMatrix1[ ((pcinfo->output_scanline & 3 )<< 1) | (j&1) ];
									dmv2 = ditherMatrix2[ ((pcinfo->output_scanline & 3 )<< 1) | (j&1) ];

									di = (r1 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
									if(dmv1 < dmi) { r1 = dmo+1; } else { r1 = dmo; };
									di = (g1 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
									if(dmv1 < dmi) { g1 = dmo+1; } else { g1 = dmo; };
									di = (b1 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
									if(dmv1 < dmi) { b1 = dmo+1; } else { b1 = dmo; };

									di = (r2 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
									if(dmv2 < dmi) { r2 = dmo+1; } else { r2 = dmo; };
									di = (g2 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
									if(dmv2 < dmi) { g2 = dmo+1; } else { g2 = dmo; };
									di = (b2 * 496) >> 8; dmi = di & 15; dmo = di >> 4;
									if(dmv2 < dmi) { b2 = dmo+1; } else { b2 = dmo; };
								}

								formPix = (r1 << 10) | (g1 << 5) | b1;
								if (!!formPix) formPix = 1;
								formPix = (formPix << 16) | (r2 << 10) | (g2 << 5) | b2;
								if (!!(formPix & 65535)) formPix = formPix | 1;
								formBits [ ((pcinfo->output_scanline - 1) * (pcinfo->image_width)) / 2 + j ] = formPix;
							}
							break;
					}
				}
				jpeg_finish_decompress(pcinfo);
			}
			jpeg_destroy_decompress(pcinfo);
		}
	' inSmalltalk: [].! !

!JPEGReadWriter2Plugin methodsFor: 'primitives' stamp: 'JMM 11/24/2002 21:41'!
primJPEGWriteImage: aJPEGCompressStruct onByteArray: destination form: form quality: quality progressiveJPEG: progressiveFlag errorMgr: aJPEGErrorMgr2Struct

	| pcinfo pjerr buffer rowStride formBits formWidth formHeight formDepth i j formPix destinationSize pixPerWord formPitch formBitsSize formBitsAsInt |
	self export: true.
	self
		primitive: 'primJPEGWriteImageonByteArrayformqualityprogressiveJPEGerrorMgr'
		parameters: #(ByteArray ByteArray Form SmallInteger Boolean ByteArray).
 	self var: #pcinfo declareC: 'j_compress_ptr pcinfo'.
 	self var: #pjerr declareC: 'error_ptr2 pjerr'.
	self var: #buffer declareC: 'JSAMPARRAY buffer'.
	self var: #formBits declareC: 'unsigned * formBits'.
	self var: #destinationSize type: 'unsigned int'.

	
		pcinfo _ nil. pjerr _ nil. buffer _nil. rowStride _ nil. formBits _ nil. 
		formWidth _ nil. formHeight _ nil. formDepth _ nil. i _ nil. j _ nil. formPix _ nil. destinationSize _ nil.
		pcinfo. pjerr. buffer. rowStride. formBits. formWidth. formHeight. formDepth. i. j. formPix. destinationSize.
	

	formBits _self cCoerce: (interpreterProxy fetchPointer: 0 ofObject: form)  to: 'unsigned *'.
	formBitsAsInt _ interpreterProxy fetchPointer: 0 ofObject: form.
	formWidth _ interpreterProxy fetchInteger: 1 ofObject: form.
	formHeight _ interpreterProxy fetchInteger: 2 ofObject: form.
	formDepth _ interpreterProxy fetchInteger: 3 ofObject: form.

	"Various parameter checks"
	self cCode: '
		interpreterProxy->success
			((interpreterProxy->stSizeOf(interpreterProxy->stackValue(5))) >= (sizeof(struct jpeg_compress_struct)));
		interpreterProxy->success
			((interpreterProxy->stSizeOf(interpreterProxy->stackValue(0))) >= (sizeof(struct error_mgr2))); 
		if (interpreterProxy->failed()) return null;
	' inSmalltalk: [].
	pixPerWord _ 32 // formDepth.
	formPitch _ formWidth + (pixPerWord-1) // pixPerWord * 4.
	formBitsSize _ interpreterProxy byteSizeOf: formBitsAsInt.
	interpreterProxy success: 
		((interpreterProxy isWordsOrBytes: formBitsAsInt)
			and: [formBitsSize = (formPitch * formHeight)]).
	interpreterProxy failed ifTrue: [^ nil].

	self cCode: '
		destinationSize = interpreterProxy->stSizeOf(interpreterProxy->stackValue(4));
		pcinfo = (j_compress_ptr)aJPEGCompressStruct;
		pjerr = (error_ptr2)aJPEGErrorMgr2Struct;
		if (destinationSize) {
			pcinfo->err = jpeg_std_error(&pjerr->pub);
			pjerr->pub.error_exit = error_exit;
			if (setjmp(pjerr->setjmp_buffer)) {
				jpeg_destroy_compress(pcinfo);
				destinationSize = 0;
			}
			if (destinationSize) {
				jpeg_create_compress(pcinfo);
				jpeg_mem_dest(pcinfo, destination, &destinationSize);
				pcinfo->image_width = formWidth;
				pcinfo->image_height = formHeight;
				pcinfo->input_components = 3;
				pcinfo->in_color_space = JCS_RGB;
				jpeg_set_defaults(pcinfo);
				if (quality > 0)
					jpeg_set_quality (pcinfo, quality, 1);
				if (progressiveFlag)
					jpeg_simple_progression(pcinfo);
				jpeg_start_compress(pcinfo, TRUE);
				rowStride = formWidth * 3;

				/* Make a one-row-high sample array that will go away 
				  when done with image */
				buffer = (*(pcinfo->mem)->alloc_sarray)
					((j_common_ptr) pcinfo, JPOOL_IMAGE, rowStride, 1);

				while (pcinfo->next_scanline < pcinfo->image_height) {
					switch (formDepth) {
						case 32:
							for(i = 0, j = 1; i < rowStride; i +=3, j++) {
								formPix = formBits [ ((pcinfo->next_scanline) * formWidth) + j ];
								buffer[0][i] = (formPix >> 16) & 255;
								buffer[0][i+1] = (formPix >> 8) & 255;
								buffer[0][i+2] = formPix & 255;
							}
							break;
						case 16:
							for(i = 0, j = 1; i < rowStride; i +=6, j++) {
								formPix = formBits [ ((pcinfo->next_scanline) * formWidth) / 2 + j ];
								buffer[0][i] = (formPix >> 23) & 248;
								buffer[0][i+1] = (formPix >> 18) & 248;
								buffer[0][i+2] = (formPix >> 13) & 248;
								buffer[0][i+3] = (formPix >> 7) & 248;
								buffer[0][i+4] = (formPix >> 2) & 248;
								buffer[0][i+5] = (formPix << 3) & 248;
							}
							break;
					}
					(void) jpeg_write_scanlines(pcinfo, buffer, 1);

				}
				jpeg_finish_compress(pcinfo);
				jpeg_destroy_compress(pcinfo);
			}
		}
	' inSmalltalk: [].
	^(self cCode: 'destinationSize' inSmalltalk: [0])
		asOop: SmallInteger! !


!MacOSPowerPCOS9VMMaker methodsFor: 'generate sources' stamp: 'tpr 10/29/2002 16:15'!
generateInterpreterFile
	"generate the main 'interp.c' file for the interpreter and the list of 
	export statments"
	Interpreter
				translateInDirectory: self coreVMDirectory
				doInlining: inline
				forBrowserPlugin: forBrowser
				forGlobalStructure: true withStructureDefinedLocally: true! !


!ObjectMemory methodsFor: 'initialization' stamp: 'tpr 2/5/2003 16:04'!
initializeObjectMemory: bytesToShift
	"Initialize object memory variables at startup time. Assume endOfMemory is initially set (by the image-reading code) to the end of the last object in the image. Initialization redefines endOfMemory to be the end of the object allocation area based on the total available memory, but reserving some space for forwarding blocks."
	"Assume: image reader initializes the following variables:
		memory
		endOfMemory
		memoryLimit
		specialObjectsOop
		lastHash
	"
	"di 11/18/2000 fix slow full GC"
	self inline: false.

	"set the start of the young object space"
	youngStart _ endOfMemory.

	"image may be at a different address; adjust oops for new location"
	totalObjectCount _ self adjustAllOopsBy: bytesToShift.

	self initializeMemoryFirstFree: endOfMemory.
		"initializes endOfMemory, freeBlock"

	specialObjectsOop _ specialObjectsOop + bytesToShift.

	"heavily used special objects"
	nilObj	_ self splObj: NilObject.
	falseObj	_ self splObj: FalseObject.
	trueObj	_ self splObj: TrueObject.

	rootTableCount _ 0.
	freeContexts _ NilContext.
	freeLargeContexts _ NilContext.
	allocationCount _ 0.
	lowSpaceThreshold _ 0.
	signalLowSpace _ false.
	compStart _ 0.
	compEnd _ 0.
	fwdTableNext _ 0.
	fwdTableLast _ 0.
	remapBufferCount _ 0.
	allocationsBetweenGCs _ 4000.  "do incremental GC after this many allocations"
	tenuringThreshold _ 2000.  "tenure all suriving objects if count is over this threshold"
	growHeadroom _ 4*1024*1024. "four megabyte of headroom when growing"
	shrinkThreshold _ 8*1024*1024. "eight megabyte of free space before shrinking"

	"garbage collection statistics"
	statFullGCs _ 0.
	statFullGCMSecs _ 0.
	statIncrGCs _ 0.
	statIncrGCMSecs _ 0.
	statTenures _ 0.
	statRootTableOverflows _ 0.
! !

!ObjectMemory methodsFor: 'object enumeration' stamp: 'tpr 2/5/2003 16:05'!
lastPointerOf: oop 
	"Return the byte offset of the last pointer field of the given object. 
	Works with CompiledMethods, as well as ordinary objects. Can be used 
	even when the type bits are not correct."
	| fmt sz methodHeader header contextSize |
	self inline: true.
	header _ self baseHeader: oop.
	fmt _ header >> 8 bitAnd: 15.
	fmt <= 4
		ifTrue: [(fmt = 3 and: [self isContextHeader: header])
				ifTrue: ["contexts end at the stack pointer"
					contextSize _ self fetchStackPointerOf: oop.
					^ CtxtTempFrameStart + contextSize * 4].
			sz _ self sizeBitsOfSafe: oop.
			^ sz - BaseHeaderSize"all pointers"].
	fmt < 12
		ifTrue: [^ 0]. "no pointers"

	"CompiledMethod: contains both pointers and bytes:"
	methodHeader _ self longAt: oop + BaseHeaderSize.
	^ (methodHeader >> 10 bitAnd: 255) * 4 + BaseHeaderSize! !

!ObjectMemory methodsFor: 'oop/chunk conversion' stamp: 'JMM 12/4/2002 19:55'!
chunkFromOop: oop
	"Compute the chunk of this oop by subtracting its extra header bytes."

	^ oop - (self extraHeaderBytes: oop)! !

!ObjectMemory methodsFor: 'oop/chunk conversion' stamp: 'JMM 12/4/2002 20:33'!
extraHeaderBytes: oopOrChunk
	"Return the number of extra bytes used by the given object's header."
	"Warning: This method should not be used during marking, when the header type bits of an object may be incorrect."

	"JMM should be an array lookup!!" 
	self inline: true.
	^ headerTypeBytes at: ((self headerType: oopOrChunk)+1).! !

!ObjectMemory methodsFor: 'oop/chunk conversion' stamp: 'JMM 12/4/2002 19:56'!
oopFromChunk: chunk
	"Compute the oop of this chunk by adding its extra header bytes."

	^ chunk + (self extraHeaderBytes: chunk)! !

!ObjectMemory methodsFor: 'gc -- mark and sweep' stamp: 'tpr 2/5/2003 16:07'!
sweepPhase
	"Sweep memory from youngStart through the end of memory. Free all 
	inaccessible objects and coalesce adjacent free chunks. Clear the mark 
	bits of accessible objects. Compute the starting point for the first pass of 
	incremental compaction (compStart). Return the number of surviving 
	objects. "
	"Details: Each time a non-free object is encountered, decrement the 
	number of available forward table entries. If all entries are spoken for 
	(i.e., entriesAvailable reaches zero), set compStart to the last free 
	chunk before that object or, if there is no free chunk before the given 
	object, the first free chunk after it. Thus, at the end of the sweep 
	phase, compStart through compEnd spans the highest collection of 
	non-free objects that can be accomodated by the forwarding table. This 
	information is used by the first pass of incremental compaction to 
	ensure that space is initially freed at the end of memory. Note that 
	there should always be at least one free chunk--the one at the end of 
	the heap."
	| entriesAvailable survivors freeChunk firstFree oop oopHeader oopHeaderType hdrBytes oopSize freeChunkSize endOfMemoryLocal |
	self inline: false.
	entriesAvailable _ self fwdTableInit: 8.
	survivors _ 0.
	freeChunk _ nil.
	firstFree _ nil.
	"will be updated later"
	endOfMemoryLocal _ endOfMemory.
	oop _ self oopFromChunk: youngStart.
	[oop < endOfMemoryLocal]
		whileTrue: ["get oop's header, header type, size, and header size"
			oopHeader _ self baseHeader: oop.
			oopHeaderType _ oopHeader bitAnd: TypeMask.
			hdrBytes _ headerTypeBytes at: oopHeaderType + 1.
			(oopHeaderType bitAnd: 1) = 1
				ifTrue: [oopSize _ oopHeader bitAnd: SizeMask]
				ifFalse: [oopHeaderType = HeaderTypeSizeAndClass
						ifTrue: [oopSize _ (self sizeHeader: oop)
										bitAnd: AllButTypeMask]
						ifFalse: ["free chunk"
							oopSize _ oopHeader bitAnd: AllButTypeMask]].
			(oopHeader bitAnd: MarkBit) = 0
				ifTrue: ["object is not marked; free it"
					"<-- Finalization support: We need to mark each oop 
					chunk as free -->"
					self longAt: oop - hdrBytes put: HeaderTypeFree.
					freeChunk ~= nil
						ifTrue: ["enlarge current free chunk to include this oop"
							freeChunkSize _ freeChunkSize + oopSize + hdrBytes]
						ifFalse: ["start a new free chunk"
							freeChunk _ oop - hdrBytes.
							"chunk may start 4 or 8 bytes before oop"
							freeChunkSize _ oopSize + (oop - freeChunk).
							"adjust size for possible extra header bytes"
							firstFree = nil ifTrue: [firstFree _ freeChunk]]]
				ifFalse: ["object is marked; clear its mark bit and possibly adjust 
					the compaction start"
					self longAt: oop put: (oopHeader bitAnd: AllButMarkBit).
					"<-- Finalization support: Check if we're running about 
					a weak class -->"
					(self isWeak: oop) ifTrue: [self finalizeReference: oop].
					entriesAvailable > 0
						ifTrue: [entriesAvailable _ entriesAvailable - 1]
						ifFalse: ["start compaction at the last free chunk before 
							this object"
							firstFree _ freeChunk].
					freeChunk ~= nil
						ifTrue: ["record the size of the last free chunk"
							self longAt: freeChunk put: ((freeChunkSize bitAnd: AllButTypeMask)
										bitOr: HeaderTypeFree)].
					freeChunk _ nil.
					survivors _ survivors + 1].
			oop _ self oopFromChunk: oop + oopSize].
	freeChunk ~= nil
		ifTrue: ["record size of final free chunk"
			self longAt: freeChunk put: ((freeChunkSize bitAnd: AllButTypeMask)
						bitOr: HeaderTypeFree)].
	oop = endOfMemory
		ifFalse: [self error: 'sweep failed to find exact end of memory'].
	firstFree = nil
		ifTrue: [self error: 'expected to find at least one free object']
		ifFalse: [compStart _ firstFree].

	^ survivors! !

!ObjectMemory methodsFor: 'gc -- compaction' stamp: 'tpr 2/5/2003 16:03'!
incCompMakeFwd
	"Create and initialize forwarding blocks for all non-free objects 
	following compStart. If the supply of forwarding blocks is exhausted, 
	set compEnd to the first chunk above the area to be compacted; 
	otherwise, set it to endOfMemory. Return the number of bytes to be 
	freed. "
	| bytesFreed oop fwdBlock newOop |
	self inline: false.
	bytesFreed _ 0.
	oop _ self oopFromChunk: compStart.
	[oop < endOfMemory]
		whileTrue: [(self isFreeObject: oop)
				ifTrue: [bytesFreed _ bytesFreed
								+ (self sizeOfFree: oop)]
				ifFalse: ["create a forwarding block for oop"
					fwdBlock _ self fwdBlockGet: 8.
					"Two-word block"
					fwdBlock = nil
						ifTrue: ["stop; we have used all available forwarding 
							blocks "
							compEnd _ self chunkFromOop: oop.
							^ bytesFreed].
					newOop _ oop - bytesFreed.
					self
						initForwardBlock: fwdBlock
						mapping: oop
						to: newOop
						withBackPtr: false].
			oop _ self objectAfterWhileForwarding: oop].
	compEnd _ endOfMemory.
	^ bytesFreed! !

!ObjectMemory methodsFor: 'gc -- compaction' stamp: 'tpr 2/5/2003 16:03'!
incCompMove: bytesFreed 
	"Move all non-free objects between compStart and compEnd to their new 
	locations, restoring their headers in the process. Create a new free 
	block at the end of memory. Return the newly created free chunk."
	"Note: The free block used by the allocator always must be the last free 
	block in memory. It may take several compaction passes to make all 
	free space bubble up to the end of memory."
	| oop next fwdBlock newOop header bytesToMove firstWord lastWord newFreeChunk sz target |
	self inline: false.
	newOop _ nil.
	oop _ self oopFromChunk: compStart.
	[oop < compEnd]
		whileTrue: [next _ self objectAfterWhileForwarding: oop.
			(self isFreeObject: oop)
				ifFalse: ["a moving object; unwind its forwarding block"
					fwdBlock _ ((self longAt: oop)
								bitAnd: AllButMarkBitAndTypeMask)
								<< 1.
					DoAssertionChecks
						ifTrue: [self fwdBlockValidate: fwdBlock].
					newOop _ self longAt: fwdBlock.
					header _ self longAt: fwdBlock + 4.
					self longAt: oop put: header.
					"restore the original header"
					bytesToMove _ oop - newOop.
					"move the oop (including any extra header words)"
					sz _ self sizeBitsOf: oop.
					firstWord _ oop
								- (self extraHeaderBytes: oop).
					lastWord _ oop + sz - BaseHeaderSize.
					target _ firstWord - bytesToMove.
					firstWord to: lastWord by: 4
						do: [:w | self
								longAt: target
								put: (self longAt: w).
							target _ target + 4]].
			oop _ next].
	newOop = nil
		ifTrue: ["no objects moved"
			oop _ self oopFromChunk: compStart.
			((self isFreeObject: oop)
					and: [(self objectAfter: oop)
							= (self oopFromChunk: compEnd)])
				ifTrue: [newFreeChunk _ oop]
				ifFalse: [newFreeChunk _ freeBlock]]
		ifFalse: ["initialize the newly freed memory chunk"
			"newOop is the last object moved; free chunk starts right after it"
			newFreeChunk _ newOop
						+ (self sizeBitsOf: newOop).
			self setSizeOfFree: newFreeChunk to: bytesFreed].
	DoAssertionChecks
		ifTrue: [(self objectAfter: newFreeChunk)
					= (self oopFromChunk: compEnd)
				ifFalse: [self error: 'problem creating free chunk after compaction']].
	(self objectAfter: newFreeChunk)
			= endOfMemory
		ifTrue: [self initializeMemoryFirstFree: newFreeChunk]
		ifFalse: ["newFreeChunk is not at end of memory; re-install freeBlock"
			self initializeMemoryFirstFree: freeBlock].
	^ newFreeChunk! !

!ObjectMemory methodsFor: 'gc -- compaction' stamp: 'tpr 2/5/2003 16:05'!
lastPointerWhileForwarding: oop 
	"The given object may have its header word in a forwarding block. Find 
	the offset of the last pointer in the object in spite of this obstacle."
	| header fwdBlock fmt size methodHeader contextSize |
	self inline: true.
	header _ self longAt: oop.
	(header bitAnd: MarkBit) ~= 0
		ifTrue: ["oop is forwarded; get its real header from its forwarding table 
			entry "
			fwdBlock _ (header bitAnd: AllButMarkBitAndTypeMask) << 1.
			DoAssertionChecks
				ifTrue: [self fwdBlockValidate: fwdBlock].
			header _ self longAt: fwdBlock + 4].
	fmt _ header >> 8 bitAnd: 15.
	fmt <= 4 ifTrue: [(fmt = 3
					and: [self isContextHeader: header])
				ifTrue: ["contexts end at the stack pointer"
					contextSize _ self fetchStackPointerOf: oop.
					^ CtxtTempFrameStart + contextSize * 4].
			"do sizeBitsOf: using the header we obtained"
			(header bitAnd: TypeMask)
					= HeaderTypeSizeAndClass
				ifTrue: [size _ (self sizeHeader: oop)
								bitAnd: AllButTypeMask]
				ifFalse: [size _ header bitAnd: SizeMask].
			^ size - BaseHeaderSize].
	fmt < 12 ifTrue: [^ 0]. "no pointers"
	methodHeader _ self longAt: oop + BaseHeaderSize.
	^ (methodHeader >> 10 bitAnd: 255) * 4 + BaseHeaderSize! !

!ObjectMemory methodsFor: 'gc -- compaction' stamp: 'JMM 12/9/2002 22:16'!
mapPointersInObjectsFrom: memStart to: memEnd
	"Use the forwarding table to update the pointers of all non-free objects in the given range of memory. Also remap pointers in root objects which may contains pointers into the given memory range, and don't forget to flush the method cache based on the range"

	self inline: false.
	self compilerMapHookFrom: memStart to: memEnd.
	"update interpreter variables"
	self mapInterpreterOops.
	self flushMethodCacheFrom: memStart to: memEnd.
	self updatePointersInRootObjectsFrom: memStart to: memEnd.
	self updatePointersInRangeFrom: memStart to: memEnd.
! !

!ObjectMemory methodsFor: 'gc -- compaction' stamp: 'tpr 2/5/2003 16:07'!
updatePointersInRangeFrom: memStart to: memEnd 
	"update pointers in the given memory range"
	| oop |
	self inline: false.
	oop _ self oopFromChunk: memStart.
	[oop < memEnd]
		whileTrue: [(self isFreeObject: oop)
				ifFalse: [self remapFieldsAndClassOf: oop].
			oop _ self objectAfterWhileForwarding: oop]! !

!ObjectMemory methodsFor: 'gc -- compaction' stamp: 'tpr 2/5/2003 16:08'!
updatePointersInRootObjectsFrom: memStart to: memEnd 
	"update pointers in root objects"
	| oop |
	self inline: false.
	1 to: rootTableCount do: [:i | 
			oop _ rootTable at: i.
			(oop < memStart or: [oop >= memEnd])
				ifTrue: ["Note: must not remap the fields of any object twice!!"
					"remap this oop only if not in the memory range 
					covered below"
					self remapFieldsAndClassOf: oop]]! !


!Interpreter methodsFor: 'initialization' stamp: 'JMM 12/28/2002 22:07'!
dummyReferToProxy
	self inline: false.
	interpreterProxy _ interpreterProxy! !

!Interpreter methodsFor: 'initialization' stamp: 'JMM 12/28/2002 22:07'!
initializeInterpreter: bytesToShift
	"Initialize Interpreter state before starting execution of a new image."

	interpreterProxy _ self sqGetInterpreterProxy.
	self dummyReferToProxy.
	self initializeObjectMemory: bytesToShift.
	self initCompilerHooks.
	self flushExternalPrimitives.

	activeContext	_ nilObj.
	theHomeContext	_ nilObj.
	method			_ nilObj.
	receiver		_ nilObj.
	messageSelector	_ nilObj.
	newMethod		_ nilObj.
	methodClass		_ nilObj.
	lkupClass		_ nilObj.
	receiverClass	_ nilObj.
	newNativeMethod		_ nilObj.

	self flushMethodCache.
	self loadInitialContext.
	interruptCheckCounter _ 0.
	interruptCheckCounterFeedBackReset _ 1000.
	interruptChecksEveryNms _ 3.
	nextPollTick _ 0.
	nextWakeupTick _ 0.
	lastTick _ 0.
	interruptKeycode _ 2094.  "cmd-."
	interruptPending _ false.
	semaphoresUseBufferA _ true.
	semaphoresToSignalCountA _ 0.
	semaphoresToSignalCountB _ 0.
	deferDisplayUpdates _ false.
	pendingFinalizationSignals _ 0.
! !

!Interpreter methodsFor: 'contexts' stamp: 'JMM 12/4/2002 13:27'!
isContextHeader: aHeader
	self inline: true.
	^ ((aHeader >> 12) bitAnd: 16r1F) = 13			"MethodContext"
		or: [((aHeader >> 12) bitAnd: 16r1F) = 14		"BlockContext"
		or: [((aHeader >> 12) bitAnd: 16r1F) = 4]]	"PseudoContext"! !

!Interpreter methodsFor: 'contexts' stamp: 'JMM 12/6/2002 16:18'!
primitiveFindNextUnwindContext
	"Primitive. Search up the context stack for the next method context marked for unwind handling from the receiver up to but not including the argument. Return nil if none found."
	| thisCntx nilOop aContext isUnwindMarked |
	aContext _ self popStack.
	thisCntx _ self fetchPointer: SenderIndex ofObject: self popStack.
	nilOop _ nilObj.

	[(thisCntx = aContext) or: [thisCntx = nilOop]] whileFalse: [
		isUnwindMarked _ self isUnwindMarked: thisCntx.
		isUnwindMarked ifTrue:[
			self push: thisCntx.
			^nil].
		thisCntx _ self fetchPointer: SenderIndex ofObject: thisCntx].

	^self push: nilOop! !

!Interpreter methodsFor: 'return bytecodes' stamp: 'JMM 4/17/2002 00:05'!
returnFalse

	cntx _ self sender.
	val _ falseObj.
	self returnValueTo.! !

!Interpreter methodsFor: 'return bytecodes' stamp: 'JMM 4/17/2002 00:04'!
returnNil

	cntx _ self sender.
	val _ nilObj.
	self returnValueTo.
! !

!Interpreter methodsFor: 'return bytecodes' stamp: 'JMM 4/17/2002 00:04'!
returnReceiver

	cntx _ self sender.
	val _ receiver.
	self returnValueTo.! !

!Interpreter methodsFor: 'return bytecodes' stamp: 'JMM 4/17/2002 00:05'!
returnTopFromBlock
	"Return to the caller of the method containing the block."

	cntx _ self caller.  "Note: caller, not sender!!"
	val _ self internalStackTop.
	self returnValueTo.! !

!Interpreter methodsFor: 'return bytecodes' stamp: 'JMM 4/17/2002 00:04'!
returnTopFromMethod

	cntx _ self sender.
	val _ self internalStackTop.
	self returnValueTo.! !

!Interpreter methodsFor: 'return bytecodes' stamp: 'JMM 4/17/2002 00:05'!
returnTrue

	cntx _ self sender.
	val _ trueObj.
	self returnValueTo.! !

!Interpreter methodsFor: 'return bytecodes'!
returnValueTo
	"Note: Assumed to be inlined into the dispatch loop."

	| nilOop thisCntx contextOfCaller localCntx localVal isUnwindMarked |
	self inline: true.
	self sharedCodeNamed: 'commonReturn' inCase: 120.

	nilOop _ nilObj. "keep in a register"
	thisCntx _ activeContext.
	localCntx _ cntx.
	localVal _ val.

	"make sure we can return to the given context"
	((localCntx = nilOop) or:
	 [(self fetchPointer: InstructionPointerIndex ofObject: localCntx) = nilOop]) ifTrue: [
		"error: sender's instruction pointer or context is nil; cannot return"
		^self internalCannotReturn: localVal].

	"If this return is not to our immediate predecessor (i.e. from a method to its sender, or from a block to its caller), scan the stack for the first unwind marked context and inform this context and let it deal with it. This provides a chance for ensure unwinding to occur."
	thisCntx _ self fetchPointer: SenderIndex ofObject: activeContext.

	"Just possibly a faster test would be to compare the homeContext and activeContext - they are of course different for blocks. Thus we might be able to optimise a touch by having a different returnTo for the blockreteurn (since we know that must return to caller) and then if active ~= home we must be doing a non-local return. I think. Maybe."
	[thisCntx = localCntx] whileFalse: [
		thisCntx = nilObj ifTrue:[
			"error: sender's instruction pointer or context is nil; cannot return"
			^self internalCannotReturn: localVal].
		"Climb up stack towards localCntx. Break out to a send of #aboutToReturn:through: if an unwind marked context is found"
		isUnwindMarked _ self isUnwindMarked: thisCntx.
		isUnwindMarked ifTrue:[
			"context is marked; break out"
			^self internalAboutToReturn: localVal through: thisCntx].
		thisCntx _ self fetchPointer: SenderIndex ofObject: thisCntx.
 ].

	"If we get here there is no unwind to worry about. Simply terminate the stack up to the localCntx - often just the sender of the method"
	thisCntx _ activeContext.
	[thisCntx = localCntx]
		whileFalse:
		["climb up stack to localCntx"
		contextOfCaller _ self fetchPointer: SenderIndex ofObject: thisCntx.

		"zap exited contexts so any future attempted use will be caught"
		self storePointerUnchecked: SenderIndex ofObject: thisCntx withValue: nilOop.
		self storePointerUnchecked: InstructionPointerIndex ofObject: thisCntx withValue: nilOop.
		reclaimableContextCount > 0 ifTrue:
			["try to recycle this context"
			reclaimableContextCount _ reclaimableContextCount - 1.
			self recycleContextIfPossible: thisCntx].
		thisCntx _ contextOfCaller].

	activeContext _ thisCntx.
	(thisCntx < youngStart) ifTrue: [ self beRootIfOld: thisCntx ].

	self internalFetchContextRegisters: thisCntx.  "updates local IP and SP"
	self fetchNextBytecode.
	self internalPush: localVal.
! !

!Interpreter methodsFor: 'image save/restore' stamp: 'tpr 1/28/2003 16:10'!
readImageFromFile: f HeapSize: desiredHeapSize StartingAt: imageOffset
	"Read an image from the given file stream, allocating the given amount of memory to its object heap. Fail if the image has an unknown format or requires more than the given amount of memory."
	"Details: This method detects when the image was stored on a machine with the opposite byte ordering from this machine and swaps the bytes automatically. Furthermore, it allows the header information to start 512 bytes into the file, since some file transfer programs for the Macintosh apparently prepend a Mac-specific header of this size. Note that this same 512 bytes of prefix area could also be used to store an exec command on Unix systems, allowing one to launch Smalltalk by invoking the image name as a command."
	"This code is based on C code by Ian Piumarta and Smalltalk code by Tim Rowledge. Many thanks to both of you!!!!"

	| swapBytes headerStart headerSize dataSize oldBaseAddr minimumMemory memStart bytesRead bytesToShift heapSize |
	self var: #f declareC: 'sqImageFile f'.
	self var: #headerStart declareC: 'squeakFileOffsetType headerStart'.
	self var: #dataSize declareC: 'size_t dataSize'.
	self var: #imageOffset declareC: 'squeakFileOffsetType imageOffset'.

	swapBytes _ self checkImageVersionFrom: f startingAt: imageOffset.
	headerStart _ (self sqImageFilePosition: f) - 4.  "record header start position"

	headerSize			_ self getLongFromFile: f swap: swapBytes.
	dataSize				_ self getLongFromFile: f swap: swapBytes.
	oldBaseAddr			_ self getLongFromFile: f swap: swapBytes.
	specialObjectsOop	_ self getLongFromFile: f swap: swapBytes.
	lastHash			_ self getLongFromFile: f swap: swapBytes.
	savedWindowSize	_ self getLongFromFile: f swap: swapBytes.
	fullScreenFlag		_ self getLongFromFile: f swap: swapBytes.
	extraVMMemory		_ self getLongFromFile: f swap: swapBytes.

	lastHash = 0 ifTrue: [
		"lastHash wasn't stored (e.g. by the cloner); use 999 as the seed"
		lastHash _ 999].

	"decrease Squeak object heap to leave extra memory for the VM"
	heapSize _ self cCode: 'reserveExtraCHeapBytes(desiredHeapSize, extraVMMemory)'.

	"compare memory requirements with availability".
	minimumMemory _ dataSize + 100000.  "need at least 100K of breathing room"
	heapSize < minimumMemory ifTrue: [
		GenerateBrowserPlugin
			ifTrue: [
				self plugInNotifyUser: 'The amount of memory specified by the ''memory'' EMBED tag is not enough for the installed Squeak image file.'.
				^ nil]
			ifFalse: [self error: 'Insufficient memory for this image']].

	"allocate a contiguous block of memory for the Squeak heap"
	memory _ self cCode: '(unsigned char *) sqAllocateMemory(minimumMemory, heapSize)'.
	memory = nil ifTrue: [
		GenerateBrowserPlugin
			ifTrue: [
				self plugInNotifyUser: 'There is not enough memory to give Squeak the amount specified by the ''memory'' EMBED tag.'.
				^ nil]
			ifFalse: [self error: 'Failed to allocate memory for the heap']].

	memStart _ self startOfMemory.
	memoryLimit _ (memStart + heapSize) - 24.  "decrease memoryLimit a tad for safety"
	endOfMemory _ memStart + dataSize.

	"position file after the header"
	self sqImageFile: f Seek: headerStart + headerSize.

	"read in the image in bulk, then swap the bytes if necessary"
	bytesRead _ self cCode: 'sqImageFileRead(memory, sizeof(unsigned char), dataSize, f)'.
	bytesRead ~= dataSize ifTrue: [
		GenerateBrowserPlugin
			ifTrue: [
				self plugInNotifyUser: 'Squeak had problems reading its image file.'.
				self plugInShutdown.
				^ nil]
			ifFalse: [self error: 'Read failed or premature end of image file']].

	headerTypeBytes at: 1 put: 8. "3-word header (type 0)"	
	headerTypeBytes at: 2 put: 4. "2-word header (type 1)"
	headerTypeBytes at: 3 put: 0. "free chunk (type 2)"	
	headerTypeBytes at: 4 put: 0. "1-word header (type 3)"

	swapBytes ifTrue: [self reverseBytesInImage].

	"compute difference between old and new memory base addresses"
	bytesToShift _ memStart - oldBaseAddr.
	self initializeInterpreter: bytesToShift.  "adjusts all oops to new location"
	^ dataSize
! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/17/2002 12:02'!
getFullScreenFlag
	^fullScreenFlag! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/17/2002 12:02'!
getInterruptCheckCounter
	^interruptCheckCounter! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/17/2002 12:02'!
getInterruptKeycode
	^interruptKeycode! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/17/2002 12:02'!
getInterruptPending
	^interruptPending! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/17/2002 12:03'!
getNextWakeupTick
	^nextWakeupTick! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/17/2002 12:03'!
getSavedWindowSize
	^savedWindowSize! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/16/2002 13:44'!
setFullScreenFlag: value
	fullScreenFlag _ value! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/16/2002 13:45'!
setInterruptCheckCounter: value
	interruptCheckCounter _ value! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/16/2002 13:46'!
setInterruptKeycode: value
	interruptKeycode _ value! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/16/2002 13:46'!
setInterruptPending: value
	interruptPending _ value! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/16/2002 13:48'!
setNextWakeupTick: value
	nextWakeupTick _ value! !

!Interpreter methodsFor: 'plugin support' stamp: 'JMM 4/16/2002 13:47'!
setSavedWindowSize: value
	savedWindowSize _ value! !


!InterpreterSimulator methodsFor: 'initialization' stamp: 'JMM 12/4/2002 20:31'!
initialize

	"Initialize the InterpreterSimulator when running the interpreter inside
	Smalltalk. The primary responsibility of this method is to allocate
	Smalltalk Arrays for variables that will be declared as statically-allocated
	global arrays in the translated code."

	"initialize class variables"
	ObjectMemory initialize.
	Interpreter initialize.

	methodCache _ Array new: MethodCacheSize.
	atCache _ Array new: AtCacheTotalSize.
	self flushMethodCache.
	rootTable _ Array new: RootTableSize.
	remapBuffer _ Array new: RemapBufferSize.
	semaphoresUseBufferA _ true.
	semaphoresToSignalA _ Array new: SemaphoresToSignalSize.
	semaphoresToSignalB _ Array new: SemaphoresToSignalSize.
	externalPrimitiveTable _ CArrayAccessor on: (Array new: MaxExternalPrimitiveTableSize).

	obsoleteNamedPrimitiveTable _ 
		CArrayAccessor on: self class obsoleteNamedPrimitiveTable.
	obsoleteIndexedPrimitiveTable _ CArrayAccessor on: 
		(self class obsoleteIndexedPrimitiveTable collect:[:spec| 
			CArrayAccessor on:
				(spec ifNil:[Array new: 3] 
					  ifNotNil:[Array with: spec first with: spec second with: nil])]).
	pluginList _ #().
	mappedPluginEntries _ #().

	"initialize InterpreterSimulator variables used for debugging"
	byteCount _ 0.
	sendCount _ 0.
	traceOn _ true.
	myBitBlt _ BitBltSimulator new setInterpreter: self.
	displayForm _ nil.  "displayForm is created in response to primitiveBeDisplay"
	filesOpen _ OrderedCollection new.
	headerTypeBytes _ Array with: 0 with: 8 with: 4 with: 0 with: 0.! !


!ObjectMemory class methodsFor: 'translation' stamp: 'JMM 12/4/2002 20:15'!
declareCVarsIn: aCCodeGenerator
	aCCodeGenerator var: #memory type: #'unsigned char*'.
	aCCodeGenerator
		var: #remapBuffer
		declareC: 'int remapBuffer[', (RemapBufferSize + 1) printString, ']'.
	aCCodeGenerator
		var: #rootTable
		declareC: 'int rootTable[', (RootTableSize + 1) printString, ']'.
	aCCodeGenerator
		var: #headerTypeBytes
		declareC: 'int headerTypeBytes[4+1]'.
		! !


!Interpreter class methodsFor: 'translation' stamp: 'tpr 10/29/2002 16:13'!
translateInDirectory: directory doInlining: inlineFlag forBrowserPlugin: pluginFlag
	^self translateInDirectory: directory doInlining: inlineFlag forBrowserPlugin: pluginFlag forGlobalStructure: false withStructureDefinedLocally: false! !

!Interpreter class methodsFor: 'translation' stamp: 'tpr 10/29/2002 16:11'!
translateInDirectory: directory doInlining: inlineFlag forBrowserPlugin: pluginFlag forGlobalStructure: globalStructureFlag withStructureDefinedLocally: structFlag
	"Translate the Smalltalk description of the virtual machine into C. If inlineFlag is true, small method bodies are inlined to reduce procedure call overhead. On the PPC, this results in a factor of three speedup with only 30% increase in code size. If pluginFlag is true, generate code for an interpreter that runs as a browser plugin (Netscape or IE)."
	"Note: The pluginFlag is meaningless on Windows and Unix. On these platforms Squeak runs as it's own process and doesn't need any special attention from the VMs point of view. Meaning that NONE of the required additional functions will be supported. In other words, the pluginFlag is not needed and not supported."
	"The forGlobalStructure flag if true uses a different CCodeGenerator to build globals as a pointer to a structure, some RISC based platforms PPC for example 
them make better assembler. The structFlag only applies to these cases and defines whether the globals struct is defined within interp.c or not - the Acorn VM uses global register vars and requires some odd handling of this"

	"Return the list of exports for this module"

	| doInlining cg fileName tStamp fstat |
	tStamp _ { Interpreter. ObjectMemory} inject: 0 into: [:tS :cl|
		tS _ tS max: cl timeStamp].

	"don't translate if the file is newer than my timeStamp"
	fileName _ 'interp.c'.
	fstat _ directory entryAt: fileName ifAbsent:[nil].
	fstat ifNotNil:[tStamp < fstat modificationTime ifTrue:[^nil]].


	doInlining _ inlineFlag.
	pluginFlag ifTrue: [doInlining _ true].  "must inline when generating browser plugin"
	Interpreter initialize.
	ObjectMemory initialize.
	GenerateBrowserPlugin  _ pluginFlag.
	cg _ globalStructureFlag 
		ifTrue: [CCodeGeneratorGlobalStructure new initialize; globalStructDefined: structFlag]
		ifFalse: [CCodeGenerator new initialize].
	cg addClass: Interpreter.
	cg addClass: ObjectMemory.
	Interpreter declareCVarsIn: cg.
	ObjectMemory declareCVarsIn: cg.

	cg storeCodeOnFile: (directory fullNameFor: fileName) doInlining: doInlining! !


!PluggableCodeGenerator methodsFor: 'C code generator' stamp: 'tpr 1/10/2003 16:09'!
emitExportsOn: aStream
	"Store all the exported primitives in a form to be used by internal plugins"
	| prefix |
	aStream nextPutAll:'

#ifdef SQUEAK_BUILTIN_PLUGIN';cr.

	aStream nextPutAll:'

void* ', pluginName,'_exports[][3] = {'.
	prefix := '"', pluginName,'"'.
	self exportedPrimitiveNames do:[:primName|
		aStream cr;
			nextPutAll:'	{'; 
			nextPutAll: prefix; 
			nextPutAll:', "'; 
			nextPutAll: primName; 
			nextPutAll:'", (void*)'; 
			nextPutAll: primName;
			nextPutAll:'},'.
	].
	aStream nextPutAll:'
	{NULL, NULL, NULL}
};
'.
	aStream nextPutAll:'

#endif /* ifdef SQ_BUILTIN_PLUGIN */

'.! !

!PluggableCodeGenerator methodsFor: 'public' stamp: 'tpr 1/10/2003 15:55'!
codeStringForPrimitives: classAndSelectorList 
"TPR - appears to be obsolete now"
	self addClass: InterpreterPlugin.
	InterpreterPlugin declareCVarsIn: self.
	^super codeStringForPrimitives: classAndSelectorList ! !

!PluggableCodeGenerator methodsFor: 'public' stamp: 'tpr 2/5/2003 16:08'!
generateCodeStringForPrimitives
"TPR - moved down from CCodeGenerator"
	| s methodList |
	s _ ReadWriteStream on: (String new: 1000).
	methodList _ methods asSortedCollection: [:m1 :m2 | m1 selector < m2 selector].
	self emitCHeaderForPrimitivesOn: s.
	self emitCVariablesOn: s.
	self emitCFunctionPrototypes: methodList on: s.
	methodList do: [:m | m emitCCodeOn: s generator: self].
	self emitExportsOn: s.
	^ s contents
! !

!PluggableCodeGenerator methodsFor: 'public' stamp: 'tpr 1/10/2003 16:20'!
localizeGlobalVariables
"TPR - we don't do this for plugins"! !

!PluggableCodeGenerator methodsFor: 'public' stamp: 'tpr 1/10/2003 16:18'!
pluginName: aString
"TPR - moved from CCodeGenerator"
	"Set the plugin name when generating plugins."
	pluginName _ aString.! !


!RiscOSVMMaker methodsFor: 'generate sources' stamp: 'tpr 10/29/2002 16:15'!
generateInterpreterFile
	"generate the main 'interp.c' file for the interpreter and the list of 
	export statments"
	Interpreter
				translateInDirectory: self coreVMDirectory
				doInlining: inline
				forBrowserPlugin: forBrowser
				forGlobalStructure: true withStructureDefinedLocally: false! !


!TMethod methodsFor: 'initialization' stamp: 'JMM 3/27/2003 17:17'!
setSelector: sel args: argList locals: localList block: aBlockNode primitive: aNumber
	"Initialize this method using the given information."

	selector _ sel.
	returnType _ 'int'. 	 "assume return type is int for now"
	args _ argList asOrderedCollection collect: [:arg | arg key].
	locals _ localList asOrderedCollection collect: [:arg | arg key].
	declarations _ Dictionary new.
	primitive _ aNumber.
	parseTree _ aBlockNode asTranslatorNode.
	labels _ OrderedCollection new.
	complete _ false.  "set to true when all possible inlining has been done"
	export _ self extractExportDirective.
	static _ self extractStaticDirective.
	self removeFinalSelfReturn.
	self recordDeclarations.
	globalStructureBuildMethodHasFoo _ 0.! !

!TMethod methodsFor: 'accessing' stamp: 'JMM 3/27/2003 17:19'!
globalStructureBuildMethodHasFoo
	^globalStructureBuildMethodHasFoo! !

!TMethod methodsFor: 'accessing' stamp: 'JMM 3/27/2003 17:19'!
globalStructureBuildMethodHasFoo: number
	globalStructureBuildMethodHasFoo _ number! !

!TMethod methodsFor: 'accessing' stamp: 'JMM 3/27/2003 17:55'!
referencesGlobalStructIncrementBy: value
	globalStructureBuildMethodHasFoo _ globalStructureBuildMethodHasFoo + value.! !

!TMethod methodsFor: 'accessing' stamp: 'JMM 3/27/2003 17:17'!
referencesGlobalStructMakeZero
	globalStructureBuildMethodHasFoo _ 0! !

!TMethod methodsFor: 'utilities' stamp: 'JMM 3/27/2003 17:41'!
zapBogusVariableReferences
	"After inlining some variable references are now obsolete, we could fix them there but the 
	code seems a bit complicated, the other choice to to rebuild the locals before extruding. This is done here"

	| refs |

	refs _ Bag new.
	"find all the variable names referenced in this method"
	parseTree nodesVarCheckDo: [ :node |
		node isVariable ifTrue: [ refs add: node name asString ].
		node isStmtList ifTrue: [refs addAll: node args]].
	"add all the non-arg declarations (might be variables usedonly in cCode sections)"
	refs addAll:((self declarations keys) reject: [:e | self args includes: e]).
	"reset the locals to be only those still referred to"
	locals _ locals select: [:e | refs includes: e].
	^refs
! !

!TMethod methodsFor: 'C code generation' stamp: 'hg 8/14/2000 15:41'!
emitCCodeOn: aStream generator: aCodeGen
	"Emit C code for this method onto the given stream. All calls to inlined methods should already have been expanded."

	self emitCCommentOn: aStream.	"place method comment before function"

	self emitCHeaderOn: aStream generator: aCodeGen.
	parseTree emitCCodeOn: aStream level: 1 generator: aCodeGen.
	aStream nextPutAll: '}'; cr.! !

!TMethod methodsFor: 'C code generation' stamp: 'tpr 1/13/2003 11:26'!
emitCHeaderOn: aStream generator: aCodeGen
	"Emit a C function header for this method onto the given stream."

	aStream cr. 
	self emitCFunctionPrototype: aStream generator: aCodeGen.
	aStream nextPutAll: ' {'; cr.
	self emitGlobalStructReferenceOn: aStream.
	locals do: [ :var |
		aStream nextPutAll: '    '.
		aStream nextPutAll: (declarations at: var ifAbsent: [ 'int ', var]), ';'; cr.
	].
	locals isEmpty ifFalse: [ aStream cr ].! !

!TMethod methodsFor: 'C code generation' stamp: 'JMM 3/27/2003 17:23'!
emitGlobalStructReferenceOn: aStream
	"Add a reference to the globals struct if needed"

	(self globalStructureBuildMethodHasFoo > 1)
		ifTrue: [aStream nextPutAll: 'register struct foo * foo = &fum;'; cr].
! !


!TParseNode methodsFor: 'as yet unclassified' stamp: 'JMM 11/23/2002 23:25'!
nodesVarCheckDo: aBlock

	aBlock value: self.! !


!TAssignmentNode methodsFor: 'as yet unclassified' stamp: 'JMM 11/23/2002 23:24'!
nodesVarCheckDo: aBlock

	variable nodesVarCheckDo: aBlock.
	expression nodesVarCheckDo: aBlock.
	aBlock value: self.! !


!TCaseStmtNode methodsFor: 'as yet unclassified' stamp: 'JMM 11/23/2002 23:25'!
nodesVarCheckDo: aBlock

	expression nodesVarCheckDo: aBlock.
	cases do: [ :c | c nodesVarCheckDo: aBlock ].
	aBlock value: self.! !


!TReturnNode methodsFor: 'as yet unclassified' stamp: 'JMM 11/23/2002 23:25'!
nodesVarCheckDo: aBlock

	expression nodesVarCheckDo: aBlock.
	aBlock value: self.! !


!TSendNode methodsFor: 'as yet unclassified' stamp: 'JMM 11/24/2002 22:31'!
nodesVarCheckDo: aBlock

	receiver nodesVarCheckDo: aBlock.
	self selector = #ifFalse: ifTrue: 
		[(self receiver isConstant and: [self receiver value == true]) ifTrue: 
			[aBlock value: self.
			^self]].
	self selector = #ifTrue: ifTrue: 
		[(self receiver isConstant and: [self receiver value == false]) ifTrue: 
			[aBlock value: self.
			^self]].
	self selector = #ifTrue:ifFalse: ifTrue: 
		[(self receiver isConstant and: [self receiver value == true]) ifTrue: 
			[arguments first nodesVarCheckDo: aBlock.
			aBlock value: self.
			^self].
		(self receiver isConstant and: [self receiver value  == false]) ifTrue: 
			[arguments second nodesVarCheckDo: aBlock.
			aBlock value: self.
			^self]].
	self selector = #ifFalse:ifTrue: ifTrue: 
		[(self receiver isConstant and: [self receiver value == false]) ifTrue: 
			[arguments first nodesVarCheckDo: aBlock.
			aBlock value: self.
			^self].
		(self receiver isConstant and: [self receiver value == true]) ifTrue: 
			[arguments second nodesVarCheckDo: aBlock.
			aBlock value: self.
			^self]].
	self selector = #cCode:inSmalltalk: 
		ifTrue: [arguments first nodesVarCheckDo: aBlock.
				aBlock value: self.
				^self].
	arguments do: [ :arg | arg nodesVarCheckDo: aBlock ].
	aBlock value: self.! !


!TStmtListNode methodsFor: 'as yet unclassified' stamp: 'JMM 11/23/2002 23:25'!
nodesVarCheckDo: aBlock

	statements do: [ :s | s nodesVarCheckDo: aBlock ].	
	aBlock value: self.! !


!TVariableNode methodsFor: 'as yet unclassified' stamp: 'JMM 4/5/2002 14:14'!
emitCCodeOn: aStream level: level generator: aCodeGen

	name = 'nil'
		ifTrue: [ aStream nextPutAll: (aCodeGen cLiteralFor: nil) ]
		ifFalse: [ aStream nextPutAll: (aCodeGen returnPrefixFromVariable: name) ].! !

TMethod removeSelector: #referencesGlobalStruct:!
Interpreter removeSelector: #returnValue:to:!
Object subclass: #ObjectMemory
	instanceVariableNames: 'memory youngStart endOfMemory memoryLimit nilObj falseObj trueObj specialObjectsOop rootTable rootTableCount child field parentField freeBlock lastHash allocationCount lowSpaceThreshold signalLowSpace compStart compEnd fwdTableNext fwdTableLast remapBuffer remapBufferCount allocationsBetweenGCs tenuringThreshold statFullGCs statFullGCMSecs statIncrGCs statIncrGCMSecs statTenures statRootTableOverflows freeContexts freeLargeContexts interruptCheckCounter totalObjectCount shrinkThreshold growHeadroom headerTypeBytes '
	classVariableNames: 'AllButHashBits AllButMarkBit AllButMarkBitAndTypeMask AllButRootBit AllButTypeMask BaseHeaderSize BlockContextProto CharacterTable ClassArray ClassBitmap ClassBlockContext ClassByteArray ClassCharacter ClassCompiledMethod ClassExternalAddress ClassExternalData ClassExternalFunction ClassExternalLibrary ClassExternalStructure ClassFloat ClassInteger ClassLargeNegativeInteger ClassLargePositiveInteger ClassMessage ClassMethodContext ClassPoint ClassProcess ClassPseudoContext ClassSemaphore ClassString ClassTranslatedMethod CompactClassMask CompactClasses ConstMinusOne ConstOne ConstTwo ConstZero CtxtTempFrameStart DoAssertionChecks DoBalanceChecks Done ExternalObjectsArray FalseObject FloatProto GCTopMarker HashBits HashBitsOffset HeaderTypeClass HeaderTypeFree HeaderTypeGC HeaderTypeShort HeaderTypeSizeAndClass LargeContextBit LargeContextSize MarkBit MethodContextProto NilContext NilObject RemapBufferSize RootBit RootTableSize SchedulerAssociation SelectorAboutToReturn SelectorCannotInterpret SelectorCannotReturn SelectorDoesNotUnderstand SelectorMustBeBoolean SizeMask SmallContextSize SpecialSelectors StackStart StartField StartObj TheDisplay TheFinalizationSemaphore TheInputSemaphore TheInterruptSemaphore TheLowSpaceSemaphore TheTimerSemaphore TrueObject TypeMask Upward '
	poolDictionaries: ''
	category: 'VMConstruction-Interpreter'!
CCodeGeneratorGlobalStructure removeSelector: #globalVariables!
CCodeGenerator removeSelector: #generateCodeStringForPrimitives!
CCodeGenerator removeSelector: #pluginName!
CCodeGenerator removeSelector: #pluginName:!
