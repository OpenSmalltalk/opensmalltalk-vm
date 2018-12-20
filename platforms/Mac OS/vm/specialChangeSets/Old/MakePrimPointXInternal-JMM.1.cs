'From Squeak3.6beta of ''4 July 2003'' [latest update: #5331] on 9 July 2003 at 12:01:38 am'!
"Change Set:		MakePrimPointXInternal-JMM
Date:			9 July 2003
Author:			johnmci@smalltalkconsulting.com

Also rearranged the primitivePointX/Y logic to interpret() internalize"!


!Interpreter methodsFor: 'contexts' stamp: 'jmm 7/8/2003 15:46'!
internalUnPop: nItems
	localSP _ localSP + (nItems*4)! !

!Interpreter methodsFor: 'common selector sends' stamp: 'jmm 7/8/2003 15:57'!
bytecodePrimPointX

	successFlag _ true.
	self primitivePointX.
	successFlag ifTrue: [^ self fetchNextBytecode "success"].

	messageSelector _ self specialSelector: 30.
	argumentCount _ 0.
	self normalSend! !

!Interpreter methodsFor: 'common selector sends' stamp: 'jmm 7/8/2003 15:57'!
bytecodePrimPointY

	successFlag _ true.
	self primitivePointY.
	successFlag ifTrue: [^ self fetchNextBytecode "success"].

	messageSelector _ self specialSelector: 31.
	argumentCount _ 0.
	self normalSend! !

!Interpreter methodsFor: 'object access primitives' stamp: 'jmm 7/8/2003 15:53'!
primitivePointX
	| rcvr | 
	self inline: true.
	rcvr _ self internalStackTop.
	self internalPop: 1.	
	self assertClassOf: rcvr is: (self splObj: ClassPoint).
	successFlag
		ifTrue: [self internalPush: (self fetchPointer: XIndex ofObject: rcvr)]
		ifFalse: [self internalUnPop: 1]! !

!Interpreter methodsFor: 'object access primitives' stamp: 'jmm 7/8/2003 15:53'!
primitivePointY
	| rcvr | 
	self inline: true.
	rcvr _ self internalStackTop.
	self internalPop: 1.	
	self assertClassOf: rcvr is: (self splObj: ClassPoint).
	successFlag
		ifTrue: [self internalPush: (self fetchPointer: YIndex ofObject: rcvr)]
		ifFalse: [self internalUnPop: 1]! !

