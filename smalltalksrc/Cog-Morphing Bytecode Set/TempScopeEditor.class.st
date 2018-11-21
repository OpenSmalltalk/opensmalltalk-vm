Class {
	#name : #TempScopeEditor,
	#superclass : #Object,
	#instVars : [
		'method',
		'methodNode',
		'out',
		'tempMap',
		'blockNodes',
		'sourceString',
		'soFar'
	],
	#category : #'Cog-Scripts'
}

{ #category : #'as yet unclassified' }
TempScopeEditor class >> edit [
	"Trawl the system for methods containing misdeclared temps and correct these methods."
	SystemNavigation default allSelect:
		[:m| | scanner |
		(m isQuick not
		and: [(scanner := InstructionStream on: m) scanFor:
				[:b| b = 143 and: [scanner followingByte >= 16]]]) ifTrue:
			[(self new forMethod: m) edit].
		false]
]

{ #category : #editing }
TempScopeEditor >> anyScopes: referenceScopeDict outsideExtent: blockExtent [
	^referenceScopeDict notNil
	   and: [referenceScopeDict notEmpty
	   and: [referenceScopeDict anySatisfy:
			[:set|
			set anySatisfy: [:location| (blockExtent rangeIncludes: location) not]]]]
]

{ #category : #editing }
TempScopeEditor >> blockNode: aBlockNode isEnclosingScopeFor: aTempVariableNode [ 
	^((self
		anyScopes: (aTempVariableNode instVarNamed: 'readingScopes')
		outsideExtent: aBlockNode blockExtent)
	or: [self
		anyScopes: (aTempVariableNode instVarNamed: 'writingScopes')
		outsideExtent: aBlockNode blockExtent]) not
]

{ #category : #editing }
TempScopeEditor >> buildTempMap [
	"Build the map for moving remote temps. Each remote temp
	 that should be moved is entered into the map referencing its
	 smallest enclosing scope.  This may seem backwards but it
	 means that the map is one-to-one, not one-to-many."
	| readBeforeWritten |
	readBeforeWritten := (methodNode accept: ReadBeforeWrittenVisitor new) readBeforeWritten.
	blockNodes do:
		[:blockNode|
		(blockNode temporaries notEmpty
		 and: [blockNode temporaries last isIndirectTempVector]) ifTrue:
			[blockNode temporaries last remoteTemps do:
				[:remoteTemp| | enclosingScopes smallestEnclosingBlockScope |
				 (readBeforeWritten includes: remoteTemp) ifFalse:
				 	[enclosingScopes := blockNodes select: [:blockScope|
															self blockNode: blockScope
																isEnclosingScopeFor: remoteTemp].
					 enclosingScopes notEmpty ifTrue:
						[smallestEnclosingBlockScope := enclosingScopes last.
						 smallestEnclosingBlockScope ~~ blockNode ifTrue:
							 [tempMap at: remoteTemp put: smallestEnclosingBlockScope]]]]]]
]

{ #category : #editing }
TempScopeEditor >> copyMethodMovingTemps [
	| methodBodyStart tempsToKeep tempsStart tempsEnd |
	methodBodyStart := method methodClass parserClass new
							parseMethodComment: sourceString setPattern: [:ignored|];
							startOfNextToken.
	tempsStart := sourceString indexOf: $| startingAt: methodBodyStart.
	tempsEnd := sourceString indexOf: $| startingAt: tempsStart + 1.
	(tempsToKeep := self tempsToKeepAtMethodLevel) isEmpty
		ifTrue:
			[| startOfFirstBlock |
			 startOfFirstBlock := (methodNode encoder sourceRangeFor: blockNodes second closureCreationNode) first.
			 tempsStart < startOfFirstBlock
				ifTrue:
					 [out next: tempsStart - 1 putAll: sourceString.
					  soFar := tempsEnd + 1]
				ifFalse:
					[soFar := 1]]
		ifFalse:
			[out next: tempsStart putAll: sourceString.
			 tempsToKeep do: [:t| out space; nextPutAll: t name].
			 soFar := tempsEnd.
			 (sourceString at: soFar - 1) isSeparator ifTrue:
				[soFar := soFar - 1]].
	blockNodes allButFirst do:
		[:blockNode|
		self processBlockNode: blockNode].
	out next: sourceString size - soFar + 1 putAll: sourceString startingAt: soFar
]

{ #category : #editing }
TempScopeEditor >> edit [
	self buildTempMap.
	tempMap notEmpty ifTrue:
		[| mr |
		 mr := method methodReference.
		 self copyMethodMovingTemps.
		 Transcript cr; show: mr actualClass name, ' >> ', mr methodSymbol.
		 method methodClass compile: out contents classified: mr category]
]

{ #category : #editing }
TempScopeEditor >> editNoCompile [
	self buildTempMap.
	^tempMap isEmpty ifFalse:
		[self copyMethodMovingTemps.
		 out contents]
]

{ #category : #'initialize-release' }
TempScopeEditor >> forMethod: aCompiledMethod [
	method := aCompiledMethod.
	sourceString := aCompiledMethod getSourceFromFile asString.
	methodNode := method methodClass parserClass new
						parse: sourceString
						class: method methodClass.
	methodNode ensureClosureAnalysisDone.
	blockNodes := (methodNode accept: BlockNodeCollectingVisitor new)
						blockNodes reject: [:bn| bn optimized].
	out := (String new: sourceString size) writeStream.
	tempMap := IdentityDictionary new


	"(TempScopeEditor new forMethod: SARInstaller class>>#ensurePackageWithId:) edit"
]

{ #category : #editing }
TempScopeEditor >> processBlockNode: blockNode [
	| tempsToMoveHere startOfBlock endOfArgs maybeBlockTempsStart blockTempsInSource |
	tempsToMoveHere := (tempMap select: [:aBlockNode| aBlockNode == blockNode]) keys.
	tempsToMoveHere isEmpty ifTrue: [^self].
	startOfBlock := (methodNode encoder sourceRangeFor: blockNode closureCreationNode) first.
	endOfArgs := blockNode arguments isEmpty
					ifTrue: [startOfBlock]
					ifFalse: [sourceString indexOf: $| startingAt: startOfBlock].
	out next: endOfArgs - soFar + 1 putAll: sourceString startingAt: soFar.
	maybeBlockTempsStart := sourceString indexOf: $| startingAt: endOfArgs + 1 ifAbsent: sourceString size + 1.
	blockTempsInSource := (sourceString copyFrom: endOfArgs + 1 to: maybeBlockTempsStart - 1) allSatisfy:
								[:c| c isSeparator].
	blockTempsInSource
		ifTrue:
			[out next: maybeBlockTempsStart - endOfArgs putAll: sourceString startingAt: endOfArgs + 1.
			 (self tempsToKeepFor: blockNode) do:
				[:tempNode| out space; nextPutAll: tempNode name].
			 tempsToMoveHere do: [:t| out space; nextPutAll: t name].
			 soFar := sourceString indexOf: $| startingAt: maybeBlockTempsStart + 1.
			 (sourceString at: soFar - 1) isSeparator ifTrue:
				[soFar := soFar - 1]]
		ifFalse:
			[out space; nextPut: $|.
			 tempsToMoveHere do: [:t| out space; nextPutAll: t name].
			 out space; nextPut: $|.
			 soFar := endOfArgs + 1]
]

{ #category : #editing }
TempScopeEditor >> tempsToKeepAtMethodLevel [
	^(self tempsToKeepFor: blockNodes first) select:
		[:t|t scope >= 0]
]

{ #category : #editing }
TempScopeEditor >> tempsToKeepFor: blockNode [
	| tempsToKeep |
	tempsToKeep := OrderedCollection new.
	blockNode temporaries do:
		[:t|
		t isIndirectTempVector
			ifTrue:
				[t remoteTemps do:
					[:rt|
					(tempMap includesKey: rt) ifFalse:
						[tempsToKeep addLast: rt]]]
			ifFalse:
				[tempsToKeep addLast: t]].
	^tempsToKeep
]
