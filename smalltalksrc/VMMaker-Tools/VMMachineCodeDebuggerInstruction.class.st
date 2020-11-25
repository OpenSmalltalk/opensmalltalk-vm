Class {
	#name : #VMMachineCodeDebuggerInstruction,
	#superclass : #Object,
	#instVars : [
		'instruction',
		'bytes',
		'machineSimulator',
		'debugger'
	],
	#category : #'VMMaker-Tools'
}

{ #category : #accessing }
VMMachineCodeDebuggerInstruction >> address [
	
	^ instruction address
]

{ #category : #printing }
VMMachineCodeDebuggerInstruction >> addressString [
	
	^ instruction address hex
]

{ #category : #printing }
VMMachineCodeDebuggerInstruction >> assemblyCodeString [

	^ instruction assemblyCodeString 
]

{ #category : #accessing }
VMMachineCodeDebuggerInstruction >> branchTargetAddress [
	
	^ instruction branchTargetAddress
]

{ #category : #accessor }
VMMachineCodeDebuggerInstruction >> bytes: aByteArray [ 
	bytes := aByteArray
]

{ #category : #printing }
VMMachineCodeDebuggerInstruction >> bytesString [
	
	^ bytes printString
]

{ #category : #accessing }
VMMachineCodeDebuggerInstruction >> debugger: aVMMachineCodeDebugger [ 
	
	debugger := aVMMachineCodeDebugger
]

{ #category : #showing }
VMMachineCodeDebuggerInstruction >> icon [

	self address = machineSimulator instructionPointerValue 
		ifTrue: [ ^ self iconNamed: #forward ].
	
	debugger selectedInstruction 
		ifNotNil: [ :selectedInstruction |
				selectedInstruction branchTargetAddress = self address 
					ifTrue: [ ^ self iconNamed: #glamorousInto ]].

	^ nil
]

{ #category : #accessing }
VMMachineCodeDebuggerInstruction >> instruction: aLLVMInstruction [ 
	instruction := aLLVMInstruction
]

{ #category : #accessing }
VMMachineCodeDebuggerInstruction >> machineSimulator: anUnicornARMv8Simulator [ 
	machineSimulator := anUnicornARMv8Simulator
]
