module ADDRESS_MEM_TEST;
    reg clk;
	reg add_point;
	wire address;

	ADDRESS_MEM(
		.add_point(add_point),
		.address(address)


		);

	initial begin
		add_point<=8'h00;
		#10
		add_point<=8'h02;	
	end	


endmodule