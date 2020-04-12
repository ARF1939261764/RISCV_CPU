.section .text
.globl   _start
_start:
  li    x5,0x12345678
  csrw  0x00,x5
  csrr  x1,0x00
  li    sp,0x10000
  auipc x5,0x01
  j     main
