"
I generate code that can be loaded dynamically from external libraries (e.g., DSOs on Unix or DLLs on Windows)
"
Class {
	#name : #VMPluginCodeGenerator,
	#superclass : #CCodeGenerator,
	#instVars : [
		'pluginName'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #inlining }
VMPluginCodeGenerator >> doInlining: inlineFlag [
"do inlining for a plugin"
	^self doBasicInlining: inlineFlag
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> emitCHeaderForPrimitivesOn: aStream [
	"Write a C file header for compiled primitives onto the given stream."

	self emitCHeaderOn: aStream.
	aStream nextPutAll: '
/*** Proxy Functions ***/
#define stackValue(i) (interpreterProxy->stackValue(i))
#define stackIntegerValue(i) (interpreterProxy->stackIntegerValue(i))
#define successFlag (!interpreterProxy->failed())
#define success(bool) (interpreterProxy->success(bool))
#define arrayValueOf(oop) (interpreterProxy->arrayValueOf(oop))
#define checkedIntegerValueOf(oop) (interpreterProxy->checkedIntegerValueOf(oop))
#define fetchArrayofObject(idx,oop) (interpreterProxy->fetchArrayofObject(idx,oop))
#define fetchFloatofObject(idx,oop) (interpreterProxy->fetchFloatofObject(idx,oop))
#define fetchIntegerofObject(idx,oop) (interpreterProxy->fetchIntegerofObject(idx,oop))
#define floatValueOf(oop) (interpreterProxy->floatValueOf(oop))
#define pop(n) (interpreterProxy->pop(n))
#define pushInteger(n) (interpreterProxy->pushInteger(n))
#define sizeOfSTArrayFromCPrimitive(cPtr) (interpreterProxy->sizeOfSTArrayFromCPrimitive(cPtr))
#define storeIntegerofObjectwithValue(idx,oop,value) (interpreterProxy->storeIntegerofObjectwithValue(idx,oop,value))
#define primitiveFail() interpreterProxy->primitiveFail()
/* allows accessing Strings in both C and Smalltalk */
#define asciiValue(c) c

'.
	aStream cr.
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> emitCHeaderOn: aStream [
	"Write a C file header onto the given stream."

	aStream nextPutAll: '/* '.
	aStream nextPutAll: VMMaker headerNotice.
	aStream nextPutAll: ' */';cr.

	aStream nextPutAll:'
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

/* Default EXPORT macro that does nothing (see comment in sq.h): */
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
#endif
'.

	"Additional header files"
	headerFiles do:[:hdr|
		aStream nextPutAll:'#include '; nextPutAll: hdr; cr].


	aStream nextPutAll: '
#include "sqMemoryAccess.h"

'.
	aStream cr.
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> emitExportsOn: aStream [
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

'.
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

{ #category : #testing }
VMPluginCodeGenerator >> isGeneratingPluginCode [
	^true
]

{ #category : #'C code generator' }
VMPluginCodeGenerator >> isTypePointerToStruct: type [ "<String>"
	^pluginClass notNil
	  and: [[pluginClass isTypePointerToStruct: type]
			on: MessageNotUnderstood
			do: [:ex| ex message selector == #isTypePointerToStruct: ifTrue: [^false].
					ex pass]]
]

{ #category : #public }
VMPluginCodeGenerator >> localizeGlobalVariables [
"TPR - we don't do this for plugins"
]

{ #category : #public }
VMPluginCodeGenerator >> pluginName: aString [
"TPR - moved from CCodeGenerator"
	"Set the plugin name when generating plugins."
	pluginName := aString.
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
		assoc value asSortedCollection do:[:sel|
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
		assoc value asSortedCollection do:[:sel|
			(methods at: sel) emitCFunctionPrototype: stream generator: self.
			stream nextPutAll: ';'; cr]].

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
