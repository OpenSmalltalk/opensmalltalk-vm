"
*  Created by John M McIntosh on 9/17/08.

 Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 Copyright (c) 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
 MIT License
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the ""Software""), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

The end-user documentation included with the redistribution, if any, must include the following acknowledgment: 
""This product includes software developed by Corporate Smalltalk Consulting Ltd (http://www.smalltalkconsulting.com) 
and its contributors"", in the same place and form as other third-party acknowledgments. 
Alternately, this acknowledgment may appear in the software itself, in the same form and location as other 
such third-party acknowledgments.

"
Class {
	#name : #ObjectiveCPlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #'initialize-release' }
ObjectiveCPlugin >> initialiseModule [
	"Initialise the module"
	
	^ true

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveCallbackLeave: aNumber [

	self primitive: 'primitiveCallbackLeave'
		parameters: #(SmallInteger).
	aNumber = 0 ifTrue: [^self].
	interpreterProxy callbackLeave: aNumber.
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveGetAddressFromEntryPointString: aEntryPointName [
	| entryPointNameLength fn entryPointName  |
	self primitive: 'primitiveGetAddressFromEntryPointString'
		parameters: #(String).

	self var: 'entryPointName' declareC: 'char entryPointName[256]'.
	self var: 'fn' declareC: 'void * fn'.
	entryPointNameLength := interpreterProxy slotSizeOf: aEntryPointName cPtrAsOop.
	entryPointNameLength > 255 ifTrue: [^interpreterProxy positive64BitIntegerFor: 0].
	self str: entryPointName l: aEntryPointName cpy: entryPointNameLength+1.
	fn  := self dl: -2 sym: entryPointName.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: fn to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveGetAutoReleasePool [
	|  pool |
	self primitive: 'primitiveGetAutoReleasePool'.
	self var: 'pool' declareC: 'NSAutoreleasePool * pool'.
	pool := nil.
	self cCode: '    NS_DURING'. 
	self cCode:  'pool = [NSAutoreleasePool new]'.
	self cCode: '    NS_HANDLER 
		pool = nil;'.
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: pool to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveGetClass: aClassOrInstanceOop [
	|  classOrInstanceObject classObject |
	self primitive: 'primitiveGetClass'
		parameters: #(Oop).
	self var: 'classOrInstanceObject' declareC: 'id classOrInstanceObject'.
	self var: 'classObject' declareC: 'Class classObject'.

	classOrInstanceObject := self cCoerce: (interpreterProxy positive64BitValueOf: aClassOrInstanceOop) to: 'id'.
	classObject := nil.
	interpreterProxy failed ifTrue: [^nil].
	self touch: classOrInstanceObject.
	self touch: classObject.
	self cCode: '    NS_DURING'. 
	self cCode:  'classObject = [classOrInstanceObject class]'.
	self cCode: '    NS_HANDLER 
		classObject = nil;'.
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: classObject to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveGetDescription: aClassOrInstanceOop [
	|  classOrInstanceObject utf8String utf8StringOop nsStringObject |
	self primitive: 'primitiveGetDescription'
		parameters: #(Oop).
	self var: 'classOrInstanceObject' declareC: 'id classOrInstanceObject'.
	self var: 'nsStringObject' declareC: 'NSString* nsStringObject'.
	self var: 'utf8String' declareC: 'const char * utf8String'.

	classOrInstanceObject := self cCoerce: (interpreterProxy positive64BitValueOf: aClassOrInstanceOop) to: 'id'.
	utf8String := nil.
	interpreterProxy failed ifTrue: [^nil].
	self touch: nsStringObject.
	self cCode: '    NS_DURING'. 
	self cCode:  'nsStringObject = [classOrInstanceObject description];
				utf8String = [nsStringObject UTF8String]'.
	self cCode: '    NS_HANDLER 
		utf8String = nil;'.
	self cCode: '    NS_ENDHANDLER'.
	utf8String
		ifFalse: [interpreterProxy success: false.
		^nil].
	utf8StringOop := self stringFromCString: utf8String.
	^utf8StringOop

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveGetMethodSignatureForSelector: aSelectorOop on: aClassOrInstanceOop [
	|  selectorObject classOrInstanceObject messageSignatureObject |
	self primitive: 'primitiveGetMethodSignatureForSelector'
		parameters: #(Oop Oop).
	self var: 'selectorObject' declareC: 'SEL selectorObject'.
	self var: 'classOrInstanceObject' declareC: 'id classOrInstanceObject'.
	self var: 'messageSignatureObject' declareC: 'NSMethodSignature * messageSignatureObject'.

	selectorObject := self cCoerce: (interpreterProxy positive64BitValueOf: aSelectorOop) to: 'SEL'.
	classOrInstanceObject := self cCoerce: (interpreterProxy positive64BitValueOf: aClassOrInstanceOop) to: 'id'.
	messageSignatureObject := nil.
	interpreterProxy failed ifTrue: [^nil].
	self touch: classOrInstanceObject.
	self touch: selectorObject.
	self cCode: '    NS_DURING'. 
	self cCode:  'messageSignatureObject = [classOrInstanceObject methodSignatureForSelector: selectorObject]'.
	self cCode: '    NS_HANDLER 
	messageSignatureObject = nil;'.
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: messageSignatureObject to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveGetNSStringForString: aStringOop encoding: anEncoding [
	| stringLength aStringAsNSString encoding aString |
	self primitive: 'primitiveGetNSStringForString'
		parameters: #(Oop Oop).
	self var: 'aStringAsNSString' declareC: 'NSString* aStringAsNSString'.
	self var: 'encoding' declareC: 'NSUInteger encoding'. 
	self var: 'aString' declareC: 'char* aString'. 
	encoding := self cCoerce: (interpreterProxy positive64BitValueOf: anEncoding) to: 'NSUInteger'.
	aString := interpreterProxy firstIndexableField: aStringOop.
	stringLength := interpreterProxy byteSizeOf: aStringOop.
	self touch: stringLength.
	aStringAsNSString := 0.
	self cCode: '    NS_DURING'. 
		aStringAsNSString := self cCode: '[[NSString alloc] initWithBytes: aString length: stringLength encoding: encoding]'.
	self cCode: '    NS_HANDLER 
				aStringAsNSString = nil;'.
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: aStringAsNSString to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveGetObjCClassForString: aClassName [
	| classNameLength classNameNSString classObject |
	self primitive: 'primitiveGetObjCClassForString'
		parameters: #(Symbol).
	self var: 'classObject' declareC: 'Class classObject'.
	self var: 'classNameNSString' declareC: 'NSString* classNameNSString'.

	classNameLength := interpreterProxy slotSizeOf: aClassName cPtrAsOop.
	self touch: classNameLength.
	classNameNSString := self cCode: '[[NSString alloc] initWithBytes: aClassName length: classNameLength encoding: NSUTF8StringEncoding]'.
	self cCode: '    NS_DURING'. 
	classObject := classNameNSString NSClassFromString.
	self cCode: '    NS_HANDLER 
	classObject = nil;'.
	self cCode: '    NS_ENDHANDLER'.
	self cCode: '[classNameNSString release]'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: classObject to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveGetSelectorFromString: aSelectorName [
	| selectorLength selectorNSString selectorObject |
	self primitive: 'primitiveGetSelectorForString'
		parameters: #(Symbol).
	self var: 'selectorObject' declareC: 'SEL selectorObject'.
	self var: 'selectorNSString' declareC: 'NSString * selectorNSString'.

	selectorLength := interpreterProxy slotSizeOf: aSelectorName cPtrAsOop.
	self touch: selectorLength.
	selectorNSString := self cCode: '[[NSString alloc] initWithBytes: aSelectorName length: selectorLength encoding: NSUTF8StringEncoding]'.
	self cCode: '    NS_DURING'. 
	selectorObject := selectorNSString NSSelectorFromString.
	self cCode: '    NS_HANDLER 
	selectorObject = nil;'.
	self cCode: '    NS_ENDHANDLER'.
	self cCode: '[selectorNSString release]'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: selectorObject to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveGetSuperClass: aClassOrInstanceOop [
	|  classOrInstanceObject classObject |
	self primitive: 'primitiveGetSuperClass'
		parameters: #(Oop).
	self var: 'classOrInstanceObject' declareC: 'id classOrInstanceObject'.
	self var: 'classObject' declareC: 'Class classObject'.

	classOrInstanceObject := self cCoerce: (interpreterProxy positive64BitValueOf: aClassOrInstanceOop) to: 'id'.
	classObject := nil.
	interpreterProxy failed ifTrue: [^nil].
	self touch: classOrInstanceObject.
	self touch: classObject.
	self cCode: '    NS_DURING'. 
	self cCode:  'classObject = [classOrInstanceObject superclass]'.
	self cCode: '    NS_HANDLER 
		classObject = nil;'.
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: classObject to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveIsEqual: anOop1 to: anOop2 [
	|  oop1 oop2 result |
	self primitive: 'primitiveIsEqual'
		parameters: #(Oop Oop).
	self var: 'oop1' declareC: 'id oop1'.
	self var: 'oop2' declareC: 'id oop2'.
	self var: 'result' declareC: 'BOOL result'.

	oop1 := self cCoerce: (interpreterProxy positive64BitValueOf: anOop1) to: 'id'.
	oop2 := self cCoerce: (interpreterProxy positive64BitValueOf: anOop2) to: 'id'.
	interpreterProxy failed ifTrue: [^nil].
	self touch: oop1.
	self touch: oop2.
	result := 0.
	self cCode: '    NS_DURING'. 
	self cCode:  'result = [oop1 isEqual: oop2]'.
	self cCode: '    NS_HANDLER'.
	interpreterProxy success: false.
	true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	^(result = 1) asBooleanObj

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveMethodSignatureGetArgumentType: aMethodSignatureOop atIndex: aIndexNumber [
	|  nsMethodSignatureObject string stringOop |
	self primitive: 'primitiveMethodSignatureGetArgumentType'
		parameters: #(Oop SmallInteger).
	self var: 'nsMethodSignatureObject' declareC: 'NSMethodSignature* nsMethodSignatureObject'.
	self var: 'string' declareC: 'const char * string'.

	nsMethodSignatureObject := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSMethodSignature *'.
	string := nil.
	interpreterProxy failed ifTrue: [^nil].
	self touch: nsMethodSignatureObject.
	self cCode: '    NS_DURING'. 
	self cCode:  'string = [nsMethodSignatureObject getArgumentTypeAtIndex: aIndexNumber]'.
	self cCode: '    NS_HANDLER 
		string = nil;'.
	self cCode: '    NS_ENDHANDLER'.
	string
		ifFalse: [interpreterProxy success: false.
		^nil].
	stringOop := self stringFromCString: string.
	^stringOop

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveMethodSignatureGetMethodReturnLength: aMethodSignatureOop [
	|  nsMethodSignatureObject methodReturnLength |
	self primitive: 'primitiveMethodSignatureGetMethodReturnLength'
		parameters: #(Oop).
	self var: 'nsMethodSignatureObject' declareC: 'NSMethodSignature* nsMethodSignatureObject'.
	self var: 'methodReturnLength' declareC: 'NSUInteger methodReturnLength'.

	nsMethodSignatureObject := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSMethodSignature *'.
	methodReturnLength := 0.
	interpreterProxy failed ifTrue: [^nil].
	self touch: nsMethodSignatureObject.
	self cCode: '    NS_DURING'. 
	self cCode: 'methodReturnLength = [nsMethodSignatureObject methodReturnLength]'.
	self cCode: '    NS_HANDLER 
		methodReturnLength = 0xFFFFFFFF'.
	self cCode: '    NS_ENDHANDLER'.
	methodReturnLength = 16rFFFFFFFF
		ifTrue: [interpreterProxy success: false.
		^nil].
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: methodReturnLength to: 'usqInt') 

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveMethodSignatureGetNumberOfArguments: aMethodSignatureOop [
	|  nsMethodSignatureObject numberOfArguments |
	self primitive: 'primitiveMethodSignatureGetNumberOfArguments'
		parameters: #(Oop).
	self var: 'nsMethodSignatureObject' declareC: 'NSMethodSignature* nsMethodSignatureObject'.
	self var: 'numberOfArguments' declareC: 'NSUInteger numberOfArguments'.

	nsMethodSignatureObject := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSMethodSignature *'.
	numberOfArguments := 9999999.
	interpreterProxy failed ifTrue: [^nil].
	self touch: nsMethodSignatureObject.
	self cCode: '    NS_DURING'. 
	self cCode: 'numberOfArguments = [nsMethodSignatureObject numberOfArguments]'.
	self cCode: '    NS_HANDLER 
		numberOfArguments = 9999999'.
	self cCode: '    NS_ENDHANDLER'.
	numberOfArguments = 9999999
		ifTrue: [interpreterProxy success: false.
		^nil].
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: numberOfArguments to: 'usqInt') 

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveMethodSignatureGetReturnType: aMethodSignatureOop [
	|  nsMethodSignatureObject string stringOop |
	self primitive: 'primitiveMethodSignatureGetReturnType'
		parameters: #(Oop).
	self var: 'nsMethodSignatureObject' declareC: 'NSMethodSignature* nsMethodSignatureObject'.
	self var: 'string' declareC: 'const char * string'.

	nsMethodSignatureObject := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSMethodSignature *'.
	string := nil.
	interpreterProxy failed ifTrue: [^nil].
	self touch: nsMethodSignatureObject.
	self cCode: '    NS_DURING'. 
	self cCode:  'string = [nsMethodSignatureObject methodReturnType]'.
	self cCode: '    NS_HANDLER 
		string = nil;'.
	self cCode: '    NS_ENDHANDLER'.
	string
		ifFalse: [interpreterProxy success: false.
		^nil].
	stringOop := self stringFromCString: string.
	^stringOop

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationCalloc: size [
	|  pointer |
	self primitive: 'primitiveNSInvocationCalloc'
		parameters: #(SmallInteger).
	self var: 'pointer' declareC: 'void* pointer'.
	self cCode: 'pointer = calloc(size,1)'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: pointer to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationFree: pointer [
	|  pointerToFree |
	self primitive: 'primitiveNSInvocationFree'
		parameters: #(Oop).
	self var: 'pointerToFree' declareC: 'void* pointerToFree'.

	pointerToFree := self cCoerce: (interpreterProxy positive64BitValueOf: pointer) to: 'void *'.
	interpreterProxy failed ifTrue: [^nil].
	self cCode: 'free((void*)pointerToFree)'.
	self touch: pointer.
	^self
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationGetArgument: aMethodSignatureOop buffer: bufferOop atIndex: index [
	|  nsInvocationInstance buffer |
	self primitive: 'primitiveNSInvocationGetArgument'
		parameters: #(Oop Oop SmallInteger).
	self var: 'nsInvocationInstance' declareC: 'NSInvocation* nsInvocationInstance'.
	self var: 'buffer' declareC: 'void * buffer'.

	nsInvocationInstance := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSInvocation *'.
	buffer := self cCoerce: (interpreterProxy positive64BitValueOf: bufferOop) to: 'void *'.
	interpreterProxy failed ifTrue: [^nil].
	self touch: nsInvocationInstance.
	self touch: buffer.
	self cCode: '    NS_DURING'. 
	self cCode:  '[nsInvocationInstance getArgument: buffer atIndex: index]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	^self
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationGetCType: bufferAddressOop signed: signedBoolean [
	|  buffer newCharacterOop targetOopData |
	self primitive: 'primitiveNSInvocationGetCType'
		parameters: #(Oop Boolean).
	self var: 'buffer' declareC: 'char * buffer'.
	self var: 'targetOopData' declareC: 'char targetOopData'.

	buffer := self cCoerce: (interpreterProxy positive64BitValueOf: bufferAddressOop) to: 'char *'.
	interpreterProxy failed ifTrue: [^nil].
	self touch: buffer.
	newCharacterOop := interpreterProxy
		instantiateClass: interpreterProxy classCharacter
		indexableSize: 1.
	targetOopData := 0.
	self touch: targetOopData.
	signedBoolean 
			ifTrue: [self cCode: 'targetOopData = *(char*) buffer'. 
					interpreterProxy storeInteger: 0 ofObject: newCharacterOop withValue: 
					 (self cCoerce: targetOopData to: 'sqInt').]
			ifFalse: [self cCode: 'targetOopData = *(char*) buffer'.
					interpreterProxy storeInteger: 0 ofObject: newCharacterOop withValue: 
					 (self cCoerce: targetOopData to: 'usqInt').].
	
	^newCharacterOop
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationGetCharPointerType: bufferAddressOop [
	|  buffer stringOop bufferPointer |
	self primitive: 'primitiveNSInvocationGetCharPointerType'
		parameters: #(Oop).
	self var: 'bufferPointer' declareC: 'char ** bufferPointer'.
	self var: 'buffer' declareC: 'char * buffer'.

	bufferPointer := self cCoerce: (interpreterProxy positive64BitValueOf: bufferAddressOop) to: 'char **'.
	interpreterProxy failed ifTrue: [^nil].
	self cCode: 'buffer = *bufferPointer'.
	stringOop := self stringFromCString: buffer.
	^stringOop

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationGetClassType: bufferAddressOop [
	|  buffer data |
	self primitive: 'primitiveNSInvocationGetClassType'
		parameters: #(Oop).
	self var: 'buffer' declareC: 'Class * buffer'.
	self var: 'data' declareC: 'Class data'.

	buffer := self cCoerce: (interpreterProxy positive64BitValueOf: bufferAddressOop) to: 'Class *'.
	interpreterProxy failed ifTrue: [^nil].
	self touch: buffer.
	self cCode: 'data = *buffer'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: data to: 'usqInt') 

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationGetDoubleType: bufferAddressOop [
	|  buffer data |
	self primitive: 'primitiveNSInvocationGetDoubleType'
		parameters: #(Oop).
	self var: 'buffer' declareC: 'double * buffer'.
	self var: 'data' declareC: 'double data'.

	buffer := self cCoerce: (interpreterProxy positive64BitValueOf: bufferAddressOop) to: 'double *'.
	interpreterProxy failed ifTrue: [^nil].
	self touch: buffer.
	self cCode: 'data = *buffer'.
	^interpreterProxy floatObjectOf: data
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationGetFloatType: bufferAddressOop [
	|  buffer data |
	self primitive: 'primitiveNSInvocationGetFloatType'
		parameters: #(Oop).
	self var: 'buffer' declareC: 'float * buffer'.
	self var: 'data' declareC: 'float data'.

	buffer := self cCoerce: (interpreterProxy positive64BitValueOf: bufferAddressOop) to: 'float *'.
	interpreterProxy failed ifTrue: [^nil].
	self touch: buffer.
	self cCode: 'data = *buffer'.
	^interpreterProxy floatObjectOf: data
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationGetIntType: bufferAddressOop signed: signedBoolean [
	|  buffer data unsignedData |
	self primitive: 'primitiveNSInvocationGetIntType'
		parameters: #(Oop Boolean).
	self var: 'buffer' declareC: 'int * buffer'.
	self var: 'data' declareC: 'int data'.
	self var: 'unsignedData' declareC: 'unsigned int unsignedData'.

	buffer := self cCoerce: (interpreterProxy positive64BitValueOf: bufferAddressOop) to: 'int *'.
	interpreterProxy failed ifTrue: [^nil].
	self touch: buffer.
	unsignedData := data := 0.
	signedBoolean 
			ifTrue: [self cCode: 'data = *buffer'.
					^interpreterProxy signed32BitIntegerFor: (self cCoerce: data to: 'sqInt') ]
			ifFalse: [self cCode: 'unsignedData = *(unsigned int *)buffer'.
					^interpreterProxy positive32BitIntegerFor: (self cCoerce: unsignedData to: 'usqInt') ].

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationGetLongLongType: bufferAddressOop signed: signedBoolean [
	|  buffer data unsignedData |
	self primitive: 'primitiveNSInvocationGetLongLongType'
		parameters: #(Oop Boolean).
	self var: 'buffer' declareC: 'long long * buffer'.
	self var: 'data' declareC: 'long long data'.
	self var: 'unsignedData' declareC: 'unsigned long long unsignedData'.

	buffer := self cCoerce: (interpreterProxy positive64BitValueOf: bufferAddressOop) to: 'long long *'.
	interpreterProxy failed ifTrue: [^nil].
	self touch: buffer.
	unsignedData := data := 0.
	signedBoolean 
			ifTrue: [self cCode: 'data = *buffer'.
					^interpreterProxy signed64BitIntegerFor: (self cCoerce: data to: 'long long') ]
			ifFalse: [self cCode: 'unsignedData = * (unsigned long long*) buffer'.
					^interpreterProxy positive64BitIntegerFor: (self cCoerce: unsignedData to: 'unsigned long long') ].

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationGetLongType: bufferAddressOop signed: signedBoolean [
	|  buffer data unsignedData |
	self primitive: 'primitiveNSInvocationGetLongType'
		parameters: #(Oop Boolean).
	self var: 'buffer' declareC: 'long * buffer'.
	self var: 'data' declareC: 'long data'.
	self var: 'unsignedData' declareC: 'unsigned long unsignedData'.

	buffer := self cCoerce: (interpreterProxy positive64BitValueOf: bufferAddressOop) to: 'long *'.
	interpreterProxy failed ifTrue: [^nil].
	self touch: buffer.
	unsignedData := data := 0.
	signedBoolean 
			ifTrue: [self cCode: 'data = *buffer'.
					^interpreterProxy signed64BitIntegerFor: (self cCoerce: data to: 'sqInt') ]
			ifFalse: [self cCode: 'unsignedData = *(unsigned long *) buffer'.
					^interpreterProxy positive64BitIntegerFor: (self cCoerce: unsignedData to: 'usqInt') ].

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationGetObjectType: bufferAddressOop [
	|  buffer data |
	self primitive: 'primitiveNSInvocationGetObjectType'
		parameters: #(Oop).
	self var: 'buffer' declareC: 'id * buffer'.
	self var: 'data' declareC: 'id data'.

	buffer := self cCoerce: (interpreterProxy positive64BitValueOf: bufferAddressOop) to: 'id *'.
	interpreterProxy failed ifTrue: [^nil].
	self touch: buffer.
	self cCode: 'data = *buffer'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: data to: 'usqInt') 

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationGetReturnValue: bufferAddressOop on: aNSinvokeOops [
	|  buffer nsInvoke |
	self primitive: 'primitiveNSInvocationGetReturnValue'
		parameters: #(Oop Oop).
	self var: 'buffer' declareC: 'void * buffer'.
	self var: 'nsInvoke' declareC: 'NSInvocation *nsInvoke'.

	buffer := self cCoerce: (interpreterProxy positive64BitValueOf: bufferAddressOop) to: 'void *'.
	nsInvoke := self cCoerce: (interpreterProxy positive64BitValueOf: aNSinvokeOops) to: 'NSInvocation *'.
	interpreterProxy failed ifTrue: [^nil].
	self touch: buffer.
	self cCode: '    NS_DURING'. 
	self cCode:  '[nsInvoke getReturnValue: buffer]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	^self
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationGetSelectorType: bufferAddressOop [
	|  buffer data |
	self primitive: 'primitiveNSInvocationGetSelectorType'
		parameters: #(Oop).
	self var: 'buffer' declareC: 'SEL * buffer'.
	self var: 'data' declareC: 'SEL data'.

	buffer := self cCoerce: (interpreterProxy positive64BitValueOf: bufferAddressOop) to: 'SEL *'.
	interpreterProxy failed ifTrue: [^nil].
	self touch: buffer.
	self cCode: 'data = *buffer'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: data to: 'usqInt') 

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationGetShortType: bufferAddressOop signed: signedBoolean [
	|  buffer data unsignedData |
	self primitive: 'primitiveNSInvocationGetShortType'
		parameters: #(Oop Boolean).
	self var: 'buffer' declareC: 'short * buffer'.
	self var: 'data' declareC: 'short data'.
	self var: 'unsignedData' declareC: 'unsigned short unsignedData'.

	buffer := self cCoerce: (interpreterProxy positive64BitValueOf: bufferAddressOop) to: 'short *'.
	unsignedData := data := 0.
	interpreterProxy failed ifTrue: [^nil].
	self touch: buffer.
	signedBoolean 
			ifTrue: [self cCode: 'data = *buffer'.
					^interpreterProxy signed32BitIntegerFor: (self cCoerce: data to: 'sqInt') ]
			ifFalse: [self cCode: 'unsignedData = *(unsigned short *)buffer'.
					^interpreterProxy positive32BitIntegerFor: (self cCoerce: unsignedData to: 'usqInt') ].

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationGetStructureType: bufferAddressOop length: length [
	|  bufferPointer newByteArray |
	self primitive: 'primitiveNSInvocationGetStructureType'
		parameters: #(Oop SmallInteger).
	self var: 'bufferPointer' declareC: 'char ** bufferPointer'.
	self var: 'buffer' declareC: 'char * buffer'.

	bufferPointer := self cCoerce: (interpreterProxy positive64BitValueOf: bufferAddressOop) to: 'void *'.
	interpreterProxy failed ifTrue: [^nil].
	newByteArray := interpreterProxy
		instantiateClass: interpreterProxy classByteArray
		indexableSize: length.
	self me: (interpreterProxy arrayValueOf: newByteArray)
		m: bufferPointer
		cpy: length. "void * memcpy(void *restrict s1, const void *restrict s2, size_t n)"
	^newByteArray

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationMalloc: size [
	|  pointer |
	self primitive: 'primitiveNSInvocationMalloc'
		parameters: #(SmallInteger).
	self var: 'pointer' declareC: 'void* pointer'.
	self cCode: 'pointer = malloc(size)'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: pointer to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationSetCType: aMethodSignatureOop signed: signedBoolean index: index value: newCharacterOop [
	|  nsInvocationInstance buffer aValue aUnsignedValue |
	self primitive: 'primitiveNSInvocationSetCType'
		parameters: #(Oop Boolean SmallInteger Oop).
	self var: 'nsInvocationInstance' declareC: 'NSInvocation* nsInvocationInstance'.
	self var: 'buffer' declareC: 'void * buffer'.
	self var: 'aValue' declareC: 'char aValue'.
	self var: 'aUnsignedValue' declareC: 'unsigned char aUnsignedValue'.

	nsInvocationInstance := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSInvocation *'.
	interpreterProxy failed ifTrue: [^nil].
	aValue := interpreterProxy fetchInteger: 0 ofObject: newCharacterOop.
	aUnsignedValue := interpreterProxy fetchInteger: 0 ofObject: newCharacterOop.
	signedBoolean 
			ifTrue: [self cCode: 'buffer = malloc(sizeof(char));
					*(char*) buffer = (char) aValue']
			ifFalse: [self cCode: 'buffer = malloc(sizeof(unsigned char));
					*(unsigned char*)buffer = (unsigned char) aUnsignedValue'].
	self touch: nsInvocationInstance.
	self touch: buffer.
	self cCode: '    NS_DURING'. 
	self cCode:  '[nsInvocationInstance setArgument: buffer atIndex: index]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: buffer to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationSetDoubleType: aMethodSignatureOop  index: index value: aValue [
	|  nsInvocationInstance buffer |
	self primitive: 'primitiveNSInvocationSetDoubleType'
		parameters: #(Oop SmallInteger Float).
	self var: 'nsInvocationInstance' declareC: 'NSInvocation* nsInvocationInstance'.
	self var: 'aValue' declareC: 'double aValue'.
	self var: 'buffer' declareC: 'void * buffer'.

	nsInvocationInstance := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSInvocation *'.
	interpreterProxy failed ifTrue: [^nil].
	self cCode: 'buffer = malloc(sizeof(double));
				*(double*) buffer = (double) aValue'.
	self touch: nsInvocationInstance.
	self touch: buffer.
	self cCode: '    NS_DURING'. 
	self cCode:  '[nsInvocationInstance setArgument: buffer atIndex: index]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: buffer to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationSetFloatType: aMethodSignatureOop  index: index value: aValue [
	|  nsInvocationInstance buffer |
	self primitive: 'primitiveNSInvocationSetFloatType'
		parameters: #(Oop SmallInteger Float).
	self var: 'nsInvocationInstance' declareC: 'NSInvocation* nsInvocationInstance'.
	self var: 'aValue' declareC: 'float aValue'.
	self var: 'buffer' declareC: 'void * buffer'.

	nsInvocationInstance := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSInvocation *'.
	interpreterProxy failed ifTrue: [^nil].
	self cCode: 'buffer = malloc(sizeof(float));
				*(float*) buffer = (float) aValue'.
	self touch: nsInvocationInstance.
	self touch: buffer.
	self cCode: '    NS_DURING'. 
	self cCode:  '[nsInvocationInstance setArgument: buffer atIndex: index]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: buffer to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationSetIntType: aMethodSignatureOop signed: signedBoolean index: index value: intValue [
	|  nsInvocationInstance buffer aValue |
	self primitive: 'primitiveNSInvocationSetIntType'
		parameters: #(Oop Boolean SmallInteger Oop).
	self var: 'nsInvocationInstance' declareC: 'NSInvocation* nsInvocationInstance'.
	self var: 'aValue' declareC: 'int aValue'.
	self var: 'buffer' declareC: 'void * buffer'.

	nsInvocationInstance := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSInvocation *'.
	interpreterProxy failed ifTrue: [^nil].
	signedBoolean 
			ifTrue: [aValue := self cCoerce: (interpreterProxy signed64BitValueOf: intValue) to: 'int'.
					interpreterProxy failed ifTrue: [^nil].
				self cCode: 'buffer = malloc(sizeof(int));
						*(int*) buffer = (int) aValue']
			ifFalse: [aValue := self cCoerce: (interpreterProxy positive64BitValueOf: intValue) to: 'unsigned int'.
					interpreterProxy failed ifTrue: [^nil].
				self cCode: 'buffer = malloc(sizeof(unsigned int));
					*(unsigned int*)buffer = (unsigned int) aValue'].
	self touch: nsInvocationInstance.
	self touch: buffer.
	self cCode: '    NS_DURING'. 
	self cCode:  '[nsInvocationInstance setArgument: buffer atIndex: index]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: buffer to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationSetLongLongType: aMethodSignatureOop signed: signedBoolean index: index value: intValue [
	|  nsInvocationInstance buffer aValue |
	self primitive: 'primitiveNSInvocationSetLongLongType'
		parameters: #(Oop Boolean SmallInteger Oop).
	self var: 'nsInvocationInstance' declareC: 'NSInvocation* nsInvocationInstance'.
	self var: 'aValue' declareC: 'long long aValue'.
	self var: 'buffer' declareC: 'void * buffer'.

	nsInvocationInstance := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSInvocation *'.
	interpreterProxy failed ifTrue: [^nil].
	signedBoolean 
			ifTrue: [aValue := self cCoerce: (interpreterProxy signed64BitValueOf: intValue) to: 'long long'.
				interpreterProxy failed ifTrue: [^nil].
					self cCode: 'buffer = malloc(sizeof(long long));
						*(long long*) buffer = (long long) aValue']
			ifFalse: [aValue := self cCoerce: (interpreterProxy positive64BitValueOf: intValue) to: 'unsigned long long'.
					interpreterProxy failed ifTrue: [^nil].
					self cCode: 'buffer = malloc(sizeof(unsigned long long));
					*(unsigned long long*)buffer = (unsigned long long) aValue'].
	self touch: nsInvocationInstance.
	self touch: buffer.
	self cCode: '    NS_DURING'. 
	self cCode:  '[nsInvocationInstance setArgument: buffer atIndex: index]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: buffer to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationSetLongType: aMethodSignatureOop signed: signedBoolean index: index value: intValue [
	|  nsInvocationInstance buffer aValue |
	self primitive: 'primitiveNSInvocationSetLongType'
		parameters: #(Oop Boolean SmallInteger Oop).
	self var: 'nsInvocationInstance' declareC: 'NSInvocation* nsInvocationInstance'.
	self var: 'aValue' declareC: 'long aValue'.
	self var: 'buffer' declareC: 'void * buffer'.

	nsInvocationInstance := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSInvocation *'.
	interpreterProxy failed ifTrue: [^nil].
	signedBoolean 
			ifTrue: [aValue := self cCoerce: (interpreterProxy signed64BitValueOf: intValue) to: 'long'.
					interpreterProxy failed ifTrue: [^nil].
					self cCode: 'buffer = malloc(sizeof(long));
						*(long*) buffer = (long) aValue']
			ifFalse: [aValue := self cCoerce: (interpreterProxy positive64BitValueOf: intValue) to: 'unsigned long'.
					interpreterProxy failed ifTrue: [^nil].
					self cCode: 'buffer = malloc(sizeof(unsigned long));
					*(unsigned long*)buffer = (unsigned long) aValue'].
	self touch: nsInvocationInstance.
	self touch: buffer.
	self cCode: '    NS_DURING'. 
	self cCode:  '[nsInvocationInstance setArgument: buffer atIndex: index]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: buffer to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationSetPointerType: aMethodSignatureOop  index: index value: pointerValue [
	|  nsInvocationInstance buffer aValue |
	self primitive: 'primitiveNSInvocationSetPointerType'
		parameters: #(Oop SmallInteger Oop).
	self var: 'nsInvocationInstance' declareC: 'NSInvocation* nsInvocationInstance'.
	self var: 'aValue' declareC: 'void * aValue'.
	self var: 'buffer' declareC: 'void ** buffer'.

	nsInvocationInstance := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSInvocation *'.
	aValue := self cCoerce: (interpreterProxy positive64BitValueOf: pointerValue) to: 'char *'.
	interpreterProxy failed ifTrue: [^nil].
	self cCode: 'buffer = malloc(sizeof(void*));
		*buffer = aValue'.
	self touch: nsInvocationInstance.
	self touch: buffer.
	self cCode: '    NS_DURING'. 
	self cCode:  '[nsInvocationInstance setArgument: buffer atIndex: index]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: buffer to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationSetRetained: aMethodSignatureOop [
	|  nsInvocationInstance |
	self primitive: 'primitiveNSInvocationSetRetained'
		parameters: #(Oop).
	self var: 'nsInvocationInstance' declareC: 'NSInvocation* nsInvocationInstance'.

	nsInvocationInstance := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSInvocation *'.
	interpreterProxy failed ifTrue: [^nil].
	self cCode: '    NS_DURING'. 
	self cCode:  '[nsInvocationInstance retainArguments]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
	self cCode: '    NS_ENDHANDLER'.

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationSetSelector: aSelectorOop target: object1Oops on: aNSinvokeOops [
	|  selectorObject object1 nsInvoke |
	self primitive: 'primitiveNSInvocationSetSelector'
		parameters: #(Oop Oop Oop).

	self var: 'object1' declareC: 'id object1'.
	self var: 'selectorObject' declareC: 'SEL selectorObject'.
	self var: 'nsInvoke' declareC: 'NSInvocation *nsInvoke'.

	selectorObject := self cCoerce: (interpreterProxy positive64BitValueOf: aSelectorOop) to: 'SEL'.
	object1 := self cCoerce: (interpreterProxy positive64BitValueOf: object1Oops) to: 'id'.
	nsInvoke := self cCoerce: (interpreterProxy positive64BitValueOf: aNSinvokeOops) to: 'NSInvocation *'.
	interpreterProxy failed ifTrue: [^nil].
	self cCode: '    NS_DURING'. 
	self cCode:  '[nsInvoke setSelector: selectorObject]'.
	self cCode:  '[nsInvoke setTarget:  object1]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^self].
	self cCode: '    NS_ENDHANDLER'.
	^self
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationSetShortType: aMethodSignatureOop signed: signedBoolean index: index value: intValue [
	|  nsInvocationInstance buffer aValue |
	self primitive: 'primitiveNSInvocationSetShortType'
		parameters: #(Oop Boolean SmallInteger Oop).
	self var: 'nsInvocationInstance' declareC: 'NSInvocation* nsInvocationInstance'.
	self var: 'aValue' declareC: 'short aValue'.
	self var: 'buffer' declareC: 'void * buffer'.

	nsInvocationInstance := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSInvocation *'.
	interpreterProxy failed ifTrue: [^nil].
	signedBoolean 
			ifTrue: [aValue := self cCoerce: (interpreterProxy signed64BitValueOf: intValue) to: 'short'.
					interpreterProxy failed ifTrue: [^nil].
					self cCode: 'buffer = malloc(sizeof(short));
						*(short*) buffer = (short) aValue']
			ifFalse: [aValue := self cCoerce: (interpreterProxy positive64BitValueOf: intValue) to: 'unsigned short'.
					interpreterProxy failed ifTrue: [^nil].
					self cCode: 'buffer = malloc(sizeof(unsigned short));
					*(unsigned short*)buffer = (unsigned short) aValue'].
	self touch: nsInvocationInstance.
	self touch: buffer.
	self cCode: '    NS_DURING'. 
	self cCode:  '[nsInvocationInstance setArgument: buffer atIndex: index]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: buffer to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationSetStringType: aMethodSignatureOop  index: index value: aValue [
	|  nsInvocationInstance buffer stringSize |
	self primitive: 'primitiveNSInvocationSetStringType'
		parameters: #(Oop SmallInteger String).
	self var: 'nsInvocationInstance' declareC: 'NSInvocation* nsInvocationInstance'.
	self var: 'aValue' declareC: 'char * aValue'.
	self var: 'buffer' declareC: 'char * buffer'.

	nsInvocationInstance := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSInvocation *'.
	interpreterProxy failed ifTrue: [^nil].
	stringSize := interpreterProxy slotSizeOf: aValue cPtrAsOop.
	self cCode: 'buffer = malloc(stringSize + 1);
		memcpy(buffer,aValue,stringSize);
		buffer[stringSize] = 0x00'.
	self touch: nsInvocationInstance.
	self touch: buffer.
	self cCode: '    NS_DURING'. 
	self cCode:  '[nsInvocationInstance setArgument: &buffer atIndex: index]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: buffer to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationSetStructureType: aMethodSignatureOop  index: index value: aValue [
	|  nsInvocationInstance buffer byteArraySize |
	self primitive: 'primitiveNSInvocationSetStructureType'
		parameters: #(Oop SmallInteger ByteArray).
	self var: 'nsInvocationInstance' declareC: 'NSInvocation* nsInvocationInstance'.
	self var: 'buffer' declareC: 'void * buffer'.

	nsInvocationInstance := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSInvocation *'.
	interpreterProxy failed ifTrue: [^nil].
	byteArraySize := interpreterProxy slotSizeOf: aValue cPtrAsOop.
	self cCode: 'buffer = malloc(byteArraySize);
		memcpy(buffer,aValue,byteArraySize)'.
	self touch: nsInvocationInstance.
	self touch: buffer.
	self touch: byteArraySize.
	self cCode: '    NS_DURING'. 
	self cCode:  '[nsInvocationInstance setArgument: buffer atIndex: index]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: buffer to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationSetVoidPointerType: aMethodSignatureOop  index: index value: aValue [
	|  nsInvocationInstance buffer byteArraySize |
	self primitive: 'primitiveNSInvocationSetVoidPointerType'
		parameters: #(Oop SmallInteger ByteArray).
	self var: 'nsInvocationInstance' declareC: 'NSInvocation* nsInvocationInstance'.
	self var: 'buffer' declareC: 'void * buffer'.

	nsInvocationInstance := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSInvocation *'.
	interpreterProxy failed ifTrue: [^nil].
	byteArraySize := interpreterProxy slotSizeOf: aValue cPtrAsOop.
	self cCode: 'buffer = malloc(byteArraySize);
		memcpy(buffer,aValue,byteArraySize)'.
	self touch: nsInvocationInstance.
	self touch: buffer.
	self touch: byteArraySize.
	self cCode: '    NS_DURING'. 
	self cCode:  '[nsInvocationInstance setArgument: &buffer atIndex: index]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: buffer to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSInvocationWithMethodSignature: aMethodSignatureOop [
	|  methodSignatureOop nsInvocationOops |
	self primitive: 'primitiveNSInvocationWithMethodSignature'
		parameters: #(Oop).
	self var: 'methodSignatureOop' declareC: 'NSMethodSignature * methodSignatureOop'.
	self var: 'nsInvocationOops' declareC: 'NSInvocation* nsInvocationOops'.

	methodSignatureOop := self cCoerce: (interpreterProxy positive64BitValueOf: aMethodSignatureOop) to: 'NSMethodSignature *'.
	interpreterProxy failed ifTrue: [^nil].
	nsInvocationOops := 0.
	self cCode: '    NS_DURING'. 
	self cCode:  'nsInvocationOops = [NSInvocation invocationWithMethodSignature: methodSignatureOop]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: nsInvocationOops to: 'usqInt') 

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSLog: aNSStringOOP [
	|  oop1 |
	self primitive: 'primitiveNSLog'
		parameters: #(Oop).
	self var: 'oop1' declareC: 'id oop1'.
	
	oop1 := self cCoerce: (interpreterProxy positive64BitValueOf: aNSStringOOP) to: 'id'.
	interpreterProxy failed ifTrue: [^nil].
	self touch: oop1.
	self NSLog: oop1.

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveNSStringToUTF8: aNSStringOop [
	|  nsStringObject utf8String utf8StringOop |
	self primitive: 'primitiveNSStringToUTF8'
		parameters: #(Oop).
	self var: 'nsStringObject' declareC: 'NSString* nsStringObject'.
	self var: 'utf8String' declareC: 'const char * utf8String'.

	nsStringObject := self cCoerce: (interpreterProxy positive64BitValueOf: aNSStringOop) to: 'NSString *'.
	interpreterProxy failed ifTrue: [^nil].
	utf8String := nil.
	self touch: nsStringObject.
	self cCode: '    NS_DURING'. 
	self cCode:  'utf8String = [nsStringObject UTF8String]'.
	self cCode: '    NS_HANDLER 
		utf8String = nil;'.
	self cCode: '    NS_ENDHANDLER'.
	utf8String
		ifFalse: [interpreterProxy success: false.
		^nil].
	utf8StringOop := self stringFromCString: utf8String.
	^utf8StringOop

]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitivePerformSelector: aSelectorOop on: aClassOrInstanceOop [
	|  classOrInstanceObject  selectorObject returnValue |
	"- (id)performSelector:(SEL)aSelector"

	self primitive: 'primitivePerformSelector'
		parameters: #(Oop Oop).
	self var: 'classOrInstanceObject' declareC: 'id classOrInstanceObject'.
	self var: 'selectorObject' declareC: 'SEL selectorObject'.
	self var: 'returnValue' declareC: 'id returnValue'.

	classOrInstanceObject := self cCoerce: (interpreterProxy positive64BitValueOf: aClassOrInstanceOop) to: 'id'.
	selectorObject := self cCoerce: (interpreterProxy positive64BitValueOf: aSelectorOop) to: 'SEL'.
	interpreterProxy failed ifTrue: [^nil].
	returnValue := nil.
	self touch: classOrInstanceObject.
	self touch: selectorObject.
	self cCode: '    NS_DURING'. 
	self cCode:  'returnValue = [classOrInstanceObject performSelector: selectorObject]'.
	self cCode: '    NS_HANDLER 
		returnValue = nil;'.
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: returnValue to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitivePerformSelectorOnMainThreadWithWaitTilDone: aSelectorOop on: aClassOrInstanceOop with: anObject1 returnValue: aReturnValueAddress waitTilDone: doneFlag [
	|  classOrInstanceObject  selectorObject object1 returnAddress |
	"- (id)performSelector:(SEL)aSelector"

	self primitive: 'primitivePerformSelectorOnMainThreadWithWaitTilDone'
		parameters: #(Oop Oop Oop Oop Boolean).
	self var: 'classOrInstanceObject' declareC: 'id classOrInstanceObject'.
	self var: 'object1' declareC: 'id object1'.
	self var: 'selectorObject' declareC: 'SEL selectorObject'.
	self var: 'returnAddress' declareC: 'void *returnAddress'.

	classOrInstanceObject := self cCoerce: (interpreterProxy positive64BitValueOf: aClassOrInstanceOop) to: 'id'.
	selectorObject := self cCoerce: (interpreterProxy positive64BitValueOf: aSelectorOop) to: 'SEL'.
	object1 := self cCoerce: (interpreterProxy positive64BitValueOf: anObject1) to: 'id'.
	returnAddress := self cCoerce: (interpreterProxy positive64BitValueOf: aReturnValueAddress) to: 'void *'.
	interpreterProxy failed ifTrue: [^nil].
	self touch: classOrInstanceObject.
	self touch: selectorObject.
	self touch: object1.
	self touch: returnAddress.
	self cCode: '    NS_DURING'. 
	self cCode:  '[classOrInstanceObject performSelectorOnMainThread: selectorObject withObject: object1 waitUntilDone: doneFlag  ]'.
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	self cCode: '    NS_DURING'. 
	returnAddress ~= 0 ifTrue:
		[self cCode: '[classOrInstanceObject getReturnValue: returnAddress]'].
	self cCode: '    NS_HANDLER'.
		interpreterProxy success: false.
		true ifTrue: [^nil].
	self cCode: '    NS_ENDHANDLER'.
	^self
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitivePerformSelectorWith: aSelectorOop on: aClassOrInstanceOop with: anObject1 [
	|  classOrInstanceObject  selectorObject returnValue object1 |
	"- (id)performSelector:(SEL)aSelector"

	self primitive: 'primitivePerformSelectorWith'
		parameters: #(Oop Oop Oop).
	self var: 'classOrInstanceObject' declareC: 'id classOrInstanceObject'.
	self var: 'object1' declareC: 'id object1'.
	self var: 'selectorObject' declareC: 'SEL selectorObject'.
	self var: 'returnValue' declareC: 'id returnValue'.

	classOrInstanceObject := self cCoerce: (interpreterProxy positive64BitValueOf: aClassOrInstanceOop) to: 'id'.
	selectorObject := self cCoerce: (interpreterProxy positive64BitValueOf: aSelectorOop) to: 'SEL'.
	object1 := self cCoerce: (interpreterProxy positive64BitValueOf: anObject1) to: 'id'.
	interpreterProxy failed ifTrue: [^nil].
	returnValue := nil.
	self touch: classOrInstanceObject.
	self touch: selectorObject.
	self touch: object1.
	self cCode: '    NS_DURING'. 
	self cCode:  'returnValue = [classOrInstanceObject performSelector: selectorObject withObject: object1]'.
	self cCode: '    NS_HANDLER 
		returnValue = nil;'.
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: returnValue to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitivePerformSelectorWithWith: aSelectorOop on: aClassOrInstanceOop with: anObject1 with: anObject2 [
	|  classOrInstanceObject  selectorObject returnValue object1 object2 |
	"- (id)performSelector:(SEL)aSelector"

	self primitive: 'primitivePerformSelectorWithWith'
		parameters: #(Oop Oop Oop Oop).
	self var: 'classOrInstanceObject' declareC: 'id classOrInstanceObject'.
	self var: 'object1' declareC: 'id object1'.
	self var: 'object2' declareC: 'id object2'.
	self var: 'selectorObject' declareC: 'SEL selectorObject'.
	self var: 'returnValue' declareC: 'id returnValue'.

	classOrInstanceObject := self cCoerce: (interpreterProxy positive64BitValueOf: aClassOrInstanceOop) to: 'id'.
	selectorObject := self cCoerce: (interpreterProxy positive64BitValueOf: aSelectorOop) to: 'SEL'.
	object1 := self cCoerce: (interpreterProxy positive64BitValueOf: anObject1) to: 'id'.
	object2 := self cCoerce: (interpreterProxy positive64BitValueOf: anObject2) to: 'id'.
	interpreterProxy failed ifTrue: [^nil].
	returnValue := nil.
	self touch: classOrInstanceObject.
	self touch: selectorObject.
	self touch: object1.
	self touch: object2.
	self cCode: '    NS_DURING'. 
	self cCode:  'returnValue = [classOrInstanceObject performSelector: selectorObject withObject: object1 withObject: object2 ]'.
	self cCode: '    NS_HANDLER 
		returnValue = nil;'.
	self cCode: '    NS_ENDHANDLER'.
	^interpreterProxy positive64BitIntegerFor: (self cCoerce: returnValue to: 'usqInt') 
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> primitiveSELGetName: aSEL [
	|  stringOop bufferPointer |
	self primitive: 'primitiveSELGetName'
		parameters: #(Oop).
	self var: 'bufferPointer' declareC: 'SEL bufferPointer'.
	self cCode: '#define selgetName sel_getName
'.
	bufferPointer := self cCoerce: (interpreterProxy positive64BitValueOf: aSEL) to: 'SEL'.
	interpreterProxy failed ifTrue: [^nil].
	stringOop := self stringFromCString: (self selgetName: bufferPointer).
	^stringOop

]

{ #category : #'initialize-release' }
ObjectiveCPlugin >> shutdownModule [
	^true
]

{ #category : #'system primitives' }
ObjectiveCPlugin >> stringFromCString: aCString [
	"Answer a new String copied from a null-terminated C string.
	Caution: This may invoke the garbage collector."

	| len newString |
	self var: 'aCString' type: 'const char *'.
	len := self cCoerce: (self strlen: aCString) to: 'sqInt'. 
	newString := interpreterProxy
		instantiateClass: interpreterProxy classString
		indexableSize: len.
	self st: (interpreterProxy arrayValueOf: newString)
		rn: aCString
		cpy: len. "(char *)strncpy()"
	^ newString


]
