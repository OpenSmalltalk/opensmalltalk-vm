"
A SpurBootstrapMonticelloPackagePatcher is used to construct a new set of patched Monticello packages for Spur.  The use case is some bootstrap process loads a set of Monticello packages.  To repeat the bootstrap with a Spur image the bootstrap must use suitably patched Monticello packages containing the new method versions on the class side of SpurBootstrap.

Instance Variables
	destDir:			<FileDirectory>
	sourceDir:		<FileDirectory>

destDir
	- directory to which patched packages are to be written

sourceDir
	- directory from which packages to be patched are to be read
"
Class {
	#name : #SpurBootstrapMonticelloPackagePatcher,
	#superclass : #Object,
	#instVars : [
		'sourceDir',
		'destDir',
		'packagesAndPatches',
		'imageTypes'
	],
	#category : #'Cog-Bootstrapping'
}

{ #category : #baselines }
SpurBootstrapMonticelloPackagePatcher class >> squeak45baseline [
	"The base Squeak-4.5-13680 package set."
	^#(	name 'base-Squeak45-eem'
		repository ('http://source.squeak.org/squeak45')
		dependency ('Squeak-Version' 'Squeak-Version-ar.4662' '6bfece28-65a4-b147-9462-417b2e86acd0')
		dependency ('311Deprecated' '311Deprecated-nice.2' '6df45c33-740a-fc4f-b3d0-45412ad7d284')
		dependency ('39Deprecated' '39Deprecated-ar.19' '8da20c38-7d28-3241-9f29-da261d6f9bfe')
		dependency ('45Deprecated' '45Deprecated-fbs.24' '4033c169-94c6-7741-9aee-5a7570a7ec7a')
		dependency ('Balloon' 'Balloon-nice.24' '97e2ed51-707d-4da1-ab4f-35add3deee5e')
		dependency ('Network' 'Network-nice.150' 'c844e5ea-c919-44fc-905e-69487b035947')
		dependency ('Compression' 'Compression-fbs.40' '82b0d6e4-0239-1241-968c-461a785fb6a7')
		dependency ('Graphics' 'Graphics-nice.289' 'e809bcbf-53e1-420b-846a-9e86e0dd1f06')
		dependency ('Multilingual' 'Multilingual-fbs.194' '07f4a7b5-7169-3345-85fc-5a8ba04e5323')
		dependency ('CollectionsTests' 'CollectionsTests-dtl.214' 'cf157d3a-2d71-46f3-86ce-450ee24e8d27')
		dependency ('PackageInfo-Base' 'PackageInfo-Base-nice.68' 'b6669527-9a35-4783-a64f-8f2af97e330b')
		dependency ('Compiler' 'Compiler-nice.279' '94b1b5f8-f71b-4425-b035-461d3dc94e3f')
		dependency ('Environments' 'Environments-ul.46' 'cfd9e7f7-6a4b-400e-b9c7-9c6239da4752')
		dependency ('Kernel' 'Kernel-dtl.836' '410e695f-7f23-43e4-9dc2-d292b9954f0d')
		dependency ('MonticelloConfigurations' 'MonticelloConfigurations-fbs.123' 'b9735d10-7cf4-a746-8a64-b50fa9cf273f')
		dependency ('Tools' 'Tools-cmm.519' 'dae6bdb9-8b54-491a-a2a4-0b114f02e10d')
		dependency ('MorphicExtras' 'MorphicExtras-tpr.147' 'e76a71a5-6be9-4420-b71a-2c92d900c476')
		dependency ('Files' 'Files-dtl.130' '8ee82071-69f7-446d-8ed7-77eafc838f03')
		dependency ('System' 'System-dtl.666' '098b856a-ecc5-498a-bceb-ef3457d3511e')
		dependency ('Collections' 'Collections-ul.564' '4b9a37ef-df86-40a0-a0dd-8e8b2c04d4ed')
		dependency ('Monticello' 'Monticello-cmm.586' 'a4dbd656-e50a-47ba-8661-44f8c87bb3e0')
		dependency ('EToys' 'EToys-cmm.117' 'c3e71dbe-17af-4b71-ad9c-c0bb2a2bc193')
		dependency ('Exceptions' 'Exceptions-cmm.49' '6cede9fe-b13d-481a-b8de-bb004ece1145')
		dependency ('FlexibleVocabularies' 'FlexibleVocabularies-bf.13' '55c72a72-619e-4a81-831f-303600bbd792')
		dependency ('GraphicsTests' 'GraphicsTests-fbs.38' '081189cc-a44f-fa4e-965e-25438280ea93')
		dependency ('Installer-Core' 'Installer-Core-cmm.392' '7cb5c040-6f68-479d-bc9e-0b264b172443')
		dependency ('KernelTests' 'KernelTests-nice.259' '0f7301b0-612c-49d8-936f-775995b35e0f')
		dependency ('GetText' 'GetText-nice.34' '4d432f8e-55be-428a-9138-63dd1738035e')
		dependency ('Sound' 'Sound-nice.38' 'b626daf0-be23-4fb8-b2d5-04b9cd370539')
		dependency ('ToolBuilder-Tests' 'ToolBuilder-Tests-cmm.1' 'e77685b9-ca09-40c0-b84e-6caee75f4075')
		dependency ('Morphic' 'Morphic-cmm.720' 'e5e81c18-990b-4e35-b325-adb032b8418d')
		dependency ('MorphicTests' 'MorphicTests-nice.24' 'e33a9ad3-2f39-4c19-a3a7-dc87f18177fc')
		dependency ('MorphicExtrasTests' 'MorphicExtrasTests-fbs.3' '1c039763-bc92-834c-943e-d96d8820cbd7')
		dependency ('MultilingualTests' 'MultilingualTests-fbs.18' '07e26018-8455-3349-9b44-9ecb4aaeefb2')
		dependency ('Nebraska' 'Nebraska-nice.36' 'cc80dca4-ed72-4c39-952c-3b37886100de')
		dependency ('NetworkTests' 'NetworkTests-fbs.37' '97699685-5826-fe47-af98-356971abf2fb')
		dependency ('PreferenceBrowser' 'PreferenceBrowser-fbs.49' '72d30dfa-0ff5-4347-9823-eb77ae236f8f')
		dependency ('Protocols' 'Protocols-nice.46' '15b63671-d541-4c1d-9ff5-72da4fc5bfe9')
		dependency ('SMBase' 'SMBase-nice.132' 'a70c8bd2-3eee-4e21-b9c6-113f6b194527')
		dependency ('SMLoader' 'SMLoader-fbs.79' '9f7d983e-d958-4115-94aa-21302f89ad8b')
		dependency ('ST80' 'ST80-cmm.172' '47b2f84a-6951-480b-88f2-b2726dba08bd')
		dependency ('ST80Tests' 'ST80Tests-nice.2' '7ee5426b-73f1-48ac-8ec4-3943dc452cb6')
		dependency ('ST80Tools' 'ST80Tools-fbs.1' '108ec7bc-d1f5-dd4b-9511-e7a653a71e9f')
		dependency ('SUnit' 'SUnit-fbs.99' 'a5be81dd-6e9f-8d41-a091-3c6c27a28abe')
		dependency ('SUnitGUI' 'SUnitGUI-fbs.59' '0bfcf308-0d02-a749-9930-6229492cca48')
		dependency ('ScriptLoader' 'ScriptLoader-cmm.338' 'adb79117-0915-40a5-a5ee-c766e4b50d42')
		dependency ('Services-Base' 'Services-Base-topa.51' '94328e86-1643-4090-8f18-bc4467119161')
		dependency ('SmallLand-ColorTheme' 'SmallLand-ColorTheme-fbs.6' 'a78b81e3-3b11-c24e-9c84-3bb5319e0858')
		dependency ('SystemChangeNotification-Tests' 'SystemChangeNotification-Tests-nice.23' '3eed6d26-4aef-4095-a604-d9f914240281')
		dependency ('Tests' 'Tests-cmm.290' 'f3fccfae-6baf-4093-ba62-e15ef110a687')
		dependency ('ToolBuilder-Kernel' 'ToolBuilder-Kernel-nice.60' '86949a07-725b-4a27-a7cd-a827c74f48be')
		dependency ('ToolBuilder-MVC' 'ToolBuilder-MVC-fbs.34' 'aded987d-5cd5-6f41-9635-1d38da947ddf')
		dependency ('ToolBuilder-Morphic' 'ToolBuilder-Morphic-fbs.91' 'abaa076b-af43-af42-8c98-7a71482c6a30')
		dependency ('ToolBuilder-SUnit' 'ToolBuilder-SUnit-fbs.19' '3e30756c-2af8-0741-836f-0d42a9d5af32')
		dependency ('ToolsTests' 'ToolsTests-cmm.68' '98c1608a-6cb3-4a03-a28a-dd101e6c876b')
		dependency ('MonticelloForTraits' 'MonticelloForTraits-fbs.1' '160be615-5ab7-4148-a7cb-60dd629ab085')
		dependency ('Traits' 'Traits-topa.302' '58712f55-3f3f-467e-ac0e-e118c9737c53')
		dependency ('TraitsTests' 'TraitsTests-fbs.13' '0429146f-6767-4a4f-8fce-37571625920a')
		dependency ('TrueType' 'TrueType-nice.28' '42a74f04-e193-455b-a2c1-14ec51724234')
		dependency ('Universes' 'Universes-nice.46' '805eb73f-391b-4e3f-aef9-64add79e4e8c')
		dependency ('VersionNumber' 'VersionNumber-cmm.4' '68fb1f05-d3e2-4c9b-9234-20a9bed166dc')
		dependency ('XML-Parser' 'XML-Parser-fbs.36' 'a2d9791a-c341-564b-9b57-a0fe9f42b66f')
		dependency ('ReleaseBuilder' 'ReleaseBuilder-cmm.114' 'ea773780-69e1-48dd-a16c-e167acb9de04')
		dependency ('ShoutCore' 'ShoutCore-cwp.40' '81b3e230-2e8a-42c5-9521-e54338fadb6f')
		dependency ('VersionNumberTests' 'VersionNumberTests-fbs.4' '953a944c-9648-dd4b-898e-9e10e0507b91')
		dependency ('HelpSystem-Core' 'HelpSystem-Core-ul.56' '6d8a0d54-5f60-da45-8c3c-d42ea8abd999')
		dependency ('HelpSystem-Tests' 'HelpSystem-Tests-fbs.15' '8927a848-29a0-f54c-8c79-efb8070c4702')
		dependency ('Help-Squeak-Project' 'Help-Squeak-Project-kfr.10' 'b86eb622-cc53-634d-aa65-aed2c86263f9')
		dependency ('Help-Squeak-TerseGuide' 'Help-Squeak-TerseGuide-dtl.2' '8b18cab9-7183-4c5e-8cac-f79c4400da43')
		dependency ('SystemReporter' 'SystemReporter-ul.21' '34c5c48c-e7cc-4dfe-8133-6dec3bc63ff7')
		dependency ('BalloonTests' 'BalloonTests-egp.2' 'a8206c39-12ee-4222-a29a-caa537e037c4')
		dependency ('CommandLine' 'CommandLine-fbs.2' '414e59b8-4f4a-814d-9dac-b7b9886e92a0')
		dependency ('UpdateStream' 'UpdateStream-nice.4' '5fcdedce-88aa-469a-bf8b-32820f051c4f')
		)
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> cachedNonDiffyVersionNamed: versionName from: repo [
	"Make sure that the cache contains a non-diffy version of versionName and  answer it."
	| cacheRepo nonDiffyVersion |
	self assert: (versionName endsWith: '.mcz').
	cacheRepo := MCCacheRepository default.
	"Make sure that at least the diffy (.mcd) version is present"
	(cacheRepo directory includesKey: versionName) ifFalse:
		[cacheRepo storeVersion: (repo versionNamed: versionName)].
	"if after storeVersion there's still no .mcz we need to create one; sigh..."
	(cacheRepo directory includesKey: versionName) ifFalse:
		[| baseName diffyVersionName diffyVersion file delete |
		 baseName := versionName allButLast: 4. "strip .mcz"
		 diffyVersionName := cacheRepo directory fileNames detect: [:fn| (fn endsWith: '.mcd') and: [(fn copyUpTo: $() = baseName]].
		 diffyVersion := cacheRepo versionNamed: diffyVersionName.
		 file := cacheRepo directory newFileNamed: versionName.
		 delete := false.
		 [file binary.
		  [MCMczWriter fileOut: diffyVersion on: file]
			on: Error
			do: [:ex|
				delete := true. "don't leave half-formed .mcz files around to screw things up later on..."
				ex pass]]
			ensure:
				[file close.
				 delete ifTrue:
					[cacheRepo directory deleteFileNamed: versionName]].
		 "now delete the damn diffy version that caused all the pain in the first place"
		 delete ifFalse:
			[cacheRepo directory deleteFileNamed: diffyVersionName].
		 cacheRepo flushCache; cacheAllFilenames].
	nonDiffyVersion := cacheRepo versionNamed: versionName.
	self assert: (nonDiffyVersion fileName endsWith: '.mcz').
	^nonDiffyVersion
]

{ #category : #'private-accessing' }
SpurBootstrapMonticelloPackagePatcher >> classDefinitionFor: className type: typeSymbol from: definitions comment: commentString stamp: stampString [
	| classDef |
	classDef := definitions
					detect: [:d| d isClassDefinition and: [d className = className]]
					ifNone:
						[self assert: (#(BoxedFloat64 SmallFloat64) includes: className).
						 MCClassDefinition new
							initializeWithName: className
							superclassName: #Float
							traitComposition: '{}'
							classTraitComposition: '{}'
							category: 'Kernel-Numbers'
							instVarNames: #()
							classVarNames: #()
							poolDictionaryNames: #()
							classInstVarNames: #()
							type: typeSymbol
							comment: commentString asString
							commentStamp: stampString].
	className == #Character ifTrue:
		[classDef variables removeAllSuchThat:
			[:varDef|
			 varDef isInstanceVariable and: [varDef name = 'value']]].
	classDef instVarNamed: 'type' put: typeSymbol.
	commentString ifNotNil:
		[classDef
			instVarNamed: 'comment' put: commentString;
			instVarNamed: 'commentStamp' put: stampString].
	^MCAddition of: classDef
]

{ #category : #'private-accessing' }
SpurBootstrapMonticelloPackagePatcher >> compiledMethodClassDefinition [
	^MCAddition of: 
		(MCClassDefinition new
			initializeWithName: #CompiledMethod
			superclassName: #ByteArray
			category: #'Kernel-Methods'
			instVarNames: #()
			classVarNames: #(LargeFrame PrimaryBytecodeSetEncoderClass SecondaryBytecodeSetEncoderClass SmallFrame)
			poolDictionaryNames: #()
			classInstVarNames: #()
			type: #compiledMethod
			comment:
'CompiledMethod instances are methods suitable for interpretation by the virtual machine.  Instances of CompiledMethod and its subclasses are the only objects in the system that have both indexable pointer fields and indexable 8-bit integer fields.  The first part of a CompiledMethod is pointers, the second part is bytes.  CompiledMethod inherits from ByteArray to avoid duplicating some of ByteArray''s methods, not because a CompiledMethod is-a ByteArray.

Class variables:
SmallFrame								- the number of stack slots in a small frame Context
LargeFrame							- the number of stack slots in a large frame Context
PrimaryBytecodeSetEncoderClass		- the encoder class that defines the primary instruction set
SecondaryBytecodeSetEncoderClass	- the encoder class that defines the secondary instruction set

The current format of a CompiledMethod is as follows:

	header (4 or 8 bytes, SmallInteger)
	literals (4 or 8 bytes each, Object, see "The last literal..." below)
	bytecodes  (variable, bytes)
	trailer (variable, bytes)

The header is a SmallInteger (which in the 32-bit system has 31 bits, and in the 64-bit system, 61 bits) in the following format:

	(index 0)		15 bits:	number of literals (#numLiterals)
	(index 15)		  1 bit:	is optimized - reserved for methods that have been optimized by Sista
	(index 16)		  1 bit:	has primitive
	(index 17)		  1 bit:	whether a large frame size is needed (#frameSize => either SmallFrame or LargeFrame)
	(index 18)		  6 bits:	number of temporary variables (#numTemps)
	(index 24)		  4 bits:	number of arguments to the method (#numArgs)
	(index 28)		  2 bits:	reserved for an access modifier (00-unused, 01-private, 10-protected, 11-public), although accessors for bit 29 exist (see #flag).
	sign bit:			  1 bit: selects the instruction set, >= 0 Primary, < 0 Secondary (#signFlag)

If the method has a primitive then the first bytecode of the method must be a callPrimitive: bytecode that encodes the primitive index.

The trailer is an encoding of an instance of CompiledMethodTrailer.  It is typically used to encode the index into the source files array of the method''s source, but may be used to encode other values, e.g. tempNames, source as a string, etc.  See the class CompiledMethodTrailer.

The last literal in a CompiledMethod must be its methodClassAssociation, a binding whose value is the class the method is installed in.  The methodClassAssociation is used to implement super sends.  If a method contains no super send then its methodClassAssociation may be nil (as would be the case for example of methods providing a pool of inst var accessors).  By convention the penultimate literal of a method is either its selector or an instance of AdditionalMethodState.  AdditionalMethodState holds any pragmas and properties of a method, but may also be used to add instance variables to a method, albeit ones held in the method''s AdditionalMethodState.  Subclasses of CompiledMethod that want to add state should subclass AdditionalMethodState to add the state they want, and implement methodPropertiesClass on the class side of the CompiledMethod subclass to answer the specialized subclass of AdditionalMethodState.'
			commentStamp: 'eem 1/22/2015 15:47')
]

{ #category : #initialization }
SpurBootstrapMonticelloPackagePatcher >> directoryFrom: dirName [
	^FileDirectory on: (dirName first = $/
							ifTrue: [dirName]
							ifFalse: [(FileDirectory default directoryNamed: dirName) fullName])
]

{ #category : #'repository population' }
SpurBootstrapMonticelloPackagePatcher >> download: baseConfigurationOrArray "<MCConfiguration|Array>" from: repo [
	| base |
	base := baseConfigurationOrArray isArray
				ifTrue: [MCConfiguration fromArray: baseConfigurationOrArray]
				ifFalse: [baseConfigurationOrArray].
	self packagesAndPatches keysAndValuesDo:
		[:package :patches| | dependency |
		dependency := base dependencies detect: [:dep| dep package name = package name].
		self downloadToSourceDirAllPackageVersionsStartingWith: dependency versionInfo
			from: repo].
]

{ #category : #'repository population' }
SpurBootstrapMonticelloPackagePatcher >> downloadToSourceDirAllPackageVersionsStartingWith: aMCVersionInfo from: repo [ 
	| localRepo priorName |
	priorName := MCVersionName on: (aMCVersionInfo versionName
											copyReplaceAll: aMCVersionInfo versionNumber asString
											with: (aMCVersionInfo versionNumber - 1) asString).
	localRepo := MCDirectoryRepository directory: sourceDir.
	(repo possiblyNewerVersionsOfAnyOf: {priorName asMCVersionName}) do:
		[:newerVersion | 
		(localRepo includesVersionNamed: newerVersion) ifFalse:
			[localRepo storeVersion: (repo versionNamed: newerVersion)]]
]

{ #category : #'private-accessing' }
SpurBootstrapMonticelloPackagePatcher >> filesForPackage: package in: aDirectory [
	"Names sorted from lowest version to highest"
	^((aDirectory fileNames
			select:
				[:fileName|
				(fileName beginsWith: package name)
				 and: [(fileName at: package name size + 1) isLetter not
				 and: [(fileName copyFrom: package name size + 2 to: package name size + 5) ~= 'spur']]]
			thenCollect: [:fn| {fn asMCVersionName versionNumber. fn}])
		sort: [:tuple :tupolev|
			tuple first < tupolev first
			or: [tuple first = tupolev first
				and: [tuple last < tupolev last]]])
		collect: [:tuple| tuple last]
]

{ #category : #'private-accessing' }
SpurBootstrapMonticelloPackagePatcher >> filteredDefinitionsAsPatches: modifiedDefinitions patches: existingPatches [
	^modifiedDefinitions
		select:
			[:def|
			 existingPatches noneSatisfy:
				[:addition|
				def isMethodDefinition
				and: [addition definition isMethodDefinition
				and: [addition definition selector = def selector
				and: [addition definition className = def className
				and: [addition definition classIsMeta = def classIsMeta]]]]]]
		thenCollect:
			[:def|
			 ((def source includesSubString: 'DELETEME')
				ifTrue: [MCRemoval]
				ifFalse: [MCAddition]) of: def]
]

{ #category : #configurations }
SpurBootstrapMonticelloPackagePatcher >> findOldestConfigurationFor: packageVersions inVersionNames: configurationVersionNames repository: repo [
	| oldest |
	oldest := configurationVersionNames first.
	configurationVersionNames do:
		[:cfgver| | config |
		config := repo versionNamed: cfgver.
		(packageVersions noneSatisfy:
			[:pkgver| | configVersion |
			configVersion := config dependencies detect:
								[:dep|
								 pkgver packageName = dep package name].
			configVersion versionInfo versionNumber >= pkgver versionNumber]) ifTrue:
				[^oldest].
		oldest := cfgver].
	self error: 'couldn''t find configuration newer than supplied versions'
]

{ #category : #initialization }
SpurBootstrapMonticelloPackagePatcher >> from: sourceDirName to: destDirName [
	sourceDir := self directoryFrom: sourceDirName.
	destDir := self directoryFrom: destDirName
]

{ #category : #initialization }
SpurBootstrapMonticelloPackagePatcher >> imageTypes: typeArray [
	imageTypes := typeArray
]

{ #category : #'private-accessing' }
SpurBootstrapMonticelloPackagePatcher >> modifiedCharacterDefinitionsIn: definitions [
	| rewriter |
	rewriter := RBParseTreeRewriter new.
	rewriter
		replace: 'value' with: 'self asInteger';
		replace: 'value := ``@args' with: 'DELETEME'.
	^(((definitions select: [:d| d isMethodDefinition and: [d fullClassName = #Character]])
		collect: [:d| { d. self patchDefinition: d withRewriter: rewriter} ]
		thenSelect: [:pair| pair first source ~= pair second source])
			collect: [:pair| pair second])
]

{ #category : #'private-accessing' }
SpurBootstrapMonticelloPackagePatcher >> modifiedFloatDefinitionsIn: definitions [
	"Delete the non-accessing primitives in Float (prims 41 through 59),
	 and copy them to BoxedFloat64,
	 and create corresponding ones in SmallFloat64 with primtiive numbers + 500."
	| floatPrims |
	floatPrims := definitions select:
					[:d| | index |
					d isMethodDefinition
					and: [d fullClassName = #Float
					and: [(index := d source indexOfSubCollection: '<primitive: ') > 0
					and: [(Integer readFrom: (ReadStream on: d source from: index + '<primitive: ' size to: index + '<primitive: ' size + 4))
							between: 41
							and: 59]]]].
	^(floatPrims collect:
		[:d|
		 MCMethodDefinition new
			initializeWithClassName: d className
			classIsMeta: false
			selector: d selector
			category: d category
			timeStamp: d timeStamp
			source: d source, 'DELETEME']),
	 (floatPrims collect:
		[:d|
		 MCMethodDefinition new
			initializeWithClassName: #BoxedFloat64
			classIsMeta: false
			selector: d selector
			category: d category
			timeStamp: d timeStamp
			source: d source]),
	 (floatPrims collect:
		[:d|
		 MCMethodDefinition new
			initializeWithClassName: #SmallFloat64
			classIsMeta: false
			selector: d selector
			category: d category
			timeStamp: 'eem 11/25/2014 07:54'
			source: (d source copyReplaceAll: '<primitive: ' with: '<primitive: 5')])
]

{ #category : #accessing }
SpurBootstrapMonticelloPackagePatcher >> packageForMissingClassNamed: className [
	(className = #BoxedFloat64
	 or: [className = #SmallFloat64]) ifTrue:
		[^PackageInfo named: 'Kernel'].
	self error: 'unknown missing class'
]

{ #category : #'private-accessing' }
SpurBootstrapMonticelloPackagePatcher >> packages [
	"Answer the packages Spur modifies."
	^self packagesAndPatches keys
]

{ #category : #'private-accessing' }
SpurBootstrapMonticelloPackagePatcher >> packagesAndPatches [
	"SpurBootstrapMonticelloPackagePatcher new packagesAndPatches"
	| spurBootstrap |
	packagesAndPatches ifNotNil:
		[^packagesAndPatches].
	packagesAndPatches := Dictionary new.
	spurBootstrap := SpurBootstrap new.
	imageTypes ifNotNil:
		[spurBootstrap imageTypes: imageTypes].
	spurBootstrap prototypeClassNameMetaSelectorMethodDo:
		[:className :isMeta :selector :method| | package category source definition |
		 (Smalltalk classNamed: className)
			ifNil: [package := self packageForMissingClassNamed: className]
			ifNotNil:
				[:behavior| | class methodReference |
				 class := isMeta ifTrue: [behavior class] ifFalse: [behavior].
				 (class includesSelector: selector) ifTrue:
					[methodReference := (class >> selector) methodReference.
					 category := methodReference category.
					 category first = $* ifTrue:
						[category := nil]].
				 package := (methodReference isNil
							  or: [methodReference category = Categorizer default
							  or: [methodReference category first = $*]]) "This for Scorch's override of InstructionClient>>classPrimitive:"
								ifTrue: [PackageOrganizer default packageOfClass: class]
								ifFalse: [PackageOrganizer default packageOfMethod: methodReference]].
		 source := method getSourceFromFile asString allButFirst: method selector size - selector size.
		 source first ~= selector first ifTrue:
			[source replaceFrom: 1 to: selector size with: selector startingAt: 1].
		 definition := MCAddition of: (MCMethodDefinition new
										initializeWithClassName: className
										classIsMeta: isMeta
										selector: selector
										category: (category ifNil: [SpurBootstrap
																	categoryForClass: className
																	meta: isMeta
																	selector: selector])
										timeStamp: method timeStamp
										source: source).
		 (method pragmaAt: #remove) ifNotNil:
			[definition := definition inverse].
		 (packagesAndPatches at: package ifAbsentPut: [OrderedCollection new])
			add: definition].
	^packagesAndPatches
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> patch [
	"(SpurBootstrapMonticelloPackagePatcher new
			from: 'trunkpackages'
			to: 'spurpackages')
		patch"
	"(SpurBootstrapMonticelloPackagePatcher new
			from: '/Users/eliot/Squeak/Squeak4.5-spur/squeakv3-package-cache'
			to: '/Users/eliot/Squeak/Squeak4.5-spur/package-cache')
		patch"
	"(SpurBootstrapMonticelloPackagePatcher new
			from: '/Users/eliot/Glue/repositories/nsboot/Squeak4.3/squeak-package-cache'
			to: '/Users/eliot/Glue/repositories/nsboot/Squeak4.3/package-cache')
		patch"
	
	sourceDir exists ifFalse:
		[self error: 'source directory doest not exist'].
	destDir assureExistence.
	self packagesAndPatches keysAndValuesDo:
		[:package :patches|
		 (self filesForPackage: package in: sourceDir) do:
			[:packageFile|
			 self patchPackage: packageFile with: patches for: package]]
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> patchAndUploadAllInTrunk [
	"Look for all versions in the default repository that have patched versions there-in.
	 Download and patch them and upload the patched versions (overwriting the older ones)."
	"(SpurBootstrapMonticelloPackagePatcher new
		from: 'trunkpackages'
		to: 'spurpackages')
			patchAndUploadAllInTrunk"
	| seed trunk sourceRepo cacheRepo |
	seed := 'Are you really sure you want to do this?\It should happen only once!' withCRs.
	3 timesRepeat:
		[(UIManager confirm: seed) ifFalse: [^self].
		 seed := seed copyReplaceAll: 'really ' with: 'really, really '].
	sourceDir assureExistence; deleteLocalFiles.
	destDir assureExistence; deleteLocalFiles.
	sourceRepo := MCDirectoryRepository directory: sourceDir.
	cacheRepo := MCCacheRepository default.
	(trunk := self trunk) cacheAllFileNamesDuring:
		[| latestBranches latestUnbranched |
		latestBranches := self packages collect:
							[:package|
							(trunk versionNamesForPackageNamed: package name, '.spur') detectMin: [:vn | vn asMCVersionName versionNumber]].
		latestUnbranched := latestBranches collect:
								[:verName|
								(trunk versionNamed: (verName copyReplaceAll: '.spur' with: '') asMCVersionName) info ancestors first versionName].
		((trunk possiblyNewerVersionsOfAnyOf: latestUnbranched)
			reject: [:unpatched| unpatched includesSubString: '.spur'])
			do: [:unpatched|
				"it is claimed that whether a repository contains a .mcz or a .mcd is irrelevant.  At least for the cache repository that's not true."
				sourceRepo storeVersion: (self cachedNonDiffyVersionNamed: unpatched from: trunk)].
		 self patchAsNeeded.
		 self uploadFrom: (MCDirectoryRepository directory: destDir) to: trunk]
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> patchAndUploadNewer [
	"Look for unbranched versions on the default repository that are newer than the
	 image''s versions. Download and patch them and upload the patched versions."
	"(SpurBootstrapMonticelloPackagePatcher new
		from: 'trunkpackages'
		to: 'spurpackages')
			patchAndUploadNewer"
	| repo sourceRepo |
	sourceDir deleteLocalFiles.
	destDir deleteLocalFiles.
	repo := self repositoryForUrl: MCMcmUpdater defaultUpdateURL.
	sourceRepo := MCDirectoryRepository directory: sourceDir.
	repo cacheAllFileNamesDuring:
		[self packages do:
			[:package| | workingCopy |
			workingCopy := MCWorkingCopy allManagers detect: [:pkg| pkg packageName = package packageName].
			(workingCopy possiblyNewerVersionsIn: repo) do:
				[:newerVersion|
				 newerVersion packageAndBranchName = package packageName ifTrue: "Don't patch already patched packages!!"
					[(sourceRepo includesVersionNamed: newerVersion) ifFalse:
						[sourceRepo storeVersion: (repo versionNamed: newerVersion)]]]].
		 self patchAsNeeded.
		 self uploadFrom: (MCDirectoryRepository directory: destDir) to: repo]
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> patchAndUploadUnpatchedInTrunk [
	"Look for unbranched versions in the default repository that are newer than the
	 latest patched versions there-in. Download and patch them and upload the patched
	 versions."
	"(SpurBootstrapMonticelloPackagePatcher new
		from: 'trunkpackages'
		to: 'spurpackages')
			patchAndUploadUnpatchedInTrunk"
	| trunk sourceRepo cacheRepo |
	sourceDir assureExistence; deleteLocalFiles.
	destDir assureExistence; deleteLocalFiles.
	sourceRepo := MCDirectoryRepository directory: sourceDir.
	cacheRepo := MCCacheRepository default.
	(trunk := self trunk) cacheAllFileNamesDuring:
		[| latestBranches latestUnbranched |
		latestBranches := self packages collect:
							[:package|
							(trunk versionNamesForPackageNamed: package name, '.spur') detectMax: [:vn | vn asMCVersionName versionNumber]]
							thenSelect: [:branch| branch notNil].
		latestUnbranched := latestBranches collect: [:verName| (verName copyReplaceAll: '.spur' with: '') asMCVersionName].
		((trunk possiblyNewerVersionsOfAnyOf: latestUnbranched)
			reject: [:unpatched| unpatched includesSubString: '.spur'])
			do: [:unpatched|
				"it is claimed that whether a repository contains a .mcz or a .mcd is irrelevant.  At least for the cache repositoriy that's not true."
				sourceRepo storeVersion: (self cachedNonDiffyVersionNamed: unpatched from: trunk)].
		 self patchAsNeeded.
		 self uploadFrom: (MCDirectoryRepository directory: destDir) to: trunk]
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> patchAsNeeded [
	(sourceDir exists and: [destDir exists]) ifFalse:
		[self error: 'one or both of the directories don''t exist'].
	self packagesAndPatches keysAndValuesDo:
		[:package :patches|
		 (self filesForPackage: package in: sourceDir) do:
			[:packageFile| | spurPackageFile |
			 spurPackageFile := self spurBranchNameForInfo: packageFile package: package.
			 ((destDir includesKey: packageFile) or: [destDir includesKey: spurPackageFile])
				ifTrue:
					[Transcript
						cr; nextPutAll: destDir fullName; nextPutAll: ' contains either ';
						nextPutAll: packageFile; nextPutAll: ' or '; nextPutAll: spurPackageFile;
						nextPutAll: '; not saving'; flush]
				ifFalse:
					[self patchPackage: packageFile with: patches for: package]]]

	"| patcher |
	 patcher := SpurBootstrapMonticelloPackagePatcher new
					from: 'trunkpackages'
					to: 'spurpackages'.
	patcher trunk cacheAllFileNamesDuring:
		[patcher patchAsNeeded]"
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> patchDefinition: aMCMethodDefinition withRewriter: aRBParseTreeRewriter [ 
	| parseTree |
	parseTree := RBParser
					parseMethod: aMCMethodDefinition source
					onError: [:str :pos | self halt].
	aRBParseTreeRewriter executeTree: parseTree.
	^MCMethodDefinition new
		initializeWithClassName: aMCMethodDefinition className
		classIsMeta:aMCMethodDefinition classIsMeta
		selector: aMCMethodDefinition selector
		category: aMCMethodDefinition category
		timeStamp: aMCMethodDefinition timeStamp
		source: aRBParseTreeRewriter tree newSource
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> patchFile: packageFile [
	"(SpurBootstrapMonticelloPackagePatcher new
			from: '/Users/eliot/oscogvm/image/package-cache'
			to: '/Users/eliot/oscogvm/image/spurpackages')
		patchFile: 'Collections-ul.573(nice.572).mcd'"
	
	sourceDir exists ifFalse:
		[self error: 'source directory doest not exist'].
	destDir assureExistence.
	self packagesAndPatches keysAndValuesDo:
		[:package :patches|
		 ((packageFile beginsWith: package name)
		  and: [(packageFile at: package name size + 1) isLetter not]) ifTrue:
			[self patchPackage: packageFile with: patches for: package]]
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> patchPackage: packageFileName with: patches for: package [
	| version newVersion |
	version := self versionFor: packageFileName in: sourceDir.
	newVersion := self version: version withPatches: patches for: package.
	self storeVersion: newVersion
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> patches: basePatches forSnapshot: snapshot [
	"Add modified class defs for Character, SmallInteger, Float, BoxedFloat64, SmallFloat64 and COmpiledMethod.
	 Remove ObjectHistory and ObjectHistoryMark (which Spur does not support)."
	| patches defs |
	patches  := basePatches copy.
	defs := snapshot definitions.
	(defs anySatisfy: [:d| d isClassDefinition and: [d className == #Character]]) ifTrue:
		[patches
			addAll: (self filteredDefinitionsAsPatches: (self modifiedCharacterDefinitionsIn: snapshot definitions)
						patches: patches);
			add: (self
					classDefinitionFor: #Character
					type: #immediate
					from: snapshot definitions
					comment: 'I represent a character by storing its associated Unicode as an unsigned 30-bit value.  Characters are created uniquely, so that all instances of a particular Unicode are identical.  My instances are encoded in tagged pointers in the VM, so called immediates, and therefore are pure immutable values.

	The code point is based on Unicode.  Since Unicode is 21-bit wide character set, we have several bits available for other information.  As the Unicode Standard  states, a Unicode code point doesn''t carry the language information.  This is going to be a problem with the languages so called CJK (Chinese, Japanese, Korean.  Or often CJKV including Vietnamese).  Since the characters of those languages are unified and given the same code point, it is impossible to display a bare Unicode code point in an inspector or such tools.  To utilize the extra available bits, we use them for identifying the languages.  Since the old implementation uses the bits to identify the character encoding, the bits are sometimes called "encoding tag" or neutrally "leading char", but the bits rigidly denotes the concept of languages.

	The other languages can have the language tag if you like.  This will help to break the large default font (font set) into separately loadable chunk of fonts.  However, it is open to the each native speakers and writers to decide how to define the character equality, since the same Unicode code point may have different language tag thus simple #= comparison may return false.'
					stamp: 'eem 8/12/2014 14:53')].
	(defs anySatisfy: [:def| def isClassDefinition and: [def className == #SmallInteger]]) ifTrue:
		[patches
			add: (self
					classDefinitionFor: #SmallInteger
					type: #immediate
					from: snapshot definitions
					comment: 'My instances are at least 31-bit numbers, stored in twos complement form. The allowable range in 32-bits is approximately +- 10^9 (+- 1billion).  In 64-bits my instances are 61-bit numbers, stored in twos complement form. The allowable range is approximately +- 10^18 (+- 1 quintillion).   The actual values are computed at start-up.  See SmallInteger class startUp:, minVal, maxVal.'
					stamp: 'eem 11/20/2014 08:41')].
	(defs anySatisfy: [:def| def isClassDefinition and: [def className == #Float]]) ifTrue:
		[patches
			add: (self
					classDefinitionFor: #Float
					type: #normal
					from: snapshot definitions
					comment: nil
					stamp: nil);
			add: (self
					classDefinitionFor: #BoxedFloat64
					type: #words
					from: snapshot definitions
					comment: 'My instances hold 64-bit Floats in heap objects.  This is the only representation on 32-bit systems.  But on 64-bit systems SmallFloat64 holds a subset of the full 64-bit double-precision range in immediate objects.'
					stamp: 'eem 11/25/2014 07:54');
			add: (self
					classDefinitionFor: #SmallFloat64
					type: #immediate
					from: snapshot definitions
					comment: 'My instances represent 64-bit Floats whose exponent fits in 8 bits as immediate objects.  This representation is only available on 64-bit systems, not 32-bit systems.'
					stamp: 'eem 11/25/2014 07:54');
			addAll: (self filteredDefinitionsAsPatches: (self modifiedFloatDefinitionsIn: snapshot definitions)
						patches: patches)].
	(defs anySatisfy: [:def| def isClassDefinition and: [def className == #CompiledMethod]]) ifTrue:
		[patches
			add: self compiledMethodClassDefinition].
	(defs anySatisfy: [:def| def isClassDefinition and: [def className == #ObjectHistory]]) ifTrue:
		[patches addAll:
			(defs
				select: [:def| #(ObjectHistory ObjectHistoryMark) includes: def className]
				thenCollect: [:def| MCRemoval of: def])].
	^MCPatch operations: patches
]

{ #category : #'repository population' }
SpurBootstrapMonticelloPackagePatcher >> repositoryForUrl: url [
	^MCRepositoryGroup default repositories 
		detect: [:r| r description = url]
		ifNone: [MCHttpRepository
					location: url
					user: 'squeak'
					password: 'squeak']
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> spurBranchNameForInfo: versionInfoOrString package: package [
	^(versionInfoOrString isString
		ifTrue: [versionInfoOrString]
		ifFalse: [versionInfoOrString name]) copyReplaceAll: package name with: package name, '.spur'
]

{ #category : #configurations }
SpurBootstrapMonticelloPackagePatcher >> spurConfigurationOf: anMCConfiguration forRepository: repo [
	"Answer a copy of anMCConfiguration containing the matching Spur dependencies.
	 If no replacements could be made (because no Spur versions exist) then answer nil."
	| found clone |
	found := false.
	clone := Array streamContents:
				[:s|
				s nextPut: #name; nextPut: (anMCConfiguration name copyReplaceAll: 'update-' with: 'update.spur-');
				 "no location accessor!!"
				  nextPut: #repository; nextPut: {anMCConfiguration repositories first locationWithTrailingSlash allButLast}.
				 anMCConfiguration dependencies do:
					[:dep| | info pkg ver spurVersionName |
					 info := dep versionInfo.
					 ((pkg := self packages
								detect: [:package| package name = dep package name]
								ifNone: []) notNil
					  and: [spurVersionName := (info name
													copyReplaceAll: pkg name
													with: pkg name, '.spur'), '.mcz'.
						 (ver := MCCacheRepository default versionNamed: spurVersionName asMCVersionName) ifNil:
							[ver := repo versionNamed: spurVersionName asMCVersionName].
						 ver notNil])
						ifTrue: [found := true. info := ver info].
					(ver isNil and: [spurVersionName notNil]) ifTrue:
						[Transcript nextPutAll: 'failed to get ', spurVersionName, ' in ', anMCConfiguration name; cr; flush.
						 self error: 'failed to get ', spurVersionName, ' in ', anMCConfiguration name].
					s nextPut: #dependency; nextPut: (MCConfiguration dependencyToArray: (MCVersionDependency package: dep package info: info))]].
	^found ifTrue:
		[MCConfiguration fromArray: clone]
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> storeVersion: newVersion [
	[(MCDirectoryRepository new directory: destDir) storeVersion: newVersion]
		on: FileExistsException
		do: [:ex| ex resume: (ex fileClass forceNewFileNamed: ex fileName)]
]

{ #category : #'repository population' }
SpurBootstrapMonticelloPackagePatcher >> trunk [
	^self repositoryForUrl: 'http://source.squeak.org/trunk'
]

{ #category : #'repository population' }
SpurBootstrapMonticelloPackagePatcher >> uploadFrom: localRepo to: uploadRepository [
	localRepo allVersionsDo:
		[:version|
		(uploadRepository includesVersionNamed: version info name) ifFalse:
			[uploadRepository storeVersion: version]]
]

{ #category : #configurations }
SpurBootstrapMonticelloPackagePatcher >> uploadNewerSpurConfigurationsInTrunk [
	"Make sure that update.spur configurations exist for all relevant update.* configurations."
	"SpurBootstrapMonticelloPackagePatcher new uploadNewerSpurConfigurationsInTrunk"
	| trunk |
	trunk := self trunk.
	trunk cacheAllFileNamesDuring:
		[| configurations spurConfigurations oldestUpdate |
		 spurConfigurations := (trunk versionNamesForPackageNamed: 'update.spur') sort: [:a :b| a versionNumber > b versionNumber].
		 configurations := ((trunk versionNamesForPackageNamed: 'update') select: [:n| n beginsWith: 'update-']) sort: [:a :b| a versionNumber > b versionNumber].
		 oldestUpdate := spurConfigurations isEmpty
							ifTrue:
								[| earliestBranches earliestUnbranched  |
								 earliestBranches := self packages collect:
														[:package|
														(trunk versionNamesForPackageNamed: package name, '.spur') detectMin:
															[:vn | vn asMCVersionName versionNumber]].
								 earliestUnbranched := earliestBranches collect:
															[:verName| (verName copyReplaceAll: '.spur' with: '') asMCVersionName].
								 self
									findOldestConfigurationFor: earliestUnbranched
									inVersionNames: configurations
									repository: trunk]
							ifFalse:
								[spurConfigurations first copyReplaceAll: '.spur' with: ''].
		 Transcript nextPutAll: 'Oldest: ', oldestUpdate; cr; flush.
		 (configurations copyFrom: 1 to: (configurations indexOf: oldestUpdate) - 1) reverseDo:
			[:configName|
			 "((configName beginsWith: 'update-eem.29') and: ['34' includes: (configName at: 14)]) ifTrue:
				[self halt]."
			 (self spurConfigurationOf: (trunk versionNamed: configName) forRepository: trunk) ifNotNil:
				[:edition| trunk storeVersion: edition]]]
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> version: version withPatches: patches for: package [
	| snapshot ancestry possibleSpurAncestor actualAncestor |
	snapshot := MCPatcher
					apply: (self patches: patches forSnapshot: version snapshot)
					to: version snapshot.
	ancestry := MCWorkingAncestry new addAncestor: version info.
	"this is a hack; we may not be patching w.r.t. a directory or trunk"
	possibleSpurAncestor := (self spurBranchNameForInfo: version info ancestors first package: package) , '.mcz'.
	(destDir includesKey: possibleSpurAncestor)
		ifTrue:
			[actualAncestor := self versionFor: possibleSpurAncestor in: destDir]
		ifFalse:
			[((self trunk versionNamesForPackageNamed: package name) includes: possibleSpurAncestor) ifTrue:
				[actualAncestor := self trunk versionNamed: possibleSpurAncestor]].
	actualAncestor ifNotNil:
		[ancestry addAncestor: actualAncestor info].
	^MCVersion
		package: version package
		info: (ancestry
				infoWithName: (self spurBranchNameForInfo: version info package: package)
				message:	version info name,
							' patched for Spur by ',
							(CCodeGenerator shortMonticelloDescriptionForClass: self class),
							'\\' withCRs,
							version info message)
		snapshot: snapshot
		dependencies: {} "punt on computing dependencies; there are't any so far"
]

{ #category : #patching }
SpurBootstrapMonticelloPackagePatcher >> versionFor: packageFileName in: directory [
	^directory
		readOnlyFileNamed: packageFileName
		do: [:fs|
			((MCVersionReader readerClassForFileNamed: fs fullName)
				on: fs fileName: fs fullName)
					version]
]
