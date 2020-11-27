"
This class provides the basic framework for creating VM plugins. Most of the useful methods are on the class side; particularly take note of the messages like #shouldBeTranslated and #requiresPlatformFiles.
"
Class {
	#name : #InterpreterPlugin,
	#superclass : #VMClass,
	#instVars : [
		'interpreterProxy',
		'moduleName',
		'translatedMethodCache'
	],
	#pools : [
		'VMBasicConstants'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #accessing }
InterpreterPlugin class >> allCallsOn [
	"Answer a SortedCollection of all the methods that refer to me. Most classes simply defer to SystemDictionary>allCallsOn: but some have special requirements - plugins may have a module name that does not match the class name"

	self theNonMetaClass name ~= self moduleName asSymbol
		ifTrue:[^super allCallsOn, (self systemNavigation allCallsOn: self moduleName asSymbol)]
		ifFalse:[^super allCallsOn]
]

{ #category : #translation }
InterpreterPlugin class >> allCodeOlderThan: modificationTime [
	^((self pluginClassesUpToRoot) allSatisfy:
			[:aPluginClass| aPluginClass timeStamp < modificationTime])
	  and: [self translatedPrimitives allSatisfy:
			[:pair| | c m stamp |
			c := Smalltalk classNamed: pair first.
			m := c compiledMethodAt: pair last ifAbsent: [c class >> pair last].
			stamp := (m timeStamp subStrings: {Character space}) last: 2.
			stamp := TimeStamp date: (Date fromString: stamp first) time: (Time fromString: stamp last).
			stamp asSeconds < modificationTime]]
]

{ #category : #'translated primitives' }
InterpreterPlugin class >> browseTranslatedPrimitives [
	"InterpreterPlugin browseTranslatedPrimitives"
	| methodRefs |
	methodRefs := OrderedCollection new.
	self withAllSubclasses do:
		[:class|
		methodRefs addAll:
			(class translatedPrimitives collect:
				[:tuple|
				(self methodForTranslatedPrimitiveTuple: tuple) methodReference])].
	self systemNavigation browseMessageList: methodRefs
		name: 'Translated primitives'
]

{ #category : #translation }
InterpreterPlugin class >> buildCodeGenerator [
	"Build a CCodeGenerator for the plugin"
	| cg pluginClasses |
	cg := self codeGeneratorClass new initialize.
	cg vmClass: self.
	cg pluginClass: self.
	cg vmMaker: VMMaker new.
	cg vmMaker vmmakerConfiguration: VMMakerConfiguration.
	(pluginClasses := self pluginClassesUpToRoot) do:
		[:aClass| cg addClass: aClass].
	(cg structClassesForTranslationClasses: pluginClasses) do:
		[:structClasss| cg addStructClass: structClasss].
	cg addMethodsForTranslatedPrimitives: self translatedPrimitives.
	^cg
]

{ #category : #translation }
InterpreterPlugin class >> buildCodeGeneratorForVMClass: aVMClass [
	"Build a CCodeGenerator for the plugin"
	| cg pluginClasses |
	cg := self codeGeneratorClass new initialize.
	cg vmClass: aVMClass.
	cg pluginClass: self.
	cg vmMaker: VMMaker new.
	cg vmMaker vmmakerConfiguration: VMMakerConfiguration.
	(pluginClasses := self pluginClassesUpToRoot) do:
		[:aClass| cg addClass: aClass].
	(cg structClassesForTranslationClasses: pluginClasses) do:
		[:structClasss| cg addStructClass: structClasss].
	cg addMethodsForTranslatedPrimitives: self translatedPrimitives.
	^cg
]

{ #category : #translation }
InterpreterPlugin class >> buildCodeGeneratorUpTo: aPluginClass [
	"Build a CCodeGenerator for the plugin - Deprecated and here only in case old plugin code tries to use it"
	self deprecated.
	^self buildCodeGenerator
]

{ #category : #private }
InterpreterPlugin class >> codeGeneratorClass [
	"return the appropriate class of code generator for this kind ofplugin"

	^VMPluginCodeGenerator
]

{ #category : #translation }
InterpreterPlugin class >> declareCVarsIn: aCCodeGenerator [
	"Note: This method must be implemented by all subclasses to declare variables."

	aCCodeGenerator 
		var: #interpreterProxy type: #'struct VirtualMachine*';
		removeVariable: 'translatedMethodCache' ifAbsent: nil.
	self declareHeaderFilesIn: aCCodeGenerator
]

{ #category : #translation }
InterpreterPlugin class >> declareHeaderFilesIn: aCCodeGenerator [
	self hasHeaderFile ifTrue:[
		aCCodeGenerator addHeaderFile: '"', self moduleName,'.h"'].
]

{ #category : #'instance creation' }
InterpreterPlugin class >> doPrimitive: primitiveName [ 
	| proxy plugin |
	proxy := InterpreterProxy new.
	proxy loadStackFrom: thisContext sender.
	plugin := self simulatorClass new.
	plugin setInterpreter: proxy.
	(plugin respondsTo: #initialiseModule) ifTrue:[plugin initialiseModule].
	plugin perform: primitiveName asSymbol.
	^ proxy stackValue: 0
]

{ #category : #translation }
InterpreterPlugin class >> exportBuildInfoOrNil [
	"A hook for classes to emit some descriptive build string.
	 See CCodeGenerator>>fileHeaderVersionStampForSourceClass:"
	^nil
]

{ #category : #translation }
InterpreterPlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^false
]

{ #category : #accessing }
InterpreterPlugin class >> isCPP [
	^ false
]

{ #category : #translation }
InterpreterPlugin class >> isPluginClass [
	^true
]

{ #category : #translation }
InterpreterPlugin class >> isStructType: typeName [ "<String>"
	"Subclasses should override to answer trye for struct types they use."
	^false
]

{ #category : #'translated primitives' }
InterpreterPlugin class >> methodForTranslatedPrimitiveTuple: tuple [
	| class |
	class := Smalltalk classNamed: tuple first.
	^class
		compiledMethodAt: tuple last
		ifAbsent:
			[class class
				compiledMethodAt: tuple last
				ifAbsent: [tuple = #(String findSubstringViaPrimitive:in:startingAt:matchTable:) ifTrue:
							[ByteString compiledMethodAt: #findSubstring:in:startingAt:matchTable:]]]
]

{ #category : #'translated primitives' }
InterpreterPlugin class >> methodOrNilForTranslatedPrimitiveSelector: selector [
	self translatedPrimitives do:
		[:tuple| | method |
		method := self methodForTranslatedPrimitiveTuple: tuple.
		method pragmas do:
			[:p|
			((p keyword beginsWith: 'primitive:') and: [p arguments first = selector]) ifTrue:
				[^method]]].
	^nil
]

{ #category : #translation }
InterpreterPlugin class >> methodsToBePruned [
	"Since sharing between plugins means that normal pruning
	 can't be done, allow plugins that want to prune specific methods."
	^#()
]

{ #category : #translation }
InterpreterPlugin class >> moduleExportsName [
	"Answer the name to include in receiver's internal plugin exports.
	 This is the value of the module: argument in named primitives.
	 By default answer the moduleName."

	^self moduleName
]

{ #category : #accessing }
InterpreterPlugin class >> moduleExtension [
	^ self isCPP ifTrue: ['.cpp'] ifFalse: ['.c']
]

{ #category : #translation }
InterpreterPlugin class >> moduleFileName [
	"Answer the receiver's module name that is used for the plugin's C code."

	^ self moduleName, self moduleExtension
]

{ #category : #translation }
InterpreterPlugin class >> moduleName [
	"Answer the receiver's module name that is used for the plugin's C code."

	^ self name asString
]

{ #category : #accessing }
InterpreterPlugin class >> moduleNameAndVersion [
	"Answer the receiver's module name and version info that is used for the plugin's C code. The default is to append the code generation date, but any useful text is ok (keep it short)"

	^ self moduleName
]

{ #category : #translation }
InterpreterPlugin class >> pluginClassesUpToRoot [
	"Answer the classes to include for translation of aPluginClass, superclasses first, and the root (VMClass in general, possibly Object)  last."
	| theClass classes |

	classes := OrderedCollection new.
	theClass := self.
	[theClass == Object
	 or: [theClass == VMClass]] whileFalse:
		[classes addLast: theClass.
		theClass := theClass superclass].
	^classes reverse
]

{ #category : #translation }
InterpreterPlugin class >> preambleCCode [
	"Defining this method to answer a string dumps that string in VMPluginCodeGenerator>>emitCHeaderOn:"
	^nil
]

{ #category : #translation }
InterpreterPlugin class >> pruneUnusedInterpreterPluginMethodsIn: aCodeGen [
	aCodeGen unreachableMethods do:
		[:m|
		 m definingClass = InterpreterPlugin ifTrue:
			[aCodeGen removeMethodForSelector: m selector]]
]

{ #category : #translation }
InterpreterPlugin class >> requiresCrossPlatformFiles [
	"default is ok for most, any plugin needing cross platform files aside from a normal header must say so. See SoundCodecPlugin for example"
	^self hasHeaderFile
]

{ #category : #translation }
InterpreterPlugin class >> requiresPlatformFiles [
	"default is ok for most, any plugin needing platform specific files must say so"
	^false
]

{ #category : #translation }
InterpreterPlugin class >> shouldBeTranslated [
"is this class intended to be translated as a plugin? Most subclasses should answer true, but some such as:-
	TestInterpreterPlugin
	FlippArrayPlugin2
	InflatePlugin
	should answer false for various reasons."
	^true
]

{ #category : #translation }
InterpreterPlugin class >> shouldBeTranslatedFor: platformName [
	"Is this class intended to be translated as a plugin, perhaps specific to a platform?
	 Most subclasses should answer true, but some such as simulation-only versions
	 should answer false for various reasons."
	^self shouldBeTranslated
]

{ #category : #translation }
InterpreterPlugin class >> shouldGenerateDeadCode [
	"Answer if the code generator should generate dead code, e.g. in false ifTrue: [dead] ifFalse: [live].
	 Since plugin source is shared between different VM builds it is unsafe to assume any code is dead."

	^true
]

{ #category : #simulation }
InterpreterPlugin class >> simulatorClass [
	"For running from Smalltalk - answer a class that can be used to simulate the receiver, or nil if you want the primitives in this module to always fail, causing simulation to fall through to the Smalltalk code.  By default every non-TestInterpreterPlugin can simulate itself."

	^ self
]

{ #category : #simulation }
InterpreterPlugin class >> simulatorForInterpreterInterface: objectMemoryOrInterpreterProxy [
	"Answer an uninitialized (in the sense that the plugin has been sent initialize, but not initialiseModule)
	 simulator for the receiver, or nil, if the receiver answers nil to simulatorClass.  Overridden by
	 SmartSyntaxPluginSimulator to answer an instance of SmartSyntaxPluginSimulator wrapped around
	 an uniniialized simulator for the receiver."

	^self simulatorClass ifNotNil:
		[:simClass|
		 simClass new
			setInterpreter: objectMemoryOrInterpreterProxy;
			yourself]
]

{ #category : #translation }
InterpreterPlugin class >> storeString: s onFileNamed: fileName [
	"Store the given string in a file of the given name."

	| f |
	f := VMMaker forceNewFileNamed: fileName.
	f nextPutAll: s.
	f close.
]

{ #category : #translation }
InterpreterPlugin class >> translateInDirectory: directory doInlining: inlineFlag [
"This is the default method for writing out sources for a plugin. Several classes need special handling, so look at all implementors of this message"
	| cg fname |
	 fname := self moduleName, '.c'.

	"don't translate if the file is newer than my timeStamp"
	"(directory / fname) ifExists: [:fstat| | mTime |
		mTime := fstat modificationTime.
		mTime isInteger ifFalse: [mTime := mTime asSeconds].
		 (self allCodeOlderThan: mTime) ifTrue:
			[^nil]]."

	self initialize.
	"The VM class should be nil for plugins, because there is code that conditionally checks if it is nil or not.
	A nil VM class is assumed as a plugin context..."
	cg := self buildCodeGeneratorForVMClass: nil.
	cg inferTypes.
	self pruneUnusedInterpreterPluginMethodsIn: cg.
	cg storeCodeOnFile:  (directory / fname) fullName doInlining: inlineFlag.
	^cg exportedPrimitiveNames asArray
]

{ #category : #translation }
InterpreterPlugin class >> translatedPrimitives [
	"Answer an Array of Class, selector pair Arrays for any primitives to
	 be translated from Smalltalk methods elsewhere in the system.
	 By default answer none.  Some subclasses redefine as required."
	^#()
]

{ #category : #simulation }
InterpreterPlugin >> cCoerce: value to: cTypeString [
	<doNotGenerate>
	"Type coercion for translation only; just return the value when running in Smalltalk.
	 This overrides the generic coercion method in VMClass.  For some reason we are the exception.
	 If we want that style of coercion we can send cCoerce:to: to interpreterProxy, not self."

	^value isCArray
		ifTrue: [value coerceTo: cTypeString sim: interpreterProxy]
		ifFalse: [value]
]

{ #category : #simulation }
InterpreterPlugin >> cCoerceSimple: value to: cType [
	<doNotGenerate>
	"Coercion without type mapping.  Don't even bother to check for valid types..."
	^value
]

{ #category : #'simulation support' }
InterpreterPlugin >> close [
	"Simulation subclasses needing some specific close action override as required."
	<doNotGenerate>
]

{ #category : #'simulation support' }
InterpreterPlugin >> doesNotUnderstand: aMessage [
	<doNotGenerate>
	"Override doesNotUnderstand: to iuntercept sends of translated primitive selectors.
	 The translated primitives are primitives derived from the primitive methods themselves
	 translating their failure code/method body into Slang code."
	(self methodAndTypesOrNilForTranslatedPrimitiveSelector: aMessage selector)
		ifNil: [^super doesNotUnderstand: aMessage]
		ifNotNil:
			[:tuple| | method |
			 "First check the cache for validity; if the ast element of the tuple is the actual method
			 then the cache is up-to-date.  if it is not, the method has changed and should be regenerated."
			 method := tuple last.
			 method == (method methodClass >> method selector) ifFalse:
				[translatedMethodCache removeKey: aMessage selector.
				 ^self doesNotUnderstand: aMessage].
			 method := tuple first.
			 tuple second
				ifNil: [interpreterProxy primitiveFail]
				ifNotNil:
					[:types|
					 self tryToRunTranslatedPrimitive: method types: types subsidiaries: tuple third].
			(#(	compare:with:collated:
				findFirstInString:inSet:startingAt:
				findSubstring:in:startingAt:matchTable:
				hashBytes:startingWith:
				indexOfAscii:inString:startingAt:
				translate:from:to:table:
				compress:toByteArray:
				decompress:fromByteArray:at:)
					includes: method selector) ifFalse:
				[interpreterProxy transcript print: method; cr.
				 interpreterProxy coInterpreter printExternalHeadFrame].
			 interpreterProxy failed ifTrue:
				[interpreterProxy transcript
					nextPutAll: 'WARNING! Failing translated primitive ';
					nextPutAll: aMessage selector;
					nextPutAll: ' implemented by ';
					nextPutAll: method methodClass name;
					nextPutAll: '>>';
					nextPutAll: method selector;
					cr;
					flush]]
]

{ #category : #simulation }
InterpreterPlugin >> evaluateIfFailed: aBlock [
	"Evaluate aBlock, catching primtiive failure, and failing if so.
	 Answer if evaluating aBlock caused primitive failure."
	<doNotGenerate>
	aBlock
		on: Error
		do: [:ex|
			((ex signalerContext selector beginsWith: #primitiveFailed) "e.g. could be error: sent from primitiveFailed:"
			 or: [ex signalerContext sender selector beginsWith: #primitiveFailed]) ifFalse:
				[ex pass].
			interpreterProxy primitiveFail.
			^true].
	^false
]

{ #category : #'simulation support' }
InterpreterPlugin >> executeTranslatedPrimitiveMethod: method arguments: args subsidiaries: subsidiaryMethods [
	<doNotGenerate>
	"Execute the method within a doesNotUnderstand: handler that will
	 catch sends of asciiValue and evaluate any subsidiary methods.."
	^[interpreterProxy withArgs: args executeMethod: method]
		on: MessageNotUnderstood
		do: [:ex|
			ex receiver == interpreterProxy ifTrue:
				[ex resume:
					(self executeTranslatedPrimitiveMethod:
							(subsidiaryMethods
								at: ex message selector
								ifAbsent: [ex pass])
						arguments: ex message arguments
						subsidiaries: subsidiaryMethods)].
			(ex receiver isInteger
			and: [ex message selector == #asciiValue]) ifTrue:
				[ex resume: ex receiver].
			ex pass]
]

{ #category : #initialize }
InterpreterPlugin >> expandDereferenceInterpreterProxyFunctionTable [
	"This is a dummy function that the VMPluginCodeGenerator expands into a
	 sequence of assignments from interpreterProxy funcitons to local function pointers."
	<doNotGenerate>
]

{ #category : #initialize }
InterpreterPlugin >> getInterpreter [
	"Note: This is coded so that plugins can be run from Squeak."

	<returnTypeC: 'VirtualMachine *'>
	^interpreterProxy
]

{ #category : #initialize }
InterpreterPlugin >> getModuleName [
	"Note: This is hardcoded so it can be run from Squeak.
	The module name is used for validating a module *after*
	it is loaded to check if it does really contain the module
	we're thinking it contains. This is important!"
	<returnTypeC:'const char*'>
	<export: true>
	^self cCode: [moduleName]
		inSmalltalk:
			[self class codeGeneratorClass new pluginClass: self class]
]

{ #category : #debugging }
InterpreterPlugin >> halt [
	self cCode: '' inSmalltalk: [^super halt "avoid the ^0 below"].
	^0
]

{ #category : #testing }
InterpreterPlugin >> isInterpreterPlugin [
	<doNotGenerate>
	"Simulation only"
	^true
]

{ #category : #accessing }
InterpreterPlugin >> isSmartSyntaxPluginSimulator [
	<doNotGenerate>
	^false
]

{ #category : #'simulation support' }
InterpreterPlugin >> majorVersion [
	"This is implemented in sqVirtualMachine.c, so this form is for simulation only."
	<doNotGenerate>
	^1
]

{ #category : #'simulation support' }
InterpreterPlugin >> memcpy: dest _: src _: bytes [
	<doNotGenerate>
	"implementation of memcpy(3). N.B. If ranges overlap, must use memmove."

	^interpreterProxy memcpy: dest _: src _: bytes

]

{ #category : #'simulation support' }
InterpreterPlugin >> memmove: destAddress _: sourceAddress _: bytes [
	<doNotGenerate>
	"implementation of memcpy(3). N.B. If ranges overlap, must use memmove."

	^interpreterProxy memmove: destAddress _: sourceAddress _: bytes
]

{ #category : #simulation }
InterpreterPlugin >> methodAndTypesOrNilForTranslatedPrimitiveSelector: selector [
	<doNotGenerate>
	"If selector maps to a simulateable translated primitive method, then
	 answer the method and its types for selector, the selector of a translated primitive.
	 Otherwise answer nil.  This caches the results of analysis in translatedMethodCache."
	translatedMethodCache ifNil:
		[translatedMethodCache := IdentityDictionary new.
		 translatedMethodCache at: #CCodeGenerator put: CCodeGenerator new].
	^translatedMethodCache
		at: selector
		ifAbsentPut: [self tupleOrNilForTranslatedPrimitiveSelector: selector]
]

{ #category : #simulation }
InterpreterPlugin >> methodWithoutPrimitive: method [
	"Answer either aMethod or a copy of aMehtod, such that the result does /not/ have a primitive."
	<doNotGenerate>
	| mn properties newProperties |
	method primitive = 0 ifTrue:
		[^method].
	mn := method methodNode.
	properties := mn properties.
	newProperties := properties copy.
	properties pragmas do:
		[:pragma|
		(pragma keyword beginsWith: #primitive:) ifTrue:
			[newProperties := newProperties copyWithout: pragma]].
	^mn
		instVarNamed: 'primitive' put: 0;
		instVarNamed: 'properties' put: newProperties;
		generate: method trailer using: method class
]

{ #category : #'simulation support' }
InterpreterPlugin >> minorVersion [
	"This is implemented in sqVirtualMachine.c, so this form is for simulation only."
	<doNotGenerate>
	^8
]

{ #category : #debugging }
InterpreterPlugin >> msg: s [ 
	<var: #s type: 'char *'>
	self cCode: 'fprintf(stderr, "\n%s: %s", moduleName, s)' inSmalltalk: [Transcript cr; show: self class moduleName , ': ' , s; endEntry].
	^0
]

{ #category : #'API access' }
InterpreterPlugin >> positiveMachineIntegerFor: value [
	<var: #value type: #'usqIntptr_t'>
	<inline: #always>
	^interpreterProxy wordSize = 8
		ifTrue: [interpreterProxy positive64BitIntegerFor: value]
		ifFalse: [interpreterProxy positive32BitIntegerFor: value]
]

{ #category : #simulation }
InterpreterPlugin >> remapOop: oopOrList in: aBlock [
	"Call remapOop: for the variable oopOrList (or all of the variables in oopOrList) before evaluating
	 aBlock, and restore them after.  If this is Spur, do nothing, since Spur does not GC on allocation
	 and the  SmartSyntaxPluginCodeGenerator generates null code for this op in Spur."
	<doNotGenerate>
	| ctxt tempNames tempIndices |
	interpreterProxy hasSpurMemoryManagerAPI ifTrue:
		[^aBlock value].
	ctxt := thisContext sender.
	tempNames := ctxt tempNames.
	oopOrList isArray
		ifTrue:
			[tempIndices := oopOrList collect: [:tempName| tempNames indexOf: tempName].
			 tempIndices do:
				[:index| interpreterProxy pushRemappableOop: (ctxt namedTempAt: index)]]
		ifFalse: [interpreterProxy pushRemappableOop: oopOrList].
	^aBlock ensure:
		[oopOrList isArray
			ifTrue:
				[tempIndices reverseDo:
					[:index| ctxt namedTempAt: index put: interpreterProxy popRemappableOop]]
			ifFalse:
				[1 to: ctxt numTemps do:
					[:index|
					(ctxt tempAt: index) = oopOrList ifTrue:
						[ctxt tempAt: index put: interpreterProxy topRemappableOop]].
				 interpreterProxy popRemappableOop]]
]

{ #category : #initialize }
InterpreterPlugin >> setInterpreter: anInterpreter [ 
	"Note: This is coded so that it can be run in Squeak."

	| ok |
	<export: true>
	<var: #anInterpreter type: #'struct VirtualMachine*'>
	interpreterProxy := anInterpreter.
	ok := interpreterProxy majorVersion = (self cCode: 'VM_PROXY_MAJOR' inSmalltalk: [self majorVersion])
		and: [interpreterProxy minorVersion >= (self cCode: 'VM_PROXY_MINOR' inSmalltalk: [self minorVersion])].
	ok ifTrue:
		[self expandDereferenceInterpreterProxyFunctionTable].
	^ok
]

{ #category : #'API access' }
InterpreterPlugin >> signedMachineIntegerFor: value [
	<var: #value type: #'sqIntptr_t'>
	<inline: #always>
	^interpreterProxy wordSize = 8
		ifTrue: [interpreterProxy signed64BitIntegerFor: value]
		ifFalse: [interpreterProxy signed32BitIntegerFor: value]
]

{ #category : #'simulation support' }
InterpreterPlugin >> sizeof: objectSymbolOrClass [
	<doNotGenerate>
	objectSymbolOrClass isInteger ifTrue:
		[^interpreterProxy wordSize].
	objectSymbolOrClass isSymbol ifTrue:
		["In the simulator file handles are just integer indices into openFiles and so need
		 only be BytesPerWord big. But in the actual VM they are at least 5 words long."
		objectSymbolOrClass == #SQFile ifTrue:
			[^interpreterProxy wordSize * 5].
		"SQSocket is typedef struct { int sessionID; int socketType; void *privateSocketPtr; } SQSocket"
		objectSymbolOrClass == #SQSocket ifTrue:
			[^8 + interpreterProxy wordSize].
		"We assume the file offset type is always 64-bits."
		objectSymbolOrClass == #squeakFileOffsetType ifTrue:
			[^8].
		(objectSymbolOrClass last == $*
		 or: [#long == objectSymbolOrClass
		 or: [#'unsigned long' == objectSymbolOrClass
		 or: [#'sqIntptr_t' == objectSymbolOrClass
		 or: [#'usqIntptr_t' == objectSymbolOrClass
		 or: [#'size_t' == objectSymbolOrClass]]]]]) ifTrue:
			[^interpreterProxy wordSize].
		(#(usqInt sqInt) includes: objectSymbolOrClass) ifTrue:
			[^interpreterProxy bytesPerOop]].
	^super sizeof: objectSymbolOrClass
]

{ #category : #'simulation support' }
InterpreterPlugin >> strlen: aCString [
	<doNotGenerate>
	^interpreterProxy strlen: aCString
]

{ #category : #'simulation support' }
InterpreterPlugin >> strncpy: aString _: bString _: n [
	<doNotGenerate>
	^interpreterProxy strncpy: aString _: bString _: n
]

{ #category : #simulation }
InterpreterPlugin >> translatedPrimitiveArgument: index ofType: cTypeString using: aCCodeGenerator [
	<doNotGenerate>
	| oop unitSize |
	oop := interpreterProxy stackValue: interpreterProxy methodArgumentCount - index.
	(interpreterProxy isOopForwarded: oop) ifTrue: [^nil]. 
	cTypeString last == $* ifTrue:
		[unitSize := self sizeof: (aCCodeGenerator baseTypeForPointerType: cTypeString) asSymbol.
		 unitSize caseOf: {
			[1]	->	[(interpreterProxy isBytes: oop) ifFalse: [^nil]].
			[2]	->	[(interpreterProxy isShorts: oop) ifFalse: [^nil]].
			[4]	->	[(interpreterProxy isWords: oop) ifFalse: [^nil]].
			[8]	->	[(interpreterProxy isLong64s: oop) ifFalse: [^nil]] }
			otherwise: [^nil].
		^ObjectProxyForTranslatedPrimitiveSimulation new
			interpreter: interpreterProxy
			oop: oop
			unitSize: unitSize].
	((interpreterProxy isIntegerObject: oop)
	 and: [aCCodeGenerator isIntegralCType: cTypeString]) ifTrue:
		[^interpreterProxy integerValueOf: oop].
	self halt
]

{ #category : #simulation }
InterpreterPlugin >> tryToRunTranslatedPrimitive: method types: types subsidiaries: subsidiaryMethods [
	"Evaluate a translated primitive method using the receiver as its receiver.
	 Supply integers or proxies for the arguments as necessary."
	<doNotGenerate>
	| cg args result |
	interpreterProxy methodArgumentCount ~= method numArgs ifTrue:
		[^interpreterProxy primitiveFail].
	cg := translatedMethodCache at: #CCodeGenerator.
	args := (1 to: method numArgs)
				with: types
				collect:
					[:i :type |
					 (self translatedPrimitiveArgument: i ofType: type using: cg) ifNil:
						[^interpreterProxy primitiveFail]].
	result := self executeTranslatedPrimitiveMethod: method arguments: args subsidiaries: subsidiaryMethods.
	interpreterProxy failed ifFalse:
		[result == interpreterProxy
			ifTrue: [interpreterProxy pop: interpreterProxy methodArgumentCount]
			ifFalse:
				[result isInteger
					ifTrue: [interpreterProxy methodReturnValue: (interpreterProxy integerObjectOf: result)]
					ifFalse: [self halt]]]
]

{ #category : #simulation }
InterpreterPlugin >> tupleOrNilForTranslatedPrimitiveSelector: selector [
	"Answer a tuple of {simulation method, types, subsidiary methods, original method}
	 for the selector of a translated primitive.  If the method cannot be simulated, for
	 example if it accesses instance variables, answer a tuple whose types element is nil."
	<doNotGenerate>
	^(self class methodOrNilForTranslatedPrimitiveSelector: selector) ifNotNil:
		[:method| | argNames argPragmas cg types subsidiaryMethods |
		"Since the plugin itself runs the method, and the method is on some
		 distant class, if the method accesses inst vars, the mechanism can't work."
		method hasInstVarRef ifTrue: [^{method. nil. nil. method}].
		argNames := [method methodClass newParser parseParameterNames: method getSource]
						on: Error
						do: [:ex|
							^{method. nil. nil. method}].
		argPragmas := method pragmas select:
							[:p|
							(p keyword beginsWith: 'var:')
							and: [argNames includes: p arguments first]].
		cg := translatedMethodCache at: #CCodeGenerator.
		types := (1 to: method numArgs) collect:
					[:i|
					(argPragmas detect: [:p| p arguments first = (argNames at: i)] ifNone: [])
						ifNil: [#sqInt]
						ifNotNil:
							[:pragma|
							cg extractTypeFor: (argNames at: i) fromDeclaration: pragma arguments second]].
		 "Subsidiary methods are typically implemented for the primitive method only."
		 subsidiaryMethods :=
			method messages
				select:
					[:subsidiary|
					 (method methodClass includesSelector: subsidiary)
					 and: [(Object includesSelector: subsidiary) not]]
				thenCollect:
					[:subsidiary| | subsidiaryMethod |
					subsidiaryMethod := method methodClass >> subsidiary.
					subsidiaryMethod hasInstVarRef ifTrue:
						[^{method. nil. nil. method}].
					subsidiaryMethod].
		 { self methodWithoutPrimitive: method.
		   types.
		   Dictionary withAll:
			(subsidiaryMethods collect:
				[:m| m selector -> (self methodWithoutPrimitive: m)]).
		   method}]
]
