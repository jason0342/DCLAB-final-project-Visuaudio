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

	logic [15:0][15:0] fft_data_r, fft_data_w;
	logic [15:0][3:0] log2_data_r, log2_data_w;
	logic [15:0][3:0] log2_data;
	logic [7:0] VGA_R_r, VGA_R_w;
	logic [7:0] VGA_G_r, VGA_G_w;
	logic [7:0] VGA_B_r, VGA_B_w;

	assign o_VGA_R = VGA_R_r;
	assign o_VGA_G = VGA_G_r;
	assign o_VGA_B = VGA_B_r;

	log2 log2_0(i_fft_data, log2_data);

	SpectrumRenderer spectrum0(
		.i_DATA(log2_data_r),
		.i_VGA_X(i_VGA_X),
		.i_VGA_Y(i_VGA_Y),
		.o_VGA_R(VGA_R_w),
		.o_VGA_G(VGA_G_w),
		.o_VGA_B(VGA_B_w)
	);

always_comb begin
	state_w = state_r;
	fft_data_w = fft_data_r;
	log2_data_w = log2_data_r;

	case(state_r)
		S_WAIT: begin
			if(i_fft_done) begin
				state_w = S_WRITE;
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

end

always_ff @(posedge i_clk or posedge i_rst) begin
	if(i_rst) begin
		fft_data_r <= 0;
		log2_data_r <= 0;
		state_r <= S_WAIT;
		VGA_R_r <= '0;
		VGA_G_r <= '0;
		VGA_B_r <= '0;
	end else begin
		fft_data_r <= fft_data_w;
		log2_data_r <= log2_data_w;
		state_r <= state_w;
		VGA_R_r <= VGA_R_w;
		VGA_G_r <= VGA_G_w;
		VGA_B_r <= VGA_B_w;
	end
end

endmodule