package AccelVX;
	import Defines::*;
	import StmtFSM::*;
	import BRAM::*;
	import FIFO::*;
	import SpecialFIFOs::*;
	import CBus::*;
	import Clocks::*;
	
	interface Ifc_AccelVX#(numeric type word_size);
		interface MemClient portA;
		interface MemClient portB;
	endinterface

	(* synthesize *)
	module mkAccelVX8#(parameter Bit#(BusAddrWidth) id) (IWithCBus#(Bus, Ifc_Accelerator));
		let ifc <- exposeCBusIFC(mkAccelVX8Wrapper(id));
		return ifc;
	endmodule

	(* synthesize *)
	module mkAccelVX16#(parameter Bit#(BusAddrWidth) id) (IWithCBus#(Bus, Ifc_Accelerator));
		let ifc <- exposeCBusIFC(mkAccelVX16Wrapper(id));
		return ifc;
	endmodule

	(* synthesize *)
	module mkAccelVX32#(parameter Bit#(BusAddrWidth) id) (IWithCBus#(Bus, Ifc_Accelerator));
		let ifc <- exposeCBusIFC(mkAccelVX32Wrapper(id));
		return ifc;
	endmodule

	module [ModWithBus] mkAccelVX8Wrapper#(parameter Bit#(BusAddrWidth) id) (Ifc_Accelerator);
		Ifc_AccelVX#(8) accelerator <- mkAccelVXInternal(id);
		interface MemClient portA = accelerator.portA;
		interface MemClient portB = accelerator.portB;
	endmodule
	
	module [ModWithBus] mkAccelVX16Wrapper#(parameter Bit#(BusAddrWidth) id) (Ifc_Accelerator);
		Ifc_AccelVX#(16) accelerator <- mkAccelVXInternal(id);
		interface MemClient portA = accelerator.portA;
		interface MemClient portB = accelerator.portB;
	endmodule

	module [ModWithBus] mkAccelVX32Wrapper#(parameter Bit#(BusAddrWidth) id) (Ifc_Accelerator);
		Ifc_AccelVX#(32) accelerator <- mkAccelVXInternal(id);
		interface MemClient portA = accelerator.portA;
		interface MemClient portB = accelerator.portB;
	endmodule

	module [ModWithBus] mkAccelVXInternal#(parameter Bit#(BusAddrWidth) id) (Ifc_AccelVX#(word_size))
		provisos (
			Add#(a, word_size, 32),
			Add#(b, 8, word_size)
		);

		FIFO#(MemRequest) requestFIFOA <- mkBypassFIFO;
		FIFO#(Bit#(BusDataWidth)) responseFIFOA <- mkBypassFIFO;
		FIFO#(MemRequest) requestFIFOB <- mkBypassFIFO;
		FIFO#(Bit#(BusDataWidth)) responseFIFOB <- mkBypassFIFO;

		BusAddr base_address = BusAddr{a:cfg_VX_addr + (id*5), o:0};
		Reg#(TCfgStart) csr_start <- mkCBRegRW(base_address + cfg_start_offset, 0);
		Reg#(TCfgDone) csr_done <- mkCBRegRW(base_address + cfg_done_offset, 0);

		Reg#(TPointer) csr_src_a <- mkCBRegW(base_address + cfg_arg1_offset, 0);
		Reg#(TPointer) csr_src_b <- mkCBRegW(base_address + cfg_arg2_offset, 0);
		Reg#(TPointer) csr_dst <- mkCBRegW(base_address + cfg_arg3_offset, 0);
		Reg#(TPointer) csr_block_size <- mkCBRegW(base_address + cfg_arg4_offset, 0);

		Reg#(TPointer) src_a_address <- mkRegU;
		Reg#(TPointer) src_b_address <- mkRegU;
		Reg#(TPointer) dst_address <- mkRegU;

		FIFO#(Bit#(MemAddrWidth)) dataFIFO <- mkSizedFIFO(8);
		Reg#(Bit#(MemAddrWidth)) src_count <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) dst_count <- mkRegU;
		Reg#(Bool) xor_done <- mkRegU;

		let word_size = valueOf(word_size);

		let actions =
		seq
			while (True)
			seq
				while (csr_start == 0)
				action
					noAction;
				endaction
			
				action
					$display("VX",id, "> Starting to work with input addresses: %x and %x at time ", csr_src_a, csr_src_b, $time);
					csr_done <= 0;
					src_a_address <= csr_src_a;
					src_b_address <= csr_src_b;
					dst_address <= csr_dst;
					src_count <= csr_block_size;
					dst_count <= csr_block_size;
					xor_done <= False;
				endaction
				par
					while (src_count > 0)
					seq
						par
							requestFIFOA.enq(makeReadRequest(src_a_address));
							requestFIFOB.enq(makeReadRequest(src_b_address));
						endpar
						action
							dataFIFO.enq((responseFIFOA.first())^(responseFIFOB.first())); responseFIFOA.deq(); responseFIFOB.deq();
							src_a_address <= src_a_address + 1;
							src_b_address <= src_b_address + 1;
						endaction
						if (src_count > fromInteger(32/word_size))
						action
							src_count <= src_count - fromInteger(32/word_size);
						endaction
						else
						action
							src_count <= 0;
							xor_done <= True;
						endaction
					endseq

					while (dst_count > 0)
					seq
						if (dst_count >= fromInteger(32/word_size))
						action
							requestFIFOB.enq(makeWriteRequest(dst_address, dataFIFO.first));
							dataFIFO.deq;
							dst_address <= dst_address + 1;
							dst_count <= dst_count - fromInteger(32/word_size);
						endaction
						else
						seq
							// Last 32 bit word
							await (xor_done == True);
							requestFIFOB.enq(makeReadRequest(dst_address));
							action
								let existing_word = responseFIFOB.first; responseFIFOB.deq;
								let word_to_be_written = dataFIFO.first; dataFIFO.deq;
								let index = 32 - dst_count * fromInteger(word_size);
								Bit#(MemAddrWidth) mask = (1 << index) - 1;
								let final_word = (existing_word & mask) | (word_to_be_written & (invert(mask)));
								requestFIFOB.enq(makeWriteRequest(dst_address, final_word));
							endaction
							dst_count <= 0;
						endseq
					endseq
				endpar
				action
					csr_done <= 1;
					csr_start <= 0;
				endaction
				$display("VX", id, "> Done with work at time ", $time);
			endseq		
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
