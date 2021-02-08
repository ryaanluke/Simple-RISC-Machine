module instruction_decoder(in, opcode, op, writenum, readnum, shift, sximm8, sximm5, ALUop, nsel, cond);
	input [15:0] in;
	input [2:0] nsel;
	output [2:0] opcode, readnum, writenum;
	output [1:0] op, ALUop, shift;
	output [15:0] sximm5, sximm8;

	// output in[10:8] as cond for lab 8
	output [2:0] cond;
	assign cond = in[10:8];

	//assigns all things to the desired bits
	assign opcode = in[15:13];
	assign op = in[12:11];
	wire[2:0] Rn = in[10:8];
	wire[2:0] Rd = in[7:5];
	wire[2:0] Rm = in[2:0];
	assign ALUop = op;
	assign shift = in[4:3];
	wire[4:0] imm5 = in[4:0];
	wire[7:0] imm8 = in[7:0];
	reg [2:0] readnum, writenum;
	
	//does the sximm8 logic, sign extending
	reg [15:0] sximm8 , sximm5;
	always @(*) begin
		sximm8[15:0] = { {8{imm8[7]}}, imm8[7:0]};
		sximm5[15:0] = { {11{imm5[4]}}, imm5[4:0]};
	end
	always @(*) begin
		case(nsel)
			3'b001: {writenum, readnum} = {2{Rn}};
			3'b010: {writenum, readnum} = {2{Rm}};
			3'b100: {writenum, readnum} = {2{Rd}};
			default: {writenum, readnum} = {6{1'bx}};
		endcase
	end
 



endmodule
