"
MemoryAccess defines the low level mapping of object memory addresses to the underlying machine address space.

This is intended to replace the traditional external definitions in sqMemoryAccess.h:

#ifdef USE_INLINE_MEMORY_ACCESSORS
  /* Use static inline functions when the compiler produces efficient code for small accessors.
     These are preferred because static type checking will prevent inadvertent confusion of pointers and oops. */
  static inline sqInt byteAtPointer(char *ptr)			{ return (sqInt)(*((unsigned char *)ptr)); }
  static inline sqInt byteAtPointerput(char *ptr, int val)	{ return (sqInt)(*((unsigned char *)ptr)= (unsigned char)val); }
  static inline sqInt shortAtPointer(char *ptr)			{ return (sqInt)(*((short *)ptr)); }
  static inline sqInt shortAtPointerput(char *ptr, int val)	{ return (sqInt)(*((short *)ptr)= (short)val); }
  static inline sqInt intAtPointer(char *ptr)			{ return (sqInt)(*((unsigned int *)ptr)); }
  static inline sqInt intAtPointerput(char *ptr, int val)	{ return (sqInt)(*((unsigned int *)ptr)= (int)val); }
  static inline sqInt longAtPointer(char *ptr)			{ return (sqInt)(*((sqInt *)ptr)); }
  static inline sqInt longAtPointerput(char *ptr, sqInt val)	{ return (sqInt)(*((sqInt *)ptr)= (sqInt)val); }
  static inline sqInt oopAtPointer(char *ptr)			{ return (sqInt)(*((sqInt *)ptr)); }
  static inline sqInt oopAtPointerput(char *ptr, sqInt val)	{ return (sqInt)(*((sqInt *)ptr)= (sqInt)val); }
  static inline char *pointerForOop(usqInt oop)			{ return sqMemoryBase + oop; }
  static inline sqInt oopForPointer(char *ptr)			{ return (sqInt)(ptr - sqMemoryBase); }
  static inline sqInt byteAt(sqInt oop)				{ return byteAtPointer(pointerForOop(oop)); }
  static inline sqInt byteAtput(sqInt oop, int val)		{ return byteAtPointerput(pointerForOop(oop), val); }
  static inline sqInt shortAt(sqInt oop)			{ return shortAtPointer(pointerForOop(oop)); }
  static inline sqInt shortAtput(sqInt oop, int val)		{ return shortAtPointerput(pointerForOop(oop), val); }
  static inline sqInt intAt(sqInt oop)				{ return intAtPointer(pointerForOop(oop)); }
  static inline sqInt intAtput(sqInt oop, int val)		{ return intAtPointerput(pointerForOop(oop), val); }
  static inline sqInt longAt(sqInt oop)				{ return longAtPointer(pointerForOop(oop)); }
  static inline sqInt longAtput(sqInt oop, sqInt val)		{ return longAtPointerput(pointerForOop(oop), val); }
  static inline sqInt oopAt(sqInt oop)				{ return oopAtPointer(pointerForOop(oop)); }
  static inline sqInt oopAtput(sqInt oop, sqInt val)		{ return oopAtPointerput(pointerForOop(oop), val); }
#else
  /* Use macros when static inline functions aren't efficient. */
