Class {
	#name : #LocalePluginSimulator,
	#superclass : #LocalePlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
LocalePluginSimulator class >> shouldBeTranslated [
	"This class should not be translated"
	^false
]

{ #category : #primitives }
LocalePluginSimulator >> primitiveTimezoneOffset [
	"return the number of minutes this VM's time value is offset from UTC
	For the simulation, use the same timezone as the simulator."

	interpreterProxy methodReturnInteger: (DateAndTime localTimeZone offset asSeconds / 60) rounded
]

{ #category : #simulation }
LocalePluginSimulator >> sqLocInitialize [

	^true
]
