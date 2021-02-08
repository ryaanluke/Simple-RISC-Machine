module mux_PCinput(select, a, b, c, d, out);
	//bit width of mux
	parameter k = 9;
	input [3:0] select; // this is a one-hot
	input [k-1:0] a, b, c, d;
	output [k-1:0] out;
	reg [k-1:0] out;
	
	always @(*) begin
		case (select)
			4'b1000: out = d; // selets 3, which is Rd
			4'b0100: out = c; // selects 2, which is PC + 1 + sx(im8)
			4'b0010: out = a; // selects 1, which is 9'b0
			4'b0001: out = b; // selects 0, which is PC + 1 
			default: out = {k{1'bx}};
		endcase
	end
endmodule 