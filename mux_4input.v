module mux_4input(select, a, b, c, d, out);
	//bit width of mux
	parameter k = 16;
	input [3:0] select;
	input [k-1:0] a, b, c, d;
	output [k-1:0] out;
	reg [k-1:0] out;
	
	always @(*) begin
		case (select)
			4'b1000: out = a;
			4'b0100: out = b;
			4'b0010: out = c;
			4'b0001: out = d;
			default: out = {k{1'bx}};
		endcase
	end
endmodule 