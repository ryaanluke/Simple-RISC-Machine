module dflipflop(clk,D,Q, load);
  //parameter n allows the changing of input and outside size D, Q
  parameter n=1;
  input clk, load;
  input [n-1:0] D;
  output [n-1:0] Q;
  reg [n-1:0] Q;
  //simple flipflop to copy over Q onto D if load is 1
  always @(posedge clk)
	if (load) begin
		Q = D;
	end
endmodule
