`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Saumya Herath
// 
// Create Date: 07/04/2019 10:24:31 AM
// Design Name:  
// Module Name: I2C_wrapper         
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


module I2C_wrapper#(
  parameter SADR= 7'b0010000,
  parameter DATA_NUMBER = 12'h182
)(
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
  
 
  localparam PRER_LO      = 3'b000;
  localparam xPRER_LO     = 8'b00111111;          //data_PRER_LO 
  localparam PRER_HI      = 3'b001;
  localparam xPRER_HI     = 8'b00000000;         //data_PRER_HI
  localparam CTR          = 3'b010;
  localparam xCTR         = 8'b10000000;        //data_CTR
  localparam RXR          = 3'b011;
  localparam xRXR         = 8'b00000000;       //data_RXR
  localparam TXR          = 3'b011;
  localparam xTXR         = {SADR,1'b0}; //address
  localparam addmemTXR    = 8'h01;       //memory address
  localparam datTXR       = 8'h0B;       //data
  localparam dat2TXR      = 8'h45;      //data  
  localparam CR           = 3'b100;
  localparam xCR          = 8'b10010000;      //start write
  localparam xxCR         = 8'b10100000;      //start read
  localparam lastdatCR    = 8'b01010000;      //stop
  localparam datCR        = 8'b00010000;      //data transmission write
  localparam datreadCR    = 8'b0010000;       //data transmission read
  localparam rdnakstopCR  = 8'b01101000;      //data transmission read  
  localparam SR           = 3'b100;

  //states
  localparam PRESCALELO   = 8'h00;
  localparam PRESCALEHI   = 8'h01; 
  localparam CORE_EN      = 8'h02; 
  localparam IDLE         = 8'h03; 
  localparam SLAVE_ADD1   = 8'h04; 
  localparam SLAVE_ADD2   = 8'h05;
  localparam ACK_CHECK    = 8'h06;
  localparam ACK_CHECK1   = 8'h07; 
  localparam ACK_CHECK2   = 8'h08; 
  localparam ACK_CHECK3   = 8'h09;
  localparam CONSTANT1    = 8'h0A;
  localparam CONSTANT2    = 8'h0B;  
  localparam SLAVE_PAGE1  = 8'h0C; 
  localparam SLAVE_PAGE2  = 8'h0D; 
  localparam SLAVE_REGADD1= 8'h0E; 
  localparam SLAVE_REGADD2= 8'h0F; 
  localparam DATA1        = 8'h10; 
  localparam DATA2        = 8'h11; 
  localparam DONE         = 8'h12;

  
    
  input wire              clk     ;
  input           [15:0]  address ;
  input           [7:0]   data    ;
  input wire              reset   ;
  input                   start   ;
  output                  ready   ;
  output                  idle    ;
  output                  done    ;
  output wire             scl     ;
  output wire             sda     ;
  
  reg               [7:0]  state                     ;
  reg               [7:0]  next_state                ;
  reg               [7:0]  page                      ;
  reg               [7:0]  pageprevious              ;
  reg               [7:0]  regaddr                   ;
  reg               [2:0]  ack                       ;
  reg               [1:0]  counter                   ;
  reg                      counter_done              ;
  reg                      FIRST_TRANSMISSION        ;
  reg               [11:0] counter_data              ;
  reg                      counter_data_done         ;
    
  reg               [2:0] WB_ADR      ; 
  reg               [7:0] WB_DAT      ;
  reg                     WB_STB_I    ;
  reg                     WB_WE_I     ;
  reg                     WB_CYC_I    ; 
  wire              [7:0] WB_DAT_O    ;
  wire                    WB_INTA_O   ;
  wire                    SR_O        ;
  wire                    WB_ACK_O    ;




  i2c_master_top master(clk, reset,1'b1, WB_ADR, WB_DAT, WB_DAT_O,WB_STB_I,WB_WE_I,  WB_CYC_I, WB_ACK_O, WB_INTA_O,scl, sda,SR_O);
  
  assign ready=(state == IDLE);
  assign idle = (state==IDLE);
  assign done = (state==DONE);
  

  always @(posedge clk) begin
    if (reset) begin
      state<=PRESCALELO;
      next_state<= 8'h00;  
    end else begin
      state<=next_state;
    end
  end  

  always @(*) begin
  next_state=state;  
    case(state)

      PRESCALELO:	next_state=PRESCALEHI;
      				
      PRESCALEHI: 	next_state=CORE_EN;

      CORE_EN:		next_state=IDLE;

      IDLE:  		begin   
				        if (start & ready) begin
				            if (counter_data_done)
				                next_state=IDLE;
				             else begin
				                next_state=SLAVE_ADD1; 
				             end
				        end else begin
				          next_state=IDLE;
				        end
				  	end

      SLAVE_ADD1: 	next_state=SLAVE_ADD2;

      SLAVE_ADD2:	next_state=ACK_CHECK;
 
      ACK_CHECK: 	begin
			            if (counter_done) begin
			              next_state=ACK_CHECK1;
			            end else begin
			              next_state=ACK_CHECK; 
			            end
			      	end

      ACK_CHECK1:	next_state=ACK_CHECK2;
      

      ACK_CHECK2:  	begin
				        if (WB_DAT_O[1])  begin   //check the tip bit
				          next_state=ACK_CHECK1;
				        end else begin
				          next_state=ACK_CHECK3;   //RETURN STATE 
				        end
			      	end

      ACK_CHECK3: 	begin
				        case(ack)
				          3'b000:next_state= CONSTANT1;
				          3'b001:next_state=SLAVE_PAGE1;
				          3'b010:next_state=SLAVE_REGADD1;
				          3'b011:next_state=DATA1;
				          3'b100:next_state=DONE;
				          3'b101:next_state=SLAVE_ADD1;
				          
				        endcase 
				    end
      
      
      CONSTANT1: 	next_state = CONSTANT2;
         
      CONSTANT2:   	next_state = ACK_CHECK;

      SLAVE_PAGE1:  next_state = SLAVE_PAGE2;
 
      SLAVE_PAGE2:  next_state=ACK_CHECK;

      SLAVE_REGADD1:next_state=SLAVE_REGADD2;

      SLAVE_REGADD2:next_state=ACK_CHECK;

      DATA1:   		next_state=DATA2;

      DATA2: 		next_state=ACK_CHECK;

      DONE: 		next_state=IDLE; 

    endcase
   end
 

	always @(posedge clk) begin 
	    if(reset) begin
            WB_ADR <= 3'b000;
            WB_DAT <= 8'h00;
            page<=8'h00;
            regaddr<=8'h00;
            ack<=2'b00;
            pageprevious<=8'h00;
            FIRST_TRANSMISSION<=1'b1;
	    end else begin
		    case(state)

		    PRESCALELO: begin
					      WB_ADR<=PRER_LO;
					      WB_DAT<=xPRER_LO;
					    end
		      

		    PRESCALEHI: begin
					      WB_ADR<=PRER_HI;
					      WB_DAT<=xPRER_HI;
					    end

		    CORE_EN:  	begin
					      WB_ADR<=CTR;
					      WB_DAT<=xCTR;
					    end

		    IDLE:  		begin 
				          page<=address[15:8];
				          regaddr<=address[7:0]; 
					    end
		    

		    SLAVE_ADD1: begin
					      WB_ADR<=TXR;
					      WB_DAT<=xTXR;
					      if (FIRST_TRANSMISSION)
					        ack<=3'b000;
					      else
					        if (pageprevious===page) begin
					            ack<=3'b010;
					        end else begin
					            ack<=3'b000;  
					        end 
					    end

		    SLAVE_ADD2: begin
					      WB_ADR<=CR;
					      WB_DAT<=xCR;
					      FIRST_TRANSMISSION<=1'b0;
					    end

		    ACK_CHECK1: begin
					      WB_ADR<=SR;
					      WB_DAT<=8'h00;
					    end
		    
		    CONSTANT1:	begin
					      WB_ADR<=TXR;
					      WB_DAT<=8'h01;
					    end
		      
		    CONSTANT2:	begin
					       WB_ADR<=CR;
					       WB_DAT<=datCR;
					       ack<=3'b001;
					   	end
		    
		    SLAVE_PAGE1:begin
					      WB_ADR<=TXR;
					      WB_DAT<=page;
					      pageprevious<=address[15:8];
					    end


		    SLAVE_PAGE2:begin
					      WB_ADR<=CR;
					      WB_DAT<=lastdatCR;
					      ack<=3'b101;
					    end

		    SLAVE_REGADD1:	begin
						      WB_ADR<=TXR;
						      WB_DAT<=regaddr;
						    end

		    SLAVE_REGADD2:  begin
						      WB_ADR<=CR;
						      WB_DAT<=datCR;
						      ack<=3'b011;
						    end

		    DATA1:   	begin
					      WB_ADR<=TXR;
					      WB_DAT<=data;
					    end

		    DATA2: 		begin
					      WB_ADR<=CR;
					      WB_DAT<=lastdatCR;
					      ack<=3'b100;
					    end
		    endcase
		end
	end

 // WB_STB_I,WB_CYC_I
 	always@(posedge clk) begin 
	  	if(reset) begin
	        WB_STB_I     <= 'b0;
	        WB_CYC_I     <= 'b0;
	  	end else begin
		    case(state) 
		    PRESCALELO,PRESCALEHI,CORE_EN,SLAVE_ADD1,SLAVE_ADD2,ACK_CHECK,CONSTANT1,CONSTANT2,SLAVE_PAGE1,SLAVE_PAGE2,SLAVE_REGADD1,
		    SLAVE_REGADD2,DATA1,DATA2:
			    begin
			      WB_STB_I     <= 'b1;
			      WB_CYC_I     <= 'b1;
			    end
		    endcase
	    end
 	end

    always @(posedge clk) begin
        if(reset) begin
            WB_WE_I <= 'b0;
        end else begin

        case(state) 
    
        PRESCALELO,PRESCALEHI,CORE_EN,SLAVE_ADD1,SLAVE_ADD2,CONSTANT1,CONSTANT2,SLAVE_PAGE1,SLAVE_PAGE2,SLAVE_REGADD1,
        SLAVE_REGADD2,DATA1,DATA2:
	        begin
	            WB_WE_I     <= 'b1;
	        end
	    
        ACK_CHECK,ACK_CHECK1,ACK_CHECK2,ACK_CHECK3,IDLE,DONE:
	        begin
	            WB_WE_I     <= 'b0;
	        end
    
        endcase
  		end
    end
 
   
   always@(posedge clk) begin
       if(reset) begin
           counter     <= 'b0;
       end else begin
           case(state)
               ACK_CHECK,IDLE:     
                   if(counter_done) begin
                       counter <= 'b0;
                   end else begin
                       counter <= counter + 1'b1;
                   end
           endcase
       end
   end
   
   always@(*) begin
       counter_done = 1'b0;
       case(state)
           ACK_CHECK:counter_done = (counter == 2'b11);
           IDLE     :counter_done = (counter == 2'b10);
           
       endcase
   end 
           
   always@(posedge clk) begin
         if(reset) begin
             counter_data    <= 'b0;
         end else begin
             case(state)
                 DONE:     
                     if(counter_data_done) begin
                         counter_data <= 'b0;
                     end else begin
                         counter_data <= counter_data + 1'b1;
                     end
             endcase
         end
    end
    
    always@(*) begin
         counter_data_done = 1'b0;
         case(state)
             IDLE:counter_data_done = (counter_data ==DATA_NUMBER);
             DONE:counter_data_done = (counter_data ==DATA_NUMBER);
         endcase
    end  
    
   
           
endmodule


   