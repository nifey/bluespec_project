package AccelVX;
	import Defines::*;
	import StmtFSM::*;
	import BRAM::*;
	import FIFO::*;
	import SpecialFIFOs::*;
	import CBus::*;

	(* synthesize *)
	module mkAccelVX#(parameter Bit#(BusAddrWidth) id) (IWithCBus#(Bus, Ifc_Accelerator));
		let ifc <- exposeCBusIFC(mkAccelVXInternal(id));
		return ifc;
	endmodule

	module [ModWithBus] mkAccelVXInternal#(parameter Bit#(BusAddrWidth) id) (Ifc_Accelerator);
		FIFO#(MemRequest) requestFIFOA <- mkBypassFIFO;
		FIFO#(Bit#(BusDataWidth)) responseFIFOA <- mkBypassFIFO;
		FIFO#(MemRequest) requestFIFOB <- mkBypassFIFO;
		FIFO#(Bit#(BusDataWidth)) responseFIFOB <- mkBypassFIFO;

		BusAddr base_address = BusAddr{a:cfg_VX_addr + (id*3), o:0};
		Reg#(TCfgStart) csr_start <- mkCBRegRW(base_address + cfg_start_offset, 0);
		Reg#(TCfgDone) csr_done <- mkCBRegR(base_address + cfg_done_offset, 0);

		Reg#(TPointer) csr_src_a <- mkCBRegW(base_address + cfg_arg1_offset, 0);
		Reg#(TPointer) csr_src_b <- mkCBRegW(base_address + cfg_arg2_offset, 0);
		Reg#(TPointer) csr_dst <- mkCBRegW(base_address + cfg_arg3_offset, 0);
		Reg#(TBlockSize) csr_block_size <- mkCBRegW(base_address + cfg_arg4_offset, 0);

		let actions =
		seq
			while (csr_start == 0) action
				$display("VX",id, "> Waiting");
			endaction
			csr_done <= 0;
			$display("VX",id, "> Starting to work with input addresses: %x, %x", csr_src_a, csr_src_b);
			csr_done <= 1;
		endseq;

		mkAutoFSM(actions);

		interface MemClient portA;
			interface Get request = fifoToGet(requestFIFOA);
			interface Put response = fifoToPut(responseFIFOA);
		endinterface

		interface MemClient portB;
			interface Get request = fifoToGet(requestFIFOB);
			interface Put response = fifoToPut(responseFIFOB);
		endinterface
	endmodule
endpackage
