"
This plugin provides access to foreign function interfaces on those platforms that provide such. For example Windows DLLs and unix .so's.  It is obsolete, having been superceded by the ThreadedFFIPlugin.
"
Class {
	#name : #FFIPlugin,
	#superclass : #InterpreterPlugin,
	#instVars : [
		'ffiLastError',
		'ffiArgSpec',
		'ffiArgSpecSize',
		'ffiArgHeader',
		'ffiRetOop',
		'ffiRetClass',
		'ffiRetSpec',
		'ffiRetSpecSize',
		'ffiRetHeader',
		'ffiLogEnabled',
		'externalFunctionInstSize'
	],
	#pools : [
		'FFIConstants'
	],
	#category : 'VMMaker-Plugins-FFI'
}

{ #category : #accessing }
FFIPlugin class >> declareCVarsIn: aCCodeGen [
	aCCodeGen addHeaderFile: '"sqFFI.h"'
]

{ #category : #'C support code' }
FFIPlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
FFIPlugin class >> moduleName [ "FFIPlugin translate"
	"IMPORTANT: IF YOU CHANGE THE NAME OF THIS PLUGIN YOU MUST CHANGE
		Interpreter>>primitiveCalloutToFFI
	TO REFLECT THE CHANGE."
	^'SqueakFFIPrims'
]

{ #category : #translation }
FFIPlugin class >> requiresPlatformFiles [
	"this plugin requires platform specific files in order to work"
	^true
]

{ #category : #'primitive support' }
FFIPlugin >> atomicTypeOf: value [
	^(value bitAnd: FFIAtomicTypeMask) >> FFIAtomicTypeShift
]

{ #category : #'primitive support' }
FFIPlugin >> ffiAddressOf: rcvr startingAt: byteOffset size: byteSize [
"return an int of the address of the byteSize slot (byte, short, int, whatever) at byteOffset in rcvr. Nominally intended for use with ExternalAddress objects, this code will work (for obscure historical reasons) with plain Byte or Word Arrays as well. "
	| rcvrClass rcvrSize addr |
	(interpreterProxy isBytes: rcvr) ifFalse:[^interpreterProxy primitiveFail].
	(byteOffset > 0) ifFalse:[^interpreterProxy primitiveFail].
	rcvrClass := interpreterProxy fetchClassOf: rcvr.
	rcvrSize := interpreterProxy byteSizeOf: rcvr.
	rcvrClass == interpreterProxy classExternalAddress ifTrue:[
		(rcvrSize = 4) ifFalse:[^interpreterProxy primitiveFail].
		addr := interpreterProxy fetchPointer: 0 ofObject: rcvr.
		"don't you dare to read from object memory!"
		(addr == 0 or:[interpreterProxy isInMemory: addr])
			ifTrue:[^interpreterProxy primitiveFail].
	] ifFalse:[
		(byteOffset+byteSize-1 <= rcvrSize)
			ifFalse:[^interpreterProxy primitiveFail].
		addr := self cCoerce: (interpreterProxy firstIndexableField: rcvr) to: 'int'.
	].
	addr := addr + byteOffset - 1.
	^addr
]

{ #category : #'callout support' }
FFIPlugin >> ffiArgByValue: oop [
	"Support for generic callout. Prepare an argument by value for a callout."
	| atomicType intValue floatValue |
	<inline: true>
	<var: #floatValue type: 'double'>
	atomicType := self atomicTypeOf: ffiArgHeader.
	"check if the range is valid"
	(atomicType < 0 or:[atomicType > FFITypeDoubleFloat])
		ifTrue:[^self ffiFail: FFIErrorBadAtomicType].
	atomicType < FFITypeSingleFloat ifTrue:["integer types"
		(atomicType >> 1) = (FFITypeSignedLongLong >> 1)
			ifTrue:[intValue := oop] "ffi support code must coerce longlong"
			ifFalse:[intValue := self ffiIntegerValueOf: oop]. "does all the coercions"
		interpreterProxy failed ifTrue:[^self ffiFail: FFIErrorCoercionFailed].
		self dispatchOn: atomicType
			in: #(
				ffiPushVoid:
				ffiPushUnsignedInt:
				ffiPushUnsignedByte:
				ffiPushSignedByte:
				ffiPushUnsignedShort:
				ffiPushSignedShort:
				ffiPushUnsignedInt:
				ffiPushSignedInt:
				ffiPushUnsignedLongLongOop:
				ffiPushSignedLongLongOop:
				ffiPushUnsignedChar:
				ffiPushSignedChar:)
		with: intValue.
	] ifFalse:[
		"either float or double"
		floatValue := self ffiFloatValueOf: oop.
		interpreterProxy failed ifTrue:[^self ffiFail: FFIErrorCoercionFailed].
		atomicType = FFITypeSingleFloat
			ifTrue:[self ffiPushSingleFloat: floatValue]
			ifFalse:[self ffiPushDoubleFloat: floatValue].
	].
	^0
]

{ #category : #'callout support' }
FFIPlugin >> ffiArgument: oop Spec: argSpec Class: argClass [
	"Callout support. Prepare the given oop as argument.
	argSpec defines the compiled spec for the argument.
	argClass (if non-nil) defines the required (super)class for the argument."
	| valueOop oopClass isStruct nilOop |
	<inline: false>
	oopClass := interpreterProxy fetchClassOf: oop. "Prefetch class (we'll need it)"
	nilOop :=  interpreterProxy nilObject.
	"Do the necessary type checks"
	argClass == nilOop ifFalse:[
		"Type check 1: 
		Is the required class of the argument a subclass of ExternalStructure?"
		(interpreterProxy includesBehavior: argClass 
						ThatOf: interpreterProxy classExternalStructure)
			ifFalse:[^self ffiFail: FFIErrorWrongType]. "Nope. Fail."
		"Type check 2:
		Is the class of the argument a subclass of required class?"
		((nilOop == oop) or:[interpreterProxy includesBehavior: oopClass ThatOf: argClass])
				ifFalse:[^self ffiFail: FFIErrorCoercionFailed]. "Nope. Fail."
		"Okay, we've passed the type check (so far)"
	].

	"Check if oopClass is a subclass of ExternalStructure.
	If this is the case we'll work on it's handle and not the actual oop."
	isStruct := false.
	((interpreterProxy isImmediate: oop) or:[oop == nilOop]) ifFalse:[
		"#isPointers: will fail if oop is immediate so don't even attempt to use it"
		(interpreterProxy isPointers: oop) 
			ifTrue:[isStruct := interpreterProxy includesBehavior: oopClass 
								ThatOf: interpreterProxy classExternalStructure.
					(argClass == nilOop or:[isStruct]) 
						ifFalse:[^self ffiFail: FFIErrorCoercionFailed]].
		"note: the test for #isPointers: above should speed up execution since no pointer type ST objects are allowed in external calls and thus if #isPointers: is true then the arg must be ExternalStructure to work. If it isn't then the code fails anyways so speed isn't an issue"
	].

	"Determine valueOop (e.g., the actual oop to pass as argument)"
	isStruct
		ifTrue:[valueOop := interpreterProxy fetchPointer: 0 ofObject: oop]
		ifFalse:[valueOop := oop].

	"Fetch and check the contents of the compiled spec"
	(interpreterProxy isWords: argSpec)
		ifFalse:[self ffiFail: FFIErrorWrongType. ^nil].
	ffiArgSpecSize := interpreterProxy slotSizeOf: argSpec.
	ffiArgSpecSize = 0 ifTrue:[self ffiFail: FFIErrorWrongType. ^nil].
	ffiArgSpec := self cCoerce: (interpreterProxy firstIndexableField: argSpec) to: 'int'.
	ffiArgHeader := interpreterProxy longAt: ffiArgSpec.

	"Do the actual preparation of the argument"
	"Note: Order is important since FFIFlagStructure + FFIFlagPointer is used to represent 'typedef void* VoidPointer' and VoidPointer really is *struct* not pointer."

	(ffiArgHeader anyMask: FFIFlagStructure) ifTrue:[
		"argument must be ExternalStructure"
		isStruct ifFalse:[^self ffiFail: FFIErrorCoercionFailed].
		(ffiArgHeader anyMask: FFIFlagAtomic) 
			ifTrue:[^self ffiFail: FFIErrorWrongType]. "bad combination"
		^self ffiPushStructureContentsOf: valueOop].

	(ffiArgHeader anyMask: FFIFlagPointer) ifTrue:[
		"no integers (or characters) for pointers please"
		(interpreterProxy isImmediate: oop) 
			ifTrue:[^self ffiFail: FFIErrorIntAsPointer].

		"but allow passing nil pointer for any pointer type"
		oop == interpreterProxy nilObject ifTrue:[^self ffiPushPointer: nil].

		"argument is reference to either atomic or structure type"
		(ffiArgHeader anyMask: FFIFlagAtomic) ifTrue:[
			isStruct "e.g., ExternalData"
				ifTrue:[^self ffiAtomicStructByReference: oop Class: oopClass]
				ifFalse:[^self ffiAtomicArgByReference: oop Class: oopClass].
			"********* NOTE: The above uses 'oop' not 'valueOop' (for ExternalData) ******"
		].

		"Needs to be external structure here"
		isStruct ifFalse:[^self ffiFail: FFIErrorCoercionFailed].
		^self ffiPushPointerContentsOf: valueOop].

	(ffiArgHeader anyMask: FFIFlagAtomic) ifTrue:[
		"argument is atomic value"
		self ffiArgByValue: valueOop.
		^0].
	"None of the above - bad spec"
	^self ffiFail: FFIErrorWrongType
]

{ #category : #'callout support' }
FFIPlugin >> ffiAtomicArgByReference: oop Class: oopClass [
	"Support for generic callout. Prepare a pointer reference to an atomic type for callout. Note: for type 'void*' we allow either one of ByteArray/String/Symbol or wordVariableSubclass."
	| atomicType isString |
	<inline: true>
	atomicType := self atomicTypeOf: ffiArgHeader.
	(atomicType = FFITypeBool) "No bools on input"
		ifTrue:[^self ffiFail: FFIErrorCoercionFailed].
	((atomicType >> 1) = (FFITypeSignedChar >> 1)) ifTrue:["string value (char*)"
		"note: the only types allowed for passing into char* types are
		ByteArray, String, Symbol and *no* other byte indexed objects
		(e.g., CompiledMethod, LargeInteger). We only check for strings
		here and fall through to the byte* check otherwise."
		isString := interpreterProxy 
					includesBehavior: oopClass 
					ThatOf: interpreterProxy classString.
		isString ifTrue:["String/Symbol"
			"Strings must be allocated by the ffi support code"
			^self ffiPushString: (self cCoerce: (interpreterProxy firstIndexableField: oop) to: 'int') OfLength: (interpreterProxy byteSizeOf: oop)].
		"Fall through to byte* test"
		atomicType := FFITypeUnsignedByte].

	(atomicType = FFITypeVoid or:[(atomicType >> 1) = (FFITypeSignedByte >> 1)]) ifTrue:[
		"byte* -- see comment on string above"
		oopClass = interpreterProxy classByteArray ifTrue:["ByteArray"
			^self ffiPushPointer: (self cCoerce: (interpreterProxy firstIndexableField: oop) to:'int')].
		isString := interpreterProxy includesBehavior: oopClass 
					ThatOf: interpreterProxy classString.
		isString ifTrue:["String/Symbol"
			^self ffiPushPointer: (self cCoerce: (interpreterProxy firstIndexableField: oop) to:'int')].
		atomicType = FFITypeVoid ifFalse:[^self ffiFail: FFIErrorCoercionFailed].
		"note: type void falls through"
	].

	(atomicType <= FFITypeSignedInt "void/short/int"
		or:[atomicType = FFITypeSingleFloat]) ifTrue:[
			"require a word subclass to work"
			(interpreterProxy isWords: oop) ifTrue:[
				^self ffiPushPointer: (self cCoerce: (interpreterProxy firstIndexableField: oop) to:'int')]].

	^self ffiFail: FFIErrorCoercionFailed.
]

{ #category : #'callout support' }
FFIPlugin >> ffiAtomicStructByReference: oop Class: oopClass [
	"Support for generic callout. Prepare an external pointer reference to an atomic type for callout."
	| atomicType valueOop |
	<inline: true>
	"must be external data to pass pointers to atomic type"
	oopClass == interpreterProxy classExternalData 
		ifFalse:[^self ffiFail: FFIErrorCoercionFailed].
	atomicType := self atomicTypeOf: ffiArgHeader.
	"no type checks for void pointers"
	atomicType ~= FFITypeVoid ifTrue:[
		self ffiValidateExternalData: oop AtomicType: atomicType.
		interpreterProxy failed ifTrue:[^nil].
	].
	"and push pointer contents"
	valueOop := interpreterProxy fetchPointer: 0 ofObject: oop.
	^self ffiPushPointerContentsOf: valueOop
]

{ #category : #'callout support' }
FFIPlugin >> ffiCall: address WithFlags: callType AndTypes: argTypeArray [
	"Generic callout. Does the actual work."
	| stackIndex argType argTypes oop nArgs argClass argSpec |
	<inline: true>
	"check if the calling convention is supported"
	(self ffiSupportsCallingConvention: callType)
		ifFalse:[^self ffiFail: FFIErrorCallType].
	argTypes := argTypeArray.
	"Fetch return type and args"
	argType := interpreterProxy fetchPointer: 0 ofObject: argTypes.
	argSpec := interpreterProxy fetchPointer: 0 ofObject: argType.
	argClass := interpreterProxy fetchPointer: 1 ofObject: argType.
	self ffiCheckReturn: argSpec With: argClass.
	interpreterProxy failed ifTrue:[^0]. "cannot return"
	ffiRetOop := argType.
	nArgs := interpreterProxy methodArgumentCount.
	stackIndex := nArgs - 1. "stack index goes downwards"
	1 to: nArgs do:[:i|
		argType := interpreterProxy fetchPointer: i ofObject: argTypes.
		argSpec := interpreterProxy fetchPointer: 0 ofObject: argType.
		argClass := interpreterProxy fetchPointer: 1 ofObject: argType.
		oop := interpreterProxy stackValue: stackIndex.
		self ffiArgument: oop Spec: argSpec Class: argClass.
		interpreterProxy failed ifTrue:[^0]. "coercion failed"
		stackIndex := stackIndex - 1.
	].
	"Go out and call this guy"
	^self ffiCalloutTo: address WithFlags: callType
]

{ #category : #'callout support' }
FFIPlugin >> ffiCall: address WithFlags: callType Args: argArray AndTypes: argTypeArray OfSize: nArgs [
	"Generic callout. Does the actual work."
	| argType argTypes oop argSpec argClass |
	<inline: true>
	"check if the calling convention is supported"
	(self ffiSupportsCallingConvention: callType)
		ifFalse:[^self ffiFail: FFIErrorCallType].
	argTypes := argTypeArray.
	"Fetch return type and args"
	argType := interpreterProxy fetchPointer: 0 ofObject: argTypes.
	argSpec := interpreterProxy fetchPointer: 0 ofObject: argType.
	argClass := interpreterProxy fetchPointer: 1 ofObject: argType.
	self ffiCheckReturn: argSpec With: argClass.
	interpreterProxy failed ifTrue:[^0]. "cannot return"
	ffiRetOop := argType.
	1 to: nArgs do:[:i|
		argType := interpreterProxy fetchPointer: i ofObject: argTypes.
		argSpec := interpreterProxy fetchPointer: 0 ofObject: argType.
		argClass := interpreterProxy fetchPointer: 1 ofObject: argType.
		oop := interpreterProxy fetchPointer: i-1 ofObject: argArray.
		self ffiArgument: oop Spec: argSpec Class: argClass.
		interpreterProxy failed ifTrue:[^0]. "coercion failed"
	].
	"Go out and call this guy"
	^self ffiCalloutTo: address WithFlags: callType
]

{ #category : #'callout support' }
FFIPlugin >> ffiCalloutTo: address WithFlags: callType [
	"Go out, call this guy and create the return value"
	| retVal |
	<inline: false>
	"Note: Order is important here since FFIFlagPointer + FFIFlagStructure is used to represent 'typedef void* VoidPointer' and VoidPointer must be returned as pointer *not* as struct"
	(ffiRetHeader anyMask: FFIFlagPointer) ifTrue:[
		retVal := self ffiCallAddressOf: address WithPointerReturn: callType.
		^self ffiCreateReturnPointer: retVal.
	].
	(ffiRetHeader anyMask: FFIFlagStructure) ifTrue:[
		self 
			ffiCallAddressOf: address 
			With: callType 
			Struct: (self cCoerce: ffiRetSpec to:'int*')
			Return: ffiRetSpecSize.
		^self ffiCreateReturnStruct.
	].
	retVal := self ffiCallAddressOf: address With: callType ReturnType: ffiRetHeader.
	^self ffiCreateReturn: retVal.
]

{ #category : #'callout support' }
FFIPlugin >> ffiCheckReturn: retSpec With: retClass [
	"Make sure we can return an object of the given type"
	<inline: true>
	retClass == interpreterProxy nilObject ifFalse:[
		(interpreterProxy includesBehavior: retClass 
						ThatOf: interpreterProxy classExternalStructure)
			ifFalse:[^self ffiFail: FFIErrorBadReturn]].
	ffiRetClass := retClass.

	(interpreterProxy isWords: retSpec)
		ifFalse:[self ffiFail: FFIErrorWrongType. ^nil].
	ffiRetSpecSize := interpreterProxy slotSizeOf: retSpec.
	ffiRetSpecSize = 0 ifTrue:[self ffiFail: FFIErrorWrongType. ^nil].
	ffiRetSpec := self cCoerce: (interpreterProxy firstIndexableField: retSpec) to: 'int'.
	ffiRetHeader := interpreterProxy longAt: ffiRetSpec.
	(self isAtomicType: ffiRetHeader) ifFalse:[
		(ffiRetClass == interpreterProxy nilObject)
			ifTrue:[^self ffiFail: FFIErrorBadReturn]].
	(self ffiCan: (self cCoerce: ffiRetSpec to:'int*') Return: ffiRetSpecSize)
		ifFalse:[self ffiFail: FFIErrorBadReturn]. "cannot return this type"
	^0
]

{ #category : #'callout support' }
FFIPlugin >> ffiContentsOfHandle: oop errCode: errCode [
	"Make sure that the given oop is a valid external handle"
	<inline: true>
	(interpreterProxy isBytes: oop)
		ifFalse:[^self ffiFail: errCode].
	((interpreterProxy byteSizeOf: oop) == 4)
		ifFalse:[^self ffiFail: errCode].
	^interpreterProxy fetchPointer: 0 ofObject: oop
]

{ #category : #'callout support' }
FFIPlugin >> ffiCreateLongLongReturn: isSigned [
	"Create a longlong return value from a previous call out"
	| lowWord highWord largeClass nBytes largeInt ptr |
	<var: #ptr type:'unsigned char *'>
	lowWord := self ffiLongLongResultLow.
	highWord := self ffiLongLongResultHigh.
	isSigned ifTrue:["check for 32 bit signed"
		(highWord = 0 and:[lowWord >= 0])
			ifTrue:[^interpreterProxy signed32BitIntegerFor: lowWord].
		(highWord = -1 and:[lowWord < 0])
			ifTrue:[^interpreterProxy signed32BitIntegerFor: lowWord].
		"negate value for negative longlong"
		highWord < 0 
			ifTrue:[	largeClass := interpreterProxy classLargeNegativeInteger.
					lowWord := lowWord bitInvert32.
					highWord := highWord bitInvert32.
					lowWord = -1 "e.g., overflow when adding one"
						ifTrue:[highWord := highWord + 1].
					lowWord := lowWord + 1]
			ifFalse:[largeClass := interpreterProxy classLargePositiveInteger].
			"fall through"
	] ifFalse:["check for 32 bit unsigned"
		highWord = 0 ifTrue:[
			^interpreterProxy positive32BitIntegerFor: lowWord].
		largeClass := interpreterProxy classLargePositiveInteger.
		"fall through"
	].
	"Create LargeInteger result"
	nBytes := 8.
	(highWord anyMask: 255 << 24) ifFalse:[
		nBytes := 7.
		highWord < (1 << 16) ifTrue:[nBytes := 6].
		highWord < (1 << 8) ifTrue:[nBytes := 5].
		highWord = 0 ifTrue:[nBytes := 4]].
	"now we know how many bytes to create"
	largeInt := interpreterProxy instantiateClass: largeClass indexableSize: nBytes.
	(interpreterProxy isBytes: largeInt) 
		ifFalse:[^self ffiFail: FFIErrorBadReturn]. "Hossa!"
	ptr := interpreterProxy firstIndexableField: largeInt.
	4 to: nBytes-1 do:[:i|
		ptr at: i put: (highWord >> (i-4*8) bitAnd: 255)].
	ptr at: 3 put: (lowWord >> 24 bitAnd: 255).
	ptr at: 2 put: (lowWord >> 16 bitAnd: 255).
	ptr at: 1 put: (lowWord >> 8 bitAnd: 255).
	ptr at: 0 put: (lowWord bitAnd: 255).
	^largeInt
]

{ #category : #'callout support' }
FFIPlugin >> ffiCreateReturn: retVal [
	"Generic callout support. Create an atomic return value from an external function call"
	| atomicType retOop oop |
	<inline: true>
	interpreterProxy failed ifTrue:[^nil].
	atomicType := self atomicTypeOf: ffiRetHeader.
	"void returns self"
	atomicType <= FFITypeVoid ifTrue:[
		^interpreterProxy pop: interpreterProxy methodArgumentCount].
	"everything else returns value"
	interpreterProxy pop: 
		interpreterProxy methodArgumentCount+1.
	interpreterProxy pushRemappableOop: ffiRetClass.
	retOop := self ffiCreateReturnOop: retVal.
	ffiRetClass := interpreterProxy popRemappableOop.
	ffiRetClass == interpreterProxy nilObject ifTrue:[
		"Just return oop"
		^interpreterProxy push: retOop].
	"Otherwise create an instance of external structure and store the return oop"
	interpreterProxy pushRemappableOop: retOop.
	retOop := interpreterProxy instantiateClass: ffiRetClass indexableSize: 0.
	oop := interpreterProxy popRemappableOop.
	interpreterProxy storePointer: 0 ofObject: retOop withValue: oop.
	^interpreterProxy push: retOop.
]

{ #category : #'callout support' }
FFIPlugin >> ffiCreateReturnOop: retVal [
	"Callout support. Return the appropriate oop for the given atomic value"
	| atomicType shift value mask byteSize |
	atomicType := self atomicTypeOf: ffiRetHeader.
	atomicType = FFITypeBool ifTrue:[
			"Make sure bool honors the byte size requested"
			byteSize := ffiRetHeader bitAnd: FFIStructSizeMask.
			byteSize = 4
				ifTrue:[value := retVal]
				ifFalse:[value := retVal bitAnd: 1 << (byteSize * 8) - 1].
			value = 0
				ifTrue:[^interpreterProxy falseObject]
				ifFalse:[^interpreterProxy trueObject]].
	atomicType <= FFITypeSignedInt ifTrue:[
		"these are all generall integer returns"
		atomicType <= FFITypeSignedShort ifTrue:[
			"byte/short. first extract partial word, then sign extend"
			shift := (atomicType >> 1) * 8. "# of significant bits"
			value := retVal bitAnd: (1 << shift - 1). 
			(atomicType anyMask: 1) ifTrue:[
				"make the guy signed"
				mask := 1 << (shift-1).
				value := (value bitAnd: mask-1) - (value bitAnd: mask)].
			^interpreterProxy integerObjectOf: value].
		"32bit integer return"
		(atomicType anyMask: 1)
			ifTrue:[^(interpreterProxy signed32BitIntegerFor: retVal)] "signed return"
			ifFalse:[^(interpreterProxy positive32BitIntegerFor: retVal)]]. "unsigned return"

	atomicType < FFITypeSingleFloat ifTrue:[
		"longlong, char"
		(atomicType >> 1) = (FFITypeSignedLongLong >> 1) 
			ifTrue:[^self ffiCreateLongLongReturn: (atomicType anyMask: 1)]
			ifFalse:[^(interpreterProxy 
						fetchPointer: (retVal bitAnd: 255)
						ofObject: interpreterProxy characterTable)]].
	"float return"
	^interpreterProxy floatObjectOf: (self ffiReturnFloatValue).
]

{ #category : #'callout support' }
FFIPlugin >> ffiCreateReturnPointer: retVal [
	"Generic callout support. Create a pointer return value from an external function call"
	| atomicType retOop oop ptr classOop |
	<var: #ptr type:'int *'>
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy pop: interpreterProxy methodArgumentCount+1.
	(ffiRetClass == interpreterProxy nilObject) ifTrue:[
		"Create ExternalData upon return"
		atomicType := self atomicTypeOf: ffiRetHeader.
		(atomicType >> 1) = (FFITypeSignedChar >> 1) ifTrue:["String return"
			^self ffiReturnCStringFrom: retVal].
		"generate external data"
		interpreterProxy pushRemappableOop: ffiRetOop.
		oop := interpreterProxy 
				instantiateClass: interpreterProxy classExternalAddress 
				indexableSize: 4.
		ptr := interpreterProxy firstIndexableField: oop.
		ptr at: 0 put: retVal.
		interpreterProxy pushRemappableOop: oop. "preserve for gc"
		retOop := interpreterProxy 
				instantiateClass: interpreterProxy classExternalData 
				indexableSize: 0.
		oop := interpreterProxy popRemappableOop. "external address"
		interpreterProxy storePointer: 0 ofObject: retOop withValue: oop.
		oop := interpreterProxy popRemappableOop. "return type"
		interpreterProxy storePointer: 1 ofObject: retOop withValue: oop.
		^interpreterProxy push: retOop.
	].
	"non-atomic pointer return"
	interpreterProxy pushRemappableOop: ffiRetClass. "preserve for gc"
	(ffiRetHeader anyMask: FFIFlagStructure)
		ifTrue:[classOop := interpreterProxy classByteArray]
		ifFalse:[classOop := interpreterProxy classExternalAddress].
	oop := interpreterProxy 
			instantiateClass: classOop
			indexableSize: 4.
	ptr := interpreterProxy firstIndexableField: oop.
	ptr at: 0 put: retVal.
	ffiRetClass := interpreterProxy popRemappableOop. "return class"
	interpreterProxy pushRemappableOop: oop. "preserve for gc"
	retOop := interpreterProxy instantiateClass: ffiRetClass indexableSize: 0.
	oop := interpreterProxy popRemappableOop. "external address"
	interpreterProxy storePointer: 0 ofObject: retOop withValue: oop.
	^interpreterProxy push: retOop.
]

{ #category : #'callout support' }
FFIPlugin >> ffiCreateReturnStruct [
	"Generic callout support. Create a structure return value from an external function call"
	| retOop structSize oop |
	<inline: true>
	interpreterProxy failed ifTrue:[^nil].
	interpreterProxy pop: interpreterProxy methodArgumentCount+1.
	structSize := ffiRetHeader bitAnd: FFIStructSizeMask.
	interpreterProxy pushRemappableOop: ffiRetClass.
	oop := interpreterProxy 
			instantiateClass: interpreterProxy classByteArray 
			indexableSize: structSize.
	self ffiStore: (self cCoerce: (interpreterProxy firstIndexableField: oop) to:'int') 
		Structure: structSize.
	ffiRetClass := interpreterProxy popRemappableOop.
	interpreterProxy pushRemappableOop: oop. "secure byte array"
	retOop := interpreterProxy instantiateClass: ffiRetClass indexableSize: 0.
	oop := interpreterProxy popRemappableOop.
	interpreterProxy storePointer: 0 ofObject: retOop withValue: oop.
	^interpreterProxy push: retOop.
]

{ #category : #'callout support' }
FFIPlugin >> ffiFail: reason [
	<inline: false>
	"Map the FFI error code into a primitive error code.  If reason is negative it encodes one of the
	 standard PrimErr... codes, negated to distinguish it from the FFIError codes.  If it is an FFIError...
	 code then add the size of the primitive error table + 2 to disambiguate it from the PrimErr... codes.
	 For historic reasons the FFIError codes range from -1 on up hence adding size + 2 maps them to
	 size of table + 1 on up.  This OFFSET IS undone by ExternalFunction class>>externalCallFailedWith:.
	 Thus we can communicate back both PrimErr.. and FFIError codes.  Complex but necessary in the ThreadedFFIPlugin."
	self ffiSetLastError: reason.
	^interpreterProxy primitiveFailFor:
		(reason >= FFINoCalloutAvailable
			ifTrue: [reason + 2 + (interpreterProxy slotSizeOf: interpreterProxy primitiveErrorTable)]
			ifFalse: [reason negated])
]

{ #category : #'callout support' }
FFIPlugin >> ffiFloatValueOf: oop [
	"Support for generic callout. Return a float value that is coerced as C would do."
	| oopClass |
	<returnTypeC:'double'>
	oopClass := interpreterProxy fetchClassOf: oop.
	oopClass == interpreterProxy classFloat
		ifTrue:[^interpreterProxy floatValueOf: oop].
	"otherwise try the integer coercions and return its float value"
	^(self ffiIntegerValueOf: oop) asFloat
]

{ #category : #'callout support' }
FFIPlugin >> ffiGetLastError [
	^ffiLastError
]

{ #category : #'callout support' }
FFIPlugin >> ffiIntegerValueOf: oop [
	"Support for generic callout. Return an integer value that is coerced as C would do."
	| oopClass |
	<inline: true>
	(interpreterProxy isIntegerObject: oop) ifTrue:[^interpreterProxy integerValueOf: oop].
	oop == interpreterProxy nilObject ifTrue:[^0]. "@@: should we really allow this????"
	oop == interpreterProxy falseObject ifTrue:[^0].
	oop == interpreterProxy trueObject ifTrue:[^1].
	oopClass := interpreterProxy fetchClassOf: oop.
	oopClass == interpreterProxy classFloat
		ifTrue:[^(interpreterProxy floatValueOf: oop) asInteger].
	oopClass == interpreterProxy classCharacter
		ifTrue:[^interpreterProxy characterValueOf: oop].
	oopClass == interpreterProxy classLargePositiveInteger
		ifTrue:[^interpreterProxy positive32BitValueOf: oop].
	^interpreterProxy signed32BitValueOf: oop "<- will fail if not integer"
]

{ #category : #'symbol loading' }
FFIPlugin >> ffiLoadCalloutAddress: lit [
	"Load the address of the foreign function from the given object"
	| addressPtr address ptr |
	<var: #ptr type:'int *'>
	"Lookup the address"
	addressPtr := interpreterProxy fetchPointer: 0 ofObject: lit.
	"Make sure it's an external handle"
	address := self ffiContentsOfHandle: addressPtr errCode: FFIErrorBadAddress.
	interpreterProxy failed ifTrue:[^0].
	address = 0 ifTrue:["Go look it up in the module"
		(interpreterProxy slotSizeOf: lit) < 5 ifTrue:[^self ffiFail: FFIErrorNoModule].
		address := self ffiLoadCalloutAddressFrom: lit.
		interpreterProxy failed ifTrue:[^0].
		"Store back the address"
		ptr := interpreterProxy firstIndexableField: addressPtr.
		ptr at: 0 put: address].
	^address
]

{ #category : #'symbol loading' }
FFIPlugin >> ffiLoadCalloutAddressFrom: oop [
	"Load the function address for a call out to an external function"
	| module moduleHandle functionName functionLength address |
	<inline: false>
	"First find and load the module"
	module := interpreterProxy fetchPointer: externalFunctionInstSize + 1 ofObject: oop.
	moduleHandle := self ffiLoadCalloutModule: module.
	interpreterProxy failed ifTrue:
		[^0]. "failed"
	"fetch the function name"
	functionName := interpreterProxy fetchPointer: externalFunctionInstSize ofObject: oop.
	(interpreterProxy isBytes: functionName) ifFalse:
		[^self ffiFail: FFIErrorBadExternalFunction].
	functionLength := interpreterProxy byteSizeOf: functionName.
	address := interpreterProxy
					ioLoadSymbol: (self cCoerce: (interpreterProxy firstIndexableField: functionName) to: #int)
					OfLength: functionLength 
					FromModule: moduleHandle.
	(interpreterProxy failed or: [address = 0]) ifTrue:
		[^self ffiFail: FFIErrorAddressNotFound].
	^address
]

{ #category : #'symbol loading' }
FFIPlugin >> ffiLoadCalloutModule: module [
	"Load the given module and return its handle"
	| moduleHandlePtr moduleHandle ffiModuleName moduleLength rcvr theClass ptr |
	<var: #ptr type:'int *'>
	(interpreterProxy isBytes: module) ifTrue:[
		"plain module name"
		ffiModuleName := module.
		moduleLength := interpreterProxy byteSizeOf: ffiModuleName.
		moduleHandle := interpreterProxy ioLoadModule: (self cCoerce: (interpreterProxy firstIndexableField: ffiModuleName) to:'int') OfLength: moduleLength.
		interpreterProxy failed ifTrue:[^self ffiFail: FFIErrorModuleNotFound]. "failed"
		^moduleHandle].
	"Check if the external method is defined in an external library"
	rcvr := interpreterProxy stackValue: interpreterProxy methodArgumentCount.
	theClass := interpreterProxy fetchClassOf: rcvr.
	(interpreterProxy includesBehavior: theClass 
			ThatOf: interpreterProxy classExternalLibrary) ifFalse:[^0].
	"external library"
	moduleHandlePtr := interpreterProxy fetchPointer: 0 ofObject: rcvr.
	moduleHandle := self ffiContentsOfHandle: moduleHandlePtr errCode: FFIErrorBadExternalLibrary.
	interpreterProxy failed ifTrue:[^0].
	moduleHandle = 0 ifTrue:["need to reload module"
		ffiModuleName := interpreterProxy fetchPointer: 1 ofObject: rcvr.
		(interpreterProxy isBytes: ffiModuleName) ifFalse:[^self ffiFail: FFIErrorBadExternalLibrary].
		moduleLength := interpreterProxy byteSizeOf: ffiModuleName.
		moduleHandle := interpreterProxy ioLoadModule: (self cCoerce: (interpreterProxy firstIndexableField: ffiModuleName) to:'int') OfLength: moduleLength.
		interpreterProxy failed ifTrue:[^self ffiFail: FFIErrorModuleNotFound]. "failed"
		"and store back"
		ptr := interpreterProxy firstIndexableField: moduleHandlePtr.
		ptr at: 0 put: moduleHandle].
	^moduleHandle
]

{ #category : #'symbol loading' }
FFIPlugin >> ffiLogCallout: lit [
	"fetch the function name"
	| functionName |
	ffiLogEnabled ifTrue:[
		functionName := interpreterProxy fetchPointer: externalFunctionInstSize ofObject: lit.
		(interpreterProxy isBytes: functionName) ifFalse:[^nil].
		self ffiLogCall: (interpreterProxy firstIndexableField: functionName)
			OfLength: (interpreterProxy byteSizeOf: functionName).
	].
]

{ #category : #initialize }
FFIPlugin >> ffiLogCallsTo: fileName [
	"This is a special entry point exposed such that client code can 
	enable and disable logging of FFI calls."
	| ok |
	<export: true>
	<var: #fileName type: 'char*'>
	fileName == nil ifTrue:[ "disable logging"
		ok := self ffiLogFileName: nil OfLength: 0.
		ok ifFalse:[^false].
		ffiLogEnabled := false.
	] ifFalse:[ "enable logging"
		ok := self ffiLogFileName: fileName OfLength: (self strlen: fileName).
		ok ifFalse:[^false].
		ffiLogEnabled := true.
	].
	^true
]

{ #category : #'callout support' }
FFIPlugin >> ffiPushPointerContentsOf: oop [
	"Push the contents of the given external structure"
	| ptrValue ptrClass ptrAddress |
	<inline: false>
	ptrValue := oop.
	ptrClass := interpreterProxy fetchClassOf: ptrValue.
	ptrClass == interpreterProxy classExternalAddress ifTrue:[
		ptrAddress := interpreterProxy fetchPointer: 0 ofObject: ptrValue.
		"Don't you dare to pass pointers into object memory"
		(interpreterProxy isInMemory: ptrAddress)
			ifTrue:[^self ffiFail: FFIErrorInvalidPointer].
		^self ffiPushPointer: ptrAddress].
	ptrClass == interpreterProxy classByteArray ifTrue:[
		ptrAddress := self cCoerce: (interpreterProxy firstIndexableField: ptrValue) to: 'int'.
		^self ffiPushPointer: ptrAddress].
	^self ffiFail: FFIErrorBadArg
]

{ #category : #'callout support' }
FFIPlugin >> ffiPushSignedLongLongOop: oop [
	"Push a longlong type (e.g., a 64bit integer).
	Note: Coercions from float are *not* supported."
	| lowWord highWord length oopClass negative ptr |
	<var: #ptr type:'unsigned char *'>
	oop == interpreterProxy nilObject 
		ifTrue:[^self ffiPushSignedLong: 0 Long: 0.]. "@@: check this"
	oop == interpreterProxy falseObject
		ifTrue:[^self ffiPushSignedLong: 0 Long: 0].
	oop == interpreterProxy trueObject
		ifTrue:[^self ffiPushSignedLong: 0 Long: 1].
	(interpreterProxy isIntegerObject: oop) ifTrue:[
		lowWord := interpreterProxy integerValueOf: oop.
		lowWord < 0 
			ifTrue:[highWord := -1]
			ifFalse:[highWord := 0].
	] ifFalse:[
		oopClass := interpreterProxy fetchClassOf: oop.
		oopClass == interpreterProxy classLargePositiveInteger 
			ifTrue:[negative := false]
			ifFalse:[oopClass == interpreterProxy classLargeNegativeInteger 
				ifTrue:[negative := true]
				ifFalse:[^self ffiFail: FFIErrorCoercionFailed]].
		(interpreterProxy isBytes: oop) ifFalse:[^self ffiFail: FFIErrorCoercionFailed].
		length := interpreterProxy byteSizeOf: oop.
		length > 8 ifTrue:[^self ffiFail: FFIErrorCoercionFailed].
		lowWord := highWord := 0.
		ptr := interpreterProxy firstIndexableField: oop.
		0 to: (length min: 4)-1 do:[:i|
			lowWord := lowWord + ((ptr at: i) << (i*8))].
		0 to: (length-5) do:[:i|
			highWord := highWord + ((ptr at: i+4) << (i*8))].
		negative ifTrue:[
			lowWord := lowWord bitInvert32.
			highWord := highWord bitInvert32.
			lowWord = -1 "e.g., will overflow when adding one"
				ifTrue:[highWord := highWord + 1].
			lowWord := lowWord + 1].
	].
	^self ffiPushSignedLong: lowWord Long: highWord.
]

{ #category : #'callout support' }
FFIPlugin >> ffiPushStructureContentsOf: oop [
	"Push the contents of the given external structure"
	| ptrValue ptrClass ptrAddress |
	<inline: true>
	ptrValue := oop.
	ptrClass := interpreterProxy fetchClassOf: ptrValue.
	ptrClass == interpreterProxy classExternalAddress ifTrue:[
		ptrAddress := interpreterProxy fetchPointer: 0 ofObject: ptrValue.
		"There is no way we can make sure the structure is valid.
		But we can at least check for attempts to pass pointers to ST memory."
		(interpreterProxy isInMemory: ptrAddress)
			ifTrue:[^self ffiFail: FFIErrorInvalidPointer].
		^self ffiPush: ptrAddress 
				Structure: (self cCoerce: ffiArgSpec to:'int*')
				OfLength: ffiArgSpecSize].
	ptrClass == interpreterProxy classByteArray ifTrue:[
		"The following is a somewhat pessimistic test but I like being sure..."
		(interpreterProxy byteSizeOf: ptrValue) = (ffiArgHeader bitAnd: FFIStructSizeMask)
			ifFalse:[^self ffiFail: FFIErrorStructSize].
		ptrAddress := self cCoerce: (interpreterProxy firstIndexableField: ptrValue) to: 'int'.
		(ffiArgHeader anyMask: FFIFlagPointer) ifFalse:[
			^self ffiPush: ptrAddress 
					Structure: (self cCoerce: ffiArgSpec to: 'int*')
					OfLength: ffiArgSpecSize].
		"If FFIFlagPointer + FFIFlagStructure is set use ffiPushPointer on the contents"
		(ffiArgHeader bitAnd: FFIStructSizeMask) = 4
			ifFalse:[^self ffiFail: FFIErrorStructSize].
		ptrAddress := interpreterProxy fetchPointer: 0 ofObject: ptrValue.
		(interpreterProxy isInMemory: ptrAddress)
			ifTrue:[^self ffiFail: FFIErrorInvalidPointer].
		^self ffiPushPointer: ptrAddress].
	^self ffiFail: FFIErrorBadArg
]

{ #category : #'callout support' }
FFIPlugin >> ffiPushUnsignedLongLongOop: oop [
	"Push a longlong type (e.g., a 64bit integer).
	Note: Coercions from float are *not* supported."
	| lowWord highWord length ptr |
	<var: #ptr type:'unsigned char *'>
	oop == interpreterProxy nilObject 
		ifTrue:[^self ffiPushUnsignedLong: 0 Long: 0.]. "@@: check this"
	oop == interpreterProxy falseObject 
		ifTrue:[^self ffiPushUnsignedLong: 0 Long: 0].
	oop == interpreterProxy trueObject 
		ifTrue:[^self ffiPushUnsignedLong: 0 Long: 1].
	(interpreterProxy isIntegerObject: oop) ifTrue:[
		lowWord := interpreterProxy integerValueOf: oop.
		lowWord < 0 ifTrue:[^self ffiFail: FFIErrorCoercionFailed].
		highWord := 0.
	] ifFalse:[
		(interpreterProxy isLargePositiveIntegerObject: oop)
			ifFalse:[^interpreterProxy primitiveFail].
		(interpreterProxy isBytes: oop) ifFalse:[^self ffiFail: FFIErrorCoercionFailed].
		length := interpreterProxy byteSizeOf: oop.
		length > 8 ifTrue:[^self ffiFail: FFIErrorCoercionFailed].
		lowWord := highWord := 0.
		ptr := interpreterProxy firstIndexableField: oop.
		0 to: (length min: 4)-1 do:[:i|
			lowWord := lowWord + ((ptr at: i) << (i*8))].
		0 to: (length-5) do:[:i|
			highWord := highWord + ((ptr at: i+4) << (i*8))].
	].
	^self ffiPushUnsignedLong: lowWord Long: highWord.
]

{ #category : #'callout support' }
FFIPlugin >> ffiPushVoid: ignored [
	"This is a fallback in case somebody tries to pass a 'void' value.
	We could simply ignore the argument but I think it's better to let
	the caller know what he did"
	^self ffiFail: FFIErrorAttemptToPassVoid.
]

{ #category : #'callout support' }
FFIPlugin >> ffiReturnCStringFrom: cPointer [
	"Create a Smalltalk string from a zero terminated C string"
	| strLen strOop cString strPtr |
	<var: #cString type:'char *'>
	<var: #strPtr type:'char *'>
	cPointer = nil ifTrue:[
		^interpreterProxy push: interpreterProxy nilObject]. "nil always returs as nil"
	cString := self cCoerce: cPointer to:'char *'.
	strLen := 0.
	[(cString at: strLen) = 0] whileFalse:[strLen := strLen+1].
	strOop := interpreterProxy 
				instantiateClass: interpreterProxy classString 
				indexableSize: strLen.
	strPtr := interpreterProxy firstIndexableField: strOop.
	0 to: strLen-1 do:[:i| strPtr at: i put: (cString at: i)].
	^interpreterProxy push: strOop
]

{ #category : #'callout support' }
FFIPlugin >> ffiSetLastError: errCode [
	^ffiLastError := errCode
]

{ #category : #'callout support' }
FFIPlugin >> ffiValidateExternalData: oop AtomicType: atomicType [
	"Validate if the given oop (an instance of ExternalData) can be passed as a pointer to the given atomic type."
	| ptrType specOop spec specType |
	<inline: true>
	ptrType := interpreterProxy fetchPointer: 1 ofObject: oop.
	(interpreterProxy isPointers: ptrType)
		ifFalse:[^self ffiFail: FFIErrorWrongType].
	(interpreterProxy slotSizeOf: ptrType) < 2
		ifTrue:[^self ffiFail: FFIErrorWrongType].
	specOop := interpreterProxy fetchPointer: 0 ofObject: ptrType.
	(interpreterProxy isWords: specOop)
		ifFalse:[^self ffiFail: FFIErrorWrongType].
	(interpreterProxy slotSizeOf: specOop) = 0
		ifTrue:[^self ffiFail: FFIErrorWrongType].
	spec := interpreterProxy fetchPointer: 0 ofObject: specOop.
	(self isAtomicType: spec)
		ifFalse:[^self ffiFail: FFIErrorWrongType].
	specType := self atomicTypeOf: spec.
	specType ~= atomicType ifTrue:[
		"allow for signed/unsigned conversion but nothing else"
		(atomicType > FFITypeBool and:[atomicType < FFITypeSingleFloat])
			ifFalse:[^self ffiFail: FFIErrorCoercionFailed].
		((atomicType >> 1) = (specType >> 1))
			ifFalse:[^self ffiFail: FFIErrorCoercionFailed]].
	^0
]

{ #category : #initialize }
FFIPlugin >> initialiseModule [
	<export: true>
	self initSurfacePluginFunctionPointers.
	"By default, disable logging"
	ffiLogEnabled := false.
	"Get the instSize of ExternalFunction to know whether it contains a cache of the stackSize,
	 and what the offset of ExternalLibraryFunction's functionName and moduleName slots are."
	externalFunctionInstSize := interpreterProxy instanceSizeOf: interpreterProxy classExternalFunction.
	^1
]

{ #category : #'primitive support' }
FFIPlugin >> isAtomicType: typeSpec [
	^typeSpec anyMask: FFIFlagAtomic
]

{ #category : #primitives }
FFIPlugin >> primitiveCallout [

	"IMPORTANT: IF YOU CHANGE THE NAME OF THIS METHOD YOU MUST CHANGE
		Interpreter>>primitiveCalloutToFFI
	TO REFLECT THE CHANGE."

	"Perform a function call to a foreign function.
	Only invoked from method containing explicit external call spec."
	| lit address flags argTypes litClass nArgs meth |
	<export: true>
	<inline: false>
	self ffiSetLastError: FFIErrorGenericError. "educated guess if we fail silently"
	lit := nil.
	"Look if the method is itself a callout function"
	meth := interpreterProxy primitiveMethod.
	(interpreterProxy literalCountOf: meth) > 0 ifFalse:[^interpreterProxy primitiveFail].
	lit := interpreterProxy literal: 0 ofMethod: meth.
	litClass := interpreterProxy fetchClassOf: lit.
	(interpreterProxy includesBehavior: litClass 
						ThatOf: interpreterProxy classExternalFunction) 
		ifFalse:[^self ffiFail: FFIErrorNotFunction].
	address := self ffiLoadCalloutAddress: lit.
	interpreterProxy failed ifTrue:[^0].
	"Load and check the other values before we call out"
	flags := interpreterProxy fetchInteger: 1 ofObject: lit.
	interpreterProxy failed ifTrue:[^self ffiFail: FFIErrorBadArgs].
	argTypes := interpreterProxy fetchPointer: 2 ofObject: lit.
	"must be array of arg types"
	(interpreterProxy isArray: argTypes)
		ifFalse:[^self ffiFail: FFIErrorBadArgs].
	nArgs := interpreterProxy slotSizeOf: argTypes.
	"must be argumentCount+1 arg types"
	nArgs = (interpreterProxy methodArgumentCount+1) 
		ifFalse:[^self ffiFail: FFIErrorBadArgs].
	self ffiLogCallout: lit.
	self ffiInitialize. "announce the execution of an external call"
	self ffiCall: address 
		WithFlags: flags 
		AndTypes: argTypes.
	self ffiCleanup. "cleanup temp allocations"
	^0
]

{ #category : #primitives }
FFIPlugin >> primitiveCalloutWithArgs [
	"Perform a function call to a foreign function.
	Only invoked from ExternalFunction>>invokeWithArguments:"
	| lit address flags argTypes litClass nArgs argArray |
	<export: true>
	<inline: false>
	self ffiSetLastError: FFIErrorGenericError. "educated guess if we fail silently"
	lit := nil.
	"Look if the method is itself a callout function"
	lit := interpreterProxy stackValue: interpreterProxy methodArgumentCount.
	litClass := interpreterProxy fetchClassOf: lit.
	(interpreterProxy includesBehavior: litClass 
						ThatOf: interpreterProxy classExternalFunction) 
		ifFalse:[^self ffiFail: FFIErrorNotFunction].
	address := self ffiLoadCalloutAddress: lit.
	interpreterProxy failed ifTrue:[^nil].
	"Load and check the other values before we call out"
	flags := interpreterProxy fetchInteger: 1 ofObject: lit.
	interpreterProxy failed ifTrue:[^self ffiFail: FFIErrorBadArgs].
	argTypes := interpreterProxy fetchPointer: 2 ofObject: lit.
	"must be array of arg types"
	(interpreterProxy isArray: argTypes) 
		ifFalse:[^self ffiFail: FFIErrorBadArgs].
	nArgs := interpreterProxy slotSizeOf: argTypes.
	(interpreterProxy methodArgumentCount = 1) 
		ifFalse:[^self ffiFail: FFIErrorBadArgs].
	argArray := interpreterProxy stackValue: 0.
	(interpreterProxy isArray: argArray)
		ifFalse:[^self ffiFail: FFIErrorBadArgs].
	nArgs = ((interpreterProxy slotSizeOf: argArray) + 1)
		ifFalse:[^self ffiFail: FFIErrorBadArgs].
	self ffiInitialize. "announce the execution of an external call"
	self ffiCall: address 
		WithFlags: flags 
		Args: argArray
		AndTypes: argTypes
		OfSize: nArgs-1.
	self ffiCleanup. "cleanup temp allocations"
	^0
]

{ #category : #'primitives - surfaces' }
FFIPlugin >> primitiveCreateManualSurface [
	"arguments: name(type, stack offset)
		width(Integer, 4)
		height(Integer, 3)
		rowPitch(Integer, 2)
		depth(Integer, 1)
		isMSB(Boolean, 0)"
	| width height rowPitch depth isMSB result |
	<export: true>
	
	interpreterProxy methodArgumentCount == 5 ifFalse: [^interpreterProxy primitiveFail].
	width := interpreterProxy stackIntegerValue: 4.
	height := interpreterProxy stackIntegerValue: 3.
	rowPitch := interpreterProxy stackIntegerValue: 2.
	depth := interpreterProxy stackIntegerValue: 1.
	isMSB := interpreterProxy stackObjectValue: 0.
	isMSB := interpreterProxy booleanValueOf: isMSB. 
	interpreterProxy failed ifTrue: [^nil].
	
	self touch: width; touch: height; touch: rowPitch; touch: depth; touch: isMSB.
	
	result := self cCode: 'createManualSurface(width, height, rowPitch, depth, isMSB)'.
	result < 0 ifTrue: [^interpreterProxy primitiveFail].
	result := interpreterProxy signed32BitIntegerFor: result.
	^interpreterProxy pop: 6 thenPush: result
	
]

{ #category : #'primitives - surfaces' }
FFIPlugin >> primitiveDestroyManualSurface [
	"arguments: name(type, stack offset)
		surfaceID(Integer, 0)"
	| surfaceID result |
	<export: true>
	
	interpreterProxy methodArgumentCount == 1 ifFalse: [^interpreterProxy primitiveFail].
	surfaceID := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue: [^nil].
	result := self destroyManualSurface: surfaceID.
	result = 0 ifTrue: [^interpreterProxy primitiveFail].
	^interpreterProxy pop: 1
	
]

{ #category : #primitives }
FFIPlugin >> primitiveFFIAllocate [
	"Primitive. Allocate an object on the external heap."
	| byteSize addr oop ptr |
	<export: true>
	<inline: false>
	<var: #ptr type:'int *'>
	byteSize := interpreterProxy stackIntegerValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	addr := self ffiAlloc: byteSize.
	addr = 0 ifTrue:[^interpreterProxy primitiveFail].
	oop := interpreterProxy 
			instantiateClass: interpreterProxy classExternalAddress 
			indexableSize: 4.
	ptr := interpreterProxy firstIndexableField: oop.
	ptr at: 0 put: addr.
	interpreterProxy pop: 2.
	^interpreterProxy push: oop.

]

{ #category : #primitives }
FFIPlugin >> primitiveFFIDoubleAt [
	"Return a (signed or unsigned) n byte integer from the given byte offset."
	| byteOffset rcvr addr floatValue |
	<export: true>
	<inline: false>
	<var: #floatValue type: #double>
	byteOffset := interpreterProxy stackIntegerValue: 0.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^0].
	addr := self ffiAddressOf: rcvr startingAt: byteOffset size: 8.
	interpreterProxy failed ifTrue:[^0].
	self mem: (self addressOf: floatValue) cp: addr y: (self sizeof: floatValue).
	interpreterProxy pop: 2.
	^interpreterProxy pushFloat: floatValue

]

{ #category : #primitives }
FFIPlugin >> primitiveFFIDoubleAtPut [
	"Return a (signed or unsigned) n byte integer from the given byte offset."
	| byteOffset rcvr addr floatValue floatOop |
	<export: true>
	<inline: false>
	<var: #floatValue type: #double>
	floatOop := interpreterProxy stackValue: 0.
	(interpreterProxy isIntegerObject: floatOop)
		ifTrue:[floatValue := self cCoerce: (interpreterProxy integerValueOf: floatOop) to:'double']
		ifFalse:[floatValue := self cCoerce: (interpreterProxy floatValueOf: floatOop) to:'double'].
	byteOffset := interpreterProxy stackIntegerValue: 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:[^0].
	addr := self ffiAddressOf: rcvr startingAt: byteOffset size: 8.
	interpreterProxy failed ifTrue:[^0].
	self mem: addr cp: (self addressOf: floatValue) y: (self sizeof: floatValue).
	interpreterProxy pop: 3.
	^interpreterProxy push: floatOop
]

{ #category : #primitives }
FFIPlugin >> primitiveFFIFloatAt [
	"Return a (signed or unsigned) n byte integer from the given byte offset."
	| byteOffset rcvr addr floatValue |
	<export: true>
	<inline: false>
	<var: #floatValue type: #float>
	byteOffset := interpreterProxy stackIntegerValue: 0.
	rcvr := interpreterProxy stackObjectValue: 1.
	interpreterProxy failed ifTrue:[^0].
	addr := self ffiAddressOf: rcvr startingAt: byteOffset size: 4.
	interpreterProxy failed ifTrue:[^0].
	self mem: (self addressOf: floatValue) cp: addr y: (self sizeof: floatValue).
	interpreterProxy pop: 2.
	^interpreterProxy pushFloat: floatValue
]

{ #category : #primitives }
FFIPlugin >> primitiveFFIFloatAtPut [
	"Return a (signed or unsigned) n byte integer from the given byte offset."
	| byteOffset rcvr addr floatValue floatOop |
	<export: true>
	<inline: false>
	<var: #floatValue type: #float>
	floatOop := interpreterProxy stackValue: 0.
	(interpreterProxy isIntegerObject: floatOop)
		ifTrue:[floatValue := self cCoerce: (interpreterProxy integerValueOf: floatOop) to:'float']
		ifFalse:[floatValue := self cCoerce: (interpreterProxy floatValueOf: floatOop) to:'float'].
	byteOffset := interpreterProxy stackIntegerValue: 1.
	rcvr := interpreterProxy stackObjectValue: 2.
	interpreterProxy failed ifTrue:[^0].
	addr := self ffiAddressOf: rcvr startingAt: byteOffset size: 4.
	interpreterProxy failed ifTrue:[^0].
	self mem: addr cp: (self addressOf: floatValue) y: (self sizeof: floatValue).
	interpreterProxy pop: 3.
	^interpreterProxy push: floatOop
]

{ #category : #primitives }
FFIPlugin >> primitiveFFIFree [
	"Primitive. Free the object pointed to on the external heap."
	| addr oop ptr |
	<export: true>
	<inline: false>
	<var: #ptr type:'int *'>
	oop := interpreterProxy stackObjectValue: 0.
	interpreterProxy failed ifTrue:[^nil].
	(interpreterProxy fetchClassOf: oop) = (interpreterProxy classExternalAddress)
		ifFalse:[^interpreterProxy primitiveFail].
	(interpreterProxy byteSizeOf: oop) = 4
		ifFalse:[^interpreterProxy primitiveFail].
	ptr := interpreterProxy firstIndexableField: oop.
	addr := ptr at: 0.
	"Don't you dare to free Squeak's memory!"
	(addr = 0 or:[interpreterProxy isInMemory: addr])
		ifTrue:[^interpreterProxy primitiveFail].
	self ffiFree: addr.
	^ptr at: 0 put: 0. "cleanup"

]

{ #category : #primitives }
FFIPlugin >> primitiveFFIGetLastError [
	"Primitive. Return the error code from a failed call to the foreign function interface."
	<export: true>
	<inline: false>
	interpreterProxy pop: 1.
	^interpreterProxy pushInteger: self ffiGetLastError.
]

{ #category : #primitives }
FFIPlugin >> primitiveFFIIntegerAt [
	"Return a (signed or unsigned) n byte integer from the given byte offset."
	| isSigned byteSize byteOffset rcvr addr value mask |
	<export: true>
	<inline: false>
	isSigned := interpreterProxy booleanValueOf: (interpreterProxy stackValue: 0).
	byteSize := interpreterProxy stackIntegerValue: 1.
	byteOffset := interpreterProxy stackIntegerValue: 2.
	rcvr := interpreterProxy stackObjectValue: 3.
	interpreterProxy failed ifTrue:[^0].
	(byteOffset > 0 and:[byteSize = 1 or:[byteSize = 2 or:[byteSize = 4]]])
		ifFalse:[^interpreterProxy primitiveFail].
	addr := self ffiAddressOf: rcvr startingAt: byteOffset size: byteSize.
	interpreterProxy failed ifTrue:[^0].
	byteSize < 4 ifTrue:[
		"short/byte"
		byteSize = 1 
			ifTrue:[value := interpreterProxy byteAt: addr]
			ifFalse:[	value := self cCode: '*((unsigned short int *) addr)' 
								inSmalltalk: [interpreterProxy shortAt: addr]].
		isSigned ifTrue:["sign extend value"
			mask := 1 << (byteSize * 8 - 1).
			value := (value bitAnd: mask-1) - (value bitAnd: mask)].
		"note: byte/short never exceed SmallInteger range"
		value := interpreterProxy integerObjectOf: value.
	] ifFalse:[
		"general 32 bit integer"
		value := interpreterProxy longAt: addr.
		isSigned
			ifTrue:[value := interpreterProxy signed32BitIntegerFor: value]
			ifFalse:[value := interpreterProxy positive32BitIntegerFor: value].
	].
	interpreterProxy pop: 4.
	^interpreterProxy push: value

]

{ #category : #primitives }
FFIPlugin >> primitiveFFIIntegerAtPut [
	"Store a (signed or unsigned) n byte integer at the given byte offset."
	| isSigned byteSize byteOffset rcvr addr value max valueOop |
	<export: true>
	<inline: false>
	isSigned := interpreterProxy booleanValueOf: (interpreterProxy stackValue: 0).
	byteSize := interpreterProxy stackIntegerValue: 1.
	valueOop := interpreterProxy stackValue: 2.
	byteOffset := interpreterProxy stackIntegerValue: 3.
	rcvr := interpreterProxy stackObjectValue: 4.
	interpreterProxy failed ifTrue:[^0].
	(byteOffset > 0 and:[byteSize = 1 or:[byteSize = 2 or:[byteSize = 4]]])
		ifFalse:[^interpreterProxy primitiveFail].
	addr := self ffiAddressOf: rcvr startingAt: byteOffset size: byteSize.
	interpreterProxy failed ifTrue:[^0].
	isSigned 
		ifTrue:[value := interpreterProxy signed32BitValueOf: valueOop]
		ifFalse:[value := interpreterProxy positive32BitValueOf: valueOop].
	interpreterProxy failed ifTrue:[^0].
	byteSize < 4 ifTrue:[
		isSigned ifTrue:[
			max := 1 << (8 * byteSize - 1).
			value >= max ifTrue:[^interpreterProxy primitiveFail].
			value < (0 - max) ifTrue:[^interpreterProxy primitiveFail].
		] ifFalse:[
			value >= (1 << (8*byteSize)) ifTrue:[^interpreterProxy primitiveFail].
		].
		"short/byte"
		byteSize = 1 
			ifTrue:[interpreterProxy byteAt: addr put: value]
			ifFalse:[	self cCode: '*((short int *) addr) = value' 
						inSmalltalk: [interpreterProxy shortAt: addr put: value]].
	] ifFalse:[interpreterProxy longAt: addr put: value].
	interpreterProxy pop: 5.
	^interpreterProxy push: valueOop.
]

{ #category : #primitives }
FFIPlugin >> primitiveForceLoad [
	"Primitive. Force loading the receiver (an instance of ExternalLibrary)."
	| rcvr theClass moduleHandlePtr moduleHandle ffiModuleName moduleLength ptr |
	<export: true>
	<inline: false>
	<var: #ptr type:'int *'>
	self ffiSetLastError: FFIErrorGenericError. "educated guess if we fail silently"
	interpreterProxy methodArgumentCount = 0
		ifFalse:[^interpreterProxy primitiveFail].
	rcvr := interpreterProxy stackValue: 0.
	theClass := interpreterProxy fetchClassOf: rcvr.
	(interpreterProxy includesBehavior: theClass 
			ThatOf: interpreterProxy classExternalLibrary) 
				ifFalse:[^self ffiFail: FFIErrorBadExternalLibrary].
	moduleHandlePtr := interpreterProxy fetchPointer: 0 ofObject: rcvr.
	moduleHandle := self ffiContentsOfHandle: moduleHandlePtr errCode: FFIErrorBadExternalLibrary.
	interpreterProxy failed ifTrue:[^0].
	ffiModuleName := interpreterProxy fetchPointer: 1 ofObject: rcvr.
	(interpreterProxy isBytes: ffiModuleName) 
		ifFalse:[^self ffiFail: FFIErrorBadExternalLibrary].
	moduleLength := interpreterProxy byteSizeOf: ffiModuleName.
	moduleHandle := interpreterProxy ioLoadModule: (self cCoerce: (interpreterProxy firstIndexableField: ffiModuleName) to:'int') OfLength: moduleLength.
	interpreterProxy failed ifTrue:[^self ffiFail: FFIErrorModuleNotFound]. "failed"
	"and store back"
	ptr := interpreterProxy firstIndexableField: moduleHandlePtr.
	ptr at: 0 put: moduleHandle.
	^0 "done"
]

{ #category : #primitives }
FFIPlugin >> primitiveLogCallsTo [
	"Enable logging of FFI calls by providing it with a log file name."
	| logFile ok |
	<export: true>
	interpreterProxy methodArgumentCount = 1 
		ifFalse:[^interpreterProxy primitiveFail].
	logFile := interpreterProxy stackObjectValue: 0.
	logFile == interpreterProxy nilObject ifTrue:[ "disable logging"
		ok := self ffiLogFileName: nil OfLength: 0.
		ok ifFalse:[^interpreterProxy primitiveFail].
		ffiLogEnabled := false.
	] ifFalse:[ "enable logging"
		(interpreterProxy isBytes: logFile) ifFalse:[^interpreterProxy primitiveFail].
		ok := self ffiLogFileName: (interpreterProxy firstIndexableField: logFile)
					OfLength: (interpreterProxy byteSizeOf: logFile).
		ok ifFalse:[^interpreterProxy primitiveFail].
		ffiLogEnabled := true.
	].
	^interpreterProxy pop: 1. "pop arg; return rcvr"

]

{ #category : #'primitives - surfaces' }
FFIPlugin >> primitiveSetManualSurfacePointer [
	"Create a 'manual surface' data-structure.  See the ExternalForm class in the FFI package for example usage."
	"arguments: name(type, stack offset)
		surfaceID(Integer, 1)
		ptr(uint32, 0)"
	| surfaceID ptr result |
	<export: true>
	<var: #ptr type: #'unsigned int'>
	
	interpreterProxy methodArgumentCount == 2 ifFalse: [^interpreterProxy primitiveFail].
	surfaceID := interpreterProxy stackIntegerValue: 1.
	ptr := interpreterProxy positive32BitValueOf: (interpreterProxy stackValue: 0).
	interpreterProxy failed ifTrue: [^nil].

	self touch: surfaceID; touch: ptr.
	
	result := self cCode: 'setManualSurfacePointer(surfaceID, (void*)ptr)'.
	result = 0 ifTrue: [^interpreterProxy primitiveFail].
	^interpreterProxy pop: 2
	
]
