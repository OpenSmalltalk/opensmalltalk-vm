Class {
	#name : #VMProfilerLinuxSymbolsManager,
	#superclass : #VMProfilerSymbolsManager,
	#instVars : [
		'initialized',
		'tempDir',
		'maxAddressMask',
		'warnInconsistentShift'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #LICENSE }
VMProfilerLinuxSymbolsManager class >> LICENSE [
	^'Project Squeak

	Copyright (c) 2005-2013, 3D Immersive Collaboration Consulting, LLC., All Rights Reserved

	Redistributions in source code form must reproduce the above copyright and this condition.

Licensed under MIT License (MIT)
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.'
]

{ #category : #debugger }
VMProfilerLinuxSymbolsManager class >> defaultIntegerBaseInDebugger [
	^16
]

{ #category : #'class initialization' }
VMProfilerLinuxSymbolsManager class >> initialize [
	"Add to the shut down list to delete the temp directory and contents."
	Smalltalk addToShutDownList: self
]

{ #category : #'shut down' }
VMProfilerLinuxSymbolsManager class >> shutDown: quitting [
	"(quitting
	 and: [#('Mac OS' 'unix') includes: Smalltalk platformName]) ifTrue:
		[| tempDir |
		 (tempDir := self tempDirectory) exists ifTrue:
			[tempDir recursiveDelete]]" "error on Pharo as recursiveDelete is from FileDirectory. Have to find something similar with FileSystem"
]

{ #category : #'as yet unclassified' }
VMProfilerLinuxSymbolsManager class >> tempDirectory [

	^ VMFileSystem nameFordirPath:'/tmp/vmsyms'  plus:OSProcess thisOSProcess pid printString 

]

{ #category : #parsing }
VMProfilerLinuxSymbolsManager >> hexFromStream: aStream [
	"Fast reading of lower-case hexadecimal."
	| value index |
	value := 0.
	[nil ~~ (index := '0123456789abcdef' indexOf: aStream next ifAbsent: nil)] whileTrue:
		[value := (value bitShift: 4) + index - 1].
	^value

	"(self basicNew hexFromStream: '91a45000' readStream) hex"
]

{ #category : #'initialize-release' }
VMProfilerLinuxSymbolsManager >> initialize [
	"Initialize the receiver, parsing the symbols in the background for faster startup."
	self initializeMost.
	self parseAsynchronously
]

{ #category : #'initialize-release' }
VMProfilerLinuxSymbolsManager >> initializeMost [
	| shortNames |
	initialized := false.
	maxAddressMask := (2 raisedToInteger: 32) - 1.
	modulesByName := Dictionary new.
	symbolsByModule := Dictionary new.
	shortNames := Set new.
	tempDir := self class tempDirectory.
	self fileSystem ensureExistenceOfDirectory:  tempDir. 
	modules := self primitiveExecutableModules.
	modules := (1 to: modules size by: 2) collect:
					[:i| | fileName shortName counter longName |
					fileName := modules at: i.
					(fileName beginsWith: '/dgagent') ifTrue:
						[fileName := fileName allButFirst: 8].
					shortName := VMFileSystem nameOfFile: fileName in: tempDir.  
					counter := 0.
					[shortNames includes: shortName] whileTrue:
						[counter := counter + 1.
						 shortName := (VMFileSystem nameOfFile: fileName  in: tempDir), counter printString].
					shortNames add: shortName.
					longName := (modules at: i + 1)
									ifNil: [fileName]
									ifNotNil:
										[:symlink|
										symlink first = $/
											ifTrue: [symlink]
											ifFalse: [( VMFileSystem parentPathOfFile: fileName ), '/', symlink]].
					"some files are off limits (e.g. /dgagent/lib/preload.so)"
					(VMFileSystem exists: longName) ifTrue:
						[(modulesByName
							at: longName
							put: VMPExecutableModuleSymbol new)
								name: longName;
								shortName: shortName]].
	"The primitive always answers the VM info in the first entry."
	vmModule := modules first.
	"now filter out the files we can't read..."
	modules := modules select: [:m| modulesByName includesKey: m name]
]

{ #category : #'initialize-release' }
VMProfilerLinuxSymbolsManager >> initializeSynchronously [
	"Initialize the receiver, parsing the symbols in the foreground for debugging."
	self initializeMost.
	self parseSynchronously
]

{ #category : #accessing }
VMProfilerLinuxSymbolsManager >> initialized [
	^initialized
]

{ #category : #parsing }
VMProfilerLinuxSymbolsManager >> parseAsynchronously [
	"Parse the symbols in the background for faster startup."
	"Parse only the VM module.  The profiler needs this initialized early."
	symbolsByModule at: vmModule put: { vmModule }.
	self parseSymbolsFor: vmModule.
	"Kick-off a process to compute the symbol list for each module.  Parsing symbols
	 can take a few seconds so we parse in the background."
	[modules allButFirst do:
		[:module|
		symbolsByModule at: module put: { module }.
		self parseSymbolsFor: module.
		module address ifNil: [symbolsByModule removeKey: module]].
	 modules := (modules reject: [:m| m address isNil]) asSortedCollection: [:m1 :m2| m1 address <= m2 address].
	 initialized := true] forkAt: Processor userBackgroundPriority
]

{ #category : #parsing }
VMProfilerLinuxSymbolsManager >> parseSymbolsFor: module [
	| proc symtab symStream |
	(VMFileSystem exists: tempDir fullName, '/', module shortName)  ifFalse:
		[proc := OSProcess thisOSProcess command:
						'objdump -j .text -tT "', module name, '" | fgrep .text | sort >"', tempDir fullName, '/', module shortName, '"'].
	symStream := (Array new: 1000) writeStream.
	symStream nextPut: module.
	proc ifNotNil:
		[[proc isComplete] whileFalse: [(Delay forMilliseconds: 25) wait]].
	symtab := [StandardFileStream readOnlyFileNamed: (tempDir fullName,'/',module shortName) ]
					on: Error
					do: [:ex| "Handle flaky OSProcess stuff by reporting error and failing to parse"
						Transcript print: ex; flush.
						^nil].
	[| prev |
	 prev := self parseSymbolsFrom: symtab to: symStream.
	 symbolsByModule
		at: module
		put: (self relocateSymbols: symStream contents allButFirst inModule: module).
	 (prev notNil
	  and: [prev limit isNil]) ifTrue: [prev limit: module limit]]
		ensure: [symtab close]
]

{ #category : #parsing }
VMProfilerLinuxSymbolsManager >> parseSymbolsFrom: symtab "<ReadStream>" to: symStream [ "<WriteStream> ^<VMPSymbol>"
	"Parse the text symbols on the stream symtab (in objdump format) to symStream.
	 Answer the last text symbol."
	| prev |
	[symtab atEnd] whileFalse:
		[| line tokens address size type symbol |
		 tokens := (line := symtab upTo: Character lf) substrings.
		 self assert: (tokens size between: 5 and: 7).
		 self assert: ((tokens size = 5 and: [tokens third = '.text']) "labels"
					or: [tokens fourth = '.text']) "functions".
		 address := Integer readFrom: tokens first readStream radix: 16.
		 size := tokens size = 5
					ifTrue: [0] "labels"
					ifFalse: [Integer readFrom: tokens fifth readStream radix: 16].
		 type := tokens second.
		 symbol := (type = 'g'
						ifTrue: [VMPPublicFunctionSymbol]
						ifFalse:
							[(tokens last beginsWith: '.L')
								ifTrue: [VMPLabelSymbol]
								ifFalse: [VMPPrivateFunctionSymbol]]) new.
		 symbol
			name: tokens last;
			address: address;
			limit: address + size.
		(prev isNil or: [prev ~= symbol]) ifTrue:
			[symStream nextPut: symbol].
		prev := symbol].
	^prev
]

{ #category : #parsing }
VMProfilerLinuxSymbolsManager >> parseSynchronously [
	modules do:
		[:module|
		symbolsByModule at: module put: { module }.
		self parseSymbolsFor: module.
		module address ifNil: [symbolsByModule removeKey: module]].
	modules := (modules reject: [:m| m address isNil]) asSortedCollection: [:m1 :m2| m1 address <= m2 address].
	initialized := true
]

{ #category : #primitives }
VMProfilerLinuxSymbolsManager >> primitiveDLSym: symbolName in: libraryName [
	<primitive: 'primitiveDLSymInLibrary' module: 'VMProfileLinuxSupportPlugin' error: ec>
	ec == #'not found' ifTrue:
		[^nil].
	^self primitiveFailed
]

{ #category : #primitives }
VMProfilerLinuxSymbolsManager >> primitiveExecutableModules [
	"Answer an Array of pairs of strings for executable modules (the VM executable and
	 loaded libraries). The first element in each pair is the filename of the module.  The
	 second element is either nil or the symlink's target, if the filename is a symlink."
	<primitive: 'primitiveExecutableModules' module: 'VMProfileLinuxSupportPlugin'>
	^self primitiveFailed

	"self basicNew primitiveExecutableModules"
]

{ #category : #primitives }
VMProfilerLinuxSymbolsManager >> primitiveInterpretAddress [
	"Answer the address of the interpret routine.  Used to compute the address shift, if any, of the VM module."
	<primitive: 'primitiveInterpretAddress' module: 'VMProfileLinuxSupportPlugin'>
	^self primitiveFailed


	"self basicNew primitiveInterpretAddress"
]

{ #category : #parsing }
VMProfilerLinuxSymbolsManager >> relocateSymbols: symbols inModule: module [
	"We can't trust the shift that comes from the dyld_get_image_header call in
	 primitiveExecutableModulesAndOffsets.  So use dlsym to find out the actual
	 address of the first real symbol and use that to compute the real shift.
	 At least some libraries (e.g. /usr/lib/libSystem.B.dylib) don't have a single shift (!!).
	 Check, and compensate by calling dlsym on each symbol."
	| shift count prev |
	symbols isEmpty ifTrue: [^symbols]. "avoid symbols first exception"
	shift := module = vmModule
				ifTrue:
					[self primitiveInterpretAddress - (symbols detect: [:s| s name = 'interpret']) address]
				ifFalse:
					[(symbols detect: [:sym|
								sym type == #publicFunction
								and: [(self primitiveDLSym: sym name in: module name) notNil]] ifNone: [])
						ifNil: [Transcript cr; show: 'warning, can''t find any public symbols in ', module name.
							0]
						ifNotNil:
							[:symbol| (self primitiveDLSym: symbol name in: module name) - symbol address]].
	module address ifNil:
		[module
			address: symbols first address + shift;
			limit: symbols last limit + shift].
	shift = 0 ifTrue:
		[count := 0.
		 symbols do: [:s| (s address between: module address and: module limit) ifTrue: [count := count + 1]].
		 count = symbols size ifTrue:
			[^symbols]. "don't waste time..."
		 count ~= 0 ifTrue:
			[self error: 'parse error; some symbols within module, some without'].
		 shift := module address].
	(prev := symbols first) address: (maxAddressMask bitAnd: symbols first address + shift).
	symbols do:
		[:sym| | reloc |
		prev ~~ sym ifTrue:
			[reloc := maxAddressMask bitAnd: sym address + shift.
			 sym address: reloc.
			 prev limit: reloc].
		prev := sym].
	symbols last limit: (symbols last limit
							ifNil: [module limit]
							ifNotNil: [:limit| maxAddressMask bitAnd: limit + shift]).
	^symbols
]
