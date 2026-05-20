    .data

buffer:          .byte  '________________', '________________'
byte_tmp:        .word  0
input_addr:      .word  0x80
output_addr:     .word  0x84
stack_top:       .word  0x400

    .text
    .org     0x100

_start:
    lui      t0, %hi(input_addr)
    addi     t0, t0, %lo(input_addr)
    lw       s0, 0(t0)                       

    lui      t0, %hi(output_addr)
    addi     t0, t0, %lo(output_addr)
    lw       s1, 0(t0)                       

    lui      sp, %hi(stack_top)
    addi     sp, sp, %lo(stack_top)
    lw       sp, 0(sp)

    lui      a0, %hi(buffer)
    addi     a0, a0, %lo(buffer)
    jal      ra, init_buffer

    mv       a0, s0
    lui      a1, %hi(buffer)
    addi     a1, a1, %lo(buffer)
    jal      ra, read_line

    bgt      zero, a0, write_error

    mv       s2, a0                          

    lui      a0, %hi(buffer)
    addi     a0, a0, %lo(buffer)
    mv       a1, s2
    jal      ra, reverse_cstr

    lui      a0, %hi(buffer)
    addi     a0, a0, %lo(buffer)
    mv       a1, s1
    jal      ra, emit_cstr

    halt

write_error:
    sw       a0, 0(s1)
    halt

init_buffer:
    addi     t0, zero, '_'
    addi     t1, zero, 32

init_buffer_loop:
    sb       t0, 0(a0)
    addi     a0, a0, 1
    addi     t1, t1, -1
    bnez     t1, init_buffer_loop
    jr       ra

read_line:
    addi     t0, zero, 0                     
    addi     t3, zero, 10                    
    addi     t4, zero, 32                    

read_line_loop:
    beq      t0, t4, read_line_overflow

    lw       t1, 0(a0)
    beq      t1, t3, read_line_finish

    sb       t1, 0(a1)
    addi     a1, a1, 1
    addi     t0, t0, 1
    j        read_line_loop

read_line_finish:
    sb       zero, 0(a1)
    mv       a0, t0
    jr       ra

read_line_overflow:
    lui      a0, %hi(0xCCCCCCCC)
    addi     a0, a0, %lo(0xCCCCCCCC)
    jr       ra

load_byte:
    lw       t5, 0(a0)

    lui      t6, %hi(byte_tmp)
    addi     t6, t6, %lo(byte_tmp)

    sb       t5, 0(t6)
    lw       a0, 0(t6)
    jr       ra

reverse_cstr:
    addi     sp, sp, -12
    sw       ra, 8(sp)
    sw       a0, 4(sp)
    sw       zero, 0(sp)                     

    jal      ra, find_cstr_end

    lw       t0, 4(sp)                       
    addi     t1, zero, 0                     
    addi     t2, a0, -1                      

reverse_cstr_loop:
    ble      t2, t1, reverse_cstr_finish

    add      t3, t0, t1
    add      t4, t0, t2

    mv       a0, t3
    jal      ra, load_byte
    sw       a0, 0(sp)

    mv       a0, t4
    jal      ra, load_byte
    mv       t6, a0

    lw       t5, 0(sp)
    sb       t6, 0(t3)
    sb       t5, 0(t4)

    addi     t1, t1, 1
    addi     t2, t2, -1
    j        reverse_cstr_loop

reverse_cstr_finish:
    lw       ra, 8(sp)
    addi     sp, sp, 12
    jr       ra

find_cstr_end:
    addi     sp, sp, -4
    sw       ra, 0(sp)

    mv       t3, a0                          
    addi     t0, zero, 0

find_cstr_end_loop:
    beq      t0, a1, find_cstr_end_finish

    add      t1, t3, t0
    mv       a0, t1
    jal      ra, load_byte
    beqz     a0, find_cstr_end_finish

    addi     t0, t0, 1
    j        find_cstr_end_loop

find_cstr_end_finish:
    mv       a0, t0
    lw       ra, 0(sp)
    addi     sp, sp, 4
    jr       ra

emit_cstr:
    addi     sp, sp, -12
    sw       ra, 8(sp)
    sw       a0, 4(sp)                       
    sw       a1, 0(sp)                       

emit_cstr_loop:
    lw       a0, 4(sp)
    jal      ra, load_byte
    beqz     a0, emit_cstr_finish

    lw       t0, 0(sp)
    sb       a0, 0(t0)

    lw       t1, 4(sp)
    addi     t1, t1, 1
    sw       t1, 4(sp)
    j        emit_cstr_loop

emit_cstr_finish:
    lw       ra, 8(sp)
    addi     sp, sp, 12
    jr       ra
