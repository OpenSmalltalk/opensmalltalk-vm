Class {
	#name : #BaselineOfVMMaker,
	#superclass : #BaselineOf,
	#category : #BaselineOfVMMaker
}

{ #category : #baselines }
BaselineOfVMMaker >> baseline: spec [
	<baseline>
	spec
		for: #common
		do: [
			"Initial VMMaker package for handling Pharo 6" 
			spec
				package: 'VMMakerTests' with: [
					spec requires: 'VMMakerCompatibilityForPharo6' ].
			spec
				package: 'VMMakerCompatibilityForPharo6'
				with: [ spec requires: 'VMMaker' ];
				package: 'VMMakerLoadingDependencies'.
			
			"Dependencies from other repositories"
			spec
				package: 'SharedPool-Speech' with: [
					spec repository: 'http://www.squeaksource.com/Speech' ];
				package: 'MethodMassage' with: [
					spec repository: 'http://ss3.gemstone.com/ss/MethodMassage' ];
				package: 'MethodMassageCompatibility' with: [
					spec repository: 'http://ss3.gemstone.com/ss/MethodMassage' ];
				package: 'Printf' with: [
					spec repository: 'http://www.squeaksource.com/Printf' ].
				
			"Main VMMaker packages"	
			spec
				package: 'Balloon-Engine-Pools';
				package: 'BytecodeSets';
				package: 'VMMaker' with: [ spec requires: #( 'VMMakerLoadingDependencies' 'Printf') ];
				package: 'Cog';
				package: 'CogTools';
				package: 'ImageFormat'.
				
			"VMMaker plugins"
			spec
				package: 'VMConstruction-Plugins-AioPlugin' with: [
					spec repository: 'http://www.squeaksource.com/AioPlugin'];
				package: 'VMConstruction-Plugins-OSProcessPlugin' with: [
					spec 
						file: 'VMConstruction-Plugins-OSProcessPlugin.oscog';
						repository: 'http://www.squeaksource.com/OSProcessPlugin'];
				package: 'VMConstruction-Plugins-XDisplayControlPlugin' with: [
					spec repository: 'http://www.squeaksource.com/XDCP'];
				package: 'Balloon3D-Constants' with: [
					spec repository: 'http://www.squeaksource.com/Balloon3D'];
				package: 'Balloon3D-Plugins' with: [
					spec repository: 'http://www.squeaksource.com/Balloon3D'];		
				package: 'CryptographyPlugins' with: [
					spec repository: 'http://www.squeaksource.com/Cryptography'];
				package: 'FileAttributesPlugin' with: [
					spec 
						file: 'FileAttributesPlugin.oscog';
						repository: 'http://smalltalkhub.com/mc/Alistair/FileAttributesPlugin/main'].
				
			spec
				package: 'AndreasProfiler' with: [
					spec repository: 'http://ss3.gemstone.com/ss/AndreasSystemProfiler'].
			spec group: 'default' with: #('VMMaker' 'VMMakerTests') ]
]
