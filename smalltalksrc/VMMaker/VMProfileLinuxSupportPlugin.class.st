"
This class provides support for the VMProfiler on Linux (at least linux versions that provide dl_iterate_phdr).  This support is for reading symbols from the executable.  We can use the OS's nm command to list symbols in the VM executable and loaded libraries.  To do this we need to know what libraries are loaded, not simply which libraries are linked against, since some libraries are loaded dynamically, and for each loaded library what the vm address relocation, if any, is for the loaded library.  

Further, we need to know the actual addresses in memory of symbols in the program and in memory.  Since the OS may be using address randomization we cannot assume that the addresses answered by nm for symbols in the program and/or libraries match the addresses of the same symbols in memory.  Instead we must correlate.  dlsym can be used to look up symbols in loaded dynamic load libraries, but it does _not_ answer the addresses of symbols in the main program.  Back in the day nlist could be used to do this, but it is no more.  Instead this module contains a reference to interpret and answers its address ia a primitive (alas this means the plugin must be internal, but it's extremely small, and the VM links against libdl.so anyway).  Any address space shift will therefore be the difference between nm's output for interpret and the primitive's value.  We can similarly compute the address shift for libraries by using dlsym to lookup a symbol in a library and comparing it to nm's output for the library.


The primitive primitiveExecutableModules returns the names of the executable and the loaded libraries.
"
Class {
	#name : #VMProfileLinuxSupportPlugin,
	#superclass : #InterpreterPlugin,
	#instVars : [
		'numModules',
		'primErr'
	],
	#category : 'VMMaker-Plugins'
}

