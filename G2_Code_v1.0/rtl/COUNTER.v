`define COUNTS				8'd255
`define COUNT_1SEC			10'd60
`define COUNT_5SEC			10'd300
`define COUNT_10SEC			10'd600

module COUNTER(irst,iclk,ivsync,oCount_1s);
	input				irst;
	input				iclk;
	input				ivsync;

	output reg[7:0]		oCount_1s;


	reg[9:0]			count_1s;

	reg[1:0]			vsync_sr;
	wire				vs_rising;

	//--------------------------------------------
	//	Edge detection
	//--------------------------------------------
	assign	vs_rising = (vsync_sr == 2'b01) ? 1'b1 : 1'b0;		// rising edge

	always@(posedge iclk or negedge irst)
		begin
			if(!irst)
				vsync_sr <= 2'b00;
			else
				vsync_sr <= {vsync_sr,ivsync};
		end

	// 1s
	always@(posedge iclk or negedge irst)
		begin
			if(!irst)
				begin
					oCount_1s <= 8'd0;
					count_1s <= 10'd0;
				end
			else
				begin
					if(vs_rising)
						begin
							if(count_1s == `COUNT_1SEC - 1)
								begin
									count_1s <= 10'd0;
									if(oCount_1s == `COUNTS - 1)
										oCount_1s <= 8'd0;
									else
										oCount_1s <= oCount_1s + 8'd1;
								end
							else
								count_1s <= count_1s + 10'd1;
						end
				end
		end


	

endmodule
