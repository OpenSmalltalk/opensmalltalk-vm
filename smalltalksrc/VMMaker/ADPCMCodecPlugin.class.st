"
This is a kludgy interface to the translated primitive code in ADPCMCodec. The translate.... method gathers the code and writes it to a file. No methods in this class actually implement the codec.
"
Class {
	#name : #ADPCMCodecPlugin,
	#superclass : #InterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
ADPCMCodecPlugin class >> translateInDirectory: directory doInlining: inlineFlag [
"handle a special case code string rather than generated code"
"Not currently hooked into the timeStamp mechanism for VMMaker since this would mean replicating code from InterpreterPlugin; waiting for a more elegant solution to appear. In the meantime this means that this plugin will always get regenerated even if the file is uptodate"
	| cg aClass |
	self initialize.

	cg := self buildCodeGeneratorUpTo: InterpreterPlugin.
	aClass := Smalltalk at: #ADPCMCodec ifAbsent:[nil].
	aClass ifNil:[
		Transcript cr; show: 'ADPCMCodec not present in image. Skipping plugin.'.
		^self].

	cg addMethodsForPrimitives: aClass translatedPrimitives.
	inlineFlag ifTrue:[
		"now remove a few which will be inlined but not pruned"
		cg pruneMethods: #(indexForDeltaFrom:to: nextBits: nextBits:put:)].
	self storeString: cg generateCodeStringForPrimitives onFileNamed: (directory fullNameFor: self moduleName, '.c').
	^cg exportedPrimitiveNames asArray

]
