"
A SqueakCMakeSourceDistroBuilder does nothing.

However, there is a need to create Source Packages for the Linux Package maintainers: Ubuntu, Slackware, SunOS, RedHat, Debain..etc

The CMakeVMMaker Design Pattern (essentially a Visitor pattern kicked off by Builders) would be spot on for this task.

I will address this when I am done with the VMGenerator.

tty. 2014.06.17
"
Class {
	#name : #SqueakCMakeSourceDistroBuilder,
	#superclass : #Object,
	#instVars : [
		'buildTypeAndDirectoryInfo',
		'config'
	],
	#category : #'CMakeVMMakerSqueak-Builder'
}
