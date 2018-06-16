Class {
	#name : #CogSimStackNativeEntry,
	#superclass : #VMStructType,
	#instVars : [
		'cogit',
		'objectRepresentation',
		'type',
		'spilled',
		'register',
		'registerSecond',
		'offset',
		'constant',
		'constantInt32',
		'constantInt64',
		'constantFloat32',
		'constantFloat64',
		'constantNativePointer',
		'bcptr'
	],
	#pools : [
		'CogAbstractRegisters',
		'CogCompilationConstants',
		'CogRTLOpcodes'
	],
	#category : 'VMMaker-JIT'
}

{ #category : #translation }
CogSimStackNativeEntry class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	"enumerate aBinaryBlock with the names and C type strings for the inst vars to include in a CogSimStackEntry struct."
	"self printTypedefOn: Transcript"
	self filteredInstVarNames do:
		[:ivn|
		aBinaryBlock
			value: (ivn = 'register' ifTrue: ['registerr'] ifFalse: [ivn]) "avoid reservedWord conflict"
			value: (ivn caseOf: {
						['constantInt64']			-> [#sqLong].
						['constantFloat32']			-> [#float].
						['constantFloat64']			-> [#double].
						['type']			-> [#char].
						['spilled']		-> [#char].}
					otherwise:
						[#sqInt])]
]

{ #category : #accessing }
CogSimStackNativeEntry >> bcptr [
	"Answer the value of bcptr"

	^ bcptr
]

{ #category : #accessing }
CogSimStackNativeEntry >> bcptr: anObject [
	"Set the value of bcptr"

	^bcptr := anObject
]

{ #category : #accessing }
CogSimStackNativeEntry >> cogit [
	"Answer the value of cogit"
	<doNotGenerate>
	^cogit
]

{ #category : #'initialize-release' }
CogSimStackNativeEntry >> cogit: aCogit [
	<doNotGenerate>
	cogit := aCogit.
	objectRepresentation := cogit objectRepresentation.
	^self
]

{ #category : #accessing }
CogSimStackNativeEntry >> constantFloat32 [
	"Answer the value of constant float32"
	self assert: type = SSConstantFloat32.
	^constantFloat32
]

{ #category : #accessing }
CogSimStackNativeEntry >> constantFloat32: aFloat32 [
	"Set the value of constant float32"

	^constantFloat32 := aFloat32
]

{ #category : #accessing }
CogSimStackNativeEntry >> constantFloat64 [
	"Answer the value of constant float64"
	self assert: type = SSConstantFloat64.
	^constantFloat64
]

{ #category : #accessing }
CogSimStackNativeEntry >> constantFloat64: aFloat64 [
	"Set the value of constant float64"

	^constantFloat64 := aFloat64
]

{ #category : #accessing }
CogSimStackNativeEntry >> constantInt32 [
	"Answer the value of constant int32"
	self assert: type = SSConstantInt32.
	^constantInt32
]

{ #category : #accessing }
CogSimStackNativeEntry >> constantInt32: anInteger [
	"Set the value of constant int32"

	^constantInt32 := anInteger
]

{ #category : #accessing }
CogSimStackNativeEntry >> constantInt64 [
	"Answer the value of constant int64"
	self assert: type = SSConstantInt64.
	^constantInt64
]

{ #category : #accessing }
CogSimStackNativeEntry >> constantInt64: anInteger [
	"Set the value of constant int64"

	^constantInt64 := anInteger
]

{ #category : #accessing }
CogSimStackNativeEntry >> constantNativePointer [
	"Answer the value of constant native pointer"
	self assert: type = SSConstantNativePointer.
	^constantNativePointer
]

{ #category : #accessing }
CogSimStackNativeEntry >> constantNativePointer: aNativePointer [
	"Set the value of constant int64"

	^constantNativePointer := aNativePointer
]

{ #category : #'compile abstract instructions' }
CogSimStackNativeEntry >> ensureIsMarkedAsSpilled [
	spilled ifFalse: [
		type caseOf: {
			[SSNativeRegister]	-> [ type := SSSpillNative ].
			[SSRegisterSingleFloat]	-> [ type := SSSpillFloat32 ].
			[SSRegisterDoubleFloat] -> [ type := SSSpillFloat64 ].
			[SSConstantFloat32] -> [ type := SSSpillFloat32. ].
			[SSConstantFloat64] -> [ type := SSSpillFloat64. ].
			[SSConstantInt32]	-> [ type := SSSpillNative. ].
			[SSConstantNativePointer]	-> [ type := SSSpillNative. ].
		}
	].

	spilled := true.

]

{ #category : #'compile abstract instructions' }
CogSimStackNativeEntry >> ensureSpilledSP: spRegister scratchRegister: scratchRegister [
	spilled ifFalse: [
		type caseOf: {
			[SSNativeRegister]	-> [
					cogit MoveR: register Mw: offset negated - 1 r: spRegister.
					type := SSSpillNative.
				].
			[SSRegisterSingleFloat]	-> [
					cogit MoveRs: register M32: offset negated - 1 r: spRegister.
					type := SSSpillFloat32.
				].
			[SSRegisterDoubleFloat] -> [
					cogit MoveRd: register M64: offset negated - 1 r: spRegister.
					type := SSSpillFloat64.
				].
			[SSConstantFloat32] -> [
				cogit MoveCw: constantFloat32 asIEEE32BitWord R: scratchRegister.
				cogit MoveR: scratchRegister M32: offset negated - 1 r: spRegister.
				type := SSSpillFloat32.
			].
			[SSConstantFloat64] -> [
				BytesPerWord == 4 ifTrue: [
					cogit MoveCw: (constantFloat64 asIEEE64BitWord bitAnd: 16rFFFFFFFF) R: scratchRegister.
					cogit MoveR: scratchRegister M32: offset negated - 1 r: spRegister.
					cogit MoveCw: (constantFloat64 asIEEE64BitWord bitShift: (self cCoerce: -32 to: #'sqLong')) R: scratchRegister.
					cogit MoveR: scratchRegister M32: offset negated - 1 + 4 r: spRegister.
				] ifFalse: [
					cogit MoveCw: constantFloat32 asIEEE64BitWord R: scratchRegister.
					cogit MoveR: scratchRegister Mw: offset negated - 1 r: spRegister.
				].
				type := SSSpillFloat64.
			].
			[SSConstantInt32]	-> [
					cogit MoveCq: constantInt32 R: scratchRegister.
					cogit MoveR: scratchRegister Mw: offset negated - 1 r: spRegister.
					type := SSSpillNative.
				].
			[SSConstantNativePointer]	-> [
					cogit MoveCw: constantNativePointer R: scratchRegister.
					cogit MoveR: scratchRegister Mw: offset negated - 1 r: spRegister.
					type := SSSpillNative.
				].
		}
	].

	spilled := true.


]

{ #category : #accessing }
CogSimStackNativeEntry >> nativeFloatRegisterMask [
	"Answer a bit mask for the receiver's register, if any."
	^ (type = SSRegisterSingleFloat or: [type = SSRegisterDoubleFloat])
			ifTrue: [cogit registerMaskFor: register]
			ifFalse: [0]
]

{ #category : #accessing }
CogSimStackNativeEntry >> nativeFloatRegisterOrNone [
	^ (type = SSRegisterSingleFloat or: [type = SSRegisterDoubleFloat])
		 ifTrue: [register]
		 ifFalse: [NoReg]
]

{ #category : #'compile abstract instructions' }
CogSimStackNativeEntry >> nativePopToReg: reg [
	spilled ifTrue: [
		cogit loadNativeFramePointerInto: TempReg.

		type caseOf: {
			[SSSpillNative]	-> [cogit MoveMw: offset negated - 1 r: TempReg R: reg].
			[SSSpillInt64]	-> [self assert: BytesPerWord = 8.
				cogit MoveMw: offset negated - 1 r: TempReg R: reg].
			[SSSpillFloat32]	-> [cogit MoveM32: offset negated - 1 r: TempReg Rs: reg.].
			[SSSpillFloat64]	-> [cogit MoveM64: offset negated - 1 r: TempReg Rd: reg.].}
	] ifFalse: [
		type caseOf: {
			[SSNativeRegister]	-> [reg ~= register
											ifTrue: [cogit MoveR: register R: reg]].
			[SSRegisterSingleFloat]	-> [reg ~= register
											ifTrue: [cogit MoveRs: register Rs: reg]].
			[SSRegisterDoubleFloat]	-> [reg ~= register
											ifTrue: [cogit MoveRd: register Rd: reg]].

			[SSConstantInt32]	-> [cogit MoveCq: constantInt32 R: reg].
			[SSConstantNativePointer]	-> [cogit MoveCw: constantNativePointer R: reg].
			[SSConstantFloat32] -> [ cogit MoveCf32: constantFloat32 Rs: reg. ].
			[SSConstantFloat64] -> [ cogit MoveCf64: constantFloat64 Rd: reg. ].
		 }
	].

]

{ #category : #'compile abstract instructions' }
CogSimStackNativeEntry >> nativePopToReg: reg secondReg: secondReg [
	self assert: BytesPerWord = 4.
	spilled ifTrue: [
			cogit PopR: reg; PopR: secondReg
		]
		ifFalse: [
			type caseOf: {
				[SSConstantInt64]	-> [
					cogit MoveCq: (constantInt64 bitAnd: 16rFFFFFFFF) R: reg.
					cogit MoveCq: ((constantInt64 >> 32) bitAnd: 16rFFFFFFFF) R: secondReg.
					].
				[SSRegisterPair]	-> [
					cogit Label.
					reg ~= register ifTrue: [
						registerSecond = reg ifTrue: [
							cogit MoveR: registerSecond R: TempReg.
						].
						cogit MoveR: register R: reg
					].

					registerSecond ~= secondReg ifTrue: [
						registerSecond = reg ifTrue: [
							cogit MoveR: TempReg R: secondReg.
						] ifFalse: [
							cogit MoveR: registerSecond R: secondReg.
						]
					].
				].
			}
		].

]

{ #category : #accessing }
CogSimStackNativeEntry >> nativeRegisterMask [
	"Answer a bit mask for the receiver's register, if any."
	^(((type = SSBaseOffset
		or: [type = SSNativeRegister])
		or: [type = SSRegisterSingleFloat])
		or: [type = SSRegisterDoubleFloat])
			ifTrue: [cogit registerMaskFor: register]
			ifFalse: [
				type = SSRegisterPair ifTrue: [(cogit registerMaskFor: register) bitOr: (cogit registerMaskFor: registerSecond)]
					ifFalse: [0]]
]

{ #category : #accessing }
CogSimStackNativeEntry >> nativeRegisterOrNone [
	^(type = SSNativeRegister or: [type = SSRegisterPair])
		 ifTrue: [register]
		 ifFalse: [NoReg]
]

{ #category : #accessing }
CogSimStackNativeEntry >> nativeRegisterSecondOrNone [
	^type = SSRegisterPair
		 ifTrue: [registerSecond]
		 ifFalse: [NoReg]
]

{ #category : #'compile abstract instructions' }
CogSimStackNativeEntry >> nativeStackPopToReg: reg [
	self assert: spilled.

		type caseOf: {
			[SSSpillNative]	-> [cogit MoveMw: offset negated r: FPReg R: reg].
			[SSSpillInt64]	-> [self assert: BytesPerWord = 8.
				cogit MoveMw: offset negated r: FPReg R: reg].
			[SSSpillFloat32]	-> [cogit MoveM32: offset negated r: FPReg Rs: reg.].
			[SSSpillFloat64]	-> [cogit MoveM64: offset negated r: FPReg Rd: reg.].
	}
]

{ #category : #'compile abstract instructions' }
CogSimStackNativeEntry >> nativeStackPopToReg: reg secondReg: secondReg [
	self assert: spilled.

		type caseOf: {
			[SSSpillInt64]	-> [cogit MoveMw: offset negated + 4 r: FPReg R: reg.
							     cogit MoveMw: offset negated r: FPReg R: secondReg].
	}
]

{ #category : #'compile abstract instructions' }
CogSimStackNativeEntry >> nativeStoreToReg: reg [
	"FIXME: Duplicated code with popToReg:"
	spilled ifTrue: [cogit loadNativeFramePointerInto: TempReg.].

	type caseOf: {
		[SSSpillNative]	-> [cogit MoveMw: offset negated - 1 r: TempReg R: reg].
		[SSSpillFloat32]	-> [cogit MoveM32: offset negated - 1 r: TempReg Rs: reg.].
		[SSSpillFloat64]	-> [cogit MoveM64: offset negated - 1 r: TempReg Rd: reg.].
		[SSNativeRegister]	-> [reg ~= register
										ifTrue: [cogit MoveR: register R: reg]
										ifFalse: [cogit Label]].
		[SSRegisterSingleFloat]	-> [reg ~= register
										ifTrue: [cogit MoveRs: register Rs: reg]
										ifFalse: [cogit Label]].
		[SSRegisterDoubleFloat]	-> [reg ~= register
										ifTrue: [cogit MoveRd: register Rd: reg]
										ifFalse: [cogit Label]].

		[SSConstantInt32]	-> [cogit MoveCw: constantInt32 R: reg].
		[SSConstantNativePointer]	-> [cogit MoveCw: constantNativePointer R: reg].
		[SSConstantFloat32] -> [ cogit MoveCf32: constantFloat32 Rs: reg. ].
		[SSConstantFloat64] -> [ cogit MoveCf64: constantFloat64 Rd: reg. ].
	}.
]

{ #category : #'compile abstract instructions' }
CogSimStackNativeEntry >> nativeStoreToReg: reg secondReg: secondReg [
	self assert: BytesPerWord = 4.
	"FIXME: Duplicated code with popToReg:secondReg:"
	type caseOf: {
		[SSBaseOffset]	-> [
				cogit MoveMw: offset r: register R: reg.
				cogit MoveMw: offset + 4 r: register R: secondReg.
			].
		[SSSpillInt64]	-> [
				cogit MoveMw: offset r: register R: reg.
				cogit MoveMw: offset + 4 r: registerSecond R: secondReg
			].
		[SSRegisterPair]	-> [
				cogit Label.
				reg ~= register ifTrue: [
					registerSecond = reg ifTrue: [
						cogit MoveR: registerSecond R: TempReg.
					].
					cogit MoveR: register R: reg
				].

				registerSecond ~= secondReg ifTrue: [
					registerSecond = reg ifTrue: [
						cogit MoveR: TempReg R: secondReg.
					] ifFalse: [
						cogit MoveR: registerSecond R: secondReg.
					]
				].
			].
		[SSConstantInt64]	-> [
			self MoveCq: (constantInt64 bitAnd: 16rFFFFFFFF) R: reg.
			self MoveCq: ((constantInt64 >> 32) bitAnd: 16rFFFFFFFF) R: secondReg.
		].
	}.

]

{ #category : #accessing }
CogSimStackNativeEntry >> offset [
	<doNotGenerate>
	"Answer the value of offset"
	^offset
]

{ #category : #accessing }
CogSimStackNativeEntry >> offset: anObject [
	<doNotGenerate>
	"Set the value of offset"

	^offset := anObject
]

{ #category : #printing }
CogSimStackNativeEntry >> printStateOn: aStream [
	<doNotGenerate> "Smalltalk-side only"
	type isInteger ifFalse: [^self].
	aStream nextPut: $(.
	type caseOf: {
		[SSNativeRegister]	-> [aStream
								nextPutAll: 'reg ';
								nextPutAll: (CogRTLOpcodes nameForRegister: register)].
		[SSRegisterPair]	-> [aStream
								nextPutAll: 'reg ';
								nextPutAll: (CogRTLOpcodes nameForRegister: register);
								nextPutAll: '+';
								nextPutAll: (CogRTLOpcodes nameForRegister: registerSecond).].
		[SSRegisterSingleFloat]	-> [aStream
								nextPutAll: 'regFloat32 ';
								nextPutAll: (CogRTLOpcodes nameForRegister: register)].
		[SSRegisterDoubleFloat]	-> [aStream
								nextPutAll: 'regFloat64 ';
								nextPutAll: (CogRTLOpcodes nameForRegister: register)].

		[SSSpillNative]		-> [aStream
								nextPutAll: 'spillNative @ '.
							offset negative ifFalse: [aStream nextPut: $+].
							aStream print: offset].
		[SSSpillInt64]		-> [aStream
								nextPutAll: 'spillInt64 @ '.
							offset negative ifFalse: [aStream nextPut: $+].
							aStream print: offset].
		[SSSpillFloat32]		-> [aStream
								nextPutAll: 'spillFloat32 @ '.
							offset negative ifFalse: [aStream nextPut: $+].
							aStream print: offset].
		[SSSpillFloat64]		-> [aStream
								nextPutAll: 'spillFloat64 @ '.
							offset negative ifFalse: [aStream nextPut: $+].
							aStream print: offset].

		[SSConstantInt32]		-> [aStream
								nextPutAll: 'constInt32 ';
								print: constantInt32].
		[SSConstantInt64]		-> [aStream
								nextPutAll: 'constInt64 ';
								print: constantInt64].
		[SSConstantFloat32]		-> [aStream
								nextPutAll: 'constFloat32 ';
								print: constantFloat32].
		[SSConstantFloat64]		-> [aStream
								nextPutAll: 'constFloat64 ';
								print: constantFloat64].
		[SSConstantNativePointer]	-> [aStream
								nextPutAll: 'constNativePointer ';
								print: constantNativePointer]
 }.
	spilled ifTrue:
		[aStream nextPutAll: ' (spilled)'].
	bcptr ifNotNil:
		[aStream space; nextPut: ${; print: bcptr; nextPut: $}].
	aStream nextPut: $)
]

{ #category : #accessing }
CogSimStackNativeEntry >> register [
	<doNotGenerate>
	"Answer the value of register"
	self assert: ((([type = SSNativeRegister] or: [type = SSRegisterPair]) or: [type = SSRegisterSingleFloat]) or: [type = SSRegisterDoubleFloat]).
	^register
]

{ #category : #accessing }
CogSimStackNativeEntry >> register: anObject [
	<doNotGenerate>
	"Set the value of register"

	^register := anObject
]

{ #category : #accessing }
CogSimStackNativeEntry >> registerSecond [
	"Answer the value of register"
	self assert: type = SSRegisterPair.
	^ registerSecond
]

{ #category : #accessing }
CogSimStackNativeEntry >> registerSecond: anObject [
	"Set the value of register"

	^registerSecond := anObject
]

{ #category : #accessing }
CogSimStackNativeEntry >> registerSecondOrNil [
	^ type = SSRegisterPair ifTrue: [registerSecond]
]

{ #category : #accessing }
CogSimStackNativeEntry >> spilled [
	"Answer the value of spilled"

	^ spilled
]

{ #category : #accessing }
CogSimStackNativeEntry >> spilled: anObject [
	"Set the value of spilled"

	^spilled := anObject
]

{ #category : #'compile abstract instructions' }
CogSimStackNativeEntry >> spillingNeedsScratchRegister [
	spilled ifFalse: [
		type caseOf: {
			[SSConstantInt32]	-> [ ^ true ].
			[SSConstantInt64]	-> [ ^ true ].
			[SSConstantFloat32]	-> [ ^ true ].
			[SSConstantFloat64]	-> [ ^ true ].
			[SSConstantNativePointer]	-> [ ^ true ].
		}
		otherwise: [^ false]
	].

	^ false.

]

{ #category : #accessing }
CogSimStackNativeEntry >> stackSpillSize [
	<returnTypeC: #sqInt>
	type caseOf: {
		[SSConstantInt64]			-> [ ^ 8 ].
		[SSConstantFloat64]		-> [ ^ 8 ].
		[SSRegisterDoubleFloat]	-> [ ^ 8 ].
		[SSRegisterPair]			-> [ ^ 8 ].
		[SSSpillFloat64]				-> [ ^ 8 ].
		[SSSpillInt64]				-> [ ^ 8 ].
	} otherwise: [^ BytesPerOop ].
	^ 0
]

{ #category : #accessing }
CogSimStackNativeEntry >> type [
	"Answer the value of type"

	^ type
]

{ #category : #accessing }
CogSimStackNativeEntry >> type: anObject [
	"Set the value of type"

	^type := anObject
]
