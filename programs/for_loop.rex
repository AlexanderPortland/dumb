; A simple program that adds numbers in a loop

`INSTR_LITA  ; (0) Load in an initial value
16'd0
`INSTR_ADD   ; (4) Keep incrementing by 8
16'h10
`INSTR_CMP
16'h40
`INSTR_JMPC  ; (12) Jump out of the loop if we've overflown to zero
16'd20
`INSTR_JMP
16'd4
`INSTR_ADD   ; (20) End program after the loop w/ a unique add
16'd100
`INSTR_STOP

; Result: 16'd164