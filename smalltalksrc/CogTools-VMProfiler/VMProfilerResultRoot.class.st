"
I represent the root of the VMProfilerResult tree.

The different parts of the profiling report are stored as class variables.

compactions, events, gc... vanilla are accessor to the class variables. These class variables are meant to store VMProfilerResult objects.

examples :

VMProfilerResultRoot create 
--> instantiate a full tree profiling report with the default parts (Compactions Events Gc General Generated Memory Samples Vanilla). 

VMProfilerResultRoot name: aString label: aString 
--> instantiate a VMProfilerResultRoot.

myReportTree general addNode: (VMProfilerResult name: 'vmPath' label: aLabel)
--> add a new node in the general section, containing the path of the vm.
"
Class {
	#name : #VMProfilerResultRoot,
	#superclass : #VMProfilerResult,
	#classVars : [
		'Compactions',
		'Events',
		'Gc',
		'General',
		'Generated',
		'Memory',
		'Samples',
		'Vanilla'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #operations }
VMProfilerResultRoot class >> create [
	| root  |
	root := VMProfilerResultRoot name: 'root' label: 'Profiling report'.
	General := VMProfilerResult
		name: 'general'
		label: 'General information about the profiling'.
	Samples := VMProfilerResult
		name: 'samplesl'
		label: 'Number of samples'.
	Generated := VMProfilerResult
		name: 'generated'
		label: '% of generated vm code (% of total) (samples) (cumulative)'.
	Vanilla := VMProfilerResult
		name: 'vanilla'
		label: '% of vanilla vm code (% of total) (samples) (cumulative)'.
	Memory := VMProfilerResult name: 'memory' label: '**Memory**'.
	Gc := VMProfilerResult name: 'gc' label: '**GC**'.
	Compactions  := VMProfilerResult
		name: 'compac'
		label: '**Compiled Code Compactions**'.
	Events := VMProfilerResult name: 'events' label: '**Events**'.
	
	root addNode: General ;
		 addNode: Samples;
		 addNode: Generated ;
		 addNode: Vanilla ;	
		 addNode: Memory;
		 addNode: Gc;
		 addNode: Compactions ;
		 addNode: Events. 

	^ root
]

{ #category : #'as yet unclassified' }
VMProfilerResultRoot class >> name: aNameString label: aLabelString [

	^ VMProfilerResultRoot new 	
			name: aNameString;
			label: aLabelString;
			yourself. 
]

{ #category : #'as yet unclassified' }
VMProfilerResultRoot >> compactions [
	
	^ Compactions
]

{ #category : #accessing }
VMProfilerResultRoot >> events [

	^ Events 
]

{ #category : #'as yet unclassified' }
VMProfilerResultRoot >> gc [

	^ Gc
]

{ #category : #'as yet unclassified' }
VMProfilerResultRoot >> general [

	^ General 
]

{ #category : #'as yet unclassified' }
VMProfilerResultRoot >> generated [

	^ Generated 
]

{ #category : #'as yet unclassified' }
VMProfilerResultRoot >> memory [

	^ Memory 
]

{ #category : #'as yet unclassified' }
VMProfilerResultRoot >> samples [

	^ Samples
]

{ #category : #'as yet unclassified' }
VMProfilerResultRoot >> vanilla [

	^ Vanilla
]
