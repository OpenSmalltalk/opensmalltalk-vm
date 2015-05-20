"
I am the Plugin for the Squeak/Applescript Interface. Since it requires platform support it will only be built when supported on your platform
"
Class {
	#name : #TestOSAPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #'as yet unclassified' }
TestOSAPlugin class >> declareCVarsIn: cg [
	cg addHeaderFile: '<Carbon/Carbon.h>'.

]

{ #category : #translation }
TestOSAPlugin class >> requiresPlatformFiles [
	"this plugin requires platform specific files in order to work"
	^true
]

{ #category : #'AppleEvents prims' }
TestOSAPlugin >> primAECoerceDesc: typeCode to: result [

	|rcvr |
	rcvr := self 	primitive: 	'primAECoerceDesc'
				parameters:	#(DescType AEDesc)
				receiver:	#AEDesc.
	^(self 
		cCode: 'AECoerceDesc(rcvr,*typeCode,result)'
		inSmalltalk: [[rcvr]. -1]) asOop: Unsigned
]

{ #category : #'AppleEvents prims' }
TestOSAPlugin >> primAECreateDesc: typeCode from: aString [

	|rcvr size |
	rcvr := self 	primitive: 	'primAECreateDesc'
				parameters:	#(DescType String)
				receiver:	#AEDesc.
	size := aString size.
	^(self 
		cCode: 'AECreateDesc(*typeCode, aString, size, rcvr)'
		inSmalltalk: [[rcvr. size]. -1]) asOop: Unsigned

]

{ #category : #'AppleEvents prims' }
TestOSAPlugin >> primAEDescToString: aString [

	| rcvr size |
	rcvr := self	primitive: 	'primAEDescToString'
				parameters: #(String)
				receiver: #AEDesc.
	size := aString size.
	self cCode: 'BlockMove(*(rcvr->dataHandle), aString, size)'
		 inSmalltalk: [rcvr. size].
	^aString asOop: String


]

{ #category : #'AppleEvents prims' }
TestOSAPlugin >> primAEDisposeDesc [
	
	|rcvr|
	rcvr :=	self	primitive: 	'primAEDisposeDesc'
				parameters:	#()
				receiver: 	#AEDesc.
	^(self 
		cCode: 'AEDisposeDesc(rcvr)'
		inSmalltalk: [[rcvr]. -1]) asOop: Unsigned
]

{ #category : #'AppleEvents prims' }
TestOSAPlugin >> primAEGetKeyPtr: key type: type actual: ignoreDesc to: bytes [

	| rcvr size ignoreSize |
	<var: #ignoreSize type: 'Size '>
	rcvr := self	primitive: 	'primAEGetKeyPtr'
				parameters: #(DescType DescType DescType ByteArray)
				receiver: #AEDesc.
	size := ignoreSize := bytes size.
	^(self cCode: 'AEGetKeyPtr(rcvr, *key, *type, ignoreDesc, bytes, size, &ignoreSize)'
		 inSmalltalk: [[rcvr. size. ignoreSize]. -1]) asOop: Unsigned
]

{ #category : #'Gen\'l Mac OS prims' }
TestOSAPlugin >> primGetHandleSize: anIndex [

	|rcvr|
	rcvr := self	primitive: 'primGetHandleSize'
				parameters: #(SmallInteger)
				receiver:	#WordArray.
	^(self
		cCode: 'GetHandleSize((Handle) *(rcvr+anIndex))'
		inSmalltalk: [[rcvr]. -1]) asOop: Unsigned
]

{ #category : #'OSA prims' }
TestOSAPlugin >> primOSACompile: source mode: mode to: object [

	|component|
	component := self primitive: 	'primOSACompile'
					parameters: #(AEDesc SmallInteger OSAID)
					receiver:	#ComponentInstance.

	^(self cCode: 'OSACompile(*component,source,mode,object)'
			inSmalltalk: [[component]. -1]) asOop: Unsigned
]

{ #category : #'OSA prims' }
TestOSAPlugin >> primOSADisplay: source as: type mode: mode to: result [

	|component|
	component := self primitive: 	'primOSADisplay'
					parameters: #(OSAID DescType SmallInteger AEDesc)
					receiver:	#ComponentInstance.

	^(self cCode: 'OSADisplay(*component,*source,*type,mode,result)'
			inSmalltalk: [[component]. -1]) asOop: Unsigned
]

{ #category : #'OSA prims' }
TestOSAPlugin >> primOSADispose: anOSAID [

	|component|
	component := self primitive: 	'primOSADispose'
					parameters: #(OSAID)
					receiver:	#ComponentInstance.

	^(self cCode: 'OSADispose(*component,*anOSAID)'
			inSmalltalk: [[component]. -1]) asOop: Unsigned
]

{ #category : #'OSA prims' }
TestOSAPlugin >> primOSADoScript: source in: context mode: mode resultType: type to: result [

	|component resultsOfCall giLocker |
	component := self primitive: 	'primOSADoScript'
					parameters: #(AEDesc OSAID SmallInteger DescType AEDesc)
					receiver:	#ComponentInstance.

	self cCode: '
        giLocker = interpreterProxy->ioLoadFunctionFrom("getUIToLock", "");
        if (giLocker != 0) {
            long *foo;
            foo = malloc(sizeof(long)*9);
            foo[0] = 6;
            foo[1] = OSADoScript;
            foo[2] = *component;
            foo[3] = source;
            foo[4] = *context;
            foo[5] = *type;
            foo[6] = mode;
            foo[7] = result;
            foo[8] = 0;
            ((int (*) (void *)) giLocker)(foo);
            resultsOfCall = interpreterProxy->positive32BitIntegerFor(foo[8]);
            free(foo);}'
			inSmalltalk: [[component. giLocker].  resultsOfCall := -1].
	^resultsOfCall asOop: Unsigned
]

{ #category : #'OSA prims' }
TestOSAPlugin >> primOSAExecute: script in: context mode: mode to: result [

	|component giLocker resultsOfCall |
	component := self primitive: 	'primOSAExecute'
					parameters: #(OSAID OSAID SmallInteger OSAID)
					receiver:	#ComponentInstance.

	self cCode: '
         giLocker = interpreterProxy->ioLoadFunctionFrom("getUIToLock", "");
         if (giLocker != 0) {
            long *foo;
            foo = malloc(sizeof(long)*8);
            foo[0] = 5;
            foo[1] = OSAExecute;
            foo[2] = *component;
            foo[3] = *script;
            foo[4] = *context;
            foo[5] = mode;
            foo[6] = result;
            foo[7] = 0;
            ((int (*) (void *)) giLocker)(foo);
            resultsOfCall = interpreterProxy->positive32BitIntegerFor(foo[7]);
            free(foo); }
'
			inSmalltalk: [[component. giLocker]. resultsOfCall := -1].
	^resultsOfCall asOop: Unsigned
]

{ #category : #'OSA prims' }
TestOSAPlugin >> primOSAGetScriptInfo: aScriptID type: aDescType to: resultData [

	|component|
	component := self	primitive: 	'primOSAGetScriptInfo'
						parameters: #(OSAID DescType IntegerArray)
						receiver:	#ComponentInstance.
	
	^(self cCode: 'OSAGetScriptInfo(*component,*aScriptID,*aDescType, (long *)resultData)'
			inSmalltalk: [[component]. -1]) asOop: Unsigned
]

{ #category : #'OSA prims' }
TestOSAPlugin >> primOSAGetSource: aScriptID type: aDescType to: resultData [

	|component|
	component := self	primitive: 	'primOSAGetSource'
						parameters: #(OSAID DescType AEDesc)
						receiver:	#ComponentInstance.
	
	^(self cCode: 'OSAGetSource(*component,*aScriptID,*aDescType, resultData)'
			inSmalltalk: [[component]. -1]) asOop: Unsigned
]

{ #category : #'OSA prims' }
TestOSAPlugin >> primOSALoad: source mode: mode to: result [

	|component|
	component := self primitive: 	'primOSALoad'
					parameters: #(AEDesc SmallInteger OSAID)
					receiver:	#ComponentInstance.

	^(self cCode: 'OSALoad(*component,source,mode,result)'
			inSmalltalk: [[component]. -1]) asOop: Unsigned
]

{ #category : #'OSA prims' }
TestOSAPlugin >> primOSAMakeContext: name parent: parent to: result [

	|component|
	component := self primitive: 	#primOSAMakeContext
					parameters: #(AEDesc OSAID OSAID)
					receiver:	#ComponentInstance.

	^(self cCode: 'OSAMakeContext(*component,name,*parent,result)'
			inSmalltalk: [[component]. -1]) asOop: Unsigned
]

{ #category : #'OSA prims' }
TestOSAPlugin >> primOSAScriptError: selector type: type to: result [

	|component|
	component := self primitive: 	'primOSAScriptError'
					parameters: #(DescType DescType AEDesc)
					receiver:	#ComponentInstance.

	^(self cCode: 'OSAScriptError(*component,*selector,*type,result)'
			inSmalltalk: [[component]. -1]) asOop: Unsigned
]

{ #category : #'OSA prims' }
TestOSAPlugin >> primOSAScriptingComponentNameTo: anAEDesc [

	|component|
	component := self	primitive: 	'primOSAScriptingComponentName'
						parameters: #(AEDesc)
						receiver:	#ComponentInstance.
	
	^(self cCode: 'OSAScriptingComponentName(*component,anAEDesc)'
			inSmalltalk: [[component]. -1]) asOop: Unsigned
]

{ #category : #'OSA prims' }
TestOSAPlugin >> primOSAStore: source resultType: type mode: mode to: result [

	|component|
	component := self primitive: 	#primOSAStore
					parameters: #(OSAID DescType SmallInteger AEDesc)
					receiver:	#ComponentInstance.

	^(self cCode: 'OSAStore(*component,*source,*type,mode,result)'
			inSmalltalk: [[component]. -1]) asOop: Unsigned
]

{ #category : #'Component Mgr prims' }
TestOSAPlugin >> primOpenDefaultConfiguration: type subtype: subtype [

	| component |
	component := self	primitive: 	'primOpenDefaultConfiguration'
						parameters: #(DescType DescType)
						receiver:	#ComponentInstance.
	self	cCode: '*component = OpenDefaultComponent(*type,*subtype)'
		inSmalltalk: [component at: 0 put: 0].
	^component asOop: ComponentInstance
]
