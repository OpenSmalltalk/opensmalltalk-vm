Class {
	#name : #ImmX11Plugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : 'VMMaker-Plugins'
}

{ #category : #'as yet unclassified' }
ImmX11Plugin class >> declareHeaderFilesIn: cg [

	cg addHeaderFile: '<locale.h>'.
	cg addHeaderFile: '"sqUnixMain.h"'.
	cg addHeaderFile: '"sqUnixCharConv.h"', Character cr asString,
		'extern char *setLocale(char *, size_t);', Character cr asString,
		'extern int setCompositionWindowPosition(int, int);', Character cr asString,
		'extern int setCompositionFocus(int);'.
]

{ #category : #'initialize-release' }
ImmX11Plugin >> initialiseModule [

	<export: true>
	^ true

]

{ #category : #primitives }
ImmX11Plugin >> primGetEncoding [

	| ret array len |

	<export: true>
	<var: #len type: 'int'>
	<var: #array type: 'char *'>
	len := self cCode: 'strlen(sqTextEncoding)'.

	ret := interpreterProxy
			instantiateClass: interpreterProxy classString
			indexableSize: len.
	array := self cCoerce: (interpreterProxy firstIndexableField: ret) to: 'char *'.	
	self cCode: 'strncpy(array, (char *)sqTextEncoding, len)'.
	
	^ ret.
]

{ #category : #primitives }
ImmX11Plugin >> primGetLocale [

	| ret array len locale |

	<export: true>
	<var: #len type: 'int'>
	<var: #array type: 'char *'>
	<var: #locale type: 'char *'>
	
	locale := self cCode: 'setlocale(LC_CTYPE, "")'.
	(self cCode: 'locale')
		ifFalse: [ ret := interpreterProxy nilObject ]
		ifTrue: [
			len := self cCode: 'strlen(locale)'.
			ret := interpreterProxy
				instantiateClass: interpreterProxy classString
				indexableSize: len.
			array := self cCoerce: (interpreterProxy firstIndexableField: ret) to: 'char *'.
			self cCode: 'strncpy(array, (char *)locale, len)'.
		].	
	^ ret.
]

{ #category : #primitives }
ImmX11Plugin >> primGetLocaleEncoding [

	| ret array len |

	<export: true>
	<var: #len type: 'int'>
	<var: #array type: 'char *'>

	(self cCode: '(int) localeEncoding')
		ifFalse: [ ret := interpreterProxy nilObject ]
		ifTrue: [
			len := self cCode: 'strlen(localeEncoding)'.
			ret := interpreterProxy
				instantiateClass: interpreterProxy classString
				indexableSize: len.
			array := self cCoerce: (interpreterProxy firstIndexableField: ret) to: 'char *'.
			self cCode: 'strncpy(array, (char *)localeEncoding, len)'.
		].	
	^ ret.
]

{ #category : #primitives }
ImmX11Plugin >> primGetPathEnc [

	| ret array len |

	<export: true>
	<var: #len type: 'int'>
	<var: #array type: 'char *'>
	len := self cCode: 'strlen(uxPathEncoding)'.

	ret := interpreterProxy
			instantiateClass: interpreterProxy classString
			indexableSize: len.
	array := self cCoerce: (interpreterProxy firstIndexableField: ret) to: 'char *'.	
	self cCode: 'strncpy(array, (char *)uxPathEncoding, len)'.
	
	^ ret.
]

{ #category : #primitives }
ImmX11Plugin >> primGetTextEnc [

	| ret array len |

	<export: true>
	<var: #len type: 'int'>
	<var: #array type: 'char *'>
	len := self cCode: 'strlen(uxTextEncoding)'.

	ret := interpreterProxy
			instantiateClass: interpreterProxy classString
			indexableSize: len.
	array := self cCoerce: (interpreterProxy firstIndexableField: ret) to: 'char *'.	
	self cCode: 'strncpy(array, (char *)uxTextEncoding, len)'.
	
	^ ret.
]

{ #category : #primitives }
ImmX11Plugin >> primGetXWinEnc [

	| ret array len |

	<export: true>
	<var: #len type: 'int'>
	<var: #array type: 'char *'>
	len := self cCode: 'strlen(uxXWinEncoding)'.

	ret := interpreterProxy
			instantiateClass: interpreterProxy classString
			indexableSize: len.
	array := self cCoerce: (interpreterProxy firstIndexableField: ret) to: 'char *'.	
	self cCode: 'strncpy(array, (char *)uxXWinEncoding, len)'.
	
	^ ret.
]

{ #category : #primitives }
ImmX11Plugin >> primIsTextEncUTF8 [

	<export: true>
	self primitive: 'primIsTextEncUTF8'.
	^ (self cCode: 'textEncodingUTF8') asOop: Boolean.
]

{ #category : #primitives }
ImmX11Plugin >> primSetCompositionFocus: bool [

	| ret |
	<export: true>
	self primitive: 'primSetCompositionFocus'
		parameters: #(Boolean).
	
	ret := self cCode: 'setCompositionFocus(bool)'.

	ret = false ifTrue: [
		interpreterProxy primitiveFail.
		^ nil
	].

	^ ret asOop: Boolean

]

{ #category : #primitives }
ImmX11Plugin >> primSetCompositionWindowPositionX: x y: y [

	| ret |

	<export: true>
	self primitive: 'primSetCompositionWindowPosition'
		parameters: #(SmallInteger SmallInteger).
	

	ret := self cCode: 'setCompositionWindowPosition(x, y)'.

	ret = false ifTrue: [
		interpreterProxy primitiveFail.
		^ nil
	].

	^ ret asOop: Boolean


]

{ #category : #primitives }
ImmX11Plugin >> primSetEncoding: encoding [

	| name len |
	<export: true>
	<var: #name type: 'char *'>
	<var: #len type: 'size_t'>
	len := interpreterProxy stSizeOf: encoding.
	name := self cCoerce: (interpreterProxy firstIndexableField: encoding) to: 'char *'.
	self cCode: 'setNEncoding(&sqTextEncoding, name, len)'.
	^ encoding.

]

{ #category : #primitives }
ImmX11Plugin >> primSetEncodingToLocale [

	| ret |
	<export: true>
	self primitive: 'primSetEncodingToLocale'.
	
	(self cCode: '(int) localeEncoding')
		ifFalse: [ ret := interpreterProxy falseObject ] 
		ifTrue: [
			self cCode: 'sqTextEncoding = (void *)localeEncoding'.
			ret := interpreterProxy trueObject
		].
	^ ret
]

{ #category : #primitives }
ImmX11Plugin >> primSetLocale: locale [

	| name len ret array |
	<export: true>
	<var: #name type: 'char *'>
	<var: #array type: 'char *'>
	<var: #len type: 'size_t'>
	len :=  interpreterProxy stSizeOf: locale.
	name := self cCoerce: (interpreterProxy arrayValueOf: locale) to: 'char *'.
	name := self cCode: 'setLocale(name, len)'.
	(self cCode: '(int) name')
		ifFalse: [^ interpreterProxy nilObject ]
		ifTrue: [
			len := self cCode: 'strlen(name)'.
			ret := interpreterProxy
				instantiateClass: interpreterProxy classString
				indexableSize: len.
			array := self cCoerce: (interpreterProxy firstIndexableField: ret) to: 'char *'.
			self cCode: 'strncpy(array, (char *)name, len)'.
			^ ret ].

]

{ #category : #primitives }
ImmX11Plugin >> primSetLocaleEncoding: encoding [

	| name len |
	<export: true>
	<var: #name type: 'char *'>
	<var: #len type: 'size_t'>
	len := interpreterProxy stSizeOf: encoding.
	name := self cCoerce: (interpreterProxy firstIndexableField: encoding) to: 'char *'.
	self cCode: 'setNEncoding(&localeEncoding, name, len)'.
	self cCode: 'sqTextEncoding= uxTextEncoding= uxPathEncoding= uxXWinEncoding= localeEncoding'.
	^ encoding.

]

{ #category : #primitives }
ImmX11Plugin >> primSetPathEnc: encoding [

	| name len |
	<export: true>
	<var: #name type: 'char *'>
	<var: #len type: 'size_t'>
	len := interpreterProxy stSizeOf: encoding.
	name := self cCoerce: (interpreterProxy firstIndexableField: encoding) to: 'char *'.
	self cCode: 'setNEncoding(&uxPathEncoding, name, len)'.
	^ encoding.
]

{ #category : #primitives }
ImmX11Plugin >> primSetPathEncToLocale [

	| ret |
	<export: true>
	self primitive: 'primSetPathEncToLocale'.
	
	(self cCode: '(int) localeEncoding')
		ifFalse: [ ret := interpreterProxy falseObject ] 
		ifTrue: [
			self cCode: 'uxPathEncoding = (void *)localeEncoding'.
			ret := interpreterProxy trueObject
		].
	^ ret
]

{ #category : #primitives }
ImmX11Plugin >> primSetTextEnc: encoding [

	| name len |
	<export: true>
	<var: #name type: 'char *'>
	<var: #len type: 'size_t'>
	len := interpreterProxy stSizeOf: encoding.
	name := self cCoerce: (interpreterProxy firstIndexableField: encoding) to: 'char *'.
	self cCode: 'setNEncoding(&uxTextEncoding, name, len)'.
	^ encoding.
]

{ #category : #primitives }
ImmX11Plugin >> primSetTextEncToLocale [

	| ret |
	<export: true>
	self primitive: 'primSetTextEncToLocale'.
	
	(self cCode: '(int) localeEncoding')
		ifFalse: [ ret := interpreterProxy falseObject ] 
		ifTrue: [
			self cCode: 'uxTextEncoding = (void *)localeEncoding'.
			ret := interpreterProxy trueObject
		].
	^ ret
]

{ #category : #primitives }
ImmX11Plugin >> primSetTextEncUTF8: bool [

	<export: true>
	self primitive: 'primSetTextEncUTF8'
		parameters: #(Boolean).
	self cCode: 'textEncodingUTF8 = bool'.
	^ bool asOop: Boolean.
]

{ #category : #primitives }
ImmX11Plugin >> primSetXWinEnc: encoding [

	| name len |
	<export: true>
	<var: #name type: 'char *'>
	<var: #len type: 'size_t'>
	len := interpreterProxy stSizeOf: encoding.
	name := self cCoerce: (interpreterProxy firstIndexableField: encoding) to: 'char *'.
	self cCode: 'setNEncoding(&uxXWinEncoding, name, len)'.
	^ encoding.
]

{ #category : #primitives }
ImmX11Plugin >> primSetXWinEncToLocale [

	| ret |
	<export: true>
	self primitive: 'primSetXWinEncToLocale'.
	
	(self cCode: '(int) localeEncoding')
		ifFalse: [ ret := interpreterProxy falseObject ] 
		ifTrue: [
			self cCode: 'uxXWinEncoding = (void *)localeEncoding'.
			ret := interpreterProxy trueObject
		].
	^ ret
]

{ #category : #'initialize-release' }
ImmX11Plugin >> shutdownModule [

	<export: true>
	^ true

]
