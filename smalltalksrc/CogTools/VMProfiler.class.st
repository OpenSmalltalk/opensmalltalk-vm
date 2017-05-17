"
This tool is a pc-sampling profiler for the VM.  It presents the profile data graphically.

Copyright© 2011-2013, 3D ICC Immersive Collaboration. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the ""Software""), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED ""AS IS"", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Licensed under the Apache License, Version 2.0 (the ""License""); you may not use this file except in compliance with the License. You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an ""AS IS"" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
"
Class {
	#name : #VMProfiler,
	#superclass : #Model,
	#instVars : [
		'sampleBuffer',
		'sampleBag',
		'sortedSamples',
		'sortedSymbols',
		'sortedSymbolsBeforeCogCode',
		'sortedSymbolsAfterCogCode',
		'symbolsMode',
		'symbolTypes',
		'symbolManager',
		'symbolList',
		'selections',
		'minSelectionIndex',
		'maxSelectionIndex',
		'total',
		'rangeTotal',
		'highAddress',
		'lowAddress',
		'history',
		'historyIndex',
		'expressionTextMorph',
		'previousPattern',
		'graph',
		'aboutToProfile',
		'startTime',
		'elapsedTime',
		'startStats',
		'elapsedStats',
		'clearPriorToProfile',
		'gcPriorToProfile',
		'forkProfile',
		'cogCodeConstituents',
		'version',
		'fileSystem'
	],
	#classVars : [
		'CannedBenchmarkStrings'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #LICENSE }
VMProfiler class >> LICENSE [
	^'Project Squeak

	Copyright (c) 2005-2013, 3D Immersive Collaboration Consulting, LLC., All Rights Reserved

	Redistributions in source code form must reproduce the above copyright and this condition.

Licensed under MIT License (MIT)
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.'
]

