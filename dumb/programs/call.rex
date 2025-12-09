; A program to test the simplest procedure calls

`INSTR_LITA
16'd99
`INSTR_CALL
16'd20
`INSTR_ADD    ; Add to `acc` to see if we return back here
16'd10
`INSTR_STOP
`INSTR_NOP
`INSTR_NOP
`INSTR_NOP
`INSTR_LITA    ; (20) Start of function
16'd33         ;      Load in a literal to check we were called
`INSTR_RET

; Result: 8'd43