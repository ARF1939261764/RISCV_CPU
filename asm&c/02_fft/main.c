#include "DSP.h"

ComplexType *Complex=(ComplexType *)0x08000;/*注意不要为0x00，不然会被判定为NULL*/

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
