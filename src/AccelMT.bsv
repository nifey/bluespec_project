package AccelMT;
	import Defines::*;
	import StmtFSM::*;
	import BRAM::*;
	import FIFO::*;
	import SpecialFIFOs::*;
	import CBus::*;
	import Clocks::*;
	import TransposeBox::*;

	interface Ifc_AccelMT#(numeric type word_size);
		interface MemClient portA;
		interface MemClient portB;
	endinterface

	(* synthesize *)
	module mkAccelMT16#(parameter Bit#(BusAddrWidth) id) (IWithCBus#(Bus, Ifc_Accelerator));
		let ifc <- exposeCBusIFC(mkAccelMT16Wrapper(id));
		return ifc;
	endmodule

	(* synthesize *)
	module mkAccelMT32#(parameter Bit#(BusAddrWidth) id) (IWithCBus#(Bus, Ifc_Accelerator));
		let ifc <- exposeCBusIFC(mkAccelMT32Wrapper(id));
		return ifc;
	endmodule

	module [ModWithBus] mkAccelMT16Wrapper#(parameter Bit#(BusAddrWidth) id) (Ifc_Accelerator);
		Ifc_AccelMT#(16) accelerator <- mkAccelMTInternal(id);
		interface MemClient portA = accelerator.portA;
		interface MemClient portB = accelerator.portB;
	endmodule

	module [ModWithBus] mkAccelMT32Wrapper#(parameter Bit#(BusAddrWidth) id) (Ifc_Accelerator);
		Ifc_AccelMT#(32) accelerator <- mkAccelMTInternal(id);
		interface MemClient portA = accelerator.portA;
		interface MemClient portB = accelerator.portB;
	endmodule

	module [ModWithBus] mkAccelMTInternal#(parameter Bit#(BusAddrWidth) id) (Ifc_AccelMT#(word_size))
		provisos (
			Add#(a, word_size, 32),
			Add#(b, 16, word_size)
		);
		FIFO#(MemRequest) requestFIFOA <- mkBypassFIFO;
		FIFO#(Bit#(BusDataWidth)) responseFIFOA <- mkBypassFIFO;
		FIFO#(MemRequest) requestFIFOB <- mkBypassFIFO;
		FIFO#(Bit#(BusDataWidth)) responseFIFOB <- mkBypassFIFO;

		BusAddr base_address = BusAddr{a:cfg_MT_addr + (id*3), o:0};
		Reg#(TCfgStart) csr_start <- mkCBRegRW(base_address + cfg_start_offset, 0);
		Reg#(TCfgDone) csr_done <- mkCBRegRW(base_address + cfg_done_offset, 0);
		Reg#(TCfgError) csr_error <- mkCBRegRW(base_address + cfg_error_offset, 0);

		Reg#(TPointer) csr_src <- mkCBRegW(base_address + cfg_arg1_offset, 0);
		Reg#(TPointer) csr_dst <- mkCBRegW(base_address + cfg_arg2_offset, 0);

		Reg#(TDimension) matrix_src_rows <- mkRegU;
		Reg#(TDimension) matrix_src_cols <- mkRegU;
		Reg#(TDimension) matrix_block_rows <- mkRegU;
		Reg#(TDimension) matrix_block_cols <- mkRegU;
		Reg#(TPointer) matrix_src_data <- mkRegU;
		Reg#(TPointer) matrix_dst_data <- mkRegU;

		Ifc_TransposeBox#(word_size, 8) transpose_box <- mkTransposeBox;
		let word_size = valueOf(word_size);

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
		Reg#(Bit#(MemAddrWidth)) z <- mkRegU;
		Reg#(Maybe#(Bit#(MemAddrWidth))) a <- mkRegU;

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
						// After dimension check, these registers are reused
						// to hold the number of blocks in x and y dimension
						action
							matrix_block_rows <= (matrix_block_cols >> 3);
							matrix_block_cols <= (matrix_block_rows >> 3);
						endaction

						seq
							requestFIFOA.enq(makeReadRequest(csr_src + 1));
							action
								let pointer = responseFIFOA.first(); responseFIFOA.deq();
								TPointer address = unpack(pointer);
								matrix_src_data <= address;
							endaction
						endseq

						seq
							requestFIFOB.enq(makeReadRequest(csr_dst + 1));
							action
								let pointer = responseFIFOB.first(); responseFIFOB.deq();
								TPointer address = unpack(pointer);
								matrix_dst_data <= address;
							endaction
						endseq
					endpar

					// Step 2. Do matrix transpose
					par
						$display("MT", id, " Start transpose at time ", $time);
						transpose_done <= False;
						transpose_box.clear;
						k <= matrix_src_data;
						n <= matrix_dst_data;
						u <= 0;
					endpar

					// Transpose fully filled blocks
					par
						for (i <= 0; i < zeroExtend(pack(matrix_block_rows)); i <= i + 1) seq
							for (j <= 0; j < zeroExtend(pack(matrix_block_cols)); j <= j + 1) action
								srcBlockAddrFIFO.enq(k);
								if (word_size == 16) begin
									k <= k + 4;
								end
								else if (word_size == 32) begin
									k <= k + 8;
								end
							endaction
							if (word_size == 16) seq
								k <= matrix_src_data + (i + 1) * (zeroExtend(pack(matrix_src_cols)) << 2);
							endseq
							else if (word_size == 32) seq
								k <= matrix_src_data + (i + 1) * (zeroExtend(pack(matrix_src_cols)) << 3);
							endseq
						endseq

						for (l <= 0; l < zeroExtend(pack(matrix_block_rows)); l <= l + 1) seq
							for (m <= 0; m < zeroExtend(pack(matrix_block_cols)); m <= m + 1) action
								dstBlockAddrFIFO.enq(n);
								if (word_size == 16) begin
									n <= n + (zeroExtend(pack(matrix_src_rows)) << 2);
								end 
								else if (word_size == 32) begin
									n <= n + (zeroExtend(pack(matrix_src_rows)) << 3);
								end
							endaction
							if (word_size == 16) seq
								n <= matrix_dst_data + (l + 1) * 4;
							endseq else if (word_size == 32) seq
								n <= matrix_dst_data + (l + 1) * 8;
							endseq
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
									if (word_size == 16) begin
										p <= p + zeroExtend(pack(matrix_src_cols >> 1));
									end
									else if (word_size == 32) begin
										p <= p + zeroExtend(pack(matrix_src_cols));
									end
								endaction
								action
									dstRowAddrFIFO.enq(q);
									if (word_size == 16) begin
										q <= q + zeroExtend(pack(matrix_src_rows >> 1));
									end
									else if (word_size == 32) begin
										q <= q + zeroExtend(pack(matrix_src_rows));
									end
								endaction
							endpar
						endseq

						// Creates memory requests to fetch the src matrix
						for (y <= 0; y < (zeroExtend(pack(matrix_block_rows)) * zeroExtend(pack(matrix_block_cols)) << 3); y <= y + 1) seq
							action
								s <= srcRowAddrFIFO.first; srcRowAddrFIFO.deq;
							endaction
							if (word_size == 16) seq
								for (t <= 0; t < 4; t <= t + 1) action
									requestFIFOA.enq(makeReadRequest(s));
									s <= s + 1;
								endaction
							endseq
							else if (word_size == 32) seq
								for (t <= 0; t < 8; t <= t + 1) action
									requestFIFOA.enq(makeReadRequest(s));
									s <= s + 1;
								endaction
							endseq
						endseq

						// Push fetched data into transpose_box (Row major order)
						seq
							if (word_size == 16) seq
								for (x <= 0; x < zeroExtend(pack((matrix_block_rows * matrix_block_cols) << 6)); x <= x + 2) seq
									action
										z <= responseFIFOA.first;
										responseFIFOA.deq;
									endaction
									transpose_box.put_element.put(tagged Valid extend(z[31:16]));
									transpose_box.put_element.put(tagged Valid extend(z[15:0]));
								endseq
							endseq
							else if (word_size == 32) seq
								for (x <= 0; x < zeroExtend(pack((matrix_block_rows * matrix_block_cols) << 6)); x <= x + 1) action
									transpose_box.put_element.put(tagged Valid truncate(responseFIFOA.first));
									responseFIFOA.deq;
								endaction
							endseq
							while (!transpose_done) action
								transpose_box.put_element.put(Invalid);
							endaction
						endseq

						// Create memory requests to store the transposed matrix
						seq
							while (u < zeroExtend(pack((matrix_block_rows * matrix_block_cols) << 6))) seq
								action
									v <= dstRowAddrFIFO.first; dstRowAddrFIFO.deq;
								endaction

								if (word_size == 16) seq
									w <= 0;
									a <= Invalid;
									while (w < 4) seq
										action
											let data <- transpose_box.get_element.get;
											case (data) matches
												tagged Valid .x : begin
													case (a) matches
														tagged Valid .b : begin
															requestFIFOB.enq(makeWriteRequest(v, extend((b << 16) | extend(x))));
															a <= Invalid;
															v <= v + 1;
															w <= w + 1;
														end
														tagged Invalid : begin
															a <= tagged Valid extend(x);
														end
													endcase
												end
												tagged Invalid : noAction;
											endcase
										endaction
									endseq
								endseq
								else if (word_size == 32) seq
									w <= 0;
									while (w < 8) seq
										action
											let data <- transpose_box.get_element.get;
											case (data) matches
												tagged Valid .x : begin
													requestFIFOB.enq(makeWriteRequest(v, extend(x)));
													v <= v + 1;
													w <= w + 1;
												end
												tagged Invalid : noAction;
											endcase
										endaction
									endseq
								endseq
								u <= u + 8;
							endseq
							transpose_done <= True;
						endseq
					endpar

					// Transpose paritally filled blocks on the right edge (if present)
					if ((matrix_src_cols & 7) > 0) seq
						i <= zeroExtend(pack(matrix_src_cols)) & 7;
						if (word_size == 16) par
							for (k <= 0; k < (i >> 1); k <= k + 1) seq
								j <= matrix_src_data + (zeroExtend(pack(matrix_block_cols)) << 2) + k;
								for (l <= 0; l < zeroExtend(pack(matrix_src_rows)); l <= l + 1) action
									requestFIFOA.enq(makeReadRequest(j));
									j <= j + zeroExtend(pack(matrix_src_cols >> 1));
								endaction
							endseq

							seq
								n <= matrix_dst_data + ((zeroExtend(pack(matrix_block_cols)) << 2) * zeroExtend(pack(matrix_src_rows)));
								for (m <= 0; m < (i >> 1); m <= m + 1) seq
									for (o <= 0; o < zeroExtend(pack(matrix_src_rows)); o <= o + 2) seq
										action
											a <= tagged Valid (responseFIFOA.first); responseFIFOA.deq;
										endaction
										action
											let aa = responseFIFOA.first; responseFIFOA.deq;
											let a_val = fromMaybe(0, a);
											let data1 = {a_val[31:16], aa[31:16]};
											a <= tagged Valid ({a_val[15:0], aa[15:0]});
											requestFIFOB.enq(makeWriteRequest(n, data1));
										endaction
										requestFIFOB.enq(makeWriteRequest(n + zeroExtend(pack(matrix_src_rows >> 1)), fromMaybe(0, a)));
										n <= n + 1;
									endseq
									n <= n + zeroExtend(pack(matrix_src_rows >> 1));
								endseq
							endseq
						endpar
						else if (word_size == 32) par
							for (k <= 0; k < i; k <= k + 1) seq
								j <= matrix_src_data + (zeroExtend(pack(matrix_block_cols)) << 3) + k;
								for (l <= 0; l < zeroExtend(pack(matrix_src_rows)); l <= l + 1) action
									requestFIFOA.enq(makeReadRequest(j));
									j <= j + zeroExtend(pack(matrix_src_cols));
								endaction
							endseq

							seq
								n <= matrix_dst_data + ((zeroExtend(pack(matrix_block_cols)) << 3) * zeroExtend(pack(matrix_src_rows)));
								for (m <= 0; m < i; m <= m + 1) seq
									for (o <= 0; o < zeroExtend(pack(matrix_src_rows)); o <= o + 1) action
										requestFIFOB.enq(makeWriteRequest(n, responseFIFOA.first()));
										responseFIFOA.deq();
										n <= n + 1;
									endaction
								endseq
							endseq
						endpar
					endseq

					// Transpose paritally filled blocks on the bottom edge (if present)
					if ((matrix_src_rows & 7) > 0) seq
						i <= zeroExtend(pack(matrix_src_rows)) & 7;
						if (word_size == 16) par
							seq
								j <= matrix_src_data + (zeroExtend(pack(matrix_block_rows)) << 2) * zeroExtend(pack(matrix_src_cols));
								p <= matrix_src_data + (zeroExtend(pack(matrix_block_rows)) << 2) * zeroExtend(pack(matrix_src_cols)) + zeroExtend(pack(matrix_src_cols >> 1));
								for (k <= 0; k < (i >> 1); k <= k + 1) seq
									for (l <= 0; l < zeroExtend(pack(matrix_src_cols)); l <= l + 2) seq
										action
											requestFIFOA.enq(makeReadRequest(j));
											j <= j + 1;
										endaction
										action
											requestFIFOA.enq(makeReadRequest(p));
											p <= p + 1;
										endaction
									endseq
									j <= j + zeroExtend(pack(matrix_src_cols >> 1));
									p <= p + zeroExtend(pack(matrix_src_cols >> 1));
								endseq
							endseq

							seq
								for (m <= 0; m < (i >> 1); m <= m + 1) seq
									n <= matrix_dst_data + (zeroExtend(pack(matrix_block_rows)) << 2) + m;
									for (o <= 0; o < zeroExtend(pack(matrix_src_cols)); o <= o + 2) seq
										action
											a <= tagged Valid (responseFIFOA.first); responseFIFOA.deq;
										endaction
										action
											let aa = responseFIFOA.first; responseFIFOA.deq;
											let a_val = fromMaybe(0, a);
											let data1 = {a_val[31:16], aa[31:16]};
											a <= tagged Valid ({a_val[15:0], aa[15:0]});
											requestFIFOB.enq(makeWriteRequest(n, data1));
										endaction
										requestFIFOB.enq(makeWriteRequest(n + zeroExtend(pack(matrix_src_rows >> 1)), fromMaybe(0, a)));
										n <= n + zeroExtend(pack(matrix_src_rows));
									endseq
								endseq
							endseq
						endpar
						else if (word_size == 32) par
							seq
								j <= matrix_src_data + ((zeroExtend(pack(matrix_block_rows)) << 3) * zeroExtend(pack(matrix_src_cols)));
								for (k <= 0; k < i; k <= k + 1) seq
									for (l <= 0; l < zeroExtend(pack(matrix_src_cols)); l <= l + 1) action
										requestFIFOA.enq(makeReadRequest(j));
										j <= j + 1;
									endaction
								endseq
							endseq

							for (m <= 0; m < i; m <= m + 1) seq
								n <= matrix_dst_data + (zeroExtend(pack(matrix_block_rows)) << 3) + m;
								for (o <= 0; o < zeroExtend(pack(matrix_src_cols)); o <= o + 1) action
									requestFIFOB.enq(makeWriteRequest(n, responseFIFOA.first()));
									responseFIFOA.deq();
									n <= n + zeroExtend(pack(matrix_src_rows));
								endaction
							endseq
						endpar
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
