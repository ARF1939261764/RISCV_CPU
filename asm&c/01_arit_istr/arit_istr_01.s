.section .text
.globl   _start
_start:
  li    x1, 0x12345678;
  addi  x1, x1,0x01;
  li    x2, 0x52369128;
  sub   x3,x1,x2;
  sub   x4,x1,x3;
  sub   x5,x4,x3;
  sub   x6,x5,x5;
  addi  x6,x6,0x01;
  addi  x6,x6,0x01;
  addi  x6,x6,0x01;
  addi  x6,x6,0x01;
  addi  x6,x6,0x01;
  addi  x6,x6,0x01;
  addi  x6,x6,0x01;
  addi  x6,x6,0x01;
  addi  x6,x6,0x01;
  addi  x6,x6,0x01;
  addi  x6,x6,0x01;
  addi  x6,x6,0x01;
  addi  x6,x6,0x01;
  addi  x6,x6,0x01;
  addi  x6,x6,0x01;
