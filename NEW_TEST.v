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


module NEW_TEST;
//wires and reg
  reg         wb_clk_i;     // master clock input
	reg         wb_rst_i;     // synchronous active high reset
	reg  [2:0]  wb_adr_i;     // lower address bits
	reg  [7:0]  wb_dat_i;     // databus input
	wire [7:0]  wb_dat_o;     // databus output
	reg         wb_we_i;      // write enable input
	reg         wb_stb_i;     // stobe/core select signal
	reg         wb_cyc_i;     // valid bus cycle input
	
	wire        wb_ack_o;     // bus cycle acknowledge output
	wire        wb_inta_o;
	
  wire        scl;
  wire sda; 
  wire [7:0]  sr_o;
  reg  [7:0]  OUT;
  reg  [7:0]  RX;
    

    
    parameter waiting=1;
    
  parameter PRER_LO  = 3'b000;
  parameter xPRER_LO = 8'b00111111;
   
  parameter PRER_HI  = 3'b001;
  parameter xPRER_HI = 8'b00000000;
    
  parameter CTR     = 3'b010;
  parameter xCTR    = 8'b10000000;
    
  parameter RXR     = 3'b011;
  parameter xRXR    = 8'b00000000;
    
  parameter TXR     = 3'b011;
  parameter xTXR    = 8'b00100000; //address
  parameter addmemTXR = 8'h01;  //memory address
  parameter datTXR  = 8'h0B;       //data
   parameter dat2TXR  = 8'h45;      //data
    
  parameter CR      = 3'b100;
  parameter xCR     = 8'b10010000;      //start write
  parameter xxCR    = 8'b10100000;      //start read
  parameter lastdatCR=8'b01010000;      //stop
  parameter datCR   = 8'b00010000;      //data transmission write
  parameter datreadCR   = 8'b0010000;  //data transmission read
  parameter datreadnakstopCR   = 8'b01101000;  //data transmission read
    
  parameter SR      = 3'b100;
  
  parameter SADR= 7'b0010000;


    
    
   // always #31.25 wb_clk_i=~wb_clk_i;
  i2c_master_top i2c_top(
    .wb_clk_i(wb_clk_i), //
    .wb_rst_i(wb_rst_i), //
    .arst_i(1'b1), //'b
    .wb_adr_i(wb_adr_i), //
    .wb_dat_i(wb_dat_i), 
    .wb_dat_o(wb_dat_o),
    .wb_we_i(wb_we_i),
    .wb_stb_i(wb_stb_i), 
    .wb_cyc_i(wb_cyc_i), 
    .wb_ack_o(wb_ack_o), 
    .wb_inta_o(wb_inta_o),
    .scl(scl),
    .sda(sda),
    .sr_o(sr_o));
    
    // hookup i2c slave model
  i2c_slave_model #(SADR)  i2c_slave (
    .scl(scl),
    .sda(sda)
    );
    
  
     initial begin
       wb_clk_i=0;
       forever 
         begin
           #31.25 wb_clk_i=~wb_clk_i;             
         end  
       end
        
       pullup r1(scl);
       pullup r2(sda);       
        
 task write;
       input waiting;
       integer waiting; 
       input [2:0]address;
       input [7:0]data;
       
        begin
        @(posedge wb_clk_i); //prescaling the clock  //32 MHz clock to 100KHz
           
              wb_adr_i<=address;
              wb_dat_i<=data;
              wb_we_i<=1;
              wb_stb_i<=1'b1;
              wb_cyc_i<=1'b1;
            
            @(posedge wb_clk_i );  
            while (~wb_ack_o) @(posedge wb_clk_i);
              
             wb_cyc_i  <= 1'b0;
             wb_stb_i <= 1'b0;
             wb_adr_i<= 3'b000;
             wb_dat_i<= 8'h00;
             wb_we_i <= 1'h0;
             
             end
          //sel  = {dwidth/8{1'bx}};
    endtask
    
    
    
    task read;
        input waiting;
        integer waiting; 
        input [2:0]address;
        output [7:0]data;
      
        begin
        @(posedge wb_clk_i); 
              wb_adr_i<=address;
              wb_dat_i<=8'h00;
              wb_we_i<=0;
              wb_stb_i<=1'b1;
              wb_cyc_i=1'b1;
            
            @(posedge wb_clk_i );  
            while (~wb_ack_o) @(posedge wb_clk_i);
              
             wb_cyc_i  <= 1'b0;
             wb_stb_i <= 1'b0;
             wb_adr_i<= 3'b000;
             wb_dat_i<= 8'h00;
             wb_we_i <= 1'h0;
             data <= wb_dat_o;
             @(posedge wb_clk_i);
             
             end
          //sel  = {dwidth/8{1'bx}};
    endtask
 
        
  initial begin
       wb_rst_i<=1'b1;
       wb_adr_i<=3'b000;
       wb_dat_i<=8'h00;
       wb_stb_i<=1'b0;
       wb_cyc_i<=1'b0; 
       wb_we_i<=1'b0; 
       repeat(10) @(posedge wb_clk_i);
        wb_rst_i<=1'b0;
       repeat(10) @(posedge wb_clk_i);
       
       write(1,PRER_LO,xPRER_LO );
       write(1,PRER_HI,xPRER_HI );
       write(1,CTR,xCTR );
       ///WRITING
       write(1,TXR,xTXR ); //SLAVE ADDRESS
       write(1,CR,xCR ); //START TRANSMISSION
       //STATUR REGISTER
       read(1,SR,OUT);
       //@(posedge wb_clk_i);
       while (OUT[1])
        begin
            read(0,SR,OUT);
            //@(posedge wb_clk_i);   ///wait til the tip=0   
        end
        
       repeat(2*waiting) @(posedge wb_clk_i);
        write(1,TXR,addmemTXR );  //memory address 
        write(1,CR,datCR);  //send memory address 
       
       //STATUR REGISTER
        read(1,SR,OUT);
               
        while (OUT[1])
            begin
              read(1,SR,OUT);   ///wait til the tip=0
                           
        end
        
        
       repeat(2*waiting) @(posedge wb_clk_i);
       write(1,TXR,datTXR );  //data byte transmission
       write(1,CR,lastdatCR );
       
       //STATUR REGISTER
        read(1,SR,OUT);
       
        while (OUT[1])
           begin
              read(1,SR,OUT);
                ///wait til the tip=0
                 
           end
           
     //READING
     
      //repeat(1) @(posedge wb_clk_i);
      write(1,TXR,xTXR); //SLAVE ADDRESS
      write(1,CR,xCR);
           
      read(1,SR,OUT);    //STATUR REGISTER
      while (OUT[1])read(1,SR,OUT);          ///wait til the tip=0   
        
      //repeat(2*waiting) @(posedge wb_clk_i);
      write(1,TXR,addmemTXR );  //memory address 
      write(0,CR,datCR);  //send memory address 
      //STATUR REGISTER
      read(1,SR,OUT);
      while (OUT[1]) read(1,SR,OUT);   ///wait til the tip=0          
   
       //repeat(1) @(posedge wb_clk_i);
        //repeated START TRANSMISSION
       write(1,TXR,8'b00100001); //SLAVE ADDRESS
       write(1,CR,xCR );
                  
       read(1,SR,OUT);            
       while (OUT[1]) read(1,SR,OUT);          ///wait til the tip=0   
            
      //repeat(2*waiting) @(posedge wb_clk_i);
      //write(1,TXR,addmemTXR );  //memory address 
      write(1,CR,8'b00101000);  
          //STATUR REGISTER
     read(1,SR,OUT);
     while (OUT[1]) read(1,SR,OUT);   ///wait til the tip=0
     read(1,RXR,RX);
     
     write(1,CR,8'b01000000);  
     read(1,SR,OUT);
     while (OUT[1]) read(1,SR,OUT);          
      
     
        
        
      end

endmodule