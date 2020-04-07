all:arit_istr_01.o
	riscv-none-embed-ld -T LinkScript.lds	$^ -o main.elf
	riscv-none-embed-objcopy -O binary -S main.elf main.bin
	riscv-none-embed-objdump -D main.elf > main.dis

%.o:%.c
	riscv-none-embed-gcc -march=rv32i -c -o $@ $<

%.o:%.s
	riscv-none-embed-gcc -march=rv32i -c -o $@ $<

clean:
	rm *.o *.out *.bin *.elf
.PHONY: clean