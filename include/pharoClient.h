#pragma once

#include "parameters.h"

int initPharoVM(char* image, char** vmParams, int vmParamCount, char** imageParams, int imageParamCount);
//TODO: Flags (this will be removed)
void setFlagVMRunOnWorkerThread(int flag);
int isVMRunOnWorkerThread();

void runInterpreter();

int mainThreadLoop();
