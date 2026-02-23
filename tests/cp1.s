.section .text
.globl _start

# ============================================================
# RV32I ALU-only test (no load/store/branch/jump)
# Covers all RV32I ALU ops with NOP-separated dependencies
# Results remain in registers for inspection.
# ============================================================

_start:
    # --------------------------------------------------------
    # Initialize source registers (independent)
    # --------------------------------------------------------
    addi  x10, x0, 21         # x10 = 21 (0x15)
    addi  x11, x0, -16        # x11 = -16 (0xFFFFFFF0)
    addi  x12, x0, 3          # x12 = 3
    addi  x13, x0, 31         # x13 = 31 (shift stress)
    nop
    nop
    nop

    # --------------------------------------------------------
    # R-type ALU ops: results in x20..x29
    # --------------------------------------------------------
    add   x20, x10, x11       # 21 + (-16) = 5
    nop
    nop
    nop

    sub   x21, x10, x11       # 21 - (-16) = 37
    nop
    nop
    nop

    sll   x22, x10, x12       # 21 << 3 = 168
    nop
    nop
    nop

    slt   x23, x11, x10       # (-16 < 21) = 1
    nop
    nop
    nop

    sltu  x24, x11, x10       # 0xFFFFFFF0 < 0x15 unsigned? = 0
    nop
    nop
    nop

    xor   x25, x10, x11
    nop
    nop
    nop

    srl   x26, x11, x12       # logical: 0xFFFFFFF0 >> 3 = 0x1FFFFFFE
    nop
    nop
    nop

    sra   x27, x11, x12       # arithmetic: -16 >> 3 = -2 (0xFFFFFFFE)
    nop
    nop
    nop

    or    x28, x10, x11
    nop
    nop
    nop

    and   x29, x10, x11
    nop
    nop
    nop


    # --------------------------------------------------------
    # I-type ALU ops: results in x30..x31 and x14..x19
    # --------------------------------------------------------
    addi  x30, x10, 100        # 21 + 100 = 121
    nop
    nop
    nop

    slti  x31, x11, 0          # (-16 < 0) = 1
    nop
    nop
    nop

    sltiu x14, x11, 1          # 0xFFFFFFF0 < 1 unsigned? = 0
    nop
    nop
    nop

    xori  x15, x10, 0x0F
    nop
    nop
    nop

    ori   x16, x10, 0x0F
    nop
    nop
    nop

    andi  x17, x10, 0x0F
    nop
    nop
    nop

    slli  x18, x10, 1          # 21 << 1 = 42
    nop
    nop
    nop

    srli  x19, x11, 1          # 0xFFFFFFF0 >> 1 logical = 0x7FFFFFF8
    nop
    nop
    nop

    srai  x14, x11, 1          # -16 >> 1 = -8 (0xFFFFFFF8)  (overwrites x14)
    nop
    nop
    nop


    # --------------------------------------------------------
    # More shift edge cases (uses x13=31)
    # --------------------------------------------------------
    sll   x15, x10, x13        # 21 << 31
    nop
    nop
    nop

    srl   x16, x10, x13        # 21 >> 31 logical = 0
    nop
    nop
    nop

    sra   x17, x11, x13        # -16 >> 31 arithmetic = 0xFFFFFFFF
    nop
    nop
    nop


    # --------------------------------------------------------
    # LUI (datapath immediate)
    # --------------------------------------------------------
    lui   x18, 0x12345         # 0x12345000
    nop
    nop
    nop

    slti x0, x0, -256 # this is the magic instruction to end the simulation
    nop               # preventing fetching illegal instructions
    nop
    nop
    nop
    nop