{ #category : #'class initialization' }
VMProfiler class >> canBenchmark: aByteString [ 
	CannedBenchmarkStrings addLast: aByteString
]

{ #category : #'class initialization' }
VMProfiler class >> fixTabs [
	"Make sure the DefaultTabsArray and DefaultMarginTabsArray are adequately sized for modern displays."
	| defaultTab tempArray width |
	(Smalltalk bindingOf: #TextConstants) ifNil: [^self].
	width := 2000.
	(TextConstants at: #DefaultTabsArray) last < width ifTrue:
		[defaultTab := TextConstants at: #DefaultTab.
		 tempArray := Array new: 2000 // defaultTab.
		 1 to: tempArray size do:
			[:i | tempArray at: i put: defaultTab * i].
		 TextConstants at: #defaultTabsArray put: tempArray.
		 tempArray := Array new: (width // defaultTab) // 2.
		 1 to: tempArray size do:
			[:i | tempArray at: i put: (Array with: (defaultTab*i) with: (defaultTab*i))].
		 TextConstants at: #DefaultMarginTabsArray put: tempArray]
]

{ #category : #'as yet unclassified' }
VMProfiler class >> headlessSpyOn: aBlock reportOn: aStream [ 
	"initialize the profiler version (squeak or pharo) and profile headless, writing the results on a given stream"

	(VMProfiler new) version new
		headlessSpyOn: aBlock;
		report: aStream.
		 
]

{ #category : #'class initialization' }
VMProfiler class >> initialize [

	CannedBenchmarkStrings := OrderedCollection new.
	
]

{ #category : #reports }
VMProfiler class >> reportGCStats: gcStatsArray upTime: elapsedMilliseconds on: str [
	| oldSpaceEnd youngSpaceEnd memoryEnd fullGCs fullGCTime incrGCs incrGCTime tenureCount rootOverflows |
	gcStatsArray ifNil: [^self].

	oldSpaceEnd	:= gcStatsArray at: 2. "a.k.a. oldSpace size on Spur"
	fullGCs			:= gcStatsArray at: 7.
	fullGCTime		:= gcStatsArray at: 8.
	incrGCs			:= gcStatsArray at: 9.
	incrGCTime		:= gcStatsArray at: 10.
	tenureCount	:= gcStatsArray at: 11.
	rootOverflows	:= gcStatsArray at: 22.

	str	cr.
	str	nextPutAll: '**Memory**'; cr.
	str	nextPutAll:	'	old			';
		nextPutAll: oldSpaceEnd asStringWithCommasSigned; nextPutAll: ' bytes'; cr.
	self amOnSpur
		ifTrue:
			[(gcStatsArray at: 54) ifNotNil:
				[:freeSpace|
				 str	nextPutAll: '	free		';
					nextPutAll: freeSpace asStringWithCommasSigned; nextPutAll: ' bytes'; cr]]
		ifFalse:
			[youngSpaceEnd	:= gcStatsArray at: 1.
			 memoryEnd		:= gcStatsArray at: 3.
			 str	nextPutAll: '	young		';
				nextPutAll: (youngSpaceEnd - oldSpaceEnd) asStringWithCommasSigned; nextPutAll: ' bytes'; cr.
			 str	nextPutAll: '	used		';
				nextPutAll: youngSpaceEnd asStringWithCommasSigned; nextPutAll: ' bytes'; cr.
			 str	nextPutAll: '	free		';
				nextPutAll: (memoryEnd - youngSpaceEnd) asStringWithCommasSigned; nextPutAll: ' bytes'; cr].

	str	cr.
	str	nextPutAll: '**GCs**'; cr.
	str	nextPutAll: '	full			';
		print: fullGCs; nextPutAll: ' totalling '; nextPutAll: fullGCTime asStringWithCommas; nextPutAll: 'ms (';
		print: ((fullGCTime / elapsedMilliseconds * 100) rounded);
		nextPutAll: '% elapsed time)'.
	fullGCs = 0 ifFalse:
		[str	nextPutAll: ', avg '; print: (fullGCTime / fullGCs roundTo: 0.1); nextPutAll: 'ms'].
	str	cr.
	str	nextPutAll: (self amOnSpur ifTrue: ['	scavenges	'] ifFalse: ['	incr			']);
		print: incrGCs; nextPutAll: ' totalling '; nextPutAll: incrGCTime asStringWithCommas; nextPutAll: 'ms (';
		print: ((incrGCTime / elapsedMilliseconds * 100) roundTo: 0.1);
		nextPutAll: '% elapsed time)'.
	incrGCs = 0 ifFalse:
		[str nextPutAll:', avg '; print: (incrGCTime / incrGCs roundTo: 0.01); nextPutAll: 'ms'].
	str cr.
	str	nextPutAll: '	tenures		';
		nextPutAll: tenureCount asStringWithCommas.
	tenureCount = 0 ifFalse:
		[str nextPutAll: ' (avg '; print: (incrGCs / tenureCount) asInteger; nextPutAll: ' GCs/tenure)'].
	str	cr.
	str	nextPutAll: '	root table	';
		nextPutAll: rootOverflows asStringWithCommas; nextPutAll:' overflows'.
	str cr.

	(gcStatsArray size >= 63 and: [(gcStatsArray at: 63) isInteger]) ifTrue:
		[| numCompactions compactionMsecs |
		str cr; nextPutAll: '**Compiled Code Compactions**'; cr.
		numCompactions := gcStatsArray at: 62.
		compactionMsecs := gcStatsArray at: 63.
		str	tab;
			print: numCompactions; nextPutAll: ' totalling ';
			nextPutAll: compactionMsecs asStringWithCommas; nextPutAll: 'ms (';
			print: ((compactionMsecs / elapsedMilliseconds * 100) rounded);
			nextPutAll: '% elapsed time)'.
		numCompactions = 0 ifFalse:
			[str	nextPutAll: ', avg '; print: (compactionMsecs / numCompactions roundTo: 0.1); nextPutAll: 'ms'].
		str	cr].

	gcStatsArray size >= 61 ifTrue:
		[str cr; nextPutAll: '**Events**'; cr.
		(56 to: 61)
			with: #('Process switches' 'ioProcessEvents calls' 'Interrupt checks' 'Event checks' 'Stack overflows' 'Stack page divorces')
			do: [:index :eventName| | value n |
				value := gcStatsArray at: index.
				n := 22 - eventName size // 4 + 1.
				str	nextPutAll: eventName; tab: n; print: value; nextPutAll: ' (';
					print: (value * 1000 / elapsedMilliseconds) rounded; nextPutAll: ' per second)'; cr]]
]

{ #category : #spying }
VMProfiler class >> spyOn: aBlock [
	
	(VMProfiler new) version default
		spyOn: aBlock.

	
]

{ #category : #'class initialization' }
VMProfiler class >> unload [

	(TheWorldMenu respondsTo: #unregisterOpenCommandWithReceiver:) ifTrue:
		[TheWorldMenu unregisterOpenCommandWithReceiver: self].
	TheWorldMenu unregisterOpenCommand: 'VM Profiler'
]

{ #category : #initialization }
VMProfiler >> clearHistory [
	history := OrderedCollection new.
	historyIndex := 0
]

{ #category : #profiling }
VMProfiler >> clearProfile [
	self stopVMProfile.
	self clearVMProfile.
	self stopVMProfile.
	
	self initializeSamples.
	elapsedTime := 0.
	elapsedStats := nil.

	self clearHistory.

]

{ #category : #primitives }
VMProfiler >> clearVMProfile [
	"Clear the VM profile sample buffer."

	<primitive: 250>
	^self primitiveFailed
]

{ #category : #'Cog compiled code' }
VMProfiler >> computeCogCodeModule [
	cogCodeConstituents ifNil: [^self].
	symbolManager computeCogCodeModule: cogCodeConstituents.
	self changed: #symbolList

	"Compute average cog method size:
	(| cogCodeConstituents i1 i2 |
	cogCodeConstituents :=  VMProfiler basicNew primitiveCollectCogCodeConstituents.
	i1 := cogCodeConstituents indexOf: 'methodZoneBase'.
	i2 := cogCodeConstituents indexOf: 'CCFree'.
	(cogCodeConstituents at: i2 + 1) - (cogCodeConstituents at: i1 + 1) / (i2 - i1 / 2.0))"
]

{ #category : #profiling }
VMProfiler >> computeHistograms: numSamples [
	sampleBuffer ifNil:
		[sampleBuffer := Bitmap new: self profileSize].
	self getVMProfileSamplesInto: sampleBuffer.
	Cursor wait showWhile:
		[1 to: numSamples do:
			[:i|
			sampleBag add: (sampleBuffer at: i)].
		 sortedSamples := sampleBag sortedElements].
	total := total + numSamples
]

{ #category : #sorting }
VMProfiler >> computeSortedSymbols [
	sortedSymbols := cogCodeConstituents
						ifNil: [self sortSymbols: symbolManager modules]
						ifNotNil:
							[self sortedSymbolsBeforeCogCode,
							 (self sortSymbols: {symbolManager cogModule}),
							 self sortedSymbolsAfterCogCode]
]

{ #category : #profiling }
VMProfiler >> computeStats: stopStats [
	elapsedStats ifNil: [elapsedStats := Array new: stopStats size withAll: 0].
	startStats ifNotNil:
		[(#(1 2 3 7 8 9 10 11 22 46 47 56 57 58 59 60 61 62 63) select: [:i| i <= elapsedStats size]) do:
			[:i|
			(stopStats at: i) isNumber ifTrue:
				[elapsedStats at: i put: (stopStats at: i) - (startStats at: i)]]]
]

{ #category : #'as yet unclassified' }
VMProfiler >> createParagraph [
	
	self subclassResponsibility 
]

{ #category : #'as yet unclassified' }
VMProfiler >> getVMParameters [

	self subclassResponsibility 
]

{ #category : #primitives }
VMProfiler >> getVMProfileSamplesInto: sampleBuffer [
	"Stop profiling the virtual machine and if the argument is a
	 Bitmap of the right size, copy the profile data into it. Otherwise fail."

	<primitive: 252>
	^self primitiveFailed
]

{ #category : #spying }
VMProfiler >> headlessSpyOn: aBlock [
	| blockToProfile r |
	blockToProfile := forkProfile 
						ifTrue:
							[| sem fr |
							 sem := Semaphore new.
							 [[fr := aBlock value. sem signal] fork.
							   sem wait.
							   fr]]
						ifFalse: [aBlock].
	[self selectBenchmark: aBlock sourceString]
		on: Error
		do: [:ex|].
	self startProfiling.
	r := blockToProfile ensure: [self stopProfiling].
	^r

]

{ #category : #opening }
VMProfiler >> initialExtent [
	^768@768 min: RealEstateAgent maximumUsableArea extent
]

{ #category : #initialization }
VMProfiler >> initialize [
	self initializeSamples.
	self initializeVersion. 
	self initializeSymbols.
	self clearHistory.
	symbolsMode := #byAddress.
	symbolTypes := IdentitySet new.
	selections := ByteArray new.
	highAddress := lowAddress := minSelectionIndex := maxSelectionIndex := 0.
	self toggleShowing: #module.
	aboutToProfile := false.
	total := rangeTotal := startTime := elapsedTime := 0.
	gcPriorToProfile := clearPriorToProfile := true.
	forkProfile := false
]

{ #category : #initialization }
VMProfiler >> initializeSamples [
	sampleBag := Bag new. sortedSamples := sampleBag sortedElements.
	total := 0.
]

{ #category : #initialization }
VMProfiler >> initializeSymbols [
	Smalltalk platformName
		caseOf: {
				['Mac OS'] -> [Cursor wait showWhile:
								[ symbolManager := VMProfilerMacSymbolsManager using: fileSystem ]].
				['unix'] -> [Cursor wait showWhile:
								[symbolManager := VMProfilerLinuxSymbolsManager using: fileSystem]] }
		otherwise: [self error: 'not yet supported on ', Smalltalk platformName]
]

{ #category : #initialization }
VMProfiler >> initializeVersion [
	
	('Pharo*' match: Smalltalk version) ifTrue: [ version := PharoVMProfiler.
												fileSystem := PharoVMFileSystem new].
	('Squeak*' match: Smalltalk version) ifTrue: [ version := SqueakVMProfiler.
												   fileSystem := SqueakVMFileSystem new].

	
]

{ #category : #reports }
VMProfiler >> interpReport: s [
	| totals samplesInInterp |
	totals := Dictionary new.
	samplesInInterp := 0.
	Cursor execute showWhile:
		[| interp labels|
		interp := (symbolManager symbolsInModule: symbolManager vmModule) detect:
					[:sym| sym name endsWith: 'interpret'].
		labels := (symbolManager symbolsInModule: symbolManager vmModule) select:
					[:sym|
					sym type == #label
					and: [sym address between: interp address and: interp limit]].
		symbolList := {interp}, labels.
		symbolList withIndexDo:
			[:sym :index| | samples |
			samples := self samplesForRange: sym address
							to: (index < symbolList size
									ifTrue: [(symbolList at: index + 1) address]
									ifFalse: [interp limit]).
			samples > 0 ifTrue:
				[totals at: sym put: samples.
				 samplesInInterp := samplesInInterp + samples]]].
	self putReportPreambleOn: s.
	s print: samplesInInterp; nextPutAll: ' samples in the Interpreter'; tab; nextPut: $(;
	   print: total; nextPutAll: ' samples in the entire program)  '.
	self printPercentage: samplesInInterp total: total on: s.
	s nextPutAll: ' of total'; cr; cr.
	totals isEmpty ifFalse:
		[self printSymbolTotals: totals labelled: 'interpret' on: s sumTotal: samplesInInterp].
	self class reportGCStats: elapsedStats upTime: elapsedTime on: s
]

{ #category : #reports }
VMProfiler >> interpreterReport: justWeird [
	UIManager default
		edit: (String streamContents: [:s| self interpReport: s])
		label: 'Interpreter Labels by Cost'
]

{ #category : #accessing }
VMProfiler >> listEntryForIndex: index [
	^(symbolList at: index ifAbsent: [^nil]) displayText
]

{ #category : #reports }
VMProfiler >> longestWidthIn: aCollectionOfAssociations [
	^aCollectionOfAssociations inject: 0 into:
		[:len :assoc|
		len max: (self widthInDefaultFontOf: (assoc key isString
												ifTrue: [assoc key]
												ifFalse: [assoc key name]))]
]

{ #category : #primitives }
VMProfiler >> primitiveCollectCogCodeConstituents [
	"Answer the contents of the code zone as an array of pair-wise element, address
	 in ascending address order.  Answer a string for a runtime routine or abstract label
	 (beginning, end, etc), a CompiledMethod for a cog machine-code method,
	 or a selector (presumably a Symbol) for a cog machine-code open or closed PIC.
	 Fail if this isn't a Cog VM or if out of memory.  If this isn't a Cog VM answer nil."
	<primitive: 253 error: ec>
	^ec ifNotNil: [self primitiveFailed]

	"self basicNew primitiveCollectCogCodeConstituents"
]

{ #category : #primitives }
VMProfiler >> primitiveControlVMProfile: startStopBar size: bufferSizeOrNil [
	"Control the VM statistical profile pc sampling system.
	 The first argument must be a boolean which causes the system to start or stop.
	 The second argument can be nil or is the number of samples to make space for.
	 Answer the current number of samples in the buffer."

	<primitive: 251>
	^self primitiveFailed
]

{ #category : #menus }
VMProfiler >> printPercentage: value total: total on: aStream [
	"Print percentage as NN.FF% (or 100.0%) on aStream"
	| rounded percentage |
	percentage := (rounded := (value * 10000 / total) rounded) / 100.0.
	percentage < 10 ifTrue:
		[aStream space; space].
	aStream print: percentage.
	(rounded \\ 10 = 0 and: [rounded ~= 10000]) ifTrue:
		[aStream nextPut: $0]. 
	aStream nextPut: $%
]

{ #category : #reports }
VMProfiler >> printSymbolTotals: totals labelled: label on: aStream sumTotal: sumTotal [
	"Print sorted totals for all symbols with a total greater than 0.01% of the grand total."
	| substantial insubstantial cut cumulative heading percentageWidth compositionWidth tabWidth labelWidthCut labelledInFull |
	cut := total / 10000.0.
	substantial := totals associations select: [:assoc| assoc value > cut].
	labelWidthCut := total / 1000.0.
	labelledInFull := totals associations select: [:assoc| assoc value > labelWidthCut].
	insubstantial := totals associations
						inject: 0
						into: [:sum :assoc|
							  (assoc value <= cut ifTrue: [assoc value] ifFalse: [0]) + sum].
	substantial := substantial asSortedCollection:
						[:a1 :a2|
						 a1 value > a2 value
						 or: [a1 value = a2 value and: [a1 name < a2 name]]].
	insubstantial > 0 ifTrue:
		[substantial := substantial asArray, {'...others...'->insubstantial}].
	cumulative := 0.
	heading := '% of ', label, ' (% of total)'.
	tabWidth := self widthInDefaultFontOf: (String with: Character tab).
	percentageWidth := self widthInDefaultFontOf: '99.99%    (99.99%) 	'.
	compositionWidth := (self longestWidthIn: labelledInFull) + tabWidth
							max: (self widthInDefaultFontOf: heading) + tabWidth - percentageWidth.
	self put: heading paddedTo: compositionWidth + percentageWidth tabWidth: tabWidth on: aStream.
	aStream nextPutAll: '(samples) (cumulative)'; cr.
	substantial do:
		[:assoc|
		self printPercentage: assoc value total: sumTotal on: aStream.
		aStream space; space; space; space; nextPut: $(.
		self printPercentage: assoc value total: total on: aStream.
		aStream nextPut: $); tab.
		self put: (assoc key isString ifTrue: [assoc key] ifFalse: [assoc key name])
			paddedTo: compositionWidth
			tabWidth: tabWidth
			on: aStream.
		aStream nextPut: $(; print: assoc value; nextPut: $); tab: (assoc value < 100 ifTrue: [2] ifFalse: [1]); nextPut: $(.
		cumulative := cumulative + assoc value.
		self printPercentage: cumulative total: sumTotal on: aStream.
		aStream nextPut: $); cr].
	aStream cr; cr
]

{ #category : #profiling }
VMProfiler >> profileSize [
	"Answer the number of pc samples to allocate space for in the VM.
	 This corresponds to the maximum time the system can collect samples.
	 Since the VM manages the sample buffer as a ring buffer the VM
	 answers the last profileSize samples.
	 256 * 1024 / (1000000 / 666.0) = 174.6 seconds =  2.9 minutes"
	^256 * 1024
]

{ #category : #reports }
VMProfiler >> put: aString paddedTo: compositionWidth tabWidth: tabWidth on: aStream [
	| fittedString size width |
	fittedString := aString.
	size := fittedString size.
	[(width := self widthInDefaultFontOf: fittedString) > compositionWidth] whileTrue:
		[size := size - 2.
		 fittedString := aString contractTo: size].
	aStream
		nextPutAll: fittedString;
		tab: compositionWidth - width + (width \\ tabWidth) // tabWidth
]

{ #category : #reports }
VMProfiler >> putReportPreambleOn: s [
	| expr |
	s nextPutAll: (SmalltalkImage current getSystemAttribute: 0); space; nextPutAll: Date today yyyymmdd; space.
	Time now print24: true on: s.
	s cr.
	(startStats size >= 44
	 and: [(startStats at: 44) isNumber]) ifTrue:
		[s nextPutAll: 'eden size: '; nextPutAll: (startStats at: 44) asStringWithCommas.
		 s nextPutAll: '  stack pages: '; print: (startStats at: 42).
		 (startStats size >= 46
		 and: [(startStats at: 46) isNumber
		 and: [(startStats at: 46) > 0]]) ifTrue:
			[s nextPutAll: '  code size: '; nextPutAll: (startStats at: 46) asStringWithCommas].
		s cr].
	s cr.
	(expr := self trimmedExpressionText) notEmpty ifTrue:
		[s nextPutAll: expr; cr; cr].
	(gcPriorToProfile or: [clearPriorToProfile or: [forkProfile]]) ifTrue:
		[gcPriorToProfile ifTrue: [s nextPutAll: 'gc prior.  '].
		 clearPriorToProfile ifTrue: [s nextPutAll: 'clear prior.  '].
		 forkProfile ifTrue: [s nextPutAll: 'run in separate process.'].
		 s cr].
	elapsedTime > 0 ifTrue:
		[s	print: elapsedTime / 1000.0; nextPutAll: ' seconds; sampling frequency ';
			print: (total * 1000 / elapsedTime) rounded; nextPutAll: ' hz'; cr]
]

{ #category : #selecting }
VMProfiler >> regress [
	| range |
	range := history at: historyIndex.
	range = (lowAddress to: highAddress)
		ifTrue:
			[(historyIndex := historyIndex - 1) > 0 ifTrue:
				[range := history at: historyIndex]]
		ifFalse:
			[history addLast: (lowAddress to: highAddress)].
	lowAddress := range first.
	highAddress := range last.
	self updateAddressDependents.
	self updateButtons.
	self selectSymbolsInRange.
	self plotGraph
]

{ #category : #reports }
VMProfiler >> report: s [
	self totalsDo:
		[:vmTotals :cogTotals :nonVMTotals
		 :samplesInVM :samplesInCog :samplesInNonVMModules :samplesInNonVM |
		"self putReportPreambleOn: s."
		s print: samplesInVM + samplesInCog; nextPutAll: ' samples in the VM'; tab; nextPut: $(;
		   print: total; nextPutAll: ' samples in the entire program)  '.
		self printPercentage: samplesInVM + samplesInCog total: total on: s.
		s nextPutAll: ' of total'; cr; cr.
		cogTotals isEmpty ifFalse:
			[s print: samplesInCog; nextPutAll: ' samples in generated vm code '.
			 self printPercentage: samplesInCog total: samplesInVM + samplesInCog on: s.
			 s nextPutAll: ' of entire vm ('.
			 self printPercentage: samplesInCog total: total on: s.
			 s nextPutAll: ' of total)'; cr.
			 s print: samplesInVM; nextPutAll: ' samples in vanilla vm code '.
			 self printPercentage: samplesInVM total: samplesInVM + samplesInCog on: s.
			 s nextPutAll: ' of entire vm ('.
			 self printPercentage: samplesInVM total: total on: s.
			 s nextPutAll: ' of total)'; cr; cr.
			 self printSymbolTotals: cogTotals labelled: 'generated vm code' on: s sumTotal: samplesInCog].
		vmTotals isEmpty ifFalse:
			[self printSymbolTotals: vmTotals labelled: 'vanilla vm code' on: s sumTotal: samplesInVM].
		(samplesInNonVM * 100 >= total
		 and: [nonVMTotals notEmpty]) ifTrue:
			[s print: samplesInNonVM; nextPutAll: ' samples in the rest  '.
			 self printPercentage: samplesInNonVM total: total on: s.
			 s nextPutAll: ' of total'; cr; cr.
			 self printSymbolTotals: nonVMTotals labelled: 'rest' on: s sumTotal: samplesInNonVM].
		self class reportGCStats: elapsedStats upTime: elapsedTime on: s]
]

{ #category : #accessing }
VMProfiler >> samplesForRange: address to: limit [
	| numSamples sampleIndex size nextSample |
	numSamples := 0.
	sampleIndex := sortedSamples findBinaryIndex: [:sample| address - sample key] ifNone: [:lowIdx :highIdx| highIdx].
	size := sortedSamples size.
	[sampleIndex <= size
	 and: [(nextSample := sortedSamples at: sampleIndex) key < limit]] whileTrue:
		[numSamples := numSamples + nextSample value.
		 sampleIndex := sampleIndex + 1].
	^numSamples
]

{ #category : #accessing }
VMProfiler >> samplesForSymbol: sym [
	^self samplesForRange: sym address to: sym limit
]

{ #category : #selecting }
VMProfiler >> selectProportionFrom: low to: high [
	| range |
	self addToHistory.
	range := highAddress - lowAddress.
	highAddress := lowAddress + (range * high) rounded.
	lowAddress := lowAddress + (range * low) rounded.
	self selectSymbolsInRange.
	self updateAddressDependents.
	self updateButtons.
	self plotGraph
]

{ #category : #selecting }
VMProfiler >> selectSymbolsInRange [
	minSelectionIndex := maxSelectionIndex := 0.
	1 to: (selections size min: symbolList size) do:
		[:i| | symbol |
		symbol := symbolList at: i.
		selections at: i put: ((symbol limit notNil "guard against lazy initialization"
							and: [symbol limit > lowAddress
							and: [symbol address <= highAddress]])
								ifTrue: [minSelectionIndex = 0 ifTrue: [minSelectionIndex := i].
										maxSelectionIndex := i.
										1]
								ifFalse: [0])].
	self changed: #allSelections.
	self changed: #symbolIndex
]

{ #category : #sorting }
VMProfiler >> sortSymbols: modules [
	"Answer an Array of all the symbols in each of modules, which is assumed to be sorted."
	^Array streamContents:
		[:s| | prev |
		 modules do:
			[:m|
			prev
				ifNil: [prev := m]
				ifNotNil: [m address > prev address ifFalse: [self error: 'modules not sorted']].
			s nextPut: m;
			  nextPutAll: ((symbolManager symbolsInModule: m) sorted:
								[:s1 :s2|
								 s1 address = s2 address
									ifTrue: [s1 importance > s2 importance]
									ifFalse: [s1 address < s2 address]])]]
]

{ #category : #sorting }
VMProfiler >> sortedSymbolsAfterCogCode [
	^sortedSymbolsAfterCogCode ifNil:
		[sortedSymbolsAfterCogCode := self sortSymbols: (symbolManager modules select: [:m| m address > cogCodeConstituents last])]
]

{ #category : #sorting }
VMProfiler >> sortedSymbolsBeforeCogCode [
	^sortedSymbolsBeforeCogCode ifNil:
		[sortedSymbolsBeforeCogCode := self sortSymbols: (symbolManager modules select: [:m| m address < cogCodeConstituents second])]
]

{ #category : #spying }
VMProfiler >> spyOn: aBlock [
	^ self headlessSpyOn: aBlock
	
]

{ #category : #profiling }
VMProfiler >> startProfiling [
	"still UI-dependent"
	"Use aboutToProfile to allow us to change the button colors without including the change in the profile."
	aboutToProfile := true.
	self clearHistory.
	"self updateButtons."
	World doOneCycleNow.
	clearPriorToProfile ifTrue: [self clearProfile].
	gcPriorToProfile ifTrue: [Smalltalk garbageCollect].
	startStats := self getVMParameters. 
	startTime := Time millisecondClockValue.
	self startVMProfile.
	aboutToProfile := false
]

{ #category : #primitives }
VMProfiler >> startVMProfile [
	"Start profiling the virtual machine."
	self primitiveControlVMProfile: true size: self profileSize
]

{ #category : #profiling }
VMProfiler >> stopProfiling [
	"still UI-dependent"
	| numSamples now vmParameters |
	numSamples := self stopVMProfile.
	now := Time millisecondClockValue.
	vmParameters := self getVMParameters. 
	cogCodeConstituents := self primitiveCollectCogCodeConstituents.
	elapsedTime := now - startTime + elapsedTime.
	self computeStats: vmParameters.
	self computeHistograms: numSamples.
	self computeCogCodeModule.
	"self computeSortedSymbols." "makes the profiling crash"
	self clearHistory.
	"self updateButtons"
]

{ #category : #primitives }
VMProfiler >> stopVMProfile [
	"Stop profiling the virtual machine."
	^self primitiveControlVMProfile: false size: self profileSize
]

{ #category : #accessing }
VMProfiler >> symbolIndex [
	"Answer the first index in the last contiguous range of selections."
	| index |
	minSelectionIndex = 0 ifTrue: [^0].
	index := maxSelectionIndex.
	[index > 1 and: [(selections at: index - 1) ~= 0]] whileTrue:
		[index := index - 1].
	^index
]

{ #category : #accessing }
VMProfiler >> symbolList [
	^symbolList
]

{ #category : #accessing }
VMProfiler >> symbolSelectionAt: index [ 
	^(selections at: index ifAbsent: [0]) ~= 0
]

{ #category : #buttons }
VMProfiler >> toggleShowing: aSymbol [
	(symbolTypes includes: aSymbol)
		ifTrue: [symbolTypes remove: aSymbol]
		ifFalse: [symbolTypes add: aSymbol].
	symbolTypes isEmpty ifTrue:
		[symbolTypes add: #module.
		 self changed: #showingModules.
		 aSymbol == #module ifTrue:
			[^self]].
	self changed: #showingModules;
		changed: #showingPublicFunctions;
		changed: #showingPrivateFunctions;
		changed: #showingLabels.
	symbolList := symbolManager symbolsWithTypes: symbolTypes.
	selections := ByteArray new: symbolList size.
	self selectSymbolsInRange.
	self changed: #symbolList;
		changed: #positionedLabels
]

{ #category : #reports }
VMProfiler >> totalsDo: septuaryBlock [
	"Evaluate aBlock with 
		a Dictionary of symbol -> total for the functions in the VM (excluding generated code)
		a Dictionary of symbol -> total for the generated code in the VM
		a Dictionary of symbol -> total for the functions in other code
		total number of samples in functions in the VM (excluding generated code)
		total number of samples in generated code in the VM
		total number of samples in generated code in the VM
		total number of samples in functions in other code
		total number of samples not in VM or VM-generated code (incudes code not in any function)"
	| vmTotals cogTotals nonVMTotals
	  samplesInVM samplesInCog samplesInNonVMModules samplesInNonVM |
	vmTotals := Dictionary new.
	cogTotals := Dictionary new.
	nonVMTotals := Dictionary new.
	samplesInVM := samplesInCog := samplesInNonVMModules := 0.
	(symbolManager symbolsInModule: symbolManager vmModule) do:
		[:sym| | samples |
		((#(publicFunction privateFunction) includes: sym type)
		 and: [(samples := self samplesForSymbol: sym) > 0]) ifTrue:
			[vmTotals at: sym put: samples.
			 samplesInVM := samplesInVM + samples]].
	 (symbolManager symbolsInModule: symbolManager cogModule) do:
		[:sym| | samples |
		((#(publicFunction privateFunction) includes: sym type)
		 and: [(samples := self samplesForSymbol: sym) > 0]) ifTrue:
			[cogTotals at: sym put: samples.
			 samplesInCog := samplesInCog + samples]].
	 ((symbolManager modules
			copyWithout: symbolManager vmModule)
				copyWithout: symbolManager cogModule) do:
		[:module|
		(symbolManager symbolsInModule: module) do:
			[:sym| | samples |
			((#(publicFunction privateFunction) includes: sym type)
			and: [(samples := self samplesForSymbol: sym) > 0]) ifTrue:
				[nonVMTotals at: sym put: samples.
				 samplesInNonVMModules := samplesInNonVMModules + samples]]].
	samplesInNonVM := total - samplesInVM - samplesInCog.
	nonVMTotals
		at: 'Samples Not In Any Function'
		put: samplesInNonVM - samplesInNonVMModules.
	septuaryBlock valueWithArguments:
		{vmTotals.
		 cogTotals.
		 nonVMTotals.
		 samplesInVM.
		 samplesInCog.
		 samplesInNonVMModules.
		 samplesInNonVM}
]

{ #category : #accessing }
VMProfiler >> version [
	^ version 
]

{ #category : #reports }
VMProfiler >> vmReport: justWeird [
	UIManager default
		edit: (String streamContents: [:s| self report: s])
		label: 'VM Functions by Cost'
]

{ #category : #reports }
VMProfiler >> widthInDefaultFontOf: aString [
	^(self createParagraph 
		compose: aString asText
		style: TextStyle default
		from: 1
		in: Display boundingBox;
		adjustRightX)
		extent x
]
