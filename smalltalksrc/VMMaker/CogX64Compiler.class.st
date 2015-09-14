"
I generate x64 (x86-64) instructions from CogAbstractInstructions.  For reference see
1. IA-32 Intel® Architecture Software Developer's Manual Volume 2A: Instruction Set Reference, A-M
2. IA-32 Intel® Architecture Software Developer's Manual Volume 2A: Instruction Set Reference, N-Z
	http://www.intel.com/products/processor/manuals/
or
AMD64 Architecture Programmer's Manual Volume 3: General-Purpose and System Instructions
AMD64 Architecture Programmer's Manual Volume 4: 128-bit Media Instructions
AMD64 Architecture Programmer's Manual Volume 5: 64-bit Media and x87 Floating Point Instructions
	http://developer.amd.com/resources/documentation-articles/developer-guides-manuals/
(® is supposed to be the Unicode ""registered  sign"").
"
Class {
	#name : #CogX64Compiler,
	#superclass : #CogAbstractInstruction,
	#category : #'VMMaker-JIT'
}
