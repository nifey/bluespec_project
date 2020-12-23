package Accelerator;
	import Defines::*;
	import StmtFSM::*;
	import BRAM::*;
	import FIFO::*;
	import SpecialFIFOs::*;

	interface Ifc_Accelerator;
		interface BRAMClient#(Bit#(MemAddrWidth), Bit#(BusDataWidth)) portA;
		interface BRAMClient#(Bit#(MemAddrWidth), Bit#(BusDataWidth)) portB;
	endinterface

	module mkAcceleratorTest(Ifc_Accelerator);
		Reg#(Bit#(10)) address <- mkReg(0);
		Reg#(Bit#(32)) counter <- mkReg(0);
		FIFO#(BRAMRequest#(Bit#(MemAddrWidth), Bit#(BusDataWidth))) requestFIFOA <- mkBypassFIFO;
		FIFO#(Bit#(BusDataWidth)) responseFIFOA <- mkFIFO1;
		FIFO#(BRAMRequest#(Bit#(MemAddrWidth), Bit#(BusDataWidth))) requestFIFOB <- mkBypassFIFO;
		FIFO#(Bit#(BusDataWidth)) responseFIFOB <- mkFIFO1;

		let actions =
		seq
			requestFIFOA.enq(makeWriteRequest(0, 10));
			requestFIFOA.enq(makeWriteRequest(2, 11));
			requestFIFOA.enq(makeWriteRequest(4, 12));

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
