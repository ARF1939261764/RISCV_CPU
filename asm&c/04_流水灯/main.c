#include "stdint.h"

typedef struct
{
	volatile uint32_t ODR;
	volatile uint32_t IDR;
	volatile uint32_t MODE;
}GPIO_t;

GPIO_t *GPIO = (GPIO_t *)0x10000;

int main(void)
{
	uint32_t i;
	GPIO->MODE=0x0000000F;
	GPIO->ODR =0x00000000;
	for(;;)
	{
		i=500000;
		while(i--);
		GPIO->ODR--;
	}
	return 0;
}
