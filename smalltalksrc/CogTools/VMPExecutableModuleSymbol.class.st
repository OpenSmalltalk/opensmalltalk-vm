"
A symbol for some sort of executable, e.g. the VM or a dynamically loaded library it is using.  The vmshift inst var is the amount (if any) the text segment of the module has been moved in memory from its static definition.
"
Class {
	#name : #VMPExecutableModuleSymbol,
	#superclass : #VMPSymbol,
	#instVars : [
		'vmshift',
		'shortName'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #LICENSE }
VMPExecutableModuleSymbol class >> LICENSE [
	^'Project Squeak

	Copyright (c) 2005-2013, 3D Immersive Collaboration Consulting, LLC., All Rights Reserved

	Redistributions in source code form must reproduce the above copyright and this condition.

Licensed under MIT License (MIT)
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.'
]

{ #category : #printing }
VMPExecutableModuleSymbol >> displayText [
	^(name copyFrom: (name lastIndexOf: FileDirectory pathNameDelimiter) + 1 to: name size) asText allBold
]

{ #category : #comparing }
VMPExecutableModuleSymbol >> hash [
	"Override to avoid hashing on the address.  This avoids multiple entries for
	 modules in the symbol manager's symbolsByModule dictionary.  Lazy initialization
	 in the symbol manager may change a module's address after parsing its symbols."
	^self class hash bitXor: name hash
]

{ #category : #comparing }
VMPExecutableModuleSymbol >> importance [
	^0
]

{ #category : #testing }
VMPExecutableModuleSymbol >> nameMatches: aPattern [
	^(super nameMatches: aPattern)
	  or: [shortName notNil and: [aPattern match: shortName]]
]

{ #category : #accessing }
VMPExecutableModuleSymbol >> shortName [
	"Answer the value of shortName"

	^ shortName
]

{ #category : #accessing }
VMPExecutableModuleSymbol >> shortName: aString [
	"Set the value of shortName"

	shortName := aString
]

{ #category : #accessing }
VMPExecutableModuleSymbol >> type [
	^#module
]

{ #category : #accessing }
VMPExecutableModuleSymbol >> vmshift [
	"Answer the value of vmshift"

	^ vmshift
]

{ #category : #accessing }
VMPExecutableModuleSymbol >> vmshift: anObject [
	"Set the value of vmshift"

	vmshift := anObject
]
