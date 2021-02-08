module ALU(Ain, Bin, ALUop, out, Z);
	input [15:0] Ain, Bin;
	input [1:0] ALUop;
	output [15:0] out;
	output [2:0] Z;
	
	wire [15:0] Ain, Bin;
	
	reg [15:0] operationResult;
	reg [2:0] Zresult;
	
	reg [15:0] unsignedBin;
	
	assign out = operationResult;
	assign Z = Zresult;
	
	//Depending on ALUop's value, completes the operation result with Ain and Bin
	always @(*) begin
		unsignedBin = Bin;
		Zresult = 3'b0;
		case (ALUop)
			2'b00: operationResult = Ain + Bin;
			2'b01: operationResult = Ain - Bin;
			2'b10: operationResult = Ain & Bin;
			2'b11: operationResult = ~unsignedBin;
			default: operationResult = {16{1'bx}};
		endcase
		
		//if result zero, indicate
		if(operationResult == 16'b0) begin
			//zero flag
			Zresult[0] = 1'b1;
		end
		
		//if result is less than 0
		if(operationResult[15] == 1) begin
			//negative flag
			Zresult[1] = 1'b1;
		end
		
		//to check for overflow, first need to know which operation
		if (ALUop == 2'b00) begin
			//if same sign, possible overflow
			if(Ain[15] == Bin[15]) begin
				//if sign change, there is overflow
				if(operationResult[15] !== Ain[15]) begin
					//overflow flag
					Zresult[2] = 1'b1;
				end
			end
		
		//if subtraction, opposite rules apply
		end else if (ALUop == 2'b01) begin
			//if opposite sign, possible overflow
			if(Ain[15] !== Bin[15]) begin
				//if sign change, there is overflow
				if(operationResult[15] !== Ain[15]) begin
					//overflow flag
					Zresult[2] = 1'b1;
				end
			end
		end
	end
endmodule
