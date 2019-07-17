module DATA_MEM
(
	data_point,
	data
);
	

	reg                 [7:0] data_mem [386:0];

	input				[8:0]	data_point;
	output				[7:0]	data;

	assign data[7:0]=data_mem[data_point];
	initial  $readmemh("G:/intern/I2C_ROM_WRAP1/DAT_MEM.txt",data_mem);


	

endmodule // DATA_MEM

