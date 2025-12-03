.PHONY: practice run-practice clean

practice:
	iverilog -o practice -c practice.txt

run-practice: practice
	vvp practice

clean:
	rm practice