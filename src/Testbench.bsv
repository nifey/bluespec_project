package Testbench;
	import Accelerator::*;
	import StmtFSM::*;
	import Defines::*;
	import BRAM::*;
	import Connectable::*;
	import Clocks::*;
	import CBus::*;

	(* synthesize *)
	module mkTestbench(Empty);
		// Create the memory module using BRAM
		BRAM_Configure cfg = defaultValue;
		cfg.memorySize = 1024;
		cfg.loadFormat = tagged Hex "memory.hex";

		BRAM2Port#(Bit#(MemAddrWidth), Bit#(BusDataWidth)) memory <- mkBRAM2Server(cfg);
		IWithCBus#(Bus, Ifc_Accelerator) accel <- mkAcceleratorTest;
		mkConnection(accel.device_ifc.portA, memory.portA);
		mkConnection(accel.device_ifc.portB, memory.portB);

		let test =
		seq
			delay(10);
			accel.cbus_ifc.write(7, 77);
			delay(100);
			$finish(0);
		endseq;

		mkAutoFSM(test);
	endmodule
endpackage
