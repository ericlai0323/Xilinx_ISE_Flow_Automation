`include "TIMING_SETTING.V"
////////////////////////////////////////
module PATTERNSEL(iOSC,iclk,mode,irst,ide_state,ipat_num,inv_pat_num,ix_coord,iy_coord,ivs,
					iauto_run,iauto_count,ordata,ogdata,obdata,oframe_rate,oUD_RL);
	
	input					iOSC;
	input					iclk;
	input					irst;
	input					ivs;
	input					ide_state;
	input[7:0]				ipat_num;
	input[7:0]				inv_pat_num;
	input[21:0]				ix_coord;
	input[21:0]				iy_coord;
	input					iauto_run;
	input[7:0]				iauto_count;

	//output reg[5:0]			ordata;
	//output reg[5:0]			ogdata;
	//output reg[5:0]			obdata;
	output reg[7:0]			ordata;
	output reg[7:0]			ogdata;
	output reg[7:0]			obdata;
	output reg[1:0]			oframe_rate;
	
	output reg				oUD_RL;

	reg[7:0]				h_pattern_reg;
	reg[7:0]				pattern_count;
	reg[7:0]				last_pat_num;
	reg[7:0]				last_inv_pat_num;
	reg[7:0]				last_auto_count;
	reg[8:0]				response_count;
	reg						response_flag;

	wire[7:0]				wCondition_RGB_VGRAY;  // yycheng 20230214
	wire[7:0]				wCondition_RGB_HGRAY;  // yycheng 20230214	
	wire[7:0]				wCondition_RGB_VGRAY_INV;  // yycheng 20230214


	wire					wCHESS_X;
	wire					wCHESS_Y;
	wire					wCondition_CHESS;
	wire					wBORDER_Condition1;
	wire					wBORDER_Condition2;
	wire					wCondition_BORDER;
	wire					wWINDOW_Condition1;
	wire					wWINDOW_Condition2;
	wire					wCondition_WINDOW;
	wire					wCondition_CROSSTALK1;
	wire					wCondition_CROSSTALK2;
	wire					wCondition_VBW;
	wire					wCondition_HBW;
	wire[7:0]				wCondition_FLICKER;
	wire					wFLICKER_X;
	wire[7:0]				wCondition_VGRAY;
	wire[7:0]				wCondition_HGRAY;
	wire[3:0]				wFONTH_INDEX_X;
	wire[3:0]				wFONTH_INDEX_Y;
	reg[1:0]				vsync_sr;
	wire					vs_rising;
	wire					wPressure_ConditionX;
	wire					wPressure_ConditionY;
	wire					wTP_ConditionP1;
	wire					wTP_ConditionP2;
	wire					wTP_ConditionP3;
	wire					wTP_ConditionP4;
	wire					wTP_ConditionP5;
	
	reg[7:0]					LOCK_T0,LOCK_T1,LOCK_T2,LOCK_T3,LOCK_T4,LOCK_T5,LOCK_T6,LOCK_T7,LOCK_T8,LOCK_T9;
	reg[7:0]					LOCK_T10,LOCK_T11,LOCK_T12,LOCK_T13,LOCK_T14,LOCK_T15,LOCK_T16,LOCK_T17,LOCK_T18,LOCK_T19;
	reg[7:0]					LOCK_T20,LOCK_T21,LOCK_T22,LOCK_T23,LOCK_T24,LOCK_T25,LOCK_T26,LOCK_T27,LOCK_T28,LOCK_T29;

	reg[7:0]					LOCK_TIME;
	reg[7:0]					LOCK_COUNT;

	reg							LOCK_RST;
	reg[24:0]					div_count;
	reg							CLK_1HZ;
	reg							CLK_2HZ;
	reg[7:0]               wpattern_count; //zman add
	input[1:0]					mode;
	reg[7:0]          gray_level_count; //zman add

	reg[7:0]				Num_X2;
	reg[7:0]				Num_Y2;
	reg[7:0]				Num_X1;
	reg[7:0]				Num_Y1;
	reg[7:0]				Num_X;
	reg[7:0]				Num_Y;
	reg[9:0]				Num_Condition2;
	reg[9:0]				Num_Condition1;
	reg[9:0]				Num_Condition;


/*********************************************************************************/	
	reg[8:0]				response_05_count;
	reg[8:0]				response_10_count;	
	reg					response_05_flag;
	reg					response_10_flag;
	
	// add 1+2 dot inversion
	reg 				x_flicker_hsd_0;
	reg 				x_flicker_hsd_1;
	reg 				x_flicker_hsd_2;
	reg 				x_flicker_hsd_3;
	reg[7:0]  			y_flicker_hsd;



	assign wBORDER_Condition1 = (iy_coord == 0 || ix_coord == 0) ? 1'b1 : 1'b0;
	assign wBORDER_Condition2 = (iy_coord == (`V_PIXEL-1) || ix_coord == (`H_PIXEL-1)) ? 1'b1 : 1'b0;
	assign wCondition_BORDER = (wBORDER_Condition1 || wBORDER_Condition2) ? 1'b1 : 1'b0;

	assign wWINDOW_Condition1 = (iy_coord >= (`V_PIXEL/4) && iy_coord < (`V_PIXEL-(`V_PIXEL/4))) ? 1'b1 : 1'b0;
	assign wWINDOW_Condition2 = (ix_coord >= (`H_PIXEL/4) && ix_coord < (`H_PIXEL-(`H_PIXEL/4))) ? 1'b1 : 1'b0;
	assign wCondition_WINDOW = (wWINDOW_Condition1 && wWINDOW_Condition2) ? 1'b1 : 1'b0;

	assign wCHESS_X = (((ix_coord >= 0) && (ix_coord < (1*(`H_PIXEL/8)))) || ((ix_coord >= (2*(`H_PIXEL/8))) && (ix_coord < (3*(`H_PIXEL/8)))) || ((ix_coord >= (4*(`H_PIXEL/8))) && (ix_coord < (5*(`H_PIXEL/8)))) || ((ix_coord >= (6*(`H_PIXEL/8))) && (ix_coord < (7*(`H_PIXEL/8)))) || ((ix_coord >= (8*(`H_PIXEL/8))) && (ix_coord < (9*(`H_PIXEL/8))))) ? 1'b1 : 1'b0;
	assign wCHESS_Y = (((iy_coord >= 0) && (iy_coord < (1*(`V_PIXEL/6)))) || ((iy_coord >= (2*(`V_PIXEL/6))) && (iy_coord < (3*(`V_PIXEL/6)))) || ((iy_coord >= (4*(`V_PIXEL/6))) && (iy_coord < (5*(`V_PIXEL/6)))) || ((iy_coord >= (6*(`V_PIXEL/6))) && (iy_coord < (7*(`V_PIXEL/6)))) || ((iy_coord >= (8*(`V_PIXEL/6))) && (iy_coord < (9*(`V_PIXEL/6))))) ? 1'b1 : 1'b0;
	
	assign wCondition_RGB_VGRAY = ((ix_coord <<8) / `H_PIXEL);					// 64/400 ~= 0.16   // 256/400~=0.64  // yycheng 20230214
	assign wCondition_RGB_HGRAY = ((iy_coord <<8) / `V_PIXEL);					// 64/240 ~= 0.27		// 256/240~=1.06  //yycheng 20230214


	
	assign wCondition_CHESS = (wCHESS_X ^ wCHESS_Y);

	assign wCondition_VBW = ((ix_coord % 2) == 0) ? 1'b1 : 1'b0;
	
	
	
	assign wCondition_HBW = ((iy_coord % 2) == 0) ? 1'b1 : 1'b0;
	
	wire[3:0] wFLICKER_X_2D;
	assign wFLICKER_X_2D[3:0] = ix_coord % 4;
	wire wFLICKER_Y_2D;
	assign wFLICKER_Y_2D = iy_coord % 2;
	wire[3:0] wFLICKER_Y_2L;
	assign wFLICKER_Y_2L = iy_coord % 4;
	
	wire[7:0] wCondition_FLICKER_2L;
	assign wCondition_FLICKER_2L = ((iy_coord % 4) < 2) ? `LUMIN_FIFTY : 8'd0;
	
	wire[7:0] wCondition_FLICKER_2L1;
	assign wCondition_FLICKER_2L1 = ((iy_coord % 4) ==2'b01 || (iy_coord % 4) ==2'b10) ? `LUMIN_FIFTY : 8'd0;
	
	wire [7:0]wFLICKER_Y_3L;
	assign wFLICKER_Y_3L = ((iy_coord % 6) < 3) ? `LUMIN_FIFTY : 8'd0;;
	
	assign wCondition_FLICKER = ((iy_coord % 2) == 1) ? `LUMIN_FIFTY : 8'd0;	// 50% gray
	assign wFLICKER_X = ((ix_coord % 2) == 0) ? 1'b1 : 1'b0;
	//assign wCondition_VGRAY = ((ix_coord * 20) / 32);					// 64/400 ~= 0.16   // 256/400~=0.64
	//assign wCondition_HGRAY = ((iy_coord * 4) / 4);					// 64/240 ~= 0.27		// 256/240~=1.06
	//assign wCondition_VGRAY = ((ix_coord * 256) / `H_PIXEL);					// 64/400 ~= 0.16   // 256/400~=0.64
	//assign wCondition_HGRAY = ((iy_coord * 256) / `V_PIXEL);					// 64/240 ~= 0.27		// 256/240~=1.06
	assign wCondition_VGRAY = ((ix_coord <<8) / `H_PIXEL);					// 64/400 ~= 0.16   // 256/400~=0.64
	assign wCondition_HGRAY = ((iy_coord <<8) / `V_PIXEL);					// 64/240 ~= 0.27		// 256/240~=1.06
	assign wFONTH_INDEX_X = (ix_coord % 8);
	assign wFONTH_INDEX_Y = (iy_coord % 8);

	assign wCondition_CROSSTALK1 = ((ix_coord % 2) == 0) ? 1'b1 : 1'b0;
	assign wCondition_CROSSTALK2 = ((ix_coord % 2) == 1) ? 1'b1 : 1'b0;

	assign wPressure_ConditionX = (ix_coord == (`H_PIXEL/3) || ix_coord == (2*(`H_PIXEL/3))) ? 1'b1 : 1'b0;
	assign wPressure_ConditionY = (iy_coord == (`V_PIXEL/3) || iy_coord == (2*(`V_PIXEL/3))) ? 1'b1 : 1'b0;

	assign wTP_ConditionP1 = ((ix_coord >= 0 && ix_coord < 20) && (iy_coord >= 0 && iy_coord < 20)) ? 1'b1 : 1'b0;
	assign wTP_ConditionP2 = ((ix_coord >= (`H_PIXEL-20) && ix_coord < (`H_PIXEL)) && (iy_coord >= 0 && iy_coord < 20)) ? 1'b1 : 1'b0;
	assign wTP_ConditionP3 = ((ix_coord >= 0 && ix_coord < 20) && (iy_coord >= (`V_PIXEL-20) && iy_coord < (`V_PIXEL))) ? 1'b1 : 1'b0;
	assign wTP_ConditionP4 = ((ix_coord >= (`H_PIXEL-20) && ix_coord < (`H_PIXEL)) && (iy_coord >= (`V_PIXEL-20) && iy_coord < (`V_PIXEL))) ? 1'b1 : 1'b0;
	assign wTP_ConditionP5 = ((ix_coord >= (`H_PIXEL/2-10) && ix_coord < (`H_PIXEL/2+10)) && (iy_coord >= (`V_PIXEL/2-10) && iy_coord < (`V_PIXEL/2+10))) ? 1'b1 : 1'b0;

	
	always@(pattern_count or mode)
	begin
		case(mode)
		2'b10:wpattern_count<=`G_PAT;
		2'b01:wpattern_count<=`GRAY_PAT;
		default:wpattern_count<=pattern_count;
		endcase
	
	end
	
	always@(*)
	begin	
		// Number 10
		Num_X2 = 15;
	 	Num_Y2 = 15;
	 	Num_X1 = 23;
	 	Num_Y1 = 15;
	 	Num_X = 31;
	 	Num_Y = 15;
		
	 Num_Condition2[0] = ((ix_coord == Num_X2 || ix_coord == Num_X2+1 || ix_coord == Num_X2+4 || ix_coord == Num_X2+5 )&& iy_coord >= Num_Y2 && iy_coord < Num_Y2+10 ||
										ix_coord >= Num_X2 && ix_coord < Num_X2+6 && (iy_coord == Num_Y2 || iy_coord == Num_Y2+1 || iy_coord == Num_Y2+8 || iy_coord == Num_Y2+9)) ? 1'b1 : 1'b0;
	 Num_Condition2[1] = ((ix_coord == Num_X2+4 || ix_coord == Num_X2+5)&& iy_coord >= Num_Y2 && iy_coord < Num_Y2+10
										) ? 1'b1 : 1'b0;
	 Num_Condition2[2] = ((ix_coord == Num_X2 || ix_coord == Num_X2+1 )&& iy_coord >= Num_Y2+4 && iy_coord < Num_Y2+10 || (ix_coord == Num_X2+4 || ix_coord == Num_X2+5)&& iy_coord >= Num_Y2 && iy_coord < Num_Y2+6 ||
										ix_coord >= Num_X2 && ix_coord < Num_X2+6 && (iy_coord == Num_Y2 || iy_coord == Num_Y2+1 || iy_coord == Num_Y2+4 || iy_coord == Num_Y2+5 || iy_coord == Num_Y2+8 || iy_coord == Num_Y2+9)) ? 1'b1 : 1'b0;
	 Num_Condition2[3] = ((ix_coord == Num_X2+4 || ix_coord == Num_X2+5 )&& iy_coord >= Num_Y2 && iy_coord < Num_Y2+10 ||
										ix_coord >= Num_X2 && ix_coord < Num_X2+6 && (iy_coord == Num_Y2 || iy_coord == Num_Y2+1 || iy_coord == Num_Y2+4 || iy_coord == Num_Y2+5 || iy_coord == Num_Y2+8 || iy_coord == Num_Y2+9)) ? 1'b1 : 1'b0;
	 Num_Condition2[4] = ((ix_coord == Num_X2 ||ix_coord == Num_X2+1) && iy_coord >= Num_Y2 && iy_coord < Num_Y2+6 || (ix_coord == Num_X2+4 || ix_coord == Num_X2+5) && iy_coord >= Num_Y2 && iy_coord < Num_Y2+10 ||
										ix_coord >= Num_X2 && ix_coord < Num_X2+6 && (iy_coord == Num_Y2+4 || iy_coord == Num_Y2+5) ) ? 1'b1 : 1'b0;
	 Num_Condition2[5] = ((ix_coord == Num_X2 || ix_coord == Num_X2+1 )&& iy_coord >= Num_Y2 && iy_coord < Num_Y2+6 || (ix_coord == Num_X2+4 || ix_coord == Num_X2+5)&& iy_coord >= Num_Y2+4 && iy_coord < Num_Y2+10 ||
										ix_coord >= Num_X2 && ix_coord < Num_X2+6 && (iy_coord == Num_Y2 || iy_coord == Num_Y2+1 || iy_coord == Num_Y2+4 || iy_coord == Num_Y2+5 || iy_coord == Num_Y2+8 || iy_coord == Num_Y2+9)) ? 1'b1 : 1'b0;
	 Num_Condition2[6] = ((ix_coord == Num_X2 || ix_coord == Num_X2+1 )&& iy_coord >= Num_Y2 && iy_coord < Num_Y2+10 || (ix_coord == Num_X2+4 || ix_coord == Num_X2+5)&& iy_coord >= Num_Y2+4 && iy_coord < Num_Y2+10 ||
										ix_coord >= Num_X2 && ix_coord < Num_X2+6 && (iy_coord == Num_Y2 || iy_coord == Num_Y2+1 || iy_coord == Num_Y2+4 || iy_coord == Num_Y2+5 || iy_coord == Num_Y2+8 || iy_coord == Num_Y2+9)) ? 1'b1 : 1'b0;
	 Num_Condition2[7] = ((ix_coord == Num_X2 ||ix_coord == Num_X2+1) && iy_coord >= Num_Y2 && iy_coord < Num_Y2+6 || (ix_coord == Num_X2+4 || ix_coord == Num_X2+5) && iy_coord >= Num_Y2 && iy_coord < Num_Y2+10 ||
										ix_coord >= Num_X2 && ix_coord < Num_X2+6 && (iy_coord == Num_Y2 || iy_coord == Num_Y2+1) ) ? 1'b1 : 1'b0;
	 Num_Condition2[8] = ((ix_coord == Num_X2 || ix_coord == Num_X2+1 )&& iy_coord >= Num_Y2 && iy_coord < Num_Y2+10 || (ix_coord == Num_X2+4 || ix_coord == Num_X2+5)&& iy_coord >= Num_Y2 && iy_coord < Num_Y2+10 ||
										ix_coord >= Num_X2 && ix_coord < Num_X2+6 && (iy_coord == Num_Y2 || iy_coord == Num_Y2+1 || iy_coord == Num_Y2+4 || iy_coord == Num_Y2+5 || iy_coord == Num_Y2+8 || iy_coord == Num_Y2+9)) ? 1'b1 : 1'b0;
	 Num_Condition2[9] = ((ix_coord == Num_X2 || ix_coord == Num_X2+1 )&& iy_coord >= Num_Y2 && iy_coord < Num_Y2+6 || (ix_coord == Num_X2+4 || ix_coord == Num_X2+5)&& iy_coord >= Num_Y2 && iy_coord < Num_Y2+10 ||
										ix_coord >= Num_X2 && ix_coord < Num_X2+6 && (iy_coord == Num_Y2 || iy_coord == Num_Y2+1 || iy_coord == Num_Y2+4 || iy_coord == Num_Y2+5 || iy_coord == Num_Y2+8 || iy_coord == Num_Y2+9)) ? 1'b1 : 1'b0;
	
	 Num_Condition1[0] = ((ix_coord == Num_X1 || ix_coord == Num_X1+1 || ix_coord == Num_X1+4 || ix_coord == Num_X1+5 )&& iy_coord >= Num_Y1 && iy_coord < Num_Y1+10 ||
										ix_coord >= Num_X1 && ix_coord < Num_X1+6 && (iy_coord == Num_Y1 || iy_coord == Num_Y1+1 || iy_coord == Num_Y1+8 || iy_coord == Num_Y1+9)) ? 1'b1 : 1'b0;
	 Num_Condition1[1] = ((ix_coord == Num_X1+4 || ix_coord == Num_X1+5)&& iy_coord >= Num_Y1 && iy_coord < Num_Y1+10
										) ? 1'b1 : 1'b0;
	 Num_Condition1[2] = ((ix_coord == Num_X1 || ix_coord == Num_X1+1 )&& iy_coord >= Num_Y1+4 && iy_coord < Num_Y1+10 || (ix_coord == Num_X1+4 || ix_coord == Num_X1+5)&& iy_coord >= Num_Y1 && iy_coord < Num_Y1+6 ||
										ix_coord >= Num_X1 && ix_coord < Num_X1+6 && (iy_coord == Num_Y1 || iy_coord == Num_Y1+1 || iy_coord == Num_Y1+4 || iy_coord == Num_Y1+5 || iy_coord == Num_Y1+8 || iy_coord == Num_Y1+9)) ? 1'b1 : 1'b0;
	 Num_Condition1[3] = ((ix_coord == Num_X1+4 || ix_coord == Num_X1+5 )&& iy_coord >= Num_Y1 && iy_coord < Num_Y1+10 ||
										ix_coord >= Num_X1 && ix_coord < Num_X1+6 && (iy_coord == Num_Y1 || iy_coord == Num_Y1+1 || iy_coord == Num_Y1+4 || iy_coord == Num_Y1+5 || iy_coord == Num_Y1+8 || iy_coord == Num_Y1+9)) ? 1'b1 : 1'b0;
	 Num_Condition1[4] = ((ix_coord == Num_X1 ||ix_coord == Num_X1+1) && iy_coord >= Num_Y1 && iy_coord < Num_Y1+6 || (ix_coord == Num_X1+4 || ix_coord == Num_X1+5) && iy_coord >= Num_Y1 && iy_coord < Num_Y1+10 ||
										ix_coord >= Num_X1 && ix_coord < Num_X1+6 && (iy_coord == Num_Y1+4 || iy_coord == Num_Y1+5) ) ? 1'b1 : 1'b0;
	 Num_Condition1[5] = ((ix_coord == Num_X1 || ix_coord == Num_X1+1 )&& iy_coord >= Num_Y1 && iy_coord < Num_Y1+6 || (ix_coord == Num_X1+4 || ix_coord == Num_X1+5)&& iy_coord >= Num_Y1+4 && iy_coord < Num_Y1+10 ||
										ix_coord >= Num_X1 && ix_coord < Num_X1+6 && (iy_coord == Num_Y1 || iy_coord == Num_Y1+1 || iy_coord == Num_Y1+4 || iy_coord == Num_Y1+5 || iy_coord == Num_Y1+8 || iy_coord == Num_Y1+9)) ? 1'b1 : 1'b0;
	 Num_Condition1[6] = ((ix_coord == Num_X1 || ix_coord == Num_X1+1 )&& iy_coord >= Num_Y1 && iy_coord < Num_Y1+10 || (ix_coord == Num_X1+4 || ix_coord == Num_X1+5)&& iy_coord >= Num_Y1+4 && iy_coord < Num_Y1+10 ||
										ix_coord >= Num_X1 && ix_coord < Num_X1+6 && (iy_coord == Num_Y1 || iy_coord == Num_Y1+1 || iy_coord == Num_Y1+4 || iy_coord == Num_Y1+5 || iy_coord == Num_Y1+8 || iy_coord == Num_Y1+9)) ? 1'b1 : 1'b0;
	 Num_Condition1[7] = ((ix_coord == Num_X1 ||ix_coord == Num_X1+1) && iy_coord >= Num_Y1 && iy_coord < Num_Y1+6 || (ix_coord == Num_X1+4 || ix_coord == Num_X1+5) && iy_coord >= Num_Y1 && iy_coord < Num_Y1+10 ||
										ix_coord >= Num_X1 && ix_coord < Num_X1+6 && (iy_coord == Num_Y1 || iy_coord == Num_Y1+1) ) ? 1'b1 : 1'b0;
	 Num_Condition1[8] = ((ix_coord == Num_X1 || ix_coord == Num_X1+1 )&& iy_coord >= Num_Y1 && iy_coord < Num_Y1+10 || (ix_coord == Num_X1+4 || ix_coord == Num_X1+5)&& iy_coord >= Num_Y1 && iy_coord < Num_Y1+10 ||
										ix_coord >= Num_X1 && ix_coord < Num_X1+6 && (iy_coord == Num_Y1 || iy_coord == Num_Y1+1 || iy_coord == Num_Y1+4 || iy_coord == Num_Y1+5 || iy_coord == Num_Y1+8 || iy_coord == Num_Y1+9)) ? 1'b1 : 1'b0;
	 Num_Condition1[9] = ((ix_coord == Num_X1 || ix_coord == Num_X1+1 )&& iy_coord >= Num_Y1 && iy_coord < Num_Y1+6 || (ix_coord == Num_X1+4 || ix_coord == Num_X1+5)&& iy_coord >= Num_Y1 && iy_coord < Num_Y1+10 ||
										ix_coord >= Num_X1 && ix_coord < Num_X1+6 && (iy_coord == Num_Y1 || iy_coord == Num_Y1+1 || iy_coord == Num_Y1+4 || iy_coord == Num_Y1+5 || iy_coord == Num_Y1+8 || iy_coord == Num_Y1+9)) ? 1'b1 : 1'b0;
	
	 Num_Condition[0] = ((ix_coord == Num_X || ix_coord == Num_X+1 || ix_coord == Num_X+4 || ix_coord == Num_X+5 )&& iy_coord >= Num_Y && iy_coord < Num_Y+10 ||
										ix_coord >= Num_X && ix_coord < Num_X+6 && (iy_coord == Num_Y || iy_coord == Num_Y+1 || iy_coord == Num_Y+8 || iy_coord == Num_Y+9)) ? 1'b1 : 1'b0;
	 Num_Condition[1] = ((ix_coord == Num_X+4 || ix_coord == Num_X+5)&& iy_coord >= Num_Y && iy_coord < Num_Y+10
										) ? 1'b1 : 1'b0;
	 Num_Condition[2] = ((ix_coord == Num_X || ix_coord == Num_X+1 )&& iy_coord >= Num_Y+4 && iy_coord < Num_Y+10 || (ix_coord == Num_X+4 || ix_coord == Num_X+5)&& iy_coord >= Num_Y && iy_coord < Num_Y+6 ||
										ix_coord >= Num_X && ix_coord < Num_X+6 && (iy_coord == Num_Y || iy_coord == Num_Y+1 || iy_coord == Num_Y+4 || iy_coord == Num_Y+5 || iy_coord == Num_Y+8 || iy_coord == Num_Y+9)) ? 1'b1 : 1'b0;
	 Num_Condition[3] = ((ix_coord == Num_X+4 || ix_coord == Num_X+5 )&& iy_coord >= Num_Y && iy_coord < Num_Y+10 ||
										ix_coord >= Num_X && ix_coord < Num_X+6 && (iy_coord == Num_Y || iy_coord == Num_Y+1 || iy_coord == Num_Y+4 || iy_coord == Num_Y+5 || iy_coord == Num_Y+8 || iy_coord == Num_Y+9)) ? 1'b1 : 1'b0;
	 Num_Condition[4] = ((ix_coord == Num_X ||ix_coord == Num_X+1) && iy_coord >= Num_Y && iy_coord < Num_Y+6 || (ix_coord == Num_X+4 || ix_coord == Num_X+5) && iy_coord >= Num_Y && iy_coord < Num_Y+10 ||
										ix_coord >= Num_X && ix_coord < Num_X+6 && (iy_coord == Num_Y+4 || iy_coord == Num_Y+5) ) ? 1'b1 : 1'b0;
	 Num_Condition[5] = ((ix_coord == Num_X || ix_coord == Num_X+1 )&& iy_coord >= Num_Y && iy_coord < Num_Y+6 || (ix_coord == Num_X+4 || ix_coord == Num_X+5)&& iy_coord >= Num_Y+4 && iy_coord < Num_Y+10 ||
										ix_coord >= Num_X && ix_coord < Num_X+6 && (iy_coord == Num_Y || iy_coord == Num_Y+1 || iy_coord == Num_Y+4 || iy_coord == Num_Y+5 || iy_coord == Num_Y+8 || iy_coord == Num_Y+9)) ? 1'b1 : 1'b0;
	 Num_Condition[6] = ((ix_coord == Num_X || ix_coord == Num_X+1 )&& iy_coord >= Num_Y && iy_coord < Num_Y+10 || (ix_coord == Num_X+4 || ix_coord == Num_X+5)&& iy_coord >= Num_Y+4 && iy_coord < Num_Y+10 ||
										ix_coord >= Num_X && ix_coord < Num_X+6 && (iy_coord == Num_Y || iy_coord == Num_Y+1 || iy_coord == Num_Y+4 || iy_coord == Num_Y+5 || iy_coord == Num_Y+8 || iy_coord == Num_Y+9)) ? 1'b1 : 1'b0;
	 Num_Condition[7] = ((ix_coord == Num_X ||ix_coord == Num_X+1) && iy_coord >= Num_Y && iy_coord < Num_Y+6 || (ix_coord == Num_X+4 || ix_coord == Num_X+5) && iy_coord >= Num_Y && iy_coord < Num_Y+10 ||
										ix_coord >= Num_X && ix_coord < Num_X+6 && (iy_coord == Num_Y || iy_coord == Num_Y+1) ) ? 1'b1 : 1'b0;
	 Num_Condition[8] = ((ix_coord == Num_X || ix_coord == Num_X+1 )&& iy_coord >= Num_Y && iy_coord < Num_Y+10 || (ix_coord == Num_X+4 || ix_coord == Num_X+5)&& iy_coord >= Num_Y && iy_coord < Num_Y+10 ||
										ix_coord >= Num_X && ix_coord < Num_X+6 && (iy_coord == Num_Y || iy_coord == Num_Y+1 || iy_coord == Num_Y+4 || iy_coord == Num_Y+5 || iy_coord == Num_Y+8 || iy_coord == Num_Y+9)) ? 1'b1 : 1'b0;
	 Num_Condition[9] = ((ix_coord == Num_X || ix_coord == Num_X+1 )&& iy_coord >= Num_Y && iy_coord < Num_Y+6 || (ix_coord == Num_X+4 || ix_coord == Num_X+5)&& iy_coord >= Num_Y && iy_coord < Num_Y+10 ||
										ix_coord >= Num_X && ix_coord < Num_X+6 && (iy_coord == Num_Y || iy_coord == Num_Y+1 || iy_coord == Num_Y+4 || iy_coord == Num_Y+5 || iy_coord == Num_Y+8 || iy_coord == Num_Y+9)) ? 1'b1 : 1'b0;
	
		 // add 1+2 dot inversion
	 x_flicker_hsd_0 = ((ix_coord % 4) == 0) ? 1'b1 : 1'b0;
	 x_flicker_hsd_1 = ((ix_coord % 4) == 1) ? 1'b1 : 1'b0;
	 x_flicker_hsd_2 = ((ix_coord % 4) == 2) ? 1'b1 : 1'b0;
	 x_flicker_hsd_3 = ((ix_coord % 4) == 3) ? 1'b1 : 1'b0;
	 y_flicker_hsd = ((iy_coord % 2) == 1) ? `LUMIN_FIFTY : 8'd0;	// 50% gray
	end	
	

	
	//--------------------------------------------
	//	Edge detection
	//--------------------------------------------
	assign	vs_rising = (vsync_sr == 2'b01) ? 1'b1 : 1'b0;		// rising edge

	always@(posedge iclk or negedge irst)
		begin
			if(!irst)
				vsync_sr <= 2'b00;
			else
				vsync_sr <= {vsync_sr,ivs};
		end
	/*
	// 5s
	always@(posedge CLK_1HZ or negedge irst)
		begin
			if(!irst)
				begin
					response_flag <= 1'b0;
					response_count <= 0;
				end
			else
				begin
					if(vs_rising)
						begin
							if(response_count == 5)
								begin
									response_count <= 9'd0;
									response_flag <= ~response_flag;
								end
							else
								response_count <= response_count + 1;
						end
				end
		end
*/

/****************************************************************************************/		
		// 0.5s
	always@(posedge CLK_2HZ or negedge irst)
		begin
			if(!irst)
				begin
					response_05_flag <= 1'b0;
					response_05_count <= 9'd0;
				end
			else
				begin
					if(response_05_count == 1)
						begin
							response_05_count <= 9'd0;
							response_05_flag <= ~response_05_flag;
						end
					else
						response_05_count <= response_05_count + 9'd1;
				end
		end
		
	// 5s
	always@(posedge CLK_1HZ or negedge irst)
		begin
			if(!irst)
				begin
					response_flag <= 1'b0;
					response_count <= 9'd0;
				end
			else
				begin
					if(response_count == 5)
						begin
							response_count <= 9'd0;
							response_flag <= ~response_flag;
						end
					else
						response_count <= response_count + 9'd1;
				end
		end

	// 10s
	always@(posedge CLK_1HZ or negedge irst)
		begin
			if(!irst)
				begin
					response_10_flag <= 1'b0;
					response_10_count <= 9'd0;
				end
			else
				begin
					if(response_10_count == 10)
						begin
							response_10_count <= 9'd0;
							response_10_flag <= ~response_10_flag;
						end
					else
						response_10_count <= response_10_count + 9'd1;
				end
		end		
/****************************************************************************************/
		
		
	//lock time
	//12.5MHz to 2Hz	
		always@(posedge iOSC or negedge irst)
		begin
			if(!irst)
				begin
					div_count <= 25'd0;
					CLK_2HZ <= 1'b0;
					
				end
			else
				begin
					if(div_count==25'd3125000)
						begin
							div_count <= 8'd0;
							CLK_2HZ <= ~CLK_2HZ;
						end
					else
						div_count <= div_count+1;
		
					end
		end
		
		always@(posedge CLK_2HZ or negedge irst)
		begin
			if(!irst)
				begin
					CLK_1HZ <= 1'b0;
					
				end
			else
				begin
					CLK_1HZ <= ~CLK_1HZ;
		
				end
		end

		always@(posedge CLK_2HZ or negedge irst or negedge LOCK_RST)
		begin
			if(!irst || !LOCK_RST)
				begin
					LOCK_COUNT <= 8'd0;
				end
			else
				begin
					if(LOCK_COUNT == 8'd255)
						LOCK_COUNT <= 8'd0;
					else
						LOCK_COUNT <= LOCK_COUNT+1;
				end	
		end
		always@(posedge iclk or negedge irst)
		begin
			if(!irst)
				begin
					LOCK_T0 <= `sLOCK_T0;
					LOCK_T1 <= `sLOCK_T1;
					LOCK_T2 <= `sLOCK_T2;
					LOCK_T3 <= `sLOCK_T3;
					LOCK_T4 <= `sLOCK_T4;
					LOCK_T5 <= `sLOCK_T5;
					LOCK_T6 <= `sLOCK_T6;
					LOCK_T7 <= `sLOCK_T7;
					LOCK_T8 <= `sLOCK_T8;
					LOCK_T9 <= `sLOCK_T9;
					
					LOCK_T10 <= `sLOCK_T10;
					LOCK_T11 <= `sLOCK_T11;
					LOCK_T12 <= `sLOCK_T12;
					LOCK_T13 <= `sLOCK_T13;
					LOCK_T14 <= `sLOCK_T14;
					LOCK_T15 <= `sLOCK_T15;
					LOCK_T16 <= `sLOCK_T16;
					LOCK_T17 <= `sLOCK_T17;
					LOCK_T18 <= `sLOCK_T18;
					LOCK_T19 <= `sLOCK_T19;
					
					LOCK_T20 <= `sLOCK_T20;
					LOCK_T21 <= `sLOCK_T21;
					LOCK_T22 <= `sLOCK_T22;
					LOCK_T23 <= `sLOCK_T23;
					LOCK_T24 <= `sLOCK_T24;
					LOCK_T25 <= `sLOCK_T25;
					LOCK_T26 <= `sLOCK_T26;
					LOCK_T27 <= `sLOCK_T27;
					LOCK_T28 <= `sLOCK_T28;
					LOCK_T29 <= `sLOCK_T29;
				end
			else
				case(pattern_count)
					8'd0:		LOCK_TIME <= LOCK_T0;
					8'd1:		LOCK_TIME <= LOCK_T1;
					8'd2:		LOCK_TIME <= LOCK_T2;
					8'd3:		LOCK_TIME <= LOCK_T3;
					8'd4:		LOCK_TIME <= LOCK_T4;
					8'd5:		LOCK_TIME <= LOCK_T5;
					8'd6:		LOCK_TIME <= LOCK_T6;
					8'd7:		LOCK_TIME <= LOCK_T7;
					8'd8:		LOCK_TIME <= LOCK_T8;
					8'd9:		LOCK_TIME <= LOCK_T9;
					
					8'd10:		LOCK_TIME <= LOCK_T10;
					8'd11:		LOCK_TIME <= LOCK_T11;
					8'd12:		LOCK_TIME <= LOCK_T12;
					8'd13:		LOCK_TIME <= LOCK_T13;
					8'd14:		LOCK_TIME <= LOCK_T14;
					8'd15:		LOCK_TIME <= LOCK_T15;
					8'd16:		LOCK_TIME <= LOCK_T16;
					8'd17:		LOCK_TIME <= LOCK_T17;
					8'd18:		LOCK_TIME <= LOCK_T18;
					8'd19:		LOCK_TIME <= LOCK_T19;
					
					8'd20:		LOCK_TIME <= LOCK_T20;
					8'd21:		LOCK_TIME <= LOCK_T21;
					8'd22:		LOCK_TIME <= LOCK_T22;
					8'd23:		LOCK_TIME <= LOCK_T23;
					8'd24:		LOCK_TIME <= LOCK_T24;
					8'd25:		LOCK_TIME <= LOCK_T25;
					8'd26:		LOCK_TIME <= LOCK_T26;
					8'd27:		LOCK_TIME <= LOCK_T27;
					8'd28:		LOCK_TIME <= LOCK_T28;
					8'd29:		LOCK_TIME <= LOCK_T29;
	
				
					default: LOCK_TIME <= 8'd0;
				endcase
		end	


// ----------------------------------
	// PATTERN FORWARD and BACKFORWARD
	// ----------------------------------
		always@(posedge iclk or negedge irst)
		begin
			if(!irst)
				begin
					pattern_count <= 8'd0;
					gray_level_count <= 8'd0;
					last_auto_count <= 8'd0;
					last_pat_num <= 8'd0;
					last_inv_pat_num <= 8'd0;
					LOCK_RST <= 1'b1;
				end
			else
				begin
					if(iauto_run != 1'b1)	// Manuel Mode
						begin
							if(ipat_num != last_pat_num)
								`ifdef LOCK_MODE
								begin
									if(pattern_count == (`PATTERN_NUMBER - 1))
										pattern_count <= 8'd0;
									else
										begin
											if(LOCK_COUNT>=LOCK_TIME)
												begin
													if(mode==2'd0)
														pattern_count <= pattern_count + 8'd1;
														
													else if(mode==2'd1)
														gray_level_count <= gray_level_count + 8'd1;
													else
														pattern_count <= pattern_count;
													LOCK_RST <= 1'b0;
												end
											else
											LOCK_RST <= 1'b1;
										end
									last_pat_num <= ipat_num;
								end								
								`elsif UNLOCK_MODE
								begin
									if(pattern_count == (`PATTERN_NUMBER - 1))
										pattern_count <= 8'd0;
									else
										begin
											if(mode==2'd0)
												pattern_count <= pattern_count + 8'd1;
											else if(mode==2'd1)
												gray_level_count <= gray_level_count + 8'd1;
											else
												pattern_count <= pattern_count;													
//											pattern_count <= pattern_count + 8'd1;
//											gray_level_count <= gray_level_count + 8'd1;
										end
									last_pat_num <= ipat_num;
								end
								`endif
							if(inv_pat_num != last_inv_pat_num)
								begin
									if(pattern_count == 8'd0)
										pattern_count <= (`PATTERN_NUMBER - 1);
									else
										begin
											if(mode==2'd0)
												pattern_count <= pattern_count - 8'd1;
											else if(mode==2'd1)
												gray_level_count <= gray_level_count - 8'd1;
											else
												pattern_count <= pattern_count;
//											pattern_count <= pattern_count - 8'd1;
//											gray_level_count <= gray_level_count -8'd1;
										end
									last_inv_pat_num <= inv_pat_num;
								end

						end
					else	// Auto Mode
						begin
							if(iauto_count != last_auto_count)
								begin
									if(pattern_count == (`PATTERN_NUMBER - 1))
										pattern_count <= 8'd0;
									else
										begin
											if(mode==2'd0)
												pattern_count <= pattern_count + 8'd1;
											else if(mode==2'd1)
												gray_level_count <= gray_level_count + 8'd1;
											else
												pattern_count <= pattern_count;
//											pattern_count <= pattern_count + 8'd1;
//											gray_level_count <= gray_level_count + 8'd1;
										end
									last_auto_count <= iauto_count;
								end
						end	
				end
		end





		
/*		
	// ----------------------------------
	// PATTERN FORWARD and BACKFORWARD
	// ----------------------------------
	always@(negedge iclk or negedge irst)
		begin
			if(!irst)
				begin
					pattern_count <= 8'd0;
					last_auto_count <= 8'd0;
					last_pat_num <= 8'd0;
					last_inv_pat_num <= 8'd0;
					LOCK_RST <= 1'b1;
				end
			else
				begin
					if(iauto_run != 1'b1)	// Manuel Mode
						begin
							if(ipat_num != last_pat_num)
								`ifdef LOCK_MODE
								begin
									if(pattern_count == (`PATTERN_NUMBER - 1))
										pattern_count <= 8'd0;
									else
										begin
										if(LOCK_COUNT>=LOCK_TIME)
											begin
											pattern_count <= pattern_count + 8'd1;
											LOCK_RST <= 1'b0;
											end
										else
											LOCK_RST <= 1'b1;
										end
									last_pat_num <= ipat_num;
								end
								
								`elsif UNLOCK_MODE
								begin
									if(pattern_count == (`PATTERN_NUMBER - 1))
										pattern_count <= 8'd0;
									else
										pattern_count <= pattern_count + 8'd1;
							
									last_pat_num <= ipat_num;
								end
								`endif
							if(inv_pat_num != last_inv_pat_num)
								begin
									if(pattern_count == 8'd0)
										pattern_count <= (`PATTERN_NUMBER - 1);
									else
										pattern_count <= pattern_count - 8'd1;
							
									last_inv_pat_num <= inv_pat_num;
								end

						end
					else	// Auto Mode
						begin
							if(iauto_count != last_auto_count)
								begin
									if(pattern_count == (`PATTERN_NUMBER - 1))
										pattern_count <= 8'd0;
									else
										pattern_count <= pattern_count + 8'd1;
							
									last_auto_count <= iauto_count;
								end
						end	
				end
		end
	*/
	// ----------------------------------
	// PATTERN SELECTION
	// ----------------------------------		
	always@(negedge iclk or negedge irst)
		begin
			if(!irst)
				begin
					ordata <= 8'd0;
					ogdata <= 8'd0;
					obdata <= 8'd0;
					oframe_rate <= 2'd0;
					oUD_RL<=1'b0;
				end
			else
				begin
					if(ide_state)
						begin
							case(wpattern_count)
								`CHAR_H_PAT:
									begin
										case(wFONTH_INDEX_Y)
											4'd0:		h_pattern_reg <= 8'b11101110;
											4'd1:		h_pattern_reg <= 8'b01000100;
											4'd2:		h_pattern_reg <= 8'b01000100;
											4'd3:		h_pattern_reg <= 8'b01111100;
											4'd4:		h_pattern_reg <= 8'b01000100;
											4'd5:		h_pattern_reg <= 8'b01000100;
											4'd6:		h_pattern_reg <= 8'b11101110;
											4'd7:		h_pattern_reg <= 8'b00000000;
											default:	h_pattern_reg <= 8'dz;
										endcase
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										H_PATTERN(h_pattern_reg,wFONTH_INDEX_X,ordata,ogdata,obdata);
									end
								`R_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										RED_PATTERN(ordata,ogdata,obdata);
									end
								`R_PAT_inv:
									begin
										oUD_RL<=1'b1;
										oframe_rate <= 2'd0;
										RED_PATTERN(ordata,ogdata,obdata);
									end
								
								`R2_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										RED2_PATTERN(ix_coord,iy_coord,ordata,ogdata,obdata);//zman
									end	
								`G_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										GREEN_PATTERN(ordata,ogdata,obdata);
									end
								`B_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										BLUE_PATTERN(ordata,ogdata,obdata);
									end
								`WHITE_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										WHITE_PATTERN(ordata,ogdata,obdata);
									end
								`BLACK_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										BLACK_PATTERN(ordata,ogdata,obdata);
									end
								`BLACK_PAT_AGEN:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										BLACK_PATTERN(ordata,ogdata,obdata);
									end	
								`BLACK_PAT2:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										BLACK_PATTERN2(ix_coord,iy_coord,ordata,ogdata,obdata);//zman
									end
								`WAKU:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										WAKU_PATTERN(ix_coord,iy_coord,ordata,ogdata,obdata);//zman
									end	
								`BLACK50Hz_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd1;
										BLACK_PATTERN(ordata,ogdata,obdata);
									end
								`BORDER_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										BORDER_PATTERN(wCondition_BORDER,ordata,ogdata,obdata);
									end
								`RGB_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										RGB_PATTERN(iy_coord,ordata,ogdata,obdata);
									end
								`RGBW_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										RGBW_PATTERN(iy_coord,ordata,ogdata,obdata);
									end
								`RGBW_VGRAY_PAT: //yycheng 20230214
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										RGBW_VGRAY_PATTERN(wCondition_RGB_VGRAY,iy_coord,ordata,ogdata,obdata);
									end									
								`RGB_VGRAY_PAT:         // yycheng 20230214
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										RGB_VGRAY_PATTERN(wCondition_RGB_VGRAY,iy_coord,ordata,ogdata,obdata);
									end
								`RGB_HGRAY_PAT:         // yycheng 20230214
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										RGB_HGRAY_PATTERN(wCondition_RGB_HGRAY,ix_coord,ordata,ogdata,obdata);
									end
									
								`GOMI_PAT1:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										GOMI_PATTERN1(iy_coord,ordata,ogdata,obdata);
									end
								`GOMI_PAT2:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										GOMI_PATTERN2(iy_coord,ordata,ogdata,obdata);
									end
								`CHESS_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										CHESS_PATTERN(wCondition_CHESS,ordata,ogdata,obdata);
									end
								`LUSTER_50P:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										LUSTER_50_PATTERN(ordata,ogdata,obdata);
									end
								`LUSTER_50P2:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										LUSTER_50_PATTERN(ordata,ogdata,obdata);
									end									
								`LUSTER_20P:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										LUSTER_20_PATTERN(ordata,ogdata,obdata);
									end	
								//1+2 dot inversion
								`FLICKER_PAT_HSD:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										FLICKER_PATTERN_HSD(x_flicker_hsd_0,x_flicker_hsd_1,x_flicker_hsd_2,x_flicker_hsd_3,y_flicker_hsd,ordata,ogdata,obdata);
									end	 
									
								`LUSTER50Hz_50P:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd1;
										LUSTER_50_PATTERN(ordata,ogdata,obdata);
									end
								`LUSTER_L16:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										LUSTER_L16_PATTERN(ordata,ogdata,obdata);
									end
								`WINDOW_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										WINDOW_PATTERN(wCondition_WINDOW,ordata,ogdata,obdata);
									end
								`CROSSTALK_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										CROSSTALK_PATTERN(wCondition_WINDOW,wCondition_CROSSTALK1,
														  wCondition_CROSSTALK2,ordata,ogdata,obdata);
									end
								`VGRAY_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										VGRAY_PATTERN(wCondition_VGRAY,ordata,ogdata,obdata);
									end
								`HGRAY_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										HGRAY_PATTERN(wCondition_HGRAY,ordata,ogdata,obdata);
									end
								`VBW_PAT:
									begin
										oUD_RL<=1'b0;
										VBW_PATTERN(wCondition_VBW,ordata,ogdata,obdata);
									end
								`VBW_HSD_PAT:
									begin
										oUD_RL<=1'b0;
										VBW_HSD_PATTERN(ix_coord,iy_coord,ordata,ogdata,obdata);
									end									
									
								`HBW_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										HBW_PATTERN(wCondition_HBW,ordata,ogdata,obdata);
									end
								`FLICKER_PAT_LINE: //line
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										FLICKER_PATTERN_LINE(wCondition_FLICKER,ordata,ogdata,obdata);
									end	
								`FLICKER_PAT_COL: //col
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										FLICKER_PATTERN_COL(wFLICKER_X,ordata,ogdata,obdata);
									end	
								`FLICKER_PAT: //dot
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										FLICKER_PATTERN(wFLICKER_X,wCondition_FLICKER,ordata,ogdata,obdata);
									end	
								`FLICKER_PAT_2D: //2dot
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										FLICKER_PATTERN2D(wFLICKER_X_2D,wFLICKER_Y_2D,ordata,ogdata,obdata);
									end	
								`FLICKER_PAT_2D_1: //2dot+1
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										FLICKER_PATTERN2D_1(wFLICKER_X_2D,wFLICKER_Y_2D,ordata,ogdata,obdata);
									end		
								`FLICKER_PAT_2D_1L_2L_1: 
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										FLICKER_PATTERN2D_1L_2L_1(wFLICKER_X_2D,wFLICKER_Y_2L,ordata,ogdata,obdata);
									end			
								`FLICKER_PAT_3: //dot
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										FLICKER_PATTERN(wFLICKER_X,wFLICKER_Y_3L,ordata,ogdata,obdata);
									end		
								`FLICKER_PAT_2L: //dot
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										FLICKER_PATTERN(wFLICKER_X,wCondition_FLICKER_2L,ordata,ogdata,obdata);
									end	
								`FLICKER_PAT_2L1: //dot
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										FLICKER_PATTERN(wFLICKER_X,wCondition_FLICKER_2L1,ordata,ogdata,obdata);
									end		
								`COLOR_8G8C:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										COLOR_PATTERN(ix_coord,iy_coord,ordata,ogdata,obdata);
									end
								`COLOR_8G8C_2:
									begin
										oUD_RL<=1'b1;
										oframe_rate <= 2'd0;
										COLOR_PATTERN(ix_coord,iy_coord,ordata,ogdata,obdata);
									end	
								`RESPONSE_5_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										RESPONSE_PATTERN(response_flag,ordata,ogdata,obdata);
									end
								`RESPONSE_05_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										RESPONSE_PATTERN(response_05_flag,ordata,ogdata,obdata);
									end
								`RESPONSE_10_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										RESPONSE_PATTERN(response_10_flag,ordata,ogdata,obdata);
									end
								`PRESSURE_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										PRESSURE_PATTERN(wPressure_ConditionX,wPressure_ConditionY,ordata,ogdata,obdata);
									end
								`TP_5P_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										TP_PATTERN(wTP_ConditionP1,wTP_ConditionP2,wTP_ConditionP3,wTP_ConditionP4,wTP_ConditionP5,ordata,ogdata,obdata);
									end
								`SLOPE_PAT:
									begin
										oUD_RL<=1'b0;
										oframe_rate <= 2'd0;
										SLOPE_PATTERN(ix_coord,iy_coord,ordata,ogdata,obdata);
									end
								`GRAY_PAT:
									begin
										GRAY_PATTERN(gray_level_count,ordata,ogdata,obdata);
									end										
								default:
									begin
										oUD_RL<=1'b0;
										ordata <= 8'dz;
										ogdata <= 8'dz;
										obdata <= 8'dz;
									end
							endcase
						end
					else
						begin
							//oUD_RL<=1'b0;
							ordata <= 8'dz;
							ogdata <= 8'dz;
							obdata <= 8'dz;
						end
				end
		end

		//-----------------------------------------------------------------
		// Task
		//-----------------------------------------------------------------
		// RED Pattern
		task RED_PATTERN;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				rdata <= 8'd255;
				gdata <= 8'd0;
				bdata <= 8'd0;
			end
		endtask

		// GREEN Pattern
		task GREEN_PATTERN;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				rdata <= 8'd0;
				gdata <= 8'd255;
				bdata <= 8'd0;
			end
		endtask

		// BLUE Pattern
		task BLUE_PATTERN;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				rdata <= 8'd0;
				gdata <= 8'd0;
				bdata <= 8'd255;
			end
		endtask

		// WHITE Pattern
		task WHITE_PATTERN;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				rdata <= 8'd255;
				gdata <= 8'd255;
				bdata <= 8'd255;
			end
		endtask

		// BLACK Pattern
		task BLACK_PATTERN;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				rdata <= 8'd0;
				gdata <= 8'd0;
				bdata <= 8'd0;
			end
		endtask
		
		// BLACK Pattern2
		task BLACK_PATTERN2;//zman
		   input[19:0]		x_coord;
			input[19:0]		y_coord;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(y_coord == 0 || y_coord == (`V_PIXEL-1) || x_coord == 0 || x_coord == (`H_PIXEL-1))	
					begin
						rdata <= 8'd255;
						gdata <= 8'd255;
						bdata <= 8'd255;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
			end
		endtask
		
		task WAKU_PATTERN;//zman
		   input[19:0]		x_coord;
			input[19:0]		y_coord;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(y_coord == 0 || y_coord == (`V_PIXEL-1) || x_coord == 0 || x_coord == (`H_PIXEL-1))	
					begin
						rdata <= `LEVEL_63;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
			end
		endtask
		
		task RED2_PATTERN;//zman
		   input[19:0]		x_coord;
			input[19:0]		y_coord;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(y_coord == 0 || y_coord == (`V_PIXEL-1) || x_coord == 0 || x_coord == (`H_PIXEL-1))	
					begin
						rdata <= `LUMIN_TWENTY;
						gdata <= `LUMIN_TWENTY;
						bdata <= `LUMIN_TWENTY;
					end
				else
					begin
						rdata <= 8'd255;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
			end
		endtask

		// BORDER Pattern
		task BORDER_PATTERN;
			input			condition;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(condition)
					begin
						rdata <= 8'd255;
						gdata <= 8'd255;
						bdata <= 8'd255;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
				end
			end
		endtask

		// RGB Pattern
		task RGB_PATTERN;
			input[19:0]		y_coord;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(y_coord < (1*(`V_PIXEL/3)))
					begin
						rdata <= `LUMIN_FIFTY;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
				else if((y_coord >= (1*(`V_PIXEL/3))) && (y_coord < (2*(`V_PIXEL/3))))
					begin
						rdata <= 8'd0;
						gdata <= `LUMIN_FIFTY;
						bdata <= 8'd0;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= `LUMIN_FIFTY;
					end
			end
		endtask


		// RGB VGRAY  Pattern   yycheng 20230214
		task RGB_VGRAY_PATTERN;
			input[7:0]		condition;	
			input[19:0]		y_coord;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(y_coord < (1*(`V_PIXEL/3)))
					begin
						rdata <= condition;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
				else if((y_coord >= (1*(`V_PIXEL/3))) && (y_coord < (2*(`V_PIXEL/3))))
					begin
						rdata <= 8'd0;
						gdata <= 255-condition;
						bdata <= 8'd0;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= condition;
					end
			end
		endtask		

		// RGB HGRAY  Pattern   yycheng 20230214
		task RGB_HGRAY_PATTERN;
			input[7:0]		condition;	
			input[19:0]		x_coord;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(x_coord < (1*(`H_PIXEL/3)))
					begin
						rdata <= condition;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
				else if((x_coord >= (1*(`H_PIXEL/3))) && (x_coord < (2*(`H_PIXEL/3))))
					begin
						rdata <= 8'd0;
						gdata <= 255-condition;
						bdata <= 8'd0;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= condition;
					end
			end
		endtask		

		// RGBW VGRAY Pattern
		task RGBW_VGRAY_PATTERN;
			input[7:0]		condition;		
			input[19:0]		y_coord;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(y_coord < (1*(`V_PIXEL/4)))
					begin
						rdata <= condition;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
				else if((y_coord >= (1*(`V_PIXEL/4))) && (y_coord < (2*(`V_PIXEL/4))))
					begin
						rdata <= 8'd0;
						gdata <= condition;
						bdata <= 8'd0;
					end
				else if((y_coord >= (2*(`V_PIXEL/4))) && (y_coord < (3*(`V_PIXEL/4))))
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= condition;
					end
				else
					begin
						rdata <= condition;
						gdata <= condition;
						bdata <= condition;
					end
			end
		endtask		
		
		// RGBW Pattern
		task RGBW_PATTERN;
			input[19:0]		y_coord;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(y_coord < (1*(`V_PIXEL/4)))
					begin
						//rdata <= `LUMIN_FIFTY;
						rdata <= 8'd255;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
				else if((y_coord >= (1*(`V_PIXEL/4))) && (y_coord < (2*(`V_PIXEL/4))))
					begin
						rdata <= 8'd0;
						//gdata <= `LUMIN_FIFTY;
						gdata <= 8'd255;
						bdata <= 8'd0;
					end
				else if((y_coord >= (2*(`V_PIXEL/4))) && (y_coord < (3*(`V_PIXEL/4))))
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						//bdata <= `LUMIN_FIFTY;
						bdata <= 8'd255;
					end
				else
					begin
						//rdata <= `LUMIN_FIFTY;
						//gdata <= `LUMIN_FIFTY;
						//bdata <= `LUMIN_FIFTY;
						rdata <= 8'd255;
						gdata <= 8'd255;
						bdata <= 8'd255;
					end
			end
		endtask

		// COLOR Pattern
		task COLOR_PATTERN;
			input[19:0]		x_coord;
			input[19:0]		y_coord;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(y_coord < (1*(`V_PIXEL/2)))
					begin
						if((x_coord >= 0) && (x_coord < (1*(`H_PIXEL/8))))
							begin
								rdata <= 8'd0;
								gdata <= 8'd0;
								bdata <= 8'd0;
							end
						else if((x_coord >= (1*(`H_PIXEL/8))) && (x_coord < (2*(`H_PIXEL/8))))
							begin
								rdata <= 8'd0;
								gdata <= 8'd0;
								bdata <= 8'd255;
							end
						else if((x_coord >= (2*(`H_PIXEL/8))) && (x_coord < (3*(`H_PIXEL/8))))
							begin
								rdata <= 8'd255;
								gdata <= 8'd0;
								bdata <= 8'd0;
							end
						else if((x_coord >= (3*(`H_PIXEL/8))) && (x_coord < (4*(`H_PIXEL/8))))
							begin
								rdata <= 8'd255;
								gdata <= 8'd0;
								bdata <= 8'd255;
							end
						else if((x_coord >= (4*(`H_PIXEL/8))) && (x_coord < (5*(`H_PIXEL/8))))
							begin
								rdata <= 8'd0;
								gdata <= 8'd255;
								bdata <= 8'd0;
							end
						else if((x_coord >= (5*(`H_PIXEL/8))) && (x_coord < (6*(`H_PIXEL/8))))
							begin
								rdata <= 8'd0;
								gdata <= 8'd255;
								bdata <= 8'd255;
							end
						else if((x_coord >= (6*(`H_PIXEL/8))) && (x_coord < (7*(`H_PIXEL/8))))
							begin
								rdata <= 8'd255;
								gdata <= 8'd255;
								bdata <= 8'd0;
							end
						else
							begin
								rdata <= 8'd255;
								gdata <= 8'd255;
								bdata <= 8'd255;
							end
					end
				else
					begin
						if((x_coord >= 0) && (x_coord < (1*(`H_PIXEL/8))))
							begin
								rdata <= 8'd255;
								gdata <= 8'd255;
								bdata <= 8'd255;
							end
						else if((x_coord >= (1*(`H_PIXEL/8))) && (x_coord < (2*(`H_PIXEL/8))))
							begin
								rdata <= 8'd191;
								gdata <= 8'd191;
								bdata <= 8'd191;
							end
						else if((x_coord >= (2*(`H_PIXEL/8))) && (x_coord < (3*(`H_PIXEL/8))))
							begin
								rdata <= 8'd159;
								gdata <= 8'd159;
								bdata <= 8'd159;
							end
						else if((x_coord >= (3*(`H_PIXEL/8))) && (x_coord < (4*(`H_PIXEL/8))))
							begin
								rdata <= 8'd127;
								gdata <= 8'd127;
								bdata <= 8'd127;
							end
						else if((x_coord >= (4*(`H_PIXEL/8))) && (x_coord < (5*(`H_PIXEL/8))))
							begin
								rdata <= 8'd95;
								gdata <= 8'd95;
								bdata <= 8'd95;
							end
						else if((x_coord >= (5*(`H_PIXEL/8))) && (x_coord < (6*(`H_PIXEL/8))))
							begin
								rdata <= 8'd63;
								gdata <= 8'd63;
								bdata <= 8'd63;
							end
						else if((x_coord >= (6*(`H_PIXEL/8))) && (x_coord < (7*(`H_PIXEL/8))))
							begin
								rdata <= 8'd31;
								gdata <= 8'd31;
								bdata <= 8'd31;
							end
						else
							begin
								rdata <= 8'd0;
								gdata <= 8'd0;
								bdata <= 8'd0;
							end
					end
			end
		endtask

		
		// FLICKER Pattern Line
		task FLICKER_PATTERN_LINE;
			input[7:0]		condition2; 
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
		
				rdata <= (condition2 ^ `LUMIN_FIFTY);
				gdata <= (condition2 ^ `LUMIN_FIFTY);
				bdata <= (condition2 ^ `LUMIN_FIFTY);

			end
		endtask
		
		// FLICKER Pattern Columns
		task FLICKER_PATTERN_COL;
			input			condition1; 
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(condition1)
					begin
						rdata <= `LUMIN_FIFTY;
						gdata <= 8'd0;
						bdata <= `LUMIN_FIFTY;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= `LUMIN_FIFTY;
						bdata <= 8'd0;
					end
			end
		endtask
		
		
		// FLICKER Pattern
		task FLICKER_PATTERN;
			input			condition1; 
			input[7:0]		condition2; //odd even
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(condition1)
					begin
						rdata <= (condition2 ^ `LUMIN_FIFTY);
						gdata <= (condition2 ^ 8'd0);
						bdata <= (condition2 ^ `LUMIN_FIFTY);
					end
				else
					begin
						rdata <= (condition2 ^ 8'd0);
						gdata <= (condition2 ^ `LUMIN_FIFTY);
						bdata <= (condition2 ^ 8'd0);
					end
			end
		endtask
		
				// FLICKER Pattern 2dot
		task FLICKER_PATTERN2D;
			input[3:0]		condition0;
			input			condition1;	//odd even		
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if((condition1==1'b0 && condition0==2'b00) || (condition1==1'b1 && condition0==2'b10) )
					begin
						rdata <=  `LUMIN_FIFTY;
						gdata <=  `LUMIN_FIFTY;
						bdata <=  8'd0;
					end
				else if((condition1==1'b0 && condition0==2'b01) || (condition1==1'b1 && condition0==2'b11) )
					begin
						rdata <=  8'd0;
						gdata <= `LUMIN_FIFTY;
						bdata <= `LUMIN_FIFTY;
					end
				else if((condition1==1'b0 && condition0==2'b10) || (condition1==1'b1 && condition0==2'b00) )
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= `LUMIN_FIFTY;
					end
				else if((condition1==1'b0 && condition0==2'b11) || (condition1==1'b1 && condition0==2'b01) )
					begin
						rdata <= `LUMIN_FIFTY;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
				
			end
		endtask
		// FLICKER Pattern 2dot +1
		task FLICKER_PATTERN2D_1;
			input[3:0]		condition0;
			input			condition1;	//odd even		
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if((condition1==1'b0 && condition0==2'b00) || (condition1==1'b1 && condition0==2'b10) )
					begin
						rdata <=  `LUMIN_FIFTY;
						gdata <=  8'd0;
						bdata <=  8'd0;
					end
				else if((condition1==1'b0 && condition0==2'b01) || (condition1==1'b1 && condition0==2'b11) )
					begin
						rdata <= `LUMIN_FIFTY;
						gdata <= `LUMIN_FIFTY;
						bdata <= 8'd0;
					end
				else if((condition1==1'b0 && condition0==2'b10) || (condition1==1'b1 && condition0==2'b00) )
					begin
						rdata <= 8'd0;
						gdata <= `LUMIN_FIFTY;
						bdata <= `LUMIN_FIFTY;
					end
				else if((condition1==1'b0 && condition0==2'b11) || (condition1==1'b1 && condition0==2'b01) )
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= `LUMIN_FIFTY;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
				
			end
		endtask
		
		
		
		
		// FLICKER Pattern 2dot+1line & 2line+1
		task FLICKER_PATTERN2D_1L_2L_1;
			input[3:0]		condition0;
			input[3:0]   	condition1;	//odd even		
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(((condition1==2'b00 || condition1==2'b11) && condition0==2'b00) || 
				   ((condition1==2'b01 || condition1==2'b10) && condition0==2'b10) )
					begin
						rdata <=  `LUMIN_FIFTY;
						gdata <=  8'd0;
						bdata <=  8'd0;
					end
				else if(((condition1==2'b00 || condition1==2'b11) && condition0==2'b01) || 
				        ((condition1==2'b01 || condition1==2'b10) && condition0==2'b11) )
					begin
						rdata <= `LUMIN_FIFTY;
						gdata <= `LUMIN_FIFTY;
						bdata <= 8'd0;
					end
				else if(((condition1==2'b00 || condition1==2'b11) && condition0==2'b10) || 
				        ((condition1==2'b01 || condition1==2'b10) && condition0==2'b00) )
					begin
						rdata <= 8'd0;
						gdata <= `LUMIN_FIFTY;
						bdata <= `LUMIN_FIFTY;
					end
				else if(((condition1==2'b00 || condition1==2'b11) && condition0==2'b11) || 
				        ((condition1==2'b01 || condition1==2'b10) && condition0==2'b01) )
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= `LUMIN_FIFTY;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
				
			end
		endtask
		
		// VBW Pattern
		task VBW_HSD_PATTERN;
			input[19:0]		x_coord;
			input[19:0]		y_coord;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				case(x_coord[0])
					1'b0:begin
						rdata <= 8'd255;
						gdata <= 8'd0;
						bdata <= 8'd255;
					end
					1'b1:begin
						rdata <= 8'd0;
						gdata <= 8'd255;
						bdata <= 8'd0;
					end
					default:begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
				endcase
			end
		endtask
		
		// VBW Pattern
		task VBW_PATTERN;
			input			condition;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(condition)
					begin
						rdata <= 8'd255;
						gdata <= 8'd255;
						bdata <= 8'd255;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
			end
		endtask

		// HBW Pattern
		task HBW_PATTERN;
			input			condition;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(condition)
					begin
						rdata <= 8'd255;
						gdata <= 8'd255;
						bdata <= 8'd255;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
			end
		endtask

		// HGRAY Pattern
		task HGRAY_PATTERN;
			input[7:0]		condition;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				rdata <= condition;
				gdata <= condition;
				bdata <= condition;
			end
		endtask

		// VGRAY Pattern
		task VGRAY_PATTERN;
			input[7:0]		condition;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				rdata <= condition;
				gdata <= condition;
				bdata <= condition;
			end
		endtask

		// WINDOW Pattern
		task WINDOW_PATTERN;
			input			condition;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(condition)
					begin
						// Normal White(TN type)
						rdata <= 8'd255;
						gdata <= 8'd255;
						bdata <= 8'd255;
					end
				else
					begin
						rdata <= `LUMIN_FIFTY;
						gdata <= `LUMIN_FIFTY;
						bdata <= `LUMIN_FIFTY;
					end
			end
		endtask

		// CROSSTALK Pattern
		task CROSSTALK_PATTERN;
			input			condition1;
			input			condition2;
			input			condition3;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(condition1)
					begin
						if(condition2)
							begin
								rdata <= 8'd255;
								gdata <= 8'd0;
								bdata <= 8'd255;
							end
						else if(condition3)
							begin
								rdata <= 8'd0;
								gdata <= 8'd255;
								bdata <= 8'd0;
							end
					end
				else
					begin
						rdata <= `LUMIN_FIFTY;
						gdata <= `LUMIN_FIFTY;
						bdata <= `LUMIN_FIFTY;
					end
			end
		endtask

		// LUSTER(50%) Pattern
		task LUSTER_50_PATTERN;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				rdata <= `LUMIN_FIFTY;
				gdata <= `LUMIN_FIFTY;
				bdata <= `LUMIN_FIFTY;
			end
		endtask
		
		// LUSTER(20%) Pattern
		task LUSTER_20_PATTERN;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				rdata <= `LUMIN_TWENTY;
				gdata <= `LUMIN_TWENTY;
				bdata <= `LUMIN_TWENTY;
			end
		endtask

		// LUSTER L16 Pattern
		task LUSTER_L16_PATTERN;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				rdata <= `LEVEL_63;
				gdata <= `LEVEL_63;
				bdata <= `LEVEL_63;
			end
		endtask

		// CHESS PATTERN
		task CHESS_PATTERN;
			input			condition;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(condition)
					begin
						rdata <= 8'd255;
						gdata <= 8'd255;
						bdata <= 8'd255;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
			end
		endtask

		// H PAttern
		task H_PATTERN;
			input[7:0]		h_reg;
			input[3:0]		index;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(h_reg[index])
					begin
						rdata <= 8'd255;
						gdata <= 8'd255;
						bdata <= 8'd255;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
			end
		endtask

		// GOMI Pattern 1
		task GOMI_PATTERN1;
			input[19:0]		y_coord;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(y_coord < (1*(`V_PIXEL/4)))
					begin
						rdata <= 8'd255;
						gdata <= 8'd255;
						bdata <= 8'd255;
					end
				else if((y_coord >= (1*(`V_PIXEL/4))) && (y_coord < (2*(`V_PIXEL/4))))
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
				else if((y_coord >= (2*(`V_PIXEL/4))) && (y_coord < (3*(`V_PIXEL/4))))
					begin
						rdata <= 8'd255;
						gdata <= 8'd255;
						bdata <= 8'd255;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
			end
		endtask

		// GOMI Pattern 2
		task GOMI_PATTERN2;
			input[19:0]		y_coord;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(y_coord < (1*(`V_PIXEL/4)))
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
				else if((y_coord >= (1*(`V_PIXEL/4))) && (y_coord < (2*(`V_PIXEL/4))))
					begin
						rdata <= 8'd255;
						gdata <= 8'd255;
						bdata <= 8'd255;
					end
				else if((y_coord >= (2*(`V_PIXEL/4))) && (y_coord < (3*(`V_PIXEL/4))))
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
				else
					begin
						rdata <= 8'd255;
						gdata <= 8'd255;
						bdata <= 8'd255;
					end
			end
		endtask

		// Response Pattern
		task RESPONSE_PATTERN;
			input			flag;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(flag)
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
				else
					begin
						rdata <= 8'd255;
						gdata <= 8'd255;
						bdata <= 8'd255;
					end
			end
		endtask
		// FLICKER Pattern_1+2 dot inversion
		task FLICKER_PATTERN_HSD;
			input			condition0;
			input			condition1;
			input			condition2;
			input			condition3;
			input[7:0]		condition4;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(condition0)
					begin
						rdata <= (condition4 ^ `LUMIN_FIFTY);
						gdata <= (condition4 ^ 8'd0);
						bdata <= (condition4 ^ 8'd0);
					end
				else if(condition1)	
					begin
						rdata <= (condition4 ^ `LUMIN_FIFTY);
						gdata <= (condition4 ^ `LUMIN_FIFTY);
						bdata <= (condition4 ^ 8'd0);
					end
				else if(condition2)	
					begin
						rdata <= (condition4 ^ 8'd0);
						gdata <= (condition4 ^ `LUMIN_FIFTY);
						bdata <= (condition4 ^ `LUMIN_FIFTY);
					end		
				else if(condition3)
					begin
						rdata <= (condition4 ^ 8'd0);
						gdata <= (condition4 ^ 8'd0);
						bdata <= (condition4 ^ `LUMIN_FIFTY);
					end	
			end
		endtask
		// Pressure Pattern
		task PRESSURE_PATTERN;
			input			range1;
			input			range2;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(range1 || range2)
					begin
						rdata <= 8'd255;
						gdata <= 8'd255;
						bdata <= 8'd255;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
			end
		endtask

		// TP Pattern
		task TP_PATTERN;
			input			range1;
			input			range2;
			input			range3;
			input			range4;
			input			range5;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
				if(range1 || range2 || range3 || range4 || range5)
					begin
						rdata <= 8'd255;
						gdata <= 8'd255;
						bdata <= 8'd255;
					end
				else
					begin
						rdata <= 8'd0;
						gdata <= 8'd0;
						bdata <= 8'd0;
					end
			end
		endtask
		
		// Slope Pattern
		task SLOPE_PATTERN;
			input[21:0]		x_coord;
			input[21:0]		y_coord;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
			if((x_coord%8)==(y_coord%8))	
				begin
					rdata <= 8'd186;
					gdata <= 8'd186;
					bdata <= 8'd186;
				end
			else
				begin
					rdata <= 8'd0;
					gdata <= 8'd0;
					bdata <= 8'd0;
				end
			end
		endtask
		
		task GRAY_PATTERN;
			input[7:0]		condition;
			output[7:0]		rdata;
			output[7:0]		gdata;
			output[7:0]		bdata;
			begin
			if(Num_Condition[condition%10]||Num_Condition1[(condition/10)%10]||Num_Condition2[condition/100])
				begin
					rdata <= 8'hFF;
					gdata <= 8'h00;
					bdata <= 8'h00;
				end
			else
				begin
					rdata <= condition;
					gdata <= condition;
					bdata <= condition;
				end
			end
		endtask		
		
endmodule
