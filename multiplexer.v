module multiplexer(select, a, b, out);
	//parameter allows for any input and output bit size
	parameter k = 16;
	input select;
	input [k-1: 0] a, b;
	output [k-1: 0] out;
	reg [k-1: 0] out;
	//combinational logic to choose out to be a or b based on select.
	always @(*) begin
		if (select) begin
			out = a;
		end else begin
			out = b;
		end
	end

endmodule
