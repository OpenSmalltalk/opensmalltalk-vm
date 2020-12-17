Class {
	#name : #VMMakerConfiguration,
	#superclass : #Object,
	#classVars : [
		'DirNames'
	],
	#category : #'VMMaker-Slang'
}

{ #category : #accessing }
VMMakerConfiguration class >> baseClass [

	^ VMClass
]

{ #category : #accessing }
VMMakerConfiguration class >> baseCogitClass [

	^ Cogit
]

{ #category : #accessing }
VMMakerConfiguration class >> baseInterpreterClass [

	^ InterpreterPrimitives
]

{ #category : #accessing }
VMMakerConfiguration class >> baseObjectMemoryManagerClass [

	^ SpurMemoryManager
]

{ #category : #accessing }
VMMakerConfiguration class >> baseStructClass [
	
	^ VMStructType
]

{ #category : #accessing }
VMMakerConfiguration class >> bytesPerOop [
	
	^ self baseClass bytesPerOop
]

{ #category : #accessing }
VMMakerConfiguration class >> bytesPerWord [
	
	^ self baseClass bytesPerWord
]

{ #category : #accessing }
VMMakerConfiguration class >> constantClass [
	"The basic constant pool for full generation"
	^ self baseClass constantClass
]

{ #category : #accessing }
VMMakerConfiguration class >> coreVMDirName [
	^DirNames at: #coreVMDir
]

{ #category : #accessing }
VMMakerConfiguration class >> coreVMHeadersDirName [

	^ DirNames at: #coreVMHeadersDir ifAbsent: [ self coreVMDirName ]
]

{ #category : #accessing }
VMMakerConfiguration class >> defaultInterpreterClass [

	^ StackInterpreter
]

{ #category : #configurations }
VMMakerConfiguration class >> generateAllNewspeakConfigurationsUnderVersionControl [
	self
		executeDisplayingProgress:
			(OrderedDictionary
				with: 'Generate newspeak spur stack 32bits' -> [ self generateNewspeakSpurStackVM ]
				with: 'Generate newspeak spur stack 64bits' -> [ self generateNewspeakSpurStack64VM ]
				with: 'Generate newspeak spur cog 32bits' -> [ self generateNewspeakSpurCogVM ]
				with: 'Generate newspeak spur cog 64bits' -> [ self generateNewspeakSpurCog64VM ])
]

{ #category : #configurations }
VMMakerConfiguration class >> generateAllSistaConfigurationsUnderVersionControl [
	self
		executeDisplayingProgress:
			(OrderedDictionary 
				with: 'Generate squeak spur cog sista 32bits' -> [ self generateSqueakSpurCogSistaVM ]
				with: 'Generate squeak spur cog sista 64bits' -> [ self generateSqueakSpurCogSista64VM ])
]

{ #category : #configurations }
VMMakerConfiguration class >> generateConfiguration [
	"VMMaker generateConfiguration"
	| configCategoryName selectors |
	configCategoryName := self class whichCategoryIncludesSelector: thisContext selector.
	selectors := Set new.
	self class organization categories do:
		[:cat|
		(cat endsWith: configCategoryName) ifTrue:
			[selectors addAll: (self class organization listAtCategoryNamed: cat)]].
	selectors remove: thisContext selector.
	selectors := selectors asArray sort.
	(UIManager default
			chooseFrom: (selectors collect: [:sel| self configurationNameFromSelector: sel])
			values: selectors) ifNotNil:
		[:choice|
		self perform: choice]
]

{ #category : #configurations }
VMMakerConfiguration class >> generateSqueakSpurCog64MTVM [
	"No primitives since we can use those for the Cog VM"
	^VMMaker
		generate: CoInterpreterMT
		and: StackToRegisterMappingCogit
		with: #(COGMTVM true
				ObjectMemory Spur64BitCoMemoryManager
				MULTIPLEBYTECODESETS true
				bytecodeTableInitializer initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid)
		to: self sourceTree, '/spur64src'
		platformDir: self sourceTree, '/platforms'
		including:#()
		configuration: self
]

{ #category : #configurations }
VMMakerConfiguration class >> generateSqueakSpurCog64VM [
	"No primitives since we can use those for the Cog VM"
	^VMMaker
		generate: CoInterpreter
		and: StackToRegisterMappingCogit
		with: #(ObjectMemory Spur64BitCoMemoryManager
				MULTIPLEBYTECODESETS true
				bytecodeTableInitializer initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid)
		to: self sourceTree, '/spur64src'
		platformDir: self sourceTree, '/platforms'
		including:#()
			configuration: self
]

{ #category : #configurations }
VMMakerConfiguration class >> generateSqueakSpurCogMTVM [
	"No primitives since we can use those for the Cog VM"
	^VMMaker
		generate: CoInterpreterMT
		and: StackToRegisterMappingCogit
		with: #(COGMTVM true
				ObjectMemory Spur32BitCoMemoryManager
				MULTIPLEBYTECODESETS true
				bytecodeTableInitializer initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid)
		to: self sourceTree, '/spursrc'
		platformDir: self sourceTree, '/platforms'
		including:#()
		configuration: self
]

{ #category : #configurations }
VMMakerConfiguration class >> generateSqueakSpurCogSista64VM [
	^VMMaker
		generate: CoInterpreter
		and: SistaCogit
		with: #(	SistaVM true
				ObjectMemory Spur64BitCoMemoryManager
				MULTIPLEBYTECODESETS true
				bytecodeTableInitializer initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid)
		to: self sourceTree, '/spursista64src'
		platformDir: self sourceTree, '/platforms'
		including:#()
		configuration: self
]

{ #category : #configurations }
VMMakerConfiguration class >> generateSqueakSpurCogSistaVM [
	"No primitives since we can use those for the Cog VM"
	^VMMaker
		generate: CoInterpreter
		and: SistaCogit
		with: #(	SistaVM true
				ObjectMemory Spur32BitCoMemoryManager
				MULTIPLEBYTECODESETS true
				bytecodeTableInitializer initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid)
		to: self sourceTree, '/spursistasrc'
		platformDir: self sourceTree, '/platforms'
		including:#()
		configuration: self
]

{ #category : #configurations }
VMMakerConfiguration class >> generateSqueakSpurCogVM [
	"No primitives since we can use those for the Cog VM"
	^VMMaker
		generate: CoInterpreter
		and: StackToRegisterMappingCogit
		with: #(ObjectMemory Spur32BitCoMemoryManager
				MULTIPLEBYTECODESETS true
				bytecodeTableInitializer initializeBytecodeTableForSqueakV3PlusClosuresSistaV1Hybrid)
		to: self sourceTree, '/spursrc'
		platformDir: self sourceTree, '/platforms'
		including:#()
		configuration: self
]

{ #category : #configurations }
VMMakerConfiguration class >> generateSqueakSpurRegisterCogVM [
	"No primitives since we can use those for the Cog VM"
	^VMMaker
		generate: CoInterpreter
		and: RegisterAllocatingCogit
		with: #(ObjectMemory Spur32BitCoMemoryManager)
		to: self sourceTree, '/spurregsrc'
		platformDir: self sourceTree, '/platforms'
		including:#()
		configuration: self
]

{ #category : #initialisation }
VMMakerConfiguration class >> initialize [
	"VMMaker initialize"
	DirNames := Dictionary new.
	DirNames
		at: #coreVMDir put: 'vm';
		at: #platformsDir put: 'platforms';
		at: #pluginsDir put: 'plugins';
		at: #sourceDir put: 'src'.

	"Try and decide where the Cog source tree is.  Two configurations are likely.
	 One is that the VMMaker image is running in the image directory in the
	 source tree and hence everything will be at '..'.
	 Another is where the source tree is at the same level as the VMMaker image,
	 in which case it is likely called oscogvm or Cog."
	#('../platforms' 'oscogvm/platforms' 'Cog/platforms' '../oscogvm/platforms')
		with: #('..' 'oscogvm' 'Cog' '../oscogvm')
		do: ((Smalltalk classNamed: #FileSystem)
				ifNotNil:
					[[:dir :path|
					  (FileLocator cwd / dir) isDirectory ifTrue:
						[DirNames at: #sourceTree put: path.
						 ^self]]]
				ifNil:
					[[:dir :path|
					  dir asFileReference exists 
						ifTrue: [DirNames at: #sourceTree put: path. ^self]]])
]

{ #category : #initialisation }
VMMakerConfiguration class >> initializeForPharo [
	"VMMaker initialize"
	DirNames := Dictionary new.
	DirNames
		at: #coreVMDir put: 'vm/src';
		at: #coreVMHeadersDir put: 'vm/include';
		at: #platformsDir put: 'platforms';
		at: #pluginsDir put: 'plugins/src';
		at: #sourceDir put: 'src'
]

{ #category : #initialize }
VMMakerConfiguration class >> initializeForPlugins: options [ 
	
	VMClass initializeForPlugins: options 
]

{ #category : #accessing }
VMMakerConfiguration class >> interpreterPluginClass [

	^ InterpreterPlugin
]

{ #category : #accessing }
VMMakerConfiguration class >> interpreterProxyClass [

	^ InterpreterProxy
]

{ #category : #accessing }
VMMakerConfiguration class >> platformsDirName [
	^DirNames at: #platformsDir
]

{ #category : #accessing }
VMMakerConfiguration class >> pluginsDirName [
	^DirNames at: #pluginsDir
]

{ #category : #accessing }
VMMakerConfiguration class >> referenceObjectMemoryClass [
	"Define the class from which to take methods to define the interpreter proxy imports."
	^ Spur32BitMemoryManager
]

{ #category : #accessing }
VMMakerConfiguration class >> sourceDirName [
	^DirNames at: #sourceDir
]

{ #category : #accessing }
VMMakerConfiguration class >> sourceTree [
	^DirNames at: #sourceTree ifAbsent: [ FileSystem workingDirectory pathString ]
]

{ #category : #accessing }
VMMakerConfiguration class >> unusedConstantNames [
	"Don't generate any defines for the externally defined constants,
	 STACKVM, COGVM, COGMTVM et al, unless they're actually used."
	^ (VMClass class>>#initializeMiscConstants) literals
		select: [ :lit | lit isVariableBinding and: [lit key isString]]
		thenCollect: [ :lit | lit key]
]
