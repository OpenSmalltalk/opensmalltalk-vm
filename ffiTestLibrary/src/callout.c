#include <unistd.h>
#include "testLibrary.h"

//Deprecated
int returnAnswer(){
	return 42;
}

//Deprecated
int sumTwoNumbers(int a, int b){
  return a+b; 
}

//Deprecated
float sumAFloatAndADouble(float a, double b){
  return a+b; 
}

int shortCallout(){
  return 42;
}

int longCallout(int seconds){
  sleep(seconds); // will sleep for number of seconds
  return 1;
}

int multipleArgumentCallout(
  int arg1,
  int arg2,
  int arg3,
  int arg4,
  int arg5,
  int arg6,
  int arg7,
  int arg8,
  int arg9,
  int arg10){
  return arg1 + arg2 + arg3 + arg4 + arg5 + arg6 + arg7 + arg8 + arg9 + arg10;
}