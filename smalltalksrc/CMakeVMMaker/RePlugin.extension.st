Extension { #name : #RePlugin }

{ #category : #'*CMakeVMMaker' }
RePlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |
	maker addCrossSources: #(
		'pcre.c' 'study.c' 'get.c' 'chartables.c').

	].
		
]
