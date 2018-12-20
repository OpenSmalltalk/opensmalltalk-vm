World submorphs do:
	[:morph|
	morph class == PreferenceWizardMorph ifTrue:
		[morph delete]].

Smalltalk snapshot: true andQuit: true
