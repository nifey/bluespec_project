package Interconnect;
	import Defines::*;
	import FIFO::*;
	import Vector::*;
	import BRAM::*;
	import ClientServer::*;

	interface Ifc_Interconnect;
		interface Vector#(MaxInitiators, MemServer) servers;
		interface MemClient portA;
		interface MemClient portB;
	endinterface

	module mkInterconnect#(parameter Bit#(5) max_initiators) (Ifc_Interconnect);
		FIFO#(MemRequest) requestFIFOA <- mkSizedFIFO(2);
		FIFO#(Bit#(BusDataWidth)) responseFIFOA <- mkSizedFIFO(2);
		FIFO#(MemRequest) requestFIFOB <- mkSizedFIFO(2);
		FIFO#(Bit#(BusDataWidth)) responseFIFOB <- mkFIFO1;

		Vector#(MaxInitiators, FIFO#(MemRequest)) requests <- replicateM (mkFIFO1);
		Vector#(MaxInitiators, FIFO#(Bit#(BusDataWidth))) responses <- replicateM (mkFIFO1);
		FIFO#(Bit#(5)) inflightA <- mkSizedFIFO(3);
		FIFO#(Bit#(5)) inflightB <- mkFIFO1;

		for (Bit#(5) i=0; i < max_initiators; i = i + 1) 
			rule clients_to_server;
				let req = requests[i].first(); requests[i].deq();
				if (req.write) begin
					requestFIFOB.enq(req);
				end
				else begin
					inflightA.enq(i);
					requestFIFOA.enq(req);
				end
			endrule

		for (Bit#(5) i=0; i < max_initiators; i = i + 1) 
			rule server_to_clients;
				let id = inflightA.first(); inflightA.deq();
				let res = responseFIFOA.first(); responseFIFOA.deq();
				responses[id].enq(res);
			endrule

		interface servers = zipWith (toGPServer, requests, responses);

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
