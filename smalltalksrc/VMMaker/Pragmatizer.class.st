"
Pragmatizer is a utility for converting message send directives (such as 'self inline: true') to their corresponding pragma implementations (<inline: true>) in method source.

The #depragmatize method provides a means for reverting to message send directives. This may be useful in the event of needing to load VMMaker into an image that does not support pragmas.

This is based on an original script provided by Eliot Miranda.
"
Class {
	#name : #Pragmatizer,
	#superclass : #Object,
	#instVars : [
		'package',
		'selectors',
		'classes',
		'stampCutString',
		'stampInsertString'
	],
	#category : #'VMMaker-Translation to C'
}

{ #category : #examples }
Pragmatizer class >> convertVMMakerAndPluginsToPragmas [
	"Create (unused) packages named 'VMMaker-Interpreter', 'VMMaker-Plugins',
	and 'VMMaker-SmartSyntaxPlugins'. Open a transcript, then evaluate this method.
	Some errors will be found during the conversion. Fix the problem methods
	manually in the notifier dialog, and proceed. The issues are related to declarations
	that are not the first lines of source in the method, so just move the declarations
	to the top of the method to resolve."
	
	"Pragmatizer convertVMMakerAndPluginsToPragmas"

	| selectorsToConvert packages converter |
	selectorsToConvert := #(#export: #static: #inline: #returnTypeC: #var:declareC: #var:type: ).
	packages := { 'VMMaker-Interpreter' . 'VMMaker-Plugins' . 'VMMaker-SmartSyntaxPlugins' }.
	packages do: [:package |
		converter := Pragmatizer on: package selectors: selectorsToConvert.
		converter pragmatize]
]

{ #category : #'instance creation' }
Pragmatizer class >> on: packageName selectors: selectorList [
	"Pragmatizer on: 'VMMaker-Interpreter' selectors: #(#export: #static: #inline: #returnTypeC: #var:declareC: #var:type: )"
	"Pragmatizer on: 'VMMaker-Plugins' selectors: #(#export: #static: #inline: #returnTypeC: #var:declareC: #var:type: )"
	"Pragmatizer on: 'VMMaker-SmartSyntaxPlugins' selectors: #(#export: #static: #inline: #returnTypeC: #var:declareC: #var:type: )"

	^ self new package: packageName selectors: selectorList
]

{ #category : #examples }
Pragmatizer class >> revertVMMakerAndPluginsToMessageSendDeclarations [
	"To revert back to the message send declarations. "
	
	"Pragmatizer revertVMMakerAndPluginsToMessageSendDeclarations"

	| selectorsToConvert packages converter substringToRemoveFromMethodStamp |

	"Optional - Edit the following to match substring to be removed from the method
	stamps to return them to their original form prior to conversion to pragmas:
	Note leading space in the string."
	substringToRemoveFromMethodStamp := ' (auto pragmas dtl 2010-09-26)'.

	selectorsToConvert := #(#export: #static: #inline: #returnTypeC: #var:declareC: #var:type: ).
	packages := { 'VMMaker-Interpreter' . 'VMMaker-Plugins' . 'VMMaker-SmartSyntaxPlugins' }.
	packages do: [:package |
		converter := Pragmatizer on: package selectors: selectorsToConvert.
		converter stampCutString: substringToRemoveFromMethodStamp.
		converter stampInsertString: ''.
		converter depragmatize]
]

{ #category : #accessing }
Pragmatizer >> classes: listOfClasses [
	"If set, only the classes in this list will be modified. The classes are assumed to be
	classes in the package. This is intended to allow specifying one or more plugins
	in VMMaker-Plugins to be converted individually."

	classes := listOfClasses
]

{ #category : #'convert pragmas to sends' }
Pragmatizer >> depragmatize [
	"Convert methods from pragmas to old style message send directives, retaining
	original author initials and time stamps. Answer the methods that were modified."

	| instanceMethods |
	"Only instance side methods are translated, so ignore class side methods in the package"
	instanceMethods := package methods
				reject: [:e | e classIsMeta
						or: [self isExcludedClass: e]].
	^ instanceMethods
		reject: [:mr | self depragmatize: mr]
]

{ #category : #'convert pragmas to sends' }
Pragmatizer >> depragmatize: methodReference [
	"Depragmatize the method. Answer true if the method was not modified, and false
	if conversion was performed."

	| method newSource newStamp pragmas stamp |
	pragmas := OrderedCollection new.
	method := methodReference compiledMethod.
	method properties keysAndValuesDo: [:sel :p |
		(selectors includes: sel)
			ifTrue: [pragmas add: p]].
	pragmas isEmpty ifTrue: [^ true].
	newSource := pragmas
		inject: method getSourceFromFile asString
		into: [:src : pragma |
				src copyReplaceAll: pragma asString
					with: 'self ', pragma asString allButFirst allButLast, '.'].
		stamp := method timeStamp.
		newStamp := self newConvertToMessageSendStamp: stamp.
	Transcript
		print: method methodClass;
		nextPutAll: '>>';
		print: method selector;
		nextPut: Character space;
		nextPutAll: newStamp;
		cr; flush.
	method methodClass
		compile: newSource
		classified: methodReference category
		withStamp: newStamp
		notifying: nil.
	^false

]

{ #category : #testing }
Pragmatizer >> isExcludedClass: aMethodReference [

	classes notNil
		and: [classes
				detect: [:cls | cls name = aMethodReference classSymbol]
				ifNone: [^ true]].
	^ false
]

{ #category : #'method stamp' }
Pragmatizer >> newConvertToMessageSendStamp: oldStamp [
	"Insert a comment in a method stamp to indicate that conversion from pragmas to old
	style message sends was done. If stampCutString has been set, remove this substring
	from the oldStamp prior to adding a new substring. If stampInsertString was set, use
	this as the substring to insert. Otherwise add a substring with current date and author
	initials." 

	| newStamp |
	stampCutString
		ifNil: [newStamp := oldStamp]
		ifNotNil: [newStamp := oldStamp copyReplaceAll: stampCutString with: ''].
	stampInsertString
		ifNil: [newStamp := newStamp
						copyReplaceFrom: (oldStamp indexOf: Character space) + 1
						to: (oldStamp indexOf: Character space)
						with: '(remove pragmas ', Utilities authorInitials, ' ', Date today yyyymmdd, ') ']
		ifNotNil: [newStamp := newStamp
						copyReplaceFrom: (oldStamp indexOf: Character space) + 1
						to: (oldStamp indexOf: Character space)
						with: stampInsertString].
	^ newStamp

]

{ #category : #'method stamp' }
Pragmatizer >> newConvertToPragmaStamp: oldStamp [
	"Insert a comment in a method stamp to indicate that conversion to pragmas was done.
	If stampCutString has been set, remove this substring from the oldStamp prior to adding
	a new substring. If stampInsertString was set, use this as the substring to insert. Otherwise
	add a substring with current date and author initials." 

	| newStamp |
	stampCutString
		ifNil: [newStamp := oldStamp]
		ifNotNil: [newStamp := oldStamp copyReplaceAll: stampCutString with: ''].
	stampInsertString
		ifNil: [newStamp := newStamp
						copyReplaceFrom: (oldStamp indexOf: Character space) + 1
						to: (oldStamp indexOf: Character space)
						with: '(auto pragmas ', Utilities authorInitials, ' ', Date today yyyymmdd, ') ']
		ifNotNil: [newStamp := newStamp
						copyReplaceFrom: (oldStamp indexOf: Character space) + 1
						to: (oldStamp indexOf: Character space)
						with: stampInsertString].
	^ newStamp

]

{ #category : #'convert sends to pragmas' }
Pragmatizer >> newPragmatizedSourceFrom: source nodes: pragmaNodes nodeRanges: ranges [

	^ String streamContents: [:str|
		str nextPutAll: (source copyFrom: 1 to: ranges first - 6).
		pragmaNodes
			do: [:node| | pragma args |
				str nextPut: $<.
				str nextPutAll: (node asString allButFirst: 6) allButLast.
				str nextPut: $>]
			separatedBy: [str crtab: 1].
		str nextPutAll: (source copyFrom: ((ranges last + 1 <= source size
										   and: [(source at: ranges last + 1) = $.])
											ifTrue: [ranges last + 2]
											ifFalse: [ranges last + 1])
							to: source size)]

]

{ #category : #'initialize-release' }
Pragmatizer >> package: packageName selectors: selectorList [

	package := RPackageOrganizer default
		packageNamed: packageName
		ifAbsent: [self error: 'package ', packageName, ' not found'].
	selectors := selectorList
]

{ #category : #'convert sends to pragmas' }
Pragmatizer >> pragmatize [
	"Convert methods to use pragmas, retaining original author initials and time stamps.
	Answer the methods that were modified."

	| instanceMethods |
	"Only instance side methods are translated, so ignore class side methods in the package"
	instanceMethods := package methods
				reject: [:e | e classIsMeta
						or: [self isExcludedClass: e]].
	^ instanceMethods
		reject: [:mr | self pragmatize: mr]
]

{ #category : #'convert sends to pragmas' }
Pragmatizer >> pragmatize: methodReference [
	"Pragmatize the method. Answer true if the method was not modified, and false
	if conversion was performed."

	| method methodNode pragmaNodes sourceRanges ranges source newSource stamp newStamp |
	method := methodReference compiledMethod.
	methodNode := method methodNode.
	pragmaNodes := SortedCollection
						sortBlock: [:a :b | (sourceRanges at: a) first <= (sourceRanges at: b) first].
	(sourceRanges := methodNode rawSourceRanges)
		keysAndValuesDo: [:node :range | (node isMessageNode
					and: [selectors includes: node selector key])
				ifTrue: [pragmaNodes add: node]].
	^ pragmaNodes isEmpty
		ifFalse: [ranges := (sourceRanges at: pragmaNodes first) first
								to: (sourceRanges at: pragmaNodes last) last.

				source := method getSourceFromFile asString.
				"methodBodyStart := method methodClass parserClass new
										parseMethodComment: source setPattern: [:ignored|];
										startOfNextToken.
				tempsStart := source indexOf: $| startingAt: methodBodyStart.
				hasTemps := tempsStart > 0 and: [tempsStart < ranges first]."
				(source copyFrom: ranges first - 5 to: ranges first - 1) ~= 'self ' ifTrue: [self halt].
				(ranges last < source size
					and: [(source indexOf: $. startingAt: ranges last) > (ranges last + 1)]) ifTrue: [self halt].
				newSource := self newPragmatizedSourceFrom: source
							nodes: pragmaNodes
							nodeRanges: ranges.
				stamp := method timeStamp.
				newStamp := self newConvertToPragmaStamp: stamp.
				Transcript
					print: method methodClass;
					nextPutAll: '>>';
					print: method selector;
					nextPut: Character space;
					nextPutAll: newStamp;
					cr; flush.
				method methodClass
					compile: newSource
					classified: methodReference category
					withStamp: newStamp
					notifying: nil.
				false]

]

{ #category : #accessing }
Pragmatizer >> stampCutString: stringToRemoveFromMethodStamp [
	"If set, this substring will be removed from method stamps during conversion. This is
	intended to enable conversion to and from pragmas without repeated extension of the
	method stamp."

	stampCutString := stringToRemoveFromMethodStamp
]

{ #category : #accessing }
Pragmatizer >> stampInsertString: commentToInsert [
	"If set, the commentToInsert will be used for method stamp modification
	rather than the default conversion value. This is intended to permit a
	Pragmatizer to reproduce a previous conversion, e.g. the previously converted
	methods in the Cog VM."

	stampInsertString := commentToInsert

]
