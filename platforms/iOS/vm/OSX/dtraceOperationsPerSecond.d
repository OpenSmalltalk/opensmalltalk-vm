#pragma D option quiet

dtrace:::BEGIN
{
	printf("Sampling... Hit Ctrl-C to end.\n");
	start = timestamp;		
}

objc$target::-drawRect?:entry
{
	@operationspercpu[cpu] = count();	
	@totaloperationexecutions[probemod] = count();

	@multicoredistributionofalloperations = lquantize((cpu + 1), 1, 16, 1);
	@multicoredistributionofoperations[probemod] = lquantize((cpu + 1), 1, 16, 1);

	starttimeformethod[probemod] = timestamp;	
	cpustarttimeformethod[probemod] = vtimestamp;	
	methodhasenteredatleastonce[probemod] = 1;
}

objc$target::-drawRect?:return
/methodhasenteredatleastonce[probemod] == 1/
{
	@overallexecutions[probemod] = count();
	@averageexecutiontime[probemod] = avg((timestamp - starttimeformethod[probemod]) / 1000);
	@averagecpuexecutiontime[probemod] = avg((vtimestamp - cpustarttimeformethod[probemod]) / 1000);
}

tick-1s
{
	printa("%30s %10@u operations / s\n", @totaloperationexecutions);

	clear(@totaloperationexecutions);
}

dtrace:::END 
{
	seconds = (timestamp - start) / 1000000000;

	normalize(@averageexecutiontime, 1000);
	normalize(@averagecpuexecutiontime, 1000);

	printf("Ran for %u seconds\n", seconds);
	printf("%30s %20s %20s %20s\n", "Operation", "Executions","Average time (ms)", "CPU average time (ms)");
	printa("%30s %20@u %20@u %20@u\n", @overallexecutions, @averageexecutiontime, @averagecpuexecutiontime);

	printf("\nCPU core distribution of all operations:\n");
	printa(@multicoredistributionofalloperations);

	printf("CPU core distribution, by operation type:\n");
	printa(@multicoredistributionofoperations);
}
