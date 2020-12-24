package Testbench;
	import Accelerator::*;
	import AccelVC::*;
	import AccelVX::*;
	import AccelMT::*;
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
		IWithCBus#(Bus, Ifc_Accelerator) accel0 <- mkAccelMT(0);
		mkConnection(accel0.device_ifc.portA, memory.portA);
		mkConnection(accel0.device_ifc.portB, memory.portB);

		Bit#(6) cfg_MT0_addr = cfg_MT_addr + (0*3);

		let test =
		seq
			delay(10);
			accel0.cbus_ifc.write(cfg_MT0_addr + 1, 20);
			accel0.cbus_ifc.write(cfg_MT0_addr + 2, 40);
			accel0.cbus_ifc.write(cfg_MT0_addr + 0, unpack('1));
			delay(100);
			$finish(0);
		endseq;

		mkAutoFSM(test);
	endmodule
endpackage
