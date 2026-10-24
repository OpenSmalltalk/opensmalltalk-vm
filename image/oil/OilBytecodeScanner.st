VMStructType subclass: #OilBytecodeDescriptor
	instanceVariableNames: 'numBytes stackDelta opcodeTag operandMode operandBase operandBias isBranchTrue isBranchFalse isBranchUnconditional isReturn isBlockCreation isExtension'
	classVariableNames: ''
	poolDictionaries: 'OilConstants'
	category: 'VMMaker-Oil'!

!OilBytecodeDescriptor commentStamp: 'cb 10/24/2026 10:10' prior: 0!
I am an entry in Oil's bytecode dispatch table, oilGeneratorTable (512 entries: 0-255 SqueakV3PlusClosures, 256-511 SistaV1).  Like Cogit's CogBytecodeDescriptor I let OilBytecodeScanner decode a bytecode in O(1) with zero allocation: one table lookup on byte0 + bytecodeSetOffset gives the instruction length, its stack delta, its high level classification (opcodeTag) and how to extract its operands (operandMode, operandBase, operandBias).

numBytes			<Integer> instruction length (1..4)
stackDelta			<Integer> net evaluation stack change (sends with a dynamic arity answer 0; the scanner computes the real arity)
opcodeTag			<Integer> one of the OilTag* constants
operandMode		<Integer> one of the OilMode* constants
operandBase		<Integer> table index of the first bytecode of my range (for range encoded operands)
operandBias		<Integer> constant added to range encoded operands (e.g. 1 for short jumps), the fixed arity of literal sends, the kind of extension (0 = A, 1 = B), or the kind of V3 extended bytecode
isBranch*			<Boolean> branch flags
isReturn			<Boolean> return flag
isBlockCreation	<Boolean> closure creation flag
isExtension			<Boolean> extension prefix (SistaV1 extA/extB)!

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
isBlockCreation
	^isBlockCreation! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
isBlockCreation: aBoolean
	^isBlockCreation := aBoolean! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
isBranchFalse
	^isBranchFalse! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
isBranchFalse: aBoolean
	^isBranchFalse := aBoolean! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
isBranchTrue
	^isBranchTrue! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
isBranchTrue: aBoolean
	^isBranchTrue := aBoolean! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
isBranchUnconditional
	^isBranchUnconditional! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
isBranchUnconditional: aBoolean
	^isBranchUnconditional := aBoolean! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
isExtension
	^isExtension! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
isExtension: aBoolean
	^isExtension := aBoolean! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
isReturn
	^isReturn! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
isReturn: aBoolean
	^isReturn := aBoolean! !

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

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
stackDelta
	^stackDelta! !

!OilBytecodeDescriptor methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
stackDelta: anInteger
	^stackDelta := anInteger! !

!OilBytecodeDescriptor methodsFor: 'translation' stamp: 'cb 10/24/2026 10:10'!
printCInitializerOn: aStream in: aCCodeGenerator
	"Print my C struct initializer, for the static oilGeneratorTable."
	<doNotGenerate>
	| first |
	first := true.
	aStream nextPut: ${; space.
	self class instVarNamesAndTypesForTranslationDo:
		[:ivn :type| | value |
		first ifTrue: [first := false] ifFalse: [aStream nextPut: $,; space].
		value := self instVarNamed: ivn.
		value isInteger
			ifTrue: [aStream print: value]
			ifFalse: [aStream nextPut: ((value notNil and: [value]) ifTrue: [$1] ifFalse: [$0])]].
	aStream space; nextPut: $}! !

!OilBytecodeDescriptor methodsFor: 'printing' stamp: 'cb 10/24/2026 10:10'!
printOn: aStream
	aStream nextPutAll: 'OilBytecodeDescriptor(';
		print: numBytes; nextPutAll: ' bytes, tag ';
		print: opcodeTag; nextPutAll: ', mode ';
		print: operandMode; nextPut: $)! !

