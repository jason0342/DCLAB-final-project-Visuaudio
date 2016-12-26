module DSP(
	input i_clk,
	input i_rst,
	input i_doneR,
	input [31:0] i_data,
	output[31:0] o_data,
	output o_done
);

	enum{ S_IDLE, S_RUN, S_DONE } state_r, state_w;

	logic[31:0] data_r, data_w;
	logic done_r, done_w;

	assign o_data = data_r;
	assign o_done = done_r;

always_comb begin
	case(state_r)
		S_IDLE: begin
			done_w = 0;
			if(i_doneR) begin
				data_w = i_data;
				state_w = S_RUN;
			end
		end

		S_RUN: begin
			done_w = 1;
			state_w = S_DONE;
		end

		S_DONE: begin
			state_w = S_IDLE;
		end

	endcase

end

always_ff @(posedge i_clk or posedge i_rst) begin
	if(i_rst) begin
		data_r <= 0;
		state_r <= S_IDLE;
		done_r <= 0;
	end else begin
		data_r <= data_w;
		state_r <= state_w;
		done_r <= done_w;
	end
end
