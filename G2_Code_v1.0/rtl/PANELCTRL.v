module PANELCTRL(iRESET,iOSC,
				iBUTTON_0,iBUTTON_1,iBUTTON_2,
				iSW0,iSW1,iSW2,iSW3,
				oDCLK,oFIN_PLL,oFBIN_PLL,
				oVSYNC,oHSYNC,oDE,
				oRDATA_86,oGDATA_86,oBDATA_86,
				oTEST0,oTEST1,oTEST2,oTEST3,oTEST4,oTEST5,oTEST6,oTEST7,oTEST8,oTEST9,oSTB);

	input	 							iRESET;
	input								iOSC;
	input								iBUTTON_0;
	input								iBUTTON_1;
	input								iBUTTON_2;

	input								iSW0,iSW1,iSW2,iSW3;

	output								oDCLK;
	output								oFIN_PLL;
	output								oFBIN_PLL;
	output 								oTEST0;		// SCL_A
	output 								oTEST1;
	output 								oTEST2;		// SCL_B
	output 								oTEST3;
	output 								oTEST4;
	
	output 								oTEST5;
	output 								oTEST6;
	output 								oTEST7;
	output 								oTEST8;
	output 								oTEST9;
	output 								oSTB;

	output reg							oVSYNC;
	output reg							oHSYNC;
	output reg							oDE;
	reg[7:0]						oRDATA;
	reg[7:0]						oGDATA;
	reg[7:0]						oBDATA;
	
	output [7:0]						oRDATA_86;
	output [7:0]						oGDATA_86;
	output [7:0]						oBDATA_86;

	wire								wVSYNC;
	wire								wHSYNC;
	wire								wDE;
	wire								wDE_STATE;
	wire								wGRAY_FLICKER_EN;

	wire[21:0]							wX_COORD;
	wire[21:0]							wY_COORD;

	wire[7:0]							wPAT_RDATA;
	wire[7:0]							wPAT_GDATA;
	wire[7:0]							wPAT_BDATA;
	wire[7:0]							wGRAY_RDATA;
	wire[7:0]							wGRAY_GDATA;
	wire[7:0]							wGRAY_BDATA;
	wire[7:0]							wIS_RDATA;
	wire[7:0]							wIS_GDATA;
	wire[7:0]							wIS_BDATA;

	wire[7:0]							wBTN0_CNT;
	wire[7:0]							wBTN1_CNT;
	wire[7:0]							wBTN2_CNT;

	wire[3:0]							wDIPSW_STATE;

	wire[7:0]							wONEsec_COUNTS;
	wire								wAUTO_PAT_EN;
	wire[1:0]							wFRAME_RATE;
	
	wire									UDLR;
	wire									OSC_25;
	reg									OSC12MHz;
	
	assign wDIPSW_STATE = {iSW3,iSW2,iSW1,iSW0};
	assign oTEST0 = (iSW2==0) ? 1'b1 :  1'b0;		// U/D, no function, UDLR replace
	assign oTEST1 = (iSW3==1) ? 1'b1 :  1'b0;		// L/R, no function, UDLR replace 
																	
																	
 
 
	assign oTEST2 = 1'b1;
	assign oTEST3 = 1'bz;
	
	assign oTEST4 = (UDLR==1'b1)? 1'bz : 1'bz; //control UDLR use one pin
 
	assign oTEST5 = 1'bz;
	assign oTEST6 = 1'bz;
	assign oTEST7 = 1'bz;
	assign oTEST8 = 1'bz;
	assign oTEST9 = 1'bz;
	assign oSTB = 1'b1;

	assign wAUTO_PAT_EN = (wDIPSW_STATE[0] == 1) ? 1'b1 : 1'b0;
	//assign wGRAY_FLICKER_EN = (wDIPSW_STATE == 4'b1000) ? 1'b1 : 1'b0;
	assign wGRAY_FLICKER_EN = 0;

	wire  iCLK_PLL; 
	reg	  CLK_8MHz, CLK_7MHz, clk_out;
	wire  iCLK_PLL16, iCLK_PLL14;

	`ifdef BIT8
		assign oRDATA_86 = oRDATA;
		assign oGDATA_86 = oGDATA;
		assign oBDATA_86 = oBDATA;
	`elsif BIT6
		assign oRDATA_86 = {2'b00,oRDATA[7:2]};
		assign oGDATA_86 = {2'b00,oGDATA[7:2]};
		assign oBDATA_86 = {2'b00,oBDATA[7:2]};
	`endif
	
	
	//--------------------------------------------
	// PLL Control Module
	//--------------------------------------------

	DCM   	uDCM(.RESET(~iRESET),.CLK_IN1(iOSC),.CLK_OUT1(iCLK_PLL16),.CLK_OUT2(iCLK_PLL14),.CLK_OUT3(OSC_25));			   
	always@(posedge OSC_25 or negedge iRESET)
	begin
		if(!iRESET)
					OSC12MHz<=1'b0;
		else
					OSC12MHz<=~OSC12MHz; //12.5MHz
	end	
	
	always@(posedge iCLK_PLL16 or negedge iRESET)
		begin
			if(!iRESET)
				CLK_8MHz<=1'b0;
			else
				CLK_8MHz<=~CLK_8MHz;
		end	
	always@(posedge iCLK_PLL14 or negedge iRESET)
		begin
			if(!iRESET)
				CLK_7MHz<=1'b0;
			else
				CLK_7MHz<=~CLK_7MHz;
		end	
	

	
	always@(wFRAME_RATE)
		begin
			case(wFRAME_RATE)
				2'd0:
					clk_out <= CLK_8MHz;	//DCLK = for 60Hz
				2'd1:
					clk_out <= CLK_7MHz;	//DCLK = for 50Hz
				default:
					clk_out <= CLK_8MHz;	//DCLK = for 60Hz
			endcase
		end
	
	//assign oDCLK = ~clk_out;
	assign oDCLK = (wDIPSW_STATE[3] == 1'b1) ? clk_out : ~clk_out; 
	assign iCLK_PLL = clk_out;
	//assign iCLK_PLL = CLK_12MHz;
	//--------------------------------------------
	// TIMING Control Module
	//--------------------------------------------
	TIMING	uTIMING(.irst(iRESET),.iclk(iCLK_PLL),.ovsync(wVSYNC),.ohsync(wHSYNC),
					.ode(wDE),.ox_coord(wX_COORD),.oy_coord(wY_COORD),
					.ode_state(wDE_STATE));

	//--------------------------------------------
	// Button Module
	//--------------------------------------------
	BUTTON	uBUTTON(.irst(iRESET),.iclk(iCLK_PLL),.ivsync(wVSYNC),.ibtn_0(iBUTTON_0),
					.ibtn_1(iBUTTON_1),.ibtn_2(iBUTTON_2),.obtn0_index(wBTN0_CNT),
					.obtn1_index(wBTN1_CNT),.obtn2_index(wBTN2_CNT));
	//--------------------------------------------
	// Pattern selection
	//--------------------------------------------
	PATTERNSEL	uPATTERNSEL(.iOSC(OSC12MHz),.iclk(iCLK_PLL),.irst(iRESET),.mode(wDIPSW_STATE[2:1]),.ide_state(wDE_STATE),
							.ipat_num(wBTN0_CNT),.inv_pat_num(wBTN1_CNT),
							.ix_coord(wX_COORD),.iy_coord(wY_COORD),.ivs(wVSYNC),
							.iauto_run(wAUTO_PAT_EN),.iauto_count(wONEsec_COUNTS),
							.ordata(wPAT_RDATA),.ogdata(wPAT_GDATA),.obdata(wPAT_BDATA),.oframe_rate(wFRAME_RATE),.oUD_RL(UDLR));

	
	//--------------------------------------------
	
	//--------------------------------------------
	// counter tick
	//--------------------------------------------
	COUNTER	uCOUNTER(.irst(iRESET),.iclk(iCLK_PLL),.ivsync(wVSYNC),.oCount_1s(wONEsec_COUNTS));

	//--------------------------------------------
	
	
	//--------------------------------------------
	//	Output signal:
	//	VSYNC
	//	HSYNC
	//	DE
	//	RDATA[7:0]
	//	GDATA[7:0]
	//	BDATA[7:0]
	//--------------------------------------------
	always@(negedge iCLK_PLL or negedge iRESET)
		begin
			if(!iRESET)
				begin
					oRDATA <= 8'd0;
					oGDATA <= 8'd0;
					oBDATA <= 8'd0;
					oVSYNC <= 1'b0;
					oHSYNC <= 1'b0;
					oDE <= 1'b0;
				end
			else
				begin
					case(wDIPSW_STATE)
						4'b0000:	// default
							begin
								oRDATA <= wPAT_RDATA;
								oGDATA <= wPAT_GDATA;
								oBDATA <= wPAT_BDATA;
								oVSYNC <= wVSYNC;
								oHSYNC <= wHSYNC;
								oDE <= wDE;
							end
						4'b0001:	// AUTO PATTERN
							begin
								oRDATA <= wPAT_RDATA;
								oGDATA <= wPAT_GDATA;
								oBDATA <= wPAT_BDATA;
								oVSYNC <= wVSYNC;
								oHSYNC <= wHSYNC;
								oDE <= wDE;
							end
					
						default:
							begin
								
								
								oRDATA <= wPAT_RDATA;
								oGDATA <= wPAT_GDATA;
								oBDATA <= wPAT_BDATA;
								oVSYNC <= wVSYNC;
								oHSYNC <= wHSYNC;
								oDE <= wDE;
							end
							
					endcase
				end
		end
endmodule
