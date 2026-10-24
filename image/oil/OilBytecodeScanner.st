VMStructType subclass: #OilBytecodeDescriptor
	instanceVariableNames: 'numBytes opcodeTag operandMode operandBase operandBias'
	classVariableNames: ''
	poolDictionaries: 'OilInstructionConstants OilConstants'
	category: 'VMMaker-JIT-Oil'!

!OilBytecodeDescriptor commentStamp: 'cb 10/24/2026 10:10' prior: 0!
I am an entry in Oil's bytecode dispatch table, oilGeneratorTable (256 entries, one per SistaV1 bytecode; Oil only compiles methods using the SistaV1 bytecode set).  Like Cogit's CogBytecodeDescriptor I let OilBytecodeScanner decode a bytecode in O(1) with zero allocation: one table lookup on oilByte0 gives the instruction length, its high level classification (opcodeTag) and how to extract its operands (operandMode, operandBase, operandBias).

numBytes			<Integer> instruction length (1..3)
opcodeTag			<Integer> one of the OilTag* constants
operandMode		<Integer> one of the OilMode* constants
operandBase		<Integer> table index of the first bytecode of my range (for range encoded operands)
operandBias		<Integer> constant added to range encoded operands (e.g. 1 for short jumps), the fixed arity of literal sends, or the kind of extension (0 = A, 1 = B)!

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
numBytes
	^numBytes! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
numBytes: anInteger
	^numBytes := anInteger! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
opcodeTag
	^opcodeTag! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
opcodeTag: anInteger
	^opcodeTag := anInteger! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
operandBase
	^operandBase! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
operandBase: anInteger
	^operandBase := anInteger! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
operandBias
	^operandBias! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
operandBias: anInteger
	^operandBias := anInteger! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
operandMode
	^operandMode! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
operandMode: anInteger
	^operandMode := anInteger! !

!OilBytecodeDescriptor methodsFor: 'translation' stamp: 'cb 10/24/2026 10:10'!
printCInitializerOn: aStream in: aCCodeGenerator
	"Print my C struct initializer, for the static oilGeneratorTable."
	<doNotGenerate>
	| first |
	first := true.
	aStream nextPut: ${; space.
	self class instVarNamesAndTypesForTranslationDo:
		[:ivn :type|
		first ifTrue: [first := false] ifFalse: [aStream nextPut: $,; space].
		aStream print: (self instVarNamed: ivn)].
	aStream space; nextPut: $}! !

!OilBytecodeDescriptor class methodsFor: 'translation' stamp: 'cb 10/24/2026 10:10'!
instVarNamesAndTypesForTranslationDo: aBinaryBlock
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in an OilBytecodeDescriptor struct (6 bytes per entry)."
	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['numBytes']		->	['unsigned char'].
						['opcodeTag']		->	['unsigned char'].
						['operandMode']	->	['unsigned char'].
						['operandBase']	->	['unsigned short'].
						['operandBias']	->	['signed char'] })]! !

!OilBytecodeDescriptor class methodsFor: 'translation' stamp: 'cb 10/24/2026 10:10'!
structTypeName
	^'OilBytecodeDescriptor'! !


VMClass subclass: #OilBytecodeScanner
	instanceVariableNames: 'coInterpreter objectMemory cogit oilGeneratorTable oilMethodObj instrPC oilBcpc oilNextPC oilTargetPC oilByte0 oilByte1 oilByte2 oilExtA oilExtB oilNumExtB opcodeTag operand1 operand2'
	classVariableNames: 'OilGeneratorTable'
	poolDictionaries: 'OilInstructionConstants OilConstants'
	category: 'VMMaker-JIT-Oil'!

!OilBytecodeScanner commentStamp: 'cb 10/24/2026 10:10' prior: 0!
I am Oil's zero-allocation bytecode scanner.  I mirror the Cogit's scanner architecture: a static 256-entry dispatch table, oilGeneratorTable, of OilBytecodeDescriptor structs indexed by oilByte0.  I only decode the SistaV1 bytecode set (the alternate bytecode set in the method header); Oil refuses to compile methods using any other set (see oilIsSistaV1Method:), leaving them to the baseline Cogit.  Decoding a bytecode is a table lookup plus a switch on the descriptor's operandMode; extension prefixes (oilExtA, oilExtB) are folded into the bytecode they extend, so clients see one logical instruction per decodeAt:.

All method access goes through fetchByte:, startPCOf: and oilEndPCOf:, which use the VM (objectMemory/coInterpreter/cogit) when translated to C and the host image's CompiledCode objects when run in Smalltalk, so the same code runs in the image and in the VM.

