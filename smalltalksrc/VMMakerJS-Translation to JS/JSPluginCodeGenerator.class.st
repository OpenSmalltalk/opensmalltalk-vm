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
function CLASSOF(obj) { return typeof obj === "number" ? interpreterProxy.classSmallInteger() : obj.sqClass }
function SLOTSIZEOF(obj) { return obj.bytes ? obj.bytes.length : obj.words ? obj.words.length : obj.pointers ? obj.pointers.length : 0 }
function BYTESIZEOF(obj) { return obj.bytes ? obj.bytes.length : 0 }
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
