"
I generate code that can be loaded dynamically from external libraries (e.g., DSOs on Unix or DLLs on Windows)
"
Class {
	#name : #VMPluginCodeGenerator,
	#superclass : #CCodeGenerator,
	#instVars : [
		'pluginClass',
		'pluginName',
		'pluginFunctionsUsed',
		'inProgressSelectors'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #'spur primitive compilation' }
VMPluginCodeGenerator >> accessorChainsForMethod: method interpreterClass: interpreterClass [
	inProgressSelectors := Set new.
	^[super accessorChainsForMethod: method interpreterClass: interpreterClass] ensure:
		[inProgressSelectors := nil]
]

{ #category : #'spur primitive compilation' }
VMPluginCodeGenerator >> accessorDepthDeterminationFollowsSelfSends [
	^true
]

{ #category : #'spur primitive compilation' }
VMPluginCodeGenerator >> accessorsAndAssignmentsForSubMethodNamed: selector actuals: actualParameters depth: depth interpreterClass: interpreterClass into: aTrinaryBlock [
	"Evaluate aTrinaryBlock with the root accessor sends, accessor sends and assignments in the sub-method named selector."

	| method map |
	(inProgressSelectors includes: selector) ifTrue:
		[^nil].
	inProgressSelectors add: selector.
	method := self methodNamed: selector.
	"this is unsatisfactory.  a pluggable scheme that asks the relevant plugin the right question would
	 be better but for now the only cross-plugin load is for loadBitBltFrom:warping: and variants."
	(#(loadBitBltFrom: loadWarpBltFrom: loadBitBltFrom:warping:) includes: selector) ifTrue:
		[(method isNil
		  or: [method definingClass ~~ BitBltSimulation]) ifTrue:
			[method := (BitBltSimulation >> selector) methodNode asTranslationMethodOfClass: TMethod]].
	method ifNil:
		[^nil].
	map := Dictionary new.
	method args do: [:var| map at: var put: depth asString, var].
	method locals do: [:var| map at: var put: depth asString, var].
	^self accessorsAndAssignmentsForMethod: (method copy renameVariablesUsing: map)
		actuals: actualParameters
		depth: depth + 1
		interpreterClass: interpreterClass
		into: aTrinaryBlock
]

{ #category : #'C translation' }
VMPluginCodeGenerator >> atLeastVMProxyMajor: major minor: minor [ 
	^String streamContents:
		[:s|
		s	nextPutAll: 'VM_PROXY_MAJOR > '; print: major;
			nextPutAll: ' || (VM_PROXY_MAJOR == '; print: major;
			nextPutAll: ' && VM_PROXY_MINOR >= '; print: minor;
			nextPutAll: ')']
]

{ #category : #utilities }
VMPluginCodeGenerator >> compileToTMethodSelector: selector in: aClass [
	"Compile a method to a TMethod. Override to eagerly record declarations etc
	 that happen in a later phase in the main VM's CCodeGenerator."

	| m |
	m := (Compiler new
			parse: (aClass sourceCodeAt: selector)
			in: aClass
			notifying: nil)
				asTranslationMethodOfClass: self translationMethodClass.
	m removeFinalSelfReturnIn: self.
	m recordDeclarationsIn: self.
	m inferReturnTypeIn: self.
	m returnType ifNil:
		[m returnType: (self implicitReturnTypeFor: selector)].
	^m
]

{ #category : #inlining }
VMPluginCodeGenerator >> doInlining: inlineFlag [
"do inlining for a plugin"
	^self doBasicInlining: inlineFlag
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag [
	"Generate twice; the first time to collect the used functions, the second to output the used functions."
	| savedHeaders |
	savedHeaders := headerFiles copy.
	[super emitCCodeOn: NullStream new doInlining: inlineFlag doAssertions: assertionFlag]
		on: MessageNotUnderstood
		do: [:ex|
				(#(cr crtab: ensureCr peekLast space tab tab:) includes: ex message selector) ifTrue:
					[ex resume: nil].
				ex pass].
	headerFiles := savedHeaders.
	super emitCCodeOn: aStream doInlining: inlineFlag doAssertions: assertionFlag
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> emitCHeaderForPrimitivesOn: aStream [
	"Write a C file header for compiled primitives onto the given stream."

	self emitCHeaderOn: aStream.
	aStream nextPutAll: '
/*** Proxy Functions ***/
#if defined(SQUEAK_BUILTIN_PLUGIN)
extern sqInt stackValue(sqInt offset);
extern sqInt stackIntegerValue(sqInt offset);
extern sqInt failed(void);
# define successFlag (!failed())
extern sqInt success(sqInt aBoolean);
extern void * arrayValueOf(sqInt oop);
extern void * fetchArrayofObject(sqInt fieldIndex, sqInt objectPointer);
extern double fetchFloatofObject(sqInt fieldIndex, sqInt objectPointer);
extern sqInt fetchIntegerofObject(sqInt fieldIndex, sqInt objectPointer);
extern double floatValueOf(sqInt oop);
extern sqInt pop(sqInt nItems);
extern sqInt pushInteger(sqInt integerValue);
extern sqInt sizeOfSTArrayFromCPrimitive(void *cPtr);
extern sqInt storeIntegerofObjectwithValue(sqInt index, sqInt oop, sqInt integer);
extern sqInt primitiveFail(void);
#else /* SQUEAK_BUILTIN_PLUGIN */
# define stackValue(i) (interpreterProxy->stackValue(i))
# define stackIntegerValue(i) (interpreterProxy->stackIntegerValue(i))
# define successFlag (!interpreterProxy->failed())
# define success(bool) (interpreterProxy->success(bool))
# define arrayValueOf(oop) (interpreterProxy->arrayValueOf(oop))
# define fetchArrayofObject(idx,oop) (interpreterProxy->fetchArrayofObject(idx,oop))
# define fetchFloatofObject(idx,oop) (interpreterProxy->fetchFloatofObject(idx,oop))
# define fetchIntegerofObject(idx,oop) (interpreterProxy->fetchIntegerofObject(idx,oop))
# define floatValueOf(oop) (interpreterProxy->floatValueOf(oop))
# define pop(n) (interpreterProxy->pop(n))
# define pushInteger(n) (interpreterProxy->pushInteger(n))
# define sizeOfSTArrayFromCPrimitive(cPtr) (interpreterProxy->sizeOfSTArrayFromCPrimitive(cPtr))
# define storeIntegerofObjectwithValue(idx,oop,value) (interpreterProxy->storeIntegerofObjectwithValue(idx,oop,value))
# define primitiveFail() interpreterProxy->primitiveFail()
#endif /* SQUEAK_BUILTIN_PLUGIN */

/* allows accessing Strings in both C and Smalltalk */
#define asciiValue(c) c


'
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> emitCHeaderOn: aStream [
	"Write a C file header onto the given stream."

	aStream nextPutAll: (self fileHeaderVersionStampForSourceClass: pluginClass).
	aStream cr; cr.

	#('<math.h>' '<stdio.h>' '<stdlib.h>' '<string.h>' '<time.h>') reverseDo:
		[:hdr| self addHeaderFileFirst: hdr].

	"Additional header files; include C library ones first."
	self emitHeaderFiles: (headerFiles select: [:hdr| hdr includes: $<]) on: aStream.

	aStream cr; nextPutAll:'/* Default EXPORT macro that does nothing (see comment in sq.h): */
#define EXPORT(returnType) returnType

/* Do not include the entire sq.h file but just those parts needed. */
/*  The virtual machine proxy definition */
#include "sqVirtualMachine.h"
/* Configuration options */
#include "sqConfig.h"
/* Platform specific definitions */
#include "sqPlatformSpecific.h"

#define true 1
#define false 0
#define null 0  /* using ''null'' because nil is predefined in Think C */
#ifdef SQUEAK_BUILTIN_PLUGIN
#undef EXPORT
// was #undef EXPORT(returnType) but screws NorCroft cc
#define EXPORT(returnType) static returnType
#endif'; cr; cr.
	self addHeaderFile: '"sqMemoryAccess.h"'.
	"Additional header files; include squeak VM ones last"
	self emitHeaderFiles: (headerFiles reject: [:hdr| hdr includes: $<]) on: aStream.
	self maybePutPreambleFor: pluginClass on: aStream.
	aStream cr.
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> emitCTypesOn: aStream [
	"Store local type declarations on the given stream."
	(self structClassesForTranslationClasses: { pluginClass }) do:
		[:structClass|
		(structClass isAbstract not
		 and: [pluginClass shouldGenerateTypedefFor: structClass]) ifTrue:
			[structClass printTypedefOn: aStream.
			 aStream cr; cr]]
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> emitExportsOn: aStream [
	"Store all the exported primitives in the form used by the internal named prim system."
	aStream cr; cr; nextPutAll:'#ifdef SQUEAK_BUILTIN_PLUGIN'.
	self emitExportsNamed: pluginName pluginName: pluginName on: aStream.
	aStream cr; nextPutAll: '#endif /* ifdef SQ_BUILTIN_PLUGIN */'; cr
]

{ #category : #'C translation' }
VMPluginCodeGenerator >> emitIfdefForPluginFunctionOption: anArray on: aStream [ 
	aStream nextPutAll: '#if '; nextPutAll: (self perform: anArray first withArguments: anArray allButFirst)
]

{ #category : #public }
VMPluginCodeGenerator >> generateCodeStringForPrimitives [
"TPR - moved down from CCodeGenerator"
	| s methodList |
	s := ReadWriteStream on: (String new: 1000).
	methodList := methods asSortedCollection: [:m1 :m2 | m1 selector < m2 selector].
	self emitCHeaderForPrimitivesOn: s.
	self emitCConstantsOn: s.
	self emitCVariablesOn: s.
	self emitCFunctionPrototypes: methodList on: s.
	methodList do: [:m | m emitCCodeOn: s generator: self].
	self emitExportsOn: s.
	^ s contents

]

{ #category : #'C translation' }
VMPluginCodeGenerator >> generateInterpreterProxyFunctionDeference: aNode on: aStream indent: anInteger [
	| pluginsToClone |
	(pluginsToClone := self pluginFunctionsToClone) isEmpty ifTrue:
		[^self].
	aStream cr; nextPutAll: '#if !defined(SQUEAK_BUILTIN_PLUGIN)'.
	pluginsToClone do:
		[:s| | cs |
		cs := self cFunctionNameFor: s.
		self withOptionalVerbiageFor: s
			on: aStream
			do: [aStream crtab: anInteger; nextPutAll: cs; nextPutAll: ' = interpreterProxy->'; nextPutAll: cs; nextPut: $;]
			ifOptionalDo: [aStream crtab: anInteger; nextPutAll: cs; nextPutAll: ' = 0;']].
	aStream cr; nextPutAll: '#endif /* !defined(SQUEAK_BUILTIN_PLUGIN) */'.
]

{ #category : #'type inference' }
VMPluginCodeGenerator >> harmonizeReturnTypesIn: aSetOfTypes [
	"Eliminate signed/unsigned conflicts in aSetOfTypes.  Override to
	 default to void if any one return type is void."
	^(aSetOfTypes includes: #void)
		ifTrue: [Set with: #void]
		ifFalse: [super harmonizeReturnTypesIn: aSetOfTypes]
]

{ #category : #public }
VMPluginCodeGenerator >> initialize [
	super initialize.
	pluginFunctionsUsed := Set new
]

{ #category : #public }
VMPluginCodeGenerator >> initializeCTranslationDictionary [ 
	"Initialize the dictionary mapping message names to actions for C code generation."

	super initializeCTranslationDictionary.
	translationDict
		at: #expandDereferenceInterpreterProxyFunctionTable
		put: #generateInterpreterProxyFunctionDeference:on:indent:
]

{ #category : #testing }
VMPluginCodeGenerator >> isGeneratingPluginCode [
	^true
]

{ #category : #public }
VMPluginCodeGenerator >> localizeGlobalVariables [
"TPR - we don't do this for plugins"
]

{ #category : #public }
VMPluginCodeGenerator >> noteUsedPluginFunction: aSelector [
	"Remember aSelector and answer whether the call should be made through
	 interpreterProxy. If not, it will be made either directly (in an internal plugin)
	 or through a local copy of the function pointer (in an external plugin)."
	pluginFunctionsUsed add: aSelector.
	"These two are static to sqVirtualMachine.c and so
	 they must be called through the interpreterProxy."
	^#(majorVersion minorVersion) includes: aSelector
]

{ #category : #public }
VMPluginCodeGenerator >> pluginClass: aPluginClass [
	"Set the plugin class and name when generating plugins."
	| packageId |
	pluginClass := aPluginClass.
	pluginName := pluginClass moduleName.
	packageId := self shortMonticelloDescriptionForClass: pluginClass.
	(packageId beginsWith: pluginClass name) ifTrue:
		[packageId := packageId allButFirst: pluginClass name size].
	(packageId beginsWith: pluginName) ifTrue:
		[packageId := packageId allButFirst: pluginName size].
	self declareModuleName: pluginClass moduleNameAndVersion, packageId
]

{ #category : #public }
VMPluginCodeGenerator >> pluginFunctionsToClone [
	"Answer those of the used plugin functions to clone as a sorted collection.
	 Exclude those that are static to sqVirtualMachine.c and hence always need
	 to be called through interpreterProxy."

	^((pluginFunctionsUsed
		reject: [:selector| self noteUsedPluginFunction: selector])
			select: [:selector| InterpreterProxy includesSelector: selector])
				asSortedCollection
]

{ #category : #public }
VMPluginCodeGenerator >> pluginName: aString [
"TPR - moved from CCodeGenerator"
	"Set the plugin name when generating plugins."
	pluginName := aString.
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> preDeclareInterpreterProxyOn: aStream [
	"Put the necessary #defines needed before interpreterProxy.  Basically
	 internal plugins use the VM's interpreterProxy variable and external plugins
	 use their own.  Override to keep local copies of all functions in external
	 prims, and link directly in internal plugins."
	"| pcc |
	pcc := self new.
	(InterpreterProxy selectors reject: [:s| #(initialize private) includes: (InterpreterProxy whichCategoryIncludesSelector: s)]) do:
		[:s| pcc noteUsedPluginFunction: s].
	pcc preDeclareInterpreterProxyOn: Transcript.
	Transcript flush"
	| pluginsToClone |
	(pluginsToClone := self pluginFunctionsToClone) isEmpty ifTrue:
		[^super preDeclareInterpreterProxyOn: aStream].
	aStream cr; nextPutAll: '#if !defined(SQUEAK_BUILTIN_PLUGIN)'; cr.
	pluginsToClone do:
		[:selector| | functionName |
		functionName := self cFunctionNameFor: selector.
		aStream nextPutAll:
			((String streamContents:
				[:s|
				(self compileToTMethodSelector: selector in: InterpreterProxy)
					emitCFunctionPrototype: s generator: self])
				copyReplaceAll: functionName
				with: '(*', functionName, ')').
		aStream nextPut: $;; cr].
	aStream nextPutAll: '#else /* !defined(SQUEAK_BUILTIN_PLUGIN) */'.
	pluginsToClone do:
		[:selector| | m |
		m := self compileToTMethodSelector: selector in: InterpreterProxy.
		self withOptionalVerbiageFor: selector
			on: aStream
			do: [aStream cr; nextPutAll: 'extern '.
				m static: false; emitCFunctionPrototype: aStream generator: self.
				aStream nextPut: $;]
			ifOptionalDo:
				[aStream cr; nextPutAll: '# define '.
				 (TSendNode new
					setSelector: selector
						receiver: (TVariableNode new setName: 'interpreterProxy')
							arguments: (m args collect: [:a| TVariableNode new setName: a]))
					emitCCodeAsArgumentOn: aStream
						level: 0
							generator: self.
				 aStream nextPutAll: ' 0']].
	aStream cr; nextPutAll: 'extern'.
	aStream cr; nextPutAll: '#endif'; cr
]

{ #category : #private }
VMPluginCodeGenerator >> storeVirtualMachineProxyHeader: categoryList on: fileName [
	"Store the interpreter definitions on the given file"
	| stream |
	stream := FileStream newFileNamed: fileName.
	stream nextPutAll:
'#ifndef _SqueakVM_H
#define _SqueakVM_H

/* Increment the following number if you change the order of
   functions listed or if you remove functions */
#define VM_PROXY_MAJOR 1

/* Increment the following number if you add functions at the end */
#define VM_PROXY_MINOR 0

typedef struct VirtualMachine {
	int (*minorVersion) (void);
	int (*majorVersion) (void);
'.

	categoryList do:[:assoc|
		stream cr; crtab; nextPutAll:'/* InterpreterProxy methodsFor: ''',assoc key, ''' */'; cr; crtab.
		(self sortStrings: assoc value) do:[:sel|
			(methods at: sel) emitProxyFunctionPrototype: stream generator: self.
			stream nextPutAll: ';'; crtab]].

	stream nextPutAll:'
} VirtualMachine;

#endif /* _SqueakVM_H */
'.
	stream close.
]

{ #category : #private }
VMPluginCodeGenerator >> storeVirtualMachineProxyImplementation: categoryList on: fileName [
	"Store the interpreter definitions on the given file"
	| stream |
	stream := FileStream newFileNamed: fileName.
	stream nextPutAll:'
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "sqVirtualMachine.h"'; cr;cr.
	stream nextPutAll:'/*** Function prototypes ***/'.

	categoryList do:[:assoc|
		stream cr; cr; nextPutAll:'/* InterpreterProxy methodsFor: ''',assoc key, ''' */'; cr.
		(self sortStrings: assoc value) do:[:sel|
			(methods at: sel) emitCFunctionPrototype: stream generator: self.
			stream nextPut: $;; cr]].

	stream cr; nextPutAll:'struct VirtualMachine *VM = NULL;'; cr.
	stream cr; nextPutAll:
'static int majorVersion(void) {
	return VM_PROXY_MAJOR;
}

static int minorVersion(void) {
	return VM_PROXY_MINOR;
}

struct VirtualMachine* sqGetInterpreterProxy(void)
{
	if(VM) return VM;
	VM = (struct VirtualMachine *) calloc(1, sizeof(VirtualMachine));
	/* Initialize Function pointers */
	VM->majorVersion = majorVersion;
	VM->minorVersion = minorVersion;
'.
	categoryList do:[:assoc|
		stream cr; crtab; nextPutAll:'/* InterpreterProxy methodsFor: ''',assoc key, ''' */'; crtab.
		assoc value asSortedCollection do:[:sel|
		stream nextPutAll:'VM->';
			nextPutAll: (self cFunctionNameFor: sel);
			nextPutAll:' = ';
			nextPutAll: (self cFunctionNameFor: sel);
			nextPutAll:';';
			crtab]].

	stream cr; crtab; nextPutAll:'return VM;'; cr; nextPutAll:'}'; cr.
	stream close.
]

{ #category : #'C translation' }
VMPluginCodeGenerator >> withOptionalVerbiageFor: selector on: aStream do: mainBlock ifOptionalDo: optionalBlock [
	(InterpreterProxy >> selector pragmaAt: #option:)
		ifNil:
			[mainBlock value]
		ifNotNil:
			[:pragma|
			 aStream cr.
			 self emitIfdefForPluginFunctionOption: pragma arguments first on: aStream.
			 mainBlock value.
			 aStream cr; nextPutAll: '#else'.
			 optionalBlock value.
			 aStream cr; nextPutAll: '#endif']
]
