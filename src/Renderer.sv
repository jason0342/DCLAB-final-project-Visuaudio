module Renderer (
	input i_clk,
	input i_rst,
	input [31:0][15:0] i_fft_data,
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
	logic [31:0][15:0] fft_data_r, fft_data_w;
	logic [2:0] count_r, count_w;
	logic [15:0] log2A, abs_data;

	// Testing
	// assign iBlue = '1;
	// assign iGreen = '0;
	// assign iRed = '0;

	log2 log2_0(abs_data, log2A);
	assign abs_data = (fft_data_r[i_VGA_X[8:4]][15])? (2**16-fft_data_r[i_VGA_X[8:4]]) : fft_data_r[i_VGA_X[8:4]];

always_comb begin
	fft_data_w = fft_data_r;
	count_w = count_r;

	iBlue = '0;
	iGreen = '0;
	iRed = '0;
	if(i_VGA_X < 512) begin
		if( 479 - i_VGA_Y < (log2A + 1) << 4) begin
			iBlue = '0;
			iGreen = '1;
			iRed = '0;
		end

		if(i_fft_done) begin
			if(count_r == 0) begin
				fft_data_w = i_fft_data;
			end
			count_w = count_r + 1;
		end
	end
end

always_ff @(posedge i_clk or posedge i_rst) begin
	if(i_rst) begin
		fft_data_r <= 0;
		count_r <= 0;
	end else begin
		fft_data_r <= fft_data_w;
		count_r <= count_w;
	end
end

endmodule