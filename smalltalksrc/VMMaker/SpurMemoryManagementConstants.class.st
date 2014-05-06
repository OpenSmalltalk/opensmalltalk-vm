Class {
	#name : #SpurMemoryManagementConstants,
	#superclass : #SharedPool,
	#classVars : [
		'DontTenure',
		'DontTenureButDoUnmark',
		'MarkOnTenure',
		'TenureByAge',
		'TenureByClass'
	],
	#category : #'VMMaker-SpurMemoryManager'
}
