all:startup.o libm.a main.o libc_nano.a libnosys.a libgcc.a
	riscv-none-embed-ld -nostartfiles -nodefaultlibs -u _printf_float -nostdlib --gc-sections --check-sections -T LinkScript.lds	$^ -o main.elf 
	riscv-none-embed-objcopy -O binary -S main.elf main.bin
	riscv-none-embed-objdump -D main.elf > main.dis
	../tool/bin2mif main.bin

%.o:%.c
	riscv-none-embed-gcc -ffunction-sections -fdata-sections -march=rv32i -c -o $@ $< 

%.o:%.s
	riscv-none-embed-gcc -ffunction-sections -fdata-sections -march=rv32i -c -o $@ $< 

clean:
	rm *.o *.out *.bin *.elf
.PHONY: clean