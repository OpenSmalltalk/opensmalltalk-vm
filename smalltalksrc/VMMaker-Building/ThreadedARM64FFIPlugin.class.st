"
A ThreadedARM64FFIPlugin is for the 64-bit ARM ABI.  It typically has 8 integer registers

Instance Variables

"
Class {
	#name : #ThreadedARM64FFIPlugin,
	#superclass : #ThreadedARMFFIPlugin,
	#category : #'VMMaker-Plugins-FFI'
}

{ #category : #translation }
ThreadedARM64FFIPlugin class >> identifyingPredefinedMacros [
	^#('__ARM_ARCH_ISA_A64' '__aarch64__' '__arm64__' 'ARM64')
]

{ #category : #'class initialization' }
ThreadedARM64FFIPlugin class >> initialize [
	super initialize.
	NumIntRegArgs     := 8.
	NumFloatRegArgs := 16
]

{ #category : #translation }
ThreadedARM64FFIPlugin class >> moduleName [
	^'ARM64FFIPlugin'
]

{ #category : #'callout support' }
ThreadedARM64FFIPlugin >> ffiCalloutTo: procAddr SpecOnStack: specOnStack in: calloutState [
	<var: #procAddr type: #'void *'>
	<var: #calloutState type: #'CalloutState *'>
	<var: #loadFloatRegs declareC: 'extern void loadFloatRegs(double, double, double, double, double, double, double, double)'>
	"Go out, call this guy and create the return value.  This *must* be inlined because of
	 the alloca of the outgoing stack frame in ffiCall:WithFlags:NumArgs:Args:AndTypes:"
	| myThreadIndex atomicType floatRet intRet |
	<var: #floatRet type: #double>
	<var: #intRet type: #usqLong>
	<inline: true>
	myThreadIndex := interpreterProxy disownVM: (self disownFlagsFor: calloutState).

	calloutState floatRegisterIndex > 0 ifTrue:
		[self loadFloatRegs:
			   ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 0)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 2)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 4)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 6)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 8)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 10)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 12)) to: #'double *') at: 0)
			_: ((self cCoerceSimple: (self addressOf: (calloutState floatRegisters at: 14)) to: #'double *') at: 0)].

	(self allocaLiesSoSetSpBeforeCall or: [self mustAlignStack]) ifTrue:
		[self setsp: calloutState argVector].

	atomicType := self atomicTypeOf: calloutState ffiRetHeader.
	(atomicType >> 1) = (FFITypeSingleFloat >> 1) ifTrue:
		[atomicType = FFITypeSingleFloat
			ifTrue:
				[floatRet := self 
					dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'float (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)')
					with: (calloutState integerRegisters at: 0)
					with: (calloutState integerRegisters at: 1)
					with: (calloutState integerRegisters at: 2)
					with: (calloutState integerRegisters at: 3)
					with: (calloutState integerRegisters at: 4)
					with: (calloutState integerRegisters at: 5)
					with: (calloutState integerRegisters at: 6)
					with: (calloutState integerRegisters at: 7)]
			ifFalse: "atomicType = FFITypeDoubleFloat"
				[floatRet := self 
					dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'double (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)')
					with: (calloutState integerRegisters at: 0)
					with: (calloutState integerRegisters at: 1)
					with: (calloutState integerRegisters at: 2)
					with: (calloutState integerRegisters at: 3)
					with: (calloutState integerRegisters at: 4)
					with: (calloutState integerRegisters at: 5)
					with: (calloutState integerRegisters at: 6)
					with: (calloutState integerRegisters at: 7)].

		 "undo any callee argument pops because it may confuse stack management with the alloca."
		 (self isCalleePopsConvention: calloutState callFlags) ifTrue:
			[self setsp: calloutState argVector].
		 interpreterProxy ownVM: myThreadIndex.

		 ^interpreterProxy floatObjectOf: floatRet].

	intRet := self 
				dispatchFunctionPointer: (self cCoerceSimple: procAddr to: 'usqIntptr_t (*)(sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t, sqIntptr_t)')
				with: (calloutState integerRegisters at: 0)
				with: (calloutState integerRegisters at: 1)
				with: (calloutState integerRegisters at: 2)
				with: (calloutState integerRegisters at: 3)
				with: (calloutState integerRegisters at: 4)
				with: (calloutState integerRegisters at: 5)
				with: (calloutState integerRegisters at: 6)
				with: (calloutState integerRegisters at: 7).

	"undo any callee argument pops because it may confuse stack management with the alloca."
	(self isCalleePopsConvention: calloutState callFlags) ifTrue:
		[self setsp: calloutState argVector].
	interpreterProxy ownVM: myThreadIndex.

	(calloutState ffiRetHeader anyMask: FFIFlagPointer+FFIFlagStructure) ifTrue:
		["Note: Order is important here since FFIFlagPointer + FFIFlagStructure is used to represent
		 'typedef void* VoidPointer' and VoidPointer must be returned as pointer *not* as struct."
		 (calloutState ffiRetHeader anyMask: FFIFlagPointer) ifTrue:
			[^self ffiReturnPointer: intRet ofType: (self ffiReturnType: specOnStack) in: calloutState].
		 ^self ffiReturnStruct: intRet ofType: (self ffiReturnType: specOnStack) in: calloutState].
	
	^self ffiCreateIntegralResultOop: intRet ofAtomicType: atomicType in: calloutState
]

{ #category : #'simulation support' }
ThreadedARM64FFIPlugin >> wordSize [

	^ 8  "arm64/aarch64"
]
