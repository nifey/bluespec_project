default: compile link simulate

.PHONY: compile
compile:
	@echo Compiling...
	bsc -u -q -sim -simdir build -bdir build -info-dir . -keep-fires -p %/Libraries:./src -g mkTestbench  src/Testbench.bsv 
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
