"
I am the VMProfiler called when using a Pharo image.

I can be used 
1) headful : for instance, by typing : VMProfiler spyOn: [1 to: 10000000 do: [ :i | Object new ]].
2) headless : for instance, inspect on : String streamContents: [ :s | VMProfiler headlessSpyOn: [ 1 to: 10000000 do: [ :i | Object new ] ] reportOn: s ]

If you want to get a bytecode level profiling report, providing detailed data about the time spent in a function, inspect on : String streamContents: [ :s | VMProfiler headlessSpyOn: [ 1 to: 10000000 do: [ :i | Object new ] ] reportOn: s withDetails: true]. This detailed report is available by default in the headful version.


"
Class {
	#name : #PharoVMProfiler,
	#superclass : #VMProfiler,
	#instVars : [
		'reportTree',
		'result'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #reports }
PharoVMProfiler class >> amOnSpur [
	^(Smalltalk vm parameterAt: 41) anyMask: 16.
]

{ #category : #accessing }
PharoVMProfiler class >> default [
	"will do something when a UI will be added for Pharo"
	^self new. 
]

{ #category : #spying }
PharoVMProfiler class >> spyOn: aBlock [

	"^self headlessSpyOn: aBlock reportOn: '' writeStream  withDetails:true. "

	^ self new
			selectBenchmark: (CompatibilityClass convertAsString: aBlock);
			withDetails: true;
			reportTree: VMProfilerResultRoot create;
			headlessSpyOn: aBlock;
			fillResults;
			fillReportTree;  
			yourself.
	

]

{ #category : #'as yet unclassified' }
PharoVMProfiler >> createParagraph [
	
	^Paragraph new
]

{ #category : #'ui elements' }
PharoVMProfiler >> fillAnalysisPartOfReportTreePart: aPart for: samplesAssoc and: samplesTotals [ 
"fill the reportTree for either the generated vm code or the vanilla vm code part. samplesAssoc refers to the Dictionary associating a VMPSymbol and its number of samples, samplesTotals refers to the total number of samples you want to compute the percentage from"

	| generated substantial label cumulated node name |
	generated := self filterSamples: samplesAssoc.
	substantial := generated at: 1.
	cumulated := 0.
	substantial do: [ :func | 
						cumulated := cumulated + func value.
						name := func key isString ifTrue: [ func key ] ifFalse: [func key name].
						label := String streamContents: [:s | 
									self printPercentage: (func value) total:  samplesTotals on: s.
									s nextPutAll: ' ('.
									self printPercentage: (func value) total:  total on: s.
									s nextPutAll: ') ',name,' (',func value asString,') ('.
									self printPercentage: cumulated total:  samplesTotals on: s.
									s nextPutAll: ')'].
						aPart addNode: (func key isString ifTrue: [VMProfilerResult name: name label: label] ifFalse: [(node := VMProfilerResultCM name: name label: label content: func key cm)]) .
						
						(result at: 'cogMethodMaps') at: func key ifPresent: 
									[node addNode: (VMProfilerResult name: func key name label: (String streamContents: [ :s | self printInnerDetails: func with: (result at: 'cogMethodMaps') on: s ])).]]
						" ]."
	
]

{ #category : #'ui elements' }
PharoVMProfiler >> fillCompactionPartOfReportTree [

	| labelCompaction |
	labelCompaction := String streamContents: [ :s | 
			s nextPutAll: (result at: 'numCompactions') asString; 
			   nextPutAll: ' totalling ';
			   nextPutAll: (result at: 'compactionMsecs') asStringWithCommas; 
			   nextPutAll: 'ms (';
			   nextPutAll: (CompatibilityClass print: (result at: 'compactionMsecs') / elapsedTime * 100 showingDecimalPlaces: 3);
			nextPutAll: '% elapsed time)'.
	(result at: 'numCompactions') = 0 ifFalse:
			[s nextPutAll: ', avg '; 
			   nextPutAll: (CompatibilityClass print: (result at: 'compactionMsecs') / (result at: 'numCompactions') showingDecimalPlaces:3); 
			   nextPutAll: 'ms']].
	
	reportTree compactions addNode: (VMProfilerResult name: 'compactions' label: labelCompaction)
	

	
]

{ #category : #'ui elements' }
PharoVMProfiler >> fillEventPartOfReportTree [

#('Process switches' 'ioProcessEvents calls' 'Interrupt checks' 'Event checks' 'Stack overflows' 'Stack page divorces') do: 
	[ :e | reportTree events addNode: (VMProfilerResult name: e label: (e, ' ', (result at: e) asString, ' (', ((((result at: e) * 1000) / elapsedTime) rounded) asString, ' per second)'))]
]

{ #category : #'ui elements' }
PharoVMProfiler >> fillGCPartOfReportTree [

	| labelGC labelScavenges labelTenures |
	labelGC := String streamContents: [ :s | s nextPutAll: 'full ', (result at: 'fullGCs') asString, ' totalling ', (result at: 'fullGCTime') asStringWithCommas, 'ms (';
											    nextPutAll: (CompatibilityClass print:( (result at: 'fullGCTime') / elapsedTime * 100) showingDecimalPlaces: 3 );
											    nextPutAll:  '% elapsed time)'.
											(result at: 'fullGCs') = 0 ifFalse: [ s nextPutAll: ', avg '; nextPutAll: (CompatibilityClass print:((result at: 'fullGCTime') / (result at: 'fullGCs')) showingDecimalPlaces: 3); nextPutAll: 'ms' ]].
										
	labelScavenges := String streamContents: [ :s | s nextPutAll: (self class amOnSpur ifTrue: ['scavenges '] ifFalse: ['incr	 ']);
													    print: (result at: 'incrGCs');
													    nextPutAll: ' totalling ';
													    nextPutAll: (result at: 'incrGCTime') asStringWithCommas;
													    nextPutAll: 'ms (';
													   nextPutAll: (CompatibilityClass print: (result at: 'incrGCTime') / elapsedTime  * 100 showingDecimalPlaces: 3);
													   nextPutAll: '% elapsed time)'.
													(result at: 'incrGCs') = 0 ifFalse:
													[s nextPutAll:', avg '; 
													   nextPutAll: (CompatibilityClass print: (result at: 'incrGCTime') / (result  at: 'incrGCs') showingDecimalPlaces:3); 
													   nextPutAll: 'ms']].
												
	labelTenures := String streamContents: [ :s |  s nextPutAll: 'tenures ';
													nextPutAll: (result at: 'tenureCount') asStringWithCommas.
												   (result at: 'tenureCount') = 0 ifFalse:
												 [s nextPutAll: ' (avg '; 
													print: ((result at: 'incrGCs') / (result at: 'tenureCount')) asInteger; 
													nextPutAll: ' GCs/tenure)']].
	
	reportTree gc addNode: (VMProfilerResult name: 'fullGC' label: labelGC);
				     addNode:  (VMProfilerResult name: 'scavenges' label: labelScavenges);
				     addNode: (VMProfilerResult name: 'tenures' label: labelTenures);
				    addNode: (VMProfilerResult name: 'rootTable' label: 'root table ', (result at: 'rootOverflows') asStringWithCommas, ' overflows' ).

]

{ #category : #'ui elements' }
PharoVMProfiler >> fillGeneralPartOfReportTree [

	reportTree general addNode: (VMProfilerResult name: 'vmPath' label: (result at: 'vmPath'));
			   			addNode: (VMProfilerResult name: 'date' label: (result at: 'date'));
						addNode: (VMProfilerResult name: 'time' label: (result at: 'time'));
						addNode: (VMProfilerResult name: 'edenSize' label: 'eden size: ' , (result at: 'edenSize') asStringWithCommas);
						addNode:(VMProfilerResult name: 'stackPages' label: 'stack pages: ' , (result at: 'stackPages') asString);
						addNode: (VMProfilerResult name: 'codeSize' label: 'code size: ' , (result at: 'codeSize') asStringWithCommas);
						addNode: (VMProfilerResult name: 'profiledBlock' label: (result at: 'profiledBlock'));
						addNode: (VMProfilerResult name: 'elapsedTime' label: (elapsedTime / 1000.0) asString , ' seconds');
						addNode: (VMProfilerResult name: 'frequency' label: 'sampling frequency: ' , (total * 1000 / elapsedTime) rounded asString, ' hz').
]

{ #category : #'ui elements' }
PharoVMProfiler >> fillMemoryPartOfReportTree [

	reportTree memory addNode: (VMProfilerResult name: 'oldSpaceEnd' label: 'old ',(result at: 'oldSpaceEnd') asStringWithCommasSigned , ' bytes').
	self class amOnSpur 
		ifTrue: [ reportTree memory addNode: (VMProfilerResult name: 'freeSpace' label: 'free ', (result at: 'freeSpace') asStringWithCommasSigned , ' bytes')]
		 ifFalse: 
			[reportTree memory addNode: (VMProfilerResult name: 'youngSpace' label: 'young ', ((result at: 'youngSpaceEnd') - (result at: 'oldSpaceEnd'))  asStringWithCommasSigned , ' bytes');
								addNode: (VMProfilerResult name: 'usedSpace' label: 'used ', (result at: 'youngSpaceEnd') asStringWithCommasSigned , ' bytes');
								addNode: (VMProfilerResult name: 'freeSpace' label: 'free ', ((result at: 'memoryEnd') - (result at: 'youngSpaceEnd')) asStringWithCommasSigned , ' bytes') ].
	
	
]

{ #category : #'ui elements' }
PharoVMProfiler >> fillReportTree [

	self fillGeneralPartOfReportTree.
	self fillSamplesPartOfReportTree.  
	self fillAnalysisPartOfReportTreePart: reportTree generated for: (result at: 'cogTotals') and: (result at: 'samplesInCog').
	self fillAnalysisPartOfReportTreePart: reportTree vanilla for: (result at: 'vmTotals') and: (result at: 'samplesInVM'). 
	self fillMemoryPartOfReportTree.
	self fillGCPartOfReportTree.
	self fillCompactionPartOfReportTree.
	self fillEventPartOfReportTree. 
]

{ #category : #results }
PharoVMProfiler >> fillResults [

	self getDataFromPreambleInResult.
	self getSamplesNumberInResult.  
	self getGCStatsInResult: elapsedStats
]

{ #category : #'ui elements' }
PharoVMProfiler >> fillSamplesPartOfReportTree [

	reportTree samples addNode: (VMProfilerResult name: 'vmSamples' label: ((result at: 'samplesInVM') + (result at: 'samplesInCog')) asString, ' samples in the VM' );
						  addNode: (VMProfilerResult name: 'totalSamples' 
													   label: total asString, ' samples in the entire program, ', 
															(String streamContents: [ :s | self printPercentage: (result at: 'samplesInEntireVM') total: total on: s]), '% of total');
						addNode: (VMProfilerResult name: 'coglSamples' 
													   label: (result at: 'samplesInCog') asString, ' samples in generated vm code, ', 
															(String streamContents: [ :s | self printPercentage: (result at: 'samplesInCog') total: (result at: 'samplesInEntireVM') on: s]), '% of entire vm (', (String streamContents: [ :s | self printPercentage: (result at: 'samplesInCog') total: total on: s]), '% of total)');
						addNode: (VMProfilerResult name: 'vanillaSamples' label: (result at: 'samplesInVM') asString, ' samples in vanilla vm code, ', (String streamContents: [ :s | self printPercentage: (result at: 'samplesInVM') total: (result at: 'samplesInEntireVM') on: s]), '% of entire vm (', (String streamContents: [ :s | self printPercentage: (result at: 'samplesInVM') total: total on: s]), '% of total)').

]

{ #category : #results }
PharoVMProfiler >> getDataFromPreambleInResult [

	result at: 'vmPath' put: (SmalltalkImage current getSystemAttribute: 0).
	result at: 'date' put: Date today yyyymmdd.
	result at: 'time' put: Time now print24.
	(startStats size >= 44 
		and: [(startStats at: 44) isNumber]) ifTrue: [ result at: 'edenSize' put: (startStats at: 44).
												 	 result at: 'stackPages' put: (startStats at: 42)].
	(startStats size >= 46
		and: [(startStats at: 46) isNumber
		and: [(startStats at: 46) > 0]]) ifTrue: [ result at: 'codeSize' put: (startStats at: 46) ].
	self trimmedExpressionText notEmpty ifTrue: [ result at: 'profiledBlock' put: self trimmedExpressionText ].

]

{ #category : #results }
PharoVMProfiler >> getGCStatsInResult: gcStatsArray [

	gcStatsArray ifNil: [^self class].
	
	result at: 'oldSpaceEnd' put: (gcStatsArray at: 2); "a.k.a. oldSpace size on Spur"
		    at: 'fullGCs' put: (gcStatsArray at: 7);
		    at: 'fullGCTime' put: (gcStatsArray at: 8);
		    at: 'incrGCs' put: (gcStatsArray at: 9);
		    at: 'incrGCTime' put: (gcStatsArray at: 10);
		    at: 'tenureCount' put: (gcStatsArray at: 11);
		    at: 'rootOverflows' put: (gcStatsArray at: 22).
		
	self class amOnSpur
		ifTrue: [(gcStatsArray at: 54) 
						ifNotNil: [:freeSpace| result at: 'freeSpace' put: freeSpace]]				 
		ifFalse:
			[result at: 'youngSpaceEnd'	 put:  (gcStatsArray at: 1).
			 result at: 'memoryEnd' put:  (gcStatsArray at: 3)].
		
	(gcStatsArray size >= 63 and: [(gcStatsArray at: 63) isInteger]) ifTrue:
		[result at: 'numCompactions' put: (gcStatsArray at: 62).
		result at: 'compactionMsecs' put: (gcStatsArray at: 63)].
	
	gcStatsArray size >= 61 ifTrue:
		[(56 to: 61)
			with: #('Process switches' 'ioProcessEvents calls' 'Interrupt checks' 'Event checks' 'Stack overflows' 'Stack page divorces')
			do: [:index :eventName| | value |
				value := gcStatsArray at: index.
				result at: eventName put: value]]
]

{ #category : #results }
PharoVMProfiler >> getSamplesNumberInResult [

	result at: 'vmTotals' put: Dictionary new;
		    at: 'cogTotals' put:  Dictionary new;
		    at: 'nonVMTotals' put: Dictionary new;
		    at: 'cogMethodMaps' put:  Dictionary new;
		    at: 'samplesInVM' put: (self countSymbols: (symbolManager symbolsInModule: symbolManager vmModule) totals: (result at: 'vmTotals'));
		    at: 'samplesInCog' put: (self countSymbols: (symbolManager symbolsInModule: symbolManager cogModule) totals: (result at: 'cogTotals'));
		    at: 'samplesInEntireVM' put: ((result at: 'samplesInVM') + (result at: 'samplesInCog'));
   		    at: 'samplesInNonVMModules' put: (self countSymbols: self symbolsInNonVMModule totals:  (result at: 'nonVMTotals'));
		    at: 'samplesInNonVM' put: total - (result at: 'samplesInVM') - (result at: 'samplesInCog').
	(result at: 'cogTotals') keysAndValuesDo: 
		[ :key :value |
		value > 10 ifTrue: [ (result at: 'cogMethodMaps') at: key put: (self createMcpcBcpcMapFor: key) ] ].
	(result at: 'nonVMTotals')
		at: 'Samples Not In Any Function'
		put: (result at: 'samplesInNonVM') - (result at: 'samplesInNonVMModules').
	
]

{ #category : #'as yet unclassified' }
PharoVMProfiler >> getVMParameters [

	^Smalltalk vm getParameters 
]

{ #category : #'ui elements' }
PharoVMProfiler >> gtInspectorTreeIn: composite [
 <gtInspectorPresentationOrder: 1> 

	^ reportTree gtInspectorTreeIn: composite
]

{ #category : #initialization }
PharoVMProfiler >> initialize [

	self initializeMost.
	reportTree := VMProfilerResultRoot create.
	result := Dictionary new.
	CompatibilityClass := PharoVMMethodConverter new.
	self initializeSymbols.
]

{ #category : #accessing }
PharoVMProfiler >> reportTree: aVMProfilerResult [

	reportTree := aVMProfilerResult 
]
