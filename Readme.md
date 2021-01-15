# Bluespec Project

The objective of this project is to create accelerators in Bluespec System Verilog for the following functionalities
1. Vector XOR
2. Vector Copy
3. Matrix Transpose

# Instructions for execution

## 1. Input generation
First generate the input memory file by running the following commands.

$ g++ gen_memory.cpp
$ ./a.out

This will create two new files: memory.hex and gold.hex.
memory.hex is the initial content of the memory on which the accelerators will operate on.
gold.hex contains the correct state of memory after all the accelerator operations have completed.
We will use the gold.hex file to check for correctness.

The C++ code will print the values that has to be provided to the accelerators as input arguments.
If you change the C++ code, please update the correct input arguments in the src/Testbench.bsv file.

## 2. Running the simulation
To run the simulation, you can use make to compile and execute the simulation

$ make

The above command will compile the BSV code and start the simulation.
During the simulation the start and end time of different accelerator functions will be printed.

Please note that the last three operations in matrix transpose will print errors.
These error are not error in the BSV code. They are because of the dimensions mismatch of the input matrices.
It is there just to test if the matrix transpose accelerator is setting the Error bit when the dimensions of the input
matrices don't match.

## 3. Testing for correctness
After the simulation is complete, a file called output.hex will be created. It contains the hex dump of memory
after the accelerators finished processing.

We can use diff to check if the output is as expected by running the command
$ diff output.hex gold.hex

If the above command gives no output then all the accelerators have performed their operations correctly.

# Description of files

- src/AccelVX.bsv	: Contains accelerator module for vector XOR
- src/AccelVC.bsv	: Contains accelerator module for vector copy
- src/AccelMT.bsv	: Contains accelerator module for matrix transpose
- src/Accelerator.bsv	: Contains the mkAccelerator module which encapsulates all the accelerator modules and provides a unified CBus interface to the testbench
- src/Defines.bsv	: Contains constants, typedefs and functions that are needed in many other modules
- src/Dump.bsv		: Contains mkDump module which is just used to dump memory contents to file after simulation
- src/Interconnect.bsv	: Contains mkInterconnect module which connects all accelerator modules to memory
- src/Testbench.bsv	: Contains the testbench module which invokes all other accelerators
- src/TransposeBox.bsv	: Contains Transpose box module used in matrix transposition
- gen_memory.cpp	: C++ code to generate the input and output to the accelerators as hex files

In each of the AccelVX.bsv, AccelVC.bsv and AccelMT.bsv files, there will be a parameterized internal module that
implements the functionality.
In addition, there will be modules suffixed with numbers, which are just wrapper modules to the internal module.
