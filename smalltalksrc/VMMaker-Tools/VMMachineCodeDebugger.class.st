Class {
	#name : #VMMachineCodeDebugger,
	#superclass : #SpPresenter,
	#instVars : [
		'cogit',
		'machineSimulator',
		'instructions',
		'stepButton',
		'machineState'
	],
	#category : #'VMMaker-Tools'
}

{ #category : #specs }
VMMachineCodeDebugger class >> defaultSpec [

	^ SpBoxLayout newHorizontal
		add: #instructions;
		add: (SpBoxLayout newVertical
			add: #machineState;
			add: #stepButton;
			yourself);
		yourself
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
	
	instructionsContextMenu := SpMenuPresenter new.
	instructionsContextMenu addItem: [ :item |
		item 
			name: 'Set Intruction Pointer Here'; 
			action: [ self setInstructionPointerToSelectedInstruction ] ].
	instructions contextMenu: instructionsContextMenu
]

{ #category : #showing }
VMMachineCodeDebugger >> initialDisassembly [

	^ LLVMDisassembler amd64 
		disassembleNext: 50
		instructionsIn: (cogit objectMemory memory memoryObject
			copyFrom: machineSimulator instructionPointerValue - cogit objectMemory memory initialAddress + 1
			to: cogit objectMemory memory memoryObject size)
		startAddress: machineSimulator instructionPointerValue
		pc: machineSimulator instructionPointerValue 
]

{ #category : #initialization }
VMMachineCodeDebugger >> initializePresenters [

	machineState := self newTable.
	machineState
		addColumn: (SpStringTableColumn evaluated: #name);
		addColumn: (SpStringTableColumn evaluated: [ :register | register value hex ]).

	instructions := self newTable.
	instructions
		addColumn: (SpStringTableColumn evaluated: [ :item | item address hex ]);
		addColumn:
			((SpImageTableColumn evaluated: [ :item | 
				item address = machineSimulator instructionPointerValue
					ifTrue: [ self iconNamed: #forward ] ])
				width: 50;
				yourself);
		addColumn: (SpStringTableColumn evaluated: #assemblyCodeString).
	
	stepButton := self newButton.
	stepButton label: 'Step'
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

	machineState items: machineSimulator registerDescriptors.
	instructions items: self initialDisassembly.
	super openWithSpec.
]

{ #category : #actions }
VMMachineCodeDebugger >> setInstructionPointerToSelectedInstruction [
	
	machineSimulator instructionPointerValue: instructions selection selectedItem address
]

{ #category : #initialization }
VMMachineCodeDebugger >> step [

	machineSimulator step
]
