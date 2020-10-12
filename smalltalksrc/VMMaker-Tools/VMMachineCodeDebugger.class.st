Class {
	#name : #VMMachineCodeDebugger,
	#superclass : #SpPresenter,
	#instVars : [
		'cogit',
		'machineSimulator',
		'instructions',
		'stepButton',
		'disassembleAtPCButton',
		'machineState',
		'initialInstructionToDisassemble',
		'stack',
		'ipInput',
		'jumpToButton'
	],
	#category : #'VMMaker-Tools'
}

{ #category : #specs }
VMMachineCodeDebugger class >> defaultSpec [

	^ SpBoxLayout newHorizontal
		add: #instructions;
		add: (SpBoxLayout newVertical
			add: #machineState;
			add: (SpBoxLayout newHorizontal
				add: #ipInput;
				add: #jumpToButton);
			add: #stepButton;
			add: #disassembleAtPCButton;
			yourself);
		add: #stack;
		yourself
]

{ #category : #'as yet unclassified' }
VMMachineCodeDebugger class >> openOnCogit: aCogit [ 

	self openOnCogit: aCogit ip: aCogit processor machineSimulator pc
]

{ #category : #'as yet unclassified' }
VMMachineCodeDebugger class >> openOnCogit: aCogit ip: anInstructionPointer [

	self new
		cogit: aCogit;
		machineSimulator: aCogit processor machineSimulator;
		initialInstructionToDisassemble: anInstructionPointer;
		openWithSpec.
]

{ #category : #accessing }
VMMachineCodeDebugger >> cogit [
	^ cogit
]

{ #category : #accessing }
VMMachineCodeDebugger >> cogit: anObject [
	cogit := anObject
]

{ #category : #initialization }
VMMachineCodeDebugger >> connectPresenters [

	| instructionsContextMenu |
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
	instructions contextMenu: instructionsContextMenu.
	
	jumpToButton action: [ self jump ].
]

{ #category : #actions }
VMMachineCodeDebugger >> disassembleAtPC [

	self initialInstructionToDisassemble:  machineSimulator instructionPointerValue.
	self refreshInstructions.
]

{ #category : #showing }
VMMachineCodeDebugger >> initialDisassembly [

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
VMMachineCodeDebugger >> initialExtent [ 

	^ 1000@1000
]

{ #category : #showing }
VMMachineCodeDebugger >> initialInstructionToDisassemble [

	^ initialInstructionToDisassemble
		ifNil: [ machineSimulator instructionPointerValue ]
]

{ #category : #showing }
VMMachineCodeDebugger >> initialInstructionToDisassemble: anInstructionAddress [

	initialInstructionToDisassemble := anInstructionAddress
]

{ #category : #initialization }
VMMachineCodeDebugger >> initializePresenters [

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
		addColumn: (SpStringTableColumn evaluated: [ :aPosition | aPosition specialRegister ] );
		addColumn: (SpStringTableColumn evaluated: [ :aPosition | aPosition address hex ] );
		addColumn: (SpStringTableColumn evaluated: [ :aPosition | 
			[aPosition value hex] on: Error do: [ 'Error' ] ]).
	
	stepButton := self newButton.
	stepButton label: 'Step'.
	
	disassembleAtPCButton := self newButton.
	disassembleAtPCButton label: 'Disassemble at PC'.
	
	ipInput := self newTextInput.
	jumpToButton := self newButton.
	jumpToButton label: 'Jump to'
]

{ #category : #actions }
VMMachineCodeDebugger >> jump [

	machineSimulator instructionPointerValue: (NumberParser parse: ipInput text).
	self refreshInstructions.
	self refreshRegisters.
]

{ #category : #accessing }
VMMachineCodeDebugger >> machineSimulator [
	^ machineSimulator
]

{ #category : #accessing }
VMMachineCodeDebugger >> machineSimulator: anObject [
	machineSimulator := anObject
]

{ #category : #showing }
VMMachineCodeDebugger >> openWithSpec [

	self refreshRegisters.
	self refreshInstructions.
	self refreshStack.
	
	super openWithSpec.
]

{ #category : #showing }
VMMachineCodeDebugger >> refreshInstructions [

	instructions items: self initialDisassembly
]

{ #category : #showing }
VMMachineCodeDebugger >> refreshRegisters [

	machineState items: machineSimulator registerDescriptors
]

{ #category : #showing }
VMMachineCodeDebugger >> refreshStack [

	stack items: machineSimulator stackValues
]

{ #category : #'as yet unclassified' }
VMMachineCodeDebugger >> runToSelectedInstruction [
	
	| selectedInstruction |

	selectedInstruction := self selectedInstruction.

	machineSimulator startAt: machineSimulator instructionPointerValue until: selectedInstruction address timeout: 1000 count: 0.
	self refreshStack.
]

{ #category : #'as yet unclassified' }
VMMachineCodeDebugger >> selectedInstruction [

	^ instructions selection selectedItem
]

{ #category : #actions }
VMMachineCodeDebugger >> setInstructionPointerToSelectedInstruction [
	
	machineSimulator instructionPointerValue: instructions selection selectedItem address
]

{ #category : #actions }
VMMachineCodeDebugger >> step [

	machineSimulator step.
	self refreshStack.
	self refreshRegisters
]
