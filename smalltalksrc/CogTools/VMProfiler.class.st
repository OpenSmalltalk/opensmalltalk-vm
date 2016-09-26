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
		'lowResolution',
		'highResSamples',
		'lowResSamples',
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
		'cogCodeConstituents'
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

{ #category : #reports }
VMProfiler class >> amOnSpur [
	^(Smalltalk vmParameterAt: 41) anyMask: 16
]

{ #category : #'class initialization' }
VMProfiler class >> canBenchmark: aByteString [ 
	CannedBenchmarkStrings addLast: aByteString
]

{ #category : #'instance creation' }
VMProfiler class >> default [
	^self openInstance
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

{ #category : #'class initialization' }
VMProfiler class >> initialize [

	CannedBenchmarkStrings := OrderedCollection new.
	(TheWorldMenu respondsTo: #registerOpenCommand:) ifTrue:
		[TheWorldMenu registerOpenCommand: {'VM Profiler'. {self. #open}. 'A VM profiler'}].
	Preferences
		addBooleanPreference: #vmProfilerFillInIntegral 
		category: #vmProfiler 
		default: false
		balloonHelp: 'If enabled, the profiler will fill in the area under the integral.'.
	self fixTabs
]

{ #category : #'instance creation' }
VMProfiler class >> open [
	^self new openInWindow
]

{ #category : #'instance creation' }
VMProfiler class >> openInstance [
	| window |
	window := World submorphs
					detect: [:sm| sm isSystemWindow and: [sm label = 'VMProfiler']]
					ifNone: [self open].
	^window model
]

{ #category : #spying }
VMProfiler class >> report: aStream [
	"Compatibility with MessageTally and AndreasSystemProfiler instance side spyOn: & report:"
	^self openInstance report: aStream
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
		print: fullGCTime / elapsedMilliseconds * 100 maxDecimalPlaces: 3;
		nextPutAll: '% elapsed time)'.
	fullGCs = 0 ifFalse:
		[str	nextPutAll: ', avg '; print: fullGCTime / fullGCs maxDecimalPlaces: 3; nextPutAll: 'ms'].
	str	cr.
	str	nextPutAll: (self amOnSpur ifTrue: ['	scavenges	'] ifFalse: ['	incr			']);
		print: incrGCs; nextPutAll: ' totalling '; nextPutAll: incrGCTime asStringWithCommas; nextPutAll: 'ms (';
		print: incrGCTime / elapsedMilliseconds * 100 maxDecimalPlaces: 3;
		nextPutAll: '% elapsed time)'.
	incrGCs = 0 ifFalse:
		[str nextPutAll:', avg '; print: incrGCTime / incrGCs maxDecimalPlaces: 3; nextPutAll: 'ms'].
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
			print: compactionMsecs / elapsedMilliseconds * 100 maxDecimalPlaces: 3;
			nextPutAll: '% elapsed time)'.
		numCompactions = 0 ifFalse:
			[str	nextPutAll: ', avg '; print: compactionMsecs / numCompactions maxDecimalPlaces: 3; nextPutAll: 'ms'].
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
	"Compatibility with MessageTally and AndreasSystemProfiler instance side spyOn: & report:"
	^Cursor execute showWhile:
		[self openInstance spyOn: aBlock]
]

{ #category : #'class initialization' }
VMProfiler class >> unload [

	(TheWorldMenu respondsTo: #unregisterOpenCommandWithReceiver:) ifTrue:
		[TheWorldMenu unregisterOpenCommandWithReceiver: self].
	TheWorldMenu unregisterOpenCommand: 'VM Profiler'
]

{ #category : #selecting }
VMProfiler >> addToHistory [
	historyIndex < history size ifTrue:
		[history := history copyFrom: 1 to: historyIndex].
	(history isEmpty or: [history last ~= (lowAddress to: highAddress)]) ifTrue:
		[history addLast: (lowAddress to: highAddress).
		 historyIndex := history size].

]

{ #category : #opening }
VMProfiler >> addressTextMorph: help get: getter set: setter [
	| ptm |
	ptm := PluggableTextMorph
			on: self
			text: getter accept: setter
			readSelection: nil menu: nil.
	ptm setProperty: #alwaysAccept toValue: true;
		askBeforeDiscardingEdits: false;
		acceptOnCR: true;
		setBalloonText: help;
		retractableOrNot;
		hideOrShowScrollBars;
		setProperty: #noScrollBarPlease toValue: true;
		setProperty: #noVScrollBarPlease toValue: true.
	^ptm
]

{ #category : #opening }
VMProfiler >> backwardsButton [
	^ImageMorph new image: ((ScriptingSystem formAtKey: #playMPEG) flipBy: #horizontal centerAt: 0@0)
]

{ #category : #opening }
VMProfiler >> buttonMorph: getLabelMessage help: help set: setter enable: enabler color: colorGetter [
	| pbm |
	pbm := PluggableButtonMorphPlus on: self getState: nil action: setter label: getLabelMessage.
	pbm
		useRoundedCorners;
		getEnabledSelector: enabler;
		setBalloonText: help;
		getColorSelector: colorGetter;
		offColor: Color transparent.
	^pbm
]

{ #category : #opening }
VMProfiler >> checkMorph: help get: getter set: setter [
	| checkBoxButton |
	checkBoxButton := UpdatingThreePhaseButtonMorph checkBox.
	#(onImage pressedImage offImage)
		with: #(onImage: pressedImage: offImage:)
		do: [:get :set| | form |
			((form := checkBoxButton perform: get) isColorForm
			 and: [form colors last = Color white]) ifTrue:
				[checkBoxButton
					perform: set
					with: ((checkBoxButton perform: get) copy
							colors: {Color transparent. Color black};
							yourself)]].
	^checkBoxButton
		target: self;
		actionSelector: setter;
		getSelector: getter;
		setBalloonText: help;
		yourself
]

{ #category : #buttons }
VMProfiler >> clearButton [
	"just weird..."
	^'clear'
]

{ #category : #buttons }
VMProfiler >> clearColor [
	^Color lightBlue
]

{ #category : #initialization }
VMProfiler >> clearHistory [
	history := OrderedCollection new.
	historyIndex := 0
]

{ #category : #buttons }
VMProfiler >> clearPriorToProfile [
	^clearPriorToProfile
]

{ #category : #profiling }
VMProfiler >> clearProfile [
	self stopVMProfile.
	self clearVMProfile.
	self stopVMProfile.
	
	highResSamples atAllPut: 0.
	lowResSamples atAllPut: 0.
	total := 0.
	elapsedTime := 0.
	elapsedStats := nil.

	self clearHistory.
	self updateButtons
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
	sampleBuffer isNil ifTrue:
		[sampleBuffer := Bitmap new: self profileSize].
	self getVMProfileSamplesInto: sampleBuffer.
	Cursor wait showWhile:
		[1 to: numSamples do:
			[:i| | pc |
			pc := sampleBuffer at: i.
			highResSamples noCheckAt: pc put: (highResSamples noCheckAt: pc) + 1.
			lowResSamples at: pc // lowResolution + 1 put: (lowResSamples at: pc // lowResolution + 1) + 1]].
	total := total + numSamples
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

{ #category : #buttons }
VMProfiler >> drawButton [
	"just weird..."
	^'plot'
]

{ #category : #menus }
VMProfiler >> expressionTextMenu: aMenuMorph [
	| expression |
	expression := self trimmedExpressionText.
	(expression isEmpty
	or: [CannedBenchmarkStrings includes: expression]) ifFalse:
		[aMenuMorph add: 'add text to benchmarks' target: self class selector: #canBenchmark: argument: expression].
	aMenuMorph add: 'inspect canned benchmarks' target: ToolSet selector: #inspect: argument: CannedBenchmarkStrings.
	CannedBenchmarkStrings isEmpty ifTrue:
		[^aMenuMorph].
	aMenuMorph addLine.
	CannedBenchmarkStrings do:
		[:benchmark|
		 aMenuMorph add: (benchmark contractTo: 60) target: self selector: #selectBenchmark: argument: benchmark].
	^aMenuMorph
]

{ #category : #menus }
VMProfiler >> findSymbol: typeOrNil event: event [
	| pattern matches selection anIndex |
	previousPattern ifNil:
		[previousPattern := '*'].
	pattern := UIManager default
					request: 'Symbol or pattern to find'
					initialAnswer: previousPattern.
	pattern isEmpty ifTrue: [^self].
	previousPattern := pattern.
	matches := symbolManager symbolsSelect:
					(typeOrNil
						ifNotNil:
							[(pattern includesAnyOf: '#*')
								ifTrue: [[:sym|
										 sym type == typeOrNil
										 and: [sym nameMatches: pattern]]]
								ifFalse: [[:sym|
										 sym type == typeOrNil
										 and: [sym name
												includesSubstring: pattern
												caseSensitive: false]]]]
						ifNil:
							[(pattern includesAnyOf: '#*')
								ifTrue: [[:sym| sym nameMatches: pattern]]
								ifFalse: [[:sym| sym name
												includesSubstring: pattern
												caseSensitive: false]]]).
	matches isEmpty ifTrue:
		[^UIManager inform: 'No symbols match your query'].
	matches size = 1
		ifTrue: [selection := matches first]
		ifFalse:
			[matches := matches asSortedCollection:
					[:s1 :s2| | sd1 sd2 |
					(sd1 := s1 displayText) asString < (sd2 := s2 displayText) asString
					or: [sd1 = sd2 and: [s1 address <= s2 address]]].
			 selection := (SelectionMenu
							labelList: {'Choose symbol'},
									  (matches collect:
										[:ea|
										ea type == #module
											ifTrue: [ea displayText]
											ifFalse: [ea displayText, ' @', (ea address printStringRadix: 16),
													' in ', (symbolManager moduleFor: ea) displayText]])
							lines: {1}
							selections: {nil}, matches) startUp.
			selection ifNil: [^self]].
	(symbolTypes includes: selection type) ifFalse:
		[self toggleShowing: selection type].
	minSelectionIndex := 0.
	1 to: symbolList size do:
		[:i|
		selections
			at: i
			put: (((symbolList at: i) address >= selection address
				  and: [(symbolList at: i) limit <= selection limit])
					ifTrue: [minSelectionIndex = 0 ifTrue: [minSelectionIndex := i].
							maxSelectionIndex := i.
							1]
					ifFalse: [0])].
	self changed: #symbolList.
	self addToHistory.
	"If selecting a label make sure there's not a zero address range so
	 select from the previous non-label symbol to the following non-label symbol"
	selection address = selection limit
		ifTrue: [anIndex := minSelectionIndex.
				[(symbolList at: anIndex) type == #label
				and: [anIndex > 1]] whileTrue: [anIndex := anIndex - 1].
				lowAddress := (symbolList at: anIndex) address.
				anIndex := maxSelectionIndex.
				[(symbolList at: anIndex) type == #label
				and: [anIndex < symbolList size]] whileTrue: [anIndex := anIndex + 1].
				highAddress := (symbolList at: anIndex) address]
		ifFalse:
			[lowAddress := selection address.
			 highAddress := selection limit]. 
	self updateAddressDependents;
		updateButtons;
		plotGraph
]

{ #category : #buttons }
VMProfiler >> forkProfile [
	^forkProfile
]

{ #category : #opening }
VMProfiler >> forwardsButton [
	^ImageMorph new image: (ScriptingSystem formAtKey: #playMPEG)
]

{ #category : #buttons }
VMProfiler >> gcPriorToProfile [
	^gcPriorToProfile
]

{ #category : #primitives }
VMProfiler >> getVMProfileSamplesInto: sampleBuffer [
	"Stop profiling the virtual machine and if the argument is a
	 Bitmap of the right size, copy the profile data into it. Otherwise fail."

	<primitive: 252>
	^self primitiveFailed
]

{ #category : #accessing }
VMProfiler >> graphMargin [
	^graph margin
]

{ #category : #selecting }
VMProfiler >> hasFuture [
	^historyIndex < history size
]

{ #category : #buttons }
VMProfiler >> hasFutureColor [
	^self hasFuture ifTrue: [Color transparent] ifFalse: [Color darkGray]
]

{ #category : #selecting }
VMProfiler >> hasHistory [
	^historyIndex >= 1
]

{ #category : #buttons }
VMProfiler >> hasHistoryColor [
	^self hasHistory ifTrue: [Color transparent] ifFalse: [Color darkGray]
]

{ #category : #accessing }
VMProfiler >> highAddressText [
	^((highAddress printStringRadix: 16) allButFirst: 3) asText
]

{ #category : #accessing }
VMProfiler >> highAddressText: aText [
	highAddress := ((Integer readFrom: aText asString asUppercase readStream base: 16) max: 0) min: 16rFFFFFFFF.
	self selectSymbolsInRange
]

{ #category : #accessing }
VMProfiler >> highResSamplesFor: sym [
	| samples |
	samples := 0.
	sym address to: sym limit - 1 do:
			[:a| samples := samples + (highResSamples at: a)].
	^samples
]

{ #category : #opening }
VMProfiler >> historyButtonMorph: getLabelMessage help: help set: setter enable: enabler color: colorGetter [
	| pbm |
	pbm := PluggableButtonMorphPlus on: self getState: nil action: setter label: getLabelMessage.
	pbm
		getEnabledSelector: enabler;
		setBalloonText: help;
		getColorSelector: colorGetter;
		offColor: Color transparent.
	^pbm
]

{ #category : #opening }
VMProfiler >> initialExtent [
	^768@768 min: RealEstateAgent maximumUsableArea extent
]

{ #category : #initialization }
VMProfiler >> initialize [
	"Use a SparseLargeArray so we can apparently have a sample per pc in the entire address space"
	highResSamples := SparseLargeArray
							new: (2 raisedToInteger: 32)
							chunkSize: 32 * 1024
							arrayClass: Array
							base: 0
							defaultValue: 0.
	lowResolution := 16 * 1024.
	lowResSamples := Array new: (2 raisedToInteger: 32) / lowResolution withAll: 0.
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
VMProfiler >> initializeSymbols [
	Smalltalk platformName
		caseOf: {
				['Mac OS'] -> [Cursor wait showWhile:
								[symbolManager := VMProfilerMacSymbolsManager new]].
				['unix'] -> [Cursor wait showWhile:
								[symbolManager := VMProfilerLinuxSymbolsManager new]] }
		otherwise: [self error: 'not yet supported on ', Smalltalk platformName]
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
			samples := 0.
			sym address
				to: (index < symbolList size
						ifTrue: [(symbolList at: index + 1) address]
						ifFalse: [interp limit]) - 1
				do:
					[:a| samples := samples + (highResSamples at: a)].
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

{ #category : #opening }
VMProfiler >> labelFont [
	"Answer the font in which to draw the graph labels.
	 N.B. the labelling morph shrinks this font by half when displaying."
	^(TextStyle named: 'BitstreamVeraSans') fontOfPointSize: 16
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

{ #category : #accessing }
VMProfiler >> lowAddressText [
	^((lowAddress printStringRadix: 16) allButFirst: 3) asText
]

{ #category : #accessing }
VMProfiler >> lowAddressText: aText [
	lowAddress := ((Integer readFrom: aText asString asUppercase readStream base: 16) max: 0) min: 16rFFFFFFFF.
	self selectSymbolsInRange
]

{ #category : #profiling }
VMProfiler >> notProfiling [
	^self profiling not
]

{ #category : #profiling }
VMProfiler >> notProfilingAndData [
	^sampleBuffer notNil and: [self notProfiling]
]

{ #category : #opening }
VMProfiler >> openInWindow [
	"VMProfiler open"
	| window symbolListMorph labelsMorph buttons |
	(window := SystemWindow new)
		setProperty: #allowPaneSplitters toValue: false;
		model: self;
		setLabel: self class name;
		fillStyle: Color white;
		paneColor: Color white;
		color: Color white.
	(window respondsTo: #allowPaneSplitters:) ifTrue:
		[window allowPaneSplitters: false].
	"Cope with Squeak 4.1 SystemWindow background color changes"
	window addMorph: (AlignmentMorph new color: Color white; yourself) frame: (0@0 corner: 1@1).
	symbolListMorph := PluggableListMorphOfManyAlt
						on: self
						list: #symbolList
						primarySelection: #symbolIndex
						changePrimarySelection: #toggleListIndex:
						listSelection: #symbolSelectionAt:
						changeListSelection: #symbolSelectionAt:put:
						getListElement: #listEntryForIndex:
						menu: #symbolListMenu:.
	symbolListMorph showHScrollBarOnlyWhenNeeded: false. "buggy misnamed selector :)"
	labelsMorph := VMProfileGraphLabelMorph model: self font: self labelFont getLabels: #positionedLabels.
	expressionTextMorph := PluggableTextMorph
								on: self
								text: nil accept: nil
								readSelection: #selectionRange
								menu: #expressionTextMenu:.
	expressionTextMorph
		setProperty: #alwaysAccept toValue: true;
		askBeforeDiscardingEdits: false;
		setBalloonText: 'type an expression to profile here'.
	buttons := OrderedCollection new.
	window
		addMorph: symbolListMorph frame: (0@0 corner: 0.15@1);
		addMorph: (graph := VMProfilePlotMorph model: self) frame: (0.15@0 corner: 1.0@0.7);
		addMorph: labelsMorph frame: (0.15@0.7 corner: 1.0@0.85);
		"address boxes"
		addMorph: (self addressTextMorph:'Type the low address of the histogram here'
						get: #lowAddressText
						set: #lowAddressText:)
			frame: (0.16@0.86 corner: 0.27@0.91);
		addMorph: (self addressTextMorph:'Type the high address of the histogram here'
						get: #highAddressText
						set: #highAddressText:)
			frame: (0.88@0.86 corner: 0.99@0.91);
		addMorph: (self totalTextMorph: 'Shows the total number of samples' get: #totalText)
			frame: (0.88@0.92 corner: 0.99@0.98);
		"symbol list check-box filters"
		addMorph: (self checkMorph: 'show module symbols'
						get: #showingModules
						set: #toggleShowModules)
			frame: (0.16@0.915 corner: 0.175@0.93);
		addMorph: (buttons addLast: (StringMorph contents: 'modules'))
			frame: (0.19@0.915 corner: 0.27@0.93);
		addMorph: (self checkMorph: 'show extern symbols'
						get: #showingPublicFunctions
						set: #toggleShowPublicFunctions)
			frame: (0.16@0.935 corner: 0.175@0.95);
		addMorph: (buttons addLast: (StringMorph contents: 'externs'))
			frame: (0.19@0.935 corner: 0.27@0.95);
		addMorph: (self checkMorph: 'show static symbols'
						get: #showingPrivateFunctions
						set: #toggleShowPrivateFunctions)
			frame: (0.16@0.955 corner: 0.175@0.97);
		addMorph: (buttons addLast: (StringMorph contents: 'statics'))
			frame: (0.19@0.955 corner: 0.27@0.97);
		addMorph: (self checkMorph: 'show static symbols'
						get: #showingLabels
						set: #toggleShowLabels)
			frame: (0.16@0.975 corner: 0.175@0.99);
		addMorph: (buttons addLast: (StringMorph contents: 'labels'))
			frame: (0.19@0.975 corner: 0.27@0.99);
		"history buttons"
		addMorph: (self historyButtonMorph: #backwardsButton help: 'go back to previous selection'
						set: #regress enable: #hasHistory color: #hasHistoryColor)
			frame: (0.28@0.86 corner: 0.315@0.90);
		addMorph: (self historyButtonMorph: #forwardsButton help: 'go forward to next selection'
						set: #progress enable: #hasFuture color: #hasFutureColor)
			frame: (0.32@0.86 corner: 0.355@0.90);
		"profiling buttons"
		addMorph: (self buttonMorph: #drawButton help: 'plot the graph'
						set: #plotGraph enable: #notProfilingAndData color: #clearColor)
			frame: (0.37@0.86 corner: 0.45@0.91);
		addMorph: (self buttonMorph: #clearButton help: 'clear the histogram data'
						set: #clearProfile enable: #notProfiling color: #clearColor)
			frame: (0.46@0.86 corner: 0.54@0.91);
		addMorph: (self buttonMorph: #startButton help: 'start the profiler'
						set: #startProfiling enable: #notProfiling color: #profileColor)
			frame: (0.28@0.915 corner: 0.36@0.96);
		addMorph: (self buttonMorph: #stopButton help: 'stop the profiler'
						set: #stopProfiling enable: #profiling color: #stopColor)
			frame: (0.37@0.915 corner: 0.45@0.96);
		addMorph: (self buttonMorph: #profileExpressionButton help: 'compile and profile the expression to the right'
						set: #profileExpression enable: #notProfiling color: #profileColor)
			frame: (0.46@0.915 corner: 0.54@0.96);
		addMorph: expressionTextMorph
			frame: (0.55@0.86 corner: 0.87@0.98);
		addMorph: (self checkMorph: 'Run the full garbage collector prior to profiling'
						get: #gcPriorToProfile
						set: #toggleGcPriorToProfile)
			frame: (0.28@0.97 corner: 0.295@0.985);
		addMorph: (buttons addLast: (StringMorph contents: 'gc prior'))
			frame: (0.30@0.97 corner: 0.365@0.995);
		addMorph: (self checkMorph: 'Clear the profile prior to profiling'
						get: #clearPriorToProfile
						set: #toggleClearPriorToProfile)
			frame: (0.37@0.97 corner: 0.385@0.985);
		addMorph: (buttons addLast: (StringMorph contents: 'clear prior'))
			frame: (0.39@0.97 corner: 0.455@0.995);
		addMorph: (self checkMorph: 'Run the profiled expression in its own process'
						get: #forkProfile
						set: #toggleForkProfile)
			frame: (0.46@0.97 corner: 0.475@0.985);
		addMorph: (buttons addLast: (StringMorph contents: 'fork profile'))
			frame: (0.48@0.97 corner: 0.545@0.995).
.
	"A Color transparent fillStyle used to be the default.  What a
	 pain that things change so radically from release to release!"
	graph fillStyle: Color transparent.

	self updateButtons. "weird!"
	buttons do: [:buttonMorph| buttonMorph color: Color black]. "otherwise labels don't show :("
	window openInWorld.
	self toggleShowing: #module.
	^window
]

{ #category : #graph }
VMProfiler >> plot: data from: start to: end addressRange: startAddress to: limitAddress [
	| histSeries intSeries resolution prevX prevY prevI sum integral bin binsPerPoint fillInIntegral |
	graph clear.
	histSeries := graph series: #histogram.
	intSeries := graph alternateSeries: #integral.
	fillInIntegral := Preferences vmProfilerFillInIntegral.
	intSeries color: Color magenta; type: #stepped; drawArea: fillInIntegral.
	resolution := graph drawBounds width.
	binsPerPoint := end - start + 1 >= resolution
					ifTrue: [(end - start + 1 / resolution) ceiling]
					ifFalse: [1].
	prevY := prevI := integral := 0.
	prevX := bin := start.
	[bin <= end] whileTrue:
		[binsPerPoint > 1
			ifTrue:
				[sum := 0.
				 bin to: (bin + binsPerPoint - 1 min: end) do:
					[:i| sum := sum + (data at: i)]]
			ifFalse:
				[sum := data at: bin].
		sum = 0
			ifTrue:
				[(bin = start or: [prevY ~= 0]) ifTrue:
					[histSeries addPoint: bin @ sum.
					 intSeries addPoint: bin @ integral]]
			ifFalse:
				[prevY = 0 ifTrue:
					[histSeries addPoint: prevX @ prevY.
					 intSeries addPoint: prevX @ prevI].
				 histSeries addPoint: bin @ sum.
				 intSeries addPoint: bin @ (integral := integral + sum)].
		prevX := bin.
		prevY := sum.
		prevI := integral.
		bin := bin + binsPerPoint].
	histSeries addPoint: end @ 0.
	intSeries addPoint: end @ integral.
	(fillInIntegral and: [integral ~= 0]) ifTrue:
		[intSeries addPoint: end @ 0].
	rangeTotal := integral.
	graph xAxisFormatter:
		[:n| | address |
		address := [startAddress + ((n asFloat - start) * (limitAddress - startAddress) / (end - start))]
					on: ZeroDivide
					do: [:ex| 0].
		(address rounded asInteger printStringRadix: 16) allButFirst: 3].
	graph yAxisFormatter:
		[:n|
		(n rounded = n
			ifTrue: [n]
			ifFalse:
				[n >= 100
					ifTrue: [n rounded]
					ifFalse: [(n * 10) rounded / 10]]) printString].
	graph limitMinX: start limitMaxX: end.
	self changed: #positionedLabels; changed: #totalText
]

{ #category : #graph }
VMProfiler >> plotGraph [
	lowResSamples first ifNil: [^self].
	(lowAddress = 0 and: [highAddress = 0]) ifTrue:
		[highAddress := (1 << 32) - 1.
		 self updateAddressDependents].
	highAddress - lowAddress / lowResolution > 100
		ifTrue:
			[self plot: lowResSamples
				from: lowAddress // lowResolution + 1
				to: (highAddress + lowResolution - 1 // lowResolution + 1
						min: lowResSamples size)
				addressRange: lowAddress
				to: highAddress]
		ifFalse:
			[self plot: highResSamples
				from: lowAddress
				to: highAddress
				addressRange: lowAddress
				to: highAddress].
	graph fullDrawOn: Display getCanvas
]

{ #category : #accessing }
VMProfiler >> positionedLabels [
	"Compute the set of labels to be displayed for the given address range.
	 Try and display no more than maxLabels labels.  The result is a dictionary
	 of fractional position in the range to string.  If there are lots of labels, try
	 and favour those that have samples."
	| maxLabels counts types symbolsInRange positionedLabels index count range significantSymbolsInRange |
	maxLabels := 50.
	minSelectionIndex isZero ifTrue:
		[^Dictionary new].
	"count how many labels of each type there are in the range."
	counts := Dictionary new.
	(types := #(module objectFile publicFunction privateFunction label)) do:
		[:type| counts at: type put: 0].
	types := types select: [:type| symbolTypes includes: type].
	symbolsInRange := symbolManager symbolsSelect: [:sym| sym address <= highAddress and: [sym limit >= lowAddress and: [(symbolTypes includes: sym type)]]].
	"If there are kots if klabels then choose to display only those with samples"
	symbolsInRange size > (maxLabels / 2) ifTrue:
		[significantSymbolsInRange := symbolsInRange select: [:s| (self symHasLowResSamples: s) and: [(self highResSamplesFor: s) > 0]]].
	(symbolsInRange size > maxLabels
	 and: [significantSymbolsInRange size >= (maxLabels / 2)]) ifTrue:
		[symbolsInRange := significantSymbolsInRange].
	symbolsInRange do:
		[:s| counts at: s type put: (counts at: s type) + 1].
	"Find out what types give us at least one label but no more
	 than maxLabels unless necessary to have at least one."
	index := 1.
	count := counts at: (types at: index).
	[index <= types size
	 and: [count + (counts at: (types at: index)) < maxLabels]] whileTrue:
		[count := count + (counts at: (types at: index)).
		 index := index + 1].
	"add labels to positionedLabels indexed by their fractional position in the range, filtering by type."
	types := types copyFrom: 1 to: (index min: types size).
	positionedLabels := Dictionary new: count.
	range := (highAddress - lowAddress) asFloat.
	symbolsInRange do:
		[:s |
		(types includes: s type) ifTrue:
			[positionedLabels
				at: ([s address - lowAddress / range]
						on: ZeroDivide
						do: [:ex| 0])
				put: s displayText]].
	^positionedLabels
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

{ #category : #buttons }
VMProfiler >> profileColor [
	^self profiling ifTrue: [Color darkGray] ifFalse: [Color lightGreen]
]

{ #category : #profiling }
VMProfiler >> profileExpression [
	| expressionText logExpression block |
	expressionText := expressionTextMorph text.
	expressionText isEmpty ifTrue:
		[^self changed: #flash].
	(expressionText first = $[
	and: [expressionText last = $] ]) ifFalse:
		[expressionText := '[' asText, expressionText, ']' asText.
		 expressionTextMorph setText: expressionText].
	self changed: #selectionRange with: (1 to: expressionText size).
	logExpression := true.  "This could be a preference but for now allows both versions to live here."
	block := logExpression
				ifTrue: [expressionTextMorph doIt]
				ifFalse:
					[Compiler
						evaluate: expressionText
						for: nil
						notifying: (expressionTextMorph instVarNamed: 'textMorph') editor
						logged: false].
	block == expressionTextMorph ifTrue:
		[self error: expressionTextMorph class name, '>>doit does not answer the result'].
	block isBlock ifTrue:
		[self spyOn: block]
]

{ #category : #buttons }
VMProfiler >> profileExpressionButton [
	"Just weird!"
	^'profile:'
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

{ #category : #profiling }
VMProfiler >> profiling [
	^aboutToProfile or: [self statusOfVMProfile]
]

{ #category : #selecting }
VMProfiler >> progress [
	| range |
	range := history at: (historyIndex := historyIndex + 1).
	lowAddress := range first.
	highAddress := range last.
	self updateAddressDependents.
	self updateButtons.
	self selectSymbolsInRange.
	self plotGraph
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
		self putReportPreambleOn: s.
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

{ #category : #menus }
VMProfiler >> selectBenchmark: expressionString [ 
	expressionTextMorph setText: expressionString asText
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

{ #category : #profiling }
VMProfiler >> selectionRange [
	^expressionTextMorph
		ifNotNil: [1 to: expressionTextMorph text size]
		ifNil: [0 to: 0]
]

{ #category : #buttons }
VMProfiler >> showingLabels [
	^symbolTypes includes: #label
]

{ #category : #buttons }
VMProfiler >> showingModules [
	^symbolTypes includes: #module
]

{ #category : #buttons }
VMProfiler >> showingPrivateFunctions [
	^symbolTypes includes: #privateFunction
]

{ #category : #buttons }
VMProfiler >> showingPublicFunctions [
	^symbolTypes includes: #publicFunction
]

{ #category : #spying }
VMProfiler >> spyOn: aBlock [
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
	WorldState addDeferredUIMessage:
		[self plotGraph].
	^r
]

{ #category : #buttons }
VMProfiler >> startButton [
	"just weird..."
	^'start'
]

{ #category : #profiling }
VMProfiler >> startProfiling [
	"Use aboutToProfile to allow us to change the button colors without including the change in the profile."
	aboutToProfile := true.
	self clearHistory.
	self updateButtons.
	World doOneCycleNow.
	clearPriorToProfile ifTrue: [self clearProfile].
	gcPriorToProfile ifTrue: [Smalltalk garbageCollect].
	startStats := Smalltalk getVMParameters.
	startTime := Time millisecondClockValue.
	self startVMProfile.
	aboutToProfile := false
]

{ #category : #primitives }
VMProfiler >> startVMProfile [
	"Start profiling the virtual machine."
	self primitiveControlVMProfile: true size: self profileSize
]

{ #category : #primitives }
VMProfiler >> statusOfVMProfile [
	<primitive: 252>
	^self primitiveFailed
]

{ #category : #buttons }
VMProfiler >> stopButton [
	"just weird..."
	^'stop'
]

{ #category : #buttons }
VMProfiler >> stopColor [
	^self profiling ifTrue: [Color red] ifFalse: [Color darkGray]
]

{ #category : #profiling }
VMProfiler >> stopProfiling [
	| numSamples now vmParameters |
	numSamples := self stopVMProfile.
	now := Time millisecondClockValue.
	vmParameters := Smalltalk getVMParameters.
	cogCodeConstituents := self primitiveCollectCogCodeConstituents.
	elapsedTime := now - startTime + elapsedTime.
	self computeStats: vmParameters.
	self computeHistograms: numSamples.
	self computeCogCodeModule.
	self clearHistory.
	self updateButtons
]

{ #category : #primitives }
VMProfiler >> stopVMProfile [
	"Stop profiling the virtual machine."
	^self primitiveControlVMProfile: false size: self profileSize
]

{ #category : #accessing }
VMProfiler >> symHasLowResSamples: sym [
	^(sym address // lowResolution to: sym limit // lowResolution)
		anySatisfy:
			[:pc| (lowResSamples at: pc + 1) > 0]
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

{ #category : #menus }
VMProfiler >> symbolListMenu: aMenuMorph [
	aMenuMorph
		add: 'find...' target: self selector: #findSymbol:event: argument: nil;
		add: 'find module...' target: self selector: #findSymbol:event: argument: #module;
		add: 'find extern...' target: self selector: #findSymbol:event: argument: #publicFunction;
		add: 'find static...' target: self selector: #findSymbol:event: argument: #privateFunction;
		add: 'find label...' target: self selector: #findSymbol:event: argument: #label.
	sampleBuffer ifNotNil:
		[aMenuMorph
			addLine;
			add: 'vm report' target: self selector: #vmReport: argument: #justWeird;
			add: 'interpreter report' target: self selector: #interpreterReport: argument: #justWeird].
	^aMenuMorph
]

{ #category : #accessing }
VMProfiler >> symbolSelectionAt: index [ 
	^(selections at: index ifAbsent: [0]) ~= 0
]

{ #category : #accessing }
VMProfiler >> symbolSelectionAt: index put: aBoolean [
	Transcript cr; nextPutAll: #symbolSelectionAt:; space; print: index; nextPutAll: ' put: '; print: aBoolean; flush.
	minSelectionIndex := maxSelectionIndex := index.
	(index between: 1 and: selections size) ifTrue:
		[selections at: index put: (aBoolean ifTrue: [1] ifFalse: [0])].
	1 to: minSelectionIndex - 1 do:
		[:i| selections at: i put: 0].
	maxSelectionIndex + 1 to: selections size do:
		[:i| selections at: i put: 0].
	self changed: #symbolList.
	self updateAddressSelection
]

{ #category : #buttons }
VMProfiler >> toggleClearPriorToProfile [
	clearPriorToProfile := clearPriorToProfile not.
	self changed: #clearPriorToProfile
]

{ #category : #buttons }
VMProfiler >> toggleForkProfile [
	forkProfile := forkProfile not.
	self changed: #forkProfile
]

{ #category : #buttons }
VMProfiler >> toggleGcPriorToProfile [
	gcPriorToProfile := gcPriorToProfile not.
	self changed: #gcPriorToProfile
]

{ #category : #accessing }
VMProfiler >> toggleListIndex: index [
	Transcript cr; nextPutAll: #toggleListIndex:; space; print: index; flush.
	selections at: index put: ((selections at: index ifAbsent: [^self]) bitXor: 1).
	self updateAddressSelection
]

{ #category : #buttons }
VMProfiler >> toggleShowLabels [
	self toggleShowing: #label
]

{ #category : #buttons }
VMProfiler >> toggleShowModules [
	self toggleShowing: #module
]

{ #category : #buttons }
VMProfiler >> toggleShowPrivateFunctions [
	self toggleShowing: #privateFunction
]

{ #category : #buttons }
VMProfiler >> toggleShowPublicFunctions [
	self toggleShowing: #publicFunction
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

{ #category : #accessing }
VMProfiler >> totalText [
	^(String streamContents:
		[:s|
		total > 0 ifTrue:
			[s	print: (rangeTotal * 10000 / total) rounded / 100.0;
				nextPutAll: '% of';
				cr].
		s print: total]) asText
]

{ #category : #opening }
VMProfiler >> totalTextMorph: help get: getter [
	| ptm |
	ptm := PluggableTextMorph
			on: self
			text: getter accept: nil
			readSelection: nil menu: nil.
	ptm askBeforeDiscardingEdits: false;
		setBalloonText: help;
		retractableOrNot;
		hideOrShowScrollBars;
		setProperty: #noScrollBarPlease toValue: true;
		setProperty: #noVScrollBarPlease toValue: true.
	^ptm
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
		 and: [(samples := self highResSamplesFor: sym) > 0]) ifTrue:
			[vmTotals at: sym put: samples.
			 samplesInVM := samplesInVM + samples]].
	 (symbolManager symbolsInModule: symbolManager cogModule) do:
		[:sym| | samples |
		((#(publicFunction privateFunction) includes: sym type)
		 and: [(samples := self highResSamplesFor: sym) > 0]) ifTrue:
			[cogTotals at: sym put: samples.
			 samplesInCog := samplesInCog + samples]].
	 ((symbolManager modules
			copyWithout: symbolManager vmModule)
				copyWithout: symbolManager cogModule) do:
		[:module|
		(symbolManager symbolsInModule: module) do:
			[:sym| | samples |
			((#(publicFunction privateFunction) includes: sym type)
			and: [(self symHasLowResSamples: sym)
			and: [(samples := self highResSamplesFor: sym) > 0]]) ifTrue:
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

{ #category : #menus }
VMProfiler >> trimmedExpressionText [
	| expression |
	^((expression := expressionTextMorph text asString) notEmpty
	   and: [expression first = $[
	   and: [expression last = $] ]])
		ifTrue: [expression copyFrom: 2 to: expression size - 1]
		ifFalse: [expression]
]

{ #category : #accessing }
VMProfiler >> updateAddressDependents [
	self changed: #lowAddressText; changed: #highAddressText; changed: #symbolIndex.
	self dependents do:
		[:dep|
		 (dep class == PluggableTextMorph
		  and: [dep getTextSelector == #highAddressText]) ifTrue:
			[(dep instVarNamed: 'textMorph') editor setAlignment: #rightFlush]]
]

{ #category : #accessing }
VMProfiler >> updateAddressSelection [
	| min max |
	1 to: selections size do:
		[:i|
		(selections at: i) > 0 ifTrue:
			[min ifNil: [min :=i].
			 max := i]].
	min
		ifNil: [lowAddress := 0.
			   highAddress := highAddress := (1 << 32) - 1.
			   minSelectionIndex := maxSelectionIndex := 0]
		ifNotNil:
			[minSelectionIndex := min. maxSelectionIndex := max.
			 minSelectionIndex + 1 to: maxSelectionIndex - 1 do:
				[:i| selections at: i put: 1].
			 lowAddress := (symbolList at: minSelectionIndex) address.
			 highAddress := (symbolList at: maxSelectionIndex) limit].
	self updateAddressDependents
]

{ #category : #buttons }
VMProfiler >> updateButtons [
	WorldState addDeferredUIMessage:
		[self changed: #profileColor; changed: #clearColor; changed: #stopColor.
		 self changed: #profiling; changed: #notProfiling; changed: #notProfilingAndData.
		 self changed: #hasHistoryColor; changed: #hasFutureColor.
		 self changed: #hasHistory; changed: #hasFuture]
]

{ #category : #reports }
VMProfiler >> vmReport: justWeird [
	UIManager default
		edit: (String streamContents: [:s| self report: s])
		label: 'VM Functions by Cost'
]

{ #category : #reports }
VMProfiler >> widthInDefaultFontOf: aString [
	^(NewParagraph new
		compose: aString asText
		style: TextStyle default
		from: 1
		in: Display boundingBox;
		adjustRightX)
		extent x
]
