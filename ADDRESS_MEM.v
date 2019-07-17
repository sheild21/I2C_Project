module ADDRESS_MEM
(   //clk,
	add_point,
	address
);
	

	reg                 [15:0] address_mem [0:386];
    //input               clk;
	input				[8:0]	add_point;
	output				[15:0]	address;

	assign address[15:0]=address_mem[add_point];

	
	initial  $readmemh("G:/intern/I2C_ROM_WRAP1/ADD_MEM.txt",address_mem,0,386);

	

endmodule // ADDRESS_MEM