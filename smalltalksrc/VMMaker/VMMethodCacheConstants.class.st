"
I am a shared pool for the constants that define the first-level method lookup cache.

self ensureClassPool.
#(#MethodCacheClass #MethodCacheEntries #MethodCacheEntrySize #MethodCacheMask #MethodCacheMethod #MethodCachePrimFunction #MethodCacheSelector #MethodCacheSize) do: [:k|
	self classPool declare: k from: StackInterpreter classPool]
"
Class {
	#name : #VMMethodCacheConstants,
	#superclass : #SharedPool,
	#classVars : [
		'LookupRuleDynamicSuper',
		'LookupRuleImplicit',
		'LookupRuleMNU',
		'LookupRuleOrdinary',
		'LookupRuleSelf',
		'MethodCacheClass',
		'MethodCacheEntries',
		'MethodCacheEntrySize',
		'MethodCacheMask',
		'MethodCacheMethod',
		'MethodCachePrim',
		'MethodCachePrimFunction',
		'MethodCacheSelector',
		'MethodCacheSize'
	],
	#category : #'VMMaker-Interpreter'
}
