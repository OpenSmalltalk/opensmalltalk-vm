"
MemoryAccess defines the low level mapping of object memory addresses to the underlying machine address space. When implemented as Smalltalk methods, the generated C code
is available for debugging and profiling. The Squeak code generator inlines the methods
such that the resulting VM will have performance very similar to that obtained with
traditional C preprocessor macros or inlined static functions.

Methods are categorized and commented in order to clarify the type casting and memory
address translation.

MemoryAccess replaces the traditional external definitions in sqMemoryAccess.h:

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
	#classVars : [
		'Enabled'
	],
	#category : #MemoryAccess
}

{ #category : #translation }
MemoryAccess class >> declareCVarsIn: aCCodeGenerator [
	"Nothing to declare, but CCodeGenerator expects this method to exist."

]

{ #category : #'enable - disable' }
MemoryAccess class >> disable [
	"Use sqMemoryAccess.h macros or inline functions to provide low level object
	memory to machine memory mapping. This is the normal setting for most
	VM builders."

	"MemoryAccess disable"

	(VMMaker respondsTo: #clearCodeGeneratorCache)
		ifTrue: [VMMaker clearCodeGeneratorCache]. "SlangBrowser"
	Enabled := false
]

{ #category : #'enable - disable' }
MemoryAccess class >> enable [
	"Use class MemoryAccess to provide low level object memory to machine memory
	mapping. When enabled, the memory access will be provided by directly generated
	C code with inlining performed by the SLANG inliner. The generated code is
	not masked by the C preprocessor, and is therefore directly visible to C debuggers
	and profiling tools,"

	"MemoryAccess enable"

	(VMMaker respondsTo: #clearCodeGeneratorCache)
		ifTrue: [VMMaker clearCodeGeneratorCache]. "SlangBrowser"
	Enabled := true
]

{ #category : #'enable - disable' }
MemoryAccess class >> isEnabled [
	"Answer true if MemoryAccess should be translated to C, in which case
	its methods will be translated as replacements for the traditional C
	preprocessor macros in sqMemoryAccess.h."

	"MemoryAccess isEnabled"

	^ Enabled == true
]

{ #category : #'object memory access' }
MemoryAccess >> byteAt: oop [
	"Answer the byte at an object memory location. The result is a signed sqInt
	value in the range 0 through 255."

	"sqInt byteAt(sqInt oop) { return byteAtPointer(pointerForOop(oop)); }"

	self inline: true.
	^ self byteAtPointer: (self pointerForOop: oop)
]

{ #category : #'object memory access' }
MemoryAccess >> byteAt: oop put: val [
	"Cast a sqInt value to signed integer and store its low order byte at the given
	object memory location."

	"sqInt byteAtput(sqInt oop, int val) { return byteAtPointerput(pointerForOop(oop), val); }"

	self inline: true.
	self var: #val type: 'int'.
	^ self byteAtPointer: (self pointerForOop: oop) put: val
]

{ #category : #'map address to value' }
MemoryAccess >> byteAtPointer: ptr [
	"Answer the unsigned byte value at a machine address. The result is a signed
	sqInt value in the range 0 through 255."

	"sqInt byteAtPointer(char *ptr) { return (sqInt)(*((unsigned char *)ptr)) }"

	self inline: true.
	self var: #ptr type: 'char *'.
	^ self cCoerce:
			((self cCoerce: ptr to: 'unsigned char *') at: 0)
		to: 'sqInt'
]

{ #category : #'map address to value' }
MemoryAccess >> byteAtPointer: ptr put: val [
	"Cast a sqInt value to signed integer and store its low order byte at the given
	machine address."

	"sqInt byteAtPointerput(char *ptr, int val) { return (sqInt)(*((unsigned char *)ptr)= (unsigned char)val) }"

	self inline: true.
	self var: #ptr type: 'char *'.
	self var: #val type: 'int'.
	^ self cCoerce: ((self cCoerce: ptr to: 'unsigned char *')
				at: 0
				put: val)
		to: 'sqInt'
]

{ #category : #'object memory access' }
MemoryAccess >> intAt: oop [
	"Answer the unsigned integer value at an object memory location. The result
	is a signed sqInt value with binary value in the range 0 through 16rFFFFFFFF.
	If the size of sqInt is 8 bytes (64-bit object memory) and size of integer is 4, 
	then the high order 4 bytes of the result are zero."

	"sqInt intAt(sqInt oop) { return intAtPointer(pointerForOop(oop)); }"

	self inline: true.
	^ self intAtPointer: (self pointerForOop: oop)
]

{ #category : #'object memory access' }
MemoryAccess >> intAt: oop put: val [
	"Cast a sqInt value to unsigned integer and store its low order bytes at the given
	object memory location. Assuming that size of integer is 4, then four bytes are stored
	regardless of the size of sqInt (32-bit or 64-bit object memory)."

	"sqInt intAtput(sqInt oop, int val) { return intAtPointerput(pointerForOop(oop), val); }"

	self inline: true.
	self var: #val type: 'int'.
	^ self intAtPointer: (self pointerForOop: oop) put: val
]

{ #category : #'map address to value' }
MemoryAccess >> intAtPointer: ptr [
	"Answer the unsigned integer value at a machine address. The result is a signed
	sqInt value with binary value in the range 0 through 16rFFFFFFFF. If the
	size of sqInt is 8 bytes (64-bit object memory) and size of integer is 4, then the
	high order 4 bytes of the result are zero."

	"sqInt intAtPointer(char *ptr) { return (sqInt)(*((unsigned int *)ptr)) }"

	self inline: true.
	self var: #ptr type: 'char *'.
	^ self cCoerce:
			((self cCoerce: ptr to: 'unsigned int *') at: 0)
		to: 'sqInt'
]

{ #category : #'map address to value' }
MemoryAccess >> intAtPointer: ptr put: val [
	"Cast a sqInt value to unsigned integer and store its low order bytes at the given
	machine address. Assuming that size of integer is 4, then four bytes are stored
	regardless of the size of sqInt (32-bit or 64-bit object memory)."

	"sqInt intAtPointerput(char *ptr, int val) { return (sqInt)(*((unsigned int *)ptr)= (int)val) }"

	self inline: true.
	self var: #ptr type: 'char *'.
	self var: #val type: 'unsigned int'.
	^ self cCoerce:
			((self cCoerce: ptr to: 'unsigned int *')
				at: 0
				put: val)
		to: 'sqInt'
]

{ #category : #'object memory access' }
MemoryAccess >> long32At: ptr [
	"#define long32At intAt"

	self inline: true.
	^ self intAt: ptr

]

{ #category : #'object memory access' }
MemoryAccess >> long32At: ptr put: val [
	"#define long32Atput intAtput"

	self inline: true.
	self var: #val type: 'int'.
	^ self intAt: ptr put: val

]

{ #category : #'object memory access' }
MemoryAccess >> longAt: oop [
	"Answer the object memory word, an sqInt, located at an object memory location.
	In the original 32-bit object memory implemention, word size was equivalent
	to C type long. For 64-bit object memory, the method name may be misleading
	because the sqInt value is of C type long long."

	"sqInt longAt(sqInt oop) { return longAtPointer(pointerForOop(oop)); }"

	self inline: true.
	^ self longAtPointer: (self pointerForOop: oop)

]

{ #category : #'object memory access' }
MemoryAccess >> longAt: oop put: val [
	"Store an object memory word, an sqInt, at the given object memory location.
	In the original 32-bit object memory implemention, word size was equivalent
	to C type long. For 64-bit object memory, the method name may be misleading
	because the sqInt value is of C type long long."

	"sqInt longAtput(sqInt oop, sqInt val) { return longAtPointerput(pointerForOop(oop), val); }"

	self inline: true.
	^ self longAtPointer: (self pointerForOop: oop) put: val

]

{ #category : #'map address to value' }
MemoryAccess >> longAtPointer: ptr [
	"Answer the object memory word, an sqInt, located at a machine address.
	In the original 32-bit object memory implemention, word size was equivalent
	to C type long. For 64-bit object memory, the method name may be misleading
	because the sqInt value is of C type long long."

	"sqInt longAtPointer(char *ptr) { return (sqInt)(*((sqInt *)ptr)) }"

	self inline: true.
	self var: #ptr type: 'char *'.
	^ self cCoerce:
			((self cCoerce: ptr to: 'sqInt *') at: 0)
		to: 'sqInt'

]

{ #category : #'map address to value' }
MemoryAccess >> longAtPointer: ptr put: val [
	"Store an object memory word, an sqInt, at the given machine address.
	In the original 32-bit object memory implemention, word size was equivalent
	to C type long. For 64-bit object memory, the method name may be misleading
	because the sqInt value is of C type long long."

	"sqInt longAtPointerput(char *ptr, sqInt val) { return (sqInt)(*((sqInt *)ptr)= (sqInt)val) }"

	self inline: true.
	self var: #ptr type: 'char *'.
	^ self cCoerce: ((self cCoerce: ptr to: 'sqInt *')
				at: 0
				put: val)
		to: 'sqInt'
]

{ #category : #'object memory access' }
MemoryAccess >> oopAt: oop [
	"Answer the object memory word, an sqInt, located at an object memory location."

	"oopAt(sqInt oop) { return oopAtPointer(pointerForOop(oop)); }"

	self inline: true.
	^ self oopAtPointer: (self pointerForOop: oop)
]

{ #category : #'object memory access' }
MemoryAccess >> oopAt: oop put: val [
	"Store an object memory word, an sqInt, at the given object memory location."

	"sqInt oopAtput(sqInt oop, sqInt val) { return oopAtPointerput(pointerForOop(oop), val); }"

	self inline: true.
	^ self oopAtPointer: (self pointerForOop: oop) put: val
]

{ #category : #'map address to value' }
MemoryAccess >> oopAtPointer: ptr [
	"Answer the object memory word, an sqInt, located at a machine address."

	"sqInt oopAtPointer(char *ptr) { return (sqInt)(*((sqInt *)ptr)) }"

	self inline: true.
	self var: #ptr type: 'char *'.
	^ (self cCoerce: ptr to: 'sqInt *') at: 0
]

{ #category : #'map address to value' }
MemoryAccess >> oopAtPointer: ptr put: val [
	"Store an object memory word, an sqInt, at the given machine address."

	"sqInt oopAtPointerput(char *ptr, sqInt val) { return (sqInt)(*((sqInt *)ptr)= (sqInt)val) }"

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
	"Answer the machine address of the object to which oop refers. This method maps
	object memory locations to their underlying machine addresses (C pointers).

	char *pointerForOop(usqInt oop) { return sqMemoryBase + oop; }"

	self inline: true.
	self returnTypeC: 'char *'.
	self var: #oop type: 'usqInt'.
	^ self sqMemoryBaseAddress + oop
]

{ #category : #'object memory access' }
MemoryAccess >> shortAt: oop [
	"Answer the signed short integer value at an object memory location. The
	result is a signed sqInt value. Negative values will be sign extended, such
	that if the short integer value is binary 16rFFFF, the result will be 16rFFFFFFFF
	for a 32-bit object memory, or 16rFFFFFFFFFFFFFFFF for a 64-bit object memory."

	"sqInt shortAt(sqInt oop) { return shortAtPointer(pointerForOop(oop)); }"

	self inline: true.
	^ self shortAtPointer: (self pointerForOop: oop)
]

{ #category : #'object memory access' }
MemoryAccess >> shortAt: oop put: val [
	"Cast a sqInt value to signed short integer and store its low order bytes at the
	given object memory location. Assuming that size of a short integer is 2, then two
	bytes are stored regardless of the size of sqInt (32-bit or 64-bit object memory)."

	"sqInt shortAtput(sqInt oop, int val){ return shortAtPointerput(pointerForOop(oop), val); }"

	self inline: true.
	self var: #val type: 'int'.
	^ self shortAtPointer: (self pointerForOop: oop) put: val
]

{ #category : #'map address to value' }
MemoryAccess >> shortAtPointer: ptr [ 
	"Answer the signed short integer value at a machine address. The result is a
	signed sqInt value. Negative values will be sign extended, such that if the
	short integer value is binary 16rFFFF, the result will be 16rFFFFFFFF for a 32-bit
	object memory, or 16rFFFFFFFFFFFFFFFF for a 64-bit object memory."

	"sqInt shortAtPointer(char *ptr) { return (sqInt)(*((short *)ptr)) }"

	self inline: true.
	self var: #ptr type: 'char *'.
	^ self cCoerce: ((self cCoerce: ptr to: 'short *') at: 0)
		to: 'sqInt'
]

{ #category : #'map address to value' }
MemoryAccess >> shortAtPointer: ptr put: val [
	"Cast a sqInt value to signed short integer and store its low order bytes at the
	given machine address. Assuming that size of a short integer is 2, then two
	bytes are stored regardless of the size of sqInt (32-bit or 64-bit object memory)."

	"sqInt shortAtPointerput(char *ptr, int val) { return (sqInt)(*((short *)ptr)= (short)val) }"

	self inline: true.
	self var: #ptr type: 'char *'.
	self var: # val type: 'int'.
	^ self cCoerce:
			((self cCoerce: ptr to: 'short *')
				at: 0
				put: (self cCoerce: val to: 'short'))
		to: 'sqInt'
]

{ #category : #'map address to value' }
MemoryAccess >> shortUnsignedAtPointer: ptr [ 
	"Answer the unsigned short integer value at a machine address. The result
	is a signed sqInt value with value in the range 0 through 16rFFFF, assuming
	that size of short integer is 2."

	"sqInt shortUnsignedAtPointer(char *ptr) { return (sqInt)(*((unsigned short *)ptr)) }"

	self inline: true.
	self var: #ptr type: 'char *'.
	^ self cCoerce: ((self cCoerce: ptr to: 'unsigned short *') at: 0)
		to: 'sqInt'
]

{ #category : #'memory mapping' }
MemoryAccess >> sqMemoryBaseAddress [
	"Answer the machine address of the start of object memory."

	self inline: true.
	self returnTypeC: 'char *'.
	^ self cCode: 'sqMemoryBase'

]
