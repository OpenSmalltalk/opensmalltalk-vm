Class {
	#name : #SpurMemoryManagementConstants,
	#superclass : #SharedPool,
	#classVars : [
		'DontTenure',
		'MarkOnTenure',
		'MaxRTRefCount',
		'TenureByAge',
		'TenureByClass',
		'TenureToShrinkRT'
	],
	#category : #'VMMaker-SpurMemoryManager'
}
