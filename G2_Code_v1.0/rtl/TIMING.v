`include "TIMING_SETTING.V"


module TIMING(irst,iclk,ovsync,ohsync,ode,ox_coord,oy_coord,ode_state);

	input						irst;
	input						iclk;

	output reg					ovsync;
	output reg					ohsync;
	output reg					ode;
	output						ode_state;
	output reg[21:0]				ox_coord;
	output reg[21:0]				oy_coord;

	reg[21:0]					vsync_count;
	reg[21:0]					hsync_count;
	reg[21:0]					de_count;

	wire						wDE_CTRL1;
	wire						wDE_CTRL2;
	wire						wDE_STATE;

	assign ode_state = wDE_STATE;

	//--------------------------------------------
	//	Edge detection
	//--------------------------------------------
	reg[1:0]					de_sr;
	wire						de_rising;

	assign	de_rising = (de_sr == 2'b10) ? 1'b1 : 1'b0;		// rising edge

	always@(posedge iclk or negedge irst)
		begin
			if(!irst)
				de_sr <= 2'b00;
			else
				de_sr <= {de_sr,ode};
		end

	//--------------------------------------------
	//	Module of VSYNC signal
	//	Input : 	iclk = 8.42MHz(typical)
	//	Output :	ovsync register
	//	vs_count :	Max.270Th
	//--------------------------------------------
	always@(negedge iclk or negedge irst)
		begin
			if(!irst)
				vsync_count <= 0;
			else
				begin
					if(vsync_count == (`VS_PERIOD*`HS_PERIOD - 1))
						vsync_count <= 0;
					else
						vsync_count <= vsync_count + 1;
				end
		end
	always@(negedge iclk or negedge irst)
		begin
			if(!irst)
				ovsync <= 0;
			else
				begin
					if(vsync_count > (`VS_PULSE_WIDTH*`HS_PERIOD - 1))
						ovsync <= 1;
					else
						ovsync <= 0;
				end
		end

	//--------------------------------------------
	//	HSYNC signal
	//	Input : 	iclk = 8.42MHz(typical)
	//	Output :	hsync register
	//	hs_count :	Max.520CLK
	//--------------------------------------------
	always@(negedge iclk or negedge irst)
		begin
			if(!irst)
				hsync_count <= 0;
			else
				begin
					if(hsync_count == (`HS_PERIOD - 1))
						hsync_count <= 0;
					else
						hsync_count <= hsync_count + 1;
				end
		end

	always@(negedge iclk or negedge irst)
		begin
			if(!irst)
				ohsync <= 0;
			else
				begin
					if(hsync_count > (`HS_PULSE_WIDTH - 1))
						ohsync <= 1;
					else
						ohsync <= 0;
				end
		end

	//--------------------------------------------
	//	Data Enable(DE) signal
	//	Input : 	iclk = 8.42MHz(typical)
	//	Output :	de register
	//	de_count :	Max.520CLK
	//--------------------------------------------
	always@(negedge iclk or negedge irst)
		begin
			if(!irst)
				de_count <= 0;
			else
				begin
					if(de_count == (`HS_PERIOD - 1))
						de_count <= 0;
					else
						de_count <= de_count + 1;
				end
		end

	`ifdef HV_MODE
		assign wDE_CTRL1 = ((vsync_count > (`VS_BACK_PORCH*`HS_PERIOD - 1)) && (vsync_count < ((`VS_BACK_PORCH+`V_PIXEL)*`HS_PERIOD)));
		assign wDE_CTRL2 = ((de_count > (`HS_BACK_PORCH - 1)) && (de_count < (`HS_BACK_PORCH+`H_PIXEL)));
		assign wDE_STATE = (wDE_CTRL1 && wDE_CTRL2) ? 1'b1:1'b0;
	`elsif DE_MODE
		assign wDE_CTRL1 = ((vsync_count > (`VS_BLANK*`HS_PERIOD - 1)) && (vsync_count < `VS_PERIOD*`HS_PERIOD)) ? 1'b1:1'b0;
		assign wDE_CTRL2 = ((de_count > (`HS_BLANK - 1)) && (de_count < `HS_PERIOD)) ? 1'b1:1'b0;
		assign wDE_STATE = (wDE_CTRL1 && wDE_CTRL2) ? 1'b1:1'b0;
	`endif

	always@(negedge iclk or negedge irst)
		begin
			if(!irst)
				ode <= 0;
			else
				begin
					if(wDE_STATE)
						ode <= 1;
					else
						ode <= 0;
				end
		end

	//--------------------------------------------
	//	x_count :	Max.Horizontal Pixel (400)
	//	y_count :	Max.Vrtical Pixel (240)
	//--------------------------------------------
	always@(negedge iclk or negedge irst)
		begin
			if(!irst)
				ox_coord <= 0;
			else
				begin
					if(wDE_STATE)
						begin
							if(ox_coord == (`H_PIXEL - 1))
								ox_coord <= 0;
							else
								ox_coord <= ox_coord + 1;
						end
					else
						ox_coord <= 0;
				end
		end
	always@(negedge iclk or negedge irst)
		begin
			if(!irst)
				oy_coord <= 0;
			else
				begin
					if(de_rising)
						begin
							if(oy_coord == (`V_PIXEL - 1))
								oy_coord <= 0;
							else
								oy_coord <= oy_coord + 1;
						end
				end
		end
endmodule