!OilBytecodeDescriptor class methodsFor: 'translation' stamp: 'cb 10/24/2026 10:10'!
instVarNamesAndTypesForTranslationDo: aBinaryBlock
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in an OilBytecodeDescriptor struct.  Six bytes of fields plus six flag bits: 8 bytes per entry, 4 KB for the whole 512 entry table."
	self instVarNames do:
		[:ivn|
		aBinaryBlock
			value: ivn
			value: (ivn caseOf: {
						['numBytes']		->	['unsigned char'].
						['stackDelta']		->	['signed char'].
						['opcodeTag']		->	['unsigned char'].
						['operandMode']	->	['unsigned char'].
						['operandBase']	->	['unsigned short'].
						['operandBias']	->	['signed char'] }
					otherwise: [#('unsigned' ' : 1')])]! !

!OilBytecodeDescriptor class methodsFor: 'translation' stamp: 'cb 10/24/2026 10:10'!
structTypeName
	^'OilBytecodeDescriptor'! !


VMClass subclass: #OilBytecodeScanner
	instanceVariableNames: 'coInterpreter objectMemory cogit oilGeneratorTable methodObj bytecodeSetOffset instrPC bcpc nextPC targetPC byte0 byte1 byte2 byte3 extA extB numExtB descriptor opcodeTag operand1 operand2'
	classVariableNames: 'OilGeneratorTable'
	poolDictionaries: 'OilConstants'
	category: 'VMMaker-Oil'!

!OilBytecodeScanner commentStamp: 'cb 10/24/2026 10:10' prior: 0!
I am Oil's zero-allocation bytecode scanner.  I mirror the Cogit's scanner architecture: a static 512-entry dispatch table, oilGeneratorTable, of OilBytecodeDescriptor structs (entries 0-255 decode SqueakV3PlusClosures, 256-511 SistaV1), indexed by byte0 + bytecodeSetOffset where bytecodeSetOffset is 256 for methods using the alternate (SistaV1) bytecode set.  Decoding a bytecode is a table lookup plus a switch on the descriptor's operandMode; extension prefixes (extA, extB) are folded into the bytecode they extend, so clients see one logical instruction per decodeAt:.

All method access goes through fetchByte:, startPCOf:, endPCOf:, literal:of: and friends, which use the VM (objectMemory/coInterpreter) when translated to C and the host image's CompiledCode objects when run in Smalltalk (in-image compilation, cf. CurrentImageCoInterpreterFacade), so the same code runs in the image and in the VM.

After decodeAt: pc:
	instrPC		pc of the instruction, including its extension prefixes
	bcpc		pc of the (extended) bytecode itself
	nextPC		pc of the following instruction
	descriptor	the bytecode's OilBytecodeDescriptor
	opcodeTag	its classification (OilTag*); may be refined by decoding (e.g. V3 extended bytecodes)
	operand1	first operand (index, literal index, signed jump distance, integer value...)
	operand2	second operand (number of arguments, temp vector index, closure flags...)
	targetPC	branch target pc (-1 if not a branch)!

!OilBytecodeScanner methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:10'!
initialize
	<doNotGenerate>
	self setUpScanner! !

!OilBytecodeScanner methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:10'!
setUpScanner
	<doNotGenerate>
	oilGeneratorTable := OilGeneratorTable ifNil: [self class initializeOilGeneratorTable].
	bytecodeSetOffset := 0.
	extA := extB := numExtB := 0! !

!OilBytecodeScanner methodsFor: 'initialization' stamp: 'cb 10/24/2026 10:10'!
setInterpreter: aCoInterpreter objectMemory: anObjectMemory cogit: aCogit
	<doNotGenerate>
	coInterpreter := aCoInterpreter.
	objectMemory := anObjectMemory.
	cogit := aCogit! !

!OilBytecodeScanner methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
descriptor
	<returnTypeC: #'OilBytecodeDescriptor *'>
	^descriptor! !

!OilBytecodeScanner methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
instrPC
	^instrPC! !

!OilBytecodeScanner methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
nextPC
	^nextPC! !

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
targetPC
	^targetPC! !

!OilBytecodeScanner methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
bcpc
	^bcpc! !

!OilBytecodeScanner methodsFor: 'accessing' stamp: 'cb 10/24/2026 10:10'!
generatorAt: index
	<cmacro: '(index) (&oilGeneratorTable[index])'>
	^oilGeneratorTable at: index! !

!OilBytecodeScanner methodsFor: 'method access' stamp: 'cb 10/24/2026 10:10'!
setScanMethod: aMethod
	<inline: true>
	methodObj := aMethod.
	bytecodeSetOffset := (self oilMethodUsesAlternateBytecodeSet: aMethod) ifTrue: [256] ifFalse: [0]! !

!OilBytecodeScanner methodsFor: 'method access' stamp: 'cb 10/24/2026 10:10'!
fetchByte: pc
	<inline: true>
	^self
		cCode: [objectMemory fetchByte: pc ofObject: methodObj]
		inSmalltalk: [methodObj at: pc]! !

!OilBytecodeScanner methodsFor: 'method access' stamp: 'cb 10/24/2026 10:10'!
oilMethodUsesAlternateBytecodeSet: aMethod
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
	"Decode the instruction at aPC of methodObj, folding extension prefixes into the bytecode they extend.
	 Set descriptor, opcodeTag, operand1, operand2, targetPC, instrPC, bcpc and nextPC. Answer the descriptor.
	 Zero allocation: a table lookup per byte plus a switch on the operand mode."
	| d |
	<var: #d type: #'OilBytecodeDescriptor *'>
	<returnTypeC: #'OilBytecodeDescriptor *'>
	extA := extB := numExtB := 0.
	byte1 := byte2 := byte3 := 0.
	instrPC := bcpc := aPC.
	[byte0 := (self fetchByte: bcpc) + bytecodeSetOffset.
	 d := self generatorAt: byte0.
	 d numBytes > 1 ifTrue:
		[byte1 := self fetchByte: bcpc + 1.
		 d numBytes > 2 ifTrue:
			[byte2 := self fetchByte: bcpc + 2.
			 d numBytes > 3 ifTrue:
				[byte3 := self fetchByte: bcpc + 3]]].
	 d isExtension] whileTrue:
		[d operandBias = 0
			ifTrue: [extA := (extA bitShift: 8) + byte1]
			ifFalse:
				[extB := (numExtB = 0 and: [byte1 > 127])
							ifTrue: [byte1 - 256]
							ifFalse: [(extB bitShift: 8) + byte1].
				 numExtB := numExtB + 1].
		 bcpc := bcpc + d numBytes].
	descriptor := d.
	nextPC := bcpc + d numBytes.
	opcodeTag := d opcodeTag.
	operand1 := operand2 := 0.
	targetPC := -1.
	self decodeOperands.
	^d! !

!OilBytecodeScanner methodsFor: 'decoding' stamp: 'cb 10/24/2026 10:10'!
decodeOperands
	"Extract the operands of the bytecode just fetched, according to its descriptor's operandMode."
	| d mode |
	<var: #d type: #'OilBytecodeDescriptor *'>
	d := descriptor.
	mode := d operandMode.
	mode caseOf: {
		[OilModeNone]			-> [].
		[OilModeLow]			-> [operand1 := byte0 - d operandBase + d operandBias].
		[OilModeByte1]			-> [operand1 := byte1 + (extA bitShift: 8)].
		[OilModeByte1Temp]		-> [operand1 := byte1].
		[OilModeByte1ExtB]		-> [operand1 := byte1 + (extB bitShift: 8)].
		[OilModeSend]			->
			[operand1 := (byte1 bitShift: -3) + (extA bitShift: 5).
			 (opcodeTag = OilTagSendSuper and: [extB >= 64])
				ifTrue: "directed super send: unsupported by Oil for now"
					[opcodeTag := OilTagUnknown.
					 operand2 := (byte1 bitAnd: 7) + ((extB bitAnd: 63) bitShift: 3)]
				ifFalse: [operand2 := (byte1 bitAnd: 7) + (extB bitShift: 3)]].
		[OilModeLowSend]		-> [operand1 := byte0 - d operandBase. operand2 := d operandBias].
		[OilModeNewArray]		-> [operand1 := byte1 bitAnd: 127. operand2 := byte1 bitShift: -7].
		[OilModeRemoteTemp]	->
			[operand1 := byte1.
			 operand2 := byte2 bitAnd: 127.
			 byte2 > 127 ifTrue: "remote inst var access: unsupported by Oil for now"
				[opcodeTag := OilTagUnknown]].
		[OilModeFullClosure]	-> [operand1 := byte1 + (extA bitShift: 8). operand2 := byte2].
		[OilModePrimitive]		-> [operand1 := byte1 + ((byte2 bitAnd: 31) bitShift: 8). operand2 := byte2 bitShift: -5].
		[OilModeV3Primitive]	-> [operand1 := byte1 + (byte2 bitShift: 8)].
		[OilModeLowByte1]		-> [operand1 := (byte0 - d operandBase + d operandBias bitShift: 8) + byte1].
		[OilModeV3Send1]		-> [operand1 := byte1 bitAnd: 31. operand2 := byte1 bitShift: -5].
		[OilModeV3Send2]		-> [operand1 := byte1 bitAnd: 63. operand2 := byte1 bitShift: -6].
		[OilModeV3Ext]			-> [self decodeV3Extended].
		[OilModeV3DoubleExt]	-> [self decodeV3DoubleExtended].
		[OilModeEmbeddedClosure] -> [self decodeEmbeddedClosure] }
		otherwise: [].
	(d isBranchTrue or: [d isBranchFalse or: [d isBranchUnconditional]]) ifTrue:
		[targetPC := nextPC + operand1].
	opcodeTag = OilTagSendSpecial ifTrue:
		[operand2 := self oilSpecialSelectorNumArgs: operand1]! !

!OilBytecodeScanner methodsFor: 'decoding' stamp: 'cb 10/24/2026 10:10'!
decodeV3Extended
	"SqueakV3 128/129/130 extended push/store/popStore: byte1 = ttiiiiii, tt = 0 receiver variable, 1 temp, 2 literal constant, 3 literal variable.
	 The descriptor's operandBias tells push (0), store (1) or popStore (2)."
	| type kind |
	type := byte1 bitShift: -6.
	kind := descriptor operandBias.
	operand1 := byte1 bitAnd: 63.
	opcodeTag := kind = 0
		ifTrue:
			[type = 0 ifTrue: [OilTagPushRcvrVar] ifFalse:
			[type = 1 ifTrue: [OilTagPushTemp] ifFalse:
			[type = 2 ifTrue: [OilTagPushLitConst] ifFalse: [OilTagPushLitVar]]]]
		ifFalse:
			[kind = 1
				ifTrue:
					[type = 0 ifTrue: [OilTagStoreRcvrVar] ifFalse:
					[type = 1 ifTrue: [OilTagStoreTemp] ifFalse:
					[type = 2 ifTrue: [OilTagUnknown] ifFalse: [OilTagStoreLitVar]]]]
				ifFalse:
					[type = 0 ifTrue: [OilTagPopIntoRcvrVar] ifFalse:
					[type = 1 ifTrue: [OilTagPopIntoTemp] ifFalse:
					[type = 2 ifTrue: [OilTagUnknown] ifFalse: [OilTagPopIntoLitVar]]]]]! !

!OilBytecodeScanner methodsFor: 'decoding' stamp: 'cb 10/24/2026 10:10'!
decodeV3DoubleExtended
	"SqueakV3 132 double extended do-anything: byte1 = oooaaaaa, byte2 = literal/variable index.
	 ooo: 0 send, 1 super send, 2 push receiver variable, 3 push literal constant, 4 push literal variable,
	 5 store receiver variable, 6 popStore receiver variable, 7 store literal variable."
	| op |
	op := byte1 bitShift: -5.
	operand1 := byte2.
	operand2 := byte1 bitAnd: 31.
	opcodeTag := op caseOf: {
		[0] -> [OilTagSend].
		[1] -> [OilTagSendSuper].
		[2] -> [OilTagPushRcvrVar].
		[3] -> [OilTagPushLitConst].
		[4] -> [OilTagPushLitVar].
		[5] -> [OilTagStoreRcvrVar].
		[6] -> [OilTagPopIntoRcvrVar].
		[7] -> [OilTagStoreLitVar] }
		otherwise: [OilTagUnknown]! !

!OilBytecodeScanner methodsFor: 'decoding' stamp: 'cb 10/24/2026 10:10'!
decodeEmbeddedClosure
	"V3 143: byte1 = ccccaaaa (numCopied, numArgs), block size = byte2 * 256 + byte3.
	 SistaV1 250: byte1 = eeiiikkk numCopied iii (+ extA // 16 * 8), numArgs kkk (+ extA \\ 16 * 8), block size = byte2 (+ extB * 256).
	 operand1 := numArgs, operand2 := numCopied, targetPC := the pc following the embedded block."
	descriptor numBytes = 4
		ifTrue:
			[operand1 := byte1 bitAnd: 15.
			 operand2 := byte1 bitShift: -4.
			 targetPC := nextPC + (byte2 bitShift: 8) + byte3]
		ifFalse:
			[operand1 := (byte1 bitAnd: 7) + ((extA \\ 16) bitShift: 3).
			 operand2 := ((byte1 bitShift: -3) bitAnd: 7) + ((extA // 16) bitShift: 3).
			 targetPC := nextPC + byte2 + (extB bitShift: 8)]! !

!OilBytecodeScanner methodsFor: 'scanning' stamp: 'cb 10/24/2026 10:10'!
scanMethod: aMethod do: aBlock
	"Evaluate aBlock with the descriptor of each instruction of aMethod, from its initial pc to its end pc.
	 Extension prefixes are folded into the bytecode they extend.  The scanner's state (instrPC, nextPC,
	 opcodeTag, operand1, operand2, targetPC) describes the instruction while aBlock runs.
	 Inlined in Slang: compiles to a pointer-chasing loop with no allocation."
	<inline: true>
	| pc end |
	self setScanMethod: aMethod.
	pc := self startPCOf: aMethod.
	end := self oilEndPCOf: aMethod.
	[pc <= end] whileTrue:
		[self decodeAt: pc.
		 aBlock value: descriptor.
		 pc := nextPC]! !


!OilBytecodeScanner class methodsFor: 'class initialization' stamp: 'cb 10/24/2026 10:10'!
initializeOilGeneratorTable
	"OilBytecodeScanner initializeOilGeneratorTable"
	| table |
	table := CArrayAccessor on: (Array new: 512).
	self fill: table offset: 0 from: self squeakV3PlusClosuresSpec.
	self fill: table offset: 256 from: self sistaV1Spec.
	0 to: 511 do: [:i| (table at: i) ifNil: [self error: 'hole in oilGeneratorTable at ', i printString]].
	^OilGeneratorTable := table! !

!OilBytecodeScanner class methodsFor: 'class initialization' stamp: 'cb 10/24/2026 10:10'!
fill: table offset: offset from: spec
	"Each tuple is (numBytes first last tag mode bias stackDelta flag*).
	 tag names an OilTag* constant, mode an OilMode* constant; flags are
	 return branch branchTrue branchFalse block extension."
	| pool |
	pool := OilConstants classPool.
	spec do:
		[:tuple| | d |
		d := OilBytecodeDescriptor new.
		d numBytes: (tuple at: 1);
		  opcodeTag: (pool at: ('OilTag', (tuple at: 4)) asSymbol);
		  operandMode: (pool at: ('OilMode', (tuple at: 5)) asSymbol);
		  operandBase: (tuple at: 2) + offset;
		  operandBias: (tuple at: 6);
		  stackDelta: (tuple at: 7);
		  isReturn: (tuple includes: #return);
		  isBranchUnconditional: (tuple includes: #branch);
		  isBranchTrue: (tuple includes: #branchTrue);
		  isBranchFalse: (tuple includes: #branchFalse);
		  isBlockCreation: (tuple includes: #block);
		  isExtension: (tuple includes: #extension).
		(tuple at: 2) to: (tuple at: 3) do:
			[:byte|
			(table at: byte + offset) ifNotNil: [self error: 'overlap at ', byte printString].
			table at: byte + offset put: d]]! !

!OilBytecodeScanner class methodsFor: 'class initialization' stamp: 'cb 10/24/2026 10:10'!
squeakV3PlusClosuresSpec
	"(numBytes first last tag mode bias stackDelta flags...)"
	^#(	(1   0  15 PushRcvrVar		Low		0  1)
		(1  16  31 PushTemp			Low		0  1)
		(1  32  63 PushLitConst		Low		0  1)
		(1  64  95 PushLitVar		Low		0  1)
		(1  96 103 PopIntoRcvrVar	Low		0 -1)
		(1 104 111 PopIntoTemp		Low		0 -1)
		(1 112 112 PushSelf			None	0  1)
		(1 113 113 PushTrue			None	0  1)
		(1 114 114 PushFalse			None	0  1)
		(1 115 115 PushNil			None	0  1)
		(1 116 119 PushInteger		Low		-1  1)
		(1 120 120 ReturnSelf		None	0  0 return)
		(1 121 121 ReturnTrue		None	0  0 return)
		(1 122 122 ReturnFalse		None	0  0 return)
		(1 123 123 ReturnNil			None	0  0 return)
		(1 124 124 ReturnTop			None	0 -1 return)
		(1 125 125 BlockReturnTop	None	0 -1 return)
		(1 126 127 Unknown			None	0  0)
		(2 128 128 V3Extended		V3Ext	0  1)
		(2 129 129 V3Extended		V3Ext	1  0)
		(2 130 130 V3Extended		V3Ext	2 -1)
		(2 131 131 Send				V3Send1	0  0)
		(3 132 132 V3DoubleExtended V3DoubleExt 0 0)
		(2 133 133 SendSuper			V3Send1	0  0)
		(2 134 134 Send				V3Send2	0  0)
		(1 135 135 Pop				None	0 -1)
		(1 136 136 Dup				None	0  1)
		(1 137 137 PushThisContext	None	0  1)
		(2 138 138 PushNewArray		NewArray 0  1)
		(3 139 139 CallPrimitive		V3Primitive 0 0)
		(3 140 140 PushRemoteTemp	RemoteTemp 0  1)
		(3 141 141 StoreRemoteTemp	RemoteTemp 0  0)
		(3 142 142 PopIntoRemoteTemp RemoteTemp 0 -1)
		(4 143 143 PushEmbeddedClosure EmbeddedClosure 0 1 block)
		(1 144 151 Jump				Low		1  0 branch)
		(1 152 159 JumpFalse			Low		1 -1 branchFalse)
		(2 160 167 Jump				LowByte1 -4 0 branch)
		(2 168 171 JumpTrue			LowByte1 0 -1 branchTrue)
		(2 172 175 JumpFalse			LowByte1 0 -1 branchFalse)
		(1 176 207 SendSpecial		Low		0  0)
		(1 208 223 Send				LowSend	0  0)
		(1 224 239 Send				LowSend	1 -1)
		(1 240 255 Send				LowSend	2 -2))! !

!OilBytecodeScanner class methodsFor: 'class initialization' stamp: 'cb 10/24/2026 10:10'!
sistaV1Spec
	"(numBytes first last tag mode bias stackDelta flags...)"
	^#(	(1   0  15 PushRcvrVar		Low		0  1)
		(1  16  31 PushLitVar		Low		0  1)
		(1  32  63 PushLitConst		Low		0  1)
		(1  64  75 PushTemp			Low		0  1)
		(1  76  76 PushSelf			None	0  1)
		(1  77  77 PushTrue			None	0  1)
		(1  78  78 PushFalse			None	0  1)
		(1  79  79 PushNil			None	0  1)
		(1  80  81 PushInteger		Low		0  1)
		(1  82  82 PushThisContext	None	0  1)
		(1  83  83 Dup				None	0  1)
		(1  84  87 Unknown			None	0  0)
		(1  88  88 ReturnSelf		None	0  0 return)
		(1  89  89 ReturnTrue		None	0  0 return)
		(1  90  90 ReturnFalse		None	0  0 return)
		(1  91  91 ReturnNil			None	0  0 return)
		(1  92  92 ReturnTop			None	0 -1 return)
		(1  93  93 BlockReturnNil	None	0  0 return)
		(1  94  94 BlockReturnTop	None	0 -1 return)
		(1  95  95 Nop				None	0  0)
		(1  96 127 SendSpecial		Low		0  0)
		(1 128 143 Send				LowSend	0  0)
		(1 144 159 Send				LowSend	1 -1)
		(1 160 175 Send				LowSend	2 -2)
		(1 176 183 Jump				Low		1  0 branch)
		(1 184 191 JumpTrue			Low		1 -1 branchTrue)
		(1 192 199 JumpFalse			Low		1 -1 branchFalse)
		(1 200 207 PopIntoRcvrVar	Low		0 -1)
		(1 208 215 PopIntoTemp		Low		0 -1)
		(1 216 216 Pop				None	0 -1)
		(1 217 217 Trap				None	0  0)
		(1 218 223 Unknown			None	0  0)
		(2 224 224 Extension			None	0  0 extension)
		(2 225 225 Extension			None	1  0 extension)
		(2 226 226 PushRcvrVar		Byte1	0  1)
		(2 227 227 PushLitVar		Byte1	0  1)
		(2 228 228 PushLitConst		Byte1	0  1)
		(2 229 229 PushTemp			Byte1Temp 0 1)
		(2 230 230 Unknown			None	0  0)
		(2 231 231 PushNewArray		NewArray 0 1)
		(2 232 232 PushInteger		Byte1ExtB 0 1)
		(2 233 233 PushCharacter		Byte1	0  1)
		(2 234 234 Send				Send	0  0)
		(2 235 235 SendSuper			Send	0  0)
		(2 236 236 Unknown			None	0  0)
		(2 237 237 Jump				Byte1ExtB 0 0 branch)
		(2 238 238 JumpTrue			Byte1ExtB 0 -1 branchTrue)
		(2 239 239 JumpFalse			Byte1ExtB 0 -1 branchFalse)
		(2 240 240 PopIntoRcvrVar	Byte1	0 -1)
		(2 241 241 PopIntoLitVar		Byte1	0 -1)
		(2 242 242 PopIntoTemp		Byte1Temp 0 -1)
		(2 243 243 StoreRcvrVar		Byte1	0  0)
		(2 244 244 StoreLitVar		Byte1	0  0)
		(2 245 245 StoreTemp			Byte1Temp 0 0)
		(2 246 247 Unknown			None	0  0)
		(3 248 248 CallPrimitive		Primitive 0 0)
		(3 249 249 PushFullClosure	FullClosure 0 1 block)
		(3 250 250 PushEmbeddedClosure EmbeddedClosure 0 1 block)
		(3 251 251 PushRemoteTemp	RemoteTemp 0  1)
		(3 252 252 StoreRemoteTemp	RemoteTemp 0  0)
		(3 253 253 PopIntoRemoteTemp RemoteTemp 0 -1)
		(3 254 254 BranchOnBehavior	None	0 -1)
		(3 255 255 Unknown			None	0  0))! !

!OilBytecodeScanner class methodsFor: 'translation' stamp: 'cb 10/24/2026 10:10'!
declareCVarsIn: aCCodeGenerator
	"The dispatch table is a static array of 512 OilBytecodeDescriptor structs (8 bytes each), like the Cogit's generatorTable."
	| table |
	table := OilGeneratorTable ifNil: [self initializeOilGeneratorTable].
	aCCodeGenerator
		var: #oilGeneratorTable
			declareC: 'static OilBytecodeDescriptor oilGeneratorTable[512]',
						(String streamContents:
							[:s|
							s nextPutAll: ' = {'.
							table object
								do: [:d| s crtab. d printCInitializerOn: s in: aCCodeGenerator]
								separatedBy: [s nextPut: $,].
							s cr; nextPut: $}]);
		var: #descriptor type: #'OilBytecodeDescriptor *'! !

OilBytecodeScanner initializeOilGeneratorTable!
