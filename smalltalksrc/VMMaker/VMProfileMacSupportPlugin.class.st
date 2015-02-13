"
This class provides support for the VMProfiler on MacOS X.  This support is for reading symbols from the executable.  We can use the OS's nm command to list symbols in the VM executable and loaded libraries.  To do this we need to know what libraries are loaded, not simply which libraries are linked against, since some libraries are loaded dynamically, and for each loaded library what the vm address relocation, if any, is for the loaded library.  The primitive primitiveExecutableModulesAndOffsets returns these as an array of pairs, module name to relocation.
"
Class {
	#name : #VMProfileMacSupportPlugin,
	#superclass : #InterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
VMProfileMacSupportPlugin class >> declareCVarsIn: aCCodeGen [
	aCCodeGen
		addHeaderFile: '<dlfcn.h>';
		addHeaderFile: '<mach-o/dyld.h>';
		addHeaderFile: '<mach-o/getsect.h>'
]

{ #category : #primitives }
VMProfileMacSupportPlugin >> primitiveDLSym [
	"Answer the address of the argument in the current process or nil if none."
	| nameObj name namePtr sz addr |
	<export: true>
	<var: #name type: #'char *'>
	<var: #namePtr type: #'char *'>
	<var: #addr type: #'void *'>
	nameObj := interpreterProxy stackValue: 0.
	(interpreterProxy isBytes: nameObj) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	sz := interpreterProxy byteSizeOf: nameObj.
	name := self malloc: sz+1.
	namePtr := interpreterProxy firstIndexableField: nameObj.
	0 to: sz-1 do:[:i| name at: i put: (namePtr at: i)].
	name at: sz put: 0.
	addr := self cCode: 'dlsym(RTLD_SELF,name)' inSmalltalk: [0].
	self free: name.
	^interpreterProxy methodReturnValue: (addr = 0
												ifTrue: [interpreterProxy nilObject]
												ifFalse: [interpreterProxy positiveMachineIntegerFor: addr asUnsignedLong])
]

{ #category : #primitives }
VMProfileMacSupportPlugin >> primitiveExecutableModulesAndOffsets [
	"Answer an Array of quads for executable modules (the VM executable
	 and loaded libraries).  Each quad is the module's name, its vm address
	 relocation in memory, the (unrelocated) start address, and the size."
	| present nimages resultObj name valueObj nameObjData slide start size h s |
	<export: true>
	<var: #name type: 'const char *'>
	<var: #nameObjData type: #'char *'>
	<var: #h type: 'const struct mach_header *'>
	<var: #s type: 'const struct section *'>
	<var: #start type: 'unsigned long'>
	<var: #size type: 'unsigned long'>
	present := self cCode: '_dyld_present()' inSmalltalk: [false].
	present ifFalse:
		[^interpreterProxy primitiveFail].
	nimages := self cCode: '_dyld_image_count()' inSmalltalk: [0].
	resultObj := interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: nimages * 4.
	resultObj = 0 ifTrue:
		[^interpreterProxy primitiveFail].

	interpreterProxy pushRemappableOop: resultObj.
	0 to: nimages - 1 do:
		[:i|
		start := size := -1. "impossible start & size"
		name := self cCode: '_dyld_get_image_name(i)' inSmalltalk: [0].
		slide   := self cCode: '_dyld_get_image_vmaddr_slide(i)' inSmalltalk: [0].
		h        := self cCode: '_dyld_get_image_header(i)' inSmalltalk: [0].
		h ~= nil ifTrue:
			[s := self cCode: 'getsectbynamefromheader(h,SEG_TEXT,SECT_TEXT)' inSmalltalk: [0].
			 s ~= nil ifTrue:
				[start := self cCode: 's->addr' inSmalltalk: [0].
				 size := self cCode: 's->size' inSmalltalk: [0]]].

		valueObj := interpreterProxy
						instantiateClass: interpreterProxy classString
						indexableSize: (self strlen: name).
		interpreterProxy failed ifTrue:
			[interpreterProxy popRemappableOop.
			 ^interpreterProxy primitiveFail].
		interpreterProxy storePointer: i * 4 ofObject: interpreterProxy topRemappableOop withValue: valueObj.
		nameObjData := interpreterProxy arrayValueOf: valueObj.
		self mem: nameObjData cp: name y: (self strlen: name).

		valueObj := interpreterProxy signed32BitIntegerFor: slide.
		interpreterProxy failed ifTrue:
			[interpreterProxy popRemappableOop.
			 ^interpreterProxy primitiveFail].
		interpreterProxy storePointer: i * 4 + 1 ofObject: interpreterProxy topRemappableOop withValue: valueObj.

		valueObj := interpreterProxy positiveMachineIntegerFor: start.
		interpreterProxy failed ifTrue:
			[interpreterProxy popRemappableOop.
			 ^interpreterProxy primitiveFail].
		interpreterProxy storePointer: i * 4 + 2 ofObject: interpreterProxy topRemappableOop withValue: valueObj.

		valueObj := interpreterProxy positiveMachineIntegerFor: size.
		interpreterProxy failed ifTrue:
			[interpreterProxy popRemappableOop.
			 ^interpreterProxy primitiveFail].
		interpreterProxy storePointer: i * 4 + 3 ofObject: interpreterProxy topRemappableOop withValue: valueObj].

	resultObj := interpreterProxy popRemappableOop.
	^interpreterProxy pop: 1 thenPush: resultObj
]
