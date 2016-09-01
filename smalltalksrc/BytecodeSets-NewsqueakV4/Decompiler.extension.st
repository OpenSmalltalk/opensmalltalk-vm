Extension { #name : #Decompiler }

{ #category : #'*BytecodeSets-instruction decoding' }
Decompiler >> blockReturnConstant: value [

	self pushConstant: value; blockReturnTop
]
