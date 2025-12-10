.PHONY: cpu run-cpu clean

DESIGN_DIR=core
BIN_NAME=cpu-test

cpu:
	cd $(DESIGN_DIR) && iverilog -o $(BIN_NAME) -c cmdfile.txt

MEM ?=

run-cpu: cpu
	cd $(DESIGN_DIR) && vvp $(BIN_NAME) $(if $(MEM),+memory_from_file=$(PWD)/$(MEM))

clean:
	rm $(DESIGN_DIR)/$(BIN_NAME)