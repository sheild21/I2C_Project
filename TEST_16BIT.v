`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/26/2019 11:49:57 AM
// Design Name: 
// Module Name: top_test_my
// Project Name: 
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

module TEST_16BIT;
	reg clk;
	reg [16:0] address;
	reg [7:0] data;
	reg reset;
	reg start;
	wire ready;
	wire idle;
	wire done;
	wire scl;
	wire sda;

	//reg [7:0] X;
	
    /*reg [7:0] state;
    reg [7:0] page;
    reg [7:0] pageprevious;
    reg [7:0] regaddr;
    reg [1:0] ack;
    reg [7:0] OUT;
    
    reg [2:0]WB_ADR; 
    reg [7:0] WB_DAT;
    reg WB_STB_I,WB_WE_I,  WB_CYC_I; 
    wire [7:0] WB_DAT_O;
    wire WB_INTA_O,SR_O, WB_ACK_O;*/
        

    
    parameter SADR= 7'b0010000;

	I2C_wrapper wrapper(
		.clk(clk),
		.address(address),
		.data(data),
		.reset(reset),
		.start(start),
		.ready(ready),
		.idle(idle),
		.done(done),
		.scl(scl),
		.sda(sda)
		);
	/*i2c_master_top master(
		.wb_clk_i(clk), //
		.wb_rst_i(reset), //
		.arst_i(1'b1), //'b
		.wb_adr_i(WB_ADR), 
		.wb_dat_i(WB_DAT), 
		.wb_dat_o(WB_DAT_O),
		.wb_we_i(WB_WE_I),
		.wb_stb_i(WB_STB_I), 
		.wb_cyc_i(WB_CYC_I), 
		.wb_ack_o(WB_ACK_O), 
		.wb_inta_o(WB_INTA_O),
		.scl(scl),
		.sda(sda),
		.sr_o(SR_O)
		);*/



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
    	start<=1'b0;
    	repeat(10) @(posedge clk);
    	reset<=1'b0;
    	repeat(10) @(posedge clk);
    	start<=1'b1;
    	address<=16'h0203;
    	data<=8'h04;
    	repeat(1) @(posedge clk);
    	start<=1'b0;
    	
    	
    	repeat(20000) @(posedge clk);
    	start<=1'b1;
        address<=16'h0208;
        data<=8'h04;
        repeat(1) @(posedge clk);
        start<=1'b0;
        
        repeat(20000) @(posedge clk);
        start<=1'b1;
        address<=16'h030A;
        data<=8'h14;
        repeat(1) @(posedge clk);
        start<=1'b0;
    end // initial




endmodule
