Class {
	#name : #VMClassTests,
	#superclass : #TestCase,
	#instVars : [
		'testString',
		'vmclass'
	],
	#category : #'VMMaker-OriginalTests'
}

{ #category : #'initialize-release' }
VMClassTests >> initialize [

	super initialize.
	testString := 'hello world'.
]

{ #category : #running }
VMClassTests >> setUp [

	super setUp.
	vmclass := VMClass new.

]

{ #category : #tests }
VMClassTests >> testStrlen [

	| testByteArray |

	"Instances of String must be the correct length"
	self assert: (vmclass strlen: testString) equals: testString size.

	"Instances of ByteArray can optionally have trailing nulls"
	testByteArray := testString asByteArray.
	self assert: (vmclass strlen: testByteArray) equals: testString size.
	testByteArray := testByteArray, (ByteArray new: 3).
	self assert: (vmclass strlen: testByteArray) equals: testString size.

]

{ #category : #tests }
VMClassTests >> testStrncpy [

	| stringA byteArrayA |

	stringA := String new: 5.
	vmclass strncpy: stringA _: testString _: stringA size.
	self assert: stringA equals: 'hello'.

	stringA := String new: testString size + 3.
	vmclass strncpy: stringA _: testString _: stringA size.
	self assert: stringA equals: (testString, (String new: 3)).

	byteArrayA := ByteArray new: 5.
	vmclass strncpy: byteArrayA _: testString _: byteArrayA size.
	self assert: byteArrayA equals: 'hello' asByteArray.

	byteArrayA := ByteArray new: testString size + 3.
	vmclass strncpy: byteArrayA _: testString _: byteArrayA size.
	self assert: byteArrayA equals: (testString, (String new: 3)) asByteArray.

	"SVr4, 4.3BSD, C89, C99 require the destination space after the string be null filled"
	byteArrayA := ByteArray new: testString size + 3.
	byteArrayA atAllPut: 255.
	vmclass strncpy: byteArrayA _: testString _: byteArrayA size.
	self assert: byteArrayA equals: (testString, (String new: 3)) asByteArray.


]
