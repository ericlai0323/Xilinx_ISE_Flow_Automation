
`define FORWARD				8'd255
`define BACKFORWARD			8'd255
`define COMMAND				8'd255

module BUTTON(irst,iclk,ivsync,ibtn_0,ibtn_1,ibtn_2,obtn0_index,obtn1_index,obtn2_index);

	input						irst;
	input						iclk;
	input						ivsync;
	input						ibtn_0;
	input						ibtn_1;
	input						ibtn_2;

	output reg[7:0]				obtn0_index;
	output reg[7:0]				obtn1_index;
	output reg[7:0]				obtn2_index;

	reg[3:0]					btn0_debounce;
	reg[3:0]					btn1_debounce;
	reg[3:0]					btn2_debounce;

	reg[3:0]					btn0_status;
	reg[3:0]					btn1_status;
	reg[3:0]					btn2_status;

	


	//--------------------------------------------
	//	Edge detection
	//--------------------------------------------
	reg[1:0]					vsync_sr;
	wire						vs_rising;

	assign	vs_rising = (vsync_sr == 2'b01) ? 1'b1 : 1'b0;		// rising edge

	always@(posedge iclk or negedge irst)
		begin
			if(!irst)
				vsync_sr <= 2'b00;
			else
				vsync_sr <= {vsync_sr,ivsync};
		end

	//--------------------------------------------
	//	Input : Button0
	//	PCB name : B1
	//	btn0_count : Max.255
	//--------------------------------------------
	always@(posedge iclk or negedge irst)
		begin
			if(!irst)
				begin
					btn0_debounce <= 4'd0;
					btn0_status <= 4'd0;
					obtn0_index <= 8'd0;
				end
			else
				case(btn0_status)
					4'd0:	
						begin
							if(ibtn_0 == 1'b0)
								btn0_status <= 4'd1;
							else
								btn0_status <= 4'd0;
						end
					4'd1: 
						begin
							if(vs_rising)
								begin
									if(btn0_debounce > 4'd5)
										begin
											btn0_debounce <= 4'd0;
											btn0_status <= 4'd2;
										end
									else
										begin
											btn0_status <= 4'd1;
											btn0_debounce <= btn0_debounce + 4'd1;
										end
								end
							else
								btn0_status <= 4'd1;
						end
					4'd2:
						begin
							if(ibtn_0 == 1'b1)
								btn0_status <= 4'd3;
							else
								btn0_status <= 4'd0;
						end
					4'd3:
						begin
							btn0_status <= 4'd0;
							if(obtn0_index == (`FORWARD - 1))
								obtn0_index <= 8'd0;
							else
								obtn0_index <= obtn0_index + 8'd1;
						end
					default: btn0_status <= 4'd0;
				endcase
		end

		
		
	//--------------------------------------------
	//	Input : Button1
	//	PCB name : B2
	//	btn1_count : Max.255
	//--------------------------------------------
	always@(posedge iclk or negedge irst)
		begin
			if(!irst)
				begin
					btn1_debounce <= 4'd0;
					btn1_status <= 4'd0;
					obtn1_index <= 8'd0;
				end
			else
				case(btn1_status)
					4'd0:
						begin
							if(ibtn_1 == 1'b0)
								btn1_status <= 4'd1;
							else
								btn1_status <= 4'd0;
						end
					4'd1: 
						begin
							if(vs_rising)
								begin
									if(btn1_debounce > 4'd5)
										begin
											btn1_debounce <= 4'd0;
											btn1_status <= 4'd2;
										end
									else
										begin
											btn1_status <= 4'd1;
											btn1_debounce <= btn1_debounce + 4'd1;
										end
								end
							else
								btn1_status <= 4'd1;
						end
					4'd2:
						begin
							if(ibtn_1 == 1'b1)
								btn1_status <= 4'd3;
							else
								btn1_status <= 4'd0;
						end
					4'd3:
						begin
							btn1_status <= 4'd0;
							if(obtn1_index == (`BACKFORWARD - 1))
								obtn1_index <= 8'd0;
							else
								obtn1_index <= obtn1_index + 8'd1;
						end
					default: btn1_status <= 4'd0;
				endcase
		end

	//--------------------------------------------
	//	Input : Button2
	//	PCB name : B3
	//	btn2_count : Max.255
	//--------------------------------------------
	always@(posedge iclk or negedge irst)
		begin
			if(!irst)
				begin
					btn2_debounce <= 4'd0;
					btn2_status <= 4'd0;
					obtn2_index <= 8'd0;
				end
			else
				case(btn2_status)
					4'd0:
						begin
							if(ibtn_2 == 1'b0)
								btn2_status <= 4'd1;
							else
								btn2_status <= 4'd0;
						end
					4'd1: 
						begin
							if(vs_rising)
								begin
									if(btn2_debounce > 4'd5)
										begin
											btn2_debounce <= 4'd0;
											btn2_status <= 4'd2;
										end
									else
										begin
											btn2_status <= 4'd1;
											btn2_debounce <= btn2_debounce + 4'd1;
										end
								end
							else
								btn2_status <= 4'd1;
						end
					4'd2:
						begin
							if(ibtn_2 == 1'b1)
								btn2_status <= 4'd3;
							else
								btn2_status <= 4'd0;
						end
					4'd3:
						begin
							btn2_status <= 4'd0;
							if(obtn2_index == (`COMMAND - 1))
								obtn2_index <= 8'd0;
							else
								obtn2_index <= obtn2_index + 8'd1;
						end
					default: btn2_status <= 4'd0;
				endcase
		end
endmodule
