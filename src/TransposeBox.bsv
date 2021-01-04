package TransposeBox;
	import FIFO::*;
	import GetPut::*;
	import SpecialFIFOs::*;
	import Vector::*;

	function ActionValue#(Maybe#(t)) permute(Maybe#(t) input_data, Reg#(Vector#(vsize, Maybe#(t))) data, Bool s)
		provisos (Add#(1, a, vsize));
		// Basic Permutation Circuit
		if (s) begin
			return(
				actionvalue
					// Rotate the shift register
					data <= rotateR(data);
					// Bypass the input value to the output
					return input_data;
				endactionvalue
			);
		end
		else begin
			return(
				actionvalue
					// Put input into the shift register
					data <= shiftInAt0(data, input_data);
					// Get output from the shift register
					return last(data);
				endactionvalue
			);
		end
	endfunction

	interface Ifc_TransposeBox#(numeric type word_size, numeric type matrix_dimension);
		interface Put#(Maybe#(Bit#(word_size))) put_element;
		interface Get#(Maybe#(Bit#(word_size))) get_element;
		method Action clear;
	endinterface 

	module mkTransposeBox (Ifc_TransposeBox#(word_size, matrix_dimension))
		provisos (
			Add#(num_stages, 1, matrix_dimension),
			Add#(1, a, num_stages),
			Log#(num_stages, width)
		);
		Reg#(Bit#(width)) counter1 <- mkReg(0);
		Reg#(Bit#(width)) counter2 <- mkReg(0);

		Vector#(num_stages, Reg#(Vector#(num_stages, Maybe#(Bit#(word_size))))) data <- replicateM(mkReg(replicate(Invalid)));

		FIFO#(Maybe#(Bit#(word_size))) inputFIFO <- mkSizedFIFO(2);
		FIFO#(Maybe#(Bit#(word_size))) outputFIFO <- mkSizedFIFO(2);

		let num_stages = valueOf(num_stages);

		rule step;
			Bool s = (counter1 <= fromInteger(num_stages) - 1 && counter2 >= 1);
			Maybe#(Bit#(word_size)) res <- permute(inputFIFO.first(), data[0], s); inputFIFO.deq();
			for (Integer i = 2; i <= num_stages; i = i + 1) begin
				s = (counter1 <= fromInteger(num_stages - i)) && counter2 >= fromInteger(i);
				res <- permute(res , data[i-1], s);
			end
			outputFIFO.enq(res);

			if (counter1 == fromInteger(num_stages)) begin
				counter1 <= 0;
				if (counter2 == fromInteger(num_stages)) begin
					counter2 <= 0;
				end
				else begin
					counter2 <= counter2 + 1;
				end
			end
			else begin
				counter1 <= counter1 + 1;
			end
		endrule

		interface Get get_element = fifoToGet(outputFIFO);
		interface Put put_element = fifoToPut(inputFIFO);

		method Action clear;
			counter1 <= 0;
			counter2 <= 0;
			for (Integer i = 0; i < num_stages; i = i + 1) begin
				data[i] <= replicate(Invalid);
			end
		endmethod
	endmodule

endpackage