# define byteAtPointer(ptr)		((sqInt)(*((unsigned char *)(ptr))))
# define byteAtPointerput(ptr, val)	((sqInt)(*((unsigned char *)(ptr))= (unsigned char)(val)))
# define shortAtPointer(ptr)		((sqInt)(*((short *)(ptr))))
# define shortAtPointerput(ptr, val)	((sqInt)(*((short *)(ptr))= (short)(val)))
# define intAtPointer(ptr)		((sqInt)(*((unsigned int *)(ptr))))
# define intAtPointerput(ptr, val)	((sqInt)(*((unsigned int *)(ptr))= (int)(val)))
# define longAtPointer(ptr)		((sqInt)(*((sqInt *)(ptr))))
# define longAtPointerput(ptr, val)	((sqInt)(*((sqInt *)(ptr))= (sqInt)(val)))
# define oopAtPointer(ptr)		(sqInt)(*((sqInt *)ptr))
# define oopAtPointerput(ptr, val)	(sqInt)(*((sqInt *)ptr)= (sqInt)val)
# define pointerForOop(oop)		((char *)(sqMemoryBase + ((usqInt)(oop))))
# define oopForPointer(ptr)		((sqInt)(((char *)(ptr)) - (sqMemoryBase)))
# define byteAt(oop)			byteAtPointer(pointerForOop(oop))
# define byteAtput(oop, val)		byteAtPointerput(pointerForOop(oop), (val))
# define shortAt(oop)			shortAtPointer(pointerForOop(oop))
# define shortAtput(oop, val)		shortAtPointerput(pointerForOop(oop), (val))
# define longAt(oop)			longAtPointer(pointerForOop(oop))
# define longAtput(oop, val)		longAtPointerput(pointerForOop(oop), (val))
# define intAt(oop)			intAtPointer(pointerForOop(oop))
# define intAtput(oop, val)		intAtPointerput(pointerForOop(oop), (val))
# define oopAt(oop)			oopAtPointer(pointerForOop(oop))
# define oopAtput(oop, val)		oopAtPointerput(pointerForOop(oop), (val))
#endif


"
Class {
	#name : #MemoryAccess,
	#superclass : #Object,
	#category : #MemoryAccess
}

