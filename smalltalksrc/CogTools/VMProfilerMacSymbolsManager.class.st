Class {
	#name : #VMProfilerMacSymbolsManager,
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
VMProfilerMacSymbolsManager class >> LICENSE [
	^'Project Squeak

	Copyright (c) 2005-2013, 3D Immersive Collaboration Consulting, LLC., All Rights Reserved

	Redistributions in source code form must reproduce the above copyright and this condition.

Licensed under MIT License (MIT)
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.'
]

{ #category : #debugger }
VMProfilerMacSymbolsManager class >> defaultIntegerBaseInDebugger [
	^16
]

{ #category : #'class initialization' }
VMProfilerMacSymbolsManager class >> initialize [
	"Add to the shut down list to delete the temp directory and contents."
	Smalltalk addToShutDownList: self
]

{ #category : #'shut down' }
VMProfilerMacSymbolsManager class >> shutDown: quitting [
	(quitting
	 and: [Smalltalk platformName= 'Mac OS']) ifTrue:
		[| tempDir |
		 (tempDir := self tempDirectory) exists ifTrue:
			[tempDir recursiveDelete]]
]

{ #category : #accessing }
VMProfilerMacSymbolsManager class >> tempDirectory [
	^FileDirectory on: '/tmp/vmsyms', OSProcess thisOSProcess pid printString
]

{ #category : #'initialize-release' }
VMProfilerMacSymbolsManager >> filter: moduleList [
	"Some modules are giving us parsing problems at the moment.  Just ignore them for now."
	^moduleList reject: [:t| #('CoreAUC' 'FaceCore' 'HIToolbox' 'VideoToolbox') anySatisfy: [:s| t name includesSubstring: s]]
]

{ #category : #parsing }
VMProfilerMacSymbolsManager >> hexFromStream: aStream [
	"Fast reading of lower-case hexadecimal."
	| value index |
	value := 0.
	[nil ~~ (index := '0123456789abcdef' indexOf: aStream next ifAbsent: nil)] whileTrue:
		[value := (value bitShift: 4) + index - 1].
	^value

	"(self basicNew hexFromStream: '91a45000' readStream) hex"
]

{ #category : #'initialize-release' }
VMProfilerMacSymbolsManager >> initialize [
	"Initialize the receiver, parsing the symbols in the background for faster startup."
	self initializeMost.
	self parseAsynchronously
]

{ #category : #'initialize-release' }
VMProfilerMacSymbolsManager >> initializeMost [
	| shortNames |
	initialized := false.
	maxAddressMask := (2 raisedToInteger: 32) - 1.
	modulesByName := Dictionary new.
	symbolsByModule := Dictionary new.
	shortNames := Set new.
	modules := self primitiveExecutableModulesAndOffsets.
	(tempDir := self class tempDirectory) assureExistence.
	modules := (1 to: modules size by: 4) collect:
					[:i| | shortName counter |
					shortName := tempDir localNameFor: (modules at: i).
					counter := 0.
					[shortNames includes: shortName] whileTrue:
						[counter := counter + 1.
						 shortName := (tempDir localNameFor: (modules at: i)), counter printString].
					shortNames add: shortName.
					(modulesByName
						at: (modules at: i)
						put: VMPExecutableModuleSymbol new)
								name: (modules at: i);
								shortName: shortName;
								vmshift: (modules at: i + 1);
								address: (maxAddressMask bitAnd: (modules at: i + 2) + (modules at: i + 1));
								size: (modules at: i + 3)].
	modules := self filter: modules.
	"The primitive always answers the VM info in the first entry."
	vmModule := modules first.
	modules := modules asSortedCollection: [:m1 :m2| m1 address <= m2 address]
]

{ #category : #'initialize-release' }
VMProfilerMacSymbolsManager >> initializeSynchronously [
	"Initialize the receiver, parsing the symbols in the foreground for debugging."
	self initializeMost.
	self parseSynchronously
]

{ #category : #accessing }
VMProfilerMacSymbolsManager >> initialized [
	^initialized
]

{ #category : #parsing }
VMProfilerMacSymbolsManager >> parseAsynchronously [
	"Parse the symbols in the background for faster startup."
	"Parse only the VM module.  The profiler needs this initialized early."
	symbolsByModule at: vmModule put: { vmModule }.
	self parseSymbolsFor: vmModule.
	"Kick-off a process to compute the symbol list for each module.  Parsing symbols
	 can take a few seconds so we parse in the background."
	[modules allButFirst do:
		[:module|
		symbolsByModule at: module put: { module }.
		self parseSymbolsFor: module].
	 initialized := true] forkAt: Processor userBackgroundPriority
]

{ #category : #parsing }
VMProfilerMacSymbolsManager >> parseSymbolsFor: module [
	| arch proc symtab symStream |
	arch := (Smalltalk image getSystemAttribute: 1003) caseOf: {
				['intel']	->	['i386'].
				['x64']	->	['x86_64'].
				}.
	(tempDir fileExists: module shortName) ifFalse:
		[proc := OSProcess thisOSProcess command:
						'cd ', tempDir fullName,
						';nm -n -arch ', arch, ' -f "', module name, '" | grep -v " [aAU] " >"', module shortName, '"'].
	symStream := (Array new: 1000) writeStream.
	symStream nextPut: module.
	proc ifNotNil:
		[[proc isComplete] whileFalse: [(Delay forMilliseconds: 25) wait]].
	symtab := [StandardFileStream readOnlyFileNamed: (tempDir fullNameFor: module shortName)]
					on: Error
					do: [:ex| "Handle flaky OSProcess stuff by reporting error and failing to parse"
						Transcript print: ex; flush.
						^nil].
	module shortName = 'HIToolbox' ifTrue: [self halt].
	[| prev |
	 prev := self parseSymbolsFrom: symtab to: symStream.
	"CoreAUC has a huge chunk of data at the end of its text segment that causes the profiler to spend ages
	 counting zeros.  Hack fix by setting the end of the last symbol in the text segment to a little less than 1Mb." 
	"00000000000f1922    retq" "Mavericks 13.4"
	"00000000000f3b21    retq" "Yosemite 14.5"
	module shortName = 'CoreAUC' ifTrue: [prev limit: 16rf8000].
	 symbolsByModule
		at: module
		put: (self relocateSymbols: symStream contents allButFirst inModule: module).
	 (prev notNil
	  and: [prev limit isNil]) ifTrue: [prev limit: module limit]]
		ensure: [symtab close]
]

{ #category : #parsing }
VMProfilerMacSymbolsManager >> parseSymbolsFrom: symtab "<ReadStream>" to: symStream [ "<WriteStream> ^<VMPSymbol>"
	"Parse the text symbols on the stream symtab (in nm format) to symStream.
	 Answer the last text symbol."
	| space lf prev |
	space := Character space.
	lf := Character lf.
	[symtab atEnd] whileFalse:
		[| line ch address |
		 line := (symtab upTo: lf) readStream.
		 line skipSeparators.
		 ((ch := line peek) notNil
		   and: [ch ~= space
		   and: [(address := self hexFromStream: line) ~= maxAddressMask
		   and: [address ~= 0 "on 10.6 this eliminates initial mh_dylib_header entries"]]]) ifTrue:
			[| symbol |
			 prev notNil ifTrue:
				[prev limit: address].
			 ('Tt' includes: line peek)
				ifTrue:
					[| public |
					 public := line next == $T.
					 line skipTo: space.
					 symbol := (line peek == $L
								ifTrue: [VMPLabelSymbol]
								ifFalse:
									[public
										ifTrue: [VMPPublicFunctionSymbol]
										ifFalse: [VMPPrivateFunctionSymbol]]) new.
					 line peek = $_ ifTrue:	"Get rid of initial underscore."
						[line next].			"N.B. relied upon by primitiveDLSym: below"
					 symbol
						name: line upToEnd;
						address: address.
					 symStream nextPut: symbol.
					 symbol type ~~ #label ifTrue:
						[prev := symbol]]
				ifFalse: "first non-text symbol marks the end of the text segment"
					[symtab setToEnd]]].
	^prev
]

{ #category : #parsing }
VMProfilerMacSymbolsManager >> parseSynchronously [
	modules do:
		[:module|
		symbolsByModule at: module put: { module }.
		self parseSymbolsFor: module].
	initialized := true
]

{ #category : #primitives }
VMProfilerMacSymbolsManager >> primitiveDLSym: symbolNameString [
	<primitive: 'primitiveDLSym' module: 'VMProfileMacSupportPlugin' error: ec>
	^self primitiveFailed
]

{ #category : #primitives }
VMProfilerMacSymbolsManager >> primitiveExecutableModulesAndOffsets [
	"Answer an Array of pairs of executable module names (the VM executable and
	 all loaded libraries) and the vm address relocation, if any, is for the module."
	<primitive: 'primitiveExecutableModulesAndOffsets' module: 'VMProfileMacSupportPlugin'>
	^self primitiveFailed


	"self basicNew primitiveExecutableModulesAndOffsets"
]

{ #category : #parsing }
VMProfilerMacSymbolsManager >> relocateAndFilter: symbols in: module initialShift: initialShift [
	"We can't trust the shift that comes from the dyld_get_image_header call in
	 primitiveExecutableModulesAndOffsets.  So use dlsym to find out the actual
	 address of the first real symbol and use that to compute the real shift.
	 At least some libraries (e.g. /usr/lib/libSystem.B.dylib) don't have a single shift (!!).
	 For these we have to call dlsym on each symbol."
	| shift prev lastSize |
	prev := nil.
	shift := initialShift.
	symbols last limit isNil ifTrue: [self halt].
	symbols do:
		[:s| | address |
		lastSize := s limit ifNotNil: [:limit| limit - s address].
		s type == #publicFunction
			ifTrue:
				[(address := self primitiveDLSym: s name)
					ifNil: [s address: nil]
					ifNotNil:
						[(address between: module address and: module limit)
							ifTrue:
								[prev notNil ifTrue:
									[prev limit: address].
								shift := address - s address.
								s address: address]
							ifFalse: "duplicate symbol from some other library"
								[address := maxAddressMask bitAnd: s address + shift.
								s address: address.
								prev ifNotNil: [prev limit: address].
								prev := s].
						prev := s]]
			ifFalse:
				[address := maxAddressMask bitAnd: s address + shift.
				s address: address.
				prev ifNotNil: [prev limit: address].
				prev := s]].
	prev limit: (lastSize ifNotNil: [prev address + lastSize] ifNil: [module limit]).
	^symbols select: [:s| s address notNil]
]

{ #category : #parsing }
VMProfilerMacSymbolsManager >> relocateSymbols: symbols inModule: module [
	"We can't trust the shift that comes from the dyld_get_image_header call in
	 primitiveExecutableModulesAndOffsets.  So use dlsym to find out the actual
	 address of the first real symbol and use that to compute the real shift.
	 At least some libraries (e.g. /usr/lib/libSystem.B.dylib) don't have a single shift (!!).
	 Check, and compensate by calling dlsym on each symbol."
	| shift i incr count prev |
	symbols isEmpty ifTrue: [^symbols]. "avoid symbols first exception"
	shift := (symbols detect: [:sym|
								sym type == #publicFunction
								and: [(self primitiveDLSym: sym name) notNil]] ifNone: [])
				ifNil: [module vmshift]
				ifNotNil:
					[:symbol| (self primitiveDLSym: symbol name) - symbol address].
	"Need to check for inconsistentshifts, because its faster by several seconds overall
	 if we can relocate using a single shift.  But we can only lookup public symbols."
	i := 2.
	incr := warnInconsistentShift ifNil: [symbols size // 50 max: 1] ifNotNil: [1].
	[i <= symbols size] whileTrue:
		[(symbols at: i) type == #publicFunction
			ifTrue:
				[(self primitiveDLSym: (symbols at: i) name) ifNotNil:
					[:addr|
					addr - (symbols at: i) address ~= shift ifTrue:
						[warnInconsistentShift == true ifTrue:
							[Transcript cr; print: module shortName; nextPutAll: ' contains symbols with inconsistent shift'; flush].
						^self relocateAndFilter: symbols in: module initialShift: shift]].
				i := i + incr]
			ifFalse: "not public; can't look it up; so skip it"
				[i := i + 1]].
	warnInconsistentShift == false ifTrue:
		[Transcript cr; print: module shortName; nextPutAll: ' contains symbols with a consistent shift'; flush].
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
