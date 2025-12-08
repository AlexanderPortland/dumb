`INSTR_LITA
8'h99
`INSTR_PUSH     ; Should be pushed to initial stack pointer location
`INSTR_ADD
8'h10
`INSTR_LOADA    ; Load from the address in memory where we pushed earlier
`SP_START_ADDR
`INSTR_STOP

; Result: 8'h99