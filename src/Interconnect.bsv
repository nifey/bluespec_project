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
		FIFO#(Bit#(BusDataWidth)) responseFIFOA <- mkFIFO1;
		FIFO#(MemRequest) requestFIFOB <- mkSizedFIFO(2);
		FIFO#(Bit#(BusDataWidth)) responseFIFOB <- mkFIFO1;

		Vector#(MaxInitiators, FIFO#(MemRequest)) requests <- replicateM (mkFIFO1);
		Vector#(MaxInitiators, FIFO#(Bit#(BusDataWidth))) responses <- replicateM (mkFIFO1);
		FIFO#(Bit#(5)) inflightA <- mkSizedFIFO(3);
		FIFO#(Bit#(5)) inflightB <- mkSizedFIFO(3);

		for (Bit#(5) i=0; i < max_initiators; i = i + 1) 
			rule clients_to_server_A;
				let req = requests[i].first(); requests[i].deq();
				if (req.write) 
					inflightA.enq(5'h1f);
				else
					inflightA.enq(i);
				requestFIFOA.enq(req);
			endrule

		for (Bit#(5) i=0; i < max_initiators; i = i + 1) 
			rule clients_to_server_B;
				let req = requests[i].first(); requests[i].deq();
				if (req.write) 
					inflightB.enq(5'h1f);
				else
					inflightB.enq(i);
				requestFIFOB.enq(req);
			endrule

		for (Bit#(5) i=0; i < max_initiators; i = i + 1) 
			rule server_A_to_clients;
				let id = inflightA.first(); inflightA.deq();
				if (id != 5'h1f) begin
					let res = responseFIFOA.first(); responseFIFOA.deq();
					responses[id].enq(res);
				end
			endrule

		for (Bit#(5) i=0; i < max_initiators; i = i + 1) 
			rule server_B_to_clients;
				let id = inflightB.first(); inflightB.deq();
				if (id != 5'h1f) begin
					let res = responseFIFOB.first(); responseFIFOB.deq();
					responses[id].enq(res);
				end
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
