package AccelMT;
	import Defines::*;
	import StmtFSM::*;
	import BRAM::*;
	import FIFO::*;
	import SpecialFIFOs::*;
	import CBus::*;
	import Clocks::*;
	import TransposeBox::*;

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
		Reg#(TDimension) matrix_block_rows <- mkRegU;
		Reg#(TDimension) matrix_block_cols <- mkRegU;
		Reg#(TPointer) matrix_src_data <- mkRegU;
		Reg#(TPointer) matrix_dst_data <- mkRegU;
		Reg#(TPointer) src_end_address <- mkRegU;
		Reg#(TPointer) dst_end_address <- mkRegU;

		Ifc_TransposeBox#(32, 8) transpose_box <- mkTransposeBox;

		FIFO#(TPointer) srcBlockAddrFIFO <- mkSizedFIFO(8);
		FIFO#(TPointer) dstBlockAddrFIFO <- mkSizedFIFO(8);
		FIFO#(TPointer) srcRowAddrFIFO <- mkSizedFIFO(8);
		FIFO#(TPointer) dstRowAddrFIFO <- mkSizedFIFO(8);

		// Registers used as loop iterators
		Reg#(Bool) transpose_done <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) i <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) j <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) k <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) l <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) m <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) n <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) o <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) p <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) q <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) r <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) s <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) t <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) u <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) v <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) w <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) x <- mkRegU;
		Reg#(Bit#(MemAddrWidth)) y <- mkRegU;

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
						matrix_block_rows <= rows;
						matrix_block_cols <= cols;
					endaction
				endpar
				$display("MT", id, " > Matrix A = %d x %d", matrix_src_rows, matrix_src_cols);
				$display("MT", id, " > Matrix B = %d x %d", matrix_block_rows, matrix_block_cols);
				if (matrix_src_rows == matrix_block_cols && matrix_src_cols == matrix_block_rows) seq
					// Matrix dimensions are correct
					// Load data source address
					par
						requestFIFOA.enq(makeReadRequest(csr_src + 1));
						requestFIFOB.enq(makeReadRequest(csr_dst + 1));

						// After dimension check, these registers are reused
						// to hold the number of blocks in x and y dimension
						action
							matrix_block_rows <= (matrix_block_cols >> 3);
							matrix_block_cols <= (matrix_block_rows >> 3);
						endaction

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
					par
						$display("MT", id, " Start transpose at time ", $time);
						action
							UInt#(32) num_elements = zeroExtend(matrix_src_rows) * zeroExtend(matrix_src_cols);
							src_end_address <= unpack(matrix_src_data + pack(num_elements));
							dst_end_address <= unpack(matrix_dst_data + pack(num_elements));
						endaction
						transpose_done <= False;
						transpose_box.clear;
						k <= matrix_src_data;
						n <= matrix_dst_data;
						u <= 0;
					endpar
					par
						for (i <= 0; i < zeroExtend(pack(matrix_block_rows)); i <= i + 1) seq
							for (j <= 0; j < zeroExtend(pack(matrix_block_cols)); j <= j + 1) action
								srcBlockAddrFIFO.enq(k);
								k <= k + 8;
							endaction
							k <= k + (zeroExtend(pack(matrix_src_cols)) << 3) - zeroExtend(pack(matrix_src_cols));
						endseq

						for (l <= 0; l < zeroExtend(pack(matrix_block_rows)); l <= l + 1) seq
							for (m <= 0; m < zeroExtend(pack(matrix_block_cols)); m <= m + 1) action
								dstBlockAddrFIFO.enq(n);
								n <= n + (zeroExtend(pack(matrix_src_rows)) << 3);
							endaction
							n <= n - zeroExtend(pack((matrix_src_rows * matrix_src_cols))) + 8;
						endseq

						for (o <= 0; o < zeroExtend(pack(matrix_block_rows)) * zeroExtend(pack(matrix_block_cols)); o <= o + 1) seq
							par
								action
									p <= srcBlockAddrFIFO.first;
									srcBlockAddrFIFO.deq;
								endaction
								action
									q <= dstBlockAddrFIFO.first;
									dstBlockAddrFIFO.deq;
								endaction
							endpar
							for (r <= 0; r < 8; r <= r + 1) par
								action
									srcRowAddrFIFO.enq(p);
									p <= p + zeroExtend(pack(matrix_src_cols));
								endaction
								action
									dstRowAddrFIFO.enq(q);
									q <= q + zeroExtend(pack(matrix_src_rows));
								endaction
							endpar
						endseq

						// Creates memory requests to fetch the src matrix
						for (y <= 0; y < (zeroExtend(pack(matrix_block_rows)) * zeroExtend(pack(matrix_block_cols)) << 3); y <= y + 1) seq
							action
								s <= srcRowAddrFIFO.first; srcRowAddrFIFO.deq;
							endaction
							for (t <= 0; t < 8; t <= t + 1) action
								requestFIFOA.enq(makeReadRequest(s));
								s <= s + 1;
							endaction
						endseq

						// Push fetched data into transpose_box (Row major order)
						seq
							for (x <= 0; x < zeroExtend(pack(matrix_src_rows * matrix_src_cols)); x <= x + 1) action
								transpose_box.put_element.put(tagged Valid responseFIFOA.first());
								responseFIFOA.deq();
							endaction
							while (!transpose_done) action
								transpose_box.put_element.put(Invalid);
							endaction
						endseq

						// Create memory requests to store the transposed matrix
						seq
							while (u < zeroExtend(pack(matrix_src_rows * matrix_src_cols))) seq
								action
									v <= dstRowAddrFIFO.first; dstRowAddrFIFO.deq;
								endaction

								w <= 0;
								while (w < 8) seq
									action
										let data <- transpose_box.get_element.get;
										case (data) matches
											tagged Valid .x : begin
												requestFIFOB.enq(makeWriteRequest(v, x));
												v <= v + 1;
												w <= w + 1;
											end
											tagged Invalid : noAction;
										endcase
									endaction
								endseq
								u <= u + 8;
							endseq
							transpose_done <= True;
						endseq
					endpar
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
