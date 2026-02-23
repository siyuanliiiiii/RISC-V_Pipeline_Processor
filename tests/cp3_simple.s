.section .text
.globl _start

_start:

    lui x2, 0xaaaab
    lw  x3, 4(x2)
    beqz x3, final_pass


final_pass:
    slti x0, x0, -256     # magic instruction to end simulation
    nop
    nop
    nop
    nop
    nop

.section .data

some_data_1:
    .word 0xbbbbbbbb
    .word 0x00000000
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


