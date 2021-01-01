package TransposeBox;
	import FIFO::*;
	import GetPut::*;
	import SpecialFIFOs::*;
	import Vector::*;

	function ActionValue#(Maybe#(t)) permute(Maybe#(t) input_data, Reg#(Vector#(3, Maybe#(t))) data, Bool s);
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
					return data[3- 1];
				endactionvalue
			);
		end
	endfunction

	interface Ifc_TransposeBox#(numeric type word_size);
		interface Put#(Maybe#(Bit#(word_size))) put_element;
		interface Get#(Maybe#(Bit#(word_size))) get_element;
		method Action clear;
	endinterface 

	module mkTransposeBox (Ifc_TransposeBox#(word_size));
		Reg#(Bit#(4)) counter1 <- mkReg(0);
		Reg#(Bit#(2)) counter2 <- mkReg(0);

		Reg#(Vector#(3, Maybe#(Bit#(word_size)))) data1 <- mkReg(replicate(Invalid));
		Reg#(Vector#(3, Maybe#(Bit#(word_size)))) data2 <- mkReg(replicate(Invalid));
		Reg#(Vector#(3, Maybe#(Bit#(word_size)))) data3 <- mkReg(replicate(Invalid));

		FIFO#(Maybe#(Bit#(word_size))) inputFIFO <- mkPipelineFIFO;
		FIFO#(Maybe#(Bit#(word_size))) outputFIFO <- mkPipelineFIFO;

		rule step;
			Bool s1 = (counter1 <= 2 && counter2 >= 1);
			Bool s2 = (counter1 <= 1 && counter2 >= 2);
			Bool s3 = (counter1 <= 0 && counter2 >= 3);

			let res1 <- permute(inputFIFO.first(), data1, s1); inputFIFO.deq();
			let res2 <- permute(res1 , data2, s2);
			let res3 <- permute(res2 , data3, s3);
			outputFIFO.enq(res3);

			if (counter1 == 3) begin
				counter1 <= 0;
				counter2 <= counter2 + 1;
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
			data1 <= replicate(Invalid);
			data2 <= replicate(Invalid);
			data3 <= replicate(Invalid);
		endmethod
	endmodule

endpackage
