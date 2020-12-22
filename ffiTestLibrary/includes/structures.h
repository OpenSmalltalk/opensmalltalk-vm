#ifndef STRUCTURES_H_
#define STRUCTURES_H_

typedef struct{
	int x;
	int y;
} OUR_POINT;

typedef struct{
	char a[100];
	float b;
	double c;
	long d;
	int e;
	short f;
} LONG_STRUCT;

typedef struct {
	char a;
	void* b;
} INNER;

typedef struct{
	INNER inner;
	float x;
	double y;
} NESTED_STRUCTS;


#endif
