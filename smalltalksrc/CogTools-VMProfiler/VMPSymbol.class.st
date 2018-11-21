"
A text symbol in the VM's address space corresponding to some form of executable code (see subclasses)
"
Class {
	#name : #VMPSymbol,
	#superclass : #Object,
	#instVars : [
		'name',
		'address',
		'limit'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #LICENSE }
VMPSymbol class >> LICENSE [
	^'Project Squeak

	Copyright (c) 2005-2013, 3D Immersive Collaboration Consulting, LLC., All Rights Reserved

	Redistributions in source code form must reproduce the above copyright and this condition.

Licensed under MIT License (MIT)
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.'
]

{ #category : #debugger }
VMPSymbol class >> defaultIntegerBaseInDebugger [
	^16
]

{ #category : #comparing }
VMPSymbol >> = anObject [
	^self class == anObject class
	   and: [address = anObject address
	   and: [name = anObject name]]
]

{ #category : #accessing }
VMPSymbol >> address [
	"Answer the value of address"

	^ address
]

{ #category : #accessing }
VMPSymbol >> address: anObject [
	"Set the value of address"

	address := anObject
]

{ #category : #printing }
VMPSymbol >> displayText [
	"Answer the name as a string, which for the purposes of the symbol list is an unemphasized text."
	^name
]

{ #category : #comparing }
VMPSymbol >> hash [
	^address hash bitXor: name hash
]

{ #category : #comparing }
VMPSymbol >> importance [
	^self subclassResponsibility
]

{ #category : #accessing }
VMPSymbol >> limit [
	"Answer the value of limit"

	^ limit
]

{ #category : #accessing }
VMPSymbol >> limit: anObject [
	"Set the value of limit"
	anObject - address > 2097152 ifTrue:
		[Transcript cr; nextPutAll: name; space; print: anObject - address; tab; nextPutAll: (anObject - address) hex; flush.
		"self halt"].
	limit := anObject

	"VMProfilerMacSymbolsManager basicNew initializeSynchronously"
]

{ #category : #accessing }
VMPSymbol >> name [
	"Answer the value of name"

	^name
]

{ #category : #accessing }
VMPSymbol >> name: anObject [
	"Set the value of name"

	name := anObject
]

{ #category : #testing }
VMPSymbol >> nameMatches: aPattern [
	^aPattern match: name
]

{ #category : #printing }
VMPSymbol >> printOn: aStream [
	super printOn: aStream.
	[aStream space; nextPut: $(; nextPutAll: self type; space; nextPutAll: name; space.
	 address printOn: aStream base: 16.
	 (limit ~~ nil
	  and: [limit ~= address]) ifTrue:
	 	[aStream nextPut: $-.
		 limit printOn: aStream base: 16].
	 aStream nextPut: $)]
		on: Error
		do: [:ex| aStream print: ex; nextPut: $)]
]

{ #category : #accessing }
VMPSymbol >> size: size [
	limit := address + size
]

{ #category : #accessing }
VMPSymbol >> type [
	^self subclassResponsibility
]
