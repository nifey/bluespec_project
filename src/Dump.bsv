package Dump;
	import Defines::*;
	import StmtFSM::*;
	import FIFO::*;
	import BRAM::*;
	import CBus::*;

	(* synthesize *)
	module mkDump (IWithCBus#(Bus, Ifc_Accelerator));
		let ifc <- exposeCBusIFC(mkDumpInternal);
		return ifc;
	endmodule

	module [ModWithBus] mkDumpInternal(Ifc_Accelerator);
		FIFO#(MemRequest) requestFIFOA <- mkFIFO1;
		FIFO#(Bit#(BusDataWidth)) responseFIFOA <- mkFIFO1;

		BusAddr address = BusAddr{a:cfg_Dump_addr, o:0};
		Reg#(TCfgStart) csr_start <- mkCBRegRW(address + cfg_start_offset, 0);
		Reg#(Bool) file_opened <- mkReg(False);
		let file <- mkReg(InvalidFile);

		rule open_file (!file_opened);
			String dumpFile = "output.hex";
			File f <- $fopen(dumpFile, "w");
			if (f == InvalidFile) begin
				$display("Cannot open output.hex file");
				$finish(0);
			end
			file_opened <= True;
			file <= f;
		endrule

		Reg#(Bit#(MemAddrWidth)) i <- mkRegU;
		let actions =
		seq
			while (csr_start == 0) action
			endaction
			$display("Dumping memory contents");
			for (i <= 0; i<1024; i <= i + 1) seq
				requestFIFOA.enq(makeReadRequest(i));
				$fwrite(file, "%x\n", responseFIFOA.first()); responseFIFOA.deq();
			endseq
		endseq;

		mkAutoFSM(actions);

		interface MemClient portA;
			interface Get request = fifoToGet(requestFIFOA);
			interface Put response = fifoToPut(responseFIFOA);
		endinterface
	endmodule
endpackage
