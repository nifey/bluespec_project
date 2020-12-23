package Accelerator;
	import Defines::*;
	import StmtFSM::*;
	import BRAM::*;
	import FIFO::*;
	import SpecialFIFOs::*;
	import CBus::*;

	interface Ifc_Accelerator;
		interface BRAMClient#(Bit#(MemAddrWidth), Bit#(BusDataWidth)) portA;
		interface BRAMClient#(Bit#(MemAddrWidth), Bit#(BusDataWidth)) portB;
	endinterface

	(* synthesize *)
	module mkAcceleratorTest(IWithCBus#(Bus, Ifc_Accelerator));
		let ifc <- exposeCBusIFC(mkAcceleratorSynth);
		return ifc;
	endmodule

	module [ModWithBus] mkAcceleratorSynth(Ifc_Accelerator);
		FIFO#(BRAMRequest#(Bit#(MemAddrWidth), Bit#(BusDataWidth))) requestFIFOA <- mkBypassFIFO;
		FIFO#(Bit#(BusDataWidth)) responseFIFOA <- mkBypassFIFO;
		FIFO#(BRAMRequest#(Bit#(MemAddrWidth), Bit#(BusDataWidth))) requestFIFOB <- mkBypassFIFO;
		FIFO#(Bit#(BusDataWidth)) responseFIFOB <- mkBypassFIFO;

		BusAddr address = BusAddr{a:7, o:0};
		Reg#(Bit#(32)) value <- mkCBRegRW(address, 0);

		let actions =
		seq
			while (value == 0) action
				$display ("Waiting");
			endaction
			requestFIFOA.enq(makeWriteRequest(0, value));
			requestFIFOA.enq(makeWriteRequest(2, value));
			requestFIFOA.enq(makeWriteRequest(4, value));

			requestFIFOB.enq(makeReadRequest(0));
			$display("%x => %x", 0, responseFIFOB.first());
			responseFIFOB.deq();
			requestFIFOB.enq(makeReadRequest(1));
			$display("%x => %x", 1, responseFIFOB.first());
			responseFIFOB.deq();
			requestFIFOB.enq(makeReadRequest(2));
			$display("%x => %x", 2, responseFIFOB.first());
			responseFIFOB.deq();
			requestFIFOB.enq(makeReadRequest(3));
			$display("%x => %x", 3, responseFIFOB.first());
			responseFIFOB.deq();
			requestFIFOB.enq(makeReadRequest(4));
			$display("%x => %x", 4, responseFIFOB.first());
			responseFIFOB.deq();
		endseq;

		mkAutoFSM(actions);

		interface BRAMClient portA;
			interface Get request = fifoToGet(requestFIFOA);
			interface Put response = fifoToPut(responseFIFOA);
		endinterface

		interface BRAMClient portB;
			interface Get request = fifoToGet(requestFIFOB);
			interface Put response = fifoToPut(responseFIFOB);
		endinterface
	endmodule
endpackage