After decodeAt: pc:
	instrPC		pc of the instruction, including its extension prefixes
	oilBcpc		pc of the (extended) bytecode itself
	oilNextPC		pc of the following instruction
	opcodeTag	its classification (OilTag*); may be refined by decoding (e.g. unsupported variants answer OilTagUnknown)
	operand1	first operand (index, literal index, signed jump distance, integer value...)
	operand2	second operand (number of arguments, temp vector index, closure flags...)
	oilTargetPC	branch target pc (-1 if not a branch)!

!OilBytecodeScanner methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:10'!
initialize
	<doNotGenerate>
	oilGeneratorTable := OilGeneratorTable! !

!OilBytecodeScanner methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
instrPC
	^instrPC! !

!OilBytecodeScanner methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
oilNextPC
	^oilNextPC! !

!OilBytecodeScanner methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
scannedTag
	"The decoded instruction's classification (named so as not to clash with OilBytecodeDescriptor>>opcodeTag in C)."
	^opcodeTag! !

!OilBytecodeScanner methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
operand1
	^operand1! !

!OilBytecodeScanner methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
operand2
	^operand2! !

!OilBytecodeScanner methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
oilTargetPC
	^oilTargetPC! !

!OilBytecodeScanner methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
oilBcpc
	^oilBcpc! !

!OilBytecodeScanner methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
oilGeneratorAt: index
	<cmacro: '(index) (&oilGeneratorTable[index])'>
	^oilGeneratorTable at: index! !

!OilBytecodeScanner methodsFor: 'method access' stamp: 'cb 10/24/2026 10:10'!
setScanMethod: aMethod
	"aMethod must use the SistaV1 bytecode set (cf. oilIsSistaV1Method:)."
	<inline: true>
	oilMethodObj := aMethod! !

!OilBytecodeScanner methodsFor: 'method access' stamp: 'cb 10/24/2026 10:10'!
fetchByte: pc
	<inline: true>
	^self
		cCode: [objectMemory fetchByte: pc ofObject: oilMethodObj]
		inSmalltalk: [oilMethodObj at: pc]! !

!OilBytecodeScanner methodsFor: 'method access' stamp: 'cb 10/24/2026 10:10'!
oilIsSistaV1Method: aMethod
	"Answer whether aMethod uses the alternate bytecode set, SistaV1, the only one Oil decodes."
	<inline: true>
	^self
		cCode: [coInterpreter methodUsesAlternateBytecodeSet: aMethod]
		inSmalltalk: [aMethod signFlag]! !

!OilBytecodeScanner methodsFor: 'method access' stamp: 'cb 10/24/2026 10:10'!
startPCOf: aMethod
	<inline: true>
	^self
		cCode: [coInterpreter startPCOfMethod: aMethod]
		inSmalltalk: [aMethod initialPC]! !

!OilBytecodeScanner methodsFor: 'method access' stamp: 'cb 10/24/2026 10:10'!
oilEndPCOf: aMethod
	<inline: true>
	^self
		cCode: [cogit endPCOf: aMethod]
		inSmalltalk: [aMethod endPC]! !

!OilBytecodeScanner methodsFor: 'method access' stamp: 'cb 10/24/2026 10:10'!
oilSpecialSelectorNumArgs: index
	<inline: true>
	^self
		cCode: [coInterpreter specialSelectorNumArgs: index]
		inSmalltalk: [Smalltalk specialSelectors at: index * 2 + 2]! !

!OilBytecodeScanner methodsFor: 'decoding' stamp: 'cb 10/24/2026 10:10'!
decodeAt: aPC
	"Decode the instruction at aPC of oilMethodObj, folding extension prefixes into the bytecode they extend.
	 Set opcodeTag, operand1, operand2, oilTargetPC, instrPC, oilBcpc and oilNextPC.
	 Zero allocation: a table lookup per byte plus a switch on the operand mode."
	| descriptor |
	<var: #descriptor type: #'OilBytecodeDescriptor *'>
	oilExtA := oilExtB := oilNumExtB := 0.
	oilByte1 := oilByte2 := 0.
	instrPC := oilBcpc := aPC.
	[oilByte0 := self fetchByte: oilBcpc.
	 descriptor := self oilGeneratorAt: oilByte0.
	 descriptor numBytes > 1 ifTrue:
		[oilByte1 := self fetchByte: oilBcpc + 1.
		 descriptor numBytes > 2 ifTrue:
			[oilByte2 := self fetchByte: oilBcpc + 2]].
	 descriptor opcodeTag = OilTagExtension] whileTrue:
		[descriptor operandBias = 0
			ifTrue: [oilExtA := (oilExtA bitShift: 8) + oilByte1]
			ifFalse:
				[oilExtB := (oilNumExtB = 0 and: [oilByte1 > 127])
							ifTrue: [oilByte1 - 256]
							ifFalse: [(oilExtB bitShift: 8) + oilByte1].
				 oilNumExtB := oilNumExtB + 1].
		 oilBcpc := oilBcpc + descriptor numBytes].
	oilNextPC := oilBcpc + descriptor numBytes.
	opcodeTag := descriptor opcodeTag.
	operand1 := operand2 := 0.
	oilTargetPC := -1.
	self decodeOperands: descriptor! !

