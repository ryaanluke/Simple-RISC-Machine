module regfile(data_in,writenum,write,readnum,clk,data_out); 
	input [15:0] data_in;
	input [2:0] writenum, readnum;
	input write, clk;
	output [15:0] data_out;
	reg [15:0] data_out;
	reg [7:0] load;
	wire [15:0] R0, R1, R2, R3, R4, R5, R6, R7;
		
	//adds 8 registers named reg0 -> reg8 to the regfile		
	register reg0(load[0], clk, data_in, R0);
	register reg1(load[1], clk, data_in, R1);
	register reg2(load[2], clk, data_in, R2);
	register reg3(load[3], clk, data_in, R3);
	register reg4(load[4], clk, data_in, R4);
	register reg5(load[5], clk, data_in, R5);
	register reg6(load[6], clk, data_in, R6);
	register reg7(load[7], clk, data_in, R7);
	
	//converts 3 bit number to a one-hot with the reg we created called load, and one bit of load is passed into each register
	always @(*) begin
		if (write) begin
			case (writenum)
				3'b000: load = 8'b00000001;
				3'b001: load = 8'b00000010;
				3'b010: load = 8'b00000100;
				3'b011: load = 8'b00001000;
				3'b100: load = 8'b00010000;
				3'b101: load = 8'b00100000;
				3'b110: load = 8'b01000000;
				3'b111: load = 8'b10000000;
				default: load = 8'bx;
			endcase
		end
		else begin
			load = 8'b0;
		end
	
	end
	
	//sets data_out to a certain reg_out depending on readnum's 3 bit number
	always @(*) begin
		case (readnum)
			3'b000: data_out = R0;
			3'b001: data_out = R1;
			3'b010: data_out = R2;
			3'b011: data_out = R3;
			3'b100: data_out = R4;
			3'b101: data_out = R5;
			3'b110: data_out = R6;
			3'b111: data_out = R7;
			default: data_out = 16'bx;
		endcase
	end
endmodule




module register(load, clk, in, out);
	input [15:0] in;
	input load, clk;
	output [15:0] out;
	reg [15:0] out;
	reg [15:0] current;
	
	always @(posedge clk) begin
		if (load) begin
			current = in;
		end else begin
			current = out;
		end
		out = current;
	end
	
endmodule

