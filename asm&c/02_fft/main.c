#include "DSP.h"

ComplexType *Complex=(ComplexType *)0x100000;

int main(void)
{
	int i;
	for (i = 0; i < 16; i++)
	{
		Complex[i].real = i*i;
		Complex[i].imag = 0;
	}
	FFT(Complex, 16);
	return 0;
}


