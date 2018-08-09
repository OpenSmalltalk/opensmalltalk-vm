"
This class provides support for the VMProfiler on MacOS X.  This support is for reading symbols from the executable.  We can use the OS's nm command to list symbols in the VM executable and loaded libraries.  To do this we need to know what libraries are loaded, not simply which libraries are linked against, since some libraries are loaded dynamically, and for each loaded library what the vm address relocation, if any, is for the loaded library.  The primitive primitiveExecutableModulesAndOffsets returns these as an array of pairs, module name to relocation.
"
Class {
	#name : #VMProfileMacSupportPlugin,
	#superclass : #InterpreterPlugin,
	#category : 'VMMaker-Plugins'
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
												ifFalse: [interpreterProxy positiveMachineIntegerFor: addr asUnsignedIntegerPtr])
]

{ #category : #primitives }
VMProfileMacSupportPlugin >> primitiveExecutableModulesAndOffsets [
	"Answer an Array of quads for executable modules (the VM executable
	 and loaded libraries).  Each quad is the module's name, its vm address
	 relocation in memory, the (unrelocated) start address, and the size."
	| nimages resultObj name valueObj nameObjData slide start size |
	<export: true>
	<var: #name type: 'const char *'>
	<var: #nameObjData type: #'char *'>
	<var: #h type: 'const struct mach_header *'>
	<var: #h64 type: 'const struct mach_header_64 *'>
	<var: #s64 type: 'const struct section_64 *'>
	<var: #s type: 'const struct section *'>
	<var: #start type: 'usqIntptr_t'>
	<var: #slide type: 'usqIntptr_t'>
	<var: #size type: 'usqIntptr_t'>
	self cppIf: #'MAC_OS_X_VERSION_MIN_REQUIRED' <= #'MAC_OS_X_VERSION_10_4'
		ifTrue: "_dyld_present was deprecated in 10.5"
			[(self cCode: '_dyld_present()' inSmalltalk: false) ifFalse:
				[^interpreterProxy primitiveFail]].
	nimages := self cCode: '_dyld_image_count()' inSmalltalk: 0.
	resultObj := interpreterProxy instantiateClass: interpreterProxy classArray indexableSize: nimages * 4.
	resultObj = 0 ifTrue:
		[^interpreterProxy primitiveFail].

	interpreterProxy pushRemappableOop: resultObj.
	0 to: nimages - 1 do:
		[:i|
		start := size := -1. "impossible start & size"
		name := self cCode: '_dyld_get_image_name(i)' inSmalltalk: 0.
		slide   := self cCode: '_dyld_get_image_vmaddr_slide(i)' inSmalltalk: 0.
		self cppIf: #'__x86_64__'
			ifTrue:
				[(self cCode: '(const struct mach_header_64 *)_dyld_get_image_header(i)' inSmalltalk: nil) ifNotNil:
					[:h64|
					 (self cCode: 'getsectbynamefromheader_64(h64,SEG_TEXT,SECT_TEXT)' inSmalltalk: nil) ifNotNil:
						[:s64|
						 start := self cCode: 's64->addr' inSmalltalk: 0.
						 size := self cCode: 's64->size' inSmalltalk: 0]]]
			ifFalse:
				[(self cCode: '_dyld_get_image_header(i)' inSmalltalk: nil) ifNotNil:
					[:h|
					 (self cCode: 'getsectbynamefromheader(h,SEG_TEXT,SECT_TEXT)' inSmalltalk: nil) ifNotNil:
						[:s|
						 start := self cCode: 's->addr' inSmalltalk: 0.
						 size := self cCode: 's->size' inSmalltalk: 0]]].

		valueObj := interpreterProxy
						instantiateClass: interpreterProxy classString
						indexableSize: (self strlen: name).
		interpreterProxy failed ifTrue:
			[interpreterProxy popRemappableOop.
			 ^interpreterProxy primitiveFail].
		interpreterProxy storePointer: i * 4 ofObject: interpreterProxy topRemappableOop withValue: valueObj.
		nameObjData := interpreterProxy arrayValueOf: valueObj.
		self mem: nameObjData cp: name y: (self strlen: name).

		valueObj := interpreterProxy signedMachineIntegerFor: slide.
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
