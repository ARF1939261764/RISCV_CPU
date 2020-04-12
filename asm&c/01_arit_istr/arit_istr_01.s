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
  li    x2,0x10200;
  li    x1,0x12345678;
  sw    x1,0x01(x2);
  sw    x1,0x05(x2);
  sb    x1,0x01(x2);
  sw    x1,0x09(x2);

  li    x1,'a';
  sb    x1,0x05(x2);
  sw    x1,0x0D(x2);
  sb    x1,0x09(x2);
  sh    x1,0x0a(x2);
  sb    x1,0x0D(x2);
  li    x1,0x80;
  sb    x1,0x02(x2);
  sb    x1,0x06(x2);
  sh    x1,0x0a(x2);
  sb    x1,0x0e(x2);
  lh    x4,0x01(x2);
  lw    x3,0x01(x2);
  lb    x5,0x01(x2);
  lhu   x6,0x01(x2);
  lbu   x7,0x01(x2);
  lh    x4,0x04(x2);
  lb    x5,0x04(x2);
  lhu   x6,0x04(x2);
  lw    x3,0x04(x2);
  lbu   x7,0x04(x2);
  sw    x7,0x11(x0);
  addi  x7,x7,0x01;
