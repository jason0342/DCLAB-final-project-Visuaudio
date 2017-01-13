module Renderer (
	input i_clk,
	input i_reset,
	input [3:0][15:0] i_fft_data,
	input i_fft_done,
	input [10:0] i_VGA_X,
	input [10:0] i_VGA_Y,
	output [7:0] o_VGA_R,
	output [7:0] o_VGA_G,
	output [7:0] o_VGA_B
);

	assign o_VGA_R = iRed;
	assign o_VGA_G = iGreen;
	assign o_VGA_B = iBlue;

	logic [7:0] iRed, iGreen, iBlue;

	// Testing
	// assign iBlue = '1;
	// assign iGreen = '0;
	// assign iRed = '0;
always_comb begin
	iBlue = '0;
	iGreen = '0;
	iRed = '0;
	if(i_VGA_Y < i_fft_done[i_VGA_X[8:5]]) begin
		iBlue = '1;
		iGreen = '1;
		iRed = '1;
	end
end

endmodule