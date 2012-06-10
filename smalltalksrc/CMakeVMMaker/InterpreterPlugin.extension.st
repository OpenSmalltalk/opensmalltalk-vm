Extension { #name : #InterpreterPlugin }

{ #category : #'*CMakeVMMaker' }
InterpreterPlugin classSide >> addExtraCMakeRules: maker [
	"Add extra rules/commands to cmake configuration for building this plugin.
	By default , do nothing"
]

{ #category : #'*CMakeVMMaker' }
InterpreterPlugin classSide >> browseSettings [

	^ CPlatformConfig browsePluginRules: self
]

{ #category : #'*CMakeVMMaker' }
InterpreterPlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [ 

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: nil
]
