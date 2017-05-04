Class {
	#name : #SpurMemoryManagementConstants,
	#superclass : #SharedPool,
	#classVars : [
		'DontTenure',
		'MarkOnTenure',
		'MaxRTRefCount',
		'ScavengeInProgress',
		'SlidingCompactionInProgress',
		'TenureByAge',
		'TenureByClass',
		'TenureToShrinkRT'
	],
	#category : 'VMMaker-SpurMemoryManager'
}
