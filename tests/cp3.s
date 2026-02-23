.section .text
.globl _start

_start:

############################################################
# 1. BNE — Branch if Not Equal
# Find first byte != 0xBB
############################################################
test_bne:
    lui x10, 0xaaaab        # Base address
    li x11, 0xBB
    nop
    nop
    nop

loop_bne:
    lbu x12, 0(x10)
    addi x10, x10, 1
    nop                    # load-use protection
    nop
    nop

    bne x12, x11, test_beq
    nop
    nop

    jal x0, loop_bne
    nop
    nop

###### TEST BEQ ##########
test_beq:
    lui x10, 0xaaaab        # Base address
    addi x11, x0, 0x33
    nop
    nop
    nop

loop_beq:
    lbu x12, 0(x10)
    addi x10, x10, 1
    nop                    # load-use protection
    nop
    nop

    beq x12, x11, test_bge
    nop
    nop

    jal x0, loop_beq
    nop
    nop

#### TEST BGE ######

test_bge:
    lui x10, 0xaaaab
    addi x11, x0, 0xee
    nop
    nop
    nop
loop_bge:
    lbu x12, 0(x10)
    addi x10, x10, 1
    nop
    nop
    nop

    bge x12, x11, test_load_hazard
    nop
    nop
    nop
    jal x0, loop_bge

###### TEST LOAD USE HAZARD #######
test_load_hazard:
    addi x1, x0, 10  # x1=10
    addi x3, x0, 2   # x3=2
    sub  x2, x1, x3  # RAW: X3, x2 = 8 
    and  x4, x2, x1  # RAW: x2, x4 = 8
    or   x5, x1, x2  # RAW: x2, x5 = 10

    addi t0, x0, 10
    add  t1, t0, t0

    addi t2, t0, 5
    nop
    add t3, t2, t2
    addi t4, x0, 100
    nop
    nop
    nop
    add t5, t4, t4
    la s0, some_data_1
    lw s1, 0(s0)
    jal x0, test_jalr

###### TEST_JALR ###########
test_jalr:
    li x1, 0
    li x2, 0
    la x3, jalr_subroutine
    jalr x4, 0(x3)
    li x2, 1
    jal x0, final_pass

jalr_subroutine:
    jalr x0, 0(x4)



############################################################
# FINAL PASS
############################################################
final_pass:
    slti x0, x0, -256     # magic instruction to end simulation
    nop
    nop
    nop
    nop
    nop


############################################################
# DATA SECTION
############################################################
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