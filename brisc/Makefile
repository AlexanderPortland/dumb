.PHONY: run-cpu clean programs check programs/%.expected.new

DESIGN_DIR=designs

# SYNTHESIS & SIMULATION

$(DESIGN_DIR)/cpu-test:
	cd $(DESIGN_DIR) && iverilog -g2012 -o cpu-test -c cmdfile.txt

PROG ?= test

run-sim: $(DESIGN_DIR)/cpu-test programs/$(PROG).hex
	cd $(DESIGN_DIR) && vvp cpu-test +prog_file=../programs/$(PROG).hex $(if $(V),+v=v)

clean:
	rm -f $(DESIGN_DIR)/cpu-test
	rm -f programs/*.elf programs/*.o programs/*.hex

# Convert elf to binary file for reading
# programs/%.bin: programs/%.elf

# COMPILATION
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

# TESTING
PROGRAM_SNAPSHOTS := $(PROGRAM_SOURCES:.c=.expected.new)
check: $(PROGRAM_SNAPSHOTS)

programs/%.expected.new: programs/%.hex $(DESIGN_DIR)/cpu-test
	cd $(DESIGN_DIR) && vvp cpu-test +prog_file=../$< > ../$@
	@if [ -f programs/$*.expected ]; then \
		echo "Comparing with expected output..."; \
		diff programs/$*.expected programs/$*.expected.new && echo "MATCH: $*" && rm programs/$*.expected.new || (echo "DIFF: $*" && exit 1); \
	else \
		echo "No expected output file found" && exit 1; \
	fi