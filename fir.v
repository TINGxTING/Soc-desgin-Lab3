`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/10/08 15:35:02
// Design Name: 
// Module Name: fir
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
module fir 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)                                                      
(
///////////////////axi-lite////////////////////
    output  wire                     awready,        
    output  wire                     wready,        
    input   wire                     awvalid,       
    input   wire [(pADDR_WIDTH-1):0] awaddr,         
    input   wire                     wvalid,          
    input   wire [(pDATA_WIDTH-1):0] wdata,       
    output  wire                     arready,        
    input   wire                     rready,        
    input   wire                     arvalid,        
    input   wire [(pADDR_WIDTH-1):0] araddr,         
    output  wire                     rvalid,           
    output  wire [(pDATA_WIDTH-1):0] rdata,           
    ///////////////////stream///////////////////////////
    input   wire                     ss_tvalid,           
    input   wire [(pDATA_WIDTH-1):0] ss_tdata,           
    input   wire                     ss_tlast,            
    output  wire                     ss_tready,          
    input   wire                     sm_tready, 
    output  wire                     sm_tvalid, 
    output  wire [(pDATA_WIDTH-1):0] sm_tdata,            
    output  wire                     sm_tlast, 
    // bram for tap RAM
    output  wire [3:0]               tap_WE,
    output  wire                     tap_EN,
    output  wire [(pDATA_WIDTH-1):0] tap_Di,
    output  wire [(pADDR_WIDTH-1):0] tap_A,
    input   wire [(pDATA_WIDTH-1):0] tap_Do,

    // bram for data RAM
    output  wire [3:0]               data_WE,
    output  wire                     data_EN,
    output  wire [(pDATA_WIDTH-1):0] data_Di,
    output  wire [(pADDR_WIDTH-1):0] data_A,
    input   wire [(pDATA_WIDTH-1):0] data_Do,

    input   wire                     axis_clk,              
    input   wire                     axis_rst_n                 
);
    
    // write your code here!
 parameter S0 = 2'b00;
 parameter S1 = 2'b01;
 parameter S2 = 2'b10;
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////  
    reg                     awready_reg;     
    reg                     wready_reg;      
    reg                     arready_reg;        
    reg                     rvalid_reg;           
    reg [(pDATA_WIDTH-1):0] rdata_reg;             
    reg                     ss_tready_reg;             
    reg                     sm_tvalid_reg; 
    reg [(pDATA_WIDTH-1):0] sm_tdata_reg;           
    reg                     sm_tlast_reg; 
    reg [3:0]               tap_WE_reg;
    reg                     tap_EN_reg;
    reg [(pDATA_WIDTH-1):0] tap_Di_reg;
    reg [(pADDR_WIDTH-1):0] tap_A_reg;
    reg [3:0]               data_WE_reg;
    reg                     data_EN_reg;
    reg [(pDATA_WIDTH-1):0] data_Di_reg;
    reg [(pADDR_WIDTH-1):0] data_A_reg;
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    reg [31:0] data_length;
    reg [31:0] length_counter;
    reg ap_start;
    reg ap_idle;
    reg ap_done;
    reg [31:0] read_temp;
    reg [31:0] write_temp;
    reg [1:0] stop;
    reg d; //use at data_A_reg for three clk
    reg [1:0] curr_state;
    reg [1:0] next_state;
    reg start; ////use at data_A_reg
    reg [3:0] counter;   
    reg [31:0] value;
    reg [31:0] temp;
    reg [31:0] next_value;
    reg skip;
    reg c;
   /////////////////////////////////////////////////////////////////////////////////////////////////////////
   assign awready = awready_reg;
   assign wready = wready_reg;
   assign arready = arready_reg;
   assign rvalid = rvalid_reg;
   assign rdata = rdata_reg;
   assign ss_tready = ss_tready_reg;
   assign sm_tvalid = sm_tvalid_reg;
   assign sm_tdata = sm_tdata_reg;
   assign sm_tlast = sm_tlast_reg;
   assign tap_WE = tap_WE_reg;
   assign tap_EN = tap_EN_reg;
   assign tap_Di = tap_Di_reg;
   assign tap_A = tap_A_reg;
   assign data_WE = data_WE_reg;
   assign data_EN = data_EN_reg;
   assign data_Di = data_Di_reg;
   assign data_A = data_A_reg;  
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always @* begin
    if(!axis_rst_n) begin
        tap_EN_reg = 0; 
        tap_WE_reg = 4'b0000;
        data_length = 0;
    end
    else if (arvalid && rvalid_reg) begin
        case(araddr)                 
            8'h20 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b0000; end
            8'h24 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b0000; end
            8'h28 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b0000; end
            8'h2c :  begin tap_EN_reg = 1; tap_WE_reg = 4'b0000; end 
            8'h30 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b0000; end
            8'h34 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b0000; end
            8'h38 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b0000; end
            8'h3c :  begin tap_EN_reg = 1; tap_WE_reg = 4'b0000; end
            8'h40 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b0000; end
            8'h44 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b0000; end
            8'h48 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b0000; end
            default : begin tap_EN_reg = 1; tap_WE_reg = 4'b0000; end
        endcase
    end
    else if(awvalid && wvalid) begin
            case(awaddr)                
            8'h10 :  begin tap_EN_reg =0; tap_WE_reg = 4'b0000; data_length = wdata; end   
            8'h20 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b1111; end
            8'h24 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b1111; end
            8'h28 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b1111; end
            8'h2c :  begin tap_EN_reg = 1; tap_WE_reg = 4'b1111; end 
            8'h30 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b1111; end
            8'h34 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b1111; end
            8'h38 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b1111; end
            8'h3c :  begin tap_EN_reg = 1; tap_WE_reg = 4'b1111; end
            8'h40 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b1111; end
            8'h44 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b1111; end
            8'h48 :  begin tap_EN_reg = 1; tap_WE_reg = 4'b1111; end
            default : begin tap_EN_reg = 0; tap_WE_reg = 4'b0000; end
        endcase
    end
    else if(curr_state == 2'b01 || curr_state == 2'b10) begin
      	tap_EN_reg = 1;
  	tap_WE_reg = 4'b0000;
    end
    end      
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
 always @* begin
 if(!axis_rst_n)begin
    tap_A_reg = 12'd0;
    tap_Di_reg = 32'd0;
    awready_reg=0; wready_reg=0;
    arready_reg = 0;
 end
 else if(awvalid && wvalid && ap_done == 0) begin
    case(awaddr[7:4])
    4'b0000 : begin ap_start = wdata[0]; awready_reg=1; wready_reg=1 ; end                          
    4'b0001 : begin tap_A_reg[3:0] = 12'd0; tap_Di_reg = 32'd0; awready_reg=1; wready_reg=1; end 
    4'b0010 : begin tap_A_reg[3:0] = awaddr[3:0]; tap_A_reg[11:4] = 8'b00000000; tap_Di_reg = wdata; awready_reg=1; wready_reg=1; end
    4'b0011 : begin tap_A_reg[3:0] = awaddr[3:0]; tap_A_reg[11:4] = 8'b00000001; tap_Di_reg = wdata; awready_reg=1; wready_reg=1; end
    4'b0100 : begin tap_A_reg[3:0] = awaddr[3:0]; tap_A_reg[11:4] = 8'b00000010; tap_Di_reg = wdata; awready_reg=1; wready_reg=1; end
    4'b0101 : begin tap_A_reg[3:0] = awaddr[3:0]; tap_A_reg[11:4] = 8'b00000011; tap_Di_reg = wdata; awready_reg=1; wready_reg=1; end
    4'b0110 : begin tap_A_reg[3:0] = awaddr[3:0]; tap_A_reg[11:4] = 8'b00000100; tap_Di_reg = wdata; awready_reg=1; wready_reg=1; end
    4'b0111 : begin tap_A_reg[3:0] = awaddr[3:0]; tap_A_reg[11:4] = 8'b00000101; tap_Di_reg = wdata; awready_reg=1; wready_reg=1; end
    4'b1000 : begin tap_A_reg[3:0] = awaddr[3:0]; tap_A_reg[11:4] = 8'b00000110; tap_Di_reg = wdata; awready_reg=1; wready_reg=1; end
    4'b1001 : begin tap_A_reg[3:0] = awaddr[3:0]; tap_A_reg[11:4] = 8'b00000111; tap_Di_reg = wdata; awready_reg=1; wready_reg=1; end
    4'b1010 : begin tap_A_reg[3:0] = awaddr[3:0]; tap_A_reg[11:4] = 8'b00001000; tap_Di_reg = wdata; awready_reg=1; wready_reg=1; end
    4'b1011 : begin tap_A_reg[3:0] = awaddr[3:0]; tap_A_reg[11:4] = 8'b00001001; tap_Di_reg = wdata; awready_reg=1; wready_reg=1; end
    4'b1100 : begin tap_A_reg[3:0] = awaddr[3:0]; tap_A_reg[11:4] = 8'b00001010; tap_Di_reg = wdata; awready_reg=1; wready_reg=1; end
    4'b1101 : begin tap_A_reg[3:0] = awaddr[3:0]; tap_A_reg[11:4] = 8'b00001011; tap_Di_reg = wdata; awready_reg=1; wready_reg=1; end
    4'b1110 : begin tap_A_reg[3:0] = awaddr[3:0]; tap_A_reg[11:4] = 8'b00001100; tap_Di_reg = wdata; awready_reg=1; wready_reg=1; end
    4'b1111 : begin tap_A_reg[3:0] = awaddr[3:0]; tap_A_reg[11:4] = 8'b00001101; tap_Di_reg = wdata; awready_reg=1; wready_reg=1; end
    default : begin tap_A_reg = 12'd2; tap_Di_reg = 32'd0; awready_reg = 0; wready_reg = 0;end
    endcase
    end
  else if(arvalid && rready && curr_state == 2'b00 && ap_done == 0)begin
    tap_A_reg[11:8] = 4'd0;
    case(araddr[7:4])
    4'b0010 : begin tap_A_reg = araddr[3:0]; arready_reg =1; end
    4'b0011 : begin tap_A_reg = araddr[3:0]; tap_A_reg[7:4] = 4'b0001; arready_reg=1; end
    4'b0100 : begin tap_A_reg = araddr[3:0]; tap_A_reg[7:4] = 4'b0010; arready_reg=1; end
    4'b0101 : begin tap_A_reg = araddr[3:0]; tap_A_reg[7:4] = 4'b0011; arready_reg=1; end
    4'b0110 : begin tap_A_reg = araddr[3:0]; tap_A_reg[7:4] = 4'b0100; arready_reg=1; end
    4'b0111 : begin tap_A_reg = araddr[3:0]; tap_A_reg[7:4] = 4'b0101; arready_reg=1; end
    4'b1000 : begin tap_A_reg = araddr[3:0]; tap_A_reg[7:4] = 4'b0110; arready_reg=1; end
    4'b1001 : begin tap_A_reg = araddr[3:0]; tap_A_reg[7:4] = 4'b0111; arready_reg=1; end
    4'b1010 : begin tap_A_reg = araddr[3:0]; tap_A_reg[7:4] = 4'b1000; arready_reg=1; end
    4'b1011 : begin tap_A_reg = araddr[3:0]; tap_A_reg[7:4] = 4'b1001; arready_reg=1; end
    4'b1100 : begin tap_A_reg = araddr[3:0]; tap_A_reg[7:4] = 4'b1010; arready_reg=1; end
    4'b1101 : begin tap_A_reg = araddr[3:0]; tap_A_reg[7:4] = 4'b1011; arready_reg=1; end
    4'b1110 : begin tap_A_reg = araddr[3:0]; tap_A_reg[7:4] = 4'b1100; arready_reg=1; end
    4'b1111 : begin tap_A_reg = araddr[3:0]; tap_A_reg[7:4] = 4'b1101; arready_reg=1; end
    default : begin tap_A_reg = 12'd0; tap_Di_reg = 32'd0;  arready_reg=0 ;end
    endcase
 end
  else if((curr_state == 2'b01 || curr_state == 2'b10) && ap_done == 0) begin
  	if(counter == 1)begin
  	tap_A_reg = 12'd0;
  	end
  	else if(counter == 2) begin
  	tap_A_reg = 12'd4;
  	end
  	else if(counter == 3) begin
  	tap_A_reg = 12'd8;
  	end
  	else if(counter == 4) begin
  	tap_A_reg = 12'd12;
  	end
  	else if(counter == 5) begin
  	tap_A_reg = 12'd16;
  	end
   	else if(counter == 6) begin
  	tap_A_reg = 12'd20;
  	end
  	else if(counter == 7) begin
  	tap_A_reg = 12'd24;
  	end
  	else if(counter == 8) begin
  	tap_A_reg = 12'd28;
  	end
  	else if(counter == 9) begin
  	tap_A_reg = 12'd32;
  	end
  	else if(counter == 10) begin
  	tap_A_reg = 12'd36;
  	end
  	else if(counter == 0) begin
  	tap_A_reg = 12'd40;
  	end  
  end
 end
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////ap_idle
 	always@(posedge axis_clk) begin
 	if(!axis_rst_n) begin
 	ap_idle <= 1;
 	end
 	else if(awvalid && wvalid && ap_done == 0 && awaddr[7:4] == 4'b0000) begin
 	ap_idle <= 0;
 	end
 	else if(ap_done == 1)begin
 	ap_idle <= 1;
 	end
 end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////     
	always @(posedge axis_clk) begin
	if(!axis_rst_n) begin
	rvalid_reg = 0;
	end
	else if(arvalid == 0 && length_counter != 600) begin
		rvalid_reg = 0;
	end
	else if(arvalid == 1 && length_counter != 600) begin
		rvalid_reg = 1;
	

	end
	else if(araddr == 12'h00 && arvalid && rready && length_counter == 600 && ap_done && ap_idle ==0) begin
		rvalid_reg = 1;
	end
	else if(araddr == 12'h00 && arvalid && rready && length_counter == 600 && ap_idle ) begin
		rvalid_reg = 1;
	end
	else begin
	rvalid_reg = 0;
	end
end
//////////////////////////////////////////////////////////////
	always @* begin
	if(!axis_rst_n) begin
	rdata_reg = 0;
	c = 0;
	end	
	else if(arvalid && rready && araddr != 12'h00) begin
	rdata_reg = tap_Do;
	end
	else if(araddr == 12'h00 && arvalid && rready && length_counter == 600 && ap_done && ap_idle ==0) begin
		rdata_reg = 32'd2;
	end
	else if(araddr == 12'h00 && arvalid && rready && length_counter == 600 && ap_idle && rvalid_reg == 0 ) begin
		if(c==0)begin
		c = 1;
		 end
		 else begin
		rdata_reg = 32'd4;
		end
	end	
	
end
///////////////////////////////////////////////////////////////
	always @* begin
	if(!axis_rst_n)begin
	ap_done = 0;
	end	
	else if(length_counter == 600 ) begin
	ap_done = 1;
	end
end 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
always @(posedge axis_clk) begin
	if(!axis_rst_n) begin
	data_A_reg = 12'd0;
	stop = 1;
	d = 0;
	//start=1;
	counter = 4'd0;
	next_state = 2'd0;
	end
	else if(ss_tvalid && ap_start && curr_state == 2'b00) begin   /// maintain 1 clk
		if(counter == 4'd0) begin
			data_A_reg = 12'd0;
			counter = counter + 1;
		end
		else if(counter == 4'd1) begin
			data_A_reg = 12'd4;
			counter = counter + 1;
		end
		else if(counter == 4'd2) begin
			data_A_reg = 12'd8;
			counter = counter + 1;
		end
		else if(counter == 4'd3) begin
			data_A_reg = 12'd12;
			counter = counter + 1;
		end
		else if(counter == 4'd4) begin
			data_A_reg = 12'd16;
			counter = counter + 1;
		end
		else if(counter == 4'd5) begin
			data_A_reg = 12'd20;
			counter = counter + 1;
		end
		else if(counter == 4'd6) begin
			data_A_reg = 12'd24;
			counter = counter + 1;
		end
		else if(counter == 4'd7) begin
			data_A_reg = 12'd28;
			counter = counter + 1;
		end
		else if(counter == 4'd8) begin
			data_A_reg = 12'd32;
			counter = counter + 1;
		end
		else if(counter == 4'd9) begin
			data_A_reg = 12'd36;
			counter = counter + 1;
		end
		else if(counter == 4'd10) begin
			data_A_reg = 12'd40;
			counter = 4'd0;
			next_state = S2;
		end
	end
	else if(ss_tvalid && ap_start && curr_state == 2'b01) begin   /// maintain 2 clk
		if(stop == 1) begin
				if(counter == 4'd0) begin
					data_A_reg = 12'd0;
					counter = counter + 1;    
					stop = 0;
				end
				else if(counter == 4'd1) begin
					data_A_reg = 12'd4;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd2) begin
					data_A_reg = 12'd8;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd3) begin
					data_A_reg = 12'd12;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd4) begin
					data_A_reg = 12'd16;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd5) begin
					data_A_reg = 12'd20;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd6) begin
					data_A_reg = 12'd24;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd7) begin
					data_A_reg = 12'd28;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd8) begin
					data_A_reg = 12'd32;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd9) begin
					data_A_reg = 12'd36;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd10) begin
					data_A_reg = 12'd40;
					counter = 4'd0;
					stop = 0;
				end
		end
		else begin
			data_A_reg = data_A_reg;
			stop = 1;
			if(counter == 0 && stop == 1) begin
			next_state = S2;
			end
		end
	end	
	else if(ss_tvalid && ap_start && curr_state == 2'b10)begin                  /// maintain 3 clk   clk1:stop ==0, d==0  clk2: stop == 1, d == 1 clk3: stop =1 d == 0.....
        	if(stop == 1 && d==0) begin
 			if(counter == 4'd0) begin
 			data_A_reg = 4'd0;
 			counter = counter + 1;
 			stop = 0;
 			end
 			else if(counter == 4'd1) begin
 			data_A_reg = 12'd4;
 			counter = counter + 1;
 			stop = 0;
 			end
 			else if(counter == 4'd2) begin
 			data_A_reg = 12'd8;
 			counter = counter + 1;
 			stop = 0;
 			end
 			else if(counter == 4'd3) begin
 			data_A_reg = 12'd12;
 			counter = counter + 1;
 			stop = 0;
 			end			
 			else if(counter == 4'd4) begin
 			data_A_reg = 12'd16;
 			counter = counter + 1;
 			stop = 0;
 			end 		
  			else if(counter == 4'd5) begin
 			data_A_reg = 12'd20;
 			counter = counter + 1;
 			stop = 0;
 			end
  			else if(counter == 4'd6) begin
 			data_A_reg = 12'd24;
 			counter = counter + 1;
 			stop = 0;
 			end
  			else if(counter == 4'd7) begin
 			data_A_reg = 12'd28;
 			counter = counter + 1;
 			stop = 0;
 			end
  			else if(counter == 4'd8) begin
 			data_A_reg = 12'd32;
 			counter = counter + 1;
 			stop = 0;
 			end
  			else if(counter == 4'd9) begin
 			data_A_reg = 12'd36;
 			counter = counter + 1;
 			stop = 0;
 			end	
  			else if(counter == 4'd10) begin
 			data_A_reg = 12'd40;
 			counter = 4'd0;
 			stop = 0;
 			end
        	end	
		else begin
		data_A_reg = data_A_reg;
		stop = 1;
		d = d+1;
			if(counter == 4'd0 && stop== 1 && d== 0) begin
			next_state = S1;
			end
		end
    end
end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
always @(posedge axis_clk) begin
	if(!axis_rst_n) begin
	curr_state = 0;
	end
	else begin
	curr_state = next_state;
	end
end
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////data_Di_reg
	always @* begin
	if(!axis_rst_n) begin
	ss_tready_reg = 0 ;
	length_counter = 0;
	end
	else if(ss_tvalid && ap_start && curr_state == 2'b01)begin
		if(counter == 4'd0 && stop == 0) begin
		ss_tready_reg = 1;
		length_counter = length_counter + 1;
		end
        	else begin
        	ss_tready_reg = 0;
        	end
       end
       else begin
       ss_tready_reg = 0;
       end
end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	always @* begin
	if(!axis_rst_n) begin
		data_Di_reg = 0;
	end
	else if(ss_tvalid && ap_start && curr_state == 2'b00)begin                               ///curr_state = 0
   		data_Di_reg = 0;
       end
	else if(ss_tvalid && ap_start && curr_state == 2'b01)begin				///cuur_state = 1
		data_Di_reg = 0;
       end
	else if(ss_tvalid && ap_start && 2'b10)begin  				///cuur_state = 2
		if(counter == 4'd1) begin
			data_Di_reg = ss_tdata;
		end
		else if(counter == 4'd2 && stop == 0 && data_WE_reg == 4'b0000) begin
			data_Di_reg = write_temp;
		end
		else if(counter == 4'd3 && stop == 0 && data_WE_reg == 4'b0000) begin
			data_Di_reg = write_temp;
		end
		else if(counter == 4'd4 && stop == 0 && data_WE_reg == 4'b0000) begin
			data_Di_reg = write_temp;
		end
		else if(counter == 4'd5 && stop == 0 && data_WE_reg == 4'b0000) begin
			data_Di_reg = write_temp;
		end
		else if(counter == 4'd6 && stop == 0 && data_WE_reg == 4'b0000) begin
			data_Di_reg = write_temp;
		end
		else if(counter == 4'd7 && stop == 0 && data_WE_reg == 4'b0000) begin
			data_Di_reg = write_temp;
		end
		else if(counter == 4'd8 && stop == 0 && data_WE_reg == 4'b0000) begin
			data_Di_reg = write_temp;
		end
		else if(counter == 4'd9 && stop == 0 && data_WE_reg == 4'b0000) begin
			data_Di_reg = write_temp;
		end
		else if(counter == 4'd10 && stop == 0 && data_WE_reg == 4'b0000) begin
			data_Di_reg = write_temp;
		end
		else if(counter == 4'd0 && stop == 0 && data_WE_reg == 4'b0000) begin
			data_Di_reg = write_temp;
		end
       end       
       
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////temp
	always @* begin
	if(!axis_rst_n) begin
		read_temp = 0;
		write_temp = 0;
	end
	else if(ss_tvalid && ap_start && curr_state == 2'b00)begin ////////////////state ==00
		read_temp = 0;
		write_temp = 0;
    	end	
	else if(ss_tvalid && ap_start && curr_state == 2'b01 && stop == 0 && d == 0)begin   ///////////////////state == 01   only read
    	end	
 	else if(ss_tvalid && ap_start && curr_state == 2'b10)begin	/////////////state == 10
		if(data_WE_reg == 4'b1111) begin
		read_temp = data_Do;
		end
		else begin
		write_temp = read_temp;
		end
    	end	   	
end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////data_ram 's  EN and WE
	always @* begin
	if(!axis_rst_n) begin
	data_EN_reg = 0;
	data_WE_reg = 4'b0000;
	end
	else if(ss_tvalid && ap_start && curr_state == 2'b00) begin
	data_EN_reg = 1;
	data_WE_reg = 4'b1111;
	end
	else if(ss_tvalid && ap_start && curr_state == 2'b10) begin
		if(d && stop) begin
		data_EN_reg = 1;
		data_WE_reg = 4'b1111;
		end
		else begin
		data_EN_reg = 1;
		data_WE_reg = 4'b0000;
		end
	end
	else if(ss_tvalid && ap_start && curr_state == 2'b01) begin
	data_EN_reg = 1;
	data_WE_reg = 4'b0000;
	end	
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////check idle = 0

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	always @* begin
	if(!axis_rst_n)begin
	sm_tdata_reg = 32'd0;
	temp = 32'd0;
	end
	else if(curr_state == 2'b01 && stop == 1)begin
	temp = tap_Do * data_Do;
	sm_tdata_reg = value + temp;
	end
	else if(curr_state == 2'b10) begin
	sm_tdata_reg = 0;
	end
	else begin
	sm_tdata_reg = value;
	end
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	always @(posedge axis_clk) begin
	value <= sm_tdata_reg;
end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	always @(negedge axis_clk) begin
	if(!axis_rst_n) begin
	sm_tvalid_reg <= 0;
	skip = 0;
	end
	else if(curr_state == 2'b10 && counter == 4'b0000 && stop == 1 && d == 0 && skip == 0) begin
	sm_tvalid_reg <= 0;
	skip <= 1;
	end
	else if(curr_state == 2'b01 && counter == 4'b1010 && stop == 1 && d == 0 && skip == 1) begin
	sm_tvalid_reg <= 1;
	end
	else begin
	sm_tvalid_reg <= 0;
	end
end
////////////////////////////////////////////////////////////////////////////////////////////
	always @* begin
	if(!axis_rst_n) begin
	sm_tlast_reg = 0;
	end
	else if(length_counter == 600)begin
	sm_tlast_reg = 1;
	end	
end
///////////////////////////////////////////////////////////////

endmodule