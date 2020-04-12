.section .text
.globl   _start
_start:
  li sp,0x10000
  auipc x5,0x01
  j main;
