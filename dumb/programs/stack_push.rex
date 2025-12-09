`INSTR_LITA
16'h99
`INSTR_PUSH     ; Should be pushed to initial stack pointer location
`INSTR_ADD
16'h10
`INSTR_PUSH
`INSTR_LOADA    ; Load from the address in memory where we pushed earlier
`SP_START_ADDR
`INSTR_STOP

; Result: 8'h99