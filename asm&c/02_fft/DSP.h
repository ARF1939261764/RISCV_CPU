#ifndef __DSP_H
#define __DSP_H

#include "stdint.h"
#include "math.h"

#define DSP_FFT_MAX_NUM		8192

typedef struct
{
	double real;
	double imag;
}ComplexType;

extern void FFT(ComplexType *x,uint32_t num);

#endif
