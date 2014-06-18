Class {
	#name : #CMakeVMMakerSqueakServiceProvider,
	#superclass : #ServiceProvider,
	#category : #CMakeVMMakerSqueak
}

{ #category : #initialization }
CMakeVMMakerSqueakServiceProvider class >> initialize [ 
	ServiceRegistry buildProvider: self new
]