!OilBytecodeScanner methodsFor: 'decoding' stamp: 'cb 10/24/2026 10:10'!
decodeOperands: descriptor
	"Extract the operands of the bytecode just fetched, according to its descriptor's operandMode."
	<var: #descriptor type: #'OilBytecodeDescriptor *'>
	descriptor operandMode caseOf: {
		[OilModeNone]			-> [].
		[OilModeLow]			-> [operand1 := oilByte0 - descriptor operandBase + descriptor operandBias].
		[OilModeByte1]			-> [operand1 := oilByte1 + (oilExtA bitShift: 8)].
		[OilModeByte1Temp]		-> [operand1 := oilByte1].
		[OilModeByte1ExtB]		-> [operand1 := oilByte1 + (oilExtB bitShift: 8)].
		[OilModeSend]			->
			[operand1 := (oilByte1 bitShift: -3) + (oilExtA bitShift: 5).
			 operand2 := (oilByte1 bitAnd: 7) + (oilExtB bitShift: 3).
			 (opcodeTag = OilTagSendSuper and: [oilExtB >= 64]) ifTrue: "directed super send: unsupported by Oil"
				[opcodeTag := OilTagUnknown]].
		[OilModeLowSend]		-> [operand1 := oilByte0 - descriptor operandBase. operand2 := descriptor operandBias].
		[OilModeNewArray]		-> [operand1 := oilByte1 bitAnd: 127. operand2 := oilByte1 bitShift: -7].
		[OilModeRemoteTemp]	->
			[operand1 := oilByte1.
			 operand2 := oilByte2 bitAnd: 127.
			 oilByte2 > 127 ifTrue: "remote inst var access: unsupported by Oil"
				[opcodeTag := OilTagUnknown]].
		[OilModeFullClosure]	-> [operand1 := oilByte1 + (oilExtA bitShift: 8). operand2 := oilByte2] }
		otherwise: [].
	(opcodeTag between: OilTagJump and: OilTagJumpFalse) ifTrue:
		[oilTargetPC := oilNextPC + operand1].
	opcodeTag = OilTagSendSpecial ifTrue:
		[operand2 := self oilSpecialSelectorNumArgs: operand1]! !

!OilBytecodeScanner methodsFor: 'scanning' stamp: 'cb 10/24/2026 10:10'!
scanMethod: aMethod do: aBlock
	"Evaluate aBlock for each instruction of aMethod, from its initial pc to its end pc.
	 Extension prefixes are folded into the bytecode they extend.  The scanner's state (instrPC, oilNextPC,
	 opcodeTag, operand1, operand2, oilTargetPC) describes the instruction while aBlock runs."
	<doNotGenerate>
	| pc end |
	self setScanMethod: aMethod.
	pc := self startPCOf: aMethod.
	end := self oilEndPCOf: aMethod.
	[pc <= end] whileTrue:
		[self decodeAt: pc.
		 aBlock value: nil.
		 pc := oilNextPC]! !


!OilBytecodeScanner class methodsFor: 'class initialization' stamp: 'cb 10/24/2026 10:10'!
initialize
	"OilBytecodeScanner initialize"
	self initializeOilGeneratorTable! !

!OilBytecodeScanner class methodsFor: 'class initialization' stamp: 'cb 10/24/2026 10:10'!
initializeOilGeneratorTable
	"OilBytecodeScanner initializeOilGeneratorTable"
	| table |
	table := CArrayAccessor on: (Array new: 256).
	self fill: table from: self sistaV1Spec.
	0 to: 255 do: [:tableIndex| (table at: tableIndex) ifNil: [self error: 'hole in oilGeneratorTable at ', tableIndex printString]].
	^OilGeneratorTable := table! !

!OilBytecodeScanner class methodsFor: 'class initialization' stamp: 'cb 10/24/2026 10:10'!
fill: table from: spec
	"Each tuple is (numBytes first last tag mode bias).
	 tag names an OilTag* constant, mode an OilMode* constant."
	| pool |
	pool := OilConstants classPool.
	spec do:
		[:tuple| | descriptor |
		descriptor := OilBytecodeDescriptor new.
		descriptor numBytes: (tuple at: 1);
		  opcodeTag: (pool at: ('OilTag', (tuple at: 4)) asSymbol);
		  operandMode: (pool at: ('OilMode', (tuple at: 5)) asSymbol);
		  operandBase: (tuple at: 2);
		  operandBias: (tuple at: 6).
		(tuple at: 2) to: (tuple at: 3) do:
			[:byte|
			(table at: byte) ifNotNil: [self error: 'overlap at ', byte printString].
			table at: byte put: descriptor]]! !

