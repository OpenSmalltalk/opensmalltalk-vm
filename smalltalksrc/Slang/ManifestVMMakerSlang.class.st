"
I store metadata for this package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : #ManifestVMMakerSlang,
	#superclass : #PackageManifest,
	#category : #'Slang-Manifest'
}

{ #category : #'meta-data - dependency analyser' }
ManifestVMMakerSlang class >> manuallyResolvedDependencies [
	^ #(#'FileSystem-Core' #'Collections-Abstract')
]
