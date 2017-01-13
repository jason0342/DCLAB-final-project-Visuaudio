module Render (
	input i_clk,
	input i_reset,
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
	assign iBlue = '1;
	assign iGreen = '0;
	assign iRed = '0;

endmodule