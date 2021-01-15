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
		Ifc_Interconnect#(21) interconnect <- mkInterconnect;

		// This accelerator is just used to dump memory at the end of execution
		Ifc_Accelerator dump <- collectCBusIFC(mkDump);
		mkConnection(dump.portA, interconnect.servers[0]);

		// Vector XOR u8
		Ifc_Accelerator accel_VX_u8 <- collectCBusIFC(mkAccelVX8(0));
		mkConnection(accel_VX_u8.portA, interconnect.servers[1]);
		mkConnection(accel_VX_u8.portB, interconnect.servers[2]);

		// Vector XOR u16
		Ifc_Accelerator accel_VX_u16 <- collectCBusIFC(mkAccelVX16(1));
		mkConnection(accel_VX_u16.portA, interconnect.servers[3]);
		mkConnection(accel_VX_u16.portB, interconnect.servers[4]);

		// Vector XOR u32
		Ifc_Accelerator accel_VX_u32 <- collectCBusIFC(mkAccelVX32(2));
		mkConnection(accel_VX_u32.portA, interconnect.servers[5]);
		mkConnection(accel_VX_u32.portB, interconnect.servers[6]);

		// Vector Copy q7
		Ifc_Accelerator accel_VC_q7 <- collectCBusIFC(mkAccelVC8(0));
		mkConnection(accel_VC_q7.portA, interconnect.servers[7]);
		mkConnection(accel_VC_q7.portB, interconnect.servers[8]);

		// Vector Copy q15
		Ifc_Accelerator accel_VC_q15 <- collectCBusIFC(mkAccelVC16(1));
		mkConnection(accel_VC_q15.portA, interconnect.servers[9]);
		mkConnection(accel_VC_q15.portB, interconnect.servers[10]);

		// Vector Copy q31
		Ifc_Accelerator accel_VC_q31 <- collectCBusIFC(mkAccelVC32(2));
		mkConnection(accel_VC_q31.portA, interconnect.servers[11]);
		mkConnection(accel_VC_q31.portB, interconnect.servers[12]);

		// Vector Copy f32
		Ifc_Accelerator accel_VC_f32 <- collectCBusIFC(mkAccelVC32(3));
		mkConnection(accel_VC_f32.portA, interconnect.servers[13]);
		mkConnection(accel_VC_f32.portB, interconnect.servers[14]);

		// Matrix Transpose q15
		Ifc_Accelerator accel_MT_q15 <- collectCBusIFC(mkAccelMT16(0));
		mkConnection(accel_MT_q15.portA, interconnect.servers[15]);
		mkConnection(accel_MT_q15.portB, interconnect.servers[16]);

		// Matrix Transpose q31
		Ifc_Accelerator accel_MT_q31 <- collectCBusIFC(mkAccelMT32(1));
		mkConnection(accel_MT_q31.portA, interconnect.servers[17]);
		mkConnection(accel_MT_q31.portB, interconnect.servers[18]);

		// Matrix Transpose f32
		Ifc_Accelerator accel_MT_f32 <- collectCBusIFC(mkAccelMT32(2));
		mkConnection(accel_MT_f32.portA, interconnect.servers[19]);
		mkConnection(accel_MT_f32.portB, interconnect.servers[20]);

		interface MemClient portA = interconnect.portA;
		interface MemClient portB = interconnect.portB;
	endmodule

endpackage
