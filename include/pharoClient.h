#ifndef PHAROVM_PHARO_CLIENT_H
#define PHAROVM_PHARO_CLIENT_H

#pragma once

#include "parameters.h"

// CHECK ME: envp is not portable, does it make sense to have it as a parameter here?
int pharovm_mainWithParameters(pharovm_parameters_t *parameters);
int pharovm_main(int argc, const char **arguments, const char **envp);
int initPharoVM(const char* imageFileName, const pharovm_parameter_vector_t *vmParameters, const pharovm_parameter_vector_t *imageParameters);
void runInterpreter();

#endif //PHAROVM_PHARO_CLIENT_H
