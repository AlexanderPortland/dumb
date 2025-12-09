# Dumb CPU
A very dumb 16-bit CPU. It only has one real register (`acc`), but has a basic stack and very simple control flow like procedure calls & conditional branches. The full list of instructions can be found [here](https://docs.google.com/spreadsheets/d/1c0boO_7xaOKxYpqUAhQFa4LIaI-Rz7ZPAWl9ut44rdk/edit?usp=sharing).

I want to try to implement some more complex features like pipelining, but rather than re-working this instruction set to be more amenable to expansion, I think I'll learn more from trying to implement an existing ISA like RISC-V. With what I've learned from this one, I can try to think about expandability in the next CPU from the start.

## Usage
The `to_dex` script can be used to build a readable executable file (`.rex`) into a dumb executable file (`.dex`) and then running `make run-cpu MEM=<path_to_dex>` will load the executable into the simulation's memory so that the CPU can read it and start executing. `check_programs` will also do that for every (`.rex`) program in a given directory and check that the execution's output matches with what was specified as expected in the `.rex` file.