.PHONY: practice run-practice clean

practice:
	iverilog -o practice -c cmdfile.txt

run-practice: practice
	vvp practice

clean:
	rm practice