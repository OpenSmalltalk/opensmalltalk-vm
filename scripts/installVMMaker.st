path := CommandLineArguments default commandLineArguments last.
Metacello new
  baseline: 'VMMaker';
	repository: 'gitlocal://' , path , '/smalltalksrc';
	load