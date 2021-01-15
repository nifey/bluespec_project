default: build memory.hex compile link simulate

build:
	@echo Creating build directory
	mkdir build

memory.hex:
	@echo Generating input memory
	g++ gen_memory.cpp
	./a.out
	rm a.out
	@echo Finished Generating input memory

.PHONY: compile
compile:
	@echo Compiling...
	bsc -u -q -sim -simdir build -bdir build -info-dir . -keep-fires -p %/Libraries:./src -g mkTestbench -no-warn-action-shadowing -suppress-warnings G0010:G0020:G0023:G0024:G0036:T0054 src/Testbench.bsv 
	@echo Compilation finished

.PHONY: link
link:
	@echo Linking...
	bsc -e mkTestbench -sim -o build/out -simdir build -p %/Libraries:./src -bdir build -keep-fires 
	@echo Linking finished

.PHONY: simulate
simulate:
	@echo Simulation...
	build/out 
	@echo Simulation finished

.PHONY: clean
clean:
	exec rm -f build/*.bo
	exec rm -f build/*.ba
	exec rm -f build/*.o

.PHONY: full_clean
full_clean:
	rm build/*
