all:startup.o main.o DSP.o  libm.a libc.a libgcc.a 
	riscv-none-embed-ld -T LinkScript.lds	$^ -o main.elf 
	riscv-none-embed-objcopy -O binary -S main.elf main.bin
	riscv-none-embed-objdump -D main.elf > main.dis
	../tool/bin2mif main.bin

%.o:%.c
	riscv-none-embed-gcc -march=rv32i -c -o $@ $< 

%.o:%.s
	riscv-none-embed-gcc -march=rv32i -c -o $@ $< 

clean:
	rm *.o *.out *.bin *.elf
.PHONY: clean