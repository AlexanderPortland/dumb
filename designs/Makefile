.PHONY: practice run-practice clean

practice:
	iverilog -o practice -c cmdfile.txt

MEM ?=

run-practice: practice
	vvp practice $(if $(MEM),+memory_from_file=$(MEM))

clean:
	rm practice