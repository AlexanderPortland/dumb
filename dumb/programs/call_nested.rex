; A program to test simple nested procedure calls

`INSTR_LITA
16'd99
`INSTR_CALL
16'd16
`INSTR_ADD    ; Add to acc to check we return back here
16'd1
`INSTR_STOP
`INSTR_NOP
`INSTR_CALL   ; (16) Start of func1
16'd26
`INSTR_ADD    ; Add to acc to check we returned here 
16'd10
`INSTR_RET
`INSTR_LITA   ; (26) Start of func2
16'd100       ; Load in literal to check we were called
`INSTR_RET

; Result: 8'd111