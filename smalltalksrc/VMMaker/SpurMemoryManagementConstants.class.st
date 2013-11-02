Class {
	#name : #SpurMemoryManagementConstants,
	#superclass : #SharedPool,
	#classVars : [
		'DontTenureButDoUnmark',
		'TenureByAge',
		'TenureByClass'
	],
	#category : #'VMMaker-SpurMemoryManager'
}
