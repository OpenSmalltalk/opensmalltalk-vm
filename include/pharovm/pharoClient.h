#ifndef PHAROVM_PHARO_CLIENT_H
#define PHAROVM_PHARO_CLIENT_H

#pragma once

#include "parameters.h"

// CHECK ME: envp is not portable, does it make sense to have it as a parameter here?
EXPORT(int) vm_main_with_parameters(VMParameters *parameters);
EXPORT(int) vm_main(int argc, const char **arguments, const char **envp);
EXPORT(int) vm_init(const char* imageFileName, const VMParameterVector *vmParameters, const VMParameterVector *imageParameters);
EXPORT(void) vm_run_interpreter();

#endif //PHAROVM_PHARO_CLIENT_H
