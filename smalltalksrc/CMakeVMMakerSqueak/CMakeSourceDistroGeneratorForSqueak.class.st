"
A CMakeSourceDistroGeneratorForSqueak does nothing at the moment.  Here is why I am here (2014.06.16 vm-dev list):


Hi Bert
Linux distros never package binaries compiled by someone else (*). What they need is a source tar ball that builds cleanly, and a list of dependencies.

hmmmm....

CMakeVMMaker has a CMakePluginGenerator and CMakeVMGenerator; I have a hunch a CMakeSourceDistroGenerator would fit right in.


The Design of CMakeVMaker is a big-ole Visitor pattern where configurations visit the Generators. We should be able to have them visit a CMakeSourceDistroGenerator and provide it
with the relevant information.

I will put in a stub-class for it as a reminder to look at when release 1 of this puppy is ready.


cheers.

tty

"
Class {
	#name : #CMakeSourceDistroGeneratorForSqueak,
	#superclass : #CMakeGenerator,
	#category : #CMakeVMMakerSqueak
}
