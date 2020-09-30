Class {
	#name : #VMContextAccessTest,
	#superclass : #VMSimpleStackBasedCogitAbstractTest,
	#category : #'VMMakerTests-JitTests'
}

{ #category : #'as yet unclassified' }
VMContextAccessTest >> assertContext: newContext equals: contextOop onInstVar: anIndex [ 

	| originalPC copiedPC |
	interpreter longPrintOop: contextOop.
	interpreter longPrintOop: newContext.

	originalPC := interpreter externalInstVar: anIndex ofContext: contextOop. 
	copiedPC := interpreter externalInstVar: anIndex ofContext: newContext. 
	
	self assert: copiedPC  equals: originalPC
]

{ #category : #tests }
VMContextAccessTest >> pushActiveContext [

	interpreter internalizeIPandSP.
	interpreter pushActiveContextBytecode.
	interpreter externalizeIPandSP.

	^ interpreter stackTop.

]

{ #category : #running }
VMContextAccessTest >> setUp [
	
	"taken from VMSimpleStackBasedCogitBytecodeTest >> #setup"
	| newMethod ctx page |
	super setUp.

	"Create the root context with a valid method"
	"Let's create a method with enough size. It should have at least a literal (4 or 8 bytes depending the word size) and some bytecodes, so we can put the IP inside the method"
	newMethod := methodBuilder newMethod buildMethod.
	
	"The context has 5 (in 32 bits) or 9 (in 64 bits) as initial IP, as method has at least one literal"
	ctx := self newSmallContextReceiver: memory nilObject method: newMethod arguments: #() temporaries: #() ip: self wordSize + 1.

	"The base context has a trampoline as the savedIP so it can return to a context that is in the heap"
	cogit ceBaseFrameReturnTrampoline: 16rAABBCCDD.	
	
	page := interpreter makeBaseFrameFor: ctx.
	interpreter setStackPointersFromPage: page.
	interpreter setStackPageAndLimit: page.
	interpreter instructionPointer: interpreter popStack.
	
	self setUpScheduler.
	self setContextClassIntoClassTable.

	self initializeOldSpaceForFullGC.

]

{ #category : #tests }
VMContextAccessTest >> testCloningTopContextHasCorrectPC [
		
	| contextOop newContext |

	contextOop := self pushActiveContext.
	interpreter primitiveClone.

	newContext := interpreter popStack.
	
	self assertContext: newContext equals: contextOop onInstVar: InstructionPointerIndex.

]

{ #category : #tests }
VMContextAccessTest >> testCloningTopContextHasCorrectPCAfterFullGC [
		
	| contextOop newContext |

	contextOop := self pushActiveContext.

	CloneOnGC := false.	
	memory fullGC.
	
	interpreter primitiveClone.

	newContext := interpreter popStack.
	
	self assertContext: newContext equals: contextOop onInstVar: InstructionPointerIndex.

]

{ #category : #tests }
VMContextAccessTest >> testCloningTopContextHasCorrectReceiver [
		
	| contextOop newContext |

	contextOop := self pushActiveContext.
	interpreter primitiveClone.

	newContext := interpreter popStack.
	
	self assertContext: newContext equals: contextOop onInstVar: ReceiverIndex.
	

]

{ #category : #tests }
VMContextAccessTest >> testCloningTopContextHasCorrectSenderWhenItIsNil [
		
	| contextOop newContext |

	contextOop := self pushActiveContext.
	interpreter primitiveClone.

	newContext := interpreter popStack.
	
	self assertContext: newContext equals: contextOop onInstVar: SenderIndex.
	

]
