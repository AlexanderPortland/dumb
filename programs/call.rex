; A program to test the simplest procedure calls

`INSTR_LITA
8'd99
`INSTR_CALL
8'd10
`INSTR_ADD    ; Add to `acc` to make sure we return back here
8'd10
`INSTR_STOP
`INSTR_NOP
`INSTR_NOP
`INSTR_NOP
`INSTR_LITA   ; (10) Start of function
8'd33         ;      Load in a literal to check we were called
`INSTR_RET

; Result: 8'd43