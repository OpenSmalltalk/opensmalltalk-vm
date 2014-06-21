"
A CMakeGeneratorForSqueak extends CMakeGenerator to support some Squeak-isms.


Instance Variables

"
Class {
	#name : #CMakeGeneratorForSqueak,
	#superclass : #CMakeGenerator,
	#category : #CMakeVMMakerSqueak
}

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> cC: aString [
	"do nothing at the moment.
	When we start generating config.h, we need to pass it flags as per this line from an mvm
       CC=''gcc -m32''

	This is supported in compilerFlags on pharo cmake, but for ease-of-use for newbies, its best to make things clear with an intention revealing method name

	CMakeVMGenerator calls 	self addDefinitions: config compilerFlags.
"
	self flag:'tty'
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> cXX: aString [
	"do nothing at the moment.
	When we start generating config.h, we need to pass it flags as per this line from an mvm
	 CXX=''g++ -m32''

	This is supported in compilerFlags on pharo cmake, but for ease-of-use for newbies, its best to make things clear with an intention revealing method name

	CMakeVMGenerator calls 	self addDefinitions: config compilerFlags.
"
	self flag:'tty'
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> configureFlags: aString [
	"do nothing at the moment.
	When we start generating config.h, we need to pass it flags as per this line from an mvm
	test -f config.h || ../../../platforms/unix/config/configure \
 	       --with-src=stacksrc --with-plugins=src/plugins --disable-cogit \
  	      --without-vm-display-fbdev --without-npsqueak \


	if cmake supports a command for doing configs, then 
	^self cmd: 'the cmake command here' params: aString
"
	self flag:'tty'
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> lDFlags: aString [
	"do nothing at the moment.
	When we start generating config.h, we need to pass it flags as per this line from an mvm
	  LDFLAGS=-Wl,-z,now

	currently this resides in CPlatformConfig linkFlags. I want to move this to an intention revealing method name
"
	self flag:'tty'
]

{ #category : #'cmake commands' }
CMakeGeneratorForSqueak >> libs: aString [
	"do nothing at the moment.
	When we start generating config.h, we need to pass it flags as per this line from an mvm

        LIBS=''-lpthread -luuid -lSM -lICE -ldl -lGL -lpthread -lm -lnsl -lX11'' 

	currently this resides in CPlatformConfig linkFlags. I want to move this to an intention revealing method name

for example, we see it in:
	extraPluginSettings: maker
		super extraPluginSettings: maker.  
		maker set: #linkFlags toString: '${linkFlags} -m32'
	
"
	self flag:'tty'
]
