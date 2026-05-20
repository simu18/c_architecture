    .data

output_buffer:   .byte  '________________', '________________', '________________', '________________'

    .data
    .org     0x140

input_buffer:    .byte  '________________', '________________', '________________', '________________', '________________', '________________', '________________', '________________'
input_addr:      .word  0x80
output_addr:     .word  0x84
stack_top:       .word  0x700

    .text
    .org     0x300

_start:
    movea.l  stack_top, A7
    movea.l  (A7), A7

    movea.l  input_addr, A0
    movea.l  (A0), A0

    movea.l  output_addr, A1
    movea.l  (A1), A1

    jsr      init_output_buffer
    jsr      read_line
    cmp.l    0, D0
    bne      write_error

    jsr      decompress_line
    cmp.l    0, D0
    bne      write_error

    jsr      emit_output_buffer
    halt

write_error:
    move.l   D0, (A1)
    halt

init_output_buffer:
    link     A6, 0

    movea.l  output_buffer, A2
    move.l   0, D0
    move.b   '_', D0
    move.l   64, D1

init_output_buffer_loop:
    move.b   D0, (A2)+
    sub.l    1, D1
    bne      init_output_buffer_loop

    unlk     A6
    rts

read_line:
    link     A6, 0

    movea.l  input_buffer, A2
    move.l   0, D1

read_line_loop:
    move.l   0, D2
    move.b   (A0), D2
    cmp.b    10, D2
    beq      read_line_finish

    move.b   D2, (A2)+
    add.l    1, D1
    cmp.l    128, D1
    bge      read_line_overflow
    jmp      read_line_loop

read_line_finish:
    move.l   0, D0
    move.b   D0, (A2)
    unlk     A6
    rts

read_line_overflow:
    move.l   0xCCCC_CCCC, D0
    unlk     A6
    rts

decompress_line:
    link     A6, -4

    movea.l  input_buffer, A2
    movea.l  output_buffer, A3
    move.l   0, -4(A6)

decompress_line_loop:
    move.l   0, D0
    move.b   (A2)+, D0
    beq      decompress_line_finish

    move.l   0, D1
    move.b   (A2)+, D1
    beq      decompress_line_invalid

    move.l   0, D3
    move.b   D0, D3
    sub.b    '1', D3
    bmi      decompress_line_invalid
    cmp.b    8, D3
    bgt      decompress_line_invalid
    add.l    1, D3

    move.l   -4(A6), D4
    add.l    D3, D4
    cmp.l    64, D4
    bge      decompress_line_overflow

    jsr      write_repeat
    move.l   D4, -4(A6)
    jmp      decompress_line_loop

decompress_line_finish:
    move.l   0, D0
    move.b   D0, (A3)
    unlk     A6
    rts

decompress_line_invalid:
    move.l   -1, D0
    unlk     A6
    rts

decompress_line_overflow:
    move.l   0xCCCC_CCCC, D0
    unlk     A6
    rts

write_repeat:
    link     A6, 0

write_repeat_loop:
    move.b   D1, (A3)+
    sub.l    1, D3
    bne      write_repeat_loop

    unlk     A6
    rts

emit_output_buffer:
    link     A6, 0

    movea.l  output_buffer, A2

emit_output_buffer_loop:
    move.l   0, D0
    move.b   (A2)+, D0
    beq      emit_output_buffer_finish

    move.b   D0, (A1)
    jmp      emit_output_buffer_loop

emit_output_buffer_finish:
    unlk     A6
    rts
