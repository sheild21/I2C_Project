`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Saumya Herath
// 
// Create Date: 07/04/2019 10:24:31 AM
// Design Name: WRAPPER FOR I2C COMMUNICATION
// Module Name: MEM_WRAPPER
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
module MEM_WRAPPER#(
  parameter SADR= 7'b0010000,
  parameter DATA_NUMBER = 12'h182,
  parameter PREAMBLE_WAIT =24'h493E00
)(	clk,
	start_top,
	reset,
	done,
	scl,
	sda
	
);  
    localparam RESET       = 3'b000;
    localparam DATA_DONE   = 3'b001;
    localparam WAIT        = 3'b010; 
    localparam START_HIGH  = 3'b011;
    localparam START_LOW   = 3'b100;
    localparam WAIT2       = 3'b101;
    localparam CHECK_PREAMBLE=3'b110;
    
  
	reg 			[8:0]	add_point	;
	wire			[15:0]	address 	;
	reg 			[8:0]	data_point	;
	wire			[7:0]	data 		;
	reg                     start       ;
	reg             [23:0]  count       ;
	reg                     count_done  ;
	reg             [11:0]  count1      ;
    reg                     count1_done ;
	reg             [2:0]   state1      ;
	reg             [2:0]   state2      ;
	wire                    ready       ;
	wire                    idle        ;

	input wire              clk     	;
	input wire            	start_top   ;
	input wire              reset       ;
	output wire	          	done		;
	output wire             scl         ;
	output wire             sda         ;
	


	I2C_wrapper  #(SADR,DATA_NUMBER)wrapper
	(
	    clk,
		address,
		data,
		reset,
		start,
		ready,
		idle,
		done,
		scl,
		sda
		);

	/*ADDRESS_MEM address_memory(
		add_point,
		address

		);*/

	/*DATA_MEM data_memory(
		data_point,
		data

		);*/
    ADDRESS_MEMORY address_memory (
          .clka(clk),    // input wire clka
          .addra(add_point),  // input wire [8 : 0] addra
          .douta(address)  // output wire [15 : 0] douta
        );
    DATA_MEMORY data_memory(
          .clka(clk),    // input wire clka
          .addra(data_point),  // input wire [8 : 0] addra
          .douta(data)  // output wire [7 : 0] douta
        );
        

   always @(posedge clk) begin
            if (reset) begin
              state1<=3'b000;
            end else begin
              state1<=state2;
            end
   end  
   
   always @(*) begin
            state2=state1;
      
            case(state1)
            RESET      : begin
                            if (start_top)begin                      //waiting to give the first start
                                state2<=WAIT;
                            end else begin
                                state2=RESET;
                            end
                         end
            
            DATA_DONE  : begin 
                            if (done)
                                state2<=CHECK_PREAMBLE ;
                            else
                                state2<=DATA_DONE;
                         end
                         
                         
           CHECK_PREAMBLE:begin 
                             if (count1_done)
                                 state2<=WAIT2 ;
                             else
                                 state2<=WAIT;
                           end
                           
            WAIT2        :begin
                               if(count_done)
                                   state2<=START_HIGH;
                               else
                                   state2<=WAIT2;
                          end
            
            WAIT        : begin
                            if (count_done) begin
                               state2=START_HIGH;
                            end else begin
                               state2=WAIT; 
                            end
                          end 
                          
           START_HIGH   : state2<=START_LOW;
                         
           
           START_LOW    : state2<=DATA_DONE;
            
           endcase
   end 
   
   always @(posedge clk) begin
           if (reset) begin
               add_point<='b0;
               data_point<='b0;  
               start<='b0;
           end else begin 
            case(state1)
            DATA_DONE   : begin
                             if (done) begin
                                add_point<=add_point+1'b1;
                                data_point<=data_point+1'b1;
                             end
                          end
            START_HIGH  : start<=1'b1;
            
            START_LOW   : start<=1'b0;
            endcase
          end
   end
            

	/*always @(posedge clk) begin
		if (reset) begin
			add_point<='b0;
			data_point<='b0;
		end else begin
			if (done) begin
			  	add_point<=add_point+1'b1;
				data_point<=data_point+1'b1;
		   end		
		end
	end*/
	
 /*	always @(posedge clk) begin
            if (reset) begin
                 start<=1'b0;
            end else begin
                if ((done)||(start_top)) begin
                    start<=1'b1;*/
                    /*if(count_done)
                        start<=1'b0;*/
               /* end else begin
                    start<=1'b0;
                end        
            end
        end*/
        
    always@(posedge clk) begin
       if(reset) begin
           count     <= 'b0;
       end else begin 
            case(state1) 
            WAIT,WAIT2: begin   
                   if(count_done) begin
                       count <= 'b0;
                   end else begin
                       count <= count + 1'b1;
                   end
                  end
            endcase
       end
   end
   
   always@(*) begin
       count_done = 1'b0;
       case(state1) 
       WAIT:count_done = (count == 2'b11);
       WAIT2:count_done = (count == PREAMBLE_WAIT);
       
      
       endcase
   end 
   
   always@(posedge clk) begin
          if(reset) begin
              count1     <= 'b0;
          end else begin 
               case(state1) 
               DATA_DONE: begin 
                                if (done) begin  
                                  if(count1_done) begin
                                      count1 <= 'b0;
                                  end else begin
                                      count1 <= count1 + 1'b1;
                                  end
                                end
                          end
               endcase
          end
      end
      
      always@(*) begin
          count1_done = 1'b0;
          case(state1) 
          CHECK_PREAMBLE:count1_done = (count1 == 2'b11);
          DATA_DONE     :count1_done = (count1 == DATA_NUMBER);
          
         
          endcase
      end 
        
	
endmodule // MEM_WRAPPER