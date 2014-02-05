Class {
	#name : #CogVMTests,
	#superclass : #TestCase,
	#category : #'Cog-Tests'
}

{ #category : #support }
CogVMTests >> recurse [
	self recurse
]

{ #category : #support }
CogVMTests >> runningOnCogit [
	"CogVMTests new runningOnCogit"
	^(1 to: 3) anySatisfy: [:each| thisContext xrayIsExecutingMachineCode]
]

{ #category : #tests }
CogVMTests >> testMultiplicativeOperators [
	"CogVMTests new setUp testMultiplicativeOperators"
	self runningOnCogit ifTrue:
		[thisContext xrayIsExecutingMachineCode ifFalse:
			[^self testMultiplicativeOperators]].
	1 to: 3 do: "Running 3 times should ensure all operators are compiled to machine code"
		[:ignored| | values |
		self assert: (1 / 2 literalEqual: (Fraction numerator: 1 denominator: 2)).
		self assert: 1 // 2 == 0.
		self assert: (1 quo: 2) == 0.
		self assert: 3 * 4 == 12.

		self assert: 65536 / 2 == 32768.
		self assert: 65536 // 2 == 32768.
		self assert: (65536 quo: 2) == 32768.
		self assert: 65536 * 2 == 131072.
		#(1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536
		   131072 262144 524288 1048576 2097152 4194304 8388608 16777216 33554432
		   67108864 134217728 268435456 536870912 1073741824 2147483648 4294967296) withIndexDo:
			[:value :index| | power | "test that integer overflow is detected in multiplication"
			power := index - 1.
			self assert: value * value = (2 raisedTo: power + power)].

		self assert: SmallInteger minVal / -1 = (SmallInteger maxVal + 1).
		self assert: SmallInteger minVal // -1 = (SmallInteger maxVal + 1).
		self assert: (SmallInteger minVal quo: -1) = (SmallInteger maxVal + 1).
		self assert: (SmallInteger minVal \\ -1) = 0.

		values := Integer primesUpTo: 1000.
		values := (values reverse collect: [:ea| ea negated]), values.
		values do:
			[:dividend|
			values do:
				[:divisor|
				self assert: (dividend quo: divisor) * divisor + (dividend rem: divisor) = dividend.
				self assert: (dividend // divisor) * divisor + (dividend \\ divisor) = dividend]]]
]

{ #category : #tests }
CogVMTests >> testPCAccessForActivation [
	"self new testPCAccessForActivation"
	| runningOnCogit theProcess block run pc executingMachineCode scanner blockCount |
	runningOnCogit := self runningOnCogit.
	run := true.
	theProcess := Processor activeProcess.
	"Fork a process that will sample the pc of the following recursive block."
	[(Delay forMilliseconds: 1) wait.
	 pc := theProcess suspendedContext pc.
	 executingMachineCode := theProcess suspendedContext xrayIsExecutingMachineCode.
	 run := false] forkAt: Processor userInterruptPriority.
	"The only suspension point in this block is on activation (assuming
	 ifTrue: is inlined) so its pc must be the first bytecode in the block."
	block := [run ifTrue: [block value]].
	block value.
	"Find the first bytecode of the second block in this method."
	blockCount := 0.
	(scanner := InstructionStream on: thisContext method)
		scanFor:
			[:b| blockCount = 2 or: [b == 143 and: [blockCount := blockCount + 1. false]]].
	self assert: pc = scanner pc.
	self assert: executingMachineCode = runningOnCogit.
	"Fork a process that will use recurse: to infinitely recurse.
	 The only suspension point in this call is on activation (assuming
	 ifTrue: is inlined) so its pc must be the first bytecode in the method."
	theProcess := [self recurse] forkAt: Processor activePriority - 1.
	(Delay forMilliseconds: 1) wait.
	pc := theProcess suspendedContext pc.
	executingMachineCode := theProcess suspendedContext xrayIsExecutingMachineCode.
	theProcess terminate.
	self assert: pc = (self class compiledMethodAt: #recurse) initialPC.
	self assert: executingMachineCode = runningOnCogit
]

{ #category : #tests }
CogVMTests >> testPCAccessForSends [
	"self new testPCAccessForSends"
	| runningOnCogit |
	runningOnCogit := self runningOnCogit.
	#("Method-level pc maping"
		( '{ thisContext pc.
			thisContext xrayIsExecutingMachineCode.
			thisContext method }'
			pc)
		( '{ thisContext perform: #perform:withArguments: with: #pc with: Array new.
			thisContext xrayIsExecutingMachineCode.
			thisContext method }'
			perform:with:with: )
		( '{ [:ctxt :msg :ign1| ctxt perform: msg] value: thisContext value: #pc value: nil.
			thisContext xrayIsExecutingMachineCode.
			thisContext method }'
			value:value:value: )
	   "Block-level pc maping"
		( '[:method|
			{ thisContext pc.
			  thisContext xrayIsExecutingMachineCode.
			  method } ] value: thisContext method'
			pc)
		( '[:method|
			{ (thisContext perform: #perform:withArguments: with: #pc with: Array new).
			  thisContext xrayIsExecutingMachineCode.
			  method } ] value: thisContext method'
			perform:with:with:)
		( '[:method|
			{ [:ctxt :msg :ign1| ctxt perform: msg] value: thisContext value: #pc value: nil.
			  thisContext xrayIsExecutingMachineCode.
			  method } ] value: thisContext method'
			value:value:value: ) ) do:
		[:case|
		 [:actualPc :executingMachineCode :method| | flag scanner expectedPc |
		  flag := false.
		  (scanner := InstructionStream on: method)
			scanFor:
				[:b| flag or: [flag := scanner selectorToSendOrSelf == case second. false]].
		  expectedPc := scanner pc.
		  self assert: actualPc = expectedPc.
		  self assert: executingMachineCode = runningOnCogit]
			valueWithArguments: (Compiler evaluate: case first logged: false)]
]
