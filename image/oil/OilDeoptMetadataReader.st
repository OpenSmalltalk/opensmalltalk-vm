Object subclass: #OilDeoptMetadataReader
	instanceVariableNames: 'receiverClass metadata base'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMMaker-JIT-OilDebugging'!

!OilDeoptMetadataReader commentStamp: 'cb 10/26/2026 14:30' prior: 0!
I decode a copy of the deoptimization metadata of an Oil method, for VM engineers and benchmarkers (the debugger needs only Context>>contexts and Context>>deoptimize).  CompiledMethod>>oilMetadata (primitiveOilMetadata) answers the copies: nil, or an Array of pairs { class or nil. metadata }, one for the method's own Oil code, else one per specialization.  The metadata object itself is hidden in the VM; its copy is a CompiledMethod (never run): its literal frame, then its bytes (see the OilMD* constants of OilConstants for their layout).

	reader := OilDeoptMetadataReader on: (aMethod oilMetadata).
	reader frames. reader sites. reader printString

receiverClass	<Class|nil>	the class of a specialization, nil for the method's own Oil code
metadata	<CompiledMethod>	the copy of the metadata: its literal frame (the root method, the inlined selectors, then the objects the records refer to; literal index 0 stands for nil), then its bytes (the header, then the records)
base		<Integer>	the byte offset of the header in the metadata object (offsets in the header and records are offsets in the object)!

!OilDeoptMetadataReader class methodsFor: 'instance creation' stamp: 'cb 10/26/2026 22:15'!
on: metadataOrPairs
	"metadataOrPairs: a pair { class or nil. metadata } or an Array of them (answer a reader on the first)."
	| pair |
	metadataOrPairs isNil ifTrue: [^self error: 'no Oil metadata'].
	pair := (metadataOrPairs size = 2 and: [(metadataOrPairs at: 2) isCompiledMethod])
				ifTrue: [metadataOrPairs]
				ifFalse: [metadataOrPairs first].
	^self new setClass: (pair at: 1) metadata: (pair at: 2)! !

