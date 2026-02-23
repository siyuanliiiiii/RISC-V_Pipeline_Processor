.section .text
.globl _start
_start:
    # Memory tests: store and load multiple widths (keep aligned)
    ######### load word############
    auipc x7, 0
    nop
    nop
    nop
    nop
    nop
    nop
    lw x8, 0(x7)
    lw x9, 4(x7)
    lw x10, 8(x7)
    lw x11, 12(x7)
    lw x12, 16(x7)
    lw x13, 20(x7)
    lw x14, 24(x7)
    lw x15, 28(x7)
    nop
    nop
    nop
    nop
    nop
    auipc x7, 0
    nop
    nop
    nop
    nop
    nop

    sw x8, 0(x7)
    sw x9, 4(x7)
    sw x10, 8(x7)
    nop
    nop
    nop
    nop
    nop

    lw x1, 0(x7)
    lw x2, 4(x7)
    lw x3, 8(x7)
    nop
    nop
    nop
    nop
    nop

    ########### load half unsigned ########
    lui x7, 0xaaaab
    nop
    nop
    nop
    nop
    nop
    lhu x1, 0(x7)
    lhu x2, 2(x7)
    lhu x3, 4(x7)
    lhu x4, 6(x7)
    lhu x5, 8(x7)
    lhu x6, 10(x7)
    nop
    nop
    nop
    nop
    nop
    auipc x7, 12
    nop
    nop
    nop
    nop
    nop
    sh x1, 0(x7)
    sh x2, 2(x7)
    sh x3, 4(x7)
    nop
    nop
    nop
    nop
    nop
    lhu x4, 0(x7)
    lhu x5, 2(x7)
    lhu x6, 4(x7)
    nop
    nop
    nop
    nop
    nop

    ######### load half test########
    lui x7, 0xaaaab
    nop
    nop
    nop
    nop
    nop

    lh x1, 0(x7)
    lh x2, 2(x7)
    lh x3, 4(x7)
    lh x4, 6(x7)
    lh x4, 8(x7)
    lh x5, 10(x7)
    nop
    nop
    nop
    nop
    nop
    auipc x7, 0
    nop
    nop
    nop
    nop
    nop
    sw x1, 0(x7)
    sw x2, 4(x7)
    sh x3, 8(x7)
    sh x4, 10(x7)
    sh x5, 12(x7)
    nop
    nop
    nop
    nop
    nop
    lh x6, 0(x7)
    lw x8, 0(x7)
    lh x9, 4(x7)
    lw x10,4(x7)
    lh x11, 8(x7)
    nop
    nop
    nop
    nop
    nop

######## load byte test #############
    lui x7, 0xaaaab
    nop
    nop
    nop
    nop
    nop

    lb x1, 0(x7)
    lb x2, 1(x7)
    lb x3, 2(x7)
    lb x4, 3(x7)
    lb x5, 4(x7)
    lb x6, 5(x7)
    lb x8, 6(x7)
    lb x9, 7(x7)
    nop
    nop
    nop
    nop
    nop

    auipc x7, 0
    nop
    nop
    nop
    nop
    nop
    nop
    sb x1, 0(x7)
    sb x2, 1(x7)
    sb x3, 2(x7)
    sb x4, 3(x7)
    sb x5, 4(x7)
    sb x6, 5(x7)
    sb x7, 6(x7)
    sb x8, 7(x7)
    nop
    nop
    nop
    nop
    nop
    lbu x9, 6(x7)
    lbu x10, 4(x7)
    lw  x11, 4(x7)
    lhu x1, 2(x7)
    lhu x2, 6(x7)

    slti x0, x0, -256     # magic instruction to end simulation
    nop
    nop
    nop
    nop
    nop

.section .data
some_data_1:
    .word 0xbbbbbbbb
    .byte 0xcc
    .byte 0xdd
    .byte 0xee
    .byte 0xff
    .word 0xcccccccc
    .word 0xdddddddd
    .word 0x88888888
    .word 0x99999999
    .word 0x77777777
    .word 0x67666666
    .word 0x55555555
    .word 0x44444444
    .word 0x33333333
    .word 0x22222222
    .word 0x11111111
