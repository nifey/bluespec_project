package Accelerator;
	import Defines::*;
	import CBus::*;
	import Interconnect::*;
	import AccelVC::*;
	import AccelVX::*;
	import AccelMT::*;
	import Dump::*;
	import Connectable::*;

	(* synthesize *)
	module mkAccelerator (IWithCBus#(Bus, Ifc_Accelerator));
		let ifc <- exposeCBusIFC(mkAcceleratorInternal);
		return ifc;
	endmodule

	module [ModWithBus] mkAcceleratorInternal (Ifc_Accelerator);
		Ifc_Interconnect interconnect <- mkInterconnect(5'h16);

		Ifc_Accelerator dump <- collectCBusIFC(mkDump);
		mkConnection(dump.portA, interconnect.servers[0]);

		Ifc_Accelerator accel0 <- collectCBusIFC(mkAccelMT(0));
		mkConnection(accel0.portA, interconnect.servers[1]);
		mkConnection(accel0.portB, interconnect.servers[2]);

		Ifc_Accelerator accel1 <- collectCBusIFC(mkAccelMT(1));
		mkConnection(accel1.portA, interconnect.servers[3]);
		mkConnection(accel1.portB, interconnect.servers[4]);

		interface MemClient portA = interconnect.portA;
		interface MemClient portB = interconnect.portB;
	endmodule

endpackage
