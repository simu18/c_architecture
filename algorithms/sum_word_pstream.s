    .data

input_addr:      .word  0x80
output_addr:     .word  0x84

sum_high:        .word  0
sum_low:         .word  0
current_x:       .word  0
low_old:         .word  0
low_sum:         .word  0
tmp_or:          .word  0
tmp_carry:       .word  0
or_left:         .word  0
or_right:        .word  0

    .text
    .org 0x100

_start:
    @p input_addr a!        
    @p output_addr b!       

    @                       
    dup
    -if sum_word_pstream_start

    drop
    lit -1
    !b
    halt

sum_word_pstream_start:
    lit 0 !p sum_high
    lit 0 !p sum_low

sum_word_pstream_loop:
    dup
    if sum_word_pstream_finish

    @                       
    add_input_word         
    lit -1 +
    sum_word_pstream_loop ;

sum_word_pstream_finish:
    drop
    @p sum_high !b
    @p sum_low !b
    halt

or_words:
    !p or_right
    !p or_left
    @p or_left inv
    @p or_right inv
    and
    inv
    ;

shift31:
    lit 30 >r
shift31_loop:
    2/
    next shift31_loop
    ;

msb_to_carry:
    shift31
    lit 1 and
    ;

sign_word:
    dup
    -if sign_word_nonnegative

    drop
    lit -1
    ;

sign_word_nonnegative:
    drop
    lit 0
    ;

add_input_word:
    dup !p current_x

    @p sum_low
    dup !p low_old
    +
    dup !p low_sum
    !p sum_low

    @p low_old
    @p current_x
    or_words
    @p low_sum
    inv
    and
    !p tmp_or

    @p low_old
    @p current_x
    and
    @p tmp_or
    or_words
    msb_to_carry
    !p tmp_carry

    @p current_x
    sign_word
    @p tmp_carry
    +
    @p sum_high
    +
    !p sum_high
    ;
