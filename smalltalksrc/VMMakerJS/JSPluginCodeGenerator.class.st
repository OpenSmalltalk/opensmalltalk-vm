"
I generate code that can be loaded dynamically from external libraries
"
Class {
	#name : #JSPluginCodeGenerator,
	#superclass : #JSCodeGenerator,
	#instVars : [
		'pluginClass',
		'pluginName'
	],
	#category : #'VMMakerJS-Translation to JS'
}

{ #category : #inlining }
JSPluginCodeGenerator >> doInlining: inlineFlag [
"do inlining for a plugin"
	self doBasicInlining: inlineFlag.
	self permitMethodPruning
		ifTrue: [self pruneUnreachableMethods]

]

{ #category : #'JS code generator' }
JSPluginCodeGenerator >> emitExportsOn: aStream [
	"Store all the exported primitives in a form to be used by internal plugins"
	aStream nextPutAll:'

Squeak.registerExternalModule("', pluginName,'", {'.

	self exportedPrimitiveNames do:[:primName|
		aStream crtab: 1;
			nextPutAll: primName; 
			nextPutAll: ': '; 
			nextPutAll: primName;
			nextPutAll:','.
	].

aStream nextPutAll: '
});

}); // end of module
'.

]

{ #category : #'JS code generator' }
JSPluginCodeGenerator >> emitJSHeaderForPrimitivesOn: aStream [
	"Write a JS file header for compiled primitives onto the given stream."

	self emitJSHeaderOn: aStream.

]

{ #category : #'JS code generator' }
JSPluginCodeGenerator >> emitJSHeaderOn: aStream [
	"Write a JS file header onto the given stream."

	aStream nextPutAll: '/* '.
	aStream nextPutAll: VMMaker headerNotice.
	aStream nextPutAll: ' */';cr.
	aStream nextPutAll: (self fileHeaderVersionStampForSourceClass: vmClass).
	aStream nextPutAll: '
module("users.bert.SqueakJS.plugins.', pluginName, '").requires("users.bert.SqueakJS.vm").toRun(function() {

var VM_PROXY_MAJOR = ', InterpreterPrimitives vmProxyMajorVersion, ';
var VM_PROXY_MINOR = ', InterpreterPrimitives vmProxyMinorVersion, ';

/*** Functions ***/
function DIV(a, b) { return Math.floor(a / b) | 0; }   // integer division
function MOD(a, b) { return a - DIV(a, b) * b | 0; }   // signed modulus
function SHL(a, b) { return b > 31 ? 0 : a << b ; }    // fix JS shift
function SHR(a, b) { return b > 31 ? 0 : a >>> b ; }   // fix JS shift

'.
]

{ #category : #public }
JSPluginCodeGenerator >> generateCodeStringForPrimitives [
"TPR - moved down from JSCodeGenerator"
	| s methodList |
	s := ReadWriteStream on: (String new: 1000).
	methodList := methods asSortedCollection: [:m1 :m2 | m1 selector < m2 selector].
	self emitJSHeaderForPrimitivesOn: s.
	self emitJSConstantsOn: s.
	self emitJSVariablesOn: s.
	methodList do: [:m | m emitJSCodeOn: s generator: self].
	self emitExportsOn: s.
	^ s contents

]

{ #category : #testing }
JSPluginCodeGenerator >> isGeneratingPluginCode [
	^true
]

{ #category : #'JS code generator' }
JSPluginCodeGenerator >> isTypePointerToStruct: type [ "<String>"
	^pluginClass notNil
	  and: [[pluginClass isTypePointerToStruct: type]
			on: MessageNotUnderstood
			do: [:ex| ex message selector == #isTypePointerToStruct: ifTrue: [^false].
					ex pass]]
]

{ #category : #public }
JSPluginCodeGenerator >> localizeGlobalVariables [
"TPR - we don't do this for plugins"
]

{ #category : #public }
JSPluginCodeGenerator >> pluginName: aString [
"TPR - moved from JSCodeGenerator"
	"Set the plugin name when generating plugins."
	pluginName := aString.
]

{ #category : #private }
JSPluginCodeGenerator >> storeVirtualMachineProxyHeader: categoryList on: fileName [
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
JSPluginCodeGenerator >> storeVirtualMachineProxyImplementation: categoryList on: fileName [
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
			(methods at: sel) emitJSFunctionHeader: stream generator: self.
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
