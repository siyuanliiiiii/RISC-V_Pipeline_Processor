.section .text
.globl _start


_start:
    auipc x1, 0
    nop
    NOP
    nop
    nop
    nop

    lw x2, 0(x1)
    lw x3, 4(x1)

    nop
    nop
    nop
    nop
    nop
    
    slti x0, x0, -256
