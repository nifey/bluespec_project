package Interconnect;
	import Defines::*;
	import FIFO::*;
	import FIFOF::*;
	import Vector::*;
	import BRAM::*;
	import ClientServer::*;

	function Bool isTrue(Bool value);
		return value;
	endfunction

	interface Ifc_Interconnect#(numeric type max_clients);
		interface Vector#(max_clients, MemServer) servers;
		interface MemClient portA;
		interface MemClient portB;
	endinterface

	module mkInterconnect (Ifc_Interconnect#(max_clients));
		// Port A is used for Read requests
		FIFO#(MemRequest) requestFIFOA <- mkSizedFIFO(8);
		FIFO#(Bit#(BusDataWidth)) responseFIFOA <- mkSizedFIFO(8);

		// Port B is used for Write requests
		FIFO#(MemRequest) requestFIFOB <- mkSizedFIFO(8);
		FIFO#(Bit#(BusDataWidth)) responseFIFOB <- mkFIFO1;

		Vector#(max_clients, FIFOF#(MemRequest)) requests <- replicateM (mkFIFOF1);
		Vector#(max_clients, FIFO#(Bit#(BusDataWidth))) responses <- replicateM (mkFIFO1);
		FIFO#(Bit#(TLog#(max_clients))) inflightA <- mkSizedFIFO(8);
		FIFO#(Bit#(TLog#(max_clients))) inflightB <- mkFIFO1;

		// State elements needed for arbiteration between clients
		Vector#(max_clients, Bool) init_vector = replicate(False);
		init_vector[0] = True;
		Reg#(Vector#(max_clients, Bool)) priority_vector <- mkReg(init_vector);
		Wire#(Vector#(max_clients, Bool)) grant_vector <- mkBypassWire;
		Vector#(max_clients, PulseWire) request_vector <- replicateM(mkPulseWire);

		Bit#(TLog#(max_clients)) imax_clients = fromInteger(valueOf(max_clients));

		// Whenever requests FIFO is not empty, send request
		for (Bit#(TLog#(max_clients)) i=0; i < imax_clients; i = i + 1) 
			rule request (requests[i].notEmpty);
				request_vector[i].send;
			endrule

		// This rule looks at all the requests and grants only one client (per cycle) to send MemRequest
		// Grants requests in a round robin manner
		rule arbiterate;
			Vector#(max_clients, Bool) grant_vector_local = replicate(False);
			Bool found = True;
			for (Integer x = 0; x < (2 * valueOf(max_clients)); x = x + 1)
			begin
				Integer y = (x % valueOf(max_clients));
				Integer y1 = ((x + 1) % valueOf(max_clients));
				if (priority_vector[y1]) found = False;
				if (!found && request_vector[y])
				begin
					grant_vector_local[y] = True;
					found = True;
				end
			end

			grant_vector <= grant_vector_local;
			if (any(isTrue,grant_vector_local))
			begin
				priority_vector <= rotateR(grant_vector_local);
			end
		endrule

		// If granted, process the MemRequest
		for (Bit#(TLog#(max_clients)) i=0; i < imax_clients; i = i + 1) 
			rule clients_to_server if (grant_vector[i]);
				let req = requests[i].first(); requests[i].deq();
				if (req.write) begin
					requestFIFOB.enq(req);
				end
				else begin
					inflightA.enq(i);
					requestFIFOA.enq(req);
				end
			endrule

		// Send the read response of Port A back to the corresponding client
		// Port B is only used for writes and so it does not produce any response
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
