module ADCcontroller(
	input i_record,
	input i_ADCLRCK,
	input i_ADCDAT,
	input i_BCLK,
	output [31:0] o_DATA,
	output o_done,
	output [1:0] o_REC_STATE
);
	enum { S_IDLE, S_WAIT, S_READ_R, S_READ_L, S_DONE } state_r, state_w;
	logic pre_LRCLK_r, pre_LRCLK_w;
	logic done_r, done_w;
	logic [3:0] bitnum_r, bitnum_w;
	logic [31:0] data_r, data_w;

	assign o_done = done_r;
	assign o_REC_STATE = state_r;

	// Assignments
	always_ff @( posedge i_BCLK ) begin
		state_r <= state_w;
		data_r <= data_w;
		bitnum_r <= bitnum_w;
		done_r <= done_w;
		pre_LRCLK_r <= pre_LRCLK_w;
	end

	always_comb begin
		pre_LRCLK_w = i_ADCLRCK;
		data_w = data_r;
		state_w = state_r;
		done_w = done_r;
		bitnum_w = bitnum_r;

		case (state_r)
			S_IDLE: begin
				bitnum_w = 0;
				done_w = 0;
				if (i_record) begin
					state_w = S_WAIT;
				end
			end

			S_WAIT: begin
				bitnum_w = 0;
				done_w = 0;
				if(pre_LRCLK_r == 1 && i_ADCLRCK == 0) state_w = S_READ_L;
				// if(pre_LRCLK_r == 0 && i_ADCLRCK == 1) state_w = S_READ_R;
			end

			S_READ_L: begin
				if(i_record == 0) begin
					state_w = S_IDLE;
				end else begin
					data_w[bitnum_r] = i_ADCDAT;
					bitnum_w = bitnum_r + 1;
					if(bitnum_r == 15) begin
						state_w = S_WAIT;
						done_w = 1;
					end
				end
			end

			// S_READ_R: begin
			// 	if(i_record == 0) begin
			// 		state_w = S_IDLE;
			// 	end else begin
			// 		data_w[bitnum_r+16] = i_ADCDAT;
			// 		bitnum_w = bitnum_r + 1;
			// 		if(bitnum_r == 15) begin
			// 			state_w = S_WAIT;
			// 		end
			// 	end
			// end

			S_DONE: begin 
				state_w = S_IDLE;
			end
		endcase

	end

endmodule
