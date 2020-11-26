Extension { #name : #VMMaker }

{ #category : #'*Melchor' }
VMMaker >> createCogitCodeGenerator [
	^MLVMCCodeGenerator new
		vmMaker: self;
		logger: logger;
		options: optionsDictionary;
		yourself
]
