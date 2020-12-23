package Defines;
	import CBus::*;
	import BRAM::*;

	typedef 6 BusAddrWidth;
	typedef 32 BusDataWidth;
	typedef 12 MemAddrWidth;

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
	
	typedef Bit#(32)	TMemAddress;	// Holds an address in Memory module
	typedef UInt#(32)	TMemData;	// Holds a data in Memory module

	// Configuration Bus addresses
	Bit#(BusAddrWidth)	cfg_VX_addr = 0;	// Start address of Vector XOR CSRs
	Bit#(BusAddrWidth)	cfg_VC_addr = 12;	// Start address of Vector copy CSRs
	Bit#(BusAddrWidth)	cfg_MT_addr = 28;	// Start address of Matrix transpose CSRs

	// Memory CSR addresses
	BusAddr cfgMemRWBitAddr = BusAddr {a:37, o:0};
	BusAddr cfgMemEnBitAddr = BusAddr {a:37, o:1};
	BusAddr cfgMemMARAddr = BusAddr {a:38, o:0};
	BusAddr cfgMemMIDRAddr = BusAddr {a:39, o:0};
	BusAddr cfgMemMODRAddr = BusAddr {a:40, o:0};

	function BRAMRequest#(Bit#(MemAddrWidth), Bit#(BusDataWidth)) makeReadRequest(Bit#(MemAddrWidth) addr);
		return BRAMRequest{
			write: False,
			responseOnWrite:False,
			address: addr,
			datain: 0
		};
	endfunction

	function BRAMRequest#(Bit#(MemAddrWidth), Bit#(BusDataWidth)) makeWriteRequest(Bit#(MemAddrWidth) addr, Bit#(BusDataWidth) data);
		return BRAMRequest{
			write: True,
			responseOnWrite:False,
			address: addr,
			datain: data
		};
	endfunction

endpackage