{ #category : #translation }
VMProfileLinuxSupportPlugin class >> declareHeaderFilesIn: cg [

	cg
		addHeaderFile: '<limits.h>';
		addHeaderFile: '#ifndef _GNU_SOURCE\# define _GNU_SOURCE\#endif\#include <link.h>' withCRs
]

{ #category : #'iteration callbacks' }
VMProfileLinuxSupportPlugin >> count: info num: size modules: ignored [
	<returnTypeC: #int>
	<var: #info type: #'struct dl_phdr_info *'>
	<var: #size type: #'size_t'>
	<var: #ignored type: #'void *'>
	numModules := numModules + 1.
	^0
]

{ #category : #primitives }
VMProfileLinuxSupportPlugin >> primitiveDLSymInLibrary [
	"Answer the address of the symbol whose name is the first argument
	 in the library whose name is the second argument, or nil if none."
	| nameObj symName libName lib sz addr ok |
	<export: true>
	<var: #symName type: #'char *'>
	<var: #libName type: #'char *'>
	<var: #lib type: #'void *'>
	<var: #addr type: #'void *'>
	nameObj := interpreterProxy stackValue: 0.
	(interpreterProxy isBytes: nameObj) ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	sz := interpreterProxy byteSizeOf: nameObj.
	libName := self malloc: sz+1.
	self st: libName rn: (interpreterProxy firstIndexableField: nameObj) cpy: sz.
	libName at: sz put: 0.
	nameObj := interpreterProxy stackValue: 1.
	(interpreterProxy isBytes: nameObj) ifFalse:
		[self free: libName.
		 ^interpreterProxy primitiveFailFor: PrimErrBadArgument].
	sz := interpreterProxy byteSizeOf: nameObj.
	symName := self malloc: sz+1.
	self st: symName rn: (interpreterProxy firstIndexableField: nameObj) cpy: sz.
	symName at: sz put: 0.
	lib := self dl: libName open: (#'RTLD_LAZY' bitOr: #'RTLD_NODELETE').
	lib ifNil:
		[self free: libName; free: symName.
		 ^interpreterProxy primitiveFailFor: PrimErrInappropriate].
	self dlerror. "clear dlerror"
	addr := self dl: lib sym: symName.
	ok := self dlerror isNil.
	self free: symName.
	self free: libName.
	self dlclose: lib.
	ok ifFalse:
		[^interpreterProxy primitiveFailFor: PrimErrNotFound].
	^interpreterProxy methodReturnValue: (interpreterProxy positiveMachineIntegerFor: addr asUnsignedLong)
]

{ #category : #primitives }
VMProfileLinuxSupportPlugin >> primitiveExecutableModules [
	"Answer an Array of pairs of strings for executable modules (the VM executable and loaded libraries).
	 The first element in each pair is the filename of the module.  The second element is either nil or
	 the symlink's target, if the filename is a symlink."
	<export: true>
	| resultObj |
	numModules := 0.
	self cCode: 'dl_iterate_phdr(countnummodules,0)' inSmalltalk: [0].
	resultObj := interpreterProxy
					instantiateClass: interpreterProxy classArray
					indexableSize: numModules - 1 * 2. "skip the fake linux-gate.so.1"
	resultObj = 0 ifTrue:
		[^interpreterProxy primitiveFailFor: PrimErrNoMemory].
	interpreterProxy pushRemappableOop: resultObj.
	primErr := numModules := 0.
	self cCode: 'dl_iterate_phdr(reapmodulesymlinks,0)' inSmalltalk: [0].
	resultObj := interpreterProxy popRemappableOop.
	primErr ~= 0 ifTrue:
		[^interpreterProxy primitiveFailFor: primErr].
	^interpreterProxy methodReturnValue: resultObj
]

{ #category : #primitives }
VMProfileLinuxSupportPlugin >> primitiveInterpretAddress [
	"Answer the address of the interpret routine."
	<export: true>
	| interpret |
	<var: #interpret declareC: 'extern void interpret()'>
	^interpreterProxy methodReturnValue: (interpreterProxy positiveMachineIntegerFor: interpret asUnsignedLong)
]

{ #category : #'iteration callbacks' }
VMProfileLinuxSupportPlugin >> reap: info module: size names: ignored [
	<returnTypeC: #int>
	| elfModuleName len moduleNameObj GetAttributeString |
	<var: #info type: #'struct dl_phdr_info *'>
	<var: 'elfModuleName' type: #'const char *'>
	<var: #GetAttributeString declareC: 'extern char *GetAttributeString(sqInt)'>
	<var: #size type: #'size_t'>
	<var: #ignored type: #'void *'>
	self touch: GetAttributeString.
	elfModuleName := self cCode: 'numModules ? info->dlpi_name : GetAttributeString(0)'.
	(elfModuleName isNil
	 or: [(len := self strlen: elfModuleName) = 0]) ifTrue:
		[^0]. "skip the fake linux-gate.so.1"
	moduleNameObj := interpreterProxy
							instantiateClass: interpreterProxy classString
							indexableSize: len.
	moduleNameObj = 0 ifTrue:
		[primErr := PrimErrNoMemory.
		 ^1]. "stop iteration"
	self st: (interpreterProxy arrayValueOf: moduleNameObj)
		rn: elfModuleName
		cpy: len. "(char *)strncpy()"
	interpreterProxy
		storePointer: numModules
		ofObject: interpreterProxy topRemappableOop
		withValue: moduleNameObj.
	numModules := numModules + 1.
	^0
]

{ #category : #'iteration callbacks' }
VMProfileLinuxSupportPlugin >> reap: info module: size symlinks: ignored [
	"like reap:module:names:, but follows symlinks"
	<returnTypeC: #int>
	| elfModuleName len moduleNameObj GetAttributeString symLinkBuf |
	<var: #info type: #'struct dl_phdr_info *'>
	<var: 'elfModuleName' type: #'const char *'>
	<var: #GetAttributeString declareC: 'extern char *GetAttributeString(sqInt)'>
	<var: #symLinkBuf declareC: 'char symLinkBuf[PATH_MAX]'>
	<var: #size type: #'size_t'>
	<var: #ignored type: #'void *'>
	self touch: GetAttributeString.
	elfModuleName := self cCode: 'numModules ? info->dlpi_name : GetAttributeString(0)'.
	(elfModuleName isNil
	 or: [(len := self strlen: elfModuleName) = 0]) ifTrue:
		[^0]. "skip the fake linux-gate.so.1"
	moduleNameObj := interpreterProxy
							instantiateClass: interpreterProxy classString
							indexableSize: len.
	moduleNameObj = 0 ifTrue:
		[primErr := PrimErrNoMemory.
		 ^1]. "stop iteration"
	self st: (interpreterProxy arrayValueOf: moduleNameObj)
		rn: elfModuleName
		cpy: len. "(char *)strncpy()"
	interpreterProxy
		storePointer: numModules
		ofObject: interpreterProxy topRemappableOop
		withValue: moduleNameObj.
	"now dereference the symlink, if it exists"
	self str: symLinkBuf cpy: elfModuleName.
	(len := self read: elfModuleName li: symLinkBuf nk: #'PATH_MAX') > 0
		ifTrue:
			[moduleNameObj := interpreterProxy
									instantiateClass: interpreterProxy classString
									indexableSize: len.
			 moduleNameObj = 0 ifTrue:
				[primErr := PrimErrNoMemory.
				 ^1]. "stop iteration"
			 self st: (interpreterProxy arrayValueOf: moduleNameObj)
				rn: symLinkBuf
				cpy: len. "(char *)strncpy()"
			 interpreterProxy
				storePointer: numModules + 1
				ofObject: interpreterProxy topRemappableOop
				withValue: moduleNameObj]
		ifFalse:
			[interpreterProxy
				storePointer: numModules + 1
				ofObject: interpreterProxy topRemappableOop
				withValue: interpreterProxy nilObject].
	numModules := numModules + 2.
	^0
]
