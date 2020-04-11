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
  add   x6,x5,x6;
  sub   x2,x2,x1;
  sll   x7,x2,x1;
  slt   x7,x1,x2;
  xor   x8,x2,x1;
  or    x9,x2,x8;
  and   x7,x6,x5;
  li    x2,0x10100;
  li    x1,0x12345678;
  sw    x1,0x01(x0);
  sw    x1,0x05(x0);
  sw    x1,0x09(x0);
  sw    x1,0x013(x0);
  sw    x1,0x017(x0);
  lw    x3,0x00(x2);
