"
I represent a node in a VMProfiler profiling result tree.
This tree structure is used when inspecting the profiling result (AST-like)

listOfNodes : anOrderedCollection of (potentially) other VMProfilerResults node
name: aString representing the name of the node. Used to access the node
label : aString representing label displayed when inspecting the tree
"
Class {
	#name : #VMProfilerResult,
	#superclass : #Object,
	#instVars : [
		'listOfNodes',
		'name',
		'label'
	],
	#classInstVars : [
		'genData'
	],
	#category : #'CogTools-VMProfiler'
}

{ #category : #'as yet unclassified' }
VMProfilerResult class >> name: aNameString label: aLabelString [

	^ VMProfilerResult new 	
			name: aNameString;
			label: aLabelString;
			yourself. 
]

{ #category : #adding }
VMProfilerResult >> addNode: aNode [

	listOfNodes add: aNode.
]

{ #category : #accessing }
VMProfilerResult >> children [ 

	^ listOfNodes 
]

{ #category : #'as yet unclassified' }
VMProfilerResult >> gtInspectorTreeIn: composite [
    <gtInspectorPresentationOrder: 25> 
        
        composite tree
		rootsExpanded ;
		title: 'Report';
		display: [ self ];
		children: [ :each | each children ];
		selectionPopulate: #selectedNode
			on: $o
			entitled: 'Open'
			with: [ :tree | 'toto' ];
		format: [ :each | each printString].
]

{ #category : #initialization }
VMProfilerResult >> initialize [

	listOfNodes := OrderedCollection new.
]

{ #category : #accessing }
VMProfilerResult >> label: aString [

	label := aString 
]

{ #category : #accessing }
VMProfilerResult >> name: aString [

	name := aString.
]

{ #category : #printing }
VMProfilerResult >> printString [

	^ label
]
