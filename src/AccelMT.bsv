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

		Reg#(TDimension) matrix_src_rows <- mkRegU;
		Reg#(TDimension) matrix_src_cols <- mkRegU;
		Reg#(TPointer) matrix_src_data <- mkRegU;
		Reg#(TDimension) matrix_dst_rows <- mkRegU;
		Reg#(TDimension) matrix_dst_cols <- mkRegU;
		Reg#(TPointer) matrix_dst_data <- mkRegU;

		Reg#(Bit#(MemAddrWidth)) i <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) j <- mkRegU;
		let actions =
		seq
			while (True) seq
				while (csr_start == 0) action
					// Waiting for request from processor
					noAction;
				endaction

				action
					// Reset the CSR bits
					$display("MT",id, "> Starting to work with input addresses: %x -> %x at time ", csr_src, csr_dst, $time);
					csr_done <= 0;
					csr_error <= 0;
				endaction

				// Step 1. Read matrix dimensions and check for mismatch
				par
					requestFIFOA.enq(makeReadRequest(csr_src));
					requestFIFOB.enq(makeReadRequest(csr_dst));
				endpar
				par
					action
						let dimensions = responseFIFOA.first(); responseFIFOA.deq();
						TDimension rows = unpack(pack(dimensions)[31:16]);
						TDimension cols = unpack(pack(dimensions)[15:0]);
						matrix_src_rows <= rows;
						matrix_src_cols <= cols;
					endaction
					action
						let dimensions = responseFIFOB.first(); responseFIFOB.deq();
						TDimension rows = unpack(pack(dimensions)[31:16]);
						TDimension cols = unpack(pack(dimensions)[15:0]);
						matrix_dst_rows <= rows;
						matrix_dst_cols <= cols;
					endaction
				endpar
				$display("MT", id, " > Matrix A = %d x %d", matrix_src_rows, matrix_src_cols);
				$display("MT", id, " > Matrix B = %d x %d", matrix_dst_rows, matrix_dst_cols);
				if (matrix_src_rows == matrix_dst_cols && matrix_src_cols == matrix_dst_rows) seq
					// Matrix dimensions are correct
					// Load data source address
					par
						requestFIFOA.enq(makeReadRequest(csr_src + 1));
						requestFIFOB.enq(makeReadRequest(csr_dst + 1));
					endpar
					par
						action
							let pointer = responseFIFOA.first(); responseFIFOA.deq();
							TPointer address = unpack(pointer);
							matrix_src_data <= address;
						endaction
						action
							let pointer = responseFIFOB.first(); responseFIFOB.deq();
							TPointer address = unpack(pointer);
							matrix_dst_data <= address;
						endaction
					endpar

					// Step 2. Do matrix transpose
					$display("MT", id, " Start transpose at time ", $time);
					for (i <= 0; i< extend(pack(matrix_src_rows)); i <= i + 1) seq
						for (j <= 0; j< extend(pack(matrix_src_cols)); j <= j + 1) seq
							action
								Bit#(MemAddrWidth) src_address = matrix_src_data + i * extend(pack(matrix_src_cols)) + j;
								requestFIFOA.enq(makeReadRequest(src_address));
							endaction
							action
								Bit#(MemAddrWidth) dst_address = matrix_dst_data + j * extend(pack(matrix_src_rows)) + i;
								requestFIFOB.enq(makeWriteRequest(dst_address, responseFIFOA.first()));
								responseFIFOA.deq();
							endaction
						endseq
					endseq
					$display("MT", id, " End transpose at time ", $time);

					action
						// Set the CSR bits
						csr_done <= 1;
						csr_start <= 0;
					endaction
				endseq
				else seq
					// Matrix dimensions don't match. Set Error bit.
					action
						csr_error <= 1;
						csr_done <= 1;
						csr_start <= 0;
					endaction
				endseq
				$display("MT", id, " Done with work at time ", $time);
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
