#include "DSP.h"

ComplexType W[DSP_FFT_MAX_NUM / 2];

void FFT(ComplexType *inputBuff, uint32_t num)
{
	static uint32_t lastNum = 0;/*上一次计算FFT时，元素的数量*/
	uint32_t m,i,j,k,n;/*m:m=log2(num),即有多少层 tempUInt:临时变量*/
	uint32_t tempUInt = 0;
	double tempDouble = 0;
	ComplexType tempComplex,*data,u;
	uint32_t le,wIndex,wIndexStep;
	if ((inputBuff == NULL) || (num == 1)) { return; }/*数据指针为空或者点数为1,返回*/
	data = inputBuff;
	for (i = 0; i < 32; i++)/*求m = log2(num)*/
	{
		if (num&(1 << i))
		{
			m = i;
			tempUInt++;
		}
	}
	if (tempUInt != 1) { return;/*不为2的整数次幂,返回*/ }
	if (num != lastNum)/*和上一次计算的点数不相同，需要重新计算W^n*/
	{
		if (num > DSP_FFT_MAX_NUM) { return;/*数量超过最大限制,返回*/ }
		lastNum = num;
		tempUInt = num / 2;
		
		tempComplex.real = cos(atan(1.0)*8.0 / num);/*atan是为了获得pi的值,math.h中未定义PI,而直接使用常数硬编码不规范,故使用atan函数间接获取pi的值*/
		tempComplex.imag = -sin(atan(1.0)*8.0 / num);
		W[0].real = 1;/*W^0恒等于1*/
		W[0].imag = 0;
		for (n = 1; n < tempUInt; n++)/*计算W^n，需要计算W^1到W^(num/2-1),W^0恒为1,无需计算*/
		{
			W[n] = tempComplex;
			tempDouble = tempComplex.real*W[1].real - tempComplex.imag*W[1].imag;
			tempComplex.imag = tempComplex.real*W[1].imag + tempComplex.imag*W[1].real;
			tempComplex.real = tempDouble;
		}
	}
	/*-----------准备工作完成，开始FFT计算-------------*/
	le = num;
	wIndexStep = 1;
	for (k = 0; k < m; k++)/*迭代计算，每次迭代计算一层，总共迭代log2(num)次*/
	{
		le = le / 2;
		for (i = 0; i < num; i+=2*le)/*首先计算出该层无需乘法的点*/
		{
			tempComplex.real = data[i].real + data[i + le].real;
			tempComplex.imag = data[i].imag + data[i + le].imag;
			data[i + le].real = data[i].real - data[i + le].real;
			data[i + le].imag = data[i].imag - data[i + le].imag;
			data[i] = tempComplex;
		}
		wIndex = wIndexStep;
		for (i = 1; i < le; i++)/*计算出剩下的点，每个部分会有le-1个点需要计算*/
		{
			u = W[wIndex];/*这里与书上不同，没有减一，因为书上W[0]代表的是W^1，而这里W[0]代表的W^0，W[1]代表的W^1*/
			for (j = i; j < num; j += 2 * le)/*计算出当前所有需要W[index]的项,总共有2^k项*/
			{
				tempComplex.real = data[j].real + data[j + le].real;
				tempComplex.imag = data[j].imag + data[j + le].imag;
				data[j + le].real = data[j].real - data[j + le].real;
				data[j + le].imag = data[j].imag - data[j + le].imag;
				data[j] = tempComplex;
				tempComplex.real = data[j + le].real*u.real - data[j + le].imag*u.imag;
				tempComplex.imag = data[j + le].real*u.imag + data[j + le].imag*u.real;
				data[j + le] = tempComplex;
			}
			wIndex += wIndexStep;
		}
		wIndexStep *= 2;
	}
	/*----------计算完成，交换字节序-----------------------------*/
	for (i = 0; i < num; i++)
	{
		j = 0;
		for (k = 0; k < m; k++) { j = (j << 1) | (0x01 & (i >> k)); }/*码位倒置*/
		if (i < j)
		{
			tempComplex = data[i];
			data[i] = data[j];
			data[j] = tempComplex;
		}
	}
}