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
		cfg.memorySize = 2048;
		cfg.loadFormat = tagged Hex "memory.hex";

		BRAM2Port#(Bit#(MemAddrWidth), Bit#(BusDataWidth)) memory <- mkBRAM2Server(cfg);

		IWithCBus#(Bus, Ifc_Accelerator) accelerators <- mkAccelerator;
		mkConnection(accelerators.device_ifc.portA, memory.portA);
		mkConnection(accelerators.device_ifc.portB, memory.portB);

		Bit#(6) cfg_VX_u8_addr = cfg_VX_addr + (0*5);
		Bit#(6) cfg_VX_u16_addr = cfg_VX_addr + (1*5);
		Bit#(6) cfg_VX_u32_addr = cfg_VX_addr + (2*5);

		Bit#(6) cfg_VC_q7_addr = cfg_VC_addr + (0*4);
		Bit#(6) cfg_VC_q15_addr = cfg_VC_addr + (1*4);
		Bit#(6) cfg_VC_q31_addr = cfg_VC_addr + (2*4);
		Bit#(6) cfg_VC_f32_addr = cfg_VC_addr + (3*4);

		Bit#(6) cfg_MT_q15_addr = cfg_MT_addr + (0*3);
		Bit#(6) cfg_MT_q31_addr = cfg_MT_addr + (1*3);
		Bit#(6) cfg_MT_f32_addr = cfg_MT_addr + (2*3);

		Reg#(Bit#(MemAddrWidth)) cfg_read <- mkRegU;

		let test =
		seq
			// 8 bit Vector XOR
			accelerators.cbus_ifc.write(cfg_VX_u8_addr + 1, 0);		// src a
			accelerators.cbus_ifc.write(cfg_VX_u8_addr + 2, 2);		// src b
			accelerators.cbus_ifc.write(cfg_VX_u8_addr + 3, 1024);		// dest
			accelerators.cbus_ifc.write(cfg_VX_u8_addr + 4, 5);		// block size
			accelerators.cbus_ifc.write(cfg_VX_u8_addr + 0, unpack('1));	// start bit
			cfg_read <= 0;
			while (cfg_read[1] == 0) action
				// Wait for accelerator to complete
				let read <- accelerators.cbus_ifc.read(cfg_VX_u8_addr + 0);
				cfg_read <= read;
			endaction

			// 16 bit Vector XOR
			accelerators.cbus_ifc.write(cfg_VX_u16_addr + 1, 4);		// src a
			accelerators.cbus_ifc.write(cfg_VX_u16_addr + 2, 7);		// src b
			accelerators.cbus_ifc.write(cfg_VX_u16_addr + 3, 1028);		// dest
			accelerators.cbus_ifc.write(cfg_VX_u16_addr + 4, 5);		// block size
			accelerators.cbus_ifc.write(cfg_VX_u16_addr + 0, unpack('1));	// start bit
			cfg_read <= 0;
			while (cfg_read[1] == 0) action
				// Wait for accelerator to complete
				let read <- accelerators.cbus_ifc.read(cfg_VX_u16_addr + 0);
				cfg_read <= read;
			endaction

			// 32 bit Vector XOR
			accelerators.cbus_ifc.write(cfg_VX_u32_addr + 1, 10);		// src a
			accelerators.cbus_ifc.write(cfg_VX_u32_addr + 2, 15);		// src b
			accelerators.cbus_ifc.write(cfg_VX_u32_addr + 3, 1034);		// dest
			accelerators.cbus_ifc.write(cfg_VX_u32_addr + 4, 5);		// block size
			accelerators.cbus_ifc.write(cfg_VX_u32_addr + 0, unpack('1));	// start bit
			cfg_read <= 0;
			while (cfg_read[1] == 0) action
				// Wait for accelerator to complete
				let read <- accelerators.cbus_ifc.read(cfg_VX_u32_addr + 0);
				cfg_read <= read;
			endaction

			// 8 bit Integer Vector Copy
			accelerators.cbus_ifc.write(cfg_VC_q7_addr + 1, 20);		// src
			accelerators.cbus_ifc.write(cfg_VC_q7_addr + 2, 1044);		// dest
			accelerators.cbus_ifc.write(cfg_VC_q7_addr + 3, 5);		// block size
			accelerators.cbus_ifc.write(cfg_VC_q7_addr + 0, unpack('1));	// start bit
			cfg_read <= 0;
			while (cfg_read[1] == 0) action
				// Wait for accelerator to complete
				let read <- accelerators.cbus_ifc.read(cfg_VC_q7_addr + 0);
				cfg_read <= read;
			endaction

			// 16 bit Integer Vector Copy
			accelerators.cbus_ifc.write(cfg_VC_q15_addr + 1, 22);		// src
			accelerators.cbus_ifc.write(cfg_VC_q15_addr + 2, 1046);		// dest
			accelerators.cbus_ifc.write(cfg_VC_q15_addr + 3, 5);		// block size
			accelerators.cbus_ifc.write(cfg_VC_q15_addr + 0, unpack('1));	// start bit
			cfg_read <= 0;
			while (cfg_read[1] == 0) action
				// Wait for accelerator to complete
				let read <- accelerators.cbus_ifc.read(cfg_VC_q15_addr + 0);
				cfg_read <= read;
			endaction

			// 32 bit Integer Vector Copy
			accelerators.cbus_ifc.write(cfg_VC_q31_addr + 1, 25);		// src
			accelerators.cbus_ifc.write(cfg_VC_q31_addr + 2, 1049);		// dest
			accelerators.cbus_ifc.write(cfg_VC_q31_addr + 3, 5);		// block size
			accelerators.cbus_ifc.write(cfg_VC_q31_addr + 0, unpack('1));	// start bit
			cfg_read <= 0;
			while (cfg_read[1] == 0) action
				// Wait for accelerator to complete
				let read <- accelerators.cbus_ifc.read(cfg_VC_q31_addr + 0);
				cfg_read <= read;
			endaction

			// 32 bit Float Vector Copy
			accelerators.cbus_ifc.write(cfg_VC_f32_addr + 1, 30);		// src
			accelerators.cbus_ifc.write(cfg_VC_f32_addr + 2, 1054);		// dest
			accelerators.cbus_ifc.write(cfg_VC_f32_addr + 3, 5);		// block size
			accelerators.cbus_ifc.write(cfg_VC_f32_addr + 0, unpack('1));	// start bit
			cfg_read <= 0;
			while (cfg_read[1] == 0) action
				// Wait for accelerator to complete
				let read <- accelerators.cbus_ifc.read(cfg_VC_f32_addr + 0);
				cfg_read <= read;
			endaction

			// 16 bit Integer Matrix Transpose
			accelerators.cbus_ifc.write(cfg_MT_q15_addr + 1, 35);		// src matrix
			accelerators.cbus_ifc.write(cfg_MT_q15_addr + 2, 1059);		// dest matrix
			accelerators.cbus_ifc.write(cfg_MT_q15_addr + 0, unpack('1));
			cfg_read <= 0;
			while (cfg_read[1] == 0) action
				// Wait for accelerator to complete
				let read <- accelerators.cbus_ifc.read(cfg_MT_q15_addr + 0);
				cfg_read <= read;
			endaction
			if (cfg_read[2] == 1) action
				$display("Error while doing Matrix transpose");
			endaction

			// 32 bit Integer Matrix Transpose
			accelerators.cbus_ifc.write(cfg_MT_q31_addr + 1, 275);		// src matrix
			accelerators.cbus_ifc.write(cfg_MT_q31_addr + 2, 1299);		// dest matrix
			accelerators.cbus_ifc.write(cfg_MT_q31_addr + 0, unpack('1));
			cfg_read <= 0;
			while (cfg_read[1] == 0) action
				// Wait for accelerator to complete
				let read <- accelerators.cbus_ifc.read(cfg_MT_q31_addr + 0);
				cfg_read <= read;
			endaction
			if (cfg_read[2] == 1) action
				$display("Error while doing Matrix transpose");
			endaction

			// 32 bit Float Matrix Transpose
			accelerators.cbus_ifc.write(cfg_MT_f32_addr + 1, 376);		// src matrix
			accelerators.cbus_ifc.write(cfg_MT_f32_addr + 2, 1400);		// dest matrix
			accelerators.cbus_ifc.write(cfg_MT_f32_addr + 0, unpack('1));
			cfg_read <= 0;
			while (cfg_read[1] == 0) action
				// Wait for accelerator to complete
				let read <- accelerators.cbus_ifc.read(cfg_MT_f32_addr + 0);
				cfg_read <= read;
			endaction
			if (cfg_read[2] == 1) action
				$display("Error while doing Matrix transpose");
			endaction

			// Now we run the three matrix transpose accelerators to check if they give
			// error for input matrices whose dimension does not match with destination matrix

			// 16 bit Integer Matrix Transpose
			accelerators.cbus_ifc.write(cfg_MT_q15_addr + 1, 477);		// src matrix
			accelerators.cbus_ifc.write(cfg_MT_q15_addr + 2, 1501);		// dest matrix
			accelerators.cbus_ifc.write(cfg_MT_q15_addr + 0, unpack('1));
			cfg_read <= 0;
			while (cfg_read[1] == 0) action
				// Wait for accelerator to complete
				let read <- accelerators.cbus_ifc.read(cfg_MT_q15_addr + 0);
				cfg_read <= read;
			endaction
			if (cfg_read[2] == 1) action
				$display("Error while doing Matrix transpose (Expected error)");
			endaction

			// 32 bit Integer Matrix Transpose
			accelerators.cbus_ifc.write(cfg_MT_q31_addr + 1, 477);		// src matrix
			accelerators.cbus_ifc.write(cfg_MT_q31_addr + 2, 1501);		// dest matrix
			accelerators.cbus_ifc.write(cfg_MT_q31_addr + 0, unpack('1));
			cfg_read <= 0;
			while (cfg_read[1] == 0) action
				// Wait for accelerator to complete
				let read <- accelerators.cbus_ifc.read(cfg_MT_q31_addr + 0);
				cfg_read <= read;
			endaction
			if (cfg_read[2] == 1) action
				$display("Error while doing Matrix transpose (Expected error)");
			endaction

			// 32 bit Float Matrix Transpose
			accelerators.cbus_ifc.write(cfg_MT_f32_addr + 1, 477);		// src matrix
			accelerators.cbus_ifc.write(cfg_MT_f32_addr + 2, 1501);		// dest matrix
			accelerators.cbus_ifc.write(cfg_MT_f32_addr + 0, unpack('1));
			cfg_read <= 0;
			while (cfg_read[1] == 0) action
				// Wait for accelerator to complete
				let read <- accelerators.cbus_ifc.read(cfg_MT_f32_addr + 0);
				cfg_read <= read;
			endaction
			if (cfg_read[2] == 1) action
				$display("Error while doing Matrix transpose (Expected error)");
			endaction

			// Calling the dumper to dump memory contents
			accelerators.cbus_ifc.write(cfg_Dump_addr, unpack('1));

			while (True) action
				// Wait for memory dumper to complete
				noAction;
			endaction
		endseq;

		mkAutoFSM(test);
	endmodule
endpackage
