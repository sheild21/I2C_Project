`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Saumya Herath
// 
// Create Date: 07/04/2019 10:24:31 AM
// Design Name: 
// Module Name: MEM_WRAPPER_TEST
// Project Name: I2C
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module MEM_WRAPPER_TEST;
	reg clk;
	reg reset;
	reg start_top;
	wire done;
	wire scl;
	wire sda;
	reg[11:0] i;
        

    
    parameter SADR= 7'b0010000;

	MEM_WRAPPER #(SADR,12'h182)mem_wrapper(
		.clk(clk),
		.reset(reset),
		.start_top(start_top),
		.done(done),
		.scl(scl),
		.sda(sda)
		);


    i2c_slave_model #(SADR) i2c_slave (
        .scl(scl),
        .sda(sda)
        );

	pullup p1(scl); // pullup scl line
	pullup p2(sda); // pullup sda line

	initial begin
    clk=0;
    forever 
	    begin
	       #31.25 clk=~clk;             
	    end  
    end

    initial begin
    	reset<=1'b1;
    	start_top<=1'b0;
    	repeat(10) @(posedge clk);
    	reset<=1'b0;
        start_top<=1'b1;
        repeat(1) @(posedge clk);
        start_top<=1'b0;
    	
    end // initial

endmodule
