

module cpu(clk, reset, read_data, write_data, N, V, Z, mem_cmd, mem_addr, state);
	input clk, reset;
	input [15:0] read_data;
	output [15:0] write_data;
	output [1:0] mem_cmd;
	output [8:0] mem_addr;
	output N, V, Z;
	wire [15:0] instruction_decoder_in, mdata;
	wire [15:0] C, sximm8, sximm5;
	wire [8:0] PC, next_pc, load_addr_out;
	wire [3:0] vsel;
	wire [2:0] opcode, writenum, readnum, nsel, Z_out;
	wire [1:0] op, shift, ALUop;
	wire loada, loadb, loadc, loads, asel, bsel, write, w, addr_sel, load_pc, load_ir, load_addr;
	wire [3:0] reset_pc;
	wire [8:0] PC_plus, PC_plus_s8;
	assign mdata = read_data;
	assign C = write_data;
	reg N, V, Z;
	wire [2:0] cond;

	// FSM present state for lab 8 
	output [6:0] state;

	//connects instruction register
	dflipflop #(16) INSTRUCTION_REGISTER(clk, read_data, instruction_decoder_in, load_ir);
	
	//connects instruction decoder
	instruction_decoder INSTRUCTION_DECODER(instruction_decoder_in, opcode, op, writenum, readnum, shift, sximm8, sximm5, ALUop, nsel, cond);
	
	//connects state machine
	FSM_Controller FSM(.clk(clk), .reset(reset), .opcode(opcode), .op(op), .loada(loada), .loadb(loadb), .loadc(loadc), .loads(loads), .asel(asel), .bsel(bsel), .vsel(vsel), .write(write), .nsel(nsel), .load_ir(load_ir), .mem_cmd(mem_cmd), .addr_sel(addr_sel), .load_pc(load_pc), .reset_pc(reset_pc), .load_addr(load_addr), .cond(cond), .Z_out(Z_out), .state(state));

	//PC SELECT
	assign PC_plus = PC + 9'b1;
	assign PC_plus_s8 = PC + sximm8[8:0]; // without + 1 
	// sximm8 is 16-bit, want sign extended to 9 bits for PC_SELECT
	// wire sx_im8 as output from instruction decoder, lab 8 

	mux_PCinput #(9) PC_SELECT(reset_pc, 9'b0, PC_plus, PC_plus_s8, write_data[8:0], next_pc);

	dflipflop #(9) PC_NEXT(clk, next_pc, PC, load_pc);

	//Data Address dflipflop
	dflipflop #(9) DATA_SELECT(clk, write_data[8:0], load_addr_out, load_addr);


	//ADDR SELECT
	multiplexer #(9) ADDR_SELECT(addr_sel, PC, load_addr_out, mem_addr);

	//connects datapath
	datapath DP(clk, readnum, vsel, mdata, sximm8, PC[7:0], C, loada, loadb, shift, asel, bsel, sximm5, ALUop, loadc, loads, writenum, write, Z_out, write_data);

endmodule 