module datapath(clk, readnum, vsel, mdata, sximm8, PC, C, loada, loadb, shift, asel, bsel, sximm5, ALUop, loadc, loads, writenum, write, Z_out, datapath_out);
	//inputs and outputs	
	input [2:0] readnum, writenum;
	input clk, write, asel, bsel, loada, loadb, loadc, loads;

	input [1:0] shift, ALUop;
	output [2:0] Z_out;
	output [15:0] datapath_out;
	
	//changed inputs from lab 5
	input [3:0] vsel;
	input [15:0] mdata;
	input [15:0] sximm8;
	input [7:0] PC;
	input [15:0] C;
	
	
	input [15:0] sximm5;
	
	//extra wires within the datapath
	wire [15:0] data_in, data_out, loada_out, loadb_out, sout, Ain, Bin, out;
	
	//changed wires from lab 5
	wire [2:0] Z;
	
	//new input
	mux_4input VSELECT(vsel, mdata, sximm8, {8'b0, PC}, C, data_in); 
	// mdata 1000
	// sximm8 0100
	// PC 0010
	// data_in 0001

	//regfile
	regfile REGFILE(data_in, writenum, write, readnum, clk, data_out);

	//load a to ALU
	dflipflop #(16) LOADA(clk, data_out, loada_out, loada);

	multiplexer ASEL(asel, 16'b0, loada_out, Ain);

	//load b to ALU
	dflipflop #(16) LOADB(clk, data_out, loadb_out, loadb);

	shifter SHIFTER(loadb_out, shift, sout);

	multiplexer BSEL(bsel, sximm5, sout, Bin);

	//ALU
	ALU U2(Ain, Bin, ALUop, out, Z);

	//new 3-bit status
	dflipflop #(3) STATUS(clk, Z, Z_out, loads);
	
	//loadc
	dflipflop #(16) LOADC(clk, out, datapath_out, loadc);

endmodule
