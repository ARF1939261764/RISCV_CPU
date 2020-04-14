#include "DSP.h"

ComplexType W[DSP_FFT_MAX_NUM / 2];

void FFT(ComplexType *inputBuff, uint32_t num)
{
	static uint32_t lastNum = 0;/*��һ�μ���FFTʱ��Ԫ�ص�����*/
	uint32_t m,i,j,k,n;/*m:m=log2(num),���ж��ٲ� tempUInt:��ʱ����*/
	uint32_t tempUInt = 0;
	double tempDouble = 0;
	ComplexType tempComplex,*data,u;
	uint32_t le,wIndex,wIndexStep;
	if ((inputBuff == NULL) || (num == 1)) { return; }/*����ָ��Ϊ�ջ��ߵ���Ϊ1,����*/
	data = inputBuff;
	for (i = 0; i < 32; i++)/*��m = log2(num)*/
	{
		if (num&(1 << i))
		{
			m = i;
			tempUInt++;
		}
	}
	if (tempUInt != 1) { return;/*��Ϊ2����������,����*/ }
	if (num != lastNum)/*����һ�μ���ĵ�������ͬ����Ҫ���¼���W^n*/
	{
		if (num > DSP_FFT_MAX_NUM) { return;/*���������������,����*/ }
		lastNum = num;
		tempUInt = num / 2;
		
		tempComplex.real = cos(atan(1.0)*8.0 / num);/*atan��Ϊ�˻��pi��ֵ,math.h��δ����PI,��ֱ��ʹ�ó���Ӳ���벻�淶,��ʹ��atan������ӻ�ȡpi��ֵ*/
		tempComplex.imag = -sin(atan(1.0)*8.0 / num);
		W[0].real = 1;/*W^0�����1*/
		W[0].imag = 0;
		for (n = 1; n < tempUInt; n++)/*����W^n����Ҫ����W^1��W^(num/2-1),W^0��Ϊ1,�������*/
		{
			W[n] = tempComplex;
			tempDouble = tempComplex.real*W[1].real - tempComplex.imag*W[1].imag;
			tempComplex.imag = tempComplex.real*W[1].imag + tempComplex.imag*W[1].real;
			tempComplex.real = tempDouble;
		}
	}
	/*-----------׼��������ɣ���ʼFFT����-------------*/
	le = num;
	wIndexStep = 1;
	for (k = 0; k < m; k++)/*�������㣬ÿ�ε�������һ�㣬�ܹ�����log2(num)��*/
	{
		le = le / 2;
		for (i = 0; i < num; i+=2*le)/*���ȼ�����ò�����˷��ĵ�*/
		{
			tempComplex.real = data[i].real + data[i + le].real;
			tempComplex.imag = data[i].imag + data[i + le].imag;
			data[i + le].real = data[i].real - data[i + le].real;
			data[i + le].imag = data[i].imag - data[i + le].imag;
			data[i] = tempComplex;
		}
		wIndex = wIndexStep;
		for (i = 1; i < le; i++)/*�����ʣ�µĵ㣬ÿ�����ֻ���le-1������Ҫ����*/
		{
			u = W[wIndex];/*���������ϲ�ͬ��û�м�һ����Ϊ����W[0]��������W^1��������W[0]������W^0��W[1]������W^1*/
			for (j = i; j < num; j += 2 * le)/*�������ǰ������ҪW[index]����,�ܹ���2^k��*/
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
	/*----------������ɣ������ֽ���-----------------------------*/
	for (i = 0; i < num; i++)
	{
		j = 0;
		for (k = 0; k < m; k++) { j = (j << 1) | (0x01 & (i >> k)); }/*��λ����*/
		if (i < j)
		{
			tempComplex = data[i];
			data[i] = data[j];
			data[j] = tempComplex;
		}
	}
}