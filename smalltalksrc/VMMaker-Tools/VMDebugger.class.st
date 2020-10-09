Class {
	#name : #VMDebugger,
	#superclass : #SpPresenter,
	#instVars : [
		'virtualMachine',
		'cogit',
		'machineSimulator',
		'instructions',
		'stepButton',
		'disassembleAtPCButton',
		'machineState',
		'initialInstructionToDisassemble',
		'stack',
		'frameContainer'
	],
	#category : #'VMMaker-Tools'
}

{ #category : #specs }
VMDebugger class >> defaultSpec [

	^ SpBoxLayout newHorizontal
		add: #stack;
		add: (SpBoxLayout newVertical
			add: #frameContainer;
			yourself);
		yourself
]

{ #category : #'as yet unclassified' }
VMDebugger class >> openOn: aVirtualMachine [

	self new
		virtualMachine: aVirtualMachine;
		openWithSpec.
]

{ #category : #accessing }
VMDebugger >> cogit [
	^ cogit
]

{ #category : #accessing }
VMDebugger >> cogit: anObject [
	cogit := anObject
]

{ #category : #initialization }
VMDebugger >> connectPresenters [

	| instructionsContextMenu |
	stack whenSelectionChangedDo: [ :selection |
		selection isEmpty ifFalse: [ self selectFrame: selection selectedItem ] ].
	
	stepButton action: [ self step ].
	disassembleAtPCButton action: [ self disassembleAtPC ].
	
	instructionsContextMenu := SpMenuPresenter new.
	instructionsContextMenu addItem: [ :item |
		item 
			name: 'Set Intruction Pointer Here'; 
			action: [ self setInstructionPointerToSelectedInstruction ] ].

	instructionsContextMenu addItem: [ :item |
		item 
			name: 'Run to Here'; 
			action: [ self runToSelectedInstruction ] ].

	instructionsContextMenu addItem: [ :item |
		item 
			name: 'Inspect'; 
			action: [ instructions selection selectedItem inspect ] ].
	instructions contextMenu: instructionsContextMenu
]

{ #category : #actions }
VMDebugger >> disassembleAtPC [

	self initialInstructionToDisassemble:  machineSimulator instructionPointerValue.
	self refreshInstructions.
]

{ #category : #showing }
VMDebugger >> initialDisassembly [

	^ machineSimulator disassembler
		printImmediatesInHexa;
		useAlternatePrinterVariant;
		disassembleNext: 150
		instructionsIn: (cogit objectMemory memory memoryObject
			copyFrom: self initialInstructionToDisassemble - cogit objectMemory memory initialAddress + 1
			to: self initialInstructionToDisassemble - cogit objectMemory memory initialAddress + 600)
		startAddress: self initialInstructionToDisassemble
		pc: machineSimulator instructionPointerValue 
]

{ #category : #showing }
VMDebugger >> initialExtent [ 

	^ 1000@1000
]

{ #category : #showing }
VMDebugger >> initialInstructionToDisassemble [

	^ initialInstructionToDisassemble
		ifNil: [ machineSimulator instructionPointerValue ]
]

{ #category : #showing }
VMDebugger >> initialInstructionToDisassemble: anInstructionAddress [

	initialInstructionToDisassemble := anInstructionAddress
]

{ #category : #initialization }
VMDebugger >> initializePresenters [

	machineState := self newTable.
	machineState
		addColumn: (SpStringTableColumn evaluated: #name);
		addColumn: (SpStringTableColumn evaluated: #alias);
		addColumn: (SpStringTableColumn evaluated: [ :register | register printString ]).

	instructions := self newTable.
	instructions
		addColumn: (SpStringTableColumn evaluated: [ :item | item address hex ]);
		addColumn:
			((SpImageTableColumn evaluated: [ :item | 
				item address = machineSimulator instructionPointerValue
					ifTrue: [ self iconNamed: #forward ] ])
				width: 50;
				yourself);
		addColumn: (SpStringTableColumn evaluated: #assemblyCodeString);
		addColumn: (SpStringTableColumn evaluated: [:e | e codeBytesString: cogit objectMemory memory ]).
	
	stack := self newTable.
	stack
"		addColumn: (SpStringTableColumn evaluated: [ :aPosition | aPosition specialRegister ] );"
		addColumn: (SpStringTableColumn evaluated: [ :aFrame | aFrame description ] )
"		addColumn: (SpStringTableColumn evaluated: [ :aPosition | 
			[aPosition value hex] on: Error do: [ 'Error' ] ])".
	
	frameContainer := self newCode.
	
	stepButton := self newButton.
	stepButton label: 'Step'.
	
	disassembleAtPCButton := self newButton.
	disassembleAtPCButton label: 'Disassemble at PC'
]

{ #category : #accessing }
VMDebugger >> machineSimulator [
	^ machineSimulator
]

{ #category : #accessing }
VMDebugger >> machineSimulator: anObject [
	machineSimulator := anObject
]

{ #category : #showing }
VMDebugger >> openWithSpec [

"	self refreshRegisters.
	self refreshInstructions.
"	self refreshStack.
	
	super openWithSpec.
]

{ #category : #showing }
VMDebugger >> refreshInstructions [

	instructions items: self initialDisassembly
]

{ #category : #showing }
VMDebugger >> refreshRegisters [

	machineState items: machineSimulator registerDescriptors
]

{ #category : #showing }
VMDebugger >> refreshStack [

	stack items: virtualMachine stack
]

{ #category : #'as yet unclassified' }
VMDebugger >> runToSelectedInstruction [
	
	| selectedInstruction |

	selectedInstruction := self selectedInstruction.

	machineSimulator startAt: machineSimulator instructionPointerValue until: selectedInstruction address timeout: 1000 count: 0.
	self refreshStack.
]

{ #category : #events }
VMDebugger >> selectFrame: aVMStackFrame [ 
	
	frameContainer text: aVMStackFrame sourceCode
]

{ #category : #'as yet unclassified' }
VMDebugger >> selectedInstruction [

	^ instructions selection selectedItem
]

{ #category : #actions }
VMDebugger >> setInstructionPointerToSelectedInstruction [
	
	machineSimulator instructionPointerValue: instructions selection selectedItem address
]

{ #category : #actions }
VMDebugger >> step [

	machineSimulator step.
	self refreshStack.
	self refreshRegisters
]

{ #category : #accessing }
VMDebugger >> virtualMachine [
	^ virtualMachine
]

{ #category : #accessing }
VMDebugger >> virtualMachine: anObject [
	virtualMachine := anObject
]
