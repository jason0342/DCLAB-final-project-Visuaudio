module FFTcontroller (
	input i_clk,
	input i_rst,
	input i_doneDSP,
	input [15:0] i_data,
	output [31:0][15:0] o_data,
	output o_data_done,
	output[1:0] o_fft_error
);
	
	enum{ S_WAIT, S_SEND } state_r, state_w;

	logic[15:0] idat_r, idat_w;
	logic[15:0] sink_count_r, sink_count_w;
	logic[15:0] src_count_r, src_count_w;
	logic[41:0] src_data;
	logic sink_sop_r, sink_sop_w; 
	logic sink_eop_r, sink_eop_w;
	logic sink_valid_r, sink_valid_w;
	logic sink_ready, src_sop, src_eop, src_valid;

	logic[31:0][15:0] odat_r, odat_w;

	fft fft0(
		.clk_clk(i_clk),
		.fft_ii_0_sink_valid(sink_ready && state_r == S_SEND),
		.fft_ii_0_sink_ready(sink_ready),
		.fft_ii_0_sink_error(0),
		.fft_ii_0_sink_startofpacket(sink_ready && state_r == S_SEND && sink_count_r == 0),
		.fft_ii_0_sink_endofpacket(sink_ready && state_r == S_SEND && sink_count_r == 511),
		.fft_ii_0_sink_data({idat_r, {16{1'b0}}, {10'b1000000000}, {1'b0}}),
		.fft_ii_0_source_valid(src_valid),
		.fft_ii_0_source_ready(1),
		.fft_ii_0_source_error(o_fft_error),
		.fft_ii_0_source_startofpacket(src_sop),
		.fft_ii_0_source_endofpacket(src_eop),
		.fft_ii_0_source_data(src_data),
		.reset_reset_n(~i_rst)
	);
	
	assign o_data = odat_r;
	assign o_data_done = src_eop;

always_comb begin
	state_w = state_r;
	idat_w = idat_r;
	odat_w = odat_r;
	sink_count_w = sink_count_r;
	src_count_w = src_count_r;
	sink_sop_w = sink_sop_r;
	sink_eop_w = sink_eop_r;
	sink_valid_w = sink_valid_r;

	case(state_r)
		S_WAIT: begin
			sink_sop_w = 0;
			sink_eop_w = 0;
			if(sink_count_r == 511) begin
				sink_count_w = 0;
			end
			if(i_doneDSP) begin
				idat_w = i_data;
				state_w = S_SEND;
			end
		end

		S_SEND: begin
			if(sink_ready) begin
				sink_valid_w = 1;
				if(sink_count_r == 0) begin
					sink_sop_w = 1;
				end else if (sink_count_r == 511) begin
					sink_eop_w = 1;
				end
				sink_count_w = sink_count_r + 1;
				state_w = S_WAIT;
			end

		end

	endcase

	if(src_valid) begin
		if(src_count_r < 256) begin
			odat_w[src_count_r[7:3]] = src_data[41:26];
		end
		src_count_w = src_count_r + 1;
		if(src_eop) begin
			src_count_w = 0;
		end
	end

end

always_ff@(posedge i_clk or posedge i_rst) begin
	if(i_rst) begin
		state_r <= S_WAIT;
		idat_r <= 0;
		odat_r <= '0;
		sink_count_r <= 0;
		src_count_r <= 0;
		sink_sop_r <= 0;
		sink_eop_r <= 0;
		sink_valid_r <= 0;
	end else begin
		state_r <= state_w;
		idat_r <= idat_w;
		odat_r <= odat_w;
		sink_count_r <= sink_count_w;
		src_count_r <= src_count_w;
		sink_sop_r <= sink_sop_w;
		sink_eop_r <= sink_eop_w;
		sink_valid_r <= sink_valid_w;
	end
end

endmodule