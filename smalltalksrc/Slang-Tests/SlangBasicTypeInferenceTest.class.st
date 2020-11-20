"
Basic tests for the type inference used in CCodeGenerator.
Support methods are in SlangTypeInferenceTestClass.
There is only one possible type by node, no ambiguities.

1 Constant
	test constantNode in a method.
	tests are tailor made for the current TConstantNode >> #typeOrNilFrom:in:.

2 Return-constant
	test return a constant node in a method.
	uses the previous categorie's values.

3 Return-temp-assigned-constant
	assign a temporary node with a constant
	then returns the temporary variable in the next statement.
	
4 Return-temp-assigned-message
	assign a temporary node with a message
	then returns the temporary variable in the next statement.
	
5 Return-explicit-temp
	returns a temporary typed by a pragma #var:type:.

6 Return-explicit-arg
	returns an argument typed by a pragma #var:type:.
"
Class {
	#name : #SlangBasicTypeInferenceTest,
	#superclass : #SlangAbstractTestCase,
	#category : #'Slang-Tests'
}

{ #category : #running }
SlangBasicTypeInferenceTest >> setUp [
	super setUp.
	ccg addClass: SlangBasicTypeInferenceTestClass.
	ccg inferTypes.

]

{ #category : #constant }
SlangBasicTypeInferenceTest >> testABigNegativeIntegerConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #aBigNegativeIntegerConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'long long'
]

{ #category : #constant }
SlangBasicTypeInferenceTest >> testAFalseConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #aFalseConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int
]

{ #category : #constant }
SlangBasicTypeInferenceTest >> testAFloatConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #aFloatConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #double
]

{ #category : #constant }
SlangBasicTypeInferenceTest >> testANilConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #aNilConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int
]

{ #category : #constant }
SlangBasicTypeInferenceTest >> testASmallNegativeIntegerConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #aSmallNegativeIntegerConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int
]

{ #category : #constant }
SlangBasicTypeInferenceTest >> testAStringConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #aStringConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'char *'
]

{ #category : #constant }
SlangBasicTypeInferenceTest >> testATrueConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #aTrueConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int
]

{ #category : #constant }
SlangBasicTypeInferenceTest >> testAnIntEqual32ConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #anIntEqual32ConstantNode.
		
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'unsigned int'
]

{ #category : #constant }
SlangBasicTypeInferenceTest >> testAnIntEqual64ConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #anIntEqual64ConstantNode.
		
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'unsigned long long'
]

{ #category : #constant }
SlangBasicTypeInferenceTest >> testAnIntGreater64ConstantNode [
	| tMethod |
	<expectedFailure>
	tMethod := ccg methodNamed: #anIntGreater64ConstantNode.
		
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'long long'
]

{ #category : #constant }
SlangBasicTypeInferenceTest >> testAnIntLess32ConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #anIntLesser32ConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int.

]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTest >> testReturnABigNegativeIntegerConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnABigNegativeIntegerConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'long long'.
	self assert: tMethod returnType equals: #sqLong
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTest >> testReturnABigNegativeIntegerMessageSend [
	| tMethod |
	tMethod := ccg methodNamed: #returnABigNegativeIntegerMessageSend.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqLong.
	self assert: (ccg typeFor: tMethod statements first expression in: tMethod) equals: #sqLong.
	self assert: tMethod returnType equals: #sqLong.
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTest >> testReturnAFalseConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnAFalseConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int.
	self assert: tMethod returnType equals: #sqInt
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTest >> testReturnAFalseMessageSend [
	| tMethod |
	tMethod := ccg methodNamed: #returnAFalseMessageSend.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt.
	self assert: (ccg typeFor: tMethod statements first expression in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTest >> testReturnAFloatMessageSend [
	| tMethod |
	tMethod := ccg methodNamed: #returnAFloatMessageSend.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #double.
	self assert: (ccg typeFor: tMethod statements first expression in: tMethod) equals: #double.
	self assert: tMethod returnType equals: #double.
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTest >> testReturnANilConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnANilConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int.
	self assert: tMethod returnType equals: #sqInt
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTest >> testReturnANilMessageSend [
	| tMethod |
	tMethod := ccg methodNamed: #returnANilMessageSend.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt.
	self assert: (ccg typeFor: tMethod statements first expression in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTest >> testReturnASmallNegativeIntegerConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnASmallNegativeIntegerConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int.
	self assert: tMethod returnType equals: #sqInt
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTest >> testReturnASmallNegativeIntegerMessageSend [
	| tMethod |
	tMethod := ccg methodNamed: #returnASmallNegativeIntegerMessageSend.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt.
	self assert: (ccg typeFor: tMethod statements first expression in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTest >> testReturnAStringConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnAStringConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'char *'.
	self assert: tMethod returnType equals: #'char *'
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTest >> testReturnAStringMessageSend [
	| tMethod |
	tMethod := ccg methodNamed: #returnAStringMessageSend.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'char *'.
	self assert: (ccg typeFor: tMethod statements first expression in: tMethod) equals: #'char *'.
	self assert: tMethod returnType equals: #'char *'.
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTest >> testReturnATrueConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnATrueConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int.
	self assert: tMethod returnType equals: #sqInt
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTest >> testReturnATrueMessageSend [
	| tMethod |
	tMethod := ccg methodNamed: #returnATrueMessageSend.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt.
	self assert: (ccg typeFor: tMethod statements first expression in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTest >> testReturnAnIntEqual32ConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnAnIntEqual32ConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'unsigned int'.
	self assert: tMethod returnType equals: #sqInt
	"returning an integer constants is the same as returning nothing"
	"this therefore return a sqInt"
	"see start of the CCodeGenerator >> harmonizeReturnTypesIn: method"
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTest >> testReturnAnIntEqual32MessageSend [
	| tMethod |
	tMethod := ccg methodNamed: #returnAnIntEqual32MessageSend.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt.
	self assert: (ccg typeFor: tMethod statements first expression in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
	"the method return type is sqint, so it's coherent, see testReturnAnIntEqual32MessageSend"
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTest >> testReturnAnIntEqual64ConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnAnIntEqual64ConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'unsigned long long'.
	self assert: tMethod returnType equals: #sqInt
	"returning an integer constants is the same as returning nothing"
	"this therefore return a sqInt"
	"see start of the CCodeGenerator >> harmonizeReturnTypesIn: method"
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTest >> testReturnAnIntEqual64MessageSend [
	| tMethod |
	tMethod := ccg methodNamed: #returnAnIntEqual64MessageSend.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt.
	self assert: (ccg typeFor: tMethod statements first expression in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
	"the method return type is sqint, so it's coherent, see testReturnAnIntEqual64MessageSend"
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTest >> testReturnAnIntGreater64ConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnAnIntGreater64ConstantNode.
		
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'long long'.
	self assert: tMethod returnType equals: #sqInt
	"returning an integer constants is the same as returning nothing"
	"this therefore return a sqInt"
	"see start of the CCodeGenerator >> harmonizeReturnTypesIn: method"
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTest >> testReturnAnIntGreater64MessageSend [
	| tMethod |
	tMethod := ccg methodNamed: #returnAnIntGreater64MessageSend.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt.
	self assert: (ccg typeFor: tMethod statements first expression in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
	"the method return type is sqint, so it's coherent, see testReturnAnIntGreater64MessageSend"
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTest >> testReturnAnIntLess32ConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnAnIntLesser32ConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int.
	self assert: tMethod returnType equals: #sqInt
	"returning constants is the same as returning nothing"
	"this therefore return a sqInt"
	"see start of the CCodeGenerator >> harmonizeReturnTypesIn: method"
]

{ #category : #'return-message-send' }
SlangBasicTypeInferenceTest >> testReturnAnIntLesser32MessageSend [
	| tMethod |
	tMethod := ccg methodNamed: #returnAnIntLesser32MessageSend.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt.
	self assert: (ccg typeFor: tMethod statements first expression in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
	"the method return type is sqint, so it's coherent, see testReturnAnIntLesser64MessageSend"
]

{ #category : #'return-explicit-arg' }
SlangBasicTypeInferenceTest >> testReturnExplicitArgDouble [
	| tMethod |
	tMethod := ccg methodNamed: #returnExplicitArgDouble:.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #double.
	self assert: tMethod returnType equals: #double
]

{ #category : #'return-explicit-arg' }
SlangBasicTypeInferenceTest >> testReturnExplicitArgFloat [
	| tMethod |
	tMethod := ccg methodNamed: #returnExplicitArgFloat:.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #float.
	self assert: tMethod returnType equals: #float
]

{ #category : #'return-explicit-arg' }
SlangBasicTypeInferenceTest >> testReturnExplicitArgInt [
	| tMethod |
	tMethod := ccg methodNamed: #returnExplicitArgInt:.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int.
	self assert: tMethod returnType equals: #sqInt
]

{ #category : #'return-explicit-arg' }
SlangBasicTypeInferenceTest >> testReturnExplicitArgLongLong [
	| tMethod |
	tMethod := ccg methodNamed: #returnExplicitArgLongLong:.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'long long'.
	self assert: tMethod returnType equals: #sqLong
]

{ #category : #'return-explicit-arg' }
SlangBasicTypeInferenceTest >> testReturnExplicitArgRandom [
	| tMethod |
	tMethod := ccg methodNamed: #returnExplicitArgRandom:.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #completelyRandom.
	self assert: tMethod returnType equals: #completelyRandom
]

{ #category : #'return-explicit-arg' }
SlangBasicTypeInferenceTest >> testReturnExplicitArgString [
	| tMethod |
	tMethod := ccg methodNamed: #returnExplicitArgString:.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'char *'.
	self assert: tMethod returnType equals: #'char *'
]

{ #category : #'return-explicit-arg' }
SlangBasicTypeInferenceTest >> testReturnExplicitArgUnsignedInt [
	| tMethod |
	tMethod := ccg methodNamed: #returnExplicitArgUnsignedInt:.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'unsigned int'.
	self assert: tMethod returnType equals: #usqInt
]

{ #category : #'return-explicit-arg' }
SlangBasicTypeInferenceTest >> testReturnExplicitArgUnsignedLongLong [
	| tMethod |
	tMethod := ccg methodNamed: #returnExplicitArgUnsignedLongLong:.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'unsigned long long'.
	self assert: tMethod returnType equals: #usqLong
]

{ #category : #'return-explicit-temp' }
SlangBasicTypeInferenceTest >> testReturnExplicitTempDouble [
	| tMethod |
	tMethod := ccg methodNamed: #returnExplicitTempDouble.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #double.
	self assert: tMethod returnType equals: #double
]

{ #category : #'return-explicit-temp' }
SlangBasicTypeInferenceTest >> testReturnExplicitTempFloat [
	| tMethod |
	tMethod := ccg methodNamed: #returnExplicitTempFloat.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #float.
	self assert: tMethod returnType equals: #float
]

{ #category : #'return-explicit-temp' }
SlangBasicTypeInferenceTest >> testReturnExplicitTempInt [
	| tMethod |
	tMethod := ccg methodNamed: #returnExplicitTempInt.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int.
	self assert: tMethod returnType equals: #sqInt
]

{ #category : #'return-explicit-temp' }
SlangBasicTypeInferenceTest >> testReturnExplicitTempLongLong [
	| tMethod |
	tMethod := ccg methodNamed: #returnExplicitTempLongLong.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'long long'.
	self assert: tMethod returnType equals: #sqLong
]

{ #category : #'return-explicit-temp' }
SlangBasicTypeInferenceTest >> testReturnExplicitTempRandom [
	| tMethod |
	tMethod := ccg methodNamed: #returnExplicitTempRandom.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #completelyRandom.
	self assert: tMethod returnType equals: #completelyRandom
]

{ #category : #'return-explicit-temp' }
SlangBasicTypeInferenceTest >> testReturnExplicitTempString [
	| tMethod |
	tMethod := ccg methodNamed: #returnExplicitTempString.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'char *'.
	self assert: tMethod returnType equals: #'char *'
]

{ #category : #'return-explicit-temp' }
SlangBasicTypeInferenceTest >> testReturnExplicitTempUnsignedInt [
	| tMethod |
	tMethod := ccg methodNamed: #returnExplicitTempUnsignedInt.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'unsigned int'.
	self assert: tMethod returnType equals: #usqInt
]

{ #category : #'return-explicit-temp' }
SlangBasicTypeInferenceTest >> testReturnExplicitTempUnsignedLongLong [
	| tMethod |
	tMethod := ccg methodNamed: #returnExplicitTempUnsignedLongLong.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'unsigned long long'.
	self assert: tMethod returnType equals: #usqLong
]

{ #category : #'return-constant' }
SlangBasicTypeInferenceTest >> testReturnFloatConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnAFloatConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #double.
	self assert: tMethod returnType equals: #double
	
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTest >> testReturnTempBigNegativeIntegerConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempBigNegativeIntegerConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'long long'. " assignementNode "
	self assert: (ccg typeFor: tMethod statements first value in: tMethod) equals: #'long long'. " value, constantNode "
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt. " variable, temporaryNode "
	self assert: tMethod returnType equals: #sqInt.
	
	self assert: false "unexpected type conversion, shouldn't it be a sqLong?"
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTest >> testReturnTempBigNegativeIntegerMessageNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempBigNegativeIntegerMessageNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqLong.
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqLong.
	self assert: tMethod returnType equals: #sqLong.
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTest >> testReturnTempFalseConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempFalseConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int. " assignementNode "
	self assert: (ccg typeFor: tMethod statements first value in: tMethod) equals: #int. " value, constantNode "
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt. " variable, temporaryNode "
	self assert: tMethod returnType equals: #sqInt.
	
	self assert: false "unexpected type conversion"
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTest >> testReturnTempFalseMessageNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempFalseMessageNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt.
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTest >> testReturnTempFloatConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempFloatConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #double. " assignementNode "
	self assert: (ccg typeFor: tMethod statements first value in: tMethod) equals: #double. " value, constantNode "
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt. " variable, temporaryNode "
	self assert: tMethod returnType equals: #sqInt.
	
	self assert: false "type lost"
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTest >> testReturnTempFloatMessageNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempFloatMessageNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #double.
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
	
	self assert: false "wait what"
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTest >> testReturnTempIntEqual32ConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempIntEqual32ConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'unsigned int'. " assignementNode "
	self assert: (ccg typeFor: tMethod statements first value in: tMethod) equals: #'unsigned int'. " value, constantNode "
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt. " variable, temporaryNode "
	self assert: tMethod returnType equals: #sqInt.
	
	self assert: false "unexpected type conversion"
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTest >> testReturnTempIntEqual32MessageNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempIntEqual32MessageNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt.
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTest >> testReturnTempIntEqual64ConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempIntEqual64ConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'unsigned long long'. " assignementNode "
	self assert: (ccg typeFor: tMethod statements first value in: tMethod) equals: #'unsigned long long'. " value, constantNode "
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt. " variable, temporaryNode "
	self assert: tMethod returnType equals: #sqInt.
	
	self assert: false "unexpected type conversion, shouldn't it at least be an sqLong? or better, an uSqLong"
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTest >> testReturnTempIntEqual64MessageNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempIntEqual64MessageNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt.
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTest >> testReturnTempIntGreater64ConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempIntGreater64ConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'long long'. " assignementNode "
	self assert: (ccg typeFor: tMethod statements first value in: tMethod) equals: #'long long'. " value, constantNode "
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt. " variable, temporaryNode "
	self assert: tMethod returnType equals: #sqInt.
	
	self assert: false "unexpected type conversion, shouldn't it be at least an sqLong?"
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTest >> testReturnTempIntGreater64MessageNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempIntGreater64MessageNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt.
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTest >> testReturnTempIntLesser32ConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempIntLesser32ConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int. " assignementNode "
	self assert: (ccg typeFor: tMethod statements first value in: tMethod) equals: #int. " value, constantNode "
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt. " variable, temporaryNode "
	self assert: tMethod returnType equals: #sqInt.
	
	self assert: false "unexpected type conversion"
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTest >> testReturnTempIntLesser32MessageNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempIntLesser32MessageNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt.
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTest >> testReturnTempNilConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempNilConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int. " assignementNode "
	self assert: (ccg typeFor: tMethod statements first value in: tMethod) equals: #int. " value, constantNode "
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt. " variable, temporaryNode "
	self assert: tMethod returnType equals: #sqInt.
	
	self assert: false "unexpected type conversion"
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTest >> testReturnTempNilMessageNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempNilMessageNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt.
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTest >> testReturnTempSmallNegativeIntegerConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempSmallNegativeIntegerConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int. " assignementNode "
	self assert: (ccg typeFor: tMethod statements first value in: tMethod) equals: #int. " value, constantNode "
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt. " variable, temporaryNode "
	self assert: tMethod returnType equals: #sqInt.
	
	self assert: false "unexpected type conversion"
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTest >> testReturnTempSmallNegativeIntegerMessageNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempSmallNegativeIntegerMessageNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt.
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTest >> testReturnTempStringConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempStringConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'char *'. " assignementNode "
	self assert: (ccg typeFor: tMethod statements first value in: tMethod) equals: #'char *'. " value, constantNode "
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt. " variable, temporaryNode "
	self assert: tMethod returnType equals: #sqInt.
	
	self assert: false "type lost"
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTest >> testReturnTempStringMessageNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempStringMessageNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #'char *'.
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #'char *'.
	self assert: tMethod returnType equals: #'char *'.
]

{ #category : #'return-temp-assigned-const' }
SlangBasicTypeInferenceTest >> testReturnTempTrueConstantNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempTrueConstantNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #int. " assignementNode "
	self assert: (ccg typeFor: tMethod statements first value in: tMethod) equals: #int. " value, constantNode "
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt. " variable, temporaryNode "
	self assert: tMethod returnType equals: #sqInt.
	
	self assert: false "Unexpected conversion"
]

{ #category : #'return-temp-assigned-message' }
SlangBasicTypeInferenceTest >> testReturnTempTrueMessageNode [
	| tMethod |
	tMethod := ccg methodNamed: #returnTempTrueMessageNode.
	
	self assert: tMethod isNotNil.
	self assert: (ccg typeFor: tMethod statements first in: tMethod) equals: #sqInt.
	self assert: (ccg typeFor: tMethod statements first variable in: tMethod) equals: #sqInt.
	self assert: tMethod returnType equals: #sqInt.
]
