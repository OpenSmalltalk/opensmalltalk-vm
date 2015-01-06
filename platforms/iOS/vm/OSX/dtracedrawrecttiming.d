#pragma D option quiet

objc$target::-drawRect?:entry
{
	start[probemod] = timestamp;	
}

objc$target::-drawRect?:return
{
	printf("%30s %10s Execution time: %u us\n", probemod, probefunc, (timestamp - start[probemod]) / 1000);
}
