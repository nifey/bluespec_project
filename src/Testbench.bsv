package Testbench;
	import StmtFSM::*;
	import Defines::*;

	(* synthesize *)
	module mkTestbench(Empty);
		let test =
		seq
			$display("Hello world");
		endseq;

		mkAutoFSM(test);
	endmodule
endpackage
