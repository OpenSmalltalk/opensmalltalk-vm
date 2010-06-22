"
I am a place to hang various pieces of translation support.
"
Class {
	#name : #CogClass,
	#superclass : #VMClass,
	#category : #'VMMaker-JIT'
}

{ #category : #translation }
CogClass class >> declareCVarsIn: aCCodeGenerator [
	"Declare variables with types other than sqInt"
]

{ #category : #translation }
CogClass class >> prepareToBeAddedToCodeGenerator: aCodeGen [
	"Hook to allow subclasses to interact with the code generation
	 immediately before having their code assimilated.  e.g. a class
	 might wish to remove methods it is about to override."
	^self
]

{ #category : #translation }
CogClass class >> requiredMethodNames [
	"Answer a list of method names that should be retained for export or other
	 support reasons.  These are typically entry-poimnts that unless explicitly noted
	 will be deleted by the code generator since it will assume these are not used."
	^#()
]

{ #category : #'translation support' }
CogClass >> cCoerceSimple: value to: cTypeString [
	"Type coercion for translation and simulation.
	 For simulation answer a suitable surrogate for the struct types"
	^cTypeString caseOf:
	   {	[#'unsigned long']						->	[value].
		[#sqInt]									->	[value].
		[#'AbstractInstruction *']					->	[value].
		[#'BytecodeFixup *']						->	[value].
		[#'CogMethod *']						->	[value].
		[#'char *']								->	[value].
		[#'sqInt *']								->	[value].
		[#'void *']								->	[value].
		[#'void (*)()']							->	[value].
		[#'void (*)(void)']						->	[value].
		[#'unsigned long (*)(void)']				->	[value].
		[#'void (*)(unsigned long,unsigned long)']	->	[value] }
]

{ #category : #'translation support' }
CogClass >> sizeof: objectOrClass [
	<doNotGenerate>
	^(objectOrClass isBehavior ifTrue: [objectOrClass] ifFalse: [objectOrClass class]) alignedByteSize
]
