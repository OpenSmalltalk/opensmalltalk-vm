Extension { #name : #InterpreterPlugin }

{ #category : #'*CMakeVMMaker' }
InterpreterPlugin classSide >> addExtraCMakeRules: maker [
	"Add extra rules/commands to cmake configuration for building this plugin.
	By default , do nothing"
]

{ #category : #'*CMakeVMMaker' }
InterpreterPlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [ 

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: nil
]

{ #category : #'*CMakeVMMaker' }
InterpreterPlugin classSide >> isSupportedPlatform: aPlatformDescriptor [

	^ (self supportedPlatforms: CPlatformDescriptor) includesPlatform: aPlatformDescriptor
]

{ #category : #'*CMakeVMMaker' }
InterpreterPlugin classSide >> supportedPlatforms: enum [
" use:
	^ enum unix
or:
	^ enum unix, enum osX
	
or 

	^ enum unix i386, enum osX
"
	^ enum all
]
