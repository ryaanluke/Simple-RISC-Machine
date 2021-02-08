//State Encoding
//State Encoding
`define RESET      7'd0
`define IF1        7'd1
`define IF2        7'd2
`define UPDATEPC   7'd3
`define DECODE     7'd4
`define GETA       7'd5
`define GETB       7'd6
`define ADD        7'd7
`define WRES       7'd8
`define MOVE       7'd9
`define MOVESHIFT  7'd10
`define MOVESHIFT2 7'd11

`define LDRGETA     7'd12
`define LDRADD      7'd13
`define LDRLOADADDR 7'd14
`define READRAM     7'd15
`define LOADMDATA   7'd16


`define STRGETA     7'd17
`define STRADD      7'd18
`define STRLOADADDR 7'd19
`define STRGETB     7'd20
`define STRDPATH    7'd21
`define WRITERAM    7'd22

`define HALT        7'b1111111 

`define BRANCH1 	7'd23
`define B			7'd24
`define BEQ			7'd25
`define BNE			7'd26
`define BLT			7'd27
`define BLE			7'd28

`define BRANCH2 	7'd29
`define BL			7'd30
`define BX			7'd31
`define BLX			7'd32
`define PC2R7		7'd33

//Memory Stuff
`define MEMCMD_R  2'b01
`define MEMCMD_W  2'b10


//NOTE: this FSM_Controller does not output ALUop to datapath
//That is left for Instruction register

//inputs go up to op, rest are outputs
module FSM_Controller(clk, reset, opcode, op, loada, loadb, loadc, loads, asel, bsel, vsel, write, nsel, load_ir, mem_cmd, addr_sel, load_pc, reset_pc, load_addr, cond, Z_out, state);
	input clk, reset;
	input [2:0] opcode;
	input [1:0] op;
	
	//input cond and Z_out for lab 8
	input [2:0] cond;
	input [2:0] Z_out;

	reg N, V, Z;

	always @(posedge clk) begin
		if ({opcode, op} == 5'b10101) begin
			N = Z_out[1];
			V = Z_out[2];
			Z = Z_out[0];
		end
	end

	//outputs
	output loada, loadb, loadc, loads, asel, bsel, write;
	output [2:0] nsel;
	output [3:0] vsel;

	//outputs
	reg loada, loadb, loadc, loads, asel, bsel, write;
	reg [2:0] nsel;
	reg [3:0] vsel;
	
	//Lab 7 new outs
	output load_ir;
	output [1:0] mem_cmd;
	output addr_sel;
	output load_pc;
	output load_addr;
	
	//Lab 8 new reset_pc is one-hot 4-MUX select
	output reg [3:0] reset_pc;

	//Lab 7 new outs
	reg load_ir;
	reg [1:0] mem_cmd;
	reg addr_sel;
	reg load_pc;
	reg load_addr;
	


	//Internal Signals
	output reg [6:0] state;
	
	//State calculator
	always @(posedge clk) begin
		if (reset) begin
			state = `RESET;
		end else begin
			case (state)
				`RESET: state = `IF1; //RESET goes to IF1
				`IF1:   state = `IF2; //IF1 to IF2
				`IF2:   state = `UPDATEPC; //IF2 to UPDATEPC
				`UPDATEPC: state = `DECODE; //UPDATEPC to DECODE
				`DECODE: case (opcode) //Decode the opcode
								3'b101: state = `GETA; //Going to ALU instruction pattern
								3'b110: 	case(op) 
												2'b00: state = `MOVESHIFT; //if op == 00: go to move with shift
												2'b10: state = `MOVE;      //if op == 10: go to move no shift
												default: state = {7{1'bx}};
											endcase
								3'b011: state = `LDRGETA; //Going to LDR pattern
								3'b100: state = `STRGETA; //Going to STR pattern
								3'b111: state = `HALT; //Going to HALT
								3'b001: 	case(cond)
												3'b000: state = `B;
												3'b001: state = `BEQ;
												3'b010: state = `BNE;
												3'b011: state = `BLT;
												3'b000: state = `BLE;
												default: state = {7{1'bx}};
											endcase
								3'b010: 	case(op) // lab 8 table 2
												2'b11: state = `BL;
												2'b00: state = `GETB;
												// 2'b10: state = `BLX;
												default: state = {7{1'bx}};
											endcase
								default: state = {7{1'bx}};
							endcase
				`GETA:  state = `GETB; //GETA to GETB
				`GETB:  state = `ADD;  //GETB to ADD
				`ADD:   begin
							if ({opcode, op} == 5'b101_01) begin
								state = `IF1; // IF opcode, op is CMP
							end 
							else if ({opcode,op} == 5'b01000) begin
								state = `BX;
							end
							else begin
								state = `WRES; //IF IN CMP WERE NOT WRITING to anything
							end
						end
				`WRES:  state = `IF1; //restart cycle after ALU pattern
				`MOVE: state = `IF1;  //restart cycle after move no shift
				`MOVESHIFT:  state = `MOVESHIFT2; //MOVESHIFT to MOVESHIFT2
				`MOVESHIFT2: state = `WRES;       //MOVESHIFT2 to WRITE RESULT
				
				//LDR Pattern
				`LDRGETA: state = `LDRADD;
				`LDRADD:  state = `LDRLOADADDR;
				`LDRLOADADDR: state = `READRAM;
				`READRAM: state = `LOADMDATA;
				`LOADMDATA: state = `IF1;
				
				//STR Pattern
				`STRGETA: state = `STRADD;
				`STRADD:  state = `STRLOADADDR;
				`STRLOADADDR: state = `STRGETB;
				`STRGETB:   state = `STRDPATH;
				`STRDPATH:  state = `WRITERAM;
				`WRITERAM:    state = `IF1;
				
				//HALT
				`HALT: state = `HALT;

				//B (Table 1)
				`B: state = `IF1;
				`BEQ: state = `IF1;
				`BNE: state = `IF1;
				`BLT: state = `IF1;
				`BLE: state = `IF1;

				//B (Table 2)
				`BL: state = `PC2R7;
				`PC2R7: state = `B;
				`BX: state = `IF1;
				// `BLX: state = `BLX;PC2R7

			endcase
		end
	end
	
	//logic for outputs from current state
	always @(*) begin
		case (state)
			`RESET: 	begin
							loada = 1'b0; loadb = 1'b0;
							loadc = 1'b0; loads = 1'b0;
							asel = 1'b1;  bsel = 1'b1;
							write = 1'b0;
							nsel = 3'b001;
							vsel = 4'b0001;
							
							reset_pc = 4'b0010;
							load_pc  = 1'b1;
							addr_sel = 1'b0;
							mem_cmd = `MEMCMD_R;
							load_addr = 1'b0;
							load_ir = 1'b0;
							
						end
			`IF1: 	begin
							loada = 1'b0; loadb = 1'b0;
							loadc = 1'b0; loads = 1'b0;
							asel = 1'b1;  bsel = 1'b1;
							write = 1'b0;
							nsel = 3'b001;
							vsel = 4'b0001;
							
							reset_pc = 4'b0001;
							load_pc  = 1'b0;
							addr_sel = 1'b1;
							mem_cmd = `MEMCMD_R;
							load_addr = 1'b0;
							load_ir = 1'b0;
						end
						
			`IF2: 	begin
							loada = 1'b0; loadb = 1'b0;
							loadc = 1'b0; loads = 1'b0;
							asel = 1'b1;  bsel = 1'b1;
							write = 1'b0;
							nsel = 3'b001;
							vsel = 4'b0001;
							
							reset_pc = 4'b0001;
							load_pc  = 1'b0;
							addr_sel = 1'b1;
							mem_cmd = `MEMCMD_R;
							load_addr = 1'b0;
							load_ir = 1'b1;
						end

			`UPDATEPC: 	begin
							loada = 1'b0; loadb = 1'b0;
							loadc = 1'b0; loads = 1'b0;
							asel = 1'b1;  bsel = 1'b1;
							write = 1'b0;
							nsel = 3'b001;
							vsel = 4'b0001;
							
							reset_pc = 4'b0001;
							load_pc  = 1'b1;
							addr_sel = 1'b0;
							mem_cmd = `MEMCMD_R;
							load_addr = 1'b0;
							load_ir = 1'b0;
						end					
						
						
			`DECODE: 	begin
							loada = 1'b0; loadb = 1'b0;
							loadc = 1'b0; loads = 1'b0;
							asel = 1'b1;  bsel = 1'b1;
							write = 1'b0;
							nsel = 3'b001;
							vsel = 4'b0001;
							
							reset_pc = 4'b0001;
							load_pc  = 1'b0;
							addr_sel = 1'b0;
							mem_cmd = `MEMCMD_R;
							load_addr = 1'b0;
							load_ir = 1'b0;
						end
			`GETA: 	begin
							loada = 1'b1; loadb = 1'b0;
							loadc = 1'b0; loads = 1'b0;
							asel = 1'b1;  bsel = 1'b1;
							write = 1'b0;
							nsel = 3'b001;
							vsel = 4'b0001;
							
							reset_pc = 4'b0001;
							load_pc  = 1'b0;
							addr_sel = 1'b0;
							mem_cmd = `MEMCMD_R;
							load_addr = 1'b0;
							load_ir = 1'b0;
						end
			`GETB: 	begin
							loada = 1'b0; loadb = 1'b1;
							loadc = 1'b0; loads = 1'b0;
							asel = 1'b1;  bsel = 1'b1;
							write = 1'b0;
							nsel = ({opcode,op} == 5'b01000)? 3'b100 : 3'b010; // if BX, then select Rd
							vsel = 4'b0001;
							
							reset_pc = 4'b0001;
							load_pc  = 1'b0;
							addr_sel = 1'b0;
							mem_cmd = `MEMCMD_R;
							load_addr = 1'b0;
							load_ir = 1'b0;
						end
			`ADD: 	begin
							loada = 1'b0; loadb = 1'b0;
							loadc = 1'b1; loads = ({opcode,op} == 5'b10101)? 1'b1 : 1'b0;
							asel = ({opcode,op} == 5'b01000)? 1'b1 : 1'b0;  bsel = 1'b0;
							write = 1'b0;
							nsel = 3'b100;
							vsel = 4'b0001;
							
							reset_pc = 4'b0001;
							load_pc  = 1'b0;
							addr_sel = 1'b0;
							mem_cmd = `MEMCMD_R;
							load_addr = 1'b0;
							load_ir = 1'b0;
						end
			`WRES: 	begin
							loada = 1'b0; loadb = 1'b0;
							loadc = 1'b0; loads = 1'b0;
							asel = 1'b0;  bsel = 1'b0;
							write = 1'b1;
							nsel = 3'b100;
							vsel = 4'b0001;
							
							reset_pc = 4'b0001;
							load_pc  = 1'b0;
							addr_sel = 1'b0;
							mem_cmd = `MEMCMD_R;
							load_addr = 1'b0;
							load_ir = 1'b0;
						end
						
			`MOVE: 	begin
							loada = 1'b0; loadb = 1'b0;
							loadc = 1'b0; loads = 1'b0;
							asel = 1'b1;  bsel = 1'b1;
							write = 1'b1;
							nsel = 3'b001;
							vsel = 4'b0100;
							
							reset_pc = 4'b0001;
							load_pc  = 1'b0;
							addr_sel = 1'b0;
							mem_cmd = `MEMCMD_R;
							load_addr = 1'b0;
							load_ir = 1'b0;
						end
			`MOVESHIFT: begin
								loada = 1'b0; loadb = 1'b1;
								loadc = 1'b0; loads = 1'b0;
								asel = 1'b1;  bsel = 1'b1;
								write = 1'b0;
								nsel = 3'b010;
								vsel = 4'b0001;
								
								reset_pc = 4'b0001;
								load_pc  = 1'b0;
								addr_sel = 1'b0;
								mem_cmd = `MEMCMD_R;
								load_addr = 1'b0;
								load_ir = 1'b0;
							end
			`MOVESHIFT2: begin
							loada = 1'b0; loadb = 1'b0;
							loadc = 1'b1; loads = 1'b0;
							asel = 1'b1;  bsel = 1'b0;
							write = 1'b0;
							nsel = 3'b100;
							vsel = 4'b0001;
							
							reset_pc = 4'b0001;
							load_pc  = 1'b0;
							addr_sel = 1'b0;
							mem_cmd = `MEMCMD_R;
							load_addr = 1'b0;
							load_ir = 1'b0;
						end
						
			`LDRGETA: 	begin
								loada = 1'b1; loadb = 1'b0;
								loadc = 1'b0; loads = 1'b0;
								asel = 1'b1;  bsel = 1'b1;
								write = 1'b0;
								nsel = 3'b001;
								vsel = 4'b0001;
								
								reset_pc = 4'b0001;
								load_pc  = 1'b0;
								addr_sel = 1'b0;
								mem_cmd = `MEMCMD_R;
								load_addr = 1'b0;
								load_ir = 1'b0;
							end
			`LDRADD:		begin
								loada = 1'b0; loadb = 1'b0;
								loadc = 1'b1; loads = 1'b0;
								asel = 1'b0;  bsel = 1'b1;
								write = 1'b0;
								nsel = 3'b100;
								vsel = 4'b0001;
								
								reset_pc = 4'b0001;
								load_pc  = 1'b0;
								addr_sel = 1'b0;
								mem_cmd = `MEMCMD_R;
								load_addr = 1'b0;
								load_ir = 1'b0;
							end
							
			`LDRLOADADDR:	begin
									loada = 1'b0; loadb = 1'b0;
									loadc = 1'b0; loads = 1'b0;
									asel = 1'b0;  bsel = 1'b1;
									write = 1'b0;
									nsel = 3'b100;
									vsel = 4'b0001;
									
									reset_pc = 4'b0001;
									load_pc  = 1'b0;
									addr_sel = 1'b0;
									mem_cmd = `MEMCMD_R;
									load_addr = 1'b1;
									load_ir = 1'b0;
								end
								
			`READRAM:		begin
									loada = 1'b0; loadb = 1'b0;
									loadc = 1'b0; loads = 1'b0;
									asel = 1'b0;  bsel = 1'b0;
									write = 1'b0;
									nsel = 3'b100;
									vsel = 4'b1000;
									
									reset_pc = 4'b0001;
									load_pc  = 1'b0;
									addr_sel = 1'b0;
									mem_cmd = `MEMCMD_R;
									load_addr = 1'b0;
									load_ir = 1'b0;
								end
								
			`LOADMDATA:		begin
									loada = 1'b0; loadb = 1'b0;
									loadc = 1'b0; loads = 1'b0;
									asel = 1'b0;  bsel = 1'b0;
									write = 1'b1;
									nsel = 3'b100;
									vsel = 4'b1000;
									
									reset_pc = 4'b0001;
									load_pc  = 1'b0;
									addr_sel = 1'b0;
									mem_cmd = `MEMCMD_R;
									load_addr = 1'b0;
									load_ir = 1'b0;
								end
			
			`STRGETA: 		begin
									loada = 1'b1; loadb = 1'b0;
									loadc = 1'b0; loads = 1'b0;
									asel = 1'b1;  bsel = 1'b1;
									write = 1'b0;
									nsel = 3'b001;
									vsel = 4'b0001;
									
									reset_pc = 4'b0001;
									load_pc  = 1'b0;
									addr_sel = 1'b0;
									mem_cmd = `MEMCMD_R;
									load_addr = 1'b0;
									load_ir = 1'b0;
								end
								
			`STRADD:			begin
									loada = 1'b0; loadb = 1'b0;
									loadc = 1'b1; loads = 1'b0;
									asel = 1'b0;  bsel = 1'b1;
									write = 1'b0;
									nsel = 3'b100;
									vsel = 4'b0001;
									
									reset_pc = 4'b0001;
									load_pc  = 1'b0;
									addr_sel = 1'b0;
									mem_cmd = `MEMCMD_R;
									load_addr = 1'b0;
									load_ir = 1'b0;		
								end
								
			`STRLOADADDR:	begin
									loada = 1'b0; loadb = 1'b0;
									loadc = 1'b0; loads = 1'b0;
									asel = 1'b0;  bsel = 1'b1;
									write = 1'b0;
									nsel = 3'b100;
									vsel = 4'b0001;
									
									reset_pc = 4'b0001;
									load_pc  = 1'b0;
									addr_sel = 1'b0;
									mem_cmd = `MEMCMD_R;
									load_addr = 1'b1;
									load_ir = 1'b0;
								end
								
			`STRGETB:		begin
									loada = 1'b0; loadb = 1'b1;
									loadc = 1'b0; loads = 1'b0;
									asel = 1'b1;  bsel = 1'b0;
									write = 1'b0;
									nsel = 3'b100;
									vsel = 4'b0001;
									
									reset_pc = 4'b0001;
									load_pc  = 1'b0;
									addr_sel = 1'b0;
									mem_cmd = `MEMCMD_R;
									load_addr = 1'b0;
									load_ir = 1'b0;
								end
								
			`STRDPATH:		begin
									loada = 1'b0; loadb = 1'b0;
									loadc = 1'b1; loads = 1'b0;
									asel = 1'b1;  bsel = 1'b0;
									write = 1'b0;
									nsel = 3'b100;
									vsel = 4'b0001;
									
									reset_pc = 4'b0001;
									load_pc  = 1'b0;
									addr_sel = 1'b0;
									mem_cmd = `MEMCMD_R;
									load_addr = 1'b0;
									load_ir = 1'b0;
								end
								
			`WRITERAM:		begin
									loada = 1'b0; loadb = 1'b0;
									loadc = 1'b0; loads = 1'b0;
									asel = 1'b0;  bsel = 1'b0;
									write = 1'b0;
									nsel = 3'b010;
									vsel = 4'b1000;
									
									reset_pc = 4'b0001;
									load_pc  = 1'b0;
									addr_sel = 1'b0;
									mem_cmd = `MEMCMD_W;
									load_addr = 1'b0;
									load_ir = 1'b0;
								end

			`B:				begin // nothing matters except for reset_pc
									loada = 1'b0; loadb = 1'b0;
									loadc = 1'b0; loads = 1'b0;
									asel = 1'b0;  bsel = 1'b0;
									write = 1'b0;
									nsel = 3'b010;
									vsel = 4'b1000;
									
									reset_pc = 4'b0100; // PC = PC + sx(im8)
									load_pc  = 1'b1;
									addr_sel = 1'b0;
									mem_cmd = `MEMCMD_W;
									load_addr = 1'b0;
									load_ir = 1'b0;
								end

			`BEQ:				begin // nothing matters except for reset_pc
									loada = 1'b0; loadb = 1'b0;
									loadc = 1'b0; loads = 1'b0;
									asel = 1'b0;  bsel = 1'b0;
									write = 1'b0;
									nsel = 3'b010;
									vsel = 4'b1000;
									
									reset_pc = Z? 4'b0100 : 4'b0001; // if Z = 1, then PC + sx(im8), else PC + 1
									load_pc  = Z? 1'b1 : 1'b0;
									addr_sel = 1'b0;
									mem_cmd = `MEMCMD_W;
									load_addr = 1'b0;
									load_ir = 1'b0;
								end

			`BNE:				begin // nothing matters except for reset_pc
									loada = 1'b0; loadb = 1'b0;
									loadc = 1'b0; loads = 1'b0;
									asel = 1'b0;  bsel = 1'b0;
									write = 1'b0;
									nsel = 3'b010;
									vsel = 4'b1000;
									
									reset_pc = ~Z? 4'b0100 : 4'b0001; // if Z = 0, then PC + 1 + sx(im8), else PC + 1
									load_pc  = ~Z? 1'b1 : 1'b0;
									addr_sel = 1'b0;
									mem_cmd = `MEMCMD_W;
									load_addr = 1'b0;
									load_ir = 1'b0;
								end

			`BLT:				begin // nothing matters except for reset_pc
									loada = 1'b0; loadb = 1'b0;
									loadc = 1'b0; loads = 1'b0;
									asel = 1'b0;  bsel = 1'b0;
									write = 1'b0;
									nsel = 3'b010;
									vsel = 4'b1000;
									
									reset_pc = (N == V)? 4'b0001 : 4'b0100; // if N!=V, then PC + 1 + sx(im8), else PC + 1
									load_pc  = (N == V)? 1'b0 : 1'b1; // if N!=V, then load_pc is on
									addr_sel = 1'b0;
									mem_cmd = `MEMCMD_W;
									load_addr = 1'b0;
									load_ir = 1'b0;
								end

			`BLE:				begin // nothing matters except for reset_pc
									loada = 1'b0; loadb = 1'b0;
									loadc = 1'b0; loads = 1'b0;
									asel = 1'b0;  bsel = 1'b0;
									write = 1'b0;
									nsel = 3'b010;
									vsel = 4'b1000;
									
									reset_pc = ((N !== V) | Z)? 4'b0100 : 4'b0001; // if N!=V or Z, then PC + 1 + sx(im8), else PC + 1
									load_pc  = ((N !== V) | Z)? 1'b1 : 1'b0;
									addr_sel = 1'b0;
									mem_cmd = `MEMCMD_W;
									load_addr = 1'b0;
									load_ir = 1'b0;
								end

			`PC2R7: 	begin // for BL, R7 = PC
							loada = 1'b0; loadb = 1'b0;
							loadc = 1'b0; loads = 1'b0;
							asel = 1'b1;  bsel = 1'b1;
							write = 1'b1;
							nsel = 3'b001; // Rn 
							vsel = 4'b0010; // selects PC
							
							reset_pc = 4'b0001;
							load_pc  = 1'b0;
							addr_sel = 1'b0;
							mem_cmd = `MEMCMD_R; // kept from MOV, whatever
							load_addr = 1'b0;
							load_ir = 1'b0;
						end


			`BX:				begin // nothing matters except for reset_pc
									loada = 1'b0; loadb = 1'b0;
									loadc = 1'b0; loads = 1'b0;
									asel = 1'b0;  bsel = 1'b0;
									write = 1'b0;
									nsel = 3'b010;
									vsel = 4'b1000;
									
									reset_pc = 4'b1000; // selects Rd from 4-input MUX
									load_pc  = 1'b1;
									addr_sel = 1'b0;
									mem_cmd = `MEMCMD_W;
									load_addr = 1'b0;
									load_ir = 1'b0;
								end

			default: begin
							loada = 1'bx; loadb = 1'bx;
							loadc = 1'bx; loads = 1'bx;
							asel = 1'bx;  bsel = 1'bx;
							write = 1'bx;
							nsel = 3'bxxx;
							vsel = 4'bxxxx;
							
							reset_pc = 4'bx;
							load_pc  = 1'bx;
							addr_sel = 1'bx;
							mem_cmd =  2'bxx;
							load_addr = 1'bx;
							load_ir = 1'bx;
						end
		endcase
	end
endmodule 