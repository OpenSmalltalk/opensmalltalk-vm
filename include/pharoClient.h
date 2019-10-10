#pragma once

#include "parameters.h"

int initPharoVM(char* image, char** vmParams, int vmParamCount, char** imageParams, int imageParamCount);
void runInterpreter();

