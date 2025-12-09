.PHONY: cpu run-cpu clean

DESIGN_DIR=designs

cpu:
	cd $(DESIGN_DIR) && iverilog -o cpu-test -c cmdfile.txt

MEM ?=

run-cpu: cpu
	cd $(DESIGN_DIR) && vvp cpu-test $(if $(MEM),+memory_from_file=$(PWD)/$(MEM))

clean:
	rm $(DESIGN_DIR)/cpu-test