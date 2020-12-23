package Testbench;
	import Accelerator::*;
	import StmtFSM::*;
	import Defines::*;
	import BRAM::*;
	import Connectable::*;
	import Clocks::*;

	(* synthesize *)
	module mkTestbench(Empty);
		// Create the memory module using BRAM
		BRAM_Configure cfg = defaultValue;
		cfg.memorySize = 1024;
		cfg.loadFormat = tagged Hex "memory.hex";

		BRAM2Port#(Bit#(MemAddrWidth), Bit#(BusDataWidth)) memory <- mkBRAM2Server(cfg);
		Ifc_Accelerator accel <- mkAcceleratorTest();
		mkConnection(accel.portA, memory.portA);
		mkConnection(accel.portB, memory.portB);

		let test =
		seq
			delay(100);
			$finish(0);
		endseq;

		mkAutoFSM(test);
	endmodule
endpackage
