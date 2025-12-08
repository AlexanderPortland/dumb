; A simple program that adds numbers in a loop

`INSTR_LITA  ; (0) Load in an initial value
8'd0
`INSTR_ADD   ; (2) Keep incrementing by 8
8'd8
`INSTR_JMPZ  ; (4) Jump out of the loop if we've overflown to zero
8'd8
`INSTR_JMP
8'd2
`INSTR_ADD   ; (8) End program after the loop w/ a unique add
8'd100