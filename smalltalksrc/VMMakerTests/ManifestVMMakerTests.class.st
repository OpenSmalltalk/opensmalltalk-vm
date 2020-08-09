"
I store metadata for this package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : #ManifestVMMakerTests,
	#superclass : #PackageManifest,
	#category : #'VMMakerTests-Manifest'
}

{ #category : #'code-critics' }
ManifestVMMakerTests class >> ruleUncommonMessageSendRuleV1FalsePositive [
	^ #(#(#(#RGPackageDefinition #(#VMMakerTests)) #'2020-07-24T12:05:44.86595+02:00') )
]
