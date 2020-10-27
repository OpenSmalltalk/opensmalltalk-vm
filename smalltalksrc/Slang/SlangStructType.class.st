Class {
	#name : #SlangStructType,
	#superclass : #SlangClass,
	#classVars : [
		'StructTypeNameCache'
	],
	#category : #Slang
}

{ #category : #translation }
SlangStructType class >> isTypePointerToStruct: type [
	| index |
	StructTypeNameCache ifNil:
		[StructTypeNameCache := Set new.
		 self allSubclassesDo:
			[:sc| StructTypeNameCache add: sc name; add: sc structTypeName ]].
	^type notNil
	  and: [(index := type indexOf: $*) > 0
	  and: [StructTypeNameCache anySatisfy:
			[:structType|
			(type beginsWith: structType)
			and: [index > structType size]]]]
]

{ #category : #translation }
SlangStructType class >> isTypeStruct: type [
	StructTypeNameCache ifNil:
		[StructTypeNameCache := Set new.
		 self allSubclassesDo:
			[:sc| StructTypeNameCache add: sc name; add: sc structTypeName]].
	^type notNil
	  and: [StructTypeNameCache anySatisfy:
			[:structType|
			type = structType]]
]

{ #category : #translation }
SlangStructType class >> structTargetKindForDeclaration: decl [
	StructTypeNameCache ifNil:
		[StructTypeNameCache := Set new.
		 self allSubclassesDo:
			[:sc| StructTypeNameCache add: sc name; add: sc structTypeName ]].
	^(decl notNil
	   and: [(StructTypeNameCache includes: decl)
			or: [StructTypeNameCache anySatisfy:
					[:structType|
					(decl beginsWith: structType)
					and: [(decl indexOf: $* ifAbsent: [decl indexOf: Character space]) > structType size]]]]) ifTrue:
		[(decl indexOf: $*) > 0
			ifTrue: [#pointer]
			ifFalse: [#struct]]
]

{ #category : #translation }
SlangStructType class >> structTargetKindForType: type [
	StructTypeNameCache ifNil:
		[StructTypeNameCache := Set new.
		 self allSubclassesDo:
			[:sc| StructTypeNameCache add: sc name; add: sc structTypeName ]].
	^(type notNil
	   and: [StructTypeNameCache anySatisfy:
			[:structType|
			(type beginsWith: structType)
			and: [type size = structType size
				or: [(type at: structType size + 1) isAlphaNumeric not]]]]) ifTrue:
		[(type includes: $*)
			ifTrue: [#pointer]
			ifFalse: [#struct]]
]

{ #category : #translation }
SlangStructType class >> voidStructTypeCache [
	StructTypeNameCache := nil
]

{ #category : #'error handling' }
SlangStructType >> error [
	"Throw a generic Error exception."

	^self error: 'Error!'.
]
