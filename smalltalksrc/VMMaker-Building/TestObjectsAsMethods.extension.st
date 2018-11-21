Extension { #name : #TestObjectsAsMethods }

{ #category : #'*VMMaker-testing' }
TestObjectsAsMethods >> testCrashWithSmallInt [
	"Earlier versions of Squeak and VM would crash the VM on this test, hence
	the alarming name."
	self should: [self answer10] raise: MessageNotUnderstood

]
