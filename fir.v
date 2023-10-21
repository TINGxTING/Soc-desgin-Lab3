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
)                                                      //³q±`¥DŸ÷³£¬Oµo°_ÅªŒgœÐšDªº€@€è,ŠÓ±qŸ÷¬OÀxŠs©Êœè
(
///////////////////axi-lite////////////////////
    output  reg                     awready,        //ªí©úslave¥i¥H±µŠ¬address¡AŠ¹®É¥Ñslave²£¥ÍŠ¹°Tž¹µ¹master
    output  reg                     wready,        //slave¥i¥H±µŠ¬write data®É¡Aslave²£¥ÍŠ¹°Tž¹µ¹master
    input   wire                     awvalid,        //·í¥i¥HŒg€Jaddress®É¡Amaster²£¥ÍŠ¹°Tž¹µ¹slave
    input   wire [(pADDR_WIDTH-1):0] awaddr,         //Œg€Jªºaddress¡A³q±`¬O32bit ,¥Ñmaster¶Çµ¹slave
    input   wire                     wvalid,          //·ímasterªºwrite dataŠ³®Ä®É¡Amasterµo¥XŠ¹°Tž¹µ¹slave
    input   wire [(pDATA_WIDTH-1):0] wdata,           //Œg€Jªºžê®Æ¡A¥u¥i32bit   
    output  reg                     arready,        //·Ç³ÆÅªšúaddress¡A·íslave¥i¥H±µšüslave¶ÇšÓªºaddress©M±±šî°Tž¹®Éµo¥XŠ¹°Tž¹
    input   wire                     rready,        //·ímaster¥i¥H±µŠ¬read data®É²£¥ÍŠ¹°Tž¹
    input   wire                     arvalid,        //·íread address·Ç³ÆŠn®É¡Amaster¶Ç»ŒŠ¹°Tž¹µ¹slave
    input   wire [(pADDR_WIDTH-1):0] araddr,          //Åªšúªºaddress¡A³q±`32bit
    output  reg                     rvalid,            //·íread data is valid®Éslave²£¥ÍŠ¹°Tž¹µ¹master
    output  reg [(pDATA_WIDTH-1):0] rdata,              //Åªšúªºžê®Æ    ¥u¥i¥H¬O32bit
    ///////////////////stream///////////////////////////
    input   wire                     ss_tvalid,           //T¶}ÀY¬O¶Ç¿éŒÆŸÚÃþ¡A·í¥DŸ÷·Ç³ÆŠn¥i¥H¶Ç»Œžê®Æ®É¡Aµo¥XŠ¹Š³®Ä°Tž¹
    input   wire [(pDATA_WIDTH-1):0] ss_tdata,             //¥DŸ÷µo¥XªºŒÆŸÚ¡AŒÆŸÚŒe«×¬°BYTEªºŸãŒÆ­¿ 8,16,32 .....
    input   wire                     ss_tlast,             //¥DŸ÷µo¥XªºŒÆŸÚ¡Aªí©ú³æ«eŒÆŸÚ¬°žÓŒÆŸÚ(packet)ªº³Ì«á€@­ÓŒÆŸÚ      ·F¹Àªº????????????
    output  reg                     ss_tready,             //ªí©ú±qŸ÷(slave)·Ç³ÆŠn±µŠ¬ŒÆŸÚªº°Tž¹
    input   wire                     sm_tready, 
    output  reg                     sm_tvalid, 
    output  reg [(pDATA_WIDTH-1):0] sm_tdata,             //ŠP€W¡AŠýsm¬O¿é¥X  ss¬O¿é€J
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

    input   wire                     axis_clk,                  //¥þ°ì®ÉÄÁ°Tž¹
    input   wire                     axis_rst_n                   //¥þ°ìŽ_Šì°Tž¹
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
  ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////EN WE°Tž¹
    always @* begin
    if(!axis_rst_n) begin
        tap_EN = 0; 
        tap_WE = 4'b0000;
        data_length = 0;
    end
    else if (arvalid && rvalid) begin
        case(araddr)                 ///ÅªŠa§}    
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
            case(awaddr)                 ///ŒgŠa§} 
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
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    Œg
 
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

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////     streamžê®ÆŒg€J
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
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// data_inŒg€Jdata_ram
always @(posedge axis_clk) begin
	if(!axis_rst_n) begin
	data_A = 12'd0;
	stop = 1;
	d = 0;
	//start=1;
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
	sm_tdata = 32'd0;
	temp = 32'd0;
	end
	else if(curr_state == 2'b01 && stop == 1)begin
	temp = tap_Do * data_Do;
	sm_tdata = value + temp;
	end
	else if(curr_state == 2'b10) begin
	sm_tdata = 0;
	end
	else begin
	sm_tdata = value;
	end
end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	always @(posedge axis_clk) begin
	value <= sm_tdata;
end
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	always @(negedge axis_clk) begin
	if(!axis_rst_n) begin
	sm_tvalid <= 0;
	skip = 0;
	end
	else if(curr_state == 2'b10 && counter == 4'b0000 && stop == 1 && d == 0 && skip == 0) begin
	sm_tvalid <= 0;
	skip <= 1;
	end
	else if(curr_state == 2'b01 && counter == 4'b1010 && stop == 1 && d == 0 && skip == 1) begin
	sm_tvalid <= 1;
	end
	else begin
	sm_tvalid <= 0;
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