!OilBytecodeScanner class methodsFor: 'class initialization' stamp: 'cb 10/24/2026 10:10'!
sistaV1Spec
	"(numBytes first last tag mode bias)"
	^#(	(1   0  15 PushRcvrVar		Low		0)
		(1  16  31 PushLitVar		Low		0)
		(1  32  63 PushLitConst		Low		0)
		(1  64  75 PushTemp			Low		0)
		(1  76  76 PushSelf			None	0)
		(1  77  77 PushTrue			None	0)
		(1  78  78 PushFalse			None	0)
		(1  79  79 PushNil			None	0)
		(1  80  81 PushInteger		Low		0)
		(1  82  82 Unknown			None	0)
		(1  83  83 Dup				None	0)
		(1  84  87 Unknown			None	0)
		(1  88  88 ReturnSelf		None	0)
		(1  89  89 ReturnTrue		None	0)
		(1  90  90 ReturnFalse		None	0)
		(1  91  91 ReturnNil			None	0)
		(1  92  92 ReturnTop			None	0)
		(1  93  93 BlockReturnNil	None	0)
		(1  94  94 BlockReturnTop	None	0)
		(1  95  95 Nop				None	0)
		(1  96 127 SendSpecial		Low		0)
		(1 128 143 Send				LowSend	0)
		(1 144 159 Send				LowSend	1)
		(1 160 175 Send				LowSend	2)
		(1 176 183 Jump				Low		1)
		(1 184 191 JumpTrue			Low		1)
		(1 192 199 JumpFalse			Low		1)
		(1 200 207 PopIntoRcvrVar	Low		0)
		(1 208 215 PopIntoTemp		Low		0)
		(1 216 216 Pop				None	0)
		(1 217 223 Unknown			None	0)
		(2 224 224 Extension			None	0)
		(2 225 225 Extension			None	1)
		(2 226 226 PushRcvrVar		Byte1	0)
		(2 227 227 PushLitVar		Byte1	0)
		(2 228 228 PushLitConst		Byte1	0)
		(2 229 229 PushTemp			Byte1Temp 0)
		(2 230 230 Unknown			None	0)
		(2 231 231 PushNewArray		NewArray 0)
		(2 232 232 PushInteger		Byte1ExtB 0)
		(2 233 233 PushCharacter		Byte1	0)
		(2 234 234 Send				Send	0)
		(2 235 235 SendSuper			Send	0)
		(2 236 236 Unknown			None	0)
		(2 237 237 Jump				Byte1ExtB 0)
		(2 238 238 JumpTrue			Byte1ExtB 0)
		(2 239 239 JumpFalse			Byte1ExtB 0)
		(2 240 240 PopIntoRcvrVar	Byte1	0)
		(2 241 241 PopIntoLitVar		Byte1	0)
		(2 242 242 PopIntoTemp		Byte1Temp 0)
		(2 243 243 StoreRcvrVar		Byte1	0)
		(2 244 244 StoreLitVar		Byte1	0)
		(2 245 245 StoreTemp			Byte1Temp 0)
		(2 246 247 Unknown			None	0)
		(3 248 248 Unknown			None	0)
		(3 249 249 PushFullClosure	FullClosure 0)
		(3 250 250 Unknown			None	0)
		(3 251 251 PushRemoteTemp	RemoteTemp 0)
		(3 252 252 StoreRemoteTemp	RemoteTemp 0)
		(3 253 253 PopIntoRemoteTemp RemoteTemp 0)
		(3 254 255 Unknown			None	0))! !

!OilBytecodeScanner class methodsFor: 'translation' stamp: 'cb 10/24/2026 10:10'!
declareCVarsIn: aCCodeGenerator
	"The dispatch table is a static array of 256 OilBytecodeDescriptor structs (one per SistaV1 bytecode), like the Cogit's generatorTable."
	| table |
	table := OilGeneratorTable ifNil: [self initializeOilGeneratorTable].
	aCCodeGenerator
		var: #oilGeneratorTable
			declareC: 'static OilBytecodeDescriptor oilGeneratorTable[256]',
						(String streamContents:
							[:s|
							s nextPutAll: ' = {'.
							table object
								do: [:d| s crtab. d printCInitializerOn: s in: aCCodeGenerator]
								separatedBy: [s nextPut: $,].
							s cr; nextPut: $}])! !

OilBytecodeScanner initialize!
