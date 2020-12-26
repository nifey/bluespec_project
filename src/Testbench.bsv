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

		IWithCBus#(Bus, Ifc_Accelerator) accelerators <- mkAccelerator;
		mkConnection(accelerators.device_ifc.portA, memory.portA);
		mkConnection(accelerators.device_ifc.portB, memory.portB);

		Bit#(6) cfg_MT0_addr = cfg_MT_addr + (0*3);
		Bit#(6) cfg_MT1_addr = cfg_MT_addr + (1*3);

		let test =
		seq
			delay(10);
			accelerators.cbus_ifc.write(cfg_MT0_addr + 1, 20);
			accelerators.cbus_ifc.write(cfg_MT0_addr + 2, 40);
			accelerators.cbus_ifc.write(cfg_MT0_addr + 0, unpack('1));
			delay(10);
			accelerators.cbus_ifc.write(cfg_MT1_addr + 1, 100);
			accelerators.cbus_ifc.write(cfg_MT1_addr + 2, 200);
			accelerators.cbus_ifc.write(cfg_MT1_addr + 0, unpack('1));
			delay(1000);

			// Calling the dumper to dump memory contents
			accelerators.cbus_ifc.write(cfg_Dump_addr, unpack('1));

			while (True) action
			endaction
		endseq;

		mkAutoFSM(test);
	endmodule
endpackage
