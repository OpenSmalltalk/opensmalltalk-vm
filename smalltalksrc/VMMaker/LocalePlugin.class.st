"
LocalePlugin provides access to some localization info.
primLanguage - returns a string describing the language in use as per ISO 639
primCountry - returns a string with country tag as per ISO 639
primVMOffsetToUTC - returns offset from UTC to time as provided by the VM. integer of minutes to allow for those odd places with halkf-hour offeset.
primTimeZone - returns UTC offset (? why two?)
primDST - returns boolean to indicate DST in use
primDecimalSymbol - return string with '.' or ',' etc
primDigitGrouping - return string with ',' or '.' etc for thousands type separation
primTimeFormat - return string with time dispaly format string - eg 'hh:mm:ss' etc
primLongDateFOrmat - return string with long date formatting - eg 'dd/mm/yyyy'
primShortDateFOrmat - similar but shortform
primCurrencySymbol - return string of currency name
primCurrencyNotation - return boolean for pre or postfix currency symbol
primMeasurement - return boolean for imperial or metric


"
Class {
	#name : #LocalePlugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
LocalePlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
LocalePlugin class >> requiresPlatformFiles [
	"this plugin requires platform specific files in order to work"
	^true
]

{ #category : #initialize }
LocalePlugin >> initialiseModule [
	<export: true>
	^self sqLocInitialize
]

{ #category : #'system primitives' }
LocalePlugin >> primitiveCountry [
	"return a 3 char string describing the country in use. ISO 3166 is the relevant source here; see http://www.unicode.org/onlinedat/countries.html for details. Using the 3 character Alpha-3 codes"
	| oop |
	self primitive:'primitiveCountry'.
	oop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: 3.
	self sqLocGetCountryInto: (interpreterProxy firstIndexableField: oop).
	^oop

]

{ #category : #'system primitives' }
LocalePlugin >> primitiveCurrencyNotation [
	"return a boolean specifying whether the currency symbol is pre or post fix. true -> pre"
	self primitive:'primitiveCurrencyNotation'.
	^self sqLocCurrencyNotation asOop: Boolean
]

{ #category : #'system primitives' }
LocalePlugin >> primitiveCurrencySymbol [
	"return a string describing the currency symbol used 
Still need to find details on standard symbols - ISO 4217 is supposed to be it but cannot find on web"
	| oop length |
	self primitive:'primitiveCurrencySymbol'.
	length := self sqLocCurrencySymbolSize.
	oop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: length.
	self sqLocGetCurrencySymbolInto: (interpreterProxy firstIndexableField: oop).
	^oop

]

{ #category : #'system primitives' }
LocalePlugin >> primitiveDaylightSavings [
	"return a boolean specifying the DST setting. true -> active"
	self primitive:'primitiveDaylightSavings'.
	^self sqLocDaylightSavings asOop: Boolean
]

{ #category : #'system primitives' }
LocalePlugin >> primitiveDecimalSymbol [
	"return a 1 char string describing the decimal symbol used - usually a . or a ,"
	| oop |
	self primitive:'primitiveDecimalSymbol'.
	oop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: 1.
	self sqLocGetDecimalSymbolInto: (interpreterProxy firstIndexableField: oop).
	^oop

]

{ #category : #'system primitives' }
LocalePlugin >> primitiveDigitGroupingSymbol [
	"return a 1 char string describing the digitGrouping symbol used - usually a . or a , between triples of digits"
	| oop |
	self primitive:'primitiveDigitGroupingSymbol'.
	oop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: 1.
	self sqLocGetDigitGroupingSymbolInto: (interpreterProxy firstIndexableField: oop).
	^oop

]

{ #category : #'system primitives' }
LocalePlugin >> primitiveLanguage [
	"return a 3 char string describing the language in use. ISO 639 is the relevant source here; see http://www.w3.org/WAI/ER/IG/ert/iso639.html for details"
	| oop |
	self primitive:'primitiveLanguage'.
	oop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: 3.
	self sqLocGetLanguageInto: (interpreterProxy firstIndexableField: oop).
	^oop

]

{ #category : #'system primitives' }
LocalePlugin >> primitiveLongDateFormat [
	"return a string describing the long date formatting.
Format is made up of
d day, m month, y year,
double symbol is null padded, single not padded (m=6, mm=06)
dddd weekday
mmmm month name
"
	| oop length |
	self primitive:'primitiveLongDateFormat'.
	length := self sqLocLongDateFormatSize.
	oop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: length.
	self sqLocGetLongDateFormatInto: (interpreterProxy firstIndexableField: oop).
	^oop

]

{ #category : #'system primitives' }
LocalePlugin >> primitiveMeasurementMetric [
	"return a boolean specifying whether the currency symbol is pre or post fix. true -> pre"
	self primitive:'primitiveMeasurementMetric'.
	^self sqLocMeasurementMetric asOop: Boolean
]

{ #category : #'system primitives' }
LocalePlugin >> primitiveShortDateFormat [
	"return a string describing the long date formatting.
Format is made up of
d day, m month, y year,
double symbol is null padded, single not padded (m=6, mm=06)
dddd weekday
mmmm month name
"
	| oop length |
	self primitive:'primitiveShortDateFormat'.
	length := self sqLocShortDateFormatSize.
	oop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: length.
	self sqLocGetShortDateFormatInto: (interpreterProxy firstIndexableField: oop).
	^oop

]

{ #category : #'system primitives' }
LocalePlugin >> primitiveTimeFormat [
	"return a string describing the time formatting.
Format is made up of
h hour (h 12, H 24), m minute, s seconds, x (am/pm String)
double symbol is null padded, single not padded (h=6, hh=06)"
	| oop length |
	self primitive:'primitiveTimeFormat'.
	length := self sqLocTimeFormatSize.
	oop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: length.
	self sqLocGetTimeFormatInto: (interpreterProxy firstIndexableField: oop).
	^oop

]

{ #category : #'system primitives' }
LocalePlugin >> primitiveTimezoneOffset [
	"return the number of minutes this VM's time value is offset from UTC"

	self primitive:'primitiveTimezoneOffset'.
	^self sqLocGetTimezoneOffset asSmallIntegerObj

]

{ #category : #'system primitives' }
LocalePlugin >> primitiveVMOffsetToUTC [
	"return the number of minutes this VM's time value is offset from UTC"

	self primitive:'primitiveVMOffsetToUTC'.
	^self sqLocGetVMOffsetToUTC asSmallIntegerObj

]
