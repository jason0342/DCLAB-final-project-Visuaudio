module Renderer (
	input i_clk,
	input i_rst,
	input [15:0][15:0] i_fft_data,
	input i_fft_done,
	input [10:0] i_VGA_X,
	input [10:0] i_VGA_Y,
	input i_VGA_lock,
	output [7:0] o_VGA_R,
	output [7:0] o_VGA_G,
	output [7:0] o_VGA_B
);

	enum{ S_WAIT, S_WRITE } state_r, state_w;

	// assign o_VGA_R = iRed;
	// assign o_VGA_G = iGreen;
	// assign o_VGA_B = iBlue;

	// logic [7:0] iRed, iGreen, iBlue;
	logic [15:0][15:0] fft_data_r, fft_data_w;
	logic [15:0][3:0] log2_data_r, log2_data_w;
	logic [15:0][3:0] log2_data;
	// logic [8:0] count_r, count_w;
	// logic [15:0] log2A, abs_data;

	// Testing
	// assign iBlue = '1;
	// assign iGreen = '0;
	// assign iRed = '0;

	// log2 log2_0(fft_data_r[i_VGA_X[8:5]], log2A);
	// assign abs_data = (fft_data_r[i_VGA_X[8:5]][15])? (2**16-fft_data_r[i_VGA_X[8:5]]) : fft_data_r[i_VGA_X[8:5]];
	log2 log2_0(i_fft_data, log2_data);

	SpectrumRenderer spectrum0(
		.i_DATA(log2_data_r),
		.i_VGA_X(i_VGA_X),
		.i_VGA_Y(i_VGA_Y),
		.o_VGA_R(o_VGA_R),
		.o_VGA_G(o_VGA_G),
		.o_VGA_B(o_VGA_B)
	);

always_comb begin
	state_w = state_r;
	fft_data_w = fft_data_r;
	log2_data_w = log2_data_r;
	// count_w = count_r;

	// iBlue = '0;
	// iGreen = '0;
	// iRed = '0;

	// if(i_VGA_Y < 10 && i_VGA_X < count_r) begin
	// 	iBlue = '1;
	// end

	// if(i_VGA_X < 512) begin
	// 	if( 479 - i_VGA_Y < (log2A + 1) << 4) begin
	// 		iBlue = 128;
	// 		iGreen = 128;
	// 		iRed = 128;
	// 	end
	// end

	case(state_r)
		S_WAIT: begin
			if(i_fft_done) begin
				state_w = S_WRITE;
				// if(count_r == 0) begin
					// fft_data_w = i_fft_data;
				// end
				// count_w = count_r + 1;
			end
		end

		S_WRITE: begin
			if(!i_VGA_lock) begin
				fft_data_w = i_fft_data;
				log2_data_w = log2_data;
				state_w = S_WAIT;
			end
		end
	endcase

	// if(i_fft_done) begin
	// 	count_w = count_r + 1;
	// end
end

always_ff @(posedge i_clk or posedge i_rst) begin
	if(i_rst) begin
		fft_data_r <= 0;
		log2_data_r <= 0;
		// count_r <= 0;
		state_r <= S_WAIT;
	end else begin
		fft_data_r <= fft_data_w;
		log2_data_r <= log2_data_w;
		// count_r <= count_w;
		state_r <= state_w;
	end
end

endmodule