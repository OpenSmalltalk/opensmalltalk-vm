Extension { #name : #SpurMemoryManager }

{ #category : #'*VMMaker-Tools' }
SpurMemoryManager >> gtInspectorFreeListIn: composite [
	<gtInspectorPresentationOrder: 0>
	^ composite fastTreeTable
		title: 'Free Lists';
		when: [ self freeLists notNil ];
		hasChildren: [ :aNode | aNode hasChildren ];
		children: [ :aNode | aNode children ];
		display: [ :anObject | (VMTFreeLists on: self) children ];
		column: 'Label' evaluated: [ :aNode | aNode printString ];
		column: 'Size' evaluated: [ :aNode | aNode size ]	
]

{ #category : #'*VMMaker-Tools' }
SpurMemoryManager >> gtInspectorHiddenRootsIn: composite [
	<gtInspectorPresentationOrder: 0>
	^ composite fastTable
		title: 'HiddenRoots';
		when: [ self hiddenRootsObject notNil ];
		display: [ :anObject | (VMTHiddenRootTable on: self) children ];
		column: 'Index' evaluated: [ :hiddenRoot | hiddenRoot index ];
		column: 'Label' evaluated: [ :hiddenRoot | hiddenRoot label ];
		column: 'Address' evaluated: [ :hiddenRoot | hiddenRoot oop ].
]
