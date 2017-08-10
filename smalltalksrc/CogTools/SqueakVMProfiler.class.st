"
I am the VMProfiler called when using a Squeak image.

I can be used 
1) headful : for instance, either via WorldMenu>open>VMProfiler, or by typing : VMProfiler spyOn: [1 to: 10000000 do: [ :i | Object new ]].
2) headless : 
* for instance, inspect on : String streamContents: [ :s | VMProfiler headlessSpyOn: [ 1 to: 10000000 do: [ :i | Object new ] ] reportOn: s ]
* If you want to get a profiling report providing detailed data about the time spent in a function, inspect on : String streamContents: [ :s | VMProfiler headlessSpyOn: [ 1 to: 10000000 do: [ :i | Object new ] ] reportOn: s withDetails: true]. 

"
Class {
	#name : #SqueakVMProfiler,
	#superclass : #VMProfiler,
	#category : #'CogTools-VMProfiler'
}

{ #category : #reports }
SqueakVMProfiler class >> amOnSpur [
	^(Smalltalk vmParameterAt: 41) anyMask: 16
]

{ #category : #'instance creation' }
SqueakVMProfiler class >> default [
	^self openInstance
]

{ #category : #'as yet unclassified' }
SqueakVMProfiler class >> fixTabs [
	"Make sure the DefaultTabsArray and DefaultMarginTabsArray are adequately sized for modern displays."
	| defaultTab tempArray width |
	(Smalltalk bindingOf: #TextConstants) ifNil: [^self].
	width := 2000.
	(TextConstants at: #DefaultTabsArray) last < width ifTrue:
		[defaultTab := TextConstants at: #DefaultTab.
		 tempArray := Array new: 2000 // defaultTab.
		 1 to: tempArray size do:
			[:i | tempArray at: i put: defaultTab * i].
		 TextConstants at: #DefaultTabsArray put: tempArray.
		 tempArray := Array new: (width // defaultTab) // 2.
		 1 to: tempArray size do:
			[:i | tempArray at: i put: (Array with: (defaultTab*i) with: (defaultTab*i))].
		 TextConstants at: #DefaultMarginTabsArray put: tempArray]
]

{ #category : #'as yet unclassified' }
SqueakVMProfiler class >> initialize [

	super initialize.
	(TheWorldMenu respondsTo: #registerOpenCommand:) ifTrue:
		[TheWorldMenu registerOpenCommand: {'VM Profiler'. {self. #open}. 'A VM profiler'}].
	Preferences ifNotNil: [Preferences addBooleanPreference: #vmProfilerFillInIntegral 
									   category: #vmProfiler 
									   default: false
									   balloonHelp: 'If enabled, the profiler will fill in the area under the integral.'].
	('Squeak*' match: Smalltalk version) ifTrue: [self fixTabs] "ugly fix for configuration. temporary"
]

{ #category : #'instance creation' }
SqueakVMProfiler class >> open [
	^self new openInWindow
]

{ #category : #'instance creation' }
SqueakVMProfiler class >> openInstance [
	| window |
	window := World submorphs
					detect: [:sm| sm isSystemWindow and: [sm label = 'VMProfiler']]
					ifNone: [self open].
	^window model
]

{ #category : #spying }
SqueakVMProfiler class >> report: aStream [
	"Compatibility with MessageTally and AndreasSystemProfiler instance side spyOn: & report:"
	^self openInstance report: aStream
]

{ #category : #spying }
SqueakVMProfiler class >> spyOn: aBlock [
	"Compatibility with MessageTally and AndreasSystemProfiler instance side spyOn: & report:"
	^Cursor execute showWhile:
		[self openInstance spyOn: aBlock]
]

{ #category : #selecting }
SqueakVMProfiler >> addToHistory [
	historyIndex < history size ifTrue:
		[history := history copyFrom: 1 to: historyIndex].
	(history isEmpty or: [history last ~= (lowAddress to: highAddress)]) ifTrue:
		[history addLast: (lowAddress to: highAddress).
		 historyIndex := history size].

]

{ #category : #opening }
SqueakVMProfiler >> addressTextMorph: help get: getter set: setter [
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
SqueakVMProfiler >> backwardsButton [
	^ImageMorph new image: ((ScriptingSystem formAtKey: #playMPEG) flipBy: #horizontal centerAt: 0@0)
]

{ #category : #opening }
SqueakVMProfiler >> buttonMorph: getLabelMessage help: help set: setter enable: enabler color: colorGetter [
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
SqueakVMProfiler >> checkMorph: help get: getter set: setter [
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
SqueakVMProfiler >> clearButton [
	"just weird..."
	^'clear'
]

{ #category : #buttons }
SqueakVMProfiler >> clearColor [
	^Color lightBlue
]

{ #category : #buttons }
SqueakVMProfiler >> clearPriorToProfile [
	^clearPriorToProfile
]

{ #category : #'as yet unclassified' }
SqueakVMProfiler >> createParagraph [
	
	^NewParagraph new
]

{ #category : #buttons }
SqueakVMProfiler >> drawButton [
	"just weird..."
	^'plot'
]

{ #category : #menus }
SqueakVMProfiler >> expressionTextMenu: aMenuMorph [
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
SqueakVMProfiler >> findSymbol: typeOrNil event: event [
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
SqueakVMProfiler >> forkProfile [
	^forkProfile
]

{ #category : #opening }
SqueakVMProfiler >> forwardsButton [
	^ImageMorph new image: (ScriptingSystem formAtKey: #playMPEG)
]

{ #category : #'as yet unclassified' }
SqueakVMProfiler >> getVMParameters [

	^Smalltalk getVMParameters 
]

{ #category : #accessing }
SqueakVMProfiler >> graphMargin [
	^graph margin
]

{ #category : #selecting }
SqueakVMProfiler >> hasFuture [
	^historyIndex < history size
]

{ #category : #buttons }
SqueakVMProfiler >> hasFutureColor [
	^self hasFuture ifTrue: [Color transparent] ifFalse: [Color darkGray]
]

{ #category : #selecting }
SqueakVMProfiler >> hasHistory [
	^historyIndex >= 1
]

{ #category : #buttons }
SqueakVMProfiler >> hasHistoryColor [
	^self hasHistory ifTrue: [Color transparent] ifFalse: [Color darkGray]
]

{ #category : #accessing }
SqueakVMProfiler >> highAddressText [
	^((highAddress printStringRadix: 16) allButFirst: 3) asText
]

{ #category : #accessing }
SqueakVMProfiler >> highAddressText: aText [
	highAddress := ((Integer readFrom: aText asString asUppercase readStream base: 16) max: 0) min: self highestAddress.
	self selectSymbolsInRange
]

{ #category : #sorting }
SqueakVMProfiler >> highestAddress [
	^(sortedSamples isEmpty
		ifTrue: [symbolManager modules last limit]
		ifFalse: [symbolManager modules last limit max: sortedSamples last key]) asPowerOfTwo - 1
]

{ #category : #opening }
SqueakVMProfiler >> historyButtonMorph: getLabelMessage help: help set: setter enable: enabler color: colorGetter [
	| pbm |
	pbm := PluggableButtonMorphPlus on: self getState: nil action: setter label: getLabelMessage.
	pbm
		getEnabledSelector: enabler;
		setBalloonText: help;
		getColorSelector: colorGetter;
		offColor: Color transparent.
	^pbm
]

{ #category : #initialization }
SqueakVMProfiler >> initialize [
	self initializeMost.
	CompatibilityClass := SqueakVMMethodConverter new.
	super initializeSymbols.
	self toggleShowing: #module.
]

{ #category : #opening }
SqueakVMProfiler >> labelFont [
	"Answer the font in which to draw the graph labels.
	 N.B. the labelling morph shrinks this font by half when displaying."
	^(TextStyle named: 'BitstreamVeraSans') fontOfPointSize: 16
]

{ #category : #accessing }
SqueakVMProfiler >> lowAddressText [
	^((lowAddress printStringRadix: 16) allButFirst: 3) asText
]

{ #category : #accessing }
SqueakVMProfiler >> lowAddressText: aText [
	lowAddress := ((Integer readFrom: aText asString asUppercase readStream base: 16) max: 0) min: 16rFFFFFFFF.
	self selectSymbolsInRange
]

{ #category : #profiling }
SqueakVMProfiler >> notProfiling [
	^self profiling not
]

{ #category : #profiling }
SqueakVMProfiler >> notProfilingAndData [
	^sampleBuffer notNil and: [self notProfiling]
]

{ #category : #opening }
SqueakVMProfiler >> openInWindow [
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
SqueakVMProfiler >> plotGraph [
	sortedSamples isEmpty ifTrue: [^self].
	highAddress = 0 ifTrue:
		[highAddress := self highestAddress.
		 self updateAddressDependents].
	self plotSamplesFrom: lowAddress to: highAddress.
	graph fullDrawOn: Display getCanvas
]

{ #category : #graph }
SqueakVMProfiler >> plotSamplesFrom: startAddress to: endAddress [
	| histSeries intSeries integral range |
	graph clear.
	histSeries := graph series: #histogram.
	intSeries := graph alternateSeries: #integral.
	intSeries color: Color magenta; type: #stepped; drawArea: Preferences vmProfilerFillInIntegral.
	range := self plotSamplesFrom: startAddress to: endAddress intoHistogram: histSeries andIntegral: intSeries.
	histSeries addPoint: range last @ 0.
	intSeries addPoint: range last @ (integral := intSeries points isEmpty ifTrue: [0] ifFalse: [intSeries points last y]).
	(integral ~= 0 and: [Preferences vmProfilerFillInIntegral]) ifTrue:
		[intSeries addPoint: range last @ 0].
	self assert: histSeries points isEmpty = intSeries points isEmpty.
	histSeries points notEmpty ifTrue:
		[self assert: histSeries points first x = intSeries points first x.
		 self assert: histSeries points last x = intSeries points last x].
	rangeTotal := integral.
	graph xAxisFormatter:
		[:n|
		((range first + (n asFloat - range first)) rounded asInteger printStringRadix: 16) allButFirst: 3].
	graph yAxisFormatter:
		[:n|
		(n rounded = n
			ifTrue: [n]
			ifFalse:
				[n >= 100
					ifTrue: [n rounded]
					ifFalse: [(n * 10) rounded / 10]]) printString].
	graph limitMinX: range first limitMaxX: range last.
	self changed: #positionedLabels; changed: #totalText
]

{ #category : #graph }
SqueakVMProfiler >> plotSamplesFrom: startAddress to: endAddress intoHistogram: histogramSeries andIntegral: integralSeries [
	"Plot the samples in the range startAddress to: endAddress, inclusive.  Answer the range actually
	 plotted, which may be larger due to rounding when putting multiple addresses in the same bin."
	| resolution sampleIndex numSamples nextSample plotter |
	resolution := graph drawBounds width.
	numSamples := sortedSamples size.
	sampleIndex := sortedSamples findBinaryIndex: [:sample| startAddress - sample key] ifNone: [:lowIdx :highIdx| highIdx].
	sampleIndex > numSamples ifTrue:
		[^startAddress to: endAddress].
	plotter := VMGraphPlotter new histogram: histogramSeries integral: integralSeries startAddress: startAddress.
	nextSample := sortedSamples at: sampleIndex.
	endAddress - startAddress + 1 > (resolution * 1.5) ifTrue:
		[| binsPerPoint range sum |
		 binsPerPoint := (endAddress - startAddress + 1 / resolution) ceiling.
		 range := startAddress to: endAddress + binsPerPoint - 1 by: binsPerPoint.
		 range do:
			[:address| | next |
			 next := address + binsPerPoint.
			 sum := 0.
			 [nextSample key < next] whileTrue:
				[self assert: nextSample key >= address.
				 sum := sum + nextSample value.
				 (sampleIndex := sampleIndex + 1) > numSamples ifTrue:
					[plotter addPlotFor: sum at: address.
					 ^range].
				nextSample := sortedSamples at: sampleIndex].
			 plotter addPlotFor: sum at: address].
			 ^range].
		plotter plotAsBars: true.
	startAddress to: endAddress do:
		[:address|
		 nextSample key <= address
			ifTrue:
				[self assert: nextSample key >= address.
				 plotter addPlotFor: nextSample value at: address.
				 (sampleIndex := sampleIndex + 1) > numSamples ifTrue:
					[^startAddress to: endAddress].
				 nextSample := sortedSamples at: sampleIndex]
			ifFalse:
				[plotter addPlotFor: 0 at: address]].
	^startAddress to: endAddress
]

{ #category : #buttons }
SqueakVMProfiler >> profileColor [
	^self profiling ifTrue: [Color darkGray] ifFalse: [Color lightGreen]
]

{ #category : #profiling }
SqueakVMProfiler >> profileExpression [
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
SqueakVMProfiler >> profileExpressionButton [
	"Just weird!"
	^'profile:'
]

{ #category : #profiling }
SqueakVMProfiler >> profiling [
	^aboutToProfile or: [self statusOfVMProfile]
]

{ #category : #selecting }
SqueakVMProfiler >> progress [
	| range |
	range := history at: (historyIndex := historyIndex + 1).
	lowAddress := range first.
	highAddress := range last.
	self updateAddressDependents.
	self updateButtons.
	self selectSymbolsInRange.
	self plotGraph
]

{ #category : #'as yet unclassified' }
SqueakVMProfiler >> regress [
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

{ #category : #'as yet unclassified' }
SqueakVMProfiler >> selectProportionFrom: low to: high [
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

{ #category : #profiling }
SqueakVMProfiler >> selectionRange [
	^expressionTextMorph
		ifNotNil: [1 to: expressionTextMorph text size]
		ifNil: [0 to: 0]
]

{ #category : #buttons }
SqueakVMProfiler >> showingLabels [
	^symbolTypes includes: #label
]

{ #category : #buttons }
SqueakVMProfiler >> showingModules [
	^symbolTypes includes: #module
]

{ #category : #buttons }
SqueakVMProfiler >> showingPrivateFunctions [
	^symbolTypes includes: #privateFunction
]

{ #category : #buttons }
SqueakVMProfiler >> showingPublicFunctions [
	^symbolTypes includes: #publicFunction
]

{ #category : #spying }
SqueakVMProfiler >> spyOn: aBlock [
	
	| r |
	r := super spyOn: aBlock.
	WorldState addDeferredUIMessage: [self plotGraph].
	^ r
	
]

{ #category : #buttons }
SqueakVMProfiler >> startButton [
	"just weird..."
	^'start'
]

{ #category : #primitives }
SqueakVMProfiler >> statusOfVMProfile [
	<primitive: 252>
	^self primitiveFailed
]

{ #category : #buttons }
SqueakVMProfiler >> stopButton [
	"just weird..."
	^'stop'
]

{ #category : #buttons }
SqueakVMProfiler >> stopColor [
	^self profiling ifTrue: [Color red] ifFalse: [Color darkGray]
]

{ #category : #profiling }
SqueakVMProfiler >> stopProfiling [
	
	super stopProfiling.
	self updateButtons
]

{ #category : #menus }
SqueakVMProfiler >> symbolListMenu: aMenuMorph [
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
SqueakVMProfiler >> symbolSelectionAt: index put: aBoolean [
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
SqueakVMProfiler >> toggleClearPriorToProfile [
	clearPriorToProfile := clearPriorToProfile not.
	self changed: #clearPriorToProfile
]

{ #category : #buttons }
SqueakVMProfiler >> toggleForkProfile [
	forkProfile := forkProfile not.
	self changed: #forkProfile
]

{ #category : #buttons }
SqueakVMProfiler >> toggleGcPriorToProfile [
	gcPriorToProfile := gcPriorToProfile not.
	self changed: #gcPriorToProfile
]

{ #category : #accessing }
SqueakVMProfiler >> toggleListIndex: index [
	Transcript cr; nextPutAll: #toggleListIndex:; space; print: index; flush.
	selections at: index put: ((selections at: index ifAbsent: [^self]) bitXor: 1).
	self updateAddressSelection
]

{ #category : #buttons }
SqueakVMProfiler >> toggleShowLabels [
	self toggleShowing: #label
]

{ #category : #buttons }
SqueakVMProfiler >> toggleShowModules [
	self toggleShowing: #module
]

{ #category : #buttons }
SqueakVMProfiler >> toggleShowPrivateFunctions [
	self toggleShowing: #privateFunction
]

{ #category : #buttons }
SqueakVMProfiler >> toggleShowPublicFunctions [
	self toggleShowing: #publicFunction
]

{ #category : #accessing }
SqueakVMProfiler >> totalText [
	^(String streamContents:
		[:s|
		total > 0 ifTrue:
			[s	print: (rangeTotal * 10000 / total) rounded / 100.0;
				nextPutAll: '% of';
				cr].
		s print: total]) asText
]

{ #category : #opening }
SqueakVMProfiler >> totalTextMorph: help get: getter [
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

{ #category : #accessing }
SqueakVMProfiler >> updateAddressDependents [
	self changed: #lowAddressText; changed: #highAddressText; changed: #symbolIndex.
	self dependents do:
		[:dep|
		 (dep class == PluggableTextMorph
		  and: [dep getTextSelector == #highAddressText]) ifTrue:
			[(dep instVarNamed: 'textMorph') editor setAlignment: #rightFlush]]
]

{ #category : #accessing }
SqueakVMProfiler >> updateAddressSelection [
	| min max |
	1 to: selections size do:
		[:i|
		(selections at: i) > 0 ifTrue:
			[min ifNil: [min :=i].
			 max := i]].
	min
		ifNil: [lowAddress := 0.
			   highAddress := self highestAddress.
			   minSelectionIndex := maxSelectionIndex := 0]
		ifNotNil:
			[minSelectionIndex := min. maxSelectionIndex := max.
			 minSelectionIndex + 1 to: maxSelectionIndex - 1 do:
				[:i| selections at: i put: 1].
			 lowAddress := (symbolList at: minSelectionIndex) address.
			 highAddress := (symbolList at: maxSelectionIndex) limit].
	self updateAddressDependents
]
