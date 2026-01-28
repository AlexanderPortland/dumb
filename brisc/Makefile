.PHONY: cpu run-cpu clean programs

DESIGN_DIR=designs
BIN_NAME=cpu-test

cpu:
	cd $(DESIGN_DIR) && iverilog -g2012 -o $(BIN_NAME) -c cmdfile.txt

MEM ?=

run-sim: cpu programs/test.hex
	cd $(DESIGN_DIR) && vvp $(BIN_NAME) $(if $(MEM),+memory_from_file=$(PWD)/$(MEM))

clean:
	rm -f $(DESIGN_DIR)/$(BIN_NAME)
	rm -f programs/*.elf programs/*.o programs/*.hex




# Convert elf to binary file for reading
# programs/%.bin: programs/%.elf

PROGRAM_SOURCES := $(wildcard programs/*.c)
PROGRAM_ELFS := $(PROGRAM_SOURCES:.c=.elf)
PROGRAM_HEXS := $(PROGRAM_SOURCES:.c=.hex)
ARCH=-march=rv32i -mabi=ilp32
LDFLAGS=-T link.ld
CFLAGS=$(ARCH) -nostdlib -nostartfiles -ffreestanding -g

.SECONDARY:

programs: $(PROGRAM_HEXS)

# Compile individual object files
programs/%.o: programs/%.c
	riscv64-unknown-elf-gcc $(CFLAGS) -c $^ -o $@

# Link object file with start to get elf
programs/%.elf:	programs/%.o programs/start.S
	riscv64-unknown-elf-gcc $(CFLAGS) $(LDFLAGS) $^ -o $@

programs/%.hex: programs/%.elf
	riscv64-unknown-elf-objcopy -O verilog --verilog-data-width 4 $^ $@
# we need data-width 4 to ensure that this can be loaded by the current ROM design
# (which uses a 4-byte wide array)