!OilDeoptMetadataReader class methodsFor: 'instance creation' stamp: 'cb 10/26/2026 14:30'!
allOn: metadata
	"A reader per pair of metadata (see on:), or none if nil."
	metadata isNil ifTrue: [^#()].
	^metadata collect: [:pair | self on: pair]! !

!OilDeoptMetadataReader class methodsFor: 'primitives' stamp: 'cb 10/26/2026 14:30'!
metadataOf: aCompiledMethod
	"The copies of the deoptimization metadata of aCompiledMethod's Oil code, or nil (see CompiledMethod>>oilMetadata)."
	<primitive: 'primitiveOilMetadata'>
	^nil! !

!OilDeoptMetadataReader class methodsFor: 'primitives' stamp: 'cb 10/26/2026 14:30'!
contextChainOf: aContext
	"{ method. pc. method. pc ... } for the activations the Oil frame of aContext stands for, innermost first, or nil if
	 aContext is not married to the frame of an Oil method (see Context>>contexts)."
	<primitive: 'primitiveOilContexts'>
	^nil! !

!OilDeoptMetadataReader class methodsFor: 'primitives' stamp: 'cb 10/26/2026 14:30'!
deoptimize: aContext
	"See Context>>deoptimize."
	<primitive: 'primitiveOilDeoptimize'>
	^aContext! !

!OilDeoptMetadataReader methodsFor: 'initialization' stamp: 'cb 10/26/2026 22:15'!
setClass: aClassOrNil metadata: aCompiledMethod
	receiverClass := aClassOrNil.
	metadata := aCompiledMethod.
	base := metadata initialPC - 1! !

!OilDeoptMetadataReader methodsFor: 'accessing' stamp: 'cb 10/26/2026 14:30'!
receiverClass
	^receiverClass! !

!OilDeoptMetadataReader methodsFor: 'accessing' stamp: 'cb 10/26/2026 22:15'!
literals
	"The literal frame of the metadata."
	^(1 to: metadata numLiterals) collect: [:index | metadata literalAt: index]! !

!OilDeoptMetadataReader methodsFor: 'accessing' stamp: 'cb 10/26/2026 22:15'!
bytes
	"The bytes of the metadata after its literal frame: the header, then the records."
	^(base + 1 to: metadata size) collect: [:index | metadata at: index] as: ByteArray! !

!OilDeoptMetadataReader methodsFor: 'decoding' stamp: 'cb 10/26/2026 22:15'!
u8: offset
	"The byte at offset in the metadata object (little endian, like all its fields)."
	^metadata at: offset + 1! !

!OilDeoptMetadataReader methodsFor: 'decoding' stamp: 'cb 10/26/2026 14:30'!
s8: offset
	| byte |
	byte := self u8: offset.
	^byte > 127 ifTrue: [byte - 256] ifFalse: [byte]! !

!OilDeoptMetadataReader methodsFor: 'decoding' stamp: 'cb 10/26/2026 14:30'!
u16: offset
	^(self u8: offset) + ((self u8: offset + 1) bitShift: 8)! !

!OilDeoptMetadataReader methodsFor: 'decoding' stamp: 'cb 10/26/2026 14:30'!
s16: offset
	| value |
	value := self u16: offset.
	^value > 32767 ifTrue: [value - 65536] ifFalse: [value]! !

!OilDeoptMetadataReader methodsFor: 'decoding' stamp: 'cb 10/26/2026 14:30'!
u32: offset
	^(self u16: offset) + ((self u16: offset + 2) bitShift: 16)! !

!OilDeoptMetadataReader methodsFor: 'decoding' stamp: 'cb 10/26/2026 14:30'!
header: field
	"The u16 header field at the byte offset field (OilMDNumSites, OilMDFrames...)."
	^self u16: base + field! !

!OilDeoptMetadataReader methodsFor: 'decoding' stamp: 'cb 10/26/2026 14:30'!
literal: index
	"Literal index 0 stands for nil."
	^index = 0 ifTrue: [nil] ifFalse: [metadata literalAt: index]! !

!OilDeoptMetadataReader methodsFor: 'decoding' stamp: 'cb 10/26/2026 14:30'!
pcFrom: offset
	"A bytecode pc of the metadata (0-relative, as in the VM) as a Smalltalk pc (1-relative), nil for none (65535)."
	^offset = 65535 ifTrue: [nil] ifFalse: [offset + 1]! !

!OilDeoptMetadataReader methodsFor: 'header' stamp: 'cb 10/27/2026 13:50'!
isValid
	^metadata size - base >= 42 and: [(self u32: base) = 16r4F494C34]! !

!OilDeoptMetadataReader methodsFor: 'header' stamp: 'cb 10/26/2026 14:30'!
rootMethod
	^metadata literalAt: 1! !

!OilDeoptMetadataReader methodsFor: 'header' stamp: 'cb 10/26/2026 14:30'!
numSites
	^self header: 4! !

!OilDeoptMetadataReader methodsFor: 'header' stamp: 'cb 10/26/2026 14:30'!
numFrames
	^self header: 8! !

!OilDeoptMetadataReader methodsFor: 'header' stamp: 'cb 10/26/2026 14:30'!
numVObjs
	^self header: 12! !

!OilDeoptMetadataReader methodsFor: 'header' stamp: 'cb 10/26/2026 14:30'!
numSpills
	^self header: 16! !

!OilDeoptMetadataReader methodsFor: 'header' stamp: 'cb 10/26/2026 14:30'!
deopts
	"The number of deoptimizations of the Oil code when the copy was made."
	^self u32: base + 20! !

!OilDeoptMetadataReader methodsFor: 'header' stamp: 'cb 10/26/2026 14:30'!
fastPaths
	"The number of failed class guards resumed after unforwarding when the copy was made."
	^self u32: base + 24! !

!OilDeoptMetadataReader methodsFor: 'header' stamp: 'cb 10/26/2026 14:30'!
numArgs
	^self header: 28! !

!OilDeoptMetadataReader methodsFor: 'header' stamp: 'cb 10/26/2026 14:30'!
inlinedSelectors
	"The selectors Oil inlined or looked up (the Oil code depends on their methods), or nil if too many to record."
	| count |
	count := self s16: base + 32.
	count < 0 ifTrue: [^nil].
	^(2 to: count + 1) collect: [:index | metadata literalAt: index]! !

!OilDeoptMetadataReader methodsFor: 'header' stamp: 'cb 10/27/2026 13:50'!
selectorMask
	"The 64-bit bloom filter mask of the identityHashes of the inlined selectors."
	^(self u32: base + 34) + ((self u32: base + 38) bitShift: 32)! !

!OilDeoptMetadataReader methodsFor: 'header' stamp: 'cb 10/26/2026 14:30'!
header
	"The header fields, by name."
	^Dictionary new
		at: #numSites put: self numSites;
		at: #numFrames put: self numFrames;
		at: #numVObjs put: self numVObjs;
		at: #numSpills put: self numSpills;
		at: #deopts put: self deopts;
		at: #fastPaths put: self fastPaths;
		at: #numArgs put: self numArgs;
		yourself! !

!OilDeoptMetadataReader methodsFor: 'records' stamp: 'cb 10/26/2026 14:30'!
frameAt: frameIndex
	"The record of inlined frame frameIndex (0 is the root): its method (or CompiledBlock), whether it is a block, its
	 base register, its parent frame (-1 for the root) and the pc after the send it was inlined at, in its parent."
	| record |
	record := (self header: 10) + (frameIndex * 10).
	^Dictionary new
		at: #index put: frameIndex;
		at: #method put: (self literal: (self u16: record));
		at: #isBlock put: (self u8: record + 2) ~= 0;
		at: #base put: (self u8: record + 3);
		at: #parentFrame put: (self s8: record + 4);
		at: #returnPC put: (self pcFrom: (self u16: record + 5));
		at: #numArgs put: (self u8: record + 9);
		yourself! !

!OilDeoptMetadataReader methodsFor: 'records' stamp: 'cb 10/26/2026 14:30'!
frames
	^(0 to: self numFrames - 1) collect: [:frameIndex | self frameAt: frameIndex]! !

!OilDeoptMetadataReader methodsFor: 'records' stamp: 'cb 10/26/2026 14:30'!
siteAt: siteIndex
	"The record of deopt site siteIndex, or nil if the site is not used: its kind (OilSiteGuard 1, OilSiteArith 2,
	 OilSiteBounds 3, OilSiteCall 4, OilSiteBranch 5, OilSiteStore 6, OilSiteAlloc 7), its inlined frame and pc, the offset
	 of the machine code to resume at (for a call, its return address), whether it is a class guard or a call, and, for a
	 call, the size of the send bytecode and its number of arguments."
	| record kindByte site |
	record := self u16: (self header: 6) + (2 * siteIndex).
	record = 0 ifTrue: [^nil].
	kindByte := self u8: record.
	site := Dictionary new
		at: #index put: siteIndex;
		at: #kind put: (kindByte bitAnd: 63);
		at: #isGuard put: kindByte >= 128;
		at: #isCall put: (kindByte bitAnd: 64) ~= 0;
		at: #frameIndex put: (self u8: record + 1);
		at: #sitePC put: (self pcFrom: (self u16: record + 2));
		at: #resumeOffset put: (self u16: record + 4);
		at: #top put: (self u8: record + 6);
		at: #high put: (self u8: record + 7);
		yourself.
	(kindByte bitAnd: 64) ~= 0 ifTrue:
		[site
			at: #sendSize put: (self u8: record + 8);
			at: #sendNumArgs put: (self u8: record + 9);
			at: #isInterruptCheck put: (self u8: record + 9) = 255 "(OilMDSiteNoSend: the interrupt check of a loop)"].
	^site! !

!OilDeoptMetadataReader methodsFor: 'records' stamp: 'cb 10/26/2026 14:30'!
sites
	"The used deopt sites."
	^((0 to: self numSites - 1) collect: [:siteIndex | self siteAt: siteIndex]) select: [:site | site notNil]! !

!OilDeoptMetadataReader methodsFor: 'records' stamp: 'cb 10/26/2026 19:45'!
callSites
	^self sites select: [:site | (site at: #isCall) and: [(site at: #isInterruptCheck) not]]! !

!OilDeoptMetadataReader methodsFor: 'records' stamp: 'cb 10/26/2026 19:45'!
interruptChecks
	"The sites of the interrupt checks of the loops: recorded like calls without a send, the frame being suspended in the
	 call of the interrupt check before the site's bytecode."
	^self sites select: [:site | (site at: #isCall) and: [site at: #isInterruptCheck]]! !

!OilDeoptMetadataReader methodsFor: 'records' stamp: 'cb 10/26/2026 14:30'!
contextsAtSite: site
	"The method -> pc associations of the activations a frame suspended at the call site site stands for, innermost first
	 (what Context>>contexts answers for such a frame)."
	| chain frameIndex frame pc |
	chain := OrderedCollection new.
	frameIndex := site at: #frameIndex.
	pc := (site at: #sitePC) + (site at: #sendSize ifAbsent: [0]).
	[frameIndex >= 0] whileTrue:
		[frame := self frameAt: frameIndex.
		 chain add: (frame at: #method) -> pc.
		 pc := frame at: #returnPC.
		 frameIndex := frame at: #parentFrame].
	^chain asArray! !

!OilDeoptMetadataReader methodsFor: 'printing' stamp: 'cb 10/26/2026 14:30'!
printOn: aStream
	aStream nextPutAll: 'OilDeoptMetadataReader('.
	self isValid ifFalse: [^aStream nextPutAll: 'invalid)'].
	aStream print: self rootMethod.
	receiverClass ifNotNil: [aStream nextPutAll: ' for '; print: receiverClass].
	aStream
		nextPutAll: ', '; print: self numFrames; nextPutAll: ' frames, ';
		print: self sites size; nextPutAll: ' sites, ';
		print: self numVObjs; nextPutAll: ' virtual objects, ';
		print: self deopts; nextPutAll: ' deopts)'! !

!CompiledMethod methodsFor: '*VMMaker-JIT-OilDebugging' stamp: 'cb 10/26/2026 14:30'!
oilMetadata
	"Copies of the deoptimization metadata of my Oil code: nil, or an Array of pairs { class or nil. metadata (a CompiledMethod) }
	 (see OilDeoptMetadataReader)."
	<primitive: 'primitiveOilMetadata'>
	^nil! !

!CompiledMethod methodsFor: '*VMMaker-JIT-OilDebugging' stamp: 'cb 10/26/2026 14:30'!
oilMetadataFor: aClass
	"The pair { class or nil. metadata } of my Oil code specialized for aClass (or of my own Oil code), or nil."
	<primitive: 'primitiveOilMetadata'>
	^nil! !

!Context methodsFor: 'debugger access' stamp: 'cb 10/26/2026 14:30'!
contexts
	"Answer the method -> pc associations of the activations I stand for, innermost first.  That is one, mine, unless I am
	 the context of the frame of a method compiled by the Oil optimizing JIT, which stands for the activations of the
	 methods and blocks it inlined at the call it is suspended in, and its own.  (Belongs to Kernel; see deoptimize.)"
	^(self oilContextChain ifNil: [^{self method -> self pc}])
		pairsCollect: [:method :pc | method -> pc]! !

!Context methodsFor: 'debugger access' stamp: 'cb 10/26/2026 14:30'!
oilContextChain
	"{ method. pc. method. pc ... }, innermost first, if I am married to the frame of an Oil method, else nil."
	<primitive: 'primitiveOilContexts'>
	^nil! !

!Context methodsFor: 'debugger access' stamp: 'cb 10/26/2026 14:30'!
deoptimize
	"If I am the context of the frame of a method compiled by the Oil optimizing JIT, replace the frame by real contexts
	 for the activations it stands for (see contexts), and answer the innermost: its sender chain leads to me, now the
	 context of the Oil method's activation.  Otherwise answer me.  (Belongs to Kernel: a debugger deoptimizes the
	 contexts it shows.)"
	<primitive: 'primitiveOilDeoptimize'>
	^self! !
