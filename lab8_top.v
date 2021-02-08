`define MWRITE 2'b10
`define MREAD 2'b01



module lab8_top(KEY,SW,LEDR,HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,CLOCK_50);
    parameter file = "lab8fig4.txt";
    input [3:0] KEY;
    input [9:0] SW;
    input CLOCK_50;
    output [9:0] LEDR;
    output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    wire [15:0] write_data, dout;
    wire [8:0] mem_addr;
    wire [1:0] mem_cmd;
    wire N, V, Z, msel;
    reg [9:0] LEDR;
    reg [15:0] read_data;
    reg load_top, write_top;
    reg load_d, write;

    // lab 8, present FSM state, clock
    wire [6:0] state;
    wire clk = CLOCK_50;

    //cpu CPU(clk, reset, read_data, write_data, N, V, Z, mem_cmd, mem_addr);
    cpu CPU(clk, ~KEY[1], read_data, write_data, N, V, Z, mem_cmd, mem_addr, state);

    // WHEN EXECUTING HALT, LED[8] IS 1
    always @(*) begin  
        if(state == 7'b1111111) begin
            LEDR[8] = 1'b1;
        end else begin
            LEDR[8] = 1'b0;
        end
    end

    //RAM SETUP
    RAM #(file, 16, 8) MEM(clk, mem_addr[7:0], mem_addr[7:0], write, write_data, dout);

    //MSEL
    assign msel = (1'b0 == mem_addr[8])? 1'b1: 1'b0;
    // //TRI STATE BUFFER
    // assign read_data = load_d? dout: {16{1'bz}};

    //LOGIC INTO WRITE
    always @(*) begin
        if(mem_cmd == `MWRITE) begin
            write = msel;
        end else begin
            write = 1'b0;
        end
    end
    //LOGIC INTO READ
    always @(*) begin
        if(mem_cmd == `MREAD) begin
            load_d = msel;
        end else begin
            load_d = 1'b0;
        end
    end


    //LOGIC FOR SWITCHES
    always @(*) begin
        if(mem_cmd == `MREAD & mem_addr == 9'h140) begin
            load_top = 1'b1;
        end else begin
            load_top = 1'b0;
        end


        if(load_top == 1'b1) begin
            read_data = {8'b0, SW[7:0]};
        end else begin 
            read_data = load_d? dout: {16{1'bz}};
        end
    end

    //LOGIC FOR LEDS
    always @(*) begin
        if(mem_cmd == `MWRITE & mem_addr == 9'h100) begin
            write_top = 1'b1;
        end else begin
            write_top = 1'b0;
        end
    end

    always @(posedge clk) begin
        if(write_top == 1'b1) begin
            LEDR[7:0] = write_data[7:0];
        end
    end
endmodule