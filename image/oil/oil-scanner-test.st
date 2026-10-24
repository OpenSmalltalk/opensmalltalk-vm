"Oil Milestone 2: OilBytecodeScanner verification against the image's own InstructionStream decoder.
 Usage: run-st.sh <VMMaker image> oil-scanner-test.st  (with OIL_DIR pointing at the .st sources)"
| dir |
Utilities authorInitials: 'cb'.
dir := Smalltalk at: #OilSourceDir ifAbsentPut: ['/usr/local/google/home/clementbera/.gemini/jetski/brain/d1466531-7c6e-4182-90d9-4bed24e00db9/scratch/osvm/image/oil/'].
#('OilConstants.st' 'OilBytecodeScanner.st') do: [:f | (FileStream readOnlyFileNamed: dir, f) fileIn]!

| dir out methods checked errors check |
dir := Smalltalk at: #OilSourceDir.
out := FileStream forceNewFileNamed: (Smalltalk at: #OilResultFile ifAbsent: [dir, 'scanner-test-result.txt']).
errors := 0. checked := 0.
check := [:m | | scanner starts pcs ok |
	ok := true.
	starts := Set new.
	(InstructionStream on: m) in: [:s |
		[s pc <= m endPC] whileTrue: [starts add: s pc. s pc: (s nextPc: (m at: s pc))]].
	scanner := OilBytecodeScanner new.
	pcs := OrderedCollection new.
	scanner scanMethod: m do: [:d | | sel |
		pcs add: scanner instrPC.
		((starts includes: scanner instrPC) and: [(starts includes: scanner oilBcpc) and: [(scanner oilNextPC > m endPC) or: [starts includes: scanner oilNextPC]]]) ifFalse:
			[ok := false. out nextPutAll: 'BOUNDARY MISMATCH '; print: m; nextPutAll: ' pc '; print: scanner instrPC; cr].
		scanner oilTargetPC >= 0 ifTrue:
			[(starts includes: scanner oilTargetPC) ifFalse: [ok := false. out nextPutAll: 'BAD TARGET '; print: m; nextPutAll: ' pc '; print: scanner instrPC; cr]].
		(#(OilTagSend OilTagSendSuper OilTagSendSpecial) anySatisfy: [:t | scanner scannedTag = (OilConstants classPool at: t)]) ifTrue:
			[| expected ours |
			 ours := scanner scannedTag = (OilConstants classPool at: #OilTagSendSpecial)
				ifTrue: [Smalltalk specialSelectors at: scanner operand1 * 2 + 1]
				ifFalse: [m literalAt: scanner operand1 + 1].
			 expected := (InstructionStream new method: m pc: scanner instrPC) selectorToSendOrSelf.
			 (expected isSymbol not) ifTrue: [expected := (InstructionStream new method: m pc: scanner oilBcpc) selectorToSendOrSelf].
			 (ours == expected and: [ours numArgs = scanner operand2]) ifFalse:
				[ok := false. out nextPutAll: 'SEND MISMATCH '; print: m; nextPutAll: ' pc '; print: scanner instrPC; nextPutAll: ' ours '; print: ours; nextPutAll: '/'; print: scanner operand2; nextPutAll: ' expected '; print: expected; cr]]].
	(pcs isEmpty or: [ok]) ifFalse: [errors := errors + 1].
	checked := checked + 1].
methods := OrderedCollection new.
(Collection withAllSubclasses asArray, (Number withAllSubclasses asArray), {Object. Behavior. String. Symbol. CompiledMethod. Morph}) do: [:c |
	c selectorsDo: [:s | | m | m := c >> s. m isQuick ifFalse: [methods add: m]. m literalsDo: [:l | (l isKindOf: CompiledBlock) ifTrue: [methods add: l]]]].
methods do: [:m | check value: m].
out nextPutAll: 'SistaV1: checked '; print: checked; nextPutAll: ' compiled methods/blocks, errors '; print: errors; cr.
"Oil decodes SistaV1 only: every scanned method must use the alternate bytecode set"
out nextPutAll: 'non-SistaV1 methods scanned: '; print: (methods count: [:m | m signFlag not]); cr.
out close.!
