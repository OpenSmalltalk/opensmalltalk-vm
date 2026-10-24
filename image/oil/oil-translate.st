"Oil Milestone 2: Slang translation smoke test.  Translates OilBytecodeScanner + OilCompiler (+ the OilBytecodeDescriptor struct)
 to C with VMMaker's CCodeGenerator, standalone (not yet wired into the Cogit), to check that Pass 1 is valid Slang."
| dir |
Utilities authorInitials: 'cb'.
dir := Smalltalk at: #OilSourceDir ifAbsentPut: ['/usr/local/google/home/clementbera/.gemini/jetski/brain/d1466531-7c6e-4182-90d9-4bed24e00db9/scratch/osvm/image/oil/'].
#('OilConstants.st' 'OilBytecodeScanner.st' 'OilCompiler.st' 'OilCompilerBackend.st' 'OilCompilerPass2.st' 'OilSimulation.st') do:
	[:f | (FileStream readOnlyFileNamed: dir, f) fileIn]!

| dir vmm cg out proc ctx n done all |
dir := Smalltalk at: #OilSourceDir.
out := FileStream forceNewFileNamed: dir, 'translate-result.txt'.
done := false.
proc := [[[[vmm := (VMMaker forPlatform: 'Cross')
		interpreterClass: CoInterpreter;
		options: #(ObjectMemory Spur64BitCoMemoryManager MULTIPLEBYTECODESETS true);
		yourself.
 cg := vmm createCogitCodeGenerator.
 cg vmClass: StackToRegisterMappingCogit. "for generator hooks (isStackAccessor: etc.)"
 cg addClass: OilBytecodeScanner.
 cg addClass: OilCompiler.
 cg addStructClasses: {OilBytecodeDescriptor}.
 cg inferTypesForImplicitlyTypedVariablesAndMethods.
 cg storeCodeOnFile: dir, 'oil-pass1.c' doInlining: true.
 out nextPutAll: 'TRANSLATION OK'; cr]
	on: Error
	do: [:e | out nextPutAll: 'TRANSLATION ERROR: '; nextPutAll: e description; cr; nextPutAll: e signalerContext longStack; cr]]
	on: Warning do: [:w | w resume: true]] valueSupplyingAnswer: true.
 done := true] forkAt: Processor userBackgroundPriority.
n := 0.
[done or: [n >= 25]] whileFalse: [(Delay forSeconds: 1) wait. n := n + 1].
done ifFalse:
	[out nextPutAll: 'TIMEOUT; stack:'; cr.
	 all := OrderedCollection new.
	 ctx := proc suspendedContext.
	 [ctx notNil] whileTrue: [all add: ctx. ctx := ctx sender].
	 out nextPutAll: 'depth '; print: all size; cr.
	 (all first: (all size min: 6)) do: [:c | out print: c; nextPutAll: '  node: '; nextPutAll: ([(c tempAt: 1) printString contractTo: 150] on: Error do: [:e | '?']); cr].
	 out nextPutAll: '...'; cr.
	 (all last: (all size min: 45)) do: [:c | out print: c; nextPutAll: '  arg1: '; nextPutAll: ([(c tempAt: 1) printString contractTo: 150] on: Error do: [:e | '?']); cr].
	 proc terminate].
out close!
