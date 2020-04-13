.section .text
.globl   _start
_start:
  li x1,0x05;
  li x2,0x06;
  add x3,x1,x2;/*0x0b*/
  sub x4,x1,x2;/*-1*/

  li x1,-10;
  li x2,0x06;
  li x3,1;
  li x4,0x12345678
  sll x5,x4,x3;
  srl x5,x4,x3;
  sra x5,x4,x3;
  sra x5,x1,x3;

  slt x5,x1,x3;
  slt x5,x3,x1;

  sltu x6,x1,x3;
  sltu x6,x3,x1;
  
  li  x1,0x12345678;
  li  x2,0x23456789;
  xor x3,x1,x2;
  or  x4,x1,x2;
  and x5,x1,x2;

  addi x1,x1,0x01;
  addi x1,x1,0x01;
  addi x1,x1,-1;
  addi x1,x1,-1;
  li   x1,-10;
  slti x2,x1,10;
  sltiu x2,x1,10;
  xori x1,x1,0x01;
  ori  x1,x1,0xFF;
  andi x1,x1,0x55;
  slli x1,x1,0x01;
  srli x1,x1,0x01;
  li   x1,-10;
  srai x1,x1,1;

  li x1,0x0123;
  li x2,0x0123;
  beq x1,x2,jump_1;
  li x1,0x01;
jump_1:
  li x1,0x12345678;
  li x2,0x23456789;
  bne x1,x2,jump_2
  li x1,0x51;
  li x1,0x52345678;
  li x2,0x53456789;
jump_2:
  li x1,0x12345678;
  BLT x1,x2,jump_3;
  li x1,0x05;
jump_3:
  li x1,0x10;
  li x1,0x52345690;
  BLT x1,x2,jump_4;
jump_4:
  li x1,0x0A
  li x1,0xAA
jump_5:
  auipc x1,0x01;
  li sp,0x10000;
  j main
  
