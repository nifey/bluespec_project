package AccelMT;
	import Defines::*;
	import StmtFSM::*;
	import BRAM::*;
	import FIFO::*;
	import SpecialFIFOs::*;
	import CBus::*;
	import Clocks::*;

	(* synthesize *)
	module mkAccelMT#(parameter Bit#(BusAddrWidth) id) (IWithCBus#(Bus, Ifc_Accelerator));
		let ifc <- exposeCBusIFC(mkAccelMTInternal(id));
		return ifc;
	endmodule

	module [ModWithBus] mkAccelMTInternal#(parameter Bit#(BusAddrWidth) id) (Ifc_Accelerator);
		FIFO#(MemRequest) requestFIFOA <- mkBypassFIFO;
		FIFO#(Bit#(BusDataWidth)) responseFIFOA <- mkBypassFIFO;
		FIFO#(MemRequest) requestFIFOB <- mkBypassFIFO;
		FIFO#(Bit#(BusDataWidth)) responseFIFOB <- mkBypassFIFO;

		BusAddr base_address = BusAddr{a:cfg_MT_addr + (id*3), o:0};
		Reg#(TCfgStart) csr_start <- mkCBRegRW(base_address + cfg_start_offset, 0);
		Reg#(TCfgDone) csr_done <- mkCBRegR(base_address + cfg_done_offset, 0);
		Reg#(TCfgError) csr_error <- mkCBRegR(base_address + cfg_error_offset, 0);

		Reg#(TPointer) csr_src <- mkCBRegW(base_address + cfg_arg1_offset, 0);
		Reg#(TPointer) csr_dst <- mkCBRegW(base_address + cfg_arg2_offset, 0);

		Reg#(Bit#(MemAddrWidth)) i <- mkRegU;
		let actions =
		seq
			while (csr_start == 0) action
			endaction
			delay(100);
			csr_done <= 0;
			$display("MT",id, "> Starting to work with input addresses: %x -> %x", csr_src, csr_dst);
			requestFIFOB.enq(makeWriteRequest(4, 'h33));
			for (i <= 0; i<64; i <= i + 4) seq
				requestFIFOA.enq(makeReadRequest(i));
				$display("MT", id, " > %d = %x",i, responseFIFOA.first()); responseFIFOA.deq();
			endseq
			csr_done <= 1;

			while (True) action
			endaction
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
