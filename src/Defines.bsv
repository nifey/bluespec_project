package Defines;
	import CBus::*;
	import BRAM::*;

	interface Ifc_Accelerator;
		interface MemClient portA;
		interface MemClient portB;
	endinterface

	typedef 6 BusAddrWidth;
	typedef 32 BusDataWidth;
	typedef 32 MemAddrWidth;

	// Number of connections to Interconnect
	typedef 22 MaxInitiators;

	// Define the Bus
	typedef CBus#(BusAddrWidth, BusDataWidth)		Bus;
	typedef ModWithCBus#(BusAddrWidth, BusDataWidth, i)	ModWithBus#(type i);
	typedef CRAddr#(BusAddrWidth, BusDataWidth)		BusAddr;

	// Configuration Register types
	typedef bit		TCfgStart;	// Signals the Accelerator to start working
	typedef bit		TCfgDone;	// Signals the CPU that the accelerator has finished
	typedef bit		TCfgError;	// Indicates an error

	typedef Bit#(32)	TPointer;	// Holds a pointer to memory
	typedef UInt#(32)	TBlockSize;	// Holds block size for vector copy and vector xor
	typedef UInt#(16)	TDimension;	// Holds the matrix dimension for matrix transpose
	
	// Configuration Bus addresses
	Bit#(BusAddrWidth)	cfg_VX_addr = 0;	// Start address of Vector XOR CSRs
	Bit#(BusAddrWidth)	cfg_VC_addr = 15;	// Start address of Vector copy CSRs
	Bit#(BusAddrWidth)	cfg_MT_addr = 31;	// Start address of Matrix transpose CSRs
	Bit#(BusAddrWidth)	cfg_Dump_addr = 40;	// Start address of Memory dumper

	// Offsets from the base address of the accelerator
	BusAddr cfg_start_offset = BusAddr {a:0, o:0};
	BusAddr cfg_done_offset = BusAddr {a:0, o:1};
	BusAddr cfg_error_offset = BusAddr {a:0, o:2};
	BusAddr cfg_arg1_offset = BusAddr {a:1, o:0};
	BusAddr cfg_arg2_offset = BusAddr {a:2, o:0};
	BusAddr cfg_arg3_offset = BusAddr {a:3, o:0};
	BusAddr cfg_arg4_offset = BusAddr {a:4, o:0};

	// Define the BRAM memory
	typedef BRAMRequest#(Bit#(MemAddrWidth), Bit#(BusDataWidth))	MemRequest;
	typedef BRAMClient#(Bit#(MemAddrWidth), Bit#(BusDataWidth))	MemClient;
	typedef BRAMServer#(Bit#(MemAddrWidth), Bit#(BusDataWidth))	MemServer;

	function MemRequest makeReadRequest(Bit#(MemAddrWidth) addr);
		return MemRequest{
			write: False,
			responseOnWrite:False,
			address: addr,
			datain: 0
		};
	endfunction

	function MemRequest makeWriteRequest(Bit#(MemAddrWidth) addr, Bit#(BusDataWidth) data);
		return MemRequest{
			write: True,
			responseOnWrite:False,
			address: addr,
			datain: data
		};
	endfunction

endpackage