{ #category : #translation }
MemoryAccess class >> asCString [
	"Answer the translated C source for this class."

	"Interpreter asCString"
	"ObjectMemory asCString"

	| vmm cg stream |
	(Smalltalk hasClassNamed: 'VMMaker')
		ifTrue: [vmm := Smalltalk at: #VMMaker]
		ifFalse: [^ self notify: 'VMMaker not in this image'].
	cg := vmm codeGenerator: #cCode forClass: self.
	stream := ReadWriteStream on: ''.
	cg emitCCodeOn: stream doAssertions: true.
	cg emitExportsOn: stream.
	^ stream contents

]

{ #category : #translation }
MemoryAccess class >> asCString: aSelector [
	"Answer the translated C source for a method."

	"Interpreter asCString: #bytecodePrimBlockCopy"
	"ObjectMemory asCString: #lastPointerOf:"

	| vmm cg method stream |
	(Smalltalk hasClassNamed: 'VMMaker')
		ifTrue: [vmm := Smalltalk at: #VMMaker]
		ifFalse: [^ self notify: 'VMMaker not in this image'].
	cg := vmm codeGenerator: #cCode forClass: self.
	cg isString ifTrue:
		[^ '/* Simulator subclasses with method overrides should not be translated. */',
			String cr, '/* ', cg, ' */'].
	method := cg methodNamed: aSelector.
	method ifNil: [^ self methodNotTranslatedMessage: aSelector].
	stream := ReadWriteStream on: ''.
	method emitCCodeOn: stream generator: cg.
	^ stream contents

]

{ #category : #translation }
MemoryAccess class >> asInlinedCString: aSelector [
	"Answer the translated Inlined C source for a method."

	"Interpreter asCString: #bytecodePrimBlockCopy"
	"ObjectMemory asCString: #lastPointerOf:"

	| vmm cg method stream |
	(Smalltalk hasClassNamed: 'VMMaker')
		ifTrue: [vmm := Smalltalk at: #VMMaker]
		ifFalse: [^ self notify: 'VMMaker not in this image'].
	cg := vmm codeGenerator: #inlinedCCode forClass: self.
	cg isString ifTrue:
		[^ '/* Simulator subclasses with method overrides should not be translated. */',
			String cr, '/* ', cg, ' */'].
	method := cg methodNamed: aSelector.
	method ifNil: [^ self methodNotTranslatedMessage: aSelector].
	stream := ReadWriteStream on: ''.
	method emitCCodeOn: stream generator: cg.
	^ stream contents

]

{ #category : #translation }
MemoryAccess class >> declareCVarsIn: aCCodeGenerator [
	"Nothing to declare, but CCodeGenerator expects this method to exist."

]

{ #category : #'enable - disable' }
MemoryAccess class >> disable [
	"Use sqMemoryAccess.h macros or inline functions to provide low level object memory to machine memory mapping. This is the normal setting for most VM builders."

	"MemoryAccess disable"

	| copyOfInterpreterPlugin copyOfObjectMemory |
	copyOfInterpreterPlugin := InterpreterPlugin copy.
	copyOfObjectMemory := ObjectMemory copy.

	InterpreterPlugin superclass: Object.
	Object addSubclass: InterpreterPlugin.
	MemoryAccess removeSubclass: InterpreterPlugin.

	ObjectMemory superclass: Object.
	Object addSubclass: ObjectMemory.
	MemoryAccess removeSubclass: ObjectMemory.

	SystemChangeNotifier uniqueInstance
		classDefinitionChangedFrom: copyOfInterpreterPlugin
		to: InterpreterPlugin.
	SystemChangeNotifier uniqueInstance
		classDefinitionChangedFrom: copyOfObjectMemory
		to: ObjectMemory.

	^ ObjectMemory superclass

]

{ #category : #'enable - disable' }
MemoryAccess class >> enable [
	"Use class MemoryAccess to provide low level object memory to machine memory
	mapping. When enabled, the memory access will be provided by directly generated
	C code with inlining performed by the SLANG inliner. The generated code is
	not masked by the C preprocessor, and is therefore directly visible to C debuggers
	and profiling tools,"

	"MemoryAccess enable"

	| copyOfInterpreterPlugin copyOfObjectMemory |
	copyOfInterpreterPlugin := InterpreterPlugin copy.
	copyOfObjectMemory := ObjectMemory copy.

	InterpreterPlugin superclass: MemoryAccess.
	MemoryAccess addSubclass: InterpreterPlugin.
	Object removeSubclass: InterpreterPlugin.

	ObjectMemory superclass: MemoryAccess.
	MemoryAccess addSubclass: ObjectMemory.
	Object removeSubclass: ObjectMemory.

	SystemChangeNotifier uniqueInstance
		classDefinitionChangedFrom: copyOfInterpreterPlugin
		to: InterpreterPlugin.
	SystemChangeNotifier uniqueInstance
		classDefinitionChangedFrom: copyOfObjectMemory
		to: ObjectMemory.

	^ ObjectMemory superclass

]

{ #category : #'enable - disable' }
MemoryAccess class >> isEnabled [
	"Answer true if MemoryAccess is the superclass of ObjectMemory, in which
	case its methods will be translated as replacements for the traditional C
	preprocessor macros in sqMemoryAccess.h."

	"MemoryAccess isEnabled"

	^ ObjectMemory superclass == self
]

{ #category : #translation }
MemoryAccess class >> requiredMethodNames [
	"return the list of method names that should be retained for export or other support reasons"
	^ #(oopForPointer: pointerForOop: oopAt:)
]

{ #category : #'memory mapping' }
MemoryAccess >> byteAt: oop [
	"sqInt byteAt(sqInt oop) { return byteAtPointer(pointerForOop(oop)); }"

	self inline: true.
	^ self byteAtPointer: (self pointerForOop: oop)
]

{ #category : #'memory mapping' }
MemoryAccess >> byteAt: oop put: val [
	"sqInt byteAtput(sqInt oop, int val) { return byteAtPointerput(pointerForOop(oop), val); }"

	self inline: true.
	self var: #val type: 'int'.
	^ self byteAtPointer: (self pointerForOop: oop) put: val
]

{ #category : #'memory mapping' }
MemoryAccess >> byteAtPointer: ptr [
	"sqInt byteAtPointer(char *ptr) { return (sqInt)(*((unsigned char *)ptr))"

	self inline: true.
	self var: #ptr type: 'char *'.
	^ self cCoerce:
			((self cCoerce: ptr to: 'unsigned char *') at: 0)
		to: 'sqInt'
]

{ #category : #'memory mapping' }
MemoryAccess >> byteAtPointer: ptr put: val [
	"sqInt byteAtPointerput(char *ptr, int val) { return (sqInt)(*((unsigned char *)ptr)= (unsigned char)val)"

	self inline: true.
	self var: #ptr type: 'char *'.
	self var: #val type: 'int'.
	^ self cCoerce: ((self cCoerce: ptr to: 'unsigned char *')
				at: 0
				put: val)
		to: 'sqInt'
]

{ #category : #'memory mapping' }
MemoryAccess >> intAt: oop [
	"static inline sqInt intAt(sqInt oop) { return intAtPointer(pointerForOop(oop)); }"

	self inline: true.
	^ self intAtPointer: (self pointerForOop: oop)
]

{ #category : #'memory mapping' }
MemoryAccess >> intAt: oop put: val [
	"sqInt intAtput(sqInt oop, int val) { return intAtPointerput(pointerForOop(oop), val); }"

	self inline: true.
	self var: #val type: 'int'.
	^ self intAtPointer: (self pointerForOop: oop) put: val
]

{ #category : #'memory mapping' }
MemoryAccess >> intAtPointer: ptr [
	"sqInt intAtPointer(char *ptr) { return (sqInt)(*((unsigned int *)ptr))"

	self inline: true.
	self var: #ptr type: 'char *'.
	^ self cCoerce:
			((self cCoerce: ptr to: 'unsigned int *') at: 0)
		to: 'sqInt'
]

{ #category : #'memory mapping' }
MemoryAccess >> intAtPointer: ptr put: val [
	"sqInt intAtPointerput(char *ptr, int val) { return (sqInt)(*((unsigned int *)ptr)= (int)val)"

	self inline: true.
	self var: #ptr type: 'char *'.
	self var: #val type: 'unsigned int'.
	^ self cCoerce:
			((self cCoerce: ptr to: 'unsigned int *')
				at: 0
				put: val)
		to: 'sqInt'
]

{ #category : #'memory mapping' }
MemoryAccess >> long32At: ptr [
	"#define long32At intAt"

	self inline: true.
	^ self intAt: ptr

]

{ #category : #'memory mapping' }
MemoryAccess >> long32At: ptr put: val [
	"#define long32Atput intAtput"

	self inline: true.
	self var: #val type: 'int'.
	^ self intAt: ptr put: val

]

{ #category : #'memory mapping' }
MemoryAccess >> longAt: oop [
	"sqInt longAt(sqInt oop) { return longAtPointer(pointerForOop(oop)); }"

	self inline: true.
	^ self longAtPointer: (self pointerForOop: oop)

]

{ #category : #'memory mapping' }
MemoryAccess >> longAt: oop put: val [
	"sqInt longAtput(sqInt oop, sqInt val) { return longAtPointerput(pointerForOop(oop), val); }"

	self inline: true.
	^ self longAtPointer: (self pointerForOop: oop) put: val

]

{ #category : #'memory mapping' }
MemoryAccess >> longAtPointer: ptr [
	"sqInt longAtPointer(char *ptr) { return (sqInt)(*((sqInt *)ptr))"

	self inline: true.
	self var: #ptr type: 'char *'.
	^ self cCoerce:
			((self cCoerce: ptr to: 'sqInt *') at: 0)
		to: 'sqInt'

]

{ #category : #'memory mapping' }
MemoryAccess >> longAtPointer: ptr put: val [
	"sqInt longAtPointerput(char *ptr, sqInt val) { return (sqInt)(*((sqInt *)ptr)= (sqInt)val)"

	self inline: true.
	self var: #ptr type: 'char *'.
	^ self cCoerce: ((self cCoerce: ptr to: 'sqInt *')
				at: 0
				put: val)
		to: 'sqInt'
]

{ #category : #'memory mapping' }
MemoryAccess >> oopAt: oop [
	"oopAt(sqInt oop) { return oopAtPointer(pointerForOop(oop)); }"

	self inline: true.
	^ self oopAtPointer: (self pointerForOop: oop)
]

{ #category : #'memory mapping' }
MemoryAccess >> oopAt: oop put: val [
	"sqInt oopAtput(sqInt oop, sqInt val) { return oopAtPointerput(pointerForOop(oop), val); }"

	self inline: true.
	^ self oopAtPointer: (self pointerForOop: oop) put: val
]

{ #category : #'memory mapping' }
MemoryAccess >> oopAtPointer: ptr [
	"sqInt oopAtPointer(char *ptr) { return (sqInt)(*((sqInt *)ptr))"

	self inline: true.
	self var: #ptr type: 'char *'.
	^ (self cCoerce: ptr to: 'sqInt *') at: 0
]

{ #category : #'memory mapping' }
MemoryAccess >> oopAtPointer: ptr put: val [
	"sqInt oopAtPointerput(char *ptr, sqInt val) { return (sqInt)(*((sqInt *)ptr)= (sqInt)val)"

	self inline: true.
	self var: #ptr type: 'char *'.
	^ (self cCoerce: ptr to: 'sqInt *') at: 0 put: val
]

{ #category : #'memory mapping' }
MemoryAccess >> oopForPointer: ptr [
	"Answer the oop located at ptr, a machine address. This method maps
	machine addresses (C pointers) to object memory locations.

	sqInt oopForPointer(char *ptr) { return (sqInt)(ptr - sqMemoryBase); }"

	self inline: true.
	self returnTypeC: 'usqInt'.
	self var: #ptr type: 'char *'.
	^ self cCoerce: ptr - self sqMemoryBaseAddress to: 'usqInt'
]

{ #category : #'memory mapping' }
MemoryAccess >> pointerForOop: oop [
	"Answer the machine address at which an oop is located. This method maps
	object memory locations to their underlying machine addresses (C pointers).

	char *pointerForOop(usqInt oop) { return sqMemoryBase + oop; }"

	self inline: true.
	self returnTypeC: 'char *'.
	self var: #oop type: 'usqInt'.
	^ self sqMemoryBaseAddress + oop
]

{ #category : #'memory mapping' }
MemoryAccess >> shortAt: oop [
	"sqInt shortAt(sqInt oop) { return shortAtPointer(pointerForOop(oop)); }"

	self inline: true.
	^ self shortAtPointer: (self pointerForOop: oop)
]

{ #category : #'memory mapping' }
MemoryAccess >> shortAt: oop put: val [
	"sqInt shortAtput(sqInt oop, int val){ return shortAtPointerput(pointerForOop(oop), val); }"

	self inline: true.
	self var: #val type: 'int'.
	^ self shortAtPointer: (self pointerForOop: oop) put: val
]

{ #category : #'memory mapping' }
MemoryAccess >> shortAtPointer: ptr [ 
	"sqInt shortAtPointer(char *ptr) { return (sqInt)(*((short *)ptr))"

	self inline: true.
	self var: #ptr type: 'char *'.
	^ self cCoerce: ((self cCoerce: ptr to: 'short *') at: 0)
		to: 'sqInt'
]

{ #category : #'memory mapping' }
MemoryAccess >> shortAtPointer: ptr put: val [
	"sqInt shortAtPointerput(char *ptr, int val) { return (sqInt)(*((short *)ptr)= (short)val)"

	self inline: true.
	self var: #ptr type: 'char *'.
	self var: # val type: 'int'.
	^ self cCoerce:
			((self cCoerce: ptr to: 'short *')
				at: 0
				put: (self cCoerce: val to: 'short'))
		to: 'sqInt'
]

{ #category : #'memory mapping' }
MemoryAccess >> sqMemoryBaseAddress [
	"Answer the machine address of the start of object memory."

	self inline: true.
	self returnTypeC: 'char *'.
	^ self cCode: 'sqMemoryBase'

]
