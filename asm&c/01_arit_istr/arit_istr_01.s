.section .text
.globl   _start
_start:
  li    a1, 0x12345678;
  addi  a1, a1,0x01;
  li    a0, 0x52369128;
  sub   a2,a0,a1;
  