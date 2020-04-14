.section .text
.globl   _start
_start:
/***清除bss段*************************/
  la x1,__bss_start;
  la x2,__bss_end;
_clear_bss_start:
  blt x2,x1,_clear_bss_done;
  sw zero,(x1);
  addi x1,x1,4;
  j _clear_bss_start;
_clear_bss_done:
/***设置栈指针**************************/
  li sp,0x100000;
/***启动main函数***********************/
  jal main;
/***死循环*****************************/
_stop:
  j _stop;
