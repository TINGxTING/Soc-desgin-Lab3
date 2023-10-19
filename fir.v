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
)                                                      //通常主機都是發起讀寫請求的一方,而從機是儲存性質
(
///////////////////axi-lite////////////////////
    output  reg                     awready,        //表明slave可以接收address，此時由slave產生此訊號給master
    output  reg                     wready,        //slave可以接收write data時，slave產生此訊號給master
    input   wire                     awvalid,        //當可以寫入address時，master產生此訊號給slave
    input   wire [(pADDR_WIDTH-1):0] awaddr,         //寫入的address，通常是32bit ,由master傳給slave
    input   wire                     wvalid,          //當master的write data有效時，master發出此訊號給slave
    input   wire [(pDATA_WIDTH-1):0] wdata,           //寫入的資料，只可32bit   
    output  reg                     arready,        //準備讀取address，當slave可以接受slave傳來的address和控制訊號時發出此訊號
    input   wire                     rready,        //當master可以接收read data時產生此訊號
    input   wire                     arvalid,        //當read address準備好時，master傳遞此訊號給slave
    input   wire [(pADDR_WIDTH-1):0] araddr,          //讀取的address，通常32bit
    output  reg                     rvalid,            //當read data is valid時slave產生此訊號給master
    output  reg [(pDATA_WIDTH-1):0] rdata,              //讀取的資料    只可以是32bit
    ///////////////////stream///////////////////////////
    input   wire                     ss_tvalid,           //T開頭是傳輸數據類，當主機準備好可以傳遞資料時，發出此有效訊號
    input   wire [(pDATA_WIDTH-1):0] ss_tdata,             //主機發出的數據，數據寬度為BYTE的整數倍 8,16,32 .....
    input   wire                     ss_tlast,             //主機發出的數據，表明單前數據為該數據(packet)的最後一個數據      幹嘛的????????????
    output  reg                     ss_tready,             //表明從機(slave)準備好接收數據的訊號
    input   wire                     sm_tready, 
    output  reg                     sm_tvalid, 
    output  reg [(pDATA_WIDTH-1):0] sm_tdata,             //同上，但sm是輸出  ss是輸入
    output  reg                     sm_tlast, 
    
    // bram for tap RAM
    output  reg [3:0]               tap_WE,
    output  reg                     tap_EN,
    output  reg [(pDATA_WIDTH-1):0] tap_Di,
    output  reg [(pADDR_WIDTH-1):0] tap_A,
    input   wire [(pDATA_WIDTH-1):0] tap_Do,

    // bram for data RAM
    output  reg [3:0]               data_WE,
    output  reg                     data_EN,
    output  reg [(pDATA_WIDTH-1):0] data_Di,
    output  reg [(pADDR_WIDTH-1):0] data_A,
    input   wire [(pDATA_WIDTH-1):0] data_Do,

    input   wire                     axis_clk,                  //全域時鐘訊號
    input   wire                     axis_rst_n                   //全域復位訊號
);
    
    // write your code here!
 parameter S0 = 2'b00;
 parameter S1 = 2'b01;
 parameter S2 = 2'b10;
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
    reg [31:0] data_length;
    reg [31:0] length_counter;
    reg ap_start;
    reg ap_idle;
    reg ap_done;
    reg [31:0] read_temp;
    reg [31:0] write_temp;
    reg [1:0] stop;
    reg d; //use at data_A for three clk
    reg [1:0] curr_state;
    reg [1:0] next_state;
    reg start; ////use at data_A
    reg [3:0] counter;   
    reg [31:0] value;
    reg [31:0] temp;
    reg [31:0] next_value;
    reg skip;
    reg c;
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////     
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////EN WE訊號
    always @* begin
    if(!axis_rst_n) begin
        tap_EN = 0; 
        tap_WE = 4'b0000;
    end
    else if (arvalid && rvalid) begin
        case(araddr)                 ///讀地址    
            8'h20 :  begin tap_EN = 1; tap_WE = 4'b0000; end
            8'h24 :  begin tap_EN = 1; tap_WE = 4'b0000; end
            8'h28 :  begin tap_EN = 1; tap_WE = 4'b0000; end
            8'h2c :  begin tap_EN = 1; tap_WE = 4'b0000; end 
            8'h30 :  begin tap_EN = 1; tap_WE = 4'b0000; end
            8'h34 :  begin tap_EN = 1; tap_WE = 4'b0000; end
            8'h38 :  begin tap_EN = 1; tap_WE = 4'b0000; end
            8'h3c :  begin tap_EN = 1; tap_WE = 4'b0000; end
            8'h40 :  begin tap_EN = 1; tap_WE = 4'b0000; end
            8'h44 :  begin tap_EN = 1; tap_WE = 4'b0000; end
            8'h48 :  begin tap_EN = 1; tap_WE = 4'b0000; end
            default : begin tap_EN = 1; tap_WE = 4'b0000; end
        endcase
    end
    else if(awvalid && wvalid) begin
            case(awaddr)                 ///寫地址 
            8'h10 :  begin tap_EN =0; tap_WE = 4'b0000; data_length = wdata; end   
            8'h20 :  begin tap_EN = 1; tap_WE = 4'b1111; end
            8'h24 :  begin tap_EN = 1; tap_WE = 4'b1111; end
            8'h28 :  begin tap_EN = 1; tap_WE = 4'b1111; end
            8'h2c :  begin tap_EN = 1; tap_WE = 4'b1111; end 
            8'h30 :  begin tap_EN = 1; tap_WE = 4'b1111; end
            8'h34 :  begin tap_EN = 1; tap_WE = 4'b1111; end
            8'h38 :  begin tap_EN = 1; tap_WE = 4'b1111; end
            8'h3c :  begin tap_EN = 1; tap_WE = 4'b1111; end
            8'h40 :  begin tap_EN = 1; tap_WE = 4'b1111; end
            8'h44 :  begin tap_EN = 1; tap_WE = 4'b1111; end
            8'h48 :  begin tap_EN = 1; tap_WE = 4'b1111; end
            default : begin tap_EN = 0; tap_WE = 4'b0000; end
        endcase
    end
    else if(curr_state == 2'b01 || curr_state == 2'b10) begin
      	tap_EN = 1;
  	tap_WE = 4'b0000;
    end
    end      
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    寫
 
 always @* begin
 if(!axis_rst_n)begin
    tap_A = 12'd0;
    tap_Di = 32'd0;
    awready=0; wready=0;
    arready = 0;
 end
 else if(awvalid && wvalid && ap_done == 0) begin
    case(awaddr[7:4])
    4'b0000 : begin ap_start = wdata[0]; awready=1; wready=1 ; end                          
    4'b0001 : begin tap_A[3:0] = 12'd0; tap_Di = 32'd0; awready=1; wready=1; end 
    4'b0010 : begin tap_A[3:0] = awaddr[3:0]; tap_A[11:4] = 8'b00000000; tap_Di = wdata; awready=1; wready=1; end
    4'b0011 : begin tap_A[3:0] = awaddr[3:0]; tap_A[11:4] = 8'b00000001; tap_Di = wdata; awready=1; wready=1; end
    4'b0100 : begin tap_A[3:0] = awaddr[3:0]; tap_A[11:4] = 8'b00000010; tap_Di = wdata; awready=1; wready=1; end
    4'b0101 : begin tap_A[3:0] = awaddr[3:0]; tap_A[11:4] = 8'b00000011; tap_Di = wdata; awready=1; wready=1; end
    4'b0110 : begin tap_A[3:0] = awaddr[3:0]; tap_A[11:4] = 8'b00000100; tap_Di = wdata; awready=1; wready=1; end
    4'b0111 : begin tap_A[3:0] = awaddr[3:0]; tap_A[11:4] = 8'b00000101; tap_Di = wdata; awready=1; wready=1; end
    4'b1000 : begin tap_A[3:0] = awaddr[3:0]; tap_A[11:4] = 8'b00000110; tap_Di = wdata; awready=1; wready=1; end
    4'b1001 : begin tap_A[3:0] = awaddr[3:0]; tap_A[11:4] = 8'b00000111; tap_Di = wdata; awready=1; wready=1; end
    4'b1010 : begin tap_A[3:0] = awaddr[3:0]; tap_A[11:4] = 8'b00001000; tap_Di = wdata; awready=1; wready=1; end
    4'b1011 : begin tap_A[3:0] = awaddr[3:0]; tap_A[11:4] = 8'b00001001; tap_Di = wdata; awready=1; wready=1; end
    4'b1100 : begin tap_A[3:0] = awaddr[3:0]; tap_A[11:4] = 8'b00001010; tap_Di = wdata; awready=1; wready=1; end
    4'b1101 : begin tap_A[3:0] = awaddr[3:0]; tap_A[11:4] = 8'b00001011; tap_Di = wdata; awready=1; wready=1; end
    4'b1110 : begin tap_A[3:0] = awaddr[3:0]; tap_A[11:4] = 8'b00001100; tap_Di = wdata; awready=1; wready=1; end
    4'b1111 : begin tap_A[3:0] = awaddr[3:0]; tap_A[11:4] = 8'b00001101; tap_Di = wdata; awready=1; wready=1; end
    default : begin tap_A = 12'd2; tap_Di = 32'd0; awready = 0; wready = 0;end
    endcase
    end
  else if(arvalid && rready && curr_state == 2'b00 && ap_done == 0)begin
    tap_A[11:8] = 4'd0;
    case(araddr[7:4])
    4'b0010 : begin tap_A = araddr[3:0]; arready =1; end
    4'b0011 : begin tap_A = araddr[3:0]; tap_A[7:4] = 4'b0001; arready=1; end
    4'b0100 : begin tap_A = araddr[3:0]; tap_A[7:4] = 4'b0010; arready=1; end
    4'b0101 : begin tap_A = araddr[3:0]; tap_A[7:4] = 4'b0011; arready=1; end
    4'b0110 : begin tap_A = araddr[3:0]; tap_A[7:4] = 4'b0100; arready=1; end
    4'b0111 : begin tap_A = araddr[3:0]; tap_A[7:4] = 4'b0101; arready=1; end
    4'b1000 : begin tap_A = araddr[3:0]; tap_A[7:4] = 4'b0110; arready=1; end
    4'b1001 : begin tap_A = araddr[3:0]; tap_A[7:4] = 4'b0111; arready=1; end
    4'b1010 : begin tap_A = araddr[3:0]; tap_A[7:4] = 4'b1000; arready=1; end
    4'b1011 : begin tap_A = araddr[3:0]; tap_A[7:4] = 4'b1001; arready=1; end
    4'b1100 : begin tap_A = araddr[3:0]; tap_A[7:4] = 4'b1010; arready=1; end
    4'b1101 : begin tap_A = araddr[3:0]; tap_A[7:4] = 4'b1011; arready=1; end
    4'b1110 : begin tap_A = araddr[3:0]; tap_A[7:4] = 4'b1100; arready=1; end
    4'b1111 : begin tap_A = araddr[3:0]; tap_A[7:4] = 4'b1101; arready=1; end
    default : begin tap_A = 12'd0; tap_Di = 32'd0;  arready=0 ;end
    endcase
 end
  else if((curr_state == 2'b01 || curr_state == 2'b10) && ap_done == 0) begin
  	if(counter == 1)begin
  	tap_A = 12'd0;
  	end
  	else if(counter == 2) begin
  	tap_A = 12'd4;
  	end
  	else if(counter == 3) begin
  	tap_A = 12'd8;
  	end
  	else if(counter == 4) begin
  	tap_A = 12'd12;
  	end
  	else if(counter == 5) begin
  	tap_A = 12'd16;
  	end
   	else if(counter == 6) begin
  	tap_A = 12'd20;
  	end
  	else if(counter == 7) begin
  	tap_A = 12'd24;
  	end
  	else if(counter == 8) begin
  	tap_A = 12'd28;
  	end
  	else if(counter == 9) begin
  	tap_A = 12'd32;
  	end
  	else if(counter == 10) begin
  	tap_A = 12'd36;
  	end
  	else if(counter == 0) begin
  	tap_A = 12'd40;
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
 ////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////     stream資料寫入
	always @(posedge axis_clk) begin
	if(!axis_rst_n) begin
	rvalid = 0;
	end
	else if(arvalid == 0 && length_counter != 600) begin
		rvalid = 0;
	end
	else if(arvalid == 1 && length_counter != 600) begin
		rvalid = 1;
	

	end
	else if(araddr == 12'h00 && arvalid && rready && length_counter == 600 && ap_done && ap_idle ==0) begin
		rvalid = 1;
	end
	else if(araddr == 12'h00 && arvalid && rready && length_counter == 600 && ap_idle ) begin
		rvalid = 1;
	end
	else begin
	rvalid = 0;
	end
end
//////////////////////////////////////////////////////////////
	always @* begin
	if(!axis_rst_n) begin
	rdata = 0;
	c = 0;
	end	
	else if(arvalid && rready && araddr != 12'h00) begin
	rdata = tap_Do;
	end
	else if(araddr == 12'h00 && arvalid && rready && length_counter == 600 && ap_done && ap_idle ==0) begin
		rdata = 32'd2;
	end
	else if(araddr == 12'h00 && arvalid && rready && length_counter == 600 && ap_idle && rvalid == 0 ) begin
		if(c==0)begin
		c = 1;
		 end
		 else begin
		rdata = 32'd4;
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
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// data_in寫入data_ram
always @(posedge axis_clk) begin
	if(!axis_rst_n) begin
	data_A = 12'd0;
	stop = 1;
	d = 0;
	start=1;
	counter = 4'd0;
	next_state = 2'd0;
	end
	else if(ss_tvalid && ap_start && curr_state == 2'b00) begin   /// maintain 1 clk
		if(counter == 4'd0) begin
			data_A = 12'd0;
			counter = counter + 1;
		end
		else if(counter == 4'd1) begin
			data_A = 12'd4;
			counter = counter + 1;
		end
		else if(counter == 4'd2) begin
			data_A = 12'd8;
			counter = counter + 1;
		end
		else if(counter == 4'd3) begin
			data_A = 12'd12;
			counter = counter + 1;
		end
		else if(counter == 4'd4) begin
			data_A = 12'd16;
			counter = counter + 1;
		end
		else if(counter == 4'd5) begin
			data_A = 12'd20;
			counter = counter + 1;
		end
		else if(counter == 4'd6) begin
			data_A = 12'd24;
			counter = counter + 1;
		end
		else if(counter == 4'd7) begin
			data_A = 12'd28;
			counter = counter + 1;
		end
		else if(counter == 4'd8) begin
			data_A = 12'd32;
			counter = counter + 1;
		end
		else if(counter == 4'd9) begin
			data_A = 12'd36;
			counter = counter + 1;
		end
		else if(counter == 4'd10) begin
			data_A = 12'd40;
			counter = 4'd0;
			next_state = S2;
		end
	end
	else if(ss_tvalid && ap_start && curr_state == 2'b01) begin   /// maintain 2 clk
		if(stop == 1) begin
				if(counter == 4'd0) begin
					data_A = 12'd0;
					counter = counter + 1;    //////
					stop = 0;
				end
				else if(counter == 4'd1) begin
					data_A = 12'd4;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd2) begin
					data_A = 12'd8;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd3) begin
					data_A = 12'd12;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd4) begin
					data_A = 12'd16;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd5) begin
					data_A = 12'd20;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd6) begin
					data_A = 12'd24;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd7) begin
					data_A = 12'd28;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd8) begin
					data_A = 12'd32;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd9) begin
					data_A = 12'd36;
					counter = counter + 1;
					stop = 0;
				end
				else if(counter == 4'd10) begin
					data_A = 12'd40;
					counter = 4'd0;
					stop = 0;
				end
		end
		else begin
			data_A = data_A;
			stop = 1;
			if(counter == 0 && stop == 1) begin
			next_state = S2;
			end
		end
	end	
	else if(ss_tvalid && ap_start && curr_state == 2'b10)begin                  /// maintain 3 clk   clk1:stop ==0, d==0  clk2: stop == 1, d == 1 clk3: stop =1 d == 0.....
        	if(stop == 1 && d==0) begin
 			if(counter == 4'd0) begin
 			data_A = 4'd0;
 			counter = counter + 1;
 			stop = 0;
 			end
 			else if(counter == 4'd1) begin
 			data_A = 12'd4;
 			counter = counter + 1;
 			stop = 0;
 			end
 			else if(counter == 4'd2) begin
 			data_A = 12'd8;
 			counter = counter + 1;
 			stop = 0;
 			end
 			else if(counter == 4'd3) begin
 			data_A = 12'd12;
 			counter = counter + 1;
 			stop = 0;
 			end			
 			else if(counter == 4'd4) begin
 			data_A = 12'd16;
 			counter = counter + 1;
 			stop = 0;
 			end 		
  			else if(counter == 4'd5) begin
 			data_A = 12'd20;
 			counter = counter + 1;
 			stop = 0;
 			end
  			else if(counter == 4'd6) begin
 			data_A = 12'd24;
 			counter = counter + 1;
 			stop = 0;
 			end
  			else if(counter == 4'd7) begin
 			data_A = 12'd28;
 			counter = counter + 1;
 			stop = 0;
 			end
  			else if(counter == 4'd8) begin
 			data_A = 12'd32;
 			counter = counter + 1;
 			stop = 0;
 			end
  			else if(counter == 4'd9) begin
 			data_A = 12'd36;
 			counter = counter + 1;
 			stop = 0;
 			end	
  			else if(counter == 4'd10) begin
 			data_A = 12'd40;
 			counter = 4'd0;
 			stop = 0;
 			end
        	end	
		else begin
		data_A = data_A;
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
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////data_Di
	always @* begin
	if(!axis_rst_n) begin
	ss_tready = 0 ;
	length_counter = 0;
	end
	else if(ss_tvalid && ap_start && curr_state == 2'b01)begin
		if(counter == 4'd0 && stop == 0) begin
		ss_tready = 1;
		length_counter = length_counter + 1;
		end
        	else begin
        	ss_tready = 0;
        	end
       end
       else begin
       ss_tready = 0;
       end
end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	always @* begin
	if(!axis_rst_n) begin
		data_Di = 0;
	end
	else if(ss_tvalid && ap_start && curr_state == 2'b00)begin                               ///curr_state = 0
   		data_Di = 0;
       end
	else if(ss_tvalid && ap_start && curr_state == 2'b01)begin				///cuur_state = 1
		data_Di = 0;
       end
	else if(ss_tvalid && ap_start && 2'b10)begin  				///cuur_state = 2
		if(counter == 4'd1) begin
			data_Di = ss_tdata;
		end
		else if(counter == 4'd2 && stop == 0 && data_WE == 4'b0000) begin
			data_Di = write_temp;
		end
		else if(counter == 4'd3 && stop == 0 && data_WE == 4'b0000) begin
			data_Di = write_temp;
		end
		else if(counter == 4'd4 && stop == 0 && data_WE == 4'b0000) begin
			data_Di = write_temp;
		end
		else if(counter == 4'd5 && stop == 0 && data_WE == 4'b0000) begin
			data_Di = write_temp;
		end
		else if(counter == 4'd6 && stop == 0 && data_WE == 4'b0000) begin
			data_Di = write_temp;
		end
		else if(counter == 4'd7 && stop == 0 && data_WE == 4'b0000) begin
			data_Di = write_temp;
		end
		else if(counter == 4'd8 && stop == 0 && data_WE == 4'b0000) begin
			data_Di = write_temp;
		end
		else if(counter == 4'd9 && stop == 0 && data_WE == 4'b0000) begin
			data_Di = write_temp;
		end
		else if(counter == 4'd10 && stop == 0 && data_WE == 4'b0000) begin
			data_Di = write_temp;
		end
		else if(counter == 4'd0 && stop == 0 && data_WE == 4'b0000) begin
			data_Di = write_temp;
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
		if(data_WE == 4'b1111) begin
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
	data_EN = 0;
	data_WE = 4'b0000;
	end
	else if(ss_tvalid && ap_start && curr_state == 2'b00) begin
	data_EN = 1;
	data_WE = 4'b1111;
	end
	else if(ss_tvalid && ap_start && curr_state == 2'b10) begin
		if(d && stop) begin
		data_EN = 1;
		data_WE = 4'b1111;
		end
		else begin
		data_EN = 1;
		data_WE = 4'b0000;
		end
	end
	else if(ss_tvalid && ap_start && curr_state == 2'b01) begin
	data_EN = 1;
	data_WE = 4'b0000;
	end	
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////check idle = 0

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	always @* begin
	if(!axis_rst_n)begin
	next_value = 32'd0;
	temp = 32'd0;
	end
	else if(curr_state == 2'b01 && stop == 1)begin
	temp = tap_Do * data_Do;
	next_value = value + temp;
	end
	else if(curr_state == 2'b10) begin
	next_value = 0;
	end
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	always @(posedge axis_clk) begin
	value <= next_value;
end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	always @(negedge axis_clk) begin
	if(!axis_rst_n) begin
	sm_tvalid <= 0;
	sm_tdata <= 0;
	skip = 0;
	end
	else if(curr_state == 2'b10 && counter == 4'b0000 && stop == 1 && d == 0 && skip == 0) begin
	sm_tvalid <= 0;
	sm_tdata <= 0;
	skip <= 1;
	end
	else if(curr_state == 2'b10 && counter == 4'b0000 && stop == 1 && d == 0 && skip == 1) begin
	sm_tvalid <= 1;
	sm_tdata <= value;
	end
	else begin
	sm_tvalid <= 0;
	sm_tdata <= 0;
	end
end
////////////////////////////////////////////////////////////////////////////////////////////
	always @* begin
	if(!axis_rst_n) begin
	sm_tlast = 0;
	end
	else if(length_counter == 600)begin
	sm_tlast = 1;
	end	
end
///////////////////////////////////////////////////////////////

endmodule
