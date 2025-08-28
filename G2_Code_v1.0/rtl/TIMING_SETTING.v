
////////////////////////////////////////////////////////////////////////////////
//`define BIT6
`define BIT8

//`define LOCK_MODE
`define UNLOCK_MODE

`define H_PIXEL				22'd800		// Panel Resolution (H)
`define V_PIXEL				22'd480		// Panel Resolution (V)

`define DE_MODE							   // Panel Timing Mode
//`define HV_MODE

`define VS_PULSE_WIDTH		22'd1		// Tvpw  
`define VS_PERIOD			22'd525		// Tv 

`define HS_PULSE_WIDTH		22'd48		// Thpw 
`define HS_PERIOD			22'd1056	// Th 

`ifdef HV_MODE
	`define HS_BACK_PORCH	22'd256		// Thb 
	`define VS_BACK_PORCH	22'd45		// Tvb 

`elsif DE_MODE
	`define	HS_BLANK		22'd256		// Thb 
	`define	VS_BLANK		22'd45		// Tvb 
`endif


//lock pateern0 time setting: unit 0.5 Sec
`define sLOCK_T0		8'd6		
`define sLOCK_T1		8'd10
`define sLOCK_T2		8'd6
`define sLOCK_T3		8'd1
`define sLOCK_T4		8'd1
`define sLOCK_T5		8'd1
`define sLOCK_T6		8'd2
`define sLOCK_T7		8'd2
`define sLOCK_T8		8'd1
`define sLOCK_T9		8'd0

`define sLOCK_T10		8'd0		
`define sLOCK_T11		8'd0
`define sLOCK_T12		8'd0
`define sLOCK_T13		8'd0
`define sLOCK_T14		8'd0
`define sLOCK_T15		8'd0
`define sLOCK_T16		8'd0
`define sLOCK_T17		8'd0
`define sLOCK_T18		8'd0
`define sLOCK_T19		8'd0

`define sLOCK_T20		8'd0		
`define sLOCK_T21		8'd0
`define sLOCK_T22		8'd0
`define sLOCK_T23		8'd0
`define sLOCK_T24		8'd0
`define sLOCK_T25		8'd0
`define sLOCK_T26		8'd0
`define sLOCK_T27		8'd0
`define sLOCK_T28		8'd0
`define sLOCK_T29		8'd0


////////////////////////////////////////////////////////////////////////////////
//lock pateern0 time setting: unit 0.5 Sec

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
`define PATTERN_NUMBER		8'd23  // pattern+1

`define	LUMIN_FIFTY			8'd128
`define	LUMIN_TWENTY		8'd127
`define	LEVEL_63			8'd64

`define BORDER_PAT		8'd0
`define R_PAT				8'd1
`define G_PAT				8'd2
`define B_PAT				8'd3
`define WHITE_PAT			8'd4
`define BLACK_PAT			8'd5
`define FLICKER_PAT_HSD	8'd6
`define WINDOW_PAT		8'd7
`define LUSTER_50P		8'd8
`define COLOR_8G8C		8'd9
`define VGRAY_PAT			8'd10
`define HGRAY_PAT			8'd11
`define VBW_PAT			8'd99
`define VBW_HSD_PAT		8'd12
`define RGB_PAT			8'd13
`define CHESS_PAT			8'd14//8*6
`define LUSTER_20P		8'd15
`define GOMI_PAT1			8'd16
`define GOMI_PAT2			8'd17
`define LUSTER_50P2		8'd18
`define RESPONSE_05_PAT	8'd19
`define RESPONSE_5_PAT	8'd20
`define RESPONSE_10_PAT	8'd21
`define BLACK_PAT_AGEN  8'd22

`define R2_PAT				8'd23  // Red pattern with board
`define RGB_VGRAY_PAT	8'd24
`define RGB_HGRAY_PAT	8'd25
`define RGBW_VGRAY_PAT	8'd26

//////////////////////////////



`define COLOR_8G8C_2		8'd27

`define PRESSURE_PAT		8'd28
//`define RGB_PAT				8'd29
`define RGBW_PAT			8'd30
`define BLACK50Hz_PAT		8'd31

`define LUSTER50Hz_50P		8'd32
`define TP_5P_PAT			8'd33

//`define RESPONSE_5_PAT		8'd34
`define LUSTER_L16			8'd35
`define HBW_PAT				8'd36
`define CHAR_H_PAT			8'd37
`define CROSSTALK_PAT		8'd38
`define WAKU				8'd39   //WAKU
`define BLACK_PAT2			8'd40
`define FLICKER_PAT_LINE	8'd41
`define FLICKER_PAT_COL		8'd42
`define FLICKER_PAT_2D		8'd43
`define FLICKER_PAT_2D_1	8'd44
`define FLICKER_PAT_2D_1L_2L_1 8'd45
`define FLICKER_PAT_3  		8'd46
`define FLICKER_PAT_2L 		8'd47
`define FLICKER_PAT_2L1 	8'd48
`define SLOPE_PAT			8'd49




`define R_PAT_inv			8'd50
`define FLICKER_PAT		8'd51
`define GRAY_PAT			8'd98
